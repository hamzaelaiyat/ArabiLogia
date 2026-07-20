class Paragraph {
  final String id;
  final String title;
  final String content;
  final String categoryId;
  final DateTime createdAt;

  Paragraph({
    required this.id,
    required this.title,
    required this.content,
    required this.categoryId,
    required this.createdAt,
  });

  Paragraph copyWith({
    String? id,
    String? title,
    String? content,
    String? categoryId,
    DateTime? createdAt,
  }) {
    return Paragraph(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Paragraph.fromJson(Map<String, dynamic> json) {
    return Paragraph(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      categoryId: json['categoryId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}