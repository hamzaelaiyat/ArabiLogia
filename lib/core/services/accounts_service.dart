import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/models/account.dart';

class AccountsService {
  static const String _key = 'saved_accounts';
  static const int maxAccounts = 8;

  Future<List<SavedAccount>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => SavedAccount.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAccount(SavedAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.insert(0, account);
      if (accounts.length > maxAccounts) {
        accounts.removeLast();
      }
    }
    await prefs.setString(_key, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  Future<void> removeAccount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == id);
    await prefs.setString(_key, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  Future<void> updateAccount(SavedAccount account) async {
    await saveAccount(account);
  }

  Future<bool> hasReachedMax() async {
    final accounts = await getAccounts();
    return accounts.length >= maxAccounts;
  }

  Future<int> accountCount() async {
    final accounts = await getAccounts();
    return accounts.length;
  }
}
