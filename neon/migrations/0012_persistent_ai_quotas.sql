-- Durable EDUNEXUS AI request quotas.
-- Additive migration: fixed per-user caps, enforced through a SECURITY DEFINER RPC.
BEGIN;

CREATE TABLE IF NOT EXISTS public.edunexus_ai_usage_limits (
  user_id uuid PRIMARY KEY,
  minute_window timestamptz NOT NULL,
  minute_count integer NOT NULL DEFAULT 0 CHECK (minute_count BETWEEN 0 AND 11),
  day_window timestamptz NOT NULL,
  day_count integer NOT NULL DEFAULT 0 CHECK (day_count BETWEEN 0 AND 101),
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE public.edunexus_ai_usage_limits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.edunexus_ai_usage_limits FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.consume_edunexus_ai_quota()
RETURNS TABLE (
  allowed boolean,
  minute_used integer,
  day_used integer,
  minute_resets_at timestamptz,
  day_resets_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth, private
AS $function$
DECLARE
  v_user_id uuid;
  v_now timestamptz := clock_timestamp();
  v_minute_window timestamptz;
  v_day_window timestamptz;
  v_minute_count integer;
  v_day_count integer;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required' USING ERRCODE = '28000';
  END IF;

  v_minute_window := date_trunc('minute', v_now);
  v_day_window := date_trunc('day', v_now);

  INSERT INTO public.edunexus_ai_usage_limits AS usage (
    user_id, minute_window, minute_count, day_window, day_count, updated_at
  )
  VALUES (v_user_id, v_minute_window, 1, v_day_window, 1, v_now)
  ON CONFLICT (user_id) DO UPDATE SET
    minute_count = CASE
      WHEN usage.minute_window = EXCLUDED.minute_window
        THEN LEAST(usage.minute_count + 1, 11)
      ELSE 1
    END,
    minute_window = EXCLUDED.minute_window,
    day_count = CASE
      WHEN usage.day_window = EXCLUDED.day_window
        THEN LEAST(usage.day_count + 1, 101)
      ELSE 1
    END,
    day_window = EXCLUDED.day_window,
    updated_at = EXCLUDED.updated_at
  RETURNING usage.minute_count, usage.day_count
    INTO v_minute_count, v_day_count;

  RETURN QUERY SELECT
    (v_minute_count <= 10 AND v_day_count <= 100),
    v_minute_count,
    v_day_count,
    v_minute_window + interval '1 minute',
    v_day_window + interval '1 day';
END;
$function$;

REVOKE ALL ON FUNCTION public.consume_edunexus_ai_quota() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consume_edunexus_ai_quota() TO authenticated;

COMMIT;
