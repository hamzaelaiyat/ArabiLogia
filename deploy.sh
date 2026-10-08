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
# Vercel team that owns the arabilogia project (see .vercel/project.json).
VERCEL_SCOPE="${VERCEL_SCOPE:-hamzas-projects-d700a79d}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" | tee -a "$LOG_FILE" >&2; WARNINGS=$((WARNINGS + 1)); }

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

clean_stale_web_output() {
    # `flutter build web` copies everything in web/ into build/web/ AFTER the
    # dart2js output is written, so a committed copy of web/main.dart.js (or
    # web/assets, web/canvaskit) silently overwrites the fresh bundle and the
    # deploy ships old code. These paths are git-ignored; this removes any
    # leftover copy that is still on disk.
    local removed=0
    for f in web/main.dart.js web/flutter_bootstrap.js web/flutter.js web/.last_build_id web/version.json; do
        if [ -f "$f" ]; then rm -f "$f" && removed=$((removed + 1)); fi
    done
    for d in web/canvaskit web/assets; do
        if [ -d "$d" ]; then rm -rf "$d" && removed=$((removed + 1)); fi
    done
    [ "$removed" -gt 0 ] && echo "Removed $removed stale web output path(s) from web/" || true
}

# Reads KEY=value from .env without sourcing the file.
read_env_value() {
    [ -f .env ] || return 0
    sed -n "s/^$1=//p" .env | head -n 1
}

verify_web_bundle() {
    # The bundled app version must appear in the compiled JS. If it does not,
    # build/web/main.dart.js is a stale leftover and must not be deployed.
    local bundle="build/web/main.dart.js"
    if [ ! -f "$bundle" ]; then
        error "Web bundle missing at $bundle"
        return 1
    fi
    if ! grep -q "$VERSION" "$bundle"; then
        error "Web bundle is stale: $bundle does not contain version $VERSION"
        return 1
    fi
    echo "Web bundle verified (contains v$VERSION)"
}

verify_web_config() {
    # The web host strips dotfiles, so assets/.env is never served. The app
    # therefore has to receive its Supabase values as --dart-define values at
    # compile time; if they are missing from the bundle, production boots
    # against the placeholder host and no data loads.
    local bundle="build/web/main.dart.js"
    local url
    url=$(read_env_value SUPABASE_URL)
    if [ -z "$url" ]; then
        warn "No SUPABASE_URL in .env - skipping web config check"
        return 0
    fi
    if ! grep -qF "$url" "$bundle"; then
        error "Web bundle is missing SUPABASE_URL - the deployed app would boot unconfigured"
        return 1
    fi
    echo "Web config verified (Supabase config compiled into bundle)"
}

verify_no_bundled_secrets() {
    # pubspec.yaml bundles .env as an asset, so it ends up in the APKs and in
    # public/assets/.env. Only the Supabase URL and anon key may be in there.
    if [ -f .env ]; then
        local leaked
        leaked=$(grep -oE "^(GITHUB_TOKEN|GH_TOKEN|ONESIGNAL_API_KEY|GOOGLE_AI|SE_API_USER[0-9]*|SE_API_SECRET[0-9]*|SUPABASE_SERVICE_ROLE_KEY)=" .env | sort -u)
        if [ -n "$leaked" ]; then
            error "Secrets in bundled .env (would be published): $(echo "$leaked" | tr '\n' ' ')"
            return 1
        fi
        echo "Bundled .env carries no server-side secrets"
    else
        warn ".env not found - the build will ship placeholder Supabase config"
    fi
}

sync_public() {
    # vercel.json publishes public/ as the output directory, so it has to be a
    # copy of the fresh build. Keeping it out of sync is how an old bundle
    # reached production.
    echo "Syncing build/web -> public/..."
    rsync -a --delete --exclude='.vercel/' build/web/ public/ || {
        error "Failed to sync build/web to public/"
        return 1
    }
    echo "public/ synced"
}

build_linux() {
    echo "Building Linux..."
    if "$FLUTTER" build linux --release; then
        local bundle="build/linux/x64/release/bundle"

        mkdir -p "$OUTPUT_DIR"
        if [ "$LINUX_BUILD" = "tar" ]; then
            # Build as arabilogia unconditionally (not app)
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
        mkdir -p "$OUTPUT_DIR"
        for apk in build/app/outputs/flutter-apk/*-release.apk; do
            local basename=$(basename "$apk")
            # Rename app-*-release.apk to arabilogia-*-v${VERSION}.apk
            local newname=$(echo "$basename" | sed "s/^app-/arabilogia-/; s/-release\.apk$/-v${VERSION}.apk/")
            cp "$apk" "$OUTPUT_DIR/$newname" 2>/dev/null && \
                echo "  -> $newname" || warn "Failed to copy $basename"
        done
    else
        error "Android build failed"
    fi
}

build_web() {
    echo "Building Web..."
    clean_stale_web_output
    local url anon
    url=$(read_env_value SUPABASE_URL)
    anon=$(read_env_value SUPABASE_ANON_KEY)
    local defines=()
    if [ -n "$url" ] && [ -n "$anon" ]; then
        defines=(--dart-define="SUPABASE_URL=$url" --dart-define="SUPABASE_ANON_KEY=$anon")
    else
        warn "SUPABASE_URL/SUPABASE_ANON_KEY missing from .env - the web app will boot unconfigured"
    fi
    # --no-web-resources-cdn ships canvaskit inside the deployment. The default
    # points the renderer at gstatic.com, which is unreliable on some networks.
    if "$FLUTTER" build web --release --no-web-resources-cdn "${defines[@]}"; then
        mkdir -p "$OUTPUT_DIR"
        verify_web_bundle || return 1
        verify_web_config || return 1
        sync_public || return 1
        echo "Web build ready at build/web/ (published from public/)"
    else
        error "Web build failed"
        exit 1
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
    VERCEL_CMD=""
    if command -v vercel &> /dev/null; then
        VERCEL_CMD="vercel"
    elif npx vercel --version &> /dev/null; then
        VERCEL_CMD="npx vercel"
    fi
    if [ -n "$VERCEL_CMD" ]; then
        cd "$SCRIPT_DIR"
        # The project lives in a team scope: without --scope the CLI answers
        # "Error: Not authorized". Override with VERCEL_SCOPE=... if needed.
        local scope_arg=""
        [ -n "$VERCEL_SCOPE" ] && scope_arg="--scope $VERCEL_SCOPE"
        $VERCEL_CMD --yes --prod $scope_arg 2>&1 | tee -a "$LOG_FILE" || warn "Vercel deploy had issues"
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
# الجديد في عربيلوجيا $VERSION

## المميزات والتحسينات
- تحسينات في الأداء والاستقرار
- إصلاح مشكلة hCaptcha في تسجيل الدخول والتسجيل
- شاشة التحديث تظهر بعد تسجيل الدخول الناجح
- طلب تلقائي للسماح بتثبيت التطبيقات من مصادر غير معروفة

## التغييرات الأخيرة
$changes_log

---
*عربيلوجيا v$VERSION*
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

    [ -f "pubspec.yaml" ] && VERSION=$(grep -m1 "^version:" pubspec.yaml | awk '{print $2}' | sed 's/+.*//;s/-b$/b/')
    VERSION=${VERSION:-"0.0.1"}

    if [ "$AUTO_BUMP" = "yes" ]; then
        auto_bump_version
    fi

    prepare_output_directory
    update_version_files "$VERSION"

    verify_no_bundled_secrets || { echo "Aborting: .env would leak secrets into the release artifacts"; exit 1; }

    clean_gradle
    run_flutter_clean
    run_flutter_pub_get

    build_android
    build_linux

    if [ "$VERCEL_DEPLOY" = "yes" ]; then
        build_web
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
        --no-publish) PUBLISH="no" ;;
    esac
    shift
done

main "$@"
