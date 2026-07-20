import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:arabilogia/core/services/avatar_service.dart';
import 'package:arabilogia/core/services/profile_service.dart';

class AvatarProvider extends ChangeNotifier {
  final AvatarService _avatarService;
  final ProfileService _profileService;
  GoTrueClient? _auth;

  int _imageViolationCount = 0;
  DateTime? _imageBlockedUntil;
  bool _hasBadTag = false;

  bool get canUploadAvatar =>
      !_hasBadTag &&
      (_imageBlockedUntil == null ||
          _imageBlockedUntil!.isBefore(DateTime.now()));
  int get imageViolationCount => _imageViolationCount;
  DateTime? get imageBlockedUntil => _imageBlockedUntil;
  bool get hasBadTag => _hasBadTag;

  AvatarProvider({
    required AvatarService avatarService,
    required ProfileService profileService,
    GoTrueClient? auth,
  })  : _avatarService = avatarService,
        _profileService = profileService,
        _auth = auth;

  set auth(GoTrueClient? value) => _auth = value;

  Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes) async {
    final session = _auth?.currentSession;
    if (session == null) {
      return {'error': 'غير مصرح به', 'code': 'UNAUTHORIZED'};
    }

    final result = await _avatarService.uploadAvatar(bytes);

    if (result.accepted || result.rejected) {
      await _loadViolationState();
    }

    if (result.accepted) {
      return {'status': 'accepted', 'avatarUrl': result.avatarUrl};
    } else if (result.rejected) {
      return {'status': 'rejected'};
    }
    return {'error': result.error, 'code': result.code ?? 'ERROR'};
  }

  Future<bool> removeAvatar() async {
    try {
      final result = await _avatarService.removeAvatar(
        _auth!.currentUser!.id,
      );
      return result.success;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadViolationState() async {
    final state = await _profileService.loadViolationState();
    _imageViolationCount = state.imageViolationCount;
    _imageBlockedUntil = state.imageBlockedUntil;
    _hasBadTag = state.hasBadTag;
    notifyListeners();
  }

  Future<void> initialize() async {
    await _loadViolationState();
  }
}
