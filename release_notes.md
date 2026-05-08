## 🚀 Major Features & Enhancements

### 🛡️ Student Privacy & Leaderboard Anonymity
- **Privacy Toggles**: Added `hide_name` and `random_name` options for student profiles.
- **Anonymous Name Generator**: Implemented a creative generator using 120 animals, 60 feelings, and a random number range (2-999) with star flairs for unique identities.
- **RPC Integration**: Created a `SECURITY DEFINER` RPC to ensure unique anonymous name assignment.
- **Leaderboard UI**:
    - Current user highlight with tinted background and border.
    - Instant local state toggle with background synchronization.
    - Fixed RLS recursion issues for teacher-profile visibility.

### 🖼️ Enhanced Media Support
- **Image-Only Paragraphs**: Teachers can now add paragraphs consisting solely of images via a gallery picker.
- **Zoomable Image Viewer**: Integrated a viewer with pinch-to-zoom and pan gestures for better content inspection.
- **Passage Model Updates**: Added `imageUrl` support to the core passage model.

### ✍️ Exam Editor Overhaul
- **Full RTL Support**: Comprehensive implementation of `TextDirection.rtl` across the editor.
- **Interactive Formatting**: Added a Stack-based formatting toolbar at the bottom-left for real-time text styling.
- **Editable Points**: Teachers can now edit question points via a dedicated bottom sheet (Range: 0.5 to 10.0).
- **Preview System (Beta)**: Added a question preview modal directly within the question card WITHOUT FORMATING (Coming Soon to the public).

---

## 🛠️ Refactoring & Architecture (The Great Extraction)
Significant effort was spent decomposing monolithic files into modular, maintainable components.

### 🧩 Component Extractions
- **Admin Widgets**: Extracted 17+ components from files like `question_card.dart` and `exam_editor.dart`.
    - *Key extractions*: `question_options_editor.dart`, `question_preview_dialog.dart`, `exam_editor_desktop_layout.dart`.
- **Auth System**: Extracted 14+ components from registration and login screens.
    - *Key extractions*: `auth_text_field.dart`, `step_header.dart`, `release_notes_card.dart`.
- **Dashboard & Settings**: Extracted 22+ components.
    - *Key extractions*: `theme_selector.dart`, `privacy_section.dart`, `home_welcome_card.dart`, `recent_activity_section.dart`.
- **Exam Screens**: Extracted 16+ components from interaction and result screens.
    - *Key extractions*: `exam_timer.dart`, `score_summary_widget.dart`, `grade_mapper.dart`.

---

## 🔧 Bug Fixes & UI Polish

### 🐞 Critical Fixes
- **Focus Preservation**: Fixed a major UX issue where focus was lost in the exam editor's text fields during keystrokes (resolved via `ValueKey`, `FocusNode`, and stable IDs).
- **State Mutation**: Resolved `ReorderableListView` mutation errors.
- **Syntax & Logic**: Fixed syntax errors in `auth_provider.dart` and initialized categories with defaults to prevent empty list crashes.
- **RLS Policies**: Fixed infinite recursion in database policies.

### 💄 UI/UX Improvements
- **Terminology**: Renamed المقروءات to **الفقرات** for better clarity.
- **Layout Alignment**:
    - Moved sidebars and sub-sidebars to the right side for consistent RTL experience.
    - Fixed RTL alignment issues in `InsetToggle` and mobile navigation.
- **Interactions**: Improved `PassageManager` with better card layouts, bottom sheets, and dismissible delete actions with confirmation.

---

## 📦 Maintenance & Chore
- **Version Bump**: Released `v0.0.48b`.
- **Documentation**: 
    - Full Arabic translation for `README.md`.
    - Revised title and branding with a new logo.
- **CI/CD Cleanup**: Removed redundant deployment scripts and GitHub workflows to streamline the build process.
- **AgentSync**: Removed `AGENTS.md` and optimized agent-related configurations.

---

## 📄 Commit Log Summary
| Hash | Date | Subject |
| :--- | :--- | :--- |
| `9009565` | 2026-05-08 | refactor(exams): extract 16 components from exam screens |
| `689c8ad` | 2026-05-08 | refactor(dashboard): extract 22 components from dashboard screens |
| `dac6f6b` | 2026-05-08 | refactor(auth): extract 14 components from auth screens |
| `1d7d89d` | 2026-05-08 | refactor(admin): extract 17 components from admin widgets |
| `eec1e04` | 2026-05-08 | feat: add student privacy toggles with random anonymous name |
| `265e516` | 2026-05-08 | feat: add image-only paragraphs with zoomable viewer |
| `dfb8eda` | 2026-05-08 | fix: rename to الفقرات, improve UI, fix mobile toggle |
| `70da007` | 2026-05-08 | feat: improve exam editor with RTL support, editable points |
| `9637152` | 2026-05-06 | fix: preserve focus in exam editor question text field |
| `c7f7044` | 2026-05-06 | chore: bump version to 0.0.48b |
| `921463f` | 2026-05-02 | chore: release v0.0.33 |
| `284f993` | 2026-05-02 | docs: add Arabic README translation |
