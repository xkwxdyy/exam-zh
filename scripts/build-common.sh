#!/usr/bin/env bash
# 通用构建工具函数库
# 所有打包脚本都应 source 此文件

set -euo pipefail

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# 验证版本号格式 (仅允许 数字.数字.数字 格式)
validate_version() {
  local version="$1"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Invalid version format: $version"
    log_error "Expected format: X.Y.Z (e.g., 0.2.7)"
    return 1
  fi
  return 0
}

# 验证目录路径是否安全（必须在项目内且不为空）
validate_path() {
  local path="$1"
  local project_root="$2"

  # 检查路径是否为空
  if [[ -z "$path" ]]; then
    log_error "Path is empty"
    return 1
  fi

  # 检查是否在项目根目录内
  local resolved_path
  resolved_path="$(cd "$path" 2>/dev/null && pwd)" || {
    log_error "Path does not exist: $path"
    return 1
  }

  if [[ "$resolved_path" != "$project_root"* ]]; then
    log_error "Path is outside project root: $resolved_path"
    return 1
  fi

  # 防止删除重要目录
  if [[ "$resolved_path" == "/" ]] || \
     [[ "$resolved_path" == "$HOME" ]] || \
     [[ "$resolved_path" == "$project_root" ]]; then
    log_error "Cannot operate on protected directory: $resolved_path"
    return 1
  fi

  return 0
}

# 安全清理目录（仅清理文件，保留目录结构）
safe_clean_dir() {
  local dir="$1"
  local project_root="$2"

  validate_path "$dir" "$project_root" || return 1

  log_info "Cleaning directory: $dir"
  find "$dir" -maxdepth 1 -type f -delete
}

# 安全删除旧压缩包
safe_delete_old_zips() {
  local dir="$1"
  local project_root="$2"

  validate_path "$dir" "$project_root" || return 1

  local zip_files
  zip_files=$(find "$dir" -maxdepth 1 -name "*.zip" -type f)

  if [[ -n "$zip_files" ]]; then
    log_info "Deleting old zip files in: $dir"
    echo "$zip_files" | while read -r zipfile; do
      log_info "  Removing: $(basename "$zipfile")"
      rm -f "$zipfile"
    done
  fi
}

# 创建压缩包（统一参数）
create_zip() {
  local zip_name="$1"
  local source_dir="$2"

  log_info "Creating zip: $zip_name"

  # 使用统一的 zip 参数：
  # -q: quiet 模式
  # -r: 递归
  # -X: 排除额外的文件属性（跨平台兼容）
  # -9: 最大压缩率
  (
    cd "$source_dir"
    zip -qrX9 "$zip_name" . \
      -x "*.DS_Store" \
      -x "__MACOSX/*" \
      -x "*.zip"
  )

  # 生成 SHA256 校验和
  local checksum_file="${zip_name}.sha256"
  log_info "Generating checksum: $checksum_file"
  (
    cd "$source_dir"
    if command -v shasum >/dev/null 2>&1; then
      shasum -a 256 "$zip_name" > "$checksum_file"
    elif command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$zip_name" > "$checksum_file"
    else
      log_warn "No SHA256 tool found, skipping checksum"
    fi
  )
}

# 检查必需的命令是否存在
check_required_commands() {
  local missing_cmds=()

  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_cmds+=("$cmd")
    fi
  done

  if [[ ${#missing_cmds[@]} -gt 0 ]]; then
    log_error "Missing required commands: ${missing_cmds[*]}"
    return 1
  fi

  return 0
}

# 清理 LaTeX 编译临时文件
clean_latex_temp() {
  local dir="$1"

  log_info "Cleaning LaTeX temporary files in: $dir"

  # 使用 latexmk 清理（如果可用）
  if command -v latexmk >/dev/null 2>&1; then
    (cd "$dir" && latexmk -c) 2>/dev/null || true
  fi

  # 手动清理常见临时文件
  find "$dir" -type f \( \
    -name "*.aux" -o \
    -name "*.log" -o \
    -name "*.out" -o \
    -name "*.toc" -o \
    -name "*.fdb_latexmk" -o \
    -name "*.fls" -o \
    -name "*.synctex.gz" -o \
    -name "*.xdv" \
  \) -delete 2>/dev/null || true
}

# 从 build.lua 提取当前版本
get_version_from_build_lua() {
  local build_lua="$1"

  if [[ ! -f "$build_lua" ]]; then
    log_error "build.lua not found: $build_lua"
    return 1
  fi

  # 提取版本号（移除 'v' 前缀）
  local version
  version=$(sed -n 's/^version[[:space:]]*=[[:space:]]*"v\([^"]*\)".*/\1/p' "$build_lua" | head -n 1)

  if [[ -z "$version" ]]; then
    log_error "Cannot extract version from build.lua"
    return 1
  fi

  echo "$version"
}

# 锁文件机制（防止并发构建）
readonly LOCK_FILE="/tmp/exam-zh-build.lock"

acquire_lock() {
  local timeout=10
  local waited=0

  while [[ -f "$LOCK_FILE" ]]; do
    if [[ $waited -ge $timeout ]]; then
      log_error "Another build process is running (lock file: $LOCK_FILE)"
      log_error "If no build is running, remove the lock file manually"
      return 1
    fi
    log_warn "Waiting for other build process to finish..."
    sleep 1
    ((waited++))
  done

  # 创建锁文件
  echo $$ > "$LOCK_FILE"

  # 确保退出时删除锁文件
  trap 'rm -f "$LOCK_FILE"' EXIT INT TERM

  return 0
}

release_lock() {
  rm -f "$LOCK_FILE"
}

# 平台特定操作：复制到剪贴板
copy_to_clipboard() {
  local text="$1"

  if command -v pbcopy >/dev/null 2>&1; then
    # macOS
    echo "$text" | pbcopy
    log_info "Copied to clipboard: $text"
  elif command -v xclip >/dev/null 2>&1; then
    # Linux with xclip
    echo "$text" | xclip -selection clipboard
    log_info "Copied to clipboard: $text"
  elif command -v xsel >/dev/null 2>&1; then
    # Linux with xsel
    echo "$text" | xsel --clipboard
    log_info "Copied to clipboard: $text"
  else
    log_warn "No clipboard tool available, skipping"
  fi
}

# 平台特定操作：打开文件管理器
open_directory() {
  local dir="$1"

  if command -v open >/dev/null 2>&1; then
    # macOS
    open "$dir"
  elif command -v xdg-open >/dev/null 2>&1; then
    # Linux
    xdg-open "$dir"
  elif command -v explorer.exe >/dev/null 2>&1; then
    # Windows (WSL)
    explorer.exe "$(wslpath -w "$dir")"
  else
    log_info "Output directory: $dir"
  fi
}

# 验证文件是否存在且非空
verify_file_exists() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  if [[ ! -s "$file" ]]; then
    log_error "File is empty: $file"
    return 1
  fi

  return 0
}

# 检查 Git 工作区状态
check_git_status() {
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    log_warn "Git working directory has uncommitted changes"
    log_warn "Consider committing changes before creating a release"
    return 1
  fi
  return 0
}

# 导出函数供其他脚本使用
export -f log_info log_warn log_error
export -f validate_version validate_path
export -f safe_clean_dir safe_delete_old_zips
export -f create_zip check_required_commands
export -f clean_latex_temp get_version_from_build_lua
export -f acquire_lock release_lock
export -f copy_to_clipboard open_directory
export -f verify_file_exists check_git_status
