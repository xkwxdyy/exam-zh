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
Usage: $0 <tag_name> <release_name> <body_file> [--prerelease]

Create a Gitee Release using Gitee API v5.

Arguments:
  tag_name      Tag name (e.g., v0.2.7)
  release_name  Release name/title (e.g., "Release v0.2.7")
  body_file     Path to file containing release notes (Markdown)
  --prerelease  (Optional) Mark as pre-release

Environment:
  GITEE_TOKEN   Gitee Personal Access Token (required)
                Get it from: https://gitee.com/profile/personal_access_tokens

Examples:
  export GITEE_TOKEN="your_token_here"
  $0 v0.2.7 "Release v0.2.7" release-notes.md
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

  log_info "Creating Gitee Release..."
  log_info "  Tag: $tag_name"
  log_info "  Name: $release_name"
  log_info "  Pre-release: $prerelease"

  # 构造 JSON payload
  local json_payload
  json_payload=$(jq -n \
    --arg token "$GITEE_TOKEN" \
    --arg tag "$tag_name" \
    --arg name "$release_name" \
    --arg body "$body" \
    --argjson pre "$prerelease" \
    '{
      access_token: $token,
      tag_name: $tag,
      name: $name,
      body: $body,
      prerelease: $pre,
      target_commitish: "main"
    }')

  # 调用 Gitee API
  local response
  local http_code

  response=$(curl -s -w "\n%{http_code}" -X POST \
    "${GITEE_API_BASE}/repos/${GITEE_OWNER}/${GITEE_REPO}/releases" \
    -H "Content-Type: application/json" \
    -d "$json_payload")

  http_code=$(echo "$response" | tail -n 1)
  local body_response
  body_response=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "201" ]]; then
    log_info "✓ Gitee Release created successfully"

    # 提取 Release URL
    local release_url
    release_url=$(echo "$body_response" | jq -r '.html_url // empty')

    if [[ -n "$release_url" ]]; then
      log_info "  URL: $release_url"
    fi

    return 0
  else
    log_error "✗ Failed to create Gitee Release (HTTP $http_code)"
    log_error "Response:"
    echo "$body_response" | jq '.' 2>/dev/null || echo "$body_response"
    return 1
  fi
}

main() {
  if [[ $# -lt 3 ]]; then
    usage
  fi

  local tag_name="$1"
  local release_name="$2"
  local body_file="$3"
  local prerelease=false

  if [[ "${4:-}" == "--prerelease" ]]; then
    prerelease=true
  fi

  # 检查必需命令
  check_required_commands curl jq || exit 1

  # 检查 Token
  check_token

  # 创建 Release
  create_gitee_release "$tag_name" "$release_name" "$body_file" "$prerelease"
}

main "$@"
