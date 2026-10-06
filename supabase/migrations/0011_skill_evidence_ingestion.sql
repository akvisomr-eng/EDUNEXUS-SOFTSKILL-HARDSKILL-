-- EDUNEXUS Skill Evidence Ingestion v1
-- Converts reviewed assessment/performance outputs into candidate evidence.
-- Human verification remains a separate authoritative step.

create or replace function private.ingest_assessment_evidence(p_attempt_id uuid)
returns integer language plpgsql security definer set search_path=public,private as $$
declare v_user_id uuid; v_count integer := 0; r record; v_key text;
begin
  select user_id into v_user_id from public.assessment_attempts where id=p_attempt_id and status='reviewed';
  if v_user_id is null then raise exception 'assessment attempt must exist and be reviewed'; end if;
  for r in
    select t.skill_id,
      round(100 * sum(coalesce(a.awarded_points,0) * t.weight) / nullif(sum(i.points * t.weight),0),2) as score,
      count(*)::integer as item_count
    from public.assessment_answers a
    join public.assessment_items i on i.id=a.item_id
    join public.assessment_item_skill_targets t on t.item_id=i.id
    where a.attempt_id=p_attempt_id and a.evaluated_at is not null
    group by t.skill_id
  loop
    v_key := format('assessment:%s:skill:%s',p_attempt_id,r.skill_id);
    perform private.record_skill_evidence_candidate(
      v_user_id,r.skill_id,'assessment_attempt',p_attempt_id,'assessment_result',
      format('Reviewed assessment evidence from attempt %s across %s targeted items.',p_attempt_id,r.item_count),
      least(100,greatest(0,r.score)),1.0,
      jsonb_build_object('pipeline_version','skill-evidence-ingestion-v1','source','assessment_attempt','attempt_id',p_attempt_id,'item_count',r.item_count),
      v_key
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end; $$;

create or replace function private.ingest_performance_evidence(p_observation_id uuid)
returns integer language plpgsql security definer set search_path=public,private as $$
declare v_user_id uuid; v_status text; r record; v_key text; v_count integer := 0;
begin
  select subject_user_id,observation_status into v_user_id,v_status from public.performance_observations where id=p_observation_id;
  if v_user_id is null then raise exception 'performance observation not found'; end if;
  if v_status <> 'reviewed' then raise exception 'performance observation must be reviewed'; end if;
  for r in
    select t.skill_id,round(avg(pm.metric_value)::numeric,2) as score,avg(pm.confidence) as confidence
    from public.performance_observation_skill_targets t
    join public.performance_metrics pm on pm.observation_id=t.observation_id
    where t.observation_id=p_observation_id and pm.metric_status='accepted'
      and pm.metric_value is not null and pm.metric_value between 0 and 100
    group by t.skill_id
  loop
    v_key := format('performance:%s:skill:%s',p_observation_id,r.skill_id);
    perform private.record_skill_evidence_candidate(
      v_user_id,r.skill_id,'performance_observation',p_observation_id,'performance_observation',
      format('Reviewed performance evidence from observation %s.',p_observation_id),
      least(100,greatest(0,r.score)),coalesce(r.confidence,1.0),
      jsonb_build_object('pipeline_version','skill-evidence-ingestion-v1','source','performance_observation','observation_id',p_observation_id),
      v_key
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end; $$;

revoke all on function private.ingest_assessment_evidence(uuid) from public,anon,authenticated;
revoke all on function private.ingest_performance_evidence(uuid) from public,anon,authenticated;
grant execute on function private.ingest_assessment_evidence(uuid) to service_role;
grant execute on function private.ingest_performance_evidence(uuid) to service_role;

create index if not exists idx_skill_evidence_source_lineage on public.skill_evidence(source_type,source_id);
create index if not exists idx_skill_evidence_user_skill_status on public.skill_evidence(user_id,skill_id,status);