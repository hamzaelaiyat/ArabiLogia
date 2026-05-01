#!/bin/bash
# ============================================
# deploy-build.sh - Build Functions
# ============================================

clean_gradle() {
    echo -e "\n🧹 Killing Gradle Daemons & Clearing Cache..."
    set +e
    pkill -f gradle 2>/dev/null || true
    sleep 1
    rm -rf android/.gradle 2>/dev/null || true
    rm -f android/gradlew 2>/dev/null || true
    find android -name "*.lock" -type f -delete 2>/dev/null || true
    find android -name "checksums" -type d -exec rm -rf {} + 2>/dev/null || true
    set -e
    echo "   ✅ Cleaned"
}

run_flutter_clean() {
    echo "🧹 Flutter Clean..."
    gum spin --spinner dot --title "Cleaning..." -- "$FLUTTER" clean > /dev/null 2>&1 || warn "Clean had warnings"
}

run_flutter_pub_get() {
    echo "📦 Installing Dependencies..."
    gum spin --spinner dot --title "Getting packages..." -- "$FLUTTER" pub get > /dev/null 2>&1 || { error "pub get failed"; exit 1; }
    echo "   ✅ Dependencies ready"
}

build_android() {
    if [ -z "$ANDROID_ARCHS" ]; then
        info "Skipping Android build (none selected)"
        return 0
    fi
    
    echo -e "\n📱 Building Android APKs..."
    
    # Ensure gradle daemon disabled
    if [ -f "android/gradle.properties" ]; then
        grep -q "org.gradle.daemon=false" android/gradle.properties || echo "org.gradle.daemon=false" >> android/gradle.properties
    fi
    
    # Build
    if gum spin --spinner dot --show-error --title "Building..." -- "$FLUTTER" build apk --release --split-per-abi; then
        # Ensure output dir exists and copy APKs
        mkdir -p "$OUTPUT_DIR"
        for arch in $ANDROID_ARCHS; do
            local apk=$(find build/app/outputs/flutter-apk -name "*${arch}*-release.apk" | head -1)
            if [ -n "$apk" ] && [ -f "$apk" ]; then
                cp "$apk" "$OUTPUT_DIR/arabilogia-v${VERSION}-${arch}.apk"
                echo "   ✅ $arch: $(du -h "$apk" | cut -f1)"
            else
                warn "APK not found: $arch"
            fi
        done
    else
        error "Android build failed"
    fi
}

build_linux() {
    if [ -z "$LINUX_BUILDS" ] || [[ "$OSTYPE" == "darwin"* ]]; then
        info "Skipping Linux build (not supported or none selected)"
        return 0
    fi
    
    echo -e "\n🐧 Building Linux..."
    
    if gum spin --spinner dot --show-error --title "Building..." -- "$FLUTTER" build linux --release; then
        local bundle="build/linux/x64/release/bundle"
        
        for fmt in $LINUX_BUILDS; do
            case "$fmt" in
                tar)
                    tar -cJf "$OUTPUT_DIR/arabilogia-v${VERSION}-linux-x64.tar.xz" -C "$bundle" . 2>/dev/null && \
                        echo "   ✅ tar created" || warn "tar failed"
                    ;;
                deb)
                    local deb_root="build/deb_tmp"
                    mkdir -p "$deb_root/usr/bin/arabilogia" "$deb_root/DEBIAN"
                    cp -r "$bundle/"* "$deb_root/usr/bin/arabilogia/"
                    echo -e "Package: arabilogia\nVersion: $VERSION\nSection: education\nPriority: optional\nArchitecture: amd64\nMaintainer: Hamza\nDescription: ArabiLogia" > "$deb_root/DEBIAN/control"
                    dpkg-deb --build "$deb_root" "$OUTPUT_DIR/arabilogia-v${VERSION}-amd64.deb" &> /dev/null && \
                        echo "   ✅ deb created" || warn "deb failed"
                    rm -rf "$deb_root"
                    ;;
                rpm)
                    warn "RPM skipped - rpm-build not installed"
                    ;;
                appimage)
                    warn "AppImage requires setup"
                    ;;
            esac
        done
    else
        error "Linux build failed"
    fi
}