import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LectureActivityRepository {
  static const String _key = 'lecture_activity_history';
  static const int _maxEntries = 20;

  Future<void> recordActivity({
    required String lectureId,
    required String title,
    String? categoryId,
    String? categoryName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();

    entries.removeWhere((e) => e['id'] == lectureId);
    entries.insert(0, {
      'id': lectureId,
      'title': title,
      'category_id': categoryId ?? '',
      'category_name': categoryName ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }

    await prefs.setStringList(_key, entries.map((e) => jsonEncode(e)).toList());
  }

  Future<List<Map<String, dynamic>>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }

  static List<Map<String, dynamic>> merge(
    List<Map<String, dynamic>> lectures,
    List<Map<String, dynamic>> exams, {
    int? limit,
  }) {
    final items = <Map<String, dynamic>>[
      ...lectures.map((l) => {...l, 'type': 'lecture'}),
      ...exams.map((e) => {...e, 'type': 'exam'}),
    ];
    items.sort(
      (a, b) => (b['created_at']?.toString() ?? '').compareTo(
        a['created_at']?.toString() ?? '',
      ),
    );
    return limit != null ? items.take(limit).toList() : items;
  }
}
