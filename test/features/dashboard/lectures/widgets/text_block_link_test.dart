import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/widgets/desktop_confirm_dialog.dart';
import 'package:arabilogia/core/widgets/external_link_dialog.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/text_block_widget.dart';

Widget _wrap(LectureContentBlock block) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: TextBlockWidget(
          block: block,
          isCompleted: false,
          onToggleCompletion: () {},
        ),
      ),
    ),
  );
}

LectureContentBlock _block(String content) =>
    LectureContentBlock(id: 'b1', type: BlockType.text, content: content);

void main() {
  group('isWebLink', () {
    test('accepts http and https', () {
      expect(isWebLink('https://example.com'), isTrue);
      expect(isWebLink('http://example.com/page?a=1'), isTrue);
      expect(isWebLink('  https://example.com  '), isTrue);
    });

    test('rejects dangerous and unusable schemes', () {
      expect(isWebLink('javascript:alert(1)'), isFalse);
      expect(isWebLink('data:text/html,<h1>x</h1>'), isFalse);
      expect(isWebLink('file:///etc/passwd'), isFalse);
      expect(isWebLink('content://media/external/file/1'), isFalse);
    });

    test('rejects relative and malformed input', () {
      expect(isWebLink('/local/page'), isFalse);
      expect(isWebLink('example.com'), isFalse);
      expect(isWebLink('https://'), isFalse);
      expect(isWebLink(''), isFalse);
    });
  });

  group('externalLinkDisplayTarget', () {
    test('shows host and path', () {
      expect(
        externalLinkDisplayTarget('https://example.com/docs/page?x=1'),
        'example.com/docs/page',
      );
    });

    test('drops a bare trailing slash', () {
      expect(externalLinkDisplayTarget('https://example.com/'), 'example.com');
    });

    test('falls back to the raw value when unparseable', () {
      expect(
        externalLinkDisplayTarget('javascript:alert(1)'),
        'javascript:alert(1)',
      );
    });
  });

  group('TextBlockWidget link handling', () {
    testWidgets('warns before leaving the site when a link is tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(_block('اقرأ [الوثيقة](https://example.com/docs) الآن')),
      );

      await tester.tapOnText(find.textRange.ofSubstring('الوثيقة'));
      await tester.pumpAndSettle();

      expect(find.text('أنت على وشك مغادرة الموقع'), findsOneWidget);
      expect(find.textContaining('example.com/docs'), findsOneWidget);
      expect(find.text('فتح الرابط'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('cancelling dismisses the warning without navigating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_block('اقرأ [الوثيقة](https://example.com/docs) الآن')),
      );

      await tester.tapOnText(find.textRange.ofSubstring('الوثيقة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(find.text('أنت على وشك مغادرة الموقع'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refuses a javascript: link and never shows the warning', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_block('اضغط [هنا](javascript:alert(1))')));

      await tester.tapOnText(find.textRange.ofSubstring('هنا'));
      await tester.pumpAndSettle();

      expect(find.text('أنت على وشك مغادرة الموقع'), findsNothing);
      expect(find.text('نوع هذا الرابط غير مدعوم.'), findsOneWidget);
    });

    testWidgets('renders a link without needing a tap', (tester) async {
      await tester.pumpWidget(_wrap(_block('نص عادي بلا روابط')));

      expect(find.text('نص عادي بلا روابط'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the desktop warning dialog on a wide window', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(_block('اقرأ [الوثيقة](https://example.com/docs) الآن')),
      );

      await tester.tapOnText(find.textRange.ofSubstring('الوثيقة'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopConfirmDialog), findsOneWidget);
      expect(find.text('أنت على وشك مغادرة الموقع'), findsOneWidget);
      expect(find.textContaining('example.com/docs'), findsOneWidget);
    });
  });
}
