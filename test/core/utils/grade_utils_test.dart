import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';

void main() {
  setUp(() {
    GradeMetadata.resetForTest();
  });

  test('gradeLabel resolves known grade ids from metadata', () {
    expect(gradeLabel(1), AppStrings.grade1);
    expect(gradeLabel(2), AppStrings.grade2);
    expect(gradeLabel(3), AppStrings.grade3);
    expect(gradeLabel(10), AppStrings.grade10);
    expect(gradeLabel(11), AppStrings.grade11);
    expect(gradeLabel(12), AppStrings.grade12);
  });

  test('gradeLabel keeps the two tracks distinct', () {
    expect(gradeLabel(1), isNot(gradeLabel(10)));
    expect(gradeLabel(2), isNot(gradeLabel(11)));
    expect(gradeLabel(3), isNot(gradeLabel(12)));
  });

  test('gradeLabel falls back for unknown ids', () {
    expect(gradeLabel(99), 'صفك الدراسي');
  });

  test('getGradeText accepts int grades', () {
    expect(getGradeText(1), AppStrings.grade1);
    expect(getGradeText(3), AppStrings.grade3);
    expect(getGradeText(11), AppStrings.grade11);
  });

  test('getGradeText accepts numeric strings', () {
    expect(getGradeText('2'), AppStrings.grade2);
    expect(getGradeText('12'), AppStrings.grade12);
  });

  test('getGradeText returns fallback for null and unknown grades', () {
    expect(getGradeText(null), 'صفك الدراسي');
    expect(getGradeText(null, fallback: 'رحلتك الدراسية'), 'رحلتك الدراسية');
    expect(getGradeText(0), 'صفك الدراسي');
    expect(getGradeText('abc'), 'صفك الدراسي');
  });
}
