# FitForge Supabase

Project ref: `nhiuqjuwbahiffwltnzd`

## Database

The initial schema is already deployed to the connected Supabase project. It includes:

- users_profiles
- athlete_biometrics
- exercises
- workout_plans
- workout_plan_days
- workout_plan_exercises
- workout_logs
- workout_log_sets
- nutrition_targets
- nutrition_logs

RLS is enabled on all application tables. Authorization is based on the authenticated user's `auth.uid()` and ownership relationships.

## Security

- Never put a service-role/secret key in Flutter.
- Use the project's publishable key for the client.
- Keep database authorization in RLS policies.
- `workout_logs.plan_id` must refer to a plan owned by the current user; the
  `0006_workout_log_plan_ownership.sql` policy enforces this independently of
  the Flutter client.
- Review Supabase advisors after schema changes.

## Client configuration

Provide only these compile-time values to the Flutter client:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

The app intentionally does not initialize Supabase when either value is
missing. Do not use a `service_role` or secret key in either value.
