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
- `neon/tests/0001_auth_identity_compat.sql` checks identity mapping and grants.
- `neon/tests/0002_trusted_practice_rpc.sql` checks function security and grants.
- Both SQL test scripts were executed successfully against disposable branch `edunexus-cutover-test-20261014` on 2026-10-14. The identity SQL test simulates the JWT subject via a transaction-local setting; it is not a substitute for the pending real browser JWT test.
- `web/neon-cutover-smoke.html` is a read-only browser diagnostic for the disposable branch. It uses the Neon Auth SDK to obtain an actual JWT, reads the mapped user identity and active practice catalog, checks visible practice sessions against the mapped identity, and optionally tests that a session ID belonging to a second test account returns no rows.
- `.github/workflows/neon-browser-smoke.yml` and `tests/neon-browser-smoke.mjs` now automate a real Chromium browser run against the disposable branch. The test creates a disposable auth account and checks sign-up, sign-in, JWT retrieval, identity RPC, catalog read, and session RLS visibility. The workflow has been committed but its GitHub Actions result is not yet confirmed. It does not yet prove cross-account isolation or the complete practice submit/finalize flow.

The browser smoke page is intentionally pinned to the disposable branch's Neon Auth and Data API endpoints. It must not be pointed at production or used with production accounts. The page creates an auth account only when the tester explicitly selects “Buat akun uji”; its database checks are read-only. It has been added to the PR but has not yet been run in a real browser, so the JWT and RLS checks remain pending runtime evidence.

These migrations have been prepared for the disposable test branch; do not apply to production until the test scripts and real JWT/RLS integration checks pass.

## Remaining release gates

1. Run both SQL test scripts against the disposable branch and retain their outputs.
2. Run `web/neon-cutover-smoke.html` in a browser against the disposable branch using two disposable accounts; verify actual JWT handling, mapped identity, catalog read, own-session RLS, and cross-account session isolation.
3. If the smoke test finds policy or identity mismatches, fix and retest on the disposable branch only.
4. Adapt the production frontend auth/session layer to Neon Auth and map its subject to the legacy business-user ID. Do not mix writes across Supabase and Neon.
5. Switch practice finalization to `rpc/finalize_my_practice_attempt` and validate the full practice flow, including scoring and candidate evidence.
6. Verify GitHub Pages deployment and browser smoke tests before cutover.
7. Keep Supabase available as rollback source until the cutover is explicitly accepted.

A successful CI run, static deployment, or active database endpoint alone is not evidence that EDUNEXUS is live end-to-end.
