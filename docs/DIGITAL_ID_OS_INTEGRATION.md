# Digital Student ID OS — EDUNEXUS Integration Plan

Status: implementation foundation, not production billing. Updated 2026-10-17.

## Business model
EDUNEXUS is the customer-facing hub for browsing Digital Student ID OS, selecting recipients (students, mentors, staff), managing subscription terms, invoices, payment status, card issuance status, and financial reporting. Digital Student ID OS remains the external card service provider.

Validate the preferred reseller/bundled model with the provider first. EDUNEXUS may resell or bundle access only after written reseller/white-label/API permission. Track provider license expense separately from EDUNEXUS customer revenue. If resale is not permitted, connect a customer-owned provider subscription instead.

## Menu map
- Layanan Digital/Katalog: plan, audience, quota, currency, price, terms and provider state.
- Langganan & Tagihan: subscription period, invoice, status, renewal and cancellation.
- Manajemen Kartu: recipient, institution, provider card reference, issue/expiry/status.
- Transaksi: payment attempts, provider references, verification and refunds.
- Keuangan & Laporan: customer receipts, provider license costs, fees, refunds, reconciliation and margin.
- Profiles/institution memberships: link each card to its recipient, not only the payer.

One canonical order/payment record feeds all views. Do not duplicate transactions just because they appear in several menus.

## End-to-end state machine
1. Select a published plan and authorized recipients.
2. Server validates plan, institution membership, recipient scope, price and quota.
3. Server creates an idempotent order/invoice; never trust client totals.
4. Payment provider creates checkout session. No gateway is configured now.
5. Server verifies a signed webhook or polls the provider; browser redirect is not payment proof.
6. Only verified payment activates subscription/entitlement.
7. Authenticated server adapter requests card issuance using documented Student ID OS API.
8. Provider response updates the card registry; retries are idempotent and events audited.
9. Reconciliation compares orders/payments/subscriptions with provider statements.
10. Renewal/cancel/refund updates entitlement and card state according to signed terms.

## Data and security
Migration draft 0013 defines provider, plan, subscription, order, order item, payment transaction, card registry and event tables. It is intentionally not applied to production. Test on an isolated Neon branch, inspect policy dependencies, verify with two real test accounts and RLS, then follow the existing production DB promotion gate.

Browser roles are read-only. Writes must use a trusted server/function. Never store payment-card data, bearer tokens, API keys, raw webhook secrets or unnecessary identity documents. Store redacted provider event payloads and external references only. Require signature verification, idempotency, audit trails, least privilege and data minimization.

## Commercial gates
- Student ID OS is not live; its public URL is a static preview.
- Provider API documentation, API host, auth, webhook contract, SLA, supported card types, QR verification and issuance quota are unverified.
- Reseller permission, license cost, customer price, refund/renewal terms, taxes and support responsibility are unset.
- No payment gateway is selected/configured; no payment has been taken.
- Privacy notice, retention schedule, consent and data-processing terms must cover the external provider.
- Public launch remains blocked until integration, security, payment, RLS, accessibility, reconciliation and failure-path tests pass.

The web/id-services/index.html page is a preparation UI: checkout is disabled and it invents no prices, transactions, issued cards or QR verification.

## Payment provider selection (research snapshot: 2026-10-17)

The gateway is deliberately not configured. Official pricing pages indicate no standard monthly integration subscription for these gateway offerings, but successful payments incur transaction fees; exact rates and tax treatment depend on payment method and business category.

- Midtrans official pricing: https://midtrans.com/id/biaya
- Xendit official pricing: https://www.xendit.co/id/biaya

Do not choose solely from headline fees. Confirm merchant eligibility, digital-goods pricing, settlement, refund/chargeback terms, taxes, webhook signatures, subscription/recurring-payment support, and account activation. For the Rp0-first plan, keep checkout disabled until a merchant account is approved and production credentials are configured server-side. No credentials belong in source control, browser code, or chat.

## Automated schema acceptance

`neon/tests/0013_digital_id_billing_acceptance.sql` verifies the eight service tables have RLS, at least one policy, authenticated SELECT access, no direct authenticated writes, and no accidentally published plans. Run only after migration 0013 on an isolated Neon branch. It does not substitute for two-account tenant-isolation, payment-webhook, provider API, or card-issuance tests.

## Recommended payment-gateway candidate

**Midtrans is the first candidate to evaluate**, not yet an active integration. Its official docs describe subscription/recurring APIs, while recurring capability requires eligible payment channels and additional activation/agreements in some cases. Official sources:
- Pricing: https://midtrans.com/id/biaya
- Subscription API: https://docs.midtrans.com/reference/create-subscription
- Recurring activation caveat: https://docs.midtrans.com/docs/coreapi-advanced-features

Keep ordinary one-time checkout and automatic recurring billing as separate release gates. Do not advertise automatic renewal until Midtrans confirms the merchant account and recurring MID/channel eligibility, and sandbox webhook/renewal/cancellation/refund tests pass. Published prices can vary for digital products and merchant categories; confirm the actual contracted rates before setting customer prices.
