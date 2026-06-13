#!/usr/bin/env python3
"""
exam-zh 项目完整构建脚本
功能：
1. 更新版本号和日期
2. 编译文档和示例
3. 创建 CTAN 和 Release 发布包
"""

import argparse
import datetime
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Optional

# 可选依赖
try:
    import pyperclip
except ImportError:
    pyperclip = None

try:
    import send2trash
except ImportError:
    send2trash = None


# ==================== 颜色输出 ====================
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color


def log_info(msg: str) -> None:
    print(f"{Colors.GREEN}[INFO]{Colors.NC} {msg}")


def log_warn(msg: str) -> None:
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}", file=sys.stderr)


def log_error(msg: str) -> None:
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}", file=sys.stderr)


def log_step(step: int, total: int, msg: str) -> None:
    print(f"\n{Colors.BLUE}[{step}/{total}]{Colors.NC} {msg}")


# ==================== 路径配置 ====================
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DOC_DIR = PROJECT_ROOT / "doc"
DOC_BASIC_DIR = PROJECT_ROOT / "doc-basic"
EXAMPLES_BASIC_DIR = PROJECT_ROOT / "examples-basic"
CTAN_ZIP_DIR = PROJECT_ROOT / "CTAN"
CTAN_DIR = CTAN_ZIP_DIR / "exam-zh"
RELEASE_DIR = PROJECT_ROOT / "release"
BUILD_LUA = PROJECT_ROOT / "build.lua"

# 创建必要的目录
for path in (CTAN_DIR, RELEASE_DIR):
    path.mkdir(parents=True, exist_ok=True)


# ==================== 版本验证 ====================
def validate_version(version: str) -> bool:
    """验证版本号格式 (X.Y.Z)"""
    pattern = r'^\d+\.\d+\.\d+$'
    if not re.match(pattern, version):
        log_error(f"Invalid version format: {version}")
        log_error("Expected format: X.Y.Z (e.g., 0.2.7)")
        return False
    return True


def get_version_from_build_lua() -> Optional[str]:
    """从 build.lua 提取当前版本"""
    if not BUILD_LUA.exists():
        log_error(f"build.lua not found: {BUILD_LUA}")
        return None

    pattern = re.compile(r'^version\s*=\s*"v([^"]+)"', re.MULTILINE)
    content = BUILD_LUA.read_text(encoding='utf-8')
    match = pattern.search(content)

    if match:
        return match.group(1)
    return None


def prompt_version(non_interactive: bool, initial_version: Optional[str] = None) -> str:
    """交互式获取版本号"""
    if non_interactive:
        if initial_version:
            if not validate_version(initial_version):
                sys.exit(1)
            log_info(f"Using version: v{initial_version} (non-interactive mode)")
            return initial_version
        else:
            log_error("Version argument required in non-interactive mode")
            sys.exit(1)

    version = initial_version or input("Please type the new version (X.Y.Z): ").strip()

    while True:
        if not validate_version(version):
            version = input("Please type the new version (X.Y.Z): ").strip()
            continue

        print(f"New version will be: v{version}. Are you sure? [y/n]: ", end='')
        answer = input().strip().lower()

        if answer in ('y', 'yes'):
            return version
        elif answer in ('n', 'no'):
            version = input("Please type the new version (X.Y.Z): ").strip()
        else:
            print("Please answer yes or no.")


# ==================== 文件操作 ====================
def safe_delete(path: Path) -> None:
    """安全删除文件（优先使用回收站）"""
    if not path.exists():
        return

    if send2trash is not None:
        try:
            send2trash.send2trash(str(path))
            return
        except Exception as e:
            log_warn(f"Failed to move to trash: {e}")

    # 回退到直接删除
    if path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def clean_directory(directory: Path, pattern: str = "*") -> None:
    """清理目录中的特定文件"""
    if not directory.exists():
        return

    for item in directory.glob(pattern):
        if item.is_file():
            item.unlink()


# ==================== 版本更新 ====================
def update_package_version(file_path: Path, version: str, date: str) -> None:
    """更新 .sty 文件的版本信息"""
    if not file_path.exists():
        log_warn(f"File not found: {file_path}")
        return

    content = file_path.read_text(encoding='utf-8')
    pkg_name = file_path.stem

    pattern = re.compile(
        r'(\\ProvidesExplPackage\s*\{' + re.escape(pkg_name) + r'\}\s*\{)[^}]+(\}\s*\{)v[^}]+(\})',
        re.MULTILINE
    )

    new_content = pattern.sub(rf'\g<1>{date}\g<2>v{version}\g<3>', content)

    if content != new_content:
        file_path.write_text(new_content, encoding='utf-8')
        log_info(f"  Updated: {file_path.name}")
    else:
        log_warn(f"  No changes in: {file_path.name}")


def update_class_version(file_path: Path, version: str, date: str) -> None:
    """更新 .cls 文件的版本信息"""
    if not file_path.exists():
        log_error(f"Critical file not found: {file_path}")
        sys.exit(1)

    content = file_path.read_text(encoding='utf-8')

    pattern = re.compile(
        r'(\\ProvidesExplClass\s*\{exam-zh\}\s*\{)[^}]+(\}\s*\{)v[^}]+(\})',
        re.MULTILINE
    )

    new_content = pattern.sub(rf'\g<1>{date}\g<2>v{version}\g<3>', content)
    file_path.write_text(new_content, encoding='utf-8')
    log_info(f"  Updated: {file_path.name}")


def update_doc_version(file_path: Path, version: str, date: str) -> None:
    """更新文档的版本和日期"""
    if not file_path.exists():
        log_warn(f"Documentation file not found: {file_path}")
        return

    content = file_path.read_text(encoding='utf-8')

    date_pattern = re.compile(r'(\\newcommand\{\\DocDate\}\{)[^}]+(\})', re.MULTILINE)
    version_pattern = re.compile(r'(\\newcommand\{\\DocVersion\}\{)v[^}]+(\})', re.MULTILINE)

    content = date_pattern.sub(rf'\g<1>{date}\g<2>', content)
    content = version_pattern.sub(rf'\g<1>v{version}\g<2>', content)

    file_path.write_text(content, encoding='utf-8')
    log_info(f"  Updated: {file_path.name}")


def update_all_versions(version: str, date: str) -> None:
    """更新所有文件的版本信息"""
    log_step(1, 5, "Updating version information...")

    # 更新 .sty 文件
    sty_files = list(PROJECT_ROOT.glob("*.sty"))
    log_info(f"Updating {len(sty_files)} .sty files...")
    for sty_file in sty_files:
        update_package_version(sty_file, version, date)

    # 更新 .cls 文件
    log_info("Updating exam-zh.cls...")
    update_class_version(PROJECT_ROOT / "exam-zh.cls", version, date)

    # 更新文档
    log_info("Updating documentation versions...")
    update_doc_version(DOC_DIR / "exam-zh-doc.tex", version, date)
    update_doc_version(DOC_BASIC_DIR / "exam-zh-doc-basic.tex", version, date)


# ==================== 编译 ====================
def compile_latex(tex_file: Path, work_dir: Path) -> bool:
    """编译单个 LaTeX 文件"""
    log_info(f"  Compiling: {tex_file.name}")

    result = subprocess.run(
        ['latexmk', '-xelatex', '-interaction=nonstopmode', str(tex_file.name)],
        cwd=work_dir,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        log_error(f"  Failed to compile: {tex_file.name}")
        log_error(f"  Return code: {result.returncode}")
        if result.stderr:
            log_error(f"  Error output:\n{result.stderr}")
        return False

    log_info(f"  ✓ {tex_file.name} compiled successfully")
    return True


def compile_examples() -> bool:
    """编译示例文件"""
    log_step(2, 5, "Compiling example files...")

    examples = [
        (PROJECT_ROOT, ["example-single.tex", "example-multiple.tex"]),
        (EXAMPLES_BASIC_DIR, ["00-minimal.tex", "01-first-exam.tex", "02-math-basic.tex"])
    ]

    for work_dir, files in examples:
        for tex_file in files:
            full_path = work_dir / tex_file
            if not full_path.exists():
                log_warn(f"  Example not found: {tex_file}")
                continue

            if not compile_latex(full_path, work_dir):
                return False

    return True


def compile_documentation() -> bool:
    """编译文档"""
    log_step(3, 5, "Compiling documentation...")

    docs = [
        (DOC_DIR / "exam-zh-doc.tex", DOC_DIR),
        (DOC_BASIC_DIR / "exam-zh-doc-basic.tex", DOC_BASIC_DIR)
    ]

    for doc_file, work_dir in docs:
        if not doc_file.exists():
            log_error(f"  Documentation file not found: {doc_file}")
            return False

        if not compile_latex(doc_file, work_dir):
            return False

    return True


# ==================== 打包 ====================
def call_build_script(script_name: str, version: str) -> bool:
    """调用 bash 打包脚本"""
    script_path = PROJECT_ROOT / "scripts" / script_name

    if not script_path.exists():
        log_error(f"Build script not found: {script_path}")
        return False

    log_info(f"  Running: {script_name}")
    result = subprocess.run(
        ['bash', str(script_path), version],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        log_error(f"  Failed to run {script_name}")
        log_error(f"  Return code: {result.returncode}")
        if result.stderr:
            log_error(f"  Error output:\n{result.stderr}")
        return False

    # 输出脚本的标准输出
    if result.stdout:
        print(result.stdout)

    return True


def create_packages(version: str) -> bool:
    """创建发布包"""
    log_step(4, 5, "Creating distribution packages...")

    # CTAN 包
    log_info("Creating CTAN package...")
    if not call_build_script("build-ctan.sh", version):
        return False

    # Release 包
    log_info("Creating release package...")
    if not call_build_script("build-release.sh", version):
        return False

    return True


def verify_packages(version: str) -> bool:
    """验证生成的包"""
    log_step(5, 5, "Verifying packages...")

    packages = [
        CTAN_ZIP_DIR / "exam-zh.zip",
        RELEASE_DIR / f"exam-zh-v{version}.zip"
    ]

    all_exist = True
    for pkg in packages:
        if pkg.exists() and pkg.stat().st_size > 0:
            log_info(f"  ✓ {pkg.name} ({pkg.stat().st_size} bytes)")
        else:
            log_error(f"  ✗ {pkg.name} missing or empty")
            all_exist = False

    return all_exist


# ==================== 主函数 ====================
def main() -> int:
    parser = argparse.ArgumentParser(
        description="exam-zh 项目完整构建脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s 0.2.7              # 构建指定版本
  %(prog)s --non-interactive 0.2.7  # 非交互模式（CI 环境）
  %(prog)s --skip-compile     # 跳过编译，仅打包
        """
    )

    parser.add_argument('version', nargs='?', help='版本号 (e.g., 0.2.7)')
    parser.add_argument('--non-interactive', action='store_true',
                        help='非交互模式（不询问确认）')
    parser.add_argument('--skip-compile', action='store_true',
                        help='跳过编译步骤（假设已编译）')

    args = parser.parse_args()

    # 打印横幅
    print("=" * 60)
    print("exam-zh Project Build Script")
    print("=" * 60)

    # 确定版本号
    initial_version = args.version or get_version_from_build_lua()
    version = prompt_version(args.non_interactive, initial_version)

    # 生成日期（ISO 格式）
    now = datetime.datetime.now()
    date = now.strftime("%Y-%m-%d")

    log_info(f"Build version: v{version}")
    log_info(f"Build date: {date}")

    try:
        # 步骤 1: 更新版本
        update_all_versions(version, date)

        # 步骤 2-3: 编译（可选跳过）
        if not args.skip_compile:
            if not compile_examples():
                log_error("Failed to compile examples")
                return 1

            if not compile_documentation():
                log_error("Failed to compile documentation")
                return 1
        else:
            log_warn("Skipping compilation as requested")

        # 步骤 4: 创建包
        if not create_packages(version):
            log_error("Failed to create packages")
            return 1

        # 步骤 5: 验证
        if not verify_packages(version):
            log_error("Package verification failed")
            return 1

        # 复制版本信息到剪贴板
        version_info = f"v{version} - {date}"
        if pyperclip is not None:
            try:
                pyperclip.copy(version_info)
                log_info(f"Copied to clipboard: {version_info}")
            except Exception as e:
                log_warn(f"Failed to copy to clipboard: {e}")
        else:
            log_info(f"Version info: {version_info}")
            log_warn("pyperclip not installed, clipboard feature disabled")

        # 成功
        print("\n" + "=" * 60)
        print(f"{Colors.GREEN}✓ Build completed successfully!{Colors.NC}")
        print("=" * 60)
        print(f"\nVersion: v{version} - {date}")
        print(f"CTAN package: {CTAN_ZIP_DIR / 'exam-zh.zip'}")
        print(f"Release package: {RELEASE_DIR / f'exam-zh-v{version}.zip'}")
        print("\n🎉 Build successful!\n")

        return 0

    except KeyboardInterrupt:
        log_error("\nBuild interrupted by user")
        return 130
    except Exception as e:
        log_error(f"Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
