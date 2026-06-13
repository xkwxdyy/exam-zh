#!/usr/bin/env bash
set -euo pipefail

# exam-zh 项目 CTAN 打包脚本
# 用途：创建 CTAN 发布包（符合 CTAN 规范）

# 加载公共函数库
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/build-common.sh
source "$script_dir/build-common.sh"

# 路径定义
readonly PROJECT_ROOT="$(cd "$script_dir/.." && pwd)"
readonly DOC_DIR="$PROJECT_ROOT/doc"
readonly DOC_BASIC_DIR="$PROJECT_ROOT/doc-basic"
readonly EXAMPLES_BASIC_DIR="$PROJECT_ROOT/examples-basic"
readonly CTAN_ZIP_DIR="$PROJECT_ROOT/CTAN"
readonly CTAN_DIR="$CTAN_ZIP_DIR/exam-zh"
readonly CTAN_DOC_DIR="$CTAN_DIR/doc"
readonly CTAN_TEX_DIR="$CTAN_DIR/tex"
readonly CTAN_EXAMPLES_DIR="$CTAN_DIR/examples"

main() {
  log_info "=== exam-zh CTAN Build Script ==="

  # 获取锁，防止并发构建
  acquire_lock

  # 检查必需的命令
  check_required_commands zip find || exit 1

  # 重新创建目录结构
  log_info "Setting up CTAN directory structure..."
  rm -rf "$CTAN_DIR"
  mkdir -p "$CTAN_DOC_DIR"/{back,body,figures}
  mkdir -p "$CTAN_TEX_DIR"
  mkdir -p "$CTAN_EXAMPLES_DIR"

  # 复制文件
  log_info "Copying files to CTAN directory..."
  copy_ctan_files

  # 验证必需文件
  verify_ctan_files || exit 1

  # 清理旧压缩包
  safe_delete_old_zips "$CTAN_ZIP_DIR" "$PROJECT_ROOT"
  rm -f "$CTAN_ZIP_DIR"/*.sha256

  # 创建压缩包
  log_info "Creating CTAN zip package..."
  create_ctan_zip

  # 验证压缩包
  verify_file_exists "$CTAN_ZIP_DIR/exam-zh.zip" || exit 1

  # 复制文件名到剪贴板
  copy_to_clipboard "exam-zh.zip"

  # 打开目录
  open_directory "$CTAN_ZIP_DIR"

  log_info "=== CTAN build completed successfully ==="
  log_info "Package: $CTAN_ZIP_DIR/exam-zh.zip"
}

copy_ctan_files() {
  # 1. 根目录文档文件
  log_info "  [1/5] Copying root documentation files..."
  for file in CHANGELOG.md README.md LICENSE; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
      cp "$PROJECT_ROOT/$file" "$CTAN_DIR/"
    else
      log_warn "  Missing file: $file"
    fi
  done

  # 2. TeX 源文件（.sty 和 .cls）
  log_info "  [2/5] Copying TeX source files..."
  local sty_count=0
  while IFS= read -r -d '' styfile; do
    cp "$styfile" "$CTAN_TEX_DIR/"
    ((sty_count += 1))
  done < <(find "$PROJECT_ROOT" -maxdepth 1 -name "*.sty" -type f -print0)

  if [[ -f "$PROJECT_ROOT/exam-zh.cls" ]]; then
    cp "$PROJECT_ROOT/exam-zh.cls" "$CTAN_TEX_DIR/"
  else
    log_error "  Critical: exam-zh.cls not found"
    exit 1
  fi
  log_info "  Copied $sty_count .sty files and 1 .cls file"

  # 3. 完整文档及其源文件
  log_info "  [3/5] Copying full documentation..."
  copy_doc_files

  # 4. 基础文档
  log_info "  [4/5] Copying basic documentation..."
  copy_doc_basic_files

  # 5. 示例文件
  log_info "  [5/5] Copying example files..."
  copy_example_files
}

copy_doc_files() {
  # 主文档文件
  for file in xdyydoc.cls exam-zh-doc-setup.tex exam-zh-doc.tex exam-zh-doc.pdf; do
    if [[ -f "$DOC_DIR/$file" ]]; then
      cp "$DOC_DIR/$file" "$CTAN_DOC_DIR/"
    else
      log_warn "  Missing doc file: $file"
    fi
  done

  # 文档子目录
  if [[ -d "$DOC_DIR/back" ]]; then
    cp "$DOC_DIR/back"/*.tex "$CTAN_DOC_DIR/back/" 2>/dev/null || log_warn "  No .tex files in doc/back"
  fi

  if [[ -d "$DOC_DIR/body" ]]; then
    cp "$DOC_DIR/body"/*.tex "$CTAN_DOC_DIR/body/" 2>/dev/null || log_warn "  No .tex files in doc/body"
  fi

  if [[ -d "$DOC_DIR/figures" ]]; then
    # 复制所有图片文件
    find "$DOC_DIR/figures" -type f \( -name "*.pdf" -o -name "*.png" -o -name "*.jpg" \) \
      -exec cp {} "$CTAN_DOC_DIR/figures/" \; 2>/dev/null || log_warn "  No figures in doc/figures"
  fi
}

copy_doc_basic_files() {
  # 在 CTAN doc 目录下创建 basic 子目录
  local basic_doc_dir="$CTAN_DOC_DIR/basic"
  mkdir -p "$basic_doc_dir"/{back,body}

  # 基础文档主文件
  for file in xdyydoc.cls exam-zh-doc-basic-setup.tex exam-zh-doc-basic.tex exam-zh-doc-basic.pdf; do
    if [[ -f "$DOC_BASIC_DIR/$file" ]]; then
      cp "$DOC_BASIC_DIR/$file" "$basic_doc_dir/"
    else
      log_warn "  Missing basic doc file: $file"
    fi
  done

  # 基础文档子目录
  if [[ -d "$DOC_BASIC_DIR/back" ]]; then
    cp "$DOC_BASIC_DIR/back"/*.tex "$basic_doc_dir/back/" 2>/dev/null || true
  fi

  if [[ -d "$DOC_BASIC_DIR/body" ]]; then
    cp "$DOC_BASIC_DIR/body"/*.tex "$basic_doc_dir/body/" 2>/dev/null || true
  fi
}

copy_example_files() {
  # 根目录示例
  for file in example-single.tex example-single.pdf example-multiple.tex example-multiple.pdf; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
      cp "$PROJECT_ROOT/$file" "$CTAN_EXAMPLES_DIR/"
    else
      log_warn "  Missing root example: $file"
    fi
  done

  # 基础示例（创建 basic 子目录）
  local basic_examples_dir="$CTAN_EXAMPLES_DIR/basic"
  mkdir -p "$basic_examples_dir"

  for file in 00-minimal 01-first-exam 02-math-basic; do
    if [[ -f "$EXAMPLES_BASIC_DIR/${file}.tex" ]]; then
      cp "$EXAMPLES_BASIC_DIR/${file}.tex" "$basic_examples_dir/"
      if [[ -f "$EXAMPLES_BASIC_DIR/${file}.pdf" ]]; then
        cp "$EXAMPLES_BASIC_DIR/${file}.pdf" "$basic_examples_dir/"
      fi
    fi
  done
}

verify_ctan_files() {
  log_info "Verifying CTAN package structure..."

  local required_files=(
    "$CTAN_DIR/CHANGELOG.md"
    "$CTAN_DIR/README.md"
    "$CTAN_DIR/LICENSE"
    "$CTAN_TEX_DIR/exam-zh.cls"
    "$CTAN_DOC_DIR/exam-zh-doc.pdf"
  )

  local missing=()
  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      missing+=("$file")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required files in CTAN package:"
    for file in "${missing[@]}"; do
      log_error "  - ${file#$CTAN_DIR/}"
    done
    return 1
  fi

  log_info "All required files verified"
  return 0
}

create_ctan_zip() {
  (
    cd "$CTAN_ZIP_DIR"
    # 使用 TDS (TeX Directory Structure) 兼容的压缩方式
    # -D: 不存储目录项（CTAN 规范要求）
    # -r: 递归
    # -X: 排除额外属性
    # -9: 最大压缩
    zip -DrX9 exam-zh.zip exam-zh \
      -x "*.DS_Store" \
      -x "__MACOSX/*" \
      -x "*.log" \
      -x "*.aux"
  )

  verify_file_exists "$CTAN_ZIP_DIR/exam-zh.zip"
}

# 执行主函数
main "$@"
