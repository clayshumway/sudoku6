-- Sudoku 6 -- global leaderboard
--
-- The existing leaderboard answers "who was fastest on THIS puzzle". This one
-- answers "who is good at this game", aggregated across every puzzle a player
-- has finished.
--
-- Per-difficulty rows carry a tier; the all-difficulties rollup carries tier
-- null. The client picks with `tier=eq.medium` or `tier=is.null`, and sorts
-- with PostgREST's `order`, so a new sort option needs no migration.
--
-- Time columns are deliberately NULL on the rollup rows. A best time across
-- all difficulties is just the player's fastest Easy puzzle, and an average
-- across tiers says more about which tiers someone plays than how well they
-- play. Overall therefore ranks on volume and cleanliness only, and the null
-- says so rather than leaving a misleading number on screen.
--
-- Written as a UNION ALL of two plain aggregates rather than GROUPING SETS,
-- and with every aggregate cast parenthesised, because the clever version of
-- this failed to create and the interesting part of this view is the data, not
-- the SQL.
--
-- Note these are client-timed solves (server-authoritative timing applies to
-- competition rounds, not casual play), which is the trust model this game has
-- always had for solo puzzles.

drop view if exists public.global_leaderboard;

create view public.global_leaderboard as
  select
    s.user_id                                                            as user_id,
    p.username                                                           as username,
    s.tier                                                               as tier,
    (count(*))::int                                                      as solves,
    (count(*) filter (where s.mistakes = 0 and s.hints_used = 0))::int   as clean_solves,
    (min(s.elapsed_ms))::int                                             as best_ms,
    (round(avg(s.elapsed_ms)))::int                                      as avg_ms,
    (sum(s.mistakes))::int                                               as total_mistakes,
    (sum(s.hints_used))::int                                             as total_hints,
    max(s.completed_at)                                                  as last_solve_at
  from public.solves s
  join public.profiles p on p.id = s.user_id
  group by s.user_id, p.username, s.tier

  union all

  select
    s.user_id,
    p.username,
    null::text,
    (count(*))::int,
    (count(*) filter (where s.mistakes = 0 and s.hints_used = 0))::int,
    null::int,
    null::int,
    (sum(s.mistakes))::int,
    (sum(s.hints_used))::int,
    max(s.completed_at)
  from public.solves s
  join public.profiles p on p.id = s.user_id
  group by s.user_id, p.username;

-- Run as the caller so the underlying policies apply, matching
-- competition_standings. solves is deliberately world-readable (see 0002):
-- a leaderboard nobody can read isn't a leaderboard, and the table holds no
-- personal data beyond a user id that only resolves to a self-chosen username.
alter view public.global_leaderboard set (security_invoker = true);

-- Explicit, not assumed. PostgREST leaves objects a role cannot select out of
-- its schema cache entirely, so a missing grant surfaces as "Could not find
-- the table in the schema cache" (PGRST205) rather than a permission error --
-- which sends you hunting for a view that exists perfectly well.
grant select on public.global_leaderboard to anon, authenticated;

-- The board sorts by these; without an index every sort is a full scan of
-- solves. Cheap now, awkward to add to a hot table later.
create index if not exists solves_user_tier_idx
  on public.solves (user_id, tier);

-- Rebuild PostgREST's schema cache now rather than waiting for it to notice.
notify pgrst, 'reload schema';
