#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"


show_menu() {
    echo "=========================================="
    echo "Developer Lightspeed Setup"
    echo "=========================================="
    echo "No Question Validation"
    echo "---"
    echo "1) Ollama (recommended for beginners)"
    echo "2) Bring your own model (external LLM server)"
    echo ""
    echo "Question Validation Options"
    echo "Note: Requires higher context size models"
    echo "---"
    echo "3) Ollama with question validation"
    echo "4) Bring your own model with question validation"
    echo ""
    echo -n "Enter your choice (1-4): "
}

validate_choice() {
    local choice=$1
    if [[ ! "$choice" =~ ^[1-4]$ ]]; then
        echo "❌ Invalid choice. Please enter 1, 2, 3, or 4."
        echo ""
        return 1
    fi
    return 0
}

validate_runtime() {
    local runtime=$1
    if [[ "$runtime" != "podman" && "$runtime" != "docker" ]]; then
        echo "❌ Invalid runtime. Please enter 'podman' or 'docker'."
        echo ""
        return 1
    fi
    return 0
}

execute_setup() {
    local choice=$1
    local runtime=$2
    
    echo ""
    echo "🚀 Starting Developer Lightspeed..."
    echo ""
    
    case $choice in
        1)
            echo "📋 Starting with Ollama (no validation) ..."
            $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose-with-ollama.yaml" up -d
            ;;
        2)
            echo "📋 Starting with your own model (no validation) ..."
            $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose.yaml" up -d
            ;;
        3)
            echo "📋 Starting with Ollama and question validation ..."
            $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose-with-ollama.yaml" -f "$ROOT_DIR/developer-lightspeed/compose-with-validation.yaml" up -d
            ;;
        4)
            echo "📋 Starting with your own model and question validation ..."
            $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose-with-validation.yaml" up -d
            ;;
    esac
    
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "🌐 Access Developer Lightspeed at: http://localhost:7007/lightspeed"
    echo ""
    echo "📊 Check service status with: $runtime compose ps"
    echo "📝 View logs with: $runtime logs <container-name>"
}

main() {
    while true; do
        show_menu
        read -r choice
        
        if validate_choice "$choice"; then
            break
        fi
    done
    
    while true; do
        echo -n "Enter container runtime (podman or docker): "
        read -r runtime
        
        if validate_runtime "$runtime"; then
            break
        fi
    done
    
    execute_setup "$choice" "$runtime"
}

main "$@"