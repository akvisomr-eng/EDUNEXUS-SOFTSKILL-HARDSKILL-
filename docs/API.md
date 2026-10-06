# EDUNEXUS API Contract v1.1

Base domains:
- /auth
- /users
- /profiles
- /goals
- /institutions
- /memberships
- /programs
- /courses
- /enrollments
- /modules
- /lessons
- /lesson-progress
- /activities
- /skills
- /competencies
- /mastery
- /assessments
- /attempts
- /projects
- /submissions
- /simulations
- /scenarios
- /live-sessions
- /session-events
- /performance
- /observations
- /metrics
- /evidence
- /mentor
- /reviews
- /feedback
- /development
- /timeline
- /skill-passport
- /portfolio
- /certificates
- /consent
- /privacy
- /retention
- /career
- /recommendations

## Learning Core
Course enrollment is explicit and user-owned. Lesson progress can only be created or updated for an active enrollment in the lesson's parent course.

All mutation endpoints should be authenticated, authorized, audited where sensitive, and designed for idempotency where retried by clients/workers.


## Evidence & Mastery Pipeline
- Controlled evidence creation is internal-only: source workflows create candidate evidence with source lineage, score, confidence, provenance, and an idempotency key.
- Human verification is required before evidence becomes verified; the reviewer must have an active mentor/student relationship with the evidence owner.
- Verified evidence is aggregated into longitudinal mastery state and appended to mastery history.
- Mastery updates produce development timeline events and a versioned Skill Passport snapshot.
- Client applications do not receive mutation access to evidence, mastery, development, or passport projections.
