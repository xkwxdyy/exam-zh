# Change Fragments

Changelog entries are recorded as UTF-8 JSON fragments in `unreleased/`.
Each topic commit should contain one fragment describing all changes from that
topic. `CHANGELOG.md` is the generated user-facing view; do not edit its
`[Unreleased]` section directly.

## Fragment Format

```json
{
  "schema_version": 1,
  "topic": "fillin-auto-width",
  "issues": ["Gitee #ID6D6C"],
  "changes": [
    {
      "id": "fillin-auto-width",
      "type": "added",
      "zh": "为 `fillin` 新增自动宽度。",
      "en": "Added automatic width calculation for `fillin`.",
      "changelog": true,
      "announce": true
    }
  ]
}
```

- `topic` and every `id` use lowercase kebab-case.
- `type` is `added`, `changed`, `deprecated`, `removed`, `fixed`, or
  `security`.
- `zh` is the complete Chinese changelog entry.
- `changelog` controls whether the entry appears in `CHANGELOG.md`.
- `announce` selects important user-visible entries for the English CTAN
  announcement. It requires `changelog: true` and a reviewed English `en`.
- Internal maintenance uses `changelog: false` and `announce: false`.
- Dashboard and local release-workflow updates may use `changelog: true` for
  GitHub/Gitee release notes, but use `announce: false` so they do not enter the
  CTAN announcement unless they directly affect CTAN package users.

## Commands

```bash
# Create a fragment.
python3 scripts/release_notes.py create \
  --topic fillin-auto-width \
  --id fillin-auto-width \
  --type added \
  --zh '为 `fillin` 新增自动宽度。' \
  --en 'Added automatic width calculation for `fillin`.' \
  --announce

# Regenerate or check the [Unreleased] section.
make changelog
make check-changelog

# Finalize notes before tagging a release.
make prepare-release VERSION=0.3.2 DATE=2026-08-01
```

`prepare-release` writes `releases/<version>.json`, moves the consumed
fragments into `archive/<version>/`, inserts the generated release section,
and resets `[Unreleased]`. Versioned manifests are the source used to generate
the English CTAN announcement.
