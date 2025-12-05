#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Detect container runtime (podman or docker)
detect_runtime() {
    if command -v podman &> /dev/null && podman ps &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null && docker ps &> /dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

show_provider_menu() {
    echo "=========================================="
    echo "Developer Lightspeed Setup - Step 1/3"
    echo "=========================================="
    echo "Choose your LLM provider:"
    echo ""
    echo "1) Ollama (recommended for beginners)"
    echo "   - Runs locally in a container"
    echo "   - No additional configuration needed"
    echo "   - Good for getting started quickly"
    echo ""
    echo "2) Bring your own model"
    echo "   - Use external LLM provider (vLLM, OpenAI, or Vertex AI)"
    echo "   - Requires configuration in .env file"
    echo "   - Better performance and model options"
    echo ""
}

show_validation_menu() {
    local provider=$1
    local provider_name=""
    
    if [[ "$provider" == "1" ]]; then
        provider_name="Ollama"
    else
        provider_name="your external model"
    fi
    
    echo ""
    echo "=========================================="
    echo "Developer Lightspeed Setup - Step 2/3"
    echo "=========================================="
    echo "Choose question validation for $provider_name:"
    echo ""
    echo "1) No question validation"
    echo "   - Allows any type of questions"
    echo "   - General-purpose assistant"
    echo "   - Recommended for most users"
    echo ""
    echo "2) With question validation"
    echo "   - Filters questions to RHDH/Backstage topics only"
    echo "   - Requires model with larger context window"
    echo "   - Recommended for focused RHDH assistance"
    echo ""
}

validate_provider_choice() {
    local choice=$1
    if [[ ! "$choice" =~ ^[1-2]$ ]]; then
        echo "❌ Invalid choice. Please enter 1 or 2."
        echo ""
        return 1
    fi
    return 0
}

validate_validation_choice() {
    local choice=$1
    if [[ ! "$choice" =~ ^[1-2]$ ]]; then
        echo "❌ Invalid choice. Please enter 1 or 2."
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
    local provider=$1
    local validation=$2
    local runtime=$3
    
    echo ""
    echo "🚀 Starting Developer Lightspeed..."
    echo ""
    
    # Determine provider type
    if [[ "$provider" == "1" ]]; then
        # Ollama provider
        if [[ "$validation" == "1" ]]; then
            # No validation
            echo "📋 Configuration: Ollama (no validation)"
            $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose-with-ollama.yaml" up -d
        else
            # With validation
            echo "📋 Configuration: Ollama (with question validation)"
            $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose-with-ollama.yaml" -f "$ROOT_DIR/developer-lightspeed/compose-with-validation.yaml" up -d
        fi
    else
        # Bring your own model
        if [[ "$validation" == "1" ]]; then
            # No validation
            echo "📋 Configuration: External model (no validation)"
            $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose.yaml" up -d
        else
            # With validation
            echo "📋 Configuration: External model (with question validation)"
            $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose-with-validation.yaml" up -d
        fi
    fi
    
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "🌐 Access Developer Lightspeed at: http://localhost:7007/lightspeed"
    echo ""
    echo "📊 Check service status with: $runtime compose ps"
    echo "📝 View logs with: $runtime logs <container-name>"
}

main() {
    local provider=""
    local validation=""
    local runtime=""
    
    # Step 1: Choose provider
    while true; do
        show_provider_menu
        read -p "Enter your choice (1-2): " -r provider
        
        if validate_provider_choice "$provider"; then
            break
        fi
    done
    
    # Step 2: Choose validation
    while true; do
        show_validation_menu "$provider"
        read -p "Enter your choice (1-2): " -r validation
        
        if validate_validation_choice "$validation"; then
            break
        fi
    done
    
    # Step 3: Detect or choose runtime
    echo ""
    echo "=========================================="
    echo "Developer Lightspeed Setup - Step 3/3"
    echo "=========================================="
    echo "Detecting container runtime..."
    
    runtime=$(detect_runtime)
    
    if [[ -z "$runtime" ]]; then
        echo "⚠️  Could not auto-detect runtime."
        echo "Container runtime detection failed."
        echo "Please choose manually:"
        echo ""
        echo "1) podman"
        echo "2) docker"
        echo ""
        read -p "Enter your choice (1-2): " -r runtime_choice
        if [[ "$runtime_choice" == "1" ]]; then
            runtime="podman"
        elif [[ "$runtime_choice" == "2" ]]; then
            runtime="docker"
        else
            echo "❌ Invalid choice. Exiting."
            exit 1
        fi
    else
        echo "✅ Detected runtime: $runtime"
        echo ""
        read -p "Press Enter to use $runtime, or type 'podman' or 'docker' to override:" -r override_runtime
        
        if [[ -n "$override_runtime" ]]; then
            if validate_runtime "$override_runtime"; then
                runtime="$override_runtime"
                echo "✅ Using runtime: $runtime"
            else
                echo "❌ Invalid choice. Exiting."
                exit 1
            fi
        fi
    fi
    
    execute_setup "$provider" "$validation" "$runtime"
}

main "$@"