#!/usr/bin/env bash
set -euo pipefail

# Gitee Release 创建脚本
# 使用 Gitee API v5 创建 Release

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/build-common.sh
source "$script_dir/build-common.sh"

readonly PROJECT_ROOT="$(cd "$script_dir/.." && pwd)"
readonly GITEE_API_BASE="https://gitee.com/api/v5"
readonly GITEE_OWNER="xkwxdyy"
readonly GITEE_REPO="exam-zh"

# 从环境变量读取 Gitee Token
readonly GITEE_TOKEN="${GITEE_TOKEN:-}"

usage() {
  cat <<EOF
Usage: $0 <tag_name> <release_name> <body_file> [--prerelease] [asset...]

Create or update a Gitee Release using Gitee API v5.

Arguments:
  tag_name      Tag name (e.g., v0.2.7)
  release_name  Release name/title (e.g., "Release v0.2.7")
  body_file     Path to file containing release notes (Markdown)
  --prerelease  (Optional) Mark as pre-release
  asset         (Optional) File to upload as a Release attachment

Environment:
  GITEE_TOKEN   Gitee Personal Access Token (required)
                Get it from: https://gitee.com/profile/personal_access_tokens

Examples:
  export GITEE_TOKEN="your_token_here"
  $0 v0.2.7 "Release v0.2.7" release-notes.md
  $0 v0.2.7 "Release v0.2.7" release-notes.md release/exam-zh-v0.2.7.zip
  $0 v0.2.8-beta "Beta Release v0.2.8" notes.md --prerelease

EOF
  exit 1
}

check_token() {
  if [[ -z "$GITEE_TOKEN" ]]; then
    log_error "GITEE_TOKEN environment variable is not set"
    log_error "Please set it with your Gitee Personal Access Token:"
    log_error "  export GITEE_TOKEN=\"your_token_here\""
    log_error ""
    log_error "Get your token from: https://gitee.com/profile/personal_access_tokens"
    log_error "Required scope: projects (read/write)"
    exit 1
  fi
}

create_gitee_release() {
  local tag_name="$1"
  local release_name="$2"
  local body_file="$3"
  local prerelease="${4:-false}"

  if [[ ! -f "$body_file" ]]; then
    log_error "Release notes file not found: $body_file"
    exit 1
  fi

  # 读取 release notes
  local body
  body=$(cat "$body_file")

  log_info "Preparing Gitee Release..."
  log_info "  Tag: $tag_name"
  log_info "  Name: $release_name"
  log_info "  Pre-release: $prerelease"

  local response
  local http_code
  local body_response

  response=$(curl -sS -w "\n%{http_code}" \
    "${GITEE_API_BASE}/repos/${GITEE_OWNER}/${GITEE_REPO}/releases/tags/${tag_name}?access_token=${GITEE_TOKEN}")

  http_code=$(echo "$response" | tail -n 1)
  body_response=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "200" ]] && echo "$body_response" | jq -e '.id' >/dev/null 2>&1; then
    GITEE_RELEASE_ID=$(echo "$body_response" | jq -r '.id')
    log_info "Updating existing Gitee Release (ID: $GITEE_RELEASE_ID)..."

    response=$(curl -sS -w "\n%{http_code}" -X PATCH \
      "${GITEE_API_BASE}/repos/${GITEE_OWNER}/${GITEE_REPO}/releases/${GITEE_RELEASE_ID}" \
      -F "access_token=${GITEE_TOKEN}" \
      -F "tag_name=${tag_name}" \
      -F "name=${release_name}" \
      -F "body=${body}" \
      -F "prerelease=${prerelease}")
  elif [[ "$http_code" == "200" || "$http_code" == "404" ]]; then
    log_info "Creating new Gitee Release..."

    response=$(curl -sS -w "\n%{http_code}" -X POST \
      "${GITEE_API_BASE}/repos/${GITEE_OWNER}/${GITEE_REPO}/releases" \
      -F "access_token=${GITEE_TOKEN}" \
      -F "tag_name=${tag_name}" \
      -F "name=${release_name}" \
      -F "body=${body}" \
      -F "prerelease=${prerelease}" \
      -F "target_commitish=main")
  else
    log_error "Failed to query Gitee Release (HTTP $http_code)"
    echo "$body_response" | jq '.' 2>/dev/null || echo "$body_response"
    return 1
  fi

  http_code=$(echo "$response" | tail -n 1)
  body_response=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
    log_info "✓ Gitee Release metadata is ready"

    GITEE_RELEASE_ID=$(echo "$body_response" | jq -r '.id')

    # 提取 Release URL
    GITEE_RELEASE_URL=$(echo "$body_response" | jq -r '.html_url // empty')

    if [[ -z "$GITEE_RELEASE_URL" || "$GITEE_RELEASE_URL" == "null" ]]; then
      GITEE_RELEASE_URL="https://gitee.com/${GITEE_OWNER}/${GITEE_REPO}/releases/tag/${tag_name}"
    fi

    log_info "  URL: $GITEE_RELEASE_URL"

    return 0
  else
    log_error "✗ Failed to create or update Gitee Release (HTTP $http_code)"
    log_error "Response:"
    echo "$body_response" | jq '.' 2>/dev/null || echo "$body_response"
    return 1
  fi
}

file_size() {
  wc -c < "$1" | tr -d '[:space:]'
}

delete_gitee_asset() {
  local release_id="$1"
  local asset_id="$2"

  local response
  local http_code

  response=$(curl -sS -w "\n%{http_code}" -X DELETE \
    "${GITEE_API_BASE}/repos/${GITEE_OWNER}/${GITEE_REPO}/releases/${release_id}/attach_files/${asset_id}?access_token=${GITEE_TOKEN}")

  http_code=$(echo "$response" | tail -n 1)

  if [[ "$http_code" != "204" ]]; then
    log_error "Failed to delete existing Gitee Release asset (HTTP $http_code)"
    echo "$response" | sed '$d' | jq '.' 2>/dev/null || echo "$response" | sed '$d'
    return 1
  fi
}

upload_gitee_asset() {
  local release_id="$1"
  local asset_file="$2"

  if [[ ! -f "$asset_file" ]]; then
    log_error "Release asset not found: $asset_file"
    return 1
  fi

  local asset_name
  local asset_size
  asset_name=$(basename "$asset_file")
  asset_size=$(file_size "$asset_file")

  log_info "Preparing Gitee Release asset: $asset_name"

  local response
  local http_code
  local body_response
  local existing_assets

  response=$(curl -sS -w "\n%{http_code}" \
    "${GITEE_API_BASE}/repos/${GITEE_OWNER}/${GITEE_REPO}/releases/${release_id}/attach_files?access_token=${GITEE_TOKEN}&per_page=100")
  http_code=$(echo "$response" | tail -n 1)
  existing_assets=$(echo "$response" | sed '$d')

  if [[ "$http_code" != "200" ]]; then
    log_error "Failed to list Gitee Release assets (HTTP $http_code)"
    echo "$existing_assets" | jq '.' 2>/dev/null || echo "$existing_assets"
    return 1
  fi

  local existing_ids
  existing_ids=$(echo "$existing_assets" | jq -r --arg name "$asset_name" '.[] | select(.name == $name) | .id')

  if [[ -n "$existing_ids" ]]; then
    log_warn "  Replacing existing asset: $asset_name"
    while IFS= read -r existing_id; do
      [[ -n "$existing_id" ]] && delete_gitee_asset "$release_id" "$existing_id"
    done <<< "$existing_ids"
  fi

  response=$(curl -sS -w "\n%{http_code}" -X POST \
    "${GITEE_API_BASE}/repos/${GITEE_OWNER}/${GITEE_REPO}/releases/${release_id}/attach_files" \
    -F "access_token=${GITEE_TOKEN}" \
    -F "file=@${asset_file}")

  http_code=$(echo "$response" | tail -n 1)
  body_response=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "201" ]]; then
    log_info "  Uploaded: $asset_name ($asset_size bytes)"
    return 0
  fi

  log_error "Failed to upload Gitee Release asset (HTTP $http_code): $asset_name"
  echo "$body_response" | jq '.' 2>/dev/null || echo "$body_response"
  return 1
}

main() {
  if [[ $# -lt 3 ]]; then
    usage
  fi

  local tag_name="$1"
  local release_name="$2"
  local body_file="$3"
  local prerelease=false
  local assets=()

  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prerelease)
        prerelease=true
        ;;
      -*)
        log_error "Unknown option: $1"
        usage
        ;;
      *)
        assets+=("$1")
        ;;
    esac
    shift
  done

  # 检查必需命令
  check_required_commands curl jq || exit 1

  # 检查 Token
  check_token

  # 创建 Release
  create_gitee_release "$tag_name" "$release_name" "$body_file" "$prerelease"

  local asset
  for asset in "${assets[@]}"; do
    upload_gitee_asset "$GITEE_RELEASE_ID" "$asset"
  done
}

main "$@"
