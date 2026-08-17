import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import '../models/gate_status.dart';
import '../repositories/gate_repository.dart';
import '../widgets/passcode_form.dart';

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  final GateRepository _repo = GateRepository();
  bool _loading = true;
  int? _grade;
  GateStatus? _status;
  GateExamList? _list;
  String? _loadError;
  final Map<String, String> _subjectNames = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Wait for AuthProvider to finish restoring the Supabase session so
    // grade lookups don't race the auth boot (cold deep-link to /gate).
    final auth = context.read<AuthProvider>();
    if (!auth.isInitialized) {
      await auth.whenInitialized();
    }
    if (!mounted) return;
    if (!auth.state.isAuthenticated) {
      // Session didn't restore. Let the router redirect handle login.
      if (mounted) context.goNamed('login');
      return;
    }
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final grade = await _repo.currentGrade();
      if (grade == null) {
        setState(() {
          _loading = false;
          _loadError = 'لم يتم العثور على صف دراسي';
        });
        return;
      }
      final status = await _repo.status(grade);
      GateExamList? list;
      if (status.unlocked) {
        list = await _repo.listExams();
        for (final item in list.items) {
          if (!_subjectNames.containsKey(item.subjectId)) {
            final name = await _repo.categoryName(item.subjectId);
            _subjectNames[item.subjectId] = name ?? item.subjectId;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _grade = grade;
        _status = status;
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'تعذر تحميل البوابة';
      });
    }
  }

  Future<void> _onUnlock(String code) async {
    final grade = _grade;
    if (grade == null) return;
    await _repo.unlock(grade, code);
    await _refresh();
  }

  Future<void> _onLock() async {
    final grade = _grade;
    if (grade == null) return;
    await _repo.clearUnlock(grade);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdminish = auth.isInitialized &&
        (auth.role == 'teacher' || auth.role == 'admin' || auth.role == 'dev');
    return Scaffold(
      appBar: AppBar(
        title: const Text('البوابة'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.goNamed('home'),
        ),
        actions: [
          if (isAdminish)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'إدارة البوابة',
              onPressed: () => context.pushNamed('gate-admin'),
            ),
          if (_status?.unlocked == true)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: 'إغلاق البوابة',
              onPressed: _loading ? null : _onLock,
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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
            FilledButton(
              onPressed: _refresh,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    final status = _status;
    if (status == null || _grade == null) {
      return const SizedBox.shrink();
    }
    if (!status.hasPasscode) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لم يتم تفعيل البوابة لصفك بعد.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!status.unlocked) {
      return PasscodeForm(
        grade: _grade!,
        rotated: status.rotated,
        onSubmit: _onUnlock,
        onCancel: () => context.goNamed('home'),
      );
    }
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final list = _list;
    if (list == null || list.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا توجد امتحانات متاحة في البوابة حالياً.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = list.items[index];
          final subject = _subjectNames[item.subjectId] ?? item.subjectId;
          return _GateExamCard(
            title: item.title,
            subject: subject,
            durationMinutes: item.durationMinutes ?? 30,
            onTap: () => context.pushNamed(
              'exam-interaction',
              pathParameters: {'id': item.id},
              extra: {'subjectId': item.subjectId, 'subjectName': subject},
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: list.items.length,
      ),
    );
  }
}

class _GateExamCard extends StatelessWidget {
  final String title;
  final String subject;
  final int durationMinutes;
  final VoidCallback onTap;

  const _GateExamCard({
    required this.title,
    required this.subject,
    required this.durationMinutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Icon(
                  Icons.lock_open,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text('$durationMinutes د'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
