import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_timer.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Row(children: [child])),
      ),
    );
  }

  Future<Color?> pumpAndReadColor(WidgetTester tester, int seconds) async {
    final notifier = ValueNotifier<int>(seconds);
    await tester.pumpWidget(wrap(
      ExamTimer(timerNotifier: notifier, onTimerEnd: () {}),
    ));
    final icon = tester.widget<Icon>(find.byIcon(Icons.timer_outlined));
    final color = icon.color;
    await tester.pumpWidget(const SizedBox());
    notifier.dispose();
    return color;
  }

  testWidgets('uses pass color above five minutes', (tester) async {
    final color = await pumpAndReadColor(tester, 600);
    expect(color, AppColors.examPass);
  });

  testWidgets('uses warning color between one and five minutes',
      (tester) async {
    final color = await pumpAndReadColor(tester, 300);
    expect(color, AppColors.examWarning);
  });

  testWidgets('uses fail color below one minute', (tester) async {
    final color = await pumpAndReadColor(tester, 45);
    expect(color, AppColors.examFail);
  });

  testWidgets('formats remaining time as MM:SS', (tester) async {
    final notifier = ValueNotifier<int>(600);
    await tester.pumpWidget(wrap(
      ExamTimer(timerNotifier: notifier, onTimerEnd: () {}),
    ));
    expect(find.text('10:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    notifier.dispose();
  });

  testWidgets('emits warning once when crossing the five minute mark',
      (tester) async {
    final notifier = ValueNotifier<int>(302);
    final warning = ValueNotifier<String?>(null);
    await tester.pumpWidget(wrap(
      ExamTimer(
        timerNotifier: notifier,
        onTimerEnd: () {},
        warningNotifier: warning,
      ),
    ));

    notifier.value = 300;
    await tester.pump();
    expect(warning.value, 'باقي 5 دقائق');

    await tester.pumpWidget(const SizedBox());
    notifier.dispose();
    warning.dispose();
  });
}
