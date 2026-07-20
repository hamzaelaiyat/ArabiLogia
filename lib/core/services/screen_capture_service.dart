import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenCaptureService {
  static const _channel = MethodChannel('com.arabilogia.app/secure');
  static final ScreenCaptureService _instance = ScreenCaptureService._();
  factory ScreenCaptureService() => _instance;

  final ValueNotifier<bool> isCaptured = ValueNotifier(false);
  bool _isEnabled = false;

  ScreenCaptureService._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> enableSecureMode() async {
    if (_isEnabled) return;
    _isEnabled = true;
    try {
      await _channel.invokeMethod('enableSecure');
    } on MissingPluginException {
      // Native channel not available (e.g. web/desktop)
    }
  }

  Future<void> disableSecureMode() async {
    if (!_isEnabled) return;
    _isEnabled = false;
    isCaptured.value = false;
    try {
      await _channel.invokeMethod('disableSecure');
    } on MissingPluginException {
      // Native channel not available (e.g. web/desktop)
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onCaptureStateChanged') {
      isCaptured.value = call.arguments['isCaptured'] ?? false;
    }
  }
}
