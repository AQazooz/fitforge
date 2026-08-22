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
  main.dart
supabase/
  README.md
  migrations/
    0001_fitforge_schema.sql
```

## Backend

Supabase project ref: `nhiuqjuwbahiffwltnzd`

The database contains the initial FitForge domain model for profiles, biometrics, exercises, workout plans/logs, and nutrition tracking. RLS is enabled for application tables.

## Flutter configuration

The Flutter client reads only public Supabase configuration at runtime:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://nhiuqjuwbahiffwltnzd.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-publishable-key>
```

Never commit a Supabase secret/service-role key.

## Current foundation

- Supabase initialization
- Riverpod `ProviderScope`
- GoRouter
- Supabase Auth repository
- Login screen
- Registration screen
- Initial home screen
- Runtime environment configuration using `--dart-define`

Authentication is not yet route-guarded; the next foundation step is an auth-aware router refresh with protected routes and profile onboarding.
