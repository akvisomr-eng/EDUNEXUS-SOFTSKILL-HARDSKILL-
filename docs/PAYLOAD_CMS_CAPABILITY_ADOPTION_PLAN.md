# EDUNEXUS — Payload CMS Capability Adoption Plan

**Status:** documentation proposal only. No Payload package installed and no application/database/runtime changes made.  
**Reviewed:** 18 October 2026  
**Upstream:** https://github.com/payloadcms/payload

## 1. Decision

Reuse selected *content-management patterns* from Payload CMS in EDUNEXUS, rather than adopting Payload as a second CMS or replacing the existing application stack.

EDUNEXUS currently uses a GitHub Pages frontend with Neon Auth and Neon Data API. Payload is a code-first CMS/application framework with its own configuration, admin UI, collections, access control, APIs, hooks, localization, and versioning. Installing Payload wholesale would introduce a server/runtime and database-integration decision that is not justified for this targeted improvement.

**Recommended first step:** design a thin, EDUNEXUS-native content governance layer around existing tables and screens. Do not create duplicate tables until the live schema and current Knowledge Hub implementation are inspected.

## 2. Payload capabilities worth adapting

| Priority | Payload concept | EDUNEXUS adaptation | Guardrail |
|---|---|---|---|
| P0 | Collections / typed fields | Standard content contracts for courses, modules, lessons, practice scenarios, rubrics, and knowledge sources | Map to existing tables first; avoid duplicate entities |
| P0 | Access control | Role- and tenant-aware permissions for viewing, editing, reviewing, publishing, and deleting learning content | Enforce on server/database RLS; hiding UI controls is not security |
| P0 | Drafts and publishing | Draft → in review → approved → published → archived workflow | Public read paths expose published/approved content only |
| P0 | Versions / revision history | Preserve revisions and identify who changed what, when, and why; allow safe rollback | Keep immutable audit evidence where appropriate; never overwrite learner evidence silently |
| P1 | Validation and lifecycle hooks | Validate required fields, competency links, rubric structure, and provenance before a publish action | Keep hooks deterministic, bounded, idempotent, and covered by tests |
| P1 | Localization | Separate content language from interface language; start with Indonesian and support English later | Track translation status; do not silently treat machine translation as reviewed |
| P1 | Admin grouping and editor UX | Organize editor workflows by Programs & Courses, Practice & Simulation, Development Goals, Knowledge Library, and Practice History | Preserve the existing user-facing information architecture |
| P2 | API contracts / pagination / filtering | Consistent, versioned content API contracts for frontend views and future integrations | Keep secrets server-side; validate inputs; restrict fields; paginate results |
| P2 | Upload/media management | Consider safe attachments for lesson materials only if a real need exists | Do not introduce public uploads without file validation, size limits, access policy, and retention rules |
| P2 | Scheduled publishing | Schedule content release for cohorts or courses if a verified requirement appears | Timezone, cancellation, permissions, and audit tests required |

Payload references:
- Collections and generated APIs: https://payloadcms.com/docs/configuration/collections
- Access control: https://payloadcms.com/docs/access-control/overview
- Versions and revision history: https://payloadcms.com/docs/versions/overview
- Drafts and preview publishing: https://payloadcms.com/docs/versions/drafts
- Global/singleton configuration: https://payloadcms.com/docs/configuration/globals
- Localization: https://payloadcms.com/docs/configuration/localization
- REST API: https://payloadcms.com/docs/rest-api/overview
- PostgreSQL adapter: https://payloadcms.com/docs/database/postgres

## 3. Proposed EDUNEXUS content lifecycle

Use a clear lifecycle for learning content:

1. **Draft** — author/AI may prepare content; not visible to ordinary learners.
2. **In review** — required metadata, outcomes, source citations, answer key, and rubric are checked.
3. **Approved** — authorized reviewer confirms content quality and license/provenance.
4. **Published** — learners can access the approved version.
5. **Archived** — hidden from new course discovery but retained for records and learners who legitimately need historical context.

Suggested publication gates:
- Course has audience, level, language, prerequisites, and measurable outcomes.
- Each module and lesson belongs to a valid parent and has a stable identifier.
- Claims derived from external knowledge link to source records and usage/license metadata.
- Practice tasks map to a competency; rubrics define observable criteria and score bands.
- Reviewer and approval timestamp are recorded.
- Sensitive or high-impact content has an appropriate human review.
- Only authorized roles can transition content into Published.

This is a proposed state model, not a claim that these states currently exist in the database.

## 4. Suggested content model (logical, not a migration)

Before designing tables, map the following concepts to existing EDUNEXUS tables and fields:

- **Program/Course:** title, slug, description, audience, level, language, competency outcomes, prerequisites, status, version.
- **Module:** course reference, title, sequence, outcomes, estimated effort, status.
- **Lesson:** module reference, content blocks, learning objectives, examples, activities, references, accessibility notes, language, status.
- **Practice Scenario:** competency target, prompt/context, constraints, expected evidence, difficulty, privacy classification.
- **Rubric:** criteria, score bands, descriptors, evidence requirements, feedback guidance, rubric version.
- **Knowledge Source:** canonical URL, title, publisher/author, dates, language, license/usage terms, credibility notes, review state.
- **Content Revision:** content ID, version, change summary, editor/reviewer, timestamps, approval decision.
- **Publication Event:** content ID/version, actor, action, time, result, reason.
- **Translation Link:** source content/version, target locale, translation status, reviewer.

Prefer foreign keys and existing normalized relations over copying whole course/module/lesson trees into JSON blobs. If the current schema already represents these concepts, extend it only after compatibility and migration review.

## 5. Roles and access boundaries

Candidate roles to map onto existing EDUNEXUS authorization:
- **Learner:** read published content for their permitted scope; submit their own practice evidence; read their own history.
- **Author / Learning Designer:** create and edit drafts; cannot self-approve restricted content by default.
- **Reviewer:** read draft and source metadata; submit review decisions; cannot change billing or tenant security settings.
- **Publisher / Course Owner:** publish approved versions within their organization.
- **Organization Admin:** manage authorized members and organization-scoped content, without bypassing platform-wide security.
- **Platform Admin:** perform narrowly scoped operational tasks with auditable elevated access.

Actual role names must be mapped to existing Neon Auth and membership structures. Never assume a client-supplied organization ID grants access. RLS and server-side authorization must verify membership and ownership for every read/write path.

## 6. Hook/event patterns to borrow

Use small, predictable validation steps at the content lifecycle boundary:
- Before save: normalize and validate schema, required fields, language, parent references, and bounded text/media size.
- Before publish: require review state, provenance/license metadata where applicable, valid outcomes/rubrics, and authorized publisher.
- After publish: write an audit event and invalidate/update relevant content indexes in a retry-safe way.
- On archive/correction: preserve historical revision and propagate a clear status to dependent learning views.
- For AI-assisted drafts: label machine-generated suggestions, preserve source references, and require human approval before publication.

Avoid calling LLMs inside database triggers or critical transaction hooks. Long-running generation should be an explicit asynchronous job with bounded retries, idempotency, quota checks, and failure status.

## 7. Architecture and cost decision

**Do not add Payload CMS to the current production stack yet.**

Reasons:
- The current frontend is static-hosted on GitHub Pages; Payload's full admin/API experience requires a compatible server runtime and deployment target.
- Payload's PostgreSQL adapter manages its own schema/migrations. Sharing the existing Neon database without a carefully isolated schema and migration plan could cause conflicts or unintended schema changes.
- Neon Data API/RLS/Auth and Payload's own access-control/authentication models would need deliberate integration; using both without a clear boundary risks duplicated auth and inconsistent authorization.
- A new runtime adds deployment, monitoring, backup, and security responsibilities that may undermine the Rp0-first goal.

Consider actual Payload adoption only if EDUNEXUS needs a full editorial admin panel that is materially more expensive to maintain than the native content-management screens, and only after confirming a free/acceptable hosting option, supported Node runtime, isolated schema, auth integration, migration/rollback plan, and total-cost limits.

For now, implement Payload-inspired patterns in the existing app with current Neon tables and native UI. The upstream Payload repository is MIT-licensed, but third-party dependencies, plugins, themes, and media remain separately licensed and must be reviewed.

## 8. Phased plan

### Phase 0 — Inventory (read-only)
- Inspect existing schema, RLS policies, Knowledge Hub, course/module/lesson views, and publication logic.
- Produce a field-by-field mapping from the logical model above to existing tables.
- Identify missing lifecycle states and existing audit/version facilities.
- No database writes or migrations.

### Phase 1 — Editorial quality gates
- Define content states and transitions in a documented state machine.
- Define role-to-action matrix and publication checklist.
- Add synthetic tests for invalid parent references, missing provenance, unauthorized publish, and draft visibility.
- Keep AI generation off for public use.

### Phase 2 — Minimal native implementation
- Add only the smallest required UI/API changes using existing architecture.
- Reuse existing tables wherever possible.
- Add revision/audit support only if the inventory proves it is missing.
- Use preview branch and test accounts first; require RLS isolation tests.

### Phase 3 — Content pilot
- Pilot one course with modules, lessons, a practice scenario, a rubric, source links, and Indonesian-language review.
- Test draft visibility, reviewer workflow, publication, correction, archival, and rollback.
- Collect evidence before broad import.

### Phase 4 — Scale if justified
- Add multilingual workflows and scheduled publishing only when needed.
- Reassess full Payload adoption using measured editorial effort and hosting costs, not feature count alone.

## 9. Acceptance gates

Do not call this capability ready until tests prove:
- drafts are not accessible to unauthorized users or public endpoints;
- learner, author, reviewer, publisher, and tenant boundaries work under RLS and server authorization;
- publish requires a valid review state and complete mandatory metadata;
- revisions and publication events can be inspected and safely restored;
- API responses are validated, bounded, paginated, and do not leak internal fields;
- localization does not mix reviewed and unreviewed translations;
- failure paths preserve data and do not publish partial content;
- no credentials appear in frontend bundles, repository, or logs;
- production migrations have preview tests, backups/restore evidence, and rollback instructions.

## 10. Explicit non-goals

- No installation of Payload CMS or new dependencies in this proposal.
- No replacement of Neon, Neon Auth, Neon Data API, GitHub Pages, or existing EDUNEXUS views.
- No database schema migration, production write, or change to RLS policies.
- No provider activation, paid service, or hosting purchase.
- No wholesale copying of upstream code or plugins.
- No claim that the proposed content lifecycle is already implemented.

## Recommendation

Proceed with **Payload-inspired content governance**, starting with a read-only inventory and field mapping. Do not install the full Payload framework unless a later, evidence-based architecture review proves that the operational benefits outweigh the hosting, migration, and authorization complexity.
