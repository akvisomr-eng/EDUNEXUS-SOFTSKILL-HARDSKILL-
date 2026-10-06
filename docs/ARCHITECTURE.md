# EDUNEXUS System Architecture v2.0

## Product boundary
EDUNEXUS is a Human Skill Intelligence & Development Platform. The platform loop is:
Learning -> Practice -> Simulation -> Performance -> Assessment -> Feedback -> Evidence -> Mastery -> Development -> Skill Passport -> Career.

## Runtime layers
1. Experience: Student, Mentor, Parent/Guardian, Institution, Admin.
2. Application API: authentication, identity/membership, learning, practice, assessment, simulation, performance, evidence, mastery, development, passport, portfolio and career.
3. Intelligence: AI Gateway + specialized agents.
4. Data: PostgreSQL/Supabase, object storage, audit/event data.
5. Integration: vendor-agnostic live-session providers and future external systems.

## Identity and authorization boundary
Identity is authenticated by Supabase Auth. Authorization is represented in relational data:
institutions -> institution_memberships and explicit mentor_student_relationships / guardian_student_relationships.

The profiles.role field is descriptive bootstrap metadata, not an authorization source. Client profile creation is student-only. Privileged access is granted through membership/relationship records managed by trusted administrative workflows.

## AI agents
- Tutor
- Coach
- Mentor Assistant
- Content
- Assessment
- Simulation
- Speech Analytics
- Visual Analytics
- Interaction Analytics
- Evidence
- Development
- Career

AI observations are evidence-producing signals, not psychological diagnoses. Human review remains authoritative for validated development evidence.

## Performance pipeline
Live Session -> Consent Check -> Capture -> Temporary Processing -> Feature Extraction -> Performance Observation -> Metric -> Evidence Candidate -> Mentor Review -> Verified Evidence -> Mastery/Development.

For minors, post-session analysis is the preferred default. Raw media follows explicit retention policy and is not assumed to be permanent.

## Non-functional requirements
- tenant/institution isolation
- relationship-based row-level authorization
- auditability
- consent and revocation
- data minimization
- idempotent event processing
- traceable AI outputs
- human override
- vendor-agnostic live-session integration
- observable production health

## Initial implementation strategy
Start as a modular monolith with clear domain boundaries. Extract high-load or asynchronous domains only when justified by load and operational needs.
