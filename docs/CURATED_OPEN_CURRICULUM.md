# EDUNEXUS curated open-source curriculum registry

This is a curated, traceable first ingestion batch, not a claim to mirror the entire internet. Lessons are original Indonesian instructional summaries and exercises; public sources are linked for further reading. The application stores source titles, URLs, and reuse notes with lesson content.

## Source registry

| Source | Purpose in EDUNEXUS | Reuse boundary |
|---|---|---|
| Kemendikdasmen / official curriculum announcements | Track current Indonesian education policy and official curriculum decisions | Link to official documents; verify the actual decree/attachment and current validity before representing any content as binding curriculum |
| UNESCO AI Competency Framework for Students | AI literacy, ethics, techniques, human-centred use and progression | Referenced conceptually; not reproduced verbatim |
| UNESCO AI Competency Framework for Teachers | Educator guidance, rights, human agency and responsible use | Referenced conceptually; not reproduced verbatim |
| ESCO | Skills, competences, qualifications and occupations taxonomy; career guidance | Link to API/download documentation; review the applicable dataset and software licenses before importing bulk records |
| O*NET Resource Center | Occupation and skills data | Link to official database; check data-specific attribution and terms before importing |
| MIT OpenCourseWare | Further learning materials | Materials are generally CC BY-NC-SA; do not copy or adapt into a commercial product without a compatible right. Link-only references are used here |
| Creative Commons | License explanations and legal-code links | Check the actual license and rights for each asset; a web-accessible file is not automatically reusable |

## Included curriculum

- **Literasi AI dan Penggunaan yang Bertanggung Jawab** — 4 lessons
- **Literasi Informasi dan Data Digital** — 4 lessons
- **Kesiapan Karier dan Portofolio Keterampilan** — 4 lessons

Each lesson includes objectives, original explanation, practice, exercise, sources, and a reuse note. The starter course content is not an official qualification, national curriculum substitute, or certification.

## Deployment files

- Neon: `neon/migrations/0006_curated_open_curriculum.sql`
- Supabase rollback: `supabase/migrations/20261014150000_curated_open_curriculum.sql`

The migration is idempotent. Apply first to the disposable Neon test branch, verify program/course/module/lesson counts, then apply to production only after tests pass. Supabase is not modified by this migration automatically.
