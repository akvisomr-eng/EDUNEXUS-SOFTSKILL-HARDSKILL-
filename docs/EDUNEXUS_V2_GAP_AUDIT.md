# EDUNEXUS MASTER BLUEPRINT v2.0 — Gap Audit

**Status:** Baseline audit from the production `web/index.html` and blueprint in the user Library. This is not a claim that unseen backend objects do not exist. A feature is "implemented" only when its UI, authorized API/data flow, error states, and tests work end-to-end.

## Current production baseline

Verified in the inspected frontend source:
- Neon Auth email sign-in/sign-up and password recovery UI.
- A minimal profile bootstrap using `ensure_my_profile` and identity consistency check.
- Active practice-scenario catalog.
- Structured response form that creates a practice session and attempt, submits responses, invokes `finalize_my_practice_attempt`, and renders a returned score/evidence.
- Recent practice-session history.
- Health indicator limited to successful bootstrap/catalog loading, not a full system health check.

The current page is still a compact learner practice prototype, not the complete v2.0 product. Prior browser tests were on a disposable Neon branch; do not treat them as proof of every production module.

## Blueprint gap matrix

| Capability from v2.0 | Current evidence | Gap / acceptance criteria |
|---|---|---|
| Identity, trust, privacy | Neon Auth and profile bootstrap | Role model, least-privilege access, consent/preferences, audit trail and privacy lifecycle need explicit verification |
| Student dashboard | Basic backend/scenario/practice counts | Personal goals, next action, learning progress, skill growth and development journey |
| Learning intelligence | Not present in inspected UI | Program/course/module/lesson/activity, content types, enrollment and persisted progress |
| Goal and diagnosis | Not present | Goal setting, initial diagnostic, skill-gap mapping, explainable personalized path |
| Hard-skill engine | Not present | Domain → skill → competency → knowledge/practice/project/assessment/evidence |
| Soft-skill engine | Practice form is generic | Observable behavior, context-specific rubrics and evidence; never infer psychological state/character |
| AI tutor/coach/content | No model-backed assistant in inspected UI | Secure server-side AI gateway, knowledge retrieval, citations, feedback and usage controls |
| Practice engine | Structured response practice exists | Quiz, writing, coding, speaking, problem-solving, projects, retry/improvement loop |
| AI simulation room | Not present | Role-play/industry scenarios, participant/session state, rubric, transcript/event ingestion and debrief |
| Performance intelligence | Not present | Speech/presentation/interaction/participation metrics with provenance and consent; no emotion/mental-health diagnosis |
| Assessment intelligence | One score from finalization path | Rubric-linked assessments, transparent criteria, attempts, review and accommodations |
| Evidence engine | Candidate evidence may be returned | Source-linked evidence, status lifecycle, review queue, mentor accept/modify/reject and audit |
| Mastery engine | Not present in inspected UI | L0–L7 mastery derived from multiple valid sources, with rationale and versioned rubric |
| Skill Passport 2.0 | Not present | Knowledge, performance, evidence, mastery, development and career sections; verified vs pending labels |
| Development timeline | Not present | Time-ordered events and progress trend; growth over ranking |
| Portfolio/certificates | Not present | Artifacts, sharing controls, verification and certificate criteria |
| Mentor console | Not present | Learners, sessions, observations, review queue, feedback and skill progress |
| Parent/guardian console | Not present | Child progress, evidence, feedback, consent and revocation controls when applicable |
| Institution/admin/content studio | Not present | Users/roles, programs, content, competencies, assessment/rubrics, AI policy and analytics |
| Career intelligence | Not present | Career mapping, skill gaps and readiness recommendations grounded in evidence |
| Live-session integration | Not present | Vendor-agnostic adapter contract; Zoom/Meet/Teams/WebRTC only when integrations are implemented and authorized |
| AI governance / evaluation | Not present in UI | Knowledge source registry, retrieval evaluation, model/tool logging, prompt-injection defense, human override and cost limits |

## Required delivery order

1. **Foundation hardening:** schema/API/RLS inventory, role-based authorization, error handling, audit logging, environment separation, backup/rollback check.
2. **LMS Core:** goals, programs/courses/modules/lessons, enrollment and progress.
3. **Skill Intelligence:** competency ontology, observable rubrics, initial diagnosis, skill-gap and personalized path.
4. **AI Learning:** secure server-side model gateway, EDUNEXUS knowledge retrieval, tutor/coach/content agents and citations.
5. **Practice & Simulation:** multiple practice types, role-play engine and retry loop.
6. **Assessment & Performance:** rubric-based scoring and observable metrics with provenance; human review for consequential judgments.
7. **Evidence & Mentor Review:** evidence lifecycle and mentor review queue.
8. **Mastery, Passport, Timeline, Portfolio:** verified/pending distinction and longitudinal growth.
9. **Parent/Institution/Admin:** consent, revocation, privacy, role-scoped dashboards and content studio.
10. **Career Intelligence:** evidence-based recommendations and skill gaps.

## Release acceptance rule

A module is not "done" because a card or menu exists. Each module must have:
- an implemented workflow and real persisted data;
- authorization/RLS tests for own-user, cross-user and role boundaries;
- empty/loading/error/success states;
- mobile and desktop checks;
- automated tests and a green CI run;
- production smoke checks for the actual deployed commit;
- documented limitations and evidence for claims.

No destructive production migrations, account changes, or disabling the Supabase rollback path without explicit authorization.
