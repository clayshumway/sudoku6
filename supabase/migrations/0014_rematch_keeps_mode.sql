-- Sudoku 6 -- a rematch keeps the mode it came from
--
-- rematch_competition was written in 0009, before async existed. Its insert
-- names only (code, host_id, tier, rounds), so the columns added in 0011 fell
-- to their defaults: mode 'sync' and status 'lobby'. Rematching an async
-- tournament therefore dropped you into a synchronous lobby waiting for
-- players, which is the opposite of what the mode is for.
--
-- Copying mode from the competition being rematched is the actual fix; the
-- status case mirrors create_competition_mode, where async skips the lobby
-- entirely so the initiator can start playing immediately.
--
-- The rest of the function is unchanged from 0009 and reproduced verbatim:
-- chain walking to the newest competition, returning an ongoing rematch's
-- code rather than forking a second one, and the row lock that serialises
-- two players pressing Rematch at the same moment.

create or replace function public.rematch_competition(p_competition uuid)
returns text
language plpgsql security definer set search_path = public
as $fn$
declare
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_tip  record;
  v_code text;
  v_new  uuid;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;
  if not exists (
    select 1 from competition_players
    where competition_id = p_competition and user_id = auth.uid()
  ) then
    raise exception 'only players can start a rematch';
  end if;
  if not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'pick a username first';
  end if;

  select * into v_tip from competitions where id = p_competition;
  if v_tip.id is null then
    raise exception 'no such competition';
  end if;

  -- Walk to the newest competition in the chain (bounded).
  for i in 1..20 loop
    exit when v_tip.rematch_id is null;
    select * into v_tip from competitions where id = v_tip.rematch_id;
  end loop;

  -- The chain already has an ongoing rematch: hand back its code to join.
  if v_tip.status <> 'complete' then
    if v_tip.id = p_competition then
      raise exception 'competition is still in progress';
    end if;
    return v_tip.code;
  end if;

  -- Tip is finished: rematch it. Re-read under lock to serialise concurrent
  -- presses; someone may have extended the chain since the walk above.
  select * into v_tip from competitions where id = v_tip.id for update;
  if v_tip.rematch_id is not null then
    return (select code from competitions where id = v_tip.rematch_id);
  end if;

  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code ||
        substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from competitions where code = v_code);
  end loop;

  -- mode carries across, and async starts active rather than sitting in a
  -- lobby -- the whole point being that you can play your rounds right away.
  insert into competitions (code, host_id, tier, rounds, mode, status)
  values (v_code, auth.uid(), v_tip.tier, v_tip.rounds,
          coalesce(v_tip.mode, 'sync'),
          case when v_tip.mode = 'async' then 'active' else 'lobby' end)
  returning id into v_new;

  insert into competition_players (competition_id, user_id)
  values (v_new, auth.uid());

  update competitions set rematch_id = v_new where id = v_tip.id;

  return v_code;
end;
$fn$;

-- Repair rematches the old function already created.
--
-- Not optional tidying: a competition made by the buggy version is now the tip
-- of its chain, so rematch_competition hands its code back rather than making
-- a new one. Without this, pressing Rematch keeps returning you to the same
-- sync lobby even after the function above is fixed.
--
-- Matched narrowly: only a sync competition whose parent is async, which the
-- UI has no way to produce deliberately. Skipped once anyone has played a
-- round in it, because sync and async measure elapsed time from different
-- places and switching mode underneath a played round would corrupt it.
update public.competitions c
set mode   = 'async',
    status = case when c.status = 'lobby' then 'active' else c.status end
from public.competitions parent
where parent.rematch_id = c.id
  and parent.mode = 'async'
  and c.mode = 'sync'
  and not exists (
    select 1 from public.competition_results r
    where r.competition_id = c.id
  );
