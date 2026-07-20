import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
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
import 'package:arabilogia/features/admin/screens/lecture_preview_screen.dart';
import 'package:arabilogia/features/admin/screens/points_editor_screen.dart';
import 'package:arabilogia/features/admin/providers/points_provider.dart';
import 'package:arabilogia/features/dashboard/lectures/screens/lectures_screen.dart';
import 'package:arabilogia/features/dashboard/lectures/screens/lecture_detail_screen.dart';
import 'package:arabilogia/features/dashboard/lectures/screens/practice_quiz_screen.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/practice_result_screen.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';
import 'package:arabilogia/features/admin/screens/lecture_editor_screen.dart';

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
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
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
      final uri = state.uri;
      if (uri.path == '/landing.html') {
        return AppRoutes.register;
      }

      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.state.isAuthenticated;
      final isTeacher = authProvider.isTeacher;
      final matched = state.matchedLocation;

      final isPublicRoute =
          matched == AppRoutes.login ||
          matched == AppRoutes.register ||
          matched == AppRoutes.forgotPassword;

      // Teacher panel is NOT public - requires teacher role
      if (matched == AppRoutes.teacherPanel ||
          matched == AppRoutes.lecturePreview ||
          matched == AppRoutes.lectureEditor ||
          matched == AppRoutes.pointsEditor) {
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
        path: AppRoutes.lecturePreview,
        name: 'lecture-preview',
        pageBuilder: (context, state) {
          final exam = state.extra as Exam;
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: LecturePreviewScreen(exam: exam),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.examEditor,
        name: 'exam-editor',
        pageBuilder: (context, state) {
          final extra = state.extra;
          Exam? exam;
          bool hideCategoryAndGrade = false;
          bool hidePoints = false;
          bool hideTimer = false;
          bool hideLevel = false;
          if (extra is Exam) {
            exam = extra;
          } else if (extra is Map<String, dynamic>) {
            exam = extra['exam'] as Exam?;
            hideCategoryAndGrade = extra['hideCategoryAndGrade'] as bool? ?? false;
            hidePoints = extra['hidePoints'] as bool? ?? false;
            hideTimer = extra['hideTimer'] as bool? ?? false;
            hideLevel = extra['hideLevel'] as bool? ?? false;
          }
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: ExamEditorScreen(
              existingExam: exam,
              hideCategoryAndGrade: hideCategoryAndGrade,
              hidePoints: hidePoints,
              hideTimer: hideTimer,
              hideLevel: hideLevel,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.lectureEditor,
        name: 'lecture-editor',
        pageBuilder: (context, state) {
          final lecture = state.extra as Lecture?;
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: LectureEditorScreen(existingLecture: lecture),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.pointsEditor,
        name: 'points-editor',
        pageBuilder: (context, state) => AppRouter._buildPage(
          context: context,
          state: state,
          child: ChangeNotifierProvider(
            create: (_) => PointsProvider(),
            child: const PointsEditorScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.practiceQuiz,
        name: 'practice-quiz',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final examId = extra?['examId'] as String? ?? id;
          final subjectId = extra?['subjectId'] as String? ?? 'nahw';
          final subjectName = extra?['subjectName'] as String? ?? 'النحو';
          final lectureId = extra?['lectureId'] as String? ?? '';
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: PracticeQuizScreen(
              examId: examId,
              subjectId: subjectId,
              subjectName: subjectName,
              lectureId: lectureId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.practiceResult,
        name: 'practice-result',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AppRouter._buildPage(
            context: context,
            state: state,
            child: PracticeResultScreen(
              exam: extra['exam'] as Exam,
              userAnswers: extra['userAnswers'] as Map<int, String?>,
              correctCount: extra['correctCount'] as int,
            ),
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
            path: AppRoutes.lectures,
            name: 'lectures',
            pageBuilder: (context, state) => AppRouter._buildPage(
              context: context,
              state: state,
              child: const LecturesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.lectureDetail,
            name: 'lecture-detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AppRouter._buildPage(
                context: context,
                state: state,
                child: LectureDetailScreen(lectureId: id),
              );
            },
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
