int mapUiGradeToDbGrade(int uiGrade) {
  if (uiGrade == 0) return 0;
  return uiGrade + 9;
}

int mapDbGradeToUiGrade(int dbGrade) {
  return dbGrade > 9 ? dbGrade - 9 : dbGrade;
}
