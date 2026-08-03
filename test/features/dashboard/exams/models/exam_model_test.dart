import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';

import '../../../../helpers/test_helper.dart';

void main() {
  group('Exam.fromMinifiedJson', () {
    test('parses an exam payload that embeds the correct answer index', () {
      final json = {
        'id': 'e1',
        't': 'Midterm',
        's': 'النحو',
        'si': 'nahw',
        'g': 2,
        'so': 3,
        'lv': 2,
        'p': 1,
        'q': [
          {
            'id': 'q1',
            't': 'What is 1+1?',
            'o': ['1', '2', '3'],
            'a': 1,
          },
        ],
      };

      final exam = Exam.fromMinifiedJson(json);

      expect(exam.id, 'e1');
      expect(exam.title, 'Midterm');
      expect(exam.subject, 'النحو');
      expect(exam.subjectId, 'nahw');
      expect(exam.grade, 2);
      expect(exam.sortOrder, 3);
      expect(exam.level, 2);
      expect(exam.isPublished, isTrue);
      expect(exam.questions, hasLength(1));
      final q = exam.questions.single;
      expect(q.options, hasLength(3));
      expect(q.options[0].id, 'o0');
      expect(q.options[0].isCorrect, isFalse);
      expect(q.options[1].id, 'o1');
      expect(q.options[1].isCorrect, isTrue);
      expect(q.options[2].isCorrect, isFalse);
    });

    test('handles server payload without an answer key (questions-only)', () {
      final json = {
        'id': 'e2',
        't': 'Take-home',
        's': 'البلاغة',
        'si': 'balagha',
        'g': 0,
        'p': 1,
        'q': [
          {'id': 'q1', 't': 'Q?', 'o': ['A', 'B']},
          {'id': 'q2', 't': 'Q2', 'o': ['X', 'Y', 'Z']},
        ],
      };

      final exam = Exam.fromMinifiedJson(json);

      expect(exam.questions, hasLength(2));
      for (final q in exam.questions) {
        for (final o in q.options) {
          expect(o.isCorrect, isFalse, reason: 'no answer key means no correct');
        }
      }
    });
  });

  group('Exam.applyAnswers', () {
    final questionsOnly = Exam.fromMinifiedJson({
      'id': 'e3',
      't': 'Review',
      's': 'النصوص',
      'si': 'nusus',
      'g': 2,
      'p': 1,
      'q': [
        {'id': 'q1', 't': 'A?', 'o': ['a', 'b']},
        {'id': 'q2', 't': 'B?', 'o': ['x', 'y', 'z']},
        {'id': 'q3', 't': 'C?', 'o': ['1', '2']},
      ],
    });

    test('marks the correct option per question using server answers', () {
      final review = questionsOnly.applyAnswers({
        '0': 1,
        '1': 0,
        '2': 1,
      });

      expect(review.questions[0].options[0].isCorrect, isFalse);
      expect(review.questions[0].options[1].isCorrect, isTrue);
      expect(review.questions[1].options[0].isCorrect, isTrue);
      expect(review.questions[1].options[1].isCorrect, isFalse);
      expect(review.questions[1].options[2].isCorrect, isFalse);
      expect(review.questions[2].options[0].isCorrect, isFalse);
      expect(review.questions[2].options[1].isCorrect, isTrue);
    });

    test('returns the question unchanged when the answer key is missing', () {
      final review = questionsOnly.applyAnswers(const {});
      for (final q in review.questions) {
        for (final o in q.options) {
          expect(o.isCorrect, isFalse);
        }
      }
    });
  });
}
