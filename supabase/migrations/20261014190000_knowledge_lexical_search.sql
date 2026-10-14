-- Lexical retrieval endpoint for the curated EDUNEXUS source registry.
-- This is metadata/summary retrieval, not full-text or vector RAG.
CREATE OR REPLACE FUNCTION public.search_edunexus_knowledge(search_query text, max_results integer DEFAULT 5)
RETURNS TABLE (
 source_id text,
 title text,
 publisher text,
 canonical_url text,
 domain text,
 trust_tier text,
 intended_use text,
 license_notes text,
 agent_roles text[],
 editorial_summary text,
 ingestion_status text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
 SELECT r.source_id,r.title,r.publisher,r.canonical_url,r.domain,r.trust_tier,
        r.intended_use,r.license_notes,r.agent_roles,r.editorial_summary,r.ingestion_status
 FROM public.knowledge_source_registry r
 WHERE coalesce(trim(search_query),'') <> ''
   AND (
     to_tsvector('simple',concat_ws(' ',r.title,r.publisher,r.domain,r.intended_use,r.license_notes,r.editorial_summary,array_to_string(r.agent_roles,' ')))
       @@ plainto_tsquery('simple',search_query)
     OR r.title ILIKE '%' || trim(search_query) || '%'
     OR r.domain ILIKE '%' || trim(search_query) || '%'
   )
 ORDER BY ts_rank(
   to_tsvector('simple',concat_ws(' ',r.title,r.publisher,r.domain,r.intended_use,r.license_notes,r.editorial_summary,array_to_string(r.agent_roles,' '))),
   plainto_tsquery('simple',search_query)
 ) DESC, r.trust_tier ASC, r.title ASC
 LIMIT greatest(1,least(coalesce(max_results,5),10));
$$;
GRANT EXECUTE ON FUNCTION public.search_edunexus_knowledge(text,integer) TO anon, authenticated;
