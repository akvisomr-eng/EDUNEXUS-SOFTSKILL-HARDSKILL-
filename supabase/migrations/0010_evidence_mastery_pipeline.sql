-- EDUNEXUS Evidence & Mastery Pipeline v1
-- Controlled evidence verification, longitudinal mastery, development events,
-- and skill passport projection. Client roles remain read-only.

alter table public.skill_evidence
  add column if not exists score numeric(5,2);

alter table public.skill_evidence
  drop constraint if exists skill_evidence_score_range;

alter table public.skill_evidence
  add constraint skill_evidence_score_range
  check (score is null or (score >= 0 and score <= 100));

alter table public.skill_evidence
  add column if not exists idempotency_key text;

create unique index if not exists skill_evidence_idempotency_key_uidx
  on public.skill_evidence (idempotency_key)
  where idempotency_key is not null;

create unique index if not exists development_events_source_uidx
  on public.development_events (event_type, source_id)
  where source_id is not null;

create or replace function private.record_skill_evidence_candidate(
  p_user_id uuid, p_skill_id uuid, p_source_type text, p_source_id uuid,
  p_evidence_type text, p_summary text, p_score numeric, p_confidence numeric,
  p_provenance jsonb, p_idempotency_key text
) returns uuid
language plpgsql security definer set search_path = public, private as $$
declare v_id uuid;
begin
  if p_user_id is null or p_skill_id is null or p_source_type is null or p_evidence_type is null then
    raise exception 'user, skill, source_type and evidence_type are required';
  end if;
  if p_score is not null and (p_score < 0 or p_score > 100) then raise exception 'score must be between 0 and 100'; end if;
  if p_confidence is not null and (p_confidence < 0 or p_confidence > 1) then raise exception 'confidence must be between 0 and 1'; end if;
  if p_idempotency_key is not null then
    select id into v_id from public.skill_evidence where idempotency_key=p_idempotency_key limit 1;
    if v_id is not null then return v_id; end if;
  end if;
  insert into public.skill_evidence(
    user_id,skill_id,evidence_type,source_id,source_type,status,summary,score,confidence,provenance
  ) values (
    p_user_id,p_skill_id,p_evidence_type,p_source_id,p_source_type,'candidate',
    p_summary,p_score,p_confidence,coalesce(p_provenance,'{}'::jsonb)
  ) returning id into v_id;
  if p_idempotency_key is not null then
    update public.skill_evidence set idempotency_key=p_idempotency_key where id=v_id;
  end if;
  return v_id;
exception when unique_violation then
  select id into v_id from public.skill_evidence where idempotency_key=p_idempotency_key limit 1;
  if v_id is not null then return v_id; end if;
  raise;
end; $$;

create or replace function private.verify_skill_evidence(p_evidence_id uuid,p_reviewer_id uuid)
returns uuid language plpgsql security definer set search_path=public,private as $$
declare v_user_id uuid; v_status text;
begin
  select user_id,status into v_user_id,v_status from public.skill_evidence where id=p_evidence_id for update;
  if v_user_id is null then raise exception 'evidence not found'; end if;
  if v_status='verified' then return p_evidence_id; end if;
  if v_status <> 'candidate' then raise exception 'only candidate evidence can be verified'; end if;
  if p_reviewer_id is null or not exists (
    select 1 from public.mentor_student_relationships r
    where r.mentor_user_id=p_reviewer_id and r.student_user_id=v_user_id and r.status='active'
  ) then raise exception 'reviewer is not an active mentor for the evidence owner'; end if;
  update public.skill_evidence set status='verified',verified_by=p_reviewer_id,verified_at=now()
  where id=p_evidence_id;
  return p_evidence_id;
end; $$;

create or replace function private.recompute_skill_mastery(
  p_user_id uuid,p_skill_id uuid,p_source_evidence_id uuid default null
) returns uuid language plpgsql security definer set search_path=public,private as $$
declare v_score numeric(5,2); v_level smallint; v_evidence_count integer; v_mastery_id uuid;
begin
  select round(avg(score)::numeric,2),count(*)::integer into v_score,v_evidence_count
  from public.skill_evidence
  where user_id=p_user_id and skill_id=p_skill_id and status='verified' and score is not null;
  if v_evidence_count=0 then return null; end if;
  v_level := case when v_score>=95 then 7 when v_score>=85 then 6 when v_score>=75 then 5
    when v_score>=65 then 4 when v_score>=50 then 3 when v_score>=35 then 2
    when v_score>=20 then 1 else 0 end;
  insert into public.mastery_records(user_id,skill_id,level_id,score,evidence_count,assessed_at)
  values(p_user_id,p_skill_id,v_level,v_score,v_evidence_count,now())
  on conflict (user_id,skill_id) do update set
    level_id=excluded.level_id,score=excluded.score,evidence_count=excluded.evidence_count,assessed_at=excluded.assessed_at
  returning id into v_mastery_id;
  insert into public.mastery_history(
    user_id,skill_id,level_id,score,evidence_count,source_evidence_id,recorded_at,reason,metadata
  ) values (
    p_user_id,p_skill_id,v_level,v_score,v_evidence_count,p_source_evidence_id,now(),
    'verified_evidence_recomputed',jsonb_build_object('pipeline_version','evidence-mastery-pipeline-v1')
  );
  insert into public.development_events(
    user_id,skill_id,event_type,summary,source_id,occurred_at,metadata
  ) values (
    p_user_id,p_skill_id,'mastery_updated',
    format('Mastery updated to %s (%s/100) from %s verified evidence.',v_level,v_score,v_evidence_count),
    coalesce(p_source_evidence_id,v_mastery_id),now(),
    jsonb_build_object('pipeline_version','evidence-mastery-pipeline-v1','level_id',v_level,'score',v_score,'evidence_count',v_evidence_count)
  ) on conflict (event_type,source_id) do nothing;
  return v_mastery_id;
end; $$;

create or replace function private.refresh_skill_passport(p_user_id uuid)
returns uuid language plpgsql security definer set search_path=public,private as $$
declare v_id uuid; v_version integer; v_snapshot jsonb;
begin
  select coalesce(max(version),0)+1 into v_version from public.skill_passports where user_id=p_user_id;
  select jsonb_build_object(
    'user_id',p_user_id,'generated_at',now(),
    'mastery',coalesce((
      select jsonb_agg(jsonb_build_object(
        'skill_id',m.skill_id,'level_id',m.level_id,'score',m.score,
        'evidence_count',m.evidence_count,'assessed_at',m.assessed_at
      ) order by m.skill_id) from public.mastery_records m where m.user_id=p_user_id
    ),'[]'::jsonb),
    'verified_evidence_count',(select count(*) from public.skill_evidence e where e.user_id=p_user_id and e.status='verified'),
    'development_event_count',(select count(*) from public.development_events d where d.user_id=p_user_id)
  ) into v_snapshot;
  insert into public.skill_passports(user_id,version,snapshot,updated_at)
  values(p_user_id,v_version,v_snapshot,now()) returning id into v_id;
  return v_id;
end; $$;

create or replace function private.finalize_evidence_pipeline(p_evidence_id uuid,p_reviewer_id uuid)
returns jsonb language plpgsql security definer set search_path=public,private as $$
declare v_user_id uuid; v_skill_id uuid; v_mastery_id uuid; v_passport_id uuid;
begin
  select user_id,skill_id into v_user_id,v_skill_id from public.skill_evidence where id=p_evidence_id;
  if v_user_id is null then raise exception 'evidence not found'; end if;
  perform private.verify_skill_evidence(p_evidence_id,p_reviewer_id);
  v_mastery_id := private.recompute_skill_mastery(v_user_id,v_skill_id,p_evidence_id);
  v_passport_id := private.refresh_skill_passport(v_user_id);
  return jsonb_build_object('evidence_id',p_evidence_id,'mastery_id',v_mastery_id,'passport_id',v_passport_id,'status','completed');
end; $$;

revoke all on function private.record_skill_evidence_candidate(uuid,uuid,text,uuid,text,text,numeric,numeric,jsonb,text) from public,anon,authenticated;
revoke all on function private.verify_skill_evidence(uuid,uuid) from public,anon,authenticated;
revoke all on function private.recompute_skill_mastery(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function private.refresh_skill_passport(uuid) from public,anon,authenticated;
revoke all on function private.finalize_evidence_pipeline(uuid,uuid) from public,anon,authenticated;

grant execute on function private.record_skill_evidence_candidate(uuid,uuid,text,uuid,text,text,numeric,numeric,jsonb,text) to service_role;
grant execute on function private.verify_skill_evidence(uuid,uuid) to service_role;
grant execute on function private.recompute_skill_mastery(uuid,uuid,uuid) to service_role;
grant execute on function private.refresh_skill_passport(uuid) to service_role;
grant execute on function private.finalize_evidence_pipeline(uuid,uuid) to service_role;
