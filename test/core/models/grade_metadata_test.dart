import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';

void main() {
  setUp(() {
    // Fresh static state per test; no Supabase client initialized, so
    // loadGrades() falls back to the bundled defaults.
    GradeMetadata.resetForTest();
  });

  test('falls back to bundled defaults when the grades table is unavailable',
      () async {
    await GradeMetadata.loadGrades();

    final grades = GradeMetadata.grades;
    expect(grades, hasLength(3));
    expect(grades[0].id, 1);
    expect(grades[0].name, AppStrings.grade10);
    expect(grades[1].id, 2);
    expect(grades[1].name, AppStrings.grade11);
    expect(grades[2].id, 3);
    expect(grades[2].name, AppStrings.grade12);
  });

  test('getById resolves a grade from the loaded list', () async {
    await GradeMetadata.loadGrades();

    expect(GradeMetadata.getById(2)?.name, AppStrings.grade11);
    expect(GradeMetadata.getById(99), isNull);
  });

  test('getGradeName returns the name or a fallback', () async {
    await GradeMetadata.loadGrades();

    expect(GradeMetadata.getGradeName(1), AppStrings.grade10);
    expect(GradeMetadata.getGradeName(42), 'غير محدد');
  });
}
