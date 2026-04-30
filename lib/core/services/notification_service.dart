import 'dart:async';
import 'dart:js' as js;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing push notifications via OneSignal on web platform
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;
  String? _subscriptionId;

  /// Initialize OneSignal for web platform
  /// This should be called after the app initializes
  Future<void> initializeWeb() async {
    if (!_isWeb) return;

    try {
      // Wait for OneSignal to be ready
      await _waitForOneSignal();

      // Check if already subscribed
      await _checkExistingSubscription();
    } catch (e) {
      print('OneSignal initialization error: $e');
    }
  }

  Future<void> _waitForOneSignal() async {
    // Wait for OneSignal SDK to load (max 5 seconds)
    int attempts = 0;
    while (attempts < 50) {
      final window = js.context['window'];
      if (window != null && window['OneSignal'] != null) {
        final OneSignal = window['OneSignal'];
        if (OneSignal['DeferredPush'] != null) {
          await OneSignal['DeferredPush'].then((os) async {
            await os.init();
          });
          return;
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<void> _checkExistingSubscription() async {
    try {
      final window = js.context['window'];
      if (window != null && window['OneSignal'] != null) {
        final OneSignal = window['OneSignal'];
        if (OneSignal != null) {
          final state = await OneSignal['DeferredPush'].then(
            (os) => os.getPermissionNativeState(),
          );
          if (state == 1) {
            // Granted
            final id = await OneSignal['DeferredPush'].then(
              (os) => os.getPushSubscriptionId(),
            );
            if (id != null) {
              _subscriptionId = id;
              await _saveSubscriptionToDb(id);
            }
          }
        }
      }
    } catch (e) {
      print('Error checking subscription: $e');
    }
  }

  /// Subscribe user to push notifications
  /// Returns true if subscription was successful
  Future<bool> subscribeToNotifications() async {
    if (!_isWeb) return false;

    try {
      final window = js.context['window'];
      if (window == null || window['OneSignal'] == null) {
        print('OneSignal not loaded yet');
        return false;
      }

      final OneSignal = window['OneSignal'];
      final os = await OneSignal['DeferredPush'];
      await os.requestPermission();

      final id = await os.getPushSubscriptionId();
      if (id != null) {
        _subscriptionId = id;
        await _saveSubscriptionToDb(id);
        return true;
      }
      return false;
    } catch (e) {
      print('Error subscribing to notifications: $e');
      return false;
    }
  }

  /// Unsubscribe from push notifications
  Future<void> unsubscribeFromNotifications() async {
    if (!_isWeb) return;

    try {
      final window = js.context['window'];
      if (window != null && window['OneSignal'] != null) {
        final OneSignal = window['OneSignal'];
        final os = await OneSignal['DeferredPush'];
        await os.optOut();
        _subscriptionId = null;
        await _removeSubscriptionFromDb();
      }
    } catch (e) {
      print('Error unsubscribing from notifications: $e');
    }
  }

  /// Check if user is subscribed to notifications
  Future<bool> isSubscribed() async {
    if (!_isWeb) return false;

    try {
      final window = js.context['window'];
      if (window == null || window['OneSignal'] == null) return false;

      final OneSignal = window['OneSignal'];
      final os = await OneSignal['DeferredPush'];
      final state = await os.getPermissionNativeState();
      return state == 1;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveSubscriptionToDb(String subscriptionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'onesignal_subscription_id': subscriptionId})
          .eq('id', user.id);
    } catch (e) {
      print('Error saving subscription to DB: $e');
    }
  }

  Future<void> _removeSubscriptionFromDb() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'onesignal_subscription_id': null})
          .eq('id', user.id);
    } catch (e) {
      print('Error removing subscription from DB: $e');
    }
  }

  /// Get the current subscription ID
  String? get subscriptionId => _subscriptionId;
}

/// Check if running on web platform
bool get _isWeb => identical(1, 1.0);
