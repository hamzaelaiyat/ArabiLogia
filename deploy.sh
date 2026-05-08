#!/bin/bash
# ============================================
# ArabiLogia Deploy Script v8.0 (Non-Interactive)
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="build/deploy.log"
OUTPUT_DIR=""
VERSION=""
ERRORS=0
WARNINGS=0
AUTO_BUMP="no"
PUBLISH="yes"
LINUX_BUILD="tar"
VERCEL_DEPLOY="yes"
RELEASE_TITLE=""
RELEASE_NOTES_FILE=""

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2; ((ERRORS++)); }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" | tee -a "$LOG_FILE" >&2; ((WARNINGS++)); }

init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    : > "$LOG_FILE"
}

find_flutter() {
    local paths=("flutter" "/mnt/Storage/flutter-files/flutter/bin/flutter" "$HOME/flutter/bin/flutter")
    for p in "${paths[@]}"; do [ -x "$p" ] && echo "$p" && return 0; done
    return 1
}

get_version_date() {
    date "+%B %d, %Y"
}

update_version_files() {
    local ver="$1"
    local legal="lib/core/constants/legal_content.dart"
    local shell="lib/features/dashboard/screens/dashboard_shell.dart"
    local english_date
    english_date=$(get_version_date)

    [ -f "$legal" ] && sed -i "s/'الإصدار الحالي: v[0-9.b]* | تاريخ الإصدار: [^}]*'/'الإصدار الحالي: v$ver | تاريخ الإصدار: $english_date'/" "$legal"
    [ -f "$shell" ] && sed -i "s/'v[0-9.b]*'/'v$ver'/" "$shell"
    # Also update dashboard_sidebar.dart
    local sidebar="lib/features/dashboard/widgets/dashboard_sidebar.dart"
    [ -f "$sidebar" ] && sed -i "s/'v[0-9.b]*'/'v$ver'/" "$sidebar"
    echo "Version files updated to v$ver ($english_date)"
}

auto_bump_version() {
    local pubspec="pubspec.yaml"
    if [ -f "$pubspec" ]; then
        local current_ver=$(grep -m1 "^version:" "$pubspec" | awk '{print $2}' | sed 's/+.*//')
        local major=$(echo "$current_ver" | cut -d. -f1)
        local minor=$(echo "$current_ver" | cut -d. -f2)
        local patch_with_suffix=$(echo "$current_ver" | cut -d. -f3)
        local patch=$(echo "$patch_with_suffix" | sed 's/[a-zA-Z]*//')
        if [ -z "$patch" ] || ! [[ "$patch" =~ ^[0-9]+$ ]]; then patch=0; fi
        local new_ver="${major}.${minor}.$((patch + 1))"
        sed -i "s/^version:.*/version: ${new_ver}+1/" "$pubspec"
        echo "Version auto-bumped: $current_ver -> ${new_ver}"
        VERSION="$new_ver"
    else
        error "pubspec.yaml not found"
    fi
}

prepare_output_directory() {
    OUTPUT_DIR="build/release_v$VERSION"
    mkdir -p "$OUTPUT_DIR"
    echo "Output directory: $OUTPUT_DIR"
}

clean_gradle() {
    echo "Cleaning Gradle..."
    set +e
    pkill -f gradle 2>/dev/null || true
    sleep 1
    rm -rf android/.gradle 2>/dev/null || true
    find android -name "*.lock" -type f -delete 2>/dev/null || true
    set -e
    echo "Cleaned"
}

run_flutter_clean() {
    echo "Flutter Clean..."
    "$FLUTTER" clean > /dev/null 2>&1 || warn "Clean had warnings"
}

run_flutter_pub_get() {
    echo "Installing Dependencies..."
    "$FLUTTER" pub get || { error "pub get failed"; exit 1; }
    echo "Dependencies ready"
}

build_linux() {
    echo "Building Linux..."
    if "$FLUTTER" build linux --release; then
        local bundle="build/linux/x64/release/bundle"

        if [ "$LINUX_BUILD" = "tar" ]; then
            tar -cJf "$OUTPUT_DIR/arabilogia-v${VERSION}-linux-x64.tar.xz" -C "$bundle" . 2>/dev/null && \
                echo "tar created" || warn "tar failed"
        elif [ "$LINUX_BUILD" = "deb" ]; then
            local deb_root="build/deb_tmp"
            mkdir -p "$deb_root/usr/bin/arabilogia" "$deb_root/DEBIAN"
            cp -r "$bundle/"* "$deb_root/usr/bin/arabilogia/"
            echo -e "Package: arabilogia\nVersion: $VERSION\nSection: education\nPriority: optional\nArchitecture: amd64\nMaintainer: ArabiLogia\nDescription: ArabiLogia Arabic Learning App" > "$deb_root/DEBIAN/control"
            dpkg-deb --build "$deb_root" "$OUTPUT_DIR/arabilogia-v${VERSION}-amd64.deb" &> /dev/null && \
                echo "deb created" || warn "deb failed"
            rm -rf "$deb_root"
        fi
    else
        error "Linux build failed"
    fi
}

build_android() {
    echo "Building Android APKs (arm64-v8a, armeabi-v7a, x86_64)..."
    if "$FLUTTER" build apk --release --split-per-abi; then
        cp build/app/outputs/flutter-apk/*-release.apk "$OUTPUT_DIR/" 2>/dev/null && \
            echo "APKs moved to output" || warn "Failed to move APKs"
    else
        error "Android build failed"
    fi
}

create_github_release() {
    echo "Creating GitHub Release..."
    if command -v gh &> /dev/null; then
        local notes_arg=""
        if [ -f "$RELEASE_NOTES_FILE" ]; then
            notes_arg="--notes-file $RELEASE_NOTES_FILE"
        elif [ -n "$RELEASE_TITLE" ]; then
            notes_arg="--notes $RELEASE_TITLE"
        fi

        local title_arg=""
        [ -n "$RELEASE_TITLE" ] && title_arg="--title $RELEASE_TITLE"

        gh release create "v$VERSION" "$OUTPUT_DIR"/* $title_arg $notes_arg && \
            echo "GitHub release created: v$VERSION" || error "GitHub release failed"
    else
        warn "gh CLI not found, skipping GitHub release"
    fi
}

deploy_vercel() {
    echo "Deploying to Vercel..."
    if command -v vercel &> /dev/null; then
        cd "$SCRIPT_DIR"
        vercel --yes --prod 2>&1 | tee -a "$LOG_FILE" || warn "Vercel deploy had issues"
        echo "Vercel deployed"
    else
        warn "vercel CLI not found"
    fi
}

generate_release_notes() {
    local release_notes_file="$OUTPUT_DIR/release-notes.md"
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v2.7.8b")
    local changes_log
    changes_log=$(git log "$last_tag..HEAD" --oneline --pretty=format:"- %s (%h)" 2>/dev/null | head -20)

    cat > "$release_notes_file" << EOF
# What's New in ArabiLogia $VERSION

## Features & Improvements
- Performance improvements
- Bug fixes and stability enhancements

## Recent Changes
$changes_log

---
*ArabiLogia v$VERSION*
EOF
    echo "Release notes generated"
}

show_summary() {
    echo ""
    echo "=== Deploy Summary ==="
    echo "Version: $VERSION"
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo "Output: $OUTPUT_DIR"
    echo ""

    if [ $ERRORS -eq 0 ]; then
        echo "DONE"
    else
        echo "Completed with errors"
        exit 1
    fi
}

main() {
    init_log

    FLUTTER=$(find_flutter) || { echo "Flutter not found"; exit 1; }
    echo "Using Flutter: $FLUTTER"

    [ -f "pubspec.yaml" ] && VERSION=$(grep -m1 "^version:" pubspec.yaml | awk '{print $2}' | sed 's/+.*//')
    VERSION=${VERSION:-"0.0.1"}

    if [ "$AUTO_BUMP" = "yes" ]; then
        auto_bump_version
    fi

    prepare_output_directory
    update_version_files "$VERSION"

    clean_gradle
    run_flutter_clean
    run_flutter_pub_get

    build_android
    build_linux

    if [ "$VERCEL_DEPLOY" = "yes" ]; then
        deploy_vercel
    fi

    if [ -z "$RELEASE_NOTES_FILE" ]; then
        generate_release_notes
        RELEASE_NOTES_FILE="$OUTPUT_DIR/release-notes.md"
    fi

    if [ "$PUBLISH" = "yes" ]; then
        create_github_release
    fi

    show_summary
}

# Parse arguments for title and notes
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift ;;
        --title) RELEASE_TITLE="$2"; shift ;;
        --notes) RELEASE_NOTES_FILE="$2"; shift ;;
        --no-publish) PUBLISH="no"; shift ;;
    esac
    shift
done

main "$@"
