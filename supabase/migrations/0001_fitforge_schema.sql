-- FitForge initial schema snapshot.
-- Source: Supabase project ref nhiuqjuwbahiffwltnzd.
-- This migration documents the base production schema for reproducible future environments.
-- The nutrition target uniqueness drift is intentionally documented in 0005.
-- It is not intended to be replayed against the already-provisioned production project.

create table public.users_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  date_of_birth date,
  sex text,
  height_cm numeric,
  unit_system text not null default 'metric',
  training_level text not null default 'beginner',
  goal text not null default 'muscle_gain',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_profiles_sex_check check (sex = any (array['male','female','other','prefer_not_to_say']::text[])),
  constraint users_profiles_height_cm_check check (height_cm is null or height_cm > 0),
  constraint users_profiles_unit_system_check check (unit_system = any (array['metric','imperial']::text[])),
  constraint users_profiles_training_level_check check (training_level = any (array['beginner','intermediate','advanced']::text[])),
  constraint users_profiles_goal_check check (goal = any (array['muscle_gain','fat_loss','recomposition','maintenance','performance']::text[]))
);

create table public.athlete_biometrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  measured_at timestamptz not null default now(),
  weight_kg numeric,
  body_fat_pct numeric,
  muscle_mass_kg numeric,
  bmi numeric,
  waist_cm numeric,
  notes text,
  created_at timestamptz not null default now(),
  constraint athlete_biometrics_weight_kg_check check (weight_kg is null or weight_kg > 0),
  constraint athlete_biometrics_body_fat_pct_check check (body_fat_pct is null or (body_fat_pct >= 0 and body_fat_pct <= 100)),
  constraint athlete_biometrics_muscle_mass_kg_check check (muscle_mass_kg is null or muscle_mass_kg >= 0),
  constraint athlete_biometrics_waist_cm_check check (waist_cm is null or waist_cm > 0)
);

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  muscle_group text not null,
  equipment text,
  instructions text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  goal text not null default 'muscle_gain',
  days_per_week smallint,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workout_plans_days_per_week_check check (days_per_week >= 1 and days_per_week <= 7),
  constraint workout_plans_goal_check check (goal = any (array['muscle_gain','fat_loss','recomposition','maintenance','performance']::text[]))
);

create table public.workout_plan_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.workout_plans(id) on delete cascade,
  day_number smallint not null,
  title text not null,
  notes text,
  constraint workout_plan_days_day_number_check check (day_number >= 1 and day_number <= 7),
  constraint workout_plan_days_plan_id_day_number_key unique (plan_id, day_number)
);

create table public.workout_plan_exercises (
  id uuid primary key default gen_random_uuid(),
  plan_day_id uuid not null references public.workout_plan_days(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  sort_order smallint not null default 1,
  sets smallint,
  reps_min smallint,
  reps_max smallint,
  rest_seconds integer,
  target_rir numeric,
  notes text,
  constraint workout_plan_exercises_sort_order_check check (sort_order > 0),
  constraint workout_plan_exercises_sets_check check (sets is null or sets > 0),
  constraint workout_plan_exercises_reps_min_check check (reps_min is null or reps_min > 0),
  constraint workout_plan_exercises_check check (reps_max is null or reps_max >= reps_min),
  constraint workout_plan_exercises_rest_seconds_check check (rest_seconds is null or rest_seconds >= 0),
  constraint workout_plan_exercises_target_rir_check check (target_rir is null or (target_rir >= 0 and target_rir <= 10)),
  constraint workout_plan_exercises_plan_day_id_sort_order_key unique (plan_day_id, sort_order)
);

create table public.workout_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_id uuid references public.workout_plans(id) on delete set null,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create table public.workout_log_sets (
  id uuid primary key default gen_random_uuid(),
  workout_log_id uuid not null references public.workout_logs(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  set_number smallint not null,
  reps smallint,
  weight_kg numeric,
  rir numeric,
  duration_seconds integer,
  notes text,
  constraint workout_log_sets_set_number_check check (set_number > 0),
  constraint workout_log_sets_reps_check check (reps is null or reps >= 0),
  constraint workout_log_sets_weight_kg_check check (weight_kg is null or weight_kg >= 0),
  constraint workout_log_sets_rir_check check (rir is null or (rir >= 0 and rir <= 10)),
  constraint workout_log_sets_duration_seconds_check check (duration_seconds is null or duration_seconds >= 0),
  constraint workout_log_sets_workout_log_id_exercise_id_set_number_key unique (workout_log_id, exercise_id, set_number)
);

create table public.nutrition_targets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  effective_from date not null default current_date,
  calories integer,
  protein_g numeric,
  carbs_g numeric,
  fat_g numeric,
  fiber_g numeric,
  created_at timestamptz not null default now(),
  constraint nutrition_targets_calories_check check (calories is null or calories > 0),
  constraint nutrition_targets_protein_g_check check (protein_g is null or protein_g >= 0),
  constraint nutrition_targets_carbs_g_check check (carbs_g is null or carbs_g >= 0),
  constraint nutrition_targets_fat_g_check check (fat_g is null or fat_g >= 0),
  constraint nutrition_targets_fiber_g_check check (fiber_g is null or fiber_g >= 0)
);

create table public.nutrition_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  consumed_at timestamptz not null default now(),
  meal_type text,
  food_name text not null,
  calories integer,
  protein_g numeric,
  carbs_g numeric,
  fat_g numeric,
  serving_size text,
  created_at timestamptz not null default now(),
  constraint nutrition_logs_calories_check check (calories is null or calories >= 0),
  constraint nutrition_logs_protein_g_check check (protein_g is null or protein_g >= 0),
  constraint nutrition_logs_carbs_g_check check (carbs_g is null or carbs_g >= 0),
  constraint nutrition_logs_fat_g_check check (fat_g is null or fat_g >= 0),
  constraint nutrition_logs_meal_type_check check (meal_type = any (array['breakfast','lunch','dinner','snack','pre_workout','post_workout']::text[]))
);

create index athlete_biometrics_user_measured_idx on public.athlete_biometrics (user_id, measured_at desc);
create index nutrition_logs_user_consumed_idx on public.nutrition_logs (user_id, consumed_at desc);
create index workout_log_sets_exercise_idx on public.workout_log_sets (exercise_id);
create index workout_logs_plan_idx on public.workout_logs (plan_id);
create index workout_logs_user_started_idx on public.workout_logs (user_id, started_at desc);
create index workout_plan_exercises_exercise_idx on public.workout_plan_exercises (exercise_id);
create index workout_plans_user_idx on public.workout_plans (user_id);

alter table public.users_profiles enable row level security;
alter table public.athlete_biometrics enable row level security;
alter table public.exercises enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_plan_days enable row level security;
alter table public.workout_plan_exercises enable row level security;
alter table public.workout_logs enable row level security;
alter table public.workout_log_sets enable row level security;
alter table public.nutrition_targets enable row level security;
alter table public.nutrition_logs enable row level security;

create policy users_profiles_select_own on public.users_profiles for select to authenticated using ((select auth.uid()) = id);
create policy users_profiles_insert_own on public.users_profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy users_profiles_update_own on public.users_profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy athlete_biometrics_select_own on public.athlete_biometrics for select to authenticated using ((select auth.uid()) = user_id);
create policy athlete_biometrics_insert_own on public.athlete_biometrics for insert to authenticated with check ((select auth.uid()) = user_id);
create policy athlete_biometrics_update_own on public.athlete_biometrics for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy athlete_biometrics_delete_own on public.athlete_biometrics for delete to authenticated using ((select auth.uid()) = user_id);

create policy exercises_read_authenticated on public.exercises for select to authenticated using (is_active = true);

create policy workout_plans_select_own on public.workout_plans for select to authenticated using ((select auth.uid()) = user_id);
create policy workout_plans_insert_own on public.workout_plans for insert to authenticated with check ((select auth.uid()) = user_id);
create policy workout_plans_update_own on public.workout_plans for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy workout_plans_delete_own on public.workout_plans for delete to authenticated using ((select auth.uid()) = user_id);

create policy workout_plan_days_select_own on public.workout_plan_days for select to authenticated using (exists (select 1 from public.workout_plans p where p.id = workout_plan_days.plan_id and p.user_id = (select auth.uid())));
create policy workout_plan_days_insert_own on public.workout_plan_days for insert to authenticated with check (exists (select 1 from public.workout_plans p where p.id = workout_plan_days.plan_id and p.user_id = (select auth.uid())));
create policy workout_plan_days_update_own on public.workout_plan_days for update to authenticated using (exists (select 1 from public.workout_plans p where p.id = workout_plan_days.plan_id and p.user_id = (select auth.uid()))) with check (exists (select 1 from public.workout_plans p where p.id = workout_plan_days.plan_id and p.user_id = (select auth.uid())));
create policy workout_plan_days_delete_own on public.workout_plan_days for delete to authenticated using (exists (select 1 from public.workout_plans p where p.id = workout_plan_days.plan_id and p.user_id = (select auth.uid())));

create policy workout_plan_exercises_select_own on public.workout_plan_exercises for select to authenticated using (exists (select 1 from public.workout_plan_days d join public.workout_plans p on p.id = d.plan_id where d.id = workout_plan_exercises.plan_day_id and p.user_id = (select auth.uid())));
create policy workout_plan_exercises_insert_own on public.workout_plan_exercises for insert to authenticated with check (exists (select 1 from public.workout_plan_days d join public.workout_plans p on p.id = d.plan_id where d.id = workout_plan_exercises.plan_day_id and p.user_id = (select auth.uid())));
create policy workout_plan_exercises_update_own on public.workout_plan_exercises for update to authenticated using (exists (select 1 from public.workout_plan_days d join public.workout_plans p on p.id = d.plan_id where d.id = workout_plan_exercises.plan_day_id and p.user_id = (select auth.uid()))) with check (exists (select 1 from public.workout_plan_days d join public.workout_plans p on p.id = d.plan_id where d.id = workout_plan_exercises.plan_day_id and p.user_id = (select auth.uid())));
create policy workout_plan_exercises_delete_own on public.workout_plan_exercises for delete to authenticated using (exists (select 1 from public.workout_plan_days d join public.workout_plans p on p.id = d.plan_id where d.id = workout_plan_exercises.plan_day_id and p.user_id = (select auth.uid())));

create policy workout_logs_select_own on public.workout_logs for select to authenticated using ((select auth.uid()) = user_id);
create policy workout_logs_insert_own on public.workout_logs for insert to authenticated with check ((select auth.uid()) = user_id);
create policy workout_logs_update_own on public.workout_logs for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy workout_logs_delete_own on public.workout_logs for delete to authenticated using ((select auth.uid()) = user_id);

create policy workout_log_sets_select_own on public.workout_log_sets for select to authenticated using (exists (select 1 from public.workout_logs l where l.id = workout_log_sets.workout_log_id and l.user_id = (select auth.uid())));
create policy workout_log_sets_insert_own on public.workout_log_sets for insert to authenticated with check (exists (select 1 from public.workout_logs l where l.id = workout_log_sets.workout_log_id and l.user_id = (select auth.uid())));
create policy workout_log_sets_update_own on public.workout_log_sets for update to authenticated using (exists (select 1 from public.workout_logs l where l.id = workout_log_sets.workout_log_id and l.user_id = (select auth.uid()))) with check (exists (select 1 from public.workout_logs l where l.id = workout_log_sets.workout_log_id and l.user_id = (select auth.uid())));
create policy workout_log_sets_delete_own on public.workout_log_sets for delete to authenticated using (exists (select 1 from public.workout_logs l where l.id = workout_log_sets.workout_log_id and l.user_id = (select auth.uid())));

create policy nutrition_targets_select_own on public.nutrition_targets for select to authenticated using ((select auth.uid()) = user_id);
create policy nutrition_targets_insert_own on public.nutrition_targets for insert to authenticated with check ((select auth.uid()) = user_id);
create policy nutrition_targets_update_own on public.nutrition_targets for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy nutrition_targets_delete_own on public.nutrition_targets for delete to authenticated using ((select auth.uid()) = user_id);

create policy nutrition_logs_select_own on public.nutrition_logs for select to authenticated using ((select auth.uid()) = user_id);
create policy nutrition_logs_insert_own on public.nutrition_logs for insert to authenticated with check ((select auth.uid()) = user_id);
create policy nutrition_logs_update_own on public.nutrition_logs for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy nutrition_logs_delete_own on public.nutrition_logs for delete to authenticated using ((select auth.uid()) = user_id);
