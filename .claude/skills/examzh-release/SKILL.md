---
name: examzh-release
description: Prepare and publish a formal exam-zh release: version metadata, CHANGELOG, l3build checks, build.py packages, release commit, tag, GitHub/Gitee push, GitHub Release assets, and Gitee Release assets. Use for 发版, 发布新版本, release, tag, or version bump requests.
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git tag *) Bash(git fetch *) Bash(git branch *) Bash(git remote *) Bash(git add *) Bash(git commit *) Bash(git push *) Bash(python3 scripts/build.py *) Bash(python3 scripts/release_notes.py *) Bash(make changelog) Bash(make check-changelog) Bash(make prepare-release *) Bash(make doc) Bash(make doc-basic) Bash(make examples) Bash(make examples-basic) Bash(bash scripts/test-build.sh) Bash(l3build check) Bash(l3build check *) Bash(l3build save *) Bash(latexmk -xelatex *) Bash(gh auth status) Bash(gh auth status *) Bash(gh release view *) Bash(gh release create *) Bash(gh release upload *) Bash(gh release edit *) Bash(bash scripts/gitee-release.sh *) Bash(date *) Bash(test *) Bash(ls *) Bash(mktemp *) Bash(unzip -tq *) Bash(sed *) Bash(awk *) Bash(head *) Bash(curl *) Bash(jq *) Read Edit Write
disable-model-invocation: true
---

# examzh-release

Project-level Claude Code skill for formal `exam-zh` releases.

Use this skill for release, version, and tag workflows. For ordinary staging, committing, amending, or pushing current worktree changes, use `git-update`.

## Invocation Modes

The first argument may restrict the workflow. Stop at the stated boundary.

- `prepare` (preferred) or `changelog` (compatibility alias): inspect current
  changes, organize new tests, update affected manuals when needed, create or
  update structured fragments, run focused checks plus `make changelog` and
  `make check-changelog`, then stop. Do not commit, run the full release build,
  tag, push, or publish.
- `package [version]`: prepare notes, test, and build local archives only. Do
  not commit, tag, push, or create platform releases.
- `github <version>`: verify an existing tag and local release archive, then
  create or refresh only the GitHub Release.
- `gitee <version>`: verify an existing tag and local release archive, then
  create or refresh only the Gitee Release.
- `full [version]` or no mode: run the complete formal release workflow.

When the dashboard supplies a mode, do not broaden it even when another step
would normally follow in a complete release.

## Scope

This skill owns:

- selecting or validating the release version;
- preparing relevant test fixtures and user documentation for release;
- updating release metadata with `scripts/build.py`;
- preparing a reviewed `CHANGELOG.md` entry;
- running focused build-script tests and the XeTeX regression suite;
- building CTAN and GitHub/Gitee Release zip packages;
- committing release metadata and intentional release-script updates;
- creating the annotated git tag;
- pushing `main` and tags to `github` and `gitee`;
- creating or updating the GitHub Release and uploading release assets;
- creating or updating the Gitee Release and uploading release assets.

Keep unrelated feature, fix, documentation, and test work outside the release
commit. Documentation and tests required by the changes being released should
be completed during `prepare`, then reviewed before starting the formal release.

## Inputs

- Explicit version: accept `0.2.7` or `v0.2.7` from the user.
- No explicit version: infer the next patch version from the newest semantic tag, for example `v0.2.6` -> `0.2.7`.
- Script version format: pass `X.Y.Z` without `v` to `scripts/build.py`.
- Git tag, GitHub Release name, and Gitee Release name: use `vX.Y.Z`.

## Required Preflight

Run these before changing files:

```bash
git status --short
git branch --show-current
git remote -v
git tag --sort=-v:refname | head -n 10
gh auth status
bash scripts/test-build.sh
make check-changelog
```

Rules:

- Work from branch `main`.
- Start release preparation from a reviewed worktree. When local changes exist, classify them first and either include intentional release-tooling fixes in the release commit or commit unrelated work separately.
- Use remotes named `github` and `gitee`; verify them with `git remote -v`.
- Confirm `gh auth status` succeeds before creating or updating a GitHub Release.
- Confirm `GITEE_TOKEN` is available before creating or updating a Gitee Release.

## Version Selection

If the user provided a version:

- Strip a leading `v` for script calls.
- Accept only `X.Y.Z`.
- Check whether the tag already exists:

```bash
git tag --list vX.Y.Z
```

If the user did not provide a version:

```bash
git tag --sort=-v:refname | head -n 1
```

Strip the leading `v`, increment the patch number, and use the resulting `X.Y.Z`. Ask for an explicit version when the newest tag is missing or not semantic.

## Release Content Preparation

Run this audit before finalizing changelog fragments in `prepare` or
`changelog` mode. Review both tracked diffs and untracked files; do not assume
that every new `.tex` file is a source artifact worth releasing.

### Tests

- Match each behavior change to focused coverage under `testfiles/`.
- Prefer a stable `*.lvt` input with its reviewed `*.tlg` expectation when the
  behavior can be asserted through `l3build` output.
- Keep a standalone `*.tex` reproduction only when it provides distinct visual
  or diagnostic coverage that a log test cannot preserve. Minimize it and use
  the repository's existing test naming and location conventions.
- Treat `.aux`, `.log`, `.out`, `.xdv`, `.fls`, `.fdb_latexmk`, `.synctex.gz`,
  generated PDFs, and similar compiler output as build artifacts rather than
  test sources unless the repository explicitly tracks that exact artifact.
- Consolidate duplicate scratch reproductions. Do not delete an ambiguous user
  file merely because it is untracked; classify it first and report uncertainty.
- Run the narrow `l3build check <test-name>` checks for touched regression tests.
  Use `l3build save <test-name>` only after reviewing an intentional log change.

### Manuals And Examples

- For user-visible syntax, options, layout, defaults, or behavior, locate the
  corresponding section in `doc/` and update it when the existing text would be
  incomplete or misleading.
- Update `doc-basic/` when the change affects beginner-facing workflows or
  examples. Do not force a documentation edit for an internal-only fix.
- Keep examples consistent with the supported interface and avoid copying a
  large regression fixture into a manual when a short example is sufficient.
- Compile each touched manual or example with the narrowest relevant command,
  such as `make doc`, `make doc-basic`, `make examples`, or
  `make examples-basic`.

After tests and documentation are settled, prepare the structured fragments,
run `make changelog` and `make check-changelog`, summarize the files changed and
checks run, then stop at the mode boundary.

## CHANGELOG And Release Fragments

The source of truth is `.changes/unreleased/*.json`; the `[Unreleased]`
section in `CHANGELOG.md` is generated. Never edit that section directly.

Review commits and the complete working-tree diff:

```bash
git log --oneline PREVIOUS_TAG..HEAD
git diff HEAD
```

For each topic, create or update one JSON fragment using the schema documented
in `.changes/README.md`. Every change has Chinese `zh` text. Use
`changelog: false, announce: false` for internal-only work. Important
user-visible release items use `changelog: true, announce: true` and require
reviewed English `en` text.

Regenerate and verify:

```bash
make changelog
make check-changelog
```

For `prepare` or `changelog` mode, stop here. For a formal release, finalize the
reviewed fragments before tagging:

```bash
make prepare-release VERSION=X.Y.Z DATE=YYYY-MM-DD
make check-changelog
```

`scripts/build.py` performs the same preparation when the version manifest is
not present. When commit history or announcement visibility is ambiguous,
draft the fragment and ask for confirmation before continuing.

## Build And Test

Run the regression suite:

```bash
l3build check
```

Build the release packages with the project build script:

```bash
python3 scripts/build.py --non-interactive X.Y.Z
```

Use `--skip-compile` when reusing already compiled PDFs is the intended release strategy:

```bash
python3 scripts/build.py --non-interactive --skip-compile X.Y.Z
```

Verify the artifacts:

```bash
test -s CTAN/exam-zh.zip
test -s release/exam-zh-vX.Y.Z.zip
cd release && unzip -tq exam-zh-vX.Y.Z.zip
```

## Release Commit

Before committing:

- Verify documentation and example code compiles.
- Search for common undefined documentation commands when compilation reports an undefined control sequence.
- Review generated changes:

```bash
git status --short
git diff --stat
git diff -- CHANGELOG.md build.lua exam-zh.cls '*.sty' doc/exam-zh-doc.tex doc-basic/exam-zh-doc-basic.tex scripts
```

Commit the release metadata and intentional release-tooling changes:

```bash
git add .changes CHANGELOG.md build.lua exam-zh.cls exam-zh-*.sty doc/exam-zh-doc.tex doc-basic/exam-zh-doc-basic.tex scripts .claude/skills
git commit -m "chore(release): vX.Y.Z"
```

Inspect any additional tracked source changes and add them when they are intentional release updates. Keep `CTAN/` and `release/` as build artifacts unless the repository policy changes.

## Tag And Push

Create the annotated tag:

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
```

Push to both configured remotes:

```bash
git push github main --tags
git push gitee main --tags
```

## GitHub Release

Render the version manifest into a temporary Chinese release-notes file:

```bash
python3 scripts/release_notes.py render \
  .changes/releases/X.Y.Z.json \
  --changelog-output NOTES_FILE
```

Create the GitHub Release when it is missing:

```bash
gh release create vX.Y.Z \
  release/exam-zh-vX.Y.Z.zip \
  --repo xkwxdyy/exam-zh \
  --title "vX.Y.Z" \
  --notes-file NOTES_FILE
```

Refresh assets for an existing GitHub Release:

```bash
gh release upload vX.Y.Z \
  release/exam-zh-vX.Y.Z.zip \
  --repo xkwxdyy/exam-zh \
  --clobber
```

Verify:

```bash
gh release view vX.Y.Z --repo xkwxdyy/exam-zh --json tagName,name,url,assets,isDraft,isPrerelease
```

## Gitee Release

Use the same notes file to create or update the Gitee Release and upload assets:

```bash
bash scripts/gitee-release.sh \
  vX.Y.Z "vX.Y.Z" NOTES_FILE \
  release/exam-zh-vX.Y.Z.zip
```

`scripts/gitee-release.sh` handles these cases:

- creates the release when it is missing;
- updates metadata when the release already exists;
- replaces same-name attachments before uploading the current local package.

### First-Time Gitee Token Setup

When `GITEE_TOKEN` is unavailable:

1. Tell the user: "需要配置 Gitee Personal Access Token 才能自动创建 Gitee Release。"
2. Guide them to https://gitee.com/profile/personal_access_tokens.
3. Select `projects` permission.
4. Export the token in the active shell:
   ```bash
   export GITEE_TOKEN="your_token_here"
   ```
5. Persist it in the preferred shell profile when the user wants a permanent setup.

## Verification Report

Report:

- release tag and commit hash;
- CTAN package path and size;
- Release package path and size;
- GitHub Release URL and uploaded asset names;
- Gitee Release ID/URL and uploaded asset names;
- commands run.

## Failure Handling

For each failed command:

- report the failing command and key error output;
- fix local script, metadata, or documentation issues when the cause is clear;
- rerun the narrow failing command first;
- rerun the broader release command after the narrow check passes.

For tag recovery:

- Before pushing tags, use `git tag -d vX.Y.Z` to remove a local tag that points to the wrong commit.
- After pushing tags, ask for explicit approval before deleting remote tags or force-pushing.

For documentation compilation errors:

- Read the error log to identify the undefined command and line number.
- Search for all occurrences with `rg "command_name" doc doc-basic`.
- Replace the problematic reference with the supported command or remove the stale mention.
- Recompile the touched manual.
