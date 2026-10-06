-- EDUNEXUS identity, membership and RLS baseline v2
-- Applied as migration: identity_membership_rls_baseline

create table if not exists public.institutions (
  id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.institution_memberships (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  membership_role text not null check (membership_role in ('student','mentor','guardian','staff','admin')),
  status text not null default 'active' check (status in ('active','suspended','ended')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (institution_id, user_id), unique (institution_id, id)
);
create table if not exists public.guardian_student_relationships (
  id uuid primary key default gen_random_uuid(),
  guardian_user_id uuid not null references public.profiles(id) on delete cascade,
  student_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active' check (status in ('active','revoked')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (guardian_user_id <> student_user_id), unique (guardian_user_id, student_user_id)
);
create table if not exists public.mentor_student_relationships (
  id uuid primary key default gen_random_uuid(),
  mentor_user_id uuid not null references public.profiles(id) on delete cascade,
  student_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active' check (status in ('active','paused','ended')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (mentor_user_id <> student_user_id), unique (mentor_user_id, student_user_id)
);

create index if not exists idx_memberships_user on public.institution_memberships(user_id);
create index if not exists idx_memberships_institution_role on public.institution_memberships(institution_id, membership_role, status);
create index if not exists idx_guardian_student_guardian on public.guardian_student_relationships(guardian_user_id, status);
create index if not exists idx_guardian_student_student on public.guardian_student_relationships(student_user_id, status);
create index if not exists idx_mentor_student_mentor on public.mentor_student_relationships(mentor_user_id, status);
create index if not exists idx_mentor_student_student on public.mentor_student_relationships(student_user_id, status);

create schema if not exists private;
create or replace function private.is_guardian_of(target_user uuid) returns boolean language sql stable security definer set search_path = pg_catalog, public as $$
  select exists(select 1 from public.guardian_student_relationships r where r.guardian_user_id=(select auth.uid()) and r.student_user_id=target_user and r.status='active');
$$;
create or replace function private.is_mentor_of(target_user uuid) returns boolean language sql stable security definer set search_path = pg_catalog, public as $$
  select exists(select 1 from public.mentor_student_relationships r where r.mentor_user_id=(select auth.uid()) and r.student_user_id=target_user and r.status='active');
$$;
create or replace function private.is_institution_staff_of(target_user uuid) returns boolean language sql stable security definer set search_path = pg_catalog, public as $$
  select exists(select 1 from public.institution_memberships mine join public.institution_memberships target on target.institution_id=mine.institution_id where mine.user_id=(select auth.uid()) and mine.membership_role in ('staff','admin') and mine.status='active' and target.user_id=target_user and target.status='active');
$$;
create or replace function private.can_access_user(target_user uuid) returns boolean language sql stable security definer set search_path = pg_catalog, public as $$
  select target_user=(select auth.uid()) or private.is_guardian_of(target_user) or private.is_mentor_of(target_user) or private.is_institution_staff_of(target_user);
$$;
create or replace function private.is_institution_admin(target_institution uuid) returns boolean language sql stable security definer set search_path = pg_catalog, public as $$
  select exists(select 1 from public.institution_memberships m where m.institution_id=target_institution and m.user_id=(select auth.uid()) and m.membership_role='admin' and m.status='active');
$$;
revoke all on function private.is_guardian_of(uuid), private.is_mentor_of(uuid), private.is_institution_staff_of(uuid), private.can_access_user(uuid), private.is_institution_admin(uuid) from public, anon;
grant execute on function private.is_guardian_of(uuid), private.is_mentor_of(uuid), private.is_institution_staff_of(uuid), private.can_access_user(uuid), private.is_institution_admin(uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.goals enable row level security;
alter table public.skills enable row level security;
alter table public.competencies enable row level security;
alter table public.skill_levels enable row level security;
alter table public.programs enable row level security;
alter table public.courses enable row level security;
alter table public.modules enable row level security;
alter table public.lessons enable row level security;
alter table public.activities enable row level security;
alter table public.assessments enable row level security;
alter table public.assessment_attempts enable row level security;
alter table public.live_sessions enable row level security;
alter table public.session_participants enable row level security;
alter table public.session_consents enable row level security;
alter table public.performance_observations enable row level security;
alter table public.performance_metrics enable row level security;
alter table public.mentor_reviews enable row level security;
alter table public.skill_evidence enable row level security;
alter table public.mastery_records enable row level security;
alter table public.development_events enable row level security;
alter table public.skill_passports enable row level security;
alter table public.audit_events enable row level security;
alter table public.institutions enable row level security;
alter table public.institution_memberships enable row level security;
alter table public.guardian_student_relationships enable row level security;
alter table public.mentor_student_relationships enable row level security;

revoke all on all tables in schema public from anon, authenticated;
grant select on public.skills, public.competencies, public.skill_levels, public.programs, public.courses, public.modules, public.lessons, public.activities, public.assessments to authenticated;
grant select, insert, update on public.profiles, public.goals, public.assessment_attempts, public.session_consents, public.skill_evidence, public.mastery_records, public.development_events, public.skill_passports to authenticated;
grant select, insert, update, delete on public.live_sessions, public.session_participants to authenticated;
grant select on public.performance_observations, public.performance_metrics, public.mentor_reviews, public.audit_events, public.institutions, public.institution_memberships, public.guardian_student_relationships, public.mentor_student_relationships to authenticated;
revoke update on public.profiles from authenticated;
grant update (display_name, updated_at) on public.profiles to authenticated;
revoke insert, update, delete on public.performance_observations, public.performance_metrics, public.audit_events, public.institutions, public.institution_memberships, public.guardian_student_relationships, public.mentor_student_relationships from authenticated;

drop policy if exists profiles_select_authorized on public.profiles;
create policy profiles_select_authorized on public.profiles for select to authenticated using (private.can_access_user(id));
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles for insert to authenticated with check ((select auth.uid())=id and role='student');
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated using ((select auth.uid())=id) with check ((select auth.uid())=id);

drop policy if exists skills_catalog_select on public.skills;
create policy skills_catalog_select on public.skills for select to authenticated using (true);
drop policy if exists competencies_catalog_select on public.competencies;
create policy competencies_catalog_select on public.competencies for select to authenticated using (true);
drop policy if exists skill_levels_catalog_select on public.skill_levels;
create policy skill_levels_catalog_select on public.skill_levels for select to authenticated using (true);
drop policy if exists programs_catalog_select on public.programs;
create policy programs_catalog_select on public.programs for select to authenticated using (true);
drop policy if exists courses_catalog_select on public.courses;
create policy courses_catalog_select on public.courses for select to authenticated using (true);
drop policy if exists modules_catalog_select on public.modules;
create policy modules_catalog_select on public.modules for select to authenticated using (true);
drop policy if exists lessons_catalog_select on public.lessons;
create policy lessons_catalog_select on public.lessons for select to authenticated using (true);
drop policy if exists activities_catalog_select on public.activities;
create policy activities_catalog_select on public.activities for select to authenticated using (true);
drop policy if exists assessments_catalog_select on public.assessments;
create policy assessments_catalog_select on public.assessments for select to authenticated using (true);

drop policy if exists goals_select_authorized on public.goals;
create policy goals_select_authorized on public.goals for select to authenticated using (private.can_access_user(user_id));
drop policy if exists goals_insert_own on public.goals;
create policy goals_insert_own on public.goals for insert to authenticated with check ((select auth.uid())=user_id);
drop policy if exists goals_update_own on public.goals;
create policy goals_update_own on public.goals for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

drop policy if exists assessment_attempts_select_authorized on public.assessment_attempts;
create policy assessment_attempts_select_authorized on public.assessment_attempts for select to authenticated using (private.can_access_user(user_id));
drop policy if exists assessment_attempts_insert_own on public.assessment_attempts;
create policy assessment_attempts_insert_own on public.assessment_attempts for insert to authenticated with check ((select auth.uid())=user_id);

drop policy if exists session_consents_select_authorized on public.session_consents;
create policy session_consents_select_authorized on public.session_consents for select to authenticated using (private.can_access_user(user_id));
drop policy if exists session_consents_insert_own on public.session_consents;
create policy session_consents_insert_own on public.session_consents for insert to authenticated with check ((select auth.uid())=user_id);
drop policy if exists session_consents_update_own on public.session_consents;
create policy session_consents_update_own on public.session_consents for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

drop policy if exists skill_evidence_select_authorized on public.skill_evidence;
create policy skill_evidence_select_authorized on public.skill_evidence for select to authenticated using (private.can_access_user(user_id));
drop policy if exists skill_evidence_insert_own on public.skill_evidence;
create policy skill_evidence_insert_own on public.skill_evidence for insert to authenticated with check ((select auth.uid())=user_id);
drop policy if exists mastery_records_select_authorized on public.mastery_records;
create policy mastery_records_select_authorized on public.mastery_records for select to authenticated using (private.can_access_user(user_id));
drop policy if exists development_events_select_authorized on public.development_events;
create policy development_events_select_authorized on public.development_events for select to authenticated using (private.can_access_user(user_id));
drop policy if exists skill_passports_select_authorized on public.skill_passports;
create policy skill_passports_select_authorized on public.skill_passports for select to authenticated using (private.can_access_user(user_id));

drop policy if exists live_sessions_select_related on public.live_sessions;
create policy live_sessions_select_related on public.live_sessions for select to authenticated using (host_user_id=(select auth.uid()) or exists(select 1 from public.session_participants sp where sp.session_id=live_sessions.id and sp.user_id=(select auth.uid())));
drop policy if exists live_sessions_insert_host on public.live_sessions;
create policy live_sessions_insert_host on public.live_sessions for insert to authenticated with check ((select auth.uid())=host_user_id);
drop policy if exists live_sessions_update_host on public.live_sessions;
create policy live_sessions_update_host on public.live_sessions for update to authenticated using ((select auth.uid())=host_user_id) with check ((select auth.uid())=host_user_id);
drop policy if exists live_sessions_delete_host on public.live_sessions;
create policy live_sessions_delete_host on public.live_sessions for delete to authenticated using ((select auth.uid())=host_user_id);

drop policy if exists session_participants_select_related on public.session_participants;
create policy session_participants_select_related on public.session_participants for select to authenticated using (user_id=(select auth.uid()) or exists(select 1 from public.live_sessions s where s.id=session_participants.session_id and s.host_user_id=(select auth.uid())));
drop policy if exists session_participants_insert_self on public.session_participants;
create policy session_participants_insert_self on public.session_participants for insert to authenticated with check (user_id=(select auth.uid()) and exists(select 1 from public.live_sessions s where s.id=session_participants.session_id and s.host_user_id=(select auth.uid())));
drop policy if exists session_participants_update_self on public.session_participants;
create policy session_participants_update_self on public.session_participants for update to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
drop policy if exists session_participants_delete_self on public.session_participants;
create policy session_participants_delete_self on public.session_participants for delete to authenticated using (user_id=(select auth.uid()));

create policy performance_observations_select_authorized on public.performance_observations for select to authenticated using (private.can_access_user(subject_user_id));
create policy performance_metrics_select_authorized on public.performance_metrics for select to authenticated using (exists(select 1 from public.performance_observations o where o.id=performance_metrics.observation_id and private.can_access_user(o.subject_user_id)));
create policy mentor_reviews_select_authorized on public.mentor_reviews for select to authenticated using (mentor_id=(select auth.uid()) or exists(select 1 from public.performance_observations o where o.id=mentor_reviews.observation_id and private.can_access_user(o.subject_user_id)));
create policy mentor_reviews_insert_mentor on public.mentor_reviews for insert to authenticated with check (mentor_id=(select auth.uid()) and exists(select 1 from public.performance_observations o where o.id=mentor_reviews.observation_id and private.is_mentor_of(o.subject_user_id)));
create policy mentor_reviews_update_mentor on public.mentor_reviews for update to authenticated using (mentor_id=(select auth.uid())) with check (mentor_id=(select auth.uid()));

create policy audit_events_select_actor on public.audit_events for select to authenticated using ((select auth.uid())=actor_user_id);
create policy institutions_select_member on public.institutions for select to authenticated using (exists(select 1 from public.institution_memberships m where m.institution_id=institutions.id and m.user_id=(select auth.uid()) and m.status='active'));
create policy memberships_select_related on public.institution_memberships for select to authenticated using (user_id=(select auth.uid()) or private.is_institution_admin(institution_id));
create policy guardian_relationships_select_related on public.guardian_student_relationships for select to authenticated using (guardian_user_id=(select auth.uid()) or student_user_id=(select auth.uid()));
create policy mentor_relationships_select_related on public.mentor_student_relationships for select to authenticated using (mentor_user_id=(select auth.uid()) or student_user_id=(select auth.uid()));
