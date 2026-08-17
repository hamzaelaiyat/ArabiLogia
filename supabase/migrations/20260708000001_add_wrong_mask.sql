-- Replace TEXT[] wrong_answers with BIGINT bitmask for ~99% storage savings
-- Each bit represents a question index: bit N = 1 means question at index N was wrong

ALTER TABLE public.exam_results
  ADD COLUMN IF NOT EXISTS wrong_mask BIGINT NOT NULL DEFAULT 0;

-- Remove old TEXT[] column — it's never read anywhere in the app
ALTER TABLE public.exam_results
  DROP COLUMN IF EXISTS wrong_answers;
