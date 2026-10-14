-- Attach safe, explicit source links to the new curriculum lesson payloads.
-- The frontend only renders the sources array; source_ids remains for traceability.
BEGIN;
UPDATE public.lessons l
SET content = jsonb_set(
  jsonb_set(
    l.content,
    '{sources}',
    COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object('title', ks.title, 'url', ks.url, 'note', ks.license_note)
        ORDER BY ks.source_key
      )
      FROM public.knowledge_sources ks
      WHERE ks.source_key = ANY(string_to_array(l.content->>'source_ids', ','))
    ), '[]'::jsonb),
    true
  ),
  '{license_note}',
  to_jsonb('Materi penjelasan dan latihan ditulis orisinal oleh EDUNEXUS. Tautan sumber disertakan untuk bacaan lanjutan; ikuti catatan lisensi setiap sumber.'::text),
  true
)
WHERE l.content ? 'source_ids'
  AND EXISTS (
    SELECT 1 FROM public.modules m
    JOIN public.courses c ON c.id=m.course_id
    WHERE m.id=l.module_id
      AND c.slug IN (
        'literasi-ai-etika',
        'literasi-digital-keamanan',
        'literasi-data-berpikir-kritis',
        'pembelajaran-mandiri-metakognisi',
        'keterampilan-kerja-komunikasi-karier'
      )
  );
COMMIT;
