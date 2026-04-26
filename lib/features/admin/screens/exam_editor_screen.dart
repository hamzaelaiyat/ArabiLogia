import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';

class ExamEditorScreen extends StatelessWidget {
  final Exam? existingExam;

  const ExamEditorScreen({super.key, this.existingExam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildPerformanceBar(context),
            Expanded(
              child: ExamEditor(
                existingExam: existingExam,
                onSave: (exam) => _handleSave(context, exam),
                onCancel: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Performance Mode:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer<PotatoModeProvider>(
              builder: (context, potato, _) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PotatoLevel.values.map((level) {
                      final isSelected = potato.level == level;
                      final config = potato.getConfigForLevel(level);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => potato.setPotatoLevel(level),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[400]!,
                              ),
                            ),
                            child: Text(
                              config.levelName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          Consumer<PotatoModeProvider>(
            builder: (context, potato, _) {
              if (!potato.isLoaded || potato.deviceSpec == null) {
                return const SizedBox.shrink();
              }
              return Text(
                '${potato.deviceSpec!.ramGB}GB RAM | ${potato.deviceSpec!.cpuCores} Cores | ${potato.deviceSpec!.batteryPercent}% Batt',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleSave(BuildContext context, Exam exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ الامتحان: ${exam.title}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    context.pop(exam);
  }
}
