#!/bin/bash
# ============================================
# ArabiLogia Deploy Script v7.2 (Modular)
# ============================================

set -o pipefail

# Source all modules
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/deploy-env.sh"
source "$SCRIPT_DIR/deploy-ui.sh"
source "$SCRIPT_DIR/deploy-build.sh"
source "$SCRIPT_DIR/deploy-publish.sh"

# Main
main() {
    init_log
    clear
    show_logo
    
    check_environment || exit 1
    
    parse_args "$@"
    run_interactive_config
    
    prepare_output_directory
    update_version_files
    
    clean_gradle
    run_flutter_clean
    run_flutter_pub_get
    
    build_android
    build_linux
    publish_to_github
    
    show_summary
}

main "$@"