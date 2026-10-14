-- Allow only the trusted finalizer to set the score on a submitted attempt.
-- Learners still cannot edit an attempt after submission/cancellation.
CREATE OR REPLACE FUNCTION private.enforce_practice_attempt_lifecycle()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status <> 'in_progress' OR NEW.score IS NOT NULL OR NEW.submitted_at IS NOT NULL THEN
      RAISE EXCEPTION 'practice attempt must start in_progress without score';
    END IF;
    RETURN NEW;
  END IF;

  IF current_setting('app.trusted_practice_finalize', true) = 'on' THEN
    IF OLD.status <> 'submitted'
       OR NEW.status <> 'submitted'
       OR OLD.score IS NOT NULL
       OR NEW.score IS NULL
       OR NEW.score < 0
       OR NEW.score > 100
       OR NEW.id IS DISTINCT FROM OLD.id
       OR NEW.session_id IS DISTINCT FROM OLD.session_id
       OR NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.attempt_number IS DISTINCT FROM OLD.attempt_number
       OR NEW.response IS DISTINCT FROM OLD.response
       OR NEW.submitted_at IS DISTINCT FROM OLD.submitted_at
       OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
      RAISE EXCEPTION 'trusted scoring may only add a valid score to a submitted attempt';
    END IF;
    RETURN NEW;
  END IF;

  IF OLD.status <> 'in_progress' THEN
    RAISE EXCEPTION 'practice attempt is immutable after submission or cancellation';
  END IF;

  IF current_user = 'service_role' THEN
    IF NEW.status = 'submitted' THEN
      IF NEW.submitted_at IS NULL OR NEW.score IS NULL OR NEW.score < 0 OR NEW.score > 100 THEN
        RAISE EXCEPTION 'trusted practice completion requires submitted_at and score 0..100';
      END IF;
    ELSIF NEW.status = 'cancelled' THEN
      IF NEW.submitted_at IS NULL OR NEW.score IS NOT NULL THEN
        RAISE EXCEPTION 'invalid trusted practice cancellation';
      END IF;
    ELSIF NEW.status <> 'in_progress' THEN
      RAISE EXCEPTION 'invalid trusted practice attempt transition';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.status = 'in_progress' THEN
    IF NEW.submitted_at IS NOT NULL OR NEW.score IS DISTINCT FROM OLD.score THEN
      RAISE EXCEPTION 'invalid in_progress practice attempt update';
    END IF;
  ELSIF NEW.status IN ('submitted', 'cancelled') THEN
    IF NEW.submitted_at IS NULL OR NEW.score IS DISTINCT FROM OLD.score THEN
      RAISE EXCEPTION 'invalid practice attempt submission state';
    END IF;
  ELSE
    RAISE EXCEPTION 'invalid practice attempt transition';
  END IF;

  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.session_id IS DISTINCT FROM OLD.session_id
     OR NEW.user_id IS DISTINCT FROM OLD.user_id
     OR NEW.attempt_number IS DISTINCT FROM OLD.attempt_number
     OR NEW.created_at IS DISTINCT FROM OLD.created_at
     OR NEW.score IS DISTINCT FROM OLD.score THEN
    RAISE EXCEPTION 'practice attempt protected fields cannot be changed by learner';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.finalize_practice_attempt(p_attempt_id uuid, p_score numeric)
RETURNS public.practice_attempts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $function$
DECLARE
  v_row public.practice_attempts;
BEGIN
  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    RAISE EXCEPTION 'score must be between 0 and 100';
  END IF;

  PERFORM set_config('app.trusted_practice_finalize', 'on', true);
  UPDATE public.practice_attempts
  SET score = round(p_score, 2)
  WHERE id = p_attempt_id
    AND status = 'submitted'
    AND score IS NULL
  RETURNING * INTO v_row;
  PERFORM set_config('app.trusted_practice_finalize', 'off', true);

  IF v_row.id IS NULL THEN
    RAISE EXCEPTION 'practice attempt must be submitted and unscored';
  END IF;
  RETURN v_row;
END;
$function$;
