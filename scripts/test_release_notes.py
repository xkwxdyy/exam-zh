#!/usr/bin/env python3
"""Regression tests for structured release notes."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import release_notes


CHANGELOG_TEMPLATE = """# Changelog

Intro.

## [Unreleased]

## [0.1.0] - 2026-01-01

### Added

- Initial release
"""


class ReleaseNotesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.fragments = self.root / ".changes" / "unreleased"
        self.releases = self.root / ".changes" / "releases"
        self.archive = self.root / ".changes" / "archive"
        self.changelog = self.root / "CHANGELOG.md"
        self.fragments.mkdir(parents=True)
        self.changelog.write_text(CHANGELOG_TEMPLATE, encoding="utf-8")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_fragment(self, name: str, data: dict[str, object]) -> Path:
        path = self.fragments / name
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return path

    def sample_fragment(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "topic": "sample-topic",
            "issues": ["Gitee #TEST"],
            "changes": [
                {
                    "id": "public-feature",
                    "type": "added",
                    "zh": "新增公开功能。",
                    "en": "Added a public feature.",
                    "changelog": True,
                    "announce": True,
                },
                {
                    "id": "internal-ci",
                    "type": "changed",
                    "zh": "调整内部 CI。",
                    "changelog": False,
                    "announce": False,
                },
                {
                    "id": "small-fix",
                    "type": "fixed",
                    "zh": "修复一个小问题。",
                    "changelog": True,
                    "announce": False,
                },
            ],
        }

    def test_prepare_release_archives_fragments_and_generates_outputs(self) -> None:
        fragment = self.write_fragment("20260801T000000Z-sample-topic.json", self.sample_fragment())
        _, expected = release_notes.generated_unreleased(self.changelog, self.fragments)
        self.changelog.write_text(expected, encoding="utf-8")

        manifest_path = release_notes.prepare_release(
            self.fragments,
            self.releases,
            self.archive,
            self.changelog,
            "0.2.0",
            "2026-08-01",
        )

        self.assertFalse(fragment.exists())
        self.assertTrue((self.archive / "0.2.0" / fragment.name).is_file())
        manifest = release_notes.load_json(manifest_path)
        changes = release_notes.validate_manifest(manifest)
        self.assertEqual([item["id"] for item in changes], ["public-feature", "small-fix"])
        self.assertEqual(
            release_notes.render_announcement(changes),
            "### Added\n\n- Added a public feature.\n",
        )
        release_notes.check_changelog(self.changelog, self.fragments, self.releases)

    def test_unreleased_check_detects_manual_edits(self) -> None:
        self.write_fragment("20260801T000000Z-sample-topic.json", self.sample_fragment())
        with self.assertRaisesRegex(release_notes.NotesError, "Unreleased section is stale"):
            release_notes.check_changelog(self.changelog, self.fragments, self.releases)

    def test_announced_change_requires_reviewed_english(self) -> None:
        fragment = self.sample_fragment()
        changes = fragment["changes"]
        assert isinstance(changes, list)
        public = changes[0]
        assert isinstance(public, dict)
        public.pop("en")
        self.write_fragment("20260801T000000Z-sample-topic.json", fragment)

        with self.assertRaisesRegex(release_notes.NotesError, "en is required"):
            release_notes.load_fragments(self.fragments, require_any=True)

    def test_release_manifest_must_match_changelog_section(self) -> None:
        fragment = self.write_fragment("20260801T000000Z-sample-topic.json", self.sample_fragment())
        _, expected = release_notes.generated_unreleased(self.changelog, self.fragments)
        self.changelog.write_text(expected, encoding="utf-8")
        release_notes.prepare_release(
            self.fragments,
            self.releases,
            self.archive,
            self.changelog,
            "0.2.0",
            "2026-08-01",
        )
        self.changelog.write_text(
            self.changelog.read_text(encoding="utf-8").replace("新增公开功能。", "手工修改。"),
            encoding="utf-8",
        )

        self.assertFalse(fragment.exists())
        with self.assertRaisesRegex(release_notes.NotesError, "release section 0.2.0 is stale"):
            release_notes.check_changelog(self.changelog, self.fragments, self.releases)


if __name__ == "__main__":
    unittest.main()
