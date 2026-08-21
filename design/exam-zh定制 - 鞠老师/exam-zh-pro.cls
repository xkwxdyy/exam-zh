%
% Copyright (c) 2022 Zeping Lee
% Released under the LaTeX Project Public License v1.3c License.
% Repository: https://gitee.com/xkwxdyy/exam-zh
%

\NeedsTeXFormat{LaTeX2e}[2017/04/15]
\RequirePackage{expl3}
\ProvidesExplClass {exam-zh-pro} {2026-08-21} {v2.13} {LaTeX template for Chinese exam}

% 检查 LaTeX2e kernel 版本
\msg_new:nnn { exam-zh } { latex-too-old }
  { TeX~ Live~ 2020~ or~ later~ version~ is~ required~ to~ compile~ this~ document. }
\@ifl@t@r \fmtversion { 2020/02/02 }
  { }
  { \msg_fatal:nn { exam-zh } { latex-too-old } }

% 检查编译引擎，要求使用 XeLaTeX。
\msg_new:nnn { exam-zh } { incompatible-engine }
  { XeLaTeX~ is~ required~ to~ compile~ this~ document. }

\sys_if_engine_xetex:F
  { \msg_fatal:nn { exam-zh } { incompatible-engine } }


% 使用 l3keys 定义 \examsetup 配置命令
\NewDocumentCommand \examsetup { m }
  { \keys_set:nn { exam-zh } {#1} }



% 加载文档类和宏包

% 处理文档类选项
\PassOptionsToClass { UTF8 , scheme = chinese, openany } { ctexbook }
\DeclareOption* { \PassOptionsToClass { \CurrentOption } { ctexbook } }
\ProcessOptions*

\RequirePackage { filehook }
\AtEndOfPackageFile* { fontspec }
  { \msg_redirect_name:nnn { fontspec } { no-script } { none } }
\AtEndOfPackageFile* { xeCJK }
  {
    \msg_redirect_name:nnn { xeCJK } { CJKfamily-redef } { none }
    \defaultCJKfontfeatures
      {
        Script  = CJK,
        % Mapping = fullwidth-stop ,
      }
  }

% 载入 \cls{ctexbook} 文档类。
\LoadClass { ctexbook }

% 要求 ctex v2.4.9 2017-04-01 或更高的版本。
\msg_new:nnn { exam-zh } { require-package-version }
  { The~ package~ "#1"~ is~ required. }

\@ifclasslater { ctexbook } { 2017/04/01 }
  { }
  {
    \msg_fatal:nnn { exam-zh } { require-package-version }
      { ctex~ v2.4.9~ 2017-04-01 }
  }

% 建议在模板开始处载入全部宏包，不要轻易改变加载顺序。
\RequirePackage { etoolbox }
\RequirePackage { geometry }
\RequirePackage { fontspec }
\RequirePackage { xeCJK }
\RequirePackage { xeCJKfntef }
\RequirePackage { fancyhdr }
\RequirePackage { lastpage }
\RequirePackage { amsmath }
\RequirePackage { enumitem }
\RequirePackage { varwidth }
\RequirePackage { tocloft }
\RequirePackage { amsthm }
\@ifpackageloaded { tcolorbox }
  { \tcbuselibrary { breakable } }
  { \RequirePackage [ most ] { tcolorbox } }
% https://github.com/CTeX-org/forum/issues/264#issuecomment-1200087776
\disable@package@load { etex }
  {
    \cs_set_eq:NN \globcount \newcount
    \cs_set_eq:NN \globdimen \newdimen
  }
\RequirePackage { linegoal }
\RequirePackage { tabularray }
\RequirePackage { graphicx }
\RequirePackage { filehook }
\RequirePackage { unicode-math }
\RequirePackage { fontawesome5 }

% linegoal 2.9 会把 XeTeX 的 1sp 级横坐标波动原样写入辅助文件。
% 将测量值舍入到 64sp，并避免保存未被其宽度计算使用的原始 posx，
% 防止依赖 linegoal 的换行在 latexmk 多轮编译时无法收敛。
\cs_new:Npn \__examzh_linegoal_round_position:n #1
  { \int_eval:n { 64 * \int_div_round:nn {#1} { 64 } } }
\cs_gset:cpn { Z@C@linegoal }
  {
    \dimexpr
      \linewidth
      - \__examzh_linegoal_round_position:n { \tex_lastxpos:D } sp
      + \ifodd
          \zref@extractdefault
            { linegoal/posx.\the\LNGL@unique } { page } \c@page
          \oddsidemargin
        \else
          \evensidemargin
        \fi
      + 1in + \hoffset
    \relax
  }
\msg_new:nnn { exam-zh } { linegoal-patch-failed }
  { Unable~to~patch~linegoal;~check~the~installed~package~version. }
\patchcmd \LNGL@set
  { \zref@labelbyprops { linegoal/posx.\the\LNGL@unique } { page,posx } }
  { \zref@labelbyprops { linegoal/posx.\the\LNGL@unique } { page } }
  { }
  { \msg_error:nn { exam-zh } { linegoal-patch-failed } }

\file_if_exist:nT { wrapstuff.sty }
  {
    \RequirePackage { wrapstuff }
    \AtEndOfPackageFile* { exam-zh-choices }
      {
        \AddToHook { env / choices / before }
          { \wrapstuffclear }
      }
  }


\ExplSyntaxOff
\RequirePackage { tikzpagenodes }
\usetikzlibrary { decorations.markings }
\usetikzlibrary { decorations.text }
\usetikzlibrary { shapes.misc }
\ExplSyntaxOn



\AtEndPreamble
  {
    \RequirePackage { hyperref }
    \hypersetup
      {
        bookmarksnumbered = true,
        psdextra          = true,
        unicode           = true,
        hidelinks
      }
  }


% 对冲突的宏包报错。
\msg_new:nnn { exam-zh } { package-conflict }
  { The~ "#2"~ package~ is~ incompatible~ with~ "#1". }

\cs_new:Npn \examzh_package_conflict:nn #1#2
  {
    \AtEndOfPackageFile* {#1}
      {
        \AtBeginOfPackageFile* {#2}
          { \msg_error:nnnn { exam-zh } { package-conflict } {#1} {#2} }
      }
  }

\examzh_package_conflict:nn { unicode-math } { amscd }
\examzh_package_conflict:nn { unicode-math } { amsfonts }
\examzh_package_conflict:nn { unicode-math } { amssymb }
\examzh_package_conflict:nn { unicode-math } { bbm }
\examzh_package_conflict:nn { unicode-math } { bm }
\examzh_package_conflict:nn { unicode-math } { eucal }
\examzh_package_conflict:nn { unicode-math } { eufrak }
\examzh_package_conflict:nn { unicode-math } { mathrsfs }
\examzh_package_conflict:nn { unicode-math } { newtxmath }
\examzh_package_conflict:nn { unicode-math } { upgreek }

\examzh_package_conflict:nn { enumitem } { paralist }


% 生成函数变体
\cs_generate_variant:Nn \tl_map_inline:nn { xn }

% 标点处理
\tl_const:Nn \c__examzh_fwid_full_stop_tl { ^^^^ff0e }

\keys_define:nn { exam-zh }
  { style .meta:nn = { exam-zh / style } {#1} }
\keys_define:nn { exam-zh / style }
  {
    fullwidth-stop .choice:,
    fullwidth-stop .value_required:n = true,
    fullwidth-stop / catcode .code:n =
      { 
        \__examzh_set_fullwidth_stop_catcode:
      },
    fullwidth-stop / false .code:n = { }
  }
\cs_new:Npn \__examzh_set_fullwidth_stop_catcode:
  {
    \char_set_active_eq:NN ^^^^3002 \c__examzh_fwid_full_stop_tl
    \char_set_catcode_active:N ^^^^3002
  }

\keys_set:nn { exam-zh / style }
  {
    fullwidth-stop = false
  }

\keys_set:nn { ctex }
  {
    % 修改目录层级
    tocdepth = 0,
    chapter = 
      {
        numbering   = false,
        beforeskip  = -4ex,
        afterskip   = 4ex minus 1ex
      }
  }

% 师生两版

% 用户自定义统一控制的预设 (将所需要控制的键值进行预设置)

\NewDocumentCommand { \ExamPrintAnswerSet } { O{} m }
  % #1: 命令
  % #2: 键值  foo/bar
  {
    \clist_const:Nn \g__examzh_print_answer_cmd_set_clist {#1}
    \clist_const:Nn \g__examzh_print_answer_keys_set_clist {#2}
  }

\NewDocumentCommand { \ExamPrintAnswer } { }
  {
    \clist_if_exist:NT \g__examzh_print_answer_cmd_set_clist
      { \clist_use:Nn \g__examzh_print_answer_cmd_set_clist {} }
    \clist_if_exist:NT \g__examzh_print_answer_keys_set_clist
      {
        \keys_set:nx { exam-zh }
          { \g__examzh_print_answer_keys_set_clist }
      }
  }



\str_new:N \l__examzh_latexmk_engine_str
\str_new:N \g__examzh_student_version_jobname_str
\str_new:N \l__examzh_student_version_suffix_str
\str_const:Nn \l__examzh_latexmk_str { latexmk }

\keys_define:nn { exam-zh / style }
  {
    student-version-suffix .code:n = 
      { \str_set:Nn \l__examzh_student_version_suffix_str {#1} },
    student-version-cleanaux .bool_set:N = \l__examzh_student_version_clean_aux_bool
  }
\keys_set:nn { exam-zh / style }
  {
    student-version-suffix   = { _student_version },
    student-version-cleanaux = true
  }

\cs_new:Nn \__examzh_build_student_version_jobname:
  {
    \str_gset:Nx \g__examzh_student_version_jobname_str { \c_sys_jobname_str }
    \str_gremove_all:Nn \g__examzh_student_version_jobname_str { " }
    \str_gput_left:Nn \g__examzh_student_version_jobname_str { " }
    \str_gput_right:Nx \g__examzh_student_version_jobname_str { \l__examzh_student_version_suffix_str }
    \str_gput_right:Nn \g__examzh_student_version_jobname_str { " }
  }

\AtEndPreamble
  {
    \sys_if_shell_unrestricted:T
      {
        \str_set:Nn \l__examzh_latexmk_engine_str { -xelatex }
        \__examzh_build_student_version_jobname:
        \sys_shell_now:x
          {
            \l__examzh_latexmk_str \c_space_tl
            \l__examzh_latexmk_engine_str \c_space_tl
            -pretex='
              % \string\RequirePackage{etoolbox}
              % \string\BeforeBeginEnvironment{document}{\string\ExamPrintAnswer}
              \string\AddToHook{env/document/before}{\string\ExamPrintAnswer}
              % \string\AtBeginDocument{\string\ExamPrintAnswer}
            ' \c_space_tl
            -usepretex \c_space_tl
            -jobname=\g__examzh_student_version_jobname_str \c_space_tl
            \c_sys_jobname_str
            \bool_if:NT \l__examzh_student_version_clean_aux_bool
              {
                &&
                \l__examzh_latexmk_str \c_space_tl
                \l__examzh_latexmk_engine_str \c_space_tl
                -c \c_space_tl
                -jobname=\g__examzh_student_version_jobname_str \c_space_tl
                \c_sys_jobname_str
              }
          }
        \sys_shell_now:x
          {
            \l__examzh_latexmk_str \c_space_tl
            \l__examzh_latexmk_engine_str \c_space_tl
            \c_sys_jobname_str
            \bool_if:NT \l__examzh_student_version_clean_aux_bool
              {
                &&
                \l__examzh_latexmk_str \c_space_tl
                \l__examzh_latexmk_engine_str \c_space_tl
                -c \c_space_tl
                \c_sys_jobname_str
              }
          }
        \stop
      }
  }


% 处理目录
% \patchcmd { \tableofcontents }
%   { \@starttoc{toc} }
%   {
%     \thispagestyle { empty } 
%     \pagestyle { empty }
%     \@starttoc{toc} 
%   }
%   {}{\fail}
\AtBeginDocument
  {
    \patchcmd { \tableofcontents }
      { \@starttoc{toc} }
      {
        \thispagestyle { empty } 
        \pagestyle { empty }
        \@starttoc{toc} 
      }
      {}{\fail}
    \cs_set_eq:NN \__examzh_tableofcontents_aux: \tableofcontents
    \RenewDocumentCommand { \tableofcontents } { }
      {
        \newpage
          \cs_set_eq:NN \onecolumn \twocolumn
          % \bool_set_true:N \g__examzh_page_show_chapter_bool
          % \keys_set:nn { ctex }
          %   {
          %     chapter = 
          %       {
          %         beforeskip  = 1pt,
          %         afterskip   = 2ex minus 1ex,
          %       },
          %   }
          \__examzh_tableofcontents_aux:
          \thispagestyle { empty }
          % \pagestyle { empty }
        % \group_end:
        \newpage
        % 将页码计数器重设置为 1
        % \bool_if:cTF { g__examzh_page_size_a4paper_bool }
        %   { \int_set:Nn \c@page { 0 } }
        %   { \int_set:Nn \c@page { 1 } }
        \int_set:Nn \c@page { 1 }
      }
  }
\AtEndPreamble
  {
    % A3 情况 separate 的目录页码需要改为 2* -1
    \bool_lazy_and:nnT
      {
        ! \bool_if_p:c { g__examzh_page_size_a4paper_bool }
      }
      {
        ! \bool_if_p:c { g__examzh_page_a3paper_foot_common_bool }
      }
      {
        \cs_set_eq:Nc \addcontentsline { __examzh_addcontentsline_a3paper_separate:nnn }
      }
  }
% https://tex.stackexchange.com/questions/650823/why-my-patch-to-addcontentsline-is-broken-in-atendpreamble-and-bool-ifnt
% 改自 hyperref.sty
\cs_set:cpn { __examzh_addcontentsline_a3paper_separate:nnn } #1#2#3
  {
    \begingroup
      \let\label\@gobble
      \ifx\@currentHref\@empty
        \Hy@Warning{
          No destination for bookmark of \string\addcontentsline,%
          \MessageBreak destination is added%
        }
        \phantomsection
      \fi
      \expandafter\ifx\csname toclevel@#2\endcsname\relax
        \begingroup
          \def\Hy@tempa{#1}
          \ifx\Hy@tempa\Hy@bookmarkstype
            \Hy@WarningNoLine{
              bookmark level for unknown #2 defaults to 0%
            }
          \else
            \Hy@Info{bookmark level for unknown #2 defaults to 0}%
          \fi
        \endgroup
        \expandafter\gdef\csname toclevel@#2\endcsname{0}%
      \fi
      \edef\Hy@toclevel{\csname toclevel@#2\endcsname}%
      \Hy@writebookmark{\csname the#2\endcsname}%
        {#3}
        {\@currentHref}
        {\Hy@toclevel}
        {#1}
      \ifHy@verbose
        \begingroup
          \def\Hy@tempa{#3}
          \@onelevel@sanitize\Hy@tempa
          \let\temp@online\on@line
          \let\on@line\@empty
          \Hy@Info{
            bookmark\temp@online:\MessageBreak
            thecounter {\csname the#2\endcsname}\MessageBreak
            text {\Hy@tempa}\MessageBreak
            reference {\@currentHref}\MessageBreak
            toclevel {\Hy@toclevel}\MessageBreak
            type {#1}
          }
        \endgroup
      \fi
      \addtocontents{#1}{
        \protect\contentsline{#2}{#3}
          % {\thepage}
          { \int_eval:n { 2 * \c@page - 1 } }
          {\@currentHref}\protected@file@percent
      }
    \endgroup
  }
\keys_define:nn { exam-zh / page }
  {
    show-chapter .bool_gset:N = \g__examzh_page_show_chapter_bool
  }
\keys_set:nn { exam-zh / page }
  {
    show-chapter = false
  }

% 不显 chapter 时不会增加 \c@chapter，所以要新建一个计数器
\int_new:N \g__examzh_hide_chapter_counter_int


\cs_set_eq:NN \__examzh_chapter:nn \chapter
\cs_new:Npn \__examzh_chapter_star:n #1
  {
    \__examzh_chapter:nn * {#1}
  }
\RenewDocumentCommand{ \chapter }{ s o m }
  {
    \keys_set:nn { exam-zh / question }
      { index = 1 }
    \int_set:Nn \c@section { 0 }
    \bool_if:NTF \g__examzh_page_show_chapter_bool
      {
        \IfBooleanTF {#1}
          { \__examzh_chapter_star:n {#3} }
          {
            \IfNoValueTF {#2}
              { \__examzh_chapter:nn {#3} }
              { \__examzh_chapter:nn [#2] {#3} }
          }
        \pagestyle { plain }
      }
      {
        \IfBooleanF {#1}
          {
            \newpage
            % 只录入目录
            \phantomsection
            \int_gincr:N \g__examzh_hide_chapter_counter_int
            \addcontentsline { toc } { chapter } 
              {
                \int_use:N \g__examzh_hide_chapter_counter_int.~
                #3
              }
            \pagestyle { plain }
            \__examzh_chapter_store_title_new:
            \__examzh_chapter_store_title:n {#3}
          }
        \clearpage
      }
  }

% Unified entry point for one paper: title, question numbering, and answers.
\msg_new:nnn { exam-zh } { exam-paper-not-found }
  { The~exam~paper~file~"#1.tex"~does~not~exist. }
\NewDocumentCommand \IncludeExamPaper { m m }
  {
    \file_if_exist:nTF {#2.tex}
      {
        \chapter {#1}
        \include {#2}
      }
      { \msg_error:nnn { exam-zh } { exam-paper-not-found } {#2} }
  }

% \AtEndDocument
%   {
%     % \tl_use:c { g__examzh_chapter_title_ \int_use:N \g__examzh_hide_chapter_counter_int _tl }
%     \int_step_inline:nn { \g__examzh_hide_chapter_counter_int }
%       {
%         % \tl_use:c { g__examzh_chapter_title_ #1 _tl }
%         \__examzh_show_answer_together_behind:n {#1}
%       }
%   }



% 把 chapter 的内容存起来

% 新建
\cs_new:Npn \__examzh_chapter_store_title_new:
  {
    \tl_if_exist:cF { g__examzh_chapter_title_ \int_use:N \g__examzh_hide_chapter_counter_int _tl }
      {
        % 不存在就新建
        \tl_new:c { g__examzh_chapter_title_ \int_use:N \g__examzh_hide_chapter_counter_int _tl }
      }
  }

% 把 chapter 内容存起来
\cs_new:Npn \__examzh_chapter_store_title:n #1
  {
    \tl_gset:cx { g__examzh_chapter_title_ \int_use:N \g__examzh_hide_chapter_counter_int _tl } {#1}
  }

% 统一在最后输出答案
\cs_new:Npn \__examzh_show_answer_together_behind:n #1
  {
    \newpage
    % \__examzh_chapter_star:n 
      % {
      \begin{center}
        \bfseries \zihao{3}
        \tl_use:c { g__examzh_chapter_title_ #1 _tl }
        参考答案
      \end{center}
      % }
      \vspace*{3ex}
    \phantomsection
    \addcontentsline { toc } { chapter } 
      {
        \hphantom{#1.~}
        \tl_use:c { g__examzh_chapter_title_ #1 _tl }
        参考答案
      }
  }
\cs_generate_variant:Nn \__examzh_show_answer_together_behind:n { V }
% 有标号
\cs_new:Npn \__examzh_show_answer_together_behind_numbered:n #1
  {
    \newpage
    % \__examzh_chapter_star:n 
      % {
        \begin{center}
          \bfseries \zihao{3}
          \tl_use:c { g__examzh_chapter_title_ #1 _tl }
          参考答案
        \end{center}
      % }
    \vspace*{3ex}
    \phantomsection
    \addcontentsline { toc } { chapter } 
      {
        #1.~
        \tl_use:c { g__examzh_chapter_title_ #1 _tl }
        参考答案
      }
    % \@writefile {toc}
      % {
        % \contentsline
        %   {chapter}
        %   {
        %     #1.~
        %     % \tl_use:c { g__examzh_chapter_title_ #1 _tl }
        %     参考答案
        %   }
          % {}
        %   {}\protected@file@percent
      % }
  }
\cs_generate_variant:Nn \__examzh_show_answer_together_behind_numbered:n { V }
% 不用 chapter 时
\cs_new:Npn \__examzh_show_answer_no_chapter_behind:
  {
    \newpage
    \__examzh_chapter_star:n 
      {
        参考答案
      }
    % \phantomsection
    % \addcontentsline { toc } { chapter } 
    %   {
    %     参考答案
    %   }
  }

% 纸张和页面布局

\msg_new:nnn { exam-zh } { custom-paper-width-required }
  { page/paper-width~must~be~positive~when~page/size=custom. }
\msg_new:nnn { exam-zh } { custom-paper-height-required }
  { page/paper-height~must~be~positive~when~page/size=custom. }

% 控制 a3paper 和常规单页纸张（a4paper 或 custom）
\bool_new:c { g__examzh_page_size_a4paper_bool }
% custom 纸张使用常规单页的页脚模型，而不是 a3paper 的双页拼版模型
\bool_new:N \g__examzh_page_size_custom_bool
\dim_new:N \g__examzh_page_paper_width_dim
\dim_new:N \g__examzh_page_paper_height_dim
\dim_new:N \g__examzh_page_margin_dim
\dim_new:N \g__examzh_page_headheight_dim
% a3paper 的页脚：两页共用一个或者仍然一页一个
\bool_new:c { g__examzh_page_a3paper_foot_common_bool }

\keys_define:nn { exam-zh / page }
  {
    % 页面大小
    size .choice:,
    size / a3paper .code:n =
      {
        \bool_gset_false:c { g__examzh_page_size_a4paper_bool }
        \bool_gset_false:N \g__examzh_page_size_custom_bool
      },
    size / a4paper .code:n =
      {
        \bool_gset_true:c { g__examzh_page_size_a4paper_bool }
        \bool_gset_false:N \g__examzh_page_size_custom_bool
      },
    size / custom .code:n =
      {
        \bool_gset_true:c { g__examzh_page_size_a4paper_bool }
        \bool_gset_true:N \g__examzh_page_size_custom_bool
      },
    size .value_required:n = true,
    paper-width .dim_gset:N = \g__examzh_page_paper_width_dim,
    paper-height .dim_gset:N = \g__examzh_page_paper_height_dim,
    margin .dim_gset:N = \g__examzh_page_margin_dim,
    headheight .dim_gset:N = \g__examzh_page_headheight_dim,
    % 页脚的类型
    foot-type .choice:,
    foot-type / common .code:n =
      {
        \bool_gset_true:c 
          { g__examzh_page_a3paper_foot_common_bool }
      },
    foot-type / separate .code:n =
      {
        \bool_gset_false:c 
          { g__examzh_page_a3paper_foot_common_bool }
      }
  }
\keys_set:nn { exam-zh / page }
  {
    size = a4paper,
    paper-width = 0pt,
    paper-height = 0pt,
    margin = 1in,
    headheight = 0.7in,
    foot-type = separate,
  }

\keys_define:nn { exam-zh }
  {
    page .meta:nn = { exam-zh / page } {#1} 
  }


% 字体

% 中文字体

% 在 ctex 的字体配置的基础上进行一些修改
% 将苹方和微软雅黑分别替换为华文黑体和中易黑体

\str_if_eq:onTF { \g__ctex_fontset_tl } { mac }
  {
    % \setCJKmainfont{Source~Han~Serif~SC}
    %   [
    %     ItalicFont     = FZKai-Z03,
    %   ]
    \setCJKsansfont { Heiti~ SC~ Light } [ BoldFont = Heiti~ SC~ Medium ]
  }
  {
    \str_if_eq:onT { \g__ctex_fontset_tl } { windows }
      { 
        % \setCJKmainfont{Source~Han~Serif~SC}
        %   [
        %     ItalicFont     = FZKai-Z03,
        %   ]
        \setCJKsansfont { SimHei } 
      }
  }

% 罗马数字使用中文字体
\xeCJKDeclareCharClass { CJK } { "2160 -> "217F }
% 带圈数字
\xeCJKDeclareCharClass { CJK } { "2460 -> "2473 }


% 如果有内容较高（如分式）使得行间距小于 0.5em，则将其增加至 0.5em。
\dim_set:Nn \lineskiplimit { .5em }
\skip_set:Nn \lineskip { .5em }

% 增加对 minipage 的处理
% https://tex.stackexchange.com/a/358080/246645
\dim_set:Nn \normallineskiplimit { .5em }
\skip_set:Nn \normallineskip { .5em }



% 设置 enumitem 列表格式
\keys_define:nn { exam-zh / list }
  {
    step-name .tl_set:N = \l__examzh_list_step_name_tl,
    method-name .tl_set:N = \l__examzh_list_method_name_tl,
    case-name .tl_set:N = \l__examzh_list_case_name_tl,
    step-punct .tl_set:N = \l__examzh_list_step_punct_tl,
    method-punct .tl_set:N = \l__examzh_list_method_punct_tl,
    case-punct .tl_set:N = \l__examzh_list_case_punct_tl,
  }
\keys_set:nn { exam-zh / list }
  {
    step-name     = 步骤,
    method-name   = 方法,
    case-name     = 情形,
    step-punct    = .,
    method-punct  = ,
    case-punct    = .,
  }
\keys_define:nn { exam-zh }
  { list .meta:nn = { exam-zh / list } {#1} }

\setlist{nosep}
\setlist
  {
    labelsep    = 2pt,
  }

\setlist[enumerate, 1]
  {
    labelindent = \parindent,
    labelsep    = 4pt,
    leftmargin  = *,
    % label       = { \arabic * .}
    label       = {（ \arabic * ）},
  }

\setlist[enumerate, 2]
  {
    % labelindent = *,
    leftmargin  = 2em, 
    widest      = 0,
    itemindent  = 0em,
    labelsep    = 0pt,
    % labelwidth  = 2em,
    listparindent = \parindent,
    label       = {（ \alph * ）},
  }
\setlist[enumerate, 3]
  {
    % labelindent = *,
    leftmargin  = 2em, 
    widest      = 0,
    itemindent  = 0em,
    labelsep    = 0pt,
    % labelwidth  = 2em,
    listparindent = \parindent,
    label       = {（ \roman * ）},
  }
% 多种方法: method环境
\newlist{method}{enumerate}{1}
\setlist[method, 1]
  {
    label = {\bfseries \l__examzh_list_method_name_tl \zhnum*\l__examzh_list_method_punct_tl},
    labelindent = !,
    labelwidth  = 1.3cm,
    labelsep*   = 0.5em,
    leftmargin  = 1.4cm
  }
% 分类讨论: case环境
\newlist{case}{enumerate}{2}
\setlist[case, 1]
  {
    label = {\bfseries \l__examzh_list_case_name_tl \arabic*\l__examzh_list_case_punct_tl},
    % labelindent=-3em ,labelwidth=1.3cm, labelsep*=1em, leftmargin=20pt
    labelindent = !,
    labelwidth  = 1.3cm,
    labelsep*   = 0.5em,
    leftmargin  = 1.7cm
    % labelindent=\parindent, leftmargin=0pt, widest=0, itemindent=*
  }
\setlist[case, 2]
  {
    label = {\bfseries \l__examzh_list_case_name_tl \arabic{casei}.\arabic*\l__examzh_list_case_punct_tl},
    % labelindent=-1em ,labelwidth=1.3cm, labelsep*=1em, leftmargin =20pt
    labelindent = -0.5em,
    labelwidth  = 1.3cm,
    labelsep*   = 0.5em,
    leftmargin  = 0cm
  }
% 分步: step环境
\newlist{step}{enumerate}{2}
\setlist[step, 1]
  {
    label = {\bfseries \l__examzh_list_step_name_tl \arabic*\l__examzh_list_step_punct_tl},
    labelindent = !,
    labelwidth  = 1.3cm,
    labelsep*   = 0.5em,
    leftmargin  = 1.7cm
    % labelindent=\parindent, leftmargin = 0pt, widest = 0, itemindent = *
  }
\setlist[step, 2]
  {
    label       =  {\bfseries \l__examzh_list_step_name_tl \arabic{stepi}.\arabic*\l__examzh_list_step_punct_tl},
    labelindent = -0.5em,
    labelwidth  = 1.3cm,
    labelsep*   = 0.5em, 
    leftmargin  = 0cm
  }

% 横向的个人信息

\clist_new:N \l__examzh_horizontal_information_clist

\NewDocumentCommand \information { O{\quad} m }
% #1 分隔符
% #2 信息内容
  {
    \clist_set:Nn \l__examzh_horizontal_information_clist {#2}
    \__examzh_print_horizontal_information:n {#1}
  }
\cs_new:Npn \__examzh_print_horizontal_information:n #1
  {
    \par \null \hfill
    \clist_use:Nn \l__examzh_horizontal_information_clist {#1}
    \hfill \null \par
  }

% 警告，如“在此卷上答题无效”
\NewDocumentCommand \warning { O{\large \sffamily \bfseries} m }
  {
    \group_begin:
      #1
      \hfill #2 \hfill \null
    \group_end:
    \par
  }


% 标题处理
\keys_define:nn { exam-zh / title }
  {
    title-format .tl_set:N = \l__examzh_title_format_tl,
    subject-format .tl_set:N = \l__examzh_subject_format_tl,
    subject-sep .skip_set:N = \l__examzh_title_subject_sep_skip,
    top-sep .skip_set:N = \l__examzh_title_top_sep_skip,
    bottom-sep .skip_set:N = \l__examzh_title_bottom_sep_skip,
  }
\keys_set:nn { exam-zh / title }
  {
    title-format   = \Large,
    subject-format = \sffamily \bfseries \huge,
    subject-sep    = -.35em,
    top-sep        = -.5em,
    bottom-sep     = .33em,
  }
\keys_define:nn { exam-zh }
  { title .meta:nn = { exam-zh / title } {#1} }

\cs_new_protected:Npn \__examzh_spread_box:nn #1#2
  {
    \mode_leave_vertical:
    \hbox_to_wd:nn {#1}
      { \tl_map_inline:xn {#2} { ##1 \hfil } \unskip }
  }

% 科目
\tl_new:N \l__examzh_subject_tl
\NewDocumentCommand \subject { o m }
  {
    \IfNoValueTF {#1}
      {
        % 默认使用自然宽度
        \hbox_set:Nn \l_tmpa_box {#2}
        \dim_set:Nn \l_tmpa_dim { \box_wd:N \l_tmpa_box * 2 }
        \tl_set:Nn \l__examzh_subject_tl
          {
            \__examzh_spread_box:nn { \l_tmpa_dim } {#2}
          }
      }
      {
        % 手动调整宽度
        \tl_set:Nn \l__examzh_subject_tl
          {
            \__examzh_spread_box:nn {#1} {#2}
          }
      }
  }

% 输出标题
\RenewDocumentCommand \maketitle { }
  {
    \par
    \vspace { \l__examzh_title_top_sep_skip }
    \group_begin:
      \centering
      \let \footnote \thanks
      { \l__examzh_title_format_tl \@title \par }
      \tl_if_blank:VF \l__examzh_subject_tl
        {
          \vspace { \l__examzh_title_subject_sep_skip }
          { \l__examzh_subject_format_tl \l__examzh_subject_tl \par }
        }
    \group_end:
    \par
    \vspace { \l__examzh_title_bottom_sep_skip }
  }



\prg_new_conditional:Npnn \examzh_if_defined:N #1 { T , F , TF }
  {
    \if_meaning:w #1 \@undefined
      \prg_return_false:
    \else:
      \prg_return_true:
    \fi:
  }

% 绝密 启用前
\NewDocumentCommand \secret { O{\bfseries} }
  {
    \par \noindent
    \group_begin:
      #1
      绝密 $\bigstar$ 启用前
    \group_end:
    \par
  }


% 注意事项环境 notice
\keys_define:nn { exam-zh / notice }
  {
    label .tl_set:N = \l__examzh_notice_label_tl,
    label-format .tl_set:N = \l__examzh_notice_label_format_tl,
    top-sep    .skip_set:N = \l__examzh_notice_top_sep_skip,
    bottom-sep .skip_set:N = \l__examzh_notice_bottom_sep_skip,
    
  }
\keys_set:nn { exam-zh / notice }
  {
    label           = 注意事项：,
    label-format    = \sffamily \bfseries,
    top-sep         = .25em plus .25em minus .1em,
    bottom-sep      = .25em plus .25em minus .1em,
  }
\NewDocumentEnvironment { notice } { O { } O { } }
  {
    \keys_set:nn { exam-zh / notice } {#1}
    \par
    \vspace { \l__examzh_notice_top_sep_skip }
    \noindent
    \group_begin:
      \l__examzh_notice_label_format_tl
      \l__examzh_notice_label_tl
    \group_end:
    \begin { enumerate }
      [
        leftmargin = 0pt ,
        itemindent = 3.5em ,
        labelsep   = 0.5em ,
        labelwidth = 1.5em ,
        align      = right ,
        label      = { \arabic * . } ,
        #2
      ]
  }
  {
    \end { enumerate }
    \vspace { \l__examzh_notice_bottom_sep_skip }
  }


% 大题的标题使用 \ctexset 设置 \section 的格式

\ctexset
  {
    section =
      {
        format    = \heiti \bfseries ,
        number    = \chinese { section } ,
        aftername = { 、 } ,
        beforeskip = 2ex plus 1ex minus .5ex,
        afterskip = 1ex plus .2ex minus 1ex
      }
  }



% 兼容 siunitx v2.x 的一些命令
\AtEndOfPackageFile* { siunitx }
  {
    \ProvideDocumentCommand \unit       { } { \si }
    \ProvideDocumentCommand \qty        { } { \SI }
    \ProvideDocumentCommand \qtyproduct { } { \SI }
  }



% 密封线
\str_new:N \g__examzh_sealline_odd_type_str
\str_new:N \g__examzh_sealline_even_type_str

\keys_define:nn { exam-zh / sealline }
  {
    % 是否显示密封线
    show .bool_gset:N = \g__examzh_sealline_show_bool,
    % 密封线类型（也理解为出现的类型，比如只在第一页，只在奇数页）
    scope .choices:nn =
      { firstpage, oddpage, everypage, first-and-last, mod-2, mod-3, mod-4, mod-6 }
      { \str_gset:Nx \g__examzh_sealline_scope_str { \l_keys_choice_tl } },
    type .choices:nn =
      { firstpage, oddpage, everypage, first-and-last, mod-2, mod-3, mod-4, mod-6 }
      { \str_gset:Nx \g__examzh_sealline_scope_str { \l_keys_choice_tl } },
    % 线的厚度
    odd-line-thickness .dim_set:N = \g__examzh_sealline_odd_line_thickness_dim,
    even-line-thickness .dim_set:N = \g__examzh_sealline_even_line_thickness_dim,
    line-thickness .code:n =
      {
        \dim_set:Nn \g__examzh_sealline_odd_line_thickness_dim {#1}
        \dim_set:Nn \g__examzh_sealline_even_line_thickness_dim {#1}
      },
    % 线的偏移
    odd-line-xshift .dim_set:N = \g__examzh_sealline_odd_line_xshift_dim,
    odd-line-yshift .dim_set:N = \g__examzh_sealline_odd_line_yshift_dim,
    even-line-xshift .dim_set:N = \g__examzh_sealline_even_line_xshift_dim,
    even-line-yshift .dim_set:N = \g__examzh_sealline_even_line_yshift_dim,
    line-xshift .code:n =
      {
        \dim_gset:Nn \g__examzh_sealline_odd_line_xshift_dim {#1}
        \dim_gset:Nn \g__examzh_sealline_even_line_xshift_dim {#1}
      },
    line-yshift .code:n =
      {
        \dim_set:Nn \g__examzh_sealline_odd_line_yshift_dim {#1}
        \dim_set:Nn \g__examzh_sealline_even_line_yshift_dim {#1}
      },
    % 密封线的线类型
    % odd-line-type .str_set:N = \g__examzh_sealline_odd_type_str,
    % even-line-type .str_set:N = \g__examzh_sealline_even_type_str,
    odd-line-type .code:n =
      {
        \str_set:Nn \g__examzh_sealline_odd_type_str {#1}
      },
    even-line-type .code:n =
      {
        \str_set:Nn \g__examzh_sealline_even_type_str {#1}
      },
    line-type .code:n = 
      {
        \str_gset:Nn \g__examzh_sealline_odd_type_str {#1}
        \str_gset:Nn \g__examzh_sealline_even_type_str {#1}
      },
    % 密封线路径的文字内容
    odd-text .tl_set:N = \g__examzh_sealline_odd_text_tl,
    even-text .tl_set:N = \g__examzh_sealline_even_text_tl,
    text .code:n = 
      {
        \tl_gset:Nn \g__examzh_sealline_odd_text_tl {#1}
        \tl_gset:Nn \g__examzh_sealline_even_text_tl {#1}
      },
    % 密封线路径的文字内容偏移
    odd-text-xshift .dim_set:N = \g__examzh_sealline_odd_text_xshift_dim,
    even-text-xshift .dim_set:N = \g__examzh_sealline_even_text_xshift_dim,
    odd-text-yshift .dim_set:N = \g__examzh_sealline_odd_text_yshift_dim,
    even-text-yshift .dim_set:N = \g__examzh_sealline_even_text_yshift_dim,
    text-xshift .code:n = 
      {
        \dim_gset:Nn \g__examzh_sealline_odd_text_xshift_dim {#1}
        \dim_gset:Nn \g__examzh_sealline_even_text_xshift_dim {#1}
      },
    text-yshift .code:n = 
      {
        \dim_gset:Nn \g__examzh_sealline_odd_text_yshift_dim {#1}
        \dim_gset:Nn \g__examzh_sealline_even_text_yshift_dim {#1}
      },
    % 密封线路径文字的宽度
    odd-text-width .dim_set:N = \g__examzh_sealline_odd_text_width_dim,
    even-text-width .dim_set:N = \g__examzh_sealline_even_text_width_dim,
    text-width .code:n = 
      {
        \dim_gset:Nn \g__examzh_sealline_odd_text_width_dim {#1}
        \dim_gset:Nn \g__examzh_sealline_even_text_width_dim {#1}
      },
    % 密封线路径文字的字体
    odd-text-format .tl_set:N = \g__examzh_sealline_odd_text_format_tl,
    even-text-format .tl_set:N = \g__examzh_sealline_even_text_format_tl,
    text-format .code:n = 
      {
        \tl_gset:Nn \g__examzh_sealline_odd_text_format_tl {#1}
        \tl_gset:Nn \g__examzh_sealline_even_text_format_tl {#1}
      },
    % 密封线路径文字的方向
    odd-text-direction-vertical .bool_gset:N = \g__examzh_sealline_odd_text_direction_vertical_bool,
    even-text-direction-vertical .bool_gset:N = \g__examzh_sealline_even_text_direction_vertical_bool,
    text-direction-vertical .choice:, 
    text-direction-vertical / true .code:n = 
      {
        \bool_gset_true:N \g__examzh_sealline_odd_text_direction_vertical_bool
        \bool_gset_true:N \g__examzh_sealline_even_text_direction_vertical_bool
      },
    text-direction-vertical / false .code:n =
      {
        \bool_gset_false:N \g__examzh_sealline_odd_text_direction_vertical_bool
        \bool_gset_false:N \g__examzh_sealline_even_text_direction_vertical_bool
      },
    % 密封线路径文字的防缩比例
    odd-text-xscale .fp_set:N = \g__examzh_sealline_odd_text_xscale_fp,
    odd-text-yscale .fp_set:N = \g__examzh_sealline_odd_text_yscale_fp,
    even-text-xscale .fp_set:N = \g__examzh_sealline_even_text_xscale_fp,
    even-text-yscale .fp_set:N = \g__examzh_sealline_even_text_yscale_fp,
    text-xscale .code:n = 
      {
        \fp_gset:Nn \g__examzh_sealline_odd_text_xscale_fp {#1}
        \fp_gset:Nn \g__examzh_sealline_even_text_xscale_fp {#1}
      },
    text-yscale .code:n = 
      {
        \fp_gset:Nn \g__examzh_sealline_odd_text_yscale_fp {#1}
        \fp_gset:Nn \g__examzh_sealline_even_text_yscale_fp {#1}
      },
    % 密封线上圆圈的参数
    % --控制显示--
    odd-circle-show .bool_set:N = \g__examzh_sealline_odd_circle_show_bool,
    even-circle-show .bool_set:N = \g__examzh_sealline_even_circle_show_bool,
    circle-show .choice:,
    circle-show / true .code:n =
      {
        \bool_gset_true:N \g__examzh_sealline_odd_circle_show_bool
        \bool_gset_true:N \g__examzh_sealline_even_circle_show_bool
      },
    circle-show / false .code:n =
      {
        \bool_gset_false:N \g__examzh_sealline_odd_circle_show_bool
        \bool_gset_false:N \g__examzh_sealline_even_circle_show_bool
      },
    % --开始--
    odd-circle-start .fp_set:N = \g__examzh_sealline_odd_circle_start_fp,
    even-circle-start .fp_set:N = \g__examzh_sealline_even_circle_start_fp,
    circle-start .code:n = 
      {
        \fp_gset:Nn \g__examzh_sealline_odd_circle_start_fp {#1}
        \fp_gset:Nn \g__examzh_sealline_even_circle_start_fp {#1}
      },
    % --结束--
    odd-circle-end .fp_set:N = \g__examzh_sealline_odd_circle_end_fp,
    even-circle-end .fp_set:N = \g__examzh_sealline_even_circle_end_fp,
    circle-end .code:n = 
      {
        \fp_gset:Nn \g__examzh_sealline_odd_circle_end_fp {#1}
        \fp_gset:Nn \g__examzh_sealline_even_circle_end_fp {#1}
      },
    % --步长--
    odd-circle-step .dim_set:N = \g__examzh_sealline_odd_circle_step_dim,
    even-circle-step .dim_set:N = \g__examzh_sealline_even_circle_step_dim,
    circle-step .code:n = 
      {
        \dim_gset:Nn \g__examzh_sealline_odd_circle_step_dim {#1}
        \dim_gset:Nn \g__examzh_sealline_even_circle_step_dim {#1}
      },
    % --直径--
    odd-circle-diameter .dim_set:N = \g__examzh_sealline_odd_circle_diameter_dim,
    even-circle-diameter .dim_set:N = \g__examzh_sealline_even_circle_diameter_dim,
    circle-diameter .code:n = 
      {
        \dim_gset:Nn \g__examzh_sealline_odd_circle_diameter_dim {#1}
        \dim_gset:Nn \g__examzh_sealline_even_circle_diameter_dim {#1}
      },
    % --偏移--
    odd-circle-xshift .dim_set:N = \g__examzh_sealline_odd_circle_xshift_dim,
    even-circle-xshift .dim_set:N = \g__examzh_sealline_even_circle_xshift_dim,
    circle-xshift .code:n = 
      {
        \dim_gset:Nn \g__examzh_sealline_odd_circle_xshift_dim {#1}
        \dim_gset:Nn \g__examzh_sealline_even_circle_xshift_dim {#1}
      },
    % 学生信息
    % --内容--
    odd-info-content .clist_set:N = \g__examzh_sealline_odd_info_content_clist,
    % --分隔符--
    odd-info-seperator .tl_set:N = \g__examzh_sealline_odd_info_seperator_tl,
    % --对齐--
    odd-info-align .tl_set:N = \g__examzh_sealline_odd_info_align_tl,
    % --偏移--
    odd-info-xshift .dim_set:N = \g__examzh_sealline_odd_info_xshift_dim,
    odd-info-yshift .dim_set:N = \g__examzh_sealline_odd_info_yshift_dim,
  }
\keys_set:nn { exam-zh / sealline }
  {
    show        = false,
    % scope      = firstpage,
    % scope      = oddpage,
    scope        = everypage,
    line-thickness          = 1pt,
    line-xshift             = 8mm,
    line-yshift             = 0mm,
    line-type               = loosely-dashed,
    text                    = 密封线内不得答题,
    text-xshift             = 11mm,
    text-yshift             = 0pt,
    text-width              = 0.8\textheight,
    text-format             = \zihao{4}\sffamily\color{black},
    text-xscale             = 1.0,
    text-yscale             = 0.8,
    text-direction-vertical = false,
    circle-show             = true,
    circle-start            = 0.07,
    circle-end              = 0.92,
    circle-step             = 3.5em,
    circle-diameter         = 3mm,
    circle-xshift           = 8mm,
    odd-info-content        = {
      {\kaishu 姓名}：{\underline{\hspace*{8em}}},
      {\kaishu 准考证号}：{\underline{\hspace*{8em}}},
      {\kaishu 考场号}：{\underline{\hspace*{8em}}},
      {\kaishu 座位号}：{\underline{\hspace*{8em}}}
    },
    odd-info-seperator   = \hspace*{3em},
    odd-info-align       = center,
    odd-info-xshift      = 20mm,
    odd-info-yshift      = 0mm
  }
\keys_define:nn { exam-zh }
  { sealline .meta:nn = { exam-zh / sealline } {#1} }

% 只在第一页出现
\cs_new:Npn \__examzh_sealline_scope_firstpage:
  {
    \AddToHook { shipout / firstpage } [ sealline ]
      {
        \put (0cm, 0cm)
          { \color{black} \__examzh_sealline_odd: }
      }
  }
% 只在第一页和最后一页出现
\cs_new:Npn \__examzh_sealline_scope_firstpage_and_lastpage:
  {
    \AddToHook { shipout / firstpage } [ sealline ]
      {
        \put (0cm, 0cm)
          { \color{black} \__examzh_sealline_odd: }
      }
    \AddToHook { shipout / lastpage } [ sealline ]
      {
        \put (0cm, 0cm)
          {
            \color{black} 
            \int_if_odd:nTF { \c@page }
              { \__examzh_sealline_odd: }
              { \__examzh_sealline_even: }
          }
      }
  }
% 只在奇数页出现
\cs_new:Npn \__examzh_sealline_scope_oddpage:
  {
    \AddToHook { shipout / background } [ sealline ]
      {
        \put (0cm, 0cm)
          {
            \color{black} 
            \int_if_odd:nT { \c@page }
              { \__examzh_sealline_odd: }
          }
      }
  }
% 每页都有，奇偶不同
\cs_new:Npn \__examzh_sealline_scope_everypage:
  {
    \AddToHook { shipout / background } [ sealline ]
      {
        \put (0cm, 0cm)
          {
            \color{black} 
            \int_if_odd:nTF { \c@page }
              { \__examzh_sealline_odd: }
              { \__examzh_sealline_even: }
          }
      }
  }
% mod 2 = 1 的类型
\cs_new:cpn { __examzh_sealline_scope_mod_2_equals_1: }
  {
    \AddToHook { shipout / background } [ sealline ]
      {
        \put (0cm, 0cm)
          {
            \color{black} 
            \int_compare:nNnT { \int_mod:nn { \c@page } { 2 } } = {1} { \__examzh_sealline_odd: }
          }
      }
  }
% mod 3 = 1 的类型
\cs_new:cpn { __examzh_sealline_scope_mod_3_equals_1: }
  {
    \AddToHook { shipout / background } [ sealline ]
      {
        \put (0cm, 0cm)
          {
            \color{black} 
            \int_compare:nNnT { \int_mod:nn { \c@page } { 3 } } = {1} { \__examzh_sealline_odd: }
          }
      }
  }
% mod 4 = 1 的类型
\cs_new:cpn { __examzh_sealline_scope_mod_4_equals_1: }
  {
    \AddToHook { shipout / background } [ sealline ]
      {
        \put (0cm, 0cm)
          {
            \color{black} 
            \int_compare:nNnT { \int_mod:nn { \c@page } { 4 } } = {1} { \__examzh_sealline_odd: }
          }
      }
  }
% mod 6 = 1 的类型
\cs_new:cpn { __examzh_sealline_scope_mod_6_equals_1: }
  {
    \AddToHook { shipout / background } [ sealline ]
      {
        \put (0cm, 0cm)
          {
            \color{black} 
            \int_compare:nNnT { \int_mod:nn { \c@page } { 6 } } = {1} { \__examzh_sealline_odd: }
          }
      }
  }

% https://github.com/CTeX-org/ctex-kit/issues/632#issuecomment-1199675064
\AddToHook{shipout/before}{\xeCJKShipoutHook}

\AtBeginDocument
  { \__examzh_sealline_set: }
\cs_new:Npn \__examzh_sealline_set:
  {
    \bool_if:NT \g__examzh_sealline_show_bool
      {
        \__examzh_sealline_scope_set:
        \str_case:Vn \g__examzh_sealline_scope_str
          {
            { firstpage } { \__examzh_sealline_scope_firstpage: }
            { oddpage   } { \__examzh_sealline_scope_oddpage:   }
            { everypage } { \__examzh_sealline_scope_everypage: }
            { first-and-last } { \__examzh_sealline_scope_firstpage_and_lastpage: }
            { mod-2 } { \use:c { __examzh_sealline_scope_mod_2_equals_1: } }
            { mod-3 } { \use:c { __examzh_sealline_scope_mod_3_equals_1: } }
            { mod-4 } { \use:c { __examzh_sealline_scope_mod_4_equals_1: } }
            { mod-6 } { \use:c { __examzh_sealline_scope_mod_6_equals_1: } }
          }
      }
  }
\cs_new:Npn \__examzh_sealline_scope_set:
  {
    \tl_gset:Nx \g__examzh_sealline_odd_type_parameter_tl
      {
        \str_case:Vn \g__examzh_sealline_odd_type_str
          {
            { solid }  { solid }
            { dotted } { dotted }
            { densely-dotted } { densely~dotted }
            { loosely-dotted } { loosely~dotted }
            { dashed } { dashed }
            { densely-dashed } { densely~dashed }
            { loosely-dashed } { loosely~dashed }
            { dash-dot } { dash~dot }
            { densely-dash-dot } { densely~dash~dot }
            { loosely-dash-dot } { loosely~dash~dot }
            { dash-dot-dot } { dash~dot~dot }
            { densely-dash-dot-dot } { densely~dash~dot~dot }
            { loosely-dash-dot-dot } { loosely~dash~dot~dot }
          }
      }
    \tl_gset:Nx \g__examzh_sealline_even_type_parameter_tl
      {
        \str_case:Vn \g__examzh_sealline_even_type_str
          {
            { solid }  { solid }
            { dotted } { dotted }
            { densely-dotted } { densely~dotted }
            { loosely-dotted } { loosely~dotted }
            { dashed } { dashed }
            { densely-dashed } { densely~dashed }
            { loosely-dashed } { loosely~dashed }
            { dash-dot } { dash~dot }
            { densely-dash-dot } { densely~dash~dot }
            { loosely-dash-dot } { loosely~dash~dot }
            { dash-dot-dot } { dash~dot~dot }
            { densely-dash-dot-dot } { densely~dash~dot~dot }
            { loosely-dash-dot-dot } { loosely~dash~dot~dot }
          }
      }
  }

\keys_define:nn { exam-zh / page }
  {
    show-columnline .bool_set:N = \l__examzh_show_columnline_bool,
    columnline-width .dim_set:N = \l__examzh_columnline_dim,
  }
\keys_set:nn { exam-zh / page }
  {
    show-columnline  = false,
    columnline-width = 0.4pt
  }

\AtEndPreamble
  {
    \bool_if:NTF \g__examzh_page_size_custom_bool
      {
        \dim_compare:nNnTF { \g__examzh_page_paper_width_dim } > { 0pt }
          {
            \dim_compare:nNnTF { \g__examzh_page_paper_height_dim } > { 0pt }
              {
                % 自定义纸张始终是单页模式；不继承 a3paper 的横向双页拼版设置。
                \geometry
                  {
                    paperwidth  = \g__examzh_page_paper_width_dim,
                    paperheight = \g__examzh_page_paper_height_dim,
                    margin      = \g__examzh_page_margin_dim,
                    headheight  = \g__examzh_page_headheight_dim
                  }
              }
              { \msg_error:nn { exam-zh } { custom-paper-height-required } }
          }
          { \msg_error:nn { exam-zh } { custom-paper-width-required } }
      }
      {
    \bool_if:cTF { g__examzh_page_size_a4paper_bool }
      {
        % a4paper
        \bool_if:NTF \g__examzh_sealline_show_bool
          {
            % 有密封线
            \geometry
              {
                twoside,
                paper  = a4paper,
                margin = 1in,
                inner  = 1.3in,
                outer  = 0.8in,
                headheight  = 0.7in
              }
          }
          {
            % 无密封线
            \geometry
              {
                paper  = a4paper,
                margin = 1in,
                headheight  = 0.7in
              }
          }
      }
      {
        % a3paper
        \bool_if:NT \l__examzh_show_columnline_bool
          { \dim_set:Nn \columnseprule { \l__examzh_columnline_dim } }
        \bool_if:NTF \g__examzh_sealline_show_bool
          {
            % 有密封线
            \geometry
              {
                twoside,
                paper      = a3paper,
                landscape,
                twocolumn,
                columnsep  = 30mm,
                margin     = 1in,
                inner      = 1.2in,
                outer      = 0.8in,
                headheight  = 0.7in
                % showframe
              }
          }
          {
            % 无密封线
            \geometry
              {
                paper      = a3paper,
                landscape,
                twocolumn,
                columnsep  = 30mm,
                margin     = 1in,
                headheight  = 0.7in
              }
          }
      }
      }
  }


\cs_new:Npn \__examzh_sealline_odd:
  {
    \begin{tikzpicture}
      [
        remember~picture,
        overlay
      ]
      % 密封线：线
      \__examzh_sealline_odd_line:
      % 密封线：小圆圈
      \__examzh_sealline_odd_circle:
      % 线上的文字
      \__examzh_sealline_odd_text_around_line:
      % 学生信息
      \__examzh_sealline_odd_infomation:
    \end{tikzpicture}
  }

\cs_new:Npn \__examzh_sealline_even:
  {
    \begin{tikzpicture}[remember~picture, overlay]
      % 密封线：线
      \__examzh_sealline_even_line:
      % 密封线：小圆圈
      \__examzh_sealline_even_circle:
      % 线上的文字
      \__examzh_sealline_even_text_around_line:
    \end{tikzpicture}
  }

% 线
\cs_new:Npn \__examzh_sealline_odd_line:
  {
    \use:x
      {
        \exp_not:N \draw
          [
            \g__examzh_sealline_odd_type_parameter_tl,
            line~width   = \dim_use:N \g__examzh_sealline_odd_line_thickness_dim
          ]
      }
      ([xshift = -\g__examzh_sealline_odd_line_xshift_dim, yshift = -\g__examzh_sealline_odd_line_yshift_dim]current~page~text~area.north~west)
        --
      ([xshift = -\g__examzh_sealline_odd_line_xshift_dim, yshift = \g__examzh_sealline_odd_line_yshift_dim]current~page~text~area.south~west);
  }
\cs_new:Npn \__examzh_sealline_even_line:
  {
    \use:x
      {
        \exp_not:N \draw
          [
            \g__examzh_sealline_even_type_parameter_tl,
            line~width    = \dim_use:N \g__examzh_sealline_even_line_thickness_dim
          ] 
      }
      ([xshift = \g__examzh_sealline_even_line_xshift_dim, yshift = -\g__examzh_sealline_even_line_yshift_dim]current~page~text~area.north~east)
        --
      ([xshift = \g__examzh_sealline_even_line_xshift_dim, yshift = \g__examzh_sealline_even_line_yshift_dim]current~page~text~area.south~east);
  }

% 小圆圈
\cs_new:Npn \__examzh_sealline_odd_circle:
  {
    \bool_if:NT \g__examzh_sealline_odd_circle_show_bool
      {
        \use:x
          {
            \exp_not:N
            \fill
              [
                decorate,
                decoration =
                  {
                    markings,
                    mark = 
                    between~positions~
                    \fp_use:N \g__examzh_sealline_odd_circle_start_fp
                    ~and~
                    \fp_use:N \g__examzh_sealline_odd_circle_end_fp
                    ~step~
                    \dim_use:N \g__examzh_sealline_odd_circle_step_dim
                    ~with
                      {
                        \exp_not:N
                        \node 
                          [
                            circle,
                            draw         = black, 
                            fill         = white,
                            minimum~size = \dim_use:N \g__examzh_sealline_odd_circle_diameter_dim
                          ]
                          {};
                      }
                  }
              ]
          }
        ([xshift = -\g__examzh_sealline_odd_circle_xshift_dim]current~page~text~area.north~west)
          --
        ([xshift = -\g__examzh_sealline_odd_circle_xshift_dim]current~page~text~area.south~west);
      }
  }
\cs_new:Npn \__examzh_sealline_even_circle:
  {
    \bool_if:NT \g__examzh_sealline_even_circle_show_bool
      {
        \use:x
          {
            \exp_not:N
            \fill
              [
                decorate,
                decoration =
                  {
                    markings,
                    mark = 
                    between~positions~
                    \fp_use:N \g__examzh_sealline_even_circle_start_fp
                    ~and~
                    \fp_use:N \g__examzh_sealline_even_circle_end_fp
                    ~step~
                    \dim_use:N \g__examzh_sealline_even_circle_step_dim
                    ~with
                      {
                        \exp_not:N
                        \node 
                          [
                            circle,
                            draw         = black, 
                            fill         = white,
                            minimum~size = \dim_use:N \g__examzh_sealline_even_circle_diameter_dim
                          ]
                          {};
                      }
                  }
              ]
          }
        ([xshift = \g__examzh_sealline_even_circle_xshift_dim]current~page~text~area.north~east)
          --
        ([xshift = \g__examzh_sealline_even_circle_xshift_dim]current~page~text~area.south~east);
      }
  }
% 线上的文字（密封线外不得答题）
\cs_new_protected:Npn \__examzh_sealline_odd_spread_box:nn #1#2
  {
    \mode_leave_vertical:
    \bool_if:NTF \g__examzh_sealline_odd_text_direction_vertical_bool
      {
        \hbox_set_to_wd:Nnn \l_tmpa_box {#1}
          {
            \tl_set:Nx \l_tmpa_tl {#2}
            \tl_reverse:N \l_tmpa_tl
            \tl_map_inline:xn { \l_tmpa_tl }
              {
                \hbox_set:Nn \l_tmpb_box {##1}
                \box_rotate:Nn \l_tmpb_box { -90 }
                \box_use_drop:N \l_tmpb_box
                \hfil 
              }
            \unskip
          }
      }
      {
        \hbox_set_to_wd:Nnn \l_tmpa_box {#1}
          {
            \tl_map_inline:xn {#2} { ##1 \hfil } \unskip
          }
      }
    \box_scale:Nnn \l_tmpa_box
      { \fp_use:N \g__examzh_sealline_odd_text_xscale_fp }
      { \fp_use:N \g__examzh_sealline_odd_text_yscale_fp }
    \box_rotate:Nn \l_tmpa_box { 90 }
    \box_move_down:nn 
      { #1 / 2 }
      { \box_use_drop:N \l_tmpa_box }
  }
\cs_new_protected:Npn \__examzh_sealline_even_spread_box:nn #1#2
  {
    \mode_leave_vertical:
    \bool_if:NTF \g__examzh_sealline_odd_text_direction_vertical_bool
      {
        \hbox_set_to_wd:Nnn \l_tmpa_box {#1}
          {
            \tl_map_inline:xn {#2}
              {
                \hbox_set:Nn \l_tmpb_box {##1}
                \box_rotate:Nn \l_tmpb_box { 90 }
                \box_use_drop:N \l_tmpb_box
                \hfil 
              }
            \unskip
          }
      }
      {
        \hbox_set_to_wd:Nnn \l_tmpa_box {#1}
          {
            \tl_map_inline:xn {#2} { ##1 \hfil } \unskip
          }
      }
    \box_scale:Nnn \l_tmpa_box
      { \fp_use:N \g__examzh_sealline_odd_text_xscale_fp }
      { \fp_use:N \g__examzh_sealline_odd_text_yscale_fp }
    \box_rotate:Nn \l_tmpa_box { -90 }
    \box_move_up:nn 
      { #1 / 2 }
      { \box_use_drop:N \l_tmpa_box }
  }
\cs_new:Npn \__examzh_sealline_odd_text_around_line:
  {
    \node [ anchor = east ]
      at ([xshift = -\g__examzh_sealline_odd_text_xshift_dim, yshift = \g__examzh_sealline_odd_text_yshift_dim]current~page~text~area.west)
      {
        \g__examzh_sealline_odd_text_format_tl
        \__examzh_sealline_odd_spread_box:nn { \g__examzh_sealline_odd_text_width_dim }
          { \g__examzh_sealline_odd_text_tl }
      };
  }
\cs_new:Npn \__examzh_sealline_even_text_around_line:
  {
    \bool_if:NTF \g__examzh_sealline_odd_text_direction_vertical_bool
      {
        \dim_set_eq:NN \l_tmpa_dim \g__examzh_sealline_even_text_yshift_dim
      }
      {
        \dim_set:Nn \l_tmpa_dim { - \g__examzh_sealline_even_text_yshift_dim }
      }
    \dim_set_eq:NN \g__examzh_sealline_even_text_yshift_dim \l_tmpa_dim
    \node [ anchor = west ]
      at ([xshift = \g__examzh_sealline_even_text_xshift_dim, yshift = \g__examzh_sealline_even_text_yshift_dim]current~page~text~area.east)
      {
        \g__examzh_sealline_even_text_format_tl
        \__examzh_sealline_even_spread_box:nn { \g__examzh_sealline_even_text_width_dim }
          { \g__examzh_sealline_even_text_tl }
      };
  }
% 学生信息
\cs_new:Npn \__examzh_sealline_odd_infomation:
  {
    \use:x 
      {
        \exp_not:N
        \path
          [
            decorate,
            decoration =
              {
                text~along~path,
                text~align = \g__examzh_sealline_odd_info_align_tl,
                reverse~path,
                text = {
                  \clist_use:Nn \g__examzh_sealline_odd_info_content_clist 
                    { { \g__examzh_sealline_odd_info_seperator_tl } }
                }
              }
          ]
      }
      ([xshift = -\g__examzh_sealline_odd_info_xshift_dim, yshift = 0mm]current~page~text~area.north~west)
        --
      ([xshift = -\g__examzh_sealline_odd_info_xshift_dim, yshift = \g__examzh_sealline_odd_info_yshift_dim]current~page~text~area.south~west);
  }

% 信息的方格
\keys_define:nn { exam-zh / square }
  {
    x-length .dim_set:N = \l__examzh_information_square_x_dim,
    y-length .dim_set:N = \l__examzh_information_square_y_dim,
    baseline .dim_set:N = \l__examzh_information_square_baseline_dim,
    linewidth .dim_set:N = \l__examzh_information_square_linewidth_dim,
    xshift .dim_set:N = \l__examzh_information_square_xshift_dim
  }
\keys_set:nn { exam-zh / square }
  {
    x-length  = 1.4em,
    y-length  = 1.2em,
    baseline  = 3pt,
    linewidth = 0.4pt,
  }
\keys_define:nn { exam-zh }
  { square .meta:nn = { exam-zh / square } {#1} }
\cs_new:Npn \__examzh_information_square_single:
  {
    \begin{tikzpicture}[baseline = \l__examzh_information_square_baseline_dim]
      \draw[line~width = \l__examzh_information_square_linewidth_dim] (0,0) rectangle 
        ( \l__examzh_information_square_x_dim , \l__examzh_information_square_y_dim);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_information_square_multiple:n #1
  {
    \dim_compare:nNnT { \l__examzh_information_square_xshift_dim } = { 0pt }
      {
        \dim_set_eq:NN 
          \l__examzh_information_square_xshift_dim
          \l__examzh_information_square_linewidth_dim
      }
    \int_compare:nNnTF { #1 } = { 1 }
      { \__examzh_information_square_single: }
      {
        \__examzh_information_square_single:
        \prg_replicate:nn { #1 - 1 }
          {
            \hspace*{ -\l__examzh_information_square_xshift_dim }
            \__examzh_information_square_single:
          }
      }
  }

\NewDocumentCommand { \examsquare } { O{ } m }
  {
    \group_begin:
      \keys_set:nn { exam-zh / square } { #1 }
      \__examzh_information_square_multiple:n { #2 }
    \group_end:
  }


% 页眉和页脚


\keys_define:nn { exam-zh / page }
  {
    show-head .bool_set:N = \l__examzh_show_head_bool,
    show-foot .bool_set:N = \l__examzh_show_foot_bool,
    head-content .tl_set:N = \l__examzh_head_content_tl,
    foot-content .tl_set:N = \l__examzh_foot_content_format_tl
      % foo, bar: foo <page> bar
      % foo, bar, baz: foo <page> bar <lastpage> baz
  }
\keys_set:nn { exam-zh / page }
  {
    show-head    = false,
    show-foot    = true,
    foot-content = {数学试题第;页（共~;页）}
  }

\int_new:N \l__examzh_foot_content_count_semicolon_int
\tl_new:N \l__examzh_foot_content_before_page_tl
\tl_new:N \l__examzh_foot_content_after_page_tl
\tl_new:N \l__examzh_foot_content_after_lastpage_tl
\cs_generate_variant:Nn \regex_count:nnN { nxN, noN }

\cs_new:Npn \__examzh_foot_content_only_page_input:ww #1 ; #2 \q_stop
  {
    \tl_set:Nn \l__examzh_foot_content_before_page_tl {#1}
    \tl_set:Nn \l__examzh_foot_content_after_page_tl {#2}
  }
\cs_new:Npn \__examzh_foot_content_only_page_input:n #1
  {
    \__examzh_foot_content_only_page_input:ww #1 \q_stop
  }
\cs_generate_variant:Nn \__examzh_foot_content_only_page_input:n { V }

\cs_new:Npn \__examzh_foot_content_page_and_lastpage_input:www #1 ; #2 ; #3 \q_stop
  {
    \tl_set:Nn \l__examzh_foot_content_before_page_tl {#1}
    \tl_set:Nn \l__examzh_foot_content_after_page_tl {#2}
    \tl_set:Nn \l__examzh_foot_content_after_lastpage_tl {#3}
  }
\cs_new:Npn \__examzh_foot_content_page_and_lastpage_input:n #1
  {
    \__examzh_foot_content_page_and_lastpage_input:www #1 \q_stop
  }
\cs_generate_variant:Nn \__examzh_foot_content_page_and_lastpage_input:n { V }

\cs_new:Npn \__examzh_foot_content_no_page_or_lastpage_output:
  {
    \l__examzh_foot_content_format_tl
  }
\cs_new:Npn \__examzh_foot_content_only_page_output:
  {
    \l__examzh_foot_content_before_page_tl \thepage { }
    \l__examzh_foot_content_after_page_tl
  }
\cs_new:cpn { __examzh_foot_content_only_page_a3paper_left_output: }
  {
    \l__examzh_foot_content_before_page_tl \int_eval:n { 2 * \c@page - 1 } { }
    \l__examzh_foot_content_after_page_tl
  }
\cs_new:cpn { __examzh_foot_content_only_page_a3paper_right_output: }
  {
    \l__examzh_foot_content_before_page_tl \int_eval:n { 2 * \c@page } { }
    \l__examzh_foot_content_after_page_tl
  }
% \tl_new:N \g_examzh_solution_move_separately_lastpage_tl
\cs_new:Npn \__examzh_foot_content_page_and_lastpage_output:
  {
    \l__examzh_foot_content_before_page_tl \thepage { }
    \l__examzh_foot_content_after_page_tl  \unskip \c_space_tl 
    \pageref { LastPage }~
    % \tl_if_blank:VTF \g_examzh_solution_move_separately_lastpage_tl
    %   { \pageref { LastPage } }
    %   { \g_examzh_solution_move_separately_lastpage_tl }
      ~
    \l__examzh_foot_content_after_lastpage_tl
  }
\cs_new:cpn { __examzh_foot_content_page_and_lastpage_a3paper_left_output: }
  {
    \__examzh_foot_lastpage_tmp_set:
    \l__examzh_foot_content_before_page_tl \int_eval:n { 2 * \c@page - 1 } { }
    \l__examzh_foot_content_after_page_tl  ~
    \int_eval:n { 2 *  \l__examzh_tmp_int }
    % \tl_if_blank:VTF \g_examzh_solution_move_separately_lastpage_tl
    %   { \int_eval:n { 2 * \l__examzh_tmp_int } }
    %   { \int_eval:n { 2 *  \g_examzh_solution_move_separately_lastpage_tl } }
      ~
    \l__examzh_foot_content_after_lastpage_tl
  }
\cs_new:cpn { __examzh_foot_content_page_and_lastpage_a3paper_right_output: }
  {
    \__examzh_foot_lastpage_tmp_set:
    \l__examzh_foot_content_before_page_tl \int_eval:n { 2 * \c@page } { }
    \l__examzh_foot_content_after_page_tl  ~
    \int_eval:n { 2 * \l__examzh_tmp_int }
    % \tl_if_blank:VTF \g_examzh_solution_move_separately_lastpage_tl
    %   { \int_eval:n { 2 * \l__examzh_tmp_int } }
    %   { \int_eval:n { 2 *  \g_examzh_solution_move_separately_lastpage_tl } }
      ~
    \l__examzh_foot_content_after_lastpage_tl
  }
\cs_new_nopar:Npn \__examzh_relax: { \relax }
% \cs_new:Npn \__examzh_foot_lastpage_tmp_set:
%   {
%     \cs_if_eq:NNTF \lastpage@lastpage \__examzh_relax:
%       { \int_set:Nn \l__examzh_tmp_int { 0 } }
%       { \int_set:Nn \l__examzh_tmp_int { \lastpage@lastpage } }
%   }

% https://gitee.com/xkwxdyy/exam-zh/issues/I6B7MU#note_17945353_link
\cs_new:Npn \__examzh_foot_lastpage_tmp_set:
  {
    \bool_lazy_or:nnTF 
      { \cs_if_eq_p:NN \lastpage@lastpage \__examzh_relax: }
      { \str_if_eq_p:ee \lastpage@lastpage {??} }
      { \int_set:Nn \l__examzh_tmp_int { 0 } }
      { \int_set:Nn \l__examzh_tmp_int { \lastpage@lastpage } }
  }
\msg_new:nnn { exam-zh } { foot-semicolon-number-error }
  {
    The~number~of~semicolon~of~foot-line~must~be~1,~2~or~3!
  }
\cs_new:cpn { __examzh_foot_content_a4paper_output: }
  {
    % 检测输入有多少个 ;
    % \regex_count:nxN { ; }
    % https://gitee.com/xkwxdyy/exam-zh/issues/I5NNR8#note_13447684_link
    \regex_count:noN { ; } 
      { \l__examzh_foot_content_format_tl }
      \l__examzh_foot_content_count_semicolon_int
    \int_case:nnF { \l__examzh_foot_content_count_semicolon_int }
      {
        {0} { \__examzh_foot_content_no_page_or_lastpage_output: }
        {1}
          { 
            % 将输入“分解”
            \__examzh_foot_content_only_page_input:V \l__examzh_foot_content_format_tl
            % 然后输出
            \__examzh_foot_content_only_page_output:
          }
        {2}
          {
            % 将输入“分解”
            \__examzh_foot_content_page_and_lastpage_input:V \l__examzh_foot_content_format_tl
            % 然后输出
            \__examzh_foot_content_page_and_lastpage_output:
          }
      }
      {
        \msg_error:nn { exam-zh } { foot-semicolon-number-error }
      }
  }
\cs_set_eq:cc
  { __examzh_foot_content_a3paper_common_output: }
  { __examzh_foot_content_a4paper_output: }
\cs_new:cpn { __examzh_foot_content_a3paper_separate_left_output: }
  {
    % 检测输入有多少个 ;
    \regex_count:nxN { ; } 
      { \l__examzh_foot_content_format_tl }
      \l__examzh_foot_content_count_semicolon_int
    \int_case:nnF { \l__examzh_foot_content_count_semicolon_int }
      {
        {0} { \__examzh_foot_content_no_page_or_lastpage_output: }
        {1}
          { 
            % 将输入“分解”
            \__examzh_foot_content_only_page_input:V \l__examzh_foot_content_format_tl
            % 然后输出
            \use:c { __examzh_foot_content_only_page_a3paper_left_output: }
          }
        {2}
          {
            % 将输入“分解”
            \__examzh_foot_content_page_and_lastpage_input:V \l__examzh_foot_content_format_tl
            % 然后输出
            \use:c { __examzh_foot_content_page_and_lastpage_a3paper_left_output: }
          }
      }
      {
        \msg_error:nn { exam-zh } { foot-semicolon-number-error }
      }
  }
\cs_new:cpn { __examzh_foot_content_a3paper_separate_right_output: }
  {
    % 检测输入有多少个 ;
    \regex_count:nxN { ; } 
      { \l__examzh_foot_content_format_tl }
      \l__examzh_foot_content_count_semicolon_int
    \int_case:nnF { \l__examzh_foot_content_count_semicolon_int }
      {
        {0} { \__examzh_foot_content_no_page_or_lastpage_output: }
        {1}
          { 
            % 将输入“分解”
            \__examzh_foot_content_only_page_input:V \l__examzh_foot_content_format_tl
            % 然后输出
            \use:c { __examzh_foot_content_only_page_a3paper_right_output: }
          }
        {2}
          {
            % 将输入“分解”
            \__examzh_foot_content_page_and_lastpage_input:V \l__examzh_foot_content_format_tl
            % 然后输出
            \use:c { __examzh_foot_content_page_and_lastpage_a3paper_right_output: }
          }
      }
      {
        \msg_error:nn { exam-zh } { foot-semicolon-number-error }
      }
  }

\tl_set:Nn \headrulewidth { 0pt }
% \cs_set_eq:NN \@mkboth \use_none:n
\cs_set_eq:NN \sectionmark \use_none:n
\cs_set_eq:NN \subsectionmark \use_none:n

\cs_new:Npn \__examzh_column_box:n #1
  {
    \makebox [ \columnwidth ] {#1}
  }


\AtEndPreamble
  {
    \fancypagestyle { plain }
      {
        \fancyhf { }
        \bool_if:NT \l__examzh_show_head_bool
          {
            \l__examzh_head_content_tl
          }
        \bool_if:cTF { g__examzh_page_size_a4paper_bool }
          {
            % a4paper
            \bool_if:NT \l__examzh_show_foot_bool
              {
                \fancyfoot [ C ]
                  {
                    \small
                    \use:c { __examzh_foot_content_a4paper_output: }
                    % \l__examzh_subject_tl 试题第 \thepage { } 页（共 \pageref { LastPage } ~ 页）
                  }
              }
          }
          {
            % a3paper
            \bool_if:NT \l__examzh_show_foot_bool
              {
                \bool_if:cTF 
                  { g__examzh_page_a3paper_foot_common_bool }
                  {
                    % 两页共用一个页脚
                    \fancyfoot [ C ]
                      {
                        \small
                        % \l__examzh_subject_tl 试题第 \thepage { } 页（共 \pageref { LastPage } ~ 页）
                        \use:c { __examzh_foot_content_a3paper_common_output: }
                      }
                  }
                  {
                    % 每页一个页脚
                    \fancyfoot [ L ]
                      {
                        \__examzh_column_box:n
                          {
                            \small
                            \use:c { __examzh_foot_content_a3paper_separate_left_output: }
                          }
                      }
                    \fancyfoot [ R ]
                      {
                        \__examzh_column_box:n
                          {
                            \small
                            \use:c { __examzh_foot_content_a3paper_separate_right_output: }
                          }
                      }
                  }
              }
          }
      }
  }
\AtBeginDocument { \pagestyle { plain } }




% 草稿纸

% “草稿纸”三个字的尺寸
\dim_new:N \l__examzh_draft_watermark_size_dim
% 控制是否自动添加草稿纸
\bool_new:N \l__examzh_draft_show_auto_bool

\keys_define:nn { exam-zh / draft }
  {
    watermark-size .code:n = 
      {
        % 之所以这样设置而不是 .dim_set:N 是因为 a4 和 a3 的切换不是文档选项
        % 而是通过 \examsetup 更改的。所以要设置默认值必须用 \AtEndPreamble
        % 来检测 g__examzh_page_size_a4paper_bool 的值才行，但这样的话就会
        % 把 watermark-size 的值覆盖，所以得实现“watermark-size” 的设置要盖掉 \AtEndPreamble
        % 设置的默认值，才可以达到用户输入产生效果
        \AtEndPreamble
          {
            \dim_set:Nn \l__examzh_draft_watermark_size_dim {#1}
          }
      },
    show-watermark .bool_set:N = \l__examzh_draft_show_watermark_bool,
    show-draft .choice:,
    show-draft / auto .code:n = 
      { \bool_set_true:N \l__examzh_draft_show_auto_bool },    
    show-draft / manual .code:n = 
      { \bool_set_false:N \l__examzh_draft_show_auto_bool },
  }
\keys_set:nn { exam-zh / draft }
  {
    show-watermark = true,
    show-draft     = manual,
  }
% “草稿纸”尺寸默认值
\AtEndPreamble
  {
    \bool_if:cTF { g__examzh_page_size_a4paper_bool }
      {
        \keys_set:nn { exam-zh / draft }
          { watermark-size = 100pt }
      }
      {
        \keys_set:nn { exam-zh / draft }
          { watermark-size = 180pt }
      }
  }
\AtEndDocument
  {
    \bool_if:NT \l__examzh_draft_show_auto_bool
      { \draftpaper \draftpaper }
  }
\NewDocumentCommand { \draftpaper } { O{} }
  {
    \group_begin:
      \keys_set:nn { exam-zh / draft } {#1}
      \bool_if:NTF \l__examzh_draft_show_watermark_bool
        { \__examzh_draft_with_watermark: }
        { \__examzh_draft_without_watermark: }
    \group_end:
  }
\cs_new:Npn \__examzh_draft_with_watermark:
  {
    \clearpage
    \null
    \thispagestyle { empty }
    \begin{tikzpicture}
        [
          remember~picture,
          overlay,
          font = \sffamily\fontsize{ \l__examzh_draft_watermark_size_dim }{180pt}\selectfont
        ]
      \node[text = lightgray!40] at (current~page.center) {草\quad 稿\quad 纸};
    \end{tikzpicture}
    \clearpage
  }
\cs_new:Npn \__examzh_draft_without_watermark:
  {
    \clearpage
    \null
    \thispagestyle { empty }
    \clearpage
  }



% 评分框 scoring box

\bool_new:N \g__examzh_combine_section_with_scoringbox_position_left_bool

\NewCommandCopy { \examzholdsection } { \section }
\cs_new:Npn \__examzh_combine_section_with_twocolumn_scoringbox:
  {
    \bool_if:NTF \g__examzh_combine_section_with_scoringbox_position_left_bool
      {
        \RenewDocumentCommand { \section } { m }
          {
            \par\addvspace{1.5em}\noindent
            \begin{tabular}{lc}
              \begin{minipage}{0.2\columnwidth}
                \begin{tabular}{|c|c|}
                  \hline 
                  得分 & \rule{3em}{0pt}\rule[-0.7em]{0pt}{2em} \\\hline
                  阅卷人 & \rule{3em}{0pt}\rule[-0.7em]{0pt}{2em} \\\hline
                \end{tabular}
              \end{minipage} & 
              \begin{minipage}{0.745\columnwidth}
                \examzholdsection {##1}
              \end{minipage}
            \end{tabular}
            \par
            \addvspace{1em}
          }
      }
      {
        \RenewDocumentCommand { \section } { m }
          {
            \par\addvspace{1.5em}\noindent
            \begin{tabular}{lc}
              \begin{minipage}{0.745\columnwidth}
                \examzholdsection {##1}
              \end{minipage} & 
              \begin{minipage}{0.2\columnwidth}
                \begin{tabular}{|c|c|}
                  \hline 
                  得分 & \rule{3em}{0pt}\rule[-0.7em]{0pt}{2em} \\\hline
                  阅卷人 & \rule{3em}{0pt}\rule[-0.7em]{0pt}{2em} \\\hline
                \end{tabular}
              \end{minipage}
            \end{tabular}
            \par
            \addvspace{1em}
          }
      }
  }
\cs_new:Npn \__examzh_combine_section_with_onecolumn_scoringbox:
  {
    \bool_if:NTF \g__examzh_combine_section_with_scoringbox_position_left_bool
      {
        \RenewDocumentCommand { \section } { m }
          {
            \par\addvspace{1.5em}\noindent
            \begin{tabular}{cc}
              \begin{varwidth}{3.5em}
                \begin{tabular}{|c|}
                  \hline 
                  得分\rule[-0.7em]{0pt}{2em} \\\hline
                  \rule[-0.7em]{0pt}{2em} \\\hline
                \end{tabular}
              \end{varwidth} & 
              \begin{varwidth}{0.865\columnwidth}
                \examzholdsection {##1}
              \end{varwidth}
            \end{tabular}
            \par
            \addvspace{1em}
          }
      }
      {
        \RenewDocumentCommand { \section } { m }
          {
            \par\addvspace{1.5em}\noindent
            \begin{tabular}{cc}
              \begin{varwidth}{0.865\columnwidth}
                \examzholdsection {##1}
              \end{varwidth} &
              \begin{varwidth}{3.5em}
                \begin{tabular}{|c|}
                  \hline 
                  得分\rule[-0.7em]{0pt}{2em} \\\hline
                  \rule[-0.7em]{0pt}{2em} \\\hline
                \end{tabular}
              \end{varwidth}
            \end{tabular}
            \par
            \addvspace{1em}
          }
      }
  }
\cs_new:Npn \__examzh_restore_section:
  {
    \RenewCommandCopy { \section } { \examzholdsection }
  }

\keys_define:nn { exam-zh / scoringbox }
  {
    type .choice:,
    type / onecolumn .code:n =
      {
        \AtEndPreamble { \__examzh_combine_section_with_onecolumn_scoringbox: }
      },
    type / twocolumn .code:n =
      {
        \AtEndPreamble { \__examzh_combine_section_with_twocolumn_scoringbox: }
      },
    type / none .code:n = { \__examzh_restore_section: },
    position .choice:,
    position / left .code:n =
      {
        \bool_gset_true:N \g__examzh_combine_section_with_scoringbox_position_left_bool
      },
    position / right .code:n =
      {
        \bool_gset_false:N \g__examzh_combine_section_with_scoringbox_position_left_bool
      },
  }
\keys_set:nn { exam-zh / scoringbox }
  {
    type = none,
    position = left
  }
\keys_define:nn { exam-zh }
  { scoringbox .meta:nn = { exam-zh / scoringbox } {#1} }


\NewDocumentCommand { \scoringbox } { s }
  {
    \IfBooleanTF {#1}
      { \__examzh_scoringbox_onecolumn: }
      { \__examzh_scoringbox_twocolumn: }
  }
\cs_new_protected:Nn \__examzh_scoringbox_twocolumn:
  {
    \begin{tabular}{|c|c|}
      \hline 
      得分 & \rule{3em}{0pt}\rule[-0.7em]{0pt}{2em} \\\hline
      阅卷人 & \rule{3em}{0pt}\rule[-0.7em]{0pt}{2em} \\\hline
    \end{tabular}
  }
\cs_new_protected:Nn \__examzh_scoringbox_onecolumn:
  {
    \begin{tabular}{|c|}
      \hline 
      得分\rule[-0.7em]{0pt}{2em} \\\hline
      \rule[-0.7em]{0pt}{2em} \\\hline
    \end{tabular}
  }



% 脚注
% 摘自 fduthesis.cls

\cs_new_protected:Npn \__examzh_define_fn_style:nn #1#2
  { \tl_const:cn { c__examzh_fn_style_ #1 _tl } {#2} }
\cs_new:Npn \__examzh_symbol:n #1 { \tex_char:D #1 \scan_stop: }

\clist_map_inline:nn
  {
    { plain           } { plain           },
    { libertinus      } { libertinus      },
    { libertinus_neg  } { libertinus*     },
    { libertinus_sans } { libertinus-sans },
    { pifont          } { pifont          },
    { pifont_neg      } { pifont*         },
    { pifont_sans     } { pifont-sans     },
    { pifont_sans_neg } { pifont-sans*    },
    { xits            } { xits            },
    { xits_sans       } { xits-sans       },
    { xits_sans_neg   } { xits-sans*      }
  }
  { \__examzh_define_fn_style:nn #1 }
\tl_new:N \l__examzh_fn_style_tl
\keys_define:nn { exam-zh / style }
  {
    footnote-style .choices:nn =
      {
        plain,
        libertinus, libertinus*, libertinus-sans,
        pifont,     pifont*,     pifont-sans,     pifont-sans*,
        xits,                    xits-sans,       xits-sans*
      }
      {
        \tl_gset_eq:NN \l__examzh_fn_style_tl \l_keys_choice_tl
        \int_compare:nT { 5 <= \l_keys_choice_int <= 8 }
          { \RequirePackage { pifont } }
      },
    footnote-style .value_required:n = true
  }
\keys_set:nn { exam-zh / style }
  {
    footnote-style = libertinus
  }
\cs_new:Npn \__examzh_fn_symbol_libertinus:n #1
  {
    \int_compare:nTF { #1 >= 21 }
      {
        \int_compare:nTF { #1 >= 47 }
          { \__examzh_symbol:n { \int_eval:n { "24B6 - 47 + #1 } } }
          { \__examzh_symbol:n { \int_eval:n { "24D0 - 21 + #1 } } }
      }
      { \__examzh_symbol:n { \int_eval:n { "2460 - 1 + #1 } } }
  }
\cs_new:Npn \__examzh_fn_symbol_libertinus_neg:n #1
  {
    \int_compare:nTF { #1 >= 11 }
      { \__examzh_symbol:n { \int_eval:n { "24EB - 11 + #1 } } }
      { \__examzh_symbol:n { \int_eval:n { "2776 -  1 + #1 } } }
  }
\cs_new_eq:NN \__examzh_fn_symbol_libertinus_sans:n \__examzh_fn_symbol_libertinus:n
\cs_new:Npn \__examzh_fn_symbol_pifont:n #1
  { \ding { \int_eval:n { 171 + #1 } } }
\cs_new:Npn \__examzh_fn_symbol_pifont_neg:n #1
  { \ding { \int_eval:n { 181 + #1 } } }
\cs_new:Npn \__examzh_fn_symbol_pifont_sans:n #1
  { \ding { \int_eval:n { 191 + #1 } } }
\cs_new:Npn \__examzh_fn_symbol_pifont_sans_neg:n #1
  { \ding { \int_eval:n { 201 + #1 } } }
\cs_new:Npn \__examzh_fn_symbol_xits:n #1
  {
    \int_compare:nTF { #1 >= 10 }
      {
        \int_compare:nTF { #1 >= 36 }
          { \__examzh_symbol:n { \int_eval:n { "24B6 - 36 + #1 } } }
          { \__examzh_symbol:n { \int_eval:n { "24D0 - 10 + #1 } } }
      }
      { \__examzh_symbol:n { \int_eval:n { "2460 - 1 + #1 } } }
  }
\cs_new:Npn \__examzh_fn_symbol_xits_sans:n #1
  { \__examzh_symbol:n { \int_eval:n { "2780 - 1 + #1 } } }
\cs_new:Npn \__examzh_fn_symbol_xits_sans_neg:n #1
  { \__examzh_symbol:n { \int_eval:n { "278A - 1 + #1 } } }
\cs_set:Npn \thefootnote { \examzh_footnote_number:N \c@footnote }
\cs_new:Npn \examzh_footnote_number:N #1
  {
    \tl_case:NnF \l__examzh_fn_style_tl
      {
        \c__examzh_fn_style_plain_tl
          { \int_use:N #1 }
        \c__examzh_fn_style_libertinus_tl
          {
            \fontspec { LibertinusSerif-Regular .otf }
            \__examzh_fn_symbol_libertinus:n {#1}
          }
        \c__examzh_fn_style_libertinus_neg_tl
          {
            \fontspec { LibertinusSerif-Regular .otf }
            \__examzh_fn_symbol_libertinus_neg:n {#1}
          }
        \c__examzh_fn_style_libertinus_sans_tl
          {
            \fontspec { LibertinusSans-Regular .otf }
            \__examzh_fn_symbol_libertinus_sans:n {#1}
          }
        \c__examzh_fn_style_pifont_tl
          { \__examzh_fn_symbol_pifont:n {#1} }
        \c__examzh_fn_style_pifont_neg_tl
          { \__examzh_fn_symbol_pifont_neg:n {#1} }
        \c__examzh_fn_style_pifont_sans_tl
          { \__examzh_fn_symbol_pifont_sans:n {#1} }
        \c__examzh_fn_style_pifont_sans_neg_tl
          { \__examzh_fn_symbol_pifont_sans_neg:n {#1} }
        \c__examzh_fn_style_xits_tl
          {
            \fontspec { XITS-Regular .otf }
            \__examzh_fn_symbol_xits:n {#1}
          }
        \c__examzh_fn_style_xits_sans_tl
          {
            \fontspec { XITS-Regular .otf }
            \__examzh_fn_symbol_xits_sans:n {#1}
          }
        \c__examzh_fn_style_xits_sans_neg_tl
          {
            \fontspec { XITS-Regular .otf }
            \__examzh_fn_symbol_xits_sans_neg:n {#1}
          }
      }
      { \int_use:N #1 }
  }
\cs_set:Npn \@makefntext #1
  {
    \mode_leave_vertical:
    \hbox_to_wd:nn { 1.5 em } { \@thefnmark \hfil }
    #1
  }

% 修改目录样式
\keys_define:nn { exam-zh / content }
  {
    name .tl_gset:N = \g__examzh_contentsname_tl,
    name .initial:n = { 目录 },
  }
\ctexset
  {
    contentsname = { \centerline{ \zihao{-1} \g__examzh_contentsname_tl} }
  }
\renewcommand{\cftdot}{\ensuremath{\cdot}}
\renewcommand{\cftchapleader}{\cftdotfill{\cftdotsep}}
% \renewcommand{\cftpartfont}{\zihao{3}\bfseries\hfil}
\renewcommand{\cftpartfont}{\zihao{-2}\bfseries}
\renewcommand{\cftchapfont}{\zihao{-4}\bfseries}
\cftpagenumbersoff{part}  % 去掉 part 在目录的页码


\NewDocumentCommand \questionsetup { m }
  { \keys_set:nn { exam-zh / question } { #1 } }
\NewDocumentCommand \fillinsetup { m }
  { \keys_set:nn { exam-zh / fillin } { #1 } }

% ulem 宏包重定义了 \emph，使用 \normalem 恢复
\normalem

\setlist{nosep}
\setlist
  {
    labelsep    = 4pt,
  }

% question 环境相关变量

% 计数器
\int_new:N \g__examzh_question_index_int
% 答案颜色
\tl_new:N \l__examzh_question_answer_color_tl
% 题目分数
\int_new:N \l__examzh_question_points_int
% 是否显示题目分数
\bool_new:N \l__examzh_question_show_points_bool
\bool_new:N \l__examzh_question_show_points_auto_bool
% 题目分数是否单独成段，解答题需要单独成段
\bool_new:N \l__examzh_question_points_separate_par_bool
% 是否显示括号
\bool_new:N \l__examzh_question_show_paren_bool
% 是否显示答案
\bool_new:N \l__examzh_question_show_answer_bool
\bool_new:N \l__examzh_question_show_fillin_answer_bool
\bool_new:N \l__examzh_question_show_paren_answer_bool
% 彩框
\str_new:N \g__examzh_question_colorbox_type_str
\str_new:N \g__examzh_problem_colorbox_type_str
% 彩框颜色
\tl_new:N \g__examzh_question_colorbox_color_tl
\tl_new:N \g__examzh_problem_colorbox_color_tl
% 上下的间距
\skip_new:N \l__examzh_question_top_sep_skip
\skip_new:N \l__examzh_question_bottom_sep_skip
% label 的对齐
\tl_new:N \l__examzh_question_label_align_tl
\tl_new:N \l__examzh_problem_label_align_tl
% 环境活动状态：用于修复 verbatim/trivlist 与题目列表的间距叠加。
\bool_new:N \l__examzh_question_active_bool
\bool_new:N \l__examzh_problem_active_bool

\AddToHook { env / verbatim / end }
  {
    \bool_lazy_or:nnT
      { \bool_if_p:N \l__examzh_question_active_bool }
      { \bool_if_p:N \l__examzh_problem_active_bool }
      {
        \skip_zero:N \topsep
        \skip_zero:N \partopsep
        \skip_zero:N \@topsepadd
      }
  }

% problem 直接进入 enumerate 时，外层题号盒已占用首段缩进；将盒宽归零，
% 避免题号与第一层列表的缩进叠加。
\AddToHook { env / enumerate / before }
  {
    \bool_if:NT \l__examzh_problem_active_bool
      {
        \legacy_if:nT { @inlabel }
          {
            \hbox_gset:Nn \@labels
              { \hbox_overlap_right:n { \box_use_drop:N \@labels } }
          }
      }
  }


\keys_define:nn { exam-zh }
  { question .meta:nn = { exam-zh / question } {#1} }
\keys_define:nn { exam-zh }
  { problem .meta:nn = { exam-zh / problem } {#1} }


\keys_define:nn { exam-zh / question }
  {
    % 手动调整 question 环境的计数器
    index               .int_gset:N = \g__examzh_question_index_int ,
    % 分数
    points              .int_set:N = \l__examzh_question_points_int ,
    % 分数显示控制
    show-points         .choice: ,
    show-points / auto  .code:n =
      { \bool_set_true:N \l__examzh_question_show_points_auto_bool } ,
    show-points / true  .code:n =
      {
        \bool_set_true:N  \l__examzh_question_show_points_bool
        \bool_set_false:N \l__examzh_question_show_points_auto_bool
      } ,
    show-points / false .code:n =
      {
        \bool_set_false:N \l__examzh_question_show_points_bool
        \bool_set_false:N \l__examzh_question_show_points_auto_bool
      } ,
    % 分数是否单独成段
    points-separate-par .bool_set:N = \l__examzh_question_points_separate_par_bool ,
    % 是否显示答案
    % show-answer         .bool_set:N = \l__examzh_question_show_answer_bool ,
    show-answer         .choice: ,
    show-answer / true .code:n = 
      {
        \bool_set_true:N \l__examzh_question_show_fillin_answer_bool
        \bool_set_true:N \l__examzh_question_show_paren_answer_bool
      },
    show-answer / false .code:n = 
      {
        \bool_set_false:N \l__examzh_question_show_fillin_answer_bool
        \bool_set_false:N \l__examzh_question_show_paren_answer_bool
      },
    % 上方间距
    top-sep             .skip_set:N = \l__examzh_question_top_sep_skip ,
    % 下方间距
    bottom-sep          .skip_set:N = \l__examzh_question_bottom_sep_skip ,
    label .tl_set:N = \l__examzh_question_label_tl,
    combine-fillin .bool_set:N = \l__examzh_question_combine_fillin_bool,
    combine-fillin-args .tl_set:N = \l__examzh_question_combine_fillin_args_tl,
    label-align .choices:nn =
      { left, center, right }
      { \tl_set_eq:NN \l__examzh_question_label_align_tl \l_keys_choice_tl },
    hang .bool_set:N = \l__examzh_question_hang_bool,
    points-prelabel .tl_set:N = \l__examzh_question_points_prelabel_tl,
    points-postlabel .tl_set:N = \l__examzh_question_points_postlabel_tl,
    source .tl_set:N = \l__examzh_question_source_tl,
    show-source .bool_set:N = \l__examzh_question_show_source_bool,
    style .choices:nn =
      { normal, colorbox1, colorbox2 }
      {
        \str_set:NV \g__examzh_question_colorbox_type_str \l_keys_choice_tl
      },
    colorbox-color .tl_gset:N = \g__examzh_question_colorbox_color_tl,
    colorbox-color .initial:n = pink!20,
  }


\keys_set:nn { exam-zh / question }
  {
    index               = 1,
    points              = 0 ,
    show-points         = auto ,
    points-separate-par = false ,
    show-answer         = false ,
    top-sep             = .25em plus .25em minus .1em ,
    bottom-sep          = .25em plus .25em minus .1em ,
    label               = \arabic*.,
    combine-fillin      = false,
    label-align         = right,
    hang                = true,
    points-prelabel     = {（},
    points-postlabel    = {分）},
    show-source         = false,
  }

\keys_define:nn { exam-zh / problem }
  {
    % 手动调整 question 环境的计数器
    index               .int_gset:N = \g__examzh_question_index_int ,
    % 分数
    points              .int_set:N = \l__examzh_question_points_int ,
    % 分数显示控制
    show-points         .choice: ,
    show-points / auto  .code:n =
      { \bool_set_true:N \l__examzh_question_show_points_auto_bool } ,
    show-points / true  .code:n =
      {
        \bool_set_true:N  \l__examzh_question_show_points_bool
        \bool_set_false:N \l__examzh_question_show_points_auto_bool
      } ,
    show-points / false .code:n =
      {
        \bool_set_false:N \l__examzh_question_show_points_bool
        \bool_set_false:N \l__examzh_question_show_points_auto_bool
      } ,
    % 分数是否单独成段
    points-separate-par .bool_set:N = \l__examzh_problem_points_separate_par_bool,
    % 是否显示答案
    % show-answer         .bool_set:N = \l__examzh_question_show_answer_bool ,
    show-answer         .choice: ,
    show-answer / true .code:n = 
      {
        \bool_set_true:N \l__examzh_question_show_fillin_answer_bool
        \bool_set_true:N \l__examzh_question_show_paren_answer_bool
      },
    show-answer / false .code:n = 
      {
        \bool_set_false:N \l__examzh_question_show_fillin_answer_bool
        \bool_set_false:N \l__examzh_question_show_paren_answer_bool
      },
    % 上方间距
    top-sep             .skip_set:N = \l__examzh_problem_top_sep_skip ,
    % 下方间距
    bottom-sep          .skip_set:N = \l__examzh_problem_bottom_sep_skip ,
    label .tl_set:N = \l__examzh_question_label_tl,
    label-align .choices:nn =
      { left, center, right }
      { \tl_set_eq:NN \l__examzh_problem_label_align_tl \l_keys_choice_tl },
    points-prelabel .tl_set:N = \l__examzh_problem_points_prelabel_tl,
    points-postlabel .tl_set:N = \l__examzh_problem_points_postlabel_tl,
    source .tl_set:N = \l__examzh_problem_source_tl,
    show-source .bool_set:N = \l__examzh_problem_show_source_bool,
    style .choices:nn =
      { normal, colorbox1, colorbox2 }
      {
        \str_set:NV \g__examzh_problem_colorbox_type_str \l_keys_choice_tl
      },
    colorbox-color .tl_gset:N = \g__examzh_problem_colorbox_color_tl,
    colorbox-color .initial:n = pink!20,
  }

\keys_set:nn { exam-zh / problem }
  {
    index               = 1,
    points              = 0 ,
    show-points         = auto ,
    points-separate-par = false ,
    show-answer         = false ,
    top-sep             = .25em plus .25em minus .1em ,
    bottom-sep          = .25em plus .25em minus .1em ,
    label               = \arabic*.,
    label-align         = right,
    points-prelabel     = {（},
    points-postlabel    = {分）}
  }

% 是否按照解答题的格式排版
\bool_new:N \l__examzh_question_problem_style_bool


% 选择题和填空题的题干。不捕获环境正文，以保留 verbatim 类环境读取正文时
% 所需的 catcode，并允许题干自然地包含代码、列表和其它逐字环境。
\NewDocumentEnvironment { question } { O { } }
  {
    % \bool_set_false:N \l__examzh_question_problem_style_bool
    \group_begin:
      \bool_set_true:N \l__examzh_question_active_bool
      \__examzh_question_begin:nn {#1}{ }
  }
  {
      \__examzh_question_end:nn { } { }
      \bool_set_false:N \l__examzh_question_active_bool
    \group_end:
  }

% 解答题
\NewDocumentEnvironment { problem } { O { } }
  {
    % \bool_set_true:N \l__examzh_question_problem_style_bool
    \group_begin:
      \bool_set_true:N \l__examzh_problem_active_bool
      \__examzh_problem_begin:nn {#1}{ }
  }
  {
      \__examzh_problem_end:nn { } { }
      \bool_set_false:N \l__examzh_problem_active_bool
    \group_end:
  }

\prg_generate_conditional_variant:Nnn \int_compare:nNn { xNn } { T }

% question 和 problem 环境的 list 间距设置
\cs_new:Npn \__examzh_enumerate_set_question:
  {
    \setlist[enumerate, 1]
      {
        labelindent = \parindent,
        labelsep    = 2pt,
        leftmargin  = *,
        % label       = { \arabic * .}
        label       = {（ \arabic * ）},
      }

    \setlist[enumerate, 2]
      {
        % labelindent = *,
        leftmargin  = 2em, 
        widest      = 0,
        itemindent  = 0em,
        labelsep    = 0pt,
        % labelwidth  = 2em,
        listparindent = \parindent,
        label       = {（ \alph * ）},
      }
    \setlist[enumerate, 3]
      {
        % labelindent = *,
        leftmargin  = 2em, 
        widest      = 0,
        itemindent  = 0em,
        labelsep    = 0pt,
        % labelwidth  = 2em,
        listparindent = \parindent,
        label       = {（ \roman * ）},
      }
  }
\cs_new:Npn \__examzh_enumerate_set_problem:
  {
    \setlist[enumerate, 1]
      {
        labelindent = 2em,
        labelsep    = 4pt,
        leftmargin  = *,
        % label       = { \arabic * .}
        label       = {（ \arabic * ）},
      }

    \setlist[enumerate, 2]
      {
        % labelindent = *,
        leftmargin  = 2em, 
        widest      = 0,
        itemindent  = 0em,
        labelsep    = 0pt,
        % labelwidth  = 2em,
        listparindent = \parindent,
        label       = {（ \alph * ）},
      }
    \setlist[enumerate, 3]
      {
        % labelindent = *,
        leftmargin  = 2em, 
        widest      = 0,
        itemindent  = 0em,
        labelsep    = 0pt,
        % labelwidth  = 2em,
        listparindent = \parindent,
        label       = {（ \roman * ）},
      }
  }

\cs_new:Npn \__examzh_question_begin:nn #1#2
  {
    \par
    % \bool_if:NTF \l__examzh_question_combine_fillin_bool
    %   { \keys_set:nn { exam-zh / question } { label-align = left } }
    %   { \keys_set:nn { exam-zh / question } { label-align = right } }
    % 设置键值
    \keys_set:nn { exam-zh / question } { #1 }
    % 题干正文不再被捕获（以支持 verbatim），因此不能在环境结束时
    % 通过 #2 反查题型；question 统一采用选择/判断题的较短留白。
    \str_if_eq:VnT \l__examzh_solution_blank_type_str { manual }
      { \skip_gset:Nn \l__examzh_solution_blank_vsep_skip { 2cm } }
    % 题干计数器的值加一
    \int_gincr:N \g__examzh_question_index_int
    % 设置上方间距
    % \addvspace { \l__examzh_question_top_sep_skip }
    \vspace { \l__examzh_question_top_sep_skip }
    % 设置 enumerate 环境间距
    \__examzh_enumerate_set_question:
    % 严格禁止孤行和寡行
    \int_set:Nn \clubpenalty { 10000 }
    \int_set:Nn \widowpenalty { 10000 }
    % 尽量避免在题目中间换行
    \int_set:Nn \interlinepenalty { 301 }
    % 这部分是仿照 source2e 中 enumerate 的定义写的
    % \@enumdepth 主要控制 enumerate 不同层级的编号
    % 这样设置后，在 question 中使用 enumerate 会调用 level 2 的编号
    % 也就是 question 中的 enumerate 环境直接从第二层开始

    % \int_incr:N \@enumdepth

    % 如果 show-points = auto 那么解答题显示分数，选择题和填空题不显示分数
    % 这样设置考虑到选择题和填空题都是每道题一样的分数，在最开始的地方说明即可
    % 而解答题不太一样
    \bool_if:NT \l__examzh_question_show_points_auto_bool
      {
        \bool_set_false:N \l__examzh_question_show_points_bool
      }
    % 使用列表环境输出
    \list 
      {
        % \int_use:N \g__examzh_question_index_int . 
        \bool_if:NTF \l__examzh_question_combine_fillin_bool
          {
            % \framebox[6em]
            % \fbox
              % {
            \__examzh_question_make_label:n
              {
                  \tl_if_blank:VTF \l__examzh_question_combine_fillin_args_tl
                  { \fillin }
                  {
                    \use:x
                      {
                        \exp_not:N \fillin \l__examzh_question_combine_fillin_args_tl
                      }
                  }
                  \__examzh_question_the_label:
              }
              % }
          }
          {
            \__examzh_question_make_label:n
              {
                \__examzh_question_the_label:
              }
          }
        % \__examzh_question_make_label:n
        %   {
        %     \bool_if:NT \l__examzh_question_combine_fillin_bool
        %       {
        %         % \makebox
        %           % {
        %             \tl_if_blank:VTF \l__examzh_question_combine_fillin_args_tl
        %               { \fillin }
        %               {
        %                 \use:x
        %                   {
        %                     \exp_not:N \fillin \l__examzh_question_combine_fillin_args_tl
        %                   }
        %               }
        %           % }
        %       }
        %     \int_compare:xNnT { \g__examzh_question_index_int } < { 11 }
        %       { \phantom {1} }
        %     \__examzh_question_the_label:
        %   }
      }
      {
        % 用 group 是为了防止 combine-fillin 的 type 影响了环境里面的 fillin 的type
        \group_begin:
          \dim_gset:Nn \topsep       { 0pt }
          \dim_gset:Nn \partopsep    { 0pt }
          \dim_gset:Nn \itemsep      { 0em }
          \dim_gset:Nn \parsep       { 0pt }
          % \group_begin:
            % 上面 \fillin 里面的设置是局部的，这样的问题是 question 的可选参数改 type 的时候不会影响 \l__examzh_fillin_type_str 的值
            % 所以要把 \l__examzh_question_combine_fillin_args_tl 里关于 type 的选取出来
            \__examzh_question_begin_fillin_type_set:
            \__examzh_question_begin_labelsep_labelwidth_set:
          % \group_end:
          % \bool_if:NTF \l__examzh_question_problem_style_bool
          %   {
          %     % 解答题是正文 + 缩进 2em 的效果
          %     \bool_if:NTF \l__examzh_question_combine_fillin_bool
          %       {
          %         % 如果 combine 的话就和 question 一样的缩进
          %         \bool_if:NTF \l__examzh_question_hang_bool
          %           { \dim_gset:Nn \itemindent { 0em } }
          %           { \dim_gset:Nn \itemindent { 2em } }
          %         \bool_if:NTF \l__examzh_question_combine_fillin_bool
          %           {
          %             \bool_if:NTF \l__examzh_question_hang_bool
          %               { \dim_gset:Nn \leftmargin { 6em } }
          %               { \dim_gset:Nn \leftmargin { 4em } }
          %           }
          %           {
          %             \bool_if:NTF \l__examzh_question_hang_bool
          %               { \dim_gset:Nn \leftmargin { 2em } }
          %               { \dim_gset:Nn \leftmargin { 0em } }
          %           }
          %       }
          %       {
          %         \dim_gset:Nn \leftmargin { 0pt }
          %         \dim_gset:Nn \itemindent { 2em }
          %       }
          %   }
            % {
              % 选择和填空题是悬挂效果
              \bool_if:NTF \l__examzh_question_hang_bool
                { \dim_gset:Nn \itemindent { 0em } }
                { \dim_gset:Nn \itemindent { 2em } }
              \bool_if:NTF \l__examzh_question_combine_fillin_bool
                {
                  \bool_if:NTF \l__examzh_question_hang_bool
                    { \dim_gset:Nn \leftmargin { 6em } }
                    { \dim_gset:Nn \leftmargin { 4em } }
                }
                {
                  \bool_if:NTF \l__examzh_question_hang_bool
                    { \dim_gset:Nn \leftmargin { 2em } }
                    { \dim_gset:Nn \leftmargin { 0em } }
                }
            % }
          \dim_gset_eq:NN \listparindent \itemindent
        \group_end:
      }
    \item \relax
    % 输出题目分数
    \bool_if:NT \l__examzh_question_show_points_bool
      {
        % 如果设置了分数且 show-points 的 bool 是 true 的话就显示
        \int_compare:nNnT { \l__examzh_question_points_int } > { 0 }
          { \l__examzh_question_points_prelabel_tl \int_use:N \l__examzh_question_points_int ~ \l__examzh_question_points_postlabel_tl }
        % 是否分段（解答题需要分段）
        \bool_if:NT \l__examzh_question_points_separate_par_bool
          % \par 分段之后使用 \nopagebreak 避免分页导致序号和分数出现在页面最后一行
          { \par \nopagebreak }   
      }
    \bool_if:NT \l__examzh_question_show_source_bool
      {
        \tl_if_blank:VF \l__examzh_question_source_tl
          {
            （\l__examzh_question_source_tl）
          }
      }
  }
\int_new:N \l__examzh_question_begin_fillin_args_bracket_num_int
\cs_generate_variant:Nn \regex_count:nnN { nVN }
\prg_generate_conditional_variant:Nnn \regex_extract_once:nnN { nxN } { F } 
\cs_new:Npn \__examzh_question_begin_fillin_type_set:
  {
    \regex_count:nVN { \[ } % \]
      \l__examzh_question_combine_fillin_args_tl
      \l__examzh_question_begin_fillin_args_bracket_num_int
    \use_none:n { \] }  % 消去 \[ 的高亮影响
    % \int_use:N \l__examzh_question_begin_fillin_args_bracket_num_int
    \int_compare:nNnT { \l__examzh_question_begin_fillin_args_bracket_num_int } = {2}
      {
        \regex_extract_once:nxNF { \[ (.*?) \] } { \l__examzh_question_combine_fillin_args_tl } \l_tmpa_seq { \fail }
        \seq_pop_left:NN \l_tmpa_seq \l_tmpa_tl
        % \seq_use:Nn \l_tmpa_seq {,}
        \keys_set:nx { exam-zh / fillin } { \seq_use:Nn \l_tmpa_seq {,} }
      }
  }
\cs_new:Npn \__examzh_problem_begin_labelsep_labelwidth_set:
  {
    \str_case:Vn \l__examzh_problem_label_align_tl 
      {
        { left } 
          { 
            \dim_gset:Nn \labelsep { .7em }
            \dim_gset:Nn \labelwidth { 1.8em } 
          }
        { center }
          {
            \dim_gset:Nn \labelsep { .7em } 
            \dim_gset:Nn \labelwidth { 1.3em } 
          }
        { right  } 
          {
            \dim_gset:Nn \labelsep { .7em } 
            \dim_gset:Nn \labelwidth { 1.3em } 
          }
      }
  }
\cs_new:Npn \__examzh_question_begin_labelsep_labelwidth_set:
  {
    \bool_if:NTF \l__examzh_question_combine_fillin_bool
      { 
        \str_case:Vn \l__examzh_question_label_align_tl
          {
            { left } 
              { 
                \str_case:VnF \l__examzh_fillin_type_str
                  {
                    { paren } 
                      { 
                        % combin-left-paren
                        \bool_if:NTF \l__examzh_question_show_fillin_answer_bool
                          {
                            % 显示答案
                            \dim_gset:Nn \labelsep { 2.6em } 
                            \dim_gset:Nn \labelwidth { 3.8em } 
                          }
                          {
                            % 不显示答案
                            \dim_gset:Nn \labelsep { 4.5em } 
                            \dim_gset:Nn \labelwidth { 3.8em } 
                          }
                      }
                    { line }
                      { 
                        % combin-left-line
                        \bool_if:NTF \l__examzh_question_show_fillin_answer_bool
                          {
                            % 显示答案
                            \dim_gset:Nn \labelsep { 2.2em } 
                            \dim_gset:Nn \labelwidth { 3.8em } 
                          }
                          {
                            % 不显示答案
                            \dim_gset:Nn \labelsep { 3.8em } 
                            \dim_gset:Nn \labelwidth { 3.8em } 
                          } 
                      }
                  }
                  { 
                    % combin-left-paren/line 外的
                    \dim_gset:Nn \labelsep { 2.8em }
                    \dim_gset:Nn \labelwidth { 1.3em }
                  }
              }
            { center }
              { 
                \str_case:VnF \l__examzh_fillin_type_str
                  {
                    { paren } 
                      { 
                        % combin-center-paren
                        \dim_gset:Nn \labelsep { 2em } 
                        \dim_gset:Nn \labelwidth { 5em } 
                      }
                    { line }
                      { 
                        % combin-center-line
                        \dim_gset:Nn \labelsep { 2.8em } 
                        \dim_gset:Nn \labelwidth { 4em } 
                      }
                  }
                  { 
                    % combin-center-paren/line 外的
                    \dim_gset:Nn \labelsep { 2em }
                    \dim_gset:Nn \labelwidth { 1.3em }
                  }
              }
            { right  }
              {
                \str_case:VnF \l__examzh_fillin_type_str
                  {
                    { paren } 
                      { 
                        % combin-left-paren
                        \bool_if:NTF \l__examzh_question_show_fillin_answer_bool
                          {
                            % 显示答案
                            \dim_gset:Nn \labelsep { 3.8em } 
                            \dim_gset:Nn \labelwidth { 2em } 
                          }
                          {
                            % 不显示答案
                            \dim_gset:Nn \labelsep { 5.8em } 
                            \dim_gset:Nn \labelwidth { 2em } 
                          }
                      }
                    { line }
                      { 
                        % combin-left-line
                        \bool_if:NTF \l__examzh_question_show_fillin_answer_bool
                          {
                            % 显示答案
                            \dim_gset:Nn \labelsep { 0.7em } 
                            \dim_gset:Nn \labelwidth { 1.3em } 
                          }
                          {
                            % 不显示答案
                            \dim_gset:Nn \labelsep { 5.2em } 
                            \dim_gset:Nn \labelwidth { 2em } 
                          }
                      }
                  }
                  { 
                    % combin-left-paren/line 外的
                    \dim_gset:Nn \labelsep { 2.8em } 
                    \dim_gset:Nn \labelwidth { 1.3em }
                  }
              }
          }
      }
      {
        \str_case:Vn \l__examzh_question_label_align_tl
          {
            { left } 
              { 
                \dim_gset:Nn \labelsep { .7em }
                \dim_gset:Nn \labelwidth { 1.8em } 
              }
            { center }
              {
                \dim_gset:Nn \labelsep { .7em } 
                \dim_gset:Nn \labelwidth { 1.3em } 
              }
            { right  } 
              {
                \dim_gset:Nn \labelsep { .7em } 
                \dim_gset:Nn \labelwidth { 1.3em } 
              }
          }
        
      }
  }

\cs_new:Npn \__examzh_question_end:nn #1#2
  {
    #2
    % 结束列表环境
    \endlist
    % 增加下方间距
    % \addvspace { \l__examzh_question_bottom_sep_skip }
    \vspace { \l__examzh_question_bottom_sep_skip }
  }

\cs_new:Npn \__examzh_problem_begin:nn #1#2
  {
    \par
    % \bool_if:NTF \l__examzh_question_combine_fillin_bool
    %   { \keys_set:nn { exam-zh / question } { label-align = left } }
    %   { \keys_set:nn { exam-zh / question } { label-align = right } }
    % 设置键值
    \keys_set:nn { exam-zh / problem } { #1 }
    % 与 question 一样，正文保持原始 catcode；problem 的手动答案区
    % 采用解答题所需的较大留白。
    \str_if_eq:VnT \l__examzh_solution_blank_type_str { manual }
      { \skip_gset:Nn \l__examzh_solution_blank_vsep_skip { 5cm } }
    % 题干计数器的值加一
    \int_gincr:N \g__examzh_question_index_int
    % 设置上方间距
    % \addvspace { \l__examzh_question_top_sep_skip }
    \vspace { \l__examzh_problem_top_sep_skip }
    % 设置 enumerate 环境间距
    \__examzh_enumerate_set_problem:
    % 严格禁止孤行和寡行
    \int_set:Nn \clubpenalty { 10000 }
    \int_set:Nn \widowpenalty { 10000 }
    % 尽量避免在题目中间换行
    \int_set:Nn \interlinepenalty { 301 }
    % 这部分是仿照 source2e 中 enumerate 的定义写的
    % \@enumdepth 主要控制 enumerate 不同层级的编号
    % 这样设置后，在 problem 中使用 enumerate 会调用 level 2 的编号
    % 也就是 question 中的 enumerate 环境直接从第二层开始
    % \int_incr:N \@enumdepth
    % 如果 show-points = auto 那么解答题显示分数，选择题和填空题不显示分数
    % 这样设置考虑到选择题和填空题都是每道题一样的分数，在最开始的地方说明即可
    % 而解答题不太一样
    \bool_if:NT \l__examzh_question_show_points_auto_bool
      {
        \bool_set_true:N  \l__examzh_question_show_points_bool
      }
    % 使用列表环境输出
    \list 
      {
        % \int_use:N \g__examzh_question_index_int . 
        \__examzh_problem_make_label:n
          {
            \__examzh_question_the_label:
          }
      }
      {
        % 用 group 是为了防止 combine-fillin 的 type 影响了环境里面的 fillin 的type
        \group_begin:
          \dim_gset:Nn \topsep       { 0pt }
          \dim_gset:Nn \partopsep    { 0pt }
          \dim_gset:Nn \itemsep      { 0pt }
          \dim_gset:Nn \parsep       { 0pt }
          \__examzh_problem_begin_labelsep_labelwidth_set:
          \dim_gset:Nn \leftmargin { 0pt }
          \dim_gset:Nn \itemindent { 2em }
          \dim_gset_eq:NN \listparindent \itemindent
        \group_end:
      }
    \item \relax
    % 输出题目分数
    \bool_if:NT \l__examzh_question_show_points_bool
      {
        % 如果设置了分数且 show-points 的 bool 是 true 的话就显示
        \int_compare:nNnT { \l__examzh_question_points_int } > { 0 }
          { \l__examzh_problem_points_prelabel_tl \int_use:N \l__examzh_question_points_int ~ \l__examzh_problem_points_postlabel_tl }
        % 是否分段（解答题需要分段）
        \bool_if:NT \l__examzh_problem_points_separate_par_bool
          % \par 分段之后使用 \nopagebreak 避免分页导致序号和分数出现在页面最后一行
          { \par \nopagebreak }   
      }
      % \bool_if:NT \l__examzh_problem_show_source_bool
      %   {
      %     \tl_if_blank:VF \l__examzh_problem_source_tl
      %       {
      %         （\l__examzh_problem_source_tl）
      %       }
      %   }
    % 由 question 的 show-source 统一控制 question 和 problem 的（因为一般也不会分开）
    \bool_if:NT \l__examzh_question_show_source_bool
      {
        \tl_if_blank:VF \l__examzh_problem_source_tl
          {
            （\l__examzh_problem_source_tl）
          }
      }
  }

\cs_new:Npn \__examzh_problem_end:nn #1#2
  {
    #2
    % 结束列表环境
    \endlist
    % 增加下方间距
    % \addvspace { \l__examzh_question_bottom_sep_skip }
    \vspace { \l__examzh_problem_bottom_sep_skip }
  }

\AtEndPreamble
  {
    \str_case:Vn \g__examzh_question_colorbox_type_str
      {
        { normal } {}
        { colorbox1 }
          {
            \tcolorboxenvironment{question}
              {
                enhanced~jigsaw, 
                parbox = false,
                breakable,
                boxrule = 0.2pt,
                colback = \g__examzh_question_colorbox_color_tl,
                left = 2mm,
                bottom = 2mm,
                right = 2mm,
                before~skip = 10pt
              }
          }
        { colorbox2 }
          {
            \tcolorboxenvironment{question}
              {
                enhanced~jigsaw,
                boxrule=0pt,
                rounded~corners,
                frame~code=
                  {
                    \clip[rounded~corners=1mm] (frame.south~west) rectangle (frame.north~east);
                    \shade[top~color=wt1,bottom~color=wt2] (title.south~west) rectangle (title.north~east);
                    \fill[circ1] ([xshift=  2em]title.west) circle [radius=1ex];
                    \fill[circ2] ([xshift=3.5em]title.west) circle [radius=1ex];
                    \fill[circ3] ([xshift=  5em]title.west) circle [radius=1ex];
                  },
                title={\makebox[1em]{\vphantom{标题}}},
                before~upper={\setlength{\parindent}{2em}},
                coltitle = black,
                coltext = black,
                colback = wt3,
              }
          }
      }
    \str_case:Vn \g__examzh_problem_colorbox_type_str
      {
        { normal } {}
        { colorbox1 }
          {
            \tcolorboxenvironment{problem}
              {
                enhanced~jigsaw, 
                parbox = false,
                breakable,
                boxrule = 0.2pt,
                colback = \g__examzh_question_colorbox_color_tl,
                left = 2mm,
                bottom = 2mm,
                right = 2mm,
                before~skip = 10pt
              }
          }
        { colorbox2 }
          {
            \tcolorboxenvironment{problem}
              {
                enhanced~jigsaw,
                boxrule=0pt,
                rounded~corners,
                frame~code=
                  {
                    \clip[rounded~corners=1mm] (frame.south~west) rectangle (frame.north~east);
                    \shade[top~color=wt1,bottom~color=wt2] (title.south~west) rectangle (title.north~east);
                    \fill[circ1] ([xshift=  2em]title.west) circle [radius=1ex];
                    \fill[circ2] ([xshift=3.5em]title.west) circle [radius=1ex];
                    \fill[circ3] ([xshift=  5em]title.west) circle [radius=1ex];
                  },
                title={\makebox[1em]{\vphantom{标题}}},
                before~upper={\setlength{\parindent}{2em}},
                coltitle = black,
                coltext = black,
                colback = wt3,
              }
          }
      }
  }


% 处理 question / problem 的 label
\tl_new:N \l__examzh_question_counters_commands_set_tl

\cs_new:Npn \__examzh_question_the_label:
  {
    \group_begin:
      % 定义计数器相关的命令函数
      \l__examzh_question_counters_commands_set_tl
      % 输出处理后的 label
      \l__examzh_question_label_tl
    \group_end:
  }
\cs_new:Npn \__examzh_question_make_label:n #1
  {
    \str_case:Vn \l__examzh_question_label_align_tl
      {
        { left   } { \rlap { #1 } \hss }
        { center } { \hss \clap { #1 } \hss }
        { right  } { \hss \llap { #1 } }
      }
  }
\cs_new:Npn \__examzh_problem_make_label:n #1
  {
    \str_case:Vn \l__examzh_problem_label_align_tl
      {
        { left   } { \rlap { #1 } \hss }
        { center } { \hss \clap { #1 } \hss }
        { right  } { \hss \llap { #1 } }
      }
  }
\NewDocumentCommand \AddQuestionCounter { m m }
  {
    % 生成用户层命令
    \tl_put_right:Nn \l__examzh_question_counters_commands_set_tl
      { \__examzh_process_counter:NNn #1 #2 { question } }
    % 把核心函数存起来
    \cs_set_eq:cN { __examzh_question_save_ \cs_to_str:N #1 : } #2
    \cs_set_eq:cN { __examzh_question_save_ \cs_to_str:N #2 : } #2
  }

\AddQuestionCounter \arabic \@arabic
\AddQuestionCounter \alph   \@alph
\AddQuestionCounter \Alph   \@Alph
\AddQuestionCounter \roman  \@roman
\AddQuestionCounter \Roman  \@Roman

\cs_new:Npn \__examzh_process_counter:NNn #1#2#3
  % #1: \Alph
  % #2: \@Alph
  % #3: question / fillin
  {
    \cs_set:Npn #1 { \use:c { __examzh_ #3 _process_counter_aux:Nn } #2 }
    \cs_set:Npn #2 { \use:c { __examzh_ #3 _process_counter_aux:Nn } #2 }
  }

\cs_new:Npn \__examzh_question_process_counter_aux:Nn #1#2
  {
    \tl_if_eq:nnTF {#2} { * }
      {
        % \Alph*
        \use:c { __examzh_question_save_ \cs_to_str:N #1 : }
          { \int_eval:n { \g__examzh_question_index_int - 1 } }
      }
      {
        % \Alph{...}
        \use:c { __examzh_question_save_ \cs_to_str:N #1 : }
          {#2}
      }
  }


% 处理 fillin/no-answer-type = counter 的 label
\tl_new:N \l__examzh_fillin_counters_commands_set_tl


\cs_new:Npn \__examzh_fillin_the_label:
  {
    \group_begin:
      % 定义计数器相关的命令函数
      \l__examzh_fillin_counters_commands_set_tl
      % 输出处理后的 label
      \l__examzh_fillin_label_tl
    \group_end:
  }

\NewDocumentCommand \AddFillinCounter { m m }
  {
    % 生成用户层命令
    \tl_put_right:Nn \l__examzh_fillin_counters_commands_set_tl
      { \__examzh_process_counter:NNn #1 #2 { fillin } }
    % 把核心函数存起来
    \cs_set_eq:cN { __examzh_fillin_save_ \cs_to_str:N #1 : } #2
    \cs_set_eq:cN { __examzh_fillin_save_ \cs_to_str:N #2 : } #2
  }

\AddFillinCounter \arabic \@arabic
\AddFillinCounter \alph   \@alph
\AddFillinCounter \Alph   \@Alph
\AddFillinCounter \roman  \@roman
\AddFillinCounter \Roman  \@Roman

\cs_new:Npn \__examzh_fillin_process_counter_aux:Nn #1#2
  {
    \tl_if_eq:nnTF {#2} { * }
      {
        % \Alph*
        \use:c { __examzh_fillin_save_ \cs_to_str:N #1 : }
          { \int_eval:n { \g__examzh_fillin_no_answer_counter_int - 1 } }
      }
      {
        % \Alph{...}
        \use:c { __examzh_fillin_save_ \cs_to_str:N #1 : }
          {#2}
      }
  }

% 使用中文字体直接输出 unicode 带圈数字
% \circlednumber 的参数既可以接受 LaTeX2e 的 <counter>，也可以直接接受 <intexpr>。
\NewDocumentCommand \circlednumber { s m }
  {
    \int_if_exist:cTF { c@ #2 }
      { \int_set_eq:Nc \l_tmpa_int { c@#2 } }
      { \int_set:Nn \l_tmpa_int { #2 } }
    \IfBooleanTF {#1}
      {
        \exp_args:Nx \__examzh_tikz_circled_number:n { \int_use:N \l_tmpa_int }
      }
      {
        \exp_args:Nx \__examzh_question_circled_number:n { \int_use:N \l_tmpa_int }
      }
  }
\newcommand{\quan}{\circlednumber}

\cs_new:Npn \__examzh_circled_number:nn #1#2
  {
    \int_set:Nn \l_tmpa_int {#1}
    \int_compare:nNnTF { \l_tmpa_int } = { 0 }
      { \int_set:Nn \l_tmpa_int { "24EA } }
      {
        \int_compare:nNnTF { \l_tmpa_int } < { 21 }
          { \int_add:Nn \l_tmpa_int { "245F } }
          {
            \int_compare:nNnTF { \l_tmpa_int } < { 36 }
              { \int_add:Nn \l_tmpa_int { "3250 } }
              {
                \int_compare:nNnTF { \l_tmpa_int } < { 51 }
                  { \int_add:Nn \l_tmpa_int { "32B0 } }
                  {
                    \msg_error:nnn { exam-zh / #2 }
                      { invalid-circled-number } { \int_use:N \l_tmpa_int }
                  }
              }
          }
      }
    \group_begin:
      \CJKfamily+ { }
      \symbol { \l_tmpa_int }
    \group_end:
  }

\msg_new:nnn { exam-zh / question } { invalid-circled-number }
{ Invalid~ circled~ number~ #1. }

\msg_new:nnn { exam-zh / fillin } { invalid-circled-number }
{ Invalid~ circled~ number~ #1. }

\cs_new:Npn \__examzh_question_circled_number:n #1
  { \__examzh_circled_number:nn {#1} { question } }
\cs_new:Npn \__examzh_fillin_circled_number:n #1
  { \__examzh_circled_number:nn {#1} { fillin } }

\AddQuestionCounter \circlednumber \__examzh_question_circled_number:n
\AddFillinCounter \circlednumber  \__examzh_fillin_circled_number:n

% tikz 绘制带圈数字
\fp_new:N \l__examzh_tikz_circled_number_xscale_fp   % 水平压缩系数
\fp_new:N \l__examzh_tikz_circled_number_yscale_fp   % 垂直压缩系数
\dim_new:N \l__examzh_tikz_circled_number_total_hegiht_dim   % 数字的总高度
\dim_new:N \l__examzh_tikz_circled_number_radius_dim     % 半径

\cs_new:Npn \__examzh_tikz_circled_number_aux:n #1
  {
    % 根据数字大小设置压缩系数
    \fp_set:Nn \l__examzh_tikz_circled_number_xscale_fp
      {
        \int_compare:nNnTF {#1} < { 10 } 
          { 0.9 }
          {
            \int_compare:nNnTF {#1} < { 100 }
              { 0.7 }
              { 0.5 }
          } 
      }
    \fp_set:Nn \l__examzh_tikz_circled_number_yscale_fp
      {
        \int_compare:nNnTF {#1} < { 10 } 
          { 0.9 }
          {
            \int_compare:nNnTF {#1} < { 100 }
              { 0.8 }
              { 0.6 }
          } 
      }
    % 获取数字的高度
    \hbox_set:Nn \l_tmpa_box {#1}
    \dim_set:Nn \l__examzh_tikz_circled_number_total_hegiht_dim
      { \box_ht:N \l_tmpa_box + \box_dp:N \l_tmpa_box  }
    % 设置圆的半径
    \dim_set:Nn \l__examzh_tikz_circled_number_radius_dim 
      { \dim_eval:n { \l__examzh_tikz_circled_number_total_hegiht_dim / 2 + 0.34 ex } }
    % 绘制
    \tikz [ baseline ]
      {
        \node
          [ inner~sep = 0pt, outer~sep = 0pt ]
          at (0, \dim_use:N \l__examzh_tikz_circled_number_total_hegiht_dim / 2 ) 
          {
            \hbox_set:Nn \l_tmpa_box
              {
                \int_compare:nNnTF {#1} > {9}
                  { \textbf {#1} }
                  {#1}
              }
            \makebox[0.35em][c]
              { 
                % \scalebox { \fp_use:N \l__examzh_tikz_circled_number_xscale_fp } 
                  % [ \fp_use:N \l__examzh_tikz_circled_number_yscale_fp ] 
                \box_scale:Nnn \l_tmpa_box
                  { \fp_use:N \l__examzh_tikz_circled_number_xscale_fp }
                  { \fp_use:N \l__examzh_tikz_circled_number_yscale_fp } 
                \box_use_drop:N \l_tmpa_box
              }
          };
        \draw (0, \l__examzh_tikz_circled_number_total_hegiht_dim / 2 )
          circle ( \l__examzh_tikz_circled_number_radius_dim );
      }
  }
\cs_new:Npn \__examzh_tikz_circled_number:n #1
  {
    \__examzh_tikz_circled_number_aux:n { \int_eval:n {#1} }
  }
\AddQuestionCounter \tikzcirclednumber \__examzh_tikz_circled_number:n
\AddFillinCounter \tikzcirclednumber \__examzh_tikz_circled_number:n

% 选择题括号
% 控制括号是否右对齐
\bool_new:N \l__examzh_paren_type_hfill_bool
% 右对齐时是否使用点线填充
\bool_new:N \l__examzh_paren_type_dotfill_bool
\keys_define:nn { exam-zh / paren }
  {
    show-answer .bool_set:N = \l__examzh_question_show_paren_answer_bool,
    text-color        .tl_set:N = \l__examzh_paren_text_color_tl ,
    % 是否显示选择题的括号
    show-paren          .bool_set:N = \l__examzh_question_show_paren_bool ,
    type .choice:,
    type / hfill .code:n =
      {
        \bool_set_true:N \l__examzh_paren_type_hfill_bool
        \bool_set_false:N \l__examzh_paren_type_dotfill_bool
      },
    type / dotfill .code:n =
      {
        \bool_set_true:N \l__examzh_paren_type_hfill_bool
        \bool_set_true:N \l__examzh_paren_type_dotfill_bool
      },
    type / none .code:n =
      {
        \bool_set_false:N \l__examzh_paren_type_hfill_bool
        \bool_set_false:N \l__examzh_paren_type_dotfill_bool
      },
  }
\keys_set:nn { exam-zh / paren }
  {
    show-answer = false,
    text-color  = black,
    show-paren  = true,
    type        = hfill
  }
\keys_define:nn { exam-zh }
  { paren .meta:nn = { exam-zh / paren } {#1} }

% TODO：在 paren 里面增加键值控制
\NewDocumentCommand \paren { s O { } }
  {
    % 如果开了 show answer 就默认 show paren 
    \bool_if:NT \l__examzh_question_show_paren_answer_bool
      { \bool_set_true:N \l__examzh_question_show_paren_bool }
    \bool_if:NT \l__examzh_question_show_paren_bool
      {
        % 使括号单独成行时居于右侧
        % \null -> \hbox{}
        % 𝖅𝖊𝖕𝖎𝖓𝖌 𝕷𝖊𝖊, [Mar 19, 2022 at 22:47:07]:
          % 这个写法是为了处理这样的情况：假设括号需要 3em 宽度，但是如果题干末尾只剩下了 2em 的空白，括号就必要另起一行，并且用 \hill 把括号推到最右侧
          % 所以中间用了两个 \hfill
          % 至于 \nobreak 和 \allowbreak 大概是为了能够同时处理「括号不换行」和「括号换行」两种情况
          % 这里参考 source2e 的 \@dottedtocline（目录的格式）
        % 控制是否 hfill 到行尾
        \bool_if:NT \l__examzh_paren_type_hfill_bool
          {
            \nobreak
            \bool_if:NTF \l__examzh_paren_type_dotfill_bool
              { \dotfill }
              { \hfill }
            \allowbreak
            \null \nobreak
            \bool_if:NTF \l__examzh_paren_type_dotfill_bool
              { \dotfill }
              { \hfill }
            \nobreak
          }
        \hbox:n
          {
            （
            % \hbox_to_wd:nn { 2em }
              % {
                \bool_if:NTF \l__examzh_question_show_paren_answer_bool
                  % { \hfill \__examzh_paren_print_answer:n {#1} \hfill }
                  {
                    \IfBlankTF{#2}
                      {
                        % 显示答案，但是 \paren 里没有输入答案
                        \kern 2em
                      }
                      {
                        \kern0.7em \__examzh_paren_print_answer:n {#2} \kern0.7em
                      }
                  }
                  {
                    % \paren* 表示不显示答案时是长宽度，\paren 表示不显示答案时是短宽度
                    \IfBooleanTF{#1}{ \kern 3em }{ \kern 2em }
                  }
              % }
            ） \kern -.4em
          }
      }
  }
% “打印出”答案内容 因为 show 被用作“显示与否”的含义了，所以此处用 print
\cs_new:Npn \__examzh_fillin_print_answer:n #1
  {
    % \group_begin:
      \tl_if_eq:NnF \l__examzh_fillin_text_color_tl { black }
        { \exp_args:NV \color \l__examzh_fillin_text_color_tl }
      #1
    % \group_end:
  }
\cs_new:Npn \__examzh_paren_print_answer:n #1
  {
    \group_begin:
      \tl_if_eq:NnF \l__examzh_paren_text_color_tl { black }
        { \exp_args:NV \color \l__examzh_paren_text_color_tl }
      #1
    \group_end:
  }


% fillin 的下划线样式控制
\str_new:N \l__examzh_fillin_type_str

% fillin type = paren 的括号类型
\bool_new:N \l__examzh_fillin_paren_banjiao_bool

% fillin 的 width 设置断行时是自动铺满行还是严格按照长度来
\bool_new:N \l__examzh_fillin_width_fill_bool

% 不显示答案时显示的类型
\str_new:N \l__examzh_fillin_no_answer_type_str

% no-answer-type = counter 的计数器
\int_new:N \g__examzh_fillin_no_answer_counter_int

% 不显示答案时，是否按答案的自然宽度生成占位。
\bool_new:N \l__examzh_fillin_width_auto_bool
\dim_new:N \l__examzh_fillin_F_width_dim
\dim_new:N \l__examzh_fillin_width_extra_dim
\dim_new:N \l__examzh_fillin_line_depth_dim

\keys_define:nn { exam-zh / fillin }
  {
    type .code:n = 
      {
        \str_set:Nn \l__examzh_fillin_type_str {#1}
      },
    show-answer .bool_set:N = \l__examzh_question_show_fillin_answer_bool,
    width .code:n =
      {
        \str_if_eq:nnTF {#1} { auto }
          { \bool_set_true:N \l__examzh_fillin_width_auto_bool }
          {
            \bool_set_false:N \l__examzh_fillin_width_auto_bool
            \dim_set:Nn \l__examzh_fillin_F_width_dim {#1}
          }
      },
    width-extra .dim_set:N = \l__examzh_fillin_width_extra_dim,
    width-type .choice:,
    width-type / fill .code:n =
      { \bool_set_true:N \l__examzh_fillin_width_fill_bool },
    width-type / normal .code:n =
      { \bool_set_false:N \l__examzh_fillin_width_fill_bool },
    box-color .tl_set:N = \l__examzh_fillin_box_color_tl,
    text-color .tl_set:N = \l__examzh_fillin_text_color_tl,
    no-answer-type .choices:nn =
      { blacktriangle, counter, none, hidden }
      { \str_set:Nx \l__examzh_fillin_no_answer_type_str { \l_keys_choice_tl } },
    no-answer-counter-index .int_gset:N = \g__examzh_fillin_no_answer_counter_int,
    no-answer-counter-label .tl_set:N = \l__examzh_fillin_label_tl,
    paren-type .choice:,
    paren-type / banjiao .code:n = 
      { \bool_set_true:N \l__examzh_fillin_paren_banjiao_bool },
    paren-type / quanjiao .code:n = 
      { \bool_set_false:N \l__examzh_fillin_paren_banjiao_bool },
    depth .dim_set:N = \l__examzh_fillin_line_depth_dim
  }
\keys_set:nn { exam-zh / fillin }
  {
    type                     = line,
    show-answer              = false,
    width                    = 3em,
    width-extra              = 0pt,
    box-color                = black,
    text-color               = black,
    no-answer-type           = blacktriangle,
    no-answer-counter-index  = 1,
    no-answer-counter-label  = \arabic*,
    paren-type               = banjiao,
    width-type               = normal,
    depth                    = 0.4em
  }

\keys_define:nn { exam-zh }
  { fillin .meta:nn = { exam-zh / fillin } {#1} }


\dim_new:N \l__examzh_question_answer_depth_dim
\dim_new:N \l__examzh_fillin_effective_line_depth_dim
\dim_new:N \l__examzh_fillin_following_punctuation_width_dim
\box_new:N \l__examzh_fillin_following_punctuation_box
\bool_new:N \l__examzh_fillin_following_punctuation_captured_bool
\tl_new:N \l__examzh_fillin_following_punctuation_tl
\tl_new:N \l__examzh_fillin_star_tl
\tl_new:N \l__examzh_fillin_keys_tl
\tl_new:N \l__examzh_fillin_answer_tl
\tl_new:N \l__examzh_fillin_resolved_answer_tl

\cs_new_protected:Npn \__examzh_fillin_reserve_following_punctuation:N #1
  {
    \hbox_set:Nn \l__examzh_fillin_following_punctuation_box {#1}
    \dim_set:Nn \l__examzh_fillin_following_punctuation_width_dim
      { \box_wd:N \l__examzh_fillin_following_punctuation_box }
    % 全角右标点的右侧留白由 xeCJK 悬挂到行外，只预留实际占用宽度。
    \__xeCJK_punct_if_right:NT #1
      {
        \xeCJK_get_punct_bounds:NN \c__xeCJK_right_tl #1
        \dim_sub:Nn \l__examzh_fillin_following_punctuation_width_dim
          {
            \__xeCJK_use_punct_dim:nNN
              { margin } \c__xeCJK_right_tl #1
          }
      }
  }

\cs_new_protected:Npn \__examzh_fillin_set_following_punctuation:N #1
  {
    \tl_set:Nn \l__examzh_fillin_following_punctuation_tl {#1}
    \__examzh_fillin_reserve_following_punctuation:N #1
  }

\cs_new_protected:Npn \__examzh_fillin_set_following_punctuation_width:
  {
    \dim_zero:N \l__examzh_fillin_following_punctuation_width_dim
    \tl_clear:N \l__examzh_fillin_following_punctuation_tl
    \token_case_meaning:Nn \l_peek_token
      {
        ,  { \__examzh_fillin_set_following_punctuation:N , }
        .  { \__examzh_fillin_set_following_punctuation:N . }
        ;  { \__examzh_fillin_set_following_punctuation:N ; }
        :  { \__examzh_fillin_set_following_punctuation:N : }
        !  { \__examzh_fillin_set_following_punctuation:N ! }
        ?  { \__examzh_fillin_set_following_punctuation:N ? }
        )  { \__examzh_fillin_set_following_punctuation:N ) }
        ]  { \__examzh_fillin_set_following_punctuation:N ] }
        ， { \__examzh_fillin_set_following_punctuation:N ， }
        。 { \__examzh_fillin_set_following_punctuation:N 。 }
        ； { \__examzh_fillin_set_following_punctuation:N ； }
        ： { \__examzh_fillin_set_following_punctuation:N ： }
        ！ { \__examzh_fillin_set_following_punctuation:N ！ }
        ？ { \__examzh_fillin_set_following_punctuation:N ？ }
        、 { \__examzh_fillin_set_following_punctuation:N 、 }
        ） { \__examzh_fillin_set_following_punctuation:N ） }
        》 { \__examzh_fillin_set_following_punctuation:N 》 }
        」 { \__examzh_fillin_set_following_punctuation:N 」 }
        』 { \__examzh_fillin_set_following_punctuation:N 』 }
        】 { \__examzh_fillin_set_following_punctuation:N 】 }
        〕 { \__examzh_fillin_set_following_punctuation:N 〕 }
        〗 { \__examzh_fillin_set_following_punctuation:N 〗 }
        〙 { \__examzh_fillin_set_following_punctuation:N 〙 }
        〛 { \__examzh_fillin_set_following_punctuation:N 〛 }
        ’  { \__examzh_fillin_set_following_punctuation:N ’ }
        ”  { \__examzh_fillin_set_following_punctuation:N ” }
      }
  }

\cs_new_protected:Npn \__examzh_fillin_capture_following_punctuation:N #1
  {
    \peek_meaning_remove:NTF #1
      {
        \bool_set_true:N \l__examzh_fillin_following_punctuation_captured_bool
        \tl_set:Nn \l__examzh_fillin_following_punctuation_tl {#1}
        \__examzh_fillin_typeset_prepared:
      }
      { \__examzh_fillin_typeset_prepared: }
  }

\prg_new_conditional:Npnn \__examzh_fillin_answer_should_break: { TF }
  {
    \str_case:VnTF \l__examzh_fillin_type_str
      {
        { line  } { }
        { paren } { }
        { blank } { }
      }
      {
        \dim_compare:nNnTF { \box_wd:N \l_tmpa_box } > { \linewidth }
          { \prg_return_true: }
          { \prg_return_false: }
      }
      { \prg_return_false: }
  }

\cs_new_protected:Npn \__examzh_fillin_set_effective_line_depth:
  {
    \dim_set_eq:NN
      \l__examzh_fillin_effective_line_depth_dim
      \l__examzh_fillin_line_depth_dim
    \dim_compare:nNnT
      { \l__examzh_question_answer_depth_dim + 0.2em }
      > { \l__examzh_fillin_effective_line_depth_dim }
      {
        \dim_set:Nn \l__examzh_fillin_effective_line_depth_dim
          { \l__examzh_question_answer_depth_dim + 0.2em }
      }
  }

\cs_new_protected:Npn \__examzh_fillin_set_auto_width:n #1
  {
    \bool_if:NT \l__examzh_fillin_width_auto_bool
      {
        \tl_if_blank:nTF {#1}
          { \dim_set:Nn \l__examzh_fillin_F_width_dim { 3em } }
          {
            \hbox_set:Nn \l_tmpa_box
              { \__examzh_fillin_print_answer:n {#1} }
            \dim_set:Nn \l__examzh_fillin_F_width_dim
              { \box_wd:N \l_tmpa_box + \l__examzh_fillin_width_extra_dim }
          }
      }
  }

\cs_new_protected:Npn \__examzh_fillin_typeset_prepared:
  {
    \__examzh_fillin_typeset_prepared:VVV
      \l__examzh_fillin_star_tl
      \l__examzh_fillin_keys_tl
      \l__examzh_fillin_answer_tl
  }

\cs_new_protected:Npn \__examzh_fillin_capture_following_punctuation:
  {
    \bool_set_false:N \l__examzh_fillin_following_punctuation_captured_bool
    \bool_if:NTF \l__examzh_fillin_width_auto_bool
      {
        \bool_if:NTF \l__examzh_question_show_fillin_answer_bool
          { \__examzh_fillin_typeset_prepared: }
          {
            \str_if_eq:VnTF \l__examzh_fillin_type_str { line }
              {
                \str_if_eq:VnTF \l__examzh_fillin_no_answer_type_str { none }
                  {
                    \dim_compare:nNnTF
                      {
                        \l__examzh_fillin_F_width_dim
                        + \l__examzh_fillin_following_punctuation_width_dim
                      } < { \linewidth }
                      {
                        \tl_if_empty:NTF \l__examzh_fillin_following_punctuation_tl
                          { \__examzh_fillin_typeset_prepared: }
                          {
                            \exp_args:NV
                              \__examzh_fillin_capture_following_punctuation:N
                              \l__examzh_fillin_following_punctuation_tl
                          }
                      }
                      { \__examzh_fillin_typeset_prepared: }
                  }
                  { \__examzh_fillin_typeset_prepared: }
              }
              { \__examzh_fillin_typeset_prepared: }
          }
      }
      { \__examzh_fillin_typeset_prepared: }
  }

\cs_new_protected:Npn \__examzh_fillin_typeset:nnn #1#2#3
  {
    \IfNoValueTF {#3}
      {
        \tl_set:Nn \l__examzh_fillin_resolved_answer_tl {#2}
        \__examzh_fillin_set_auto_width:n {#2}
      }
      {
        \keys_set:nn { exam-zh / fillin } {#2}
        \tl_set:Nn \l__examzh_fillin_resolved_answer_tl {#3}
        \__examzh_fillin_set_auto_width:n {#3}
      }
    \__examzh_fillin_set_following_punctuation_width:
    \__examzh_fillin_capture_following_punctuation:
  }
\cs_new_protected:Npn \__examzh_fillin_typeset_prepared:nnn #1#2#3
  {
    \IfNoValueTF {#3}
      {
        \bool_if:NTF \l__examzh_question_show_fillin_answer_bool
          {
            \IfBooleanTF {#1}
              { \__examzh_fillin_breakline:n {#2} }
              { \__examzh_fillin:n {#2} }
          }
          {
            \IfBooleanTF {#1}
              { \__examzh_fillin_no_answer_breakable_typeset: }
              { \__examzh_fillin_no_answer_unbreakable_typeset: }
          }
      }
      {
        \bool_if:NTF \l__examzh_question_show_fillin_answer_bool
          {
            \IfBooleanTF {#1}
              { \__examzh_fillin_breakline:n {#3} }
              { \__examzh_fillin:n {#3} }
          }
          {
            \IfBooleanTF {#1}
              { \__examzh_fillin_no_answer_breakable_typeset: }
              { \__examzh_fillin_no_answer_unbreakable_typeset: }
          }
      }
    \bool_if:NTF \l__examzh_fillin_following_punctuation_captured_bool
      { \space }
      {
        \bool_if:NTF \l__examzh_fillin_width_auto_bool
          {
            \dim_compare:nNnTF
              { \l__examzh_fillin_following_punctuation_width_dim } > { 0pt }
              { \nobreak }
              { \space }
          }
          { \space }
      }
    \group_end:
  }
\cs_generate_variant:Nn \__examzh_fillin_typeset:nnn { VVV }
\cs_generate_variant:Nn \__examzh_fillin_typeset_prepared:nnn { VVV }

\cs_new_protected:Npn \__examzh_fillin_typeset_after_peek:
  {
    \__examzh_fillin_typeset:VVV
      \l__examzh_fillin_star_tl
      \l__examzh_fillin_keys_tl
      \l__examzh_fillin_answer_tl
  }

% 填空命令
% \fillin \fillin[] \fillin[][] 在 show-answer = false 的情况下
% no-answer-type = blacktriangle 就显示黑色三角形
% no-answer-type = counter ：计数器（设计来源于完形填空）
% no-answer-type = none ：不显示
\NewDocumentCommand \fillin { s O{} o }
  {
    \group_begin:
      \tl_set:Nn \l__examzh_fillin_star_tl {#1}
      \tl_set:Nn \l__examzh_fillin_keys_tl {#2}
      \tl_set:Nn \l__examzh_fillin_answer_tl {#3}
      \peek_remove_spaces:n
        { \peek_after:Nw \__examzh_fillin_typeset_after_peek: }
  }
\msg_new:nnn { exam-zh / fillin } { no-such-noanswertype }
  {
    There~is~no~such~noanswertype~named~#1!\\
    Please~read~the~manual~carefully!
  }
\cs_new:Npn \__examzh_fillin_no_answer_unbreakable_typeset:
  {
    \str_case:VnF \l__examzh_fillin_no_answer_type_str
      {
        { blacktriangle } { \__examzh_fillin_no_answer_typeset_blacktriangle: }
        { counter } { \__examzh_fillin_no_answer_typeset_counter: }
        { none }
          {
            \bool_if:NTF \l__examzh_fillin_width_auto_bool
              { \__examzh_fillin_output_breakable_F: }
              {
                \dim_compare:nNnTF { \l__examzh_fillin_F_width_dim } < { \linewidth }
                  { \__examzh_fillin_output_unbreakable_F: }
                  { \__examzh_fillin_output_breakable_F: }
              }
          }
      }
      {
        \msg_error:nnx { exam-zh / fillin } { no-such-noanswertype }
          { \l__examzh_fillin_no_answer_type_str }
      }
  }
\cs_new:Npn \__examzh_fillin_no_answer_breakable_typeset:
  {
    \str_case:VnF \l__examzh_fillin_no_answer_type_str
      {
        { blacktriangle } { \__examzh_fillin_no_answer_typeset_blacktriangle: }
        { counter } { \__examzh_fillin_no_answer_typeset_counter: }
        { none } { \__examzh_fillin_output_breakable_F: }
      }
      {
        \msg_error:nnx { exam-zh / fillin } { no-such-noanswertype }
          { \l__examzh_fillin_no_answer_type_str }
      }
  }
\cs_new:Npn \__examzh_fillin_no_answer_typeset_blacktriangle:
  {
    \__examzh_fillin_without_judge:n { \__examzh_fillin_blacktriangle: }
  }
\cs_new:Npn \__examzh_fillin_no_answer_typeset_counter:
  {
    \int_gincr:N \g__examzh_fillin_no_answer_counter_int
    \__examzh_fillin_without_judge:n
      { \__examzh_fillin_the_label: }
      % { \int_eval:n { \g__examzh_fillin_no_answer_counter_int - 1 } }
  }
\cs_new:Npn \__examzh_fillin_without_judge:n #1
  {
    % \ULdepth 是 \uline 的下划线的深度
    \dim_set:Nn \ULdepth { 0.3em }
    % lazy 版本是指需要判断时才去获取当前用于判断的 bool 值 
    % 而不是类似于“提前展开”，和项子越在 LaTeX3 的 b站视频里讲到的 lazy evaluation 想法相同
    \hbox_set:Nn \l_tmpa_box { \__examzh_fillin_print_answer:n {#1} }
    \dim_set:Nn \l__examzh_question_answer_depth_dim
      { \box_dp:N \l_tmpa_box }
    \__examzh_fillin_output_T:
  }
\cs_new:Npn \__examzh_fillin:n #1
  {
    % \ULdepth 是 \uline 的下划线的深度
    \dim_set:Nn \ULdepth { 0.3em }
    % lazy 版本是指需要判断时才去获取当前用于判断的 bool 值 
    % 而不是类似于“提前展开”，和项子越在 LaTeX3 的 b站视频里讲到的 lazy evaluation 想法相同
    \bool_lazy_and:nnTF
      { \bool_if_p:N \l__examzh_question_show_fillin_answer_bool }
      { \bool_not_p:n { \tl_if_empty_p:n {#1} } }
      {
        \hbox_set:Nn \l_tmpa_box { \__examzh_fillin_print_answer:n {#1} }
        \dim_set:Nn \l__examzh_question_answer_depth_dim
          { \box_dp:N \l_tmpa_box }
        \__examzh_fillin_answer_should_break:TF
          {
            \tl_set:Nn \l_tmpa_tl { \__examzh_fillin_print_answer:n {#1} }
            \__examzh_fillin_set_effective_line_depth:
            \__examzh_fillin_output_breakline_T:
          }
          { \__examzh_fillin_output_T: }
      }
      { 
        \__examzh_fillin_output_unbreakable_F:
      }
  }
\cs_new:Npn \__examzh_fillin_breakline:n #1
  {
    \bool_lazy_and:nnTF
      { \bool_if_p:N \l__examzh_question_show_fillin_answer_bool }
      { \bool_not_p:n { \tl_if_empty_p:n {#1} } }
      {
        \hbox_set:Nn \l_tmpa_box { \__examzh_fillin_print_answer:n {#1} }
        \dim_set:Nn \l__examzh_question_answer_depth_dim
          { \box_dp:N \l_tmpa_box }
        \tl_set:Nn \l_tmpa_tl { \__examzh_fillin_print_answer:n {#1} }
        \__examzh_fillin_set_effective_line_depth:
        \__examzh_fillin_output_breakline_T:
      }
      { 
        \__examzh_fillin_output_breakable_F:
      }
  }
\msg_new:nnn { exam-zh } { no-fillin-type }
  {
    There~is~no~type~of~\fillin~named~#1!\\
    Please~read~the~manual~for~more~details.
  }
\cs_new:Npn \__examzh_fillin_output_T:
  {
    \str_case:VnF \l__examzh_fillin_type_str
      {
        { line } { \__examzh_fillin_uline_T: }
        { paren } { \__examzh_fillin_paren_T: }
        { circle } { \__examzh_fillin_circle_T: }
        { blank } { \__examzh_fillin_blank_T: }
        { rectangle } { \__examzh_fillin_rectangle_T: }
      }
      {
        \msg_error:nnx { exam-zh } { no-fillin-type }
          { \l__examzh_fillin_type_str }
      }
  }
\cs_new:Npn \__examzh_fillin_output_breakline_T:
  {
    \str_case:VnF \l__examzh_fillin_type_str
      {
        { line } { \__examzh_fillin_uline_breakline_T: }
        { paren } { \__examzh_fillin_paren_breakline_T: }
        { blank } { \__examzh_fillin_blank_breakline_T: }
      }
      {
        \msg_error:nnx { exam-zh } { no-breakable-fillin-type }
          { \l__examzh_fillin_type_str }
      }
  }
\msg_new:nnn { exam-zh } { no-breakable-fillin-type }
  {
    The~type~:~#1~ cannot~be~used~in~breakable~fillin~cmd.
  }
\cs_new:Npn \__examzh_fillin_output_breakable_F:
  {
    \str_case:VnF \l__examzh_fillin_type_str
      {
        { line } { \__examzh_fillin_uline_breakable_F: }
        { paren } { \__examzh_fillin_paren_breakable_F: }
        { circle } { \__examzh_fillin_circle_F: }
        { blank } { \__examzh_fillin_blank_breakable_F: }
        { rectangle } { \__examzh_fillin_rectangle_F: }
      }
      {
        \msg_error:nnx { exam-zh } { no-fillin-type }
          { \l__examzh_fillin_type_str }
      }
  }
\cs_new:Npn \__examzh_fillin_output_unbreakable_F:
  {
    \str_case:VnF \l__examzh_fillin_type_str
      {
        { line } { \__examzh_fillin_uline_unbreakable_F: }
        { paren } { \__examzh_fillin_paren_unbreakable_F: }
        { circle } { \__examzh_fillin_circle_F: }
        { blank } { \__examzh_fillin_blank_unbreakable_F: }
        { rectangle } { \__examzh_fillin_rectangle_F: }
      }
      {
        \msg_error:nnx { exam-zh } { no-fillin-type }
          { \l__examzh_fillin_type_str }
      }
  }
\cs_new:Npn \__examzh_fillin_uline_T:
  {
    % \uline
    \CJKunderline*
      [ depth = \l__examzh_fillin_line_depth_dim ]
      {
        \hspace* { 0.5em plus .5em minus .5em }
        \dim_compare:nNnTF { \l__examzh_question_answer_depth_dim } > { 0.2em }
          {
            \dim_sub:Nn \l__examzh_question_answer_depth_dim { 0.2em }
            \raisebox { \l__examzh_question_answer_depth_dim }
              { \box_use_drop:N \l_tmpa_box }
          }
          { \box_use_drop:N \l_tmpa_box }
        \hspace* { 0.5em plus .5em minus .5em }
      }
  }
\cs_new:Npn \__examzh_fillin_uline_breakable_F:
  {
    % 自动宽度模式保留答案本身的 CJK/数学断点，只隐藏文字而保持其自然宽度。
    \bool_if:NTF \l__examzh_fillin_width_auto_bool
      {
        \tl_if_blank:VTF \l__examzh_fillin_resolved_answer_tl
          {
            \__examzh_fillin_breakable_hspace:NN \CJKunderline \prg_do_nothing:
            \__examzh_fillin_append_following_punctuation:
          }
          { \__examzh_fillin_uline_hidden_answer_F: }
      }
      { \__examzh_fillin_breakable_hspace:NN \CJKunderline \allowbreak }
  }
\cs_new:Npn \__examzh_fillin_append_following_punctuation:
  {
    \bool_if:NT \l__examzh_fillin_following_punctuation_captured_bool
      { \tl_use:N \l__examzh_fillin_following_punctuation_tl }
  }
\cs_new:Npn \__examzh_fillin_uline_hidden_answer_F:
  {
    \__examzh_fillin_break_before_single_character:
    \CJKunderline*[hidden=true]
      {
        \hspace*
          {
            0.5\l__examzh_fillin_width_extra_dim
            plus 0.5\l__examzh_fillin_width_extra_dim
            minus 0.5\l__examzh_fillin_width_extra_dim
          }
        \tl_use:N \l__examzh_fillin_resolved_answer_tl
        \hspace*
          {
            0.5\l__examzh_fillin_width_extra_dim
            plus 0.5\l__examzh_fillin_width_extra_dim
            minus 0.5\l__examzh_fillin_width_extra_dim
          }
      }
    \bool_if:NT \l__examzh_fillin_following_punctuation_captured_bool
      { \tl_use:N \l__examzh_fillin_following_punctuation_tl }
  }
\cs_new:Npn \__examzh_fillin_uline_unbreakable_F:
  {
    \unskip
    \hspace* { 0.5em plus .5em minus .5em }
    \uline { \hspace* { \l__examzh_fillin_F_width_dim } }
    \ignorespaces
  }
% \cs_new:Nn \__examzh_fillin_uline:
  % {
    % \bgroup
    %   \color{ \l__examzh_fillin_text_color_tl } 
    %   \markoverwith{\textcolor{black}{\rule[-0.7ex]{2pt}{0.4pt}}}
    %   \ULon
% xeCJKfntef.sty
% xeCJK: 修复下划线中数学公式的错误处理
% https://github.com/CTeX-org/ctex-kit/commit/ad44c6674bb377653544349f23b7c629bc9e4677
\RenewDocumentCommand \CJKunderline { s t- s o }
  {
    \xeCJK_ulem_group_begin:
      \xeCJK_fntef_boot:nnNNNn { underline } { uline } #1#2#3 {#4}
      \xeCJK_fntef_initial:nnn
        { \l__xeCJK_uline_depth_tl }
        { \l__xeCJK_uline_sep_tl }
        {
          \l__xeCJK_uline_format_tl
          \tex_vrule:D
            height \dim_eval:n { \l__xeCJK_uline_thickness_tl }
            depth \c_zero_dim
            width .2em
        }
      % 给 CJKunderline 加了颜色控制
      \color { \l__examzh_fillin_text_color_tl }
      \xeCJK_ulem_on:n
  }
  % }
\cs_new:Npn \__examzh_fillin_uline_breakline_T:
  {
    \CJKunderline*
      [ depth = \l__examzh_fillin_effective_line_depth_dim ]
    % \uline
    % \__examzh_fillin_uline:
      {
        \hspace* { 0.5em plus .5em minus .5em }
        % \color{ \l__examzh_fillin_text_color_tl } 
        \l_tmpa_tl
        % 答案很长时，不能完全显示，答案很长时，不能完全显示
        \hspace* { 0.5em plus .5em minus .5em }
      }
  }
\cs_new:Npn \__examzh_fillin_paren_T:
  {
    \unskip
    \bool_if:NTF \l__examzh_fillin_paren_banjiao_bool
      {
        (
          \hspace* { 0.5em plus .5em minus .5em }
          \group_begin:
            \box_use_drop:N \l_tmpa_box
          \group_end:
          \hspace* { 0.5em plus .5em minus .5em }
        )
      }
      {
        （
          \hspace* { 0.5em plus .5em minus .5em }
          \group_begin:
            \box_use_drop:N \l_tmpa_box
          \group_end:
          \hspace* { 0.5em plus .5em minus .5em }
        ）
      }
    \ignorespaces
  }
\cs_new:Npn \__examzh_fillin_paren_breakline_T:
  {
    \unskip
    \bool_if:NTF \l__examzh_fillin_paren_banjiao_bool
      {
        (
          \hspace* { 0.5em plus .5em minus .5em }
          \group_begin:
            \l_tmpa_tl
          \group_end:
          \hspace* { 0.5em plus .5em minus .5em }
        )
      }
      {
        （
          \hspace* { 0.5em plus .5em minus .5em }
          \group_begin:
            \l_tmpa_tl
          \group_end:
          \hspace* { 0.5em plus .5em minus .5em }
        ）
      }
    \ignorespaces
  }
\box_new:N \c__examzh_banjiao_right_brace_box
\box_new:N \c__examzh_quanjiao_right_brace_box
\hbox_set:Nn \c__examzh_banjiao_right_brace_box { ) }
\hbox_set:Nn \c__examzh_quanjiao_right_brace_box { ） }
\dim_const:Nn \c__examzh_banjiao_right_brace_width_dim  % (
  { \box_wd:N \c__examzh_banjiao_right_brace_box }
\dim_const:Nn \c__examzh_quanjiao_right_brace_width_dim  % (
  { \box_wd:N \c__examzh_quanjiao_right_brace_box }
\cs_new:Npn \__examzh_fillin_paren_breakable_F:
  {
    \unskip
    \hspace* { 0.5em plus .5em minus .5em }
    \bool_if:NTF \l__examzh_fillin_paren_banjiao_bool
      {
        ( \__examzh_fillin_breakable_hspace:NN \use:n \nobreak \kern-\c__examzh_banjiao_right_brace_width_dim )
        \bool_if:NF \l__examzh_fillin_width_auto_bool { \allowbreak }
      }
      {
        （ \__examzh_fillin_breakable_hspace:NN \use:n \nobreak \kern-\c__examzh_quanjiao_right_brace_width_dim ）
        \bool_if:NF \l__examzh_fillin_width_auto_bool { \allowbreak }
      }
    \ignorespaces
  }
\cs_new:Npn \__examzh_fillin_paren_unbreakable_F:
  {
    \unskip
    \hspace* { 0.5em plus .5em minus .5em }
    \bool_if:NTF \l__examzh_fillin_paren_banjiao_bool
      {
        ( \hspace* { \l__examzh_fillin_F_width_dim } )
      }
      {
        （ \hspace* { \l__examzh_fillin_F_width_dim } ）
      }
    \ignorespaces
  }
\cs_new:Npn \__examzh_fillin_blank_T:
  {
    \unskip
    \hspace* { 0.5em plus .5em minus .5em }
    \group_begin:
      \box_use_drop:N \l_tmpa_box
    \group_end: 
    \ignorespaces
  }
\cs_new:Npn \__examzh_fillin_blank_breakline_T:
  {
    \unskip
    \hspace* { 0.5em plus .5em minus .5em }
    \group_begin:
      \l_tmpa_tl 
    \group_end:
    \ignorespaces
  }
\cs_new:Npn \__examzh_fillin_blank_breakable_F:
  {
    % \hspace* { \l__examzh_fillin_F_width_dim }
    \bool_if:NTF \l__examzh_fillin_width_auto_bool
      { \__examzh_fillin_breakable_hspace:NN \use:n \prg_do_nothing: }
      { \__examzh_fillin_breakable_hspace:NN \use:n \allowbreak }
  }
\cs_new:Npn \__examzh_fillin_blank_unbreakable_F:
  {
    \hspace* { \l__examzh_fillin_F_width_dim }
    % \__examzh_fillin_breakable_hspace:NN \use:n \allowbreak
  }
\tikzset
  {
    fillin-circle/.style = 
      {
        rounded~rectangle~west~arc = convex,
        draw, rounded~rectangle,
        color = \l__examzh_fillin_box_color_tl, text = \l__examzh_fillin_text_color_tl
      }
  }
\cs_new:Npn \__examzh_fillin_circle_T:
  {
    \hspace* { .5em minus .5em }
    \tikz[baseline=-3pt]
      {
        \node [fillin-circle] at (0,0) 
          { \box_use_drop:N \l_tmpa_box };
      }
    \hspace* { .5em minus .5em }
  }
\cs_new:Npn \__examzh_fillin_circle_F:
  {
    \hspace* { 0.5em plus .5em minus .5em }
    \tikz[baseline=-3pt]
      {
        \node [fillin-circle] at (0,0) 
          { \phantom{t} };
      }
    \hspace* { 0.5em plus .5em minus .5em }
  }
\cs_new:Npn \__examzh_fillin_rectangle_T:
  {
    \hspace* { .5em minus .5em }
    \begin{tikzpicture}[baseline = -3pt]
      \node[draw, color = \l__examzh_fillin_box_color_tl, text = \l__examzh_fillin_text_color_tl] 
        { \box_use_drop:N \l_tmpa_box };
    \end{tikzpicture}
    \hspace* { .5em minus .5em }
  }
\cs_new:Npn \__examzh_fillin_rectangle_F:
  {
    \hspace* { 0.5em plus .5em minus .5em }
    \begin{tikzpicture}[baseline = -3pt]
      \node[draw, color = \l__examzh_fillin_box_color_tl, text = \l__examzh_fillin_text_color_tl] 
        { \phantom{a} };
    \end{tikzpicture}
    \hspace* { 0.5em plus .5em minus .5em }
  }

% 通过循环来达到自动断行的空白下划线
\cs_generate_variant:Nn \dim_sub:Nn { NV }
\cs_generate_variant:Nn \dim_add:Nn { NV }
\cs_generate_variant:Nn \dim_set:Nn { NV, Nx }
% 用来检测是否处于 list 环境中
\bool_new:N \l__if_list_bool
\int_new:N \l__list_depth_int
\cs_generate_variant:Nn \dim_set:Nn { Nx }
\AddToHook { cmd / list / after }
  {
    \bool_set_true:N \l__if_list_bool
    \int_incr:N \l__list_depth_int
    \dim_if_exist:cF { l__list_leftmargin_ \int_to_roman:n { \l__list_depth_int } _dim }
      {
        \dim_new:c { l__list_leftmargin_ \int_to_roman:n { \l__list_depth_int } _dim }
      }
    % 用来储存相应层级的 \leftmargin 值
    \dim_set_eq:cN { l__list_leftmargin_ \int_to_roman:n { \l__list_depth_int } _dim } \leftmargin
  }
\AddToHook { cmd / endlist  / before } 
  { \int_zero:N \l__list_depth_int }

\cs_new_protected:Npn \__examzh_fillin_adjust_paragraph_start_width:N #1
  {
    \mode_if_vertical:T
      { \dim_sub:Nn #1 { \parindent } }
  }

% 统一计算当前位置到当前栏末的可用宽度。linegoal 在双栏和嵌套列表中
% 的坐标基准不同，集中修正后，长填空和自动宽度填空共用同一套算法。
\cs_new_protected:Npn \__examzh_fillin_set_remaining_width:N #1
  {
    \dim_set_eq:NN #1 \linegoal
    \legacy_if:nT { @twocolumn }
      {
        \dim_compare:nNnT
          {#1} < { \linewidth - \columnwidth - 0.5\columnsep }
          { \dim_add:Nn #1 { \columnwidth + \columnsep } }
      }
    \bool_if:NT \l__if_list_bool
      {
        \int_step_inline:nn { \l__list_depth_int }
          {
            \dim_add:Nn #1
              { \dim_use:c { l__list_leftmargin_ \int_to_roman:n { ##1 } _dim } }
          }
      }
    \bool_if:NT \l__examzh_fillin_width_auto_bool
      { \__examzh_fillin_adjust_paragraph_start_width:N #1 }
    \dim_set:Nn #1 { \dim_max:nn { 0pt } {#1} }
  }

\cs_new_protected:Npn \__examzh_fillin_break_before_single_character:
  {
    \bool_if:NT \l__examzh_fillin_width_auto_bool
      {
        \dim_compare:nNnT
          { \l__examzh_fillin_F_width_dim } > { 2em }
          {
            \__examzh_fillin_set_remaining_width:N \l_tmpb_dim
            \dim_compare:nNnT { \l_tmpb_dim } < { 2em }
              {
                \dim_compare:nNnT { \l_tmpb_dim } > { 0pt }
                  { \newline }
              }
          }
      }
  }

\cs_new:Npn \__examzh_fillin_breakable_hspace:NN #1#2
  % #1: CJKunderline / use:n
  % #2: \allowbreak
  {
    \__examzh_fillin_set_remaining_width:N \l_tmpb_dim
    % 比较 \l__examzh_fillin_F_width_dim 和 linegoal
    \dim_compare:nNnTF { \l__examzh_fillin_F_width_dim } > { \l_tmpb_dim }
      {
        % 超过 linegoal 就排一段 linegoal，然后 \l__examzh_fillin_F_width_dim 减去 linegoal 长度
        \dim_set:NV \l_tmpa_dim \l_tmpb_dim
        #1 { \hspace { \l_tmpb_dim } }
        \dim_sub:NV \l__examzh_fillin_F_width_dim \l_tmpb_dim
        \dim_while_do:nNnn { \l__examzh_fillin_F_width_dim } > { \linewidth }
          {
            % 循环：\l__examzh_fillin_F_width_dim 和 \linewidth 比较，大的话就排一个，然后减掉 linewidth
            \\ #1 { \hspace* { \linewidth } }
            \dim_sub:Nn \l__examzh_fillin_F_width_dim { \linewidth }
          }
        % \\ #1 { \hspace* { \linewidth } }
        \dim_compare:nNnT { \l__examzh_fillin_F_width_dim } < { \linewidth }
          { 
            % 最后一行是否 fill
            \bool_if:NTF \l__examzh_fillin_width_fill_bool
              {
                \\ #1 { \hspace* { \linewidth } } 
              }
              {
                \\ #1 { \hspace* { \l__examzh_fillin_F_width_dim } } 
              }
          }
      }
      {
        #1 { \hspace* { \l__examzh_fillin_F_width_dim } }
      }
    #2
  }


\dim_new:N \l__examzh_blacktriangle_length_dim
\dim_set:Nn \l__examzh_blacktriangle_length_dim { .7em }
\cs_new:Npn \__examzh_fillin_blacktriangle:
  {
    \tikz[rounded~corners=0.5pt,baseline=0pt]
      {
        \fill[] (0,0) -- ++(60\c_colon_str \l__examzh_blacktriangle_length_dim) -- ++(-60\c_colon_str \l__examzh_blacktriangle_length_dim) -- cycle ;
      }
  }

\str_new:N \l__examzh_solution_blank_type_str
\bool_new:N \g__examzh_solution_show_bool
\bool_new:N \g__examzh_solution_show_move_bool
% 对应答案移动到对应题目的后面
\bool_new:N \g__examzh_solution_show_move_separately_bool
\keys_define:nn { exam-zh / solution }
  {
    % show-solution .bool_set:N = \g__examzh_solution_show_bool,
    show-solution .choice:,
    show-solution / hide .code:n =
      {
        \bool_gset_false:N \g__examzh_solution_show_bool
      },
    show-solution / show-stay .code:n =
      {
        \bool_gset_true:N \g__examzh_solution_show_bool
        \bool_gset_false:N \g__examzh_solution_show_move_bool
      },
    show-solution / show-move .code:n =
      {
        \bool_gset_true:N \g__examzh_solution_show_bool
        \bool_gset_true:N \g__examzh_solution_show_move_bool
      },
    % 多份控制：对应答案移动到对应题目的后面
    show-solution / show-move-separately .code:n =
      {
        \bool_gset_true:N \g__examzh_solution_show_bool
        \bool_gset_true:N \g__examzh_solution_show_move_bool
        \bool_gset_true:N \g__examzh_solution_show_move_separately_bool
      },
    % 多份控制：全都移到最后
    show-solution / show-move-all .code:n =
      {
        \bool_gset_true:N \g__examzh_solution_show_bool
        \bool_gset_true:N \g__examzh_solution_show_move_bool
        \bool_gset_false:N \g__examzh_solution_show_move_separately_bool
      },
    show-answer .bool_set:N = \g__examzh_solution_show_bool,
    show-qed      .bool_set:N = \l__examzh_solution_show_qed_bool,
    qedsymbol     .tl_set:N = \l__examzh_solution_qedsymbol_tl,
    label-content  .tl_set:N   = \l__examzh_solution_label_content_tl,
    label-punct    .tl_set:N   = \l__examzh_solution_label_punct_tl,
    score-showleader .bool_set:N = \l__examzh_score_show_leader_bool,
    score-pre-content .tl_set:N = \l__examzh_score_pre_content_tl,
    score-post-content .tl_set:N = \l__examzh_score_post_content_tl,
    score-format .tl_set:N = \l__examzh_score_format_tl,
    text-color .tl_set:N = \l__examzh_solution_text_color_tl,
    blank-type .choices:nn =
      { none, manual, hide }
      {
        \str_set:Nx \l__examzh_solution_blank_type_str { \l_keys_choice_tl }
      },
    vsep .skip_set:N = \l__examzh_solution_blank_vsep_skip,
    top-sep    .skip_set:N = \l__examzh_solution_top_sep_skip,
    bottom-sep .skip_set:N = \l__examzh_solution_bottom_sep_skip,
    parbreak .bool_set:N = \l__examzh_solution_par_break_bool,
    partname-question .tl_gset:N = \g__examzh_solution_partname_question_tl,
    partname-solution .tl_gset:N = \g__examzh_solution_partname_solution_tl,
  }
\keys_set:nn { exam-zh / solution }
  {
    show-solution      = hide,
    show-qed           = false,
    qedsymbol          = $\square$,
    label-content      = {【解析】},
    label-punct        = {},
    score-showleader   = true,
    score-pre-content  = {},
    score-post-content = 分,
    score-format       = \color{red},
    text-color         = black,
    blank-type         = none,
    vsep         = 12ex plus 1ex minus 1ex,
    top-sep            = .25em plus .25em minus .1em,
    bottom-sep         = 0pt,
    parbreak           = false,
    partname-question  = 真题部分,
    partname-solution  = 参考答案部分,
  }
\keys_define:nn { exam-zh }
  { solution .meta:nn = { exam-zh / solution } {#1} }
% 解答题环境
\iow_new:N \g__write_soltion_to_auxfile
% 生成变体函数
\cs_generate_variant:Nn \iow_open:Nn { Nx }
\int_new:N \g__examzh_solution_aux_index_int
\NewDocumentEnvironment { solution } { O{ } +b }
  {
    % \addvspace { \l__examzh_solution_top_sep_skip }
    \keys_set:nn { exam-zh / solution } {#1}
    % 放在这是使得 \examsetup 设置 qedsymbol 可以放在正文区
    \cs_set_eq:NN \qedsymbol \l__examzh_solution_qedsymbol_tl
    \bool_if:NTF \g__examzh_solution_show_bool
      {
        \bool_if:NTF \g__examzh_solution_show_move_bool
          {
            % 这个方法成功
            \iow_open:Nn \g__write_soltion_to_auxfile { examzh_chapter_ \int_use:N \g__examzh_hide_chapter_counter_int _ \int_use:N \g__examzh_question_index_int .solution }
            \iow_now:Nx \g__write_soltion_to_auxfile 
              {
                % \exp_not:n { \newpage }
                \exp_not:n 
                  {
                    % \ShowAnswerTogetherBehind
                    % \__examzh_show_answer_together_behind:
                    % \__examzh_chapter:nn {参考答案}
                    % \__examzh_chapter_star:n 
                    %   {
                    %     % \tl_use:c { g__examzh_chapter_title_ \int_use:N \g__examzh_hide_chapter_counter_int _tl }
                    %     参考答案
                    %   }
                  }
                \par \noindent
                \int_eval:n { \g__examzh_question_index_int - 1 }.  【解析】
                \exp_not:n {#2}
                \par \exp_not:n { \vspace*{1ex} }
              }
            \iow_close:N \g__write_soltion_to_auxfile

            % 下面的方法失败
            % \group_begin:
            % \tl_set:Nn \tcb@verbatim@begin@hook 
            %   { \iow_now:Nx \tcb@out { \int_use:N \g__examzh_question_index_int } }
            % \tcbverbatimwrite {examzh \int_use:N \g__examzh_question_index_int .solution} #2
            % \endtcbverbatimwrite
            % \group_end:
          }
          {
            \vspace { \l__examzh_solution_top_sep_skip }
            \__examzh_solution_print_answer:n {#2}
            \par    
            \vspace { \l__examzh_solution_bottom_sep_skip }
          }
      }
      {
        \str_case:VnF \l__examzh_solution_blank_type_str
          {
            { none } { }
            { manual } { \addvspace { \l__examzh_solution_blank_vsep_skip } }
            { hide } { \__examzh_solution_simply_hide_solution:n {#2} }
          }
          {}
      }
    \par
    % \mode_leave_vertical:
    % \addvspace { \l__examzh_solution_bottom_sep_skip }
  }
  {}


% 由于每一章的  \g__examzh_question_index_int 可能不同，所以需要用一个计数器来记里面最大的那个
\int_zero_new:N \g__examzh_question_index_chapters_max_int

% 在每一章的开始将 \g__examzh_question_index_chapters_max_int 和 \g__examzh_question_index_int 比较，存最大的到 \g__examzh_question_index_chapters_max_int 里
\AddToHook{cmd/chapter/before}
  {
    \__examzh_question_index_chapter_max_calc:
  }

\cs_new:Npn \__examzh_question_index_chapter_max_calc:
  {
    \int_compare:nNnT { \g__examzh_question_index_int } > { \g__examzh_question_index_chapters_max_int }
      {
        \int_gset_eq:NN \g__examzh_question_index_chapters_max_int \g__examzh_question_index_int
      }
  }

\AtBeginDocument
  {
    \bool_lazy_and:nnT { \g__examzh_solution_show_bool } { \g__examzh_solution_show_move_bool }
      {
        \bool_if:NTF \g__examzh_solution_show_move_separately_bool
          {
            \AddToHook{cmd/chapter/before}
              {
                \int_compare:nNnT { \g__examzh_hide_chapter_counter_int } > { 0 }
                  {
                    \__examzh_question_index_chapter_max_calc:
                    \__examzh_show_answer_together_behind:V \g__examzh_hide_chapter_counter_int
                    \int_step_inline:nn { \g__examzh_question_index_chapters_max_int }
                      {
                        \file_if_exist:nT { examzh_chapter_ \int_use:N \g__examzh_hide_chapter_counter_int _ #1 .solution }
                          { \file_input:n { examzh_chapter_ \int_use:N \g__examzh_hide_chapter_counter_int _ #1 .solution } }
                      }
                  }
              }
            \AtEndDocument
              {
                \int_compare:nNnTF { \g__examzh_hide_chapter_counter_int } = { 0 }
                  {
                    \__examzh_question_index_chapter_max_calc:
                    \__examzh_show_answer_no_chapter_behind:
                    \int_step_inline:nn { \g__examzh_question_index_chapters_max_int }
                      {
                        \file_if_exist:nT { examzh_chapter_ 0 _ #1 .solution }
                          { \file_input:n { examzh_chapter_ 0 _ #1 .solution } }
                      }
                  }
                  {
                    \__examzh_show_answer_together_behind:V \g__examzh_hide_chapter_counter_int
                    \int_step_inline:nn { \g__examzh_question_index_chapters_max_int }
                      {
                        \file_if_exist:nT { examzh_chapter_ \int_use:N \g__examzh_hide_chapter_counter_int _ #1 .solution }
                          { \file_input:n { examzh_chapter_ \int_use:N \g__examzh_hide_chapter_counter_int _ #1 .solution } }
                      }
                  }
              }
          }
          {
            \AddToHook{cmd/tableofcontents/after}
              {
                % 去掉目录的页码
                \keys_set:nn { exam-zh / page }
                  { show-foot = false }
                \part{\g__examzh_solution_partname_question_tl}
                \keys_set:nn { exam-zh / page }
                  { show-foot = true }
                \int_set:cn { c@page } { 1 }
              }
          }
      }
  }
% \tl_new:N \g_examzh_solution_move_separately_lastpage_tl
\AtEndDocument
  {
    % \iow_now:cx { @auxout }
    %   {
    %     \token_to_str:N \ExplSyntaxOn
    %     ^^J
    %     % 注意要用 gset
    %     \tl_gset:Nn \exp_not:N \g_examzh_solution_move_separately_lastpage_tl  { \the\c@page }
    %     ^^J
    %     \token_to_str:N \ExplSyntaxOff
    %   }
    % \keys_set:nn { exam-zh / page }
    %   { show-foot = false }
    % 去掉页码
    % \patchcmd { \addcontentsline }
    %   { \thepage }
    %   {}
    %   {}{}
    % 因为结尾没有 chapter 了，但还是要算一次
    \__examzh_question_index_chapter_max_calc:
    \bool_lazy_and:nnT { \g__examzh_solution_show_bool } { \g__examzh_solution_show_move_bool }
      {
        % 统一放在后面
        \bool_if:NF \g__examzh_solution_show_move_separately_bool
          {
            \int_compare:nNnTF { \g__examzh_hide_chapter_counter_int } = { 0 }
              {
                \__examzh_question_index_chapter_max_calc:
                \__examzh_show_answer_no_chapter_behind:
                \int_step_inline:nn { \g__examzh_question_index_chapters_max_int }
                  {
                    \file_if_exist:nT { examzh_chapter_ 0 _ #1 .solution }
                      { \file_input:n { examzh_chapter_ 0 _ #1 .solution } }
                  }
              }
              {
                \int_compare:nNnT { \g__examzh_question_index_chapters_max_int } > { 0 }
                  {
                    \keys_set:nn { exam-zh / page }
                      { show-foot = false }
                    \part{\g__examzh_solution_partname_solution_tl}
                    % \fancyfoot[C]{}
                    % \thispagestyle{empty}
                    % \newpage 
                    \int_step_inline:nn { \g__examzh_hide_chapter_counter_int }
                      {
                        % 输出标题
                        \__examzh_show_answer_together_behind_numbered:n {#1}
                        % 输出答案内容
                        \int_step_inline:nn { \g__examzh_question_index_chapters_max_int }
                          {
                            \file_if_exist:nT { examzh_chapter_ #1 _ ##1 .solution }
                              { 
                                % \int_decr:c { c@page }
                                \file_input:n { examzh_chapter_ #1 _ ##1 .solution } 
                              }
                          }
                      }
                  }
              }
          }
      }
  }



\cs_new:Npn \__examzh_solution_simply_hide_solution:n #1
  {
    \begin{tcolorbox}
      [
        invisible,
        frame~hidden,
        breakable,
        opacityback  = 0,
        opacityframe = 0,
        size  = minimal,
        width = \linewidth
      ]
      #1
    \end{tcolorbox}
  }
\cs_new:Npn \__examzh_solution_print_answer:n #1
  {
    \par
    \pushQED { \qed }
    % \normalfont \topsep6 \p@ \@plus6 \p@ \relax
    % \trivlist
    % \item \relax
    \group_begin:
      % \hspace* { 2\ccwd }
      \color{blue} \zihao{5}
      \kaishu \l__examzh_solution_label_content_tl  
      \@addpunct { \l__examzh_solution_label_punct_tl }
    \group_end:
    \hspace{0.5em} 
    % \ignorespaces
    % 是否要新起一段开始
    \bool_if:NT \l__examzh_solution_par_break_bool { \par }
    % \group_begin:
    \begingroup
      \color { \l__examzh_solution_text_color_tl } #1
    \endgroup
    % \group_end:
    \bool_if:NT \l__examzh_solution_show_qed_bool
      { \popQED }
    % \endtrivlist 
    % \@endpefalse
  }

% https://github.com/CTeX-org/forum/issues/256#issuecomment-1172319787
\zref@require@unique

\NewDocumentCommand { \score } { O{} m }
  {
    \group_begin:
      \keys_set:nn { exam / question } {#1}
      \mode_if_math:TF
        { 
          \__examzh_score_math_version:n { #2 }
        }
        { 
          \__examzh_score_text_version:n { #2 }
        }
    \group_end:
  }
\cs_new:Npn \__examzh_score_math_version:n #1
  {
    \bool_if:NTF \l__examzh_score_show_leader_bool
      {
        \__examzh_math_cdotfill:n 
          { 
            \group_begin:
              \l__examzh_score_format_tl
              \l__examzh_score_pre_content_tl
              #1
              \l__examzh_score_post_content_tl 
            \group_end:
          }
      }
      {
        \__examzh_math_nodotfill:n
          {
            { 
              \group_begin:
                \l__examzh_score_format_tl
                \l__examzh_score_pre_content_tl
                #1
                \l__examzh_score_post_content_tl 
              \group_end:
            }
          }
      }
  }
\cs_new:Npn \__examzh_score_text_version:n #1
  {
    \bool_if:NTF \l__examzh_score_show_leader_bool
      {
        \group_begin:
          \__examzh_cdotfill:
          \l__examzh_score_format_tl
          \l__examzh_score_pre_content_tl #1 \l__examzh_score_post_content_tl 
        \group_end:
      }
      {
        \hfill
        \group_begin:
          \l__examzh_score_format_tl
          \l__examzh_score_pre_content_tl #1 \l__examzh_score_post_content_tl
        \group_end:
      }
    \par \noindent \ignorespaces
  }
% 仿照 latex.ltx, line 651 的 \dotfill
\cs_new:Npn \__examzh_cdotfill:
  {
    \mode_leave_vertical:
    \cleaders
      \hbox_to_wd:nn { .44em } { \hss $\cdot$ \hss }
      \hfill \kern\z@
  }
\cs_new_protected:Npn \__examzh_math_nodotfill:n #1
  {
    \stepcounter { zref@unique }
    \hbox_overlap_right:n
      {
        \zsaveposx { \thezref@unique L }
        \zref@ifrefundefined { \thezref@unique R }
          { }
          {
            \skip_horizontal:n
              {
                  \zposx { \thezref@unique R } sp
                - \zposx { \thezref@unique L } sp
              }
          }
      }
    \tag * { \zsaveposx { \thezref@unique R } #1 }
  }
\cs_new_protected:Npn \__examzh_math_cdotfill:n #1
  {
    \stepcounter { zref@unique }
    \hbox_overlap_right:n
      {
        \zsaveposx { \thezref@unique L }
        \zref@ifrefundefined { \thezref@unique R }
          { }
          {
            \cleaders
              \hbox_to_wd:nn { .44em } { \hss $\cdot$ \hss }
              \skip_horizontal:n
                {
                    \zposx { \thezref@unique R } sp
                  - \zposx { \thezref@unique L } sp
                }
          }
      }
    \tag * { \zsaveposx { \thezref@unique R } #1 }
  }

  \keys_define:nn { exam-zh }
  { symbols .meta:nn = { exam-zh / symbols } {#1} }


% 正体的 e 和 i
\NewDocumentCommand \eu { } { \mathrm{ e } }
\NewDocumentCommand \upe { } { \mathrm{ e } }
\NewDocumentCommand \iu { } { \mathrm{ i } }
\NewDocumentCommand \upi { } { \mathrm{ i } }

\NewDocumentCommand \uppi { } { \mathrm{ \pi } }



% 分数 \frac \dfrac
\int_new:N \l__examzh_symbols_frac_numerator_str_int       % frac 分子字符数
\int_new:N \l__examzh_symbols_frac_denominator_str_int     % frac 分母字符数
\int_new:N \l__examzh_symbols_dfrac_numerator_str_int       % frac 分子字符数
\int_new:N \l__examzh_symbols_dfrac_denominator_str_int     % frac 分母字符数

\keys_define:nn { exam-zh / symbols }
  {
    % 是否重定义 \frac
    change-frac-style .bool_set:N = \l__examzh_symbols_change_frac_style_bool,
    % 是否重定义 \dfrac
    change-dfrac-style .bool_set:N = \l__examzh_symbols_change_dfrac_style_bool,
    % \frac 分子分母增加的额外距离
    frac-add .muskip_set:N = \l__examzh_symbols_frac_add_distance_muskip,
    % \dfrac 分子分母增加的额外距离
    dfrac-add .muskip_set:N = \l__examzh_symbols_dfrac_add_distance_muskip,
  }
\keys_set:nn { exam-zh / symbols }
  {
    change-frac-style = false,
    change-dfrac-style = false,
    frac-add = 5mu,
    dfrac-add = 5mu,
  }
\NewCommandCopy { \examzhfrac } { \frac }
\NewCommandCopy { \examzhdfrac } { \dfrac }
\RenewDocumentCommand { \frac } { m m }
  {
    \group_begin:
      \bool_if:NTF \l__examzh_symbols_change_frac_style_bool
        {
          % 计算分子分母的字符数
          \__examzh_symbols_frac_calc_str_num:nn {#1} {#2}
          % 根据字符数选择将额外的距离加在哪
          \__examzh_symbols_frac_add_distance:NNNNnn
            \examzhfrac
            \l__examzh_symbols_frac_numerator_str_int
            \l__examzh_symbols_frac_denominator_str_int
            \l__examzh_symbols_frac_add_distance_muskip
            {#1}{#2}
        }
        {
          % \examzhfrac {#1} {#2} 
          \mathchoice { \examzhdfrac{#1}{#2} }
            { \examzhdfrac{#1}{#2} }
            { \examzhfrac{#1}{#2} }
            { \examzhfrac{#1}{#2} }
        }
    \group_end:
  }
\RenewDocumentCommand { \dfrac } { m m }
  {
    \group_begin:
      \bool_if:NTF \l__examzh_symbols_change_dfrac_style_bool
        {
          % 计算分子分母的字符数
          \__examzh_symbols_frac_calc_str_num:nn {#1} {#2}
          % 根据字符数选择将额外的距离加在哪
          \__examzh_symbols_frac_add_distance:NNNNnn
            \examzhdfrac
            \l__examzh_symbols_frac_numerator_str_int
            \l__examzh_symbols_frac_denominator_str_int
            \l__examzh_symbols_dfrac_add_distance_muskip
            {#1}{#2}
        }
        { \examzhdfrac {#1} {#2} }
    \group_end:
  }
\cs_new:Npn \__examzh_symbols_frac_calc_str_num:nn #1#2
  {
    \int_set:Nn \l__examzh_symbols_frac_numerator_str_int
      { \str_count:n {#1} }
    \int_set:Nn \l__examzh_symbols_frac_denominator_str_int
      { \str_count:n {#2} }
  }
% \__examzh_symbols_frac_add_distance:NNNNnn
  % <\oldfrac><numerator str num><denominator str num><add muskip><numerator><denominator>
\cs_new:Npn \__examzh_symbols_frac_add_distance:NNNNnn #1#2#3#4#5#6
  {
    \int_compare:nNnTF {#2} = {1}
      {
        \int_compare:nNnTF {#3} = {1}
          {
            % 分子字符数=1，分母字符数=1
            #1
              {
                \mskip #4
                #5
                \mskip #4
              } {#6}
          }
          {
            % 分子字符数=1，分母字符数>1
            #1 {#5}
              {
                \mskip #4
                #6
                \mskip #4
              }
          }
      }
      {
        \int_compare:nNnTF {#3} = {1}
          {
            % 分子字符数>1，分母字符数=1
            #1 
              {
                \mskip #4
                #5
                \mskip #4
              } {#6}
          }
          {
            % 分子字符数>1，分母字符数>1
            #1
              {
                \mskip #4
                #5
                \mskip #4
              } {#6}
          }
      }
  }

% 向量 vec
\int_new:N \l__examzh_symbols_vec_input_count_int

\AtBeginDocument
  {
    \RenewDocumentCommand { \vec } { m }
      { \__examzh_symbols_vec:n {#1} }
  }
\cs_new:Npn \__examzh_symbols_vec:n #1
  {
    % 先检测 #1 有多少个字符
    % \__examzh_symbols_vec_detect_number_of_input_str:n {#1}
    % 只有 1 个的：加粗，多于两个的加箭头
    % \int_compare:nNnTF { \l__examzh_symbols_vec_input_count_int } = {1}
      % { \symbfit {#1} }
      { \overrightarrow {#1} }
  }
\cs_new:Npn \__examzh_symbols_vec_detect_number_of_input_str:n #1
  {
    \int_set:Nn \l__examzh_symbols_vec_input_count_int
      { \str_count:n { #1 } }
  }

% 平行四边形 \parallelogram
\keys_define:nn { exam-zh / symbols }
  {
    parallelogram-angle .fp_set:N = \l__examzh_symbols_parallelogram_angle_fp,
    parallelogram-x .dim_set:N = \l__examzh_symbols_parallelogram_x_dim,
    parallelogram-y .dim_set:N = \l__examzh_symbols_parallelogram_y_dim
  }

\cs_new:Npn \__examzh_symbols_parallelogram:
  {
    \begin{tikzpicture}[baseline]
      \draw[line~join = round] (0,0) --++ (\l__examzh_symbols_parallelogram_x_dim,0) --++ (\fp_use:N \l__examzh_symbols_parallelogram_angle_fp \c_colon_str \l__examzh_symbols_parallelogram_y_dim) -- (\fp_use:N \l__examzh_symbols_parallelogram_angle_fp \c_colon_str \l__examzh_symbols_parallelogram_y_dim) -- cycle;
    \end{tikzpicture}
  }

\AtBeginDocument
  {
    \RenewDocumentCommand { \parallelogram } { }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols } 
            {
              parallelogram-angle = 67,
              parallelogram-x = 0.9em,
              parallelogram-y = 0.7em
            }
          \mathrel 
            { 
              \__examzh_symbols_symbol_four_size:n 
                { \__examzh_symbols_parallelogram: } 
            }
        \group_end:
      }
  }

% 平行 \parallel
\bool_new:N \l__examzh_symbols_parallel_slant_bool
\bool_new:N \l__examzh_symbols_nparallel_slant_bool

\keys_define:nn { exam-zh / symbols }
  {
    parallel-angle .fp_set:N = \l__examzh_symbols_parallel_angle_fp,
    parallel-twoline-distance .dim_set:N = \l__examzh_symbols_parallel_twoline_distance_dim,
    parallel-length .dim_set:N = \l__examzh_symbols_parallel_length_dim,
    parallel-baseline .dim_set:N = \l__examzh_symbols_parallel_baseline_dim,
    nparallel-slant-angle .fp_set:N = \l__examzh_symbols_nparallel_slant_angle_fp,
    nparallel-slant-length .dim_set:N = \l__examzh_symbols_nparallel_slant_length_dim,
    parallel-type .choice:,
    parallel-type / slant.code:n =
      { \bool_set_true:N \l__examzh_symbols_parallel_slant_bool },
    parallel-type / perpendicular .code:n =
      { \bool_set_false:N \l__examzh_symbols_parallel_slant_bool },
    nparallel-type .choice:,
    nparallel-type / slant.code:n =
      { \bool_set_true:N \l__examzh_symbols_nparallel_slant_bool },
    nparallel-type / perpendicular .code:n =
      { \bool_set_false:N \l__examzh_symbols_nparallel_slant_bool },
  }
\keys_set:nn { exam-zh / symbols }
  {
    parallel-type = slant,
    nparallel-type = slant,
  }

\cs_new:Npn \__examzh_symbols_parallel:
  {
    \begin{tikzpicture}[baseline=\l__examzh_symbols_parallel_baseline_dim]
      \draw[line~cap = round] (0, 0) --++ (\fp_use:N \l__examzh_symbols_parallel_angle_fp \c_colon_str \l__examzh_symbols_parallel_length_dim)
      (\l__examzh_symbols_parallel_twoline_distance_dim, 0) --++ (\fp_use:N \l__examzh_symbols_parallel_angle_fp \c_colon_str \l__examzh_symbols_parallel_length_dim);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_nparallel:
  {
    \begin{tikzpicture}[line~cap = round, baseline=\l__examzh_symbols_parallel_baseline_dim]
      \draw
        (0, 0) --++ (\fp_use:N \l__examzh_symbols_parallel_angle_fp \c_colon_str \l__examzh_symbols_parallel_length_dim)
        (\l__examzh_symbols_parallel_twoline_distance_dim, 0) --++ (\fp_use:N \l__examzh_symbols_parallel_angle_fp \c_colon_str \l__examzh_symbols_parallel_length_dim);
      % n 线
      \draw
        (\l__examzh_symbols_parallel_twoline_distance_dim / 2, 0)++(\fp_use:N \l__examzh_symbols_parallel_angle_fp \c_colon_str \l__examzh_symbols_parallel_length_dim / 2) --++ (\fp_use:N \l__examzh_symbols_nparallel_slant_angle_fp \c_colon_str \l__examzh_symbols_nparallel_slant_length_dim / 2)
        (\l__examzh_symbols_parallel_twoline_distance_dim / 2, 0)++(\fp_use:N \l__examzh_symbols_parallel_angle_fp \c_colon_str \l__examzh_symbols_parallel_length_dim / 2) --++ (\fp_eval:n { \l__examzh_symbols_nparallel_slant_angle_fp + 180 } \c_colon_str \l__examzh_symbols_nparallel_slant_length_dim / 2);
    \end{tikzpicture}
  }

\AtBeginDocument
  {
    \cs_set_eq:NN \__examzh_symbols_old_parallel: \parallel
    \cs_set_eq:NN \__examzh_symbols_old_nparallel: \nparallel
    \RenewDocumentCommand { \parallel } { }
      {
        \group_begin:
          \bool_if:NTF \l__examzh_symbols_parallel_slant_bool
            {
              \keys_set:nn { exam-zh / symbols } 
                {
                  parallel-angle = 60,
                  parallel-twoline-distance = 0.28em,
                  parallel-length = 0.98em,
                  parallel-baseline = 0.5pt
                }
            }
            {
              % 竖直
              \keys_set:nn { exam-zh / symbols } 
                {
                  parallel-angle = 90,
                  parallel-twoline-distance = 0.2em,
                  parallel-length = 0.93em,
                  parallel-baseline = 1pt
                }
            }
          \mathrel 
            { 
              \__examzh_symbols_symbol_four_size:n 
                { \__examzh_symbols_parallel: } 
            }
        \group_end:
      }
    \RenewDocumentCommand { \nparallel } { }
      {
        \group_begin:
          
          \bool_if:NTF \l__examzh_symbols_nparallel_slant_bool
            {
              \keys_set:nn { exam-zh / symbols }
                {
                  parallel-angle = 60,
                  parallel-twoline-distance = 0.28em,
                  parallel-length = 0.98em,
                  parallel-baseline = 0.5pt,
                  nparallel-slant-angle = 120,
                  nparallel-slant-length = 0.65em
                }
            }
            {
              \keys_set:nn { exam-zh / symbols }
                {
                  parallel-angle = 90,
                  parallel-twoline-distance = 0.2em,
                  parallel-length = 0.93em,
                  parallel-baseline = 1pt,
                  nparallel-slant-angle = 50,
                  nparallel-slant-length = 0.6em
                }
              % \tikz[baseline = {([yshift = 5pt]current~bounding~box.south)}]{ \node { $\__examzh_symbols_old_nparallel:$ }; }
            }
          \mathrel 
            { 
              \__examzh_symbols_symbol_four_size:n 
                { \__examzh_symbols_nparallel: } 
            }
        \group_end:
      }
  }

% 平行且相等 \paralleleq
\bool_new:N \l__examzh_symbols_paralleleq_slant_bool

\keys_define:nn { exam-zh / symbols }
  {
    % 上面部分的倾斜角
    paralleleq-slant-angle .fp_set:N = \l__examzh_symbols_paralleleq_angle_fp,
    % 线长度
    paralleleq-upper-line-length .dim_set:N = \l__examzh_symbols_paralleleq_upper_line_length_dim,
    paralleleq-lower-line-length .dim_set:N = \l__examzh_symbols_paralleleq_lower_line_length_dim,
    % 线间距
    paralleleq-upper-twoline-distance .dim_set:N = \l__examzh_symbols_paralleleq_upper_twoline_distance_dim,
    paralleleq-lower-twoline-distance .dim_set:N = \l__examzh_symbols_paralleleq_lower_twoline_distance_dim,
    % 下面部分的水平偏移量
    paralleleq-lower-xshift .dim_set:N = \l__examzh_symbols_paralleleq_lower_xshift_dim,
    paralleleq-type .choice:,
    paralleleq-type / slant.code:n =
      { \bool_set_true:N \l__examzh_symbols_paralleleq_slant_bool },
    paralleleq-type / perpendicular .code:n =
      { \bool_set_false:N \l__examzh_symbols_paralleleq_slant_bool },
  }

\keys_set:nn { exam-zh / symbols }
  { paralleleq-type = slant }

\cs_new:Npn \__examzh_symbols_paralleleq:
  {
    \begin{tikzpicture}[baseline = -1.7pt]
      \draw[line~cap = round, name = parallel] (0, 0) --++ (\fp_use:N \l__examzh_symbols_paralleleq_angle_fp \c_colon_str \l__examzh_symbols_paralleleq_upper_line_length_dim)
      (\l__examzh_symbols_paralleleq_upper_twoline_distance_dim, 0) --++ (\fp_use:N \l__examzh_symbols_paralleleq_angle_fp \c_colon_str \l__examzh_symbols_paralleleq_upper_line_length_dim);
      \draw[anchor = parallel.south] 
        (\l__examzh_symbols_paralleleq_upper_twoline_distance_dim / 2 + \l__examzh_symbols_paralleleq_lower_xshift_dim,0) --++ (\l__examzh_symbols_paralleleq_lower_line_length_dim / 2,0)
        (\l__examzh_symbols_paralleleq_upper_twoline_distance_dim / 2 + \l__examzh_symbols_paralleleq_lower_xshift_dim,0) --++ (-\l__examzh_symbols_paralleleq_lower_line_length_dim / 2,0)
        (\l__examzh_symbols_paralleleq_upper_twoline_distance_dim / 2 + \l__examzh_symbols_paralleleq_lower_xshift_dim,-\l__examzh_symbols_paralleleq_lower_twoline_distance_dim) --++ (\l__examzh_symbols_paralleleq_lower_line_length_dim / 2 ,0)
        (\l__examzh_symbols_paralleleq_upper_twoline_distance_dim / 2 + \l__examzh_symbols_paralleleq_lower_xshift_dim,-\l__examzh_symbols_paralleleq_lower_twoline_distance_dim) --++ (-\l__examzh_symbols_paralleleq_lower_line_length_dim / 2,0)
      ;
    \end{tikzpicture}
  }

\NewDocumentCommand { \paralleleq } { }
  {
    \group_begin:
      \keys_set:nn { exam-zh / symbols }
        {
          paralleleq-upper-line-length = 0.65em,
          paralleleq-lower-line-length = 0.8em,
          paralleleq-upper-twoline-distance = 0.2em,
          paralleleq-lower-twoline-distance = 0.18em,
        }
      \bool_if:NTF \l__examzh_symbols_paralleleq_slant_bool
        {
          % \paralleleq : 倾斜型
          \keys_set:nn { exam-zh / symbols }
            {
              paralleleq-slant-angle = 70,
              paralleleq-lower-xshift = 0.04em
            }
        }
        {
          % \paralleleq* : 垂直型
          \keys_set:nn { exam-zh / symbols }
            {
              paralleleq-slant-angle = 90,
              paralleleq-lower-xshift = 0em
            }
        }
      \mathrel 
        { 
          \__examzh_symbols_symbol_four_size:n 
            { \__examzh_symbols_paralleleq: } 
        }
    \group_end:
  }


% 子集 \subset 真子集 \subseteqq
\keys_define:nn { exam-zh / symbols }
  {
    % 半圆的半径
    subset-radius .dim_set:N = \l__examzh_symbols_subset_semicircle_radius_dim,
    % 半圆右边横线的长度
    subset-upper-linewidth .dim_set:N = \l__examzh_symbols_subset_semicircle_line_width_dim,
    % 下面线的长度
    subset-lower-linewidth .dim_set:N = \l__examzh_symbols_subset_lower_line_width_dim,
    % 上面部分和下面部分的距离
    subset-upper-lower-distance .dim_set:N =  \l__examzh_symbols_subset_upper_lower_distance_dim,
    % 下面部分 两条线的距离
    subsetneqq-lower-twoline-distance .dim_set:N =  \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim,
    % 下面斜线的长度
    subsetneqq-lower-slant-length .dim_set:N = \l__examzh_symbols_subsetneqq_lower_slant_line_length_dim,
    supsetneqq-lower-slant-length .dim_set:N = \l__examzh_symbols_supsetneqq_lower_slant_line_length_dim,
    % 真子集下方斜线的倾斜角度
    subsetneqq-lower-slant-angle .fp_set:N = \l__examzh_symbols_subsetneqq_lower_slant_line_angle_fp,
    supsetneqq-lower-slant-angle .fp_set:N = \l__examzh_symbols_supsetneqq_lower_slant_line_angle_fp,
    % nxxx 类的参数
    % --角度--
    nsubset-n-slant-angle .fp_set:N = \l__examzh_symbols_nsubset_slant_angle_fp,
    nsubseteq-n-slant-angle .fp_set:N = \l__examzh_symbols_nsubseteq_slant_angle_fp,
    nsubsetneqq-n-slant-angle .fp_set:N = \l__examzh_symbols_nsubsetneqq_slant_angle_fp,
    % --长度--
    nsubset-n-slant-length .dim_set:N = \l__examzh_symbols_nsubset_slant_length_dim,
    nsubseteq-n-slant-length .dim_set:N = \l__examzh_symbols_nsubseteq_slant_length_dim,
    nsubsetneqq-n-slant-length .dim_set:N = \l__examzh_symbols_nsubsetneqq_slant_length_dim,
  }
\keys_set:nn { exam-zh / symbols }
  {
    subset-radius = 0.2em,
    subset-upper-linewidth = 0.6em,
    subset-lower-linewidth = 
      {
        \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
      },
    subset-upper-lower-distance = 0.12em,
    subsetneqq-lower-twoline-distance = 0.14em,
    subsetneqq-lower-slant-length     = 0.42em,
    supsetneqq-lower-slant-length     = 0.4em,
    subsetneqq-lower-slant-angle      = 55,
    supsetneqq-lower-slant-angle      = 60,
    nsubset-n-slant-angle             = 65,
    nsubseteq-n-slant-angle           = 68,
    nsubsetneqq-n-slant-angle         = 70,
    nsubset-n-slant-length            = 1em,
    nsubseteq-n-slant-length          = 1em,
    nsubsetneqq-n-slant-length        = 1.2em,
  }

\cs_new:Npn \__examzh_symbols_subset:
  {
    \begin{tikzpicture}[line~cap=round,baseline = {([yshift = -1pt]current~bounding~box.south)}]
      % 半圆 + 两条线
      \draw[line~cap=round] (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str 270 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_nsubset:
  {
    \begin{tikzpicture}[line~cap=round,baseline = {([yshift = -1pt]current~bounding~box.south)}]
      % 半圆 + 两条线
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str 270 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      % 定位斜线的中心
      \coordinate (n-center) at (\l__examzh_symbols_subset_semicircle_line_width_dim / 2 - \l__examzh_symbols_subset_semicircle_radius_dim / 2,0);
      % 画斜线
      \draw[overlay] 
        (n-center) --++ (\fp_use:N \l__examzh_symbols_nsubset_slant_angle_fp \c_colon_str \l__examzh_symbols_nsubset_slant_length_dim / 2)
        (n-center) --++ (\fp_eval:n { \l__examzh_symbols_nsubset_slant_angle_fp + 180} \c_colon_str \l__examzh_symbols_nsubset_slant_length_dim / 2);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_subseteq:
  {
    \begin{tikzpicture}[line~cap=round,baseline = (current~bounding~box.south)]
      % 半圆 + 两条线
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str 270 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      % 下面的一条线
      \draw (-\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim) --++ (\l__examzh_symbols_subset_lower_line_width_dim, 0);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_nsubseteq:
  {
    \begin{tikzpicture}[line~cap=round,baseline = (current~bounding~box.south)]
      % 半圆 + 两条线
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str 270 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      % 下面的一条线
      \draw (-\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim) --++ (\l__examzh_symbols_subset_lower_line_width_dim, 0);
      % 定位斜线的中心
      \coordinate (n-center) at (\l__examzh_symbols_subset_semicircle_line_width_dim / 2 - \l__examzh_symbols_subset_semicircle_radius_dim / 2,0);
      % 画斜线
      \draw[overlay] 
        (n-center) --++ (\fp_use:N \l__examzh_symbols_nsubseteq_slant_angle_fp \c_colon_str \l__examzh_symbols_nsubseteq_slant_length_dim / 8 * 3.5)
        (n-center) --++ (\fp_eval:n { \l__examzh_symbols_nsubseteq_slant_angle_fp + 180} \c_colon_str \l__examzh_symbols_nsubseteq_slant_length_dim / 8 * 4.5);
    \end{tikzpicture}
  }
% 真子集
\cs_new:Npn \__examzh_symbols_subsetneqq:
  {
    \begin{tikzpicture}[line~cap=round,baseline = (current~bounding~box.south)]
      % 半圆 + 两条线
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str 270 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      % 下面的两条线
      \draw (-\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim) --++ (\l__examzh_symbols_subset_lower_line_width_dim, 0)
      (-\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim - \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim) --++ (\l__examzh_symbols_subset_lower_line_width_dim, 0);
      % 定位斜线的中心点
      \coordinate (lower-center) at 
        (\l__examzh_symbols_subset_semicircle_line_width_dim / 2 - \l__examzh_symbols_subset_semicircle_radius_dim / 2 , - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim - \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim / 2 );
      % 画斜线
      \draw[overlay]
        (lower-center) --++ (\fp_use:N \l__examzh_symbols_subsetneqq_lower_slant_line_angle_fp \c_colon_str \l__examzh_symbols_subsetneqq_lower_slant_line_length_dim / 2)
        (lower-center) --++ (\fp_eval:n {\l__examzh_symbols_subsetneqq_lower_slant_line_angle_fp + 180} \c_colon_str \l__examzh_symbols_subsetneqq_lower_slant_line_length_dim / 2);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_nsubsetneqq:
  {
    \begin{tikzpicture}[line~cap=round,baseline = (current~bounding~box.south)]
      % 半圆 + 两条线
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str 270 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      % 下面的两条线
      \draw (-\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim) --++ (\l__examzh_symbols_subset_lower_line_width_dim, 0)
      (-\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim - \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim) --++ (\l__examzh_symbols_subset_lower_line_width_dim, 0);
      % 定位斜线的中心点
      \coordinate (lower-center) at 
        (\l__examzh_symbols_subset_semicircle_line_width_dim / 2 - \l__examzh_symbols_subset_semicircle_radius_dim / 2 , - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim - \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim / 2 );
      % 画斜线
      \draw[overlay]
        (lower-center) --++ (\fp_use:N \l__examzh_symbols_subsetneqq_lower_slant_line_angle_fp \c_colon_str \l__examzh_symbols_subsetneqq_lower_slant_line_length_dim / 2)
        (lower-center) --++ (\fp_eval:n {\l__examzh_symbols_subsetneqq_lower_slant_line_angle_fp + 180} \c_colon_str \l__examzh_symbols_subsetneqq_lower_slant_line_length_dim / 2);
      % 定位斜线的中心
      \coordinate (n-center) at (\l__examzh_symbols_subset_semicircle_line_width_dim / 2 - \l__examzh_symbols_subset_semicircle_radius_dim / 2,0);
      % 画斜线
      \draw[overlay] 
        (n-center) --++ (\fp_use:N \l__examzh_symbols_nsubsetneqq_slant_angle_fp \c_colon_str \l__examzh_symbols_nsubsetneqq_slant_length_dim / 8 * 3.2)
        (n-center) --++ (\fp_eval:n { \l__examzh_symbols_nsubsetneqq_slant_angle_fp + 180} \c_colon_str \l__examzh_symbols_nsubsetneqq_slant_length_dim / 8 * 4.8);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_supset:
  {
    \begin{tikzpicture}[line~cap=round,baseline = {([yshift = -1pt]current~bounding~box.south)}]
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str -90 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_nsupset:
  {
    \begin{tikzpicture}[line~cap=round,baseline = {([yshift = -1pt]current~bounding~box.south)}]
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str -90 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      % 定位斜线的中心
      \coordinate (n-center) at (- \l__examzh_symbols_subset_semicircle_line_width_dim / 2 + \l__examzh_symbols_subset_semicircle_radius_dim / 2,0);
      % 画斜线
      \draw[overlay] 
        (n-center) --++ (\fp_use:N \l__examzh_symbols_nsubset_slant_angle_fp \c_colon_str \l__examzh_symbols_nsubset_slant_length_dim / 2)
        (n-center) --++ (\fp_eval:n { \l__examzh_symbols_nsubset_slant_angle_fp + 180} \c_colon_str \l__examzh_symbols_nsubset_slant_length_dim / 2);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_supseteq:
  {
    \begin{tikzpicture}[line~cap=round,baseline = (current~bounding~box.south)]
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str -90 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim);
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      \draw (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      \draw 
        (\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim - \l__examzh_symbols_subset_semicircle_radius_dim, 0);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_nsupseteq:
  {
    \begin{tikzpicture}[line~cap=round,baseline = (current~bounding~box.south)]
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str -90 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim)
      (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0)
      (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      \draw 
        (\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim - \l__examzh_symbols_subset_semicircle_radius_dim, 0);
      \coordinate (n-center) at (-\l__examzh_symbols_subset_semicircle_line_width_dim / 2 + \l__examzh_symbols_subset_semicircle_radius_dim / 2,0);
      % 画斜线
      \draw[overlay] 
        (n-center) --++ (\fp_use:N \l__examzh_symbols_nsubseteq_slant_angle_fp \c_colon_str \l__examzh_symbols_nsubseteq_slant_length_dim / 8 * 3.5)
        (n-center) --++ (\fp_eval:n { \l__examzh_symbols_nsubseteq_slant_angle_fp + 180} \c_colon_str \l__examzh_symbols_nsubseteq_slant_length_dim / 8 * 4.5);
    \end{tikzpicture}
  }
% 反向真子集
\cs_new:Npn \__examzh_symbols_supsetneqq:
  {
    \begin{tikzpicture}[line~cap=round,baseline = (current~bounding~box.south)]
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str -90 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim);
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      \draw (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      \draw 
        (\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim - \l__examzh_symbols_subset_semicircle_radius_dim, 0)
        (\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim - \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim - \l__examzh_symbols_subset_semicircle_radius_dim, 0);
      % 定位斜线的中心点
      \coordinate (center) at 
      (- \l__examzh_symbols_subset_semicircle_line_width_dim / 2 + \l__examzh_symbols_subset_semicircle_radius_dim / 2 , - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim - \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim / 2 );
      % 画斜线
      \draw[overlay]
        (center) --++ (\fp_use:N \l__examzh_symbols_supsetneqq_lower_slant_line_angle_fp \c_colon_str \l__examzh_symbols_supsetneqq_lower_slant_line_length_dim / 2)
        (center) --++ (\fp_eval:n {\l__examzh_symbols_supsetneqq_lower_slant_line_angle_fp + 180} \c_colon_str \l__examzh_symbols_supsetneqq_lower_slant_line_length_dim / 2);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_nsupsetneqq:
  {
    \begin{tikzpicture}[line~cap=round,baseline = (current~bounding~box.south)]
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) arc (90 \c_colon_str -90 \c_colon_str \l__examzh_symbols_subset_semicircle_radius_dim);
      \draw (0,\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      \draw (0,-\l__examzh_symbols_subset_semicircle_radius_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim,0);
      \draw 
        (\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim - \l__examzh_symbols_subset_semicircle_radius_dim, 0)
        (\l__examzh_symbols_subset_semicircle_radius_dim, - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim - \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim) --++ (-\l__examzh_symbols_subset_semicircle_line_width_dim - \l__examzh_symbols_subset_semicircle_radius_dim, 0);
      % 定位斜线的中心点
      \coordinate (center) at 
      (- \l__examzh_symbols_subset_semicircle_line_width_dim / 2 + \l__examzh_symbols_subset_semicircle_radius_dim / 2 , - \l__examzh_symbols_subset_semicircle_radius_dim - \l__examzh_symbols_subset_upper_lower_distance_dim - \l__examzh_symbols_subsetneqq_lower_twoline_distance_dim / 2 );
      % 画斜线
      \draw[overlay] 
        (center) --++ (\fp_use:N \l__examzh_symbols_supsetneqq_lower_slant_line_angle_fp \c_colon_str \l__examzh_symbols_supsetneqq_lower_slant_line_length_dim / 2)
        (center) --++ (\fp_eval:n {\l__examzh_symbols_supsetneqq_lower_slant_line_angle_fp + 180} \c_colon_str \l__examzh_symbols_supsetneqq_lower_slant_line_length_dim / 2);
      % 定位斜线的中心
      \coordinate (n-center) at (-\l__examzh_symbols_subset_semicircle_line_width_dim / 2 + \l__examzh_symbols_subset_semicircle_radius_dim / 2,0);
      % 画斜线
      \draw[overlay] 
        (n-center) --++ (\fp_use:N \l__examzh_symbols_nsubsetneqq_slant_angle_fp \c_colon_str \l__examzh_symbols_nsubsetneqq_slant_length_dim / 8 * 3.2)
        (n-center) --++ (\fp_eval:n { \l__examzh_symbols_nsubsetneqq_slant_angle_fp + 180} \c_colon_str \l__examzh_symbols_nsubsetneqq_slant_length_dim / 8 * 4.8);
    \end{tikzpicture}
  }
\AtBeginDocument
  {
    \cs_set_eq:NN \__examzh_symbols_old_subset: \subset
    \cs_set_eq:NN \__examzh_symbols_old_supset: \supset
    \cs_set_eq:NN \__examzh_symbols_old_nsubset: \nsubset
    \cs_set_eq:NN \__examzh_symbols_old_nsupset: \nsupset
    \cs_set_eq:NN \__examzh_symbols_old_subseteq: \subseteq
    \cs_set_eq:NN \__examzh_symbols_old_supseteq: \supseteq
    \cs_set_eq:NN \__examzh_symbols_old_nsubseteq: \nsubseteq
    \cs_set_eq:NN \__examzh_symbols_old_nsupseteq: \nsupseteq
    \cs_set_eq:NN \__examzh_symbols_old_subsetneqq: \subsetneqq
    \cs_set_eq:NN \__examzh_symbols_old_supsetneqq: \supsetneqq
    % \cs_set_eq:NN \__examzh_symbols_old_nsubsetneqq: \nsubsetneqq
    % \cs_set_eq:NN \__examzh_symbols_old_nsupsetneqq: \nsupsetneqq
    \RenewDocumentCommand { \subset } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth  = 0.6em
            }
          \IfBooleanTF {#1}
            { \__examzh_symbols_old_subset: }
            {
              \mathrel 
                { 
                  \__examzh_symbols_symbol_four_size:n 
                    { \__examzh_symbols_subset: } 
                }
            }
        \group_end:
      }
    \RenewDocumentCommand { \nsubset } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              nsubset-n-slant-angle       = 65,
              nsubset-n-slant-length      = 1em,
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_nsubset: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_nsubset: } 
                  }
              }
        \group_end:
      }
    \RenewDocumentCommand { \subseteq } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-upper-lower-distance = 0.12em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                }
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_subseteq: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_subseteq: } 
                  }
              }
        \group_end:
      }
    \RenewDocumentCommand { \nsubseteq } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                },
              subset-upper-lower-distance = 0.12em,
              nsubseteq-n-slant-angle           = 68,
              nsubseteq-n-slant-length          = 1em,
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_nsubseteq: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_nsubseteq: } 
                  }
              }
        \group_end:
      }
    \RenewDocumentCommand { \subsetneqq } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                },
              subset-upper-lower-distance = 0.12em,
              subsetneqq-lower-twoline-distance = 0.14em,
              subsetneqq-lower-slant-length     = 0.42em,
              subsetneqq-lower-slant-angle      = 55,
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_subsetneqq: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_subsetneqq: } 
                  }
              }
        \group_end:
      }
    \NewDocumentCommand { \nsubsetneqq } { }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                },
              subset-upper-lower-distance = 0.12em,
              subsetneqq-lower-twoline-distance = 0.14em,
              subsetneqq-lower-slant-length     = 0.42em,
              subsetneqq-lower-slant-angle      = 55,
              nsubsetneqq-n-slant-angle         = 70,
              nsubsetneqq-n-slant-length        = 1.2em,
            }
          \mathrel 
            { 
              \__examzh_symbols_symbol_four_size:n 
                { \__examzh_symbols_nsubsetneqq: } 
            }
        \group_end:
      }
    \RenewDocumentCommand { \supset } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth  = 0.6em
            }
          \IfBooleanTF {#1}
            { \__examzh_symbols_old_supset: }
            {
              \mathrel 
                { 
                  \__examzh_symbols_symbol_four_size:n 
                    { \__examzh_symbols_supset: } 
                }
            }
        \group_end:
      }
    \RenewDocumentCommand { \nsupset } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              nsubset-n-slant-angle       = 65,
              nsubset-n-slant-length      = 1em,
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_nsupset: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_nsupset: } 
                  }
              }
        \group_end:
      }
    \RenewDocumentCommand { \supseteq } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-upper-lower-distance = 0.12em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                }
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_supseteq: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_supseteq: } 
                  }
              }
        \group_end:
      }
    \RenewDocumentCommand { \nsupseteq } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                },
              subset-upper-lower-distance = 0.12em,
              nsubseteq-n-slant-angle           = 68,
              nsubseteq-n-slant-length          = 1em,
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_nsupseteq: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_nsupseteq: } 
                  }
              }
        \group_end:
      }
    \RenewDocumentCommand { \supsetneqq } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                },
              subset-upper-lower-distance = 0.12em,
              subsetneqq-lower-twoline-distance = 0.14em,
              supsetneqq-lower-slant-length     = 0.4em,
              supsetneqq-lower-slant-angle      = 60,
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_supsetneqq: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_supsetneqq: } 
                  }
              }
        \group_end:
      }
    \NewDocumentCommand { \nsupsetneqq } { }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                },
              subset-upper-lower-distance = 0.12em,
              subsetneqq-lower-twoline-distance = 0.14em,
              supsetneqq-lower-slant-length     = 0.4em,
              supsetneqq-lower-slant-angle      = 60,
              nsubsetneqq-n-slant-angle         = 70,
              nsubsetneqq-n-slant-length        = 1.2em,
            }
          \mathrel 
            { 
              \__examzh_symbols_symbol_four_size:n 
                { \__examzh_symbols_nsupsetneqq: } 
            }
        \group_end:
      }
    % \RenewDocumentCommand { \subset } { s }
    %   {
    %     \group_begin:
    %       \keys_set:nn { exam-zh / symbols }
    %         {
    %           subset-radius = 0.2em,
    %           subset-upper-linewidth = 0.6em,
    %           subset-lower-linewidth = 
    %             {
    %               \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
    %             },
    %           subset-upper-lower-distance = 0.12em,
    %           subsetneqq-lower-twoline-distance = 0.14em,
    %           subsetneqq-lower-slant-length     = 0.42em,
    %           supsetneqq-lower-slant-length     = 0.4em,
    %           subsetneqq-lower-slant-angle      = 55,
    %           supsetneqq-lower-slant-angle      = 60,
    %           nsubset-n-slant-angle             = 65,
    %           nsubseteq-n-slant-angle           = 68,
    %           nsubsetneqq-n-slant-angle         = 70,
    %           nsubset-n-slant-length            = 1em,
    %           nsubseteq-n-slant-length          = 1em,
    %           nsubsetneqq-n-slant-length        = 1.2em,
    %         }
    %         \IfBooleanTF {#1}
    %           { \__examzh_symbols_old_subset: }
    %           {
    %             \mathrel 
    %               { 
    %                 \__examzh_symbols_symbol_four_size:n 
    %                   { \__examzh_symbols_subset: } 
    %               }
    %           }
    %     \group_end:
    %   }
    \RenewDocumentCommand { \subseteq } { s }
      {
        \group_begin:
          \keys_set:nn { exam-zh / symbols }
            {
              subset-radius = 0.2em,
              subset-upper-linewidth = 0.6em,
              subset-lower-linewidth = 
                {
                  \l__examzh_symbols_subset_semicircle_radius_dim + \l__examzh_symbols_subset_semicircle_line_width_dim
                },
              subset-upper-lower-distance = 0.12em,
            }
            \IfBooleanTF {#1}
              { \__examzh_symbols_old_subseteq: }
              {
                \mathrel 
                  { 
                    \__examzh_symbols_symbol_four_size:n 
                      { \__examzh_symbols_subseteq: } 
                  }
              }
        \group_end:
      }
      
  }



% 并集 交集 cap cup

% 直线长度
\dim_new:N \l__examzh_symbols_cap_line_length_dim
\dim_new:N \l__examzh_symbols_cup_line_length_dim
% 半径大小
\dim_new:N \l__examzh_symbols_cap_radius_dim
\dim_new:N \l__examzh_symbols_cup_radius_dim

\cs_new:Npn \__examzh_symbols_cap:
  {
    \begin{tikzpicture}[line~cap=round, line~width = 0.6pt,baseline = {([yshift = 1.2pt]current~bounding~box.south)}]
      \draw (\l__examzh_symbols_cap_radius_dim,0) arc (0 \c_colon_str 180 \c_colon_str \l__examzh_symbols_cap_radius_dim);
      \draw 
        (\l__examzh_symbols_cap_radius_dim,0) --++ (0,-\l__examzh_symbols_cap_line_length_dim)
        (-\l__examzh_symbols_cap_radius_dim,0) --++ (0,-\l__examzh_symbols_cap_line_length_dim);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_cup:
  {
    \begin{tikzpicture}[line~cap=round, line~width = 0.6pt,baseline = {([yshift = 1.8pt]current~bounding~box.south)}]
      \draw (-\l__examzh_symbols_cup_radius_dim,0) arc (180 \c_colon_str 360 \c_colon_str \l__examzh_symbols_cup_radius_dim);
      \draw 
        (\l__examzh_symbols_cup_radius_dim,0) --++ (0,\l__examzh_symbols_cup_line_length_dim)
        (-\l__examzh_symbols_cup_radius_dim,0) --++ (0,\l__examzh_symbols_cup_line_length_dim);
    \end{tikzpicture}
  }
\AtBeginDocument
  {
    \cs_set_eq:NN \__examzh_symbols_old_cap: \cap
    \cs_set_eq:NN \__examzh_symbols_old_cup: \cup
    \RenewDocumentCommand { \cap } { s }
      {
        \group_begin:
          \dim_set:Nn \l__examzh_symbols_cap_line_length_dim { 0.56em }
          \dim_set:Nn \l__examzh_symbols_cap_radius_dim { 0.28em }
          \IfBooleanTF {#1}
            { \__examzh_symbols_old_cap: }
            {
              \mathrel 
                { 
                  \__examzh_symbols_symbol_four_size:n 
                    { \__examzh_symbols_cap: } 
                }
            }
        \group_end:
      }
    \RenewDocumentCommand { \cup } { s }
      {
        \group_begin:
          \dim_set:Nn \l__examzh_symbols_cup_line_length_dim { 0.53em }
          \dim_set:Nn \l__examzh_symbols_cup_radius_dim { 0.28em }
          \IfBooleanTF {#1}
            { \__examzh_symbols_old_cup: }
            {
              \mathrel 
                { 
                  \__examzh_symbols_symbol_four_size:n 
                    { \__examzh_symbols_cup: } 
                }
            }
        \group_end:
      }
  }
% 相似
\cs_new:Npn \__examzh_symbols_sim:
  {
    \begin{tikzpicture}[line~cap=round, line~width = 0.6pt,baseline = {([yshift = -1pt]current~bounding~box.south)}]
      \draw
        (-.25em,1.15ex) 
          .. controls (-.55em,1.15ex) and (-.51em,.23ex) .. (-.275em,.23ex) 
          .. controls (0,.23ex) and (0,1.15ex) .. (.275em,1.15ex) 
          .. controls (.51em,1.15ex) and (.55em,.23ex) .. (.25em,.23ex);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_nsim:
  {
    \begin{tikzpicture}[line~width = 0.6pt,line~cap=round, baseline = {([yshift = 1pt]current~bounding~box.south)}]
      \draw
        (-.25em,1.15ex) 
          .. controls (-.55em,1.15ex) and (-.51em,.23ex) .. (-.275em,.23ex) 
          .. controls (0,.23ex) and (0,1.15ex) .. (.275em,1.15ex) 
          .. controls (.51em,1.15ex) and (.55em,.23ex) .. (.25em,.23ex);
      \draw (-0.15em,-0.2ex) --++ (70 \c_colon_str 0.8em);
    \end{tikzpicture}
  }
\AtBeginDocument
  {
    \cs_set_eq:NN \__examzh_symbols_old_sim: \sim
    \RenewDocumentCommand { \sim } { s }
      {
        \IfBooleanTF {#1}
          { \__examzh_symbols_old_sim: }
          {
            \mathrel { \__examzh_symbols_symbol_four_size:n { \__examzh_symbols_sim: } }
          }
      }
    \RenewDocumentCommand { \nsim } {  }
      {
        \mathrel { \__examzh_symbols_symbol_four_size:n { \__examzh_symbols_nsim: } }
      }
  }

% 全等
\cs_new:Npn \__examzh_symbols_cong:
  {
    \begin{tikzpicture}[line~cap=round, baseline]
      \draw
        (-.2em,1.35ex) 
          .. controls (-.46em,1.6ex) and (-.54em,.65ex) .. (-.25em,.65ex)
          .. controls (-.06em,.65ex) and (.06em,1.35ex) .. (.25em,1.35ex)
          .. controls (.54em,1.35ex) and (.46em,.4ex) .. (.2em,.65ex)
        (-.46em,.4ex) -- (.46em,.4ex)
        (-.46em,0ex) -- (.46em,0ex);
    \end{tikzpicture}
  }
\cs_new:Npn \__examzh_symbols_ncong:
  {
    \begin{tikzpicture}[line~cap=round, baseline]
      \draw
        (-.2em,1.35ex) 
          .. controls (-.46em,1.6ex) and (-.54em,.65ex) .. (-.25em,.65ex)
          .. controls (-.06em,.65ex) and (.06em,1.35ex) .. (.25em,1.35ex)
          .. controls (.54em,1.35ex) and (.46em,.4ex) .. (.2em,.65ex)
        (-.46em,.4ex) -- (.46em,.4ex)
        (-.46em,0ex) -- (.46em,0ex);
      \draw (-0.22em,-0.4ex) --++ (66 \c_colon_str 1em);
    \end{tikzpicture}
  }

\AtBeginDocument
  {
    \cs_set_eq:NN \__examzh_symbols_old_cong: \backcong
    \RenewDocumentCommand { \cong } { s }
      {
        \IfBooleanTF {#1}
          { \__examzh_symbols_old_cong: }
          {
            \mathrel { \__examzh_symbols_symbol_four_size:n { \__examzh_symbols_cong: } }
          }
      }
    \RenewDocumentCommand { \ncong } { }
      {
        \mathrel { \__examzh_symbols_symbol_four_size:n { \__examzh_symbols_ncong: } }
      }
  }

% 处理符号的不同情况的大小
\cs_set_eq:NN \NewDocumentCommand:Nnn \NewDocumentCommand
\cs_set_eq:NN \RenewDocumentCommand:Nnn \RenewDocumentCommand
\cs_generate_variant:Nn \NewDocumentCommand:Nnn { cnn }
\cs_generate_variant:Nn \RenewDocumentCommand:Nnn { cnn }

\cs_new:Npn \__examzh_symbols_new_command_without_star_or_old_version:n #1
  {
    \NewDocumentCommand:cnn { #1 } { }
      {
        \mathrel 
          { 
            \__examzh_symbols_symbol_four_size:n 
              { \use:c { __examzh_symbols_ #1 : } } 
          }
      }
  }

\cs_new:Npn \__examzh_symbols_new_command_with_star_and_old_version:n #1
  {
    \RenewDocumentCommand:cnn { #1 } { s }
      {
        \IfBooleanTF {##1}
          { \use:c { __examzh_symbols_old_ #1 : } }
          {
            \mathrel 
              { 
                \__examzh_symbols_symbol_four_size:n 
                  { \use:c { __examzh_symbols_ #1 : } } 
              }
          }
      }
  }
\cs_new:Npn \__examzh_symbols_symbol_four_size:n #1
  {
    \mathchoice
      {
        \hbox:n 
          {
            \fontsize{\tf@size}{\tf@size}\selectfont #1
          }
      }
      {
        \hbox:n 
          {
            \fontsize{\tf@size}{\tf@size}\selectfont #1
          }
      }
      {
        \hbox:n
          {
            \fontsize{\sf@size}{\sf@size}\selectfont #1
          }
      }
      {
        \hbox:n
          {
            \fontsize{\ssf@size}{\ssf@size}\selectfont #1 
          }
      }
  }



%% multifigures 环境，排版多张图片 %%

% \begin{multifigures}
%   \item[题 9 图：勾股数] \includegraphics[width=3cm]{example-image.png}
%   \item[题 11 图：圆锥曲线] \includegraphics[width=3cm]{example-image.png}
% \end{multifigures}

% 图片相对于 label 的方位
\str_new:N \l__examzh_multifigures_figure_position_str
% coffin type 的对齐方式
\str_new:N \l__examzh_multifigures_coffin_align_str
\dim_new:N \l__examzh_multifigures_column_gap_dim
\dim_new:N \l__examzh_multifigures_item_width_dim


\keys_define:nn { exam-zh / multifigures }
  {
    % 每行多少个（等价于有多少列）
    columns .int_set:N = \l__examzh_multifigures_column_int,
    % 图片相对于文字的位置（上下左右）
    fig-pos .choices:nn =
      { top, above, bottom, below, left, right }
      { \str_set:Nx \l__examzh_multifigures_figure_position_str { \l_keys_choice_tl } },
    % 环境上方的额外距离
    top-sep .skip_set:N = \l__examzh_multifigures_top_sep_skip,
    % 环境下方的额外距离
    bottom-sep .skip_set:N = \l__examzh_multifigures_bottom_sep_skip,
    % 整体的偏移量
    xshift .dim_set:N = \l__examzh_multifigures_xshift_dim,
    hshift .dim_set:N = \l__examzh_multifigures_xshift_dim,
    yshift .dim_set:N = \l__examzh_multifigures_yshift_dim,
    vshift .dim_set:N = \l__examzh_multifigures_yshift_dim,
    column-gap .dim_set:N = \l__examzh_multifigures_column_gap_dim,
    % label 的偏移量
    label-xshift .dim_set:N = \l__examzh_multifigures_label_xshift_dim,
    label-hshift .dim_set:N = \l__examzh_multifigures_label_xshift_dim,
    label-yshift .dim_set:N = \l__examzh_multifigures_label_yshift_dim,
    label-vshift .dim_set:N = \l__examzh_multifigures_label_yshift_dim,
    % 对齐方式
    align .choices:nn = 
      { t, m, b }
      { \str_set:Nx \l__examzh_multifigures_coffin_align_str { \l_keys_choice_tl } }
  }
\keys_set:nn { exam-zh / multifigures }
  {
    columns      = 3,
    fig-pos      = above,
    label-xshift = 0pt,
    label-yshift = 0pt,
    align        = b,
    top-sep      = 1ex plus .5ex minus .5ex,
    bottom-sep   = 0pt,
    column-gap   = 1em,
  }

% item 的 index 指标（即第几个 item）
\int_new:N \l__examzh_multifigures_item_index_int
% 将拼接后的 coffin 存到 seq 里
\seq_new:N \l__examzh_multifigures_store_seq
% 上面的 seq 的 item 数
\int_new:N \l__examzh_multifigures_store_seq_item_int
% 最终放在 tblr 里的内容
\tl_new:N \l__examzh_multifigures_tblr_content_tl

\NewDocumentEnvironment { multifigures } { O{ } +O{ } +b }
  {
    \group_begin:
      \RenewDocumentCommand \item { O{ } }
        { \__examzh_multifigures_item:n {##1} }
      \int_set:Nn \l__examzh_multifigures_item_index_int {0}
      \seq_clear:N \l__examzh_multifigures_store_seq
      \tl_clear:N \l__examzh_multifigures_tblr_content_tl
      \keys_set:nn { exam-zh / multifigures } {#1}
      \seq_set_split:Nnn \l_tmpa_seq { \item } {#3}
      \int_set:Nn \l__examzh_multifigures_column_int
        {
          \int_min:nn
            { \l__examzh_multifigures_column_int }
            { \seq_count:N \l_tmpa_seq - 1 }
        }
      \dim_set:Nn \l_tmpa_dim
        {
          \int_eval:n
            { 2 * ( \l__examzh_multifigures_column_int - 1 ) }
          \l__examzh_multifigures_column_gap_dim
        }
      \dim_set:Nn \l__examzh_multifigures_item_width_dim
        { ( \linewidth - \l_tmpa_dim ) / \l__examzh_multifigures_column_int }
      #3
  }
  {
      % 结束收集
        \unskip
      \end{varwidth}
      \hcoffin_set_end:
      % 拼接 label 和 figure
      \__examzh_multifigures_coffin_join:
      % 输出
      \__examzh_multifigures_coffin_typeset:n {#2}
      % \par \int_use:N \l__examzh_multifigures_item_index_int
    \group_end:
  }
% 拼接 label 和 figure
\cs_new:Npn \__examzh_multifigures_coffin_join:
  {
    \int_step_inline:nn { \l__examzh_multifigures_item_index_int }
      {
        \__examzh_multifigures_coffin_join_position_set:n {##1}
        \seq_gput_right:Nn \l__examzh_multifigures_store_seq
          {
            \__examzh_multifigures_coffin_align_set:n {##1}
          }
      }
  }
\cs_new:Npn \__examzh_multifigures_coffin_align_set:n #1
  {
    \str_case:Vn \l__examzh_multifigures_coffin_align_str
      {
        {t} { \__examzh_multifigures_coffin_align_set_t:n {#1} }
        {m} { \__examzh_multifigures_coffin_align_set_m:n {#1} }
        {b} { \__examzh_multifigures_coffin_align_set_b:n {#1} }
      }
  }
\cs_new:Npn \__examzh_multifigures_coffin_align_set_t:n #1
  {
    \coffin_typeset:cnnnn
      { l__examzh_multifigures_figure_ \int_to_roman:n { #1 } _coffin }
      { l } { t }  % align = t
      { 0pt } { \l__examzh_multifigures_yshift_dim + 1em }
  }
\cs_new:Npn \__examzh_multifigures_coffin_align_set_m:n #1
  {
    \coffin_typeset:cnnnn
      { l__examzh_multifigures_figure_ \int_to_roman:n { #1 } _coffin }
      { l } { vc }  % align = m
      { 0pt } { \l__examzh_multifigures_yshift_dim }
  }
\cs_new:Npn \__examzh_multifigures_coffin_align_set_b:n #1
  {
    \coffin_typeset:cnnnn
      { l__examzh_multifigures_figure_ \int_to_roman:n { #1 } _coffin }
      { l } { b }   % align = b
      { 0pt } { \l__examzh_multifigures_yshift_dim }
  }
\cs_new:Npn \__examzh_multifigures_coffin_join_position_set:n #1
  {
    \use:c { __examzh_multifigures_coffin_join_position_set_ \l__examzh_multifigures_figure_position_str :n } {#1}
  }
\cs_new:Npn \__examzh_multifigures_coffin_join_position_set_top:n #1
  {
    \coffin_join:cnncnnnn
      { l__examzh_multifigures_figure_ \int_to_roman:n {#1} _ coffin }
      { hc } { b }
      { l__examzh_multifigures_label_ \int_to_roman:n {#1} _ coffin }
      { hc } { t }
      { \l__examzh_multifigures_label_xshift_dim }
      { \l__examzh_multifigures_label_yshift_dim - 6pt }
  }
\cs_set_eq:NN 
  \__examzh_multifigures_coffin_join_position_set_above:n 
  \__examzh_multifigures_coffin_join_position_set_top:n
\cs_new:Npn \__examzh_multifigures_coffin_join_position_set_bottom:n #1
  {
    \coffin_join:cnncnnnn
      { l__examzh_multifigures_figure_ \int_to_roman:n {#1} _ coffin }
      { hc } { t }
      { l__examzh_multifigures_label_ \int_to_roman:n {#1} _ coffin }
      { hc } { b }
      { \l__examzh_multifigures_label_xshift_dim }
      { \l__examzh_multifigures_label_yshift_dim + 6pt }
  }
\cs_set_eq:NN 
  \__examzh_multifigures_coffin_join_position_set_below:n 
  \__examzh_multifigures_coffin_join_position_set_bottom:n
\cs_new:Npn \__examzh_multifigures_coffin_join_position_set_left:n #1
  {
    \coffin_join:cnncnnnn
      { l__examzh_multifigures_figure_ \int_to_roman:n {#1} _ coffin }
      { l } { vc }
      { l__examzh_multifigures_label_ \int_to_roman:n {#1} _ coffin }
      { r } { vc }
      { \l__examzh_multifigures_label_xshift_dim - 6pt }
      { \l__examzh_multifigures_label_yshift_dim }
  }
\cs_new:Npn \__examzh_multifigures_coffin_join_position_set_right:n #1
  {
    \coffin_join:cnncnnnn
      { l__examzh_multifigures_figure_ \int_to_roman:n {#1} _ coffin }
      { r } { vc }
      { l__examzh_multifigures_label_ \int_to_roman:n {#1} _ coffin }
      { l } { vc }
      { \l__examzh_multifigures_label_xshift_dim + 2pt }
      { \l__examzh_multifigures_label_yshift_dim }
  }
\cs_new:Npn \__examzh_multifigures_coffin_typeset:n #1
  {
    \__examzh_multifigures_coffin_typeset_count:
    \seq_map_indexed_inline:Nn \l__examzh_multifigures_store_seq
      % ##1: index
      % ##2: content
      {
        \int_compare:nNnTF { \int_mod:nn {##1} { \l__examzh_multifigures_column_int } } = {0}
          {
            \tl_gput_right:Nn \l__examzh_multifigures_tblr_content_tl { ##2 \\ }
          }
          {
            \tl_gput_right:Nn \l__examzh_multifigures_tblr_content_tl { ##2 & }
          }
      }
    % 如果 seq 的 item 比 column 多且不整除 column 的话，要补 &
    \int_compare:nNnT { \l__examzh_multifigures_store_seq_item_int } > { \l__examzh_multifigures_column_int }
      {
        \int_compare:nNnF { \l__examzh_multifigures_item_num_mod_column_left_int } = { 0 }
          {
            \tl_gput_right:Nx \l__examzh_multifigures_tblr_content_tl
              {
                \prg_replicate:nn { \l__examzh_multifigures_item_num_mod_column_left_int -1 } {&}
              }
            % \int_use:N \l__examzh_multifigures_item_num_mod_column_left_int
          }
      }
    \par 
    \vspace*{ \l__examzh_multifigures_top_sep_skip }
    \noindent \hspace*{ \l__examzh_multifigures_xshift_dim }
    % \SetTblrInner
    %   {
    %     rowsep = 4pt,
    %     % colsep = 0pt
    %   }
    \begin{tblr}
      [ expand = \l__examzh_multifigures_tblr_content_tl ]
      {
        width = \linewidth,
        colsep = \l__examzh_multifigures_column_gap_dim,
        cells = {c},
        column{1} = {leftsep = 0pt},
        column{Z} = {rightsep = 0pt},
        rows = 
          {
            abovesep = 0pt,
            belowsep = 0pt,
          },
        % vlines,hlines,
        #1
      }
      \l__examzh_multifigures_tblr_content_tl
    \end{tblr}
    \vspace*{ \l__examzh_multifigures_bottom_sep_skip }
    \par
  }
\int_new:N \l__examzh_multifigures_item_num_mod_column_left_int
\cs_new:Npn \__examzh_multifigures_coffin_typeset_count:
  {
    % 计算 seq 有多少项
    \int_set:Nn \l__examzh_multifigures_store_seq_item_int
      { \seq_count:N \l__examzh_multifigures_store_seq }
    % seq 项数小于 column 的话，column 设置为 seq 项数
    \int_compare:nNnTF { \l__examzh_multifigures_store_seq_item_int } < { \l__examzh_multifigures_column_int }
      { \int_set_eq:NN \l__examzh_multifigures_column_int \l__examzh_multifigures_store_seq_item_int }
      {
        % 计算 \l__examzh_multifigures_store_seq_item_int mod \l__examzh_multifigures_column_int 的余数，用于补 &
        \int_set:Nn \l__examzh_multifigures_item_num_mod_column_left_int { \int_mod:nn { \l__examzh_multifigures_store_seq_item_int } { \l__examzh_multifigures_column_int } }
      }
  }
\cs_new:Npn \__examzh_multifigures_item:n #1
  {
    % 增加指标（g 是关键）
    \int_gincr:N \l__examzh_multifigures_item_index_int
    % 新建 coffin
    \__examzh_multifigures_item_new_coffin:
    % 储存 label（一直出不来的原因是因为没改成 gset）
    \hcoffin_gset:cn { l__examzh_multifigures_label_ \int_to_roman:n { \l__examzh_multifigures_item_index_int } _coffin } {#1}
    % 储存 figure
    \int_compare:nNnF { \l__examzh_multifigures_item_index_int } = {1}
      {
          \unskip
          \end{varwidth}
        % 结束上一个 item 的收集
        \hcoffin_set_end:
      }
    % 收集
    \hcoffin_set:cw { l__examzh_multifigures_figure_ \int_to_roman:n { \l__examzh_multifigures_item_index_int } _coffin }
      \begin{varwidth}{\l__examzh_multifigures_item_width_dim}
        \ignorespaces
  }

% 新建 coffin
\cs_new:Npn \__examzh_multifigures_item_new_coffin:
  {
    % 放图片的 coffin
    \coffin_if_exist:cF { l__examzh_multifigures_figure_ \int_to_roman:n { \l__examzh_multifigures_item_index_int } _coffin }
      { \coffin_new:c { l__examzh_multifigures_figure_ \int_to_roman:n { \l__examzh_multifigures_item_index_int } _coffin } }
    % 放 label 的 coffin
    \coffin_if_exist:cF { l__examzh_multifigures_label_ \int_to_roman:n { \l__examzh_multifigures_item_index_int } _coffin }
      { \coffin_new:c { l__examzh_multifigures_label_ \int_to_roman:n { \l__examzh_multifigures_item_index_int } _coffin } }
  }



%% \textfigure 


\coffin_new:N \l__examzh_textfigure_text_coffin        % 用于存文本
\coffin_new:N \l__examzh_textfigure_figure_coffin         % 用于存图片

\str_new:N \l__examzh_textfigure_current_figure_position_str    % 用来存当前的 anchor值

\fp_new:N \l__examzh_textfigure_text_ratio_fp              % 文本的比例

\dim_new:N \l__examzh_textfigure_text_width_dim            % 文本的宽度
\dim_new:N \l__examzh_textfigure_text_coffin_width_dim     % 文本c offin 的宽度
\dim_new:N \l__examzh_textfigure_figure_width_dim      % 图片的 varwidth 环境的宽度
\dim_new:N \l__examzh_textfigure_min_text_width_dim    % 自动分栏时文本的最小宽度
\tl_new:N \l__examzh_textfigure_min_text_width_tl      % 保留相对当前行宽的宽度表达式
\dim_new:N \l__examzh_textfigure_column_gap_dim        % 左右图文之间的距离
\bool_new:N \l__examzh_textfigure_auto_text_width_bool % 是否按图片实宽计算文本宽度

% 用于 top-center, top-right, bottom-center, bottom-right 的水平偏移量储存
\dim_new:N \l__examzh_textfigure_figure_coffin_horizontal_transform_dim
\dim_new:N \l__examzh_textfigure_tmpa_dim              % 临时变量

\skip_new:N \l__examzh_textfigure_tmpa_skip            % 临时变量


\keys_define:nn { exam-zh }
  {
    textfigure  .meta:nn = { exam-zh / textfigure } {#1}
  }
\keys_define:nn { exam-zh / textfigure }
  {
    % fig-pos为图片位于文本的方位
    fig-pos .choices:nn =
      { 
        left , right , top , bottom ,
        top-left , top-right , top-center ,
        top-flushright , bottom-flushright , 
        bottom-left , bottom-right , bottom-center ,
        right-top , right-bottom , right-center ,
        left-top , left-bottom , left-center
      }
      {
        \str_set:NV \l__examzh_textfigure_current_figure_position_str \l_keys_choice_tl
      },
    % figure-yshift：调整图片的垂直额外偏移量
    figure-yshift .dim_set:N = \l__examzh_textfigure_figure_yshift_dim,
    figure-vshift .dim_set:N = \l__examzh_textfigure_figure_yshift_dim,
    % figure-xshift：调整图片的水平额外偏移量
    figure-xshift .dim_set:N = \l__examzh_textfigure_figure_xshift_dim,
    figure-hshift .dim_set:N = \l__examzh_textfigure_figure_xshift_dim,
    % yshift：调整整体的垂直额外偏移量
    yshift .dim_set:N = \l__examzh_textfigure_yshift_dim,
    vshift .dim_set:N = \l__examzh_textfigure_yshift_dim,
    % xshift：调整整体的水平额外偏移量
    xshift .dim_set:N = \l__examzh_textfigure_xshift_dim,
    hshift .dim_set:N = \l__examzh_textfigure_xshift_dim,
    % text-width：手动设置文本的 varwidth 环境的宽度
    text-width .dim_set:N = \l__examzh_textfigure_text_width_dim,
    % pos 是 fig-pos 的简写，便于与其它浮动布局接口保持一致
    pos .choices:nn =
      {
        left , right , top , bottom ,
        top-left , top-right , top-center ,
        top-flushright , bottom-flushright ,
        bottom-left , bottom-right , bottom-center ,
        right-top , right-bottom , right-center ,
        left-top , left-bottom , left-center
      }
      {
        \str_set:NV \l__examzh_textfigure_current_figure_position_str \l_keys_choice_tl
      },
    % 自动按图片实际宽度分配左右布局的文本宽度
    auto-text-width .bool_set:N = \l__examzh_textfigure_auto_text_width_bool,
    min-text-width .code:n =
      { \tl_set:Nn \l__examzh_textfigure_min_text_width_tl {#1} },
    column-gap .dim_set:N = \l__examzh_textfigure_column_gap_dim,
    % figure-width：手动设置 figure 的 varwidth 环境的宽度
    figure-width .dim_set:N = \l__examzh_textfigure_figure_width_dim,
    % ratio / text-ratio：文本 coffin 占行宽的比例，范围0-1
    ratio .fp_set:N = \l__examzh_textfigure_text_ratio_fp,
    text-ratio .fp_set:N = \l__examzh_textfigure_text_ratio_fp,
    % 环境上方的额外距离
    top-sep .skip_set:N = \l__examzh_textfigure_top_sep_skip,
    % 环境下方的额外距离
    bottom-sep .skip_set:N = \l__examzh_textfigure_bottom_sep_skip,
    % 类似于 wrapstuff 的 top
    top .int_set:N = \l__examzh_textfigure_top_int,
    parindent .dim_set:N = \l__examzh_textfigure_text_parindent_dim
  }

\keys_set:nn { exam-zh / textfigure }
  {
    fig-pos         = right,
    yshift          = .5\baselineskip,
    text-width      = \columnwidth,
    auto-text-width = false,
    min-text-width  = .35\linewidth,
    column-gap      = 1em,
    figure-width    = \columnwidth,
    text-ratio      = 0.95,
    top-sep         = 0pt,
    bottom-sep      = 1.5ex plus .5ex minus 0.5ex,
    top             = 0,
    parindent       = 2em 
  }


% 【已解决】判断anchor是不是west或者east，是的话就自动调整调整一下text-ratio
% - 问题在于要知道key-val设置了什么anchor才能判断
% - 但是这个key-val设置和手动设置ratio是同一接口
% - 理想是：
%   - 先用户设置anchor
%   - 然后自动判断是否是west或者east，并自动调整ratio
%    【思考】其实也就是说anchor的时候要判断是否是east和west来设置ratio（关键）
%   - 然后用户手动的话以手动的为准
% 【解决关键】既然不可能中途处理，那只能在 key-val 设置的时候就要处理掉这个自动的ratio，所以重新设计了anchor键值代码

\NewDocumentCommand{ \textfigure }{ O{} +m +m }
  {
    \group_begin:
      \keys_set:nn { exam-zh / textfigure } {#1}
      \par 
      \vspace*{ \l__examzh_textfigure_top_sep_skip }
      \noindent
      \__examzh_textfigure_output:nnn {#1} {#2} {#3}
      \vspace*{ \l__examzh_textfigure_bottom_sep_skip }
      \par
    \group_end:
  }


% 最终的拼接命令
\cs_new:Npn \__examzh_textfigure_output:nnn #1#2#3
  {
    % issue：https://gitee.com/xkwxdyy/text-figure/issues/I4RVQX
    % 关键点在于要离开垂直模式
    % https://ask.latexstudio.net/ask/question/7238.html
    \mode_leave_vertical:
    % 先测量图片；自动文本宽度必须使用图片的实际宽度
    \__examzh_textfigure_figure_coffin_store:n {#3}
    \__examzh_textfigure_text_width_dim_set:n {#1}
    \__examzh_textfigure_text_coffin_store:n {#2}
    % coffin 的拼接
    \__examzh_textfigure_coffin_join:
    % coffin 的 typeset
    \__examzh_textfigure_coffin_typeset:
  }
\cs_new:Npn \__examzh_textfigure_text_width_dim_set:n #1
  {
    \str_case:VnT \l__examzh_textfigure_current_figure_position_str
      {
        {bottom-flushright} {}
        {bottom-left} {}
        {bottom-right} {}
        {bottom-center} {}
      }
      { \fp_set:Nn \l__examzh_textfigure_text_ratio_fp {1} }
    \fp_compare:nNnF { \l__examzh_textfigure_text_ratio_fp } = { 1 }
      {
        \str_case:VnT \l__examzh_textfigure_current_figure_position_str
          {
            {left} {}
            {right} {}
            {left-center} {}
            {right-center} {}
            {right-top} {}
            {right-bottom} {}
            {left-top} {}
            {left-bottom} {}
          }
          { \fp_set:Nn \l__examzh_textfigure_text_ratio_fp {0.7} }
      }
    \keys_set:nn { exam-zh / textfigure } {#1}
    \dim_set_eq:NN \l__examzh_textfigure_tmpa_dim  \l__examzh_textfigure_text_width_dim
    \dim_set:Nn \l__examzh_textfigure_text_width_dim
      {
        \l__examzh_textfigure_tmpa_dim * \dim_ratio:nn { \fp_use:N \l__examzh_textfigure_text_ratio_fp pt } { 1 pt }
      }
    \bool_if:NT \l__examzh_textfigure_auto_text_width_bool
      {
        \str_case:VnT \l__examzh_textfigure_current_figure_position_str
          {
            {left}         {}
            {right}        {}
            {left-center}  {}
            {right-center} {}
            {left-top}     {}
            {right-top}    {}
            {left-bottom}  {}
            {right-bottom} {}
          }
          { \__examzh_textfigure_auto_text_width_dim_set: }
      }
  }
\cs_new_protected:Npn \__examzh_textfigure_auto_text_width_dim_set:
  {
    \dim_set:Nn \l__examzh_textfigure_min_text_width_dim
      { \l__examzh_textfigure_min_text_width_tl }
    \dim_set:Nn \l__examzh_textfigure_text_width_dim
      {
        \linewidth
        - \coffin_wd:N \l__examzh_textfigure_figure_coffin
        - \l__examzh_textfigure_column_gap_dim
      }
    \dim_compare:nNnT
      { \l__examzh_textfigure_text_width_dim }
      < { \l__examzh_textfigure_min_text_width_dim }
      {
        \dim_set_eq:NN
          \l__examzh_textfigure_text_width_dim
          \l__examzh_textfigure_min_text_width_dim
      }
    \dim_compare:nNnT { \l__examzh_textfigure_text_width_dim } > { \linewidth }
      { \dim_set:Nn \l__examzh_textfigure_text_width_dim { \linewidth } }
  }
\cs_new:Npn \__examzh_textfigure_text_coffin_store:n #1
  {
    \hcoffin_set:Nn \l__examzh_textfigure_text_coffin 
    {
        \begin{varwidth}[t]{ \l__examzh_textfigure_text_width_dim }
          \dim_set:Nn \parindent { \l__examzh_textfigure_text_parindent_dim }
          \ignorespaces
          #1
          \unskip
        \end{varwidth}
      }
  }
\cs_new:Npn \__examzh_textfigure_figure_coffin_store:n #1
  {
    \hcoffin_set:Nn \l__examzh_textfigure_figure_coffin 
      {
        \begin{varwidth}{ \l__examzh_textfigure_figure_width_dim }
          \centering
          \ignorespaces
          #1
          \unskip
        \end{varwidth}
      }
  }
\cs_new:Npn \__examzh_textfigure_coffin_join:
  {
    \use:c { __examzh_textfigure_fig_pos_set_ \l__examzh_textfigure_current_figure_position_str :NN }
      \l__examzh_textfigure_text_coffin
      \l__examzh_textfigure_figure_coffin
  }
\cs_new:Npn \__examzh_textfigure_coffin_typeset:
  {
    \coffin_typeset:Nnnnn \l__examzh_textfigure_text_coffin
      { l } { H }
      { \l__examzh_textfigure_xshift_dim } 
      { \l__examzh_textfigure_yshift_dim }
  }

% top表示位于文本正上方
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_top:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { t } { hc }
      #2 { b } { hc }
      { \l__examzh_textfigure_figure_xshift_dim } 
      { \l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
% top-center表示位于文本上方，但是处于水平的中线处
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_top-center:NN } #1#2
  {
    \dim_set:Nn \l__examzh_textfigure_tmpa_dim 
      { \coffin_wd:N #1 }
    \dim_set:Nn \l__examzh_textfigure_figure_coffin_horizontal_transform_dim
      {
        \linewidth * \dim_ratio:nn { 1 pt } { 2 pt } 
        - 
        \l__examzh_textfigure_tmpa_dim * \dim_ratio:nn { 1 pt } { 2 pt } 
      }
    \coffin_join:NnnNnnnn
      #1 { t } { hc }
      #2 { b } { hc }
      { \l__examzh_textfigure_figure_coffin_horizontal_transform_dim + \l__examzh_textfigure_figure_xshift_dim } 
      { \l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
% bottom-center表示位于文本下方，但是处于水平的中线处
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_bottom-center:NN } #1#2
  {
    \dim_set:Nn \l__examzh_textfigure_tmpa_dim 
      { \coffin_wd:N #1 }
    \dim_set:Nn \l__examzh_textfigure_figure_coffin_horizontal_transform_dim
      {
        \linewidth * \dim_ratio:nn { 1 pt } { 2 pt } 
        - 
        \l__examzh_textfigure_tmpa_dim * \dim_ratio:nn { 1 pt } { 2 pt } 
      }
    \coffin_join:NnnNnnnn
      #1 { b } { hc }
      #2 { t } { hc }
      { \l__examzh_textfigure_figure_coffin_horizontal_transform_dim + \l__examzh_textfigure_figure_xshift_dim }
      { -\l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
% bottom 表示位于文本正下方
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_bottom:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { b } { hc }
      #2 { t } { hc }
      { \l__examzh_textfigure_figure_xshift_dim }
      { -\l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_left:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { vc } { l }
      #2 { vc } { r }
      { -\l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_xshift_dim }
      { \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_set_eq:cc { __examzh_textfigure_fig_pos_set_left-center:NN } { __examzh_textfigure_fig_pos_set_left:NN }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_left-top:NN } #1#2
  {
    \dim_set:Nn \l__examzh_textfigure_tmpa_dim
      { \baselineskip * \dim_ratio:nn { \int_use:N \l__examzh_textfigure_top_int pt } { 1pt } }
    \coffin_join:NnnNnnnn
      #1 { t } { l }
      #2 { t } { r }
      { -\l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_xshift_dim }
      { - \l__examzh_textfigure_tmpa_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_left-bottom:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { b } { l }
      #2 { b } { r }
      { -\l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_xshift_dim }
      { 0pt + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_right-top:NN } #1#2
  {
    \dim_set:Nn \l__examzh_textfigure_tmpa_dim
      { \baselineskip * \dim_ratio:nn { \int_use:N \l__examzh_textfigure_top_int pt } { 1pt } }
    \coffin_join:NnnNnnnn
      #1 { t } { r }
      #2 { t } { l }
      { \l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_xshift_dim }
      { - \l__examzh_textfigure_tmpa_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_right-center:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { vc } { r }
      #2 { vc } { l }
      { \l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_xshift_dim }
      { 0pt + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_right-bottom:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { b } { r }
      #2 { b } { l }
      { \l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_xshift_dim }
      { 0pt + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_set_eq:cc { __examzh_textfigure_fig_pos_set_right:NN } { __examzh_textfigure_fig_pos_set_right-center:NN }
% top-flushright：文本上方，水平方向是在行尾
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_top-flushright:NN } #1#2
  {
    \dim_set:Nn \l__examzh_textfigure_tmpa_dim 
      { \coffin_wd:N #1 }
    \dim_set:Nn \l__examzh_textfigure_figure_coffin_horizontal_transform_dim
      { \linewidth - \l__examzh_textfigure_tmpa_dim }
    \coffin_join:NnnNnnnn
      #1 { t } { r }
      #2 { b } { r }
      { \l__examzh_textfigure_figure_coffin_horizontal_transform_dim  + \l__examzh_textfigure_figure_xshift_dim }
      { \l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_top-right:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { t } { r }
      #2 { b } { r }
      { \l__examzh_textfigure_figure_xshift_dim }
      { \l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
% bottom-flushright：文本下方，水平方向在行尾
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_bottom-flushright:NN } #1#2
  {
    \dim_set:Nn \l__examzh_textfigure_tmpa_dim 
      { \coffin_wd:N #1 }
    \dim_set:Nn \l__examzh_textfigure_figure_coffin_horizontal_transform_dim
      { \linewidth - \l__examzh_textfigure_tmpa_dim  }
    \coffin_join:NnnNnnnn
      #1 { b } { r }
      #2 { t } { r }
      { \l__examzh_textfigure_figure_coffin_horizontal_transform_dim + \l__examzh_textfigure_figure_xshift_dim }
      { -\l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_bottom-right:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { b } { r }
      #2 { t } { r }
      { \l__examzh_textfigure_figure_xshift_dim }
      { -\l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_top-left:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { t } { l }
      #2 { b } { l }
      { 0pt + \l__examzh_textfigure_figure_xshift_dim }
      { \l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }
\cs_new_protected:cpn { __examzh_textfigure_fig_pos_set_bottom-left:NN } #1#2
  {
    \coffin_join:NnnNnnnn
      #1 { b } { l }
      #2 { t } { l }
      { 0pt + \l__examzh_textfigure_figure_xshift_dim }
      { -\l__examzh_textfigure_column_gap_dim + \l__examzh_textfigure_figure_yshift_dim }
  }

\tl_new:N \g__examzh_font_font_tl
\tl_new:N \g__examzh_font_math_font_tl

\keys_define:nn { exam-zh }
  {
    font .choices:nn =
      {
        garamond ,
        libertinus ,
        lm ,
        newcm ,
        pala ,
        stix ,
        termes ,
        times ,
        xits ,
        none
      }
      {
        \tl_gset_eq:NN \g__examzh_font_font_tl \l_keys_choice_tl
        \use:c { examzh_font_set_font_ \g__examzh_font_font_tl : }
      } ,
    math-font .choices:nn =
      {
        asana ,
        cambria ,
        garamond ,
        libertinus ,
        lm ,
        newcm ,
        pala ,
        stix ,
        termes ,
        xits ,
        none
      }
      {
        \tl_gset_eq:NN \g__examzh_font_math_font_tl \l_keys_choice_tl
        \use:c { examzh_font_set_math_font_ \g__examzh_font_math_font_tl : }
      } ,
  }


% New Computer Modern
\cs_new:Npn \examzh_font_set_font_newcm:
  {
    \setmainfont { NewCM10 }
      [
        Extension      = .otf ,
        UprightFont    = *-Book ,
        BoldFont       = *-Bold ,
        ItalicFont     = *-BookItalic ,
        BoldItalicFont = *-BoldItalic ,
      ]
    \setsansfont { NewCMSans10 }
      [
        Extension         = .otf ,
        UprightFont       = *-Book ,
        BoldFont          = *-Bold ,
        ItalicFont        = *-BookOblique ,
        BoldItalicFont    = *-BoldOblique ,
      ]
    \setmonofont { NewCMMono10 }
      [
        Extension           = .otf ,
        UprightFont         = *-Book ,
        ItalicFont          = *-BookItalic ,
        BoldFont            = *-Bold ,
        BoldItalicFont      = *-BoldOblique ,
      ]
  }


% Latin Modern
\cs_new:Npn \examzh_font_set_font_lm:
  {
    \setmainfont { lmroman10 }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-italic ,
        BoldItalicFont = *-bolditalic ,
      ]
    \setsansfont { lmsans10 }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-oblique ,
        BoldItalicFont = *-boldoblique ,
      ]
    \setmonofont { lmmonolt10 }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-oblique ,
        BoldItalicFont = *-boldoblique ,
      ]
  }


% Times New Roman + Arial
\cs_new:Npn \examzh_font_set_font_times:
  {
    \setmainfont { Times~ New~ Roman }
    \setsansfont { Arial } [ Scale = MatchLowercase ]
    \setmonofont { Courier~ New } [ Scale = MatchLowercase ]
  }


% TeX Gyre Termes
\cs_new:Npn \examzh_font_set_font_termes:
  {
    \setmainfont { texgyretermes }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-italic ,
        BoldItalicFont = *-bolditalic ,
      ]
    \examzh_font_set_tex_gyre_sans_mono:
  }


% Garamond (实际上是 EB Garamond)
\cs_new:Npn \examzh_font_set_font_garamond:
  {
    \setmainfont { EBGaramond }
      [
        Extension      = .otf ,
        UprightFont    = *-Regular ,
        BoldFont       = *-Bold ,
        ItalicFont     = *-Italic ,
        BoldItalicFont = *-BoldItalic ,
      ]
    \setsansfont { LinBiolinum }
      [
        Extension      = .otf ,
        UprightFont    = *_R ,
        BoldFont       = *_RB ,
        ItalicFont     = *_RI ,
        BoldItalicFont = *_RBO ,
      ]
    \setmonofont { texgyrecursor }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-italic ,
        BoldItalicFont = *-bolditalic ,
      ]
  }


% Palatino (TeX Gyre Pagella)
\cs_new:Npn \examzh_font_set_font_pala:
  {
    \setmainfont { texgyrepagella }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-italic ,
        BoldItalicFont = *-bolditalic ,
      ]
    \examzh_font_set_tex_gyre_sans_mono:
  }

% TeX Gyre Heros / Cursor
\cs_new:Npn \examzh_font_set_tex_gyre_sans_mono:
  {
    \setsansfont { texgyreheros }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-italic ,
        BoldItalicFont = *-bolditalic ,
        Scale          = MatchLowercase ,
      ]
    \setmonofont { texgyrecursor }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-italic ,
        BoldItalicFont = *-bolditalic ,
        Scale          = MatchLowercase ,
        Ligatures      = CommonOff ,
      ]
  }


% STIX Two 字体。
% STIX 文件名在 v2.10 2020-12-19 从
% \file{STIX2Text-Regular.otf}、\file{STIX2Math.otf} 分别改为
% \file{STIXTwoText-Regular.otf}、\file{STIXTwoMath-Regular.otf}。
\tl_new:N \g__examzh_font_font_family_stix_tl
\tl_new:N \g__examzh_font_font_name_stix_math_tl
\cs_new:Npn \examzh_font_set_stix_names:
  {
    \tl_if_empty:NT \g__examzh_font_font_family_stix_tl
      {
        \fontspec_font_if_exist:nTF { STIXTwoText-Regular.otf }
          {
            \tl_gset:Nn \g__examzh_font_font_family_stix_tl { STIXTwoText }
            \tl_gset:Nn \g__examzh_font_font_name_stix_math_tl { STIXTwoMath-Regular }
          }
          {
            \tl_gset:Nn \g__examzh_font_font_family_stix_tl { STIX2Text }
            \tl_gset:Nn \g__examzh_font_font_name_stix_math_tl { STIX2Math }
          }
      }
  }

\cs_new:Npn \examzh_font_set_font_stix:
  {
    \examzh_font_set_stix_names:
    \setmainfont { \g__examzh_font_font_family_stix_tl }
      [
        Extension      = .otf ,
        UprightFont    = *-Regular ,
        BoldFont       = *-Bold ,
        ItalicFont     = *-Italic ,
        BoldItalicFont = *-BoldItalic ,
      ]
    \examzh_font_set_tex_gyre_sans_mono:
  }


% XITS 字体。
% XITS 的文件名在 v1.109 2018-09-30
% 从 \file{xits-regular.otf}、\file{xits-math.otf} 分别改为
% \file{XITS-Regular.otf}、\file{XITSMath-Regular.otf}。
\tl_new:N \g__examzh_font_font_family_xits_tl
\tl_new:N \g__examzh_font_font_style_xits_rm_tl
\tl_new:N \g__examzh_font_font_style_xits_bf_tl
\tl_new:N \g__examzh_font_font_style_xits_it_tl
\tl_new:N \g__examzh_font_font_style_xits_bfit_tl
\tl_new:N \g__examzh_font_font_name_xits_math_tl

\cs_new:Npn \examzh_font_set_xits_names:
  {
    \tl_if_empty:NT \g__examzh_font_font_family_xits_tl
      {
        \fontspec_font_if_exist:nTF { XITSMath-Regular.otf }
          {
            \tl_gset:Nn \g__examzh_font_font_family_xits_tl { XITS }
            \tl_gset:Nn \g__examzh_font_font_style_xits_rm_tl { Regular }
            \tl_gset:Nn \g__examzh_font_font_style_xits_bf_tl { Bold }
            \tl_gset:Nn \g__examzh_font_font_style_xits_it_tl { Italic }
            \tl_gset:Nn \g__examzh_font_font_style_xits_bfit_tl { BoldItalic }
            \tl_gset:Nn \g__examzh_font_font_name_xits_math_tl { XITSMath-Regular }
          }
          {
            \tl_gset:Nn \g__examzh_font_font_family_xits_tl { xits }
            \tl_gset:Nn \g__examzh_font_font_style_xits_rm_tl { regular }
            \tl_gset:Nn \g__examzh_font_font_style_xits_bf_tl { bold }
            \tl_gset:Nn \g__examzh_font_font_style_xits_it_tl { italic }
            \tl_gset:Nn \g__examzh_font_font_style_xits_bfit_tl { bolditalic }
            \tl_gset:Nn \g__examzh_font_font_name_xits_math_tl { xits-math }
          }
      }
  }

\cs_new:Npn \examzh_font_set_font_xits:
  {
    \examzh_font_set_xits_names:
    \setmainfont { \g__examzh_font_font_family_xits_tl }
      [
        Extension      = .otf ,
        UprightFont    = *-\g__examzh_font_font_style_xits_rm_tl ,
        BoldFont       = *-\g__examzh_font_font_style_xits_bf_tl ,
        ItalicFont     = *-\g__examzh_font_font_style_xits_it_tl ,
        BoldItalicFont = *-\g__examzh_font_font_style_xits_bfit_tl ,
      ]
    \examzh_font_set_tex_gyre_sans_mono:
  }


% Libertinus 的文件名在 v6.7 2019-04-03 从小写改为驼峰式，
% 在大小写敏感的平台上需要进行判断。
\tl_new:N \g__examzh_font_font_family_libertinus_serif_tl
\tl_new:N \g__examzh_font_font_family_libertinus_sans_tl
\tl_new:N \g__examzh_font_font_style_libertinus_rm_tl
\tl_new:N \g__examzh_font_font_style_libertinus_bf_tl
\tl_new:N \g__examzh_font_font_style_libertinus_it_tl
\tl_new:N \g__examzh_font_font_style_libertinus_bfit_tl
\tl_new:N \g__examzh_font_font_name_libertinus_math_tl

\cs_new:Npn \examzh_font_set_libertinus_names:
  {
    \tl_if_empty:NT \g__examzh_font_font_family_libertinus_serif_tl
      {
        \fontspec_font_if_exist:nTF { LibertinusSerif-Regular.otf }
          {
            \tl_gset:Nn \g__examzh_font_font_family_libertinus_serif_tl { LibertinusSerif }
            \tl_gset:Nn \g__examzh_font_font_family_libertinus_sans_tl { LibertinusSans }
            \tl_gset:Nn \g__examzh_font_font_style_libertinus_rm_tl { Regular }
            \tl_gset:Nn \g__examzh_font_font_style_libertinus_bf_tl { Bold }
            \tl_gset:Nn \g__examzh_font_font_style_libertinus_it_tl { Italic }
            \tl_gset:Nn \g__examzh_font_font_style_libertinus_bfit_tl { BoldItalic }
            \tl_gset:Nn \g__examzh_font_font_name_libertinus_math_tl { LibertinusMath-Regular }
          }
          {
            \tl_gset:Nn \g__examzh_font_font_family_libertinus_serif_tl { libertinusserif }
            \tl_gset:Nn \g__examzh_font_font_family_libertinus_sans_tl { libertinussans }
            \tl_gset:Nn \g__examzh_font_font_style_libertinus_rm_tl { regular }
            \tl_gset:Nn \g__examzh_font_font_style_libertinus_bf_tl { bold }
            \tl_gset:Nn \g__examzh_font_font_style_libertinus_it_tl { italic }
            \tl_gset:Nn \g__examzh_font_font_style_libertinus_bfit_tl { bolditalic }
            \tl_gset:Nn \g__examzh_font_font_name_libertinus_math_tl { libertinusmath-regular }
          }
      }
  }

\cs_new:Npn \examzh_font_set_font_libertinus:
  {
    \examzh_font_set_libertinus_names:
    \setmainfont { \g__examzh_font_font_family_libertinus_serif_tl }
      [
        Extension      = .otf ,
        UprightFont    = *-\g__examzh_font_font_style_libertinus_rm_tl ,
        BoldFont       = *-\g__examzh_font_font_style_libertinus_bf_tl ,
        ItalicFont     = *-\g__examzh_font_font_style_libertinus_it_tl ,
        BoldItalicFont = *-\g__examzh_font_font_style_libertinus_bfit_tl ,
      ]
    \setsansfont { \g__examzh_font_font_family_libertinus_sans_tl }
      [
        Extension      = .otf ,
        UprightFont    = *-\g__examzh_font_font_style_libertinus_rm_tl ,
        BoldFont       = *-\g__examzh_font_font_style_libertinus_bf_tl ,
        ItalicFont     = *-\g__examzh_font_font_style_libertinus_it_tl ,
      ]
    \setmonofont { lmmonolt10 }
      [
        Extension      = .otf ,
        UprightFont    = *-regular ,
        BoldFont       = *-bold ,
        ItalicFont     = *-oblique ,
        BoldItalicFont = *-boldoblique ,
      ]
  }


% 数学字体

% 按照国标样式配置 unicode-math

\tl_new:N \l__examzh_save_leq_tl
\tl_new:N \l__examzh_save_geq_tl

\AtEndOfPackageFile* { unicode-math }
  {
    \unimathsetup
      {
        math-style = ISO ,
        bold-style = ISO ,
        partial    = upright ,
      }
    \AtBeginDocument
      {
        \tl_set_eq:NN \leq \l__examzh_save_leq_tl
        \tl_set_eq:NN \geq \l__examzh_save_geq_tl
        \tl_set_eq:NN \leq \leqslant
        \tl_set_eq:NN \geq \geqslant
      }
    \cs_set_protected:Npn \mathellipsis { \mathinner { \unicodecdots } }
  }


% 数学符号样式

% \tl_new:N \l__examzh_font_uppercase_greek_tl
% \tl_new:N \l__examzh_font_leq_style_tl
\tl_new:N \l__examzh_font_integral_style_tl
% \bool_new:N \l__examzh_font_integral_limits_bool
% \tl_new:N \l__examzh_font_partial_style_tl
% \tl_new:N \l__examzh_font_math_ellipsis_tl
% \tl_new:N \l__examzh_font_real_part_tl

\tl_set:Nn \l__examzh_font_integral_style_tl { upright }

% \keys_define:nn { exam-zh }
%   {
%     math-style .choices:nn =
%       { GB , ISO , TeX }
%       { \exp_args:NV \examzh_font_set_math_style:n \l_keys_choice_tl } ,
%     uppercase-greek .choices:nn =
%       { italic , upright }
%       { \tl_set_eq:NN \l__examzh_font_uppercase_greek_tl \l_keys_choice_tl } ,
%     less-than-or-equal .choices:nn =
%       { slanted , horizontal }
%       { \tl_set_eq:NN \l__examzh_font_leq_style_tl \l_keys_choice_tl } ,
%     integral .choices:nn =
%       { upright , slanted }
%       { \tl_set_eq:NN \l__examzh_font_integral_style_tl \l_keys_choice_tl } ,
%     integral-limits .bool_set:N = \l__examzh_font_integral_limits_bool ,
%     partial .choices:nn =
%       { upright , slanted }
%       { \tl_set_eq:NN \l__examzh_font_partial_style_tl \l_keys_choice_tl } ,
%     math-ellipsis .choices:nn =
%       { centered , lower , AMS }
%       { \tl_set_eq:NN \l__examzh_font_math_ellipsis_tl \l_keys_choice_tl } ,
%     real-part .choices:nn =
%       { roman , fraktur }
%       { \tl_set_eq:NN \l__examzh_font_real_part_tl \l_keys_choice_tl } ,
%   }



% New Computer Modern Math

\tl_new:N \l__examzh_font_stylistic_set_tl

\cs_new:Npn \examzh_font_set_math_font_newcm:
  {
    % \examzh_font_load_unimath:
    % \examzh_font_set_unimath_style:
    \tl_if_eq:NnTF \l__examzh_font_integral_style_tl { upright }
      { \tl_set:Nn \l__examzh_font_stylistic_set_tl { 2 } }
      { \tl_clear:N \l__examzh_font_stylistic_set_tl }
    \setmathfont { NewCMMath-Book }
      [
        Extension    = .otf,
        StylisticSet = \l__examzh_font_stylistic_set_tl ,
      ]
    \setmathfont { NewCMMath-Book }
      [
        Extension    = .otf,
        StylisticSet = 1,
        range        = { scr , bfscr } ,
      ]
    \examzh_font_set_stix_names:
    \setmathfont { \g__examzh_font_font_name_stix_math_tl }
      [
        Extension    = .otf,
        range        = { \complement, \bigstar } ,
      ]
    \setmathrm { NewCM10 }
      [
        Extension      = .otf,
        UprightFont    = *-Book,
        BoldFont       = *-Bold,
        ItalicFont     = *-BookItalic,
        BoldItalicFont = *-BoldItalic,
      ]
    \setmathsf { NewCMSans10 }
      [
        Extension      = .otf,
        UprightFont    = *-Book,
        BoldFont       = *-Bold,
        ItalicFont     = *-BookOblique,
        BoldItalicFont = *-BoldOblique,
      ]
    \setmathtt { NewCMMono10 }
      [
        Extension      = .otf,
        UprightFont    = *-Book,
        ItalicFont     = *-BookItalic,
        BoldFont       = *-Bold,
        BoldItalicFont = *-BoldOblique,
      ]
  }


% Latin Modern Math
\cs_new:Npn \examzh_font_set_math_font_lm:
  {
    % \examzh_font_load_unimath:
    % \examzh_font_set_unimath_style:
    \setmathfont { latinmodern-math } [ Extension = .otf ]
    \examzh_font_set_stix_names:
    \setmathfont { \g__examzh_font_font_name_stix_math_tl }
      [
        Extension    = .otf,
        range        = { \complement, \bigstar } ,
      ]
    \setmathrm { lmroman10 }
      [
        Extension      = .otf,
        UprightFont    = *-regular,
        BoldFont       = *-bold,
        ItalicFont     = *-italic,
        BoldItalicFont = *-bolditalic,
      ]
    \setmathsf { lmsans10 }
      [
        Extension      = .otf,
        UprightFont    = *-regular,
        BoldFont       = *-bold,
        ItalicFont     = *-oblique,
        BoldItalicFont = *-boldoblique,
      ]
    \setmathtt { lmmonolt10 }
      [
        Extension      = .otf,
        UprightFont    = *-regular,
        BoldFont       = *-bold,
        ItalicFont     = *-oblique,
        BoldItalicFont = *-boldoblique,
      ]
  }


% STIX Two Math
\cs_new:Npn \examzh_font_set_math_font_stix:
  {
    % \examzh_font_load_unimath:
    % \examzh_font_set_unimath_style:
    \examzh_font_set_stix_names:
    \tl_if_eq:NnTF \l__examzh_font_integral_style_tl { upright }
      { \tl_set:Nn \l__examzh_font_stylistic_set_tl { 8 } }
      { \tl_clear:N \l__examzh_font_stylistic_set_tl }
    \setmathfont { \g__examzh_font_font_name_stix_math_tl }
      [
        Extension    = .otf,
        StylisticSet = \l__examzh_font_stylistic_set_tl,
      ]
    \setmathfont { \g__examzh_font_font_name_stix_math_tl }
      [
        Extension    = .otf,
        StylisticSet = 1,
        range        = { scr , bfscr },
      ]
  }


% XITS Math
\cs_new:Npn \examzh_font_set_math_font_xits:
  {
    % \examzh_font_load_unimath:
    % \examzh_font_set_unimath_style:
    \examzh_font_set_xits_names:
    \tl_if_eq:NnTF \l__examzh_font_integral_style_tl { upright }
      { \tl_set:Nn \l__examzh_font_stylistic_set_tl { 8 } }
      { \tl_clear:N \l__examzh_font_stylistic_set_tl }
    \setmathfont { \g__examzh_font_font_name_xits_math_tl }
      [
        Extension    = .otf ,
        StylisticSet = \l__examzh_font_stylistic_set_tl ,
      ]
    \setmathfont { \g__examzh_font_font_name_xits_math_tl }
      [
        Extension    = .otf ,
        StylisticSet = 1 ,
        range        = { cal , bfcal } ,
      ]
  }

% Libertinus Math
\cs_new:Npn \examzh_font_set_math_font_libertinus: {
  % \examzh_font_load_unimath:
  % \examzh_font_set_unimath_style:
  \examzh_font_set_libertinus_names:
  \tl_if_eq:NnTF \l__examzh_font_integral_style_tl { slanted }
    { \tl_set:Nn \l__examzh_font_stylistic_set_tl { 8 } }
    { \tl_clear:N \l__examzh_font_stylistic_set_tl }
  \setmathfont { \g__examzh_font_font_name_libertinus_math_tl }
    [
      Extension    = .otf,
      StylisticSet = \l__examzh_font_stylistic_set_tl,
    ]
  \examzh_font_set_stix_names:
  \setmathfont { \g__examzh_font_font_name_stix_math_tl }
    [
      Extension    = .otf,
      range        = { \complement } ,
    ]
}


% Cambria Math
\cs_new:Npn \examzh_font_set_math_font_cambria: {
  % \examzh_font_load_unimath:
  % \examzh_font_set_unimath_style:
  \setmathfont { Cambria~ Math }
  \examzh_font_set_stix_names:
  \setmathfont { \g__examzh_font_font_name_stix_math_tl }
    [
      Extension    = .otf,
      range        = { \complement, \bigstar } ,
    ]
  \message
    {
      Please~note~that~the~Cambria~font~family~cannot~be~used~on~commercial~purpose~unless~you~are~using~Windows~7/8/10/11~PROFESSIONAL.
    }
}

% 新增的 asana, garamond, pala
\cs_new:Npn \examzh_font_set_math_font_asana: 
  {
    \setmathfont { Asana-Math.otf }
    \examzh_font_set_stix_names:
    \setmathfont { \g__examzh_font_font_name_stix_math_tl }
      [
        Extension    = .otf,
        range        = { \complement } ,
      ]
  }

\cs_new:Npn \examzh_font_set_math_font_garamond: 
  {
    \setmathfont { Garamond-Math.otf }
    \examzh_font_set_stix_names:
    \setmathfont { \g__examzh_font_font_name_stix_math_tl }
      [
        Extension    = .otf,
        range        = { \complement } ,
      ]
  }

\cs_new:Npn \examzh_font_set_math_font_pala: 
  {
    \setmathfont { texgyrepagella-math.otf }
    \examzh_font_set_stix_names:
    \setmathfont { \g__examzh_font_font_name_stix_math_tl }
      [
        Extension    = .otf,
        range        = { \complement, \bigstar } ,
      ]
  }



\AtEndPreamble
  {
    \tl_if_empty:NT \g__examzh_font_font_tl
      { \keys_set:nn { exam-zh } { font = newcm } }
    \tl_if_empty:NT \g__examzh_font_math_font_tl
      { \keys_set:nn { exam-zh } { math-font = newcm } }
  }


% unicode-math 的配置

% 兼容旧的粗体命令：\pkg{bm} 的 \cs{bm} 和 \pkg{amsmath} 的 \cs{boldsymbol}。
\AtEndOfPackageFile* { unicode-math }
  {
    \NewDocumentCommand \bm { m } 
      { 
        \tl_if_head_eq_catcode:nNTF { ##1 } A 
          { \symbfit{#1} }
          { 
            #1 
            \PackageWarning { exam-zh-font } 
              { 
                Do~not~use~\string\bm \space ~with~`unicode-math',~normal~font~instead. 
              }
          }
      }
    \RenewDocumentCommand \boldsymbol { } { \bm }
    % 兼容 \pkg{amsfonts} 和 \pkg{amssymb} 中的一些命令。
    \NewDocumentCommand \square { } { \mdlgwhtsquare }
    \NewDocumentCommand \blacksquare { } { \mdlgblksquare }
    \AtBeginDocument { \RenewDocumentCommand \checkmark { } { \ensuremath{ ✓ } } }
  }

  \keys_define:nn { exam-zh }
  { select .meta:nn = { exam-zh / select } {#1} }


% 选择环境 select
\str_new:N \l__examzh_select_mark_position_str   % mark 的方位

\keys_define:nn { exam-zh / select }
  {
    mark-symbol .tl_set:N = \l__examzh_select_mark_symbol_tl,
    mark-position .code:n =
      {
        \str_set:Nn \l__examzh_select_mark_position_str {#1}
      },
    mark-xshift .dim_set:N = \l__examzh_select_mark_xshift_dim,
    mark-yshift .dim_set:N = \l__examzh_select_mark_yshift_dim,
    separator .tl_set:N = \l__examzh_select_separator_tl,
    pre-content .tl_set:N = \l__examzh_select_pre_content_tl,
    post-content .tl_set:N = \l__examzh_select_post_content_tl,
    show-mark .bool_set:N = \l__examzh_select_show_mark_bool
  }
\keys_set:nn { exam-zh / select }
  {
    mark-symbol   = $\checkmark$,
    mark-position = right,
    mark-xshift   = 0pt,
    mark-yshift   = 0pt,
    separator     = \hspace{1em},
    pre-content   = (,
    post-content  = ),
    show-mark     = false
  }

\seq_new:N \l__examzh_select_seq      % 储存输入的内容

\NewDocumentEnvironment { select } { O{ } +b }
  {
    % 可选参数
    \keys_set:nn { exam-zh / select } {#1}
  }
  {
    % 检测 mark-position 的输入
    \__examzh_chinese_select_coffin_position_test:
    % 对输入用 \item 进行分割
    \seq_set_split:Nnn \l__examzh_select_seq { \sitem } {#2}
    \seq_if_empty:NF \l__examzh_select_seq
      { \seq_pop_left:NN \l__examzh_select_seq \l_tmpa_tl }
    % 将内容和 mark 符号存入 coffin 并拼接输出
    \__examzh_chinese_select_coffin_set_print:N
      \l__examzh_select_seq
  }
\cs_new:Npn \__examzh_chinese_select_coffin_set_print:N #1
% #1:\l__examzh_select_seq
  {
    % 前置内容
    \l__examzh_select_pre_content_tl
    % 主体部分
    \seq_map_indexed_inline:Nn #1
    % ##1: index
    % ##2: content
      {
        % coffin 的声明
        \__examzh_chinese_select_coffin_new:n {##1}
        % 看 seq 的项是否开头是 *，是的话去掉 * 和空格存到 content coffin 并且在 mark coffin 里加入 mark，不是的话就只存到 content coffin
        \__examzh_chinese_select_coffin_set:nn {##1} {##2}
        \bool_if:NT \l__examzh_select_show_mark_bool
          {
            % 拼接 content coffin 和 mark coffin
            \__examzh_chinese_select_coffin_join:n {##1}
          }
        % 输出 content coffin
        \__examzh_chinese_select_coffin_typeset:n {##1}
      }
    % 后置内容
    \l__examzh_select_post_content_tl
  }
\cs_new:Npn \__examzh_chinese_select_coffin_new:n #1
  {
    % 检测是否存在，没有的话就 new 一个
    \coffin_if_exist:cF { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin }
      { \coffin_new:c { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin } }
    \coffin_if_exist:cF { l__examzh_select_mark_ \int_to_roman:n {#1} _ coffin }
      { \coffin_new:c { l__examzh_select_mark_ \int_to_roman:n {#1} _ coffin } }
  }
\cs_new:Npn \__examzh_chinese_select_coffin_set:nn #1#2
% #1: index
% #2: content
  {
    \tl_if_head_eq_meaning:nNTF {#2} *
      {
        % 将去掉 * 号后的内容保存进 \l_tmpa_tl
        \tl_set:Nx \l_tmpa_tl { \tl_tail:n {#2} }
        % 去掉 * 和内容之间的空格
        \tl_trim_spaces:N \l_tmpa_tl
        % 将处理后的内容存到 content coffin 里
        \hcoffin_set:cn { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin } 
          { \l_tmpa_tl }
        % 将 marksymbol 存到对应的第 #1 个 mark coffin 里
        \hcoffin_set:cn { l__examzh_select_mark_ \int_to_roman:n {#1} _ coffin } 
          { \l__examzh_select_mark_symbol_tl }
      }
      {
        % 不带 * 的直接存 coffin
        \hcoffin_set:cn { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin } 
          {#2}
      }
  }
\msg_new:nnn { exam-zh / chinese } { select-no-mark-position }
  {
    There~is~no~position~named~#1 .\\
    Please~read~the~manual~carefully.
  }
\cs_new:Npn \__examzh_chinese_select_coffin_position_test:
  {
    \str_case:VnF \l__examzh_select_mark_position_str
      {
        { top } { }
        { above } { }
        { bottom } { }
        { below } { }
        { left } { }
        { right } { }
      }
      {
        \msg_error:nnx { exam-zh / chinese } { select-no-mark-position } { \l__examzh_select_mark_position_str }
      }
  }
\cs_new:Npn \__examzh_chinese_select_coffin_join:n #1
% #1: index
  {
    \use:c { __examzh_chinese_select_coffin_join_ \l__examzh_select_mark_position_str :n } {#1}
  }
\cs_new:Npn \__examzh_chinese_select_coffin_join_top:n #1
  {
    \coffin_join:cnncnnnn
      { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin }
      { hc } { t }
      { l__examzh_select_mark_ \int_to_roman:n {#1} _ coffin }
      { hc } { b }
      { \l__examzh_select_mark_xshift_dim }
      { \l__examzh_select_mark_yshift_dim + 2pt }
  }
\cs_set_eq:NN 
  \__examzh_chinese_select_coffin_join_above:n 
  \__examzh_chinese_select_coffin_join_top:n
\cs_new:Npn \__examzh_chinese_select_coffin_join_bottom:n #1
  {
    \coffin_join:cnncnnnn
      { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin }
      { hc } { H }
      { l__examzh_select_mark_ \int_to_roman:n {#1} _ coffin }
      { hc } { t }
      { \l__examzh_select_mark_xshift_dim }
      { \l__examzh_select_mark_yshift_dim - 2pt }
  }
\cs_set_eq:NN 
  \__examzh_chinese_select_coffin_join_below:n 
  \__examzh_chinese_select_coffin_join_bottom:n
\cs_new:Npn \__examzh_chinese_select_coffin_join_left:n #1
  {
    \coffin_join:cnncnnnn
      { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin }
      { l } { H }
      { l__examzh_select_mark_ \int_to_roman:n {#1} _ coffin }
      { r } { H }
      { \l__examzh_select_mark_xshift_dim }
      { \l__examzh_select_mark_yshift_dim }
  }
\cs_new:Npn \__examzh_chinese_select_coffin_join_right:n #1
  {
    \coffin_join:cnncnnnn
      { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin }
      { r } { H }
      { l__examzh_select_mark_ \int_to_roman:n {#1} _ coffin }
      { l } { H }
      { \l__examzh_select_mark_xshift_dim }
      { \l__examzh_select_mark_yshift_dim }
  }
\cs_new:Npn \__examzh_chinese_select_coffin_typeset:n #1
  {
    \int_compare:nNnTF {#1} = {1}
      {
        \coffin_typeset:cnnnn 
          { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin }
          {l} {H} {0pt} {0pt}
      }
      {
        \l__examzh_select_separator_tl
        \coffin_typeset:cnnnn 
          { l__examzh_select_content_ \int_to_roman:n {#1} _ coffin }
          {l} {H} {0pt} {0pt}
      }
  }


% 连线题 lineto
\clist_clear_new:N \l__examzh_lineto_list_set_clist 
\int_zero_new:N \l__examzh_lineto_node_index_int 

\keys_define:nn { exam-zh }
  { lineto .meta:nn = { exam-zh / lineto } {#1} }

\keys_define:nn { exam-zh / lineto }
  {
    xsep  .dim_set:N = \l__examzh_lineto_node_xsep_dim,
    ysep  .dim_set:N = \l__examzh_lineto_node_ysep_dim,
    name  .tl_set:N  = \l__examzh_lineto_name_tl,
    list-style .tl_set:N  = \l__examzh_lineto_list_style_tl 
  }
\keys_set:nn { exam-zh / lineto }
  {
    xsep = .25\linewidth,
    ysep = 1cm,
    name = \int_to_roman:n { \l__examzh_lineto_node_index_int }
  }


\NewDocumentEnvironment { lineto } { O{ } }
  {
    \begin{center}
      \begin{tikzpicture}[#1]
  }
  {
      \end{tikzpicture}
    \end{center}
  }


\NewDocumentCommand { \linelistset } { O{} m }
  {
    \int_incr:N \l__examzh_lineto_node_index_int  
    \group_begin:
      \keys_set:nn { exam-zh / lineto } {#1}
      \clist_set:Nn \l__examzh_lineto_list_set_clist {#2}
      \int_step_inline:nnn {1} 
        { \clist_count:N \l__examzh_lineto_list_set_clist }
        {
          \use:x
            {
              \exp_not:N \node
                [
                  name   = \l__examzh_lineto_name_tl - ##1,
                  \l__examzh_lineto_list_style_tl
                ] 
              at 
                (
                  \l__examzh_lineto_node_index_int * \l__examzh_lineto_node_xsep_dim,
                  - \int_eval:n { ##1 - 1 } * \l__examzh_lineto_node_ysep_dim
                ) 
                { \clist_item:Nn \l__examzh_lineto_list_set_clist {##1} }; 
            }
        }
    \group_end:
  }

\NewDocumentCommand { \lineconnect }{ O{} +m }
  {
    \clist_set:Nn \l_tmpa_clist {#2}
    \int_step_inline:nn { \clist_count:N \l_tmpa_clist - 1 }
      {
        \use:x
          {
            \exp_not:N \draw
              [line~cap = round, #1] 
              ( \clist_item:Nn \l_tmpa_clist {##1} .east ) 
                -- 
              ( \clist_item:Nn \l_tmpa_clist { ##1 + 1 } .west ); 
          }
      }
  }


% 语文的文章 材料
\keys_define:nn { exam-zh / material }
  {
    title .tl_set:N = \l__examzh_material_title_content_tl,
    title-format .tl_set:N = \l__examzh_material_title_format_tl,
    title-material-sep .skip_set:N = \l__examzh_material_title_material_sep_skip,
    format .tl_set:N = \l__examzh_material_format_tl,
    top-sep .skip_set:N = \l__examzh_material_top_sep_skip,
    bottom-sep .skip_set:N = \l__examzh_material_bottom_sep_skip,
    author .tl_set:N = \l__examzh_material_author_content_tl,
    author-format .tl_set:N = \l__examzh_material_author_format_tl,
    title-author-sep .skip_set:N = \l__examzh_material_title_author_sep_skip,
    source .tl_set:N = \l__examzh_material_source_content_tl,
    source-format .tl_set:N = \l__examzh_material_source_format_tl,
  }

\keys_set:nn { exam-zh / material }
  {
    title-format        = \zihao{4},
    author-format       = \small,
    format              = \kaishu,
    title-author-sep    = 2em,
    top-sep             = 0pt,
    bottom-sep          = 0pt,
    title-material-sep  = 0pt,
  }

\NewDocumentEnvironment { material } { O{ } +b }
  {
    \par
    \keys_set:nn { exam-zh / material } {#1}
    \addvspace { \l__examzh_material_top_sep_skip }
    \__examzh_material_title_author_type:
    \group_begin:
      \l__examzh_material_format_tl
      #2
    \group_end:
  }
  {
    \tl_if_empty:NF \l__examzh_material_source_content_tl
      {
        \par
        \group_begin:
          \hfill
          \begin{varwidth}{\textwidth}
            \raggedleft
            \l__examzh_material_source_format_tl
            \l__examzh_material_source_content_tl
          \end{varwidth}
        \group_end:
      }
    \par
    \addvspace { \l__examzh_material_bottom_sep_skip }
    \par
  }

\cs_new:Npn \__examzh_material_title_author_type:
  {
    \tl_if_empty:NF \l__examzh_material_title_content_tl
      {
        \noindent \hfill
          \group_begin:
            \l__examzh_material_title_format_tl
            \l__examzh_material_title_content_tl
          \group_end:
          \tl_if_empty:NF \l__examzh_material_author_content_tl
            {
              \hspace { \l__examzh_material_title_author_sep_skip }
              \group_begin:
                \l__examzh_material_author_format_tl
                \l__examzh_material_author_content_tl
              \group_end:
            }
        \hfill \null
        \par
        \addvspace { \l__examzh_material_title_material_sep_skip }
      }
  }


% 古诗 
\bool_new:N \l__examzh_poem_type_minipage_bool
\bool_set_true:N \l__examzh_poem_type_minipage_bool 
\int_new:N \l__examzh_poem_zhu_index_int
\seq_new:N \g__examzh_poem_zhu_store_seq
\str_new:N \l__examzh_poem_zhu_circlednumber_base_str

\keys_define:nn { exam-zh / poem }
  {
    title .tl_set:N = \l__examzh_poem_title_content_tl,
    title-format .tl_set:N = \l__examzh_poem_title_format_tl,
    title-poem-sep .skip_set:N = \l__examzh_poem_title_poem_sep_skip,
    format .tl_set:N = \l__examzh_poem_format_tl,
    top-sep .skip_set:N = \l__examzh_poem_top_sep_skip,
    bottom-sep .skip_set:N = \l__examzh_poem_bottom_sep_skip,
    author .tl_set:N = \l__examzh_poem_author_content_tl,
    author-format .tl_set:N = \l__examzh_poem_author_format_tl,
    title-author-sep .skip_set:N = \l__examzh_poem_title_author_sep_skip,
    type .choice:,
    type / minipage .code:n = { \bool_set_true:N \l__examzh_poem_type_minipage_bool },
    type / chinese .code:n = { \bool_set_false:N \l__examzh_poem_type_minipage_bool },
    align .choices:nn =
      { l , c , r }
      { \tl_set:Nx \l__examzh_poem_align_tl { \l_keys_choice_tl } },
    zhu-circlednumber-base .choices:nn = 
      { tikz, font }
      { \str_set:Nx \l__examzh_poem_zhu_circlednumber_base_str { \l_keys_choice_tl } }
  }

\keys_set:nn { exam-zh / poem }
  {
    title-format           = \zihao{5},
    author-format          = \small,
    format                 = \kaishu,
    title-author-sep       = 2em,
    top-sep                = 0pt,
    bottom-sep             = 1em,
    title-poem-sep         = 0.25\baselineskip,
    type                   = chinese,
    align                  = l,
    zhu-circlednumber-base = font
  }

\NewDocumentEnvironment { poem } { O{ } +b }
  {
    \par
    \keys_set:nn { exam-zh / poem } {#1}
    \addvspace { \l__examzh_poem_top_sep_skip }
    \__examzh_poem_begin:
      \__examzh_poem_title_author_type:
      \group_begin:
        \l__examzh_poem_format_tl
        \use:x
          {
            \exp_not:N \tabular
              { \l__examzh_poem_align_tl }
          }
          #2
        \endtabular
      \group_end:
    \par
    \addvspace { 1em }
  }
  {
    \__examzh_poem_end:
    \par
    \addvspace { \l__examzh_poem_bottom_sep_skip }
    \par
  }
\cs_new:Npn \__examzh_poem_title_author_type:
  {
    \tl_if_empty:NF \l__examzh_poem_title_content_tl
      {
        % \noindent \hfill
          \group_begin:
            \l__examzh_poem_title_format_tl
            \l__examzh_poem_title_content_tl
          \group_end:
          \tl_if_empty:NF \l__examzh_poem_author_content_tl
            {
              \hspace { \l__examzh_poem_title_author_sep_skip }
              \group_begin:
                \l__examzh_poem_author_format_tl
                \l__examzh_poem_author_content_tl
              \group_end:
            }
        % \hfill \null
        \par
        \addvspace { \l__examzh_poem_title_poem_sep_skip }
      }
  }
\cs_new:Npn \__examzh_poem_begin:
  {
    \bool_if:NTF \l__examzh_poem_type_minipage_bool
      {
        \noindent
        \minipage { \linewidth }
        \cs_set:Npn \thempfootnote { \examzh_footnote_number:N  \c@mpfootnote} 
          \center
      }
      {
        \int_zero:N \l__examzh_poem_zhu_index_int
        \seq_clear:N \g__examzh_poem_zhu_store_seq
        \center
      }
  }
\cs_new:Npn \__examzh_poem_end: 
  {
    \bool_if:NTF \l__examzh_poem_type_minipage_bool
      {
          \endcenter
        \endminipage
      }
      {
        \endcenter
        \seq_if_empty:NF \g__examzh_poem_zhu_store_seq
          {
            \vspace*{-0.7em}
            \small
            \begin{description}[leftmargin = 2em]
              \item[{[注]}] 
                \seq_map_indexed_inline:Nn \g__examzh_poem_zhu_store_seq
                  % ##1: index
                  % ##2: content
                  {
                    \__examzh_chinese_circled_number:n {##1} ~ ##2 
                  }
            \end{description}
          }
      }
  }


\NewDocumentCommand { \zhu } { o m }
  {
    \bool_if:NTF \l__examzh_poem_type_minipage_bool
      {
        \footnote {#2}
      }
      {
        \IfNoValueF {#1}
          { 
            \int_gset:Nn \l__examzh_poem_zhu_index_int {#1 - 1}
          }
        \__examzh_poem_type_chinese_zhu:n {#2}
      }
  }

\cs_new:Npn \__examzh_poem_type_chinese_zhu:n #1
  {
    \int_gincr:N \l__examzh_poem_zhu_index_int
    \int_set_eq:NN \l_tmpa_int \l__examzh_poem_zhu_index_int
    \unskip
    % 输出符号
    \textsuperscript 
      { \__examzh_chinese_circled_number:n { \l__examzh_poem_zhu_index_int } }
    % 将参数存起来
    \seq_gput_right:Nx \g__examzh_poem_zhu_store_seq 
      { #1 }
  }

\cs_new:Npn \__examzh_chinese_circled_number:n #1
  {
    \str_case:Vn \l__examzh_poem_zhu_circlednumber_base_str
      {
        { tikz } { \__examzh_chinese_tikz_circled_number:n {#1} }
        { font } { \__examzh_chinese_tikz_circled_number:n {#1} }
      }
  }
% 基于字体的带圈数字
\cs_new:Npn \__examzh_chinese_font_circled_number:n #1
  {
    \int_set:Nn \l_tmpa_int {#1}
    \int_compare:nNnTF { \l_tmpa_int } = { 0 }
      { \int_set:Nn \l_tmpa_int { "24EA } }
      {
        \int_compare:nNnTF { \l_tmpa_int } < { 21 }
          { \int_add:Nn \l_tmpa_int { "245F } }
          {
            \int_compare:nNnTF { \l_tmpa_int } < { 36 }
              { \int_add:Nn \l_tmpa_int { "3250 } }
              {
                \int_compare:nNnTF { \l_tmpa_int } < { 51 }
                  { \int_add:Nn \l_tmpa_int { "32B0 } }
                  {
                    \msg_error:nnn { exam-zh / poem }
                      { invalid-circled-number } { \int_use:N \l_tmpa_int }
                  }
              }
          }
      }
    \group_begin:
      \CJKfamily+ { }
      \symbol { \l_tmpa_int }
    \group_end:
  }

\msg_new:nnn { exam-zh / poem } { invalid-circled-number }
  { Invalid~ circled~ number~ #1. }

% tikz 绘制带圈数字
\fp_new:N \l__examzh_chinese_tikz_circled_number_xscale_fp   % 水平压缩系数
\fp_new:N \l__examzh_chinese_tikz_circled_number_yscale_fp   % 垂直压缩系数
\dim_new:N \l__examzh_chinese_tikz_circled_number_total_hegiht_dim   % 数字的总高度
\dim_new:N \l__examzh_chinese_tikz_circled_number_radius_dim     % 半径

\cs_new:Npn \__examzh_chinese_tikz_circled_number_aux:n #1
  {
    % 根据数字大小设置压缩系数
    \fp_set:Nn \l__examzh_chinese_tikz_circled_number_xscale_fp
      {
        \int_compare:nNnTF {#1} < { 10 } 
          { 0.9 }
          {
            \int_compare:nNnTF {#1} < { 100 }
              { 0.7 }
              { 0.5 }
          } 
      }
    \fp_set:Nn \l__examzh_chinese_tikz_circled_number_yscale_fp
      {
        \int_compare:nNnTF {#1} < { 10 } 
          { 0.9 }
          {
            \int_compare:nNnTF {#1} < { 100 }
              { 0.8 }
              { 0.6 }
          } 
      }
    % 获取数字的高度
    \hbox_set:Nn \l_tmpa_box {#1}
    \dim_set:Nn \l__examzh_chinese_tikz_circled_number_total_hegiht_dim
      { \box_ht:N \l_tmpa_box + \box_dp:N \l_tmpa_box  }
    % 设置圆的半径
    \dim_set:Nn \l__examzh_chinese_tikz_circled_number_radius_dim 
      { \dim_eval:n { \l__examzh_chinese_tikz_circled_number_total_hegiht_dim / 2 + 0.34 ex } }
    % 绘制
    \tikz [ baseline ]
      {
        \node
          [ inner~sep = 0pt, outer~sep = 0pt ]
          at (0, \dim_use:N \l__examzh_chinese_tikz_circled_number_total_hegiht_dim / 2 ) 
          {
            \hbox_set:Nn \l_tmpa_box
              {
                \int_compare:nNnTF {#1} > {9}
                  { \textbf {#1} }
                  {#1}
              }
            \makebox[0.35em][c]
              { 
                % \scalebox { \fp_use:N \l__examzh_chinese_tikz_circled_number_xscale_fp } 
                  % [ \fp_use:N \l__examzh_chinese_tikz_circled_number_yscale_fp ] 
                \box_scale:Nnn \l_tmpa_box
                  { \fp_use:N \l__examzh_chinese_tikz_circled_number_xscale_fp }
                  { \fp_use:N \l__examzh_chinese_tikz_circled_number_yscale_fp } 
                \box_use_drop:N \l_tmpa_box
              }
          };
        \draw (0, \l__examzh_chinese_tikz_circled_number_total_hegiht_dim / 2 )
          circle ( \l__examzh_chinese_tikz_circled_number_radius_dim );
      }
  }
\cs_new:Npn \__examzh_chinese_tikz_circled_number:n #1
  {
    \__examzh_chinese_tikz_circled_number_aux:n { \int_eval:n {#1} }
  }


% 作文框
\NewDocumentEnvironment { writingbox } { O{ } +b }
  {
    \begin{tcolorbox}
      [
        % 直角
        sharp~corners = all,
        % 颜色
        colback = white,
        colbacktitle = white,
        % colframe = white,
        coltitle = black,
        % 边框粗细
        boxrule   = 1pt,
        titlerule = 0pt,
        % 间距
        toptitle  = 4pt,
        % 字体
        fonttitle = \centering,
        % 首行缩进
        parbox  = false,
        before~upper = \indent,
        % 跨页
        breakable,
        enhanced~jigsaw,
        #1
      ]
      #2
  }
  {
    \end{tcolorbox}
  }

\dim_new:N \l__examzh_choices_column_sep_dim
\int_new:N \l__examzh_choices_columns_int
\tl_new:N \l__examzh_choices_label_tl
\tl_new:N \l__examzh_choices_label_pos_tl
\tl_new:N \l__examzh_choices_label_align_tl
\dim_new:N \l__examzh_choices_label_sep_dim
\dim_new:N \l__examzh_choices_label_width_dim
\int_new:N \l__examzh_choices_max_columns_int

\keys_define:nn { exam-zh }
  { choices .meta:nn = { exam-zh / choices } {#1} }

\keys_define:nn { exam-zh / choices }
  {
    column-sep  .dim_set:N = \l__examzh_choices_column_sep_dim ,
    columns     .int_set:N = \l__examzh_choices_columns_int ,
    label       .tl_set:N  = \l__examzh_choices_label_tl ,
    label-pos   .choices:nn =
      { auto , top-left , left , bottom }
      { \tl_set_eq:NN \l__examzh_choices_label_pos_tl \l_keys_choice_tl } ,
    label-align .tl_set:N = \l__examzh_choices_label_align_tl ,
    label-sep   .dim_set:N = \l__examzh_choices_label_sep_dim ,
    label-width .dim_set:N = \l__examzh_choices_label_width_dim ,
    max-columns .int_set:N = \l__examzh_choices_max_columns_int ,
    index       .int_set:N = \l__examzh_choices_item_index_int,
    % 环境上方的额外距离
    top-sep .skip_set:N = \l__examzh_choices_top_sep_skip,
    % 环境下方的额外距离
    bottom-sep .skip_set:N = \l__examzh_choices_bottom_sep_skip,
    % 若不是单行排版，则可以控制行之间的额外间距
    linesep .skip_set:N = \l__examzh_choices_line_sep_skip
  }

\keys_set:nn { exam-zh / choices }
  {
    column-sep  = 1em ,
    columns     = 0 ,
    label       = \Alph*. ,
    label-pos   = auto ,
    label-align = left ,
    label-sep   = .5em ,
    label-width = 0pt ,
    max-columns = 4 ,
    index       = 1,
    top-sep     = 0pt,
    bottom-sep  = 0pt,
    linesep     = 0pt plus .5ex
  }

\NewDocumentCommand \setchoices { m }
  { \keys_set:nn { exam-zh / choices } {#1} }


\tl_new:N \l__examzh_choices_counters_tl

\NewDocumentCommand \AddChoicesCounter { m m }
  % #1: \Alph（用户接口）
  % #2: \@Alph（具体实现的命令或函数（开发层））
  {
    % TODO 这一步的作用是什么，为什么要把函数放在 tl 变量里而不是直接在某处使用？
    % 猜测：put_right 而不是 set，是为了保证操作 label 的输入值前
    %      几个函数都被 set
    \tl_put_right:Nn \l__examzh_choices_counters_tl
      { \__examzh_choices_process_counter:NN #1 #2 }
    \cs_set_eq:cN { __examzh_choices_save_ \cs_to_str:N #1 : } #2
    \cs_set_eq:cN { __examzh_choices_save_ \cs_to_str:N #2 : } #2
  }

\AddChoicesCounter \arabic \@arabic
\AddChoicesCounter \alph   \@alph
\AddChoicesCounter \Alph   \@Alph
\AddChoicesCounter \roman  \@roman
\AddChoicesCounter \Roman  \@Roman


\dim_new:N \l__examzh_choices_total_width_dim
\seq_new:N \l__examzh_choices_seq

\NewDocumentEnvironment { choices } { O { } +b }
  {
    \keys_set:nn { exam-zh / choices } {#1}
    \par \nopagebreak
    % 严格禁止孤行和寡行
    \int_set:Nn \clubpenalty { 10000 }
    \int_set:Nn \widowpenalty { 10000 }
    % 尽量避免在选项中间换行
    \int_set:Nn \interlinepenalty { 301 }
    \vspace* { \l__examzh_choices_top_sep_skip }
    \noindent
    % \dim_set_eq:NN \l__examzh_choices_total_width_dim \linewidth
    \dim_set:Nn \l__examzh_choices_total_width_dim { \linewidth - \leftskip - \rightskip }
    \int_zero:N \l__examzh_choices_columns_int
    \dim_zero:N \l__examzh_choices_label_width_dim
  }
  {
    % 用 \item 分割选项
    \seq_set_split:Nnn \l__examzh_choices_seq { \item } {#2}
    % 把第一个空项去掉
    \seq_if_empty:NF \l__examzh_choices_seq
      { \seq_pop_left:NN \l__examzh_choices_seq \l_tmpa_tl }
    % 收集正确的选项
    \__examzh_choices_collect_correct_choices:N   
      \l__examzh_choices_seq
    % 计算标签和选项内容的最大自然宽度
    \__examzh_choices_calc_max_width:N \l__examzh_choices_seq
    % label-pos = auto 时自动选择标签位置
    \__examzh_choices_set_auto_label_pos:
    % 如果用户没有声明列数，计算合适的列数
    % 「学习点」从默认值是否被改变来测试用户是否输入
    % 用户没有输入的话就采用自动计算列数
    \int_compare:nNnT { \l__examzh_choices_columns_int } < {1}
      { \__examzh_choices_calc_columns: }
    % 解决 columns 无效的问题
    \keys_set:nn { exam-zh / choices } {#1}
    % 计算每个选项内容的宽度 \l__examzh_choices_item_width_dim
    \__examzh_choices_calc_item_width:
    % 输出选项
    \__examzh_print_choices:N \l__examzh_choices_seq
    % 输出正确选项
    % \__examzh_print_correctchoice:
    \vspace* { \l__examzh_choices_bottom_sep_skip }
  }

% 用来存正确选项的序号（entry）
\seq_new:N \l__examzh_choices_correct_choices_label_seq
% 用来存正确选项的内容
\seq_new:N \l__examzh_choices_correct_choices_item_seq

% 收集正确的选项，保存在 \l__examzh_choices_correct_choices_seq
\cs_new:Npn \__examzh_choices_collect_correct_choices:N #1
  % #1: \l__examzh_choices_seq
  {
    \seq_clear:N \l__examzh_choices_correct_choices_label_seq
    \seq_clear:N \l__examzh_choices_correct_choices_item_seq
    \seq_clear:N \l_tmpa_seq
    \seq_map_indexed_inline:Nn #1
      {
        % ##1: 选项序号
        % ##2: 选项内容
        % 如果分割后，第一个字符是 * 的，表明这是一个正确选项
        %（即用 \item* 来标记正确答案）
        \tl_if_head_eq_meaning:nNTF {##2} *
          {
            \seq_put_right:Nn \l__examzh_choices_correct_choices_label_seq 
              { \__examzh_choices_correct_choices_label_transfrom:n {##1} }
            % 将去掉 * 号后的内容保存进 \l_tmpa_tl
            \tl_set:Nx \l_tmpa_tl { \tl_tail:n {##2} }
            % 去掉 * 和内容之间的空格
            \tl_trim_spaces:N \l_tmpa_tl
            \seq_put_right:NV \l__examzh_choices_correct_choices_item_seq 
              \l_tmpa_tl 
            \seq_put_right:NV \l_tmpa_seq \l_tmpa_tl
          }
          {
            \seq_put_right:Nn \l_tmpa_seq { ##2 }
          }
      }
    \seq_set_eq:NN #1 \l_tmpa_seq
  }

% 根据 label 的样式 \l__examzh_choices_label_tl 转化正确选项的样式
\cs_new:Npn \__examzh_choices_correct_choices_label_transfrom:n #1
  {
    \group_begin:
      \int_set:Nn \l__examzh_choices_index_int {#1}
      % 定义计数器转换函数（如 \Alph 等）
      \l__examzh_choices_counters_tl
      % 输出
      \l__examzh_choices_label_tl
    \group_end:
  }
% 输出正确的选项
\cs_new:Nn \__examzh_print_correctchoice:
  {
    \seq_if_empty:NF \l__examzh_choices_correct_choices_item_seq
      {
        \par
        参考答案：
        \seq_use:Nn \l__examzh_choices_correct_choices_label_seq {,~}
      }
  }


\dim_new:N \l__examzh_choices_item_width_dim
\dim_new:N \l__examzh_choices_item_min_height_dim

% 计算标签和选项内容的最大宽度，
% 分别保存到 \l__examzh_choices_label_width_dim 和 \l__examzh_choices_item_width_dim
% #1: \l__examzh_choices_seq
\cs_new:Npn \__examzh_choices_calc_max_width:N #1
  {
    % 下面这两个的想法是 xchoices 项目可以优化学习的地方
    % 因为 xchoices 是把变量先设置为第一项的参数，然后让后面的和前面的比
    % 这里相当于把“设置为第一项的参数”这一步，用默认的“端点量”来代替
    % 比如取最大的，就和 0 比，这样的话其实也会产生变量会变成第一项的参数的结果
    % 但是两者性质不同，此处处理让 第一项 「没有特殊性」
    % 后面的计算最小高度的也是如此
    \dim_zero:N \l__examzh_choices_item_width_dim
    \dim_set_eq:NN \l__examzh_choices_item_min_height_dim \c_max_dim
    \seq_map_indexed_inline:Nn #1
      {
        % -- 标签 --
        % 把标签整体放进 \l_tmpa_box
        \hbox_set:Nn \l_tmpa_box { \__examzh_choices_the_label:n {##1} }
        % 测量宽度
        \dim_set:Nn \l_tmpa_dim { \box_wd:N \l_tmpa_box }
        % 与当前最大值比较，最后效果是 \l__examzh_choices_label_width_dim 储存了所有标签中宽度最大的标签的宽度值
        \dim_compare:nNnT
          { \l_tmpa_dim } > { \l__examzh_choices_label_width_dim }
          { \dim_set_eq:NN \l__examzh_choices_label_width_dim \l_tmpa_dim }
        % -- 选项内容 --
        % 把内容放进 \l_tmpa_box 中
        \hbox_set:Nn \l_tmpa_box {##2}
        % 测量宽度
        \dim_set:Nn \l_tmpa_dim { \box_wd:N \l_tmpa_box }
        % 与当前最大值比较，最后效果是 \l__examzh_choices_item_width_dim 储存了所有选项内容中宽度最大的内容的宽度值
        \dim_compare:nNnT
          { \l_tmpa_dim } > { \l__examzh_choices_item_width_dim }
          {
            \dim_set_eq:NN \l__examzh_choices_item_width_dim
              \l_tmpa_dim
          }
        % -- 找到最小高度 --
        % 把内容高度储存到 \l_tmpb_dim
        \dim_set:Nn \l_tmpb_dim { \box_ht:N \l_tmpa_box }
        % 与当前最小值比较，最后效果是 \l__examzh_choices_item_min_height_dim 储存了所有内容中高度最小的内容的高度值
        \dim_compare:nNnT
          { \l_tmpb_dim } < { \l__examzh_choices_item_min_height_dim }
          { \dim_set_eq:NN \l__examzh_choices_item_min_height_dim \l_tmpb_dim }
        \box_clear:N \l_tmpa_box
      }
  }

% TODO 没看懂怎么实现的
\int_new:N \l__examzh_choices_index_int

% \Alph* 形式生成正确的标签
\cs_new:Npn \__examzh_choices_the_label:n #1
  {
    \group_begin:
      \int_set:Nn \l__examzh_choices_index_int 
        {
          \int_eval:n
            {
              \l__examzh_choices_item_index_int + #1 - 1
            }
        }
      \l__examzh_choices_counters_tl
      \l__examzh_choices_label_tl
    \group_end:
  }

\cs_new:Npn \__examzh_choices_process_counter:NN #1#2
  % #1: \Alph
  % #2: \@Alph
  {
    % 用户可以同时使用 #1 和 #2 两个函数（命令）作为 label 的操作函数
    % #1 的内核原理函数是 #2
    \cs_set:Npn #1 { \__examzh_choices_process_counter_aux:Nn #2 }
    \cs_set:Npn #2 { \__examzh_choices_process_counter_aux:Nn #2 }
  }

\cs_new:Npn \__examzh_choices_process_counter_aux:Nn #1#2
  % #1: \@Alph
  {
    \tl_if_eq:nnTF {#2} { * }
      {
        % 如果是 \alph* 类型的，效果为 \alph{ \l__examzh_choices_index_int }
        \use:c { __examzh_choices_save_ \cs_to_str:N #1 : }
          { \l__examzh_choices_index_int }
      }
      {
        % 否则就是 \alph{...} 效果
        \use:c { __examzh_choices_save_ \cs_to_str:N #1 : } {#2}
      }
  }


% 超过这一高度阈值的选项视为插图模式
% 注意使用 tl
% TODO 为何要使用 tl 而不用 dim ？
\tl_new:N \l__examzh_choices_figure_mode_threshold_tl
\tl_set:Nn \l__examzh_choices_figure_mode_threshold_tl { 2 \baselineskip }

\cs_new:Npn \__examzh_choices_set_auto_label_pos:
  {
    \tl_if_eq:NnT \l__examzh_choices_label_pos_tl { auto }
      {
        % 若最小高度超过阈值，推测其中包含插图，将标签位置改为左居中
        \dim_compare:nNnTF
          { \l__examzh_choices_item_min_height_dim } >
            { \l__examzh_choices_figure_mode_threshold_tl }
          { \tl_set:Nn \l__examzh_choices_label_pos_tl { left } }
          { \tl_set:Nn \l__examzh_choices_label_pos_tl { top-left } }
      }
  }


\int_new:N \l__examzh_tmp_int

% 计算选项的合适列数，存到 \l__examzh_choices_columns_int
\cs_new:Npn \__examzh_choices_calc_columns:
  {
    % 若标签不在底部，将 label-width 和 label-sep 加到 \l__examzh_choices_item_width_dim 里面
    \tl_if_eq:NnF \l__examzh_choices_label_pos_tl { bottom }
      {
        \dim_add:Nn \l__examzh_choices_item_width_dim
          { \l__examzh_choices_label_width_dim + \l__examzh_choices_label_sep_dim }
      }
    % [总宽度 / 最大的选项宽度] = 列数 
    % 这个计算出来是作为「算出来的、可以排的最大列数」
    % 将要和下面的手动（或者默认的）最大列数进行比较，来确定最后排多少列
    \int_set:Nn \l__examzh_choices_columns_int
      {
        \int_div_truncate:nn
          { \l__examzh_choices_total_width_dim + \l__examzh_choices_column_sep_dim }
          { \l__examzh_choices_item_width_dim + \l__examzh_choices_column_sep_dim }
      }
    % 如果上面的计算算出来是 0 的话，就设置为 1
    \int_compare:nNnTF { \l__examzh_choices_columns_int } = {0}
      { \int_set:Nn \l__examzh_choices_columns_int {1} }
    % 从允许的最大列数开始，每次除以 2，直到行宽允许排下
    % 比如设置了最大列数是 4 ， 但是算出来可以排 5 
    % 那么就会将 [4 / 2] = 2 < 5 作为列数
    \int_set_eq:NN \l__examzh_tmp_int \l__examzh_choices_max_columns_int
    \int_while_do:nNnn
      { \l__examzh_tmp_int } > { \l__examzh_choices_columns_int }
      {
        \int_set:Nn \l__examzh_tmp_int
          { \int_div_truncate:nn { \l__examzh_tmp_int } {2} }
      }
    \int_set_eq:NN \l__examzh_choices_columns_int \l__examzh_tmp_int
  }


% 计算选项的最终宽度，保存到 \l__examzh_choices_item_width_dim
\cs_new:Npn \__examzh_choices_calc_item_width:
  {
    \dim_set:Nn \l__examzh_choices_item_width_dim
      {
        % TODO 不是很理解这里的算法
        ( \l__examzh_choices_total_width_dim
          - \l__examzh_choices_columns_int \l__examzh_choices_column_sep_dim
          + \l__examzh_choices_column_sep_dim
        ) / \l__examzh_choices_columns_int
      }
    % 若标签不在底部，将 label-width 和 label-sep 算进来
    % TODO 算进来？那怎么还是 sub？
    \tl_if_eq:NnF \l__examzh_choices_label_pos_tl { bottom }
      {
        \dim_sub:Nn \l__examzh_choices_item_width_dim
          { \l__examzh_choices_label_width_dim + \l__examzh_choices_label_sep_dim }
      }
  }


\int_new:N \l__examzh_choices_current_col_int

% #1: \l__examzh_choices_seq
\cs_new:Npn \__examzh_print_choices:N #1
  {
    \int_zero:N \l__examzh_choices_current_col_int
    \seq_map_indexed_inline:Nn \l__examzh_choices_seq
      {
        \int_incr:N \l__examzh_choices_current_col_int
        % 当前列号重置为 1
        \int_compare:nNnT
          { \l__examzh_choices_current_col_int } > { \l__examzh_choices_columns_int }
          {
            % \par \noindent
            \\[ \l__examzh_choices_line_sep_skip ]
            % \newline
            % \skip_vertical:N \l__examzh_choices_line_sep_skip
            \int_set:Nn \l__examzh_choices_current_col_int {1}
          }
        % TODO 为什么 > 1 才加呢？ 这样的话第 1 列和第 2 列之间就没有这个间距？
        \int_compare:nNnT { \l__examzh_choices_current_col_int } > {1}
          {
            \skip_horizontal:N \l__examzh_choices_column_sep_dim
            % 增加一点弹性
            \skip_horizontal:n {0pt plus 1pt minus 1pt}
          }
        \__examzh_print_single_choice:nn {##1} {##2}
      }
    \par
  }


\coffin_new:N \l__examzh_choices_item_coffin
\coffin_new:N \l__examzh_choices_label_coffin
% \box_new:N \l__examzh_choices_item_box
% \box_new:N \l__examzh_choices_label_box
\cs_new:Npn \__examzh_print_single_choice:nn #1#2
  {
    % 选项标签
    \__examzh_choices_make_label_coffin:n {#1}
    % \__examzh_choices_make_label_box:n {#1}
    % 选项内容
    \__examzh_choices_make_item_coffin:n {#2}
    % \__examzh_choices_make_item_box:n {#2}
    % 合并选项的标签和内容
    \str_case:Vn \l__examzh_choices_label_pos_tl
      {
        { top-left }
          {
            \coffin_join:NnnNnnnn
              \l__examzh_choices_label_coffin {r} {H}
              \l__examzh_choices_item_coffin  {l} {H}
              { \l__examzh_choices_label_sep_dim }
              { 0pt }
            % \hbox_set:Nn \l__examzh_choices_item_box
            %   {
            %     \box_use_drop:N \l__examzh_choices_label_box
            %     \kern \l__examzh_choices_label_sep_dim
            %     \box_use_drop:N \l__examzh_choices_item_box
            %   }
          }
        { left }
          {
            \coffin_join:NnnNnnnn
              \l__examzh_choices_label_coffin {r} {vc}
              \l__examzh_choices_item_coffin  {l} {vc}
              { \l__examzh_choices_label_sep_dim }
              { 0pt }
            % \hbox_set:Nn \l__examzh_choices_item_box
            %   {
            %     \box_move_down:nn
            %       {
            %         (
            %           \box_ht:N \l__examzh_choices_label_box -
            %           \box_dp:N \l__examzh_choices_label_box -
            %           \box_ht:N \l__examzh_choices_item_box +
            %           \box_dp:N \l__examzh_choices_item_box
            %         ) / 2
            %       }
            %       { \box_use_drop:N \l__examzh_choices_label_box }
            %     \kern \l__examzh_choices_label_sep_dim
            %     \box_use_drop:N \l__examzh_choices_item_box
            %   }
          }
        { bottom }
          {
            \coffin_join:NnnNnnnn
              \l__examzh_choices_label_coffin {hc} {t}
              \l__examzh_choices_item_coffin  {hc} {b}
              { 0pt }
              % { - \l__examzh_choices_label_sep_dim }
              { 0pt }
            % \hbox_set:Nn \l__examzh_choices_item_box
            %   {
            %     % \vbox_top:n
            %     %   {
            %     %     \box_use:N \l__examzh_choices_item_box
            %     %     \nointerlineskip
            %     %     % \kern \l__examzh_choices_label_sep_dim 
            %     %     \box_move_left:nn
            %     %       {
            %     %         (
            %     %           \box_wd:N \l__examzh_choices_label_box -
            %     %           \box_wd:N \l__examzh_choices_item_box
            %     %         ) / 2
            %     %       }
            %     %       { \box_use_drop:N \l__examzh_choices_label_box }
            %     %       \box_clear:N \l__examzh_choices_item_box
            %     %   }
            %     \hbox_set:Nn \l__examzh_choices_item_box
            %       {
            %         \box_use:N \l__examzh_choices_item_box
            %         \kern \dim_eval:n
            %           {
            %             ( - \box_wd:N \l__examzh_choices_label_box
            %               -  \box_wd:N \l__examzh_choices_item_box ) / 2 
            %           }
            %         \box_move_down:nn
            %           {
            %             \box_ht:N \l__examzh_choices_label_box +
            %             \box_dp:N \l__examzh_choices_item_box
            %             % + \l__examzh_choices_label_sep_dim 
            %           }
            %           { \box_use_drop:N \l__examzh_choices_label_box }
            %         \box_clear:N \l__examzh_choices_item_box
            %       }
            %   }
          }
      }
    % 输出合并后
    % \coffin_typeset:Nnnnn \l__examzh_choices_item_coffin {l} {H} {0pt} {0pt}
    \coffin_typeset:Nnnnn \l__examzh_choices_label_coffin {l} {H} {0pt} {0pt}
    \coffin_clear:N \l__examzh_choices_item_coffin
    \coffin_clear:N \l__examzh_choices_label_coffin
    % \box_use_drop:N \l__examzh_choices_item_box
  }

% 将标签内容存入 coffin
\cs_new:Npn \__examzh_choices_make_label_coffin:n #1
% 将标签内容存入 box
% \cs_new:Npn \__examzh_choices_make_label_box:n #1
  {
    \hcoffin_set:Nn \l__examzh_choices_label_coffin
    % \hbox_set:Nn \l__examzh_choices_label_box
      {
        \hbox_to_wd:nn { \l__examzh_choices_label_width_dim }
          { \__examzh_choices_make_label:n {#1} \strut }
      }
  }

\cs_new:Npn \__examzh_choices_make_label:n #1
  {
    \str_case:Vn \l__examzh_choices_label_align_tl
      {
        { left   } { \rlap { \__examzh_choices_the_label:n {#1} } \hss }
        { center } { \hss \clap { \__examzh_choices_the_label:n {#1} } \hss }
        { right  } { \hss \llap { \__examzh_choices_the_label:n {#1} } }
      }
  }

\bool_new:N \l__examzh_choices_figure_mode_bool

% 将选项内容存入 coffin
\cs_new:Npn \__examzh_choices_make_item_coffin:n #1
% 将选项内容存入 box
% \cs_new:Npn \__examzh_choices_make_item_box:n #1
  {
    \hcoffin_set:Nn \l__examzh_choices_item_coffin
    % \hbox_set:Nn \l__examzh_choices_item_box
      {
        % 优先尝试使用 hbox，这是因为在 \vbox_set 外部能保留原来的 \linewidth 和
        % \textwidth，方便用户在 \includegraphics 中使用
        \hbox_set:Nn \l_tmpa_box {#1}
        % 若盒子的自然高度大于 2 行，且深度为 0pt，设置为插图模式
        \bool_lazy_and:nnT
          {
            \dim_compare_p:nNn { \box_ht:N \l_tmpa_box } >
            { \l__examzh_choices_figure_mode_threshold_tl }
          }
          { \dim_compare_p:nNn { \box_dp:N \l_tmpa_box } < { 1pt } }
          { \bool_set_true:N \l__examzh_choices_figure_mode_bool }
        \vcoffin_set:Nnn \l_tmpa_coffin
          { \l__examzh_choices_item_width_dim }
        % \vbox_set:Nn \l_tmpa_box
          {
            % \dim_set_eq:NN \parskip \c_zero_dim
            % \dim_set_eq:NN \parindent \listparindent
            \dim_set_eq:NN \hsize \l__examzh_choices_item_width_dim
            \dim_set_eq:NN \linewidth \hsize
            \dim_set_eq:NN \columnwidth \hsize
            \dim_set_eq:NN \parskip \c_zero_dim
            \dim_set_eq:NN \parindent \listparindent
            \dim_set:Nn \leftskip { 0pt }
            \dim_set:Nn \rightskip { 0pt }
            \noindent
            % \strut
            % 若标签在底部，将图片居中对齐。
            \tl_if_eq:NnT \l__examzh_choices_label_pos_tl { bottom }
              { \centering }
            \dim_compare:nNnTF
              { \box_wd:N \l_tmpa_box } > { \l__examzh_choices_item_width_dim }
              { #1 }
              { \box_use_drop:N \l_tmpa_box }
            % 使用 \strut 将行距撑开，防止跟下一行选项的间距过小
            \mode_if_horizontal:T { \strut }
          }
        \dim_set:Nn \l_tmpa_dim { \coffin_ht:N \l_tmpa_coffin }
        \bool_if:NT \l__examzh_choices_figure_mode_bool
        % \dim_set:Nn \l_tmpa_dim { \box_ht:N \l_tmpa_box }
        % \bool_if:NTF \l__examzh_choices_figure_mode_bool
        %   {
        %     \box_move_up:nn { \l_tmpa_dim - 0.7 \baselineskip } { \box_use_drop:N \l_tmpa_box }
        %   }
          {
            \coffin_set_horizontal_pole:Nnn \l_tmpa_coffin {T}
              { \l_tmpa_dim - 0.7 \baselineskip }
            % \vbox_top:n { \vbox_unpack_drop:N \l_tmpa_box }
          }
        \coffin_typeset:Nnnnn \l_tmpa_coffin {l} {T} {0pt} {0pt}
        \coffin_clear:N \l_tmpa_coffin
      }
  }


% 使用中文字体直接输出 unicode 带圈数字
% \circlednumber 的参数既可以接受 LaTeX2e 的 <counter>，也可以直接接受 <intexpr>。
% \NewDocumentCommand \circlednumber { m }
%   {
%     \int_if_exist:cTF { c@ #1 }
%       { \int_set_eq:Nc \l_tmpa_int { c@#1 } }
%       { \int_set:Nn \l_tmpa_int { #1 } }
%     \exp_args:Nx \__examzh_choices_circled_number:n { \int_use:N \l_tmpa_int }
%   }

\cs_new:Npn \__examzh_choices_circled_number:n #1
  {
    \int_set:Nn \l_tmpa_int {#1}
    \int_compare:nNnTF { \l_tmpa_int } = { 0 }
      { \int_set:Nn \l_tmpa_int { "24EA } }
      {
        \int_compare:nNnTF { \l_tmpa_int } < { 21 }
          { \int_add:Nn \l_tmpa_int { "245F } }
          {
            \int_compare:nNnTF { \l_tmpa_int } < { 36 }
              { \int_add:Nn \l_tmpa_int { "3250 } }
              {
                \int_compare:nNnTF { \l_tmpa_int } < { 51 }
                  { \int_add:Nn \l_tmpa_int { "32B0 } }
                  {
                    \msg_error:nnn { exam-zh / choices }
                      { invalid-circled-number } { \int_use:N \l_tmpa_int }
                  }
              }
          }
      }
    \group_begin:
      % TODO 为何要用 \CJKfamily+ { }
      % xeCJK 宏包文档：当 \CJKfamily+ 参数为空时，则使用当前的 CJK 字体族。
      \CJKfamily+ { }
      \symbol { \l_tmpa_int }
    \group_end:
  }

\msg_new:nnn { exam-zh / choices } { invalid-circled-number }
  { Invalid~ circled~ number~ #1. }

\AddChoicesCounter \circlednumber \__examzh_choices_circled_number:n


\NewDocumentCommand{\xx}{O{} +m +m +m +m }
  {
    \begin{choices}[#1]
      \item #2
      \item #3
      \item #4
      \item #5
    \end{choices}
  }

\providecolor{icon}{HTML}{aa937c} % 标题前的图标颜色
\providecolor{wt1}{HTML}{ebebeb} % 白色主题的标题框顶部背景颜色
\providecolor{wt2}{HTML}{bebebe} % 白色主题的标题框底部背景颜色
\providecolor{wt3}{HTML}{efefef} % 白色主题的正文部分的背景颜色
\providecolor{circ1}{HTML}{eb605b} % 标题框左边第一个圆圈的颜色
\providecolor{circ2}{HTML}{f6bb31} % 标题框左边第二个圆圈的颜色
\providecolor{circ3}{HTML}{56cb45} % 标题框左边第三个圆圈的颜色
