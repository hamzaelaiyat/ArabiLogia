import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/config/supabase_config.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/utils/auth_error_mapper.dart';

class AvatarUploadResult {
  final String? avatarUrl;
  final bool accepted;
  final bool rejected;
  final String? error;
  final String? code;
  const AvatarUploadResult({
    this.avatarUrl,
    this.accepted = false,
    this.rejected = false,
    this.error,
    this.code,
  });
}

class RemoveAvatarResult {
  final bool success;
  final User? user;
  final String? error;
  const RemoveAvatarResult({
    required this.success,
    this.user,
    this.error,
  });
}

class AvatarService {
  final SupabaseServiceInterface _supabase;
  final http.Client _httpClient;

  AvatarService(this._supabase, this._httpClient);

  Future<AvatarUploadResult> uploadAvatar(Uint8List bytes) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return const AvatarUploadResult(
        error: 'غير مصرح به',
        code: 'UNAUTHORIZED',
      );
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(SupabaseConfig.edgeFunctionUrl),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'accepted') {
        return AvatarUploadResult(
          avatarUrl: data['avatarUrl'] as String?,
          accepted: true,
        );
      } else if (response.statusCode == 200 && data['status'] == 'rejected') {
        return const AvatarUploadResult(rejected: true);
      }

      return AvatarUploadResult(
        error: data['error'] as String? ?? 'خطأ في رفع الصورة',
        code: 'UPLOAD_ERROR',
      );
    } on http.ClientException {
      return const AvatarUploadResult(
        error: 'تعذر الاتصال بالخادم',
        code: 'NETWORK_ERROR',
      );
    } catch (e) {
      return const AvatarUploadResult(
        error: 'حدث خطأ في رفع الصورة',
        code: 'UPLOAD_ERROR',
      );
    }
  }

  Future<RemoveAvatarResult> removeAvatar(String userId) async {
    try {
      await _supabase.client
          .from('profiles')
          .update({
            'avatar_url': null,
            'avatar_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      final response =
          await _supabase.auth.updateUser(UserAttributes(data: {
        'avatar_url': null,
        'avatar_updated_at': DateTime.now().toIso8601String(),
      }));

      return RemoveAvatarResult(success: true, user: response.user);
    } on PostgrestException catch (e) {
      final errorMsg = getArabicDbError('${e.code} ${e.message}');
      return RemoveAvatarResult(success: false, error: errorMsg);
    } on AuthException catch (e) {
      return RemoveAvatarResult(
        success: false,
        error: getArabicAuthError(e.message),
      );
    } catch (e) {
      return const RemoveAvatarResult(
        success: false,
        error: 'حدث خطأ في إزالة الصورة',
      );
    }
  }
}
