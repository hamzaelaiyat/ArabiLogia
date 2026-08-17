import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';

class PointsRepository {
  static final PointsRepository _instance = PointsRepository._internal();
  factory PointsRepository({SupabaseServiceInterface? supabaseService}) =>
      supabaseService != null
          ? PointsRepository._create(supabaseService: supabaseService)
          : _instance;
  PointsRepository._internal()
    : _supabaseService = SupabaseServiceWrapper();
  PointsRepository._create({required SupabaseServiceInterface supabaseService})
    : _supabaseService = supabaseService;

  final SupabaseServiceInterface _supabaseService;

  Future<List<Map<String, dynamic>>> getStudentsWithBalances({
    int? grade,
  }) async {
    final response = await _supabaseService.rpc(
      'get_students_with_balances',
      params: {'p_grade': grade ?? 0},
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<int> incrementPoints(String userId, int amount) async {
    return _adjustPoints(userId, amount, 'increment');
  }

  Future<int> decrementPoints(String userId, int amount) async {
    return _adjustPoints(userId, amount, 'decrement');
  }

  Future<int> resetPoints(String userId) async {
    return _adjustPoints(userId, 0, 'reset');
  }

  Future<int> _adjustPoints(
    String userId,
    int amount,
    String action,
  ) async {
    final response = await _supabaseService.rpc(
      'adjust_student_points',
      params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_action': action,
      },
    ).maybeSingle();

    if (response is Map<String, dynamic>) {
      final balance = response['new_balance'];
      if (balance is int) return balance;
      if (balance is num) return balance.toInt();
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getStudentAdjustments(
    String userId,
  ) async {
    try {
      final response = await _supabaseService
          .from('points_adjustments')
          .select('id, amount, performed_by, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }
}
