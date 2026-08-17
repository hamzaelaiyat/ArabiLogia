-- ============================================================
-- Gate + Security hardening — Part 7: Per-grade reads + practice
-- - Tighten exams SELECT to the student's grade (was USING true
--   for both anon and authenticated — cross-grade content leak).
-- - Tighten lectures SELECT to the student's grade.
-- - Stop get_practice_exam from returning the answer key.
--   Answers are only revealed via get_exam_review after the
--   student completes the attempt.
-- ============================================================

-- ---------- exams: students only see exams for their grade ----------
DROP POLICY IF EXISTS "Allow all users to read exams" ON public.exams;
DROP POLICY IF EXISTS "Anyone can read exams" ON public.exams;
DROP POLICY IF EXISTS "Students view exams for their grade" ON public.exams;

CREATE POLICY "Students view published exams for their grade" ON public.exams
    FOR SELECT TO authenticated
    USING (
        COALESCE((data->>'p')::int, 0) = 1
        AND public.exam_available_for_grade(id, (SELECT grade FROM public.profiles WHERE id = auth.uid()))
    );

-- Staff still covered by the existing "Staff can manage exams" ALL policy.

-- ---------- lectures: students only see lectures for their grade ----------
DROP POLICY IF EXISTS "Students view published lectures" ON public.lectures;
CREATE POLICY "Students view published lectures for their grade" ON public.lectures
    FOR SELECT TO public
    USING (
        is_published = true
        AND (
            grade_ids @> ARRAY[0]
            OR grade_ids @> ARRAY[(SELECT grade FROM public.profiles WHERE id = auth.uid())]
            OR (array_length(grade_ids, 1) IS NULL
                AND (grade = 0 OR grade = (SELECT grade FROM public.profiles WHERE id = auth.uid())))
        )
    );

-- ---------- get_practice_exam: return questions only (no answer key) ----------
CREATE OR REPLACE FUNCTION public.get_practice_exam(p_exam_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_linked boolean;
    v_data jsonb;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.lectures
        WHERE quiz_id = p_exam_id
          AND (
              grade_ids @> ARRAY[0]
              OR grade_ids @> ARRAY[(SELECT grade FROM public.profiles WHERE id = v_uid)]
              OR (array_length(grade_ids, 1) IS NULL AND (grade = 0 OR grade = (SELECT grade FROM public.profiles WHERE id = v_uid)))
          )
    ) INTO v_linked;

    IF NOT COALESCE(v_linked, false) THEN
        RAISE EXCEPTION 'الامتحان غير متاح للتدريب' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT data INTO v_data FROM public.exams WHERE id = p_exam_id;
    IF v_data IS NULL THEN
        RAISE EXCEPTION 'الامتحان غير موجود' USING ERRCODE = 'no_data_found';
    END IF;

    RETURN v_data;
END;
$function$;

-- Re-grant because CREATE OR REPLACE resets to default.
GRANT EXECUTE ON FUNCTION public.get_practice_exam(text) TO anon, authenticated;
