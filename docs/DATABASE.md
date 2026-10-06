# EDUNEXUS Database Foundation v2.0

The canonical relational model follows the EDUNEXUS MASTER BLUEPRINT v2.0.

## Core domains
- Identity: users, profiles, goals, institutions, institution memberships, guardian/student relationships, mentor/student relationships.
- Learning: programs, courses, modules, lessons, activities.
- Skills: skills, competencies, skill levels, mastery records.
- Assessment: assessments, attempts.
- Simulation: simulations, scenarios, simulation attempts (planned extension).
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
- `course_enrollments` records explicit user enrollment and enforces one enrollment per course/user.
- `lesson_progress` records per-user lesson state and only permits progress writes for an active enrollment in the lesson's parent course.
- Both tables use relationship-aware RLS through `private.can_access_user`.

## Assessment Core
- `assessments` remains the catalog-level assessment definition.
- `assessment_attempts` now has an explicit lifecycle: `in_progress -> submitted -> reviewed`, with `cancelled` as a terminal alternative.
- `assessment_items` stores ordered assessment tasks/questions without embedding item structure into the attempt row.
- `assessment_item_skill_targets` maps items to skills and optional competencies so assessment results can feed the Skill Intelligence layer.
- `assessment_answers` stores attempt-scoped responses and evaluation feedback; learners can only mutate answers while their attempt is `in_progress`.
- Assessment catalog and item-target mappings are readable by authenticated users; learner attempt/answer records remain relationship-authorized.
- Learners may only create an `in_progress` attempt and transition it to `submitted` or `cancelled`; score/result/review state is protected from client mutation.
