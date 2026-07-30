#!/usr/bin/env python3
"""Regression tests for CTAN archive validation."""

from __future__ import annotations

import importlib.util
import tempfile
import unittest
import zipfile
from pathlib import Path


SCRIPT = Path(__file__).with_name("check-ctan-release.py")
SPEC = importlib.util.spec_from_file_location("check_ctan_release", SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot load {SCRIPT}")
check_ctan_release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(check_ctan_release)


class ArchiveValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.archive = Path(self.temporary.name) / "exam-zh.zip"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_archive(self, members: set[str]) -> None:
        with zipfile.ZipFile(self.archive, "w") as archive:
            for member in members:
                archive.writestr(member, "test\n")

    def test_accepts_l3build_layout(self) -> None:
        self.write_archive(check_ctan_release.ARCHIVE_LAYOUTS["l3build"])
        check_ctan_release.validate_archive(self.archive)

    def test_accepts_tds_layout(self) -> None:
        self.write_archive(check_ctan_release.ARCHIVE_LAYOUTS["tds"])
        check_ctan_release.validate_archive(self.archive)

    def test_rejects_archive_missing_files_from_both_layouts(self) -> None:
        self.write_archive({"exam-zh/README.md", "exam-zh/LICENSE"})
        with self.assertRaisesRegex(
            check_ctan_release.ReleaseError, "does not match a supported layout"
        ):
            check_ctan_release.validate_archive(self.archive)

    def test_rejects_unsafe_member(self) -> None:
        members = set(check_ctan_release.ARCHIVE_LAYOUTS["tds"])
        members.add("exam-zh/../secret.txt")
        self.write_archive(members)
        with self.assertRaisesRegex(check_ctan_release.ReleaseError, "unsafe"):
            check_ctan_release.validate_archive(self.archive)


if __name__ == "__main__":
    unittest.main()
