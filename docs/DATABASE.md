# EDUNEXUS Database Foundation v2.0

The canonical relational model follows the EDUNEXUS MASTER BLUEPRINT v2.0.

## Core domains
- Identity: users, profiles, goals, institutions, institution memberships, guardian/student relationships, mentor/student relationships.
- Learning: programs, courses, modules, lessons, activities.
- Skills: skills, competencies, skill levels, mastery records.
- Assessment: assessments, attempts.
- Simulation: practice scenarios, scenario skill targets, practice sessions, practice attempts, simulation runs and simulation events.
- Live: live sessions, participants, consent, media metadata (planned extension).
- Performance: observations, metrics, evidence.
- Mentoring: mentor reviews and feedback.
- Development: development events and timelines.
- Credentialing: skill evidence, passports, portfolio and certificates (incremental extension).
- Governance: consent, privacy, retention and audit events.

## Identity and authorization
Cross-user access is relationship-based, not role-claim-based.

### Institution membership
institution_memberships maps a user to an institution with one of: student, mentor, guardian, staff, admin.

### Guardian/student
guardian_student_relationships explicitly grants a guardian access to the student's authorized learning/development records.

### Mentor/student
mentor_student_relationships explicitly grants a mentor access to the student's authorized learning/performance records.

### Authorization rules
- Self access is allowed.
- Guardian/mentor access requires an active explicit relationship.
- Institution staff/admin access requires active membership in the same institution.
- Client-side users cannot create or mutate membership/relationship records.
- AI performance observations and metrics are derived records; clients cannot write them directly.
- Verified development evidence remains subject to human review workflows.
- Profile role cannot be self-assigned: client profile creation is restricted to student; authorization is derived from explicit relationships/memberships.

## RLS
RLS is enabled across the exposed public schema. anon has no table privileges. authenticated receives only domain-specific grants and policies. Authorization helpers live in a non-exposed private schema and are narrowly executable by authenticated.

## Design rules
- UUID primary keys.
- created_at/updated_at on mutable business entities.
- Explicit foreign keys and indexes for relationship lookup paths.
- Soft deletion only where business/legal requirements justify it.
- RLS is mandatory for user-owned and institution-owned data.
- AI-generated observations include provenance and model metadata.
- Verified evidence requires mentor/human validation when the workflow requires it.
- Media metadata is separated from derived performance features.

## Learning Core
- course_enrollments records explicit user enrollment and enforces one enrollment per course/user.
- lesson_progress records per-user lesson state and only permits progress writes for an active enrollment in the lesson's parent course.
- Both tables use relationship-aware RLS through private.can_access_user.

## Assessment Core
- assessments remains the catalog-level assessment definition.
- assessment_attempts now has an explicit lifecycle: in_progress -> submitted -> reviewed, with cancelled as a terminal alternative.
- assessment_items stores ordered assessment tasks/questions without embedding item structure into the attempt row.
- assessment_item_skill_targets maps items to skills and optional competencies so assessment results can feed the Skill Intelligence layer.
- assessment_answers stores attempt-scoped responses and evaluation feedback; learners can only mutate answers while their attempt is in_progress.
- Assessment catalog and item-target mappings are readable by authenticated users; learner attempt/answer records remain relationship-authorized.
- Learners may only create an in_progress attempt and transition it to submitted or cancelled; score/result/review state is protected from client mutation.

## Evidence & Mastery Intelligence
- skill_evidence is the durable evidence boundary. Client applications can read authorized evidence but cannot create, modify, verify, or reject evidence directly; trusted workflows/human review own those mutations.
- Evidence records retain source_type, source_id, confidence, provenance, verifier, and verification time so AI-derived signals remain traceable.
- mastery_records represents the current skill state and is read-only to clients.
- mastery_history records longitudinal mastery changes and links each change to optional source evidence; clients can read only authorized history.
- development_events and skill_passports are also read-only client projections. Their mutations belong to controlled application workflows.

## Practice & Simulation Core
- practice_scenarios is the catalog boundary for reusable practice, simulation, role-play, and industry scenarios.
- scenario_skill_targets explicitly maps scenarios to skills and optional competencies with a target weight.
- practice_sessions tracks learner-owned execution of a scenario and supports in_progress -> submitted, with cancellation as a terminal path.
- practice_attempts stores attempt-scoped learner responses. Scores are protected from learner mutation and belong to controlled assessment/performance workflows.
- simulation_runs represents a simulation execution and supports live_assistance or post_session modes.
- simulation_events captures observable simulation events while a run is active. It is intentionally event-oriented so later Performance Intelligence workflows can consume the stream without coupling simulation to scoring.
- Practice/simulation records use relationship-aware RLS through private.can_access_user.
- Simulation results remain controlled workflow output; the client cannot write the final result payload.

## Performance Intelligence Core
- performance_observations remains a derived record and is not client-writable.
- performance_metrics remains derived and is not client-writable.
- performance_observation_sources provides explicit lineage from observations to live sessions, practice, simulation, or assessment sources without forcing a polymorphic foreign key.
- performance_observation_skill_targets maps observations to skills and optional competencies so performance signals can feed Skill Intelligence.
- observation and metric confidence values are constrained to valid ranges; observation status tracks candidate/reviewed/rejected state.
- Trusted workflow functions are private and not executable by client roles. They are the controlled entry points for creating observations and metrics.
- Human review remains the authoritative boundary before downstream evidence, mastery, development, or passport projections.


## Evidence & Mastery Pipeline v1
- Trusted workflows create evidence as `candidate` records with score, confidence, provenance, and an idempotency key; client roles remain unable to mutate evidence.
- Candidate evidence is verified only by an active mentor relationship for the evidence owner. Verification records the reviewer and timestamp.
- Verified evidence with scores is aggregated per user/skill into `mastery_records`; mastery changes are appended to `mastery_history` for longitudinal tracking.
- Mastery updates emit idempotent `development_events` and refresh a versioned `skill_passports` snapshot.
- Mastery level mapping in v1 uses score bands: 0-19 Unfamiliar, 20-34 Awareness, 35-49 Beginner, 50-64 Developing, 65-74 Intermediate, 75-84 Advanced, 85-94 Professional, 95-100 Expert.
- `private.finalize_evidence_pipeline` is the controlled orchestration boundary for verification, mastery recomputation, development projection, and passport refresh.
- All pipeline functions are revoked from client roles and executable only by `service_role`; this keeps downstream derived records outside direct client mutation.


## Skill Evidence Ingestion v1
- Reviewed assessment attempts can be transformed into candidate evidence per targeted skill using weighted awarded points.
- Reviewed performance observations can be transformed into candidate evidence per targeted skill from accepted metrics in the normalized 0-100 range.
- Both ingestion paths use deterministic idempotency keys based on source and skill, preventing duplicate candidate evidence.
- Ingestion is trusted-workflow/service-role-only; it does not bypass the human verification boundary.
