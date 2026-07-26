-- Sudoku 6 -- competitions
--
-- Design notes that matter:
--
-- * The puzzle seed lives in competition_rounds, and that row does not exist
--   until a round starts. "Nobody can see the puzzle before everyone joins"
--   is therefore enforced by the data not existing yet, not by the UI hiding
--   it -- there is nothing to peek at.
--
-- * Timing is server-authoritative. started_at and finished_at are both set
--   by the database, and elapsed is computed from them, so a client cannot
--   report a time it didn't earn. Solo leaderboards stay client-timed; this
--   is where it actually matters because someone is competing against you.
--
-- * State transitions go through SECURITY DEFINER functions rather than
--   direct table writes, so rules like "host only" and "minimum two players"
--   can't be bypassed by writing rows straight from the client.

create table if not exists public.competitions (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique,
  host_id       uuid not null references public.profiles (id) on delete cascade,
  tier          text not null,
  rounds        integer not null,
  current_round integer not null default 0,   -- 0 = still in the lobby
  status        text not null default 'lobby',-- lobby | active | complete
  created_at    timestamptz not null default now(),

  constraint rounds_sane check (rounds between 1 and 20),
  constraint status_valid check (status in ('lobby','active','complete'))
);

create table if not exists public.competition_players (
  competition_id uuid not null references public.competitions (id) on delete cascade,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  joined_at      timestamptz not null default now(),
  primary key (competition_id, user_id)
);

create table if not exists public.competition_rounds (
  competition_id uuid not null references public.competitions (id) on delete cascade,
  round_number   integer not null,
  seed           bigint not null,
  started_at     timestamptz not null default now(),
  primary key (competition_id, round_number)
);

create table if not exists public.competition_results (
  competition_id uuid not null references public.competitions (id) on delete cascade,
  round_number   integer not null,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  elapsed_ms     integer not null,
  mistakes       integer not null default 0,
  hints_used     integer not null default 0,
  finished_at    timestamptz not null default now(),
  primary key (competition_id, round_number, user_id)
);

alter table public.competitions        enable row level security;
alter table public.competition_players enable row level security;
alter table public.competition_rounds  enable row level security;
alter table public.competition_results enable row level security;

-- Readable by anyone holding the link: joining requires looking the
-- competition up by code before you're a member. Nothing sensitive here.
drop policy if exists "competitions readable" on public.competitions;
create policy "competitions readable"
  on public.competitions for select using (true);

drop policy if exists "players readable" on public.competition_players;
create policy "players readable"
  on public.competition_players for select using (true);

drop policy if exists "results readable" on public.competition_results;
create policy "results readable"
  on public.competition_results for select using (true);

-- Rounds carry the seed, so restrict them to players. This is what stops
-- someone with the link from pulling the puzzle without joining.
drop policy if exists "rounds readable by players" on public.competition_rounds;
create policy "rounds readable by players"
  on public.competition_rounds for select
  using (exists (
    select 1 from public.competition_players p
    where p.competition_id = competition_rounds.competition_id
      and p.user_id = auth.uid()
  ));

-- No direct INSERT/UPDATE policies on purpose: every mutation goes through
-- the functions below, which enforce the rules.

create or replace function public.create_competition(p_tier text, p_rounds int)
returns text
language plpgsql security definer set search_path = public
as $$
declare
  v_code text;
  v_id   uuid;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;

  -- Short, unambiguous code. Excludes look-alike characters so a code read
  -- aloud or typed from a screenshot doesn't fail.
  loop
    v_code := upper(
      substr(translate(encode(gen_random_bytes(8), 'base64'),
             '+/=OI01lLU', 'abcdefghij'), 1, 6));
    exit when not exists (select 1 from competitions where code = v_code);
  end loop;

  insert into competitions (code, host_id, tier, rounds)
  values (v_code, auth.uid(), p_tier, p_rounds)
  returning id into v_id;

  insert into competition_players (competition_id, user_id)
  values (v_id, auth.uid());

  return v_code;
end;
$$;

create or replace function public.join_competition(p_code text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id     uuid;
  v_status text;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;

  select id, status into v_id, v_status
  from competitions where code = upper(p_code);

  if v_id is null then
    raise exception 'no such competition';
  end if;
  if v_status = 'complete' then
    raise exception 'competition already finished';
  end if;

  insert into competition_players (competition_id, user_id)
  values (v_id, auth.uid())
  on conflict do nothing;   -- re-joining is a no-op, not an error

  return v_id;
end;
$$;

create or replace function public.start_next_round(p_competition uuid, p_seed bigint)
returns int
language plpgsql security definer set search_path = public
as $$
declare
  v_host    uuid;
  v_rounds  int;
  v_current int;
  v_players int;
begin
  select host_id, rounds, current_round
    into v_host, v_rounds, v_current
  from competitions where id = p_competition;

  if v_host is null then
    raise exception 'no such competition';
  end if;
  -- Only the host advances rounds; otherwise any player could start the
  -- next one while others are still reading the results.
  if v_host <> auth.uid() then
    raise exception 'only the host can start a round';
  end if;

  select count(*) into v_players
  from competition_players where competition_id = p_competition;

  -- A "competition" with one player is just a solo game.
  if v_players < 2 then
    raise exception 'need at least 2 players';
  end if;
  if v_current >= v_rounds then
    raise exception 'all rounds already played';
  end if;

  insert into competition_rounds (competition_id, round_number, seed)
  values (p_competition, v_current + 1, p_seed);

  update competitions
     set current_round = v_current + 1,
         status = 'active'
   where id = p_competition;

  return v_current + 1;
end;
$$;

create or replace function public.finish_round(
  p_competition uuid,
  p_round int,
  p_mistakes int,
  p_hints int
) returns int
language plpgsql security definer set search_path = public
as $$
declare
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

  select started_at into v_started
  from competition_rounds
  where competition_id = p_competition and round_number = p_round;

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

  -- Close the competition once the final round has a result from everyone.
  select rounds, current_round into v_rounds, v_current
  from competitions where id = p_competition;

  if v_current >= v_rounds
     and (select count(*) from competition_results
          where competition_id = p_competition and round_number = v_current)
       >= (select count(*) from competition_players
           where competition_id = p_competition)
  then
    update competitions set status = 'complete' where id = p_competition;
  end if;

  return v_elapsed;
end;
$$;

-- Standings: total time across played rounds, fewest rounds missed first.
create or replace view public.competition_standings as
select
  r.competition_id,
  r.user_id,
  p.username,
  count(*)                as rounds_played,
  sum(r.elapsed_ms)       as total_ms,
  sum(r.mistakes)         as total_mistakes,
  sum(r.hints_used)       as total_hints
from competition_results r
join profiles p on p.id = r.user_id
group by r.competition_id, r.user_id, p.username;

create index if not exists competition_players_user_idx
  on public.competition_players (user_id);
create index if not exists competition_results_board_idx
  on public.competition_results (competition_id, round_number, elapsed_ms);
