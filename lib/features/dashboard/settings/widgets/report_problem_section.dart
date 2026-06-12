import 'package:flutter/material.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/report_problem_bottom_sheet.dart';

class ReportProblemSection extends StatelessWidget {
  const ReportProblemSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('الإبلاغ عن مشكلة'),
            subtitle: const Text('ساعدنا في تحسين التطبيق'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => ReportProblemBottomSheet.show(context),
          ),
        ],
      ),
    );
  }
}
