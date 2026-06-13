#!/usr/bin/env bash
# exam-zh 打包脚本测试套件
# 用途：验证所有打包脚本的正确性

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/build-common.sh
source "$script_dir/build-common.sh"

readonly PROJECT_ROOT="$(cd "$script_dir/.." && pwd)"
readonly TEST_DIR="$PROJECT_ROOT/.build-test"

# 测试结果统计
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试用例函数
run_test() {
  local test_name="$1"
  local test_func="$2"

  ((TESTS_RUN += 1))

  log_info "Running test: $test_name"

  if $test_func; then
    ((TESTS_PASSED += 1))
    log_info "  ✓ PASSED"
  else
    ((TESTS_FAILED += 1))
    log_error "  ✗ FAILED"
  fi

  echo ""
}

# ==================== 测试用例 ====================

test_version_validation() {
  validate_version "0.2.7" || return 1
  validate_version "1.0.0" || return 1

  # 应该失败的格式
  ! validate_version "v0.2.7" || return 1
  ! validate_version "0.2" || return 1
  ! validate_version "0.2.7-beta" || return 1

  return 0
}

test_path_validation() {
  local safe_path="$PROJECT_ROOT/release"
  validate_path "$safe_path" "$PROJECT_ROOT" || return 1

  # 应该失败的路径
  ! validate_path "/tmp" "$PROJECT_ROOT" || return 1
  ! validate_path "$HOME" "$PROJECT_ROOT" || return 1

  return 0
}

test_version_extraction() {
  local version
  version=$(get_version_from_build_lua "$PROJECT_ROOT/build.lua") || return 1

  if [[ -z "$version" ]]; then
    return 1
  fi

  log_info "  Extracted version: $version"
  return 0
}

test_required_commands() {
  check_required_commands bash git || return 1
  ! check_required_commands nonexistent_command_xyz || return 1

  return 0
}

test_safe_clean_dir() {
  local test_dir="$TEST_DIR/clean_test"
  mkdir -p "$test_dir"
  touch "$test_dir/test1.txt" "$test_dir/test2.txt"

  safe_clean_dir "$test_dir" "$PROJECT_ROOT" || return 1

  # 目录应该存在但文件应该被删除
  [[ -d "$test_dir" ]] || return 1
  [[ ! -f "$test_dir/test1.txt" ]] || return 1

  return 0
}

test_build_scripts_exist() {
  local scripts=(
    "build-common.sh"
    "build-ctan.sh"
    "build-release.sh"
    "gitee-release.sh"
    "build.py"
  )

  for script in "${scripts[@]}"; do
    if [[ ! -f "$PROJECT_ROOT/scripts/$script" ]]; then
      log_error "  Missing script: $script"
      return 1
    fi

    if [[ "$script" == *.sh ]] && [[ ! -x "$PROJECT_ROOT/scripts/$script" ]]; then
      log_error "  Script not executable: $script"
      return 1
    fi
  done

  return 0
}

test_build_lua_exists() {
  [[ -f "$PROJECT_ROOT/build.lua" ]] || return 1
  return 0
}

test_source_files_exist() {
  local required_files=(
    "exam-zh.cls"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
  )

  for file in "${required_files[@]}"; do
    if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
      log_error "  Missing required file: $file"
      return 1
    fi
  done

  return 0
}

test_dry_run_ctan() {
  log_info "  Testing CTAN build script (syntax check only)..."
  bash -n "$PROJECT_ROOT/scripts/build-ctan.sh" || return 1
  return 0
}

test_dry_run_release() {
  log_info "  Testing release build script (syntax check only)..."
  bash -n "$PROJECT_ROOT/scripts/build-release.sh" || return 1
  return 0
}

test_dry_run_gitee_release() {
  log_info "  Testing Gitee release script (syntax check only)..."
  bash -n "$PROJECT_ROOT/scripts/gitee-release.sh" || return 1
  return 0
}

test_python_script_syntax() {
  log_info "  Testing Python script syntax..."
  python3 -m py_compile "$PROJECT_ROOT/scripts/build.py" || return 1
  return 0
}

# ==================== 主函数 ====================

main() {
  log_info "=== exam-zh Build Scripts Test Suite ==="
  echo ""

  # 创建测试目录
  mkdir -p "$TEST_DIR"
  trap 'rm -rf "$TEST_DIR"' EXIT

  # 运行测试
  run_test "Version validation" test_version_validation
  run_test "Path validation" test_path_validation
  run_test "Version extraction from build.lua" test_version_extraction
  run_test "Required commands check" test_required_commands
  run_test "Safe directory cleaning" test_safe_clean_dir
  run_test "Build scripts exist" test_build_scripts_exist
  run_test "build.lua exists" test_build_lua_exists
  run_test "Source files exist" test_source_files_exist
  run_test "CTAN script syntax" test_dry_run_ctan
  run_test "Release script syntax" test_dry_run_release
  run_test "Gitee release script syntax" test_dry_run_gitee_release
  run_test "Python script syntax" test_python_script_syntax

  # 输出结果
  echo ""
  echo "============================================================"
  echo "Test Results:"
  echo "  Total:  $TESTS_RUN"
  echo "  Passed: $TESTS_PASSED"
  echo "  Failed: $TESTS_FAILED"
  echo "============================================================"

  if [[ $TESTS_FAILED -eq 0 ]]; then
    log_info "All tests passed! ✓"
    return 0
  else
    log_error "Some tests failed! ✗"
    return 1
  fi
}

# 执行主函数
main "$@"
