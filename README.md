<p align="center">
  <img src="https://github.com/hamzaelaiyat/ArabiLogia/blob/main/assets/images/logo-removedbg.png" width="200">
</p>
<h1 align="center">ArabiLogia Platform</h1>

A Flutter mobile application for **learning Arabic language**, featuring *grammar*, *morphology*, *literature*, *poetry*, and reading comprehension exercises for high school students.

## Features

- **Authentication** - User registration and login with email/password, grade selection, terms agreement
- **Exam Categories**:
  - النحو (Grammar)
  - الصرف (Morphology)
  - الأدب (Literature)
  - الشعر (Poetry)
  - القراءة (Reading)
  - النصوص (Text)
- **Dashboard** - Home, Lectures, Leaderboard, Profile, and Settings sections
- **Exam System** - Interactive exams with multiple question styles, timer, instant results, and quick preview
- **Lecture System** - Video lectures with YouTube integration, practice quizzes, and content blocks
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

3. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

4. Update `.env` with your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

5. Run the app:
   
   ```bash
   flutter run
   ```

### Building for Release

```bash
flutter build apk --release --split-per-abi  # Android APKs (arm64-v8a, armeabi-v7a, x86_64)
flutter build linux --release                 # Linux tar.xz
flutter build web --release                   # Web (Vercel)
```

## Project Structure

```
lib/
├── core/
│   ├── config/         # Supabase configuration
│   ├── constants/      # App strings, routes, legal content
│   ├── routes/         # App routing (GoRouter)
│   ├── services/       # API services (Supabase, notifications, etc.)
│   ├── theme/          # Theme configuration (light/dark/tokens)
│   └── widgets/        # Shared widgets (glass components, native ads)
├── features/
│   ├── auth/           # Login, Register, Forgot Password
│   ├── dashboard/      # Main app (home, exams, lectures, leaderboard, profile, history)
│   └── legal/          # Legal content and bottom sheet
├── providers/          # Provider state management
└── main.dart           # App entry point
```

## Environment Variables

| Variable            | Description               |
| ------------------- | ------------------------- |
| `SUPABASE_URL`      | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key    |

## Version

Current version: **26.8.18**

## License

MIT
