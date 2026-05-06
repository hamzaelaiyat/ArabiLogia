import 'package:flutter/material.dart';

/// Text styling options for question text
class QuestionTextStyle {
  final double fontSize; // 14 to 32
  final bool isBold;
  final bool isUnderlined;
  final int colorIndex; // 0-9, index into predefined colors

  const QuestionTextStyle({
    this.fontSize = 18,
    this.isBold = false,
    this.isUnderlined = false,
    this.colorIndex = 0,
  });

  /// Predefined colors for question text (10 colors) - works on both light and dark
  static const List<Color> textColors = [
    Color(0xFFD32F2F), // 0: Red
    Color(0xFF1A237E), // 1: Indigo
    Color(0xFF1565C0), // 2: Blue (lighter for dark mode visibility)
    Color(0xFF00897B), // 3: Teal
    Color(0xFF2E7D32), // 4: Green
    Color(0xFF689F38), // 5: Light Green
    Color(0xFFE65100), // 6: Deep Orange (lighter)
    Color(0xFF9C27B0), // 7: Purple
    Color(0xFF6D4C41), // 8: Brown (lighter)
    Color(0xFF546E7A), // 9: Blue Grey
  ];

  /// Dark mode colors - slightly brighter for visibility on dark backgrounds
  static const List<Color> textColorsDark = [
    Color(0xFFFF5252), // 0: Red Light
    Color(0xFF7986CB), // 1: Indigo Light
    Color(0xFF64B5F6), // 2: Blue Light
    Color(0xFF4DB6AC), // 3: Teal Light
    Color(0xFF81C784), // 4: Green Light
    Color(0xFFAED581), // 5: Light Green Light
    Color(0xFFFF8A65), // 6: Deep Orange Light
    Color(0xFFBA68C8), // 7: Purple Light
    Color(0xFFA1887F), // 8: Brown Light
    Color(0xFF90A4AE), // 9: Blue Grey Light
  ];

  static Color getColor(int index, {bool isDark = false}) {
    if (isDark && index > 0) {
      return textColorsDark[index];
    }
    return textColors[index];
  }

  /// Color names for display
  static const List<String> colorNames = [
    'أحمر',
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

  Color getTextColor({bool isDark = false}) => getColor(colorIndex, isDark: isDark);

  QuestionTextStyle copyWith({
    double? fontSize,
    bool? isBold,
    bool? isUnderlined,
    int? colorIndex,
  }) {
    return QuestionTextStyle(
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isUnderlined: isUnderlined ?? this.isUnderlined,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'isBold': isBold,
      'isUnderlined': isUnderlined,
      'colorIndex': colorIndex,
    };
  }

  factory QuestionTextStyle.fromJson(Map<String, dynamic> json) {
    return QuestionTextStyle(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      isBold: json['isBold'] as bool? ?? false,
      isUnderlined: json['isUnderlined'] as bool? ?? false,
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

/// Helper function to parse formatted question text and return TextSpans
/// Supports: **bold**, __underline__, and $N"text" for colors (N=0-9)
List<TextSpan> parseQuestionText(String text, {bool isDark = false}) {
  final spans = <TextSpan>[];
  if (text.isEmpty) return spans;

  int i = 0;
  while (i < text.length) {
    if (text.substring(i).startsWith('**')) {
      final end = text.indexOf('**', i + 2);
      if (end != -1) {
        final boldText = text.substring(i + 2, end);
        spans.add(TextSpan(
          text: boldText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
        i = end + 2;
      } else {
        spans.add(TextSpan(text: '**'));
        i += 2;
      }
    } else if (text.substring(i).startsWith('__')) {
      final end = text.indexOf('__', i + 2);
      if (end != -1) {
        final underlineText = text.substring(i + 2, end);
        spans.add(TextSpan(
          text: underlineText,
          style: const TextStyle(decoration: TextDecoration.underline),
        ));
        i = end + 2;
      } else {
        spans.add(TextSpan(text: '__'));
        i += 2;
      }
    } else if (i + 1 < text.length &&
        text[i] == r'$' &&
        RegExp(r'\d').hasMatch(text[i + 1])) {
      // New color format: $N"text" (e.g., $0"hello")
      int j = i + 1;
      while (j < text.length && RegExp(r'\d').hasMatch(text[j])) j++;
      if (j < text.length && text[j] == '"') {
        final colorIndex = int.tryParse(text.substring(i + 1, j));
        if (colorIndex != null && colorIndex >= 0 && colorIndex < 10) {
          final color = QuestionTextStyle.getColor(colorIndex, isDark: isDark);
          final textStart = j + 1;
          final lastQuote = text.lastIndexOf('"');
          if (lastQuote > textStart) {
            spans.add(TextSpan(
              text: text.substring(textStart, lastQuote),
              style: TextStyle(color: color),
            ));
            i = lastQuote + 1;
          } else {
            i = j + 1;
          }
        } else {
          spans.add(TextSpan(text: text[i]));
          i++;
        }
      } else {
        spans.add(TextSpan(text: text[i]));
        i++;
      }
    } else {
      spans.add(TextSpan(text: text[i]));
      i++;
    }
  }

  if (spans.isEmpty) spans.add(TextSpan(text: text));
  return spans;
}
