# l3build 使用指南

本文档说明如何使用新配置的 `build.lua` 进行项目构建和发布。

## 概述

`build.lua` 已从基础配置完善为功能完整的 l3build 配置文件，支持：

- ✅ 自动版本号更新
- ✅ 文档和示例编译
- ✅ CTAN 打包
- ✅ 直接上传 CTAN
- ✅ 本地安装
- ✅ 测试套件

## 常用命令

### 开发和测试

```bash
# 编译示例文件（example-single.tex, example-multiple.tex）
l3build doc

# 运行测试套件
l3build check

# 更新测试基准（当代码变更导致测试失败时）
l3build save <测试名称>

# 本地安装（安装到 TEXMFHOME）
l3build install

# 完整安装（包括文档）
l3build install --full

# 清理构建文件
l3build clean
```

### 版本发布流程

#### 方法 A：使用 l3build（推荐用于 CTAN 发布）

```bash
# 1. 更新 build.lua 中的版本信息
#    编辑 build.lua 的第 15-16 行：
#      version = "v0.2.7"
#      date    = "2025-11-15"

# 2. 自动更新所有文件中的版本号
l3build tag

# 3. 测试编译
l3build doc
l3build check

# 4. 生成 CTAN 包
l3build ctan

# 5. 上传到 CTAN（需要配置 CTAN 凭据）
l3build upload

# 或使用单行命令：
# l3build tag && l3build ctan && l3build upload
```

#### 方法 B：使用 build.py（当前保留）

```bash
# 继续使用现有的 Python 脚本（包含更多自定义功能）
python scripts/build.py 0.2.7
```

#### 方法 C：使用轻量 shell 打包脚本

```bash
# 只复制已有 PDF 和源码并重新生成 GitHub Release 包
bash scripts/build-release.sh 0.2.7

# 只复制已有 PDF 和源码并重新生成 CTAN 包
bash scripts/build-ctan.sh
```

Shell 脚本不更新版本号，也不重新编译文档和示例；发布前仍应先使用 `make examples examples-basic doc doc-basic` 或 `python scripts/build.py 0.2.7` 生成最新 PDF。

## 配置详解

### 版本管理

在 `build.lua` 的开头设置版本信息（第 15-22 行）：

```lua
version          = "v0.2.6"        -- 当前版本
date             = "2025-11-12"    -- 发布日期
maintainer       = "Kangwei Xia"
email            = "xia.kangwei@outlook.com"
repository       = "https://github.com/xkwxdyy/exam-zh"
```

### update_tag 函数

`l3build tag` 会自动更新以下文件中的版本信息：

- **所有 .sty 文件**: `\ProvidesExplPackage {name} {date} {version}`
- **exam-zh.cls**: `\ProvidesExplClass {exam-zh} {date} {version}`
- **文档文件**: `\newcommand{\DocDate}{date}` 和 `\newcommand{\DocVersion}{version}`
- **CHANGELOG.md**: 添加新的 Unreleased 区段

### 文件分类

```lua
sourcefiles      -- 源文件（*.sty, *.cls）
installfiles     -- 需要安装的文件
typesetfiles     -- 需要编译的文档（示例文件）
docfiles         -- 文档源文件（包含在 CTAN 包中）
demofiles        -- 示例文件（examples-basic/）
tagfiles         -- 需要更新版本号的文件
```

### CTAN 上传配置

`uploadconfig` 表包含了所有 CTAN 上传所需的元数据：

- pkg, version, author, email
- summary, description
- license (lppl1.3c)
- ctanPath (`/macros/xetex/latex/exam-zh`)
- repository URLs

## 与 build.py 的对比

| 功能 | build.py | build.lua | 说明 |
|------|----------|-----------|------|
| 版本号更新 | ✅ 正则替换 | ✅ update_tag | l3build 更标准 |
| 编译示例 | ✅ | ✅ | 两者都支持 |
| 编译文档 | ✅ doc/ 和 doc-basic/ | ⚠️ 需手动编译 | build.py 功能更全 |
| 编译 basic 示例 | ✅ | ⚠️ 需手动编译 | build.py 功能更全 |
| CTAN 打包 | ✅ | ✅ | shell 脚本也可复用已有 PDF 生成 `CTAN/exam-zh.zip` |
| Release 打包 | ✅ | ❌ | `scripts/build-release.sh` 可复用已有 PDF 生成 release 包 |
| 上传 CTAN | ❌ 手动 | ✅ 自动 | l3build 优势 |
| 本地安装 | ❌ | ✅ | l3build 优势 |
| 测试套件 | ❌ | ✅ | l3build 优势 |
| 跨平台 | ✅ 仓库相对路径 | ✅ | 两者均避免本机绝对路径 |
| 剪贴板支持 | ✅ | ❌ | build.py 独有 |

## 推荐工作流

### 日常开发

```bash
# 修改代码...
l3build check        # 运行测试
l3build install      # 本地安装测试
```

### CTAN 发布

```bash
# 1. 编辑 build.lua 更新版本号
# 2. 更新 CHANGELOG.md
# 3. 使用 build.py 完整构建（包括所有文档和示例）
python scripts/build.py 0.2.7

# 4. 使用 l3build 上传到 CTAN
l3build upload
```

如果文档和示例 PDF 已经是最新的，也可以使用轻量打包脚本重新生成 CTAN zip：

```bash
bash scripts/build-ctan.sh
```

### Release 发布

```bash
# 使用 build.py（包含 release 和 CTAN 两个包）
python scripts/build.py 0.2.7

# 或在 PDF 已经最新时，只重新生成 GitHub Release 包
bash scripts/build-release.sh 0.2.7

# 手动上传 release/exam-zh-v0.2.7.zip 到 GitHub Releases
# CTAN 包会在 CTAN/exam-zh.zip
```

## 高级功能

### 自定义目标

可以在 `build.lua` 末尾添加自定义目标：

```lua
target_list.mycommand = {
  func = function()
    -- 自定义逻辑
    return 0
  end,
  desc = "My custom command description"
}
```

然后使用：`l3build mycommand`

### 跳过测试打包

如果测试失败但需要打包（不推荐用于正式发布）：

```bash
# 方法 1: 先更新测试基准
l3build save <test-name>

# 方法 2: 使用自定义目标（已配置）
l3build ctan_nocheck
```

## 故障排除

### 问题：测试失败

```
Check failed with difference files
```

**解决方案**：

1. 查看差异：`cat build/test/<test-name>.xetex.diff`
2. 如果是预期的变更，更新基准：`l3build save <test-name>`
3. 重新运行：`l3build check`

### 问题：编译失败

```
Compilation failed
```

**解决方案**：

1. 检查 XeLaTeX 是否正确安装
2. 查看详细日志：`build/doc/*.log`
3. 确保所有依赖的宏包已安装

### 问题：CTAN 上传失败

**解决方案**：

1. 检查 `uploadconfig` 是否完整
2. 使用 `--dry-run` 测试：`l3build upload --dry-run`
3. 检查 CTAN 凭据配置

## 参考资料

- [l3build 官方文档](https://ctan.org/pkg/l3build): `texdoc l3build`
- [LaTeX3 项目发布流程](https://github.com/latex3/latex2e/wiki/Releases:-version-strings,-tagging-and-building)
- [litetable 项目 build.lua](https://github.com/myhsia/litetable/blob/main/build.lua)（参考实现）

## 未来改进

可能的增强方向：

1. **完整文档编译**: 在 l3build 中支持 doc/ 和 doc-basic/ 的编译
2. **Release 目标**: 添加自定义 `l3build release` 目标生成 release 包
3. **Git 集成**: 在 tag_hook 中自动创建 git tag 和 commit
4. **CI/CD 集成**: 在 GitHub Actions 中使用 l3build 进行自动化构建和测试

---

**最后更新**: 2025-11-12
**文档版本**: 1.0
**对应 exam-zh 版本**: v0.2.6+
