import 'package:flutter/material.dart';
import 'package:arabilogia/features/admin/widgets/exam_participants_list.dart';
import 'package:arabilogia/features/admin/widgets/exam_non_participants_list.dart';

class ExamResultsDetailView extends StatelessWidget {
  final String examTitle;
  final bool isLoading;
  final List<Map<String, dynamic>> participants;
  final List<Map<String, dynamic>> nonParticipants;
  final VoidCallback onBack;
  final ValueChanged<dynamic> onShowWrongAnswers;

  const ExamResultsDetailView({
    super.key,
    required this.examTitle,
    required this.isLoading,
    required this.participants,
    required this.nonParticipants,
    required this.onBack,
    required this.onShowWrongAnswers,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  examTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'المشاركون'),
                    Tab(text: 'لم يكتمل بعد'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ExamParticipantsList(
                        participants: participants,
                        onParticipantTap: onShowWrongAnswers,
                      ),
                      ExamNonParticipantsList(
                        nonParticipants: nonParticipants,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}