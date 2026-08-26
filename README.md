# FitForge

A production-oriented Flutter fitness tracking app powered by Supabase.

## Stack

- Flutter / Dart
- Riverpod
- GoRouter
- Supabase Auth / PostgreSQL / Storage / Edge Functions
- GitHub Actions

## Repository structure

```text
lib/
  app/
  core/
  features/
    auth/
    biometrics/
    dashboard/
    nutrition/
    profile/
    workouts/
  main.dart
supabase/
  README.md
  migrations/
    0001_fitforge_schema.sql
    0002_workout_catalog_and_starter_plan.sql
    0003_index_workout_foreign_keys.sql
    0004_food_catalog.sql
    0005_nutrition_targets_unique_per_day.sql
test/
  nutrition_intelligence_test.dart
  progress_summary_test.dart
.github/
  workflows/
    flutter_ci.yml
    flutter_release.yml
    flutter_web.yml
```

## Backend

Supabase project ref: `nhiuqjuwbahiffwltnzd`

The production database contains the FitForge domain model for profiles, biometrics, exercises, workout plans and logs, and nutrition tracking. RLS is enabled on the application tables and ownership policies are defined in the schema migration.

The migrations are now the repository source of truth for rebuilding the schema in a fresh Supabase project. The current production project is already provisioned, so the snapshot migrations should **not** be replayed against it.

Migration history:

- `0001_fitforge_schema.sql` — base schema and RLS policies for the ten core domain tables.
- `0002_workout_catalog_and_starter_plan.sql` — exercise catalog and starter workout-plan RPC.
- `0003_index_workout_foreign_keys.sql` — workout foreign-key indexes.
- `0004_food_catalog.sql` — nutrition food catalog.
- `0005_nutrition_targets_unique_per_day.sql` — records the production drift fix enforcing one nutrition target per user and effective date, with the supporting index.

## Flutter configuration

The Flutter client reads only public Supabase configuration at runtime:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://nhiuqjuwbahiffwltnzd.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-publishable-key>
```

Never commit a Supabase secret/service-role key.

## Current state

### Application foundation

- Supabase initialization
- Riverpod `ProviderScope`
- GoRouter with auth-aware protected routing
- Supabase Auth repository and authentication flows
- Runtime environment configuration using `--dart-define`

### Profile

- Profile setup and persistence through `users_profiles`
- Goal, training level, unit system, height, sex, and date-of-birth fields

### Biometrics

- Athlete biometric capture and persistence
- Weight, body-fat, muscle-mass, BMI, waist, measurement timestamp, and notes
- Own-user RLS policies

### Workouts

- Workout plans, days, exercises, workout sessions, and logged sets
- Starter workout-plan RPC backed by the exercise catalog
- Progress repository and progress summary UI
- Own-user RLS policies across the workout hierarchy

### Nutrition

- Nutrition targets and daily nutrition logs
- Food catalog and food search
- `NutritionIntelligence` calculations, including Katch-McArdle-based energy estimation
- Nutrition coach and nutrition tracking UI
- Per-user nutrition RLS policies

### Quality / CI

- GitHub Actions CI for Flutter
- Web and release workflows
- Automated Dart/Flutter analysis and tests
- Unit tests for nutrition intelligence and progress summaries

## Development order

The current product development sequence is:

**Profile → Workout → Progress → Nutrition**

Schema synchronization and CI validation take priority before further Workout UI changes.
