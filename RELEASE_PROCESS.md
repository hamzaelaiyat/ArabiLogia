# ArabiLogia Release Process

## Overview

This document describes how to release new versions of ArabiLogia with automatic update detection.

## How Updates Work

1. **Detection**: When the app starts, it checks GitHub Releases for the latest version
2. **Comparison**: It compares the latest release tag with the current app version
3. **Notification**: If a newer version exists, users see a dialog with 3 options:
   - **تحديث الآن** (Update Now) - Downloads and installs the new APK
   - **Remind me Later** - Reminds on next app launch
   - **Skip this Update** - Skips this version permanently

## Release Checklist

### Step 1: Prepare the Release

```bash
# Navigate to project directory
cd /mnt/Storage/projects/ArabiLogia

# Run the release script
./scripts/generate_release.sh 1.2.0 "Added new exam categories"
```

This will:
- Clean and rebuild the app
- Generate an optimized APK (~30-40MB instead of 170MB)
- Create `arabilogia-1.2.0-arm64-v8a.apk`

### Step 2: Create GitHub Release

1. Go to: https://github.com/hamzaelaiyat/ArabiLogia/releases
2. Click **"Draft a new release"**
3. Fill in:
   - **Tag version**: `v1.2.0` (must start with `v`)
   - **Release title**: `Version 1.2.0`
   - **Description**: Release notes
4. Upload the generated APK file
5. Click **"Publish release"**

### Step 3: Verify

The app will automatically detect the new release on next launch!

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **Major** (1.0.0 → 2.0.0): Breaking changes, major features
- **Minor** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch** (1.0.0 → 1.0.1): Bug fixes only

## APK Size Optimization

The build uses ABI splits to generate smaller APKs:
- **Full APK**: ~170MB (all architectures)
- **arm64-v8a only**: ~30-40MB (recommended for Egypt)

This significantly reduces:
- Download time
- Data costs for users
- Storage space on device

## Troubleshooting

### Update not detected?
- Ensure the release tag starts with `v` (e.g., `v1.2.0`)
- Check the APK was uploaded to the release
- Verify `update_service.dart` has the correct repo URL

### Download fails?
- The app uses `app_installer_plus` which requires:
  - Storage permission (for APK download)
  - Install permission (for APK installation)
- These are handled automatically by the package

### User clicks "Skip this Update"?
- The version is stored in SharedPreferences
- They will still be notified of future updates

## Manual Release (Without Script)

If you prefer manual control:

```bash
# Build APK
flutter build apk --release --split-per-abi

# Find APK
ls build/app/outputs/flutter-apk/

# Rename for clarity
mv app-release.apk arabilogia-VERSION-arm64-v8a.apk
```

Then upload manually to GitHub Releases.

## Current Configuration

- **Repository**: https://github.com/hamzaelaiyat/ArabiLogia
- **Update Check URL**: GitHub Releases API
- **Target Architecture**: arm64-v8a (Android 8.0+)
- **Minimum Android**: API 21 (Android 5.0)