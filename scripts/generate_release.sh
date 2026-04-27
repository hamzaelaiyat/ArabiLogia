#!/bin/bash

# ArabiLogia Release Generation Script
# This script builds the APK with optimizations and prepares it for GitHub Release

set -e

echo "=========================================="
echo "  ArabiLogia Release Generator"
echo "=========================================="

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./generate_release.sh <version> [notes]"
    echo "Example: ./generate_release.sh 1.2.0 'Added new exam categories'"
    exit 1
fi

VERSION=$1
NOTES=${2:-"Bug fixes and performance improvements"}

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build optimized APK with ABI splits (arm64-v8a only for smaller size)
echo "🔨 Building APK for arm64-v8a..."
flutter build apk --release --split-per-abi

# Find the generated APK
APK_DIR="build/app/outputs/flutter-apk"
ARM64_APK=$(find "$APK_DIR" -name "*arm64-v8a*.apk" | head -1)

if [ -z "$ARM64_APK" ]; then
    echo "❌ Error: Could not find arm64-v8a APK"
    exit 1
fi

# Get APK size
APK_SIZE=$(du -h "$ARM64_APK" | cut -f1)
echo "✅ APK built: $ARM64_APK"
echo "📏 APK Size: $APK_SIZE"

# Rename to include version
FINAL_APK="arabilogia-${VERSION}-arm64-v8a.apk"
cp "$ARM64_APK" "$FINAL_APK"

echo ""
echo "=========================================="
echo "  Release Ready!"
echo "=========================================="
echo "📦 APK: $FINAL_APK"
echo "📏 Size: $APK_SIZE"
echo ""
echo "Next steps:"
echo "1. Go to: https://github.com/hamzaelaiyat/ArabiLogia/releases"
echo "2. Click 'Draft a new release'"
echo "3. Tag version: v$VERSION"
echo "4. Upload: $FINAL_APK"
echo "5. Add release notes: $NOTES"
echo ""
echo "The app will automatically detect this update!"
echo "=========================================="