import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_navigation_bar.dart';

Widget _host({
  required Size size,
  bool onPrevious = true,
  int currentQuestionIndex = 0,
  int totalQuestions = 5,
  bool isLastQuestion = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ExamNavigationBar(
          currentQuestionIndex:
              isLastQuestion ? totalQuestions - 1 : currentQuestionIndex,
          totalQuestions: totalQuestions,
          onPrevious: onPrevious ? () {} : null,
          onNext: () {},
          isSubmitting: false,
          hasSelectedAnswer: true,
          categoryColor: Colors.blue,
          isFlagged: false,
          onToggleFlag: () {},
          onOpenPalette: () {},
        ),
      ),
    ),
  );
}

/// AppTokens.isMobile reads MediaQuery, so the view size is what matters.
Future<void> _pumpAt(
  WidgetTester tester,
  Size size, {
  bool onPrevious = true,
  bool isLastQuestion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _host(size: size, onPrevious: onPrevious, isLastQuestion: isLastQuestion),
  );
}

void main() {
  // A typical small phone. At this width the old layout gave the Arabic labels
  // roughly 29px between the button padding, which wrapped them one character
  // per line.
  const phone = Size(360, 640);
  const tablet = Size(900, 700);

  group('ExamNavigationBar on a phone', () {
    testWidgets('shows icons only, with no Arabic label text', (tester) async {
      await _pumpAt(tester, phone);

      expect(find.text('التالي'), findsNothing);
      expect(find.text('السابق'), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('does not overflow on a very narrow screen', (tester) async {
      // A RenderFlex overflow fails the test on its own, which is exactly the
      // squeeze that produced one-character-per-line Arabic labels.
      await _pumpAt(tester, const Size(320, 560));

      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the icon buttons tappable at a usable size', (
      tester,
    ) async {
      await _pumpAt(tester, phone);

      final size = tester.getSize(
        find.ancestor(
          of: find.byIcon(Icons.arrow_back),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(size.width, greaterThanOrEqualTo(40));
    });

    testWidgets('last question shows a check icon instead of an arrow', (
      tester,
    ) async {
      await _pumpAt(tester, phone, isLastQuestion: true);

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.text('إنهاء الاختبار'), findsNothing);
    });

    testWidgets('hides the previous button when there is no previous', (
      tester,
    ) async {
      await _pumpAt(tester, phone, onPrevious: false);

      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('ExamNavigationBar on a wide screen', () {
    testWidgets('keeps the Arabic labels', (tester) async {
      await _pumpAt(tester, tablet);

      expect(find.text('التالي'), findsOneWidget);
      expect(find.text('السابق'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('last question shows the finish label', (tester) async {
      await _pumpAt(tester, tablet, isLastQuestion: true);

      expect(find.text('إنهاء الاختبار'), findsOneWidget);
    });
  });
}
