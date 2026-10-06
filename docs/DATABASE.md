# EDUNEXUS Database Foundation v1.0

The canonical relational model follows the EDUNEXUS MASTER BLUEPRINT v2.0.

## Core domains
Identity: users, profiles, goals.
Learning: programs, courses, modules, lessons, activities.
Skills: skills, competencies, skill levels, mastery records.
Assessment: assessments, questions, attempts.
Simulation: simulations, scenarios, simulation attempts.
Live: live sessions, participants, consent, media.
Performance: observations, metrics, evidence.
Mentoring: reviews, feedback.
Development: development events, timelines.
Credentialing: skill evidence, passports, portfolio, certificates.
Governance: parent consent, privacy preferences, retention policies, audit events.

## Design rules
- UUID primary keys.
- created_at/updated_at on mutable business entities.
- Foreign keys are explicit.
- Soft deletion only where business/legal requirements justify it.
- RLS is mandatory for user-owned and institution-owned data.
- AI-generated observations include provenance and model metadata.
- Verified evidence requires mentor/human validation when the workflow requires it.
- Media metadata is separated from derived performance features.
