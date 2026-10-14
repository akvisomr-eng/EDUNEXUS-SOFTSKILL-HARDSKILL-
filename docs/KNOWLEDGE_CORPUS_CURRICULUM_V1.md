# EDUNEXUS Knowledge Corpus and Curriculum v1

## Included in this release

This release registers a curated set of public educational and skills-framework references, adds four original courses, eight modules and sixteen lessons, and extends the in-app source directory. It does not claim to crawl every internet source.

### Source handling

- Registry records store canonical URL, publisher, trust tier, intended use, license notes, target agent roles, summary and ingestion status.
- New registry records are marked `metadata_registered`. This means source metadata and editorial summaries are registered; it does not mean the source's full text was downloaded, indexed, embedded, or reviewed line-by-line.
- External sources inform original EDUNEXUS learning material. The 16 new lessons are original summaries/exercises with source links; they are not copied chapters.
- Khan Academy is metadata/link-only because its current terms prohibit scraping and AI training on its content. OpenStax, MIT OCW, and OpenLearn have non-commercial or share-alike restrictions for many resources; each asset needs a license review before reuse.
- Public internet content is untrusted input. Retrieved content must never execute instructions or invoke privileged tools. Do not ingest leaked credentials, private records, stolen courseware, or illegal material.

### Newly added curriculum

Program: **Literasi Digital, AI, dan Kesiapan Karier** (uses existing program slug `literasi-digital-ai-kesiapan-karier`).

1. **Literasi Digital dan Evaluasi Informasi** — source credibility; fact/inference/assumption; content licenses and attribution; source-traceable synthesis.
2. **Literasi AI dan Penggunaan AI yang Bertanggung Jawab** — model limitations; human-centred AI and ethics; measurable prompts; output verification.
3. **Keamanan Digital dan Privasi Pribadi** — passwords/MFA; phishing; data minimization; incident response.
4. **Kesiapan Karier dan Portofolio Keterampilan** — mapping skills to roles; job description analysis; evidence-based portfolio; 30-day development plan.

Each course has two modules and each module two lessons. Lessons contain summaries, objectives, core content, application notes, exercises and source links.

### Migrations

- Neon: `neon/migrations/0006_knowledge_corpus_curriculum_v1.sql`
- Supabase rollback path: `supabase/migrations/20261014230000_knowledge_corpus_curriculum_v1.sql`
- Idempotent seed tested on disposable Neon branch before production rollout.
- Source ingestion status stays `metadata_registered`; no embedding/vector index is claimed by this migration.

### Public references checked for this release

- UNESCO generative AI education guidance: https://www.unesco.org/en/articles/guidance-generative-ai-education-and-research
- UNESCO AI competency framework for students: https://www.unesco.org/en/articles/ai-competency-framework-students
- ESCO API: https://esco.ec.europa.eu/en/use-esco/use-esco-services-api
- O*NET database: https://www.onetcenter.org/database.html
- European Commission DigComp: https://joint-research-centre.ec.europa.eu/digcomp/digcomp-framework_en
- MIT OpenCourseWare: https://ocw.mit.edu/
- OER Commons: https://www.oercommons.org/
- OpenLearn: https://www.open.edu/openlearn/free-courses
- OpenStax licensing: https://help.openstax.org/s/article/Licensing-information-of-OpenStax-textbooks
- Khan Academy content-use terms: https://support.khanacademy.org/hc/en-us/articles/42929097425037-What-s-allowed-and-not-allowed-under-Khan-Academy-s-Terms-of-Service

## Next stage for multi-agent AI

This migration gives the agent system source metadata and original structured lesson content to retrieve through authenticated database access. It does not, by itself, turn on external model inference, full-text crawling, semantic embeddings, or the full 15-agent orchestration. Those require a verified server-side model provider, an ingestion pipeline, and evaluation/security tests.
