-- Draft 0013: Digital Student ID OS subscription foundation. Test on isolated Neon branch first.
-- No payment gateway/API is enabled by this schema.
BEGIN;
CREATE TABLE IF NOT EXISTS public.id_service_providers (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), provider_key text NOT NULL UNIQUE, display_name text NOT NULL,
 integration_status text NOT NULL DEFAULT 'planned' CHECK (integration_status IN ('planned','sandbox','active','paused','retired')),
 public_app_url text, api_base_url text, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.id_service_plans (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), provider_id uuid NOT NULL REFERENCES public.id_service_providers(id),
 plan_key text NOT NULL, display_name text NOT NULL, recipient_type text NOT NULL CHECK (recipient_type IN ('student','mentor','staff','institution')),
 currency char(3) NOT NULL DEFAULT 'IDR', amount_minor bigint CHECK (amount_minor IS NULL OR amount_minor>=0),
 billing_interval text NOT NULL DEFAULT 'month' CHECK (billing_interval IN ('month','year','one_time')),
 card_quota integer CHECK (card_quota IS NULL OR card_quota>0), is_published boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(provider_id,plan_key)
);
CREATE TABLE IF NOT EXISTS public.id_service_subscriptions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), customer_user_id uuid NOT NULL REFERENCES public.profiles(id),
 institution_id uuid REFERENCES public.institutions(id), plan_id uuid NOT NULL REFERENCES public.id_service_plans(id),
 status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','awaiting_payment','active','past_due','cancelled','expired','suspended')),
 quantity integer NOT NULL DEFAULT 1 CHECK (quantity>0), currency char(3) NOT NULL DEFAULT 'IDR',
 unit_amount_minor bigint CHECK (unit_amount_minor IS NULL OR unit_amount_minor>=0),
 current_period_start timestamptz, current_period_end timestamptz, cancel_at_period_end boolean NOT NULL DEFAULT false,
 provider_subscription_ref text, metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_id_subscriptions_customer_status ON public.id_service_subscriptions(customer_user_id,status);
CREATE TABLE IF NOT EXISTS public.id_service_orders (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_number text NOT NULL UNIQUE,
 customer_user_id uuid NOT NULL REFERENCES public.profiles(id), institution_id uuid REFERENCES public.institutions(id),
 status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','pending_payment','paid','fulfillment_pending','fulfilled','payment_failed','cancelled','refunded','partially_refunded')),
 currency char(3) NOT NULL DEFAULT 'IDR', subtotal_minor bigint NOT NULL DEFAULT 0 CHECK (subtotal_minor>=0),
 discount_minor bigint NOT NULL DEFAULT 0 CHECK (discount_minor>=0), tax_minor bigint NOT NULL DEFAULT 0 CHECK (tax_minor>=0),
 total_minor bigint NOT NULL DEFAULT 0 CHECK (total_minor>=0), idempotency_key text NOT NULL UNIQUE,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.id_service_order_items (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_id uuid NOT NULL REFERENCES public.id_service_orders(id) ON DELETE CASCADE,
 plan_id uuid NOT NULL REFERENCES public.id_service_plans(id), recipient_type text NOT NULL CHECK (recipient_type IN ('student','mentor','staff','institution')),
 quantity integer NOT NULL CHECK (quantity>0), unit_amount_minor bigint NOT NULL CHECK (unit_amount_minor>=0),
 line_total_minor bigint NOT NULL CHECK (line_total_minor>=0), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.id_service_payment_transactions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_id uuid NOT NULL REFERENCES public.id_service_orders(id),
 customer_user_id uuid NOT NULL REFERENCES public.profiles(id), payment_provider text NOT NULL, provider_transaction_ref text,
 status text NOT NULL DEFAULT 'created' CHECK (status IN ('created','pending','succeeded','failed','cancelled','refunded','partially_refunded')),
 currency char(3) NOT NULL DEFAULT 'IDR', amount_minor bigint NOT NULL CHECK (amount_minor>=0), idempotency_key text NOT NULL UNIQUE,
 verified_at timestamptz, provider_payload_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(payment_provider,provider_transaction_ref)
);
CREATE TABLE IF NOT EXISTS public.id_service_cards (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), customer_user_id uuid NOT NULL REFERENCES public.profiles(id),
 recipient_user_id uuid REFERENCES public.profiles(id), institution_id uuid REFERENCES public.institutions(id),
 subscription_id uuid REFERENCES public.id_service_subscriptions(id), provider_id uuid NOT NULL REFERENCES public.id_service_providers(id),
 recipient_type text NOT NULL CHECK (recipient_type IN ('student','mentor','staff')), provider_card_ref text,
 status text NOT NULL DEFAULT 'not_requested' CHECK (status IN ('not_requested','requested','pending','issued','active','suspended','revoked','expired','failed')),
 issued_at timestamptz, expires_at timestamptz, last_provider_sync_at timestamptz, metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(provider_id,provider_card_ref)
);
CREATE TABLE IF NOT EXISTS public.id_service_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), event_source text NOT NULL, event_type text NOT NULL, external_event_ref text,
 order_id uuid REFERENCES public.id_service_orders(id), subscription_id uuid REFERENCES public.id_service_subscriptions(id),
 card_id uuid REFERENCES public.id_service_cards(id), processing_status text NOT NULL DEFAULT 'received' CHECK (processing_status IN ('received','processed','ignored','failed')),
 payload_redacted jsonb NOT NULL DEFAULT '{}'::jsonb, received_at timestamptz NOT NULL DEFAULT now(), processed_at timestamptz,
 UNIQUE(event_source,external_event_ref)
);
CREATE INDEX IF NOT EXISTS idx_id_subscriptions_institution ON public.id_service_subscriptions(institution_id,status);
CREATE INDEX IF NOT EXISTS idx_id_orders_customer_created ON public.id_service_orders(customer_user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_id_cards_recipient_status ON public.id_service_cards(recipient_user_id,status);
CREATE INDEX IF NOT EXISTS idx_id_cards_institution_status ON public.id_service_cards(institution_id,status);
CREATE INDEX IF NOT EXISTS idx_id_service_events_status_received ON public.id_service_events(processing_status,received_at);
ALTER TABLE public.id_service_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.id_service_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.id_service_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.id_service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.id_service_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.id_service_payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.id_service_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.id_service_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY id_service_providers_read ON public.id_service_providers FOR SELECT TO authenticated USING (integration_status IN ('sandbox','active'));
CREATE POLICY id_service_plans_read ON public.id_service_plans FOR SELECT TO authenticated USING (is_published=true);
CREATE POLICY id_service_subscriptions_read ON public.id_service_subscriptions FOR SELECT TO authenticated USING (customer_user_id=auth.uid() OR (institution_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.institution_memberships m WHERE m.institution_id=id_service_subscriptions.institution_id AND m.user_id=auth.uid() AND m.status='active' AND m.membership_role IN ('admin','staff'))));
CREATE POLICY id_service_orders_read ON public.id_service_orders FOR SELECT TO authenticated USING (customer_user_id=auth.uid() OR (institution_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.institution_memberships m WHERE m.institution_id=id_service_orders.institution_id AND m.user_id=auth.uid() AND m.status='active' AND m.membership_role IN ('admin','staff'))));
CREATE POLICY id_service_order_items_read ON public.id_service_order_items FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.id_service_orders o WHERE o.id=id_service_order_items.order_id AND (o.customer_user_id=auth.uid() OR (o.institution_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.institution_memberships m WHERE m.institution_id=o.institution_id AND m.user_id=auth.uid() AND m.status='active' AND m.membership_role IN ('admin','staff'))))));
CREATE POLICY id_service_payment_transactions_read ON public.id_service_payment_transactions FOR SELECT TO authenticated USING (customer_user_id=auth.uid() OR EXISTS (SELECT 1 FROM public.id_service_orders o JOIN public.institution_memberships m ON m.institution_id=o.institution_id WHERE o.id=id_service_payment_transactions.order_id AND m.user_id=auth.uid() AND m.status='active' AND m.membership_role IN ('admin','staff')));
CREATE POLICY id_service_cards_read ON public.id_service_cards FOR SELECT TO authenticated USING (customer_user_id=auth.uid() OR recipient_user_id=auth.uid() OR (institution_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.institution_memberships m WHERE m.institution_id=id_service_cards.institution_id AND m.user_id=auth.uid() AND m.status='active' AND m.membership_role IN ('admin','staff'))));
CREATE POLICY id_service_events_read ON public.id_service_events FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.id_service_orders o WHERE o.id=id_service_events.order_id AND o.customer_user_id=auth.uid()) OR EXISTS (SELECT 1 FROM public.id_service_subscriptions s WHERE s.id=id_service_events.subscription_id AND s.customer_user_id=auth.uid()));
REVOKE ALL PRIVILEGES ON public.id_service_providers,public.id_service_plans,public.id_service_subscriptions,public.id_service_orders,public.id_service_order_items,public.id_service_payment_transactions,public.id_service_cards,public.id_service_events FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.id_service_providers,public.id_service_plans,public.id_service_subscriptions,public.id_service_orders,public.id_service_order_items,public.id_service_payment_transactions,public.id_service_cards,public.id_service_events TO authenticated;
COMMIT;
