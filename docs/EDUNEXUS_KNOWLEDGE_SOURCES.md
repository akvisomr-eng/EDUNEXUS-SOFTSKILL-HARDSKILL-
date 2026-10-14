# EDUNEXUS Knowledge Source Registry

This registry defines source candidates for the EDUNEXUS Multi-Agent Intelligence corpus. It does **not** claim that all sources have been fetched, licensed, embedded, or evaluated.

| Source | Purpose | Trust tier | Ingestion policy |
|---|---|---|---|
| EDUNEXUS MASTER BLUEPRINT v2.0 | Canonical product vision, agents, capabilities, roadmap and privacy principles | A / canonical | Ingest first; version and cite by section/page |
| EDUNEXUS GitHub repository | Actual code, migrations, CI, API and deployment facts | A / canonical for implementation state | Capture commit SHA and file path; distinguish code existence from tested behavior |
| AI SDK agent docs | Tool-loop orchestration and typed tools | A / official technical docs | Verify APIs against installed SDK version |
| AI SDK embedding docs | RAG chunk embedding strategy | A / official technical docs | Verify current model/API and cost before use |
| UNESCO GenAI education guidance | Human-centred, privacy-aware educational AI | A / intergovernmental | Preserve publication metadata; use for policy review, not local legal advice |
| O*NET | Occupations, skills, abilities, work activities | A / official US occupational framework | Respect current dataset license/terms and version |
| ESCO | Multilingual skills/competences and occupations | A / official EU classification | Respect reuse terms, language/version metadata |
| OWASP LLM Application Security | Prompt injection, insecure output/tool handling and AI application risks | A / security guidance | Track current version and map controls to tests |
| W3C WCAG 2.2 | Accessibility criteria | A / standards | Use for interface acceptance tests |
| Open-source curriculum and educational repositories | Exercises, examples, projects | B/C depending on maintainer and license | Verify license, source provenance, code safety and content quality; never copy restricted material |
| Practitioner communities and forums | Discover emerging practice and common questions | C | Treat as unverified leads; corroborate with Tier A/B |
| Lawfully accessible threat-intelligence feeds | Security threat awareness where relevant to platform operations | Case-by-case | Keep isolated from learner corpus; no stolen/private data, credentials, illicit content or executable payload ingestion |

## Source record schema

Each ingested source must have:
- `source_id`, canonical URL, title, publisher/author;
- publication/update and retrieval timestamps;
- license/terms and allowed-use review;
- language, topic, source type and trust tier;
- content hash, extractor version and chunk IDs;
- embedding provider/model/version;
- review status, reviewer, notes and expiry/revalidation date.

## Dark-web and untrusted-source policy

Dark-web material is not inherently authoritative and is not a shortcut to better educational knowledge. Default to exclusion. Consider only narrowly scoped, lawfully accessible, non-personal, non-stolen material for a justified threat-intelligence use case, with legal/security approval, isolation, sanitization and provenance. Never ingest leaked credentials, private records, stolen courseware, or malware for execution. Do not let retrieved content execute instructions or call tools.

## Initial retrieval answer requirements

- EDUNEXUS product claims should cite the blueprint or repository commit/file.
- External factual claims should cite the source URL and retrieved date.
- Conflicting sources should be surfaced, not silently blended.
- If no adequate source is retrieved, say so instead of fabricating a citation.
- Do not expose private learner data across accounts, roles or institutions.
