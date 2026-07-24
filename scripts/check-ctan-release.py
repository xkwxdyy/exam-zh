#!/usr/bin/env python3
"""Validate release metadata and the archive used for a CTAN upload."""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parent.parent
VERSION_RE = re.compile(r"v[0-9]+\.[0-9]+\.[0-9]+")
DATE_RE = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")
FORBIDDEN_SUFFIXES = (
    ".aux",
    ".curlopt",
    ".fdb_latexmk",
    ".fls",
    ".log",
    ".synctex.gz",
)


class ReleaseError(RuntimeError):
    """A release invariant is not satisfied."""


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ReleaseError(f"cannot read {path.relative_to(ROOT)}: {exc}") from exc


def lua_string(name: str, content: str) -> str:
    match = re.search(rf'^\s*{re.escape(name)}\s*=\s*"([^"]+)"', content, re.MULTILINE)
    if not match:
        raise ReleaseError(f'build.lua does not define {name} = "..."')
    return match.group(1)


def release_metadata(tag: str) -> tuple[str, str, str]:
    if not VERSION_RE.fullmatch(tag):
        raise ReleaseError(f"tag must have the form vX.Y.Z, got {tag!r}")

    build_lua = read(ROOT / "build.lua")
    version = lua_string("version", build_lua)
    date = lua_string("date", build_lua)
    if version != tag:
        raise ReleaseError(f"tag {tag} does not match build.lua version {version}")
    if not DATE_RE.fullmatch(date):
        raise ReleaseError(f"build.lua date is not YYYY-MM-DD: {date!r}")

    package_files = [ROOT / "exam-zh.cls", *sorted(ROOT.glob("exam-zh-*.sty"))]
    marker = f"{{{date}}} {{{version}}}"
    mismatched = [path.name for path in package_files if marker not in read(path)]
    if mismatched:
        raise ReleaseError(
            "package metadata does not match build.lua: " + ", ".join(mismatched)
        )

    for relative in ("doc/exam-zh-doc.tex", "doc-basic/exam-zh-doc-basic.tex"):
        content = read(ROOT / relative)
        if f"\\newcommand{{\\DocDate}}{{{date}}}" not in content:
            raise ReleaseError(f"{relative} does not contain DocDate {date}")
        if f"\\newcommand{{\\DocVersion}}{{{version}}}" not in content:
            raise ReleaseError(f"{relative} does not contain DocVersion {version}")

    changelog = read(ROOT / "CHANGELOG.md")
    bare_version = version.removeprefix("v")
    heading = rf"^## \[{re.escape(bare_version)}\] - {re.escape(date)}\s*$"
    start = re.search(heading, changelog, re.MULTILINE)
    if not start:
        raise ReleaseError(f"CHANGELOG.md has no release section for {bare_version} - {date}")
    following = re.search(r"^## \[", changelog[start.end() :], re.MULTILINE)
    end = start.end() + following.start() if following else len(changelog)
    announcement = changelog[start.end() : end].strip()
    if not announcement:
        raise ReleaseError("the release changelog section is empty")
    if len(announcement.encode("utf-8")) > 8192:
        raise ReleaseError("the CTAN announcement exceeds l3build's 8192-byte limit")

    return version, date, announcement + "\n"


def validate_archive(path: Path) -> None:
    if not path.is_file() or path.stat().st_size == 0:
        raise ReleaseError(f"archive is missing or empty: {path}")

    required = {
        "exam-zh/README.md",
        "exam-zh/LICENSE",
        "exam-zh/exam-zh.cls",
        "exam-zh/exam-zh-doc.pdf",
        "exam-zh/exam-zh-doc-basic.pdf",
    }
    with zipfile.ZipFile(path) as archive:
        corrupt = archive.testzip()
        if corrupt:
            raise ReleaseError(f"archive contains a corrupt member: {corrupt}")
        names = set(archive.namelist())

    missing = sorted(required - names)
    if missing:
        raise ReleaseError("archive is missing required files: " + ", ".join(missing))

    bad: list[str] = []
    for name in sorted(names):
        member = PurePosixPath(name)
        if member.is_absolute() or ".." in member.parts:
            bad.append(name)
            continue
        if not member.parts or member.parts[0] != "exam-zh":
            bad.append(name)
            continue
        lowered = name.lower()
        if (
            any(part in {".git", "__macosx", "__pycache__"} for part in member.parts)
            or lowered.endswith(FORBIDDEN_SUFFIXES)
            or lowered.endswith(".ds_store")
        ):
            bad.append(name)
    if bad:
        raise ReleaseError("archive contains unsafe or generated files: " + ", ".join(bad))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True, help="release tag, for example v0.3.0")
    parser.add_argument("--archive", type=Path, help="optional l3build CTAN archive")
    parser.add_argument("--announcement-output", type=Path)
    args = parser.parse_args()

    try:
        version, date, announcement = release_metadata(args.tag)
        if args.archive:
            validate_archive(args.archive)
        if args.announcement_output:
            args.announcement_output.parent.mkdir(parents=True, exist_ok=True)
            args.announcement_output.write_text(announcement, encoding="utf-8")
    except (OSError, zipfile.BadZipFile, ReleaseError) as exc:
        print(f"CTAN release check failed: {exc}", file=sys.stderr)
        return 1

    archive_note = f" and {args.archive}" if args.archive else ""
    print(f"CTAN release metadata for {version} ({date}){archive_note} is valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
