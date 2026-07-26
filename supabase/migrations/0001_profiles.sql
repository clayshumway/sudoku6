-- Sudoku 6 -- profiles
--
-- Run this in the Supabase SQL Editor (Dashboard -> SQL Editor -> New query).
--
-- The app ships the anon key publicly, so RLS is the only thing standing
-- between a user and someone else's row. Every table gets policies here, at
-- creation time, rather than being retrofitted later.

-- Case-insensitive text, so "Clay" and "clay" can't both be claimed.
create extension if not exists citext;

create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  username   citext not null unique,
  created_at timestamptz not null default now(),

  constraint username_length check (char_length(username) between 3 and 20),
  -- Letters, digits and underscore only: keeps usernames safe to render in
  -- share text and URLs without escaping, and blocks homoglyph impersonation.
  constraint username_format check (username ~ '^[A-Za-z0-9_]+$')
);

alter table public.profiles enable row level security;

-- Public read: leaderboards and competition standings need to resolve a user
-- id to a display name. Only id/username/created_at live here -- email stays
-- in auth.users, which is never client-readable.
drop policy if exists "profiles are readable by everyone" on public.profiles;
create policy "profiles are readable by everyone"
  on public.profiles for select
  using (true);

drop policy if exists "users insert their own profile" on public.profiles;
create policy "users insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "users update their own profile" on public.profiles;
create policy "users update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- No delete policy on purpose: profiles disappear via the cascade from
-- auth.users, so a client can't orphan a username while solves still
-- reference it.

-- Supports the availability check as an index scan rather than a table scan.
create index if not exists profiles_username_idx on public.profiles (username);
