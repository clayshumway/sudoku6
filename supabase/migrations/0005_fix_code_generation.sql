-- Fix: create_competition failed with
--   "function gen_random_bytes(integer) does not exist"
--
-- gen_random_bytes lives in pgcrypto, which Supabase installs into the
-- `extensions` schema. The function pins `search_path = public` (correct, for
-- SECURITY DEFINER safety), so the extension isn't visible.
--
-- Rather than widen search_path or depend on an extension, build the code
-- from an explicit alphabet. That also fixes a second problem with the old
-- version: it could still emit look-alike characters, so a code read off a
-- screen or out loud could be mistyped.
--
-- Note this code is not a secret -- it's an invite, and anyone holding it is
-- meant to be able to join. It only needs to be unguessable enough to avoid
-- collisions and accidental joins: 31^6 is ~887 million.

create or replace function public.create_competition(p_tier text, p_rounds int)
returns text
language plpgsql security definer set search_path = public
as $$
declare
  -- No I, L, O, 0 or 1: the pairs people most often confuse.
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_code text;
  v_id   uuid;
begin
  if auth.uid() is null then
    raise exception 'must be signed in';
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
$$;
