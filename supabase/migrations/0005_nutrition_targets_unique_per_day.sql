-- FitForge schema drift reconciliation.
-- Production contains a per-user/per-day uniqueness constraint and its supporting date index.
-- This migration documents that production-only constraint for future environments.
-- Do not replay against the already-provisioned production project.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'nutrition_targets_user_id_effective_from_key'
      AND conrelid = 'public.nutrition_targets'::regclass
  ) THEN
    ALTER TABLE public.nutrition_targets
      ADD CONSTRAINT nutrition_targets_user_id_effective_from_key
      UNIQUE (user_id, effective_from);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS nutrition_targets_user_date_idx
  ON public.nutrition_targets (user_id, effective_from DESC);
