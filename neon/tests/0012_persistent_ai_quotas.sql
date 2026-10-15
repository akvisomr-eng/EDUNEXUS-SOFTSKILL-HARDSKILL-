-- Manual SQL acceptance test for migration 0012. Run on a disposable branch.
-- Uses synthetic JWT subjects only and cleans up its test rows.
DO $test$
DECLARE
  v_allowed boolean;
  v_minute integer;
  v_day integer;
  i integer;
  v_user uuid;
BEGIN
  v_user := '00000000-0000-4000-8000-000000000001'::uuid;
  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  FOR i IN 1..11 LOOP
    SELECT q.allowed, q.minute_used INTO v_allowed, v_minute
      FROM public.consume_edunexus_ai_quota() AS q;
    IF i <= 10 AND NOT v_allowed THEN RAISE EXCEPTION 'minute quota denied early at %', i; END IF;
    IF i = 11 AND v_allowed THEN RAISE EXCEPTION 'minute quota did not deny request 11'; END IF;
  END LOOP;
  DELETE FROM public.edunexus_ai_usage_limits WHERE user_id = v_user;

  v_user := '00000000-0000-4000-8000-000000000002'::uuid;
  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  FOR i IN 1..101 LOOP
    UPDATE public.edunexus_ai_usage_limits
      SET minute_window = date_trunc('minute', clock_timestamp()) - interval '1 minute'
      WHERE user_id = v_user;
    SELECT q.allowed, q.day_used INTO v_allowed, v_day
      FROM public.consume_edunexus_ai_quota() AS q;
    IF i <= 100 AND NOT v_allowed THEN RAISE EXCEPTION 'daily quota denied early at %', i; END IF;
    IF i = 101 AND v_allowed THEN RAISE EXCEPTION 'daily quota did not deny request 101'; END IF;
  END LOOP;
  DELETE FROM public.edunexus_ai_usage_limits WHERE user_id = v_user;

  IF has_function_privilege('anonymous', 'public.consume_edunexus_ai_quota()', 'EXECUTE') THEN
    RAISE EXCEPTION 'anonymous can execute quota RPC';
  END IF;
  IF NOT has_function_privilege('authenticated', 'public.consume_edunexus_ai_quota()', 'EXECUTE') THEN
    RAISE EXCEPTION 'authenticated cannot execute quota RPC';
  END IF;
  IF has_table_privilege('authenticated', 'public.edunexus_ai_usage_limits', 'SELECT') THEN
    RAISE EXCEPTION 'authenticated can read quota table';
  END IF;
END;
$test$;
