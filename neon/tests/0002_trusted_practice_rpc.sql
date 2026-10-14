-- Non-destructive structural and permission checks; run on a disposable Neon branch.
DO $test$
DECLARE v_oid oid;
BEGIN
 SELECT p.oid INTO v_oid FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.proname='finalize_my_practice_attempt' AND p.prosecdef;
 IF v_oid IS NULL THEN RAISE EXCEPTION 'trusted finalization RPC must exist as SECURITY DEFINER'; END IF;
 IF NOT has_function_privilege('authenticated',v_oid,'EXECUTE') THEN RAISE EXCEPTION 'authenticated execute grant missing'; END IF;
 IF EXISTS (
   SELECT 1 FROM aclexplode(COALESCE((SELECT proacl FROM pg_proc WHERE oid=v_oid),
     acldefault('f',(SELECT proowner FROM pg_proc WHERE oid=v_oid)))) a
   WHERE a.grantee=0 AND a.privilege_type='EXECUTE'
 ) THEN RAISE EXCEPTION 'PUBLIC execute must be revoked'; END IF;
END;
$test$;
