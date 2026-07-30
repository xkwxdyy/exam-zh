#!/usr/bin/env python3
"""Regression tests for the local release workflow dashboard."""

from __future__ import annotations

import json
import os
import sys
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from pathlib import Path
from unittest import mock

import workflow_dashboard as dashboard


VALID_PARAMS = {
    "version": "1.2.3",
    "date": "2026-08-01",
    "message": "chore: prepare release",
}


class ValidationTests(unittest.TestCase):
    def test_version_requires_three_numeric_components(self) -> None:
        self.assertEqual(dashboard.require_version({"version": "v1.2.3"}), "1.2.3")
        for value in ("", "1.2", "1.2.3-beta", "release-1.2.3", "1; touch x"):
            with self.subTest(value=value), self.assertRaises(dashboard.DashboardError):
                dashboard.require_version({"version": value})

    def test_date_and_message_are_bounded(self) -> None:
        self.assertEqual(dashboard.require_date({"date": "2026-08-01"}), "2026-08-01")
        for value in ("", "2026-02-30", "08/01/2026"):
            with self.subTest(value=value), self.assertRaises(dashboard.DashboardError):
                dashboard.require_date({"date": value})
        for value in ("", "line one\nline two", "x" * 201):
            with self.subTest(value=value), self.assertRaises(dashboard.DashboardError):
                dashboard.require_message({"message": value})

    def test_every_process_workflow_builds_argv_without_a_shell(self) -> None:
        for spec in dashboard.WORKFLOWS:
            if spec["executor"] != "process":
                continue
            with self.subTest(workflow=spec["id"]):
                steps = dashboard.build_steps(spec["id"], VALID_PARAMS)
                self.assertTrue(steps)
                for label, command in steps:
                    self.assertIsInstance(label, str)
                    self.assertIsInstance(command, list)
                    self.assertTrue(command)
                    self.assertTrue(all(isinstance(arg, str) for arg in command))
                    self.assertNotIn(command[0], {"sh", "zsh", "/bin/sh", "/bin/zsh"})

    def test_release_pipeline_starts_after_manual_ai_changelog(self) -> None:
        github_steps = dashboard.build_steps("release-pipeline", VALID_PARAMS)
        labels = [label for label, _ in github_steps]
        commands = [command for _, command in github_steps]
        self.assertEqual(labels[0], "01 · 校验 Changelog")
        self.assertTrue(any(label.endswith("Git 提交") for label in labels))
        self.assertTrue(any(label.endswith("创建 Git Tag") for label in labels))
        self.assertTrue(any(label.endswith("发布 GitHub Release") for label in labels))
        self.assertTrue(any(label.endswith("发布 Gitee Release") for label in labels))
        self.assertNotIn("触发 CTAN 发布", labels)
        self.assertFalse(any(command[0] == "claude" for command in commands))
        self.assertTrue(any(command[:3] == ["git", "push", "github"] for command in commands))
        self.assertTrue(any(command[:3] == ["gh", "release", "create"] for command in commands))

        all_steps = dashboard.build_steps("release-pipeline", {**VALID_PARAMS, "publishTarget": "all"})
        self.assertTrue(any(label.endswith("触发 CTAN 发布") for label, _ in all_steps))

        ctan_steps = dashboard.build_steps(
            "release-pipeline", {**VALID_PARAMS, "publishTarget": "ctan"}
        )
        self.assertEqual(ctan_steps[-1][0], "02 · 触发 CTAN 发布")

    def test_release_pipeline_rejects_unknown_publish_target(self) -> None:
        with self.assertRaises(dashboard.DashboardError):
            dashboard.build_steps("release-pipeline", {**VALID_PARAMS, "publishTarget": "gitee"})

    def test_pipeline_resume_identity_includes_version_and_options(self) -> None:
        params = dashboard.normalized_pipeline_params(VALID_PARAMS)
        self.assertEqual(params["version"], "1.2.3")
        self.assertEqual(params["message"], "chore: prepare release")
        self.assertFalse(params["skipCompile"])
        changed = dashboard.normalized_pipeline_params({**VALID_PARAMS, "version": "1.2.4"})
        self.assertNotEqual(params, changed)

    def test_unknown_workflow_is_rejected(self) -> None:
        with self.assertRaises(dashboard.DashboardError):
            dashboard.build_steps("arbitrary-shell", VALID_PARAMS)

    def test_claude_prompts_preserve_mode_boundaries(self) -> None:
        changelog = dashboard.claude_prompt("ai-changelog", {})
        github = dashboard.claude_prompt("ai-github-release", VALID_PARAMS)
        full = dashboard.claude_prompt("ai-full-release", VALID_PARAMS)
        self.assertIn("/examzh-release changelog", changelog)
        self.assertIn("不要提交", changelog)
        self.assertIn("/examzh-release github 1.2.3", github)
        self.assertIn("远程写操作前等待我确认", github)
        self.assertIn("/examzh-release full 1.2.3", full)

    def test_applescript_string_escapes_quotes_and_backslashes(self) -> None:
        self.assertEqual(dashboard.applescript_string('a"b\\c'), '"a\\"b\\\\c"')

    @mock.patch("workflow_dashboard.subprocess.run")
    @mock.patch("workflow_dashboard.shutil.which")
    def test_claude_launch_uses_terminal_without_running_a_shell_api(
        self,
        which: mock.Mock,
        run: mock.Mock,
    ) -> None:
        which.side_effect = lambda name: f"/usr/local/bin/{name}"
        run.return_value = dashboard.subprocess.CompletedProcess([], 0, "tab 1", "")
        prompt = dashboard.launch_claude("ai-github-release", VALID_PARAMS)
        argv = run.call_args.args[0]
        self.assertEqual(argv[:2], ["/usr/local/bin/osascript", "-e"])
        self.assertIn("tell application \"Terminal\"", argv[2])
        self.assertIn("/usr/local/bin/claude", argv[2])
        self.assertIn("examzh-release github 1.2.3", prompt)
        self.assertNotIn("shell", run.call_args.kwargs)


class PersistenceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.state_path = Path(self.temporary.name) / "state.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_failed_pipeline_checkpoint_survives_restart_and_is_version_bound(self) -> None:
        params = dashboard.normalized_pipeline_params(VALID_PARAMS)
        steps = dashboard.build_steps("release-pipeline", params)
        manager = dashboard.JobManager(self.state_path)
        job = dashboard.Job(
            id="saved-job",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="failed",
            step="04 · 固化发布说明",
            step_number=4,
            step_count=len(steps),
            completed_steps=3,
            params=params,
            plan_signature=dashboard.step_plan_signature(steps),
            logs=["前三步已通过"],
        )
        manager.jobs[job.id] = job
        manager._persist()

        restored = dashboard.JobManager(self.state_path)
        snapshot = restored.recent()[0]
        self.assertEqual(snapshot["completedSteps"], 3)
        self.assertTrue(snapshot["resumeAvailable"])
        self.assertEqual(snapshot["params"]["version"], "1.2.3")
        other = dashboard.normalized_pipeline_params({**VALID_PARAMS, "version": "1.2.4"})
        self.assertIsNone(restored._resume_checkpoint(other, dashboard.step_plan_signature(steps)))

    def test_running_job_is_restored_as_interrupted(self) -> None:
        manager = dashboard.JobManager(self.state_path)
        job = dashboard.Job(
            id="running-job",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="running",
            step_count=4,
            completed_steps=2,
        )
        manager.jobs[job.id] = job
        manager._persist()

        restored = dashboard.JobManager(self.state_path).get(job.id)
        self.assertEqual(restored.status, "interrupted")
        self.assertEqual(restored.completed_steps, 2)

    def test_process_resume_skips_completed_commands(self) -> None:
        manager = dashboard.JobManager(None)
        job = dashboard.Job(
            id="resume-job",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            step_count=2,
            completed_steps=1,
        )
        steps = [
            ("01 · 不应重跑", [sys.executable, "-c", "print('FIRST-RAN')"]),
            ("02 · 继续执行", [sys.executable, "-c", "print('SECOND-RAN')"]),
        ]
        manager.jobs[job.id] = job
        manager.active_id = job.id
        manager._run_processes(job, steps, 1)
        self.assertEqual(job.status, "success")
        self.assertEqual(job.completed_steps, 2)
        self.assertFalse(any("FIRST-RAN" in line for line in job.logs))
        self.assertTrue(any("SECOND-RAN" in line for line in job.logs))

    @mock.patch("workflow_dashboard.shutil.which", return_value="/usr/local/bin/tool")
    @mock.patch("workflow_dashboard.capture")
    def test_pipeline_rejects_missing_fragments_before_expensive_tests(
        self,
        capture: mock.Mock,
        _which: mock.Mock,
    ) -> None:
        root = Path(self.temporary.name) / "repo"
        (root / ".changes" / "unreleased").mkdir(parents=True)
        capture.side_effect = lambda command: (
            "main" if command[:3] == ["git", "branch", "--show-current"]
            else "https://example.invalid/repo" if command[:3] == ["git", "remote", "get-url"]
            else ""
        )
        with mock.patch.object(dashboard, "ROOT", root), mock.patch.dict(os.environ, {"GITEE_TOKEN": "test"}):
            with self.assertRaisesRegex(dashboard.DashboardError, "没有未发布的 JSON 变更片段"):
                dashboard.JobManager(None).start("release-pipeline", VALID_PARAMS)

    @mock.patch("workflow_dashboard.shutil.which", return_value="/usr/local/bin/tool")
    @mock.patch("workflow_dashboard.capture")
    def test_pipeline_does_not_start_when_checkpoint_cannot_be_saved(
        self,
        capture: mock.Mock,
        _which: mock.Mock,
    ) -> None:
        root = Path(self.temporary.name) / "writable-repo"
        fragments = root / ".changes" / "unreleased"
        fragments.mkdir(parents=True)
        (fragments / "change.json").write_text("{}", encoding="utf-8")
        capture.side_effect = lambda command: (
            "main" if command[:3] == ["git", "branch", "--show-current"]
            else "https://example.invalid/repo" if command[:3] == ["git", "remote", "get-url"]
            else ""
        )
        manager = dashboard.JobManager(None)

        def fail_persistence() -> None:
            manager.persistence_error = "无法保存任务状态：只读文件系统"

        with (
            mock.patch.object(dashboard, "ROOT", root),
            mock.patch.dict(os.environ, {"GITEE_TOKEN": "test"}),
            mock.patch.object(manager, "_persist_locked", side_effect=fail_persistence),
        ):
            with self.assertRaisesRegex(dashboard.DashboardError, "无法保存任务状态"):
                manager.start("release-pipeline", VALID_PARAMS)
        self.assertFalse(manager.jobs)
        self.assertIsNone(manager.active_id)


class HttpTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.token = "dashboard-test-token"
        cls.temporary = tempfile.TemporaryDirectory()
        cls.server = dashboard.DashboardServer(
            ("127.0.0.1", 0),
            cls.token,
            Path(cls.temporary.name) / "state.json",
        )
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.server.server_address[1]}"

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)
        cls.temporary.cleanup()

    def request(
        self,
        path: str,
        *,
        method: str = "GET",
        body: dict[str, object] | None = None,
        token: str | None = None,
    ) -> tuple[int, dict[str, object]]:
        payload = json.dumps(body).encode("utf-8") if body is not None else None
        headers = {"Content-Type": "application/json"} if payload is not None else {}
        if token is not None:
            headers["X-Workflow-Token"] = token
        request = urllib.request.Request(
            self.base_url + path,
            data=payload,
            headers=headers,
            method=method,
        )
        try:
            response = urllib.request.urlopen(request, timeout=10)
        except urllib.error.HTTPError as exc:
            return exc.code, json.loads(exc.read().decode("utf-8"))
        with response:
            return response.status, json.loads(response.read().decode("utf-8"))

    def test_bootstrap_exposes_allowlist_and_token(self) -> None:
        status, payload = self.request("/api/bootstrap")
        self.assertEqual(status, 200)
        self.assertEqual(payload["apiVersion"], dashboard.DASHBOARD_API_VERSION)
        self.assertEqual(payload["token"], self.token)
        ids = {item["id"] for item in payload["workflows"]}
        self.assertIn("changelog-check", ids)
        self.assertNotIn("shell", ids)

    def test_post_requires_session_token(self) -> None:
        status, payload = self.request(
            "/api/run",
            method="POST",
            token="wrong-token",
            body={"workflowId": "changelog-check", "params": {}},
        )
        self.assertEqual(status, 403)
        self.assertIn("令牌", payload["error"])

    def test_artifact_preview_asset_is_not_served(self) -> None:
        status, _ = self.request("/assets/gitee-release.png")
        self.assertEqual(status, 404)

    def test_harmless_job_can_run_and_stream_logs(self) -> None:
        status, payload = self.request(
            "/api/run",
            method="POST",
            token=self.token,
            body={"workflowId": "changelog-check", "params": {}},
        )
        self.assertEqual(status, 202)
        job_id = payload["id"]
        cursor = 0
        logs: list[str] = []
        deadline = time.monotonic() + 12
        while time.monotonic() < deadline:
            status, job = self.request(f"/api/jobs/{job_id}?cursor={cursor}")
            self.assertEqual(status, 200)
            logs.extend(job["logs"])
            cursor = job["cursor"]
            if job["status"] not in {"queued", "running"}:
                break
            time.sleep(0.05)
        self.assertEqual(job["status"], "success")
        self.assertTrue(any("make check-changelog" in line or "release_notes.py" in line for line in logs))


if __name__ == "__main__":
    unittest.main(verbosity=2)
