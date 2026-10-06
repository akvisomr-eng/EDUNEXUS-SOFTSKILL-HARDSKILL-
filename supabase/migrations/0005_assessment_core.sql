-- EDUNEXUS Assessment Core v1
alter table public.assessment_attempts
  add column if not exists status text not null default 'in_progress'
    check (status in ('in_progress','submitted','reviewed','cancelled')),
  add column if not exists started_at timestamptz not null default now(),
  add column if not exists submitted_at timestamptz,
  add column if not exists reviewed_at timestamptz;

alter table public.assessment_attempts
  drop constraint if exists assessment_attempts_submission_consistency;
alter table public.assessment_attempts
  add constraint assessment_attempts_submission_consistency
  check (
    (status in ('submitted','reviewed') and submitted_at is not null)
    or status in ('in_progress','cancelled')
  );

create table if not exists public.assessment_items (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  item_type text not null check (item_type in ('multiple_choice','short_answer','long_answer','numeric','performance')),
  prompt text not null,
  position integer not null default 0,
  points numeric(8,2) not null default 1 check (points >= 0),
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(assessment_id, position)
);

create table if not exists public.assessment_item_skill_targets (
  item_id uuid not null references public.assessment_items(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  competency_id uuid references public.competencies(id) on delete set null,
  weight numeric(6,3) not null default 1 check (weight > 0),
  primary key(item_id, skill_id, competency_id)
);

create table if not exists public.assessment_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.assessment_attempts(id) on delete cascade,
  item_id uuid not null references public.assessment_items(id) on delete cascade,
  response jsonb not null default '{}'::jsonb,
  awarded_points numeric(8,2),
  feedback text,
  evaluated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(attempt_id, item_id)
);

create index if not exists idx_assessment_items_assessment on public.assessment_items(assessment_id, position);
create index if not exists idx_assessment_targets_skill on public.assessment_item_skill_targets(skill_id);
create index if not exists idx_assessment_answers_attempt on public.assessment_answers(attempt_id);

alter table public.assessment_items enable row level security;
alter table public.assessment_item_skill_targets enable row level security;
alter table public.assessment_answers enable row level security;

revoke all on public.assessment_items, public.assessment_item_skill_targets, public.assessment_answers from anon, authenticated;
grant select on public.assessment_items, public.assessment_item_skill_targets to authenticated;
grant select, insert, update on public.assessment_answers to authenticated;
grant update on public.assessment_attempts to authenticated;

drop policy if exists assessment_items_catalog_select on public.assessment_items;
create policy assessment_items_catalog_select on public.assessment_items
  for select to authenticated using (true);

drop policy if exists assessment_targets_catalog_select on public.assessment_item_skill_targets;
create policy assessment_targets_catalog_select on public.assessment_item_skill_targets
  for select to authenticated using (true);

drop policy if exists assessment_answers_select_authorized on public.assessment_answers;
create policy assessment_answers_select_authorized on public.assessment_answers
  for select to authenticated
  using (
    exists (
      select 1 from public.assessment_attempts a
      where a.id = attempt_id and private.can_access_user(a.user_id)
    )
  );

drop policy if exists assessment_answers_insert_own on public.assessment_answers;
create policy assessment_answers_insert_own on public.assessment_answers
  for insert to authenticated
  with check (
    exists (
      select 1 from public.assessment_attempts a
      where a.id = attempt_id and a.user_id = (select auth.uid()) and a.status = 'in_progress'
    )
  );

drop policy if exists assessment_answers_update_own on public.assessment_answers;
create policy assessment_answers_update_own on public.assessment_answers
  for update to authenticated
  using (
    exists (
      select 1 from public.assessment_attempts a
      where a.id = attempt_id and a.user_id = (select auth.uid()) and a.status = 'in_progress'
    )
  )
  with check (
    exists (
      select 1 from public.assessment_attempts a
      where a.id = attempt_id and a.user_id = (select auth.uid()) and a.status = 'in_progress'
    )
  );

drop policy if exists assessment_attempts_update_own on public.assessment_attempts;
create policy assessment_attempts_update_own on public.assessment_attempts
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
