# EDUNEXUS Neon cutover checklist

## Verified on 2026-10-14

- Neon Auth is configured with Better Auth; email/password sign-up is enabled.
- Neon Data API is active and limited to the `public` schema.
- 41 public tables were inspected; all 41 currently have RLS enabled.
- The Neon database contains 2 practice scenarios.
- The identity migration table has one mapping, and the mapped Supabase and Neon user UUIDs differ.
- Neon Function `edunexusapi` deployment 4 failed because the bundle could not resolve package `pg`; deployment 2 remains the active deployment.
- GitHub Pages frontend still uses Supabase Auth, Supabase REST, and the Supabase `edunexus-practice` Edge Function.

## Changes prepared for Neon

- `neon/migrations/0001_auth_identity_compat.sql` maps Neon Auth subjects to legacy business-user IDs.
- `neon/migrations/0002_trusted_practice_rpc.sql` exposes a narrowly scoped Data API RPC for trusted practice finalization. It checks authenticated ownership and submitted status, keeps scoring/evidence functions private, and grants execution only to `authenticated`.
- `neon/tests/0001_auth_identity_compat.sql` checks identity mapping and grants.
- `neon/tests/0002_trusted_practice_rpc.sql` checks function security and grants.

These migrations have been prepared for the disposable test branch; do not apply to production until the test scripts and real JWT/RLS integration checks pass.

## Remaining release gates

1. Apply both Neon migrations to the disposable branch and run both SQL test scripts.
2. Verify actual Neon Auth JWT subject claims through the Data API, not only simulated session settings.
3. Test RLS isolation using two disposable authenticated accounts and user-owned rows; verify cross-user reads/writes are denied.
4. Adapt the frontend auth/session layer to Neon Auth and map its subject to the legacy business-user ID. Do not mix writes across Supabase and Neon.
5. Switch practice finalization to `rpc/finalize_my_practice_attempt` and validate the entire workflow.
6. Verify GitHub Pages deployment and browser smoke tests before cutover.
7. Keep Supabase available as rollback source until the cutover is explicitly accepted.

A successful static deployment or active database endpoint alone is not evidence that EDUNEXUS is live end-to-end.
