# EDUNEXUS Admin — Backend Integration Map

**Status:** engineering plan; not a claim that admin persistence is implemented.  
**Baseline:** PR #74 / commit `64e4f1895bf91a1a86078093df919748d5b56c41`.  
**Reviewed:** 2026-10-16.

## Verified current behavior

The admin UI lives in `web/admin/index.html`. The reviewed implementation stores module rows, operational ledgers, and audit previews in browser `localStorage`. It labels these records as local demo data. The admin UI has no external script except Tailwind CDN, and no `fetch()`/database client integration was found in the inspected file.

Do not remove the demo label until authenticated server-side persistence and authorization are implemented and tested.

## Existing production database capabilities

A read-only inventory of the Neon production branch `br-bitter-king-azb11lde` confirmed these relevant tables:

- Learning: `programs`, `courses`, `modules`, `lessons`, `course_enrollments`, `assessments`, `assessment_attempts`, `assessment_answers`, `lesson_progress`.
- Competency/evidence: `competencies`, `skills`, `skill_levels`, `skill_evidence`, `mastery_records`, `performance_observations`, `mentor_reviews`.
- Identity/institution: `profiles`, `institutions`, `institution_memberships`, `guardian_student_relationships`, `mentor_student_relationships`.
- Audit/security: `audit_events`, `session_consents`.
- Knowledge: `knowledge_sources`, `knowledge_source_registry`, `knowledge_chunks`.

The following Project Builder tables exist on preview only and remain blocked from production promotion until the documented real-account JWT/RLS gate passes: `ai_projects`, `ai_project_tasks`, `ai_agent_runs`, `ai_project_artifacts`, `ai_project_audit_events`.

The production schema inventory did **not** show a complete operational ERP/HR/payroll/accounting/invoice/inventory/CRM table set. Do not force these domains into unrelated learning tables.

## Domain mapping and implementation decision

| Admin module | Existing fit | Decision |
|---|---|---|
| Akademik & Siswa | `profiles`, `course_enrollments`, `assessments`, `assessment_attempts`, `lesson_progress` | Map only after inspecting columns, foreign keys, RLS, and status semantics. Attendance/session records may need a new domain schema. |
| Kurikulum & Kursus | `programs`, `courses`, `modules`, `lessons`, `knowledge_source_registry` | Reuse matching learning/catalog entities; verify source provenance and write policies first. |
| Mentor | `mentor_student_relationships`, `mentor_reviews`, `performance_observations` | Map assignment/review fields after schema review; do not assume current columns match the admin form. |
| HRD & Payroll | No complete HR/payroll domain schema confirmed | New schema and privacy/access review required. Payroll stays demo/simulation until approved. |
| Accounting | No accounting ledger domain schema confirmed | Design double-entry journal, accounts, periods, posting controls and immutable audit trail before writes. |
| Inventori & Aset | No complete inventory/asset schema confirmed | New schema required for stock movements, counts, locations, asset maintenance and idempotency. |
| CRM | No CRM lead/ticket schema confirmed | New schema required; define retention, contact permissions, ownership and status transitions. |
| ERP/Pengadaan | No procurement/budget/receipt schema confirmed | New schema required with approval transitions and receiving controls. |
| Tagihan & Pembayaran | No invoice/payment/refund domain schema confirmed | New schema/provider integration required; never mark paid/refunded from a user-submitted claim alone. |
| Audit | `audit_events` exists | Inspect schema and grants before reuse. Security-sensitive audit events must be written server-side and protected against user tampering. |
| Pengaturan & akses | `profiles`, `institution_memberships` may support identity context | Do not treat profile data as authorization by itself. Enforce role/unit permissions server-side. |

## Required implementation sequence

1. Inspect schemas, foreign keys, RLS policies, grants, and existing server functions for each candidate table.
2. Define explicit roles and institution/unit scoping; derive identity from a verified session/JWT, never from a client-supplied user ID.
3. Add an authenticated server/API layer for admin reads and mutations. The browser must not hold privileged database credentials.
4. Implement domain-specific migrations only for missing entities. Add constraints, indexes, foreign keys, transaction boundaries, idempotency, and audit events.
5. Add tests for unauthenticated denial, role denial, cross-institution isolation using two real accounts, validation, status transitions, and audit integrity.
6. Connect the UI through a small API adapter with loading/error states. Preserve the local demo as a clearly separated demo mode until the production API passes.
7. Keep exports scoped to records the current principal is authorized to view. Avoid logging personal data or payroll details.
8. Run CI and browser smoke tests against preview; capture evidence before considering any production migration.

## Release gates

- No production writes until table mapping and access policies are reviewed.
- No promotion of Project Builder migration 0011 until `docs/PRODUCTION_DB_PROMOTION_GATE.md` is satisfied.
- No live AI claims while `MODEL_API_KEY` is absent and health reports inference disabled.
- No paid launch until `docs/COMMERCIAL_READINESS.md` P0 gates have evidence.

## Acceptance evidence to attach to the implementation PR

- Migration diff and schema review.
- API route/function inventory and authorization tests.
- Two-account cross-tenant isolation test results (redacted).
- CRUD/workflow/validation/audit test results.
- CI run and preview URL smoke-test result.
- Explicit list of features that remain demo-only.
