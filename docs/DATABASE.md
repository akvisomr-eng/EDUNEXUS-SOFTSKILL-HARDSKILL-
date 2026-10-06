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
