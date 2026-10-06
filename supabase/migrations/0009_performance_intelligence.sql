-- EDUNEXUS Performance Intelligence Core v1
-- Derived observation/metric boundaries, source lineage, skill targets,
-- and trusted workflow entry points.

create table if not exists public.performance_observation_sources (
  id uuid primary key default gen_random_uuid(),
  observation_id uuid not null references public.performance_observations(id) on delete cascade,
  source_type text not null check (source_type in ('live_session','practice_session','practice_attempt','simulation_run','simulation_event','assessment_attempt')),
  source_id uuid not null,
  created_at timestamptz not null default now(),
  unique (observation_id),
  unique (source_type, source_id, observation_id)
);

create table if not exists public.performance_observation_skill_targets (
  id uuid primary key default gen_random_uuid(),
  observation_id uuid not null references public.performance_observations(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete restrict,
  competency_id uuid references public.competencies(id) on delete restrict,
  relevance numeric(6,3) not null default 1.0 check (relevance > 0 and relevance <= 1),
  created_at timestamptz not null default now(),
  unique (observation_id, skill_id, competency_id)
);

alter table public.performance_observations
  add column if not exists observation_status text not null default 'candidate'
    check (observation_status in ('candidate','reviewed','rejected')),
  add column if not exists observed_duration_ms bigint
    check (observed_duration_ms is null or observed_duration_ms >= 0);

alter table public.performance_metrics
  add column if not exists metric_status text not null default 'candidate'
    check (metric_status in ('candidate','accepted','rejected')),
  add column if not exists confidence numeric(5,4)
    check (confidence is null or (confidence >= 0 and confidence <= 1));

create index if not exists idx_observation_sources_source on public.performance_observation_sources(source_type, source_id);
create index if not exists idx_observation_targets_skill on public.performance_observation_skill_targets(skill_id, observation_id);
create index if not exists idx_observations_status on public.performance_observations(subject_user_id, observation_status, observed_at desc);
create index if not exists idx_metrics_status on public.performance_metrics(observation_id, metric_status);

alter table public.performance_observation_sources enable row level security;
alter table public.performance_observation_skill_targets enable row level security;
revoke all on public.performance_observation_sources, public.performance_observation_skill_targets from anon, authenticated;
grant select on public.performance_observation_sources, public.performance_observation_skill_targets to authenticated;

create policy performance_observation_sources_select_authorized on public.performance_observation_sources for select to authenticated using (
  exists (select 1 from public.performance_observations o where o.id=performance_observation_sources.observation_id and private.can_access_user(o.subject_user_id))
);
create policy performance_observation_targets_select_authorized on public.performance_observation_skill_targets for select to authenticated using (
  exists (select 1 from public.performance_observations o where o.id=performance_observation_skill_targets.observation_id and private.can_access_user(o.subject_user_id))
);

alter table public.performance_observations drop constraint if exists performance_observations_confidence_check;
alter table public.performance_observations add constraint performance_observations_confidence_check check (confidence is null or (confidence >= 0 and confidence <= 1));
alter table public.performance_metrics drop constraint if exists performance_metrics_value_finite_check;
alter table public.performance_metrics add constraint performance_metrics_value_finite_check check (metric_value is null or metric_value between -100000000 and 100000000);

revoke insert, update, delete on public.performance_observations, public.performance_metrics from authenticated;

create or replace function private.record_performance_observation(
  p_session_id uuid, p_subject_user_id uuid, p_observation_type text, p_data jsonb,
  p_ai_model text default null, p_confidence numeric default null,
  p_provenance jsonb default '{}'::jsonb, p_source_type text default 'live_session',
  p_source_id uuid default null
) returns uuid
language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_id uuid;
begin
  if p_subject_user_id is null or p_observation_type is null then raise exception 'observation subject and type are required'; end if;
  insert into public.performance_observations(session_id,subject_user_id,observation_type,data,ai_model,confidence,provenance)
  values(p_session_id,p_subject_user_id,p_observation_type,coalesce(p_data,'{}'::jsonb),p_ai_model,p_confidence,coalesce(p_provenance,'{}'::jsonb))
  returning id into v_id;
  if p_source_id is not null then
    insert into public.performance_observation_sources(observation_id,source_type,source_id)
    values(v_id,p_source_type,p_source_id);
  end if;
  return v_id;
end; $$;

create or replace function private.record_performance_metric(
  p_observation_id uuid, p_metric_key text, p_metric_value numeric,
  p_unit text default null, p_evidence jsonb default '{}'::jsonb,
  p_confidence numeric default null
) returns uuid
language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_id uuid;
begin
  if p_metric_key is null or p_metric_key='' then raise exception 'metric key is required'; end if;
  if not exists(select 1 from public.performance_observations where id=p_observation_id) then raise exception 'performance observation not found'; end if;
  insert into public.performance_metrics(observation_id,metric_key,metric_value,unit,evidence,confidence)
  values(p_observation_id,p_metric_key,p_metric_value,p_unit,coalesce(p_evidence,'{}'::jsonb),p_confidence)
  returning id into v_id;
  return v_id;
end; $$;

revoke all on function private.record_performance_observation(uuid,uuid,text,jsonb,text,numeric,jsonb,text,uuid) from public,anon,authenticated;
revoke all on function private.record_performance_metric(uuid,text,numeric,text,jsonb,numeric) from public,anon,authenticated;

create or replace function private.mark_observation_reviewed(p_observation_id uuid,p_status text)
returns void language plpgsql security definer set search_path=pg_catalog,public as $$
begin
  if p_status not in ('reviewed','rejected') then raise exception 'invalid observation review status'; end if;
  update public.performance_observations set observation_status=p_status where id=p_observation_id;
  if not found then raise exception 'performance observation not found'; end if;
end; $$;

revoke all on function private.mark_observation_reviewed(uuid,text) from public,anon,authenticated;
