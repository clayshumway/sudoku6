-- Sudoku 6 -- rematch chains + notification bookkeeping
--
-- Scenario this fixes: players 1-3 finish a competition; 1 and 2 rematch and
-- finish that too; player 3 opens the app later. Player 3 must NOT be told to
-- join the (finished) rematch, but must be able to see outcomes and start a
-- fresh rematch of their own.
--
-- rematch_competition therefore walks to the NEWEST competition in the chain:
--   * if that tip is still joinable, it returns the tip's code (the caller
--     joins the ongoing rematch);
--   * if the tip is finished, it creates a rematch OF THE TIP, so chains
--     extend instead of forking.
-- Membership is checked against the competition the caller pressed the button
-- on -- player 3 was never in rematch #1 but was in the original, and that's
-- what makes them part of the group.
--
-- rematch_notified_at supports the email notifier: set once per rematch when
-- invite emails go out, so repeat button presses can't re-spam the group.

alter table public.competitions
  add column if not exists rematch_notified_at timestamptz;

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

  insert into competitions (code, host_id, tier, rounds)
  values (v_code, auth.uid(), v_tip.tier, v_tip.rounds)
  returning id into v_new;

  insert into competition_players (competition_id, user_id)
  values (v_new, auth.uid());

  update competitions set rematch_id = v_new where id = v_tip.id;

  return v_code;
end;
$fn$;
