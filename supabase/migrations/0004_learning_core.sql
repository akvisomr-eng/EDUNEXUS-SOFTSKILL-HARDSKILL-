-- EDUNEXUS Learning Core v1
create table if not exists public.course_enrollments (
 id uuid primary key default gen_random_uuid(),
 course_id uuid not null references public.courses(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'active' check (status in ('active','completed','paused','dropped')),
 enrolled_at timestamptz not null default now(),
 completed_at timestamptz,
 updated_at timestamptz not null default now(),
 unique(course_id,user_id),
 check ((status='completed' and completed_at is not null) or status<>'completed')
);
create table if not exists public.lesson_progress (
 id uuid primary key default gen_random_uuid(),
 lesson_id uuid not null references public.lessons(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'not_started' check (status in ('not_started','in_progress','completed')),
 progress_percent numeric(5,2) not null default 0 check (progress_percent between 0 and 100),
 started_at timestamptz,
 completed_at timestamptz,
 updated_at timestamptz not null default now(),
 unique(lesson_id,user_id),
 check ((status='completed' and progress_percent=100) or status<>'completed')
);
create index if not exists idx_enrollments_user_status on public.course_enrollments(user_id,status);
create index if not exists idx_enrollments_course_status on public.course_enrollments(course_id,status);
create index if not exists idx_lesson_progress_user on public.lesson_progress(user_id,status);

create or replace function private.is_enrolled_in_lesson(target_user uuid, target_lesson uuid) returns boolean
language sql stable security definer set search_path=pg_catalog,public as $$
 select exists(
   select 1 from public.course_enrollments e
   join public.modules m on m.course_id=e.course_id
   join public.lessons l on l.module_id=m.id
   where e.user_id=target_user and e.status='active' and l.id=target_lesson
 );
$$;
revoke all on function private.is_enrolled_in_lesson(uuid,uuid) from public,anon;
grant execute on function private.is_enrolled_in_lesson(uuid,uuid) to authenticated;

alter table public.course_enrollments enable row level security;
alter table public.lesson_progress enable row level security;
revoke all on public.course_enrollments, public.lesson_progress from anon, authenticated;
grant select,insert,update on public.course_enrollments, public.lesson_progress to authenticated;

drop policy if exists enrollments_select_authorized on public.course_enrollments;
create policy enrollments_select_authorized on public.course_enrollments for select to authenticated using (private.can_access_user(user_id));
drop policy if exists enrollments_insert_own on public.course_enrollments;
create policy enrollments_insert_own on public.course_enrollments for insert to authenticated with check ((select auth.uid())=user_id);
drop policy if exists enrollments_update_own on public.course_enrollments;
create policy enrollments_update_own on public.course_enrollments for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

drop policy if exists lesson_progress_select_authorized on public.lesson_progress;
create policy lesson_progress_select_authorized on public.lesson_progress for select to authenticated using (private.can_access_user(user_id));
drop policy if exists lesson_progress_insert_own on public.lesson_progress;
create policy lesson_progress_insert_own on public.lesson_progress for insert to authenticated with check ((select auth.uid())=user_id and private.is_enrolled_in_lesson((select auth.uid()),lesson_id));
drop policy if exists lesson_progress_update_own on public.lesson_progress;
create policy lesson_progress_update_own on public.lesson_progress for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id and private.is_enrolled_in_lesson((select auth.uid()),lesson_id));
