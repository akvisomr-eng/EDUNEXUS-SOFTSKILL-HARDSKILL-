-- Trusted practice scoring hardening.
create or replace function private.enforce_practice_attempt_lifecycle()
returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$
begin
 if tg_op='INSERT' then
  if new.status<>'in_progress' or new.score is not null or new.submitted_at is not null then raise exception 'practice attempt must start in_progress without score'; end if;
  return new;
 end if;
 if old.status<>'in_progress' then raise exception 'practice attempt is immutable after submission or cancellation'; end if;
 if current_user='service_role' then
  if new.status='submitted' then
   if new.submitted_at is null or new.score is null or new.score<0 or new.score>100 then raise exception 'trusted practice completion requires submitted_at and score 0..100'; end if;
  elsif new.status='cancelled' then
   if new.submitted_at is null or new.score is not null then raise exception 'invalid trusted practice cancellation'; end if;
  elsif new.status<>'in_progress' then raise exception 'invalid trusted practice attempt transition'; end if;
  return new;
 end if;
 if new.status='in_progress' then
  if new.submitted_at is not null or new.score is distinct from old.score then raise exception 'invalid in_progress practice attempt update'; end if;
 elsif new.status in ('submitted','cancelled') then
  if new.submitted_at is null or new.score is distinct from old.score then raise exception 'invalid practice attempt submission state'; end if;
 else raise exception 'invalid practice attempt transition'; end if;
 if new.id<>old.id or new.session_id<>old.session_id or new.user_id<>old.user_id or new.attempt_number<>old.attempt_number or new.created_at<>old.created_at or new.score is distinct from old.score then raise exception 'practice attempt protected fields cannot be changed by learner'; end if;
 return new;
end; $$;