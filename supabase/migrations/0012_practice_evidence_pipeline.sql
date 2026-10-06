-- EDUNEXUS Practice Evidence Pipeline v1
-- Trusted scoring/finalization plus candidate evidence ingestion.
-- Learners can submit attempts/runs, but only service_role can write scores/results.

create or replace function private.enforce_practice_attempt_lifecycle()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
begin
  if tg_op = 'INSERT' then
    if new.status <> 'in_progress' or new.score is not null or new.submitted_at is not null then
      raise exception 'practice attempt must start in_progress without score';
    end if;
    return new;
  end if;

  if old.status <> 'in_progress' then
    raise exception 'practice attempt is immutable after submission or cancellation';
  end if;

  if current_user = 'service_role' then
    if new.status = 'submitted' then
      if new.submitted_at is null or new.score is null or new.score < 0 or new.score > 100 then
        raise exception 'trusted practice completion requires submitted_at and score 0..100';
      end if;
    elsif new.status = 'cancelled' then
      if new.submitted_at is null then raise exception 'cancelled practice attempt requires submitted_at'; end if;
      if new.score is not null then raise exception 'cancelled practice attempt cannot have score'; end if;
    elsif new.status <> 'in_progress' then
      raise exception 'invalid trusted practice attempt transition';
    end if;
    return new;
  end if;

  if new.status = 'in_progress' then
    if new.submitted_at is not null or new.score is distinct from old.score then
      raise exception 'invalid in_progress practice attempt update';
    end if;
  elsif new.status in ('submitted','cancelled') then
    if new.submitted_at is null or new.score is distinct from old.score then
      raise exception 'invalid practice attempt submission state';
    end if;
  else
    raise exception 'invalid practice attempt transition';
  end if;

  if new.id <> old.id or new.session_id <> old.session_id or new.user_id <> old.user_id
     or new.attempt_number <> old.attempt_number or new.created_at <> old.created_at
     or new.score is distinct from old.score then
    raise exception 'practice attempt protected fields cannot be changed by learner';
  end if;
  return new;
end;
$$;

create or replace function private.enforce_simulation_run_lifecycle()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
begin
  if tg_op = 'INSERT' then
    if new.status <> 'in_progress' or new.completed_at is not null or new.result <> '{}'::jsonb then
      raise exception 'simulation run must start in_progress without result';
    end if;
    return new;
  end if;

  if old.status <> 'in_progress' then
    raise exception 'simulation run is immutable after completion or cancellation';
  end if;

  if current_user = 'service_role' then
    if new.status = 'completed' then
      if new.completed_at is null or new.result = '{}'::jsonb then
        raise exception 'trusted simulation completion requires completed_at and result';
      end if;
    elsif new.status = 'cancelled' then
      if new.completed_at is null or new.result <> old.result then
        raise exception 'invalid trusted simulation cancellation';
      end if;
    elsif new.status <> 'in_progress' then
      raise exception 'invalid trusted simulation transition';
    end if;
    return new;
  end if;

  if new.status = 'in_progress' then
    if new.completed_at is not null or new.result <> old.result then
      raise exception 'invalid in_progress simulation update';
    end if;
  elsif new.status in ('completed','cancelled') then
    if new.completed_at is null or new.result <> old.result then
      raise exception 'simulation result is controlled and cannot be written by learner';
    end if;
  else
    raise exception 'invalid simulation run transition';
  end if;

  if new.id <> old.id or new.user_id <> old.user_id or new.scenario_id <> old.scenario_id
     or new.mode <> old.mode or new.started_at <> old.started_at or new.created_at <> old.created_at then
    raise exception 'simulation run protected fields cannot be changed by learner';
  end if;
  return new;
end;
$$;

create or replace function private.finalize_practice_attempt(
  p_attempt_id uuid,
  p_score numeric
)
returns public.practice_attempts
language plpgsql
security definer
set search_path=public,private
as $$
declare v_row public.practice_attempts;
begin
  if p_score is null or p_score < 0 or p_score > 100 then
    raise exception 'score must be between 0 and 100';
  end if;
  update public.practice_attempts
     set score=round(p_score,2)
   where id=p_attempt_id and status='submitted' and score is null
   returning * into v_row;
  if v_row.id is null then raise exception 'practice attempt must be submitted and unscored'; end if;
  return v_row;
end;
$$;

create or replace function private.ingest_practice_evidence(p_attempt_id uuid)
returns integer
language plpgsql
security definer
set search_path=public,private
as $$
declare v_user_id uuid; v_scenario_id uuid; v_score numeric; r record; v_count integer := 0; v_key text;
begin
  select a.user_id,s.scenario_id,a.score into v_user_id,v_scenario_id,v_score
  from public.practice_attempts a join public.practice_sessions s on s.id=a.session_id
  where a.id=p_attempt_id and a.status='submitted' and a.score is not null;
  if v_user_id is null then raise exception 'practice attempt must be submitted and scored'; end if;

  for r in select skill_id, target_weight from public.scenario_skill_targets where scenario_id=v_scenario_id loop
    v_key := format('practice:%s:skill:%s',p_attempt_id,r.skill_id);
    perform private.record_skill_evidence_candidate(
      v_user_id,r.skill_id,'practice_attempt',p_attempt_id,'practice_result',
      format('Scored practice evidence from attempt %s.',p_attempt_id),
      least(100,greatest(0,v_score)),1.0,
      jsonb_build_object('pipeline_version','practice-evidence-pipeline-v1','source','practice_attempt','attempt_id',p_attempt_id,'scenario_id',v_scenario_id,'target_weight',r.target_weight),
      v_key
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

create or replace function private.finalize_simulation_run(
  p_run_id uuid,
  p_result jsonb
)
returns public.simulation_runs
language plpgsql
security definer
set search_path=public,private
as $$
declare v_row public.simulation_runs;
begin
  if p_result is null or p_result = '{}'::jsonb then raise exception 'simulation result is required'; end if;
  update public.simulation_runs
     set status='completed', completed_at=now(), result=p_result
   where id=p_run_id and status='in_progress'
   returning * into v_row;
  if v_row.id is null then raise exception 'simulation run must be in progress'; end if;
  return v_row;
end;
$$;

create or replace function private.ingest_simulation_evidence(p_run_id uuid)
returns integer
language plpgsql
security definer
set search_path=public,private
as $$
declare v_user_id uuid; v_scenario_id uuid; v_result jsonb; r record; v_count integer := 0; v_key text;
begin
  select user_id,scenario_id,result into v_user_id,v_scenario_id,v_result
  from public.simulation_runs where id=p_run_id and status='completed';
  if v_user_id is null then raise exception 'simulation run must be completed'; end if;
  if jsonb_typeof(v_result->'skill_scores') <> 'object' then
    raise exception 'simulation result must contain object skill_scores';
  end if;

  for r in
    select t.skill_id, (v_result->'skill_scores'->>t.skill_id::text)::numeric as score
    from public.scenario_skill_targets t
    where t.scenario_id=v_scenario_id
      and (v_result->'skill_scores' ? t.skill_id::text)
  loop
    if r.score < 0 or r.score > 100 then raise exception 'simulation skill score must be 0..100'; end if;
    v_key := format('simulation:%s:skill:%s',p_run_id,r.skill_id);
    perform private.record_skill_evidence_candidate(
      v_user_id,r.skill_id,'simulation_run',p_run_id,'simulation_result',
      format('Completed simulation evidence from run %s.',p_run_id),
      round(r.score,2),1.0,
      jsonb_build_object('pipeline_version','practice-evidence-pipeline-v1','source','simulation_run','run_id',p_run_id,'scenario_id',v_scenario_id),
      v_key
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function private.finalize_practice_attempt(uuid,numeric),
  private.ingest_practice_evidence(uuid),
  private.finalize_simulation_run(uuid,jsonb),
  private.ingest_simulation_evidence(uuid)
from public,anon,authenticated;
grant execute on function private.finalize_practice_attempt(uuid,numeric),
  private.ingest_practice_evidence(uuid),
  private.finalize_simulation_run(uuid,jsonb),
  private.ingest_simulation_evidence(uuid)
to service_role;

create index if not exists idx_practice_evidence_source_lineage
  on public.skill_evidence(source_type,source_id)
  where source_type in ('practice_attempt','simulation_run');
