# exam-zh-pro 鞠老师定制版

这是一个独立的定制版示例项目。源文件只保留 class、示例入口、`Parts/` 分卷和图片；所有可再生文件统一放在 `build/`，发布压缩包统一放在 `dist/`。

## 工作流

先检查环境：

```zsh
make doctor
```

开发时编译单份或多份示例：

```zsh
make single                 # example-single.tex
make multiple               # example-multiple.tex
make compile FILE=foo.tex  # 根目录中的任意 .tex 入口
```

提交前运行完整检查：

```zsh
make test
```

这会用 XeLaTeX 编译两个示例，并在 `build/aux/` 保存日志、辅助文件，在 `build/pdf/` 保存最新 PDF。构建目录可随时删除并重建，不会污染源目录。

清理可再生文件：

```zsh
make clean
```

打包发布版本（版本号缺省时自动递增 class 的最后一段）：

```zsh
make package VERSION=2.12 DATE=2026-08-21
# 或：zsh 打包.command 2.12 2026-08-21
# 仅做组装和校验，不写入发布包或 class：
zsh scripts/workflow.zsh package --dry-run 2.12 2026-08-21
# 明确覆盖 dist 中的同名发布包：
make package VERSION=2.12 DATE=2026-08-21 FORCE=1
# 已经单独完成测试时，可跳过编译检查：
zsh scripts/workflow.zsh package --skip-test 2.12 2026-08-21
```

打包默认先完整编译两个示例，再在临时目录组装内容、校验 zip，并确认没有 `.aux`、`.log`、`.pdf`、`.solution` 或 macOS 元数据混入；还会校验包内 class 的版本号、拒绝无效日期、阻止并发打包和意外覆盖同名包。全部校验通过后才回写 `exam-zh-pro.cls` 的版本日期，并将压缩包写入 `dist/`。

## 目录约定

```text
exam-zh-pro.cls       定制版 class
example-*.tex         可编译入口
Parts/                多卷示例的分卷内容
scripts/workflow.zsh  统一工作流入口
build/                编译缓存和最新 PDF（可删除）
dist/                 发布压缩包（可删除后重建）
```

双击 `编译.command`、`清理临时文件.command`、`打包.command` 仍然可用，它们只是统一工作流的图形化兼容入口。
