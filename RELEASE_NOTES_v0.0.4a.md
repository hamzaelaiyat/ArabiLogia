## ✨ New Features

### Google AdMob Native Advanced Ads
- Integrated Google Mobile Ads SDK for monetization
- Native Advanced Ads displayed in exams list
- Mode-based ad frequency:
  - **Normal mode**: Ad every 5 exams
  - **Sweet potato mode**: Ad every 3 exams
  - **Tiny potato mode**: Ad every 2 exams

---

## 🐛 Bug Fixes (31 Issues Fixed)

### Critical Issues (8 Fixed)
1. ✅ Fixed broken "Retake Exam" button - Wrong route name
2. ✅ Fixed option ID mismatch after shuffle restore
3. ✅ Fixed race condition - unawaited score sync
4. ✅ Fixed null safety crash - byteData crash
5. ✅ Fixed firstWhere crash if no correct answer
6. ✅ Fixed memory leak - TapGestureRecognizer not disposed
7. ✅ Fixed Dropdown initialValue bug - Invalid parameter
8. ✅ Fixed Supabase not configured null

### High Priority (8 Fixed)
1. ✅ Added form validation for correct answer selection
2. ✅ Added error feedback for forgot password
3. ✅ Replaced hardcoded route with constant
4. ✅ Fixed dialog context handling
5. ✅ Fixed question ID fallback
6. ✅ Added try-catch to exams fetch
7. ✅ Fixed stats key mismatch
8. ✅ Fixed grade text display "0ث" issue

### Medium Priority (10 Fixed)
1. ✅ Timer now pauses when app goes to background
2. ✅ Score sync failures now reported
3. ✅ Removed theme toggle snackbar annoyance
4. ✅ Potato mode now persisted
5. ✅ Fixed animations toggle logic
6. ✅ Added notification toggle feedback
7. ✅ Fixed wrong category IDs
8. ✅ Added pull-to-refresh to home screen
9. ✅ Fixed wrong navigation in exam preview
10. ✅ Consolidated ScoreRepository instances

### Low Priority (5 Fixed)
1. ✅ Use dynamic date in legal bottom sheet
2. ✅ Cleaned ZWNJ characters from Arabic text
3. ✅ Removed duplicate colors
4. ✅ Removed unused code
5. ✅ Fixed wrong translation

---

## 📦 Changes

### Dependencies Added
- `google_mobile_ads: ^5.1.0`

### Files Modified
| File | Changes |
|------|---------|
| `pubspec.yaml` | Added google_mobile_ads package |
| `AndroidManifest.xml` | Added AdMob App ID & INTERNET permission |
| `main.dart` | Mobile Ads SDK initialization |
| `exams_screen.dart` | Mode-based ad placement logic |
| `proguard-rules.pro` | Added Google Mobile Ads rules |

### Files Added
| File | Description |
|------|-------------|
| `native_ad_widget.dart` | Native Advanced Ad component |

---

## 🔧 Technical Details

### Build Configuration
- **Target Architecture**: arm64-v8a (Android 8.0+)
- **APK Size**: ~30-40MB (optimized with ABI splits)

### Ad Placement UX
- Ads appear naturally between exam items
- Frequency adapts to user's device performance mode
- Less frequent ads for normal users, more for potato mode users

---

## 📱 Compatibility

- **Minimum Android**: API 21 (Android 5.0)
- **Target Android**: API 34 (Android 14)
- **Flutter SDK**: ^3.11.4

---

*Built with ❤️ for Arabic language education*
