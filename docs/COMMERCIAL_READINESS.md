# EDUNEXUS — Commercial Readiness & Launch Gate

**Document status:** internal release-control checklist, 15 October 2026  
**Release status:** NOT READY for paid public launch until every P0 gate is evidenced.  
**Operating principle:** do not sell roadmap items as available features.

## 1. What can be described today

Based on repository checks and the current deployment configuration, EDUNEXUS is a web learning and skills-development prototype with Neon authentication, profile initialization, practice scenarios, submission/finalization flow, and practice history. The site and automated browser smoke workflow are available.

The current implementation does **not** establish that all LMS, AI tutoring, multi-agent project execution, institutional administration, certificates, payment processing, or automated repository changes are production-ready. Model inference is not configured in the production function at the last verified check. Project Builder is planning-only and must fail closed without model credentials.

## 2. P0 — release blockers

A paid launch is blocked until the owner records evidence for each item below.

- [ ] **AI inference:** configure a legitimate model provider key as a server-side Neon Function secret; test a real authenticated request end-to-end; verify provider model ID, timeout, rate limits, error behavior, and no secret leakage.
- [ ] **Commercial cost control:** define per-account request caps, token/usage ceilings, provider spend alerts, abuse response, and an emergency disable switch. The Neon Data API RPC `consume_edunexus_ai_quota()` now enforces a persistent per-user cap of 10 requests/minute and 100/day; direct table access is revoked and the RPC is executable only by `authenticated`. Runtime fails closed if quota service is unavailable. The bounded in-memory limiter remains defense-in-depth. Provider token/spend ceilings and provider-side spend alerts are still required before paid access.
- [ ] **Privacy & data lifecycle:** publish reviewed privacy notice and terms; identify data controller/operator, contact, purposes, retention, deletion request route, processor/subprocessor list, cross-border handling, and treatment of minors before onboarding real users.
- [ ] **Tenant isolation:** test every user-owned read/write path with two separate real accounts. Re-check Neon Auth subject mapping, RLS, and privileged function boundaries.
- [ ] **Production data:** confirm migration history, backup/restore procedure, rollback plan, and data ownership. Do not promote Project Builder migration 0011 until JWT identity mapping and tenant isolation are verified on a preview branch.
- [ ] **Security:** scan dependencies and secrets; test CORS, CSRF-relevant flows, XSS/input handling, authorization, account recovery, abuse/rate limits, and auditability. No production penetration test is claimed by this document.
- [ ] **User support:** publish support contact, incident intake process, response expectations, account deletion route, and status/maintenance communications.
- [ ] **Commercial operations:** confirm legal business identity, invoice/tax handling, refund/cancellation policy, and payment method before charging customers. No payment gateway is currently claimed.
- [ ] **Accessibility & device checks:** test keyboard navigation, visible focus, labels, contrast, mobile viewport, and supported browsers with recorded results.
- [ ] **Content rights:** retain provenance/license for course material, use original summaries, honor source terms, and provide correction/removal process.
- [ ] **Acceptance sign-off:** product owner signs a dated release checklist with links to CI, smoke tests, live health, and end-to-end evidence.

## 3. Release stages

### Stage A — Internal technical preview
Allowed: internal accounts, non-sensitive sample data, practice-flow evaluation, and clearly labeled experimental AI tests.
Not allowed: promise of complete AI features, certification outcomes, enterprise-grade SLA, or paid access.

### Stage B — Invited pilot
Requires: P0 security, real inference, cost limits, privacy/terms review, support route, and a small number of invited testers. Collect only necessary data. Have a written rollback and feedback process.

### Stage C — Paid public release
Requires: all P0 items complete, legal/commercial identity and billing process confirmed, cancellation/refund policy published, usage limits enforced server-side, tested deletion/export workflows, monitoring and incident response, and owner sign-off.

## 4. Suggested initial packaging (hypothesis, not a published offer)

Keep the first offer narrow and avoid unlimited AI usage.

| Package | Audience | Scope | Commercial rule |
|---|---|---|---|
| Demo | Public visitors | Public catalog and sample practice | No account data beyond essential operation |
| Pilot | Invited individuals | Practice flows and limited AI access after activation | Fixed pilot period and explicit usage cap |
| Personal | Individual learners | Learning plan, practice history, AI assistance with quota | Monthly quota; no unlimited inference |
| Team / Institution | Organizations | Only features demonstrated and accepted | Quote after tenant isolation, admin controls, support and privacy requirements pass |

Prices should be set only after measuring actual provider costs, expected usage, taxes, payment fees, support workload, and target margin. Do not advertise pricing or an SLA until the owner approves the exact offer.

## 5. Launch evidence register

For every checkbox, record: evidence URL or run ID, date, tested environment, result, known limitations, and reviewer. “Workflow green” proves only the checks that workflow actually runs; it does not prove payment readiness, legal compliance, provider reliability, or security certification.

### Verified in the repository as of 15 October 2026

- Source and workflow changes are committed to the repository. Current source includes a persistent per-user quota RPC, a fail-closed runtime client, and an emergency inference disable switch.
- Production Neon Function `edunexusai` is active on deployment #10; preview is active on deployment #16. Both report `status: ok`, 51 curated knowledge chunks, and `persistentQuotaConfigured: true`. Both report `inferenceConfigured: false` and `projectExecutionConfigured: false`.
- Runtime Health run `38692369802`: success — https://github.com/akvisomr-eng/EDUNEXUS-SOFTSKILL-HARDSKILL-/actions/runs/38692369802
- EDUNEXUS CI run `38692369524`: success — https://github.com/akvisomr-eng/EDUNEXUS-SOFTSKILL-HARDSKILL-/actions/runs/38692369524
- Browser smoke run `38692230916`: success — https://github.com/akvisomr-eng/EDUNEXUS-SOFTSKILL-HARDSKILL-/actions/runs/38692230916. It exercised a real Neon Auth JWT, profile provisioning, quota RPC, catalog retrieval, practice finalization, candidate evidence, and cross-account isolation for practice sessions. It also called the deployed AI runtime in curated-retrieval mode and received HTTP 200.
- Migration `0012_persistent_ai_quotas.sql` has been applied on production and preview. SQL boundary tests passed for 10 requests/minute and 100/day per application identity. Direct table access is revoked; the RPC is executable by `authenticated` only.
- The `AI_ENABLED=false` emergency inference switch is covered by a runtime unit test. Provider inference remains disabled by missing `MODEL_API_KEY`; no live generative model call is claimed.
- Website deploy run `38691681331` and live Pages verification run `38691681297` both succeeded — https://github.com/akvisomr-eng/EDUNEXUS-SOFTSKILL-HARDSKILL-/actions/runs/38691681331 and https://github.com/akvisomr-eng/EDUNEXUS-SOFTSKILL-HARDSKILL-/actions/runs/38691681297.
- Project Builder migration `0011_project_builder_records.sql` remains preview-only. Its five tables have owner-scoped SELECT policies, but the required dedicated two-account isolation test for those tables has not been recorded. Do not promote it yet.

## 6. Immediate next actions

1. Owner configures a legitimate model-provider API key privately in Neon and confirms the exact provider base URL/model ID. Do not place the key in GitHub source, frontend code, logs, or chat.
2. Test one real authenticated tutor request and one Project Builder planning request after inference is configured; retain redacted evidence and check the emergency disable switch.
3. Configure provider-side spend alerts and any available token/budget ceilings; measure real costs before approving prices.
4. Complete legal operator/contact details, reviewed privacy notice and terms, retention/deletion procedures, support and incident intake.
5. Test Project Builder table isolation with two distinct authorized accounts on preview; keep migration 0011 blocked until evidence is recorded. Complete mobile/accessibility checks and backup/restore rehearsal.
6. Confirm billing, invoice/tax, refund/cancellation and payment provider readiness before charging customers; then sign off the paid-release checklist.

This checklist is operational guidance, not legal, tax, security-certification, or financial advice.
