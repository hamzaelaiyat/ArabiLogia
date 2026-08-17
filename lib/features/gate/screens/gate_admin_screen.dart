import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import '../models/gate_status.dart';
import '../repositories/gate_repository.dart';

/// PRIVATE dev-only gate administration screen.
/// Sets/rotates the gate passcode and attaches exams to the catalog.
class GateAdminScreen extends StatefulWidget {
  const GateAdminScreen({super.key});

  @override
  State<GateAdminScreen> createState() => _GateAdminScreenState();
}

class _GateAdminScreenState extends State<GateAdminScreen> {
  final GateRepository _repo = GateRepository();
  final TextEditingController _passcodeController = TextEditingController();

  static const List<int> _grades = [1, 2, 3];
  int _selectedGrade = 2;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  GateAdminStatus? _status;
  List<Map<String, dynamic>> _exams = [];
  final Set<String> _selectedExamIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  bool get _isAdminish {
    final role = context.read<AuthProvider>().role;
    return role == 'teacher' || role == 'admin' || role == 'dev';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final status = await _repo.adminStatus(_selectedGrade);
      final exams = await _repo.listAllExams();
      if (!mounted) return;
      setState(() {
        _status = status;
        _exams = exams;
        _selectedExamIds
          ..clear()
          ..addAll(status.examIds);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'تعذر تحميل إعدادات البوابة';
      });
    }
  }

  Future<void> _savePasscode() async {
    final code = _passcodeController.text.trim();
    if (code.length < 4) {
      _showSnack('كلمة المرور قصيرة جداً (4 أحرف على الأقل)');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.setPasscode(_selectedGrade, code);
      _passcodeController.clear();
      if (!mounted) return;
      _showSnack('تم تحديث كلمة المرور');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('فشل تحديث كلمة المرور');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveExams() async {
    setState(() => _saving = true);
    try {
      await _repo.setExams(_selectedGrade, _selectedExamIds.toList());
      if (!mounted) return;
      _showSnack('تم حفظ الامتحانات');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('فشل حفظ الامتحانات');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة البوابة'), centerTitle: true),
        body: auth.role != null && !_isAdminish
            ? const Center(child: Text('غير مصرح لك'))
            : _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final status = _status;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('الصف الدراسي:'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _selectedGrade,
                items: [
                  for (final g in _grades)
                    DropdownMenuItem(value: g, child: Text('الصف $g')),
                ],
                onChanged: (g) {
                  if (g == null) return;
                  setState(() => _selectedGrade = g);
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كلمة المرور', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    status?.hasPasscode == true
                        ? 'الحالة: مفعّلة'
                        : 'الحالة: غير مفعّلة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: status?.hasPasscode == true
                          ? Colors.green.shade700
                          : theme.colorScheme.error,
                    ),
                  ),
                  if (status?.expiresAt != null)
                    Text(
                      'تنتهي في: ${_formatDate(status!.expiresAt!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passcodeController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة مرور جديدة (4+ أحرف)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _savePasscode,
                      child: Text(
                        _saving ? 'جارٍ الحفظ...' : 'تحديث كلمة المرور',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('امتحانات البوابة', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'اختر الامتحانات المتاحة لهذا الصف',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (_exams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('لا توجد امتحانات في قاعدة البيانات'),
                    )
                  else
                    for (final exam in _exams)
                      CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          exam['title'] as String? ?? 'بدون عنوان',
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('الصف ${exam['grade']}'),
                        value: _selectedExamIds.contains(exam['id']),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedExamIds.add(exam['id'] as String);
                            } else {
                              _selectedExamIds.remove(exam['id']);
                            }
                          });
                        },
                      ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _saveExams,
                      child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الامتحانات'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
