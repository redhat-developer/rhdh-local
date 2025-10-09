#!/bin/bash

set -e

RAG_CONTENT_IMAGE=quay.io/redhat-ai-dev/rag-content:release-1.7-lcs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")/configs/extra-files"

container_engine=$1

if [[ "$container_engine" != "podman" && "$container_engine" != "docker" ]]; then
    echo "Invalid or no container engine passed. Defaulting to podman ..."
    container_engine="podman"
fi

"$container_engine" create --replace --name tmp-rag-container $RAG_CONTENT_IMAGE true

rm -rf "$TARGET_DIR/vector_db" "$TARGET_DIR/embeddings_model"

"$container_engine" cp tmp-rag-container:/rag/vector_db "$TARGET_DIR/"

"$container_engine" cp tmp-rag-container:/rag/embeddings_model "$TARGET_DIR/"

"$container_engine" rm tmp-rag-container
