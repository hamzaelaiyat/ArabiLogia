import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';

class LeaderboardRepository {
  static final LeaderboardRepository _instance = LeaderboardRepository._internal();
  factory LeaderboardRepository({
    SupabaseServiceInterface? supabaseService,
  }) => supabaseService != null
      ? LeaderboardRepository._create(supabaseService: supabaseService)
      : _instance;
  LeaderboardRepository._internal()
    : _supabaseService = SupabaseServiceWrapper();
  LeaderboardRepository._create({
    required SupabaseServiceInterface supabaseService,
  }) : _supabaseService = supabaseService;

  final SupabaseServiceInterface _supabaseService;

  Future<List<Map<String, dynamic>>> getLeaderboard({
    int? grade,
    String period = 'all',
  }) async {
    try {
      var query = _supabaseService.rpc(
        'get_leaderboard_by_period',
        params: {'period_filter': period},
      );

      if (grade != null && grade != 0) {
        query = query.eq('grade', grade);
      }

      final response = await query
          .order('total_score', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabaseService
          .rpc('get_leaderboard_by_period', params: {'period_filter': 'all'})
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getDetailedProfileStats() async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return {};

    final basicStats = await getUserStats();

    final recentExamResponse = await _supabaseService
        .from('exam_results')
        .select('subject, score, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    Map<String, dynamic>? lastExam;
    if (recentExamResponse.isNotEmpty) {
      lastExam = Map<String, dynamic>.from(recentExamResponse.first);
    }

    return {
      'exams_completed': basicStats?['exams_completed'] ?? 0,
      'avg_score': basicStats?['avg_score'] ?? 0.0,
      'total_score': basicStats?['total_score'] ?? 0,
      'rank': basicStats?['rank'] ?? 0,
      'last_exam': lastExam,
    };
  }
}
