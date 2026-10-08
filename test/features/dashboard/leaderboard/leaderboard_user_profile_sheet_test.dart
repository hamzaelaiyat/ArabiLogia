import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/dashboard/leaderboard/widgets/leaderboard_user_profile_sheet.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

void main() {
  Widget wrap(Widget child) {
    return ChangeNotifierProvider<PotatoModeProvider>(
      create: (_) => PotatoModeProvider(),
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  Map<String, dynamic> userData({String description = ''}) {
    return {
      'user_id': '5286dc12-aa0f-4093-89b4-27b9ee5093a2',
      'full_name': 'حمزة صفوت كامل حسن',
      'grade': 3,
      'description': description,
      'exams_completed': 4,
      'avg_score': 80,
      'total_score': 320,
      'rank': 1,
    };
  }

  testWidgets('renders the bio when the RPC row carries one', (tester) async {
    await tester.pumpWidget(
      wrap(LeaderboardUserProfileSheet(
        userData: userData(description: 'كل من عليها فان'),
      )),
    );

    expect(find.text('كل من عليها فان'), findsOneWidget);
    expect(find.text('حمزة صفوت كامل حسن'), findsOneWidget);
  });

  testWidgets('omits the bio block when the description is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(LeaderboardUserProfileSheet(userData: userData())),
    );

    expect(find.byType(Text), findsWidgets);
    expect(find.text('حمزة صفوت كامل حسن'), findsOneWidget);
  });
}
