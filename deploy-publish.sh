#!/bin/bash
# ============================================
# deploy-publish.sh - GitHub Publishing
# ============================================

publish_to_github() {
    if [ "$PUBLISH" != "yes" ]; then
        info "Skipping GitHub publish"
        return 0
    fi
    
    if ! command -v gh &> /dev/null; then
        warn "GitHub CLI not installed"
        return 0
    fi
    
    echo -e "\n🚀 Publishing to GitHub..."
    
    set +e
    
    # Git add, commit, tag
    git add . 2>/dev/null
    git commit -m "chore: release v$VERSION" --allow-empty 2>/dev/null
    
    # Create and push tag
    if git tag -a "v$VERSION" -m "$NOTES" 2>/dev/null; then
        info "Tag created: v$VERSION"
    else
        warn "Tag creation failed (may already exist)"
    fi
    
    # Push
    if git push origin main --tags 2>&1 | tee -a "$LOG_FILE"; then
        info "Pushed to origin"
    else
        warn "Push failed - check remote"
    fi
    
    set -e
    
    # Create release if artifacts exist
    if [ -d "$OUTPUT_DIR" ] && [ "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
        if gh release create "v$VERSION" "$OUTPUT_DIR"/* --title "v$VERSION ($RELEASE_DATE)" --notes "$NOTES" 2>&1 | tee -a "$LOG_FILE"; then
            echo "   ✅ Release created"
        else
            warn "Release creation failed"
        fi
    else
        warn "No artifacts to release"
    fi
}