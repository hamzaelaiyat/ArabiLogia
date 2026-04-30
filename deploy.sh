#!/bin/bash

# ============================================
# ArabiLogia Deploy Script v6.7
# Ultra Clean + Gradle Daemon Killer
# ============================================

# --- Theme Configuration ---
export GUM_CHOOSE_CURSOR_FOREGROUND="212"
export GUM_CHOOSE_SELECTED_FOREGROUND="212"
export GUM_SPIN_SPINNER_FOREGROUND="212"
export GUM_INPUT_CURSOR_FOREGROUND="212"
export GUM_INPUT_PROMPT_FOREGROUND="212"

# --- Helper Functions ---
find_flutter() {
    local paths=("flutter" "/mnt/Storage/flutter-files/flutter/bin/flutter" "$HOME/flutter/bin/flutter")
    for p in "${paths[@]}"; do
        if command -v "$p" &> /dev/null; then
            echo "$p"
            return
        fi
    done
}

get_arabic_date() {
    local months=("يناير" "فبراير" "مارس" "أبريل" "مايو" "يونيو" "يوليو" "أغسطس" "سبتمبر" "أكتوبر" "نوفمبر" "ديسمبر")
    local m=$(date +"%m")
    local y=$(date +"%Y")
    echo "${months[$((10#$m-1))]} $y"
}

update_version_files() {
    local ver="$1"
    local r_date="$2"
    local legal_file="lib/core/constants/legal_content.dart"
    local shell_file="lib/features/dashboard/screens/dashboard_shell.dart"

    [ -f "$legal_file" ] && sed -i "s/'الإصدار الحالي: v[0-9.]* | تاريخ الإصدار: [^}]*'/'الإصدار الحالي: v$ver | تاريخ الإصدار: $r_date'/" "$legal_file"
    [ -f "$shell_file" ] && sed -i "s/'v[0-9.]*'/'v$ver'/" "$shell_file"
    
    echo "✅ Version files updated to v$ver"
}

# --- Initialization ---
clear

chafa --size 40x assets/images/logo-removedbg.png


FLUTTER=$(find_flutter)
GH_AVAILABLE=$(command -v gh &> /dev/null && echo true || echo false)

# Environment Check
echo -e "\n🔍 Checking Environment..."
[ -z "$FLUTTER" ] && { echo "❌ Flutter not found"; exit 1; }
command -v gum &> /dev/null || { echo "❌ gum not found"; exit 1; }
echo "   ✅ Flutter: $FLUTTER"
echo "   ✅ gum: Ready"

# ============================================
# Interactive Configuration
# ============================================

echo -e "\n📋 DEPLOYMENT CONFIGURATION\n"

# Check if TTY is available
if [ -t 0 ]; then
    # Interactive mode
    VERSION=$(gum input --placeholder "e.g. 1.2.3" --prompt "🔖 Version: → ")
    VERSION=${VERSION:-"0.0.1"}
    echo "📝 RELEASE NOTES"
    NOTES=$(gum write --placeholder "• List changes here..." --height 5)
    echo "📱 ANDROID ARCHITECTURES"
    ANDROID_ARCHS=$(gum choose --no-limit --selected "arm64-v8a" "arm64-v8a" "armeabi-v7a" "x86_64")
    
    LINUX_BUILDS=""
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "🐧 LINUX BUILDS"
        LINUX_BUILDS=$(gum choose --no-limit --selected "deb" "tar" "deb" "appimage" "rpm")
    fi
    
    PUBLISH="no"
    if [ "$GH_AVAILABLE" = true ]; then
        gum confirm "🚀 Publish to GitHub?" && PUBLISH="yes"
    fi
else
    # Non-interactive mode - use defaults
    # Try to get version from pubspec.yaml if available
    if [ -f "pubspec.yaml" ]; then
        VERSION=$(grep -m1 "^version:" pubspec.yaml | awk '{print $2}' || echo "0.0.1")
    else
        VERSION="0.0.1"
    fi
    echo "📝 RELEASE NOTES"
    NOTES="Build from non-interactive mode"
    echo "📱 ANDROID ARCHITECTURES"
    ANDROID_ARCHS="arm64-v8a armeabi-v7a x86_64"
    echo "   → Using: $ANDROID_ARCHS"
    
    echo "🐧 LINUX BUILDS"
    LINUX_BUILDS="tar"
    echo "   → Using: $LINUX_BUILDS"
    
    PUBLISH="no"
fi

# ============================================
# Execution
# ============================================

set -e
RELEASE_DATE=$(get_arabic_date)
OUTPUT_DIR="build/release_v$VERSION"
mkdir -p "$OUTPUT_DIR"

update_version_files "$VERSION" "$RELEASE_DATE"

# --- Ultra Clean Procedure ---
echo -e "\n🧹 Killing Gradle Daemons & Clearing Cache..."
set +e
# قتل أي عملية Gradle خلفية قد تكون ماسكة الـ locks
pkill -f gradle || true

# حذف ملفات الـ lock والـ checksums المسببة للمشكلة
echo "   🗑️ Removing locks and checksums..."
rm -rf android/.gradle
rm -f android/gradlew
find android -name "*.lock" -type f -delete
find android -name "checksums" -type d -exec rm -rf {} + 2>/dev/null || true

gum spin --spinner dot --title "Flutter Cleaning..." -- "$FLUTTER" clean > /dev/null 2>&1
gum spin --spinner dot --title "Syncing Dependencies..." -- "$FLUTTER" pub get > /dev/null 2>&1
set -e

# Android Build
if [ -n "$ANDROID_ARCHS" ]; then
    echo "📱 Building Android APKs (No-Daemon Mode)..."
    # Disable Gradle daemon via properties to avoid file locks (only if not already present)
    if ! grep -q "org.gradle.daemon=false" android/gradle.properties 2>/dev/null; then
        echo "org.gradle.daemon=false" >> android/gradle.properties
    fi
    gum spin --spinner dot --show-error --title "Building Release APK..." -- "$FLUTTER" build apk --release --split-per-abi
    
    for arch in $ANDROID_ARCHS; do
        APK=$(find build/app/outputs/flutter-apk -name "*${arch}*-release.apk" | head -1)
        if [ -n "$APK" ]; then
            # Ensure output directory exists
            mkdir -p "$OUTPUT_DIR"
            cp "$APK" "$OUTPUT_DIR/arabilogia-v${VERSION}-${arch}.apk"
            echo "   ✅ $arch: $(du -h "$APK" | cut -f1)"
        else
            echo "   ⚠️  $arch: APK not found!"
        fi
    done
fi

# Linux Build
if [ -n "$LINUX_BUILDS" ]; then
    echo "🐧 Building Linux..."
    gum spin --spinner dot --show-error --title "Building Linux App..." -- "$FLUTTER" build linux --release
    BUNDLE="build/linux/x64/release/bundle"
    # Ensure output directory exists
    mkdir -p "$OUTPUT_DIR"
    if [ -d "$BUNDLE" ]; then
        for fmt in $LINUX_BUILDS; do
            case "$fmt" in
                tar) tar -cJf "$OUTPUT_DIR/arabilogia-v${VERSION}-linux-x64.tar.xz" -C "$BUNDLE" . ;;
                deb)
                    DEB_ROOT="build/deb_tmp"
                    mkdir -p "$DEB_ROOT/usr/bin/arabilogia" "$DEB_ROOT/DEBIAN"
                    cp -r "$BUNDLE/"* "$DEB_ROOT/usr/bin/arabilogia/"
                    echo -e "Package: arabilogia\nVersion: $VERSION\nSection: education\nPriority: optional\nArchitecture: amd64\nMaintainer: Hamza\nDescription: ArabiLogia" > "$DEB_ROOT/DEBIAN/control"
                    dpkg-deb --build "$DEB_ROOT" "$OUTPUT_DIR/arabilogia-v${VERSION}-amd64.deb" &> /dev/null
                    rm -rf "$DEB_ROOT" ;;
            esac
        done
    else
        echo "   ⚠️  Linux build directory not found: $BUNDLE"
    fi
fi

# GitHub Release
if [ "$PUBLISH" == "yes" ]; then
    echo "🚀 Publishing..."
    git add . && git commit -m "chore: release v$VERSION" --allow-empty
    git tag -a "v$VERSION" -m "$NOTES" && git push origin main --tags
    gh release create "v$VERSION" "$OUTPUT_DIR"/* --title "v$VERSION ($RELEASE_DATE)" --notes "$NOTES"
fi

echo -e "\n📦 Artifacts in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR" | awk '{print "   " $5 "\t" $9}'
echo -e "\n"
gum style --foreground 212 --bold --border double --padding "1 2" --align center "✨ DONE"
