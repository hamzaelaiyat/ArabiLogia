#!/bin/bash
# ============================================
# deploy-env.sh - Environment & Helpers
# ============================================

# Load .env if exists
if [ -f "$(dirname "$0")/.env" ]; then
    set -a; source "$(dirname "$0")/.env"; set +a
fi

# Config
LOG_FILE="build/deploy.log"
ERRORS=0
WARNINGS=0
VERSION=""
RELEASE_DATE=""
VERSION=""
NOTES=""
OUTPUT_DIR=""
ANDROID_ARCHS=""
LINUX_BUILDS=""
PUBLISH="no"
AUTO_BUMP="no"
USE_AI="no"
FLUTTER=""

# Theme
export GUM_CHOOSE_CURSOR_FOREGROUND="212"
export GUM_CHOOSE_SELECTED_FOREGROUND="212"
export GUM_SPIN_SPINNER_FOREGROUND="212"
export GUM_INPUT_CURSOR_FOREGROUND="212"
export GUM_INPUT_PROMPT_FOREGROUND="212"

# Logging
init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    : > "$LOG_FILE"
}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2; ((ERRORS++)); }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" | tee -a "$LOG_FILE" >&2; ((WARNINGS++)); }
info() { log "INFO: $1"; }

# Error handler
handle_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "Failed with exit code: $exit_code"
        log "Log: $LOG_FILE"
        [ -d "$OUTPUT_DIR" ] && log "Artifacts: $OUTPUT_DIR"
    fi
}
trap 'handle_error' ERR

# Find Flutter
find_flutter() {
    local paths=("flutter" "/mnt/Storage/flutter-files/flutter/bin/flutter" "$HOME/flutter/bin/flutter")
    for p in "${paths[@]}"; do [ -x "$p" ] && echo "$p" && return 0; done
    return 1
}

# Arabic date
get_arabic_date() {
    local months=("يناير" "فبراير" "مارس" "أبريل" "مايو" "يونيو" "يوليو" "أغسطس" "سبتمبر" "أكتوبر" "نوفمبر" "ديسمبر")
    echo "${months[$(($(date +%-m)-1))]} $(date +%Y)"
}

# English date (e.g., "May 1, 2026")
get_version_date() {
    date "+%B %d, %Y"
}

# Version management
update_version_files() {
    local ver="$1" r_date="$2"
    local legal="lib/core/constants/legal_content.dart"
    local shell="lib/features/dashboard/screens/dashboard_shell.dart"
    local english_date
    english_date=$(get_version_date)
    
    [ -f "$legal" ] && sed -i "s/'الإصدار الحالي: v[0-9.]* | تاريخ الإصدار: [^}]*'/'الإصدار الحالي: v$ver | تاريخ الإصدار: $english_date'/" "$legal"
    [ -f "$shell" ] && sed -i "s/'v[0-9.]*'/'v$ver'/" "$shell"
    echo "✅ Version files updated to v$ver ($english_date)"
}

auto_bump_version() {
    local pubspec="pubspec.yaml" readme="README.md"
    if [ -f "$pubspec" ]; then
        local current_ver=$(grep -m1 "^version:" "$pubspec" | awk '{print $2}')
        local major=$(echo "$current_ver" | cut -d. -f1)
        local minor=$(echo "$current_ver" | cut -d. -f2)
        local patch=$(echo "$current_ver" | cut -d. -f3)
        local new_ver="${major}.${minor}.$((patch + 1))"
        sed -i "s/^version:.*/version: $new_ver/" "$pubspec"
        [ -f "$readme" ] && sed -i "s/Current version: \*\*[0-9.]*\*/Current version: **$new_ver**/" "$readme"
        echo "✅ Version auto-bumped: $current_ver → $new_ver"
        VERSION="$new_ver"
        OUTPUT_DIR="build/release_v$VERSION"
    else
        error "pubspec.yaml not found"
    fi
}

# Prepare output
prepare_output_directory() {
    OUTPUT_DIR="build/release_v$VERSION"
    mkdir -p "$OUTPUT_DIR"
    export OUTPUT_DIR
    info "Output directory: $OUTPUT_DIR"
}

# Parse CLI args
parse_args() {
    for arg in "$@"; do
        case $arg in --bump|-b) AUTO_BUMP="yes" ;; --publish|-p) PUBLISH="yes" ;; --no-ai) USE_AI="no" ;; esac
    done
}

# Check environment
check_environment() {
    echo -e "\n🔍 Checking Environment..."
    FLUTTER=$(find_flutter) || { echo "❌ Flutter not found"; exit 1; }
    command -v gum &> /dev/null || { echo "❌ gum not found"; exit 1; }
    echo "   ✅ Flutter: $FLUTTER"
    echo "   ✅ gum: Ready"
}

# Show logo
show_logo() {
    chafa --size 40x assets/images/logo-removedbg.png 2>/dev/null || true
}

# Summary
show_summary() {
    echo -e "\n📦 Artifacts in $OUTPUT_DIR:"
    ls -lh "$OUTPUT_DIR" 2>/dev/null | awk '{print "   " $5 "\t" $9}' || echo "   (empty)"

    echo -e "\n📊 Deploy Summary:"
    echo "   ✅ Errors: $ERRORS"
    echo "   ⚠️  Warnings: $WARNINGS"
    echo "   📱 Version: $VERSION"

    if [ $ERRORS -eq 0 ]; then
        echo -e "\n"
        gum style --foreground 212 --bold --border double --padding "1 2" --align center "✨ DONE"
    else
        echo -e "\n⚠️  Completed with errors"
        exit 1
    fi
}