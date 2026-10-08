-- ============================================================
-- Gate + grading integration smoke test (manual).
--
-- Run as the postgres role (Supabase MCP execute_sql). It
-- temporarily inserts a test exam + passcode as a dev user
-- (spiecy / safwatkamel6000@gmail.com), then exercises the
-- gate + grading RPCs end-to-end. Cleans up after itself.
--
-- Use the project_id from the active branch.
-- ============================================================

BEGIN;

-- ---- Test fixtures ----
DELETE FROM public.exam_sessions WHERE user_id = '5286dc12-aa0f-4093-89b4-27b9ee5093a2';
DELETE FROM public.exam_results WHERE user_id = '5286dc12-aa0f-4093-89b4-27b9ee5093a2';
DELETE FROM public.exam_answers WHERE exam_id = 'gate-integ-test';
DELETE FROM public.gate_unlocks WHERE user_id = '5286dc12-aa0f-4093-89b4-27b9ee5093a2';
DELETE FROM public.gate_attempts WHERE user_id = '5286dc12-aa0f-4093-89b4-27b9ee5093a2';
DELETE FROM public.gate_passcodes WHERE grade = 2;
DELETE FROM public.gate_exams WHERE exam_id = 'gate-integ-test';
DELETE FROM public.exams WHERE id = 'gate-integ-test';

INSERT INTO public.exams (id, title, subject_id, duration_minutes, grade, grade_ids, data)
VALUES ('gate-integ-test', 'Integration', 'nahw', 10, 2, ARRAY[0,2],
        '{"p":1,"q":[{"t":"Q1","o":["A","B"]},{"t":"Q2","o":["A","B","C"]}]}'::jsonb);
INSERT INTO public.exam_answers (exam_id, answers) VALUES ('gate-integ-test','{"0":1,"1":0}');

-- 1. Staff (dev) sets a passcode for grade 2.
SELECT set_config('request.jwt.claims',
  '{"sub":"5286dc12-aa0f-4093-89b4-27b9ee5093a2","role":"authenticated"}', true);
SELECT public.gate_set_passcode(2, 'integ-pw', NULL) AS set_passcode;

-- 2. Attach the exam to the gate catalog.
SELECT public.gate_set_exams(2, ARRAY['gate-integ-test']) AS set_exams;

-- 3. Before unlock: list should be empty.
SELECT public.gate_list_exams() AS list_locked;

-- 4. Wrong passcode rejected.
DO $$ BEGIN
  PERFORM public.gate_unlock(2, 'wrong');
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'wrong_rejected: %', SQLERRM;
END $$;

-- 5. Correct passcode unlocks.
SELECT public.gate_unlock(2, 'integ-pw') AS unlocked;

-- 6. Status now reflects unlocked.
SELECT public.gate_status(2) AS status_unlocked;

-- 7. List returns the gated exam.
SELECT public.gate_list_exams() AS list_unlocked;

-- 8. Start a grading session and submit answers (Q1 wrong, Q2 correct).
SELECT public.start_exam('gate-integ-test') AS started;

DO $$
DECLARE s jsonb; r jsonb;
BEGIN
  s := public.start_exam('gate-integ-test');
  r := public.submit_exam_answer(
    'gate-integ-test',
    '{"0":"o0","1":"o0"}'::jsonb,
    (s->>'session_id')::uuid
  );
  RAISE NOTICE 'graded: %', r;
END $$;

-- 9. Review should return the question data + answer key.
SELECT public.get_exam_review('gate-integ-test') AS review;

-- 10. Wrong-grade exam rejected (grade_ids = ARRAY[3] only).
INSERT INTO public.exams (id, title, subject_id, duration_minutes, grade, grade_ids, data)
VALUES ('gate-integ-wrong', 'Wrong', 'nahw', 10, 3, ARRAY[3],
        '{"p":1,"q":[{"t":"Q","o":["A","B"]}]}'::jsonb);
INSERT INTO public.exam_answers (exam_id, answers) VALUES ('gate-integ-wrong','{"0":0}');

DO $$ BEGIN
  PERFORM public.start_exam('gate-integ-wrong');
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'wrong_grade_rejected: %', SQLERRM;
END $$;

-- 11. Rotation invalidates the unlock.
SELECT public.gate_set_passcode(2, 'rotated', NULL) AS rotated;
SELECT public.gate_status(2) AS status_after_rotation;

-- ---- Cleanup ----
DELETE FROM public.gate_unlocks WHERE user_id = '5286dc12-aa0f-4093-89b4-27b9ee5093a2';
DELETE FROM public.gate_attempts WHERE user_id = '5286dc12-aa0f-4093-89b4-27b9ee5093a2';
DELETE FROM public.gate_passcodes WHERE grade = 2;
DELETE FROM public.gate_exams WHERE exam_id = 'gate-integ-test';
DELETE FROM public.exam_answers WHERE exam_id IN ('gate-integ-test','gate-integ-wrong');
DELETE FROM public.exams WHERE id IN ('gate-integ-test','gate-integ-wrong');

ROLLBACK;
