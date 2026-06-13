# Repository Guidelines

## Project Structure & Module Organization

`exam-zh.cls` is the main class file. Feature modules live beside it as `exam-zh-*.sty`, including question, choices, font, math, symbols, bilingual text, and text-figure support. Examples are in the root (`example-single.tex`, `example-multiple.tex`) and `examples-basic/`. Full and beginner documentation sources are under `doc/` and `doc-basic/`; keep chapters in `body/` and appendices in `back/`. Regression tests use `testfiles/*.lvt` inputs and `.tlg` expected logs. Build and release helpers are in `build.lua`, `Makefile`, `tools/`, and `scripts/`.

## Build, Test, and Development Commands

### Testing & Compilation
- `l3build check`: run the XeTeX regression suite in `testfiles/`.
- `l3build save <test-name>` or `make save`: update expected `.tlg` files after an intentional output change.
- `bash scripts/test-build.sh`: validate all build scripts (version extraction, path safety, file existence).
- `l3build doc`: compile the configured example documents through `latexmk`.
- `latexmk -xelatex example-single.tex`: compile one example during focused debugging.
- `make examples`: compile root examples; `make examples-basic`: compile basic examples.
- `make doc`: compile full documentation; `make doc-basic`: compile beginner documentation.

### Release & Packaging
- `python scripts/build.py [version]`: **complete release workflow** — updates versions, compiles all docs/examples, creates CTAN and Release packages with SHA256 checksums. Supports `--non-interactive` (CI/CD) and `--skip-compile` flags.
- `bash scripts/build-ctan.sh [version]`: build CTAN package only (`CTAN/exam-zh.zip`).
- `bash scripts/build-release.sh [version]`: build GitHub Release package only (`release/exam-zh-v*.zip`).
- `l3build ctan`: alternative CTAN build (l3build's built-in method).

### Git Workflow
- `bash scripts/git-update.sh "message"`: automated git workflow (stage, commit, push). Supports `--dry-run`, `--no-push`, `--amend`, and `--force` flags. Includes safety checks for amending pushed commits.

### Build Script Architecture
All packaging scripts use the common library (`scripts/build-common.sh`) for:
- Path validation (prevents operations outside project root)
- Version format validation (enforces X.Y.Z format)
- Lock mechanism (prevents concurrent builds)
- Safe file operations (cleanup, compression, checksum generation)
- Unified logging (color-coded INFO/WARN/ERROR)

Use XeLaTeX for local checks; the class explicitly rejects other engines.

## Coding Style & Naming Conventions

Follow existing `expl3` conventions: internal variables and functions use the `examzh` module prefix, double-underscore private names such as `\__examzh_choices_...`, and typed suffixes like `_tl`, `_dim`, `_int`, and `_seq`. Keep key names lower-kebab-case in `\keys_define:nn` blocks. Match existing TeX spacing: declarations use forms like `\RequirePackage { fontspec }`, key lists align where practical, and continuation lines are indented two spaces.

## Testing Guidelines

Add or update `testfiles/*.lvt` for behavior changes, and commit the corresponding `.tlg` only after reviewing `build/test/*.diff`. Prefer narrow tests for option parsing, layout decisions, counters, and generated labels. For documentation-only changes, compile the touched example or manual section with `latexmk -xelatex` when feasible.

## Commit & Pull Request Guidelines

Recent history uses short imperative or descriptive messages, often in Chinese, with optional prefixes such as `docs:` and issue links such as `fix: https://gitee.com/xkwxdyy/exam-zh/issues/...`. Keep commits focused. Pull requests should describe the user-visible effect, list commands run, link related GitHub/Gitee issues, and include PDF or screenshot evidence when layout output changes.

## Release & Configuration Notes

Update version metadata consistently in `build.lua`, package/class `\ProvidesExpl...` lines, manuals, and `CHANGELOG.md`. Prefer `l3build tag` for CTAN metadata updates, and use `scripts/build.py` only for the full custom release flow.

### Build Script Usage Examples
```bash
# Interactive release (prompts for confirmation)
python scripts/build.py 0.2.7

# Non-interactive (CI/CD environments)
python scripts/build.py --non-interactive 0.2.7

# Skip compilation (assumes docs already compiled)
python scripts/build.py --skip-compile 0.2.7

# Test build scripts without executing
bash scripts/test-build.sh

# Git workflow - preview mode
bash scripts/git-update.sh --dry-run "Update docs"

# Git workflow - commit only (no push)
bash scripts/git-update.sh --no-push "WIP: feature"
```

### Build Script Security Features
- **Path validation**: All file operations validate paths are within project root before executing.
- **Version validation**: Enforces semantic versioning format (X.Y.Z); rejects invalid formats.
- **Build locking**: Prevents concurrent builds via `/tmp/exam-zh-build.lock`.
- **Integrity verification**: Post-build validation ensures all required files exist and are non-empty.
- **Checksum generation**: SHA256 checksums created for all distribution packages.
- **Safe deletion**: Preferentially uses trash/recycle bin for file removal when available.

For detailed documentation, see `scripts/README.md` and `scripts/REVIEW.md`.
