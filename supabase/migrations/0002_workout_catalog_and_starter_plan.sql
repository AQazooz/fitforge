-- FitForge workout catalog + starter-plan RPC.

insert into public.exercises (name, muscle_group, equipment, instructions, is_active)
values
  ('Barbell Bench Press', 'chest', 'barbell', 'Lie flat, brace your core, lower the bar to mid-chest, then press to full elbow extension.', true),
  ('Lat Pulldown', 'back', 'cable', 'Pull the bar toward the upper chest while keeping the torso stable and elbows driving down.', true),
  ('Seated Cable Row', 'back', 'cable', 'Pull the handle toward your torso while keeping the chest lifted and shoulders controlled.', true),
  ('Barbell Squat', 'legs', 'barbell', 'Brace, squat with controlled depth while keeping the knees tracking over the toes, then stand tall.', true),
  ('Romanian Deadlift', 'hamstrings', 'barbell', 'Hinge at the hips with a neutral spine and lower the bar along the legs before driving the hips forward.', true),
  ('Leg Press', 'legs', 'machine', 'Lower the platform with control, keep the knees aligned with the feet, then press through the full foot.', true),
  ('Dumbbell Shoulder Press', 'shoulders', 'dumbbells', 'Press the dumbbells overhead without excessive arching and lower under control.', true),
  ('Cable Lateral Raise', 'shoulders', 'cable', 'Raise the arm to shoulder height with a slight bend in the elbow and controlled tempo.', true),
  ('EZ-Bar Curl', 'biceps', 'ez_bar', 'Curl the bar without swinging, keeping the upper arms relatively fixed.', true),
  ('Cable Triceps Pushdown', 'triceps', 'cable', 'Extend the elbows down while keeping the upper arms close to the torso.', true),
  ('Standing Calf Raise', 'calves', 'machine', 'Drive through the balls of the feet, pause at the top, and lower with a full stretch.', true),
  ('Cable Crunch', 'abs', 'cable', 'Brace the abdomen and curl the ribcage toward the pelvis without pulling with the arms.', true)
on conflict (name) do nothing;

create or replace function public.create_starter_workout_plan()
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan_id uuid;
  v_day_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select id into v_plan_id
  from public.workout_plans
  where user_id = v_user_id and is_active = true
  order by created_at desc
  limit 1;

  if v_plan_id is not null then
    return v_plan_id;
  end if;

  insert into public.workout_plans (user_id, name, description, goal, days_per_week, is_active)
  values (v_user_id, 'FitForge Starter', 'A simple full-body starter plan for building consistency.', 'muscle_gain', 3, true)
  returning id into v_plan_id;

  insert into public.workout_plan_days (plan_id, day_number, title, notes)
  values
    (v_plan_id, 1, 'Full Body A', 'Focus on controlled reps and consistent technique.'),
    (v_plan_id, 2, 'Full Body B', 'Keep 1-3 reps in reserve on most working sets.'),
    (v_plan_id, 3, 'Full Body C', 'Progress load or reps gradually when form is solid.');

  insert into public.workout_plan_exercises (plan_day_id, exercise_id, sort_order, sets, reps_min, reps_max, rest_seconds, target_rir)
  select d.id, e.id, x.sort_order, 3, x.reps_min, x.reps_max, x.rest_seconds, 2
  from public.workout_plan_days d
  join (values
    (1, 'Barbell Bench Press', 1, 6, 10, 120),
    (1, 'Lat Pulldown', 2, 8, 12, 90),
    (1, 'Barbell Squat', 3, 6, 10, 120),
    (1, 'Cable Lateral Raise', 4, 10, 15, 60),
    (1, 'Cable Triceps Pushdown', 5, 10, 15, 60),
    (2, 'Romanian Deadlift', 1, 6, 10, 120),
    (2, 'Seated Cable Row', 2, 8, 12, 90),
    (2, 'Leg Press', 3, 8, 12, 120),
    (2, 'Dumbbell Shoulder Press', 4, 8, 12, 90),
    (2, 'EZ-Bar Curl', 5, 10, 15, 60),
    (3, 'Barbell Squat', 1, 6, 10, 120),
    (3, 'Barbell Bench Press', 2, 8, 12, 90),
    (3, 'Seated Cable Row', 3, 8, 12, 90),
    (3, 'Standing Calf Raise', 4, 10, 15, 60),
    (3, 'Cable Crunch', 5, 10, 15, 60)
  ) as x(day_number, exercise_name, sort_order, reps_min, reps_max, rest_seconds)
    on true
  join public.exercises e on e.name = x.exercise_name and e.is_active = true
  where d.plan_id = v_plan_id and d.day_number = x.day_number;

  return v_plan_id;
end;
$$;

grant execute on function public.create_starter_workout_plan() to authenticated;
