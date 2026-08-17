-- ============================================================
-- Gate feature: per-grade passcode + gated exam catalog.
-- - gate_passcodes: one row per grade; bcrypt hash + rotation
--   timestamp. Rotating the passcode invalidates outstanding
--   unlocks automatically.
-- - gate_unlocks: tracks which user unlocked which grade and
--   the passcode.updated_at they unlocked against.
-- - gate_exams: which exam ids participate in the gate for
--   each grade.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.gate_passcodes (
    grade INTEGER PRIMARY KEY CHECK (grade >= 0 AND grade <= 3),
    code_hash TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id)
);

CREATE TABLE IF NOT EXISTS public.gate_unlocks (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    grade INTEGER NOT NULL CHECK (grade >= 0 AND grade <= 3),
    passcode_updated_at TIMESTAMPTZ NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, grade)
);

CREATE TABLE IF NOT EXISTS public.gate_exams (
    exam_id TEXT PRIMARY KEY REFERENCES public.exams(id) ON DELETE CASCADE,
    grade INTEGER NOT NULL CHECK (grade >= 0 AND grade <= 3),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS gate_exams_grade_idx ON public.gate_exams(grade);

ALTER TABLE public.gate_passcodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gate_unlocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gate_exams ENABLE ROW LEVEL SECURITY;

-- No direct read/write policies on any of the three tables; access
-- is via SECURITY DEFINER RPCs only.

-- ============================================================
-- RPCs
-- ============================================================

-- Student tries to unlock a grade with a passcode.
CREATE OR REPLACE FUNCTION public.gate_unlock(p_grade integer, p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_row public.gate_passcodes%ROWTYPE;
    v_ok boolean;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_row FROM public.gate_passcodes WHERE grade = p_grade;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'لم يتم تعيين كلمة مرور لهذا الصف' USING ERRCODE = 'no_data_found';
    END IF;

    IF v_row.expires_at IS NOT NULL AND v_row.expires_at <= NOW() THEN
        RAISE EXCEPTION 'انتهت صلاحية كلمة المرور' USING ERRCODE = 'check_violation';
    END IF;

    v_ok := (v_row.code_hash = crypt(p_code, v_row.code_hash));
    IF NOT v_ok THEN
        RAISE EXCEPTION 'كلمة المرور غير صحيحة' USING ERRCODE = 'check_violation';
    END IF;

    INSERT INTO public.gate_unlocks (user_id, grade, passcode_updated_at)
    VALUES (v_uid, p_grade, v_row.updated_at)
    ON CONFLICT (user_id, grade) DO UPDATE
        SET passcode_updated_at = EXCLUDED.passcode_updated_at,
            unlocked_at = NOW();

    RETURN jsonb_build_object(
        'grade', p_grade,
        'unlocked_at', NOW(),
        'expires_at', v_row.expires_at
    );
END;
$function$;

-- Returns the student's current gate status for their grade.
-- Result: { needs_unlock: bool, unlocked: bool, rotated: bool,
--           expires_at: timestamptz|null, grade: int }
CREATE OR REPLACE FUNCTION public.gate_status(p_grade integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_passcode public.gate_passcodes%ROWTYPE;
    v_unlock public.gate_unlocks%ROWTYPE;
    v_has_passcode boolean;
    v_unlocked boolean := false;
    v_rotated boolean := false;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_passcode FROM public.gate_passcodes WHERE grade = p_grade;
    v_has_passcode := FOUND;

    SELECT * INTO v_unlock
    FROM public.gate_unlocks
    WHERE user_id = v_uid AND grade = p_grade;

    IF v_unlock.passcode_updated_at IS NOT NULL THEN
        v_unlocked := true;
        IF v_has_passcode AND v_unlock.passcode_updated_at < v_passcode.updated_at THEN
            v_rotated := true;
            v_unlocked := false;
            DELETE FROM public.gate_unlocks WHERE user_id = v_uid AND grade = p_grade;
        END IF;
    END IF;

    IF v_has_passcode AND v_passcode.expires_at IS NOT NULL
       AND v_passcode.expires_at <= NOW() THEN
        DELETE FROM public.gate_unlocks WHERE user_id = v_uid AND grade = p_grade;
        v_unlocked := false;
    END IF;

    RETURN jsonb_build_object(
        'grade', p_grade,
        'needs_unlock', NOT v_unlocked,
        'unlocked', v_unlocked,
        'rotated', v_rotated,
        'has_passcode', v_has_passcode,
        'expires_at', CASE WHEN v_has_passcode THEN v_passcode.expires_at ELSE NULL END
    );
END;
$function$;

-- Lock the gate again for the current student/grade.
CREATE OR REPLACE FUNCTION public.gate_clear_unlock(p_grade integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;
    DELETE FROM public.gate_unlocks WHERE user_id = v_uid AND grade = p_grade;
END;
$function$;

-- Staff/dev sets (or rotates) the passcode for a grade.
-- Rotating bumps updated_at so existing unlocks become invalid.
CREATE OR REPLACE FUNCTION public.gate_set_passcode(
    p_grade integer,
    p_code text,
    p_expires_at timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_hash text;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF NOT public.is_adminish() THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF LENGTH(COALESCE(p_code, '')) < 4 THEN
        RAISE EXCEPTION 'كلمة المرور قصيرة جداً' USING ERRCODE = 'check_violation';
    END IF;

    v_hash := crypt(p_code, gen_salt('bf'));

    INSERT INTO public.gate_passcodes (grade, code_hash, updated_at, expires_at, created_by)
    VALUES (p_grade, v_hash, NOW(), p_expires_at, v_uid)
    ON CONFLICT (grade) DO UPDATE SET
        code_hash = EXCLUDED.code_hash,
        updated_at = NOW(),
        expires_at = EXCLUDED.expires_at,
        created_by = EXCLUDED.created_by;

    -- Rotation invalidates existing unlocks.
    DELETE FROM public.gate_unlocks WHERE grade = p_grade;

    RETURN jsonb_build_object(
        'grade', p_grade,
        'updated_at', NOW(),
        'expires_at', p_expires_at
    );
END;
$function$;

-- Staff/dev attaches/detaches exams to/from the gate catalog.
CREATE OR REPLACE FUNCTION public.gate_set_exams(p_grade integer, p_exam_ids text[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_exam_id text;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF NOT public.is_adminish() THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Remove exams in this grade that are no longer in the list.
    DELETE FROM public.gate_exams
    WHERE grade = p_grade
      AND exam_id <> ALL(COALESCE(p_exam_ids, ARRAY[]::text[]));

    -- Add the new ones.
    IF p_exam_ids IS NOT NULL THEN
        FOREACH v_exam_id IN ARRAY p_exam_ids LOOP
            INSERT INTO public.gate_exams (exam_id, grade)
            VALUES (v_exam_id, p_grade)
            ON CONFLICT (exam_id) DO UPDATE SET grade = EXCLUDED.grade;
        END LOOP;
    END IF;
END;
$function$;

-- Returns the gated exam catalog for the caller's grade.
-- Combines gate_exams with exam metadata (id/title/duration/grade_ids).
-- SECURITY DEFINER so it can join exams despite the RLS that
-- restricts direct exam reads to the student's grade; here we
-- explicitly scope by the caller's profile grade.
CREATE OR REPLACE FUNCTION public.gate_list_exams()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_grade integer;
    v_has_unlock boolean;
    v_passcode_updated_at timestamptz;
    v_items jsonb;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT grade INTO v_grade FROM public.profiles WHERE id = v_uid;
    IF v_grade IS NULL THEN
        RAISE EXCEPTION 'لم يتم العثور على صف للطالب' USING ERRCODE = 'no_data_found';
    END IF;

    SELECT passcode_updated_at INTO v_passcode_updated_at
    FROM public.gate_unlocks
    WHERE user_id = v_uid AND grade = v_grade;

    v_has_unlock := v_passcode_updated_at IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM public.gate_passcodes gp
            WHERE gp.grade = v_grade
              AND gp.updated_at = v_passcode_updated_at
              AND (gp.expires_at IS NULL OR gp.expires_at > NOW())
        );

    IF NOT v_has_unlock THEN
        RETURN jsonb_build_object('unlocked', false, 'grade', v_grade, 'items', '[]'::jsonb);
    END IF;

    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', ge.exam_id,
        'title', e.data->>'t',
        'duration_minutes', e.duration_minutes,
        'subject_id', e.subject_id,
        'grade_ids', to_jsonb(e.grade_ids),
        'sort_order', COALESCE((e.data->>'so')::int, 0)
    ) ORDER BY COALESCE((e.data->>'so')::int, 0), ge.created_at), '[]'::jsonb)
    INTO v_items
    FROM public.gate_exams ge
    JOIN public.exams e ON e.id = ge.exam_id
    WHERE ge.grade = v_grade;

    RETURN jsonb_build_object('unlocked', true, 'grade', v_grade, 'items', v_items);
END;
$function$;

-- Revoke EXECUTE on internal maintenance RPCs.
REVOKE EXECUTE ON FUNCTION public.gate_set_passcode(integer, text, timestamptz) FROM anon;
REVOKE EXECUTE ON FUNCTION public.gate_set_exams(integer, text[]) FROM anon;
