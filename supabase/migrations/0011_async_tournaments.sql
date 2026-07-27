-- Sudoku 6 -- async tournaments
--
-- A competition you play on your own schedule: the host plays all five rounds
-- tonight, players 2 and 3 play tomorrow, one round at a time. Standings show
-- everyone's cumulative time through their OWN last completed round.
--
-- The single thing that forced simultaneous play was competition_rounds
-- .started_at: one timestamp per (competition, round), which finish_round
-- measured everyone against. Async moves that clock to per player per round
-- (competition_attempts). Both ends of the measurement are still server
-- clocks, so times remain untamperable.
--
-- It also fixes an unfairness in sync mode that nobody asked about: there, the
-- clock starts when the host presses Start, so a player slow to pick up their
-- phone burns time they never got to use.
--
-- Sync is untouched and still selectable; async ships as a mode, not a
-- replacement.

alter table public.competitions
  add column if not exists mode text not null default 'sync';

alter table public.competitions drop constraint if exists mode_valid;
alter table public.competitions
  add constraint mode_valid check (mode in ('sync','async'));

-- Per-player, per-round clock. Deliberately NOT a nullable started_at on
-- competition_results: results mean "finished", and overloading that row would
-- put in-progress rows in front of every standings query.
create table if not exists public.competition_attempts (
  competition_id uuid not null references public.competitions (id) on delete cascade,
  round_number   integer not null,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  started_at     timestamptz not null default now(),
  primary key (competition_id, round_number, user_id)
);

alter table public.competition_attempts enable row level security;

drop policy if exists "attempts readable by players" on public.competition_attempts;
create policy "attempts readable by players"
  on public.competition_attempts for select
  using (public.is_competition_member(competition_id));

-- No insert/update policy: writes go through start_round only, matching every
-- other competition table.

-- New tables are not in the realtime publication by default, and the failure
-- mode is silent non-delivery rather than an error. That cost us a debugging
-- session once already (see 0007).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'competition_attempts'
  ) then
    alter publication supabase_realtime add table public.competition_attempts;
  end if;
end $$;

-- Definer helpers so policies can ask these questions without re-entering the
-- RLS of the tables they read (same reasoning as is_competition_member).
create or replace function public.has_started_round(p_competition uuid, p_round int)
returns boolean
language sql security definer stable set search_path = public
as $$
  select exists (
    select 1 from competition_attempts
    where competition_id = p_competition
      and round_number = p_round
      and user_id = auth.uid()
  );
$$;

create or replace function public.competition_mode(p_competition uuid)
returns text
language sql security definer stable set search_path = public
as $$
  select mode from competitions where id = p_competition;
$$;

-- In sync mode the round row does not exist until the host starts the round,
-- so "row exists" has been sufficient to mean "you may see the seed".
--
-- Async breaks that: you playing round 3 tonight creates the row hours before
-- another player gets there, and the old policy would hand them a seed for a
-- round they have not started. Hence an explicit predicate.
drop policy if exists "rounds readable by players" on public.competition_rounds;
create policy "rounds readable by players"
  on public.competition_rounds for select
  using (
    public.is_competition_member(competition_id)
    and (
      public.competition_mode(competition_id) = 'sync'
      or public.has_started_round(competition_id, round_number)
    )
  );

-- Creation ------------------------------------------------------------------

create or replace function public.create_competition_mode(
  p_tier text,
  p_rounds int,
  p_mode text
)
returns text
language plpgsql security definer set search_path = public
as $fn$
declare
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_code text;
  v_id   uuid;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;
  if not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'pick a username first';
  end if;
  if p_mode not in ('sync','async') then
    raise exception 'unknown mode';
  end if;

  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code ||
        substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from competitions where code = v_code);
  end loop;

  -- Async has no lobby to wait in and no two-player minimum: the host can
  -- start playing immediately, which is the entire point of the mode.
  insert into competitions (code, host_id, tier, rounds, mode, status)
  values (v_code, auth.uid(), p_tier, p_rounds, p_mode,
          case when p_mode = 'async' then 'active' else 'lobby' end)
  returning id into v_id;

  insert into competition_players (competition_id, user_id)
  values (v_id, auth.uid());

  return v_code;
end;
$fn$;

-- The old two-argument entry point keeps working, unchanged in behaviour, so a
-- client build still in someone's browser tab does not break the moment this
-- migration lands. Deliberately NOT done by giving p_mode a default: that
-- would make a two-argument call ambiguous between the two functions and
-- Postgres would reject it outright.
create or replace function public.create_competition(p_tier text, p_rounds int)
returns text
language sql security definer set search_path = public
as $$
  select public.create_competition_mode(p_tier, p_rounds, 'sync');
$$;

-- Playing -------------------------------------------------------------------

-- Opens a round for the caller: fixes the seed if nobody has reached this
-- round yet, stamps their personal clock, and returns the seed.
create or replace function public.start_round(p_competition uuid, p_round int)
returns bigint
language plpgsql security definer set search_path = public
as $fn$
declare
  v_comp record;
  v_done int;
  v_seed bigint;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;
  if not public.is_competition_member(p_competition) then
    raise exception 'not a player in this competition';
  end if;

  -- Locked for the duration so two players arriving at an unplayed round at
  -- the same moment cannot generate two different seeds for it.
  select * into v_comp from competitions where id = p_competition for update;
  if v_comp.id is null then
    raise exception 'no such competition';
  end if;
  if v_comp.mode <> 'async' then
    raise exception 'not an async competition';
  end if;
  if v_comp.status = 'complete' then
    raise exception 'competition already finished';
  end if;
  if p_round < 1 or p_round > v_comp.rounds then
    raise exception 'no such round';
  end if;

  -- Rounds are taken in order. Without this a client could ask for round 5 on
  -- its first request and skip the ones it expected to be slow at.
  select count(*) into v_done
  from competition_results
  where competition_id = p_competition and user_id = auth.uid();

  if p_round <> v_done + 1 then
    raise exception 'finish the previous round first';
  end if;

  -- One seed per round, shared by everyone -- that is what makes the times
  -- comparable. First player to arrive fixes it.
  select seed into v_seed from competition_rounds
  where competition_id = p_competition and round_number = p_round;

  if v_seed is null then
    insert into competition_rounds (competition_id, round_number, seed)
    values (p_competition, p_round, floor(random() * 2147483647)::bigint)
    on conflict (competition_id, round_number) do nothing;

    select seed into v_seed from competition_rounds
    where competition_id = p_competition and round_number = p_round;
  end if;

  -- do nothing, not overwrite: re-opening a round already in progress must
  -- resume the existing clock rather than hand back a fresh one.
  insert into competition_attempts (competition_id, round_number, user_id)
  values (p_competition, p_round, auth.uid())
  on conflict do nothing;

  return v_seed;
end;
$fn$;

create or replace function public.finish_round(
  p_competition uuid,
  p_round int,
  p_mistakes int,
  p_hints int
) returns int
language plpgsql security definer set search_path = public
as $fn$
declare
  v_mode    text;
  v_started timestamptz;
  v_elapsed int;
  v_rounds  int;
  v_current int;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;
  if not exists (
    select 1 from competition_players
    where competition_id = p_competition and user_id = auth.uid()
  ) then
    raise exception 'not a player in this competition';
  end if;

  select mode, rounds, current_round
    into v_mode, v_rounds, v_current
  from competitions where id = p_competition;

  if v_mode = 'async' then
    select started_at into v_started
    from competition_attempts
    where competition_id = p_competition
      and round_number = p_round
      and user_id = auth.uid();
  else
    select started_at into v_started
    from competition_rounds
    where competition_id = p_competition and round_number = p_round;
  end if;

  if v_started is null then
    raise exception 'round not started';
  end if;

  -- The whole point: elapsed comes from server clocks at both ends, so a
  -- client can't submit a time it didn't actually take.
  v_elapsed := greatest(1, (extract(epoch from (now() - v_started)) * 1000)::int);

  insert into competition_results
    (competition_id, round_number, user_id, elapsed_ms, mistakes, hints_used)
  values
    (p_competition, p_round, auth.uid(), v_elapsed, greatest(p_mistakes,0), greatest(p_hints,0))
  on conflict (competition_id, round_number, user_id) do nothing;

  if v_mode = 'async' then
    -- Done when no (player, round) pair is missing a result. Evaluated against
    -- the current player list, so a late joiner reopens the question simply by
    -- joining -- which is the behaviour we want, since they can still play.
    --
    -- The >= 2 guard is load-bearing, not caution. The headline async flow is
    -- "create it and play all my rounds now, friends join later": without it,
    -- the host finishing round N alone satisfies "everyone has played
    -- everything", the competition closes, and join_competition then rejects
    -- the very people it was created for. A solo competition is waiting, not
    -- finished; the host can still end it by hand.
    if (select count(*) from competition_players
        where competition_id = p_competition) >= 2
       and not exists (
      select 1
      from competition_players cp
      cross join generate_series(1, v_rounds) as r(n)
      where cp.competition_id = p_competition
        and not exists (
          select 1 from competition_results cr
          where cr.competition_id = p_competition
            and cr.user_id = cp.user_id
            and cr.round_number = r.n
        )
    ) then
      update competitions set status = 'complete' where id = p_competition;
    end if;
  else
    -- Close the competition once the final round has a result from everyone.
    if v_current >= v_rounds
       and (select count(*) from competition_results
            where competition_id = p_competition and round_number = v_current)
         >= (select count(*) from competition_players
             where competition_id = p_competition)
    then
      update competitions set status = 'complete' where id = p_competition;
    end if;
  end if;

  return v_elapsed;
end;
$fn$;

-- Host escape hatch for the player who joins and never plays. Standings are
-- already partial-aware, so closing early simply reports what happened.
create or replace function public.close_competition(p_competition uuid)
returns void
language plpgsql security definer set search_path = public
as $fn$
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;
  if not exists (
    select 1 from competitions
    where id = p_competition and host_id = auth.uid()
  ) then
    raise exception 'only the host can close this competition';
  end if;

  update competitions set status = 'complete' where id = p_competition;
end;
$fn$;

revoke all on function public.start_round(uuid, int) from public, anon;
revoke all on function public.close_competition(uuid) from public, anon;
revoke all on function public.create_competition_mode(text, int, text) from public, anon;
grant execute on function public.start_round(uuid, int) to authenticated;
grant execute on function public.close_competition(uuid) to authenticated;
grant execute on function public.create_competition_mode(text, int, text) to authenticated;
