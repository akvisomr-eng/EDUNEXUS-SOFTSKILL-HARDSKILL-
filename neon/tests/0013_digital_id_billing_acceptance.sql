-- Digital ID billing schema acceptance test.
-- Safe to run read-only on an isolated branch after migration 0013.
DO $$
DECLARE
  t text;
  rls boolean;
  p_count integer;
  auth_select boolean;
  auth_insert boolean;
  auth_update boolean;
  auth_delete boolean;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'id_service_providers','id_service_plans','id_service_subscriptions',
    'id_service_orders','id_service_order_items','id_service_payment_transactions',
    'id_service_cards','id_service_events'
  ] LOOP
    SELECT c.relrowsecurity INTO rls
      FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='public' AND c.relname=t AND c.relkind='r';
    IF rls IS DISTINCT FROM true THEN RAISE EXCEPTION 'RLS is not enabled on %',t; END IF;
    SELECT count(*) INTO p_count FROM pg_policies WHERE schemaname='public' AND tablename=t;
    IF p_count < 1 THEN RAISE EXCEPTION 'No RLS policy found on %',t; END IF;
    EXECUTE format('SELECT has_table_privilege(''authenticated'', %L, ''SELECT'')', 'public.'||t) INTO auth_select;
    EXECUTE format('SELECT has_table_privilege(''authenticated'', %L, ''INSERT'')', 'public.'||t) INTO auth_insert;
    EXECUTE format('SELECT has_table_privilege(''authenticated'', %L, ''UPDATE'')', 'public.'||t) INTO auth_update;
    EXECUTE format('SELECT has_table_privilege(''authenticated'', %L, ''DELETE'')', 'public.'||t) INTO auth_delete;
    IF auth_select IS DISTINCT FROM true THEN RAISE EXCEPTION 'authenticated cannot SELECT %',t; END IF;
    IF auth_insert OR auth_update OR auth_delete THEN RAISE EXCEPTION 'Browser role has direct write privileges on %',t; END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM public.id_service_plans WHERE is_published=true) THEN
    RAISE EXCEPTION 'Unexpected published ID plans in test schema; verify all prices and provider terms before publication';
  END IF;
END $$;
