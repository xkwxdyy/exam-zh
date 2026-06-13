> [!WARNING]
> `exam-zh` 作为开源项目开发至今，基础功能算是完善了，且没有严重的 bug，而开发者精力有限，决定于 2024 年 04 月 26 日 开始无限期停止维护 `exam-zh`。未来可能会继续维护，但不保证时间，但也可能不再维护了。
> 
> Gitee 的项目仓库不会关闭，也欢迎有能力的开发者继续维护。
> GitHub：https://github.com/xkwxdyy/exam-zh
> Gitee（国内镜像）：https://gitee.com/xkwxdyy/exam-zh
> 
> 感谢使用过此模板的用户的支持。


# exam-zh: LaTeX template for Chinese exam

Provides a class exam-zh.cls and its several module packages like exam-zh-question.sty and exam-zh-choices.sty, where these module packages can be used individually. 

Although there are several excellent exam packages or classes uploaded before like exam and bhcexam , they don't fit the chinese style very well or they cannot be customized easily for chinese exam of all types like exams in primary school, junior high school, senior high school and even college. Those are the main reason why exam-zh was created.

In exam-zh, you can

- seperate the format and the content very well;
- use choices environment to typeset choice items easily and automatically;
- design the sealline easily;
- use it in Windows, macOS and Linux;
- ... (for more that you can do with it, please read the manual（in Chinese）: `exam-zh-doc.pdf`
- QQ group: 652500180


Repository:
- GitHub: https://github.com/xkwxdyy/exam-zh
- Gitee (Mirror): https://gitee.com/xkwxdyy/exam-zh

Author: Zeping Lee
Maintainer: Kangwei Xia, Lijun Guo

Issues and pull requests are welcome:
- GitHub: https://github.com/xkwxdyy/exam-zh/issues | https://github.com/xkwxdyy/exam-zh/pulls
- Gitee: https://gitee.com/xkwxdyy/exam-zh/issues | https://gitee.com/xkwxdyy/exam-zh/pulls

# exam-zh：中国试卷 LaTeX 模板

- 项目主页：
  - GitHub: https://github.com/xkwxdyy/exam-zh
  - Gitee（国内镜像）: https://gitee.com/xkwxdyy/exam-zh
- 作者：Zeping Lee
- 维护者：Kangwei Xia, Lijun Guo
- 授权：[LaTeX Project Public License 1.3c](https://www.latex-project.org/lppl.txt)
- QQ 用户交流群：652500180


本项目提供了一个中国高考试卷样式的 LaTeX 模板，旨在帮助中小学教师更方便地使用 LaTeX。模板具有以下特性：

1. 样式与内容尽可能分离；
2. 选择题选项可以自动排版成合适的列数；
3. 通过用户接口可以方便更改密封线样式；
4. 在 Windows, macOS 和 Linux 跨平台编译。

使用前请仔细阅读用户手册 `exam-zh-doc.pdf`，可从以下发行版下载：
- GitHub Releases: https://github.com/xkwxdyy/exam-zh/releases
- Gitee 发行版: https://gitee.com/xkwxdyy/exam-zh/releases

## 示例（simple example）

```latex
\section{选择题：本题共 8 小题，每小题 5 分，共 40 分。}

\begin{question}
  设集合 $A = \{x \mid -1 < x < 4\}$，$B = \{2, 3, 4, 5\}$，则 $A \cap B = $ \paren
  \begin{choices}
    \item $\{2\}$
    \item $\{2, 3\}$
    \item $\{3, 4\}$
    \item $\{2, 3, 4\}$
  \end{choices}
\end{question}

\section{填空题：本题共 4 小题，每小题 5 分，共 20 分。}

\begin{question}
  已知函数 $f(x) = x^3 (a \cdot 2^x - 2^{-x})$ 是偶函数，则 $a = $ \fillin 。
\end{question}

\section{解答题：本题共 6 小题，共 70 分。解答应写出文字说明、证明过程或者演算步骤。}

\begin{problem}[points = 12]
  已知函数 $f(x) = x (1 - \ln x)$。讨论 $f(x)$ 的单调性。
  设 $a$，$b$ 为两个不相等的正数，且 $b \ln a - a \ln b = a - b$，
  证明：$2 < \frac{1}{a} + \frac{1}{b} < \eu$。
\end{problem}
```


## 📖 文档说明

exam-zh 提供**两份文档**，请根据需求选择：

### 🎯 入门文档（推荐新手阅读）
- **文件名**：`exam-zh-doc-basic.pdf`
- **页数**：约 40-60 页
- **适合人群**：LaTeX 新手、首次使用 exam-zh 的用户
- **内容**：
  - 5分钟快速开始指南
  - 基础概念讲解（LaTeX 零基础友好）
  - 常用功能教程（选择题、填空题、解答题等）
  - 完整示例代码（可直接复制使用）
  - 常见问题 FAQ（覆盖80%的使用问题）
- **下载**：
  - GitHub Releases: https://github.com/xkwxdyy/exam-zh/releases
  - Gitee 发行版: https://gitee.com/xkwxdyy/exam-zh/releases

### 📚 完整文档（API参考手册）
- **文件名**：`exam-zh-doc.pdf`
- **页数**：约 100+ 页
- **适合人群**：有基础、需要查询详细参数的用户
- **内容**：
  - 完整的 API 参考
  - 所有功能详细说明
  - 高级用法和定制选项
- **下载**：
  - GitHub Releases: https://github.com/xkwxdyy/exam-zh/releases
  - Gitee 发行版: https://gitee.com/xkwxdyy/exam-zh/releases

### 📝 学习路径建议
1. **完全新手**：先看《入门文档》→ 尝试 `examples-basic/` 中的示例 → 遇到问题查《完整文档》
2. **有 LaTeX 基础**：快速浏览《入门文档》第1-2章 → 直接使用《完整文档》
3. **老用户**：直接使用《完整文档》作为参考手册


## 使用方法

下面简要叙述 `exam-zh` 的使用方法，**详细使用说明请阅读《入门文档》`exam-zh-doc-basic.pdf` 或《完整文档》`exam-zh-doc.pdf`。**
### 西文和数学字体

模板中可以设置西文和数学的字体。

```tex
\examsetup{
  font      = times,
  math-font = xits,
}
```

西文字体 `font` 有以下选项：
- `newcm`（默认）New Computer Modern
- `lm` Latin Modern
- `times` Times New Roman
- `termes` TeX Gyre Termes
- `stix` STIX Two
- `xits` XITS
- `libertinus` Libertinus

数学字体 `math-font` 有以下选项：
- `newcm`（默认）New Computer Modern Math
- `lm` Latin Modern Math
- `termes` TeX Gyre Termes Math
- `stix` STIX Two Math
- `xits` XITS Math
- `libertinus` Libertinus Math
- `cambria` Cambria Math

注意数学字体使用了 `unicode-math` 宏包进行配置。


### 题目环境 `question` 和 `problem`

选择题和填空题使用 `question` 环境，解答题使用 `problem` 环境。两者的内容对齐方式不同。

`question` 和 `problem` 环境还接受一个可选参数，其中可以使用以下 key—value 进行设置。
- `index` 题号。
- `points` 题目的分数（默认：`0`）。
- `show-points` 是否显示题目的分数（默认 `auto`：选择题和填空题默认 `false`，解答题默认 `true`）。
- `show-answer` 是否同时显示 `\paren` 和 `\fillin` 的答案（默认：`false`）。
- `top-sep` 题目上方垂直方向的空白距离（默认：`.25em plus .25em minus .1em`）。
- `bottom-sep` 题目下方垂直方向的空白距离，与 `top-sep` 不叠加（默认：`.25em plus .25em minus .1em`）。

其中 `index`、`show-points`、`show-answer`、`top-sep` 和 `bottom-sep` 可以使用 `\examsetup` 命令的 `question` 层级进行全局设置。比如设置同一层级的多个选项：
```latex
\examsetup{
  question = {
    show-points = true,
    show-answer = true,
  },
}
```
也可以用斜线“/”表示层级并设置单项。
```latex
\examsetup{
  question/show-points = true,
  question/show-answer = true,
}
```


### 选择题的括号 `\paren` 和填空 `\fillin`

`\paren` 和 `\fillin` 命令分别生成选择题的括号和填空题的横线。这两个命令还分别接受一个可选参数作为题目的答案，如 `\paren[B]` 或 `\fillin[foo]`。当 `show-answer = true` 时则将答案显示在其中。

需要注意的是，如果 `\fillin` 的参数中含有不配对的中括号时会报错，如 `\fillin[$(−\infty, 1]$]`。这时需要使用大括号将内容保护起来：`\fillin[{$(−\infty, 1]$}]`。

`\fillin` 提供了样式的切换（目前就是下划线和括号两种）：
```latex
\examsetup{
  fillin = {
    type = paren    % 括号风格 
    % type = line    % 下划线风格
  }
}
```
也可以局部更改单个 `\fillin` 的样式：`\fillin[type = paren][foo]`（有答案）或 `\fillin[type = paren][]`（无答案）。


### 选项环境 `choices`

选择题的选项使用 `choices` 环境排版，可以自动根据内容的长度选择合适的列数并对齐。该环境的设计主要参考了 @xkwxdyy 的 [choices-l3](https://gitee.com/xkwxdyy/choices-l3) 和 [xchoices](https://gitee.com/xkwxdyy/xchoices) 项目。
```latex
\begin{choices}[label-pos = top-left]
  \item $\{2\}$
  \item $\{2, 3\}$
  \item $\{3, 4\}$
  \item $\{2, 3, 4\}$
\end{choices}
```
其中的可选参数使用 key–value 的方式进行设置，除了 `label-pos` 外还包括以下选项。
- `index`       第一个选项标签的计数器的数字值（默认为 `1`）。
- `column-sep`  选项列之间的最小间隔（默认 `1em`）。
- `columns`     强制按照该列数排版选项，如果为 0 则自动选择合适的列数（默认 `0`）。
- `label-align`（可选：`left`, `center`, `right`；默认 `right`）标签内容的对齐方式。
- `label`       标签的格式，类似 `enumitem` 可以在 `\Roman` 等命令后加 `*` 生成数字（默认 `\Alph*.`）。
- `label-pos`   标签相对于选项内容的位置；`auto` 表示自动选择：如果内容高度超过两行时（通常是图片）标签位于左居中 `left`，否则位于左上角跟首行文字对齐（`top-left`）（可选：`auto`, `top-left`, `left`, `bottom`；默认 `auto`）。
- `label-align` 标签内部的对齐方式。（可选：`left`, `center`, `right`；默认 `right`）
- `label-sep`   标签与选项之间的距离（默认 `0.5em`）。
- `label-width` 标签的宽度；如果宽度不足会自动调整为最长标签的宽度（默认 `0pt`）。
- `max-columns` 选项的最大列数；排版选项时会优先尝试该列数，如果无法排下内容，依次将列数除以 2 并取整再进行尝试，直到可以排下全部选项（默认 `4`）。

这些选项可以使用 `\examsetup` 命令的 `choices` 层级进行全局设置，类似 `question`。

`exam-zh-choices` 模块还提供了 `\circlednumber` 命令调用中文字体生成带圈数字，该命令既可以接受 LaTeX2e 计数器的名字（如 `section`）作为参数，也可以接受数值表达式，比如 `\circlednumber{7}`，但仅限 0～50 的整数。而且有的字体可能没有提供 10 以上的字形，建议只对 10 以内的值使用。

如果用户需要使用其他形式的数字作为 `choices` 的标签，需要使用 `\AddChoicesCounter` 命令将其添加进 `label` 选项的识别范围内（类似 `enumitem` 的 `\AddEnumerateCounter`）。它的格式是 `\AddChoicesCounter{⟨LaTeX command⟩}{⟨internal command⟩}`，其中 `⟨LaTeX command⟩` 是在 `label` 选项中的形式，`⟨internal command⟩` 是内部的实现。比如带圈数字的添加方法：`\AddChoicesCounter{\circlednumber}{\__examzh_choices_circled_number:n}`。


### 解答环境 `solution` 和分数命令 `\score`

```latex
\begin{solution}
  函数的定义域为 $(0, +\infty)$,
  又 \[f^{\prime}(x) = 1 - \ln x-1 = -\ln x, \score{2}\]
  当 $x \in(0, 1)$ 时, $f^{\prime}(x) > 0$, 当 $x \in(1, +\infty)$ 时, $f^{\prime}(x) < 0$,
  故 $f(x)$ 的递增区间为 $(0,1)$, 递减区间为 $(1, +\infty)$.
\end{solution}
```
用于解答题的解答环境，以及 `\score` 命令输出给分点，具体使用和相关键值请阅读手册。

### 正体的数学常数

按照国标，数学常数应使用正体。模板中提供了命令 `\eu` 和 `\iu` 分别表示自然对数的底“e”和虚数单位“i”。`\eu` 可以理解为 “e upright” 的缩写或者 “Euler's number” 的首字母，`\iu` 可以理解为 “i upright” 或 “imaginary unit” 的缩写，这样更方便记忆。圆周率“π”直接使用 `\uppi` 命令。


### 密封线

```latex
  \examsetup{
    sealline = {
      show        = true,
      % scope        = firstpage,
      % scope        = oddpage,
      scope        = everypage,
      line-thickness       = 1pt,
      line-xshift          = 8mm,
      line-yshift          = 0mm,
      line-type            = densely-dashed,
      text                 = 密封线内不得答题,
      text-xshift          = 11mm,
      text-yshift          = 30mm,
      circle-show          = true,
      circle-start         = 0.07,
      circle-end           = 0.92,
      circle-step          = 3.5em,
      circle-diameter      = 3mm,
      circle-xshift        = 8mm,
      odd-info-content     = {
        {\kaishu 姓名}：{\underline{\hspace*{8em}}},
        {\kaishu 准考证号}：{\underline{\hspace*{8em}}},
        {\kaishu 考场号}：{\underline{\hspace*{8em}}},
        {\kaishu 座位号}：{\underline{\hspace*{8em}}},
      },
      odd-info-seperator   = \hspace*{3em},
      odd-info-align       = center,
      odd-info-xshift      = 20mm,
      odd-info-yshift      = 0mm
    }
  }
```

具体密封线参数含义从参数名称基本可以知道，具体的可以看手册 `exam-zh-doc.pdf`。

## 反馈

欢迎反馈项目的问题或者改进建议。推荐使用发 issue 的形式，并且附上相关的代码和截图。



## 使用授权

本项目以 LaTeX Project Public License v1.3 协议发布。




## 相关项目

- Philip Hirschhorn, `exam`: <https://www.ctan.org/pkg/exam>
- 鲍宏昌 `BHCexam`: <https://github.com/mathedu4all/bhcexam>
- 吕荐瑞 `jnuexam`: <https://www.ctan.org/pkg/jnuexam>
- @htharoldht `USTBExam`: <https://github.com/htharoldht/USTBExam>
- 唐绍东 `GEEexam`: <https://github.com/shaodongtang/gaokao_exam>
- 唐绍东 `CMC`: <https://github.com/shaodongtang/CMC>
- @sd44 `DANexam`: <https://github.com/sd44/DANexam>
- 胡振震 `simplexam`: <https://github.com/hushidong/simplexam>
