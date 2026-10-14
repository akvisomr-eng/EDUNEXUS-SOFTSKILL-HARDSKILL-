# Lesson source links

The learner lesson reader renders `content.sources` as safe HTTPS links and displays `content.license_note`. The curated knowledge curriculum stores source IDs for provenance; migration `0008_lesson_source_links.sql` resolves those IDs through `public.knowledge_sources` into title, URL and license note objects. It does not copy third-party source text.
