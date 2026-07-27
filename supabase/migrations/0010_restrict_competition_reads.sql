-- Sudoku 6 -- close the anonymous-read gap on competition tables
--
-- 0004 shipped `for select using (true)` on competitions, competition_players
-- and competition_results (and 0007 on competition_ready). The publishable key
-- is embedded in the public web bundle, so "using (true)" meant anyone could
-- list every competition CODE, every player, and everyone's round times. That
-- quietly breaks the invite model: the code is supposed to BE the invite, and
-- a listable table turns it into public knowledge.
--
-- Reads are now restricted to players of the competition in question.
--
-- Two flows deliberately still work for non-members, both through
-- SECURITY DEFINER functions, because in each case the caller holds a
-- capability that justifies the read:
--   * join_competition (existing, 0004/0008) -- knowing the code.
--   * competition_chain_tip (new, below)     -- being a player of an EARLIER
--     competition in the same rematch chain.

-- Membership test used by every policy below.
--
-- SECURITY DEFINER on purpose: a policy on competition_players that queried
-- competition_players directly would re-enter that table's own RLS. Doing the
-- lookup inside a definer function reads the table once, with policies
-- bypassed, and hands back a plain boolean -- no recursion, and one place to
-- change if membership ever means something more than "has a player row".
create or replace function public.is_competition_member(p_competition uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from competition_players
    where competition_id = p_competition
      and user_id = auth.uid()
  );
$$;

drop policy if exists "competitions readable" on public.competitions;
drop policy if exists "competitions readable by players" on public.competitions;
create policy "competitions readable by players"
  on public.competitions for select
  using (public.is_competition_member(id));

drop policy if exists "players readable" on public.competition_players;
drop policy if exists "players readable by players" on public.competition_players;
create policy "players readable by players"
  on public.competition_players for select
  using (public.is_competition_member(competition_id));

drop policy if exists "results readable" on public.competition_results;
drop policy if exists "results readable by players" on public.competition_results;
create policy "results readable by players"
  on public.competition_results for select
  using (public.is_competition_member(competition_id));

drop policy if exists "ready readable" on public.competition_ready;
drop policy if exists "ready readable by players" on public.competition_ready;
create policy "ready readable by players"
  on public.competition_ready for select
  using (public.is_competition_member(competition_id));

-- Already player-only in 0004, restated through the helper so every table in
-- this group answers the membership question the same way.
drop policy if exists "rounds readable by players" on public.competition_rounds;
create policy "rounds readable by players"
  on public.competition_rounds for select
  using (public.is_competition_member(competition_id));

-- Views run with the OWNER's rights by default, which would let the standings
-- view keep reading competition_results straight past the policy just added.
-- security_invoker makes it run as the caller, so the new RLS actually applies.
alter view public.competition_standings set (security_invoker = true);

-- Walks a rematch chain to its newest competition.
--
-- Exists so the staleness-aware banner survives member-only RLS. The case it
-- protects: players 1-3 finish a competition, 1 and 2 rematch without 3, and
-- player 3 later opens the original. Player 3 is not a member of the rematch,
-- so a plain read of it now returns nothing -- and the UI would silently show
-- no banner even while an ongoing rematch was waiting for them.
--
-- Authorisation is membership of the competition the caller is LOOKING AT,
-- which is exactly the group-membership claim the rematch feature is built on
-- (and the same test rematch_competition uses). Returns no rows when the chain
-- has no rematch, so "nothing to join" and "not allowed" look identical to an
-- outsider.
create or replace function public.competition_chain_tip(p_competition uuid)
returns setof public.competitions
language plpgsql
security definer
stable
set search_path = public
as $fn$
declare
  v_tip record;
begin
  if auth.uid() is null then
    return;
  end if;
  if not public.is_competition_member(p_competition) then
    return;
  end if;

  select * into v_tip from competitions where id = p_competition;
  if v_tip.id is null then
    return;
  end if;

  -- Bounded, matching rematch_competition: a cycle must never hang a request.
  for i in 1..20 loop
    exit when v_tip.rematch_id is null;
    select * into v_tip from competitions where id = v_tip.rematch_id;
  end loop;

  -- No rematch started yet: nothing to point at.
  if v_tip.id = p_competition then
    return;
  end if;

  return next v_tip;
end;
$fn$;

revoke all on function public.competition_chain_tip(uuid) from public, anon;
grant execute on function public.competition_chain_tip(uuid) to authenticated;
