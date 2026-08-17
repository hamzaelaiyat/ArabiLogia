-- Schema hardening part 1: constraints, foreign keys, and indexes
-- Migration date: 2026-06-18

-- 1. CHECK constraint on exam_results.score to ensure scores are between 0 and 100
ALTER TABLE public.exam_results ADD CONSTRAINT check_score_range CHECK (score >= 0 AND score <= 100);

-- 2. Foreign key from exam_results.exam_id to exams.id with ON DELETE SET NULL
-- Note: exam_id is TEXT, exams.id is TEXT (implicitly). We need to ensure types match.
-- First, clean up any orphaned exam_results where the exam doesn't exist
DELETE FROM public.exam_results WHERE exam_id IS NOT NULL AND exam_id NOT IN (SELECT id FROM public.exams);
-- Then add the FK
ALTER TABLE public.exam_results ADD CONSTRAINT fk_exam_results_exam FOREIGN KEY (exam_id) REFERENCES public.exams(id) ON DELETE SET NULL;

-- 3. ON DELETE CASCADE for reports.user_id
-- First clean up orphaned reports
DELETE FROM public.reports WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM auth.users);
-- Then alter the FK to add CASCADE
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_user_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. Composite index on exam_results for leaderboard queries
CREATE INDEX IF NOT EXISTS idx_exam_results_user_exam ON public.exam_results(user_id, exam_id);
