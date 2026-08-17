import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/widgets/empty_state.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders icon, title and message', (tester) async {
    await tester.pumpWidget(wrap(
      const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'لا توجد عناصر',
        message: 'سيتم إضافة عناصر قريباً',
      ),
    ));

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('لا توجد عناصر'), findsOneWidget);
    expect(find.text('سيتم إضافة عناصر قريباً'), findsOneWidget);
  });

  testWidgets('renders optional action and forwards taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(
      EmptyState(
        icon: Icons.search_off,
        title: 'لا توجد نتائج',
        message: 'جرب كلمات بحث مختلفة',
        action: TextButton(
          onPressed: () => tapped = true,
          child: const Text('مسح البحث'),
        ),
      ),
    ));

    expect(find.text('مسح البحث'), findsOneWidget);
    await tester.tap(find.text('مسح البحث'));
    expect(tapped, isTrue);
  });

  testWidgets('omits action slot when not provided', (tester) async {
    await tester.pumpWidget(wrap(
      const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'عنوان',
        message: 'رسالة',
      ),
    ));

    expect(find.byType(TextButton), findsNothing);
  });
}
