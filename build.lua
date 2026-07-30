#!/usr/bin/env texlua
---@diagnostic disable: lowercase-global

--[==========================================[--
          L3BUILD FILE FOR EXAM-ZH
     Once Modified, Test Before Tagging
--]==========================================]--

--[==========================================[--
              Basic Information
            Do Check Before Upload
--]==========================================]--

module           = "exam-zh"
version          = "v0.3.2"
date             = "2026-07-30"
maintainer       = "Kangwei Xia"
uploader         = maintainer
email            = "kangweixia_xdyy@163.com"
repository       = "https://github.com/xkwxdyy/exam-zh"
announcement     = ""
note             = ""
summary          = "LaTeX template for Chinese exam"
description      = [[
exam-zh is a LaTeX class and a set of packages for creating Chinese exam papers.
It provides various question types (multiple choice, fill-in-the-blank, problem solving),
answer control, draft mode, and more. Written with expl3 and requires XeLaTeX.
]]

--[==========================================[--
         Build, Pack and Upload To CTAN
         Do not Modify Unless Necessary
--]==========================================]--

-- File classification
ctanzip          = module
sourcefiles      = {"*.sty", "exam-zh.cls"}
installfiles     = {"*.sty", "exam-zh.cls"}
-- Keep repository-only guidance (for example AGENTS.md and CLAUDE.md) out of
-- the public CTAN archive.
textfiles        = {"README.md", "CHANGELOG.md", "LICENSE"}
excludefiles     = {"*~", "test.tex", "issue-test.tex"}

-- Tagging configuration
tagfiles         = {
  "*.sty",
  "exam-zh.cls",
  "CHANGELOG.md",
  "doc/exam-zh-doc.tex",
  "doc-basic/exam-zh-doc-basic.tex"
}

-- Documentation compilation
typesetexe       = "latexmk"
typesetopts      = "-xelatex -synctex=1 -interaction=nonstopmode"
typesetfiles     = {
  "example-single.tex",
  "example-multiple.tex"
}

-- Documentation source files (for CTAN distribution, not for typesetting here)
docfiles = {
  "doc/exam-zh-doc.tex",
  "doc/exam-zh-doc-setup.tex",
  "doc/xdyydoc.cls",
  "doc/exam-zh-doc.pdf",
  "doc/body/*.tex",
  "doc/back/*.tex",
  "doc/figures/*",
  "doc-basic/exam-zh-doc-basic.tex",
  "doc-basic/exam-zh-doc-basic-setup.tex",
  "doc-basic/xdyydoc.cls",
  "doc-basic/exam-zh-doc-basic.pdf",
  "doc-basic/body/*.tex",
  "doc-basic/back/*.tex"
}

-- Examples for CTAN distribution (basic examples)
demofiles = {
  "examples-basic/*.tex",
  "examples-basic/*.pdf"
}

-- Testing configuration
checkengines     = {"xetex"}
stdengine        = "xetex"

-- CTAN upload configuration
-- TeX Live 2026 initializes default variables after loading build.lua, which
-- turns the upload module's false dry-run marker back into "ask".  Set the
-- final state immediately before the target runs.  Local uploads otherwise
-- retain l3build's confirmation prompt.
local upload_pre = target_list.upload.pre
target_list.upload.pre = function(names)
  if upload_pre then
    local result = upload_pre(names)
    if result ~= 0 then
      return result
    end
  end
  if options["dry-run"] then
    ctanupload = false
  elseif os.getenv("L3BUILD_CTAN_UPLOAD") == "true" then
    ctanupload = true
  end
  return 0
end

uploadconfig = {
  pkg          = module,
  version      = version .. " " .. date,
  author       = maintainer,
  uploader     = uploader,
  email        = email,
  summary      = summary,
  description  = description,
  announcement = announcement,
  note         = note,
  license      = "lppl1.3c",
  ctanPath     = "/macros/latex/contrib/" .. module,
  home         = repository,
  support      = repository .. "/issues",
  bugtracker   = repository .. "/issues",
  repository   = repository,
  development  = "https://github.com/xkwxdyy",
  update       = true
}

--[==========================================[--
           Custom Functions and Hooks
--]==========================================]--

-- Update version and date in tagged files
function update_tag(file, content, tagname, tagdate)
  local tagname_stripped = tagname
  local tagdate_stripped = tagdate

  -- Remove 'v' prefix if present (e.g., v0.2.6 -> 0.2.6)
  if string.match(tagname, "^v") then
    tagname_stripped = string.sub(tagname, 2)
  end

  -- Update .sty files: \ProvidesExplPackage {name} {date} {version}
  if string.match(file, "%.sty$") then
    local pkg_name = string.match(file, "^(.*)%.sty$")
    -- Escape Lua pattern magic characters (especially '-') in the package name
    local pkg_name_pat = string.gsub(pkg_name, "([%-%.%(%)%[%]%+%*%?%^%$%%])", "%%%1")
    content = string.gsub(content,
      "\\ProvidesExplPackage%s*{" .. pkg_name_pat .. "}%s*{[^}]+}%s*{[^}]+}",
      "\\ProvidesExplPackage {" .. pkg_name .. "} {" .. tagdate_stripped .. "} {" .. tagname .. "}")
  end

  -- Update .cls file: \ProvidesExplClass {exam-zh} {date} {version}
  if string.match(file, "exam%-zh%.cls$") then
    content = string.gsub(content,
      "\\ProvidesExplClass%s*{exam%-zh}%s*{[^}]+}%s*{[^}]+}",
      "\\ProvidesExplClass {exam-zh} {" .. tagdate_stripped .. "} {" .. tagname .. "}")
  end

  -- Update documentation files: \newcommand{\DocDate} and \DocVersion
  if string.match(file, "%-doc%.tex$") or string.match(file, "%-doc%-basic%.tex$") then
    content = string.gsub(content,
      "\\newcommand{\\DocDate}{[^}]+}",
      "\\newcommand{\\DocDate}{" .. tagdate_stripped .. "}")
    content = string.gsub(content,
      "\\newcommand{\\DocVersion}{[^}]+}",
      "\\newcommand{\\DocVersion}{" .. tagname .. "}")
  end

  -- Update CHANGELOG.md: add new Unreleased section header if needed
  if string.match(file, "CHANGELOG%.md$") then
    -- Check if there's already an Unreleased section
    if not string.match(content, "%[Unreleased%]") then
      -- Add Unreleased section after the intro paragraph
      content = string.gsub(content,
        "(## %[[0-9%.]+%])",
        "## [Unreleased]\n\n### Added\n\n### Changed\n\n### Fixed\n\n%1")
    end
  end

  return content
end

--[==========================================[--
              Compilation Hooks
--]==========================================]--

-- Custom tex() function for proper latexmk invocation
function tex(file, dir, cmd)
  dir = dir or "."
  cmd = cmd or (typesetexe .. " " .. typesetopts)

  -- Ensure TEXINPUTS includes the unpacked directory
  local env_setup
  if os.type == "windows" then
    env_setup = "set \"TEXINPUTS=.;../unpacked;%TEXINPUTS%;\" &&"
  else
    env_setup = "TEXINPUTS=\".:../unpacked:$(kpsewhich -var-value=TEXINPUTS):\""
  end

  return run(dir, env_setup .. " " .. cmd .. " " .. file)
end

-- Note: Documentation compilation (doc/ and doc-basic/) is handled by build.py
-- Only example files in the root directory are compiled by l3build

--[==========================================[--
              Custom Targets
--]==========================================]--

-- Custom target: ctan-nocheck - Create CTAN package without running tests
-- Usage: l3build ctan-nocheck
if not target_list then
  target_list = {}
end

target_list.ctan_nocheck = {
  func = function()
    -- Save original checkfiles value
    local saved_checkfiles = checkfiles
    checkfiles = {}  -- Temporarily disable all tests

    -- Run ctan target
    local result = call({}, "bundlectan")

    -- Restore checkfiles
    checkfiles = saved_checkfiles

    return result
  end,
  desc = "Create CTAN package without running tests (for testing purposes)"
}
