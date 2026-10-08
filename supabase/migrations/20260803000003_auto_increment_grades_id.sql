-- Make grades.id auto-generated so new grades can be added without an id.
CREATE SEQUENCE IF NOT EXISTS grades_id_seq START WITH 4;
ALTER TABLE public.grades ALTER COLUMN id SET DEFAULT nextval('grades_id_seq');
SELECT setval('grades_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.grades));
