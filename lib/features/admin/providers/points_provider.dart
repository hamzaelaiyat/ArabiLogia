import 'package:flutter/foundation.dart';
import 'package:arabilogia/features/admin/repositories/points_repository.dart';

class PointsProvider extends ChangeNotifier {
  final PointsRepository _repository;

  PointsProvider({PointsRepository? repository})
    : _repository = repository ?? PointsRepository();

  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  int? _selectedGrade;
  String _searchQuery = '';
  String? _error;

  List<Map<String, dynamic>> get students {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) {
      final name = (s['full_name'] as String? ?? '').toLowerCase();
      final username = (s['username'] as String? ?? '').toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();
  }

  bool get isLoading => _isLoading;
  int? get selectedGrade => _selectedGrade;
  String get searchQuery => _searchQuery;
  String? get error => _error;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setGrade(int? grade) {
    _selectedGrade = grade;
    notifyListeners();
  }

  Future<void> loadStudents({int? grade, bool force = false}) async {
    if (_isLoading && !force) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getStudentsWithBalances(grade: grade);
      _students = data;
    } catch (e) {
      _error = e.toString();
      _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> increment(String userId, int amount) async {
    return _mutate(userId, () => _repository.incrementPoints(userId, amount));
  }

  Future<int?> decrement(String userId, int amount) async {
    return _mutate(userId, () => _repository.decrementPoints(userId, amount));
  }

  Future<int?> reset(String userId) async {
    return _mutate(userId, () => _repository.resetPoints(userId));
  }

  Future<int?> _mutate(String userId, Future<int> Function() action) async {
    _error = null;
    try {
      final newBalance = await action();
      _updateLocalBalance(userId, newBalance);
      return newBalance;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _updateLocalBalance(String userId, int newBalance) {
    final idx = _students.indexWhere(
      (s) => s['user_id'] == userId || s['id'] == userId,
    );
    if (idx != -1) {
      _students[idx] = Map<String, dynamic>.from(_students[idx]);
      _students[idx]['total_balance'] = newBalance;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getStudentHistory(String userId) async {
    return _repository.getStudentAdjustments(userId);
  }
}
