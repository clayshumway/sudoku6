-- Sudoku 6 -- solves (leaderboards)
--
-- Run in the Supabase SQL Editor.
--
-- No puzzle content is stored: a puzzle is fully reproducible from
-- (tier, seed), so a leaderboard row is ~100 bytes and two players comparing
-- times on "the same puzzle" is enforced by those two columns alone.

create table if not exists public.solves (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  tier        text not null,
  seed        bigint not null,
  elapsed_ms  integer not null,
  mistakes    integer not null default 0,
  hints_used  integer not null default 0,
  completed_at timestamptz not null default now(),

  -- Guards against a client posting a nonsense time to top a board.
  -- Not a substitute for server-authoritative timing (that arrives with
  -- competitions), but it keeps the obviously-impossible out.
  constraint elapsed_sane check (elapsed_ms between 1000 and 86400000),
  constraint counts_sane  check (mistakes >= 0 and hints_used >= 0),

  -- One ranked result per player per puzzle. Replays update the existing row
  -- rather than filling the board with the same name.
  constraint one_solve_per_puzzle unique (user_id, tier, seed)
);

alter table public.solves enable row level security;

-- Leaderboards are public; the table holds no personal data beyond a user id
-- that only resolves to a self-chosen username via public.profiles.
drop policy if exists "solves are readable by everyone" on public.solves;
create policy "solves are readable by everyone"
  on public.solves for select
  using (true);

drop policy if exists "users insert their own solves" on public.solves;
create policy "users insert their own solves"
  on public.solves for insert
  with check (auth.uid() = user_id);

drop policy if exists "users update their own solves" on public.solves;
create policy "users update their own solves"
  on public.solves for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- The leaderboard query is WHERE tier = ? AND seed = ? ORDER BY elapsed_ms.
-- This makes it an index scan instead of a table scan; adding it now is free,
-- adding it later means building an index on a hot table.
create index if not exists solves_board_idx
  on public.solves (tier, seed, elapsed_ms);

-- Supports "my results" / per-player history.
create index if not exists solves_user_idx
  on public.solves (user_id, completed_at desc);
