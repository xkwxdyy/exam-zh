#!/usr/bin/env python3
"""Manage structured changelog fragments and release notes."""

from __future__ import annotations

import argparse
import difflib
import json
import re
import shutil
import sys
import tempfile
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_FRAGMENTS = ROOT / ".changes" / "unreleased"
DEFAULT_RELEASES = ROOT / ".changes" / "releases"
DEFAULT_ARCHIVE = ROOT / ".changes" / "archive"
DEFAULT_CHANGELOG = ROOT / "CHANGELOG.md"

TYPE_HEADINGS = {
    "added": "Added",
    "changed": "Changed",
    "deprecated": "Deprecated",
    "removed": "Removed",
    "fixed": "Fixed",
    "security": "Security",
}
ID_RE = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
VERSION_RE = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+")
CJK_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]")
ANNOUNCEMENT_LIMIT = 8192


class NotesError(RuntimeError):
    """A release-note invariant is not satisfied."""


def display_path(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise NotesError(f"cannot read valid JSON from {display_path(path)}: {exc}") from exc
    if not isinstance(value, dict):
        raise NotesError(f"{display_path(path)} root must be a JSON object")
    return value


def require_single_line(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise NotesError(f"{field} must be a non-empty string")
    if "\n" in value or "\r" in value:
        raise NotesError(f"{field} must be a single line")
    return value.strip()


def validate_version_date(version_value: Any, date_value: Any) -> tuple[str, str]:
    version = require_single_line(version_value, "version")
    if not VERSION_RE.fullmatch(version):
        raise NotesError("version must have the form X.Y.Z without a leading v")
    release_date = require_single_line(date_value, "date")
    try:
        date.fromisoformat(release_date)
    except ValueError as exc:
        raise NotesError("date must be a valid ISO date in YYYY-MM-DD form") from exc
    return version, release_date


def normalize_change(item: Any, prefix: str, *, fragment: bool) -> dict[str, Any]:
    if not isinstance(item, dict):
        raise NotesError(f"{prefix} must be an object")
    item_id = require_single_line(item.get("id"), f"{prefix}.id")
    if not ID_RE.fullmatch(item_id):
        raise NotesError(f"{prefix}.id must use lowercase kebab-case")
    change_type = item.get("type")
    if change_type not in TYPE_HEADINGS:
        allowed = ", ".join(TYPE_HEADINGS)
        raise NotesError(f"{prefix}.type must be one of: {allowed}")
    zh = require_single_line(item.get("zh"), f"{prefix}.zh")
    announce = item.get("announce")
    if not isinstance(announce, bool):
        raise NotesError(f"{prefix}.announce must be true or false")

    changelog = True
    if fragment:
        changelog = item.get("changelog")
        if not isinstance(changelog, bool):
            raise NotesError(f"{prefix}.changelog must be true or false")
        if announce and not changelog:
            raise NotesError(f"{prefix}: announce=true requires changelog=true")

    en_value = item.get("en")
    en = None
    if en_value is not None:
        en = require_single_line(en_value, f"{prefix}.en")
    if announce and not en:
        raise NotesError(f"{prefix}.en is required when announce is true")
    if announce and en and CJK_RE.search(en):
        raise NotesError(f"{prefix}.en must contain no CJK characters")

    return {
        "id": item_id,
        "type": change_type,
        "zh": zh,
        "en": en,
        "changelog": changelog,
        "announce": announce,
    }


def validate_unique(changes: list[dict[str, Any]]) -> None:
    seen: set[str] = set()
    for item in changes:
        if item["id"] in seen:
            raise NotesError(f"duplicate change id: {item['id']}")
        seen.add(item["id"])


def fragment_paths(directory: Path) -> list[Path]:
    return sorted(directory.glob("*.json")) if directory.is_dir() else []


def load_fragments(directory: Path, *, require_any: bool) -> tuple[list[Path], list[dict[str, Any]]]:
    paths = fragment_paths(directory)
    if require_any and not paths:
        raise NotesError(f"no JSON fragments found in {display_path(directory)}")

    changes: list[dict[str, Any]] = []
    for path in paths:
        data = load_json(path)
        if data.get("schema_version") != 1:
            raise NotesError(f"{display_path(path)}.schema_version must be 1")
        topic = require_single_line(data.get("topic"), f"{display_path(path)}.topic")
        if not ID_RE.fullmatch(topic):
            raise NotesError(f"{display_path(path)}.topic must use lowercase kebab-case")
        issues = data.get("issues", [])
        if not isinstance(issues, list):
            raise NotesError(f"{display_path(path)}.issues must be an array")
        for index, issue in enumerate(issues):
            require_single_line(issue, f"{display_path(path)}.issues[{index}]")
        raw_changes = data.get("changes")
        if not isinstance(raw_changes, list) or not raw_changes:
            raise NotesError(f"{display_path(path)}.changes must be a non-empty array")
        changes.extend(
            normalize_change(
                item,
                f"{display_path(path)}.changes[{index}]",
                fragment=True,
            )
            for index, item in enumerate(raw_changes)
        )
    validate_unique(changes)
    return paths, changes


def validate_manifest(data: dict[str, Any], source: str = "manifest") -> list[dict[str, Any]]:
    if data.get("schema_version") != 1:
        raise NotesError(f"{source}.schema_version must be 1")
    validate_version_date(data.get("version"), data.get("date"))
    source_fragments = data.get("source_fragments")
    if not isinstance(source_fragments, list) or not source_fragments:
        raise NotesError(f"{source}.source_fragments must be a non-empty array")
    for index, name in enumerate(source_fragments):
        fragment_name = require_single_line(name, f"{source}.source_fragments[{index}]")
        if Path(fragment_name).name != fragment_name or not fragment_name.endswith(".json"):
            raise NotesError(f"{source}.source_fragments[{index}] must be a JSON filename")
    if len(set(source_fragments)) != len(source_fragments):
        raise NotesError(f"{source}.source_fragments contains duplicates")

    raw_changes = data.get("changes")
    if not isinstance(raw_changes, list) or not raw_changes:
        raise NotesError(f"{source}.changes must be a non-empty array")
    changes = [
        normalize_change(item, f"{source}.changes[{index}]", fragment=False)
        for index, item in enumerate(raw_changes)
    ]
    validate_unique(changes)
    return changes


def assemble_manifest(directory: Path, version: str, release_date: str) -> dict[str, Any]:
    validate_version_date(version, release_date)
    paths, changes = load_fragments(directory, require_any=True)
    public_changes: list[dict[str, Any]] = []
    for item in changes:
        if not item["changelog"]:
            continue
        output = {
            "id": item["id"],
            "type": item["type"],
            "zh": item["zh"],
            "announce": item["announce"],
        }
        if item["en"] is not None:
            output["en"] = item["en"]
        public_changes.append(output)
    if not public_changes:
        raise NotesError("fragments contain no entries selected for the changelog")

    manifest = {
        "schema_version": 1,
        "version": version,
        "date": release_date,
        "source_fragments": [path.name for path in paths],
        "changes": public_changes,
    }
    validate_manifest(manifest)
    return manifest


def render_grouped(changes: list[dict[str, Any]], language: str) -> str:
    blocks: list[str] = []
    for change_type, heading in TYPE_HEADINGS.items():
        entries = [item[language] for item in changes if item["type"] == change_type]
        entries = [entry for entry in entries if entry]
        if entries:
            blocks.append(f"### {heading}\n\n" + "\n".join(f"- {entry}" for entry in entries))
    return "\n\n".join(blocks)


def render_release_section(data: dict[str, Any], changes: list[dict[str, Any]]) -> str:
    body = render_grouped(changes, "zh")
    return f"## [{data['version']}] - {data['date']}\n\n{body}\n"


def render_unreleased_section(changes: list[dict[str, Any]]) -> str:
    public = [item for item in changes if item["changelog"]]
    body = render_grouped(public, "zh")
    return "## [Unreleased]\n" + (f"\n{body}\n" if body else "")


def render_announcement(changes: list[dict[str, Any]]) -> str:
    public = [item for item in changes if item["announce"]]
    output = render_grouped(public, "en")
    if output:
        output += "\n"
    size = len(output.encode("utf-8"))
    if size > ANNOUNCEMENT_LIMIT:
        raise NotesError(
            f"English announcement is {size} bytes; l3build limit is {ANNOUNCEMENT_LIMIT}"
        )
    return output


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        raise NotesError(f"cannot read {display_path(path)}: {exc}") from exc


def section_bounds(changelog: str, heading: str) -> tuple[int, int]:
    match = re.search(
        rf"^## \[{re.escape(heading)}\](?: - [^\n]+)?[ \t]*$",
        changelog,
        re.MULTILINE,
    )
    if not match:
        raise NotesError(f"CHANGELOG.md has no [{heading}] section")
    following = re.search(r"^## \[", changelog[match.end() :], re.MULTILINE)
    end = match.end() + following.start() if following else len(changelog)
    return match.start(), end


def extract_section(changelog: str, heading: str) -> str:
    start, end = section_bounds(changelog, heading)
    return changelog[start:end].strip() + "\n"


def replace_unreleased(changelog: str, section: str) -> str:
    start, end = section_bounds(changelog, "Unreleased")
    suffix = changelog[end:].lstrip("\n")
    return changelog[:start] + section.rstrip() + "\n\n" + suffix


def insert_release(changelog: str, manifest: dict[str, Any], changes: list[dict[str, Any]]) -> str:
    version = manifest["version"]
    try:
        section_bounds(changelog, version)
    except NotesError:
        pass
    else:
        raise NotesError(f"CHANGELOG.md already has a [{version}] section")
    start, end = section_bounds(changelog, "Unreleased")
    suffix = changelog[end:].lstrip("\n")
    release = render_release_section(manifest, changes).rstrip()
    return changelog[:start] + "## [Unreleased]\n\n" + release + "\n\n" + suffix


def unified_diff(current: str, expected: str, path: Path) -> str:
    return "".join(
        difflib.unified_diff(
            current.splitlines(keepends=True),
            expected.splitlines(keepends=True),
            fromfile=display_path(path),
            tofile=f"generated/{display_path(path)}",
        )
    )


def write_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        newline="\n",
        dir=path.parent,
        prefix=f".{path.name}.",
        delete=False,
    ) as handle:
        handle.write(content)
        temporary = Path(handle.name)
    temporary.replace(path)


def json_text(data: dict[str, Any]) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def generated_unreleased(changelog_path: Path, fragments: Path) -> tuple[str, str]:
    current = read_text(changelog_path)
    _, changes = load_fragments(fragments, require_any=False)
    expected = replace_unreleased(current, render_unreleased_section(changes))
    return current, expected


def check_changelog(
    changelog_path: Path,
    fragments: Path,
    releases: Path,
    archive: Path | None = None,
) -> None:
    current, expected = generated_unreleased(changelog_path, fragments)
    if current != expected:
        diff = unified_diff(current, expected, changelog_path)
        raise NotesError(f"generated Unreleased section is stale\n{diff}")

    archive = archive or releases.parent / "archive"
    manifest_paths = sorted(releases.glob("*.json")) if releases.is_dir() else []
    for path in manifest_paths:
        data = load_json(path)
        changes = validate_manifest(data, display_path(path))
        expected_name = f"{data['version']}.json"
        if path.name != expected_name:
            raise NotesError(f"{display_path(path)} must be named {expected_name}")
        archived_fragments = archive / data["version"]
        archived_names = [item.name for item in fragment_paths(archived_fragments)]
        if archived_names != data["source_fragments"]:
            raise NotesError(
                f"{display_path(archived_fragments)} does not match source_fragments "
                f"in {display_path(path)}"
            )
        reassembled = assemble_manifest(archived_fragments, data["version"], data["date"])
        if reassembled != data:
            raise NotesError(f"{display_path(path)} cannot be reproduced from archived fragments")
        actual_section = extract_section(current, data["version"])
        expected_section = render_release_section(data, changes)
        if actual_section != expected_section:
            diff = unified_diff(actual_section, expected_section, changelog_path)
            raise NotesError(f"release section {data['version']} is stale\n{diff}")


def prepare_release(
    fragments: Path,
    releases: Path,
    archive: Path,
    changelog_path: Path,
    version: str,
    release_date: str,
) -> Path:
    manifest = assemble_manifest(fragments, version, release_date)
    paths = fragment_paths(fragments)
    current, expected_unreleased = generated_unreleased(changelog_path, fragments)
    if current != expected_unreleased:
        diff = unified_diff(current, expected_unreleased, changelog_path)
        raise NotesError(f"run changelog generation before preparing a release\n{diff}")

    manifest_path = releases / f"{version}.json"
    archive_path = archive / version
    if manifest_path.exists():
        raise NotesError(f"refusing to overwrite {display_path(manifest_path)}")
    if archive_path.exists():
        raise NotesError(f"refusing to overwrite {display_path(archive_path)}")

    changes = validate_manifest(manifest)
    updated_changelog = insert_release(current, manifest, changes)
    archive.mkdir(parents=True, exist_ok=True)
    temporary_archive = Path(tempfile.mkdtemp(prefix=f".{version}.", dir=archive))
    moved: list[tuple[Path, Path]] = []
    manifest_written = False
    changelog_written = False
    try:
        for source in paths:
            target = temporary_archive / source.name
            source.replace(target)
            moved.append((source, target))
        write_atomic(manifest_path, json_text(manifest))
        manifest_written = True
        write_atomic(changelog_path, updated_changelog)
        changelog_written = True
        temporary_archive.replace(archive_path)
    except OSError as exc:
        if changelog_written:
            write_atomic(changelog_path, current)
        if manifest_written and manifest_path.exists():
            manifest_path.unlink()
        for source, target in reversed(moved):
            if target.exists():
                target.replace(source)
        if temporary_archive.exists():
            shutil.rmtree(temporary_archive)
        raise NotesError(f"could not prepare release transaction: {exc}") from exc
    return manifest_path


def create_fragment(args: argparse.Namespace) -> Path:
    if args.announce and args.no_changelog:
        raise NotesError("--announce cannot be combined with --no-changelog")
    change: dict[str, Any] = {
        "id": args.id,
        "type": args.type,
        "zh": args.zh,
        "changelog": not args.no_changelog,
        "announce": args.announce,
    }
    if args.en is not None:
        change["en"] = args.en
    fragment: dict[str, Any] = {
        "schema_version": 1,
        "topic": args.topic,
        "changes": [change],
    }
    if args.issue:
        fragment["issues"] = args.issue
    for index, issue in enumerate(args.issue):
        require_single_line(issue, f"issues[{index}]")
    normalize_change(change, "change", fragment=True)
    if not ID_RE.fullmatch(require_single_line(args.topic, "topic")):
        raise NotesError("topic must use lowercase kebab-case")

    args.fragments.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    path = args.fragments / f"{stamp}-{args.topic}.json"
    counter = 2
    while path.exists():
        path = args.fragments / f"{stamp}-{args.topic}-{counter}.json"
        counter += 1
    write_atomic(path, json_text(fragment))
    return path


def add_common_paths(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--fragments", type=Path, default=DEFAULT_FRAGMENTS)
    parser.add_argument("--changelog", type=Path, default=DEFAULT_CHANGELOG)


def main() -> int:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)

    create = commands.add_parser("create", help="create one unreleased fragment")
    create.add_argument("--fragments", type=Path, default=DEFAULT_FRAGMENTS)
    create.add_argument("--topic", required=True)
    create.add_argument("--id", required=True)
    create.add_argument("--type", required=True, choices=tuple(TYPE_HEADINGS))
    create.add_argument("--zh", required=True)
    create.add_argument("--en")
    create.add_argument("--no-changelog", action="store_true")
    create.add_argument("--announce", action="store_true")
    create.add_argument("--issue", action="append", default=[])

    changelog = commands.add_parser("changelog", help="render the Unreleased section")
    add_common_paths(changelog)
    changelog.add_argument("--check", action="store_true")

    check = commands.add_parser("check", help="validate fragments, manifests, and changelog")
    add_common_paths(check)
    check.add_argument("--releases", type=Path, default=DEFAULT_RELEASES)
    check.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE)

    prepare = commands.add_parser("prepare", help="finalize release notes and archive fragments")
    add_common_paths(prepare)
    prepare.add_argument("--releases", type=Path, default=DEFAULT_RELEASES)
    prepare.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE)
    prepare.add_argument("--version", required=True)
    prepare.add_argument("--date", required=True)

    render = commands.add_parser("render", help="render one versioned manifest")
    render.add_argument("manifest", type=Path)
    render.add_argument("--changelog-output", type=Path)
    render.add_argument("--announcement-output", type=Path)

    validate = commands.add_parser("validate", help="validate one versioned manifest")
    validate.add_argument("manifest", type=Path)

    args = parser.parse_args()
    try:
        if args.command == "create":
            path = create_fragment(args)
            print(display_path(path))
            return 0

        if args.command == "changelog":
            current, expected = generated_unreleased(args.changelog, args.fragments)
            if args.check:
                if current != expected:
                    diff = unified_diff(current, expected, args.changelog)
                    raise NotesError(f"generated Unreleased section is stale\n{diff}")
                print("Unreleased changelog section is current")
            else:
                write_atomic(args.changelog, expected)
                print("Unreleased changelog section updated")
            return 0

        if args.command == "check":
            check_changelog(args.changelog, args.fragments, args.releases, args.archive)
            print("change fragments, release manifests, and CHANGELOG.md are consistent")
            return 0

        if args.command == "prepare":
            path = prepare_release(
                args.fragments,
                args.releases,
                args.archive,
                args.changelog,
                args.version,
                args.date,
            )
            print(f"release notes prepared: {display_path(path)}")
            return 0

        data = load_json(args.manifest)
        changes = validate_manifest(data, display_path(args.manifest))
        announcement = render_announcement(changes)
        if args.command == "validate":
            public_count = sum(item["announce"] for item in changes)
            print(
                f"release {data['version']} is valid: "
                f"{len(changes)} changelog entries, {public_count} announcement entries"
            )
            return 0

        if not args.changelog_output and not args.announcement_output:
            raise NotesError("render requires at least one output path")
        if args.changelog_output:
            write_atomic(args.changelog_output, render_release_section(data, changes))
        if args.announcement_output:
            write_atomic(args.announcement_output, announcement)
        print("release-note outputs rendered")
        return 0
    except NotesError as exc:
        print(f"release notes error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
