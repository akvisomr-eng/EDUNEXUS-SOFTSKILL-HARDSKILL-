-- EDUNEXUS Project Builder records. Draft only; not applied to any database.
-- Test on a Neon preview branch and verify JWT role mapping before production use.
BEGIN;

CREATE TABLE IF NOT EXISTS public.ai_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 180),
  brief text NOT NULL CHECK (char_length(brief) BETWEEN 1 AND 12000),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft','planning','planned','in_progress','review','completed','blocked','archived')),
  mode text NOT NULL DEFAULT 'planning' CHECK (mode IN ('planning','patch_review','execution')),
  repository_url text CHECK (repository_url IS NULL OR repository_url ~ '^https://github[.]com/[^/]+/[^/]+/?$'),
  repository_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_column_size(metadata) <= 16384),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, owner_id)
);

CREATE TABLE IF NOT EXISTS public.ai_project_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,
  owner_id uuid NOT NULL,
  parent_task_id uuid REFERENCES public.ai_project_tasks(id) ON DELETE SET NULL,
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 240),
  description text NOT NULL DEFAULT '' CHECK (char_length(description) <= 12000),
  assigned_agent text NOT NULL CHECK (assigned_agent IN ('projectManager','architect','engineer','qa')),
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','running','needs_review','succeeded','failed','cancelled')),
  priority smallint NOT NULL DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
  sequence_no integer NOT NULL DEFAULT 0 CHECK (sequence_no >= 0),
  input_refs jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (pg_column_size(input_refs) <= 8192),
  acceptance_criteria jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (pg_column_size(acceptance_criteria) <= 8192),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (project_id, sequence_no, id),
  UNIQUE (id, owner_id),
  FOREIGN KEY (project_id, owner_id) REFERENCES public.ai_projects(id, owner_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.ai_agent_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,
  task_id uuid REFERENCES public.ai_project_tasks(id) ON DELETE SET NULL,
  owner_id uuid NOT NULL,
  agent_id text NOT NULL CHECK (agent_id IN ('projectManager','architect','engineer','qa')),
  provider_id text,
  model_id text,
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','running','succeeded','failed','cancelled','needs_review')),
  input_digest text,
  output_summary text CHECK (output_summary IS NULL OR char_length(output_summary) <= 16000),
  source_refs jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (pg_column_size(source_refs) <= 8192),
  usage jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_column_size(usage) <= 4096),
  error_code text,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at),
  FOREIGN KEY (project_id, owner_id) REFERENCES public.ai_projects(id, owner_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.ai_project_artifacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,
  task_id uuid REFERENCES public.ai_project_tasks(id) ON DELETE SET NULL,
  owner_id uuid NOT NULL,
  artifact_type text NOT NULL CHECK (artifact_type IN ('project_brief','architecture','plan','patch','test_report','review','release_note')),
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 240),
  content text NOT NULL CHECK (char_length(content) <= 100000),
  content_sha256 text NOT NULL CHECK (content_sha256 ~ '^[a-f0-9]{64}$'),
  review_status text NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending','approved','rejected','superseded')),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((review_status = 'pending' AND reviewed_at IS NULL AND reviewed_by IS NULL)
      OR (review_status <> 'pending' AND reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL)),
  FOREIGN KEY (project_id, owner_id) REFERENCES public.ai_projects(id, owner_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.ai_project_audit_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  project_id uuid,
  owner_id uuid NOT NULL,
  actor_id uuid,
  event_type text NOT NULL CHECK (event_type IN ('project_created','project_updated','task_created','task_status_changed',
    'agent_started','agent_finished','artifact_created','artifact_reviewed','repository_read','patch_proposed',
    'patch_checked','ci_started','ci_finished','release_approved','release_blocked')),
  target_type text,
  target_id text,
  outcome text NOT NULL CHECK (outcome IN ('allowed','denied','success','failure','pending_review')),
  details jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_column_size(details) <= 8192),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (project_id, owner_id) REFERENCES public.ai_projects(id, owner_id) ON DELETE SET NULL (project_id)
);

CREATE INDEX IF NOT EXISTS ai_projects_owner_updated_idx ON public.ai_projects (owner_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS ai_project_tasks_owner_status_idx ON public.ai_project_tasks (owner_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS ai_project_tasks_project_order_idx ON public.ai_project_tasks (project_id, sequence_no);
CREATE INDEX IF NOT EXISTS ai_agent_runs_project_created_idx ON public.ai_agent_runs (project_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ai_agent_runs_owner_status_idx ON public.ai_agent_runs (owner_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS ai_project_artifacts_project_created_idx ON public.ai_project_artifacts (project_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ai_project_audit_project_created_idx ON public.ai_project_audit_events (project_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ai_project_audit_owner_created_idx ON public.ai_project_audit_events (owner_id, created_at DESC);

ALTER TABLE public.ai_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_project_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_project_artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_project_audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ai_projects_owner_read ON public.ai_projects;
CREATE POLICY ai_projects_owner_read ON public.ai_projects FOR SELECT TO authenticated USING (owner_id = auth.uid());
DROP POLICY IF EXISTS ai_project_tasks_owner_read ON public.ai_project_tasks;
CREATE POLICY ai_project_tasks_owner_read ON public.ai_project_tasks FOR SELECT TO authenticated USING (owner_id = auth.uid());
DROP POLICY IF EXISTS ai_agent_runs_owner_read ON public.ai_agent_runs;
CREATE POLICY ai_agent_runs_owner_read ON public.ai_agent_runs FOR SELECT TO authenticated USING (owner_id = auth.uid());
DROP POLICY IF EXISTS ai_project_artifacts_owner_read ON public.ai_project_artifacts;
CREATE POLICY ai_project_artifacts_owner_read ON public.ai_project_artifacts FOR SELECT TO authenticated USING (owner_id = auth.uid());
DROP POLICY IF EXISTS ai_project_audit_owner_read ON public.ai_project_audit_events;
CREATE POLICY ai_project_audit_owner_read ON public.ai_project_audit_events FOR SELECT TO authenticated USING (owner_id = auth.uid());

REVOKE ALL ON public.ai_projects, public.ai_project_tasks, public.ai_agent_runs,
  public.ai_project_artifacts, public.ai_project_audit_events FROM PUBLIC, anonymous;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.ai_projects,
  public.ai_project_tasks, public.ai_agent_runs, public.ai_project_artifacts,
  public.ai_project_audit_events FROM authenticated;
GRANT SELECT ON public.ai_projects, public.ai_project_tasks, public.ai_agent_runs,
  public.ai_project_artifacts, public.ai_project_audit_events TO authenticated;

COMMIT;
