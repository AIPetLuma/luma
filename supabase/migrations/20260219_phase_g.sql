begin;

create extension if not exists pgcrypto;

create table if not exists public.pet_backups (
  owner_id uuid not null,
  id text not null,
  name text not null,
  birthday timestamptz not null,
  personality text not null,
  need_loneliness double precision not null default 0.5,
  need_curiosity double precision not null default 0.5,
  need_fatigue double precision not null default 0,
  need_security double precision not null default 0.5,
  emotion_valence double precision not null default 0.2,
  emotion_arousal double precision not null default 0.3,
  trust_score double precision not null default 0.5,
  last_active_at timestamptz not null,
  total_interactions integer not null default 0,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  backed_up_at timestamptz not null default now(),
  primary key (owner_id, id)
);

create table if not exists public.fcm_tokens (
  owner_id uuid not null,
  token text not null,
  pet_id text not null,
  platform text not null,
  locale text not null,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (owner_id, token)
);

create table if not exists public.experiment_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  pet_id text not null,
  event_name text not null,
  event_at timestamptz not null default now(),
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_fcm_tokens_owner_pet
  on public.fcm_tokens(owner_id, pet_id);

create index if not exists idx_experiment_events_owner_pet_event_time
  on public.experiment_events(owner_id, pet_id, event_name, event_at);

create unique index if not exists ux_experiment_events_retention_once
  on public.experiment_events(owner_id, pet_id, event_name)
  where event_name in ('user_returned_d1', 'user_returned_d7', 'user_returned_d21');

create or replace function public.set_owner_id_from_auth()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.owner_id is null then
    new.owner_id := auth.uid();
  end if;

  if new.owner_id is null then
    raise exception 'owner_id is required';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_pet_backups_set_owner on public.pet_backups;
create trigger trg_pet_backups_set_owner
before insert on public.pet_backups
for each row
execute function public.set_owner_id_from_auth();

drop trigger if exists trg_fcm_tokens_set_owner on public.fcm_tokens;
create trigger trg_fcm_tokens_set_owner
before insert on public.fcm_tokens
for each row
execute function public.set_owner_id_from_auth();

drop trigger if exists trg_experiment_events_set_owner on public.experiment_events;
create trigger trg_experiment_events_set_owner
before insert on public.experiment_events
for each row
execute function public.set_owner_id_from_auth();

create or replace function public.maybe_mark_retention_return()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  signup_at timestamptz;
  elapsed interval;
begin
  if new.event_name <> 'session_started' then
    return new;
  end if;

  select min(event_at)
    into signup_at
  from public.experiment_events
  where owner_id = new.owner_id
    and pet_id = new.pet_id
    and event_name = 'signup_completed';

  if signup_at is null then
    return new;
  end if;

  elapsed := new.event_at - signup_at;

  if elapsed >= interval '1 day' and elapsed < interval '2 day' then
    insert into public.experiment_events (owner_id, pet_id, event_name, event_at, properties)
    values (
      new.owner_id,
      new.pet_id,
      'user_returned_d1',
      new.event_at,
      jsonb_build_object('generated_by', 'retention_trigger', 'source_event_id', new.id)
    )
    on conflict do nothing;
  end if;

  if elapsed >= interval '7 day' and elapsed < interval '8 day' then
    insert into public.experiment_events (owner_id, pet_id, event_name, event_at, properties)
    values (
      new.owner_id,
      new.pet_id,
      'user_returned_d7',
      new.event_at,
      jsonb_build_object('generated_by', 'retention_trigger', 'source_event_id', new.id)
    )
    on conflict do nothing;
  end if;

  if elapsed >= interval '21 day' and elapsed < interval '22 day' then
    insert into public.experiment_events (owner_id, pet_id, event_name, event_at, properties)
    values (
      new.owner_id,
      new.pet_id,
      'user_returned_d21',
      new.event_at,
      jsonb_build_object('generated_by', 'retention_trigger', 'source_event_id', new.id)
    )
    on conflict do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_experiment_events_mark_retention on public.experiment_events;
create trigger trg_experiment_events_mark_retention
after insert on public.experiment_events
for each row
execute function public.maybe_mark_retention_return();

alter table public.pet_backups enable row level security;
alter table public.fcm_tokens enable row level security;
alter table public.experiment_events enable row level security;

drop policy if exists pet_backups_select_own on public.pet_backups;
create policy pet_backups_select_own
on public.pet_backups
for select
using (auth.uid() = owner_id);

drop policy if exists pet_backups_insert_own on public.pet_backups;
create policy pet_backups_insert_own
on public.pet_backups
for insert
with check (auth.uid() = owner_id);

drop policy if exists pet_backups_update_own on public.pet_backups;
create policy pet_backups_update_own
on public.pet_backups
for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists pet_backups_delete_own on public.pet_backups;
create policy pet_backups_delete_own
on public.pet_backups
for delete
using (auth.uid() = owner_id);

drop policy if exists fcm_tokens_select_own on public.fcm_tokens;
create policy fcm_tokens_select_own
on public.fcm_tokens
for select
using (auth.uid() = owner_id);

drop policy if exists fcm_tokens_insert_own on public.fcm_tokens;
create policy fcm_tokens_insert_own
on public.fcm_tokens
for insert
with check (auth.uid() = owner_id);

drop policy if exists fcm_tokens_update_own on public.fcm_tokens;
create policy fcm_tokens_update_own
on public.fcm_tokens
for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists fcm_tokens_delete_own on public.fcm_tokens;
create policy fcm_tokens_delete_own
on public.fcm_tokens
for delete
using (auth.uid() = owner_id);

drop policy if exists experiment_events_select_own on public.experiment_events;
create policy experiment_events_select_own
on public.experiment_events
for select
using (auth.uid() = owner_id);

drop policy if exists experiment_events_insert_own on public.experiment_events;
create policy experiment_events_insert_own
on public.experiment_events
for insert
with check (auth.uid() = owner_id);

drop policy if exists experiment_events_update_own on public.experiment_events;
create policy experiment_events_update_own
on public.experiment_events
for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists experiment_events_delete_own on public.experiment_events;
create policy experiment_events_delete_own
on public.experiment_events
for delete
using (auth.uid() = owner_id);

create or replace view public.retention_daily_cohorts
with (security_invoker = true) as
with signups as (
  select
    owner_id,
    pet_id,
    min(event_at) as signup_at,
    date_trunc('day', min(event_at))::date as cohort_day
  from public.experiment_events
  where event_name = 'signup_completed'
  group by owner_id, pet_id
),
returns as (
  select
    owner_id,
    pet_id,
    bool_or(event_name = 'user_returned_d1') as returned_d1,
    bool_or(event_name = 'user_returned_d7') as returned_d7,
    bool_or(event_name = 'user_returned_d21') as returned_d21
  from public.experiment_events
  where event_name in ('user_returned_d1', 'user_returned_d7', 'user_returned_d21')
  group by owner_id, pet_id
)
select
  s.cohort_day,
  count(*) as signup_users,
  count(*) filter (where coalesce(r.returned_d1, false)) as d1_users,
  count(*) filter (where coalesce(r.returned_d7, false)) as d7_users,
  count(*) filter (where coalesce(r.returned_d21, false)) as d21_users,
  round((count(*) filter (where coalesce(r.returned_d1, false)))::numeric / nullif(count(*), 0), 4) as d1_rate,
  round((count(*) filter (where coalesce(r.returned_d7, false)))::numeric / nullif(count(*), 0), 4) as d7_rate,
  round((count(*) filter (where coalesce(r.returned_d21, false)))::numeric / nullif(count(*), 0), 4) as d21_rate
from signups s
left join returns r
  on r.owner_id = s.owner_id
 and r.pet_id = s.pet_id
group by s.cohort_day
order by s.cohort_day;

commit;
