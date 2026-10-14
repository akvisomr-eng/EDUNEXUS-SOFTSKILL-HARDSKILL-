# EDUNEXUS Knowledge Hub v3 — 2026-10-15

## What is included

- 28 public source records spanning Indonesian curriculum guidance, UNESCO AI competency and media-information literacy, OECD learning frameworks, ESCO, O*NET, DigComp, open educational resources, accessibility and LLM application security.
- 18 original editorial learning notes linked to source IDs and canonical URLs. Notes cover CP-to-ATP planning, formative assessment, literacy/numeracy, AI competencies, educator AI practice, GenAI privacy, learner agency, career mapping, task evidence, digital competence, source verification, observable soft-skill rubrics, collaboration, OER licensing, accessibility, prompt injection and account/data safety.
- The learner UI displays source metadata and the editorial notes with trust tiers, relevant agent roles and links.
- Migration creates `public.knowledge_chunks`, text-search index, GIN index for agent roles, public-read RLS for reviewed chunks, updates source registry and legacy source table, and adds source references to existing lessons without replacing their lesson text.

## Data and licensing boundaries

This is a curated source registry and an original synthesis corpus, **not a complete crawl of the internet**. It does not claim that all source documents have been downloaded, that embeddings have been created, or that the entire source text can be redistributed. Current corpus metadata explicitly records:
- 28 registered sources;
- 18 editorial notes;
- 0 full-text documents downloaded by this pipeline;
- 0 embeddings created.

Each external source is linked to its canonical location. The static JSON also exposes each original editorial note in the source-shaped retrieval format used by the current agent runtime; the learner interface filters those records from the canonical source directory and renders them in the separate notes list. Free access is not equivalent to a redistribution license. MIT OCW, OpenStax, OER Commons, OpenLearn, Khan Academy and other resources must be checked at the item level before copying or commercial reuse. This migration stores original summaries and source metadata, not the full source content.

## Multi-agent use

Each knowledge chunk is tagged with `agent_roles`, `domain`, `trust_tier`, `canonical_url`, source title, corpus version and content hash. Intended specialists include learning design, hard-skill tutoring, soft-skill coaching, assessment/rubrics, career intelligence, evidence curation, mentor assistance, development/mastery and safety/privacy evaluation.

Retrieved external text must remain untrusted data. It cannot override policy or authorize tool use. The AI runtime's actual ingestion and retrieval behavior must be verified with a live authenticated request before claiming that every chunk is consumed by production inference. This repository migration and the static source JSON provide a versioned, testable corpus foundation; they do not create embeddings automatically.

## Rollout

1. CI and frontend syntax checks.
2. Apply migration `neon/migrations/0006_curated_knowledge_hub.sql` to Neon production after CI succeeds; it is additive and idempotent.
3. Verify counts and RLS from production.
4. Merge to `main` so GitHub Pages serves the updated `web/knowledge-sources.json` and learner interface.
5. Verify Pages and the live AI health/chat path. Do not claim generative inference is live unless the provider is configured and a real response with source citations is verified.
6. Keep Supabase rollback schema in sync by applying the corresponding timestamped migration only under the project's approved rollback procedure.
