import 'package:flutter/material.dart';

/// Text styling options for question text
class QuestionTextStyle {
  final double fontSize; // 14 to 32
  final bool isBold;
  final bool isItalic;
  final int colorIndex; // 0-9, index into predefined colors

  const QuestionTextStyle({
    this.fontSize = 18,
    this.isBold = false,
    this.isItalic = false,
    this.colorIndex = 0,
  });

  /// Predefined colors for question text (10 colors)
  static const List<Color> textColors = [
    Color(0xFF000000), // 0: Black
    Color(0xFF1A237E), // 1: Indigo
    Color(0xFF0D47A1), // 2: Blue
    Color(0xFF004D40), // 3: Teal
    Color(0xFF1B5E20), // 4: Green
    Color(0xFF33691E), // 5: Light Green
    Color(0xFFBF360C), // 6: Deep Orange
    Color(0xFF8E24AA), // 7: Purple
    Color(0xFF4E342E), // 8: Brown
    Color(0xFF37474F), // 9: Blue Grey
  ];

  /// Color names for display
  static const List<String> colorNames = [
    'أسود',
    'نيلي',
    'أزرق',
    'أزرق داكن',
    'أخضر',
    'أخضر فاتح',
    'برتقالي داكن',
    'بنفسجي',
    'بني',
    'رمادي مزرق',
  ];

  Color get textColor => textColors[colorIndex];

  QuestionTextStyle copyWith({
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    int? colorIndex,
  }) {
    return QuestionTextStyle(
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'isBold': isBold,
      'isItalic': isItalic,
      'colorIndex': colorIndex,
    };
  }

  factory QuestionTextStyle.fromJson(Map<String, dynamic> json) {
    return QuestionTextStyle(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int? ?? 0,
    );
  }
}

/// Point value for each question
class QuestionPoints {
  final int points; // 1 to 100

  const QuestionPoints({this.points = 10});

  QuestionPoints copyWith({int? points}) {
    return QuestionPoints(points: points ?? this.points);
  }

  Map<String, dynamic> toJson() {
    return {'points': points};
  }

  factory QuestionPoints.fromJson(Map<String, dynamic> json) {
    return QuestionPoints(points: json['points'] as int? ?? 10);
  }
}

/// Combined style and points for a question
class QuestionSettings {
  final QuestionTextStyle textStyle;
  final QuestionPoints points;

  const QuestionSettings({
    this.textStyle = const QuestionTextStyle(),
    this.points = const QuestionPoints(),
  });

  QuestionSettings copyWith({
    QuestionTextStyle? textStyle,
    QuestionPoints? points,
  }) {
    return QuestionSettings(
      textStyle: textStyle ?? this.textStyle,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toJson() {
    return {'textStyle': textStyle.toJson(), 'points': points.toJson()};
  }

  factory QuestionSettings.fromJson(Map<String, dynamic> json) {
    return QuestionSettings(
      textStyle: json['textStyle'] != null
          ? QuestionTextStyle.fromJson(
              json['textStyle'] as Map<String, dynamic>,
            )
          : const QuestionTextStyle(),
      points: json['points'] != null
          ? QuestionPoints.fromJson(json['points'] as Map<String, dynamic>)
          : const QuestionPoints(),
    );
  }
}
