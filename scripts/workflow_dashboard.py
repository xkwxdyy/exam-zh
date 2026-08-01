#!/usr/bin/env python3
"""Serve the local exam-zh release workflow dashboard."""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import os
import re
import secrets
import shlex
import shutil
import signal
import subprocess
import sys
import threading
import time
import uuid
import webbrowser
from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse


ROOT = Path(__file__).resolve().parent.parent
DASHBOARD_DIR = ROOT / "tools" / "release-dashboard"
VERSION_RE = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+")
MAX_REQUEST_BYTES = 64 * 1024
MAX_LOG_LINES = 6000
DASHBOARD_API_VERSION = 7
STATE_SCHEMA_VERSION = 1
STATE_PATH = ROOT / ".release-dashboard" / "state.json"


WORKFLOWS: tuple[dict[str, Any], ...] = (
    {
        "id": "release-pipeline",
        "stage": "pipeline",
        "title": "执行完整发布链",
        "description": "从 Changelog 校验开始，按所选出口自动完成后续发布步骤",
        "icon": "workflow",
        "risk": "external",
        "executor": "pipeline",
        "command": "Changelog 校验 → 测试 → 编译打包 → Git 提交 → Tag → 发布出口",
        "requires": ["version", "date", "publishTarget"],
    },
    {
        "id": "changelog-generate",
        "stage": "changes",
        "title": "生成 Unreleased",
        "description": "从结构化片段刷新 CHANGELOG.md",
        "icon": "file-clock",
        "risk": "write",
        "executor": "process",
        "command": "make changelog",
        "requires": [],
    },
    {
        "id": "changelog-check",
        "stage": "changes",
        "title": "校验变更记录",
        "description": "核对片段、归档、清单与 Markdown",
        "icon": "list-checks",
        "risk": "safe",
        "executor": "process",
        "command": "make check-changelog",
        "requires": [],
    },
    {
        "id": "ai-changelog",
        "stage": "changes",
        "title": "AI 整理发布内容",
        "description": "整理 Changelog、测试文件和相关手册",
        "icon": "sparkles",
        "risk": "interactive",
        "executor": "claude",
        "command": "claude '/examzh-release prepare'",
        "requires": [],
    },
    {
        "id": "release-notes-test",
        "stage": "verify",
        "title": "发布说明测试",
        "description": "运行 fragment 与 manifest 回归测试",
        "icon": "braces",
        "risk": "safe",
        "executor": "process",
        "command": "python3 scripts/test_release_notes.py",
        "requires": [],
    },
    {
        "id": "build-scripts-test",
        "stage": "verify",
        "title": "构建脚本测试",
        "description": "验证路径、版本与发布元数据",
        "icon": "wrench",
        "risk": "safe",
        "executor": "process",
        "command": "bash scripts/test-build.sh",
        "requires": [],
    },
    {
        "id": "tex-check",
        "stage": "verify",
        "title": "XeTeX 回归测试",
        "description": "执行完整 l3build check",
        "icon": "scan-line",
        "risk": "safe",
        "executor": "process",
        "command": "l3build check",
        "requires": [],
    },
    {
        "id": "examples-build",
        "stage": "verify",
        "title": "编译示例",
        "description": "编译单卷、多卷与基础示例",
        "icon": "files",
        "risk": "write",
        "executor": "process",
        "command": "make examples && make examples-basic",
        "requires": [],
    },
    {
        "id": "docs-build",
        "stage": "verify",
        "title": "编译双手册",
        "description": "生成完整手册与入门手册 PDF",
        "icon": "book-open-check",
        "risk": "write",
        "executor": "process",
        "command": "make doc && make doc-basic",
        "requires": [],
    },
    {
        "id": "prepare-release",
        "stage": "package",
        "title": "固化发布说明",
        "description": "归档片段并生成版本清单",
        "icon": "archive-restore",
        "risk": "mutating",
        "executor": "process",
        "command": "make prepare-release VERSION={version} DATE={date}",
        "requires": ["version", "date"],
        "confirmation": "PREPARE",
    },
    {
        "id": "ctan-package",
        "stage": "package",
        "title": "构建 CTAN 包",
        "description": "测试、编译并生成 exam-zh.zip",
        "icon": "package-check",
        "risk": "write",
        "executor": "process",
        "command": "l3build ctan",
        "requires": [],
    },
    {
        "id": "release-package",
        "stage": "package",
        "title": "构建 Release 包",
        "description": "生成 GitHub/Gitee 用户下载包",
        "icon": "package-plus",
        "risk": "write",
        "executor": "process",
        "command": "bash scripts/build-release.sh {version}",
        "requires": ["version"],
    },
    {
        "id": "full-package",
        "stage": "package",
        "title": "完整发布构建",
        "description": "更新元数据并生成两类发布包",
        "icon": "boxes",
        "risk": "mutating",
        "executor": "process",
        "command": "python3 scripts/build.py --non-interactive {version}",
        "requires": ["version"],
        "confirmation": "BUILD",
    },
    {
        "id": "inspect-ctan",
        "stage": "package",
        "title": "检查 CTAN 归档",
        "description": "检查压缩完整性、成员与发布元数据",
        "icon": "shield-check",
        "risk": "safe",
        "executor": "process",
        "command": "unzip -tq exam-zh.zip + metadata check",
        "requires": ["version"],
    },
    {
        "id": "release-preflight",
        "stage": "publish",
        "title": "发布前检查",
        "description": "检查分支、远程、Tag 与 GitHub 登录",
        "icon": "clipboard-check",
        "risk": "safe",
        "executor": "process",
        "command": "git/gh read-only preflight",
        "requires": [],
    },
    {
        "id": "git-dry-run",
        "stage": "publish",
        "title": "双远程同步预演",
        "description": "预览 commit 与 GitHub/Gitee push",
        "icon": "git-compare-arrows",
        "risk": "safe",
        "executor": "process",
        "command": "bash scripts/git-update.sh --dry-run --all-remotes",
        "requires": ["message"],
    },
    {
        "id": "ai-git-update",
        "stage": "publish",
        "title": "Claude Git 助手",
        "description": "在终端启动 /git-update",
        "icon": "git-commit-horizontal",
        "risk": "interactive",
        "executor": "claude",
        "command": "claude '/git-update --dry-run'",
        "requires": [],
    },
    {
        "id": "ai-github-release",
        "stage": "publish",
        "title": "发布 GitHub Release",
        "description": "由 Claude 核验 Tag、说明与附件",
        "icon": "github",
        "risk": "external",
        "executor": "claude",
        "command": "claude '/examzh-release github {version}'",
        "requires": ["version"],
        "confirmation": "VERSION",
    },
    {
        "id": "ai-gitee-release",
        "stage": "publish",
        "title": "发布 Gitee Release",
        "description": "由 Claude 核验 Token、说明与附件",
        "icon": "upload-cloud",
        "risk": "external",
        "executor": "claude",
        "command": "claude '/examzh-release gitee {version}'",
        "requires": ["version"],
        "confirmation": "VERSION",
    },
    {
        "id": "ai-full-release",
        "stage": "publish",
        "title": "正式发布全流程",
        "description": "提交、Tag、双远程及平台 Release",
        "icon": "rocket",
        "risk": "external",
        "executor": "claude",
        "command": "claude '/examzh-release full {version}'",
        "requires": ["version"],
        "confirmation": "VERSION",
    },
    {
        "id": "open-artifacts",
        "stage": "observe",
        "title": "打开产物目录",
        "description": "在 Finder 中显示 CTAN 与 Release",
        "icon": "folder-open",
        "risk": "safe",
        "executor": "process",
        "command": "open release && open CTAN",
        "requires": [],
    },
)

WORKFLOW_BY_ID = {item["id"]: item for item in WORKFLOWS}


class DashboardError(RuntimeError):
    """A dashboard request cannot be completed safely."""


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def require_version(params: dict[str, Any]) -> str:
    value = str(params.get("version", "")).strip().removeprefix("v")
    if not VERSION_RE.fullmatch(value):
        raise DashboardError("版本号必须使用 X.Y.Z 格式")
    return value


def require_date(params: dict[str, Any]) -> str:
    value = str(params.get("date", "")).strip()
    try:
        date.fromisoformat(value)
    except ValueError as exc:
        raise DashboardError("日期必须使用 YYYY-MM-DD 格式") from exc
    return value


def require_message(params: dict[str, Any]) -> str:
    value = str(params.get("message", "")).strip()
    if not value or len(value) > 200 or "\n" in value or "\r" in value:
        raise DashboardError("提交信息必须是 1-200 字符的单行文本")
    return value


def require_publish_target(params: dict[str, Any]) -> str:
    value = str(params.get("publishTarget", "platforms")).strip().lower()
    if value not in {"platforms", "all", "ctan"}:
        raise DashboardError("发布出口只能选择 GitHub + Gitee、全部发布或单独 CTAN")
    return value


def pipeline_params(params: dict[str, Any]) -> tuple[str, str, str, str]:
    version = require_version(params)
    release_date = require_date(params)
    target = require_publish_target(params)
    message = str(params.get("message", "")).strip() or f"chore(release): v{version}"
    if len(message) > 200 or "\n" in message or "\r" in message:
        raise DashboardError("提交信息必须是 1-200 字符的单行文本")
    return version, release_date, target, message


def normalized_pipeline_params(params: dict[str, Any]) -> dict[str, Any]:
    version, release_date, target, message = pipeline_params(params)
    return {
        "version": version,
        "date": release_date,
        "publishTarget": target,
        "message": message,
        "skipCompile": bool(params.get("skipCompile")),
    }


def next_patch_version(version: str) -> str:
    value = require_version({"version": version})
    major, minor, patch = (int(part) for part in value.split("."))
    return f"{major}.{minor}.{patch + 1}"


def suggested_release_context(
    current_version: str,
    release_date: str,
    jobs: list[Job],
) -> dict[str, Any]:
    pipeline_jobs = sorted(
        (job for job in jobs if job.workflow_id == "release-pipeline"),
        key=lambda item: item.created_at,
        reverse=True,
    )
    latest = pipeline_jobs[0] if pipeline_jobs else None
    completed = bool(
        latest
        and latest.status == "success"
        and latest.step_count > 0
        and latest.completed_steps == latest.step_count
    )
    if latest and not completed:
        try:
            return normalized_pipeline_params(latest.params)
        except DashboardError:
            pass

    candidates: list[str] = []
    for value in (current_version, latest.params.get("version", "") if completed else ""):
        try:
            candidates.append(require_version({"version": value}))
        except DashboardError:
            pass
    base_version = max(candidates, key=lambda value: tuple(map(int, value.split("."))), default="")
    version = next_patch_version(base_version) if base_version else ""
    return {
        "version": version,
        "date": release_date,
        "publishTarget": "platforms",
        "message": f"chore(release): v{version}" if version else "",
        "skipCompile": False,
    }


def build_steps(workflow_id: str, params: dict[str, Any]) -> list[tuple[str, list[str]]]:
    if workflow_id not in WORKFLOW_BY_ID:
        raise DashboardError("未知工作流")

    simple: dict[str, list[tuple[str, list[str]]]] = {
        "changelog-generate": [("生成 Unreleased", ["make", "changelog"])],
        "changelog-check": [("校验变更记录", ["make", "check-changelog"])],
        "release-notes-test": [
            ("发布说明回归测试", ["python3", "scripts/test_release_notes.py"])
        ],
        "build-scripts-test": [("构建脚本测试", ["bash", "scripts/test-build.sh"])],
        "tex-check": [("XeTeX 回归测试", ["l3build", "check"])],
        "examples-build": [
            ("根目录示例", ["make", "examples"]),
            ("基础示例", ["make", "examples-basic"]),
        ],
        "docs-build": [
            ("完整手册", ["make", "doc"]),
            ("入门手册", ["make", "doc-basic"]),
        ],
        "ctan-package": [("CTAN 标准包", ["l3build", "ctan"])],
        "release-preflight": [
            ("工作树", ["git", "status", "--short"]),
            ("当前分支", ["git", "branch", "--show-current"]),
            ("远程仓库", ["git", "remote", "-v"]),
            ("最近 Tag", ["git", "tag", "--sort=-v:refname"]),
            ("GitHub 登录", ["gh", "auth", "status"]),
        ],
        "open-artifacts": [
            ("打开 Release", ["open", str(ROOT / "release")]),
            ("打开 CTAN", ["open", str(ROOT / "CTAN")]),
        ],
    }
    if workflow_id == "release-pipeline":
        version, release_date, target, message = pipeline_params(params)
        if target == "ctan":
            ctan_steps = [
                (
                    "检查 CTAN 发布条件",
                    ["python3", "scripts/check-ctan-release.py", "--tag", f"v{version}"],
                ),
                (
                    "触发 CTAN 发布",
                    [
                        "gh",
                        "workflow",
                        "run",
                        "ctan-upload.yml",
                        "--repo",
                        "xkwxdyy/exam-zh",
                        "--ref",
                        "main",
                        "-f",
                        f"tag=v{version}",
                    ],
                ),
            ]
            return [(f"{index:02d} · {label}", command) for index, (label, command) in enumerate(ctan_steps, 1)]
        raw_steps: list[tuple[str, list[str]]] = [
            ("校验 Changelog", ["make", "check-changelog"]),
            ("发布工具测试", ["bash", "scripts/test-build.sh"]),
            ("XeTeX 回归测试", ["l3build", "check"]),
            (
                "固化发布说明",
                ["make", "prepare-release", f"VERSION={version}", f"DATE={release_date}"],
            ),
        ]
        build_command = ["python3", "scripts/build.py", "--non-interactive"]
        if bool(params.get("skipCompile")):
            build_command.append("--skip-compile")
        build_command.append(version)
        raw_steps.extend(
            [
                ("编译并构建归档", build_command),
                ("检查 CTAN ZIP", ["unzip", "-tq", "CTAN/exam-zh.zip"]),
                (
                    "校验 CTAN 元数据",
                    [
                        "python3",
                        "scripts/check-ctan-release.py",
                        "--tag",
                        f"v{version}",
                        "--archive",
                        "CTAN/exam-zh.zip",
                    ],
                ),
                (
                    "Git 提交",
                    ["bash", "scripts/git-update.sh", "--force", "--no-push", message],
                ),
                ("创建 Git Tag", ["git", "tag", "-a", f"v{version}", "-m", f"Release v{version}"]),
                ("推送 GitHub main", ["git", "push", "github", "main"]),
                ("推送 GitHub Tag", ["git", "push", "github", f"v{version}"]),
            ]
        )
        if target in {"platforms", "all"}:
            raw_steps.extend(
                [
                    ("推送 Gitee main", ["git", "push", "gitee", "main"]),
                    ("推送 Gitee Tag", ["git", "push", "gitee", f"v{version}"]),
                ]
            )
        raw_steps.extend(
            [
                (
                    "生成 Release 说明",
                    [
                        "python3",
                        "scripts/release_notes.py",
                        "render",
                        f".changes/releases/{version}.json",
                        "--changelog-output",
                        f"build/release-notes-v{version}.md",
                    ],
                ),
                (
                    "发布 GitHub Release",
                    [
                        "gh",
                        "release",
                        "create",
                        f"v{version}",
                        f"release/exam-zh-v{version}.zip",
                        "--repo",
                        "xkwxdyy/exam-zh",
                        "--title",
                        f"v{version}",
                        "--notes-file",
                        f"build/release-notes-v{version}.md",
                    ],
                ),
            ]
        )
        raw_steps.append(
            (
                "发布 Gitee Release",
                [
                    "bash",
                    "scripts/gitee-release.sh",
                    f"v{version}",
                    f"v{version}",
                    f"build/release-notes-v{version}.md",
                    f"release/exam-zh-v{version}.zip",
                ],
            )
        )
        if target == "all":
            raw_steps.append(
                (
                    "触发 CTAN 发布",
                    [
                        "gh", "workflow", "run", "ctan-upload.yml", "--repo", "xkwxdyy/exam-zh",
                        "--ref", "main", "-f", f"tag=v{version}",
                    ]
                )
            )
        return [(f"{index:02d} · {label}", command) for index, (label, command) in enumerate(raw_steps, 1)]
    if workflow_id in simple:
        return simple[workflow_id]

    if workflow_id == "prepare-release":
        version = require_version(params)
        release_date = require_date(params)
        return [
            (
                "固化发布说明",
                ["make", "prepare-release", f"VERSION={version}", f"DATE={release_date}"],
            )
        ]
    if workflow_id == "release-package":
        version = require_version(params)
        return [("Release 用户包", ["bash", "scripts/build-release.sh", version])]
    if workflow_id == "full-package":
        version = require_version(params)
        command = ["python3", "scripts/build.py", "--non-interactive"]
        if bool(params.get("skipCompile")):
            command.append("--skip-compile")
        command.append(version)
        return [("完整发布构建", command)]
    if workflow_id == "inspect-ctan":
        version = require_version(params)
        return [
            ("ZIP 完整性", ["unzip", "-tq", "exam-zh.zip"]),
            (
                "CTAN 发布元数据",
                [
                    "python3",
                    "scripts/check-ctan-release.py",
                    "--tag",
                    f"v{version}",
                    "--archive",
                    "CTAN/exam-zh.zip",
                ],
            ),
        ]
    if workflow_id == "git-dry-run":
        message = require_message(params)
        return [
            (
                "双远程同步预演",
                [
                    "bash",
                    "scripts/git-update.sh",
                    "--dry-run",
                    "--all-remotes",
                    message,
                ],
            )
        ]
    raise DashboardError("该工作流必须通过 Claude Code 终端执行")


def step_plan_signature(steps: list[tuple[str, list[str]]]) -> str:
    encoded = json.dumps(steps, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def claude_prompt(workflow_id: str, params: dict[str, Any]) -> str:
    if workflow_id == "ai-changelog":
        return (
            "/examzh-release prepare 审阅当前工作树：整理结构化变更片段，"
            "把新增测试文件按项目约定归档为可维护的回归测试或必要的最小复现，"
            "排除测试生成物，并按用户可见改动的实际需要优化完整手册和入门手册；"
            "运行相关聚焦检查、make changelog 和 make check-changelog 后停止；"
            "不要执行完整发布构建，也不要提交、打 Tag、推送或发布。"
        )
    if workflow_id == "ai-git-update":
        message = str(params.get("message", "")).strip()
        suffix = f" 建议提交信息：{message}" if message else " 先审阅改动并拟定提交信息。"
        return f"/git-update --dry-run{suffix} 只做预演，等待我在终端确认后再执行真实提交。"

    version = require_version(params)
    mode_by_id = {
        "ai-github-release": "github",
        "ai-gitee-release": "gitee",
        "ai-full-release": "full",
    }
    mode = mode_by_id.get(workflow_id)
    if not mode:
        raise DashboardError("未知 Claude 工作流")
    return f"/examzh-release {mode} {version} 从项目 skill 的预检开始，并在任何远程写操作前等待我确认。"


def applescript_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def launch_claude(workflow_id: str, params: dict[str, Any]) -> str:
    claude = shutil.which("claude")
    osascript = shutil.which("osascript")
    if not claude:
        raise DashboardError("未找到 Claude Code CLI")
    if not osascript:
        raise DashboardError("当前系统不支持通过 Terminal 启动 Claude Code")
    prompt = claude_prompt(workflow_id, params)
    shell_command = f"cd {shlex.quote(str(ROOT))} && exec {shlex.quote(claude)} {shlex.quote(prompt)}"
    script = f'tell application "Terminal" to do script {applescript_string(shell_command)}'
    result = subprocess.run(
        [osascript, "-e", script, "-e", 'tell application "Terminal" to activate'],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )
    if result.returncode != 0:
        raise DashboardError(result.stderr.strip() or "无法启动 Terminal")
    return prompt


@dataclass
class Job:
    id: str
    workflow_id: str
    title: str
    status: str = "queued"
    created_at: str = field(default_factory=utc_now)
    started_at: str | None = None
    finished_at: str | None = None
    return_code: int | None = None
    step: str = ""
    step_number: int = 0
    step_count: int = 0
    completed_steps: int = 0
    resumed_from_step: int | None = None
    params: dict[str, Any] = field(default_factory=dict)
    plan_signature: str = ""
    process: subprocess.Popen[str] | None = None
    logs: list[str] = field(default_factory=list)
    log_offset: int = 0
    cancel_requested: bool = False

    def append(self, line: str) -> None:
        self.logs.append(line.rstrip("\n"))
        if len(self.logs) > MAX_LOG_LINES:
            removed = len(self.logs) - MAX_LOG_LINES
            del self.logs[:removed]
            self.log_offset += removed

    def snapshot(self, cursor: int = 0) -> dict[str, Any]:
        start = max(cursor, self.log_offset)
        relative = max(0, start - self.log_offset)
        return {
            "id": self.id,
            "workflowId": self.workflow_id,
            "title": self.title,
            "status": self.status,
            "createdAt": self.created_at,
            "startedAt": self.started_at,
            "finishedAt": self.finished_at,
            "returnCode": self.return_code,
            "step": self.step,
            "stepNumber": self.step_number,
            "stepCount": self.step_count,
            "completedSteps": self.completed_steps,
            "resumedFromStep": self.resumed_from_step,
            "params": self.params,
            "logs": self.logs[relative:],
            "cursor": self.log_offset + len(self.logs),
        }

    def record(self) -> dict[str, Any]:
        value = self.snapshot()
        value["planSignature"] = self.plan_signature
        return value

    @classmethod
    def restore(cls, value: Any) -> Job:
        if not isinstance(value, dict):
            raise ValueError("job record must be an object")
        required_strings = ("id", "workflowId", "title", "status", "createdAt")
        if any(not isinstance(value.get(name), str) for name in required_strings):
            raise ValueError("job record contains invalid strings")
        if value["status"] not in {"queued", "running", "success", "failed", "cancelled", "interrupted"}:
            raise ValueError("job record contains an invalid status")
        logs = value.get("logs", [])
        params = value.get("params", {})
        if not isinstance(logs, list) or not all(isinstance(line, str) for line in logs):
            raise ValueError("job record contains invalid logs")
        if not isinstance(params, dict):
            raise ValueError("job record contains invalid params")
        step_count = max(0, int(value.get("stepCount", 0)))
        completed_steps = min(step_count, max(0, int(value.get("completedSteps", 0))))
        resumed_from = value.get("resumedFromStep")
        return cls(
            id=value["id"],
            workflow_id=value["workflowId"],
            title=value["title"],
            status=value["status"],
            created_at=value["createdAt"],
            started_at=value.get("startedAt") if isinstance(value.get("startedAt"), str) else None,
            finished_at=value.get("finishedAt") if isinstance(value.get("finishedAt"), str) else None,
            return_code=value.get("returnCode") if isinstance(value.get("returnCode"), int) else None,
            step=value.get("step") if isinstance(value.get("step"), str) else "",
            step_number=max(0, int(value.get("stepNumber", 0))),
            step_count=step_count,
            completed_steps=completed_steps,
            resumed_from_step=int(resumed_from) if isinstance(resumed_from, int) else None,
            params=dict(params),
            plan_signature=value.get("planSignature") if isinstance(value.get("planSignature"), str) else "",
            logs=logs[-MAX_LOG_LINES:],
            log_offset=max(0, int(value.get("cursor", len(logs))) - min(len(logs), MAX_LOG_LINES)),
        )


class JobManager:
    def __init__(self, state_path: Path | None = STATE_PATH) -> None:
        self.jobs: dict[str, Job] = {}
        self.active_id: str | None = None
        self.lock = threading.RLock()
        self.state_path = state_path
        self.persistence_error: str | None = None
        self._load()

    def _load(self) -> None:
        if self.state_path is None or not self.state_path.is_file():
            return
        try:
            data = json.loads(self.state_path.read_text(encoding="utf-8"))
            if not isinstance(data, dict) or data.get("schemaVersion") != STATE_SCHEMA_VERSION:
                raise ValueError("unsupported state schema")
            records = data.get("jobs")
            if not isinstance(records, list):
                raise ValueError("jobs must be an array")
            restored = [Job.restore(value) for value in records[-12:]]
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            self.persistence_error = f"无法读取已保存的任务状态：{exc}"
            return

        interrupted = False
        for job in restored:
            if job.status in {"queued", "running"}:
                job.status = "interrupted"
                job.return_code = None
                job.finished_at = utc_now()
                job.append("Dashboard 服务曾中断；可从最近完成的步骤继续。")
                interrupted = True
            self.jobs[job.id] = job
        if interrupted:
            self._persist_locked()

    def _persist_locked(self) -> None:
        if self.state_path is None:
            return
        try:
            ordered = sorted(self.jobs.values(), key=lambda item: item.created_at)[-12:]
            payload = {
                "schemaVersion": STATE_SCHEMA_VERSION,
                "updatedAt": utc_now(),
                "jobs": [job.record() for job in ordered],
            }
            self.state_path.parent.mkdir(parents=True, exist_ok=True)
            temporary = self.state_path.with_suffix(".tmp")
            temporary.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            temporary.replace(self.state_path)
            self.persistence_error = None
        except OSError as exc:
            self.persistence_error = f"无法保存任务状态：{exc}"

    def _persist(self) -> None:
        with self.lock:
            self._persist_locked()

    def _resume_checkpoint(
        self,
        params: dict[str, Any],
        plan_signature: str,
    ) -> Job | None:
        ordered = sorted(self.jobs.values(), key=lambda item: item.created_at, reverse=True)
        for job in ordered:
            if (
                job.workflow_id != "release-pipeline"
                or job.params != params
                or job.plan_signature != plan_signature
            ):
                continue
            if job.status == "success" and job.step_count > 0 and job.completed_steps == job.step_count:
                return None
            if job.status in {"failed", "cancelled", "interrupted"} and 0 < job.completed_steps < job.step_count:
                return job
        return None

    def start(self, workflow_id: str, params: dict[str, Any], *, resume: bool = False) -> Job:
        spec = WORKFLOW_BY_ID.get(workflow_id)
        if not spec:
            raise DashboardError("未知工作流")
        steps: list[tuple[str, list[str]]] | None = None
        job_params: dict[str, Any] = {}
        plan_signature = ""
        completed_steps = 0
        if spec["executor"] != "claude":
            steps = build_steps(workflow_id, params)
            if workflow_id == "release-pipeline":
                job_params = normalized_pipeline_params(params)
                version = job_params["version"]
                target = job_params["publishTarget"]
                plan_signature = step_plan_signature(steps)
                with self.lock:
                    checkpoint = self._resume_checkpoint(job_params, plan_signature) if resume else None
                if resume and checkpoint is None:
                    raise DashboardError("找不到与当前版本、日期和发布出口匹配的可恢复进度")
                completed_steps = checkpoint.completed_steps if checkpoint else 0
                if capture(["git", "branch", "--show-current"]) != "main":
                    raise DashboardError("发布链只能从 main 分支执行")
                if not capture(["git", "remote", "get-url", "github"]):
                    raise DashboardError("未配置 github 远程仓库")
                local_tag = capture(["git", "tag", "--list", f"v{version}"])
                if target == "ctan" and not local_tag:
                    raise DashboardError(f"找不到已测试的 Tag v{version}，请先完成 GitHub + Gitee 发布链")
                tag_step = next(
                    (index for index, (label, _) in enumerate(steps, 1) if label.endswith("创建 Git Tag")),
                    len(steps) + 1,
                )
                if target != "ctan" and local_tag and completed_steps < tag_step:
                    raise DashboardError(f"Tag v{version} 已存在，发布链已停止")
                if target != "ctan" and completed_steps >= tag_step and not local_tag:
                    raise DashboardError(f"已保存进度要求 Tag v{version} 存在，但本地没有找到该 Tag")
                if target in {"platforms", "all"} and not capture(["git", "remote", "get-url", "gitee"]):
                    raise DashboardError("未配置 gitee 远程仓库")
                if target in {"platforms", "all"} and not os.environ.get("GITEE_TOKEN"):
                    raise DashboardError("发布 GitHub + Gitee 需要 GITEE_TOKEN")
                prepare_step = next(
                    (index for index, (label, _) in enumerate(steps, 1) if label.endswith("固化发布说明")),
                    len(steps) + 1,
                )
                if target != "ctan" and completed_steps < prepare_step and not any(
                    (ROOT / ".changes" / "unreleased").glob("*.json")
                ):
                    raise DashboardError(
                        "没有未发布的 JSON 变更片段；请先生成 Changelog，再执行发布链"
                    )
                tools = ("gh",) if target == "ctan" else ("l3build", "gh")
                for tool in tools:
                    if not shutil.which(tool):
                        raise DashboardError(f"未找到发布链依赖：{tool}")
        with self.lock:
            if self.active_id:
                active = self.jobs.get(self.active_id)
                if active and active.status in {"queued", "running"}:
                    raise DashboardError(f"已有任务正在运行：{active.title}")
            job = Job(
                id=uuid.uuid4().hex,
                workflow_id=workflow_id,
                title=spec["title"],
                step_count=len(steps or []),
                completed_steps=completed_steps,
                resumed_from_step=completed_steps + 1 if completed_steps else None,
                params=job_params,
                plan_signature=plan_signature,
            )
            if completed_steps:
                job.step_number = completed_steps + 1
                job.step = steps[completed_steps][0] if steps else ""
                job.append(f"从已保存进度继续：跳过前 {completed_steps} 个已完成步骤。")
            self.jobs[job.id] = job
            self.active_id = job.id
            self._persist_locked()
            if workflow_id == "release-pipeline" and self.persistence_error:
                del self.jobs[job.id]
                self.active_id = None
                raise DashboardError(self.persistence_error)

        if spec["executor"] == "claude":
            thread = threading.Thread(
                target=self._run_claude,
                args=(job, params),
                daemon=True,
            )
        else:
            assert steps is not None
            thread = threading.Thread(
                target=self._run_processes,
                args=(job, steps, completed_steps),
                daemon=True,
            )
        thread.start()
        return job

    def _finish(self, job: Job, status: str, return_code: int | None) -> None:
        with self.lock:
            job.status = status
            job.return_code = return_code
            job.finished_at = utc_now()
            job.process = None
            if self.active_id == job.id:
                self.active_id = None
            self._persist_locked()

    def _run_claude(self, job: Job, params: dict[str, Any]) -> None:
        with self.lock:
            job.status = "running"
            job.started_at = utc_now()
            job.step = "启动 Claude Code"
            self._persist_locked()
        try:
            prompt = launch_claude(job.workflow_id, params)
            job.append("Claude Code 已在新的 Terminal 会话中启动。")
            job.append(f"Skill prompt: {prompt}")
            self._finish(job, "success", 0)
        except (DashboardError, OSError, subprocess.SubprocessError) as exc:
            job.append(f"ERROR: {exc}")
            self._finish(job, "failed", 1)

    def _run_processes(
        self,
        job: Job,
        steps: list[tuple[str, list[str]]],
        completed_steps: int = 0,
    ) -> None:
        with self.lock:
            job.status = "running"
            job.started_at = utc_now()
            self._persist_locked()
        env = os.environ.copy()
        env["PYTHONUNBUFFERED"] = "1"
        try:
            for index in range(completed_steps, len(steps)):
                number = index + 1
                label, command = steps[index]
                if job.cancel_requested:
                    self._finish(job, "cancelled", None)
                    return
                job.step = label
                job.step_number = number
                job.append(f"\n[{label}]")
                job.append(f"$ {shlex.join(command)}")
                self._persist()
                process = subprocess.Popen(
                    command,
                    cwd=ROOT,
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    start_new_session=True,
                )
                job.process = process
                assert process.stdout is not None
                with process.stdout:
                    for line in process.stdout:
                        job.append(line)
                return_code = process.wait()
                job.process = None
                if job.cancel_requested:
                    self._finish(job, "cancelled", return_code)
                    return
                if return_code != 0:
                    job.append(f"命令失败，退出码 {return_code}。")
                    self._finish(job, "failed", return_code)
                    return
                job.completed_steps = number
                self._persist()
            self._finish(job, "success", 0)
        except (OSError, subprocess.SubprocessError) as exc:
            job.append(f"ERROR: {exc}")
            self._finish(job, "failed", 1)

    def cancel(self, job_id: str) -> Job:
        with self.lock:
            job = self.jobs.get(job_id)
            if not job:
                raise DashboardError("任务不存在")
            if job.status not in {"queued", "running"}:
                return job
            job.cancel_requested = True
            process = job.process
            self._persist_locked()
        if process and process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        return job

    def get(self, job_id: str) -> Job:
        with self.lock:
            job = self.jobs.get(job_id)
            if not job:
                raise DashboardError("任务不存在")
            return job

    def recent(self) -> list[dict[str, Any]]:
        with self.lock:
            ordered = sorted(self.jobs.values(), key=lambda item: item.created_at, reverse=True)
            snapshots: list[dict[str, Any]] = []
            for item in ordered[:12]:
                snapshot = item.snapshot()
                resumable = False
                if item.workflow_id == "release-pipeline" and item.params:
                    try:
                        current_plan = step_plan_signature(build_steps(item.workflow_id, item.params))
                        resumable = self._resume_checkpoint(item.params, current_plan) is item
                    except DashboardError:
                        pass
                snapshot["resumeAvailable"] = resumable
                snapshots.append(snapshot)
            return snapshots


def capture(command: list[str], timeout: float = 4.0) -> str:
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return (result.stdout or result.stderr).strip()


def artifact(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {"path": str(path.relative_to(ROOT)), "exists": False, "size": 0, "updatedAt": None}
    stat = path.stat()
    return {
        "path": str(path.relative_to(ROOT)),
        "exists": True,
        "size": stat.st_size,
        "updatedAt": datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds"),
    }


def repository_status(manager: JobManager) -> dict[str, Any]:
    build_lua = (ROOT / "build.lua").read_text(encoding="utf-8")
    version_match = re.search(r'^version\s*=\s*"v([^"]+)"', build_lua, re.MULTILINE)
    date_match = re.search(r'^date\s*=\s*"([^"]+)"', build_lua, re.MULTILINE)
    current_version = version_match.group(1) if version_match else ""
    today = date.today().isoformat()
    with manager.lock:
        release_context = suggested_release_context(current_version, today, list(manager.jobs.values()))
    porcelain = capture(["git", "status", "--porcelain=v1"])
    dirty_files = [line for line in porcelain.splitlines() if line]
    fragments = sorted((ROOT / ".changes" / "unreleased").glob("*.json"))
    try:
        changelog_check = subprocess.run(
            ["python3", "scripts/release_notes.py", "check"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=8,
            check=False,
        )
        changelog_ok = changelog_check.returncode == 0
        changelog_message = (changelog_check.stdout or changelog_check.stderr).strip()
    except (OSError, subprocess.SubprocessError) as exc:
        changelog_ok = False
        changelog_message = f"无法运行变更记录检查：{exc}"
    return {
        "branch": capture(["git", "branch", "--show-current"]),
        "head": capture(["git", "rev-parse", "--short", "HEAD"]),
        "latestTag": capture(["git", "describe", "--tags", "--abbrev=0"]),
        "version": current_version,
        "releaseDate": date_match.group(1) if date_match else "",
        "today": today,
        "releaseContext": release_context,
        "dirtyCount": len(dirty_files),
        "dirtyFiles": dirty_files[:16],
        "fragmentCount": len(fragments),
        "changelogOk": changelog_ok,
        "changelogMessage": changelog_message,
        "tools": {
            "python": bool(shutil.which("python3")),
            "l3build": bool(shutil.which("l3build")),
            "git": bool(shutil.which("git")),
            "gh": bool(shutil.which("gh")),
            "claude": bool(shutil.which("claude")),
            "giteeToken": bool(os.environ.get("GITEE_TOKEN")),
        },
        "skills": {
            "release": (ROOT / ".claude" / "skills" / "examzh-release" / "SKILL.md").is_file(),
            "gitUpdate": (ROOT / ".claude" / "skills" / "git-update" / "SKILL.md").is_file(),
        },
        "artifacts": [
            artifact(ROOT / "exam-zh.zip"),
            artifact(ROOT / "CTAN" / "exam-zh.zip"),
            artifact(ROOT / "release" / f"exam-zh-v{current_version}.zip"),
            artifact(ROOT / "doc" / "exam-zh-doc.pdf"),
            artifact(ROOT / "doc-basic" / "exam-zh-doc-basic.pdf"),
        ],
        "jobs": manager.recent(),
        "activeJobId": manager.active_id,
        "statePath": str(manager.state_path) if manager.state_path else None,
        "stateError": manager.persistence_error,
        "refreshedAt": datetime.now().isoformat(timespec="seconds"),
    }


class DashboardServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True

    def __init__(
        self,
        address: tuple[str, int],
        token: str,
        state_path: Path | None = STATE_PATH,
    ) -> None:
        super().__init__(address, DashboardHandler)
        self.token = token
        self.jobs = JobManager(state_path)


class DashboardHandler(BaseHTTPRequestHandler):
    server: DashboardServer

    def log_message(self, format_string: str, *args: Any) -> None:
        sys.stdout.write(f"[{self.log_date_time_string()}] {format_string % args}\n")

    def send_bytes(
        self,
        content: bytes,
        content_type: str,
        status: HTTPStatus = HTTPStatus.OK,
        *,
        cache: bool = False,
    ) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(content)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Cache-Control", "public, max-age=3600" if cache else "no-store")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'self'; script-src 'self' https://unpkg.com; "
            "style-src 'self'; img-src 'self' data:; connect-src 'self'; "
            "object-src 'none'; frame-ancestors 'none'; base-uri 'none'",
        )
        self.end_headers()
        self.wfile.write(content)

    def send_json(self, value: Any, status: HTTPStatus = HTTPStatus.OK) -> None:
        content = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_bytes(content, "application/json; charset=utf-8", status)

    def send_error_json(self, message: str, status: HTTPStatus) -> None:
        self.send_json({"error": message}, status)

    def require_token(self) -> bool:
        supplied = self.headers.get("X-Workflow-Token", "")
        if not secrets.compare_digest(supplied, self.server.token):
            self.send_error_json("无效的工作流会话令牌", HTTPStatus.FORBIDDEN)
            return False
        return True

    def read_json(self) -> dict[str, Any]:
        content_type = self.headers.get("Content-Type", "")
        if not content_type.startswith("application/json"):
            raise DashboardError("请求必须使用 application/json")
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError as exc:
            raise DashboardError("无效的请求长度") from exc
        if length <= 0 or length > MAX_REQUEST_BYTES:
            raise DashboardError("请求体大小无效")
        try:
            value = json.loads(self.rfile.read(length).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise DashboardError("请求 JSON 无效") from exc
        if not isinstance(value, dict):
            raise DashboardError("请求 JSON 必须是对象")
        return value

    def do_OPTIONS(self) -> None:
        self.send_error_json("跨源请求不受支持", HTTPStatus.FORBIDDEN)

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/bootstrap":
            self.send_json(
                {
                    "apiVersion": DASHBOARD_API_VERSION,
                    "workflows": WORKFLOWS,
                    "status": repository_status(self.server.jobs),
                    "token": self.server.token,
                }
            )
            return
        if parsed.path == "/api/status":
            self.send_json(repository_status(self.server.jobs))
            return
        if parsed.path.startswith("/api/jobs/"):
            job_id = parsed.path.removeprefix("/api/jobs/").strip("/")
            try:
                cursor_text = parse_qs(parsed.query).get("cursor", ["0"])[0]
                cursor = max(0, int(cursor_text))
                self.send_json(self.server.jobs.get(job_id).snapshot(cursor))
            except (DashboardError, ValueError) as exc:
                self.send_error_json(str(exc), HTTPStatus.NOT_FOUND)
            return
        self.serve_static(parsed.path)

    def do_POST(self) -> None:
        if not self.require_token():
            return
        parsed = urlparse(self.path)
        try:
            if parsed.path == "/api/run":
                data = self.read_json()
                workflow_id = str(data.get("workflowId", ""))
                params = data.get("params", {})
                if not isinstance(params, dict):
                    raise DashboardError("params 必须是对象")
                resume = data.get("resume", False)
                if not isinstance(resume, bool):
                    raise DashboardError("resume 必须是布尔值")
                job = self.server.jobs.start(workflow_id, params, resume=resume)
                self.send_json(job.snapshot(), HTTPStatus.ACCEPTED)
                return
            match = re.fullmatch(r"/api/jobs/([a-f0-9]+)/cancel", parsed.path)
            if match:
                self.read_json()
                job = self.server.jobs.cancel(match.group(1))
                self.send_json(job.snapshot(), HTTPStatus.ACCEPTED)
                return
            self.send_error_json("接口不存在", HTTPStatus.NOT_FOUND)
        except DashboardError as exc:
            self.send_error_json(str(exc), HTTPStatus.CONFLICT)

    def serve_static(self, path: str) -> None:
        if path in {"", "/"}:
            target = DASHBOARD_DIR / "index.html"
        else:
            target = DASHBOARD_DIR / path.lstrip("/")
        try:
            resolved = target.resolve(strict=True)
        except OSError:
            self.send_error_json("文件不存在", HTTPStatus.NOT_FOUND)
            return
        allowed_roots = (DASHBOARD_DIR.resolve(),)
        if not any(resolved.is_relative_to(base) for base in allowed_roots):
            self.send_error_json("禁止访问该路径", HTTPStatus.FORBIDDEN)
            return
        content_type = mimetypes.guess_type(resolved.name)[0] or "application/octet-stream"
        if content_type.startswith("text/") or content_type in {"application/javascript", "application/json"}:
            content_type += "; charset=utf-8"
        self.send_bytes(resolved.read_bytes(), content_type, cache=resolved.suffix == ".png")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--open", action="store_true", dest="open_browser")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not DASHBOARD_DIR.is_dir():
        print(f"dashboard files not found: {DASHBOARD_DIR}", file=sys.stderr)
        return 1
    token = secrets.token_urlsafe(24)
    try:
        server = DashboardServer(("127.0.0.1", args.port), token)
    except OSError as exc:
        print(f"cannot start dashboard: {exc}", file=sys.stderr)
        return 1
    port = server.server_address[1]
    url = f"http://127.0.0.1:{port}/"
    print(f"exam-zh release dashboard: {url}", flush=True)
    print("Press Ctrl-C to stop.", flush=True)
    if args.open_browser:
        webbrowser.open(url)
    try:
        server.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt:
        print("\nStopping dashboard.")
    finally:
        server.shutdown()
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
