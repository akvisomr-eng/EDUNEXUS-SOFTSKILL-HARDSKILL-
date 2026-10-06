-- EDUNEXUS Practice & Simulation Core v1
-- Practice scenarios, learner practice sessions, simulation runs/events,
-- skill targeting, lifecycle hardening, and relationship-aware RLS.

create table if not exists public.practice_scenarios (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  scenario_type text not null check (scenario_type in ('practice','simulation','role_play','industry')),
  difficulty smallint not null default 1 check (difficulty between 1 and 5),
  instructions jsonb not null default '{}'::jsonb,
  context jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('draft','active','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scenario_skill_targets (
  id uuid primary key default gen_random_uuid(),
  scenario_id uuid not null references public.practice_scenarios(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete restrict,
  competency_id uuid references public.competencies(id) on delete restrict,
  target_weight numeric(6,3) not null default 1.0 check (target_weight > 0 and target_weight <= 1),
  created_at timestamptz not null default now(),
  unique (scenario_id, skill_id, competency_id)
);

create table if not exists public.practice_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  scenario_id uuid not null references public.practice_scenarios(id) on delete restrict,
  status text not null default 'in_progress' check (status in ('in_progress','submitted','completed','cancelled')),
  attempt_number integer not null default 1 check (attempt_number > 0),
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  completed_at timestamptz,
  reflection text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check (
    (status = 'in_progress' and submitted_at is null and completed_at is null)
    or (status = 'submitted' and submitted_at is not null and completed_at is null)
    or (status = 'completed' and submitted_at is not null and completed_at is not null)
    or (status = 'cancelled' and submitted_at is not null and completed_at is null)
  )
);

create table if not exists public.practice_attempts (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.practice_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  attempt_number integer not null default 1 check (attempt_number > 0),
  status text not null default 'in_progress' check (status in ('in_progress','submitted','cancelled')),
  response jsonb not null default '{}'::jsonb,
  score numeric(5,2),
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (session_id, attempt_number),
  check (score is null or score between 0 and 100)
);

create table if not exists public.simulation_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  scenario_id uuid not null references public.practice_scenarios(id) on delete restrict,
  mode text not null check (mode in ('live_assistance','post_session')),
  status text not null default 'in_progress' check (status in ('in_progress','completed','cancelled')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check (
    (status = 'in_progress' and completed_at is null)
    or (status in ('completed','cancelled') and completed_at is not null)
  )
);

create table if not exists public.simulation_events (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.simulation_runs(id) on delete cascade,
  event_type text not null,
  occurred_at timestamptz not null default now(),
  payload jsonb not null default '{}'::jsonb
);

create index if not exists idx_scenarios_status_type
  on public.practice_scenarios(status, scenario_type);
create index if not exists idx_scenario_targets_skill
  on public.scenario_skill_targets(skill_id, scenario_id);
create index if not exists idx_practice_sessions_user
  on public.practice_sessions(user_id, created_at desc);
create index if not exists idx_practice_sessions_scenario
  on public.practice_sessions(scenario_id, status);
create index if not exists idx_practice_attempts_user
  on public.practice_attempts(user_id, created_at desc);
create index if not exists idx_practice_attempts_session
  on public.practice_attempts(session_id, attempt_number);
create index if not exists idx_simulation_runs_user
  on public.simulation_runs(user_id, created_at desc);
create index if not exists idx_simulation_runs_scenario
  on public.simulation_runs(scenario_id, status);
create index if not exists idx_simulation_events_run
  on public.simulation_events(run_id, occurred_at);

alter table public.practice_scenarios enable row level security;
alter table public.scenario_skill_targets enable row level security;
alter table public.practice_sessions enable row level security;
alter table public.practice_attempts enable row level security;
alter table public.simulation_runs enable row level security;
alter table public.simulation_events enable row level security;

revoke all on public.practice_scenarios, public.scenario_skill_targets,
  public.practice_sessions, public.practice_attempts,
  public.simulation_runs, public.simulation_events from anon, authenticated;

grant select on public.practice_scenarios, public.scenario_skill_targets to authenticated;
grant select, insert, update on public.practice_sessions to authenticated;
grant select, insert, update on public.practice_attempts to authenticated;
grant select, insert, update on public.simulation_runs to authenticated;
grant select, insert on public.simulation_events to authenticated;

drop policy if exists practice_scenarios_catalog_select on public.practice_scenarios;
create policy practice_scenarios_catalog_select
  on public.practice_scenarios for select to authenticated
  using (status = 'active');

drop policy if exists scenario_targets_catalog_select on public.scenario_skill_targets;
create policy scenario_targets_catalog_select
  on public.scenario_skill_targets for select to authenticated
  using (exists (
    select 1 from public.practice_scenarios s
    where s.id = scenario_skill_targets.scenario_id
      and s.status = 'active'
  ));

drop policy if exists practice_sessions_select_authorized on public.practice_sessions;
create policy practice_sessions_select_authorized
  on public.practice_sessions for select to authenticated
  using (private.can_access_user(user_id));

drop policy if exists practice_sessions_insert_own on public.practice_sessions;
create policy practice_sessions_insert_own
  on public.practice_sessions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'in_progress'
    and submitted_at is null
    and completed_at is null
  );

drop policy if exists practice_sessions_update_own on public.practice_sessions;
create policy practice_sessions_update_own
  on public.practice_sessions for update to authenticated
  using ((select auth.uid()) = user_id and status = 'in_progress')
  with check (
    (select auth.uid()) = user_id
    and status in ('in_progress','submitted','cancelled')
    and (
      (status = 'in_progress' and submitted_at is null and completed_at is null)
      or (status in ('submitted','cancelled') and submitted_at is not null and completed_at is null)
    )
  );

drop policy if exists practice_attempts_select_authorized on public.practice_attempts;
create policy practice_attempts_select_authorized
  on public.practice_attempts for select to authenticated
  using (private.can_access_user(user_id));

drop policy if exists practice_attempts_insert_own on public.practice_attempts;
create policy practice_attempts_insert_own
  on public.practice_attempts for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'in_progress'
    and score is null
    and submitted_at is null
    and exists (
      select 1 from public.practice_sessions s
      where s.id = practice_attempts.session_id
        and s.user_id = (select auth.uid())
        and s.status = 'in_progress'
    )
  );

drop policy if exists practice_attempts_update_own on public.practice_attempts;
create policy practice_attempts_update_own
  on public.practice_attempts for update to authenticated
  using ((select auth.uid()) = user_id and status = 'in_progress')
  with check (
    (select auth.uid()) = user_id
    and status in ('in_progress','submitted','cancelled')
    and (
      (status = 'in_progress' and submitted_at is null)
      or (status in ('submitted','cancelled') and submitted_at is not null)
    )
  );

drop policy if exists simulation_runs_select_authorized on public.simulation_runs;
create policy simulation_runs_select_authorized
  on public.simulation_runs for select to authenticated
  using (private.can_access_user(user_id));

drop policy if exists simulation_runs_insert_own on public.simulation_runs;
create policy simulation_runs_insert_own
  on public.simulation_runs for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'in_progress'
    and completed_at is null
    and result = '{}'::jsonb
  );

drop policy if exists simulation_runs_update_own on public.simulation_runs;
create policy simulation_runs_update_own
  on public.simulation_runs for update to authenticated
  using ((select auth.uid()) = user_id and status = 'in_progress')
  with check (
    (select auth.uid()) = user_id
    and status in ('in_progress','completed','cancelled')
    and (
      (status = 'in_progress' and completed_at is null)
      or (status in ('completed','cancelled') and completed_at is not null)
    )
  );

drop policy if exists simulation_events_select_authorized on public.simulation_events;
create policy simulation_events_select_authorized
  on public.simulation_events for select to authenticated
  using (exists (
    select 1 from public.simulation_runs r
    where r.id = simulation_events.run_id
      and private.can_access_user(r.user_id)
  ));

drop policy if exists simulation_events_insert_own on public.simulation_events;
create policy simulation_events_insert_own
  on public.simulation_events for insert to authenticated
  with check (exists (
    select 1 from public.simulation_runs r
    where r.id = simulation_events.run_id
      and r.user_id = (select auth.uid())
      and r.status = 'in_progress'
  ));

revoke update on public.practice_attempts, public.simulation_runs from authenticated;
grant update (status, response, submitted_at) on public.practice_attempts to authenticated;
grant update (status, completed_at) on public.simulation_runs to authenticated;

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

  if new.id <> old.id
     or new.session_id <> old.session_id
     or new.user_id <> old.user_id
     or new.attempt_number <> old.attempt_number
     or new.created_at <> old.created_at
     or new.score is distinct from old.score then
    raise exception 'practice attempt protected fields cannot be changed by learner';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_practice_attempt_lifecycle on public.practice_attempts;
create trigger trg_practice_attempt_lifecycle
before insert or update on public.practice_attempts
for each row execute function private.enforce_practice_attempt_lifecycle();

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

  if new.status = 'in_progress' then
    if new.completed_at is not null or new.result <> old.result then
      raise exception 'invalid in_progress simulation update';
    end if;
  elsif new.status in ('completed','cancelled') then
    if new.completed_at is null or new.result <> old.result then
      raise exception 'simulation result is controlled and cannot be written by learner';
    end if;
  else
    raise exception 'invalid simulation transition';
  end if;

  if new.id <> old.id
     or new.user_id <> old.user_id
     or new.scenario_id <> old.scenario_id
     or new.mode <> old.mode
     or new.started_at <> old.started_at
     or new.created_at <> old.created_at then
    raise exception 'simulation run protected fields cannot be changed by learner';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_simulation_run_lifecycle on public.simulation_runs;
create trigger trg_simulation_run_lifecycle
before insert or update on public.simulation_runs
for each row execute function private.enforce_simulation_run_lifecycle();

revoke all on function private.enforce_practice_attempt_lifecycle(), private.enforce_simulation_run_lifecycle() from public, anon;
grant execute on function private.enforce_practice_attempt_lifecycle(), private.enforce_simulation_run_lifecycle() to authenticated;
