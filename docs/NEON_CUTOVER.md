# EDUNEXUS Neon cutover checklist

## Verified on 2026-10-14

- Neon project: `EDUNEXUS SOFTSKILL & HARDSKILL`, production branch.
- Neon Auth is configured with Better Auth; email/password sign-up is enabled.
- Neon Data API is active and limited to the `public` schema.
- 41 public tables were inspected; all 41 currently have RLS enabled.
- The current Neon database contains 2 practice scenarios.
- The identity migration table has one mapping, and the mapped Supabase and Neon user UUIDs differ.
- Neon Function `edunexusapi` has an older completed deployment, but its current deployment failed because the uploaded bundle could not resolve the `pg` package. Do not treat the current function deployment as healthy.
- The current GitHub Pages frontend still uses Supabase Auth, Supabase Data API, and the Supabase `edunexus-practice` Edge Function.

## Cutover blockers

1. **Identity compatibility:** legacy business records use the original Supabase user UUIDs. Neon Auth returns a different user UUID. RLS owner checks and frontend writes must use the mapped business-user UUID.
2. **Trusted practice finalization:** the current frontend calls a Supabase Edge Function that invokes trusted database functions. Moving only the browser's reads/writes to Neon would split a single practice workflow across two databases and is not safe.
3. **Backend deployment:** the latest `edunexusapi` deployment failed dependency loading. A green function deployment and endpoint smoke test are required before switching practice finalization.
4. **End-to-end validation:** verify login, sign-up, scenario reads, creating and submitting a practice, trusted scoring/evidence ingestion, history, and RLS isolation with a test account before production cutover.

## Identity compatibility migration

`neon/migrations/0001_auth_identity_compat.sql` is a proposed Neon-specific migration. It preserves the existing data model by translating a Neon Auth subject to its mapped legacy business-user UUID inside `auth.uid()`, and exposes a no-argument `public.current_user_id()` RPC so the browser can use the mapped ID for inserts.

**Do not apply this migration directly to production yet.** It has been applied on disposable branch `edunexus-cutover-test-20261014` and validated for:
- mapped Neon subject resolving to the existing legacy business-user UUID;
- unmapped subject falling back to its own UUID;
- `authenticated` can execute `current_user_id()`, while `PUBLIC` cannot.

The SQL checks are reproducible in `neon/tests/0001_auth_identity_compat.sql`. The clone has no practice-session or attempt rows, so end-to-end RLS isolation and the actual Data API JWT claim behavior remain unverified. Test those with a disposable test account and real Neon Auth JWT before applying the migration to production.

## Release gates

- [x] CI green for the migration branch.
- [x] Identity mapping function and RPC grants tested on a disposable Neon branch.
- [ ] Real Neon Auth JWT verified against the Data API and mapped user ID.
- [ ] Identity/RLS isolation tested with disposable user-owned rows and cross-user denial confirmed.
- [ ] Neon practice API deployed with all runtime dependencies bundled.
- [ ] API smoke test passes with a Neon Auth JWT; unauthorized requests rejected.
- [ ] End-to-end practice flow writes and reads from Neon only.
- [ ] Existing business rows and identity mapping counts reconciled.
- [ ] GitHub Pages deployment verified by HTTP response and browser smoke tests.
- [ ] Supabase retained as rollback source until the cutover is explicitly accepted.

A deployed static page or an active database endpoint alone is not evidence that EDUNEXUS is live end-to-end.
