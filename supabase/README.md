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
- Review Supabase advisors after schema changes.
