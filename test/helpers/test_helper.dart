import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:mocktail/mocktail.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:supabase_flutter/supabase_flutter.dart';
export 'package:arabilogia/core/services/supabase_service_interface.dart';

class MockSupabaseService extends Mock implements SupabaseServiceInterface {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void setUpMockAuthClient(MockGoTrueClient mockAuth) {
  when(() => mockAuth.currentUser).thenReturn(null);
  when(() => mockAuth.currentSession).thenReturn(null);
}

Map<String, dynamic> createTestExamData({
  String id = 'exam_1',
  String title = 'Test Exam',
  String subjectId = 'subject_1',
  int grade = 1,
  int durationMinutes = 30,
}) {
  return {
    'id': id,
    'title': title,
    'subject_id': subjectId,
    'grade': grade,
    'duration_minutes': durationMinutes,
    'data': {
      'id': id,
      't': title,
      's': subjectId,
      'g': grade,
      'd': durationMinutes,
      'q': [],
      'p': 1,
    },
  };
}

Map<String, dynamic> createTestScoreData({
  String examId = 'exam_1',
  double score = 85.0,
  int points = 10,
  String userId = 'user_1',
  String status = 'completed',
}) {
  return {
    'exam_id': examId,
    'score': score,
    'points': points,
    'user_id': userId,
    'status': status,
    'subject': 'subject_1',
    'wrong_mask': 0,
    'created_at': DateTime.now().toIso8601String(),
  };
}
