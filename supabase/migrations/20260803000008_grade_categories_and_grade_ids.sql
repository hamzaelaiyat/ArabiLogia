-- ============================================================
-- Gate + Security hardening — Part 3: Per-grade categories,
-- shared-content grade_ids, and protected exam answers
-- ============================================================

-- ---------- 1) grade_categories: which categories a grade sees ----------
CREATE TABLE IF NOT EXISTS public.grade_categories (
    grade_id INT NOT NULL REFERENCES public.grades(id) ON DELETE CASCADE,
    category_id TEXT NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (grade_id, category_id)
);

ALTER TABLE public.grade_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read grade_categories" ON public.grade_categories
    FOR SELECT USING (true);

CREATE POLICY "Staff manage grade_categories" ON public.grade_categories
    FOR ALL TO authenticated
    USING (public.is_adminish())
    WITH CHECK (public.is_adminish());

CREATE INDEX IF NOT EXISTS idx_grade_categories_grade ON public.grade_categories(grade_id);

-- ---------- 2) grade_ids on exams + lectures ----------
-- 0 inside = shared to all grades; empty {} = fall back to legacy `grade`.
ALTER TABLE public.exams ADD COLUMN IF NOT EXISTS grade_ids INT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.lectures ADD COLUMN IF NOT EXISTS grade_ids INT[] NOT NULL DEFAULT '{}';

-- Backfill from legacy grade column (empty content tables right now).
UPDATE public.exams
SET grade_ids = CASE
    WHEN grade = 0 OR grade IS NULL THEN ARRAY[0]
    ELSE ARRAY[grade]
END
WHERE grade_ids = '{}';

UPDATE public.lectures
SET grade_ids = CASE
    WHEN grade = 0 OR grade IS NULL THEN ARRAY[0]
    ELSE ARRAY[grade]
END
WHERE grade_ids = '{}';

-- ---------- 3) Protected correct-answer store ----------
ALTER TABLE public.exams ADD COLUMN IF NOT EXISTS answers JSONB NOT NULL DEFAULT '{}';

-- Move correct indexes (q[i].a) out of data into answers, keyed by 0-based
-- question index to match the client's wrong_mask bit positions.
WITH extracted AS (
    SELECT e.id,
           jsonb_object_agg((q.ord - 1)::text, q.value->'a') AS answers,
           jsonb_agg(q.value - 'a' ORDER BY q.ord) AS stripped_q
    FROM public.exams e
    CROSS JOIN LATERAL jsonb_array_elements(e.data->'q') WITH ORDINALITY AS q(value, ord)
    WHERE e.data ? 'q' AND jsonb_typeof(e.data->'q') = 'array'
    GROUP BY e.id
)
UPDATE public.exams e
SET answers = x.answers,
    data = jsonb_set(e.data, '{q}', x.stripped_q)
FROM extracted x
WHERE e.id = x.id;

-- Column-level protection: authenticated/anon can never select answers.
-- SECURITY DEFINER RPCs (owner = postgres) still access it freely.
REVOKE SELECT (answers) ON public.exams FROM anon, authenticated;

-- ---------- 4) Grade availability helper ----------
CREATE OR REPLACE FUNCTION public.exam_available_for_grade(p_exam_id text, p_grade int)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE
    WHEN array_length(e.grade_ids, 1) IS NULL THEN
      (e.grade IS NULL OR e.grade = 0 OR e.grade = p_grade)
    ELSE
      (e.grade_ids @> ARRAY[0] OR e.grade_ids @> ARRAY[p_grade])
  END
  FROM public.exams e
  WHERE e.id = p_exam_id;
$$;

GRANT EXECUTE ON FUNCTION public.exam_available_for_grade(text, int) TO authenticated, service_role;
