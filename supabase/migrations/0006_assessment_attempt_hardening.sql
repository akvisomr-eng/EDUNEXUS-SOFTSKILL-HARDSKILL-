-- EDUNEXUS Assessment Core v1 hardening
revoke update on public.assessment_attempts from authenticated;
grant update (status, submitted_at) on public.assessment_attempts to authenticated;

drop policy if exists assessment_attempts_insert_own on public.assessment_attempts;
create policy assessment_attempts_insert_own on public.assessment_attempts
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'in_progress'
    and score is null
    and result = '{}'::jsonb
    and submitted_at is null
    and reviewed_at is null
  );

drop policy if exists assessment_attempts_update_own on public.assessment_attempts;
create policy assessment_attempts_update_own on public.assessment_attempts
  for update to authenticated
  using (
    (select auth.uid()) = user_id
    and status = 'in_progress'
  )
  with check (
    (select auth.uid()) = user_id
    and status in ('in_progress','submitted','cancelled')
    and (
      (status = 'in_progress' and submitted_at is null)
      or (status in ('submitted','cancelled') and submitted_at is not null)
    )
  );

create or replace function private.enforce_assessment_attempt_lifecycle()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
begin
  if tg_op = 'INSERT' then
    if new.status <> 'in_progress' or new.score is not null or new.result <> '{}'::jsonb
       or new.submitted_at is not null or new.reviewed_at is not null then
      raise exception 'assessment attempt must start in_progress without result';
    end if;
    return new;
  end if;

  if old.status <> 'in_progress' then
    raise exception 'assessment attempt is immutable after submission or cancellation';
  end if;

  if new.status = 'in_progress' then
    if new.submitted_at is not null or new.score is not null or new.result <> old.result
       or new.reviewed_at is not null then
      raise exception 'invalid in_progress assessment attempt update';
    end if;
  elsif new.status in ('submitted','cancelled') then
    if new.submitted_at is null or new.reviewed_at is not null then
      raise exception 'invalid assessment attempt submission state';
    end if;
  else
    raise exception 'invalid assessment attempt transition';
  end if;

  if new.assessment_id <> old.assessment_id
     or new.user_id <> old.user_id
     or new.started_at <> old.started_at
     or new.created_at <> old.created_at
     or new.score is distinct from old.score
     or new.result is distinct from old.result
     or new.reviewed_at is distinct from old.reviewed_at then
    raise exception 'assessment attempt protected fields cannot be changed by learner';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_assessment_attempt_lifecycle on public.assessment_attempts;
create trigger trg_assessment_attempt_lifecycle
before insert or update on public.assessment_attempts
for each row execute function private.enforce_assessment_attempt_lifecycle();

revoke all on function private.enforce_assessment_attempt_lifecycle() from public, anon;
grant execute on function private.enforce_assessment_attempt_lifecycle() to authenticated;
