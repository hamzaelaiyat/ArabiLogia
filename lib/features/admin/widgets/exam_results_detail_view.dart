import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/admin/widgets/exam_participants_list.dart';
import 'package:arabilogia/features/admin/widgets/exam_non_participants_list.dart';

/// Tabbed body for a single exam: everyone who completed it (ranked by
/// score) and everyone in the grade who has not attempted it yet.
class ExamResultsDetailView extends StatelessWidget {
  final List<Map<String, dynamic>> participants;
  final List<Map<String, dynamic>> nonParticipants;
  final ValueChanged<Map<String, dynamic>> onParticipantTap;

  const ExamResultsDetailView({
    super.key,
    required this.participants,
    required this.nonParticipants,
    required this.onParticipantTap,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTokens.fontSizeMd,
            ),
            tabs: [
              Tab(text: 'أدوا الامتحان (${participants.length})'),
              Tab(text: 'لم يكتملوا بعد (${nonParticipants.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ExamParticipantsList(
                  participants: participants,
                  onParticipantTap: onParticipantTap,
                ),
                ExamNonParticipantsList(nonParticipants: nonParticipants),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
