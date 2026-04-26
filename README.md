# ArabiLogia (عربيلوجيا)

A Flutter mobile application for learning Arabic language, featuring grammar, morphology, literature, poetry, and reading comprehension exercises for high school students (Grades 10-12).

## Features

- **Authentication** - User registration and login with email/password
- **Exam Categories**:
  - النحو (Grammar)
  - الصرف (Morphology)
  - الأدب (Literature)
  - الشعر (Poetry)
  - القراءة والنصوص (Reading & Texts)
- **Dashboard** - Home, Tasks, Leaderboard, and Profile sections
- **Settings** - Theme customization (Light/Dark/System), notifications, privacy
- **Bilingual UI** - Full Arabic interface with RTL support

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Backend**: Supabase (Auth, Database)
- **Architecture**: Feature-based clean architecture

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart 3.x
- Supabase account

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Supabase:
   - Create a Supabase project
   - Update `lib/core/config/supabase_config.dart` with your credentials
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── config/       # Supabase configuration
│   ├── constants/    # App strings and routes
│   ├── routes/       # App routing
│   ├── services/     # API services
│   └── theme/        # Theme configuration
├── features/
│   ├── auth/         # Login, Register, Forgot Password
│   └── dashboard/    # Home, Tasks, Leaderboard, Profile, Settings
├── providers/        # Riverpod providers
└── main.dart         # App entry point
```

## License

MIT