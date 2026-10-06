-- Remove redundant index superseded by the foundation source-lineage index.
drop index if exists public.idx_skill_evidence_source_lineage;