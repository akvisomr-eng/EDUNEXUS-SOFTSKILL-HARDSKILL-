-- EDUNEXUS initial relational foundation
create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'student' check (role in ('student','mentor','parent','institution','admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text,
  status text not null default 'active' check (status in ('active','completed','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists skills (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  domain text not null check (domain in ('soft_skill','hard_skill')),
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists competencies (
  id uuid primary key default gen_random_uuid(),
  skill_id uuid not null references skills(id) on delete cascade,
  slug text not null,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  unique(skill_id, slug)
);

create table if not exists skill_levels (
  id smallint primary key,
  name text not null unique,
  description text
);

insert into skill_levels(id,name,description) values
(0,'Unfamiliar','No demonstrated familiarity'),
(1,'Awareness','Basic awareness'),
(2,'Beginner','Can perform with significant guidance'),
(3,'Developing','Can perform with periodic guidance'),
(4,'Intermediate','Can perform independently in common contexts'),
(5,'Advanced','Consistently strong independent performance'),
(6,'Professional','Professional-level capability'),
(7,'Expert','Expert-level capability')
on conflict (id) do nothing;

create table if not exists programs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists courses (
  id uuid primary key default gen_random_uuid(),
  program_id uuid references programs(id) on delete set null,
  name text not null,
  slug text not null unique,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  name text not null,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  unique(course_id, position)
);

create table if not exists lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references modules(id) on delete cascade,
  title text not null,
  content jsonb not null default '{}'::jsonb,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  unique(module_id, position)
);

create table if not exists activities (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) on delete cascade,
  activity_type text not null,
  title text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists assessments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id) on delete set null,
  title text not null,
  assessment_type text not null,
  rubric jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists assessment_attempts (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references assessments(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  score numeric(5,2),
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists live_sessions (
  id uuid primary key default gen_random_uuid(),
  host_user_id uuid not null references profiles(id) on delete restrict,
  provider text not null check (provider in ('edunexus','zoom','google_meet','microsoft_teams','webrtc')),
  external_session_id text,
  title text not null,
  status text not null default 'scheduled' check (status in ('scheduled','live','completed','cancelled')),
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists session_participants (
  session_id uuid not null references live_sessions(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  participant_role text not null check (participant_role in ('student','mentor','observer')),
  joined_at timestamptz,
  left_at timestamptz,
  primary key(session_id,user_id)
);

create table if not exists session_consents (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references live_sessions(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  analysis_enabled boolean not null default false,
  recording_enabled boolean not null default false,
  portfolio_sharing_enabled boolean not null default false,
  granted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists performance_observations (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references live_sessions(id) on delete cascade,
  subject_user_id uuid not null references profiles(id) on delete cascade,
  observation_type text not null,
  observed_at timestamptz not null default now(),
  data jsonb not null default '{}'::jsonb,
  ai_model text,
  confidence numeric(5,4),
  provenance jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists performance_metrics (
  id uuid primary key default gen_random_uuid(),
  observation_id uuid not null references performance_observations(id) on delete cascade,
  metric_key text not null,
  metric_value numeric(8,3),
  unit text,
  evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists mentor_reviews (
  id uuid primary key default gen_random_uuid(),
  observation_id uuid not null references performance_observations(id) on delete cascade,
  mentor_id uuid not null references profiles(id) on delete restrict,
  decision text not null check (decision in ('accepted','modified','rejected')),
  notes text,
  reviewed_at timestamptz not null default now()
);

create table if not exists skill_evidence (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  skill_id uuid not null references skills(id) on delete restrict,
  evidence_type text not null,
  source_id uuid,
  status text not null default 'candidate' check (status in ('candidate','verified','rejected')),
  summary text,
  created_at timestamptz not null default now()
);

create table if not exists mastery_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  skill_id uuid not null references skills(id) on delete cascade,
  level_id smallint not null references skill_levels(id),
  score numeric(5,2),
  evidence_count integer not null default 0,
  assessed_at timestamptz not null default now(),
  unique(user_id, skill_id)
);

create table if not exists development_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  skill_id uuid references skills(id) on delete set null,
  event_type text not null,
  summary text not null,
  source_id uuid,
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists skill_passports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references profiles(id) on delete cascade,
  version integer not null default 1,
  snapshot jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references profiles(id) on delete set null,
  action text not null,
  resource_type text not null,
  resource_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_goals_user on goals(user_id);
create index if not exists idx_competencies_skill on competencies(skill_id);
create index if not exists idx_courses_program on courses(program_id);
create index if not exists idx_modules_course on modules(course_id);
create index if not exists idx_lessons_module on lessons(module_id);
create index if not exists idx_attempts_user on assessment_attempts(user_id);
create index if not exists idx_session_participants_user on session_participants(user_id);
create index if not exists idx_observations_subject on performance_observations(subject_user_id);
create index if not exists idx_metrics_observation on performance_metrics(observation_id);
create index if not exists idx_evidence_user_skill on skill_evidence(user_id,skill_id);
create index if not exists idx_mastery_user on mastery_records(user_id);
create index if not exists idx_development_user on development_events(user_id);
create index if not exists idx_audit_resource on audit_events(resource_type,resource_id);
