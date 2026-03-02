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

# Check if a container is running
is_container_running() {
    local runtime=$1
    local container_name=$2
    
    if [[ "$runtime" == "podman" ]]; then
        podman ps --format "{{.Names}}" 2>/dev/null | grep -q "^${container_name}$" && return 0 || return 1
    else
        docker ps --format "{{.Names}}" 2>/dev/null | grep -q "^${container_name}$" && return 0 || return 1
    fi
}

# Check which run.yaml file is mounted in llama-stack container
# This is the most reliable way to detect safety guard mode
check_safety_guard_mode() {
    local runtime=$1
    
    # Check if llama-stack container is running
    if ! is_container_running "$runtime" "llama-stack"; then
        echo ""
        return
    fi
    
    # Get the source path of the mounted run.yaml file
    local source_path
    if [[ "$runtime" == "podman" ]]; then
        source_path=$(podman inspect llama-stack --format '{{range .Mounts}}{{if eq .Destination "/app-root/run.yaml"}}{{.Source}}{{end}}{{end}}' 2>/dev/null || echo "")
    else
        source_path=$(docker inspect llama-stack --format '{{range .Mounts}}{{if eq .Destination "/app-root/run.yaml"}}{{.Source}}{{end}}{{end}}' 2>/dev/null || echo "")
    fi
    
    # Check which file is mounted
    if echo "$source_path" | grep -q "run-no-guard.yaml"; then
        echo "no-guard"
    elif echo "$source_path" | grep -q "run.yaml"; then
        echo "guard"
    else
        echo ""
    fi
}

# Detect which compose files are being used based on running containers
detect_compose_config() {
    local runtime=$1
    
    local has_ollama=false
    local has_lightspeed=false
    
    # Check for Lightspeed-specific containers
    if is_container_running "$runtime" "ollama"; then
        has_ollama=true
    fi
    
    if is_container_running "$runtime" "lightspeed-core-service"; then
        has_lightspeed=true
    fi
    
    # If no Lightspeed containers are running, return empty
    if [[ "$has_lightspeed" == false ]]; then
        echo ""
        return
    fi
    
    # Determine provider type (Ollama vs external)
    local provider=""
    if [[ "$has_ollama" == true ]]; then
        provider="ollama"
    else
        provider="external"
    fi
    
    # Check safety guard mode by inspecting the mounted run.yaml file
    local safety_guard_mode
    safety_guard_mode=$(check_safety_guard_mode "$runtime")
    
    # Combine provider and safety guard mode
    if [[ -n "$safety_guard_mode" ]]; then
        if [[ "$safety_guard_mode" == "guard" ]]; then
            echo "${provider}-guard"
        else
            echo "${provider}"
        fi
    else
        # Fallback: just return provider if we can't detect safety guard mode
        echo "$provider"
    fi
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


execute_cleanup() {
    local runtime="$1"
    local config="$2"
    local cleanup_level="$3"
    
    echo ""
    echo "🛑 Stopping Developer Lightspeed..."
    echo ""
    
    local compose_files=""
    local cleanup_flag=""
    
    # Build compose file list based on detected configuration
    case "$config" in
        "ollama")
            compose_files="-f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose-with-ollama.yaml"
            echo "📋 Configuration detected: Ollama (no safety guard)"
            ;;
        "ollama-guard")
            compose_files="-f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose-with-ollama.yaml -f $ROOT_DIR/developer-lightspeed/compose-with-safety-guard-ollama.yaml"
            echo "📋 Configuration detected: Ollama (with safety guard)"
            ;;
        "external")
            compose_files="-f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose.yaml"
            echo "📋 Configuration detected: External model (no safety guard)"
            ;;
        "external-guard")
            compose_files="-f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose-with-safety-guard.yaml"
            echo "📋 Configuration detected: External model (with safety guard)"
            ;;
        *)
            echo "❌ Could not detect running configuration."
            echo "   Attempting to stop all possible combinations..."
            echo ""
            
            # Try all combinations
            local configs=(
                "ollama: -f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose-with-ollama.yaml"
                "ollama-guard: -f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose-with-ollama.yaml -f $ROOT_DIR/developer-lightspeed/compose-with-safety-guard-ollama.yaml"
                "external: -f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose.yaml"
                "external-guard: -f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose-with-safety-guard.yaml"
            )
            
            for config_line in "${configs[@]}"; do
                local config_name="${config_line%%:*}"
                local files="${config_line#*: }"
                echo "   Trying: $config_name"
                # shellcheck disable=SC2086
                "$runtime" compose $files down $cleanup_flag 2>/dev/null || true
            done
            
            echo ""
            echo "✅ Cleanup complete!"
            return
            ;;
    esac
    
    # Set cleanup flag
    if [[ "$cleanup_level" == "2" ]]; then
        cleanup_flag="-v"
        echo "🗑️  Removing volumes..."
    else
        echo "💾 Preserving volumes..."
    fi
    
    # Execute cleanup
    # shellcheck disable=SC2086 
    "$runtime" compose $compose_files down $cleanup_flag
    
    echo ""
    echo "✅ Cleanup complete!"
    echo ""
    
    if [[ "$cleanup_level" == "2" ]]; then
        echo "💡 Volumes have been removed. Next start will be a fresh setup."
    else
        echo "💡 Volumes preserved. Use './developer-lightspeed/scripts/stop-lightspeed.sh -v' to remove volumes."
    fi
    echo ""
}

show_usage() {
    echo "Usage: $0 [-v|--volumes]"
    echo ""
    echo "Options:"
    echo "  -v, --volumes    Remove volumes during cleanup"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                Stop containers only (preserves volumes)"
    echo "  $0 -v             Stop containers and remove volumes"
    echo "  $0 --volumes       Stop containers and remove volumes"
}

parse_arguments() {
    local remove_volumes=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--volumes)
                remove_volumes=true
                shift
                ;;
            *)
                echo "❌ Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "$remove_volumes"
}

main() {
    local runtime=""
    local config=""
    local cleanup_level=""
    local remove_volumes=false
    
    # Check for help flag first (before parsing other arguments)
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            show_usage
            exit 0
        fi
    done
    
    # Parse command-line arguments
    remove_volumes=$(parse_arguments "$@")
    
    # Step 1: Detect or prompt for runtime
    echo "=========================================="
    echo "Developer Lightspeed Cleanup"
    echo "=========================================="
    echo "Detecting container runtime..."
    
    runtime=$(detect_runtime)
    
    if [[ -z "$runtime" ]]; then
        echo "⚠️  Could not auto-detect runtime."
        while true; do
            echo -n "Enter container runtime (podman or docker): "
            read -r runtime
            
            if validate_runtime "$runtime"; then
                break
            fi
        done
    else
        echo "✅ Detected runtime: $runtime"
    fi
    
    # Step 2: Detect running configuration
    echo ""
    echo "Detecting running configuration..."
    config=$(detect_compose_config "$runtime")
    
    if [[ -z "$config" ]]; then
        echo "⚠️  No Developer Lightspeed containers detected."
        echo ""
        echo "This could mean:"
        echo "  - Containers are not running"
        echo "  - Containers are using different names"
        echo ""
        echo "Would you like to attempt cleanup anyway? (y/n)"
        read -r proceed
        
        if [[ "$proceed" != "y" && "$proceed" != "Y" ]]; then
            echo "Cleanup cancelled."
            exit 0
        fi
        
        config="unknown"
    else
        echo "✅ Configuration detected: $config"
    fi
    
    # Step 3: Set cleanup level based on flag
    if [[ "$remove_volumes" == "true" ]]; then
        cleanup_level="2"
        echo ""
        echo "🗑️  Volumes will be removed (--volumes flag provided)"
    else
        cleanup_level="1"
        echo ""
        echo "💾 Volumes will be preserved (use -v flag to remove volumes)"
    fi
    
    # Step 4: Execute cleanup
    execute_cleanup "$runtime" "$config" "$cleanup_level"
}

main "$@"

