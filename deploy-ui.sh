#!/bin/bash
# ============================================
# deploy-ui.sh - Interactive UI
# ============================================

run_interactive_config() {
    echo -e "\n📋 DEPLOYMENT CONFIGURATION\n"
    
    if [ -t 0 ]; then
        # Interactive mode
        VERSION=$(gum input --placeholder "e.g. 1.2.3" --prompt "🔖 Version (leave empty for auto-bump): → ")
        
        if [ -z "$VERSION" ]; then
            AUTO_BUMP="yes"
            # Get current version first
            [ -f "pubspec.yaml" ] && VERSION=$(grep -m1 "^version:" pubspec.yaml | awk '{print $2}')
            VERSION=${VERSION:-"0.0.1"}
        fi
        
        echo "📝 RELEASE NOTES"
        NOTES=$(gum write --placeholder "• List changes here..." --height 5)
        
        echo "📱 ANDROID ARCHITECTURES"
        ANDROID_ARCHS=$(gum choose --no-limit --selected "arm64-v8a" "arm64-v8a" "armeabi-v7a" "x86_64")
        
        LINUX_BUILDS=""
        if [[ "$OSTYPE" != "darwin"* ]]; then
            echo "🐧 LINUX BUILDS"
            LINUX_BUILDS=$(gum choose --no-limit --selected "tar" "tar" "deb" "appimage" "rpm")
        fi
        
        if command -v gh &> /dev/null; then
            gum confirm "🚀 Publish to GitHub?" && PUBLISH="yes"
            gum confirm "📈 Auto-bump version after build?" && AUTO_BUMP="yes"
        fi
    else
        # Non-interactive mode
        [ -f "pubspec.yaml" ] && VERSION=$(grep -m1 "^version:" pubspec.yaml | awk '{print $2}')
        VERSION=${VERSION:-"0.0.1"}
        NOTES="Auto-build"
        ANDROID_ARCHS="arm64-v8a"
        LINUX_BUILDS="tar"
        PUBLISH="yes"
        # AUTO_BUMP stays as-is (default no)
        echo "   📱 Version: $VERSION (auto-bump: $AUTO_BUMP, publish: $PUBLISH)"
    fi
    
    # Auto-bump if enabled
    if [ "$AUTO_BUMP" = "yes" ]; then
        auto_bump_version
    fi
    
    RELEASE_DATE=$(get_version_date)
    info "Version: $VERSION, Date: $RELEASE_DATE"
}