-- EDUNEXUS practice catalog seed v1
-- Deterministic catalog content only; no learner-specific data.

insert into public.skills (slug, name, domain, description)
values
  ('structured-communication', 'Structured Communication', 'soft_skill', 'Communicate ideas clearly using context, key message, evidence and next step.'),
  ('problem-structuring', 'Problem Structuring', 'hard_skill', 'Break a practical problem into inputs, assumptions, reasoning and a measurable recommendation.')
on conflict (slug) do update set
  name=excluded.name, domain=excluded.domain, description=excluded.description, updated_at=now();

insert into public.competencies (skill_id, slug, name, description)
select s.id,v.slug,v.name,v.description
from public.skills s
join (values
  ('structured-communication','structured-message','Structured Message','Organize a response around context, strength, evidence and goal.'),
  ('problem-structuring','kpi-reasoning','KPI Reasoning','Translate a business question into inputs, calculation logic and an actionable recommendation.')
) v(skill_slug,slug,name,description) on v.skill_slug=s.slug
on conflict (skill_id,slug) do update set name=excluded.name, description=excluded.description;

insert into public.practice_scenarios (title,description,scenario_type,difficulty,instructions,context,status)
select v.title,v.description,v.scenario_type,v.difficulty,v.instructions::jsonb,v.context::jsonb,'active'
from (values
('Structured 60-Second Introduction','Practice a concise professional introduction that demonstrates structured communication.','practice',1,
'{"response_fields":[{"key":"context","label":"Context","prompt":"Who are you and what context should the listener know?"},{"key":"strength","label":"Strength","prompt":"What skill or strength do you want to demonstrate?"},{"key":"example","label":"Evidence / Example","prompt":"Give one concrete example that supports the strength."},{"key":"goal","label":"Goal / Next Step","prompt":"What are you trying to achieve or invite next?"}],"rubric":"Each completed response field earns 25 points. Fields must contain at least 12 characters to count."}',
'{"audience":"mentor_or_peer","time_limit_seconds":60,"mode":"structured_response"}'),
('KPI Problem-Structuring Drill','Practice turning a simple performance question into inputs, reasoning and a recommendation.','practice',2,
'{"response_fields":[{"key":"question","label":"Question","prompt":"State the business question precisely."},{"key":"inputs","label":"Inputs","prompt":"List the data or inputs required."},{"key":"reasoning","label":"Reasoning","prompt":"Explain the calculation or reasoning steps."},{"key":"recommendation","label":"Recommendation","prompt":"State the decision or next action supported by the reasoning."}],"rubric":"Each completed response field earns 25 points. Fields must contain at least 12 characters to count."}',
'{"audience":"analyst_or_mentor","time_limit_seconds":180,"mode":"structured_response"}')
) v(title,description,scenario_type,difficulty,instructions,context)
where not exists(select 1 from public.practice_scenarios p where p.title=v.title);

insert into public.scenario_skill_targets(scenario_id,skill_id,competency_id,target_weight)
select p.id,s.id,c.id,1.0 from public.practice_scenarios p
join public.skills s on s.slug=case when p.title='Structured 60-Second Introduction' then 'structured-communication' when p.title='KPI Problem-Structuring Drill' then 'problem-structuring' end
join public.competencies c on c.skill_id=s.id and c.slug=case when s.slug='structured-communication' then 'structured-message' when s.slug='problem-structuring' then 'kpi-reasoning' end
where p.title in ('Structured 60-Second Introduction','KPI Problem-Structuring Drill')
on conflict(scenario_id,skill_id,competency_id) do update set target_weight=excluded.target_weight;