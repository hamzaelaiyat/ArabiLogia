import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/contextual_sidebar_provider.dart';

class ExamSidebar extends StatefulWidget {
  final ExamSidebarData data;
  final double width;

  const ExamSidebar({
    super.key,
    required this.data,
    this.width = AppTokens.sidebarWidth,
  });

  @override
  State<ExamSidebar> createState() => _ExamSidebarState();
}

class _ExamSidebarState extends State<ExamSidebar> {
  bool _filterOnlyFlagged = false;

  String _formatTimer(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final totalQuestions = data.questionCount;
    final answeredCount = data.selectedAnswers.values.where((v) => v != null).length;
    final flaggedCount = data.flaggedQuestions.values.where((v) => v == true).length;

    List<int> visibleIndices = List.generate(totalQuestions, (i) => i);
    if (_filterOnlyFlagged) {
      visibleIndices = visibleIndices
          .where((i) => data.flaggedQuestions[i] == true)
          .toList();
    }

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(
          left: BorderSide(
            color: AppColors.mutedColor(context).withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Exam Category, Title & Timer
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: data.categoryColor,
                        borderRadius: AppTokens.radiusFullAll,
                      ),
                      child: Text(
                        data.categoryName.isNotEmpty ? data.categoryName : 'الاختبار',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (data.timerNotifier != null)
                      ValueListenableBuilder<int>(
                        valueListenable: data.timerNotifier!,
                        builder: (context, seconds, _) {
                          final isUrgent = seconds <= 180;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: isUrgent ? Colors.red : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimer(seconds),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isUrgent ? Colors.red : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacing8),
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.spacing8),
                Row(
                  children: [
                    Text(
                      'الإجابات: $answeredCount/$totalQuestions',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (flaggedCount > 0)
                      Row(
                        children: [
                          const Icon(Icons.flag_rounded, size: 14, color: Colors.red),
                          const SizedBox(width: 2),
                          Text(
                            '$flaggedCount معلمة',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Row: All vs Flagged
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing12,
              vertical: AppTokens.spacing8,
            ),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('الكل', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.grid_view_rounded, size: 14),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('الأعلام', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.flag_rounded, size: 14, color: Colors.red),
                ),
              ],
              selected: {_filterOnlyFlagged},
              onSelectionChanged: (val) {
                setState(() => _filterOnlyFlagged = val.first);
              },
            ),
          ),

          // Question List / Grid
          Expanded(
            child: visibleIndices.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _filterOnlyFlagged
                            ? 'لا توجد أسئلة معلمة بعلم أحمر'
                            : 'لا توجد أسئلة',
                        style: TextStyle(
                          color: AppColors.mutedColor(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacing8,
                      vertical: AppTokens.spacing4,
                    ),
                    itemCount: visibleIndices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, idx) {
                      final qIndex = visibleIndices[idx];
                      final isCurrent = qIndex == data.currentIndex;
                      final isAnswered = data.selectedAnswers[qIndex] != null;
                      final isFlagged = data.flaggedQuestions[qIndex] == true;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : isAnswered
                                  ? Colors.green.withValues(alpha: 0.08)
                                  : Colors.transparent,
                          borderRadius: AppTokens.radiusMdAll,
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary
                                : isFlagged
                                    ? Colors.red.withValues(alpha: 0.7)
                                    : isAnswered
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : AppColors.mutedColor(context)
                                            .withValues(alpha: 0.2),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spacing8,
                          ),
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: isAnswered
                                ? Colors.green
                                : isCurrent
                                    ? AppColors.primary
                                    : AppColors.mutedColor(context)
                                        .withValues(alpha: 0.2),
                            child: isAnswered
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${qIndex + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent
                                          ? Colors.white
                                          : AppColors.foreground(context),
                                    ),
                                  ),
                          ),
                          title: Text(
                            'السؤال ${qIndex + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent
                                  ? AppColors.primary
                                  : AppColors.foreground(context),
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: isFlagged ? 'إزالة العلم الأحمر' : 'تعليم بعلم أحمر',
                            icon: Icon(
                              isFlagged
                                  ? Icons.flag_rounded
                                  : Icons.flag_outlined,
                              size: 18,
                              color: isFlagged
                                  ? Colors.red
                                  : AppColors.mutedColor(context).withValues(alpha: 0.4),
                            ),
                            onPressed: () => data.onToggleFlag(qIndex),
                          ),
                          onTap: () => data.onSelectQuestion(qIndex),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
