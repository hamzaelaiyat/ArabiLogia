import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:arabilogia/core/services/profile_service.dart';
import 'package:arabilogia/features/auth/providers/auth_state.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;
  GoTrueClient? _auth;

  String? _role;

  bool get isTeacher {
    final effectiveRole = _role;
    return effectiveRole == 'teacher' || effectiveRole == 'admin';
  }

  bool get isAdmin {
    final effectiveRole = _role;
    return effectiveRole == 'admin';
  }

  ProfileProvider({
    required ProfileService profileService,
    GoTrueClient? auth,
  })  : _profileService = profileService,
        _auth = auth;

  set auth(GoTrueClient? value) => _auth = value;

  void setRoleFromUser(User? user) {
    _role = user?.userMetadata?['role'] as String?;
  }

  Future<bool> updateProfile({
    required AuthState currentState,
    String? fullName,
    String? username,
    String? avatarUrl,
    int? grade,
    String? description,
    bool? isPublic,
    bool? hideAvatar,
    bool? hideName,
    String? randomName,
    Map<String, bool>? notifications,
  }) async {
    final result = await _profileService.updateProfile(
      userId: _auth!.currentUser!.id,
      fullName: fullName,
      username: username,
      avatarUrl: avatarUrl,
      grade: grade,
      description: description,
      isPublic: isPublic,
      hideAvatar: hideAvatar,
      hideName: hideName,
      randomName: randomName,
      notifications: notifications,
    );

    return result.success;
  }

  Future<String?> getUserRole() async {
    return _profileService.getUserRole();
  }

  Future<void> syncRoleFromDb() async {
    _role = await _profileService.getUserRole();
    notifyListeners();
  }
}
