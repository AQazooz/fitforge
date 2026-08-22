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

## Secrets

Never commit Supabase secret/service-role keys. The Flutter client must use only a publishable/anon-compatible public key.

Local environment variables should be provided through `--dart-define` or a local `.env` workflow that is excluded from git.
