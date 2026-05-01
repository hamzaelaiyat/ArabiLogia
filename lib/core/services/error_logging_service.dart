import 'package:flutter/foundation.dart';
import 'package:arabilogia/core/services/supabase_service.dart';

class ErrorLoggingService {
  ErrorLoggingService._();
  static final ErrorLoggingService instance = ErrorLoggingService._();

  /// Log an error to the Issues table in Supabase
  Future<void> logError({
    required String errorMessage,
    String? errorType,
    String? stackTrace,
    String? deviceInfo,
    String? appVersion,
    String? context,
  }) async {
    try {
      final userId = SupabaseService.instance.userId;

      await SupabaseService.instance.client.from('issues').insert({
        'user_id': userId,
        'error_message': context != null
            ? '[$context] $errorMessage'
            : errorMessage,
        'error_type': errorType,
        'stack_trace': stackTrace,
        'device_info': deviceInfo ?? _getDeviceInfo(),
        'app_version': appVersion ?? _getAppVersion(),
      });

      debugPrint('Error logged to Supabase: $errorMessage');
    } catch (e) {
      debugPrint('Failed to log error to Supabase: $e');
    }
  }

  /// Log a caught exception
  Future<void> logException(
    Object error, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    final errorMessage = error.toString();
    String? stackTrace;

    if (error is Error) {
      stackTrace = error.stackTrace?.toString();
    }

    await logError(
      errorMessage: errorMessage,
      errorType: error.runtimeType.toString(),
      stackTrace: stackTrace,
      deviceInfo: _getDeviceInfo(),
      appVersion: _getAppVersion(),
    );
  }

  String _getDeviceInfo() {
    // You can add more device info here
    return 'Platform: ${defaultTargetPlatform.name}';
  }

  String _getAppVersion() {
    // You can get the actual app version from pubspec.yaml or a config
    return 'ArabiLogia v1.0.0';
  }
}
