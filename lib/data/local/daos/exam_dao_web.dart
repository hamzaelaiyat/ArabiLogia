class WebCachedExam {
  final String id;
  final String title;
  final String subjectId;
  final int grade;
  final String data;
  final DateTime downloadedAt;

  WebCachedExam({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.grade,
    required this.data,
    required this.downloadedAt,
  });
}

class ExamDao {
  final _cache = <String, WebCachedExam>{};

  ExamDao([dynamic _]);

  Future<void> cacheExamFields({
    required String id,
    required String title,
    required String subjectId,
    required int grade,
    required String data,
  }) async {
    _cache[id] = WebCachedExam(
      id: id,
      title: title,
      subjectId: subjectId,
      grade: grade,
      data: data,
      downloadedAt: DateTime.now(),
    );
  }

  Future<WebCachedExam?> getCachedExam(String id) async {
    return _cache[id];
  }

  Future<List<WebCachedExam>> getCachedExamsBySubject(String subjectId, int grade) async {
    return _cache.values.where((e) => e.subjectId == subjectId && e.grade == grade).toList();
  }

  Future<void> removeCachedExam(String id) async {
    _cache.remove(id);
  }

  Future<void> clearExpiredCache(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    _cache.removeWhere((_, e) => e.downloadedAt.isBefore(cutoff));
  }
}
