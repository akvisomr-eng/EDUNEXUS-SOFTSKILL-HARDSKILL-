-- Trusted simulation result hardening.
create or replace function private.enforce_simulation_run_lifecycle()
returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$
begin
 if tg_op='INSERT' then
  if new.status<>'in_progress' or new.completed_at is not null or new.result<>'{}'::jsonb then raise exception 'simulation run must start in_progress without result'; end if;
  return new;
 end if;
 if old.status<>'in_progress' then raise exception 'simulation run is immutable after completion or cancellation'; end if;
 if current_user='service_role' then
  if new.status='completed' then
   if new.completed_at is null or new.result='{}'::jsonb then raise exception 'trusted simulation completion requires completed_at and result'; end if;
  elsif new.status='cancelled' then
   if new.completed_at is null or new.result<>old.result then raise exception 'invalid trusted simulation cancellation'; end if;
  elsif new.status<>'in_progress' then raise exception 'invalid trusted simulation transition'; end if;
  return new;
 end if;
 if new.status='in_progress' then
  if new.completed_at is not null or new.result<>old.result then raise exception 'invalid in_progress simulation update'; end if;
 elsif new.status in ('completed','cancelled') then
  if new.completed_at is null or new.result<>old.result then raise exception 'simulation result is controlled and cannot be written by learner'; end if;
 else raise exception 'invalid simulation run transition'; end if;
 if new.id<>old.id or new.user_id<>old.user_id or new.scenario_id<>old.scenario_id or new.mode<>old.mode or new.started_at<>old.started_at or new.created_at<>old.created_at then raise exception 'simulation run protected fields cannot be changed by learner'; end if;
 return new;
end; $$;