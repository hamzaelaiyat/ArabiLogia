-- ============================================================
-- Gate feature: fix pgcrypto schema reference (gen_salt, crypt
-- live in the `extensions` schema, not `public`).
-- ============================================================

CREATE OR REPLACE FUNCTION public.gate_unlock(p_grade integer, p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
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
    v_ok := (v_row.code_hash = extensions.crypt(p_code, v_row.code_hash));
    IF NOT v_ok THEN
        RAISE EXCEPTION 'كلمة المرور غير صحيحة' USING ERRCODE = 'check_violation';
    END IF;
    INSERT INTO public.gate_unlocks (user_id, grade, passcode_updated_at)
    VALUES (v_uid, p_grade, v_row.updated_at)
    ON CONFLICT (user_id, grade) DO UPDATE
        SET passcode_updated_at = EXCLUDED.passcode_updated_at,
            unlocked_at = NOW();
    RETURN jsonb_build_object('grade', p_grade, 'unlocked_at', NOW(), 'expires_at', v_row.expires_at);
END;
$function$;

CREATE OR REPLACE FUNCTION public.gate_set_passcode(
    p_grade integer,
    p_code text,
    p_expires_at timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
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
    v_hash := extensions.crypt(p_code, extensions.gen_salt('bf'));
    INSERT INTO public.gate_passcodes (grade, code_hash, updated_at, expires_at, created_by)
    VALUES (p_grade, v_hash, NOW(), p_expires_at, v_uid)
    ON CONFLICT (grade) DO UPDATE SET
        code_hash = EXCLUDED.code_hash,
        updated_at = NOW(),
        expires_at = EXCLUDED.expires_at,
        created_by = EXCLUDED.created_by;
    DELETE FROM public.gate_unlocks WHERE grade = p_grade;
    RETURN jsonb_build_object('grade', p_grade, 'updated_at', NOW(), 'expires_at', p_expires_at);
END;
$function$;
