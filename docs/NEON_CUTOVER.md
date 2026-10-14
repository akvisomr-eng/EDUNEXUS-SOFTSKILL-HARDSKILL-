# EDUNEXUS Neon cutover checklist

## Verified on 2026-10-14

- Neon Auth is configured with Better Auth; email/password sign-up is enabled.
- Neon Data API is active and limited to the `public` schema on production and the disposable test branch.
- A no-compute rollback snapshot branch `edunexus-pre-neon-cutover-20261014` (`br-icy-pine-az1nl1b7`) was created from production at LSN `0/21E2710` before applying cutover functions.
- Production row counts were inspected read-only before cutover: 1 legacy `auth.users` ID, 1 `neon_auth.user`, 0 `profiles`, 0 `practice_sessions`, 0 `practice_attempts`, 0 `skill_evidence`, and 2 active practice scenarios.
- 41 public tables were inspected on production; all 41 currently have RLS enabled.
- The Neon database contains 2 practice scenarios.
- The identity migration table has one mapping, and the mapped Supabase and Neon user UUIDs differ.
- Neon Function `edunexusapi` deployment 4 failed because the bundle could not resolve package `pg`; deployment 2 remains the active deployment.
- GitHub Pages production frontend has been migrated to Neon Auth and Neon Data API; live Pages smoke test returned HTTP 200 and confirmed the Neon frontend markers with no Supabase endpoint reference.
- Production migrations 0001–0004 were applied transactionally and the Neon Data API schema cache was refreshed. Supabase remains enabled only as a rollback source; it was not disabled.

## Changes prepared for Neon

- `neon/migrations/0001_auth_identity_compat.sql` maps Neon Auth subjects to legacy business-user IDs.
- `neon/migrations/0002_trusted_practice_rpc.sql` exposes a narrowly scoped Data API RPC for trusted practice finalization. It checks authenticated ownership and submitted status, keeps scoring/evidence functions private, and grants execution only to `authenticated`.
- `neon/migrations/0003_ensure_my_profile.sql` provisions a minimal student profile only for the authenticated user's mapped ID. It creates the legacy `auth.users` ID anchor required by the existing `profiles` foreign key, without copying credentials or touching other users.
- `neon/migrations/0004_trusted_practice_score_transition.sql` allows the trusted scoring function to set a score only on an already-submitted, unscored attempt; normal user updates remain blocked after submission.
- `neon/tests/0001_auth_identity_compat.sql` checks identity mapping and grants.
- `neon/tests/0002_trusted_practice_rpc.sql` checks function security and grants.
- `neon/tests/0003_ensure_my_profile.sql` checks own-profile provisioning and least-privilege grants.
- `neon/tests/0004_trusted_practice_score_transition.sql` checks trusted score assignment and confirms learner edits remain blocked after submission.
- `tests/neon-frontend-e2e.mjs` exercises the actual migrated UI against a temporary copy of `web/index.html` pointed at the disposable branch; current diagnostics record form validity, submit-button ownership, and attempt identity while resolving a frontend submit-event issue.
- Both SQL test scripts were executed successfully against disposable branch `edunexus-cutover-test-20261014` on 2026-10-14. The identity SQL test simulates the JWT subject via a transaction-local setting; it is not a substitute for the pending real browser JWT test.
- `tests/fixtures/neon-cutover-smoke.html` is a browser diagnostic pinned to the disposable branch. It creates a disposable auth account, obtains an actual JWT, provisions that account's minimal profile, reads mapped identity and active scenarios, creates a disposable practice session and attempt, submits a structured response, calls the trusted finalization RPC, checks candidate evidence and own-session RLS, and optionally tests that a session ID belonging to a second test account returns no rows.
- `.github/workflows/neon-browser-smoke.yml` and `tests/neon-browser-smoke.mjs` now automate a real Chromium browser run against the disposable branch. The test creates a disposable auth account and checks sign-up, sign-in, JWT retrieval, identity RPC, catalog read, and session RLS visibility. The workflow has been committed but its GitHub Actions result is not yet confirmed. It does not yet prove cross-account isolation or the complete practice submit/finalize flow.

The browser smoke page is intentionally pinned to the disposable branch's Neon Auth and Data API endpoints and lives under `tests/fixtures/`, outside the deployed `web/` root. It must not be pointed at production or used with production accounts. Browser run #116 passed auth/JWT/identity/catalog/profile, full practice submission/finalization (score 100), candidate evidence, and own-session RLS. The separate frontend E2E passed signup/login, profile bootstrap, catalog, practice submission, score/evidence display, and history display. A live Pages smoke workflow verified HTTP 200 and the deployed Neon frontend.

These migrations have been prepared for the disposable test branch; do not apply to production until the test scripts and real JWT/RLS integration checks pass.

## Post-cutover status

- [x] Run SQL tests and verify the identity, profile provisioning, and trusted score lifecycle on the disposable branch.
- [x] Pass browser E2E for Neon Auth/JWT, identity, catalog, practice session/attempt submission, trusted scoring, candidate evidence, and own-session RLS.
- [x] Apply migrations 0001–0004 transactionally to production and refresh the Data API schema cache.
- [x] Verify all 41 public tables still have RLS enabled and business row counts remain unchanged.
- [x] Verify GitHub Pages returns HTTP 200 and serves the Neon frontend.
- [x] Keep Supabase available as rollback source; it has not been disabled.

A dedicated two-account cross-session isolation test remains a follow-up hardening task; the initial own-session RLS checks and browser workflow pass, but this separate negative test was not claimed as completed.

A successful CI run, static deployment, or active database endpoint alone is not evidence that EDUNEXUS is live end-to-end.
