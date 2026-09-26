import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/widgets/splash_screen.dart';

void main() {
  Widget wrap() {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: const SplashScreen(),
      ),
    );
  }

  testWidgets('renders a small centered logo', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('عربيلوجيا'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.height, 80);
  });
}