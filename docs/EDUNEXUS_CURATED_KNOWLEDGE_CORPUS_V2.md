# EDUNEXUS Curated Knowledge Corpus v2

**Snapshot date:** 14 October 2026  
**Status:** Curated source registry plus original instructional synthesis. This is not an exhaustive crawl of the internet, and it does not claim that every listed document has been downloaded or indexed in full.

## Knowledge domains and usage

1. **Indonesian curriculum and assessment** — Use official CP/ATP and subject guides as the primary authority for claims about Indonesian school requirements. Verify the current decision number, effective date, phase, subject, and document version for every compliance statement. Do not treat an illustrative course in EDUNEXUS as an official school curriculum.
2. **Reading and numeracy** — Use official AKM examples as references for staged literacy and numeracy; write original practice questions and cite source pages.
3. **Digital literacy** — Use DigComp 2.2 as an international taxonomy reference, contextualized for Indonesian learners and accessibility.
4. **AI literacy** — Use UNESCO's student and teacher competency frameworks (understand/apply/create and acquire/deepen/create) plus its human-centred GenAI guidance. AI outputs must be verified and should not replace human judgement.
5. **Future skills and pedagogy** — Use OECD Learning/Teaching Compass as conceptual frameworks, not binding Indonesian regulation.
6. **Career skills** — Use ESCO and O*NET to map skills/occupations. Localize language and labor-market context. O*NET Online content is CC BY 4.0 subject to stated exceptions; attribute the U.S. Department of Labor/ETA and disclose modifications. Check ESCO dataset-specific terms; software license is not a blanket dataset license.
7. **Well-being and safeguarding** — Use WHO/UNICEF/UNESCO educational guidance for safe and inclusive learning. EDUNEXUS must not diagnose mental health or infer personality from video/behavior.

## Sources registered

The machine-readable list is `web/knowledge-sources.json`. Each entry includes the canonical URL, publisher, trust tier, intended use, license caution, and agent roles. Migration `neon/migrations/0007_knowledge_source_registry.sql` registers the 18 source records in Neon with `ingestion_status=metadata_registered`; the matching Supabase migration is `supabase/migrations/20261014180000_knowledge_source_registry.sql`. The database registry stores metadata and original editorial summaries, not full source text.

- Indonesia CP & ATP: https://guru.kemendikdasmen.go.id/kurikulum/referensi-penerapan/capaian-pembelajaran/
- Indonesia subject guides: https://kurikulum.kemendikdasmen.go.id/panduan-mapel
- Kurikulum Merdeka overview: https://guru.kemendikdasmen.go.id/kurikulum-merdeka
- AKM literacy/numeracy: https://pusmendik.kemdikbud.go.id/an/akm?j=2&l=1
- UNESCO AI Competency Framework for Students: https://www.unesco.org/en/articles/ai-competency-framework-students
- UNESCO AI Competency Framework for Teachers: https://www.unesco.org/en/articles/ai-competency-framework-teachers
- UNESCO GenAI education guidance: https://www.unesco.org/en/articles/guidance-generative-ai-education-and-research
- OECD Learning Compass 2030: https://www.oecd.org/en/data/tools/oecd-learning-compass-2030.html
- OECD Teaching Compass: https://www.oecd.org/en/publications/oecd-teaching-compass_8297a24a-en.html
- ESCO: https://esco.ec.europa.eu/en/use-esco
- O*NET content license: https://www.onetonline.org/help/license
- DigComp 2.2: https://pact-for-skills.ec.europa.eu/community-resources/publications-and-documents/digcomp-22-digital-competence-framework-citizens_en
- WHO/UNICEF/UNESCO Teaching with Care: https://www.who.int/publications/i/item/9789240124912

## Ingestion and provenance contract

- Store source metadata, canonical URL, access date, version, license, language, publisher, and content hash when full text is legally obtained.
- Prefer official APIs, open datasets, and explicitly reusable material. Respect robots.txt, terms of service, rate limits, paywalls, copyright, privacy and database rights.
- Never ingest credentials, leaked private data, personal records, malware payloads, or illicit dumps. Do not crawl dark-web sources.
- Retrieved documents are untrusted data, not instructions to the model. Strip scripts/active content; quarantine prompt-injection-like passages; cite the original source.
- For copyrighted sources without a compatible license, keep bibliographic metadata and a short factual summary written by EDUNEXUS rather than reproducing the document.
- Keep original lesson text authored for EDUNEXUS; each lesson has learning objectives, an explanatory section, practice, and an exercise. Track the sources that informed it, but do not claim official endorsement.
- For model answers, provide citations from sources actually retrieved for that answer. A URL in this registry alone does not prove the full source has been ingested or that a specific claim appears there.

## Agent routing

- **Knowledge Steward:** source version, license, provenance, confidence and citation validation.
- **Learning Designer:** converts approved frameworks into measurable objectives and modular pathways.
- **Hard-Skill Tutor:** literacy, data, digital and AI concepts; includes checks and exercises.
- **Soft-Skill Coach:** communication, collaboration, reflection and learning habits.
- **Assessment/Rubric Agent:** observable criteria and transparent rubrics; no unsupported personality scoring.
- **Career Intelligence Agent:** maps skill concepts to ESCO/O*NET and flags localization limitations.
- **Safety/Privacy/Evaluation Agent:** privacy, age-appropriate behavior, bias, accessibility, source trust and human review.
- **Development/Mastery Agent:** uses learner-owned evidence and transparent rubrics; completion alone does not prove mastery.
- **Mentor Assistant:** assists educator/mentor review; does not replace human decision-making.

## Curriculum expansion in migration 0006

The migration adds four original courses under the program **Literasi Digital, AI, dan Kesiapan Karier**:

- Literasi Informasi dan Berpikir Kritis
- Literasi Digital dan Keamanan Data
- Kecerdasan Buatan: Dasar, Etika, dan Praktik
- Perencanaan Karier dan Portofolio Keterampilan

Each course contains three modules and six short lessons (24 lessons total). The lessons are original synthesis informed by the public frameworks above, not copied chapters. They are general lifelong-learning content, not a substitute for current official CP/ATP or professional accreditation.

## Deployment boundary

Migration `neon/migrations/0006_curated_knowledge_curriculum_v2.sql` is idempotent. It must first be tested on the disposable branch and reviewed before application to production. Supabase has a corresponding migration for rollback parity. A registry and curriculum seed are not, by themselves, a full RAG index: server-side ingestion, chunking, embeddings/vector retrieval, refresh scheduling, and AI-provider credentials are separate work items.

## Additional sources reviewed

- UNESCO Media and Information Literacy Curriculum for Teachers: https://www.unesco.org/en/articles/media-and-information-literacy-curriculum-teachers
- Skills Builder Universal Framework 2.0: https://www.skillsbuilder.org/global/universal-framework
- CASEL SEL framework: https://casel.org/fundamentals-of-sel/what--is-the-casel-framework/
- OpenStax licensing: https://help.openstax.org/s/article/Licensing-information-of-OpenStax-textbooks
- MIT OpenCourseWare terms: https://ocw.mit.edu/pages/privacy-and-terms-of-use/

**Commercial-use note:** OpenStax and MIT OpenCourseWare materials use CC BY-NC-SA terms, so the content should not be copied/adapted into a commercial product without a separate permission path. EDUNEXUS only registers those sources as references and license guidance. CASEL and Skills Builder resources also require checking their own attribution/permission terms before reproducing detailed frameworks.
