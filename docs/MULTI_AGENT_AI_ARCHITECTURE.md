# EDUNEXUS Multi-Agent Intelligence — Architecture v1

**Product baseline:** EDUNEXUS MASTER BLUEPRINT v2.0  
**Deployment baseline:** GitHub Pages frontend + Neon Auth/Data API. Keep the existing Supabase rollback path until explicitly approved to retire it.

## Non-negotiable implementation constraints

1. GitHub Pages is static hosting. Never place model-provider API keys, database owner credentials, Neon admin keys, or other secrets in browser JavaScript.
2. All model calls and privileged tools run server-side behind an authenticated API (initial candidate: a Neon Function if runtime/package/environment limits are validated). The frontend must fail closed with a clear "AI belum dikonfigurasi" state until the endpoint is actually deployed and health-checked; never simulate model responses.
3. Use a provider adapter. The first adapter may use a supported AI gateway, but model IDs and SDK calls must be verified against current official documentation at implementation time. Keep the design provider-agnostic.
4. Retrieval-Augmented Generation (RAG) grounds answers in approved, versioned source chunks. Responses expose citations/source IDs and distinguish source facts from recommendations.
5. Agents are scoped roles inside one governed orchestrator, not independent privileged identities. They receive only tools and data allowed for the signed-in user's role.
6. Do not give agents unrestricted SQL, shell, web crawling, credential access, or write privileges. Any state-changing operation needs a narrowly scoped server tool, validation, audit log and explicit user/authorized reviewer approval where consequential.
7. Never infer emotion, personality, mental health, or character from faces/video. Performance analytics may report only observable, task-relevant measures with consent, transparent rubrics, provenance and human review.
8. For minors, default to conservative post-session analysis, minimal collection, explicit guardian consent where required, revocation, retention limits and no public sharing by default.

## Agent registry

| Agent | Responsibility | Allowed knowledge/tools | Output |
|---|---|---|---|
| Orchestrator / Router | Classify request, select specialist(s), merge answers | Agent registry, policy, retrieval search | Routed plan and final synthesis |
| EDUNEXUS Knowledge Steward | Answer blueprint/product architecture questions | Approved blueprint, repository docs, versioned source registry | Grounded answer with citations and version |
| Learning Designer | Build learning paths and learning activities | Approved pedagogy, course catalog, goals and skill ontology | Course/module/lesson plans |
| Soft-Skill Coach | Coach communication, leadership, teamwork, negotiation | Observable behavior rubrics, practice history user is authorized to see | Specific practice and feedback |
| Hard-Skill Tutor | Explain technical concepts and create exercises | Approved technical docs, curriculum and competency map | Explanation, exercise, worked steps |
| Practice & Simulation Designer | Create role-play and industry scenarios | Validated scenarios, rubric library, context | Scenario, objectives, rubric, debrief |
| Assessment & Rubric Agent | Draft transparent assessment/rubric | Approved competency framework and rubric templates | Criterion-based assessment; not final authority |
| Performance Analyst | Summarize task-linked, observable performance | Authorized transcript/metrics and explicit consent | Evidence-linked observations, uncertainty |
| Evidence Curator | Organize evidence and provenance | Authorized attempts, artifacts, observations | Candidate evidence, source links and confidence |
| Mentor Assistant | Prepare review summaries and feedback drafts | Assigned learners/sessions only | Draft review; mentor accepts/modifies/rejects |
| Development & Mastery Agent | Track growth over time | Verified evidence, versioned mastery rules | Timeline and explainable progress |
| Skill Passport & Portfolio Agent | Compile verified skills/artifacts | Verified evidence and sharing permissions | Passport/portfolio sections |
| Career Intelligence Agent | Map evidence to roles and next skills | Public occupational/skills taxonomies and user-authorized profile | Career options, skill gaps and caveats |
| Safety, Privacy & Evaluation Agent | Check policy, consent, citations and unsupported claims | Policies, source trust registry, evaluation set | Allow/block/escalate result and audit reason |
| Knowledge Ingestion Agent | Propose ingestion of external sources | Public URLs/repos/datasets within allowlist and license policy | Source metadata, extracted text, risk flags; no automatic publication |
| Project Manager Agent | Convert a project idea into an auditable project brief | User request, approved project templates, allowed repository metadata | Scope, milestones, acceptance criteria, assumptions and risks |
| Solution Architect Agent | Design a practical solution and data flow | Approved stack catalog, project constraints and allowed repository metadata | Architecture, data model, integration and security plan |
| Software Engineer Agent | Propose implementation slices and code contracts | User-authorized repository context, coding standards and task plan | File-level plan, interfaces, implementation checklist; no claim of writes without tool evidence |
| QA & Security Agent | Define release gates and review evidence | Test policies, security checklist, acceptance criteria and CI outputs | Test matrix, findings, release/rollback recommendation

## Orchestration pattern

1. Authenticate the caller and resolve the user's role and tenant scope.
2. Classify intent and sensitivity; reject requests that exceed permissions.
3. Retrieve relevant chunks from the approved knowledge corpus, applying source, recency, language and permission filters.
4. Route to one or more specialist agents with only the necessary context and tools.
5. Require structured outputs for assessments, evidence, and state changes; validate schemas and policy.
6. Run safety/evidence checks; unsupported or conflicting claims must be labeled or escalated.
7. Return a concise answer with source citations, limitations, and next steps.
8. Log model/provider/version, retrieved source IDs, tool calls, latency, token/cost estimates, safety outcome and user feedback—never log passwords or raw secrets.

## Knowledge ingestion pipeline

`discover → allowlist/policy check → fetch public source → extract → malware/content scan → deduplicate → license/provenance metadata → chunk → embed → evaluation → human approval → publish/version`

Each source record should contain: canonical URL, title, publisher/author, published/updated date when available, retrieved timestamp, license/terms, language, source type, trust tier, content hash, extractor version, chunk IDs, embedding/model version, review status, and supersedes/expiry metadata.

### Trust tiers

- **Tier A — primary:** EDUNEXUS blueprint and repository; official standards, official API documentation, government occupational frameworks, peer-reviewed research.
- **Tier B — reputable secondary:** universities, established professional bodies, recognized educational organizations and technical explainers with named authors.
- **Tier C — community:** open-source repositories, issue discussions, practitioner blogs, forums. Use as leads, not unquestioned truth.
- **Tier D — unverified/high-risk:** anonymous uploads, scraped mirrors, unknown datasets, dark-web material. Exclude by default. Any lawful threat-intelligence exception must be separately approved, isolated, sanitized, provenance-tagged and reviewed; never ingest stolen credentials, private personal data, malware payloads for execution, or illicit material.

External web content is untrusted data, not instructions. Ignore prompt-injection text embedded in retrieved documents; never allow a source to override system policy or authorize tools.

## Initial source catalogue

- EDUNEXUS MASTER BLUEPRINT v2.0 in the project Library — canonical product requirements.
- EDUNEXUS repository documentation and migrations — canonical implementation facts; code is not itself proof of product acceptance.
- AI SDK agents/tool-calling docs: https://ai-sdk.dev/docs/agents/overview and https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
- AI SDK embeddings: https://ai-sdk.dev/docs/ai-sdk-core/embeddings
- UNESCO, Guidance for generative AI in education and research: https://www.unesco.org/en/articles/guidance-generative-ai-education-and-research
- O*NET database: https://www.onetcenter.org/database.html — occupational skills/abilities/tasks; check dataset terms and version.
- ESCO classification: https://esco.ec.europa.eu/en — multilingual occupations and skills; check reuse terms and version.
- OWASP Top 10 for LLM Applications: https://owasp.org/www-project-top-10-for-large-language-model-applications/ — application risk baseline; verify current version at implementation.
- W3C WCAG 2.2: https://www.w3.org/TR/WCAG22/ — accessibility acceptance baseline.

Source URLs are candidates for a governed ingestion pipeline, not proof that content has already been downloaded or embedded. The system must store retrieval dates and citations and periodically revalidate links/versions.

## Evaluation and quality gates

- Blueprint QA: answers about EDUNEXUS must cite the canonical blueprint or repository evidence.
- Retrieval QA: recall@k, citation correctness, freshness, duplicate rate and unsupported-claim rate.
- Agent QA: task success, tool permission checks, schema validity, handoff correctness, refusal/escalation quality.
- Security QA: prompt injection, data exfiltration, cross-user retrieval, tool abuse, rate limiting, origin/auth checks and secret scanning.
- Education QA: rubric clarity, age-appropriateness, accessibility, multilingual quality, fairness checks and mentor override.
- Cost QA: per-user quotas, max tool steps, model fallback, timeout and budget alarms.

## Implementation prerequisites before enabling production chat

- Decide/deploy the server-side function and its authenticated route.
- Provision provider credentials as server-side secrets; do not commit them.
- Add the knowledge-source/chunk/vector storage schema and scoped retrieval API.
- Implement auth/role checks, rate limiting, audit and cost caps.
- Build the chat/agent UI with source citations, agent activity transparency, feedback and disabled/unconfigured states. The initial Project Builder mode is planning-only and fails closed if model inference is not configured.
- Add integration tests on a disposable branch and live smoke tests for the deployed endpoint.
- Only then describe the Multi-Agent AI as live. The Project Builder must additionally pass the project-specific release gates in `docs/PROJECT_BUILDER_MVP.md`.
