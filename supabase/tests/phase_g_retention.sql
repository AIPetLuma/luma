begin;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_pet text := 'pet-' || replace(gen_random_uuid()::text, '-', '');
  v_signup timestamptz := '2026-02-01T10:00:00Z'::timestamptz;
  v_count int;
begin
  insert into public.experiment_events (owner_id, pet_id, event_name, event_at)
  values (v_owner, v_pet, 'signup_completed', v_signup);

  -- signup + 25h -> only d1
  insert into public.experiment_events (owner_id, pet_id, event_name, event_at)
  values (v_owner, v_pet, 'session_started', v_signup + interval '25 hour');

  select count(*) into v_count
  from public.experiment_events
  where owner_id = v_owner and pet_id = v_pet and event_name = 'user_returned_d1';
  if v_count <> 1 then
    raise exception 'Expected exactly 1 d1 event after +25h, got %', v_count;
  end if;

  select count(*) into v_count
  from public.experiment_events
  where owner_id = v_owner and pet_id = v_pet and event_name = 'user_returned_d7';
  if v_count <> 0 then
    raise exception 'Expected 0 d7 event after +25h, got %', v_count;
  end if;

  -- signup + 7d + 1m -> d7
  insert into public.experiment_events (owner_id, pet_id, event_name, event_at)
  values (v_owner, v_pet, 'session_started', v_signup + interval '7 day 1 minute');

  select count(*) into v_count
  from public.experiment_events
  where owner_id = v_owner and pet_id = v_pet and event_name = 'user_returned_d7';
  if v_count <> 1 then
    raise exception 'Expected exactly 1 d7 event after +7d+1m, got %', v_count;
  end if;

  -- duplicate in same window should not duplicate d7
  insert into public.experiment_events (owner_id, pet_id, event_name, event_at)
  values (v_owner, v_pet, 'session_started', v_signup + interval '7 day 2 minute');

  select count(*) into v_count
  from public.experiment_events
  where owner_id = v_owner and pet_id = v_pet and event_name = 'user_returned_d7';
  if v_count <> 1 then
    raise exception 'Expected deduped d7 count=1, got %', v_count;
  end if;

  -- signup + 21d + 1m -> d21
  insert into public.experiment_events (owner_id, pet_id, event_name, event_at)
  values (v_owner, v_pet, 'session_started', v_signup + interval '21 day 1 minute');

  select count(*) into v_count
  from public.experiment_events
  where owner_id = v_owner and pet_id = v_pet and event_name = 'user_returned_d21';
  if v_count <> 1 then
    raise exception 'Expected exactly 1 d21 event after +21d+1m, got %', v_count;
  end if;

  -- duplicate in same window should not duplicate d21
  insert into public.experiment_events (owner_id, pet_id, event_name, event_at)
  values (v_owner, v_pet, 'session_started', v_signup + interval '21 day 2 minute');

  select count(*) into v_count
  from public.experiment_events
  where owner_id = v_owner and pet_id = v_pet and event_name = 'user_returned_d21';
  if v_count <> 1 then
    raise exception 'Expected deduped d21 count=1, got %', v_count;
  end if;
end;
$$;

rollback;
