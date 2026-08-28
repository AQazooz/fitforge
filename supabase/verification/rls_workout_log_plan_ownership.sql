-- TEST ENVIRONMENT ONLY. Run in the Supabase SQL editor as the database owner.
-- This transaction rolls back all fixture rows. Substitute two existing,
-- dedicated test-account IDs; never use production user IDs.

begin;

select set_config('app.fitforge_test.alice_id', 'REPLACE_WITH_ALICE_UUID', true);
select set_config('app.fitforge_test.bob_id', 'REPLACE_WITH_BOB_UUID', true);

do $$
declare
  alice_id uuid := current_setting('app.fitforge_test.alice_id')::uuid;
  bob_id uuid := current_setting('app.fitforge_test.bob_id')::uuid;
  alice_plan_id uuid;
  bob_plan_id uuid;
begin
  if not exists (select 1 from auth.users where id = alice_id) then
    raise exception 'Alice test account does not exist';
  end if;
  if not exists (select 1 from auth.users where id = bob_id) then
    raise exception 'Bob test account does not exist';
  end if;

  insert into public.workout_plans (user_id, name, goal, days_per_week)
  values (alice_id, 'RLS verification: Alice', 'maintenance', 1)
  returning id into alice_plan_id;

  insert into public.workout_plans (user_id, name, goal, days_per_week)
  values (bob_id, 'RLS verification: Bob', 'maintenance', 1)
  returning id into bob_plan_id;

  perform set_config('app.fitforge_test.alice_plan_id', alice_plan_id::text, true);
  perform set_config('app.fitforge_test.bob_plan_id', bob_plan_id::text, true);
end
$$;

-- Simulate requests made with Alice's authenticated JWT.
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  current_setting('app.fitforge_test.alice_id'),
  true
);

-- PASS: Alice can create a log for Alice's plan.
do $$
declare
  alice_id uuid := current_setting('app.fitforge_test.alice_id')::uuid;
  alice_plan_id uuid := current_setting('app.fitforge_test.alice_plan_id')::uuid;
  log_id uuid;
begin
  insert into public.workout_logs (user_id, plan_id)
  values (alice_id, alice_plan_id)
  returning id into log_id;
  perform set_config('app.fitforge_test.alice_log_id', log_id::text, true);
end
$$;

-- PASS: Alice can create an unplanned log.
insert into public.workout_logs (user_id, plan_id)
values (current_setting('app.fitforge_test.alice_id')::uuid, null);

-- PASS: Alice cannot create a log that references Bob's plan.
do $$
begin
  begin
    insert into public.workout_logs (user_id, plan_id)
    values (
      current_setting('app.fitforge_test.alice_id')::uuid,
      current_setting('app.fitforge_test.bob_plan_id')::uuid
    );
    raise exception 'FAIL: foreign plan insert was allowed';
  exception when insufficient_privilege then
    raise notice 'PASS: foreign plan insert rejected by RLS';
  end;
end
$$;

-- PASS: Alice cannot change her own log to Bob's plan.
do $$
begin
  begin
    update public.workout_logs
    set plan_id = current_setting('app.fitforge_test.bob_plan_id')::uuid
    where id = current_setting('app.fitforge_test.alice_log_id')::uuid;
    raise exception 'FAIL: foreign plan update was allowed';
  exception when insufficient_privilege then
    raise notice 'PASS: foreign plan update rejected by RLS';
  end;
end
$$;

-- PASS: Alice cannot forge a log for Bob, even using Alice's plan.
do $$
begin
  begin
    insert into public.workout_logs (user_id, plan_id)
    values (
      current_setting('app.fitforge_test.bob_id')::uuid,
      current_setting('app.fitforge_test.alice_plan_id')::uuid
    );
    raise exception 'FAIL: cross-user log insert was allowed';
  exception when insufficient_privilege then
    raise notice 'PASS: cross-user log insert rejected by RLS';
  end;
end
$$;

rollback;
