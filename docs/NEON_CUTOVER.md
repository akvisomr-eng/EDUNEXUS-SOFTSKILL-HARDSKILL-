# EDUNEXUS Neon cutover checklist

## Verified on 2026-10-14

- Neon Auth is configured with Better Auth; email/password sign-up is enabled.
- Neon Data API is active and limited to the `public` schema on production and the disposable test branch.
- 41 public tables were inspected on production; all 41 currently have RLS enabled.
- The Neon database contains 2 practice scenarios.
- The identity migration table has one mapping, and the mapped Supabase and Neon user UUIDs differ.
- Neon Function `edunexusapi` deployment 4 failed because the bundle could not resolve package `pg`; deployment 2 remains the active deployment.
- GitHub Pages frontend still uses Supabase Auth, Supabase REST, and the Supabase `edunexus-practice` Edge Function.
- No Neon migration has been applied to production; Supabase remains the active frontend backend.

## Changes prepared for Neon

- `neon/migrations/0001_auth_identity_compat.sql` maps Neon Auth subjects to legacy business-user IDs.
- `neon/migrations/0002_trusted_practice_rpc.sql` exposes a narrowly scoped Data API RPC for trusted practice finalization. It checks authenticated ownership and submitted status, keeps scoring/evidence functions private, and grants execution only to `authenticated`.
- `neon/migrations/0003_ensure_my_profile.sql` provisions a minimal student profile only for the authenticated user's mapped ID. It creates the legacy `auth.users` ID anchor required by the existing `profiles` foreign key, without copying credentials or touching other users.
- `neon/tests/0001_auth_identity_compat.sql` checks identity mapping and grants.
- `neon/tests/0002_trusted_practice_rpc.sql` checks function security and grants.
- `neon/tests/0003_ensure_my_profile.sql` checks own-profile provisioning and least-privilege grants.
- Both SQL test scripts were executed successfully against disposable branch `edunexus-cutover-test-20261014` on 2026-10-14. The identity SQL test simulates the JWT subject via a transaction-local setting; it is not a substitute for the pending real browser JWT test.
- `web/neon-cutover-smoke.html` is a browser diagnostic pinned to the disposable branch. It creates a disposable auth account, obtains an actual JWT, provisions that account's minimal profile, reads mapped identity and active scenarios, creates a disposable practice session and attempt, submits a structured response, calls the trusted finalization RPC, checks candidate evidence and own-session RLS, and optionally tests that a session ID belonging to a second test account returns no rows.
- `.github/workflows/neon-browser-smoke.yml` and `tests/neon-browser-smoke.mjs` now automate a real Chromium browser run against the disposable branch. The test creates a disposable auth account and checks sign-up, sign-in, JWT retrieval, identity RPC, catalog read, and session RLS visibility. The workflow has been committed but its GitHub Actions result is not yet confirmed. It does not yet prove cross-account isolation or the complete practice submit/finalize flow.

The browser smoke page is intentionally pinned to the disposable branch's Neon Auth and Data API endpoints. It must not be pointed at production or used with production accounts. It creates a disposable auth account and test-only profile/practice rows when the tester selects the corresponding test actions. It has been run in a real browser for auth/JWT/identity/catalog/initial RLS checks; full practice finalization and candidate-evidence checks are now being added to the automated run.

These migrations have been prepared for the disposable test branch; do not apply to production until the test scripts and real JWT/RLS integration checks pass.

## Remaining release gates

1. Run all three SQL test scripts against the disposable branch and retain their outputs.
2. Pass the browser E2E for actual JWT, profile provisioning, identity mapping, catalog, practice session/attempt submission, trusted scoring/finalization, candidate evidence, and own-session RLS.
3. Run a separate two-account cross-session isolation test.
4. If the smoke test finds policy or identity mismatches, fix and retest on the disposable branch only.
5. Adapt the production frontend auth/session layer to Neon Auth and map its subject to the legacy business-user ID. Do not mix writes across Supabase and Neon.
6. Verify GitHub Pages deployment and browser smoke tests before cutover.
7. Keep Supabase available as rollback source until the cutover is explicitly accepted.

A successful CI run, static deployment, or active database endpoint alone is not evidence that EDUNEXUS is live end-to-end.
