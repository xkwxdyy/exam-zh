#!/bin/zsh

# exam-zh-pro custom design workflow.
# One entry point for local development, verification, packaging, and cleanup.

emulate -L zsh
setopt errexit nounset pipe_fail

PROJECT_DIR="${0:A:h:h}"
BUILD_DIR="$PROJECT_DIR/build"
AUX_DIR="$BUILD_DIR/aux"
PDF_DIR="$BUILD_DIR/pdf"
DIST_DIR="$PROJECT_DIR/dist"
CLASS_FILE="$PROJECT_DIR/exam-zh-pro.cls"

die() {
  print -u2 "错误：$*"
  exit 1
}

info() {
  print "[exam-zh] $*"
}

usage() {
  cat <<'EOF'
用法：
  zsh scripts/workflow.zsh compile [入口.tex]  编译一个示例
  zsh scripts/workflow.zsh test                编译全部示例并执行结构检查
  zsh scripts/workflow.zsh package [版本] [日期] 生成发布压缩包
  zsh scripts/workflow.zsh package --dry-run [版本] [日期] 只校验不写入
  zsh scripts/workflow.zsh package --force [版本] [日期] 覆盖同名发布包
  zsh scripts/workflow.zsh package --skip-test [版本] [日期] 跳过编译检查
  zsh scripts/workflow.zsh doctor              检查本机工具和项目结构
  zsh scripts/workflow.zsh clean               清理所有可再生构建产物

默认入口：example-multiple.tex
构建产物：build/aux/、build/pdf/；发布包：dist/。
EOF
}

require_command() {
  local name="$1"
  (( $+commands[$name] )) || die "未找到 $name。请安装 MacTeX/BasicTeX，并确认其已加入 PATH。"
}

validate_target() {
  local target="$1"
  [[ "$target" == *.tex && "$target" != */* && -f "$PROJECT_DIR/$target" ]] \
    || die "入口必须是项目根目录中存在的 .tex 文件：$target"
}

version_from_class() {
  sed -nE 's/^\\ProvidesExplClass[[:space:]]+\{exam-zh-pro\}.*\{v([^}]*)\}.*/\1/p' \
    "$CLASS_FILE" | head -n 1
}

validate_version() {
  local version="${1#v}"
  [[ "$version" =~ '^[0-9]+(\.[0-9]+){1,2}$' ]] \
    || die "版本号必须类似 2.11 或 2.11.1：$1"
}

validate_date() {
  local release_date="$1"
  local normalized
  [[ "$release_date" =~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' ]] \
    || die "日期必须使用 YYYY-MM-DD：$release_date"
  normalized="$(date -j -f '%Y-%m-%d' "$release_date" '+%Y-%m-%d' 2>/dev/null)" \
    || die "日期不是有效的日历日期：$release_date"
  [[ "$normalized" == "$release_date" ]] || die "日期不是有效的日历日期：$release_date"
}

acquire_package_lock() {
  local lock_dir="$1"
  if [[ -e "$lock_dir" ]]; then
    local lock_pid="$(cat "$lock_dir/pid" 2>/dev/null || true)"
    if [[ "$lock_pid" =~ '^[0-9]+$' ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
      rm -rf "$lock_dir"
    else
      die "已有另一个打包任务正在运行或锁文件不完整：dist/.package.lock（如确认已中断，可删除该锁目录）"
    fi
  fi
  mkdir "$lock_dir" 2>/dev/null || die "无法建立打包锁：dist/.package.lock"
  print -r -- "$$" > "$lock_dir/pid"
}

next_version() {
  local current="$1"
  local -a parts
  parts=("${(@s:.:)current}")
  [[ "${parts[-1]}" =~ '^[0-9]+$' ]] || die "当前版本号无法自动递增：$current"
  (( parts[-1]++ ))
  print -r -- "${(j:.:)parts}"
}

compile_one() {
  local target="$1"
  local base="${target%.tex}"
  validate_target "$target"
  require_command latexmk
  mkdir -p "$AUX_DIR" "$AUX_DIR/Parts" "$PDF_DIR"

  info "编译 $target"
  (cd "$PROJECT_DIR" && latexmk \
    -xelatex \
    -interaction=nonstopmode \
    -file-line-error \
    -halt-on-error \
    -synctex=1 \
    -emulate-aux-dir \
    -outdir="$AUX_DIR" \
    "$target") || die "编译失败。日志：$AUX_DIR/$base.log"

  [[ -s "$AUX_DIR/$base.pdf" ]] || die "编译未生成 PDF：$AUX_DIR/$base.pdf"
  cp -p "$AUX_DIR/$base.pdf" "$PDF_DIR/$base.pdf"
  info "完成：build/pdf/$base.pdf"
}

doctor() {
  local missing=0
  for command_name in latexmk xelatex unzip ditto perl; do
    if (( $+commands[$command_name] )); then
      info "$command_name: ${commands[$command_name]}"
    else
      print -u2 "缺少工具：$command_name"
      missing=1
    fi
  done
  for required_file in exam-zh-pro.cls example-single.tex example-multiple.tex Parts/example-paper-one.tex Parts/example-paper-two.tex; do
    if [[ -f "$PROJECT_DIR/$required_file" ]]; then
      info "文件存在：$required_file"
    else
      print -u2 "缺少项目文件：$required_file"
      missing=1
    fi
  done
  local version="$(version_from_class)"
  [[ -n "$version" ]] && info "当前版本：v$version" || { print -u2 "无法读取 class 版本"; missing=1; }
  (( missing == 0 )) || exit 1
  info "环境检查通过"
}

test_all() {
  doctor
  compile_one example-single.tex
  compile_one example-multiple.tex
  info "测试通过：两个示例均可用 XeLaTeX 完整编译"
}

package_release() {
  require_command ditto
  require_command unzip
  require_command perl
  [[ -f "$CLASS_FILE" ]] || die "找不到 $CLASS_FILE"

  local force=0
  local dry_run=0
  local skip_test=0
  local -a package_args=()
  while (( $# > 0 )); do
    case "$1" in
      --force|-f) force=1 ;;
      --dry-run) dry_run=1 ;;
      --skip-test) skip_test=1 ;;
      --help|-h) usage; return 0 ;;
      *) package_args+=("$1") ;;
    esac
    shift
  done
  (( ${#package_args} <= 2 )) || die "打包最多接受版本号和日期两个位置参数；可用 --force 覆盖同名包"

  local current="$(version_from_class)"
  [[ -n "$current" ]] || die "无法从 class 文件读取当前版本号"
  local version="${package_args[1]:-$(next_version "$current")}"
  local release_date="${package_args[2]:-$(date '+%Y-%m-%d')}"
  version="${version#v}"
  validate_version "$version"
  validate_date "$release_date"
  (( skip_test == 1 )) || test_all

  local package_name="exam-zh-pro-鞠老师-v${version}"
  local archive_path="$DIST_DIR/$package_name.zip"
  [[ ! -e "$archive_path" || $force -eq 1 || $dry_run -eq 1 ]] \
    || die "发布包已存在：dist/$package_name.zip；如需覆盖请显式使用 --force"
  local stage_root="$(mktemp -d "${TMPDIR:-/tmp}/exam-zh-pro-package.XXXXXX")"
  local stage="$stage_root/$package_name"
  local archive_tmp="$DIST_DIR/.${package_name}.$$.tmp.zip"
  local lock_dir="$DIST_DIR/.package.lock"
  mkdir -p "$DIST_DIR"
  acquire_package_lock "$lock_dir"
  PACKAGE_STAGE_ROOT="$stage_root"
  PACKAGE_ARCHIVE_TMP="$archive_tmp"
  PACKAGE_LOCK_DIR="$lock_dir"
  mkdir -p "$stage"
  trap 'rm -rf "${PACKAGE_STAGE_ROOT:-}" "${PACKAGE_ARCHIVE_TMP:-}" "${PACKAGE_LOCK_DIR:-}"' EXIT

  local -a required_files=(exam-zh-pro.cls example-single.tex example-multiple.tex README.md CHANGELOG.md 使用说明.md 编译.command 清理临时文件.command 打包.command)
  local file
  for file in "${required_files[@]}"; do
    [[ -f "$PROJECT_DIR/$file" ]] || die "缺少必须打包的文件：$file"
    cp -p "$PROJECT_DIR/$file" "$stage/"
  done
  [[ -f "$PROJECT_DIR/scripts/workflow.zsh" ]] || die "缺少工作流脚本：scripts/workflow.zsh"
  mkdir -p "$stage/scripts"
  cp -p "$PROJECT_DIR/scripts/workflow.zsh" "$stage/scripts/"
  [[ -d "$PROJECT_DIR/Parts" ]] || die "缺少必须打包的目录：Parts"
  cp -R "$PROJECT_DIR/Parts" "$stage/"
  for file in 07-14.jpg 07-15.jpg; do
    [[ -f "$PROJECT_DIR/$file" ]] && cp -p "$PROJECT_DIR/$file" "$stage/"
  done

  RELEASE_DATE="$release_date" RELEASE_VERSION="$version" perl -0pi -e \
    's~(\\ProvidesExplClass\s*\{exam-zh-pro\}\s*\{)[^}]+(\}\s*\{v)[^}]+(\})~${1}$ENV{RELEASE_DATE}${2}$ENV{RELEASE_VERSION}${3}~' \
    "$stage/exam-zh-pro.cls"
  cat > "$stage/版本信息.txt" <<EOF
exam-zh-pro 鞠老师定制版
版本号：v${version}
发布日期：${release_date}
打包时间：$(date '+%Y-%m-%d')
EOF

  /usr/bin/ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "$stage" "$archive_tmp"
  /usr/bin/unzip -tq "$archive_tmp" || die "压缩包完整性校验失败"
  local forbidden
  forbidden="$(/usr/bin/unzip -Z1 "$archive_tmp" | grep -E '(^|/)(\.DS_Store|__MACOSX)(/|$)|(^|/)[^/]+\.(aux|fdb_latexmk|fls|log|out|pdf|solution|synctex\.gz|toc|xdv)$' || true)"
  [[ -z "$forbidden" ]] || die "压缩包包含编译产物：$forbidden"
  local staged_version="$(sed -nE 's/^\\ProvidesExplClass[[:space:]]+\{exam-zh-pro\}.*\{v([^}]*)\}.*/\1/p' "$stage/exam-zh-pro.cls" | head -n 1)"
  [[ "$staged_version" == "$version" ]] || die "包内 class 版本校验失败：$staged_version != $version"
  local staged_date="$(sed -nE 's/^\\ProvidesExplClass[[:space:]]+\{exam-zh-pro\}[[:space:]]+\{([^}]*)\}.*/\1/p' "$stage/exam-zh-pro.cls" | head -n 1)"
  [[ "$staged_date" == "$release_date" ]] || die "包内 class 日期校验失败：$staged_date != $release_date"

  if (( dry_run == 1 )); then
    info "打包校验通过（dry-run），未写入 dist/，未修改 class"
    return 0
  fi

  mv "$archive_tmp" "$archive_path"

  # 只有压缩包通过全部检查后才回写版本，避免生成半成品。
  local class_tmp="$PROJECT_DIR/.exam-zh-pro.cls.$$.tmp"
  cp -p "$stage/exam-zh-pro.cls" "$class_tmp"
  mv -f "$class_tmp" "$CLASS_FILE"
  info "发布包已生成：dist/$package_name.zip"
}

clean() {
  rm -rf "$BUILD_DIR"
  mkdir -p "$AUX_DIR" "$PDF_DIR"
  info "已清理 build/，并重新建立空的构建目录"
}

command="${1:-help}"
shift || true
case "$command" in
  compile) compile_one "${1:-example-multiple.tex}" ;;
  test|check) test_all ;;
  package|release) package_release "$@" ;;
  doctor) doctor ;;
  clean) clean ;;
  help|-h|--help) usage ;;
  *) usage; die "未知命令：$command" ;;
esac
