---
name: examzh-release
description: Prepare and publish a formal exam-zh release: version metadata, CHANGELOG, l3build checks, build.py packages, release commit, tag, GitHub/Gitee push, GitHub Release assets, and Gitee Release assets. Use for 发版, 发布新版本, release, tag, or version bump requests.
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git tag *) Bash(git fetch *) Bash(git branch *) Bash(git remote *) Bash(git add *) Bash(git commit *) Bash(git push *) Bash(python3 scripts/build.py *) Bash(bash scripts/test-build.sh) Bash(l3build check) Bash(gh auth status) Bash(gh auth status *) Bash(gh release view *) Bash(gh release create *) Bash(gh release upload *) Bash(gh release edit *) Bash(bash scripts/gitee-release.sh *) Bash(date *) Bash(test *) Bash(ls *) Bash(mktemp *) Bash(sed *) Bash(awk *) Bash(head *) Bash(curl *) Bash(jq *) Read Edit Write
disable-model-invocation: true
---

# examzh-release

Project-level Claude Code skill for formal `exam-zh` releases.

Use this skill for release, version, and tag workflows. For ordinary staging, committing, amending, or pushing current worktree changes, use `git-update`.

## Scope

This skill owns:

- selecting or validating the release version;
- updating release metadata with `scripts/build.py`;
- preparing a reviewed `CHANGELOG.md` entry;
- running focused build-script tests and the XeTeX regression suite;
- building CTAN and GitHub/Gitee Release zip packages;
- committing release metadata and intentional release-script updates;
- creating the annotated git tag;
- pushing `main` and tags to `github` and `gitee`;
- creating or updating the GitHub Release and uploading release assets;
- creating or updating the Gitee Release and uploading release assets.

Keep unrelated feature, fix, documentation, and test work outside the release commit. Review and commit that work before starting a formal release.

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

## CHANGELOG

Draft the release entry from commits since the previous tag:

```bash
git log --oneline PREVIOUS_TAG..HEAD
```

Add a new section near the top of `CHANGELOG.md`:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added

- ...

### Changed

- ...

### Fixed

- ...

### Documentation

- ...
```

Include categories that have real entries. When commit history is ambiguous, draft the entry and ask for confirmation before continuing.

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
git add CHANGELOG.md build.lua exam-zh.cls exam-zh-*.sty doc/exam-zh-doc.tex doc-basic/exam-zh-doc-basic.tex scripts .claude/skills
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

Extract the `CHANGELOG.md` section for `X.Y.Z` into a temporary notes file.

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
