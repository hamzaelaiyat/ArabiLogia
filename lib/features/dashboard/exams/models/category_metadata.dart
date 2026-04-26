import 'package:flutter/material.dart';

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

  static const List<CategoryMetadata> categories = [
    CategoryMetadata(
      id: 'nahw',
      name: 'النحو',
      icon: Icons.architecture,
      color: Color(0xFFE53935),
    ),
    CategoryMetadata(
      id: 'balagha',
      name: 'البلاغة',
      icon: Icons.format_paint,
      color: Color(0xFF3F51B5),
    ),
    CategoryMetadata(
      id: 'nusus',
      name: 'النصوص',
      icon: Icons.library_books,
      color: Color(0xFF009688),
    ),
    CategoryMetadata(
      id: 'qiraa',
      name: 'القراءة',
      icon: Icons.menu_book,
      color: Color(0xFFFB8C00),
    ),
    CategoryMetadata(
      id: 'qissa',
      name: 'القصة',
      icon: Icons.auto_stories,
      color: Color(0xFF795548),
    ),
    CategoryMetadata(
      id: 'adab',
      name: 'الأدب',
      icon: Icons.history_edu,
      color: Color(0xFFFFB300),
    ),
    CategoryMetadata(
      id: 'shamil',
      name: 'شامل',
      icon: Icons.all_inclusive,
      color: Color(0xFF607D8B),
    ),
    CategoryMetadata(
      id: 'nisf_shamil',
      name: 'نصف شامل',
      icon: Icons.pie_chart,
      color: Color(0xFF03A9F4),
    ),
  ];

  static CategoryMetadata? getByName(String name) {
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  static CategoryMetadata? getById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
