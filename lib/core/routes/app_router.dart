import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/auth/login/screens/login_screen.dart';
import 'package:arabilogia/features/auth/register/screens/register_screen.dart';
import 'package:arabilogia/features/auth/update_confirm/screens/update_confirm_page.dart';
import 'package:arabilogia/features/dashboard/screens/dashboard_shell.dart';
import 'package:arabilogia/features/dashboard/home/screens/home_screen.dart';
import 'package:arabilogia/features/dashboard/exams/screens/exams_screen.dart';
import 'package:arabilogia/features/dashboard/exams/screens/exam_details_screen.dart';
import 'package:arabilogia/features/dashboard/exams/screens/exam_interaction_screen.dart';
import 'package:arabilogia/features/dashboard/exams/screens/exam_result_screen.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/leaderboard/screens/leaderboard_screen.dart';
import 'package:arabilogia/features/dashboard/profile/screens/profile_screen.dart';
import 'package:arabilogia/features/dashboard/settings/screens/settings_screen.dart';
import 'package:arabilogia/features/dashboard/history/screens/activity_history_screen.dart';
import 'package:arabilogia/features/dashboard/profile/screens/profile_edit_page.dart';
import 'package:arabilogia/features/admin/screens/teacher_panel_screen.dart';
import 'package:arabilogia/features/admin/screens/teacher_settings_screen.dart';
import 'package:arabilogia/features/admin/screens/exam_editor_screen.dart';
import 'package:arabilogia/features/admin/screens/exam_preview_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static GoRouter get router => _router;

  static Page<dynamic> _buildPageWithNoTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static Page<dynamic> _buildPageWithFade({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static Page<dynamic> _buildPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final potato = context.read<PotatoModeProvider>();
    if (potato.transitionsEnabled) {
      return _buildPageWithFade(context: context, state: state, child: child);
    }
    return _buildPageWithNoTransition(
      context: context,
      state: state,
      child: child,
    );
  }

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    observers: [routeObserver],
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.state.isAuthenticated;
      final isTeacher = authProvider.isTeacher;
      final isPublicRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Teacher panel is NOT public - requires teacher role
      if (state.matchedLocation == AppRoutes.teacherPanel ||
          state.matchedLocation == AppRoutes.examPreview) {
        if (!isAuthenticated) {
          return AppRoutes.login;
        }
        if (!isTeacher) {
          return AppRoutes.dashboard;
        }
        return null;
      }

      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isPublicRoute) {
        return isTeacher ? AppRoutes.teacherPanel : AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => AppRouter._buildPage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => AppRouter._buildPage(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.updateConfirm,
        name: 'update-confirm',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final update = state.extra as dynamic;
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: UpdateConfirmPage(update: update),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.teacherPanel,
        name: 'teacher-panel',
        pageBuilder: (context, state) => AppRouter._buildPage(
          context: context,
          state: state,
          child: const TeacherPanelScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherSettings,
        name: 'teacher-settings',
        pageBuilder: (context, state) => AppRouter._buildPage(
          context: context,
          state: state,
          child: const TeacherSettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.examPreview,
        name: 'exam-preview',
        pageBuilder: (context, state) {
          final exam = state.extra as Exam;
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: ExamPreviewScreen(exam: exam),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.examEditor,
        name: 'exam-editor',
        pageBuilder: (context, state) {
          final exam = state.extra as Exam?;
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: ExamEditorScreen(existingExam: exam),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.examInteraction,
        name: 'exam-interaction',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final subjectId = extra?['subjectId'] as String? ?? 'nahw';
          final subjectName = extra?['subjectName'] as String? ?? 'النحو';
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: ExamInteractionScreen(
              examId: id,
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.examResult,
        name: 'exam-result',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: ExamResultScreen(
              exam: extra['exam'] as Exam,
              userAnswers: extra['userAnswers'] as Map<int, String?>,
              score: extra['score'] as int,
              accuracy: extra['accuracy'] as int? ?? 0,
              speedBonus: extra['speedBonus'] as int? ?? 0,
              correctCount: extra['correctCount'] as int,
            ),
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            redirect: (_, __) => AppRoutes.home,
          ),
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => AppRouter._buildPage(
              context: context,
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.exams,
            name: 'exams',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final initialTabIndex = extra?['initialTabIndex'] as int? ?? 0;
              return AppRouter._buildPage(
                context: context,
                state: state,
                child: ExamsScreen(initialTabIndex: initialTabIndex),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.examDetail,
            name: 'exam-detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final extra = state.extra as Map<String, dynamic>?;
              final subjectId = extra?['subjectId'] as String? ?? 'nahw';
              final subjectName = extra?['subjectName'] as String? ?? 'النحو';
              return AppRouter._buildPage(
                context: context,
                state: state,
                child: ExamDetailsScreen(
                  examId: id,
                  subjectId: subjectId,
                  subjectName: subjectName,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            name: 'leaderboard',
            pageBuilder: (context, state) => AppRouter._buildPage(
              context: context,
              state: state,
              child: const LeaderboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) => AppRouter._buildPage(
              context: context,
              state: state,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => AppRouter._buildPage(
              context: context,
              state: state,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.activityHistory,
            name: 'activity-history',
            pageBuilder: (context, state) => AppRouter._buildPage(
              context: context,
              state: state,
              child: const ActivityHistoryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profileEdit,
            name: 'profile-edit',
            pageBuilder: (context, state) => AppRouter._buildPage(
              context: context,
              state: state,
              child: const ProfileEditPage(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}
