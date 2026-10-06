-- EDUNEXUS RLS policy design v1
-- Review before applying to Supabase production.
-- Principle: deny by default; authenticated users own personal records.
-- Shared mentor/institution policies are intentionally deferred until membership
-- relations exist, avoiding accidental cross-user access.

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

revoke all on all tables in schema public from anon;
revoke all on all tables in schema public from authenticated;

grant select on public.skills, public.competencies, public.skill_levels, public.programs, public.courses, public.modules, public.lessons, public.activities, public.assessments to authenticated;
grant select, insert, update on public.profiles, public.goals, public.assessment_attempts, public.session_consents, public.skill_evidence, public.mastery_records, public.development_events, public.skill_passports to authenticated;
grant select, insert, update, delete on public.live_sessions, public.session_participants to authenticated;
grant select on public.performance_observations, public.performance_metrics, public.mentor_reviews to authenticated;

create policy profiles_select_own on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy profiles_insert_own on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy profiles_update_own on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy goals_select_own on public.goals for select to authenticated using ((select auth.uid()) = user_id);
create policy goals_insert_own on public.goals for insert to authenticated with check ((select auth.uid()) = user_id);
create policy goals_update_own on public.goals for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy assessment_attempts_select_own on public.assessment_attempts for select to authenticated using ((select auth.uid()) = user_id);
create policy assessment_attempts_insert_own on public.assessment_attempts for insert to authenticated with check ((select auth.uid()) = user_id);

create policy session_consents_select_own on public.session_consents for select to authenticated using ((select auth.uid()) = user_id);
create policy session_consents_insert_own on public.session_consents for insert to authenticated with check ((select auth.uid()) = user_id);
create policy session_consents_update_own on public.session_consents for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy skill_evidence_select_own on public.skill_evidence for select to authenticated using ((select auth.uid()) = user_id);
create policy skill_evidence_insert_own on public.skill_evidence for insert to authenticated with check ((select auth.uid()) = user_id);

create policy mastery_records_select_own on public.mastery_records for select to authenticated using ((select auth.uid()) = user_id);

create policy development_events_select_own on public.development_events for select to authenticated using ((select auth.uid()) = user_id);

create policy skill_passports_select_own on public.skill_passports for select to authenticated using ((select auth.uid()) = user_id);

create policy live_sessions_select_host on public.live_sessions for select to authenticated using ((select auth.uid()) = host_user_id);
create policy live_sessions_insert_host on public.live_sessions for insert to authenticated with check ((select auth.uid()) = host_user_id);
create policy live_sessions_update_host on public.live_sessions for update to authenticated using ((select auth.uid()) = host_user_id) with check ((select auth.uid()) = host_user_id);
create policy live_sessions_delete_host on public.live_sessions for delete to authenticated using ((select auth.uid()) = host_user_id);

create policy session_participants_select_self on public.session_participants for select to authenticated using ((select auth.uid()) = user_id);
create policy session_participants_insert_self on public.session_participants for insert to authenticated with check ((select auth.uid()) = user_id);

-- Performance observations, metrics and mentor reviews remain readable only
-- after explicit policies for participant/mentor relationships are implemented.
