import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class ExamParticipantsList extends StatelessWidget {
  final List<Map<String, dynamic>> participants;
  final ValueChanged<dynamic> onParticipantTap;

  const ExamParticipantsList({
    super.key,
    required this.participants,
    required this.onParticipantTap,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Center(
        child: Text('لم يقم أي طالب بأداء هذا الامتحان بعد.'),
      );
    }

    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final p = participants[index];
        final profile = p['profiles'] as Map<String, dynamic>?;
        final score = (p['score'] as num).toDouble();
        final dbGrade = profile?['grade'] as int? ?? 0;
        final uiGrade = dbGrade > 9 ? dbGrade - 9 : dbGrade;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: score >= 50 ? Colors.green : Colors.red,
            child: Text(
              '${score.toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          title: Text(
            profile?['full_name'] ?? profile?['username'] ?? 'مستخدم مجهول',
          ),
          subtitle: Text('الصف: ${uiGrade}ثانوي'),
          trailing: Text(
            intl.DateFormat(
              'MM/dd HH:mm',
            ).format(DateTime.parse(p['created_at'])),
          ),
          onTap: () => onParticipantTap(p['wrong_answers']),
        );
      },
    );
  }
}