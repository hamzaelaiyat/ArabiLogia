import 'package:supabase_flutter/supabase_flutter.dart';

class GradeMetadata {
  final int id;
  final String name;
  final int sortOrder;

  const GradeMetadata({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  static List<GradeMetadata> _grades = [];
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
      
      _grades = (response as List).map((g) => GradeMetadata(
        id: g['id'] as int,
        name: g['name'] as String,
        sortOrder: g['sort_order'] as int? ?? 0,
      )).toList();
      
      _isLoaded = true;
    } catch (e) {
      _grades = _defaultGrades;
      _isLoaded = true;
    }
  }

  static const _defaultGrades = [
    GradeMetadata(id: 1, name: 'الأول الثانوية', sortOrder: 1),
    GradeMetadata(id: 2, name: 'الثاني الثانوية', sortOrder: 2),
    GradeMetadata(id: 3, name: 'الثالث الثانوية', sortOrder: 3),
  ];

  static GradeMetadata? getById(int id) {
    if (!_isLoaded) loadGrades();
    try {
      return _grades.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
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

  static Future<void> updateGrade(int id, {
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