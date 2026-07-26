-- Sudoku 6 -- realtime fix + ready gate between rounds
--
-- Bug fixed here: the lobby never updated when a player joined. The
-- postgres_changes subscriptions were correct, but new tables are NOT part
-- of the `supabase_realtime` publication by default -- and a subscription to
-- an unpublished table connects fine and then silently receives nothing.
--
-- Feature added here: rounds after the first wait for every player to press
-- Ready. The host's Start press counts as the host's ready.

-- ---------------------------------------------------------------------------
-- Ready table
-- ---------------------------------------------------------------------------

create table if not exists public.competition_ready (
  competition_id uuid not null references public.competitions (id) on delete cascade,
  round_number   integer not null,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  ready_at       timestamptz not null default now(),
  primary key (competition_id, round_number, user_id)
);

alter table public.competition_ready enable row level security;

drop policy if exists "ready readable" on public.competition_ready;
create policy "ready readable"
  on public.competition_ready for select using (true);

-- No INSERT policy on purpose: readiness goes through mark_ready below,
-- matching the pattern used by every other competition mutation.

-- ---------------------------------------------------------------------------
-- Realtime publication
-- ---------------------------------------------------------------------------
-- Each ALTER errors with duplicate_object if the table is already published,
-- so each gets its own guard and the script stays re-runnable.

do $$ begin
  alter publication supabase_realtime add table public.competitions;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.competition_players;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.competition_results;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.competition_ready;
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- mark_ready
-- ---------------------------------------------------------------------------

create or replace function public.mark_ready(p_competition uuid)
returns int
language plpgsql security definer set search_path = public
as $fn$
declare
  v_status  text;
  v_current int;
  v_rounds  int;
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

  select status, current_round, rounds
    into v_status, v_current, v_rounds
  from competitions where id = p_competition;

  if v_status is null then
    raise exception 'no such competition';
  end if;
  if v_status <> 'active' then
    raise exception 'competition is not active';
  end if;
  if v_current >= v_rounds then
    raise exception 'no rounds left';
  end if;

  insert into competition_ready (competition_id, round_number, user_id)
  values (p_competition, v_current + 1, auth.uid())
  on conflict do nothing;

  return v_current + 1;
end;
$fn$;

-- ---------------------------------------------------------------------------
-- start_next_round: unchanged for round 1 (the lobby is its gate); rounds
-- after that require every OTHER player to be ready. The host pressing
-- Start is treated as the host's own ready, so they don't need two taps.
-- ---------------------------------------------------------------------------

create or replace function public.start_next_round(p_competition uuid, p_seed bigint)
returns int
language plpgsql security definer set search_path = public
as $fn$
declare
  v_host    uuid;
  v_rounds  int;
  v_current int;
  v_players int;
  v_missing int;
begin
  select host_id, rounds, current_round
    into v_host, v_rounds, v_current
  from competitions where id = p_competition;

  if v_host is null then
    raise exception 'no such competition';
  end if;
  if v_host <> auth.uid() then
    raise exception 'only the host can start a round';
  end if;

  select count(*) into v_players
  from competition_players where competition_id = p_competition;

  if v_players < 2 then
    raise exception 'need at least 2 players';
  end if;
  if v_current >= v_rounds then
    raise exception 'all rounds already played';
  end if;

  if v_current >= 1 then
    select count(*) into v_missing
    from competition_players p
    where p.competition_id = p_competition
      and p.user_id <> auth.uid()
      and not exists (
        select 1 from competition_ready r
        where r.competition_id = p_competition
          and r.round_number = v_current + 1
          and r.user_id = p.user_id
      );
    if v_missing > 0 then
      raise exception 'waiting for % player(s) to be ready', v_missing;
    end if;
  end if;

  insert into competition_rounds (competition_id, round_number, seed)
  values (p_competition, v_current + 1, p_seed);

  update competitions
     set current_round = v_current + 1,
         status = 'active'
   where id = p_competition;

  return v_current + 1;
end;
$fn$;
