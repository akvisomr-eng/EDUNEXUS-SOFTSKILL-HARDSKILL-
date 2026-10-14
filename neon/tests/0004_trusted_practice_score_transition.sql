-- Run on a disposable Neon branch after applying 0004_trusted_practice_score_transition.sql.
-- The fixture rows are rolled back.
BEGIN;
DO $test$
DECLARE
  v_user uuid := '33333333-3333-4333-8333-333333333333';
  v_scenario uuid;
  v_session uuid;
  v_attempt uuid;
  v_row public.practice_attempts;
  v_blocked boolean := false;
BEGIN
  SELECT id INTO v_scenario FROM public.practice_scenarios WHERE status='active' ORDER BY created_at LIMIT 1;
  IF v_scenario IS NULL THEN RAISE EXCEPTION 'active practice scenario fixture missing'; END IF;

  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  PERFORM set_config('request.jwt.claims', '', true);
  INSERT INTO auth.users(id) VALUES (v_user) ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.profiles(id, role) VALUES (v_user, 'student') ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.practice_sessions(user_id, scenario_id, status, attempt_number, metadata)
  VALUES (v_user, v_scenario, 'in_progress', 1, '{"source":"sql-lifecycle-test"}'::jsonb)
  RETURNING id INTO v_session;

  INSERT INTO public.practice_attempts(session_id, user_id, attempt_number, status, response)
  VALUES (v_session, v_user, 1, 'in_progress', '{"question":"A valid response long enough for a score"}'::jsonb)
  RETURNING id INTO v_attempt;

  UPDATE public.practice_attempts
  SET status='submitted', submitted_at=now()
  WHERE id=v_attempt;
  UPDATE public.practice_sessions
  SET status='submitted', submitted_at=now()
  WHERE id=v_session;

  SELECT private.finalize_practice_attempt(v_attempt, 85) INTO v_row;
  IF v_row.score IS DISTINCT FROM 85::numeric THEN
    RAISE EXCEPTION 'trusted finalizer failed to assign score: %', v_row.score;
  END IF;

  BEGIN
    UPDATE public.practice_attempts
    SET response='{"question":"tampered after submission"}'::jsonb
    WHERE id=v_attempt;
  EXCEPTION WHEN OTHERS THEN
    v_blocked := position('immutable after submission' in SQLERRM) > 0;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'learner edit after submission was not blocked';
  END IF;
END;
$test$;
ROLLBACK;
