# Repository Guidelines

## Project Structure & Module Organization

This directory is a customized `exam-zh` LaTeX design. The main implementation is
[`exam-zh-pro.cls`](exam-zh-pro.cls), which defines the document class and its
question, solution, layout, and font behavior. Use [`example-single.tex`](example-single.tex)
for a single-paper workflow and [`example-multiple.tex`](example-multiple.tex)
for a document containing several papers and answer sections. The JPEG files
(`07-14.jpg` and `07-15.jpg`) are local visual assets used by the design. The
parent repository contains the full upstream modules, documentation, and
regression fixtures; keep changes here focused on this customized variant.

## Build, Test, and Development Commands

All development commands go through `scripts/workflow.zsh`; the three `.command`
files are compatibility wrappers for double-click use.

- `make doctor`: check MacTeX/BasicTeX tools and required project files.
- `make single` / `make multiple`: compile the two maintained examples.
- `make compile FILE=foo.tex`: compile another root-level `.tex` entry.
- `make test`: run `doctor` and compile both examples from a cleanable build tree.
- `make package VERSION=2.12 DATE=2026-08-21`: verify, assemble, and validate a release zip.
- Add `FORCE=1` only when intentionally replacing an existing same-version package; use
  `zsh scripts/workflow.zsh package --dry-run ...` to validate without writing.
- Packaging runs the example compilation check by default; use `--skip-test` only after
  an explicit prior `make test`.
- `make clean`: remove and recreate `build/`.

XeLaTeX auxiliary files and logs live under `build/aux/`; the latest PDFs live
under `build/pdf/`; release archives live under `dist/`. Do not compile directly
in the source directory.

The class requires XeLaTeX and TeX Live 2020 or newer. Review the generated PDF
for page breaks, Chinese fonts, answer placement, and question numbering after
any class or example change.

## Coding Style & Naming Conventions

Write LaTeX with UTF-8 source and two-space indentation for nested environments
and key-value blocks. Follow the existing `expl3` naming scheme in the class:
use the `examzh` module prefix, private names such as `\__examzh_<feature>_...`,
and typed suffixes (`_tl`, `_dim`, `_int`, `_seq`). Keep `\examsetup` keys in
lower-kebab-case and preserve the established package-loading order.

## Testing Guidelines

There is no separate test harness in this design directory. Treat successful
XeLaTeX compilation plus visual inspection of both examples as the focused
check. For shared behavior, run the parent repository's `l3build check` and
update only the corresponding `.tlg` fixture after reviewing the diff.

## Commit & Pull Request Guidelines

Use short, imperative or descriptive subjects with the repository's existing
prefixes (`fix:`, `docs:`, `ci:`, `chore:`); Chinese subjects are also common.
Keep commits focused. Pull requests should explain the user-visible effect,
list commands run, link related issues, and attach PDF or screenshot evidence
for layout changes. Do not commit `.aux`, `.log`, `.synctex`, or other generated
build output.
