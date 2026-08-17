-- ============================================================
-- Gate admin read RPC.
-- gate_exams / gate_passcodes have no direct read policies, so the
-- dashboard admin UI reads the current gate config through this.
-- Adminish-only (is_adminish). Returns passcode info + attached
-- exam ids for a grade.
-- ============================================================

CREATE OR REPLACE FUNCTION public.gate_admin_status(p_grade integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_passcode public.gate_passcodes%ROWTYPE;
    v_has_passcode boolean;
    v_ids text[];
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF NOT public.is_adminish() THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_passcode FROM public.gate_passcodes WHERE grade = p_grade;
    v_has_passcode := FOUND;

    SELECT ARRAY_AGG(exam_id ORDER BY created_at, exam_id) INTO v_ids
    FROM public.gate_exams WHERE grade = p_grade;

    RETURN jsonb_build_object(
        'grade', p_grade,
        'has_passcode', v_has_passcode,
        'updated_at', CASE WHEN v_has_passcode THEN v_passcode.updated_at ELSE NULL END,
        'expires_at', CASE WHEN v_has_passcode THEN v_passcode.expires_at ELSE NULL END,
        'exam_ids', COALESCE(v_ids, ARRAY[]::text[])
    );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.gate_admin_status(integer) FROM anon;
