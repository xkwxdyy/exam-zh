# Changelog

此处记载了项目中所有值得留意的改动。

格式参照 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，
并且此项目遵守 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)。


## [Unreleased]

### Added

- 新增 `scripts/git-update.sh`：智能 Git 工作流脚本，支持自动按模块分组提交
- 新增 `scripts/test-build.sh`：测试构建流程验证脚本
- 新增 `scripts/build-common.sh`：构建脚本公共函数库
- 新增 `scripts/README.md`：脚本使用说明文档
- 新增 `examples-basic/03-real-exam-scenario.tex`：真实试卷场景示例
- 新增 `doc-basic/body/quick-reference.tex`：快速参考手册
- 新增 `AGENTS.md`：代理协作文档

### Changed

- 重构 `scripts/build.py`：优化代码结构和 CTAN 打包逻辑
- 增强 `scripts/build-ctan.sh`：改进 CTAN 构建流程
- 优化 `scripts/build-release.sh`：完善发布流程处理
- 改进 `Makefile`：新增 `examples-basic` 编译目标
- 优化 `examples-basic/` 下所有示例文件的内容和格式
- 全面更新入门文档 `doc-basic/` 各章节内容
- 更新 `doc/body/usage.tex`：修正选项值说明
- 更新 `README.md`：改进项目说明和使用指南
- 优化 `.gitignore`：添加 Python 缓存排除规则，修正 `.claude/` 排除逻辑

### Fixed

- 移除 `exam-zh-question.sty` 中未使用的答案颜色变量
- 统一代码格式：清理尾随空格，规范缩进

### Testing

- 更新所有测试基准文件（`.lvt` 和 `.tlg`），确保测试与代码修改同步


## [0.2.6] - 2025-11-07

### Added

- 增加 `exam-zh/draft` 的多层级键值对支持，允许更灵活的草稿配置

### Changed

- 修改 `calculations` 环境的宽度参数，从 `0.3\textwidth` 调整为 `0.45\textwidth`，改善计算题排版效果

### Fixed

- 修复 `solution` 环境与 `align*` 数学环境结合时出现的尾随空行问题
- 修复 `\fillin` 命令在 `no-answer-type=none` 时超宽内容无法自动换行的问题
- 将 `\par` 保护起来，防止其被意外展开导致的格式问题
- 使用字符串比较方式处理 `*` 和 `label-pos` 的值，提高代码健壮性

### Documentation

- 补充 `page/show-foot` 选项的文档说明


## [0.2.5] - 2024-04-28

### Changed

- 修改 `\frac` 的定义



## [0.2.4] - 2024-03-31

### Changed

- 修改 `example-single.tex` 和 `example-multiple.tex` 的细节（感谢 @gannaiju ）



## [0.2.3] - 2024-03-23

### Added

- 增加 `solution` 的 `label-indentation` 键值
- 增加手册的 “如何提问” 节



## [0.2.2] - 2024-02-22

### Added

- 增加 `solution` 的键值 `pre-analysis`


## [0.2.1] - 2024-02-15

### Fixed

- 更改手册的一处笔误


## [0.2.1] - 2024-02-11

### Added

- 增加答案控制功能
- 增加计算题排版环境 `calculations`

### Fixed

- 修复 `section` 的超链接问题


## [0.1.29] - 2024-02-07

### Added

- 增加 `fig-pos` 的同义选项 `pos`

### Changed

- 修改 `textfigure` 的选项的一些默认值



## [0.1.28] - 2023-07-14

### Changed

- 修改 `\paren` 的宽度细节


## [0.1.27] - 2023-06-27

### Added

- 完善 `enumerate` 环境的三层的间距控制


## [0.1.26] - 2023-06-22


### Fixed

- 修复 `choices` 环境的 `columns` 失效问题（#I7FBVF）



## [0.1.25] - 2023-05-25

### Changed

- 修改 `\sim*` 的效果为原来的 `\sim`(I6Z0MD)


## [0.1.24] - 2023-05-11

### Fixed

- 修复 TeXLive2023 造成的师生两版编译失效问题

## [0.1.23] - 2022-12-20

### Changed

- `\paren` 默认更改为 `show`


## [0.1.22] - 2022-09-30

### Fixed

- 修复 `foot-content` 中无法使用命令的问题（#I5NNR8）

## [0.1.21] - 2022-09-24

### Fixed

- 修复 `question` 环境结合 `\fillin` 的 label 对齐问题


## [0.1.20] - 2022-09-18

### Added

- 增加了 `textfigure/parindent` 键值
- 增加 `exam-zh-textfigure` 模块对 `wrapstuff` 的检测

### Changed

- 将 `question` 和 `problem` 的键值分开

### Removed

- 去掉 `\goodluck` 命令


## [0.1.20] - 2022-09-12

### Added

- 增加页眉接口


## [0.1.19] - 2022-08-27

### Added

- 增加 `choices` 的 `top-sep`, `bottom-sep`, `linesep` 键值
- 增加对 `minipage` 的最小行距的控制
- 增加 `\fillin` 的 `depth` 键值控制下划线的深度
- 增加图文排版模块 `exam-zh-textfigure.sty`
- 增加示例文件的图文排版

### Changed

- 修改列表环境 `enumerate` 参数
- `show-columnline` 默认值改为 `false`

### Fixed

- 修复不同字体可能导致的 `bigstar` 缺失问题
- 修复 `\ExamPrintAnswer` 的未设置编译报错问题

## [0.1.19] - 2022-08-17

### Added

- 增加 `solution/show-solution` 的等效键值：`solution/show-answer`


## [0.1.18] - 2022-08-15

### Added

- 增加新的字体

### Changed

- 修改示例文件的部分代码

## [0.1.17] - 2022-08-12

### Added

- 增加 `question` 的 `hang` 键值控制“悬挂效果”

### Fixed

- 修复同一行的 `\fillin` 造成的 `\linegoal` 冲突问题


## [0.1.16] - 2022-08-11

### Fixed

- 修复双栏下使用 `\fillin` 造成的 `linegoal` 干扰问题


## [0.1.15] - 2022-08-09

### Fixed

- 增加 `\tl_map_inline:nn` 的变体函数修复报错


## [0.1.15] - 2022-08-02

### Added

- 增加直立的 pi：`\uppi`

### Fixed

- 修复 `poem` 环境没有 `\zhu` 的注解显示问题


## [0.1.14] - 2022-07-30

### Added

- 增加 `fillin/paren-type` 控制括号的半角全角
- 增加 `fillin/width-type` 控制 `fillin/no-answer-type=none` 下 `width` 的表现

## [0.1.14] - 2022-07-29

### Fixed

- 修复 `solution` 的颜色设置影响密封线问题（#I5JJT3）
- 修复 `fillin*` 内包含文字和公式的问题（https://gitee.com/zepinglee/exam-zh/issues/I4TJTO#note_12005992_link）
- 修复 `lstlistings` 环境影响密封线问题（#I5JJT3）

## [0.1.13] - 2022-07-28

### Changed

- 优化 `question/combine-fillin` 的效果

## [0.1.12] - 2022-07-27

### Added

- 增加 `\fillin*` 命令实现自动换行

### Changed

- `exam-zh-chinese` 模块改名为 `exam-zh-chinese-english`


### Fixed

- 修复 `chapter` 下的 `question` 的序号从0开始问题
- 修复页脚 `lastpage` 前的空格自动化的问题



## [0.1.12] - 2022-07-26

### Added

- 增加 `writingbox` 环境
- 增加 `question/combine-fillin`, `question/combine-fillin-args`, `question/label-align` 键值
- 增加密封线的范围值


## [0.1.12] - 2022-07-25

### Added

- 增加第一层级 `enumerate` 的设置
- 增加 `notice` 环境的键值 `label`, `label-format`, `top-sep`, `bottom-sep`

### Changed

- 给 `notice` 环境增加参数

## [0.1.12] - 2022-07-24

### Added

- 增加密封线 `text-width`, `text-format`, `text-xscale`,`text-yscale`, `text-direction-vertical` 键值
- 增加 `select` 环境的 `above` 和 `below` 键值
- 增加 `sealline/scope` 同效键值 `sealline/type`
- 增加脚注设置
- 增加 `\subject` 的可选参数
- 增加 `scoringbox/position` 键值
- 增加 `material` 环境
- 增加 `style/footnote-style` 键值

### Changed

- `foot-style` 改为 `foot-type`
- 修改 `solution`, `choices` 的 `top-sep`, `bottom-sep` 的默认值


### Fixed

- 更正 `select/seperator` 为 `select/separator`
- 修复 `question` 环境的 `index` 减一问题

## [0.1.12] - 2022-07-23

### Changed

- 修改 `square` 键值名称
- 将 `select` 环境的 `\item` 改为 `\sitem` 以兼容 `choices` 环境

### Removed

- 去掉 `sealline/text-align` 键值


## [0.1.12] - 2022-07-22

- 修复 `fullwidth-stop` 的失效问题

## [0.1.11] - 2022-07-22

### Added

- 实现师生两版


## [0.1.11] - 2022-07-21

### Added

- `\fillin` 不显示答案时增加 `counter` 类型的显示
- `question/label` 增加基于 `TiKZ` 的带圈数字 `\tikzcirclednumber` 类型计数器
- 增加 `select/show-mark` 键值控制 `select` 环境的 mark 显示
- 增加 `fillin/no-answer-counter-label` 键值

### Changed

- `fillin/show-blacktriangle` 键值改为 `no-answer-type`
- `questioncirclednumber` 改为 `circlednumber`
- `\circlednumber` 命令增加 `\circlednumber*` 类型
- 将 `question` 环境的上下方间距从 `\addvspace` 改为 `\vspace*`

## [0.1.11] - 2022-07-20

### Added

- 增加 `question` 和 `problem`  环境的 `label` 键值
- 增加 `solution` 环境的 `parbreak` 键值

### Changed

- 完善 `question/blank-type=hide` 的效果

## [0.1.11] - 2022-07-19

### Added

- 增加手册 `choices` 环境方形和圆形 label 的示例
- 增加 `solution` 不显示解答时的垂直空白 `blank-type` 和 `blank-sep` 键值
- 增加 `solution` 的 `top-sep` 和 `bottom-sep` 键值
- 增加 `fullwidth-stop` 键值

### Changed

- 更改 `solution` 环境接口
- 修改 `change-frac-style`, `change-dfrac-style` 默认值为 `false`


### Fixed

- 修复 `missing \item` 问题（#I5HUUV）

## [0.1.10] - 2022-07-19

### Added

- 新增 `exam-zh-chinese.sty` 模块
- 新增 `select` 环境（#I5HG8K）
- 新增 `lineto` 连线环境（#I5FXOX）

## [0.1.10] - 2022-07-17

### Added

- 增加不同字体命令的效果展示
- 增加 `\frac` 和 `\dfrac` 分子分母额外间距的控制（#I5H51B）

## [0.1.9] - 2022-07-17

### Added

- 增加手册“符号”的部分

## [0.1.9] - 2022-07-16

### Added

- 密封线增加 `first-and-last` 类型

### Changed

- 去掉 `\fillin[type=paren]` 的基线调整
- 去掉 `\fillin[type=blank]` 的基线调整
- 将 `example.tex` 改为 `example-single.tex` 和 `example-multiple.tex` 分别作为单份和多份试卷排版示例


### Fixed

- 修复 `solution` 环境的列表嵌套的空格问题
- 修复 `a4paper` 无 `\chapter` 下的页面格式问题

## [0.1.9] - 2022-07-15

### Added

- 增加 `\fillin` 的 `type/blank` 值
- 增加 `\fillin` 的颜色控制
- 增加 `\paren` 的 `type` 键值
- 增加 `solution` 环境的 `text-color` 键值

### Changed

- 修改所有页面（目录除外）为统一的页眉页脚
- 将 `answer-color` 拆成 `\fillin` 和 `\paren` 的颜色分别控制


## [0.1.8] - 2022-07-14

### Fixed

- 修复了 `a3paper` 和 `foot-style=separate` 的目录页码问题


## [0.1.8] - 2022-07-12

### Fixed

- 修复 `missing number` 问题
- 修复“目录”二字重复问题

## [0.1.7] - 2022-07-08

### Added

- 将文类改为 `ctexbook`，并修改 `\chapter` 样式（#I5G2QM）
- 增加 `show-chapter` 键值控制 `\chapter` 的显示

## [0.1.7] - 2022-07-08

### Fixed

- 去掉 `.str_set:N` 使得模版兼容  TeXLive 2021 （#I5G7X2）

## [0.1.7] - 2022-07-07

### Added

- 增加 `exam-zh-symbols.sty` 模块绘制部分中国化的数学符号

### Changed

- 修改 `\complement` 的效果

### Fixed

- 修复 `a3paper` 的分数框问题（#I5FZWW）

## [0.1.7] - 2022-07-06

### Added

- 增加 `\fillin` 的 `width` 键值

## [0.1.6] - 2022-07-05

### Added

- `\fillin` 命令增加一个 `circle` 类型（#I5FMPP）

### Changed

- 将 `\paren` 和 `\fillin` 的答案控制单独分离


## [0.1.6] - 2022-07-04

### Added

- 增加 `\examsquare` 方格命令
- 增加 `step`、`method`、`case` 环境
- 增加页脚内容定制接口 `page/foot-content`

## [0.1.6] - 2022-07-03

### Added

- 增加标题的控制接口
- 增加顶部的个人信息接口
- 增加 `\warning` 命令
- 增加草稿纸 `\draftpaper` 以及相关接口

### Changed

- 将 `\goodluck` 命令改为参数式


## [0.1.5] - 2022-07-02

### Added

- 增加 `solution` 环境和 `score` 命令

## [0.1.4] - 2022-06-27

### Added

- 基本完成用户手册的编写

## [0.1.4] - 2022-06-24

### Added

- 给 `\fillin` 命令增加了可选参数接口
- `choices` 环境增加 `index` 接口

## [0.1.3] - 2022-06-22

### Added

- 增加密封线奇偶统一控制接口

### Fixed

- 修复密封线接口失效问题


## [0.1.2] - 2022-06-16

- 完成密封线的所有接口设计

## [0.1.2] - 2022-06-15

- 增加密封线


## [0.1.2] - 2022-06-14

### Added

- 新增页面尺寸 `a4paper` 和 `a3paper` 的控制
- 新增 `a3paper` 页面的“是否共用页脚”控制


## [0.1.1] - 2022-06-09

### Added

- 新增 `question` 环境的 `top-sep` 和 `bottom-sep` 选项控制前后距离（[#I4SLWN](https://gitee.com/zepinglee/exam-zh/issues/I4SLWN)）。
- 新增 `question` 环境的 `index` 选项设置题号（[#I4SQLI](https://gitee.com/zepinglee/exam-zh/issues/I4SQLI)）。
- 新增 `question` 环境的 `answer-color` 选项控制答案颜色（[#I4SW79](https://gitee.com/zepinglee/exam-zh/issues/I4SW79)）。
- 新增 `choices` 环境的 `label` 选项控制标签格式（[#I4SXC1](https://gitee.com/zepinglee/exam-zh/issues/I4SXC1)）。
- 新增 `\circlednumber` 使用中文字体生成带圈数字。
- 新增 `choices` 环境的 `label-align` 选项控制标签的对齐方式（[#I4TDSA](https://gitee.com/zepinglee/exam-zh/issues/I4TDSA)）。
- 新增 `exam-zh-font` 模块，提供西文字体 `font` 和数学字体 `math-font` 选项（[#I512EV](https://gitee.com/zepinglee/exam-zh/issues/I512EV)）。
- 新增 `fillin` 命令的 `type` 选项控制下划线和括号类型

### Fixed

- 答案的内容较高时调整深度（[#I4SXC1](https://gitee.com/zepinglee/exam-zh/issues/I4SXC1)）。

## [v0.1.0] - 2022-02-04

### Added

- 在 Gitee 发布。

[Unreleased]: https://github.com/xkwxdyy/exam-zh/compare/v0.1.0...HEAD
[v0.1.0]: https://github.com/xkwxdyy/exam-zh/releases/v0.1.0
[v0.1.1]: https://github.com/xkwxdyy/exam-zh/releases/v0.1.1
