import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/features/dashboard/leaderboard/widgets/leaderboard_rank_card.dart';

Map<String, dynamic> _leader({
  String id = 'u1',
  String name = 'طالب',
  int score = 100,
  int rank = 1,
}) {
  return {
    'full_name': name,
    'user_id': id,
    'total_score': score,
    'rank': rank,
    'grade': 10,
    'has_bad_tag': false,
  };
}

Widget buildCard({
  int rank = 1,
  bool isMe = false,
  bool isTopThree = true,
  Map<String, dynamic> leader = const {},
  String gradeName = 'الأولى باكالوريا',
  String avatarLetters = 'ك',
}) {
  return MaterialApp(
    home: Scaffold(
      body: LeaderboardRankCard(
        leader: leader.isNotEmpty ? leader : _leader(rank: rank),
        isMe: isMe,
        rank: rank,
        isTopThree: isTopThree,
        gradeName: gradeName,
        avatarLetters: avatarLetters,
      ),
    ),
  );
}

void main() {
  testWidgets('shows rank number', (tester) async {
    await tester.pumpWidget(buildCard(rank: 5));
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('shows avatar letters (first character only)', (tester) async {
    await tester.pumpWidget(buildCard(avatarLetters: 'ك'));
    expect(find.text('ك'), findsOneWidget);
  });

  testWidgets('shows full name from leader data', (tester) async {
    await tester.pumpWidget(buildCard(
      leader: _leader(name: 'كريم سيد'),
    ));
    expect(find.text('كريم سيد'), findsOneWidget);
  });

  testWidgets('shows grade name', (tester) async {
    await tester.pumpWidget(buildCard(gradeName: 'الثالثة ثانوي'));
    expect(find.text('الثالثة ثانوي'), findsOneWidget);
  });

  testWidgets('shows total score', (tester) async {
    await tester.pumpWidget(buildCard(
      leader: _leader(score: 250),
    ));
    expect(find.text('250'), findsOneWidget);
  });

  testWidgets('shows أنت badge for current user', (tester) async {
    await tester.pumpWidget(buildCard(
      isMe: true,
      leader: _leader(id: 'me', name: 'أنا'),
    ));
    expect(find.text('أنت'), findsOneWidget);
  });

  testWidgets('does not show أنت badge for other users', (tester) async {
    await tester.pumpWidget(buildCard(
      isMe: false,
      leader: _leader(id: 'u2', name: 'غيري'),
    ));
    expect(find.text('أنت'), findsNothing);
  });

  testWidgets('shows trophy for rank 1', (tester) async {
    await tester.pumpWidget(buildCard(
      rank: 1,
      leader: _leader(score: 999),
    ));
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('no trophy for rank 2', (tester) async {
    await tester.pumpWidget(buildCard(
      rank: 2,
      leader: _leader(score: 500),
    ));
    expect(find.byIcon(Icons.emoji_events), findsNothing);
  });
}
