class GateStatus {
  final int grade;
  final bool needsUnlock;
  final bool unlocked;
  final bool rotated;
  final bool hasPasscode;
  final DateTime? expiresAt;

  const GateStatus({
    required this.grade,
    required this.needsUnlock,
    required this.unlocked,
    required this.rotated,
    required this.hasPasscode,
    this.expiresAt,
  });

  factory GateStatus.fromJson(Map<String, dynamic> json) {
    return GateStatus(
      grade: json['grade'] as int,
      needsUnlock: json['needs_unlock'] as bool? ?? true,
      unlocked: json['unlocked'] as bool? ?? false,
      rotated: json['rotated'] as bool? ?? false,
      hasPasscode: json['has_passcode'] as bool? ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
}

class GateAdminStatus {
  final int grade;
  final bool hasPasscode;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final List<String> examIds;

  const GateAdminStatus({
    required this.grade,
    required this.hasPasscode,
    required this.updatedAt,
    required this.expiresAt,
    required this.examIds,
  });

  factory GateAdminStatus.fromJson(Map<String, dynamic> json) {
    final rawIds = json['exam_ids'] as List<dynamic>? ?? const [];
    return GateAdminStatus(
      grade: json['grade'] as int,
      hasPasscode: json['has_passcode'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      examIds: rawIds.cast<String>(),
    );
  }
}

class GateExamItem {
  final String id;
  final String title;
  final String subjectId;
  final int? durationMinutes;
  final int sortOrder;

  const GateExamItem({
    required this.id,
    required this.title,
    required this.subjectId,
    this.durationMinutes,
    required this.sortOrder,
  });

  factory GateExamItem.fromJson(Map<String, dynamic> json) {
    return GateExamItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class GateExamList {
  final bool unlocked;
  final int grade;
  final List<GateExamItem> items;

  const GateExamList({
    required this.unlocked,
    required this.grade,
    required this.items,
  });

  factory GateExamList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return GateExamList(
      unlocked: json['unlocked'] as bool? ?? false,
      grade: json['grade'] as int? ?? 0,
      items: raw
          .map((e) => GateExamItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
