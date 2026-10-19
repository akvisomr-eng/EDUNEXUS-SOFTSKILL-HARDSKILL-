# EDUNEXUS — Scientific Agent Skills Adoption Plan

**Status:** proposal only; documentation branch; no skills installed or runtime behavior changed.  
**Purpose:** select reusable methods from K-Dense AI Scientific Agent Skills for EDUNEXUS learning, research, assessment, and project-planning workflows.  
**Reference repository:** https://github.com/K-Dense-AI/scientific-agent-skills  
**Review date:** 18 October 2026

## 1. Executive decision

Adopt the *methods and quality gates* first, not the entire third-party skill collection. EDUNEXUS should keep its current application architecture, Neon data/auth boundaries, curated retrieval fallback, and `AI_ENABLED=false` until real provider inference and safety checks pass.

The upstream repository is a collection of agent instructions and workflows; it is not a complete LMS, validated curriculum database, or drop-in multi-agent runtime.

## 2. Selected capabilities

| Priority | Capability pattern | EDUNEXUS use | Minimum acceptance evidence |
|---|---|---|---|
| P0 | Evidence provenance / literature review | Build course knowledge from credible sources; record title, author/organization, URL, publication/update date, access date, claims supported, license, and review status | Every imported claim has traceable provenance; duplicate sources detected; unsupported claims flagged |
| P0 | Public API / database lookup | Import public standards and documented datasets with pagination, rate limits, and source metadata | Schema validation, pagination/count reconciliation, retries bounded, source and timestamp retained |
| P0 | Critical thinking / evidence appraisal | Identify assumptions, evidence gaps, bias, conflicts, and uncertainty in lessons and AI answers | Reviewer checklist completed; uncertainty disclosed; high-impact claims require stronger evidence |
| P1 | Learning design | Convert approved knowledge into outcomes, modules, lessons, exercises, and rubrics aligned to observable competencies | Every lesson maps to an outcome and practice task; rubric criteria are measurable |
| P1 | Independent peer review | Review lesson correctness, relevance, accessibility, cultural context, and source quality before publication | Separate reviewer pass; blocking issues resolved or explicitly marked |
| P1 | Assessment and rubric design | Score demonstrated work against competency criteria and provide actionable feedback | Scores cite evidence from the learner submission; human override/appeal path exists |
| P2 | Exploratory/statistical analysis | Summarize aggregate practice results and detect learning bottlenecks | Minimum sample-size and privacy checks; no unsupported causal claims |
| P2 | Brainstorming / what-if analysis | Generate project options, risks, assumptions, milestones, and alternatives | Alternatives compared against constraints; assumptions and decisions logged |

Relevant upstream examples (review the exact skill and its license before reuse):
- Literature review: https://github.com/K-Dense-AI/scientific-agent-skills/tree/main/skills/literature-review
- Database lookup: https://github.com/K-Dense-AI/scientific-agent-skills/tree/main/skills/database-lookup
- Critical thinking: https://github.com/K-Dense-AI/scientific-agent-skills/tree/main/skills/scientific-critical-thinking
- Peer review: https://github.com/K-Dense-AI/scientific-agent-skills/tree/main/skills/peer-review
- Exploratory data analysis: https://github.com/K-Dense-AI/scientific-agent-skills/tree/main/skills/exploratory-data-analysis
- Statistical analysis: https://github.com/K-Dense-AI/scientific-agent-skills/tree/main/skills/statistical-analysis
- Scientific brainstorming: https://github.com/K-Dense-AI/scientific-agent-skills/tree/main/skills/scientific-brainstorming

Upstream names and paths may change; verify them against the current upstream tree before any adoption.

## 3. Proposed logical agent roles

These are role boundaries for future design, **not a claim that these agents are currently implemented**. Initial implementation may use one configured model with distinct, versioned role prompts rather than multiple paid models.

1. **Orchestrator** — routes a request to an allowed workflow, enforces user permissions, timeouts, budgets, and stop conditions.
2. **Research & Source Agent** — gathers candidate sources, deduplicates them, records provenance, and separates source text from instructions.
3. **Learning Designer** — maps approved knowledge to outcomes, modules, lessons, practice tasks, and rubrics.
4. **Critical Reviewer** — checks evidence strength, factual consistency, bias, uncertainty, and citation support.
5. **Assessment Agent** — evaluates learner-submitted evidence against published criteria; offers formative feedback rather than opaque judgments.
6. **Project Planner** — creates requirements, milestones, risks, acceptance tests, and implementation plans. It does not execute code or deploy by default.
7. **Safety & Quality Gate** — blocks publication or action when privacy, authorization, provenance, quality, quota, or policy checks fail.

Use explicit handoffs and structured outputs between roles. Do not allow one agent's unsupported conclusion to become verified fact merely because another agent repeats it.

## 4. Knowledge record and learning-object model

Before bulk content ingestion, agree on a versioned record with at least:

- `source_id`, canonical URL, title, publisher/author, publication date, access date, license/usage terms, and source type;
- claim or excerpt summary, language, topic, intended audience, evidence strength, known limitations, and last-reviewed date;
- learning outcome, competency tags, module/lesson IDs, prerequisite links, exercise, rubric, and review state;
- content version, reviewer, provenance links, correction/removal status, and ingestion timestamp.

Do not copy whole copyrighted courses or books by default. Prefer public-domain/openly licensed material, source-linked summaries, and original explanations. Keep source licensing metadata attached to derived learning objects.

## 5. Safe workflow

1. **Discover:** search approved sources and documented public APIs; do not treat search results as authoritative by default.
2. **Screen:** check relevance, date, credibility, license, duplicates, and whether a source is appropriate for the learner audience.
3. **Extract:** create concise, source-linked claims; preserve uncertainty and conflicting evidence.
4. **Design:** map approved claims to competencies and observable learning outcomes.
5. **Generate practice:** create exercises and rubrics aligned to outcomes; use examples that do not expose real personal data.
6. **Review independently:** verify citations, correctness, accessibility, cultural context, and answer keys.
7. **Publish selectively:** require human approval for high-impact, sensitive, or disputed content; retain a correction path.
8. **Evaluate:** analyze aggregate outcomes with privacy safeguards and update content through a versioned review process.

## 6. Security, privacy, and cost controls

- Keep all provider credentials in server-side Neon Function secrets; never put secrets in the frontend, repository, logs, or chat.
- Treat retrieved pages, documents, API responses, and learner uploads as untrusted data. They must not override system rules or authorize tool calls.
- Enforce authentication, tenant isolation/RLS, least privilege, bounded payloads, output validation, timeouts, and rate limits.
- Fail closed if quota checks or required safety controls are unavailable. Keep the emergency AI disable switch available.
- Do not send student names, contact details, sensitive records, or identifiable submissions to external providers unless a reviewed purpose, notice, legal basis, and provider handling are established.
- Use free-tier services where feasible, but do not assume a free tier is unlimited or suitable for public traffic. Set usage ceilings and test provider fallback before enabling AI.
- Keep AI off for public use until an authenticated end-to-end inference test, quality tests, privacy/security tests, quota tests, and fallback tests pass.

## 7. Licensing and source governance

The upstream repository-level license does not automatically settle the license of every individual skill, linked dependency, dataset, or external API. Before copying or adapting any specific skill:
1. inspect its directory-level license and notices;
2. inspect the license of scripts, dependencies, datasets, and external services it invokes;
3. retain attribution and notices required by the applicable license;
4. prefer a clean-room rewrite of the *method* when copying text is not permitted;
5. record the review decision and reviewer in the source registry.

Do not install domain-specific biomedical, clinical, wet-lab, or other specialized tooling into the EDUNEXUS core. Consider it only inside a separately scoped course or research workflow after a security and licensing review.

## 8. Phased delivery proposal

### Phase 0 — Design and baseline
- Confirm source registry fields and content/lesson schema.
- Map existing EDUNEXUS knowledge tables and frontend flows before proposing migrations.
- Record current CI, health, inference, quota, and RLS baselines.
- No schema changes, package installs, or AI activation in this phase.

### Phase 1 — Provenance and reviewer checklist
- Add source-quality rubric and content review template.
- Define machine-readable input/output contracts for research, lesson design, and review.
- Create synthetic fixtures and tests for missing citations, conflicting sources, prompt injection, and license metadata.

### Phase 2 — Learning workflow pilot
- Use a small, openly licensed sample corpus.
- Generate one course/module/lesson/practice/rubric chain.
- Require independent review and manual approval before publication.
- Measure citation accuracy, rubric alignment, refusal/fallback behavior, latency, and cost.

### Phase 3 — Controlled AI pilot
- Only after provider credentials are configured server-side and all gates pass.
- Use invited test accounts, non-sensitive sample data, strict quotas, visible experimental status, and a rollback path.
- Keep the project planner in planning-only mode until execution permissions and sandboxing are separately designed and tested.

### Phase 4 — Expand cautiously
- Add source domains and competency families incrementally.
- Run tenant-isolation, regression, privacy, accessibility, and cost tests on each release.
- Publish only features demonstrated by evidence; do not claim commercial readiness from a green CI run alone.

## 9. Acceptance gates

Do not call the workflow ready until the test report demonstrates:

- citation/source traceability and license metadata completeness;
- correct handling of conflicting or stale sources;
- prompt-injection resistance for retrieved content;
- tenant isolation and authorization on all read/write paths;
- schema-valid outputs with bounded retries and timeouts;
- clear uncertainty and evidence-based feedback;
- safe behavior when the provider, quota service, or retrieval source is unavailable;
- privacy-safe logs and no provider secrets in browser bundles or logs;
- measured provider usage and tested emergency disable/fallback;
- human approval and content correction/removal path.

## 10. Explicit non-goals for this proposal

- No wholesale cloning, downloading, or installing of all upstream skills.
- No new paid services, plan upgrades, or assumptions of unlimited free inference.
- No change to production or preview database schemas.
- No change to `AI_ENABLED`, provider secrets, Neon Functions, or public feature gates.
- No claim that multi-agent orchestration, project execution, or full course coverage is already implemented.
- No promotion to paid public launch; the existing commercial-readiness blockers remain in force.

## 11. Decision

**Recommended:** approve the concepts in this plan for staged design review, starting with provenance, source screening, critical review, and learning-object mapping. Keep this as a proposal until the team validates the existing data model and the owner explicitly approves a separate implementation change.
