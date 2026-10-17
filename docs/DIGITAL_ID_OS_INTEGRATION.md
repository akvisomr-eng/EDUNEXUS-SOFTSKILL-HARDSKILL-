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
Migration draft 0012 defines provider, plan, subscription, order, order item, payment transaction, card registry and event tables. It is intentionally not applied to production. Test on an isolated Neon branch, inspect policy dependencies, verify with two real test accounts and RLS, then follow the existing production DB promotion gate.

Browser roles are read-only. Writes must use a trusted server/function. Never store payment-card data, bearer tokens, API keys, raw webhook secrets or unnecessary identity documents. Store redacted provider event payloads and external references only. Require signature verification, idempotency, audit trails, least privilege and data minimization.

## Commercial gates
- Student ID OS is not live; its public URL is a static preview.
- Provider API documentation, API host, auth, webhook contract, SLA, supported card types, QR verification and issuance quota are unverified.
- Reseller permission, license cost, customer price, refund/renewal terms, taxes and support responsibility are unset.
- No payment gateway is selected/configured; no payment has been taken.
- Privacy notice, retention schedule, consent and data-processing terms must cover the external provider.
- Public launch remains blocked until integration, security, payment, RLS, accessibility, reconciliation and failure-path tests pass.

The web/id-services/index.html page is a preparation UI: checkout is disabled and it invents no prices, transactions, issued cards or QR verification.
