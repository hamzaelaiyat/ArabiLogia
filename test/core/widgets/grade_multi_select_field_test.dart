import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/core/widgets/grade_multi_select_field.dart';

void main() {
  // resetForTest() empties the static list, so reload the bundled defaults;
  // there is no Supabase client here, so loadGrades() falls back.
  setUp(() async {
    GradeMetadata.resetForTest();
    await GradeMetadata.loadGrades();
  });

  /// Pumps the field and records every selection it emits.
  Future<List<List<int>>> pumpField(
    WidgetTester tester,
    List<int> initial,
  ) async {
    final emitted = <List<int>>[];
    var current = initial;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradeMultiSelectField(
            selectedGradeIds: current,
            onChanged: (ids) {
              current = ids;
              emitted.add(ids);
            },
          ),
        ),
      ),
    );
    return emitted;
  }

  /// Taps the chip whose visible label matches [label].
  Future<void> tapChip(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(ChoiceChip, label));
    await tester.pump();
  }

  /// The summary sits under the chips, and a selected grade's name also
  /// appears on its own chip, so read the summary line by key.
  String summaryText(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const Key('gradeMultiSelectSummary')))
      .data!;

  testWidgets('a single selection summarises as that grade', (tester) async {
    await pumpField(tester, const [2]);
    expect(summaryText(tester), 'الصف الثاني الثانوي');
  });

  testWidgets('several selections summarise as a shared count', (tester) async {
    await pumpField(tester, const [1, 2, 10]);
    expect(summaryText(tester), 'مشارك مع 3 صفوف');
  });

  testWidgets('the all-grades sentinel summarises as all grades', (
    tester,
  ) async {
    await pumpField(tester, const [0]);
    expect(summaryText(tester), 'جميع الصفوف');
  });

  testWidgets('tapping a grade adds it to the selection', (tester) async {
    final emitted = await pumpField(tester, const [1]);
    await tapChip(tester, 'الصف الأول البكالوري');

    expect(emitted.single, [1, 10]);
  });

  testWidgets('tapping a selected grade removes it', (tester) async {
    final emitted = await pumpField(tester, const [1, 2, 3]);
    await tapChip(tester, 'الصف الثاني الثانوي');

    expect(emitted.single, [1, 3]);
  });

  testWidgets('the last remaining grade cannot be removed', (tester) async {
    // Guards against an empty selection, which would otherwise fall through
    // to the legacy scalar column and behave surprisingly.
    final emitted = await pumpField(tester, const [3]);
    await tapChip(tester, 'الصف الثالث الثانوي');

    expect(emitted, isEmpty);
  });

  testWidgets('tapping all grades replaces the whole selection', (
    tester,
  ) async {
    final emitted = await pumpField(tester, const [1, 2]);
    await tapChip(tester, 'الكل');

    expect(emitted.single, [0]);
  });

  testWidgets('while all grades is active, a grade tap switches to just it', (
    tester,
  ) async {
    final emitted = await pumpField(tester, const [0]);
    await tapChip(tester, 'الصف الثاني البكالوري');

    expect(emitted.single, [11]);
  });

  testWidgets('every grade is offered so both tracks are reachable', (
    tester,
  ) async {
    await pumpField(tester, const [1]);

    expect(find.widgetWithText(ChoiceChip, 'الكل'), findsOneWidget);
    for (final grade in GradeMetadata.grades) {
      expect(
        find.widgetWithText(ChoiceChip, grade.name),
        findsOneWidget,
        reason: 'missing chip for grade ${grade.id}',
      );
    }
  });
}
