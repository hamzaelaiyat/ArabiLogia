import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';

void main() {
  setUp(GradeMetadata.resetForTest);

  Lecture lectureWith(Map<String, dynamic> json) => Lecture.fromJson({
    'id': 'l1',
    'title': 'اسم الفاعل',
    'course_id': 'c1',
    'youtube_url': '',
    'description': '',
    ...json,
  });

  Exam examWith(Map<String, dynamic> json) => Exam.fromMinifiedJson({
    'id': 'e1',
    't': 'امتحان',
    's': 'النحو',
    'si': 'c1',
    'q': const [],
    'p': 1,
    ...json,
  });

  group('Lecture shared grades', () {
    test('reads grade_ids for a shared lecture', () {
      final lecture = lectureWith({
        'grade': 1,
        'grade_ids': [1, 10, 12],
      });

      expect(lecture.effectiveGradeIds, [1, 10, 12]);
      expect(lecture.grade, 1, reason: 'legacy column mirrors the first id');
      expect(lecture.isSharedAcrossGrades, isTrue);
      expect(lecture.isSharedWithAllGrades, isFalse);
    });

    test('falls back to the scalar grade before the backfill', () {
      final lecture = lectureWith({'grade': 3, 'grade_ids': <int>[]});

      expect(lecture.effectiveGradeIds, [3]);
      expect(lecture.isSharedAcrossGrades, isFalse);
    });

    test('treats the 0 sentinel as shared with every grade', () {
      final lecture = lectureWith({
        'grade': 0,
        'grade_ids': [0],
      });

      expect(lecture.isSharedWithAllGrades, isTrue);
      expect(lecture.isVisibleToGrade(12), isTrue);
      expect(lecture.isVisibleToGrade(1), isTrue);
    });

    test('isVisibleToGrade only matches the shared grades', () {
      final lecture = lectureWith({
        'grade': 1,
        'grade_ids': [1, 11],
      });

      expect(lecture.isVisibleToGrade(1), isTrue);
      expect(lecture.isVisibleToGrade(11), isTrue);
      expect(lecture.isVisibleToGrade(2), isFalse);
      expect(lecture.isVisibleToGrade(10), isFalse);
    });

    test('toJson persists grade_ids so the row stays shared', () {
      final json = lectureWith({
        'grade': 1,
        'grade_ids': [1, 12],
      }).toJson();

      expect(json['grade_ids'], [1, 12]);
      expect(json['grade'], 1);
    });

    test('copyWith replaces the whole selection', () {
      final lecture = lectureWith({
        'grade': 1,
        'grade_ids': [1, 2],
      });
      final shared = lecture.copyWith(gradeIds: const [10, 11]);

      expect(shared.effectiveGradeIds, [10, 11]);
      expect(lecture.effectiveGradeIds, [1, 2], reason: 'original is intact');
    });
  });

  group('Exam shared grades', () {
    test('reads grade_ids for a shared exam', () {
      final exam = examWith({
        'g': 1,
        'grade_ids': [1, 2, 3],
      });

      expect(exam.effectiveGradeIds, [1, 2, 3]);
      expect(exam.isSharedAcrossGrades, isTrue);
    });

    test('falls back to the scalar grade before the backfill', () {
      final exam = examWith({'g': 2, 'grade_ids': <int>[]});

      expect(exam.effectiveGradeIds, [2]);
      expect(exam.isSharedAcrossGrades, isFalse);
    });

    test('a single grade is not treated as shared', () {
      final exam = examWith({
        'g': 10,
        'grade_ids': [10],
      });

      expect(exam.effectiveGradeIds, [10]);
      expect(exam.isSharedAcrossGrades, isFalse);
      expect(exam.isVisibleToGrade(10), isTrue);
      expect(exam.isVisibleToGrade(11), isFalse);
    });

    test('toMinifiedJson round-trips the shared selection', () {
      final exam = examWith({
        'g': 1,
        'grade_ids': [1, 10],
      });
      final restored = Exam.fromMinifiedJson(exam.toMinifiedJson());

      expect(restored.effectiveGradeIds, [1, 10]);
    });
  });

  group('cross-track sharing', () {
    test('one lecture serves matching grades across both tracks', () {
      // The whole point: grade 1 and grade 10 share the same lesson row
      // instead of the teacher recreating it six times.
      final shared = [1, 2, 3, 10, 11, 12];
      final lecture = lectureWith({'grade': 1, 'grade_ids': shared});

      for (final grade in GradeMetadata.gradeIds) {
        expect(
          lecture.isVisibleToGrade(grade),
          isTrue,
          reason: 'grade $grade should see the shared lecture',
        );
      }
      expect(lecture.isSharedAcrossGrades, isTrue);
    });
  });
}
