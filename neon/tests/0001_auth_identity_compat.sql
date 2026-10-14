-- Run on a disposable Neon branch after applying 0001_auth_identity_compat.sql.
-- This script does not write business rows and rolls back all session-local test state.
BEGIN;
DO $test$
DECLARE
  v_neon_user uuid;
  v_legacy_user uuid;
  v_probe uuid := '11111111-1111-4111-8111-111111111111';
  v_actual uuid;
BEGIN
  SELECT neon_auth_user_id, source_user_id
    INTO v_neon_user, v_legacy_user
    FROM private.supabase_identity_migration
    ORDER BY neon_auth_user_id
    LIMIT 1;

  IF v_neon_user IS NULL OR v_legacy_user IS NULL THEN
    RAISE EXCEPTION 'identity mapping fixture is missing';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_neon_user::text, true);
  SELECT auth.uid() INTO v_actual;
  IF v_actual IS DISTINCT FROM v_legacy_user THEN
    RAISE EXCEPTION 'mapped identity mismatch: expected %, got %', v_legacy_user, v_actual;
  END IF;

  -- Neon Data API may expose JWT claims as a JSON object rather than an individual sub setting.
  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_neon_user)::text, true);
  SELECT auth.uid() INTO v_actual;
  IF v_actual IS DISTINCT FROM v_legacy_user THEN
    RAISE EXCEPTION 'JSON claims mapped identity mismatch: expected %, got %', v_legacy_user, v_actual;
  END IF;

  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_probe)::text, true);
  SELECT auth.uid() INTO v_actual;
  IF v_actual IS DISTINCT FROM v_probe THEN
    RAISE EXCEPTION 'JSON claims fallback mismatch: expected %, got %', v_probe, v_actual;
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_probe::text, true);
  SELECT auth.uid() INTO v_actual;
  IF v_actual IS DISTINCT FROM v_probe THEN
    RAISE EXCEPTION 'unmapped subject fallback mismatch: expected %, got %', v_probe, v_actual;
  END IF;

  IF NOT has_function_privilege('authenticated', 'public.current_user_id()', 'EXECUTE') THEN
    RAISE EXCEPTION 'authenticated role must be able to execute current_user_id';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) a
    WHERE p.oid = 'public.current_user_id()'::regprocedure
      AND a.grantee = 0
      AND a.privilege_type = 'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'PUBLIC must not be able to execute current_user_id';
  END IF;
END;
$test$;
ROLLBACK;
