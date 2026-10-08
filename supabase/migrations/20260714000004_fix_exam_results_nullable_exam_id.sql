-- Fix: Remove NOT NULL constraint from exam_results.exam_id
-- The FK ON DELETE SET NULL was failing because exam_id was NOT NULL
ALTER TABLE public.exam_results ALTER COLUMN exam_id DROP NOT NULL;