-- ============================================================
-- Gate + Security hardening — Part 4: Server-side grading RPCs
-- ------------------------------------------------------------
-- Correct answers live ONLY in exams.answers (column-level REVOKEd).
-- Grading happens server-side; exam_results writes are RPC-only.
-- ============================================================

-- ---------- 1) exam_sessions: server-issued start timestamps ----------
CREATE TABLE IF NOT EXISTS public.exam_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exam_id TEXT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exam_sessions_user_exam
    ON public.exam_sessions (user_id, exam_id, started_at);

-- RLS enabled with NO policies => zero direct access via PostgREST.
ALTER TABLE public.exam_sessions ENABLE ROW LEVEL SECURITY;

-- ---------- 2) start_exam ----------
CREATE OR REPLACE FUNCTION public.start_exam(p_exam_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_session_id uuid;
    v_started timestamptz;
    v_published boolean;
    v_available boolean;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT (data->>'p')::int = 1,
           public.exam_available_for_grade(p_exam_id, (SELECT grade FROM public.profiles WHERE id = v_uid))
    INTO v_published, v_available
    FROM public.exams
    WHERE id = p_exam_id;

    IF v_published IS NULL THEN
        RAISE EXCEPTION 'الامتحان غير موجود' USING ERRCODE = 'no_data_found';
    END IF;
    IF NOT v_published THEN
        RAISE EXCEPTION 'الامتحان غير منشور' USING ERRCODE = 'check_violation';
    END IF;
    IF NOT COALESCE(v_available, false) THEN
        RAISE EXCEPTION 'الامتحان غير متاح لصفك الدراسي' USING ERRCODE = 'insufficient_privilege';
    END IF;

    INSERT INTO public.exam_sessions (user_id, exam_id)
    VALUES (v_uid, p_exam_id)
    RETURNING id, started_at INTO v_session_id, v_started;

    RETURN jsonb_build_object(
        'session_id', v_session_id,
        'started_at', v_started,
        'duration_seconds', (
            SELECT COALESCE(duration_minutes, 30) * 60 FROM public.exams WHERE id = p_exam_id
        )
    );
END;
$function$;

-- ---------- 3) submit_exam_answer ----------
CREATE OR REPLACE FUNCTION public.submit_exam_answer(
    p_exam_id text,
    p_answers jsonb,
    p_session_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_exam public.exams%ROWTYPE;
    v_session public.exam_sessions%ROWTYPE;
    v_total int;
    v_i int;
    v_correct int := 0;
    v_wrong_mask bigint := 0;
    v_selected text;
    v_correct_idx int;
    v_accuracy double precision := 0;
    v_total_seconds int;
    v_remaining double precision := 0;
    v_speed_bonus double precision := 0;
    v_final double precision := 0;
    v_points int;
    v_result jsonb;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_exam FROM public.exams WHERE id = p_exam_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'الامتحان غير موجود' USING ERRCODE = 'no_data_found';
    END IF;

    IF NOT public.exam_available_for_grade(p_exam_id, (SELECT grade FROM public.profiles WHERE id = v_uid)) THEN
        RAISE EXCEPTION 'الامتحان غير متاح لصفك الدراسي' USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Session is optional: online submissions carry one (speed bonus from the
    -- server clock); offline-synced submissions pass NULL (no speed bonus).
    v_total_seconds := COALESCE(v_exam.duration_minutes, 30) * 60;
    IF p_session_id IS NOT NULL THEN
        SELECT * INTO v_session
        FROM public.exam_sessions
        WHERE id = p_session_id AND user_id = v_uid AND exam_id = p_exam_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'جلسة غير صالحة' USING ERRCODE = 'check_violation';
        END IF;
        v_remaining := GREATEST(0, v_total_seconds - EXTRACT(EPOCH FROM (NOW() - v_session.started_at)));
    ELSE
        v_remaining := 0;
    END IF;

    -- Grade against protected answers (0-based question index -> option index)
    v_total := jsonb_array_length(v_exam.data->'q');
    FOR v_i IN 0 .. v_total - 1 LOOP
        v_correct_idx := (v_exam.answers->v_i::text)::int;
        v_selected := p_answers->>v_i::text;
        IF v_selected IS NOT NULL AND v_selected <> '' THEN
            IF v_selected = ('o' || v_correct_idx) THEN
                v_correct := v_correct + 1;
            ELSIF v_i < 64 THEN
                v_wrong_mask := v_wrong_mask | (1::bigint << v_i);
            END IF;
        END IF;
    END LOOP;

    IF v_total > 0 THEN
        v_accuracy := (v_correct::double precision / v_total) * 100;
    END IF;
    IF v_accuracy >= 60 AND v_total_seconds > 0 THEN
        v_speed_bonus := (v_remaining / v_total_seconds) * 10;
    END IF;
    v_final := LEAST(100, GREATEST(0, v_accuracy + v_speed_bonus));
    v_points := v_correct;

    INSERT INTO public.exam_results (user_id, exam_id, subject, score, wrong_mask, points, status)
    VALUES (v_uid, p_exam_id, v_exam.subject_id, ROUND(v_final::numeric, 1), v_wrong_mask, v_points, 'completed')
    ON CONFLICT (user_id, exam_id) WHERE status = 'completed'
    DO UPDATE SET
        score = CASE
            WHEN public.exam_results.score < EXCLUDED.score THEN EXCLUDED.score
            ELSE public.exam_results.score
        END,
        points = CASE
            WHEN COALESCE(public.exam_results.points, 0) < EXCLUDED.points THEN EXCLUDED.points
            ELSE public.exam_results.points
        END,
        wrong_mask = CASE
            WHEN EXCLUDED.score > public.exam_results.score THEN EXCLUDED.wrong_mask
            ELSE public.exam_results.wrong_mask
        END;

    IF v_session.id IS NOT NULL THEN
        DELETE FROM public.exam_sessions WHERE id = v_session.id;
    END IF;

    v_result := jsonb_build_object(
        'exam_id', p_exam_id,
        'score', ROUND(v_final::numeric, 1),
        'correct_count', v_correct,
        'total_count', v_total,
        'wrong_mask', v_wrong_mask,
        'accuracy', ROUND(v_accuracy::numeric, 1),
        'speed_bonus', ROUND(v_speed_bonus::numeric, 2),
        'points', v_points,
        'status', 'completed'
    );
    RETURN v_result;
END;
$function$;

-- ---------- 4) get_exam_review: questions + answers, only after completion ----------
CREATE OR REPLACE FUNCTION public.get_exam_review(p_exam_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_completed boolean;
    v_exam public.exams%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.exam_results WHERE user_id = v_uid AND exam_id = p_exam_id AND status = 'completed'
        UNION ALL
        SELECT 1 FROM public.exam_results_archive WHERE user_id = v_uid AND exam_id = p_exam_id AND status = 'completed'
    ) INTO v_completed;

    IF NOT COALESCE(v_completed, false) THEN
        RAISE EXCEPTION 'أكمل الامتحان أولاً لمراجعته' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_exam FROM public.exams WHERE id = p_exam_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'الامتحان غير موجود' USING ERRCODE = 'no_data_found';
    END IF;

    RETURN jsonb_build_object('data', v_exam.data, 'answers', v_exam.answers);
END;
$function$;

-- ---------- 5) get_practice_exam: questions + answers for lecture quizzes ----------
CREATE OR REPLACE FUNCTION public.get_practice_exam(p_exam_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_exam public.exams%ROWTYPE;
    v_linked boolean;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Only exams linked as a lecture quiz can be read for practice.
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

    SELECT * INTO v_exam FROM public.exams WHERE id = p_exam_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'الامتحان غير موجود' USING ERRCODE = 'no_data_found';
    END IF;

    RETURN jsonb_build_object('data', v_exam.data, 'answers', v_exam.answers);
END;
$function$;

-- ---------- Grants ----------
GRANT EXECUTE ON FUNCTION public.start_exam(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_exam_answer(text, jsonb, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_exam_review(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_practice_exam(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.start_exam(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.submit_exam_answer(text, jsonb, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_exam_review(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_practice_exam(text) FROM anon;
