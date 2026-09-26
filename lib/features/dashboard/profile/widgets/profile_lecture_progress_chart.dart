import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ProfileLectureProgressChartCard extends StatelessWidget {
  final List<double> progressPoints;

  const ProfileLectureProgressChartCard({
    super.key,
    required this.progressPoints,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : const Color(0xFFE5F3FF);

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Stack(
        children: [
          // Top-Right Label: "التقدم في المحاضرات"
          Positioned(
            top: 0,
            right: 0,
            child: Text(
              'التقدم في المحاضرات',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.mutedDark : AppColors.textLight,
              ),
            ),
          ),

          // Bottom-Left Label: "الزمن (يوماً)"
          Positioned(
            bottom: 0,
            left: 0,
            child: Text(
              'الزمن (يوماً)',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.mutedDark : AppColors.textLight,
              ),
            ),
          ),

          // Smooth Bézier Curve Painter
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 20.0),
              child: CustomPaint(
                painter: _SmoothCurvePainter(
                  points: progressPoints.isEmpty
                      ? const [0.2, 0.4, 0.35, 0.7, 0.5, 0.85, 0.95]
                      : progressPoints,
                  lineColor: AppColors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothCurvePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;

  _SmoothCurvePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    final p0 = Offset(0, size.height * (1.0 - points[0].clamp(0.05, 0.95)));
    path.moveTo(p0.dx, p0.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = Offset(
        i * stepX,
        size.height * (1.0 - points[i].clamp(0.05, 0.95)),
      );
      final p2 = Offset(
        (i + 1) * stepX,
        size.height * (1.0 - points[i + 1].clamp(0.05, 0.95)),
      );

      final controlPoint1 = Offset(p1.dx + stepX / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + stepX / 2, p2.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SmoothCurvePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
