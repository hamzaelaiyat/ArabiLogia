import 'dart:convert';

enum BlockType { text, youtube, exam, quiz }

class LectureContentBlock {
  final String id;
  final BlockType type;
  final String content;
  final Map<String, dynamic>? metadata;

  const LectureContentBlock({
    required this.id,
    required this.type,
    required this.content,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'metadata': metadata,
      };

  factory LectureContentBlock.fromJson(Map<String, dynamic> json) {
    return LectureContentBlock(
      id: json['id'] as String? ?? '',
      type: BlockType.values.firstWhere(
        (e) => e.name == (json['type'] as String?),
        orElse: () => BlockType.text,
      ),
      content: json['content'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  LectureContentBlock copyWith({
    String? id,
    BlockType? type,
    String? content,
    Map<String, dynamic>? metadata,
  }) {
    return LectureContentBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Lecture {
  final String id;
  final String title;
  final String courseId;
  final String youtubeUrl;
  final String description;
  final String? quizId;
  final int sortOrder;
  final int grade;
  final bool isPublished;
  final List<LectureContentBlock> contentBlocks;
  final List<String> examIds;

  const Lecture({
    required this.id,
    required this.title,
    required this.courseId,
    required this.youtubeUrl,
    required this.description,
    this.quizId,
    this.sortOrder = 0,
    this.grade = 1,
    this.isPublished = false,
    this.contentBlocks = const [],
    this.examIds = const [],
  });

  /// Extract YouTube video ID from various URL formats
  String? get videoId {
    final uri = Uri.tryParse(youtubeUrl);
    if (uri == null) return null;

    // youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }

    // youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    // youtube.com/embed/VIDEO_ID
    if (uri.pathSegments.contains('embed') && uri.pathSegments.length > 1) {
      final embedIndex = uri.pathSegments.indexOf('embed');
      return uri.pathSegments[embedIndex + 1];
    }

    return null;
  }

  /// YouTube iframe embed URL
  String? get embedUrl {
    final id = videoId;
    if (id == null) return null;
    return 'https://www.youtube.com/embed/$id';
  }

  Lecture copyWith({
    String? id,
    String? title,
    String? courseId,
    String? youtubeUrl,
    String? description,
    String? quizId,
    bool clearQuizId = false,
    int? sortOrder,
    int? grade,
    bool? isPublished,
    List<LectureContentBlock>? contentBlocks,
    List<String>? examIds,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      courseId: courseId ?? this.courseId,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      description: description ?? this.description,
      quizId: clearQuizId ? null : (quizId ?? this.quizId),
      sortOrder: sortOrder ?? this.sortOrder,
      grade: grade ?? this.grade,
      isPublished: isPublished ?? this.isPublished,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      examIds: examIds ?? this.examIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'course_id': courseId,
      'youtube_url': youtubeUrl,
      'description': description,
      'quiz_id': quizId,
      'sort_order': sortOrder,
      'grade': grade,
      'is_published': isPublished,
      'content_blocks': {
        'blocks': contentBlocks.map((b) => b.toJson()).toList(),
        'exam_ids': examIds,
      },
    };
  }

  factory Lecture.fromJson(Map<String, dynamic> json) {
    List<LectureContentBlock> blocks = [];
    List<String> examIds = [];
    final rawBlocks = json['content_blocks'];
    if (rawBlocks != null) {
      try {
        dynamic decoded = rawBlocks;
        if (rawBlocks is String) {
          decoded = jsonDecode(rawBlocks);
        }
        if (decoded is Map<String, dynamic>) {
          final blocksList = decoded['blocks'] as List<dynamic>?;
          if (blocksList != null) {
            blocks = blocksList.map((b) => LectureContentBlock.fromJson(b as Map<String, dynamic>)).toList();
          }
          final examsList = decoded['exam_ids'] as List<dynamic>?;
          if (examsList != null) {
            examIds = examsList.map((e) => e.toString()).toList();
          }
        } else if (decoded is List) {
          blocks = decoded.map((b) => LectureContentBlock.fromJson(b as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        // Fallback or log
      }
    }

    // Backwards Compatibility:
    // If blocks are empty but legacy columns are populated, construct blocks dynamically
    if (blocks.isEmpty) {
      final legacyDesc = json['description'] as String? ?? '';
      final legacyYoutube = json['youtube_url'] as String? ?? '';
      final legacyQuiz = json['quiz_id'] as String? ?? '';

      if (legacyDesc.isNotEmpty) {
        blocks.add(LectureContentBlock(
          id: 'legacy_desc',
          type: BlockType.text,
          content: legacyDesc,
        ));
      }
      if (legacyYoutube.isNotEmpty) {
        blocks.add(LectureContentBlock(
          id: 'legacy_youtube',
          type: BlockType.youtube,
          content: legacyYoutube,
        ));
      }
      if (legacyQuiz.isNotEmpty) {
        blocks.add(LectureContentBlock(
          id: 'legacy_quiz',
          type: BlockType.quiz,
          content: legacyQuiz,
        ));
      }
    }

    if (examIds.isEmpty && json['quiz_id'] != null) {
      final quizVal = json['quiz_id'] as String;
      if (quizVal.isNotEmpty) {
        examIds.add(quizVal);
      }
    }

    return Lecture(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      youtubeUrl: json['youtube_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quizId: json['quiz_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      grade: json['grade'] as int? ?? 1,
      isPublished: json['is_published'] as bool? ?? false,
      contentBlocks: blocks,
      examIds: examIds,
    );
  }
}
