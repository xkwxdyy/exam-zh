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
| `gitee-release.sh` | **Gitee Release 创建** | 使用 Gitee API 自动发布 |
| `test-build.sh` | 测试构建流程 | 验证构建脚本 |
| `build-common.sh` | 公共函数库 | 被其他脚本引用 |
| `release_notes.py` | 结构化变更记录 | 生成 changelog 与英文 CTAN 公告 |
| `workflow_dashboard.py` | 本地发布控制台 | 可视化运行固定脚本与 Claude Code skill |

### 使用方法

#### 1. 完整构建（推荐）

创建新版本发布时使用：

```bash
# 交互式模式（会提示确认版本号）
python3 scripts/build.py 0.2.7

# 非交互模式（CI 环境）
python3 scripts/build.py --non-interactive 0.2.7

# 跳过编译（假设文档已编译）
python3 scripts/build.py --skip-compile 0.2.7
```

**功能：**
- ✅ 汇总或校验 `.changes` 中的版本发布记录
- ✅ 更新所有文件的版本号和日期
- ✅ 编译示例文件和文档
- ✅ 创建 CTAN 和 Release 两个发布包
- ✅ 验证包的完整性

#### 2. 单独创建 CTAN 包

```bash
bash scripts/build-ctan.sh [version]

# 示例
bash scripts/build-ctan.sh 0.2.7
```

**输出：** `CTAN/exam-zh.zip`

#### CTAN 发布工作流

在发布控制台选择“GitHub + Gitee + CTAN”或“单独发 CTAN”时，系统会触发
`.github/workflows/ctan-upload.yml`。选择“单独发 CTAN”会自动读取最新的稳定
GitHub Release，并使用它对应的版本、日期和 Tag；只选择 GitHub + Gitee 不会触发
CTAN。Dashboard 会等待对应的 GitHub Actions run 完成，远程失败会让本地任务失败。
如果 `ctan` Environment 或启用变量缺失，Dashboard 会在触发前明确提示并禁用 CTAN 发布按钮。
工作流会：

1. 校验 Tag、`build.lua`、类/宏包、手册、版本清单与 `CHANGELOG.md` 的发布元数据；
2. 编译完整手册和入门手册，运行 `l3build` 回归测试并从该 Tag 生成 `exam-zh.zip`；
3. 检查压缩包结构、必需文件和临时文件，再调用 CTAN Validate 接口；
4. 保存已校验的压缩包，在 `CTAN_UPLOAD_ENABLED=true` 时自动正式上传。

CTAN 工作流只依赖已发布 Tag 内的版本清单，不会重新执行面向开发工作树的
`make check-changelog` 或完整构建脚本测试，因此历史碎片归档缺失不会要求重发
GitHub/Gitee。`.changes/archive/<version>/` 仍应随今后的版本清单纳入 Git，供开发期
溯源和一致性检查使用。

首次启用时，在 GitHub 的 **Settings → Environments** 中创建 `ctan`：

- 不配置 Required reviewers；发布出口的选择已经决定是否进入 CTAN；
- 添加 Environment variable `CTAN_UPLOAD_ENABLED=true`，作为显式启用开关。

CTAN 当前的 `l3build upload` 表单接口不使用 API Token，因此无需创建
`CTAN_UPLOAD_TOKEN` Secret。工作流通过 `L3BUILD_CTAN_UPLOAD=true` 在自动上传步骤
关闭交互确认；本地运行 `l3build upload` 仍会询问确认。发布公告从对应
版本的 `.changes/releases/<version>.json` 清单生成，只包含 `announce: true` 的
已审阅英文条目；完整中文记录仍写入 `CHANGELOG.md`。

#### 变更记录与发布说明

每个主题提交在 `.changes/unreleased/` 中保存一个 JSON 片段。维护者不直接修改
`CHANGELOG.md` 的 `[Unreleased]` 小节，而是运行：

```bash
# 根据片段更新或校验 [Unreleased]
make changelog
make check-changelog

# 发布前生成版本清单、归档片段并写入正式版本小节
make prepare-release VERSION=0.3.2 DATE=2026-08-01
```

`scripts/build.py` 在完整发布时也会执行同样的准备步骤；若版本清单已经存在，
则校验其版本、日期和 changelog 内容。详细字段说明与创建示例见
`.changes/README.md`。

#### 本地发布控制台

```bash
make dashboard
```

控制台只监听 `127.0.0.1:8765`。AI 整理发布内容是独立的手动动作：它会先整理
changelog 片段，把新增测试按项目约定归档为正式回归或必要的最小复现，并按用户可见
改动的需要同步完整手册和入门手册。主发布链从校验现有 changelog 开始，依次执行发布
工具测试、XeTeX 回归、固化版本、编译打包、归档检查、Git 提交、创建 Tag、推送
GitHub/Gitee 和创建平台 Release。发布出口有三种：只发 GitHub + Gitee、GitHub + Gitee
+ CTAN、单独发 CTAN。单独发 CTAN 自动采用最新稳定 GitHub Release 的版本，不创建新版本，
也不重新发布 GitHub/Gitee；主链会先确认远程 Release，再触发并等待 CTAN 工作流。服务端只执行固定的参数数组，不提供任意命令接口；单步工具仍可用于
局部重跑。Git 提交标题由控制台填写或自动生成，提交正文则从该版本结构化清单自动附加
完整中文 Changelog 条目。主发布链会把任务参数、日志和已完成步骤保存在
`.release-dashboard/state.json`；版本、日期、发布出口、编译选项和提交信息完全匹配时，
重新打开控制台会恢复原目标版本并可从失败步骤继续，也可以明确选择从头重跑。

```bash
make dashboard-test
```

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

#### 5. Gitee Release 创建与附件上传

**前置要求**：配置 Gitee Personal Access Token

```bash
# 1. 获取 Token
# 访问：https://gitee.com/profile/personal_access_tokens
# 权限：projects（仓库读写）

# 2. 设置环境变量
export GITEE_TOKEN="your_token_here"

# 3. 持久化配置（可选）
echo 'export GITEE_TOKEN="your_token_here"' >> ~/.zshrc
source ~/.zshrc

# 4. 创建或更新 Release，并上传发行包
bash scripts/gitee-release.sh \
  v0.2.7 "Release v0.2.7" release-notes.md \
  release/exam-zh-v0.2.7.zip

# 5. 创建预发布版本
bash scripts/gitee-release.sh v0.2.8-beta "Beta v0.2.8" notes.md --prerelease
```

**依赖**：
- `curl`：发送 HTTP 请求
- `jq`：JSON 处理 (`brew install jq`)

**注意**：
- 通常由 `/examzh-release` Claude Code 技能自动调用
- 已存在的同名附件会按文件大小判断；大小一致时复用，大小不一致时替换
- 如果未设置 `GITEE_TOKEN`，脚本会显示详细的设置说明

## 构建流程

### 标准发布流程

```mermaid
graph LR
    A[更新版本号] --> B[编译示例]
    B --> C[编译文档]
    C --> D[创建 CTAN 包]
    D --> E[创建 Release 包]
    E --> F[验证包完整性]
    F --> G[发布包就绪]
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
    └── exam-zh-v0.2.7.zip    # GitHub/Gitee Release 包（扁平结构）
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

### 5. 错误处理
- ✅ 所有脚本使用 `set -euo pipefail`
- ✅ 命令失败时立即退出
- ✅ 彩色日志输出（INFO/WARN/ERROR）

## 依赖项

### 必需依赖
- `bash` >= 4.0
- `python3` >= 3.10
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
PYTHON ?= python3

release:
	$(PYTHON) scripts/build.py $(VERSION)

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
    python3 scripts/build.py --non-interactive ${{ github.ref_name }}
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
