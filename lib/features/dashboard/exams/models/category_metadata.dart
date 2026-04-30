import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryMetadata {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryMetadata({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static List<CategoryMetadata> _categories = [];
  static bool _isLoaded = false;

  static IconData _iconFromString(String iconName) {
    const iconMap = {
      'architecture': Icons.architecture,
      'format_paint': Icons.format_paint,
      'library_books': Icons.library_books,
      'menu_book': Icons.menu_book,
      'auto_stories': Icons.auto_stories,
      'history_edu': Icons.history_edu,
      'all_inclusive': Icons.all_inclusive,
      'pie_chart': Icons.pie_chart,
      'quiz': Icons.quiz,
      'school': Icons.school,
    };
    return iconMap[iconName] ?? Icons.quiz;
  }

  static Color _colorFromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  static List<CategoryMetadata> get categories => _categories;

  static Future<void> loadCategories() async {
    if (_isLoaded) return;
    
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order');
      
      _categories = (response as List).map((c) => CategoryMetadata(
        id: c['id'] as String,
        name: c['name'] as String,
        icon: _iconFromString(c['icon'] as String? ?? 'quiz'),
        color: _colorFromHex(c['color'] as String? ?? '#607D8B'),
      )).toList();
      
      _isLoaded = true;
    } catch (e) {
      _categories = _defaultCategories;
      _isLoaded = true;
    }
  }

  static const _defaultCategories = [
    CategoryMetadata(id: 'nahw', name: 'النحو', icon: Icons.architecture, color: Color(0xFFE53935)),
    CategoryMetadata(id: 'balagha', name: 'البلاغة', icon: Icons.format_paint, color: Color(0xFF3F51B5)),
    CategoryMetadata(id: 'nusus', name: 'النصوص', icon: Icons.library_books, color: Color(0xFF009688)),
    CategoryMetadata(id: 'qiraa', name: 'القراءة', icon: Icons.menu_book, color: Color(0xFFFB8C00)),
    CategoryMetadata(id: 'qissa', name: 'القصة', icon: Icons.auto_stories, color: Color(0xFF795548)),
    CategoryMetadata(id: 'adab', name: 'الأدب', icon: Icons.history_edu, color: Color(0xFFFFB300)),
    CategoryMetadata(id: 'shamil', name: 'شامل', icon: Icons.all_inclusive, color: Color(0xFF607D8B)),
    CategoryMetadata(id: 'nisf_shamil', name: 'نصف شامل', icon: Icons.pie_chart, color: Color(0xFF03A9F4)),
  ];

  static CategoryMetadata? getByName(String name) {
    if (!_isLoaded) loadCategories();
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  static CategoryMetadata? getById(String id) {
    if (!_isLoaded) loadCategories();
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> addCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
    int sortOrder = 0,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.from('categories').insert({
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
    });
    await loadCategories();
  }

  static Future<void> updateCategory(String id, {
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    bool? isActive,
  }) async {
    final supabase = Supabase.instance.client;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (sortOrder != null) updates['sort_order'] = sortOrder;
    if (isActive != null) updates['is_active'] = isActive;
    
    await supabase.from('categories').update(updates).eq('id', id);
    await loadCategories();
  }

  static Future<void> deleteCategory(String id, {bool softDelete = true}) async {
    final supabase = Supabase.instance.client;
    if (softDelete) {
      await supabase.from('categories').update({'is_active': false}).eq('id', id);
    } else {
      await supabase.from('categories').delete().eq('id', id);
    }
    await loadCategories();
  }
}