#!/usr/bin/env bash

set -euo pipefail

DEFAULT_REPO="redhat-ai-dev/lightspeed-configs"
DEFAULT_REF="main"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIGHTSPEED_DIR="$(cd -- "${SCRIPT_DIR}/../configs/extra-files" && pwd)"

TARGETS=(
  "lightspeed-core-configs/lightspeed-stack.yaml|${LIGHTSPEED_DIR}/lightspeed-stack.yaml|copy_fetched_file"
  "lightspeed-core-configs/lightspeed-stack.yaml|${LIGHTSPEED_DIR}/lightspeed-stack-no-okp.yaml|strip_okp_config"
  "lightspeed-core-configs/rhdh-profile.py|${LIGHTSPEED_DIR}/rhdh-profile.py|copy_fetched_file"
)

copy_fetched_file() {
  local source_file=$1
  local destination_file=$2

  cp "${source_file}" "${destination_file}"
}

strip_okp_config() {
  local source_file=$1
  local destination_file=$2

  # Remove the top-level RAG section without introducing a YAML-tool dependency.
  awk '
    /^rag:[[:space:]]*($|#)/ { skipping_rag = 1; next }
    skipping_rag && /^[^[:space:]#][^:]*:/ { skipping_rag = 0 }
    !skipping_rag { print }
  ' "${source_file}" > "${destination_file}"
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Sync vendored Lightspeed config files from an upstream repo/ref.

Options:
  --repo REPO   GitHub repo in owner/name form (default: ${DEFAULT_REPO})
  --ref REF     Git ref to fetch from: branch, tag, or commit SHA (default: ${DEFAULT_REF})
  --check       Check whether local vendored files already match the selected upstream ref
  -h, --help    Show this help message and exit
EOF
}

fetch_file() {
  local url=$1
  local destination=$2

  if ! curl -fsSL -A "rhdh-local-lightspeed-sync" "${url}" -o "${destination}"; then
    echo "error: failed to fetch ${url}" >&2
    exit 1
  fi
}

print_diff() {
  local existing_file=$1
  local fetched_file=$2
  local relative_path=$3

  if [[ -f "${existing_file}" ]]; then
    diff -u \
      --label "${relative_path}" \
      --label "${relative_path}" \
      "${existing_file}" "${fetched_file}" || true
  else
    diff -u \
      --label "${relative_path}" \
      --label "${relative_path}" \
      /dev/null "${fetched_file}" || true
  fi
}

repo="${DEFAULT_REPO}"
ref="${DEFAULT_REF}"
check_only=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      if [[ $# -lt 2 ]]; then
        echo "error: --repo requires a value" >&2
        usage
        exit 1
      fi
      repo=$2
      shift 2
      ;;
    --ref)
      if [[ $# -lt 2 ]]; then
        echo "error: --ref requires a value" >&2
        usage
        exit 1
      fi
      ref=$2
      shift 2
      ;;
    --check)
      check_only=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

changed_count=0

for target in "${TARGETS[@]}"; do
  IFS='|' read -r source_path destination_path transform_function <<< "${target}"
  relative_destination=${destination_path#"${LIGHTSPEED_DIR}/"}
  upstream_url="https://raw.githubusercontent.com/${repo}/${ref}/${source_path}"
  fetched_file="${tmpdir}/$(basename "${destination_path}")"
  transformed_file="${tmpdir}/rendered-$(basename "${destination_path}")"

  fetch_file "${upstream_url}" "${fetched_file}"
  "${transform_function}" "${fetched_file}" "${transformed_file}"

  if [[ -f "${destination_path}" ]] && cmp -s "${destination_path}" "${transformed_file}"; then
    echo "up to date: ${relative_destination}"
    continue
  fi

  if [[ "${check_only}" == true ]]; then
    print_diff "${destination_path}" "${transformed_file}" "${relative_destination}"
  else
    cp "${transformed_file}" "${destination_path}"
    echo "updated: ${relative_destination} <- ${upstream_url}"
  fi

  changed_count=$((changed_count + 1))
done

if [[ "${check_only}" == true ]]; then
  if [[ "${changed_count}" -gt 0 ]]; then
    echo "lightspeed config sync is required for ${changed_count} file(s)" >&2
    exit 1
  fi
  echo "lightspeed config files are already synced"
else
  echo "sync complete from ${repo}@${ref}"
fi
