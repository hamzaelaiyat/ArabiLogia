-- ============================================================
-- Gate + Security hardening — Part 5: Move answers to an
-- RPC-only table (column grants can't protect against the
-- table-level SELECT granted to anon/authenticated).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.exam_answers (
    exam_id TEXT PRIMARY KEY REFERENCES public.exams(id) ON DELETE CASCADE,
    answers JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS on with NO policies => zero direct access via PostgREST.
-- Only SECURITY DEFINER RPCs (owner = postgres) can read/write.
ALTER TABLE public.exam_answers ENABLE ROW LEVEL SECURITY;

-- Move any answers extracted by M8 into the protected table.
INSERT INTO public.exam_answers (exam_id, answers)
SELECT id, answers FROM public.exams
WHERE answers IS NOT NULL AND answers <> '{}'
ON CONFLICT (exam_id) DO UPDATE SET answers = EXCLUDED.answers, updated_at = NOW();

-- Drop the now-redundant column from exams (keeps table-level grants intact).
ALTER TABLE public.exams DROP COLUMN IF EXISTS answers;

-- ---------- Rewire grading/review RPCs to the protected table ----------
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
    v_answers jsonb;
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

    SELECT ea.answers INTO v_answers FROM public.exam_answers ea WHERE ea.exam_id = p_exam_id;
    IF v_answers IS NULL THEN
        v_answers := '{}'::jsonb;
    END IF;

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

    v_total := jsonb_array_length(v_exam.data->'q');
    FOR v_i IN 0 .. v_total - 1 LOOP
        v_correct_idx := (v_answers->v_i::text)::int;
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

CREATE OR REPLACE FUNCTION public.get_exam_review(p_exam_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_completed boolean;
    v_data jsonb;
    v_answers jsonb;
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

    SELECT e.data, COALESCE(ea.answers, '{}'::jsonb)
    INTO v_data, v_answers
    FROM public.exams e
    LEFT JOIN public.exam_answers ea ON ea.exam_id = e.id
    WHERE e.id = p_exam_id;

    IF v_data IS NULL THEN
        RAISE EXCEPTION 'الامتحان غير موجود' USING ERRCODE = 'no_data_found';
    END IF;

    RETURN jsonb_build_object('data', v_data, 'answers', v_answers);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_practice_exam(p_exam_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_linked boolean;
    v_data jsonb;
    v_answers jsonb;
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

    SELECT e.data, COALESCE(ea.answers, '{}'::jsonb)
    INTO v_data, v_answers
    FROM public.exams e
    LEFT JOIN public.exam_answers ea ON ea.exam_id = e.id
    WHERE e.id = p_exam_id;

    IF v_data IS NULL THEN
        RAISE EXCEPTION 'الامتحان غير موجود' USING ERRCODE = 'no_data_found';
    END IF;

    RETURN jsonb_build_object('data', v_data, 'answers', v_answers);
END;
$function$;
