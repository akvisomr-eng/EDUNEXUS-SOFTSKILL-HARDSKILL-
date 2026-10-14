-- Neon Data API RPC for trusted practice finalization.
-- Exposed only to authenticated callers; the caller can finalize only their own submitted attempt.
-- Keep the underlying scoring/evidence functions private and service-role-only.
CREATE OR REPLACE FUNCTION public.finalize_my_practice_attempt(p_attempt_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, auth
AS $function$
DECLARE
  v_user_id uuid;
  v_attempt public.practice_attempts%ROWTYPE;
  v_scenario public.practice_scenarios%ROWTYPE;
  v_total integer;
  v_completed integer;
  v_score numeric;
  v_evidence jsonb;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required' USING ERRCODE = '28000';
  END IF;

  SELECT a.* INTO v_attempt
  FROM public.practice_attempts AS a
  WHERE a.id = p_attempt_id AND a.user_id = v_user_id
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'attempt_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF v_attempt.status <> 'submitted' THEN
    RAISE EXCEPTION 'attempt_must_be_submitted' USING ERRCODE = '55000';
  END IF;

  SELECT s.* INTO v_scenario
  FROM public.practice_sessions AS ps
  JOIN public.practice_scenarios AS s ON s.id = ps.scenario_id
  WHERE ps.id = v_attempt.session_id AND ps.user_id = v_user_id
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'scenario_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF v_attempt.score IS NULL THEN
    SELECT count(*),
           count(*) FILTER (
             WHERE jsonb_typeof(v_attempt.response -> (field ->> 'key')) = 'string'
               AND length(btrim(v_attempt.response ->> (field ->> 'key'))) >= 12
           )
      INTO v_total, v_completed
    FROM jsonb_array_elements(
      COALESCE(v_scenario.instructions -> 'response_fields', '[]'::jsonb)
    ) AS field;

    v_score := CASE WHEN v_total = 0 THEN 0
                    ELSE round((v_completed::numeric / v_total::numeric) * 100, 2)
               END;
    PERFORM private.finalize_practice_attempt(v_attempt.id, v_score);
  END IF;

  PERFORM private.ingest_practice_evidence(v_attempt.id);

  UPDATE public.practice_sessions
  SET status = 'completed',
      completed_at = COALESCE(completed_at, now()),
      submitted_at = COALESCE(submitted_at, now())
  WHERE id = v_attempt.session_id
    AND user_id = v_user_id
    AND status = 'submitted';

  SELECT COALESCE(
    jsonb_agg(jsonb_build_object(
      'id', e.id,
      'skill_id', e.skill_id,
      'score', e.score,
      'status', e.status,
      'summary', e.summary
    ) ORDER BY e.created_at),
    '[]'::jsonb
  ) INTO v_evidence
  FROM public.skill_evidence AS e
  WHERE e.source_id = v_attempt.id AND e.source_type = 'practice_attempt';

  RETURN jsonb_build_object(
    'status', 'completed',
    'score', COALESCE(v_attempt.score, v_score),
    'evidence', v_evidence,
    'review_status', CASE WHEN jsonb_array_length(v_evidence) > 0
                          THEN 'pending_mentor_review'
                          ELSE 'no_evidence_generated' END,
    'mastery_updated', false,
    'note', 'Practice evidence is a candidate until an authorized mentor verifies it.'
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.finalize_my_practice_attempt(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.finalize_my_practice_attempt(uuid) TO authenticated;
