-- Provision the caller's own legacy profile identity for new Neon Auth users.
-- This keeps the existing profiles -> auth.users FK compatible without touching other users.
CREATE OR REPLACE FUNCTION public.ensure_my_profile()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required' USING ERRCODE = '28000';
  END IF;

  -- auth.users is the legacy ID anchor required by the existing profiles FK.
  -- Only the current authenticated ID is inserted; no password or session data is copied.
  INSERT INTO auth.users (id)
  VALUES (v_user_id)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.profiles (id, role)
  VALUES (v_user_id, 'student')
  ON CONFLICT (id) DO NOTHING;

  RETURN v_user_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.ensure_my_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_my_profile() TO authenticated;
