import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class StudentPointCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final Future<void> Function(int amount) onIncrement;
  final Future<void> Function(int amount) onDecrement;
  final VoidCallback onReset;
  final bool isProcessing;

  const StudentPointCard({
    super.key,
    required this.student,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
    this.isProcessing = false,
  });

  static const _gradeNames = [
    '',
    'الأول الثانوي',
    'الثاني الثانوي',
    'الثالث الثانوي',
  ];

  int get _balance {
    final v = student['total_balance'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  int get _examPoints {
    final v = student['exam_points'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  int get _manualPoints {
    final v = student['manual_adjustments'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  String get _name {
    final n = student['full_name'] as String?;
    if (n != null && n.isNotEmpty) return n;
    final u = student['username'] as String?;
    if (u != null && u.isNotEmpty) return '@$u';
    return 'مستخدم';
  }

  int? get _grade {
    final g = student['grade'];
    if (g is int) return g;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = student['avatar_url'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl)
                       : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          _name.isNotEmpty ? _name[0] : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_grade != null)
                        Text(
                          _gradeNames[_grade!.clamp(1, 3)],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedColor(context),
                          ),
                        ),
                    ],
                  ),
                ),
                _BalanceDisplay(balance: _balance),
              ],
            ),
            const SizedBox(height: 12),
            _PointsBreakdown(
              examPoints: _examPoints,
              manualPoints: _manualPoints,
            ),
            const SizedBox(height: 12),
            _ActionButtons(
              onIncrement: onIncrement,
              onDecrement: onDecrement,
              onReset: onReset,
              isProcessing: isProcessing,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceDisplay extends StatelessWidget {
  final int balance;
  const _BalanceDisplay({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: balance >= 0
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: balance >= 0
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$balance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: balance >= 0 ? AppColors.primary : Colors.red,
            ),
          ),
          Text(
            'نقطة',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsBreakdown extends StatelessWidget {
  final int examPoints;
  final int manualPoints;
  const _PointsBreakdown({
    required this.examPoints,
    required this.manualPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (examPoints == 0 && manualPoints == 0) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Icon(
          Icons.quiz_outlined,
          size: 14,
          color: AppColors.mutedColor(context),
        ),
        const SizedBox(width: 4),
        Text(
          'امتحانات: $examPoints',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedColor(context),
          ),
        ),
        const SizedBox(width: 12),
        if (manualPoints != 0) ...[
          Icon(
            Icons.tune,
            size: 14,
            color: manualPoints > 0 ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            'تعديل: ${manualPoints > 0 ? '+' : ''}$manualPoints',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: manualPoints > 0 ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Future<void> Function(int amount) onIncrement;
  final Future<void> Function(int amount) onDecrement;
  final VoidCallback onReset;
  final bool isProcessing;
  final bool isDark;

  const _ActionButtons({
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
    required this.isProcessing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isProcessing,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AdjButton(
                icon: Icons.remove,
                label: '10',
                color: Colors.red,
                onTap: () => onDecrement(10),
                tooltip: 'خصم 10 نقاط',
              ),
              _AdjButton(
                icon: Icons.remove,
                label: '1',
                color: Colors.red,
                onTap: () => onDecrement(1),
                tooltip: 'خصم نقطة',
                compact: true,
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.mutedColor(context).withValues(alpha: 0.3),
              ),
              _AdjButton(
                icon: Icons.add,
                label: '1',
                color: Colors.green,
                onTap: () => onIncrement(1),
                tooltip: 'إضافة نقطة',
                compact: true,
              ),
              _AdjButton(
                icon: Icons.add,
                label: '10',
                color: Colors.green,
                onTap: () => onIncrement(10),
                tooltip: 'إضافة 10 نقاط',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('إعادة تعيين النقاط'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final bool compact;

  const _AdjButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
