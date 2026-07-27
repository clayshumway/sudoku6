-- Sudoku 6 -- pausing a competition round
--
-- Solo play is client-timed, so pausing there is just a stopped ticker.
-- Competition rounds are not: finish_round computes elapsed from server
-- clocks precisely so a client can't report a time it didn't take. A pause
-- button that only stopped the on-screen timer would therefore be a lie --
-- the player's recorded time would keep climbing while the display sat still.
--
-- So pauses are recorded server-side and deducted at finish. The deduction is
-- per player even in sync mode, where the round's start timestamp is shared:
-- your pause is yours, and does not affect anyone else's clock.
--
-- What this deliberately does not defend against: pausing to think. The board
-- is hidden while paused, so it costs you the puzzle being on screen, but a
-- determined player could memorise a 6x6 grid. That's the same trust model as
-- the rest of the game among friends, and a screenshot would work anyway.

alter table public.competition_attempts
  add column if not exists paused_ms integer not null default 0;
alter table public.competition_attempts
  add column if not exists paused_at timestamptz;

-- Sync competitions have no attempt row today -- their clock lives on
-- competition_rounds -- so pausing creates one purely to hold the pause
-- bookkeeping. started_at is unused in that mode.
--
-- coalesce on conflict makes a second pause a no-op rather than restarting the
-- pause window, which would silently discard the time already accrued.
create or replace function public.pause_round(p_competition uuid, p_round int)
returns void
language plpgsql security definer set search_path = public
as $fn$
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;
  if not public.is_competition_member(p_competition) then
    raise exception 'not a player in this competition';
  end if;

  insert into competition_attempts
    (competition_id, round_number, user_id, paused_at)
  values (p_competition, p_round, auth.uid(), now())
  on conflict (competition_id, round_number, user_id) do update
    set paused_at = coalesce(competition_attempts.paused_at, now());
end;
$fn$;

create or replace function public.resume_round(p_competition uuid, p_round int)
returns void
language plpgsql security definer set search_path = public
as $fn$
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;

  update competition_attempts
  set paused_ms = paused_ms
        + greatest(0, (extract(epoch from (now() - paused_at)) * 1000)::int),
      paused_at = null
  where competition_id = p_competition
    and round_number = p_round
    and user_id = auth.uid()
    and paused_at is not null;
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
  v_paused  int;
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

  -- Time spent paused, including a pause still open right now: finishing
  -- while paused is possible from a stale client, and charging that time
  -- would be the exact unfairness pausing exists to prevent.
  select coalesce(paused_ms, 0)
         + case
             when paused_at is not null
             then greatest(0, (extract(epoch from (now() - paused_at)) * 1000)::int)
             else 0
           end
    into v_paused
  from competition_attempts
  where competition_id = p_competition
    and round_number = p_round
    and user_id = auth.uid();

  -- The whole point: elapsed comes from server clocks at both ends, so a
  -- client can't submit a time it didn't actually take.
  v_elapsed := greatest(
    1,
    (extract(epoch from (now() - v_started)) * 1000)::int - coalesce(v_paused, 0)
  );

  update competition_attempts
  set paused_at = null
  where competition_id = p_competition
    and round_number = p_round
    and user_id = auth.uid()
    and paused_at is not null;

  insert into competition_results
    (competition_id, round_number, user_id, elapsed_ms, mistakes, hints_used)
  values
    (p_competition, p_round, auth.uid(), v_elapsed, greatest(p_mistakes,0), greatest(p_hints,0))
  on conflict (competition_id, round_number, user_id) do nothing;

  if v_mode = 'async' then
    -- Done when no (player, round) pair is missing a result. The >= 2 guard
    -- keeps "create it and play my rounds now, friends join later" working:
    -- without it the host finishing alone closes the competition and
    -- join_competition then rejects the people it was created for.
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

revoke all on function public.pause_round(uuid, int) from public, anon;
revoke all on function public.resume_round(uuid, int) from public, anon;
grant execute on function public.pause_round(uuid, int) to authenticated;
grant execute on function public.resume_round(uuid, int) to authenticated;
