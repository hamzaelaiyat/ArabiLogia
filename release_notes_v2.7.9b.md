## 🐛 Bug Fixes

### 🔒 Privacy Settings Fix
- Fixed "Failed to update data" error when toggling **Hide my profile** or **Hide my Name** in student settings.
- Privacy fields were incorrectly being sent to Supabase Auth metadata, causing silent failures. They now only update the `profiles` table.

### 📲 Update System Fix
- Fixed the version comparison logic that caused the app to falsely show an "update available" notification even when already on the latest version.
- **Root cause**: Version strings from `PackageInfo` (e.g., `2.7.9-b`) were incorrectly cleaned to `2.7.9-` due to a regex that didn't handle the hyphen before the letter suffix, causing the comparison to always detect a newer version.

---

## 📦 Maintenance
- Version bumped to **v2.7.9b**
- Build artifacts: arm64-v8a, armeabi-v7a, x86_64 APKs, Linux .tar.xz & .deb

---

## 📄 Commit Log
| Hash | Date | Subject |
| :--- | :--- | :--- |
| `572e291` | 2026-05-09 | fix: remove privacy fields from auth metadata to prevent update failure |
| *(next)* | 2026-05-09 | fix: correct version comparison regex to handle `-b` suffix |
