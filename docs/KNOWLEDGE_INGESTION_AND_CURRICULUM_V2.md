# EDUNEXUS Public Knowledge Registry and Ingestion Policy

Version: 2.0 — 14 October 2026

## What is included now

The bundled AI corpus contains 24 curated chunks: product implementation context plus source-grounded summaries for Indonesian curriculum references, UNESCO AI frameworks and GenAI guidance, OECD Learning Compass, O*NET, ESCO, UNESCO digital literacy, WCAG 2.2, MIT OpenCourseWare, OpenStax licensing, OWASP LLM risks and Creative Commons licensing. These are concise authored summaries with direct source URLs; this is not a claim that all internet pages have been crawled.

The curriculum migration adds five original courses, ten modules and twenty original lessons:
- Literasi AI dan Etika Penggunaan AI
- Literasi Digital, Informasi dan Keamanan Siber
- Literasi Data dan Berpikir Kritis
- Pembelajaran Mandiri dan Metakognisi
- Keterampilan Kerja, Komunikasi dan Karier

These sit alongside the original two starter courses. Each lesson has a summary, objective, original explanatory text, comprehension question, exercise, and source IDs. Source links in the lesson are references; lesson text is not copied from source books.

## Primary sources

- Indonesian national curriculum subject guides: https://kurikulum.kemendikdasmen.go.id/panduan-mapel
- Curriculum and learning assessment: https://puskur.kemendikdasmen.go.id/
- UNESCO student AI competency framework: https://www.unesco.org/en/articles/ai-competency-framework-students
- UNESCO teacher AI competency framework: https://www.unesco.org/en/articles/ai-competency-framework-teachers
- UNESCO generative AI education guidance: https://www.unesco.org/en/articles/guidance-generative-ai-education-and-research
- OECD Learning Compass 2030: https://www.oecd.org/en/data/tools/oecd-learning-compass-2030.html
- O*NET database: https://www.onetcenter.org/database.html
- ESCO web service API: https://esco.ec.europa.eu/en/use-esco/use-esco-services-api/esco-web-service-api
- UNESCO Digital Literacy Global Framework: https://www.uis.unesco.org/en/gaml/monitoring-framework
- W3C WCAG 2.2: https://www.w3.org/TR/WCAG22/
- MIT OpenCourseWare: https://ocw.mit.edu/get-started/
- OpenStax license: https://help.openstax.org/s/article/Openstax-textbook-licensing-and-customization
- OWASP LLM Top 10: https://owasp.org/www-project-top-10-for-large-language-model-applications/
- Creative Commons license chooser: https://creativecommons.org/share-your-work/cclicenses/

## Trust and licensing policy

- Tier A: official standards, government, intergovernmental, standards organizations and primary dataset publishers.
- Tier B: recognized open-course providers where content has license limitations or requires additional license checks.
- Tier C: secondary material; not added to the initial approved set.
- Record publisher, URL, reviewed date, trust tier and license note.
- Prefer short original summaries and links. Do not reproduce whole textbooks, paywalled content, private data, leaked material or content whose reuse rights are unclear.
- MIT OCW and OpenStax content is commonly CC BY-NC-SA; it must not be republished in a commercial product unless the relevant rights allow it or separate permission is obtained.
- O*NET database is described as CC BY 4.0 except where noted; retain attribution and mark changes. Validate the US-centric occupational context before localizing to Indonesia.
- ESCO mappings should retain concept URIs and dataset/API version.

## AI use

The specialist runtime retrieves at most four chunks from the bundled curated corpus by lexical overlap. Sources are presented as evidence links. Retrieved text is untrusted data and must never override system or safety instructions. This is not yet a live general web-search engine, full-text crawler, vector database, or autonomous agent swarm.

## Rollout status

- Neon migration: neon/migrations/0007_knowledge_registry_curriculum_v2.sql
- Supabase rollback migration: supabase/migrations/20261014170000_knowledge_registry_curriculum_v2.sql
- This change is designed to be idempotent. The production rollout must be followed by row counts and browser verification.
- The migration's SQL does not delete learner records or modify authentication.
