import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class StudentPerformanceChartCard extends StatelessWidget {
  final double avgScore;
  final List<double>? scoresHistory;
  final VoidCallback? onTap;

  const StudentPerformanceChartCard({
    super.key,
    this.avgScore = 0.0,
    this.scoresHistory,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.secondaryDark : AppColors.cardLightBg;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5F3FF);

    final realScores = scoresHistory ?? [];
    final hasData = realScores.isNotEmpty;
    final displayScore = hasData ? realScores.last : avgScore;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppTokens.radius2xlAll,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radius2xlAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Stack(
            children: [
              // Badge at top left showing score percentage (% smaller than number)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: displayScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.primary
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        TextSpan(
                          text: '%',
                          style: TextStyle(
                            fontSize:
                                8.5, // % sign is smaller than the number itself
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.primary
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Dynamic score line chart painter driven by actual score history!
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 4.0),
                  child: hasData
                      ? CustomPaint(
                          painter: _DynamicPerformanceChartPainter(
                            scores: realScores,
                            lineColor: isDark ? Colors.white : Colors.black87,
                            guideColor: isDark
                                ? Colors.white38
                                : Colors.black26,
                          ),
                        )
                      : Center(
                          child: Text(
                            'لا توجد بيانات درجات بعد',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.mutedDark
                                  : Colors.black38,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DynamicPerformanceChartPainter extends CustomPainter {
  final List<double> scores;
  final Color lineColor;
  final Color guideColor;

  _DynamicPerformanceChartPainter({
    required this.scores,
    required this.lineColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || scores.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintGuide = Paint()
      ..color = guideColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    // Convert scores to Canvas points (x, y)
    final effectiveScores = scores.length == 1 ? [0.0, scores.first] : scores;
    final points = <Offset>[];
    final n = effectiveScores.length;

    for (int i = 0; i < n; i++) {
      final x = (size.width / (n - 1 > 0 ? n - 1 : 1)) * i;
      final scoreVal = effectiveScores[i].clamp(0.0, 100.0);
      final y =
          size.height -
          (size.height * 0.75 * (scoreVal / 100.0)) -
          (size.height * 0.1);
      points.add(Offset(x, y));
    }

    // Dotted horizontal baseline at 50%
    final pathH = Path();
    pathH.moveTo(0, size.height * 0.5);
    pathH.lineTo(size.width * 0.45, size.height * 0.5);
    _drawDottedLine(canvas, pathH, paintGuide);

    // Dotted vertical indicator line at peak score
    final lastPoint = points.last;
    final pathV = Path();
    pathV.moveTo(lastPoint.dx, lastPoint.dy);
    pathV.lineTo(lastPoint.dx, size.height);
    _drawDottedLine(canvas, pathV, paintGuide);

    // Draw Smooth Bezier Spline connecting actual data points
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    canvas.drawPath(path, paintLine);

    // Draw active point node at last test score
    canvas.drawCircle(lastPoint, 3.5, paintDot);
  }

  void _drawDottedLine(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 3.0;
    const dashSpace = 3.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicPerformanceChartPainter oldDelegate) {
    return oldDelegate.scores != scores ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.guideColor != guideColor;
  }
}
