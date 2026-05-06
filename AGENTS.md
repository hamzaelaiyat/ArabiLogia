# ArabiLogia Agent Instructions

## Deployment Workflow

When user says "deploy v{version}" (e.g., "deploy v0.0.49"):

1. **Commit current changes** to GitHub with message "release v{version}"
2. **Tag the commit** with v{version}
3. **Run deployment script** that builds:
   - Android APK (arm64-v8a, armeabi-v7a, x86_64)
   - Linux (.deb, .tar.xz, .appimage)
4. **Deploy to Vercel** for web

## Build Commands

```bash
# Android
flutter build apk --release --split-per-abi

# Linux
flutter build linux --release

# Package Linux
tar -cJf arabilogia-v{version}-linux-x64.tar.xz -C build/linux/x64/release/bundle .
dpkg-deb --build ...
```

## Version Management

- Update version in pubspec.yaml
- Update version in lib/core/constants/legal_content.dart
- Update version in lib/features/dashboard/screens/dashboard_shell.dart