#!/usr/bin/env bash
set -euo pipefail

# exam-zh 项目 GitHub Release 打包脚本
# 用途：创建 GitHub Release 压缩包（面向最终用户）

# 加载公共函数库
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/build-common.sh
source "$script_dir/build-common.sh"

# 路径定义
readonly PROJECT_ROOT="$(cd "$script_dir/.." && pwd)"
readonly DOC_DIR="$PROJECT_ROOT/doc"
readonly DOC_BASIC_DIR="$PROJECT_ROOT/doc-basic"
readonly EXAMPLES_BASIC_DIR="$PROJECT_ROOT/examples-basic"
readonly RELEASE_DIR="$PROJECT_ROOT/release"
readonly BUILD_LUA="$PROJECT_ROOT/build.lua"

# 版本参数
version="${1:-}"

main() {
  log_info "=== exam-zh Release Build Script ==="

  # 获取锁，防止并发构建
  acquire_lock

  # 检查必需的命令
  check_required_commands zip find sed || exit 1

  # 确定版本号
  if [[ -z "$version" ]]; then
    version=$(get_version_from_build_lua "$BUILD_LUA") || exit 1
    log_info "Version auto-detected from build.lua: $version"
  else
    # 验证用户提供的版本号格式
    validate_version "$version" || exit 1
    log_info "Using provided version: $version"
  fi

  # 创建目标目录
  mkdir -p "$RELEASE_DIR"

  # 清理旧文件
  log_info "Cleaning old release files..."
  safe_clean_dir "$RELEASE_DIR" "$PROJECT_ROOT"
  safe_delete_old_zips "$RELEASE_DIR" "$PROJECT_ROOT"

  # 复制文件
  log_info "Copying files to release directory..."
  copy_release_files

  # 验证必需文件是否存在
  verify_release_files || exit 1

  # 创建压缩包
  local zip_name="exam-zh-v${version}.zip"
  create_zip "$zip_name" "$RELEASE_DIR"

  # 验证压缩包
  verify_file_exists "$RELEASE_DIR/$zip_name" || exit 1

  # 复制版本信息到剪贴板
  copy_to_clipboard "exam-zh-v${version}.zip"

  # 打开目录
  open_directory "$RELEASE_DIR"

  log_info "=== Release build completed successfully ==="
  log_info "Package: $RELEASE_DIR/$zip_name"
}

copy_release_files() {
  # 1. 根目录文档文件
  log_info "  [1/7] Copying documentation files..."
  for file in CHANGELOG.md README.md LICENSE; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
      cp "$PROJECT_ROOT/$file" "$RELEASE_DIR/"
    else
      log_warn "  Missing file: $file"
    fi
  done

  # 2. 根目录示例文件
  log_info "  [2/7] Copying root example files..."
  for file in example-single.tex example-single.pdf example-multiple.tex example-multiple.pdf; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
      cp "$PROJECT_ROOT/$file" "$RELEASE_DIR/"
    else
      log_warn "  Missing example: $file"
    fi
  done

  # 3. 基础示例文件
  log_info "  [3/7] Copying basic example files..."
  for file in 00-minimal 01-first-exam 02-math-basic; do
    if [[ -f "$EXAMPLES_BASIC_DIR/${file}.tex" ]]; then
      cp "$EXAMPLES_BASIC_DIR/${file}.tex" "$RELEASE_DIR/"
      if [[ -f "$EXAMPLES_BASIC_DIR/${file}.pdf" ]]; then
        cp "$EXAMPLES_BASIC_DIR/${file}.pdf" "$RELEASE_DIR/"
      else
        log_warn "  Missing PDF for: ${file}.tex"
      fi
    else
      log_warn "  Missing example: ${file}.tex"
    fi
  done

  # 4. .sty 文件
  log_info "  [4/7] Copying .sty files..."
  local sty_count=0
  while IFS= read -r -d '' styfile; do
    cp "$styfile" "$RELEASE_DIR/"
    ((sty_count += 1))
  done < <(find "$PROJECT_ROOT" -maxdepth 1 -name "*.sty" -type f -print0)
  log_info "  Copied $sty_count .sty files"

  # 5. .cls 文件
  log_info "  [5/7] Copying exam-zh.cls..."
  if [[ -f "$PROJECT_ROOT/exam-zh.cls" ]]; then
    cp "$PROJECT_ROOT/exam-zh.cls" "$RELEASE_DIR/"
  else
    log_error "  Critical: exam-zh.cls not found"
    exit 1
  fi

  # 6. 完整文档
  log_info "  [6/7] Copying full documentation PDF..."
  if [[ -f "$DOC_DIR/exam-zh-doc.pdf" ]]; then
    cp "$DOC_DIR/exam-zh-doc.pdf" "$RELEASE_DIR/"
  else
    log_error "  Critical: exam-zh-doc.pdf not found"
    log_error "  Please run 'make doc' first"
    exit 1
  fi

  # 7. 基础文档
  log_info "  [7/7] Copying basic documentation PDF..."
  if [[ -f "$DOC_BASIC_DIR/exam-zh-doc-basic.pdf" ]]; then
    cp "$DOC_BASIC_DIR/exam-zh-doc-basic.pdf" "$RELEASE_DIR/"
  else
    log_error "  Critical: exam-zh-doc-basic.pdf not found"
    log_error "  Please run 'make doc-basic' first"
    exit 1
  fi
}

verify_release_files() {
  log_info "Verifying release files..."

  local required_files=(
    "CHANGELOG.md"
    "README.md"
    "LICENSE"
    "exam-zh.cls"
    "exam-zh-doc.pdf"
    "exam-zh-doc-basic.pdf"
  )

  local missing=()
  for file in "${required_files[@]}"; do
    if [[ ! -f "$RELEASE_DIR/$file" ]]; then
      missing+=("$file")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required files in release:"
    for file in "${missing[@]}"; do
      log_error "  - $file"
    done
    return 1
  fi

  log_info "All required files verified"
  return 0
}

# 执行主函数
main "$@"
