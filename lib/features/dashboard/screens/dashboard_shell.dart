import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/app_version.dart';
import 'package:arabilogia/features/legal/widgets/legal_bottom_sheet.dart';
import 'package:arabilogia/features/dashboard/widgets/dashboard_bottom_nav_bar.dart';
import 'package:arabilogia/features/dashboard/widgets/dashboard_sidebar.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/lecture_sidebar.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_sidebar.dart';
import 'package:arabilogia/providers/contextual_sidebar_provider.dart';
import 'package:arabilogia/features/dashboard/exams/providers/exam_provider.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  double _sidebarWidth = 240.0;
  bool _isPinned = true;
  bool _isHoveringEdge = false;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.lectures) ||
        location.startsWith(AppRoutes.lecturePattern) ||
        location.startsWith(AppRoutes.exams)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.leaderboard)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'الرئيسية';
      case 1:
        return 'المحاضرات';
      case 2:
        return 'لوحة المتصدرين';
      case 3:
        return 'الملف الشخصي';
      case 4:
        return 'الإعدادات';
      default:
        return 'الرئيسية';
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    if (_calculateSelectedIndex(context) == index) return;

    final examProvider = context.read<ExamProvider>();
    if (examProvider.isExamInProgress) {
      _showExitConfirmation(context, index);
      return;
    }

    _navigate(context, index);
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.lectures);
        break;
      case 2:
        context.go(AppRoutes.leaderboard);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  void _showExitConfirmation(BuildContext context, int index) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.push(
      DialogRoute(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('هل أنت متأكد من الخروج؟'),
            content: const Text(
              'أنت حالياً في منتصف اختبار. إذا خرجت الآن، ستفقد جميع إجاباتك ولن يتم احتساب درجتك.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<ExamProvider>().endExam();
                  _navigate(context, index);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('خروج وإلغاء الاختبار'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppTokens.isDesktop(context);
    final selectedIndex = _calculateSelectedIndex(context);

    if (isDesktop) {
      return _buildDesktopLayout(context, selectedIndex);
    } else {
      return _buildMobileLayout(context, selectedIndex);
    }
  }

  Widget _buildMobileLayout(BuildContext context, int selectedIndex) {
    final potato = context.watch<PotatoModeProvider>();
    final sidebarProvider = context.watch<ContextualSidebarProvider>();
    final examProvider = context.watch<ExamProvider>();
    final routerState = GoRouterState.of(context);
    final uriPath = routerState.uri.path;
    final matchedLocation = routerState.matchedLocation;
    
    final isExamOrQuizRoute = (uriPath.startsWith('/exam') && uriPath != AppRoutes.exams) ||
        (matchedLocation.startsWith('/exam') && matchedLocation != AppRoutes.exams) ||
        uriPath.contains('practice') ||
        uriPath.contains('quiz') ||
        matchedLocation.contains('practice') ||
        matchedLocation.contains('quiz') ||
        uriPath == AppRoutes.practiceResult ||
        uriPath == AppRoutes.examResult;

    final hideNav = isExamOrQuizRoute ||
        examProvider.isExamInProgress ||
        sidebarProvider.shouldHideBottomNav;

    final backgroundColor = potato.blurEffectsEnabled
        ? AppColors.background(context).withValues(alpha: 0.7)
        : AppColors.background(context);

    final navWidget = potato.blurEffectsEnabled
        ? ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DashboardBottomNavBar(
                selectedIndex: selectedIndex,
                onDestinationSelected:
                    (index) => _onItemTapped(context, index),
                backgroundColor: backgroundColor,
              ),
            ),
          )
        : DashboardBottomNavBar(
            selectedIndex: selectedIndex,
            onDestinationSelected:
                (index) => _onItemTapped(context, index),
            backgroundColor: backgroundColor,
          );

    return Scaffold(
      key: TestKeys.dashboardShell,
      extendBody: !hideNav,
      body: childWidgetCard(context, widget.child, hideNav: hideNav),
      bottomNavigationBar: hideNav ? null : navWidget,
    );
  }

  Widget childWidgetCard(BuildContext context, Widget child, {bool hideNav = false}) {
    final cardBgColor = AppColors.dashboardContentBackground(context);
    final isMobile = AppTokens.isMobile(context);
    final padding = hideNav && isMobile
        ? const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 0.0)
        : const EdgeInsets.all(12.0);

    return Container(
      color: AppColors.background(context),
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, int selectedIndex) {
    final auth = context.watch<AuthProvider>();
    final sidebarProvider = context.watch<ContextualSidebarProvider>();
    final version = kIsWeb ? '' : AppVersion.displayVersion;
    final totalWidth = MediaQuery.of(context).size.width;
    final maxAllowedWidth = totalWidth * 0.40;

    final cardBgColor = AppColors.dashboardContentBackground(context);
    final outerBgColor = AppColors.background(context);

    final routerState = GoRouterState.of(context);
    final uriPath = routerState.uri.path;
    final matchedLocation = routerState.matchedLocation;

    final isLectureDetailRoute = (uriPath.startsWith('/lecture/') && !uriPath.endsWith('/practice')) ||
        (matchedLocation.startsWith('/lecture/') && !matchedLocation.endsWith('/practice'));

    final isExamOrQuizRoute = (uriPath.startsWith('/exam') && uriPath != AppRoutes.exams) ||
        (matchedLocation.startsWith('/exam') && matchedLocation != AppRoutes.exams) ||
        uriPath.contains('practice') ||
        uriPath.contains('quiz') ||
        matchedLocation.contains('practice') ||
        matchedLocation.contains('quiz') ||
        uriPath == AppRoutes.practiceResult ||
        uriPath == AppRoutes.examResult;

    Widget buildSidebarWidget() {
      if (isLectureDetailRoute &&
          sidebarProvider.mode == SidebarMode.lectureToc &&
          sidebarProvider.lectureData != null) {
        return LectureSidebar(
          data: sidebarProvider.lectureData!,
          width: _sidebarWidth,
        );
      }
      if (isExamOrQuizRoute &&
          sidebarProvider.mode == SidebarMode.examNavigation &&
          sidebarProvider.examData != null) {
        return ExamSidebar(
          data: sidebarProvider.examData!,
          width: _sidebarWidth,
        );
      }

      return DashboardSidebar(
        selectedIndex: selectedIndex,
        onItemTapped: (index) => _onItemTapped(context, index),
        isTeacher: auth.isTeacher,
        isAdmin: auth.isAdmin,
        onTeacherPanelTap: () => context.push(AppRoutes.teacherPanel),
        onAboutTap: () => LegalBottomSheet.showAbout(context),
        onTermsTap: () => LegalBottomSheet.showTerms(context),
        onPrivacyTap: () => LegalBottomSheet.showPrivacy(context),
        version: version,
        isPinned: _isPinned,
        onTogglePin: () {
          setState(() {
            _isPinned = false;
          });
        },
        width: _sidebarWidth,
      );
    }

    return Scaffold(
      key: TestKeys.dashboardShell,
      drawer: !_isPinned
          ? Drawer(
              width: 280,
              child: buildSidebarWidget(),
            )
          : null,
      body: Container(
        color: outerBgColor,
        child: Row(
          children: [
            // Pinned Sidebar Layout
            if (_isPinned) ...[
              buildSidebarWidget(),

              // Draggable Edge Handler overlay directly on boundary
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                onEnter: (_) => setState(() => _isHoveringEdge = true),
                onExit: (_) => setState(() => _isHoveringEdge = false),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      final isRtl = Directionality.of(context) == TextDirection.rtl;
                      final delta = isRtl ? -details.delta.dx : details.delta.dx;
                      double newWidth = _sidebarWidth + delta;
                      if (newWidth < 120.0) {
                        _isPinned = false;
                        _sidebarWidth = 240.0;
                      } else {
                        _sidebarWidth = newWidth.clamp(140.0, maxAllowedWidth);
                      }
                    });
                  },
                  child: SizedBox(
                    width: 6,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isHoveringEdge ? 1.0 : 0.0,
                          child: Container(
                            width: 3,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.25, 0.75, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Main Content Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Solid Outer Header Bar containing centered page title & hamburger button when unpinned
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      color: outerBgColor,
                      child: SizedBox(
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: Text(
                                _getPageTitle(selectedIndex),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                              ),
                            ),

                            // Hamburger Menu button integrated cleanly in top header row
                            if (!_isPinned)
                              Positioned(
                                right: Directionality.of(context) ==
                                        TextDirection.rtl
                                    ? 0
                                    : null,
                                left: Directionality.of(context) ==
                                        TextDirection.ltr
                                    ? 0
                                    : null,
                                child: Builder(
                                  builder: (context) {
                                    return IconButton(
                                      icon: const Icon(Icons.menu),
                                      tooltip: 'فتح القائمة الجانبية',
                                      onPressed: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),

                    // Main Content Card (16px Border Radius with lighter background)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
