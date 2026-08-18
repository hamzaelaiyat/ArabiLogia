import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/progress_bar_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }

  const segments = [
    ProgressSegmentData(
      label: 'قراءة',
      icon: Icons.notes,
      total: 2,
      completed: 1,
      color: Colors.red,
    ),
    ProgressSegmentData(
      label: 'فيديو',
      icon: Icons.play_circle_outline,
      total: 1,
      completed: 0,
      color: Colors.green,
    ),
  ];

  testWidgets('renders overall percentage from all segments', (tester) async {
    await tester.pumpWidget(wrap(
      const ProgressBarCard(segments: segments, categoryColor: Colors.blue),
    ));

    expect(find.text('تقدمك في المحاضرة'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
  });

  testWidgets('renders one legend chip per segment', (tester) async {
    await tester.pumpWidget(wrap(
      const ProgressBarCard(segments: segments, categoryColor: Colors.blue),
    ));

    expect(find.text('قراءة 1/2'), findsOneWidget);
    expect(find.text('فيديو 0/1'), findsOneWidget);
    expect(find.byIcon(Icons.notes), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });

  testWidgets('renders nothing when there are no segments', (tester) async {
    await tester.pumpWidget(wrap(
      const ProgressBarCard(segments: [], categoryColor: Colors.blue),
    ));

    expect(find.byType(Card), findsNothing);
  });

  testWidgets('renders nothing when all totals are zero', (tester) async {
    await tester.pumpWidget(wrap(
      const ProgressBarCard(
        segments: [
          ProgressSegmentData(
            label: 'قراءة',
            icon: Icons.notes,
            total: 0,
            completed: 0,
            color: Colors.red,
          ),
        ],
        categoryColor: Colors.blue,
      ),
    ));

    expect(find.byType(Card), findsNothing);
  });
}
