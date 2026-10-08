-- ============================================================
-- Gate: simple per-(user,grade) rate limit on gate_unlock.
-- 5 wrong attempts within 10 minutes -> 10 minute lockout.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.gate_attempts (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    grade INTEGER NOT NULL CHECK (grade >= 0 AND grade <= 3),
    wrong_count INTEGER NOT NULL DEFAULT 0,
    last_wrong_at TIMESTAMPTZ,
    locked_until TIMESTAMPTZ,
    PRIMARY KEY (user_id, grade)
);

ALTER TABLE public.gate_attempts ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.gate_unlock(p_grade integer, p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_row public.gate_passcodes%ROWTYPE;
    v_att public.gate_attempts%ROWTYPE;
    v_ok boolean;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_att FROM public.gate_attempts WHERE user_id = v_uid AND grade = p_grade;
    IF v_att.locked_until IS NOT NULL AND v_att.locked_until > NOW() THEN
        RAISE EXCEPTION 'تم تعليق المحاولات، حاول لاحقاً' USING ERRCODE = 'check_violation';
    END IF;

    SELECT * INTO v_row FROM public.gate_passcodes WHERE grade = p_grade;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'لم يتم تعيين كلمة مرور لهذا الصف' USING ERRCODE = 'no_data_found';
    END IF;
    IF v_row.expires_at IS NOT NULL AND v_row.expires_at <= NOW() THEN
        RAISE EXCEPTION 'انتهت صلاحية كلمة المرور' USING ERRCODE = 'check_violation';
    END IF;

    v_ok := (v_row.code_hash = extensions.crypt(p_code, v_row.code_hash));
    IF NOT v_ok THEN
        INSERT INTO public.gate_attempts (user_id, grade, wrong_count, last_wrong_at, locked_until)
        VALUES (v_uid, p_grade, 1, NOW(),
                CASE WHEN COALESCE(v_att.wrong_count, 0) + 1 >= 5
                     THEN NOW() + INTERVAL '10 minutes' ELSE NULL END)
        ON CONFLICT (user_id, grade) DO UPDATE SET
            wrong_count = public.gate_attempts.wrong_count + 1,
            last_wrong_at = NOW(),
            locked_until = CASE WHEN public.gate_attempts.wrong_count + 1 >= 5
                                THEN NOW() + INTERVAL '10 minutes'
                                ELSE public.gate_attempts.locked_until END;
        RAISE EXCEPTION 'كلمة المرور غير صحيحة' USING ERRCODE = 'check_violation';
    END IF;

    -- Success: clear attempts.
    DELETE FROM public.gate_attempts WHERE user_id = v_uid AND grade = p_grade;
    INSERT INTO public.gate_unlocks (user_id, grade, passcode_updated_at)
    VALUES (v_uid, p_grade, v_row.updated_at)
    ON CONFLICT (user_id, grade) DO UPDATE
        SET passcode_updated_at = EXCLUDED.passcode_updated_at,
            unlocked_at = NOW();
    RETURN jsonb_build_object('grade', p_grade, 'unlocked_at', NOW(), 'expires_at', v_row.expires_at);
END;
$function$;
