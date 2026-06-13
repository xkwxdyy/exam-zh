#!/usr/bin/env bash
# exam-zh 项目 Git 更新助手
# 用途：自动化 Git 工作流 - add, commit, push

set -euo pipefail

# 加载公共函数库
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/build-common.sh
source "$script_dir/build-common.sh"

readonly PROJECT_ROOT="$(cd "$script_dir/.." && pwd)"

show_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [COMMIT_MESSAGE]

自动化 Git 工作流程（检查状态、暂存、提交、推送）

OPTIONS:
  -h, --help          显示此帮助信息
  -n, --dry-run       仅显示将要执行的操作，不实际执行
  -f, --force         跳过确认提示
  -p, --no-push       提交后不推送到远程
  -r, --remote NAME   推送到指定远程（默认自动选择 origin、github 或唯一远程）
      --all-remotes   推送到所有已配置远程
  -a, --amend         修改上一次提交（注意：仅用于未推送的提交）

EXAMPLES:
  $(basename "$0") "Fix typo in README"
  $(basename "$0") -n "Update docs"       # 预览模式
  $(basename "$0") -p "WIP: feature"      # 仅提交不推送
  $(basename "$0") -r gitee "Sync docs"   # 推送到指定远程
  $(basename "$0") --all-remotes "Sync docs"
  $(basename "$0") -f --amend             # 修改上次提交（跳过确认）

EOF
}

# 参数解析
DRY_RUN=false
FORCE=false
NO_PUSH=false
AMEND=false
COMMIT_MSG=""
REMOTE=""
ALL_REMOTES=false
POSITIONAL_ARGS=()
PUSH_REMOTES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_usage
      exit 0
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -p|--no-push)
      NO_PUSH=true
      shift
      ;;
    -r|--remote)
      if [[ $# -lt 2 ]]; then
        log_error "Missing remote name after $1"
        show_usage
        exit 1
      fi
      REMOTE="$2"
      shift 2
      ;;
    --all-remotes)
      ALL_REMOTES=true
      shift
      ;;
    -a|--amend)
      AMEND=true
      shift
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        POSITIONAL_ARGS+=("$1")
        shift
      done
      ;;
    -*)
      log_error "Unknown option: $1"
      show_usage
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
  COMMIT_MSG="${POSITIONAL_ARGS[*]}"
fi

main() {
  cd "$PROJECT_ROOT"

  log_info "=== exam-zh Git Update Helper ==="

  # 检查是否在 Git 仓库中
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not a git repository"
    exit 1
  fi

  if [[ "$ALL_REMOTES" == true && -n "$REMOTE" ]]; then
    log_error "--remote and --all-remotes cannot be used together"
    exit 1
  fi

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$current_branch" == "HEAD" ]]; then
    log_error "Detached HEAD state is not supported"
    exit 1
  fi

  # 检查 Git 状态
  log_info "Checking Git status..."
  git status --short

  # 检查是否有变更
  if [[ -z "$(git status --porcelain)" && "$AMEND" != true ]]; then
    log_info "No changes to commit"
    exit 0
  fi

  if [[ "$NO_PUSH" != true ]]; then
    resolve_push_remotes
  fi

  # Amend 模式：检查上次提交是否已推送
  if [[ "$AMEND" == true ]]; then
    check_amend_safety
  fi

  # 获取提交消息
  if [[ -z "$COMMIT_MSG" ]] && [[ "$AMEND" != true ]]; then
    log_error "Commit message is required"
    echo "Usage: $(basename "$0") [OPTIONS] \"commit message\""
    exit 1
  fi

  # 确认操作（除非使用 --force）
  if [[ "$FORCE" != true ]] && [[ "$DRY_RUN" != true ]]; then
    confirm_operation
  fi

  # 执行 Git 操作
  if [[ "$DRY_RUN" == true ]]; then
    show_dry_run
  else
    execute_git_workflow
  fi
}

remote_exists() {
  local remote_name="$1"
  git remote get-url "$remote_name" >/dev/null 2>&1
}

list_remotes() {
  git remote
}

resolve_push_remotes() {
  PUSH_REMOTES=()

  if [[ "$ALL_REMOTES" == true ]]; then
    while IFS= read -r remote_name; do
      [[ -n "$remote_name" ]] && PUSH_REMOTES+=("$remote_name")
    done < <(list_remotes)

    if [[ ${#PUSH_REMOTES[@]} -eq 0 ]]; then
      log_error "No git remotes configured"
      exit 1
    fi
    return
  fi

  if [[ -n "$REMOTE" ]]; then
    if ! remote_exists "$REMOTE"; then
      log_error "Remote does not exist: $REMOTE"
      log_error "Available remotes:"
      list_remotes >&2
      exit 1
    fi
    PUSH_REMOTES=("$REMOTE")
    return
  fi

  if remote_exists origin; then
    PUSH_REMOTES=(origin)
  elif remote_exists github; then
    PUSH_REMOTES=(github)
  else
    local remotes=()
    while IFS= read -r remote_name; do
      [[ -n "$remote_name" ]] && remotes+=("$remote_name")
    done < <(list_remotes)

    case "${#remotes[@]}" in
      0)
        log_error "No git remotes configured"
        exit 1
        ;;
      1)
        PUSH_REMOTES=("${remotes[0]}")
        ;;
      *)
        log_error "Multiple git remotes found and no default origin/github exists"
        log_error "Use --remote NAME or --all-remotes"
        log_error "Available remotes: ${remotes[*]}"
        exit 1
        ;;
    esac
  fi
}

check_amend_safety() {
  log_info "Checking if last commit is safe to amend..."

  # 检查上次提交是否已推送到远程
  local pushed_refs
  pushed_refs=$(git branch -r --contains HEAD || true)
  if [[ -n "$pushed_refs" ]]; then
    log_error "Last commit has been pushed to remote"
    log_error "Amending a pushed commit will rewrite history"
    if [[ "$NO_PUSH" == true ]]; then
      log_error "This may require a later force push and may affect collaborators"
    else
      log_error "This requires force push and may affect collaborators"
    fi
    log_error "Remote refs containing HEAD:"
    echo "$pushed_refs" >&2

    if [[ "$FORCE" != true ]]; then
      echo -n "Do you really want to amend? [y/N]: "
      read -r answer
      if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        log_info "Amend cancelled"
        exit 0
      fi
    fi
  fi
}

confirm_operation() {
  echo ""
  log_warn "This will:"
  echo "  1. Stage all changes (git add -A)"

  if [[ "$AMEND" == true ]]; then
    echo "  2. Amend the last commit"
  else
    echo "  2. Commit with message: \"$COMMIT_MSG\""
  fi

  if [[ "$NO_PUSH" == true ]]; then
    echo "  3. [SKIPPED] Push to remote"
  else
    echo "  3. Push to remote repository:"
    local remote_name
    for remote_name in "${PUSH_REMOTES[@]}"; do
      echo "     - $remote_name"
    done
  fi

  echo ""
  echo -n "Continue? [y/N]: "
  read -r answer

  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    log_info "Operation cancelled"
    exit 0
  fi
}

show_dry_run() {
  log_info "=== DRY RUN MODE ==="
  echo "git add -A"

  if [[ "$AMEND" == true ]]; then
    if [[ -n "$COMMIT_MSG" ]]; then
      echo "git commit --amend -m \"$COMMIT_MSG\""
    else
      echo "git commit --amend --no-edit"
    fi
  else
    echo "git commit -m \"$COMMIT_MSG\""
  fi

  if [[ "$NO_PUSH" != true ]]; then
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    local remote_name
    for remote_name in "${PUSH_REMOTES[@]}"; do
      if [[ "$AMEND" == true ]]; then
        echo "git push $remote_name $current_branch --force-with-lease"
      else
        echo "git push $remote_name $current_branch"
      fi
    done
  fi

  log_info "=== END DRY RUN ==="
}

execute_git_workflow() {
  log_info "Staging changes..."
  git add -A

  # 提交
  if [[ "$AMEND" == true ]]; then
    log_info "Amending last commit..."
    if [[ -n "$COMMIT_MSG" ]]; then
      git commit --amend -m "$COMMIT_MSG"
    else
      git commit --amend --no-edit
    fi
  else
    log_info "Committing changes..."
    git commit -m "$COMMIT_MSG"
  fi

  # 推送
  if [[ "$NO_PUSH" == true ]]; then
    log_info "Skipping push (--no-push specified)"
  else
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    local remote_name
    for remote_name in "${PUSH_REMOTES[@]}"; do
      log_info "Pushing to $remote_name/$current_branch..."

      if [[ "$AMEND" == true ]]; then
        # Amend 后需要 force push
        git push "$remote_name" "$current_branch" --force-with-lease
      else
        git push "$remote_name" "$current_branch"
      fi
    done
  fi

  log_info "=== Git workflow completed ==="
}

# 执行主函数
main "$@"
