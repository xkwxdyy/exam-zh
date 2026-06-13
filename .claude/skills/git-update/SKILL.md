---
name: git-update
description: Stage, commit, amend, and optionally push current exam-zh changes with scripts/git-update.sh. Use for ordinary commit/sync requests. Use examzh-release for releases, version bumps, tags, CTAN packages, GitHub Releases, and Gitee Releases.
allowed-tools: Bash(git status *) Bash(git diff) Bash(git diff *) Bash(git log *) Bash(git remote *) Bash(bash scripts/git-update.sh) Bash(bash scripts/git-update.sh *)
disable-model-invocation: true
---

# git-update

Project-level Claude Code skill for ordinary `exam-zh` Git workflow.

Use this skill for day-to-day staging, committing, amending, and pushing. Use `examzh-release` for release, version, tag, CTAN, GitHub Release, and Gitee Release workflows.

## Script Capability

`scripts/git-update.sh` currently supports:

- checking repository status;
- staging all changes with `git add -A`;
- creating a commit with a supplied message;
- amending the previous commit when requested;
- pushing to the selected remote branch;
- `--dry-run`, `--no-push`, `--remote`, `--all-remotes`, `--amend`, and `--force` modes.

## Usage

```text
/git-update "Update documentation"
/git-update --dry-run "Update documentation"
/git-update --no-push "WIP: improve examples"
/git-update --remote github "Update examples"
/git-update --all-remotes "Sync release notes"
/git-update --amend --no-push
/git-update --force "Update release scripts"
```

## Required Workflow

1. Inspect current changes:
   ```bash
   git status --short
   git diff --stat
   ```
2. Review relevant diffs before committing:
   ```bash
   git diff
   ```
3. Choose a precise Conventional Commits message from the actual changes.
4. Run the helper:
   ```bash
   bash scripts/git-update.sh "commit message"
   ```
5. Use `--no-push` for local-only commits.
6. Use `--remote github`, `--remote gitee`, or `--all-remotes` when the target remote matters.

## Argument Rules

- A commit message is required for a new commit.
- `--dry-run` previews `git add`, `git commit`, and `git push` commands.
- `--no-push` creates the commit locally.
- `--remote NAME` pushes to one configured remote.
- `--all-remotes` pushes to every configured remote.
- `--amend` updates the previous commit.
- `--force` skips the interactive confirmation prompt.

## Safety Notes

- Review the diff before running the helper because the script stages all changes.
- Use `--dry-run` when the target remote or amend behavior needs confirmation.
- Use `--no-push` when changes should stay local for review.
- For release requests, switch to `examzh-release`.
- When `scripts/git-update.sh` reports an error, relay the failing step and key error output.
