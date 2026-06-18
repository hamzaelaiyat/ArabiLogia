import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/core/utils/anonymous_name_generator.dart';
import 'package:arabilogia/core/utils/auth_error_mapper.dart';

class PrivacySection extends StatefulWidget {
  const PrivacySection({super.key});

  @override
  State<PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<PrivacySection> {
  bool _hideAvatar = false;
  bool _hideName = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('hide_avatar, hide_name')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _hideAvatar = profile['hide_avatar'] ?? false;
          _hideName = profile['hide_name'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToDb({
    bool? hideAvatar,
    bool? hideName,
    String? randomName,
  }) async {
    if (!mounted || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.updateProfile(
        hideAvatar: hideAvatar,
        hideName: hideName,
        randomName: randomName,
      );

      if (!mounted) return;

      if (success) {
        // Re-fetch from DB to confirm save took effect
        await _loadProfile();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hideName == true ? 'سيظهر اسم عشوائي في لوحة الصدارة' : 'تم الحفظ'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Rollback local state — error message is shown by authProvider
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getArabicDbError(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Text(
        'الخصوصية',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary),
      ),
    );

    return Column(
      children: [
        header,
        const SizedBox(height: AppTokens.spacing8),
        Card(
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.no_photography_outlined,
                      title: 'إخفاء صورتي في لوحة الصدارة',
                      value: _hideAvatar,
                      enabled: !_isSaving,
                      onChanged: (value) async {
                        setState(() {
                          _hideAvatar = value;
                          if (!value) {
                            _hideName = false;
                          }
                        });
                        if (!value) {
                          await _saveToDb(hideName: false, randomName: null);
                        }
                        await _saveToDb(hideAvatar: value);
                      },
                    ),
                    if (_hideAvatar) ...[
                      const Divider(height: 1),
                      _buildToggleTile(
                        icon: Icons.person_off_outlined,
                        title: 'إخفاء حسابي في لوحة الصدارة',
                        subtitle: 'سيظهر اسم عشوائي بدلاً من اسمك الحقيقي',
                        value: _hideName,
                        enabled: !_isSaving,
                        onChanged: (value) async {
                          if (value) {
                            try {
                              final name = await AnonymousNameGenerator.generate(
                                supabase: Supabase.instance.client,
                              );
                              setState(() => _hideName = true);
                              await _saveToDb(hideName: true, randomName: name);
                            } catch (e) {
                              setState(() => _hideName = false);
                            }
                          } else {
                            setState(() => _hideName = false);
                            await _saveToDb(hideName: false, randomName: null);
                          }
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool> onChanged,
  }) {
    final tileOpacity = enabled ? 1.0 : 0.5;
    return Opacity(
      opacity: tileOpacity,
      child: AbsorbPointer(
        absorbing: !enabled,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: AppTokens.fontSizeMd,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CustomSwitch(value: value, onChanged: onChanged),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeSm,
                            color: AppColors.mutedColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _CustomSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final switchDur = potato.animationsEnabled
        ? AppTokens.durationSm
        : Duration.zero;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: switchDur,
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: value ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: switchDur,
              left: value ? 26 : 4,
              top: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
