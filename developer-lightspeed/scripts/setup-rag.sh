#!/bin/bash

set -e

RAG_CONTENT_IMAGE=quay.io/redhat-ai-dev/rag-content:release-1.7-lcs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")/configs/extra-files"

podman create --replace --name tmp-rag-container $RAG_CONTENT_IMAGE true

rm -rf "$TARGET_DIR/vector_db" "$TARGET_DIR/embeddings_model"

podman cp tmp-rag-container:/rag/vector_db "$TARGET_DIR/"

podman cp tmp-rag-container:/rag/embeddings_model "$TARGET_DIR/"

podman rm tmp-rag-container
