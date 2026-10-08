-- Fix recursive RLS on profiles table using auth_role() helper (already defined)
-- This mirrors the fix applied to exam_results, exams, issues, reports in 20260528000005

DROP POLICY IF EXISTS "Teachers can view profiles" ON public.profiles;

CREATE POLICY "Teachers can view profiles" ON public.profiles
    FOR SELECT TO authenticated
    USING (public.auth_role() = ANY (ARRAY['teacher', 'admin']));
