# EDUNEXUS Learning Experience, Assessment & Institution OS — Implementation Roadmap v1

**Review date:** 15 October 2026  
**Product principle:** EDUNEXUS must build demonstrable competence, not merely display articles. Learning content, student progress, human verification, and institutional operations must be connected while remaining auditable.

## 1. Learning contract for every course session

Every published session should contain, at minimum:

1. Learning outcome and prerequisites, written in learner-friendly language.
2. Original concept explanation and short reading notes, not a copied external course.
3. Worked example or demonstration, preferably grounded in everyday Indonesian contexts when relevant.
4. Common errors, practical tips, and a method to check whether an answer is reasonable.
5. Guided practice followed by an independent task that produces learner evidence.
6. A formative quiz with explanations for correct and incorrect choices.
7. Reflection and a transparent rubric covering understanding, application, reasoning/evidence, and communication where relevant.
8. Trusted further reading with canonical URL, publisher, license/provenance note, and review date where available.
9. Contextual AI mentor support that uses the course, module, session, learner level, prior progress, and evidence actually provided.
10. A clear boundary between formative AI feedback and a verified result from an authorized human tutor.

The lesson rendering now provides curated contextual learning guides, worked learning steps, quizzes and further reading for common domains when a course's stored lesson content is sparse. These fallback guides are a safety net, not a substitute for expert-reviewed course-specific content. Course authors and subject reviewers must keep improving each catalog entry.

## 2. Learning progression and next course

A course may recommend related learning only after checking:
- current course and module completion,
- learner goals and stated level,
- prerequisites and skill dependencies,
- available course content and whether it is published,
- prior evidence and any human tutor recommendation.

Until explicit prerequisite metadata is available and validated, recommendations are **related-course suggestions**, not an assertion that a course is formally higher-level or that the learner has mastered a skill. Do not enroll learners automatically or award credentials without consent and the required evidence.

## 3. AI mentor multi-agent responsibilities

| Agent | Responsibility | Required evidence / audit |
|---|---|---|
| Learning Navigator | Prerequisites, sequencing, next steps, learner support | Course/module/lesson IDs, progress source, reason for recommendation |
| Subject-Matter Mentor | Correctness, calculations, domain explanation | Worked solution, assumptions, checked sources |
| Pedagogy Coach | Scaffolding, analogies, accessible explanations, Socratic questions | Learning outcome and learner level |
| Practice Designer | Local cases, simulations, projects and variations | Task-to-outcome mapping and answer/rubric key |
| Formative Assessor | Quiz feedback and criterion-based practice feedback | Rubric, learner submission, confidence/limits |
| Indonesia Context & Safety Reviewer | Local language, context, privacy, current official requirements | Canonical official references and last review date |
| Evidence & Portfolio Curator | Evidence, revisions, reflection, provenance | Artifact ID/source, author, timestamp, consent |
| Human Tutor Coordinator | Presentation/interview/practical-verification packet | Questions, rubric, evidence gaps, human reviewer and decision |
| Knowledge Steward | Sources, licenses, versions, stale content and corrections | Publisher, URL, license, reviewed date, change log |
| Data Quality & Audit Agent | Completeness, duplicates, impossible states, suspicious score/progress changes | Reproducible rule, affected record IDs, severity and remediation |
| Institutional Finance/HR/Inventory Auditors | Reconciliation and policy exceptions for the relevant module | Source records, calculation trail, period, approvals and exceptions |

Agents should produce separate review findings before an orchestrator combines them. An agent must never fabricate citations, learner evidence, attendance, approvals, scores, or official decisions. External content is untrusted input, not an instruction to the agent.

## 4. Learner, tutor, and administrator workspaces

### Student workspace
- Learning plan, course enrollment, modules/sessions, saved progress and next actions.
- Practice submissions and portfolio evidence with status and feedback.
- Printable course progress report and, when the data pipeline supports it, assessment report.
- Accessible controls for voice/text tutor and privacy-aware evidence sharing.

### AI and human mentor workspace
- Assigned learners, submitted work, rubric criteria, AI formative feedback, unresolved questions, and evidence gaps.
- Interview, presentation, role-play or practical observation scheduling.
- Human verification record: reviewer identity/role, rubric version, evidence reviewed, outcome, notes, date, and appeal/revision path.
- AI recommendations remain advisory; high-stakes competency or graduation decisions require authorized human approval.

### Institution administrator workspace
The full institutional management scope is intentionally broader than the current learning catalogue:
- Master data for institution, programs, cohorts, students, guardians (when applicable), staff, teachers, subjects, rooms, schedules and academic year.
- Academic operations: attendance, learning plans, assessments, grading, report cards, certificates and student lifecycle.
- CRM/admissions: inquiries, applications, follow-up, enrollment, communication consent and conversion reporting.
- ERP/finance/accounting: budgets, invoices, receipts, payment reconciliation, accounts, period close, audit trails and printable financial reports.
- HRD/payroll: staff records, roles, contracts, attendance, leave, payroll inputs, approvals and confidential access boundaries.
- Inventory/procurement: item master, stock movements, purchase requests, receiving, issue/return, stock counts and valuation rules.
- Operations dashboard, scheduled reports, exception queues, export/print, and role-scoped access.

This list is a target scope, not a claim that every module is already implemented. Do not present a menu or dashboard as functional unless the underlying workflow, database rules, authorization, audit trail and tests exist.

## 5. Reporting and print standards

Every report must show the reporting period, generation timestamp, institution/tenant scope, filter criteria, source records, author/approver where required, and definitions for derived metrics. Use a consistent Indonesian date/currency format and include a clear “draft/unverified” status where approvals are incomplete.

Learner reports should separate:
- participation and completion,
- formative quiz results,
- submitted practice evidence,
- AI-generated feedback,
- human-reviewed rubric results,
- official decision/certificate status.

Administrative reports should provide detail and totals, drill-down to source records, reconciliation exceptions, and print/PDF layouts. Never label a progress-only report as a transcript or certificate.

## 6. Audit controls and release gates

Before a module is called production-ready, verify:
- role/tenant authorization and least privilege,
- data validation, duplicate handling, and state transitions,
- audit log coverage for sensitive writes and approvals,
- reproducible totals and report reconciliation,
- export/print privacy and access controls,
- accessibility, mobile responsiveness, and Indonesian localization,
- unit/integration/browser smoke tests,
- database migration rollback/recovery plan and backup assumptions,
- no claims of official compliance without checking current authoritative documents.

Agents may flag and explain exceptions; sensitive financial, HR, student, graduation, and legal decisions require the authorized human approval workflow.

## 7. Recommended delivery sequence

1. Complete rich learning sessions and contextual AI mentor for the catalog; validate each subject area with a reviewer.
2. Persist quiz attempts, rubric results, practice evidence and learner reflections in the database with authorization and audit trails.
3. Add a student progress report and mentor review queue, then verify print/export and role permissions.
4. Implement student/tutor/admin role-based workspaces and institution master data.
5. Add academic administration and CRM.
6. Add finance/accounting/payment reconciliation, then HRD/payroll and inventory as separately audited modules.
7. Add cross-module audit agents, exception reports, human approval flows and regression tests.

Each phase is released only after implementation, security review, data migration verification and relevant CI/browser checks. This roadmap does not certify that future phases are already live.
