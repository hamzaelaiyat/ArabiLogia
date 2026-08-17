import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/lecture_sub_sidebar.dart';

class LectureEditorDesktopLayout extends StatelessWidget {
  final bool isDark;
  final int activeSidebarIndex;
  final ValueChanged<int> onSidebarIndexChanged;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback onExit;
  final Widget Function() buildContentTab;
  final Widget Function() buildExamsTab;
  final Widget Function() buildSettingsTab;

  const LectureEditorDesktopLayout({
    super.key,
    required this.isDark,
    required this.activeSidebarIndex,
    required this.onSidebarIndexChanged,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onExit,
    required this.buildContentTab,
    required this.buildExamsTab,
    required this.buildSettingsTab,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 400,
          color: isDark ? const Color(0xFF191B1D) : const Color(0xFFF7FCFF),
          child: Row(
            children: [
              LectureSubSidebar(
                activeIndex: activeSidebarIndex,
                onIndexChanged: onSidebarIndexChanged,
                onSave: onSaveDraft,
                onPublish: onPublish,
                onExit: onExit,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: context.watch<PotatoModeProvider>().animationsEnabled
                      ? AppTokens.durationFast
                      : Duration.zero,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    );
                  },
                  child: activeSidebarIndex == 0
                      ? SettingsPanelWrapper(
                          key: const ValueKey('settings'),
                          builder: buildSettingsTab,
                        )
                      : ExamsPanelWrapper(
                          key: const ValueKey('exams'),
                          builder: buildExamsTab,
                        ),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        Expanded(
          flex: 3,
          child: buildContentTab(),
        ),
      ],
    );
  }
}

class SettingsPanelWrapper extends StatelessWidget {
  final Widget Function() builder;

  const SettingsPanelWrapper({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}

class ExamsPanelWrapper extends StatelessWidget {
  final Widget Function() builder;

  const ExamsPanelWrapper({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}
