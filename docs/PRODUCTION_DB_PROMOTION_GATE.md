# EDUNEXUS — Production Database Promotion Gate

**Last checked:** 2026-10-15  
**Status:** HOLD — do not apply Project Builder migration 0011 to production yet.

## Read-only evidence collected

- Production Neon branch: `br-bitter-king-azb11lde`.
- Preview Neon branch: `br-quiet-frost-azemctlk`.
- All five Project Builder tables (`ai_projects`, `ai_project_tasks`, `ai_agent_runs`, `ai_project_artifacts`, `ai_project_audit_events`) exist on preview.
- No `ai_*` tables exist on production at the time of the check.
- Production `auth.uid()` is a security-definer SQL function. It resolves the JWT subject through `private.supabase_identity_migration` when a mapping is present, then falls back to the JWT subject UUID.
- Preview table grants show `authenticated` has SELECT only on the five Project Builder tables; browser INSERT/UPDATE/DELETE are not granted. Row-level policies scope reads to `owner_id = auth.uid()`.
- This confirms the migration's intended boundary is present on preview; it does **not** prove end-to-end tenant isolation for real accounts.

## Additional preview validation recorded on 15 October 2026

- Ran `neon/tests/0011_project_builder_rls.sql` against the preview branch using synthetic owner UUIDs and the `authenticated` database role.
- Account A and Account B each saw exactly their own project, task, agent-run, artifact, and audit-event row; all cross-owner rows were filtered by RLS. The test rows were removed after verification.
- This validates the SQL policy boundary, but it is **not** a substitute for testing with two real Neon Auth accounts and their actual JWT subject mappings. The production promotion gate remains on hold.

## Required checks before production migration

1. Use two separate, authorized test accounts (Account A and Account B) in a non-production environment.
2. Obtain each account's actual Neon Auth JWT subject and resolved application user UUID through the approved test harness. Never paste bearer tokens into logs, GitHub issues, or this document.
3. Insert test records using a privileged server-side test harness with each account's owner UUID.
4. Authenticate as A and verify A can read A's project/task/run/artifact/audit records but cannot read B's records. Repeat as B.
5. Verify anonymous users have no access and authenticated users cannot directly INSERT, UPDATE, or DELETE these tables.
6. Check that JWT subject mapping is correct for both newly provisioned users and users migrated through `private.supabase_identity_migration`.
7. Capture redacted test output, environment, timestamp, and reviewer in the release evidence register.
8. Only after the tests pass, review migration 0011 against the current production schema and apply it in a controlled migration window with a tested rollback plan.

## Important safety note

Do not run a broad schema promotion or modify the identity mapping to make tests pass. If the mapping is wrong, fix and test the identity integration first. This document is a gate/checklist, not proof that the tests have already been run.
