#!/usr/bin/env python3
"""Regression tests for the local release workflow dashboard."""

from __future__ import annotations

import json
import threading
import time
import unittest
import urllib.error
import urllib.request
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


class HttpTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.token = "dashboard-test-token"
        cls.server = dashboard.DashboardServer(("127.0.0.1", 0), cls.token)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.server.server_address[1]}"

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)

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
