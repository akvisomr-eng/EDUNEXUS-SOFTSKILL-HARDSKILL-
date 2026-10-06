-- EDUNEXUS Evidence & Mastery Intelligence v1
alter table public.skill_evidence
  add column if not exists source_type text not null default 'assessment',
  add column if not exists verified_by uuid references public.profiles(id) on delete set null,
  add column if not exists verified_at timestamptz,
  add column if not exists confidence numeric(5,4),
  add column if not exists provenance jsonb not null default '{}'::jsonb;

alter table public.skill_evidence
  drop constraint if exists skill_evidence_verification_consistency;
alter table public.skill_evidence
  add constraint skill_evidence_verification_consistency
  check (
    (status = 'verified' and verified_by is not null and verified_at is not null)
    or status in ('candidate','rejected')
  );

alter table public.skill_evidence
  drop constraint if exists skill_evidence_confidence_range;
alter table public.skill_evidence
  add constraint skill_evidence_confidence_range
  check (confidence is null or (confidence >= 0 and confidence <= 1));

alter table public.mastery_records
  drop constraint if exists mastery_records_score_range;
alter table public.mastery_records
  add constraint mastery_records_score_range
  check (score is null or (score >= 0 and score <= 100));

create table if not exists public.mastery_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  level_id smallint not null references public.skill_levels(id),
  score numeric(5,2),
  evidence_count integer not null default 0,
  source_evidence_id uuid references public.skill_evidence(id) on delete set null,
  recorded_at timestamptz not null default now(),
  reason text not null,
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists idx_mastery_history_user_skill
  on public.mastery_history(user_id, skill_id, recorded_at desc);
create index if not exists idx_evidence_source
  on public.skill_evidence(source_type, source_id);

alter table public.mastery_history enable row level security;
revoke all on public.mastery_history from anon, authenticated;
grant select on public.mastery_history to authenticated;

drop policy if exists mastery_history_select_authorized on public.mastery_history;
create policy mastery_history_select_authorized on public.mastery_history
  for select to authenticated
  using (private.can_access_user(user_id));

revoke insert, update, delete on public.skill_evidence from authenticated;
grant select on public.skill_evidence to authenticated;

drop policy if exists skill_evidence_select_authorized on public.skill_evidence;
create policy skill_evidence_select_authorized on public.skill_evidence
  for select to authenticated
  using (private.can_access_user(user_id));

revoke insert, update, delete on public.mastery_records from authenticated;
grant select on public.mastery_records to authenticated;

drop policy if exists mastery_records_select_authorized on public.mastery_records;
create policy mastery_records_select_authorized on public.mastery_records
  for select to authenticated
  using (private.can_access_user(user_id));

revoke insert, update, delete on public.development_events from authenticated;
grant select on public.development_events to authenticated;

drop policy if exists development_events_select_authorized on public.development_events;
create policy development_events_select_authorized on public.development_events
  for select to authenticated
  using (private.can_access_user(user_id));

revoke insert, update, delete on public.skill_passports from authenticated;
grant select on public.skill_passports to authenticated;

drop policy if exists skill_passports_select_authorized on public.skill_passports;
create policy skill_passports_select_authorized on public.skill_passports
  for select to authenticated
  using (private.can_access_user(user_id));
