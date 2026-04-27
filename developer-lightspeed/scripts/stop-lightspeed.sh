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
    echo "  $0 --volumes      Stop containers and remove volumes"
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
                echo "Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
        esac
    done

    echo "$remove_volumes"
}

execute_cleanup() {
    local runtime="$1"
    local remove_volumes="$2"

    echo ""
    echo "Stopping Developer Lightspeed..."
    echo ""

    local compose_files="-f $ROOT_DIR/compose.yaml -f $ROOT_DIR/developer-lightspeed/compose.yaml"
    local cleanup_flag=""

    if [[ "$remove_volumes" == "true" ]]; then
        cleanup_flag="-v"
        echo "Removing volumes..."
    else
        echo "Preserving volumes..."
    fi

    # shellcheck disable=SC2086
    "$runtime" compose $compose_files down $cleanup_flag

    echo ""
    echo "Cleanup complete!"
    echo ""

    if [[ "$remove_volumes" == "true" ]]; then
        echo "Volumes have been removed. Next start will be a fresh setup."
    else
        echo "Volumes preserved. Use './developer-lightspeed/scripts/stop-lightspeed.sh -v' to remove volumes."
    fi
    echo ""
}

main() {
    local runtime=""
    local remove_volumes=false

    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            show_usage
            exit 0
        fi
    done

    remove_volumes=$(parse_arguments "$@")

    echo "=========================================="
    echo "Developer Lightspeed Cleanup"
    echo "=========================================="
    echo "Detecting container runtime..."

    runtime=$(detect_runtime)

    if [[ -z "$runtime" ]]; then
        echo "Could not auto-detect runtime."
        while true; do
            echo -n "Enter container runtime (podman or docker): "
            read -r runtime

            if validate_runtime "$runtime"; then
                break
            fi
        done
    else
        echo "Detected runtime: $runtime"
    fi

    execute_cleanup "$runtime" "$remove_volumes"
}

main "$@"
