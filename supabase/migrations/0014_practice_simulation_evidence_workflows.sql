-- Trusted practice/simulation finalization and evidence ingestion.
create or replace function private.finalize_practice_attempt(p_attempt_id uuid,p_score numeric)
returns public.practice_attempts language plpgsql security definer set search_path=public,private as $$
declare v_row public.practice_attempts;
begin
 if p_score is null or p_score<0 or p_score>100 then raise exception 'score must be between 0 and 100'; end if;
 update public.practice_attempts set score=round(p_score,2) where id=p_attempt_id and status='submitted' and score is null returning * into v_row;
 if v_row.id is null then raise exception 'practice attempt must be submitted and unscored'; end if;
 return v_row;
end; $$;

create or replace function private.ingest_practice_evidence(p_attempt_id uuid)
returns integer language plpgsql security definer set search_path=public,private as $$
declare v_user_id uuid; v_scenario_id uuid; v_score numeric; r record; v_count integer:=0; v_key text;
begin
 select a.user_id,s.scenario_id,a.score into v_user_id,v_scenario_id,v_score from public.practice_attempts a join public.practice_sessions s on s.id=a.session_id where a.id=p_attempt_id and a.status='submitted' and a.score is not null;
 if v_user_id is null then raise exception 'practice attempt must be submitted and scored'; end if;
 for r in select skill_id,target_weight from public.scenario_skill_targets where scenario_id=v_scenario_id loop
  v_key:=format('practice:%s:skill:%s',p_attempt_id,r.skill_id);
  perform private.record_skill_evidence_candidate(v_user_id,r.skill_id,'practice_attempt',p_attempt_id,'practice_result',format('Scored practice evidence from attempt %s.',p_attempt_id),least(100,greatest(0,v_score)),1.0,jsonb_build_object('pipeline_version','practice-evidence-pipeline-v1','source','practice_attempt','attempt_id',p_attempt_id,'scenario_id',v_scenario_id,'target_weight',r.target_weight),v_key);
  v_count:=v_count+1;
 end loop;
 return v_count;
end; $$;

create or replace function private.finalize_simulation_run(p_run_id uuid,p_result jsonb)
returns public.simulation_runs language plpgsql security definer set search_path=public,private as $$
declare v_row public.simulation_runs;
begin
 if p_result is null or p_result='{}'::jsonb then raise exception 'simulation result is required'; end if;
 update public.simulation_runs set status='completed',completed_at=now(),result=p_result where id=p_run_id and status='in_progress' returning * into v_row;
 if v_row.id is null then raise exception 'simulation run must be in progress'; end if;
 return v_row;
end; $$;

create or replace function private.ingest_simulation_evidence(p_run_id uuid)
returns integer language plpgsql security definer set search_path=public,private as $$
declare v_user_id uuid; v_scenario_id uuid; v_result jsonb; r record; v_count integer:=0; v_key text;
begin
 select user_id,scenario_id,result into v_user_id,v_scenario_id,v_result from public.simulation_runs where id=p_run_id and status='completed';
 if v_user_id is null then raise exception 'simulation run must be completed'; end if;
 if jsonb_typeof(v_result->'skill_scores')<>'object' then raise exception 'simulation result must contain object skill_scores'; end if;
 for r in select t.skill_id,(v_result->'skill_scores'->>t.skill_id::text)::numeric as score from public.scenario_skill_targets t where t.scenario_id=v_scenario_id and (v_result->'skill_scores' ? t.skill_id::text) loop
  if r.score<0 or r.score>100 then raise exception 'simulation skill score must be 0..100'; end if;
  v_key:=format('simulation:%s:skill:%s',p_run_id,r.skill_id);
  perform private.record_skill_evidence_candidate(v_user_id,r.skill_id,'simulation_run',p_run_id,'simulation_result',format('Completed simulation evidence from run %s.',p_run_id),round(r.score,2),1.0,jsonb_build_object('pipeline_version','practice-evidence-pipeline-v1','source','simulation_run','run_id',p_run_id,'scenario_id',v_scenario_id),v_key);
  v_count:=v_count+1;
 end loop;
 return v_count;
end; $$;

revoke all on function private.finalize_practice_attempt(uuid,numeric),private.ingest_practice_evidence(uuid),private.finalize_simulation_run(uuid,jsonb),private.ingest_simulation_evidence(uuid) from public,anon,authenticated;
grant execute on function private.finalize_practice_attempt(uuid,numeric),private.ingest_practice_evidence(uuid),private.finalize_simulation_run(uuid,jsonb),private.ingest_simulation_evidence(uuid) to service_role;
create index if not exists idx_practice_evidence_source_lineage on public.skill_evidence(source_type,source_id) where source_type in ('practice_attempt','simulation_run');