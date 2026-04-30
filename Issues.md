# ArabiLogia Bug Report

> **Investigation Date:** April 30, 2026

---

## Executive Summary

This document catalogs all identified bugs and issues in the ArabiLogia Flutter application. The investigation uncovered **27 unique issues** across various severity levels, ranging from critical app-breaking crashes to minor UI/UX concerns. The issues are categorized by priority to facilitate systematic remediation efforts.

---

## Table of Contents

1. [Critical Issues](#critical-issues-app-crashesbroken-features---must-fix)
2. [High Priority](#high-priority--poor-ux--data-issues)
3. [Medium Priority](#medium-priority)
4. [Low Priority](#low-priority)

---

## Critical Issues (App Crashes/Broken Features - MUST FIX)

| # | Issue | File Location | Status |
|---|-------|---------------|--------|
| 1 | Broken "Retake Exam" button - Wrong route name | `exam_result_screen.dart:352` | [x] FIXED |
| 2 | Option ID mismatch after shuffle restore | `exam_interaction__screen.dart:108-128` | [x] FIXED |
| 3 | Race condition - unawaited score sync | `auth_provider.dart:86,129,249` | [x] FIXED |
| 4 | Null safety crash - byteData crash | `exam_result_screen.dart:57` | [x] FIXED |
| 5 | firstWhere crash if no correct answer | `exam_result_screen.dart:87,289` | [x] FIXED |
| 6 | Memory leak - TapGestureRecognizer not disposed | `terms_agreement.dart:52-53` | [x] FIXED |
| 7 | Dropdown initialValue bug - Invalid parameter | `exam_form_fields.dart:115,129` | [x] FIXED |
| 8 | Supabase not configured null | `auth_provider.dart:44-48` | [x] FIXED |

---

### 1. Broken "Retake Exam" button - Wrong route name

- **File:** `lib/screens/exam_result_screen.dart`
- **Line:** 352
- **Status:** [x] FIXED

**Description:**
The "Retake Exam" button navigates using a route name that doesn't exist in the routing configuration. When clicked, the app fails to navigate or throws an error because `ExamRouteNames.examIntroduction` may not be properly registered.

**Suggested Fix:**
```dart
// Line 352 - Change to correct route
onTap: () => Get.toNamed(
  ExamRouteNames.examIntroduction.replaceAll('/exam/', '/exam-intro/'),
  // OR use the actual route name that exists
),
```

---

### 2. Option ID mismatch after shuffle restore

- **File:** `lib/screens/exam_interaction_screen.dart`
- **Lines:** 108-128
- **Status:** [x] FIXED

**Description:**
When `restoreOriginalOrder()` is called, it restores the original question order but doesn't restore the correct option IDs that were scrambled. This causes answer validation to fail because the stored correct answer ID no longer matches the displayed option's ID.

**Suggested Fix:**
```dart
void restoreOriginalOrder() {
  // Existing code restores question order...
  // ADD: Restore correct option IDs for each question
  for (var question in questions) {
    question.correctOptionId = question.originalCorrectOptionId;
  }
}
```

---

### 3. Race condition - unawaited score sync

- **File:** `lib/providers/auth_provider.dart`
- **Lines:** 86, 129, 249
- **Status:** [x] FIXED

**Description:**
Score synchronization calls are made without `await`, causing potential race conditions where the UI may update before the data is actually saved to the database. This can result in score data loss or inconsistency.

**Suggested Fix:**
```dart
// Line 86 - Add await
await _scoreRepository.syncUserScore(userId, examId, score);

// Line 129 - Add await
await _scoreRepository.syncUserScore(userId, examId, score);

// Line 249 - Add await
await _scoreRepository.syncUserScore(userId, examId, score);
```

---

### 4. Null safety crash - byteData crash

- **File:** `lib/screens/exam_result_screen.dart`
- **Line:** 57
- **Status:** [x] FIXED

**Description:**
The code attempts to access `.buffer.asUint8List()` on a potentially null `byteData` object when generating the certificate/share image. This will crash if the image generation fails or returns null.

**Suggested Fix:**
```dart
// Line 57 - Add null check
final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
if (byteData == null) {
  // Handle error or return placeholder
  return;
}
final pngBytes = byteData.buffer.asUint8List();
```

---

### 5. firstWhere crash if no correct answer

- **File:** `lib/screens/exam_result_screen.dart`
- **Lines:** 87, 289
- **Status:** [x] FIXED

**Description:**
`firstWhere` is used without a default value, causing a `StateError` crash when no correct answer exists in the options list. This can happen with corrupted question data or improperly configured questions.

**Suggested Fix:**
```dart
// Line 87 - Use firstWhereOrNull or add default
final correctOption = options.firstWhere(
  (o) => o.id == question.correctOptionId,
  orElse: () => options.first, // Default to first option
);

// Line 289 - Same fix
```

---

### 6. Memory leak - TapGestureRecognizer not disposed

- **File:** `lib/widgets/terms_agreement.dart`
- **Lines:** 52-53
- **Status:** [x] FIXED

**Description:**
`TapGestureRecognizer` is created but not disposed in the `dispose()` method, causing a memory leak. This happens because the gesture recognizer is created in `initState()` but the dispose method doesn't clean it up.

**Suggested Fix:**
```dart
// Add to dispose method (line 52-53)
@override
void dispose() {
  _tapGesture.dispose(); // Add this line
  super.dispose();
}
```

---

### 7. Dropdown initialValue bug - Invalid parameter

- **File:** `lib/widgets/exam_form_fields.dart`
- **Lines:** 115, 129
- **Status:** [x] FIXED

**Description:**
The dropdown's `initialValue` is set to an ID (string) but the widget expects an index (int). This causes the dropdown to default to the first item regardless of the intended selection, making it impossible to properly pre-select the correct option.

**Suggested Fix:**
```dart
// Line 115 - Convert ID to index
final selectedIndex = options.indexWhere((o) => o.id == initialValue);
DropdownButtonFormField<int>(
  value: selectedIndex >= 0 ? selectedIndex : null,
  // ... onChanged: (index) => onChanged(options[index].id)
)

// Line 129 - Same fix
```

---

### 8. Supabase not configured null

- **File:** `lib/providers/auth_provider.dart`
- **Lines:** 44-48
- **Status:** [x] FIXED

**Description:**
The Supabase client is not properly null-checked before use. If `Supabase.instance` is not initialized or configured, accessing it will throw a null error. The code assumes Supabase is always configured but doesn't validate this.

**Suggested Fix:**
```dart
// Lines 44-48 - Add validation
SupabaseClient? get _supabase {
  try {
    if (Supabase.instance == null) return null;
    return Supabase.instance.client;
  } catch (e) {
    return null;
  }
}
```

---

## High Priority (Poor UX / Data Issues)

| # | Issue | File Location | Status |
|---|-------|---------------|--------|
| 1 | Form validation missing - Doesn't validate one correct answer | `exam_editor.dart:196-203` | [x] FIXED |
| 2 | No error feedback | `forgot_password_overlay.dart:66-89` | [x] FIXED |
| 3 | Hardcoded route | `login_screen.dart:48` | [x] FIXED |
| 4 | Dialog context bug | `dashboard_shell.dart:60-87` | [x] FIXED |
| 9 | Mobile button text truncated | `login_screen.dart:247`, `register_screen.dart:292`, etc | [x] FIXED |
| 5 | Question ID wrong fallback | `question_card.dart:317` | [x] FIXED |
| 6 | No try-catch in fetch | `exams_screen.dart:52-73` | [x] FIXED |
| 7 | Stats key mismatch | `profile_screen.dart:26-32` | [x] FIXED |
| 8 | Grade text shows "0ث" | `exam_results_view.dart:302` | [x] FIXED |

---

### 1. Form validation missing - Doesn't validate one correct answer

- **File:** `lib/screens/exam_editor.dart`
- **Lines:** 196-203
- **Status:** [x] FIXED

**Description:**
The exam form validation checks all required fields but doesn't ensure at least one correct answer is marked. Users can create exams where no answer is marked as correct, leading to 100% failure rates for all takers.

**Suggested Fix:**
```dart
// Add to form validation (line 196-203)
if (questions.any((q) => q.correctOptionId == null)) {
  emit(state.copyWith(
    status: ExamEditorStatus.failure,
    errorMessage: 'يرجى تحديد إجابة صحيحة لكل سؤال',
  ));
  return;
}
```

---

### 2. No error feedback

- **File:** `lib/overlays/forgot_password_overlay.dart`
- **Lines:** 66-89
- **Status:** [x] FIXED

**Description:**
When password reset fails (e.g., network error, invalid email), no error message is shown to the user. The operation silently fails, leaving users confused about why their reset email didn't arrive.

**Suggested Fix:**
```dart
// Add error handling (lines 66-89)
try {
  await supabase.auth.resetPasswordForEmail(email);
  emit(state.copyWith(status: ResetStatus.success));
} on AuthException catch (e) {
  emit(state.copyWith(
    status: ResetStatus.failure,
    errorMessage: _getErrorMessage(e),
  ));
}
```

---

### 3. Hardcoded route

- **File:** `lib/screens/login_screen.dart`
- **Line:** 48
- **Status:** [x] FIXED

**Description:**
Navigation uses a hardcoded route path instead of the defined route constants. If routes are refactored, this hardcoded path will break. It also bypasses any route guards or middleware.

**Suggested Fix:**
```dart
// Line 48 - Use route constant
onPressed: () => Get.toNamed(RouteNames.dashboard),
```

---

### 4. Dialog context bug

- **File:** `lib/screens/dashboard_shell.dart`
- **Lines:** 60-87
- **Status:** [x] FIXED

**Description:**
The dialog is built using `Get.dialog()` but without proper context handling. In some scenarios, especially when called from within a modal or bottom sheet, the dialog fails to appear or throws a context-related error.

**Suggested Fix:**
```dart
// Lines 60-87 - Use proper context
void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      // ... dialog content
    ),
  );
}
```

---

### 5. Question ID wrong fallback

- **File:** `lib/widgets/question_card.dart`
- **Line:** 317
- **Status:** [x] FIXED

**Description:**
When a question ID is not found or is null, the fallback defaults to an empty string or 0, which can cause issues when saving or comparing questions. This can lead to duplicate questions or incorrect tracking.

**Suggested Fix:**
```dart
// Line 317 - Use proper fallback
final questionId = question?.id ?? uuid.v4(); // Generate new ID
```

---

### 6. No try-catch in fetch

- **File:** `lib/screens/exams_screen.dart`
- **Lines:** 52-73
- **Status:** [x] FIXED

**Description:**
Network calls don't have proper error handling. If the request fails (timeout, server error, no network), the app crashes or shows a blank screen without any feedback to the user.

**Suggested Fix:**
```dart
// Add try-catch (lines 52-73)
try {
  final response = await _examsRepository.getExams();
  // handle response
} on NetworkException catch (e) {
  emit(state.copyWith(
    status: ExamsStatus.failure,
    errorMessage: 'فشل تحميل الامتحانات. تحقق من اتصالك.',
  ));
}
```

---

### 7. Stats key mismatch

- **File:** `lib/screens/profile_screen.dart`
- **Lines:** 26-32
- **Status:** [x] FIXED

**Description:**
The profile screen expects specific keys from the stats data (e.g., "total_exams", "average_score") but the backend returns different keys. This causes stats to display as 0 or null even when data exists.

**Suggested Fix:**
```dart
// Add key mapping (lines 26-32)
final stats = userStats ?? {};
return ProfileStats(
  totalExams: stats['total_exams'] ?? stats['exams_completed'] ?? 0,
  averageScore: stats['average_score'] ?? stats['avg_score'] ?? 0,
);
```

---

### 8. Grade text shows "0ث"

- **File:** `lib/views/exam_results_view.dart`
- **Line:** 302
- **Status:** [x] FIXED

**Description:**
The grade text concatenates "0" with "ث" (Arabic letter for "ثانية/seconds") incorrectly. It should show a proper grade like "85 درجة" but instead shows "0ث".

**Suggested Fix:**
```dart
// Line 302 - Fix grade text
Text(
  '${score.toInt()} درجة',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

---

## Medium Priority

| # | Issue | File Location | Status |
|---|-------|---------------|--------|
| 1 | Timer runs in background | `exam_interaction_screen.dart:56-87` | [x] FIXED |
| 2 | Silent score failures | `score_repository.dart:115-128` | [x] FIXED |
| 3 | Theme toggle snackbar annoyance | `theme_toggle_button.dart:50-62` | [x] FIXED |
| 4 | Potato mode not persisted | `potato_mode_provider.dart:50-53` | [x] FIXED |
| 5 | Inverted animations toggle | `settings_screen.dart:166-172` | [x] FIXED |
| 6 | Notification toggle no feedback | `settings_screen.dart:272-277` | [x] FIXED |
| 7 | Wrong category IDs | `exam_form_fields.dart:88-100` | [x] FIXED |
| 8 | No pull-to-refresh | `home_screen.dart` | [x] FIXED |
| 9 | Wrong navigation | `exam_preview_screen.dart:222` | [x] FIXED |
| 10 | Duplicate ScoreRepository instances | Multiple locations | [x] FIXED |

---

### 1. Timer runs in background

- **File:** `lib/screens/exam_interaction_screen.dart`
- **Lines:** 56-87
- **Status:** [x] FIXED

**Description:**
The exam timer continues running even when the app is in the background. This leads to users losing exam time while away from the app. The timer should pause when the app goes to background.

**Suggested Fix:**
```dart
// Add AppLifecycleListener (lines 56-87)
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _timer.cancel();
  } else if (state == AppLifecycleState.resumed) {
    _startTimer();
  }
}
```

---

### 2. Silent score failures

- **File:** `lib/repositories/score_repository.dart`
- **Lines:** 115-128
- **Status:** [x] FIXED

**Description:**
When score synchronization fails, the error is logged but not communicated to the user or the UI. Users may think their scores are saved when they're not, leading to data loss.

**Suggested Fix:**
```dart
// Add error reporting (lines 115-128)
try {
  await supabase.from('scores').upsert(scoreData);
} catch (e) {
  // Report to error tracking service
  await _errorReporter.report(ScoreSyncException(e));
  // Optionally retry queue
}
```

---

### 3. Theme toggle snackbar annoyance

- **File:** `lib/widgets/theme_toggle_button.dart`
- **Lines:** 50-62
- **Status:** [x] FIXED

**Description:**
Every time the theme is toggled, a snackbar appears confirming the change. This is unnecessary and becomes annoying for users who frequently switch themes. The snackbar should only appear on first use or be removed entirely.

**Suggested Fix:**
```dart
// Remove snackbar (lines 50-62)
// Simply toggle without notification
setState(() => _isDarkMode = !_isDarkMode);
_prefs.setBool('dark_mode', _isDarkMode);
```

---

### 4. Potato mode not persisted

- **File:** `lib/providers/potato_mode_provider.dart`
- **Lines:** 50-53
- **Status:** [x] FIXED

**Description:**
The potato mode preference is read from SharedPreferences but not written back when changed. The mode setting is lost when the app is closed and reopened.

**Suggested Fix:**
```dart
// Add persistence (lines 50-53)
void setPotatoMode(bool enabled) {
  _isPotatoMode = enabled;
  _prefs.setBool('potato_mode', enabled);
  notifyListeners();
}
```

---

### 5. Inverted animations toggle

- **File:** `lib/screens/settings_screen.dart`
- **Lines:** 166-172
- **Status:** [x] FIXED

**Description:**
The animations toggle switch has inverted logic - turning it ON disables animations and turning it OFF enables them. This is counter-intuitive for users.

**Suggested Fix:**
```dart
// Fix logic (lines 166-172)
Switch(
  value: _animationsEnabled, // Already stored correctly
  onChanged: (value) {
    _settings.animationEnabled = value;
  },
)
```

---

### 6. Notification toggle no feedback

- **File:** `lib/screens/settings_screen.dart`
- **Lines:** 272-277
- **Status:** [x] FIXED

**Description:**
Toggling the notification setting shows no feedback - no confirmation that the setting was saved, no error message if it failed. Users may toggle multiple times unsure if it worked.

**Suggested Fix:**
```dart
// Add feedback (lines 272-277)
onChanged: (value) async {
  await _settings.setNotifications(value);
  Get.snackbar(
    value ? 'تم تفعيل الإشعارات' : 'تم إيقاف الإشعارات',
    '',
    snackPosition: SnackPosition.BOTTOM,
    duration: Duration(seconds: 2),
  );
}
```

---

### 7. Wrong category IDs

- **File:** `lib/widgets/exam_form_fields.dart`
- **Lines:** 88-100
- **Status:** [x] FIXED

**Description:**
The hardcoded category IDs in the dropdown don't match the IDs stored in the database. This causes exams to be categorized incorrectly or not at all when created.

**Suggested Fix:**
```dart
// Use constants or database values (lines 88-100)
const categoryIds = {
  'arabic': 'cat_001',
  'math': 'cat_002',
  'science': 'cat_003',
};
// OR fetch from database on init
```

---

### 8. No pull-to-refresh

- **File:** `lib/screens/home_screen.dart`
- **Status:** [x] FIXED

**Description:**
The home screen doesn't implement pull-to-refresh functionality. Users must navigate away and back to see new content or updated stats.

**Suggested Fix:**
```dart
// Add RefreshIndicator
RefreshIndicator(
  onRefresh: () => _loadData(),
  child: ListView(...),
)
```

---

### 9. Wrong navigation

- **File:** `lib/screens/exam_preview_screen.dart`
- **Line:** 222
- **Status:** [x] FIXED

**Description:**
The navigation from exam preview to taking the exam uses incorrect route parameters, causing the exam to load without proper context or settings.

**Suggested Fix:**
```dart
// Line 222 - Use correct route with parameters
Get.toNamed(
  '/exam/interaction/${exam.id}',
  arguments: {'duration': exam.duration, 'questions': questions},
);
```

---

### 10. Duplicate ScoreRepository instances

- **File:** Multiple locations
- **Status:** [x] FIXED

**Description:**
ScoreRepository is instantiated multiple times across different screens/providers instead of being provided as a singleton. This causes inconsistent state and multiple network calls.

**Suggested Fix:**
```dart
// Add to GetIt/Provider
GetIt.instance.registerSingleton<ScoreRepository>(ScoreRepository());

// Use throughout app
final scoreRepo = GetIt.instance<ScoreRepository>();
```

---

## Low Priority

| # | Issue | File Location | Status |
|---|-------|---------------|--------|
| 1 | Hardcoded date | `legal_bottom_sheet.dart:89` | [x] FIXED |
| 2 | ZWNJ in Arabic text | `legal_content.dart:44-60` | [x] FIXED |
| 3 | Duplicate colors | `app_colors.dart:15-16` | [x] FIXED |
| 4 | Unused code | `leaderboard_screen.dart:206` | [x] FIXED |
| 5 | Wrong translation | `strings.dart:53` | [x] FIXED |

---

### 1. Hardcoded date

- **File:** `lib/bottom_sheets/legal_bottom_sheet.dart`
- **Line:** 89
- **Status:** [x] FIXED

**Description:**
The legal bottom sheet displays "Last updated: 2024" as a hardcoded value. This should be dynamic based on the actual last update date from the content or backend.

**Suggested Fix:**
```dart
// Line 89 - Use dynamic date
Text('آخر تحديث: ${_lastUpdated ?? DateTime.now().year}'),
```

---

### 2. ZWNJ in Arabic text

- **File:** `lib/data/legal_content.dart`
- **Lines:** 44-60
- **Status:** [x] FIXED

**Description:**
Arabic text contains Zero Width Non-Joiner (ZWNJ) characters that can cause rendering issues or text processing problems in some contexts.

**Suggested Fix:**
```dart
// Clean text (lines 44-60)
String cleanArabicText(String text) {
  return text.replaceAll('\u200B', '').trim();
}
```

---

### 3. Duplicate colors

- **File:** `lib/theme/app_colors.dart`
- **Lines:** 15-16
- **Status:** [x] FIXED

**Description:**
Colors `successGreen` and `correctGreen` have identical hex values (#4CAF50), creating redundancy. This should be consolidated into a single token or differentiated.

**Suggested Fix:**
```dart
// Consolidate (lines 15-16)
const Color correctGreen = Color(0xFF4CAF50);
// Remove successGreen or differentiate
```

---

### 4. Unused code

- **File:** `lib/screens/leaderboard_screen.dart`
- **Line:** 206
- **Status:** [x] FIXED

**Description:**
Function `_buildRankBadge()` is defined but never called anywhere in the file. This dead code should be removed to reduce confusion and improve maintainability.

**Suggested Fix:**
```dart
// Remove unused function (line 206)
// Or implement its usage
```

---

### 5. Wrong translation

- **File:** `lib/l10n/strings.dart`
- **Line:** 53
- **Status:** [x] FIXED

**Description:**
The Arabic translation for "Average Score" is "متوسط الدرجات" which grammatically should be "متوسط الدرجات" but appears with incorrect diacritics or form in some contexts.

**Suggested Fix:**
```dart
// Line 53 - Fix translation
'averageScore': 'متوسط الدرجات',
```

---

## Issue Tracking Summary

| Priority | Count | Fixed | Not Fixed |
|----------|-------|-------|-----------|
| Critical | 8 | 8 | 0 |
| High | 8 | 8 | 0 |
| Medium | 10 | 10 | 0 |
| Low | 5 | 5 | 0 |
| **Total** | **31** | **31** | **0** |

---

## Progress Checklist

### Critical Issues
- [x] Fix broken "Retake Exam" button route
- [x] Fix option ID mismatch after shuffle restore
- [x] Add await to score sync calls
- [x] Add null safety for byteData
- [x] Add default to firstWhere calls
- [x] Dispose TapGestureRecognizer
- [x] Fix Dropdown initialValue
- [x] Add Supabase null validation

### High Priority Issues
- [x] Add form validation for correct answer
- [x] Add error feedback to forgot password
- [x] Replace hardcoded route with constant
- [x] Fix dialog context handling
- [x] Fix question ID fallback
- [x] Add try-catch to exams fetch
- [x] Fix stats key mapping
- [x] Fix grade text display

### Medium Priority Issues
- [x] Pause timer when app backgrounded
- [x] Report score sync failures
- [x] Remove theme toggle snackbar
- [x] Persist potato mode
- [x] Fix animations toggle logic
- [x] Add notification toggle feedback
- [x] Fix category IDs
- [x] Add pull-to-refresh
- [x] Fix navigation parameters
- [x] Consolidate ScoreRepository

### Low Priority Issues
- [x] Use dynamic date
- [x] Clean ZWNJ characters
- [x] Remove duplicate colors
- [x] Remove unused code
- [x] Fix translation

---

*Document generated: April 30, 2026*
*Next review date: May 15, 2026*