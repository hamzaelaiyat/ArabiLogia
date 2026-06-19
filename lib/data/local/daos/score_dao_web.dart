class WebExamScore {
  final String examId;
  final double score;
  final int points;
  final bool synced;

  WebExamScore({
    required this.examId,
    required this.score,
    required this.points,
    required this.synced,
  });
}

class ScoreDao {
  final _scores = <String, WebExamScore>{};

  ScoreDao([dynamic _]);

  Future<void> upsertScore(String examId, double score, int points) async {
    _scores[examId] = WebExamScore(
      examId: examId,
      score: score,
      points: points,
      synced: false,
    );
  }

  Future<Map<String, Map<String, dynamic>>> getAllScores() async {
    return {
      for (final s in _scores.values)
        s.examId: {
          'score': s.score,
          'points': s.points,
          'synced': s.synced,
        },
    };
  }

  Future<void> markSynced(String examId) async {
    final existing = _scores[examId];
    if (existing != null) {
      _scores[examId] = WebExamScore(
        examId: existing.examId,
        score: existing.score,
        points: existing.points,
        synced: true,
      );
    }
  }

  Future<List<WebExamScore>> getUnsyncedScores() async {
    return _scores.values.where((s) => !s.synced).toList();
  }
}
