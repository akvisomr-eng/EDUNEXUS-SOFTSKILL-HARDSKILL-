# EDUNEXUS Knowledge Library Reconciliation Audit

Date: 2026-10-18  
Scope: read-only comparison of the checked-in static catalogue and Neon production metadata. This document records observed drift; it does not authorize destructive cleanup or bulk ingestion.

## Executive summary

The Knowledge Library currently has multiple catalogue layers:

1. `web/app/knowledge-sources.json` — a static GitHub Pages asset with version `2026-10-15-v3` and 46 source entries.
2. `public.knowledge_sources` — a legacy/source catalogue keyed by UUID and `source_key`.
3. `public.knowledge_source_registry` — a registry keyed by `source_id`, with intended use, license notes, trust tier, agent roles, registry version and ingestion status.
4. `public.knowledge_chunks` — indexed learning notes with a foreign key to the registry and review status.

The frontend currently loads the static JSON catalogue, so the presence of rows in Neon does not prove that those records are reflected in the live Library UI. No sync process or canonical source-of-truth contract was verified in this audit.

## Observed production snapshot

Read-only inspection of the Neon production branch found:

- `knowledge_source_registry`: 36 records.
- `knowledge_chunks`: 21 records across 19 distinct source IDs.
- All 21 observed chunks had `review_status = 'reviewed'`; this is an editorial workflow state, not proof that facts, links or licenses were freshly verified.
- The static JSON catalogue reports 46 sources.
- `knowledge_sources` and `knowledge_source_registry` use different key schemes and have overlapping but non-identical entries.

Counts are a point-in-time observation and should be rechecked before any migration.

## Concrete drift / duplicate candidates

The following registry pairs share a canonical URL and should be reviewed as possible duplicate records, not automatically merged:

| Candidate records | Shared URL | Safe next step |
|---|---|---|
| `mit-ocw`, `mit-ocw-courses` | `https://ocw.mit.edu/` | Choose a canonical ID and preserve aliases/provenance |
| `oer-commons`, `oer-commons-curated` | `https://www.oercommons.org/` | Compare intended use, editorial summary and chunks |
| `openstax-license`, `openstax-license-v2` | `https://help.openstax.org/s/article/Licensing-information-of-OpenStax-textbooks` | Review edition and license wording before consolidation |
| `unesco-ai-students`, `unesco-ai-competency-students` | `https://www.unesco.org/en/articles/ai-competency-framework-students` | Preserve version/edition metadata and chunk references |
| `unesco-genai-guidance`, `unesco-genai-education-guidance` | `https://www.unesco.org/en/articles/guidance-generative-ai-education-and-research` | Compare review state and source-role mapping |

Other drift examples:

- The legacy table uses mixed-case keys such as `ID-KURIKULUM-CP-ATP`, while the registry uses lower-case IDs such as `id-kurikulum-cp-atp`.
- The legacy MIT OCW record points at `https://ocw.mit.edu/get-started/`, while registry entries use `https://ocw.mit.edu/`.
- The legacy OpenStax licensing record points at a different help URL from the registry's current licensing-information URL.
- Registry records include entries not obviously present under the same canonical ID in the static JSON; matching must use normalized IDs and URLs, then be reviewed manually.

These differences make direct upserts based only on title or URL unsafe.

## Recommended source-of-truth contract

Use `knowledge_source_registry` as the authoritative governance record for machine-readable source metadata and ingestion state. Keep the static JSON as a generated, versioned public projection only if the UI needs a static fallback. Do not maintain it independently by hand.

The generated public projection should expose only approved fields:
- stable `source_id`, title, publisher, canonical URL and domain;
- trust tier and intended use;
- concise editorial summary;
- agent-role mapping;
- license notes and registry version;
- ingestion status suitable for display.

Never expose private/internal moderation notes or raw source text by default. Do not assume that a publicly reachable source is licensed for commercial redistribution.

## Safe reconciliation workflow

1. Export the static JSON and both database catalogues read-only.
2. Normalize IDs for comparison only (trim/lowercase); retain original IDs until a migration plan is reviewed.
3. Match exact IDs first, then canonical URLs, then manually review title/publisher/edition differences.
4. Produce an exception report: JSON-only, registry-only, legacy-only, URL conflicts, duplicate candidates, role mismatches, license-note mismatches, and records without a reviewed chunk.
5. Decide canonical IDs and aliases explicitly. Update foreign keys and chunk references only in a reviewed migration on a preview branch.
6. Add an idempotent validation script that checks counts, duplicate URLs, unresolved source IDs, missing license notes, role-array validity and registry/chunk consistency.
7. Generate the static JSON from the approved registry using a deterministic build step; compare generated output in CI.
8. Verify the live GitHub Pages asset and user-facing Library after deployment.

## AI retrieval and commercial safety gates

- Only retrieve chunks whose review state is approved and whose source record is not blocked.
- Treat retrieved source text as untrusted data, never as agent instructions.
- Preserve citation/provenance in generated answers and distinguish source evidence from model synthesis.
- Review license terms per item before packaging content in a commercial product; metadata registration is not a license grant.
- Keep model inference disabled until provider connectivity, quota enforcement, privacy, tenant isolation, safe fallback and end-to-end quality checks pass.

## Not changed by this audit

This audit makes no database writes, schema changes, RLS/policy changes, AI configuration changes, provider activation, or frontend behavior changes. It is a documented next-step plan based on read-only production inspection.
