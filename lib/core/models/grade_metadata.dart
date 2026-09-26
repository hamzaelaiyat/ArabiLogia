import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads grade metadata (names, sort order) from the `grades` table so grade
/// labels can be edited in the database without shipping a new app version.
class GradeMetadata {
  final int id;
  final String name;
  final int sortOrder;

  const GradeMetadata({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  // Two tracks share one id space: 1-3 are secondary, 10-12 are baccalaureate.
  // These ids are the single source of truth; never inline them elsewhere.
  static const List<int> secondaryGradeIds = [1, 2, 3];
  static const List<int> baccalaureateGradeIds = [10, 11, 12];

  /// Sentinel meaning "every grade" in filters and "all grades" queries.
  static const int allGrades = 0;

  /// Applied when a record has no grade yet. Const so it can be used as a
  /// default parameter value; keep in sync with secondaryGradeIds.first.
  static const int defaultGradeId = 1;

  static List<int> get gradeIds => [
    ...secondaryGradeIds,
    ...baccalaureateGradeIds,
  ];

  static bool isKnownGradeId(int id) => gradeIds.contains(id);

  static const _defaultGrades = [
    GradeMetadata(id: 1, name: 'الصف الأول الثانوي', sortOrder: 1),
    GradeMetadata(id: 2, name: 'الصف الثاني الثانوي', sortOrder: 2),
    GradeMetadata(id: 3, name: 'الصف الثالث الثانوي', sortOrder: 3),
    GradeMetadata(id: 10, name: 'الصف الأول البكالوري', sortOrder: 4),
    GradeMetadata(id: 11, name: 'الصف الثاني البكالوري', sortOrder: 5),
    GradeMetadata(id: 12, name: 'الصف الثالث البكالوري', sortOrder: 6),
  ];

  static List<GradeMetadata> _grades = List.from(_defaultGrades);
  static bool _isLoaded = false;

  static List<GradeMetadata> get grades => _grades;

  static Future<void> loadGrades() async {
    if (_isLoaded) return;

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('grades')
          .select('*')
          .eq('is_active', true)
          .order('sort_order');

      _grades = (response as List)
          .map(
            (g) => GradeMetadata(
              id: g['id'] as int,
              name: g['name'] as String,
              sortOrder: g['sort_order'] as int? ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      _grades = _defaultGrades;
    } finally {
      _isLoaded = true;
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _grades = [];
    _isLoaded = false;
  }

  static GradeMetadata? getById(int id) {
    if (!_isLoaded) loadGrades();
    for (final g in _grades) {
      if (g.id == id) return g;
    }
    return null;
  }

  static String getGradeName(int id) {
    return getById(id)?.name ?? 'غير محدد';
  }

  static Future<void> addGrade({
    required int id,
    required String name,
    int sortOrder = 0,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.from('grades').insert({
      'id': id,
      'name': name,
      'sort_order': sortOrder,
    });
    await loadGrades();
  }

  static Future<void> updateGrade(
    int id, {
    String? name,
    int? sortOrder,
    bool? isActive,
  }) async {
    final supabase = Supabase.instance.client;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (sortOrder != null) updates['sort_order'] = sortOrder;
    if (isActive != null) updates['is_active'] = isActive;

    await supabase.from('grades').update(updates).eq('id', id);
    await loadGrades();
  }

  static Future<void> deleteGrade(int id, {bool softDelete = true}) async {
    final supabase = Supabase.instance.client;
    if (softDelete) {
      await supabase.from('grades').update({'is_active': false}).eq('id', id);
    } else {
      await supabase.from('grades').delete().eq('id', id);
    }
    await loadGrades();
  }
}
