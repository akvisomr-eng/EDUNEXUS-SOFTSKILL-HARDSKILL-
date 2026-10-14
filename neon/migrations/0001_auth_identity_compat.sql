-- Neon Auth compatibility for legacy EDUNEXUS business rows.
-- Apply only to the Neon production database after reviewing and testing on a clone.
-- This does not alter or delete business rows. It translates Neon Auth subject IDs
-- to the existing Supabase user IDs used by user-owned business records.

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
  WITH jwt_identity AS (
    SELECT COALESCE(
      NULLIF(current_setting('request.jwt.claim.sub', true), ''),
      NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
    ) AS subject
  )
  SELECT COALESCE(
    (
      SELECT m.source_user_id
      FROM private.supabase_identity_migration AS m
      CROSS JOIN jwt_identity AS j
      WHERE m.neon_auth_user_id = NULLIF(j.subject, '')::uuid
    ),
    (SELECT NULLIF(subject, '')::uuid FROM jwt_identity)
  );
$function$;

-- The browser may ask for its mapped business-user ID, but cannot choose another ID.
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
  SELECT auth.uid();
$function$;

REVOKE ALL ON FUNCTION public.current_user_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_id() TO authenticated;
