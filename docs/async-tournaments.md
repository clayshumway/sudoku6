# Async tournaments

## Goal

A competition you can play on your own schedule. The host creates it and plays
straight through all five rounds tonight; players 2 and 3 play tomorrow, at
their leisure, one round at a time if they like. Standings show every player's
cumulative time **through their own last completed round** — exactly what the
current standings show, minus the requirement that everyone be present at once.

Sync competitions stay. This ships as a **mode**, chosen at creation, not a
replacement — same tables, one flag.

## Decisions taken

- **A tournament closes when every player has finished every round**, with a
  host override to close it early (for the player who joins and never plays).
  No deadlines — this is a game among friends, and an expiry timer is a support
  burden with no upside at this scale.
- **Joining after play has started is allowed.** A late joiner simply starts at
  round 1 like everyone else and is behind on `rounds_played`. Async has no
  coherent reason to lock the door, and the standings already sort players who
  have played fewer rounds below those who have played more.

## The one real blocker

`competition_rounds` holds a single `started_at` per `(competition_id,
round_number)`, and `finish_round` computes elapsed as `now() - that
timestamp`. That single column is the entire reason everyone must play
simultaneously. Every other synchronous behaviour (the ready gate, the host's
Start button, the shared `current_round` pointer) is scaffolding around it.

The fix is to move the start clock from **per round** to **per player per
round**: the server stamps `started_at` when *you* open round N, and your
elapsed time is measured against your own stamp.

This preserves the property that matters — both ends of the measurement are
server clocks, so a client still cannot report a time it did not take.

It also removes an unfairness that exists today: currently the clock starts
when the host presses Start, so a player slow to pick up their phone burns time
they never had a chance to use.

## What already supports this

Worth stating plainly, because it is most of the work:

- **`competition_standings` already handles partial completion.** It computes
  `rounds_played` and `sum(elapsed_ms)` grouped per player. Ordering by
  `rounds_played desc, total_ms asc` produces precisely the requested
  behaviour with no view change.
- **Puzzles are reproducible from `(tier, seed)`**, so a player arriving at
  round 3 a day later gets the identical board with nothing stored server-side.
- **`current_round` becomes derivable per player** — `1 + count(my finished
  rounds)`. Nothing to keep in sync, so the column stays only for sync mode.
- **RLS membership model is unchanged.** Async introduces no new visibility
  class; players see their competition, non-players see nothing.
- **Rematch chains are unaffected** and work the same for async competitions.

## Schema

```sql
alter table public.competitions
  add column if not exists mode text not null default 'sync'
    check (mode in ('sync','async'));

-- Per-player, per-round attempt clock. Created when a player opens a round.
create table if not exists public.competition_attempts (
  competition_id uuid not null references public.competitions (id) on delete cascade,
  round_number   integer not null,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  started_at     timestamptz not null default now(),
  primary key (competition_id, round_number, user_id)
);
```

A separate table rather than a nullable `started_at` on `competition_results`:
results are finished rounds, and overloading that row would make every
standings query filter on "actually done" and risk a partial row leaking into a
leaderboard. Attempts and results stay distinct concepts.

`competition_results` is unchanged. `competition_rounds` is unchanged — the
seed per round is still shared by all players, which is what makes the
comparison fair.

## RPCs

**`start_round(p_competition uuid, p_round int) returns bigint`** (new)

1. Caller must be a player; competition must be `async` and not `complete`.
2. Caller must be entitled to this round: `p_round = 1 + (count of their
   finished results)`. This is the anti-skip check — you cannot jump to round 5.
3. Lazily create `competition_rounds` for this round if absent (first player to
   arrive generates the seed; everyone after gets the same one).
4. Insert the attempt row `on conflict do nothing`, so re-opening a round in
   progress resumes rather than resetting the clock.
5. Return the seed.

**`finish_round`** (modified)

Branch on mode. Sync keeps reading `competition_rounds.started_at` exactly as
now. Async reads the caller's `competition_attempts.started_at`, and raises if
absent — you cannot finish a round you never started.

The completion check changes for async: close the competition when every player
has a result for every round. Because late joiners are permitted, this is
evaluated against the *current* player list, and joining reopens the check
naturally.

**`close_competition(p_competition uuid)`** (new)

Host-only. Sets `status = 'complete'` regardless of outstanding rounds — the
escape hatch for a player who joins and never plays. Standings are already
partial-aware, so a competition closed early reports what actually happened.

**`start_next_round`, `mark_ready`** — untouched, and simply never called in
async mode.

## RLS

One genuinely new problem. Today "the puzzle is hidden until the round starts"
is guaranteed *structurally*: the `competition_rounds` row does not exist until
the host starts the round, so there is nothing to read. In async, player 1
creates round 3's row hours before player 2 gets there, so the row exists and
the current policy would show player 2 a seed they have not started.

That needs a real predicate, in the same shape as `is_competition_member`:

```sql
create or replace function public.has_started_round(p_competition uuid, p_round int)
returns boolean language sql security definer stable set search_path = public
as $$
  select exists (
    select 1 from competition_attempts
    where competition_id = p_competition
      and round_number = p_round
      and user_id = auth.uid()
  );
$$;
```

`competition_rounds` select policy becomes: member **and** (sync mode, where
the existing "row exists means it started" logic holds) **or**
`has_started_round(...)`.

`competition_attempts` gets a members-only select policy via
`is_competition_member`, and no insert/update policy — writes go through
`start_round` only, consistent with every other competition table.

Add `competition_attempts` to the `supabase_realtime` publication. This has
bitten us before: new tables are not in the publication by default and the
failure mode is silent non-delivery, not an error.

## Client

- **`CompetitionRepository`**: `startRound(competitionId, round) -> seed`,
  `closeCompetition(competitionId)`, and `myAttempts(competitionId)`.
- **`competitionViewProvider`**: derive `myRound` from finished results;
  expose `myFinishedRounds` and whether the caller is mid-attempt.
- **Async competition screen**: standings sorted `rounds_played desc, total_ms
  asc`, each row labelled `3/5`, and a single primary button — *Play round N* —
  always available. No ready gate, no host Start, no waiting state.
- **`compete_screen`**: mode choice at creation. Async should probably be the
  default; simultaneous play is the special case, not the norm, for a group of
  friends in different timezones.
- **Game screen**: unchanged apart from sourcing the seed from `start_round`.

## UX risk worth designing around

Partial standings are misleading at a glance: a player one round in has the
lowest total time and will look like they are winning. The sort order handles
correctness, but the screen has to *say* `2/5` prominently next to each time,
or people will read the leaderboard wrong. This is the main design problem in
the feature, and it is a presentation problem rather than a technical one.

A secondary point: with no deadline, a tournament can sit open indefinitely.
The host override covers it, but the competition history list should visually
distinguish "waiting on players" from "finished" so an abandoned one does not
look identical to a live one.

## What this deletes

Async mode has no lobby wait, no ready gate, and no host Start button — which
is precisely where most of this project's bugs have come from (the frozen
lobby, the realtime publication miss, the ready-gate races, the stacked
navigation after rounds). Making async the default retires that whole class of
failure for most games.

## Verification

- Two accounts, async competition: host plays all rounds immediately; second
  player joins afterwards and plays one round at a time, confirming standings
  update and stay correctly ordered throughout.
- A third account joining *after* rounds have been played, confirming late join
  works and starts at round 1.
- Attempt to `start_round` for a round beyond entitlement, confirming the
  server rejects it.
- Direct read of `competition_rounds` for an unstarted round, confirming the
  seed is not visible (the RLS predicate is the one genuinely new security
  boundary here and should be probed anonymously and as a member).
- Host override closing a competition with a player who never played.
- A sync competition run end to end, confirming the mode split did not disturb
  the existing path.
- `flutter analyze` and `flutter test` clean before deploy, as always.
