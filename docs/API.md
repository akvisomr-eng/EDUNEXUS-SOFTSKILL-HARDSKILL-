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
