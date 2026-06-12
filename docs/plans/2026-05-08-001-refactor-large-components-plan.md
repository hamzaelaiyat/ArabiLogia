---
title: "refactor: Break down 24 large components into smaller, maintainable pieces"
type: refactor
status: active
date: 2026-05-08
---

# Refactor Large Components Plan

## Summary

Refactor 24 large source files (300+ lines each) into smaller, focused components (3-10 per file). This improves readability, testability, and reusability while following existing project patterns.

---

## Problem Frame

The codebase contains 24 files with 300+ lines each:
- Large widgets/screens mix UI layout, business logic, and state management
- Provider files bundle multiple concerns
- Testing large files in isolation is difficult
- Components are hard to reuse when nested in monolithic files

Current patterns show promise: `question_input.dart` and `question_card_extras.dart` were already extracted from `question_card.dart`. This plan formalizes and extends that pattern.

---

## Requirements

- R1. Extract 3-10 focused components from each large file
- R2. Follow existing project patterns: widgets go in `widgets/` subdirectory
- R3. Preserve all existing behavior - no functional changes
- R4. Keep extracted components cohesive and reusable
- R5. Update imports in parent files to use extracted components
- R6. Ensure app compiles without errors after each extraction

---

## Scope Boundaries

- In scope: All 24 files with 300+ lines
- Out of scope: Adding new features, changing behavior, renaming existing APIs
- Out of scope: Rewriting state management architecture (keep using Provider)

### Deferred to Follow-Up Work

- Writing new unit tests for extracted components (separate task)
- Performance optimizations (separate task)

---

## Context & Research

### Relevant Code and Patterns

**Existing extraction pattern** (already used in the codebase):
- `question_card.dart` (1043 lines) → extracted `question_input.dart` and `question_card_extras.dart`
- Location: `lib/features/<feature>/widgets/<component_name>.dart`

**Widget organization pattern**:
- Screens live in `screens/` directory
- Reusable widgets live in `widgets/` directory
- Example: `register_screen.dart` imports from `widgets/grade_selector.dart`, `widgets/terms_agreement.dart`, etc.

### Files to Refactor (24 total)

Grouped by feature for parallel execution:

#### Group A: Admin Widgets (5 files)
| File | Lines | Type |
|------|-------|------|
| `lib/features/admin/widgets/question_card.dart` | 1043 | Widget |
| `lib/features/admin/widgets/exam_editor.dart` | 473 | Widget |
| `lib/features/admin/widgets/passage_manager.dart` | 454 | Widget |
| `lib/features/admin/widgets/question_list_panel.dart` | 334 | Widget |
| `lib/features/admin/widgets/exam_editor_state.dart` | 315 | State |

#### Group B: Auth Screens (4 files)
| File | Lines | Type |
|------|-------|------|
| `lib/features/auth/register/screens/register_screen.dart` | 714 | Screen |
| `lib/features/auth/update_confirm/screens/update_confirm_page.dart` | 697 | Screen |
| `lib/features/auth/forgot_password/screens/forgot_password_overlay.dart` | 414 | Widget |
| `lib/features/auth/login/screens/login_screen.dart` | 371 | Screen |

#### Group C: Dashboard Screens (4 files)
| File | Lines | Type |
|------|-------|------|
| `lib/features/dashboard/settings/screens/settings_screen.dart` | 737 | Screen |
| `lib/features/dashboard/profile/screens/profile_screen.dart` | 608 | Screen |
| `lib/features/dashboard/home/screens/home_screen.dart` | 582 | Screen |
| `lib/features/dashboard/leaderboard/screens/leaderboard_screen.dart` | 353 | Screen |

#### Group D: Exam Screens & Models (6 files)
| File | Lines | Type |
|------|-------|------|
| `lib/features/dashboard/exams/screens/exam_interaction_screen.dart` | 692 | Screen |
| `lib/features/dashboard/exams/screens/exam_result_screen.dart` | 499 | Screen |
| `lib/features/dashboard/exams/screens/exam_details_screen.dart` | 399 | Screen |
| `lib/features/dashboard/exams/screens/exams_screen.dart` | 392 | Screen |
| `lib/features/dashboard/exams/repositories/score_repository.dart` | 383 | Repository |
| `lib/features/dashboard/exams/models/exam_model.dart` | 310 | Model |

#### Group E: Core & Providers (5 files)
| File | Lines | Type |
|------|-------|------|
| `lib/providers/auth_provider.dart` | 529 | Provider |
| `lib/features/dashboard/screens/dashboard_shell.dart` | 429 | Shell |
| `lib/core/services/update_service.dart` | 350 | Service |
| `lib/core/routes/app_router.dart` | 334 | Router |

---

## Key Technical Decisions

1. **Extraction Strategy**: Extract widgets by logical section/responsibility, not by line count
2. **File Location**: New widgets go in `widgets/` subdirectory of their feature
3. **Naming Pattern**: `<Purpose><Type>.dart` (e.g., `theme_selector.dart`, `account_section.dart`)
4. **State Management**: Keep state in parent where it belongs; pass callbacks down
5. **Progressive Extraction**: One file per implementation unit; verify app compiles after each

---

## Open Questions

### Deferred to Implementation

- Exact component boundaries will be determined during implementation based on actual code structure
- Some files may benefit from more extractions than initially estimated

---

## Implementation Units

### Phase 1: Admin Widgets (Independent of other groups)

#### U1. Refactor question_card.dart (1043 lines)

**Goal:** Extract remaining components from the largest file in the codebase

**Files:**
- Modify: `lib/features/admin/widgets/question_card.dart`
- Create: `lib/features/admin/widgets/question_options_editor.dart`
- Create: `lib/features/admin/widgets/question_header_actions.dart`
- Create: `lib/features/admin/widgets/question_passage_selector.dart`
- Create: `lib/features/admin/widgets/question_settings_panel.dart`

**Approach:**
- Extract options grid/editor to `QuestionOptionsEditor` (handles 4 option inputs)
- Extract header with index and action buttons (delete, duplicate)
- Extract passage selector UI
- Extract settings panel (style toggles, etc.)
- Keep state and core build method in parent

**Patterns to follow:**
- `lib/features/admin/widgets/question_input.dart` (already extracted)
- `lib/features/admin/widgets/options_grid.dart`

**Expected components:** 5-6 total

**Verification:**
- App compiles successfully
- Exam editor still shows question cards correctly
- All question card interactions work (edit, delete, duplicate)

---

#### U2. Refactor exam_editor.dart (473 lines)

**Goal:** Split exam editor into focused sub-components

**Files:**
- Modify: `lib/features/admin/widgets/exam_editor.dart`
- Create: `lib/features/admin/widgets/exam_editor_app_bar.dart`
- Create: `lib/features/admin/widgets/exam_editor_fab.dart`
- Create: `lib/features/admin/widgets/exam_editor_body.dart`

**Approach:**
- Note: This file already imports many extracted components (`ExamSettingsPanel`, `QuestionListPanel`, etc.)
- Extract the remaining inline widgets:
  - AppBar with save/cancel buttons
  - FAB for adding questions
  - Main body layout with TabBarView logic
- Keep state management in `_ExamEditorContentState`

**Patterns to follow:**
- Existing extracted components in same directory

**Expected components:** 3-4 additional

**Verification:**
- App compiles successfully
- Exam editor can create and edit exams
- Preview overlay still works

---

#### U3. Refactor passage_manager.dart (454 lines)

**Goal:** Extract passage management UI components

**Files:**
- Modify: `lib/features/admin/widgets/passage_manager.dart`
- Create: `lib/features/admin/widgets/passage_list_view.dart`
- Create: `lib/features/admin/widgets/passage_editor_form.dart`
- Create: `lib/features/admin/widgets/passage_empty_state.dart`

**Approach:**
- Extract passage list view (shows saved passages)
- Extract passage editor form
- Extract empty state UI
- Keep passage state management in parent if applicable

**Patterns to follow:**
- Similar list+editor patterns in admin widgets

**Expected components:** 3-4 total

**Verification:**
- App compiles successfully
- Passage manager can add/edit/delete passages

---

#### U4. Refactor question_list_panel.dart (334 lines)

**Goal:** Break down question list panel

**Files:**
- Modify: `lib/features/admin/widgets/question_list_panel.dart`
- Create: `lib/features/admin/widgets/question_list_header.dart`
- Create: `lib/features/admin/widgets/question_list_empty.dart`
- Create: `lib/features/admin/widgets/question_nav_controls.dart`

**Approach:**
- Extract header with question count and bulk actions
- Extract empty state (no questions)
- Extract navigation controls (page indicator, next/prev)
- Keep list build logic in parent

**Expected components:** 3-4 total

**Verification:**
- App compiles successfully
- Question list displays and navigates correctly

---

#### U5. Refactor exam_editor_state.dart (315 lines)

**Goal:** Split state management if it contains mixed concerns

**Files:**
- Modify: `lib/features/admin/widgets/exam_editor_state.dart`
- Evaluate: Extract smaller notifiers or use mixins

**Approach:**
- Analyze what state is being managed
- If it mixes exam settings + question list state:
  - Consider `ExamSettingsState` and `QuestionListState`
- If not easily separable, keep as-is but document
- This is a ChangeNotifier - be careful about extraction boundaries

**Expected outcome:** Either 2-3 smaller notifiers OR documented reason to keep as-is

**Verification:**
- App compiles successfully
- All exam editor state operations work

---

### Phase 2: Auth Screens (Independent)

#### U6. Refactor register_screen.dart (714 lines)

**Goal:** Extract multi-step form components

**Files:**
- Modify: `lib/features/auth/register/screens/register_screen.dart`
- Create: `lib/features/auth/register/widgets/step_account_form.dart`
- Create: `lib/features/auth/register/widgets/step_personal_form.dart`
- Create: `lib/features/auth/register/widgets/step_verify_form.dart`
- Create: `lib/features/auth/register/widgets/step_success_view.dart`
- Create: `lib/features/auth/register/widgets/registration_nav_buttons.dart`

**Approach:**
- Note: Some widgets already extracted (`GradeSelector`, `TermsAgreement`, `StepProgressIndicator`)
- Extract each step's form:
  - Step 0: Account form (email, password)
  - Step 1: Personal info (name, username)
  - Step 2: Grade selection + verify
  - Step 3: Success view
- Extract navigation buttons (next/back)
- Keep form validation and step state in parent

**Patterns to follow:**
- `lib/features/auth/register/widgets/` existing widgets

**Expected components:** 4-5 additional

**Verification:**
- App compiles successfully
- Registration flow works end-to-end
- Form validation still works

---

#### U7. Refactor update_confirm_page.dart (697 lines)

**Goal:** Extract update confirmation components

**Files:**
- Modify: `lib/features/auth/update_confirm/screens/update_confirm_page.dart`
- Create: Analyze and name based on content

**Approach:**
- Read full file to understand structure
- Extract by logical sections
- Common patterns in update flows:
  - Update form fields
  - Password confirmation
  - OTP verification
  - Success/error states
- Keep 3-5 focused components

**Verification:**
- App compiles successfully
- Update confirmation flow works

---

#### U8. Refactor forgot_password_overlay.dart (414 lines)

**Goal:** Extract forgot password flow components

**Files:**
- Modify: `lib/features/auth/forgot_password/screens/forgot_password_overlay.dart`
- Create: `lib/features/auth/forgot_password/widgets/forgot_password_email_form.dart`
- Create: `lib/features/auth/forgot_password/widgets/forgot_password_otp_form.dart`
- Create: `lib/features/auth/forgot_password/widgets/forgot_password_reset_form.dart`

**Approach:**
- Typical forgot password has 3 steps:
  1. Enter email
  2. Enter OTP
  3. Set new password
- Extract each step's form
- Keep step navigation in parent

**Expected components:** 3-4 total

**Verification:**
- App compiles successfully
- Forgot password flow works

---

#### U9. Refactor login_screen.dart (371 lines)

**Goal:** Extract login screen components

**Files:**
- Modify: `lib/features/auth/login/screens/login_screen.dart`
- Create: `lib/features/auth/login/widgets/login_form.dart`
- Create: `lib/features/auth/login/widgets/login_header.dart`
- Create: `lib/features/auth/login/widgets/login_footer.dart`

**Approach:**
- Extract header (logo, welcome text)
- Extract form (email, password fields, forgot password link)
- Extract footer (register link)
- Keep auth logic in screen

**Expected components:** 3-4 total

**Verification:**
- App compiles successfully
- Login works

---

### Phase 3: Dashboard Screens (Independent)

#### U10. Refactor settings_screen.dart (737 lines)

**Goal:** Extract settings sections as focused widgets

**Files:**
- Modify: `lib/features/dashboard/settings/screens/settings_screen.dart`
- Create: `lib/features/dashboard/settings/widgets/theme_selector_section.dart`
- Create: `lib/features/dashboard/settings/widgets/performance_mode_section.dart`
- Create: `lib/features/dashboard/settings/widgets/account_settings_section.dart`
- Create: `lib/features/dashboard/settings/widgets/notification_settings_section.dart`
- Create: `lib/features/dashboard/settings/widgets/exam_offline_settings_section.dart`
- Create: `lib/features/dashboard/settings/widgets/about_section.dart`
- Create: `lib/features/dashboard/settings/widgets/logout_button.dart`

**Approach:**
- Screen already has logical sections: Theme, Performance Mode, Account, Notifications, Exams, About, Logout
- Extract each section as a widget
- Pass necessary providers/callbacks via parameters or keep Consumer in parent
- Use StatelessWidgets where possible

**Patterns to follow:**
- Section-based extraction pattern

**Expected components:** 6-8 total

**Verification:**
- App compiles successfully
- All settings sections display and function correctly
- Theme switching works
- Logout works

---

#### U11. Refactor profile_screen.dart (608 lines)

**Goal:** Extract profile screen components

**Files:**
- Modify: `lib/features/dashboard/profile/screens/profile_screen.dart`
- Create: Analyze structure to identify components

**Approach:**
- Read full file to understand structure
- Common profile sections:
  - Header/avatar with user info
  - Stats section (scores, achievements)
  - Edit profile form
  - Action buttons
- Extract each logical section

**Expected components:** 4-6 total

**Verification:**
- App compiles successfully
- Profile displays correctly
- Edit profile works

---

#### U12. Refactor home_screen.dart (582 lines)

**Goal:** Extract home screen sections

**Files:**
- Modify: `lib/features/dashboard/home/screens/home_screen.dart`
- Create: Analyze structure

**Approach:**
- Home screens typically have:
  - Welcome/header section
  - Quick actions/navigation cards
  - Recent exams/activity
  - Featured content
- Extract each section

**Expected components:** 4-6 total

**Verification:**
- App compiles successfully
- Home screen displays correctly
- Navigation works

---

#### U13. Refactor leaderboard_screen.dart (353 lines)

**Goal:** Extract leaderboard components

**Files:**
- Modify: `lib/features/dashboard/leaderboard/screens/leaderboard_screen.dart`
- Create: `lib/features/dashboard/leaderboard/widgets/leaderboard_rankings_list.dart`
- Create: `lib/features/dashboard/leaderboard/widgets/leaderboard_user_rank.dart`
- Create: `lib/features/dashboard/leaderboard/widgets/leaderboard_filter.dart`

**Approach:**
- Extract rankings list
- Extract current user's rank display
- Extract filter/tab controls
- Keep loading/error state logic in screen

**Expected components:** 3-4 total

**Verification:**
- App compiles successfully
- Leaderboard displays correctly

---

### Phase 4: Exam Screens (Independent)

#### U14. Refactor exam_interaction_screen.dart (692 lines)

**Goal:** Split exam interaction into focused components

**Files:**
- Modify: `lib/features/dashboard/exams/screens/exam_interaction_screen.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_timer_display.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_question_display.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_question_navigator.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_progress_indicator.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_submit_button.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_loading_state.dart`

**Approach:**
- Extract timer display
- Extract question display (question text + options)
- Extract navigator (next/prev/jump to question)
- Extract progress indicator
- Extract submit button
- Keep exam state logic in parent

**Patterns to follow:**
- `lib/features/dashboard/exams/widgets/result_share_card.dart` (existing)

**Expected components:** 5-7 total

**Verification:**
- App compiles successfully
- Exam taking works end-to-end
- Timer counts down correctly
- Answer selection works
- Submit works

---

#### U15. Refactor exam_result_screen.dart (499 lines)

**Goal:** Extract exam result components

**Files:**
- Modify: `lib/features/dashboard/exams/screens/exam_result_screen.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_result_header.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_result_score.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_result_breakdown.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_result_actions.dart`

**Approach:**
- Extract header with exam title
- Extract score display (score + percentage)
- Extract breakdown (correct/incorrect counts, per-category)
- Extract action buttons (review, share, home)

**Expected components:** 4-5 total

**Verification:**
- App compiles successfully
- Exam results display correctly
- Share and review work

---

#### U16. Refactor exam_details_screen.dart (399 lines)

**Goal:** Extract exam details components

**Files:**
- Modify: `lib/features/dashboard/exams/screens/exam_details_screen.dart`
- Create: Analyze structure

**Approach:**
- Common exam details sections:
  - Exam info header
  - Description/about
  - Question list/preview
  - Start exam button
- Extract each

**Expected components:** 3-4 total

**Verification:**
- App compiles successfully
- Exam details display correctly
- Start exam works

---

#### U17. Refactor exams_screen.dart (392 lines)

**Goal:** Extract exams list components

**Files:**
- Modify: `lib/features/dashboard/exams/screens/exams_screen.dart`
- Create: `lib/features/dashboard/exams/widgets/exams_list.dart`
- Create: `lib/features/dashboard/exams/widgets/exam_card_item.dart`
- Create: `lib/features/dashboard/exams/widgets/exams_filter.dart`

**Approach:**
- Extract exams list
- Extract individual exam card
- Extract filter/tabs
- Keep loading state in screen

**Note:** If `exam_card_item` already exists, skip and extract other pieces

**Expected components:** 3-4 total

**Verification:**
- App compiles successfully
- Exams list displays correctly
- Filtering works

---

#### U18. Refactor score_repository.dart (383 lines)

**Goal:** Split repository by concern (not widgets)

**Files:**
- Modify: `lib/features/dashboard/exams/repositories/score_repository.dart`
- Evaluate: Extract smaller services

**Approach:**
- This is a repository, not a widget - different refactoring pattern
- Analyze concerns:
  - Local storage (SharedPreferences)
  - Sync with Supabase
  - Score calculations
- Consider:
  - `ScoreLocalStorageService`
  - `ScoreSyncService`
- Or keep as single repo but document

**Expected outcome:** 2-3 focused files OR documented reason to keep

**Verification:**
- App compiles successfully
- Score sync works
- Score retrieval works

---

#### U19. Refactor exam_model.dart (310 lines)

**Goal:** Extract sub-models or serialization helpers

**Files:**
- Modify: `lib/features/dashboard/exams/models/exam_model.dart`
- Evaluate: Extract sub-models

**Approach:**
- Look for nested model classes: `Question`, `Option`, etc.
- If the file contains multiple freezed classes or model classes:
  - Extract to separate files
  - Or keep in same file but document structure
- Consider serialization helpers as separate if large

**Expected outcome:** Cleaner model organization

**Verification:**
- App compiles successfully
- Model deserialization still works

---

### Phase 5: Core & Providers (Independent)

#### U20. Refactor auth_provider.dart (529 lines)

**Goal:** Split ChangeNotifier by concern

**Files:**
- Modify: `lib/providers/auth_provider.dart`
- Evaluate: Extract smaller notifiers or use mixins

**Approach:**
- This is a ChangeNotifier - carefully analyze state boundaries
- Look at methods:
  - `signIn`, `signUp` - authentication
  - `verifyEmail`, `resendOTP` - verification
  - `signOut` - session management
  - `updateProfile`, `updatePassword` - account management
  - Arabic error mapping
- Consider:
  - Keep single AuthProvider for now (state is shared)
  - OR: Extract `AuthService` class for pure auth logic
  - Extract Arabic error mapper as separate utility
- Extract `_getArabicError` as a utility first

**Expected outcome:** Cleaner separation between UI state and auth logic

**Verification:**
- App compiles successfully
- Login works
- Registration works
- Profile updates work

---

#### U21. Refactor dashboard_shell.dart (429 lines)

**Goal:** Extract shell navigation components

**Files:**
- Modify: `lib/features/dashboard/screens/dashboard_shell.dart`
- Create: `lib/features/dashboard/widgets/dashboard_bottom_nav.dart`
- Create: `lib/features/dashboard/widgets/dashboard_navigation_rail.dart`
- Create: `lib/features/dashboard/widgets/dashboard_app_bar.dart`

**Approach:**
- Shell typically has:
  - Bottom navigation bar (mobile)
  - Navigation rail (tablet/desktop)
  - App bar
- Extract each navigation component
- Keep navigation state in shell

**Expected components:** 3-4 total

**Verification:**
- App compiles successfully
- Bottom nav works
- Navigation between tabs works

---

#### U22. Refactor update_service.dart (350 lines)

**Goal:** Split update service by concern

**Files:**
- Modify: `lib/core/services/update_service.dart`
- Evaluate: Extract smaller services

**Approach:**
- Analyze concerns:
  - Checking for updates
  - Downloading updates
  - Installing updates
  - Force update logic
- Consider:
  - `UpdateChecker`
  - `UpdateInstaller`
  - Keep single service if highly cohesive

**Expected outcome:** Cleaner organization

**Verification:**
- App compiles successfully

---

#### U23. Refactor app_router.dart (334 lines)

**Goal:** Split routes by feature module

**Files:**
- Modify: `lib/core/routes/app_router.dart`
- Create: `lib/core/routes/routes/auth_routes.dart`
- Create: `lib/core/routes/routes/dashboard_routes.dart`
- Create: `lib/core/routes/routes/admin_routes.dart`
- Keep main router definition

**Approach:**
- Group routes by feature:
  - Auth routes: login, register, forgot password
  - Dashboard routes: home, exams, profile, settings
  - Admin routes: exam editor, teacher settings
- Extract each group as a GoRoute list or function
- Import and combine in main app_router.dart

**Patterns to follow:**
- Typical Flutter route modularization patterns

**Expected components:** 3-4 route modules

**Verification:**
- App compiles successfully
- All navigation works
- Deep links still work (if applicable)

---

## System-Wide Impact

- **No API changes**: All component extractions preserve public APIs
- **No behavior changes**: Pure refactoring - functionality remains identical
- **Import updates**: Parent files will import extracted widgets
- **No state management changes**: Provider architecture preserved

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Accidentally changing behavior during extraction | Verify app compiles and key scenarios work after each unit |
| Extracting too aggressively creating too many tiny files | Target 3-10 components per file; stop when diminishing returns |
| Import cycles when extracting | Keep dependency graph unidirectional (widgets don't import screens) |

## Sources & References

- Existing pattern: `question_card.dart` → `question_input.dart`, `question_card_extras.dart`
- Existing widget organization: `lib/features/<feature>/widgets/`
- Project already uses Provider + GoRouter + Supabase
