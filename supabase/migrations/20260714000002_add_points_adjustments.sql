-- Points Adjustments Table (Instructor-managed points ledger)
CREATE TABLE IF NOT EXISTS public.points_adjustments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount INTEGER NOT NULL,
    performed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.points_adjustments ENABLE ROW LEVEL SECURITY;

-- Teachers/admins can view all adjustments
DROP POLICY IF EXISTS "Teachers view all adjustments" ON public.points_adjustments;
CREATE POLICY "Teachers view all adjustments"
    ON public.points_adjustments
    FOR SELECT TO authenticated
    USING (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

-- Students can view their own adjustments
DROP POLICY IF EXISTS "Students view own adjustments" ON public.points_adjustments;
CREATE POLICY "Students view own adjustments"
    ON public.points_adjustments
    FOR SELECT
    USING (auth.uid() = user_id);

-- Teachers/admins can insert adjustments
DROP POLICY IF EXISTS "Teachers insert adjustments" ON public.points_adjustments;
CREATE POLICY "Teachers insert adjustments"
    ON public.points_adjustments
    FOR INSERT TO authenticated
    WITH CHECK (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_points_adjustments_user_id
    ON public.points_adjustments(user_id);
CREATE INDEX IF NOT EXISTS idx_points_adjustments_created_at
    ON public.points_adjustments(created_at DESC);

-- ============================================
-- adjust_student_points RPC
-- Handles increment, decrement, and reset operations atomically
-- Returns: { new_balance, change }
-- ============================================
CREATE OR REPLACE FUNCTION public.adjust_student_points(
    p_user_id UUID,
    p_amount INTEGER,
    p_action TEXT
)
RETURNS TABLE(new_balance BIGINT, change_amount INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_balance BIGINT;
    v_change INTEGER;
    v_actor UUID;
    v_target_exists BOOLEAN;
BEGIN
    -- Authorization check: only teachers/admins
    IF public.auth_role() NOT IN ('teacher', 'admin') THEN
        RAISE EXCEPTION 'غير مصرح لك بتعديل النقاط'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Validate target student exists
    SELECT EXISTS(
        SELECT 1 FROM public.profiles
        WHERE id = p_user_id AND role = 'student'
    ) INTO v_target_exists;

    IF NOT v_target_exists THEN
        RAISE EXCEPTION 'الطالب غير موجود'
            USING ERRCODE = 'no_data_found';
    END IF;

    -- Validate action
    IF p_action NOT IN ('increment', 'decrement', 'reset') THEN
        RAISE EXCEPTION 'إجراء غير صالح'
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    v_actor := auth.uid();

    -- Compute current manual adjustments total
    SELECT COALESCE(SUM(amount), 0)
    INTO v_current_balance
    FROM public.points_adjustments
    WHERE user_id = p_user_id;

    IF p_action = 'increment' THEN
        v_change := ABS(p_amount);
        IF v_change <= 0 THEN
            RAISE EXCEPTION 'يجب أن تكون القيمة أكبر من صفر'
                USING ERRCODE = 'check_violation';
        END IF;
    ELSIF p_action = 'decrement' THEN
        v_change := -ABS(p_amount);
        IF ABS(p_amount) <= 0 THEN
            RAISE EXCEPTION 'يجب أن تكون القيمة أكبر من صفر'
                USING ERRCODE = 'check_violation';
        END IF;
        -- Prevent balance from going below zero
        IF v_current_balance + v_change < 0 THEN
            v_change := -v_current_balance;
        END IF;
    ELSIF p_action = 'reset' THEN
        v_change := -v_current_balance;
    END IF;

    INSERT INTO public.points_adjustments (user_id, amount, performed_by)
    VALUES (p_user_id, v_change, v_actor);

    new_balance := v_current_balance + v_change;
    change_amount := v_change;
    RETURN NEXT;
END;
$$;

-- ============================================
-- get_students_with_balances RPC
-- Returns all students with their computed point balance
-- (exam points from exam_results + manual adjustments)
-- ============================================
CREATE OR REPLACE FUNCTION public.get_students_with_balances(p_grade INT DEFAULT NULL)
RETURNS TABLE(
    user_id UUID,
    full_name TEXT,
    username TEXT,
    avatar_url TEXT,
    grade INT,
    exam_points BIGINT,
    manual_adjustments BIGINT,
    total_balance BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Authorization check
    IF public.auth_role() NOT IN ('teacher', 'admin') THEN
        RAISE EXCEPTION 'غير مصرح لك بالوصول'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    RETURN QUERY
    WITH exam_totals AS (
        SELECT er.user_id,
               COALESCE(SUM(best_points), 0)::BIGINT AS exam_pts
        FROM (
            SELECT user_id, exam_id,
                   MAX(COALESCE(points, score::integer)) AS best_points
            FROM public.exam_results
            WHERE status = 'completed'
            GROUP BY user_id, exam_id
        ) er
        GROUP BY er.user_id
    ),
    adj_totals AS (
        SELECT pa.user_id,
               COALESCE(SUM(pa.amount), 0)::BIGINT AS adj_pts
        FROM public.points_adjustments pa
        GROUP BY pa.user_id
    )
    SELECT
        p.id AS user_id,
        p.full_name,
        p.username,
        p.avatar_url,
        p.grade,
        COALESCE(et.exam_pts, 0) AS exam_points,
        COALESCE(at.adj_pts, 0) AS manual_adjustments,
        COALESCE(et.exam_pts, 0) + COALESCE(at.adj_pts, 0) AS total_balance
    FROM public.profiles p
    LEFT JOIN exam_totals et ON et.user_id = p.id
    LEFT JOIN adj_totals at ON at.user_id = p.id
    WHERE p.role = 'student'
      AND (p_grade IS NULL OR p_grade = 0 OR p.grade = p_grade)
    ORDER BY total_balance DESC, p.full_name ASC;
END;
$$;
