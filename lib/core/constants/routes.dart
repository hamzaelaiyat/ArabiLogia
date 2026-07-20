abstract class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String exams = '/exams';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String exam = '/exam';
  static const String examDetail = '/exam/:id';
  static const String examInteraction = '/exam/interaction/:id';
  static const String examResult = '/exams/result';
  static const String userView = '/user/:id';
  static const String activityHistory = '/activity-history';
  static const String profileEdit = '/profile/edit';

  // Admin Routes
  static const String teacherPanel = '/admin/teacher-panel';
  static const String teacherSettings = '/admin/teacher-settings';
  static const String lecturePreview = '/admin/lecture-preview';
  static const String examEditor = '/admin/exam-editor';
  static const String pointsEditor = '/admin/points-editor';

  // Lecture Routes
  static const String lectures = '/lectures';
  static const String lectureDetail = '/lecture/:id';
  static const String lecturePattern = '/lecture';
  static const String practiceQuiz = '/lecture/:id/practice';
  static const String practiceResult = '/practice-result';

  // Admin Lecture Routes
  static const String lectureEditor = '/admin/lecture-editor';

  // Update Routes
  static const String updateConfirm = '/update-confirm';
}
