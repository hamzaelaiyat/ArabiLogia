import 'package:flutter/material.dart';
import 'package:arabilogia/features/dashboard/exams/utils/grade_mapper.dart';

class ExamNonParticipantsList extends StatelessWidget {
  final List<Map<String, dynamic>> nonParticipants;

  const ExamNonParticipantsList({
    super.key,
    required this.nonParticipants,
  });

  @override
  Widget build(BuildContext context) {
    if (nonParticipants.isEmpty) {
      return const Center(
        child: Text('جميع الطلاب في هذا الصف أتموا الامتحان!'),
      );
    }

    return ListView.builder(
      itemCount: nonParticipants.length,
      itemBuilder: (context, index) {
        final profile = nonParticipants[index];
        final dbGrade = profile['grade'] as int? ?? 0;
        final uiGrade = mapDbGradeToUiGrade(dbGrade);
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(
            profile['full_name'] ?? profile['username'] ?? 'مستخدم مجهول',
          ),
          subtitle: Text('الصف: ${uiGrade}ثانوي - @${profile['username']}'),
        );
      },
    );
  }
}