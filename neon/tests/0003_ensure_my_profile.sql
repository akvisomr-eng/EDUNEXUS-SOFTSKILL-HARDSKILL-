-- Run on a disposable Neon branch after applying 0003_ensure_my_profile.sql.
-- All fixture rows and request claims are rolled back.
BEGIN;
DO $test$
DECLARE
  v_probe uuid := '22222222-2222-4222-8222-222222222222';
  v_actual uuid;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_probe::text, true);
  PERFORM set_config('request.jwt.claims', '', true);

  SELECT public.ensure_my_profile() INTO v_actual;
  IF v_actual IS DISTINCT FROM v_probe THEN
    RAISE EXCEPTION 'ensure_my_profile identity mismatch: expected %, got %', v_probe, v_actual;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_probe) THEN
    RAISE EXCEPTION 'legacy auth.users identity anchor was not created';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_probe AND role = 'student') THEN
    RAISE EXCEPTION 'student profile was not created';
  END IF;
  IF NOT has_function_privilege('authenticated', 'public.ensure_my_profile()', 'EXECUTE') THEN
    RAISE EXCEPTION 'authenticated role must execute ensure_my_profile';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) a
    WHERE p.oid = 'public.ensure_my_profile()'::regprocedure
      AND a.grantee = 0
      AND a.privilege_type = 'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'PUBLIC must not execute ensure_my_profile';
  END IF;
END;
$test$;
ROLLBACK;
