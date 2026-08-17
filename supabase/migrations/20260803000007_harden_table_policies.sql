-- ============================================================
-- Gate + Security hardening — Part 2: Table policies
-- ------------------------------------------------------------
-- Closes holes #2 (grades/categories USING true ALL),
-- #3 (admin123@me.com email policy), #5 (exam_results insert + read),
-- #6 (profiles_all_read).
-- Leaderboard + profile sheet keep working: they use the RPCs.
-- ============================================================

-- ---------- grades: only staff can write ----------
DROP POLICY IF EXISTS "Admin full access grades" ON public.grades;
CREATE POLICY "Admin full access grades" ON public.grades
    FOR ALL TO authenticated
    USING (public.is_adminish())
    WITH CHECK (public.is_adminish());

-- ---------- categories: only staff can write ----------
DROP POLICY IF EXISTS "Admin full access categories" ON public.categories;
CREATE POLICY "Admin full access categories" ON public.categories
    FOR ALL TO authenticated
    USING (public.is_adminish())
    WITH CHECK (public.is_adminish());

-- ---------- exams: only staff can write ----------
DROP POLICY IF EXISTS "Teachers can manage exams" ON public.exams;
DROP POLICY IF EXISTS "Allow admins to manage exams" ON public.exams;
CREATE POLICY "Staff can manage exams" ON public.exams
    FOR ALL TO authenticated
    USING (public.is_adminish())
    WITH CHECK (public.is_adminish());

-- ---------- lectures: add dev to the manage policy ----------
DROP POLICY IF EXISTS "Teachers manage lectures" ON public.lectures;
CREATE POLICY "Staff manage lectures" ON public.lectures
    FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = ANY (ARRAY['teacher', 'admin', 'dev'])
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = ANY (ARRAY['teacher', 'admin', 'dev'])
    ));

-- ---------- exam_results: RPC-only writes ----------
DROP POLICY IF EXISTS "Users can insert own scores" ON public.exam_results;
DROP POLICY IF EXISTS "Users can insert own exam results" ON public.exam_results;
DROP POLICY IF EXISTS "Users can insert own results" ON public.exam_results;
DROP POLICY IF EXISTS "Users can insert their own results" ON public.exam_results;

DROP POLICY IF EXISTS "Users can read exam results" ON public.exam_results;
DROP POLICY IF EXISTS "Teachers can read all scores" ON public.exam_results;
DROP POLICY IF EXISTS "Teachers can view all exam results" ON public.exam_results;
DROP POLICY IF EXISTS "Teachers can view all results" ON public.exam_results;

DROP POLICY IF EXISTS "Users can view own exam results" ON public.exam_results;
DROP POLICY IF EXISTS "Users can view own results" ON public.exam_results;
DROP POLICY IF EXISTS "Users can view their own results" ON public.exam_results;

CREATE POLICY "Users can view own exam results" ON public.exam_results
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Staff can view all exam results" ON public.exam_results
    FOR SELECT TO authenticated
    USING (public.is_adminish());

-- No INSERT/UPDATE/DELETE policies on exam_results:
-- only SECURITY DEFINER RPCs can write.

-- ---------- exam_results_archive: staff read incl. dev ----------
DROP POLICY IF EXISTS "Teachers can view all archived results" ON public.exam_results_archive;
DROP POLICY IF EXISTS "Admins can view all archived results" ON public.exam_results_archive;
CREATE POLICY "Staff can view all archived results" ON public.exam_results_archive
    FOR SELECT TO public
    USING (public.is_adminish());

-- ---------- profiles: no more blanket read ----------
DROP POLICY IF EXISTS "profiles_all_read" ON public.profiles;
DROP POLICY IF EXISTS "Teachers can view profiles" ON public.profiles;
CREATE POLICY "Staff can view profiles" ON public.profiles
    FOR SELECT TO authenticated
    USING (public.is_adminish());

-- Self read / self update policies stay (role + moderation columns are
-- already protected by the trigger from M6).

-- ---------- points_adjustments: staff roles incl. dev ----------
DROP POLICY IF EXISTS "Teachers view all adjustments" ON public.points_adjustments;
CREATE POLICY "Staff view all adjustments" ON public.points_adjustments
    FOR SELECT TO authenticated
    USING (public.is_adminish());

DROP POLICY IF EXISTS "Teachers insert adjustments" ON public.points_adjustments;
CREATE POLICY "Staff insert adjustments" ON public.points_adjustments
    FOR INSERT TO authenticated
    WITH CHECK (public.is_adminish());

-- ---------- Public profile view (safe columns only) ----------
CREATE OR REPLACE VIEW public.profiles_public AS
SELECT id, full_name, username, grade, avatar_url, is_public, hide_avatar,
       hide_name, random_name, description, created_at
FROM public.profiles;

-- ---------- RPC guards: dev is a staff role ----------
CREATE OR REPLACE FUNCTION public.adjust_student_points(p_user_id uuid, p_amount integer, p_action text)
 RETURNS TABLE(new_balance bigint, change_amount integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_current_balance BIGINT;
    v_change INTEGER;
    v_actor UUID;
    v_target_exists BOOLEAN;
BEGIN
    IF NOT public.is_adminish() THEN
        RAISE EXCEPTION 'غير مصرح لك بتعديل النقاط'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT EXISTS(
        SELECT 1 FROM public.profiles
        WHERE id = p_user_id AND role = 'student'
    ) INTO v_target_exists;

    IF NOT v_target_exists THEN
        RAISE EXCEPTION 'الطالب غير موجود'
            USING ERRCODE = 'raise_exception';
    END IF;

    IF p_action NOT IN ('increment', 'decrement', 'reset') THEN
        RAISE EXCEPTION 'إجراء غير صالح'
            USING ERRCODE = 'raise_exception';
    END IF;

    v_actor := auth.uid();

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
$function$;

CREATE OR REPLACE FUNCTION public.get_students_with_balances(p_grade integer DEFAULT NULL::integer)
 RETURNS TABLE(user_id uuid, full_name text, username text, avatar_url text, grade integer, exam_points bigint, manual_adjustments bigint, total_balance bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
#variable_conflict use_column
BEGIN
    IF NOT public.is_adminish() THEN
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
$function$;
