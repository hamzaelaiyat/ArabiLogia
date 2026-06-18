import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';

class ScoreResult {
  final int correctCount;
  final List<String> wrongAnswers;
  final double accuracy;
  final double speedBonus;
  final double finalScore;

  const ScoreResult({
    required this.correctCount,
    required this.wrongAnswers,
    required this.accuracy,
    this.speedBonus = 0,
    required this.finalScore,
  });
}

ScoreResult calculateScore({
  required List<Question> questions,
  required Map<int, String?> selectedAnswers,
  int? remainingSeconds,
  int? totalDurationSeconds,
}) {
  int correctCount = 0;
  final List<String> wrongAnswers = [];

  for (int i = 0; i < questions.length; i++) {
    final question = questions[i];
    final selectedId = selectedAnswers[i];
    if (selectedId == null) continue;

    final correctOption = question.options.firstWhere((o) => o.isCorrect);
    if (selectedId == correctOption.id) {
      correctCount++;
    } else {
      wrongAnswers.add(question.id);
    }
  }

  final totalCount = questions.length;
  final accuracy = totalCount > 0 ? (correctCount / totalCount) * 100 : 0.0;

  double speedBonus = 0;
  if (remainingSeconds != null &&
      totalDurationSeconds != null &&
      accuracy >= 60) {
    speedBonus = (remainingSeconds / totalDurationSeconds) * 10;
  }

  final finalScore = (accuracy + speedBonus).clamp(0.0, 100.0);

  return ScoreResult(
    correctCount: correctCount,
    wrongAnswers: wrongAnswers,
    accuracy: accuracy,
    speedBonus: speedBonus,
    finalScore: finalScore,
  );
}
