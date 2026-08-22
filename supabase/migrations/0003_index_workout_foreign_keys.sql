create index if not exists workout_log_sets_exercise_idx on public.workout_log_sets (exercise_id);
create index if not exists workout_logs_plan_idx on public.workout_logs (plan_id);
create index if not exists workout_plan_exercises_exercise_idx on public.workout_plan_exercises (exercise_id);
