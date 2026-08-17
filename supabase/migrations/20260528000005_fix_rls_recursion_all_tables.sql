-- Replace all recursive policies (which query profiles from within a subquery,
-- causing infinite RLS recursion) with a SECURITY DEFINER helper function.

CREATE OR REPLACE FUNCTION public.auth_role()
RETURNS TEXT
SECURITY DEFINER
LANGUAGE sql
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- exam_results
DROP POLICY IF EXISTS "Teachers can read all scores" ON public.exam_results;
DROP POLICY IF EXISTS "Teachers can view all exam results" ON public.exam_results;
DROP POLICY IF EXISTS "Teachers can view all results" ON public.exam_results;

CREATE POLICY "Teachers can read all scores" ON public.exam_results
    FOR SELECT TO authenticated
    USING (public.auth_role() = 'teacher');

CREATE POLICY "Teachers can view all exam results" ON public.exam_results
    FOR SELECT TO public
    USING (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

-- exams
DROP POLICY IF EXISTS "Teachers can manage exams" ON public.exams;
CREATE POLICY "Teachers can manage exams" ON public.exams
    FOR ALL TO public
    USING (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

-- issues
DROP POLICY IF EXISTS "Admins can view all issues" ON public.issues;
CREATE POLICY "Admins can view all issues" ON public.issues
    FOR SELECT TO public
    USING (public.auth_role() = ANY (ARRAY['admin', 'teacher']));

-- reports
DROP POLICY IF EXISTS "Admins can view all reports" ON public.reports;
CREATE POLICY "Admins can view all reports" ON public.reports
    FOR SELECT TO public
    USING (public.auth_role() = 'admin');
