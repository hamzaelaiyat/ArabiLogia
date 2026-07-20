import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/models/account.dart';
import 'package:arabilogia/core/services/accounts_service.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';

class AccountsProvider extends ChangeNotifier {
  final AccountsService _service = AccountsService();
  List<SavedAccount> _accounts = [];
  bool _isLoading = false;

  List<SavedAccount> get accounts => _accounts;
  bool get isLoading => _isLoading;
  bool get hasReachedMax => _accounts.length >= AccountsService.maxAccounts;
  int get remainingSlots => AccountsService.maxAccounts - _accounts.length;

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    _accounts = await _service.getAccounts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveCurrentSession(AuthProvider authProvider) async {
    final session = authProvider.state.session;
    final user = authProvider.state.user;
    if (session == null || user == null) return;

    final sessionJson = jsonEncode(session.toJson());
    final email = user.email ?? '';
    final metadata = user.userMetadata ?? {};
    final fullName = metadata['full_name'] as String? ?? '';
    final username = metadata['username'] as String? ?? '';
    final grade = metadata['grade'] as int? ?? 0;
    final avatarUrl = metadata['avatar_url'] as String?;

    final account = SavedAccount(
      id: user.id,
      email: email,
      fullName: fullName,
      username: username,
      grade: grade,
      avatarUrl: avatarUrl,
      sessionJson: sessionJson,
      savedAt: DateTime.now(),
    );

    await _service.saveAccount(account);
    _accounts = await _service.getAccounts();
    notifyListeners();
  }

  Future<bool> switchToAccount(
    SavedAccount account,
    BuildContext context,
  ) async {
    try {
      await Supabase.instance.client.auth.recoverSession(account.sessionJson);

      _accounts = await _service.getAccounts();
      notifyListeners();
      return true;
    } catch (e) {
      await _service.removeAccount(account.id);
      _accounts = await _service.getAccounts();
      notifyListeners();
      return false;
    }
  }

  Future<void> removeAccount(SavedAccount account) async {
    await _service.removeAccount(account.id);
    _accounts = await _service.getAccounts();
    notifyListeners();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_accounts');
    _accounts = [];
    notifyListeners();
  }
}
