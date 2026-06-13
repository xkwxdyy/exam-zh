# exam-zh 打包脚本文档

本目录包含 exam-zh 项目的所有构建和打包脚本。

## 脚本概览

### 核心脚本

| 脚本 | 用途 | 使用场景 |
|------|------|---------|
| `build.py` | **完整构建流程** | 创建正式版本发布 |
| `build-ctan.sh` | CTAN 发布包 | 提交到 CTAN |
| `build-release.sh` | GitHub Release 包 | GitHub 发布 |
| `git-update.sh` | Git 工作流助手 | 快速提交和推送 |
| `build-common.sh` | 公共函数库 | 被其他脚本引用 |

### 使用方法

#### 1. 完整构建（推荐）

创建新版本发布时使用：

```bash
# 交互式模式（会提示确认版本号）
python scripts/build.py 0.2.7

# 非交互模式（CI 环境）
python scripts/build.py --non-interactive 0.2.7

# 跳过编译（假设文档已编译）
python scripts/build.py --skip-compile 0.2.7
```

**功能：**
- ✅ 更新所有文件的版本号和日期
- ✅ 编译示例文件和文档
- ✅ 创建 CTAN 和 Release 两个发布包
- ✅ 生成 SHA256 校验和
- ✅ 验证包的完整性

#### 2. 单独创建 CTAN 包

```bash
bash scripts/build-ctan.sh [version]

# 示例
bash scripts/build-ctan.sh 0.2.7
```

**输出：** `CTAN/exam-zh.zip`

#### 3. 单独创建 Release 包

```bash
bash scripts/build-release.sh [version]

# 示例
bash scripts/build-release.sh 0.2.7
```

**输出：** `release/exam-zh-v0.2.7.zip`

#### 4. Git 工作流助手

```bash
# 基本用法：提交并推送
bash scripts/git-update.sh "Update documentation"

# 预览模式（不实际执行）
bash scripts/git-update.sh -n "Fix typo"

# 仅提交不推送
bash scripts/git-update.sh -p "WIP: new feature"

# 推送到指定远程（本仓库常用 github / gitee）
bash scripts/git-update.sh -r github "Update docs"

# 推送到所有远程
bash scripts/git-update.sh --all-remotes "Sync docs"

# 修改上次提交（未推送的提交）
bash scripts/git-update.sh -f --amend

# 显示帮助
bash scripts/git-update.sh --help
```

## 构建流程

### 标准发布流程

```mermaid
graph LR
    A[更新版本号] --> B[编译示例]
    B --> C[编译文档]
    C --> D[创建 CTAN 包]
    D --> E[创建 Release 包]
    E --> F[验证包完整性]
    F --> G[生成校验和]
```

### 文件组织

```
exam-zh/
├── CTAN/
│   └── exam-zh.zip           # CTAN 发布包
│       └── exam-zh/
│           ├── tex/          # .sty 和 .cls 文件
│           ├── doc/          # 文档及源文件
│           └── examples/     # 示例文件
│
└── release/
    └── exam-zh-v0.2.7.zip    # GitHub Release 包（扁平结构）
```

## 安全特性

### 1. 路径验证
- ✅ 所有路径操作前验证是否在项目根目录内
- ✅ 防止误删除重要目录（/, $HOME, 项目根）
- ✅ 使用相对路径和 `realpath` 验证

### 2. 锁机制
- ✅ 防止并发构建导致冲突
- ✅ 自动清理锁文件
- ✅ 支持超时检测

### 3. 版本验证
- ✅ 强制 X.Y.Z 格式
- ✅ 自动从 `build.lua` 提取版本
- ✅ 交互式确认（可用 `--non-interactive` 跳过）

### 4. 文件完整性
- ✅ 编译前检查必需文件
- ✅ 打包后验证文件存在性和大小
- ✅ 生成 SHA256 校验和

### 5. 错误处理
- ✅ 所有脚本使用 `set -euo pipefail`
- ✅ 命令失败时立即退出
- ✅ 彩色日志输出（INFO/WARN/ERROR）

## 依赖项

### 必需依赖
- `bash` >= 4.0
- `python` >= 3.6
- `latexmk`
- `xelatex`
- `zip`
- `git`

### 可选依赖（Python）
```bash
pip install pyperclip send2trash
```

- `pyperclip`: 剪贴板功能
- `send2trash`: 安全删除文件（移到回收站）

## 配置

### Makefile 集成

```makefile
# 使用 Python 完整构建
release:
	python scripts/build.py $(VERSION)

# 单独创建 CTAN 包
ctan:
	bash scripts/build-ctan.sh

# Git 快速提交
git-update:
	bash scripts/git-update.sh "$(MSG)"
```

### CI/CD 集成

```yaml
# GitHub Actions 示例
- name: Build release packages
  run: |
    python scripts/build.py --non-interactive ${{ github.ref_name }}
```

## 常见问题

### Q1: `build.py` 报错 "build.lua not found"
**A:** 确保在项目根目录运行脚本，或检查 `build.lua` 是否存在。

### Q2: 编译失败怎么办？
**A:** 
1. 检查是否安装 `latexmk` 和 `xelatex`
2. 手动编译测试：`make doc && make examples`
3. 使用 `--skip-compile` 跳过编译步骤

### Q3: 锁文件一直存在？
**A:** 如果脚本异常退出，手动删除锁文件：
```bash
rm -f /tmp/exam-zh-build.lock
```

### Q4: Git 工作流脚本找不到公共库？
**A:** 确保 `build-common.sh` 在同一目录，并且有执行权限：
```bash
chmod +x scripts/*.sh
```

### Q5: 如何修改版本号格式？
**A:** 版本号格式在 `build-common.sh` 的 `validate_version()` 函数中定义，当前仅支持 `X.Y.Z` 格式。

## 脚本设计原则

1. **幂等性**: 多次执行相同操作应产生相同结果
2. **原子性**: 操作要么完全成功，要么完全失败
3. **可追溯**: 所有操作都有清晰的日志输出
4. **安全性**: 默认保守，危险操作需要确认
5. **可测试**: 提供 `--dry-run` 和 `--non-interactive` 模式

## 维护建议

### 添加新脚本时
1. 使用 `source build-common.sh` 复用公共函数
2. 添加 `set -euo pipefail` 错误处理
3. 实现 `--help` 和 `--dry-run` 选项
4. 使用统一的日志函数（`log_info`, `log_warn`, `log_error`）
5. 更新此 README

### 修改构建流程时
1. 先在本地测试完整流程
2. 验证 CI/CD 集成不受影响
3. 更新相关文档
4. 考虑向后兼容性

## 许可证

本目录下的脚本遵循项目主许可证（LPPL 1.3c）。
