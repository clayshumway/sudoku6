-- Sudoku 6 -- rematches
--
-- A finished competition can spawn one rematch: a new competition with the
-- same tier and round count. The old row points at it via rematch_id, which
-- gives three behaviours for free:
--
--   * anyone looking at the finished competition (from history, or an old
--     tab) sees "a rematch has started" and can join it in one tap;
--   * the ORIGINAL invite link keeps working -- join_competition follows the
--     rematch chain to the newest competition instead of failing with
--     "already finished";
--   * pressing Rematch twice, or two players pressing it at once, converges
--     on one rematch instead of forking (the old row is locked while the
--     first rematch is created).

alter table public.competitions
  add column if not exists rematch_id uuid references public.competitions (id);

create or replace function public.rematch_competition(p_competition uuid)
returns text
language plpgsql security definer set search_path = public
as $fn$
declare
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_old record;
  v_code text;
  v_new  uuid;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;

  -- FOR UPDATE serialises concurrent rematch presses on the same competition.
  select * into v_old from competitions where id = p_competition for update;

  if v_old.id is null then
    raise exception 'no such competition';
  end if;
  if v_old.status <> 'complete' then
    raise exception 'competition is still in progress';
  end if;
  if not exists (
    select 1 from competition_players
    where competition_id = p_competition and user_id = auth.uid()
  ) then
    raise exception 'only players can start a rematch';
  end if;

  -- Second presser joins the first one's rematch rather than forking.
  if v_old.rematch_id is not null then
    return (select code from competitions where id = v_old.rematch_id);
  end if;

  if not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'pick a username first';
  end if;

  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code ||
        substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from competitions where code = v_code);
  end loop;

  insert into competitions (code, host_id, tier, rounds)
  values (v_code, auth.uid(), v_old.tier, v_old.rounds)
  returning id into v_new;

  insert into competition_players (competition_id, user_id)
  values (v_new, auth.uid());

  update competitions set rematch_id = v_new where id = p_competition;

  return v_code;
end;
$fn$;

-- join_competition now follows the rematch chain, so a link shared for the
-- original competition carries newcomers into the latest rematch.
create or replace function public.join_competition(p_code text)
returns uuid
language plpgsql security definer set search_path = public
as $fn$
declare
  v_id      uuid;
  v_status  text;
  v_rematch uuid;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;
  if not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'pick a username first';
  end if;

  select id, status, rematch_id into v_id, v_status, v_rematch
  from competitions where code = upper(p_code);

  if v_id is null then
    raise exception 'no such competition';
  end if;

  -- Bounded walk; a chain deeper than 20 rematches means something is wrong.
  for i in 1..20 loop
    exit when v_status <> 'complete' or v_rematch is null;
    select id, status, rematch_id into v_id, v_status, v_rematch
    from competitions where id = v_rematch;
  end loop;

  if v_status = 'complete' then
    raise exception 'competition already finished';
  end if;

  insert into competition_players (competition_id, user_id)
  values (v_id, auth.uid())
  on conflict do nothing;

  return v_id;
end;
$fn$;
