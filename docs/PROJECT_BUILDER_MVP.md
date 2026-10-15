# EDUNEXUS Project Builder — MVP scope and release gates

**Status:** implementation in progress; project-planning route is code-complete for the first bounded orchestration slice, but production model inference and repository execution are not enabled yet.

## Product intent

The Project Builder is a second workspace beside the learning tutor. It should help a user turn an idea into a reviewed project plan and, in later releases, make changes in an authorized GitHub repository, run CI, and prepare deployment evidence.

## Current implementation in this slice

- UI mode selector: learning tutor or Multi-Agent Project Builder (planning).
- Four bounded project specialists: Project Manager, Solution Architect, Software Engineer, and QA & Security.
- Authenticated `POST /chat` receives `mode: "project"`; each specialist gets a role-specific instruction and the same scoped user request/curated retrieval context.
- The project route fails closed with HTTP 503 when the server-side model configuration is absent. It must not show a fake plan.
- Responses explicitly set `projectExecutionConfigured: false`. Planning is not represented as code execution, commit, test, or deployment.
- Model credentials remain server-side only; the frontend must never receive or store them.

## Current production gate

The current production function metadata does not list `MODEL_API_KEY`. Therefore model-generated planning is not ready for production until a legitimate provider credential is configured as a Neon Function secret. Do not use a paid gateway while the project remains constrained to Rp0 unless the owner explicitly changes that constraint. Free-tier provider availability, limits, and data terms must be rechecked before selecting one.

## Durable records schema added

The additive draft at `neon/migrations/0011_project_builder_records.sql` defines projects, tasks, agent runs, artifacts, and audit events. It includes bounded payload sizes, status checks, project-owner composite foreign keys, owner-scoped read policies, and no browser mutation grants. It has been applied to the Neon preview branch and verified there: all five tables exist, RLS is enabled, each table has one owner-read policy, and `authenticated` has only `SELECT` grants (no `INSERT`/`UPDATE`/`DELETE`). It is **not applied to production**. Before promotion, verify the exact Neon Auth role/JWT mapping and run tenant-isolation tests. The tables alone do not enable a repository-writing gateway.

## Next engineering slices

1. **Runtime parity:** deploy this exact function bundle to a non-production Neon branch; run health, unauthenticated rejection, CORS, retrieval-only, and authenticated provider tests; then deploy to production only if all checks pass.
2. **Credential gate:** verify a server-side provider credential and a supported model ID without logging or committing secrets. Health checks expose booleans only.
3. **Durable project records:** add per-user projects, tasks, agent runs, artifacts, and audit events with tenant isolation and retention controls.
4. **Read-only GitHub connector:** use narrowly scoped GitHub App/OAuth authorization; inspect only a user-authorized repository; summarize file paths and branch state. No arbitrary repository access.
5. **Patch workflow:** generate a diff on an isolated branch, validate changed paths, run tests and secret scanning, and show the patch for review.
6. **CI repair loop:** allow a bounded number of fix attempts only on the isolated branch; record each patch, test output, and reason for stopping.
7. **Human-reviewed release:** require authorized approval before merging to protected branches, changing production data, deploying, spending money, or deleting resources.

## Production acceptance criteria

- [ ] All runtime unit tests pass, including schema-boundary checks.
- [ ] Live health returns correct inference/auth/knowledge state without exposing secrets.
- [ ] Unauthenticated and disallowed-origin requests fail closed.
- [ ] Project mode uses four specialist roles only when model inference is configured.
- [ ] The user sees agent roles, source references, mode, and limitations.
- [ ] Project planning never claims code was written or tests passed without execution evidence.
- [ ] Project records migration has passed a preview-branch SQL test and tenant-isolation test.\n- [ ] GitHub writes are branch-scoped, audited, and reviewed; production changes require explicit authorization.
- [ ] Usage caps, timeout, persistent rate limits, budget alerts, data deletion, and privacy notice are in place.
- [ ] Mobile and desktop workflows pass browser smoke and accessibility checks.

## Non-goals for this slice

No unrestricted shell, arbitrary SQL, automatic production migration, credential discovery, unreviewed merge, paid-service provisioning, or claim of fully autonomous deployment. These require separate permission and security controls.
