# ArabiLogia (عربيلوجيا)

A Flutter mobile application for learning Arabic language, featuring grammar, morphology, literature, poetry, and reading comprehension exercises for high school students (Grades 10-12).

## Features

- **Authentication** - User registration and login with email/password, grade selection, terms agreement
- **Exam Categories**:
  - النحو (Grammar)
  - الصرف (Morphology)
  - الأدب (Literature)
  - الشعر (Poetry)
  - القراءة والنصوص (Reading & Texts)
- **Dashboard** - Home, Tasks, Leaderboard, and Profile sections
- **Exam System** - Interactive exams with multiple question styles, timer, instant results
- **Admin Panel** - Teacher/Admin exam management, question editor, passage manager, results viewer
- **Activity History** - Track completed exams and performance over time
- **Settings** - Theme customization (Light/Dark/System), notifications, privacy, potato mode
- **Bilingual UI** - Full Arabic interface with RTL support
- **Mobile Features** - Push notifications, sharing results, in-app updates

## Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Provider
- **Routing**: GoRouter
- **Backend**: Supabase (Auth, Database)
- **Ads**: Google Mobile Ads
- **Architecture**: Feature-based clean architecture

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart 3.x
- Supabase account

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/hamzaelaiyat/ArabiLogia.git
   cd ArabiLogia
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Supabase:
   - Create a Supabase project
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Update `.env` with your Supabase credentials:
     ```
     SUPABASE_URL=https://your-project.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     ```

4. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

```bash
flutter build apk --release
flutter build ipa --release  # iOS (requires macOS)
```

## Project Structure

```
lib/
├── core/
│   ├── config/         # Supabase configuration
│   ├── constants/      # App strings, routes, legal content
│   ├── routes/         # App routing (GoRouter)
│   ├── services/       # API services (Supabase, notifications, etc.)
│   ├── theme/         # Theme configuration (light/dark/tokens)
│   └── widgets/        # Shared widgets (glass components, native ads)
├── features/
│   ├── admin/         # Teacher/Admin panel (exam editor, results, settings)
│   ├── auth/          # Login, Register, Forgot Password
│   ├── dashboard/     # Main app (home, exams, leaderboard, profile, history)
│   └── legal/          # Legal content and bottom sheet
├── providers/          # Riverpod/Provider state management
└── main.dart          # App entry point
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |

## Version

Current version: **0.0.26*****

## License

MIT
