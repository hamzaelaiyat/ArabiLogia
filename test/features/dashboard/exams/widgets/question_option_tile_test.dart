import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_option_tile.dart';

void main() {
  const option = Option(id: 'o0', text: 'نص الخيار', isCorrect: false);

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('shows letter label for the option index', (tester) async {
    await tester.pumpWidget(wrap(
      QuestionOptionTile(
        option: option,
        index: 0,
        isSelected: false,
        categoryColor: Colors.blue,
        onTap: () {},
      ),
    ));

    expect(find.text('أ'), findsOneWidget);
  });

  testWidgets('shows third letter for index 2', (tester) async {
    await tester.pumpWidget(wrap(
      QuestionOptionTile(
        option: option,
        index: 2,
        isSelected: false,
        categoryColor: Colors.blue,
        onTap: () {},
      ),
    ));

    expect(find.text('ج'), findsOneWidget);
  });

  testWidgets('exposes semantics for unselected and selected states',
      (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap(
      QuestionOptionTile(
        option: option,
        index: 0,
        isSelected: false,
        categoryColor: Colors.blue,
        onTap: () {},
      ),
    ));
    expect(find.bySemanticsLabel('الخيار أ، غير محدد'), findsOneWidget);

    await tester.pumpWidget(wrap(
      QuestionOptionTile(
        option: option,
        index: 0,
        isSelected: true,
        categoryColor: Colors.blue,
        onTap: () {},
      ),
    ));
    expect(find.bySemanticsLabel('الخيار أ، محدد'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('forwards taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(
      QuestionOptionTile(
        option: option,
        index: 0,
        isSelected: false,
        categoryColor: Colors.blue,
        onTap: () => tapped = true,
      ),
    ));

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
