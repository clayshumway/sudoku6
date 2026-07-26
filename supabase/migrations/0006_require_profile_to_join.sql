-- Fix: joining an invite as a brand-new user failed with
--   insert or update on "competition_players" violates foreign key
--   constraint "competition_players_user_id_fkey"
--
-- competition_players.user_id references profiles(id), but a user can be
-- signed in without having claimed a username yet -- which is exactly what
-- happens when someone follows an invite link, signs up, and is auto-joined
-- before ever seeing the username screen.
--
-- The client now routes them through username selection first. These guards
-- make the failure legible if it ever happens anyway: a raw FK violation
-- tells the user nothing they can act on.

create or replace function public.join_competition(p_code text)
returns uuid
language plpgsql security definer set search_path = public
as $fn$
declare
  v_id     uuid;
  v_status text;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
  end if;
  if not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'pick a username first';
  end if;

  select id, status into v_id, v_status
  from competitions where code = upper(p_code);

  if v_id is null then
    raise exception 'no such competition';
  end if;
  if v_status = 'complete' then
    raise exception 'competition already finished';
  end if;

  insert into competition_players (competition_id, user_id)
  values (v_id, auth.uid())
  on conflict do nothing;

  return v_id;
end;
$fn$;

-- Same exposure on the create path: the host is also inserted as a player.
create or replace function public.create_competition(p_tier text, p_rounds int)
returns text
language plpgsql security definer set search_path = public
as $fn$
declare
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_code text;
  v_id   uuid;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
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
  values (v_code, auth.uid(), p_tier, p_rounds)
  returning id into v_id;

  insert into competition_players (competition_id, user_id)
  values (v_id, auth.uid());

  return v_code;
end;
$fn$;
