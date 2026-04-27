#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

detect_runtime() {
    if command -v podman &> /dev/null && podman ps &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null && docker ps &> /dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

validate_runtime() {
    local runtime=$1
    if [[ "$runtime" != "podman" && "$runtime" != "docker" ]]; then
        echo "Invalid runtime. Please enter 'podman' or 'docker'."
        echo ""
        return 1
    fi
    return 0
}

execute_setup() {
    local runtime=$1

    echo ""
    echo "Starting Developer Lightspeed..."
    echo ""

    $runtime compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/developer-lightspeed/compose.yaml" up -d

    echo ""
    echo "Setup complete!"
    echo ""
    echo "Access Developer Lightspeed at: http://localhost:7007/lightspeed"
    echo ""
    echo "Check service status with: $runtime compose ps"
    echo "View logs with: $runtime logs <container-name>"
}

main() {
    local runtime=""

    echo "=========================================="
    echo "Developer Lightspeed Setup"
    echo "=========================================="
    echo "Detecting container runtime..."

    runtime=$(detect_runtime)

    if [[ -z "$runtime" ]]; then
        echo "Could not auto-detect runtime."
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
            echo "Invalid choice. Exiting."
            exit 1
        fi
    else
        echo "Detected runtime: $runtime"
        echo ""
        read -p "Press Enter to use $runtime, or type 'podman' or 'docker' to override: " -r override_runtime

        if [[ -n "$override_runtime" ]]; then
            if validate_runtime "$override_runtime"; then
                runtime="$override_runtime"
                echo "Using runtime: $runtime"
            else
                echo "Invalid choice. Exiting."
                exit 1
            fi
        fi
    fi

    execute_setup "$runtime"
}

main "$@"
