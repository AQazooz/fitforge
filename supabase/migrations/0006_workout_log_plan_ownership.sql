-- Enforce plan ownership at the database boundary. Client-side checks are not
-- sufficient because a caller can submit any UUID to the Data API directly.

drop policy if exists workout_logs_insert_own on public.workout_logs;

create policy workout_logs_insert_own
on public.workout_logs
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and (
    plan_id is null
    or exists (
      select 1
      from public.workout_plans
      where workout_plans.id = workout_logs.plan_id
        and workout_plans.user_id = (select auth.uid())
    )
  )
);
