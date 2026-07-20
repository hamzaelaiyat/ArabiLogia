import 'package:flutter/material.dart';

/// Centralized semantic keys for integration tests (Robot Pattern).
///
/// Keep these stable; they are the contract between the production widgets
/// and the Patrol/Robot tests in `integration_test/`.
class TestKeys {
  TestKeys._();

  // ---------------------------------------------------------------------------
  // Auth — Login
  // ---------------------------------------------------------------------------
  static const loginScreen = Key('login_screen');
  static const loginEmailField = Key('login_email_field');
  static const loginPasswordField = Key('login_password_field');
  static const loginPasswordVisibilityToggle = Key(
    'login_password_visibility_toggle',
  );
  static const loginForgotPassword = Key('login_forgot_password');
  static const loginButton = Key('login_button');
  static const loginGoToRegister = Key('login_go_to_register');
  static const loginResendVerification = Key('login_resend_verification');

  // ---------------------------------------------------------------------------
  // Auth — Register
  // ---------------------------------------------------------------------------
  static const registerScreen = Key('register_screen');
  static const registerEmailField = Key('register_email_field');
  static const registerPasswordField = Key('register_password_field');
  static const registerConfirmPasswordField = Key(
    'register_confirm_password_field',
  );
  static const registerUsernameField = Key('register_username_field');
  static const registerPhoneField = Key('register_phone_field');
  static const registerGradeSelector = Key('register_grade_selector');
  static const registerNextButton = Key('register_next_button');
  static const registerBackButton = Key('register_back_button');
  static const registerSubmitButton = Key('register_submit_button');
  static const registerGoToLogin = Key('register_go_to_login');

  // ---------------------------------------------------------------------------
  // Dashboard / Shell
  // ---------------------------------------------------------------------------
  static const dashboardShell = Key('dashboard_shell');
  static const navHome = Key('nav_home');
  static const navExams = Key('nav_exams');
  static const navLectures = Key('nav_lectures');
  static const navLeaderboard = Key('nav_leaderboard');
  static const navHistory = Key('nav_history');
  static const navProfile = Key('nav_profile');
  static const navSettings = Key('nav_settings');

  // ---------------------------------------------------------------------------
  // Home
  // ---------------------------------------------------------------------------
  static const homeScreen = Key('home_screen');

  // ---------------------------------------------------------------------------
  // Exams
  // ---------------------------------------------------------------------------
  static const examsScreen = Key('exams_screen');
  static const examsTabAll = Key('exams_tab_all');
  static const examsTabCompleted = Key('exams_tab_completed');
  static const examsTabNew = Key('exams_tab_new');
  static const examsRetry = Key('exams_retry');
  static const examDetailsScreen = Key('exam_details_screen');
  static const examDetailsStart = Key('exam_details_start');
  static const examDetailsBack = Key('exam_details_back');
  static const examInteractionScreen = Key('exam_interaction_screen');
  static const examQuestionText = Key('exam_question_text');
  static const examAnswerOptionPrefix = Key('exam_answer_option_');
  static const examPreviousQuestion = Key('exam_previous_question');
  static const examNextQuestion = Key('exam_next_question');
  static const examSubmit = Key('exam_submit');
  static const examResultScreen = Key('exam_result_screen');
  static const examResultRetry = Key('exam_result_retry');
  static const examResultExit = Key('exam_result_exit');
  static const examErrorRetry = Key('exam_error_retry');

  // ---------------------------------------------------------------------------
  // Lectures
  // ---------------------------------------------------------------------------
  static const lecturesScreen = Key('lectures_screen');
  static const lectureCardPrefix = Key('lecture_card_');
  static const lectureDetailScreen = Key('lecture_detail_screen');
  static const lectureStartPractice = Key('lecture_start_practice');
  static const practiceQuizScreen = Key('practice_quiz_screen');
  static const practiceQuizNext = Key('practice_quiz_next');
  static const practiceQuizFinish = Key('practice_quiz_finish');

  // ---------------------------------------------------------------------------
  // Admin / Teacher — Lecture editor
  // ---------------------------------------------------------------------------
  static const lectureEditorScreen = Key('lecture_editor_screen');
  static const lectureEditorBack = Key('lecture_editor_back');
  static const lectureEditorTitle = Key('lecture_editor_title');
  static const lectureEditorDescription = Key('lecture_editor_description');
  static const lectureEditorAddBlock = Key('lecture_editor_add_block');
  static const lectureEditorAddText = Key('lecture_editor_add_text');
  static const lectureEditorAddImage = Key('lecture_editor_add_image');
  static const lectureEditorAddQuestion = Key('lecture_editor_add_question');
  static const lectureEditorSaveDraft = Key('lecture_editor_save_draft');
  static const lectureEditorPublish = Key('lecture_editor_publish');
  static const lectureEditorAddExam = Key('lecture_editor_add_exam');
  static const lectureEditorTabPrefix = Key('lecture_editor_tab_');
  static const exitConfirmationSheet = Key('exit_confirmation_sheet');
  static const exitSaveDraft = Key('exit_save_draft');
  static const exitPublish = Key('exit_publish');
  static const exitCancel = Key('exit_cancel');
  static const lecturePreviewScreen = Key('lecture_preview_screen');
  static const lecturePreviewShuffle = Key('lecture_preview_shuffle');
  static const lecturePreviewSubmit = Key('lecture_preview_submit');
  static const lecturePreviewExit = Key('lecture_preview_exit');
  static const teacherPanelScreen = Key('teacher_panel_screen');

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------
  static const profileScreen = Key('profile_screen');
  static const profileEditButton = Key('profile_edit_button');
  static const profileSettingsButton = Key('profile_settings_button');
  static const profileSwitchAccountButton = Key(
    'profile_switch_account_button',
  );
  static const profileLogoutButton = Key('profile_logout_button');
  static const profileEditScreen = Key('profile_edit_screen');
  static const profileEditUsername = Key('profile_edit_username');
  static const profileEditPhone = Key('profile_edit_phone');
  static const profileEditGrade = Key('profile_edit_grade');
  static const profileEditSave = Key('profile_edit_save');
  static const profileEditCancel = Key('profile_edit_cancel');
  static const profileEditAvatar = Key('profile_edit_avatar');
  static const editProfileDialog = Key('edit_profile_dialog');
  static const editProfileSave = Key('edit_profile_save');
  static const editProfileCancel = Key('edit_profile_cancel');
  static const switchAccountsSheet = Key('switch_accounts_sheet');
  static const switchAccountsAdd = Key('switch_accounts_add');
  static const switchAccountsItemPrefix = Key('switch_accounts_item_');

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------
  static const settingsScreen = Key('settings_screen');
  static const settingsThemeSelector = Key('settings_theme_selector');
  static const settingsPerformanceMode = Key('settings_performance_mode');
  static const settingsNotifications = Key('settings_notifications');
  static const settingsPrivacy = Key('settings_privacy');
  static const settingsReportProblem = Key('settings_report_problem');
  static const settingsAbout = Key('settings_about');
  static const settingsExamOffline = Key('settings_exam_offline');
  static const settingsAccount = Key('settings_account');
  static const settingsLogout = Key('settings_logout');
  static const reportProblemSheet = Key('report_problem_sheet');
  static const reportProblemCategory = Key('report_problem_category');
  static const reportProblemMessage = Key('report_problem_message');
  static const reportProblemPhone = Key('report_problem_phone');
  static const reportProblemWhatsapp = Key('report_problem_whatsapp');
  static const reportProblemSubmit = Key('report_problem_submit');
  static const reportProblemCancel = Key('report_problem_cancel');
  static const reportProblemSuccess = Key('report_problem_success');
  static const privacySection = Key('privacy_section');

  // ---------------------------------------------------------------------------
  // Update flow
  // ---------------------------------------------------------------------------
  static const updateConfirmScreen = Key('update_confirm_screen');
  static const updateDownload = Key('update_download');
  static const updateInstall = Key('update_install');
  static const updateLater = Key('update_later');
}
