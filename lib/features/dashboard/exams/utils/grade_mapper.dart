/// Maps the student's grade from user metadata (10, 11, 12)
/// to the exam grade (1, 2, 3). Uses an explicit mapping table
/// instead of arithmetic so the relationship is self-documenting.
int mapStudentGradeToExamGrade(int studentGrade) {
  const mapping = <int, int>{
    10: 1,
    11: 2,
    12: 3,
  };
  return mapping[studentGrade] ?? 1;
}

int mapUiGradeToDbGrade(int uiGrade) {
  if (uiGrade == 0) return 0;
  return uiGrade + 9;
}

int mapDbGradeToUiGrade(int dbGrade) {
  return dbGrade > 9 ? dbGrade - 9 : dbGrade;
}
