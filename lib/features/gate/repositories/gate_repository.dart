import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:flutter/foundation.dart';
import '../models/gate_status.dart';

class GateRepository {
  static final GateRepository _instance = GateRepository._internal();
  factory GateRepository({SupabaseServiceInterface? supabaseService}) =>
      supabaseService != null
      ? GateRepository._create(supabaseService)
      : _instance;
  GateRepository._internal() : _supabaseService = SupabaseServiceWrapper();
  GateRepository._create(SupabaseServiceInterface supabaseService)
    : _supabaseService = supabaseService;

  final SupabaseServiceInterface _supabaseService;

  Future<GateStatus> status(int grade) async {
    final res = await _supabaseService.rpc(
      'gate_status',
      params: {'p_grade': grade},
    );
    if (res is! Map) {
      throw const FormatException('gate_status returned non-object');
    }
    return GateStatus.fromJson(Map<String, dynamic>.from(res));
  }

  Future<GateAdminStatus> adminStatus(int grade) async {
    final res = await _supabaseService.rpc(
      'gate_admin_status',
      params: {'p_grade': grade},
    );
    if (res is! Map) {
      throw const FormatException('gate_admin_status returned non-object');
    }
    return GateAdminStatus.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> setPasscode(
    int grade,
    String code, {
    DateTime? expiresAt,
  }) async {
    await _supabaseService.rpc(
      'gate_set_passcode',
      params: {
        'p_grade': grade,
        'p_code': code,
        'p_expires_at': expiresAt?.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> setExams(int grade, List<String> examIds) async {
    await _supabaseService.rpc(
      'gate_set_exams',
      params: {'p_grade': grade, 'p_exam_ids': examIds},
    );
  }

  Future<List<Map<String, dynamic>>> listAllExams() async {
    try {
      final res = await _supabaseService
          .from('exams')
          .select('id, title, subject_id, grade, created_at')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('GateRepository.listAllExams error: $e');
      return [];
    }
  }

  Future<void> unlock(int grade, String code) async {
    try {
      await _supabaseService.rpc(
        'gate_unlock',
        params: {'p_grade': grade, 'p_code': code},
      );
    } catch (e) {
      // Surface Supabase RPC errors as-is; UI shows friendly text.
      rethrow;
    }
  }

  Future<void> clearUnlock(int grade) async {
    await _supabaseService.rpc('gate_clear_unlock', params: {'p_grade': grade});
  }

  Future<GateExamList> listExams() async {
    final res = await _supabaseService.rpc('gate_list_exams');
    if (res is! Map) {
      throw const FormatException('gate_list_exams returned non-object');
    }
    return GateExamList.fromJson(Map<String, dynamic>.from(res));
  }

  Future<int?> currentGrade() async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return null;
    try {
      final res = await _supabaseService
          .from('profiles')
          .select('grade')
          .eq('id', user.id)
          .maybeSingle();
      if (res == null) return null;
      return res['grade'] as int?;
    } catch (e) {
      debugPrint('GateRepository.currentGrade error: $e');
      return null;
    }
  }

  Future<String?> categoryName(String id) async {
    try {
      final res = await _supabaseService
          .from('categories')
          .select('name')
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      return res['name'] as String?;
    } catch (e) {
      debugPrint('GateRepository.categoryName error: $e');
      return null;
    }
  }
}
