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
        self.assertTrue(any(label.endswith("生成 Git 提交信息") for label in labels))
        self.assertTrue(any(label.endswith("创建 Git Tag") for label in labels))
        self.assertTrue(any(label.endswith("发布 GitHub Release") for label in labels))
        self.assertTrue(any(label.endswith("发布 Gitee Release") for label in labels))
        self.assertNotIn("触发 CTAN 发布", labels)
        self.assertFalse(any(command[0] == "claude" for command in commands))
        self.assertTrue(any(command[:3] == ["git", "push", "github"] for command in commands))
        self.assertTrue(any(command[:3] == ["gh", "release", "create"] for command in commands))
        commit_message_command = next(
            command for label, command in github_steps if label.endswith("生成 Git 提交信息")
        )
        self.assertIn("--commit-message-output", commit_message_command)
        self.assertEqual(commit_message_command[-2:], ["--commit-title", VALID_PARAMS["message"]])
        commit_command = next(
            command for label, command in github_steps if label.endswith("Git 提交")
        )
        self.assertEqual(commit_command[-2:], ["--message-file", "build/release-commit-v1.2.3.txt"])

        all_steps = dashboard.build_steps("release-pipeline", {**VALID_PARAMS, "publishTarget": "all"})
        self.assertTrue(any(label.endswith("触发 CTAN 发布") for label, _ in all_steps))

        ctan_steps = dashboard.build_steps(
            "release-pipeline", {**VALID_PARAMS, "publishTarget": "ctan"}
        )
        self.assertEqual(ctan_steps[0][0], "01 · 确认 GitHub Release")
        self.assertEqual(ctan_steps[0][1][:4], ["gh", "release", "view", "v1.2.3"])
        self.assertEqual(ctan_steps[-1][0], "02 · 触发 CTAN 发布")
        self.assertFalse(any("check-ctan-release.py" in command for _, command in ctan_steps))

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
        self.assertIn("/examzh-release prepare", changelog)
        self.assertIn("新增测试文件", changelog)
        self.assertIn("完整手册和入门手册", changelog)
        self.assertIn("具体说明与短示例", changelog)
        self.assertIn("不要把后续自动更新的版本号或日期算作手册优化", changelog)
        self.assertIn("渲染并检查受影响页面", changelog)
        self.assertIn("清空 tmp/", changelog)
        self.assertIn("make changelog", changelog)
        self.assertIn("不要提交", changelog)
        self.assertIn("不要执行完整发布构建", changelog)
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


class ReleaseContextTests(unittest.TestCase):
    @mock.patch("workflow_dashboard.capture")
    @mock.patch("workflow_dashboard._github_release_list")
    def test_ctan_context_uses_latest_stable_github_release(
        self,
        release_list: mock.Mock,
        capture: mock.Mock,
    ) -> None:
        release_list.return_value = [
            {"tagName": "v0.3.5", "publishedAt": "2026-07-31T11:14:09Z", "isDraft": False, "isPrerelease": False},
            {"tagName": "v0.3.6", "publishedAt": "2026-08-01T08:12:23Z", "isDraft": False, "isPrerelease": False},
            {"tagName": "v0.4.0-rc1", "publishedAt": "2026-08-02T08:12:23Z", "isDraft": False, "isPrerelease": True},
        ]
        capture.return_value = 'version = "v0.3.6"\ndate = "2026-08-01"'

        context = dashboard.latest_github_release_context()

        self.assertEqual(context["version"], "0.3.6")
        self.assertEqual(context["date"], "2026-08-01")
        self.assertEqual(context["publishTarget"], "ctan")
        self.assertEqual(context["sourceTag"], "v0.3.6")

    @mock.patch("workflow_dashboard.capture", side_effect=dashboard.DashboardError("missing tag"))
    @mock.patch("workflow_dashboard._github_release_list")
    def test_ctan_context_does_not_require_a_local_tag(
        self,
        release_list: mock.Mock,
        _capture: mock.Mock,
    ) -> None:
        release_list.return_value = [
            {
                "tagName": "v0.3.6",
                "publishedAt": "2026-08-01T08:12:23Z",
                "isDraft": False,
                "isPrerelease": False,
            }
        ]

        context = dashboard.latest_github_release_context()

        self.assertEqual(context["version"], "0.3.6")
        self.assertEqual(context["date"], "2026-08-01")

    def test_ctan_workflow_does_not_require_development_fragment_archives(self) -> None:
        workflow = (dashboard.ROOT / ".github" / "workflows" / "ctan-upload.yml").read_text(
            encoding="utf-8"
        )

        self.assertIn('ref: ${{ inputs.tag }}', workflow)
        self.assertIn("python3 scripts/check-ctan-release.py", workflow)
        self.assertIn("run: make doc doc-basic", workflow)
        self.assertIn("run: l3build ctan", workflow)
        self.assertIn("l3build upload --dry-run", workflow)
        for package in ("hypdoc", "makecell", "mnsymbol", "xpinyin", "zhlipsum"):
            self.assertIn(package, workflow)
        self.assertNotIn("make check-changelog", workflow)
        self.assertNotIn("scripts/test-build.sh", workflow)

    @mock.patch("workflow_dashboard._gh_json")
    def test_ctan_environment_must_explicitly_enable_upload(self, gh_json: mock.Mock) -> None:
        gh_json.side_effect = [
            {"environments": [{"name": "ctan"}]},
            {"variables": [{"name": "CTAN_UPLOAD_ENABLED", "value": "true"}]},
        ]

        status = dashboard.ctan_upload_environment_status()

        self.assertTrue(status["ctanUploadReady"])

    @mock.patch("workflow_dashboard._gh_json")
    def test_missing_ctan_environment_is_reported_before_dispatch(self, gh_json: mock.Mock) -> None:
        gh_json.return_value = {"environments": []}

        status = dashboard.ctan_upload_environment_status()

        self.assertFalse(status["ctanUploadReady"])
        self.assertIn("尚未创建", status["ctanUploadMessage"])

    def test_new_release_uses_next_patch_today_and_matching_commit_message(self) -> None:
        context = dashboard.suggested_release_context("0.3.4", "2026-07-31", [])

        self.assertEqual(
            context,
            {
                "version": "0.3.5",
                "date": "2026-07-31",
                "publishTarget": "platforms",
                "message": "chore(release): v0.3.5",
                "skipCompile": False,
            },
        )

    def test_incomplete_release_keeps_its_version_date_and_message(self) -> None:
        failed = dashboard.Job(
            id="failed-job",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="failed",
            created_at="2026-07-30T10:00:00+00:00",
            step_count=16,
            completed_steps=3,
            params={
                "version": "0.3.5",
                "date": "2026-08-02",
                "publishTarget": "all",
                "message": "release: publish v0.3.5",
                "skipCompile": True,
            },
        )

        context = dashboard.suggested_release_context("0.3.4", "2026-07-31", [failed])

        self.assertEqual(context, dashboard.normalized_pipeline_params(failed.params))

    def test_incomplete_ctan_attempt_does_not_change_platform_context(self) -> None:
        failed = dashboard.Job(
            id="failed-ctan",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="interrupted",
            created_at="2026-08-03T13:27:55+00:00",
            step_count=2,
            completed_steps=2,
            params={
                "version": "0.3.6",
                "date": "2026-08-03",
                "publishTarget": "ctan",
                "message": "chore(release): v0.3.6",
                "skipCompile": False,
            },
        )

        context = dashboard.suggested_release_context("0.3.6", "2026-08-03", [failed])

        self.assertEqual(context["version"], "0.3.7")
        self.assertEqual(context["publishTarget"], "platforms")

    def test_completed_release_advances_instead_of_restoring_old_inputs(self) -> None:
        completed = dashboard.Job(
            id="completed-job",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="success",
            created_at="2026-07-30T11:00:00+00:00",
            step_count=16,
            completed_steps=16,
            params={
                "version": "0.3.4",
                "date": "2026-07-30",
                "publishTarget": "platforms",
                "message": "chore(release): v0.3.4",
            },
        )

        context = dashboard.suggested_release_context("0.3.4", "2026-07-31", [completed])

        self.assertEqual(context["version"], "0.3.5")
        self.assertEqual(context["date"], "2026-07-31")
        self.assertEqual(context["message"], "chore(release): v0.3.5")

    def test_latest_success_supersedes_an_older_failed_attempt(self) -> None:
        params = dashboard.normalized_pipeline_params(VALID_PARAMS)
        failed = dashboard.Job(
            id="failed-job",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="failed",
            created_at="2026-08-01T01:00:00+00:00",
            step_count=16,
            completed_steps=3,
            params=params,
        )
        success = dashboard.Job(
            id="successful-retry",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="success",
            created_at="2026-08-01T02:00:00+00:00",
            step_count=16,
            completed_steps=16,
            params=params,
        )

        context = dashboard.suggested_release_context("1.2.3", "2026-08-02", [failed, success])

        self.assertEqual(context["version"], "1.2.4")
        self.assertEqual(context["message"], "chore(release): v1.2.4")


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

    def test_legacy_ctan_success_is_not_kept_as_verified(self) -> None:
        manager = dashboard.JobManager(self.state_path)
        job = dashboard.Job(
            id="legacy-ctan",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="success",
            step_count=2,
            completed_steps=2,
            params={"version": "0.3.6", "publishTarget": "ctan"},
        )
        manager.jobs[job.id] = job
        manager._persist()

        restored = dashboard.JobManager(self.state_path).get(job.id)

        self.assertEqual(restored.status, "interrupted")
        self.assertIn("未核实远程 Actions", "\n".join(restored.logs))

    def test_successful_retry_invalidates_older_failed_checkpoint(self) -> None:
        params = dashboard.normalized_pipeline_params(VALID_PARAMS)
        steps = dashboard.build_steps("release-pipeline", params)
        signature = dashboard.step_plan_signature(steps)
        manager = dashboard.JobManager(None)
        failed = dashboard.Job(
            id="failed-job",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="failed",
            created_at="2026-08-01T01:00:00+00:00",
            step_number=4,
            step_count=len(steps),
            completed_steps=3,
            params=params,
            plan_signature=signature,
        )
        success = dashboard.Job(
            id="successful-retry",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            status="success",
            created_at="2026-08-01T02:00:00+00:00",
            step_number=len(steps),
            step_count=len(steps),
            completed_steps=len(steps),
            params=params,
            plan_signature=signature,
        )
        manager.jobs = {failed.id: failed, success.id: success}

        self.assertIsNone(manager._resume_checkpoint(params, signature))
        snapshots = manager.recent()
        self.assertEqual(snapshots[0]["id"], success.id)
        self.assertFalse(any(job["resumeAvailable"] for job in snapshots))

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

    @mock.patch("workflow_dashboard.run_github_workflow_and_wait", return_value=1)
    def test_remote_workflow_failure_marks_dashboard_job_failed(self, _run_remote: mock.Mock) -> None:
        manager = dashboard.JobManager(None)
        job = dashboard.Job(
            id="remote-failure",
            workflow_id="release-pipeline",
            title="执行完整发布链",
            step_count=1,
        )
        manager.jobs[job.id] = job
        manager.active_id = job.id
        command = ["gh", "workflow", "run", dashboard.CTAN_WORKFLOW, "--repo", dashboard.GITHUB_REPOSITORY]

        manager._run_processes(job, [("01 · 触发 CTAN 发布", command)])

        self.assertEqual(job.status, "failed")
        self.assertEqual(job.return_code, 1)
        self.assertEqual(job.completed_steps, 0)

    @mock.patch("workflow_dashboard.REMOTE_WORKFLOW_POLL_INTERVAL", 0)
    @mock.patch("workflow_dashboard._gh_json")
    @mock.patch("workflow_dashboard.subprocess.run")
    def test_remote_workflow_waits_for_the_new_run_conclusion(
        self,
        run: mock.Mock,
        gh_json: mock.Mock,
    ) -> None:
        trigger = dashboard.subprocess.CompletedProcess([], 0, "", "")
        run.return_value = trigger
        gh_json.side_effect = [
            [],
            [{
                "databaseId": 123,
                "status": "queued",
                "conclusion": None,
                "createdAt": dashboard.datetime.now(dashboard.timezone.utc).isoformat(),
                "headBranch": "main",
                "event": "workflow_dispatch",
                "url": "https://github.com/xkwxdyy/exam-zh/actions/runs/123",
            }],
            {
                "status": "completed",
                "conclusion": "success",
                "url": "https://github.com/xkwxdyy/exam-zh/actions/runs/123",
            },
        ]
        job = dashboard.Job(
            id="remote-success",
            workflow_id="release-pipeline",
            title="执行完整发布链",
        )
        command = ["gh", "workflow", "run", dashboard.CTAN_WORKFLOW, "--repo", dashboard.GITHUB_REPOSITORY]

        result = dashboard.run_github_workflow_and_wait(job, command)

        self.assertEqual(result, 0)
        self.assertTrue(any("GitHub Actions 已结束：success" in line for line in job.logs))

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

    @mock.patch("workflow_dashboard.latest_github_release_context")
    @mock.patch("workflow_dashboard.shutil.which", return_value="/usr/local/bin/tool")
    @mock.patch("workflow_dashboard.capture")
    def test_ctan_pipeline_requires_latest_github_release(
        self,
        capture: mock.Mock,
        _which: mock.Mock,
        latest: mock.Mock,
    ) -> None:
        params = {**VALID_PARAMS, "publishTarget": "ctan"}
        latest.return_value = {"version": "1.2.4"}
        capture.side_effect = lambda command: (
            "main" if command[:3] == ["git", "branch", "--show-current"]
            else "https://example.invalid/repo" if command[:4] == ["git", "remote", "get-url", "github"]
            else "v1.2.3" if command[:3] == ["git", "tag", "--list"]
            else ""
        )

        with self.assertRaisesRegex(dashboard.DashboardError, "最新已发布的 GitHub Release v1.2.4"):
            dashboard.JobManager(None).start("release-pipeline", params)

    def test_ctan_pipeline_does_not_require_a_local_tag_or_fragment_archives(self) -> None:
        params = {**VALID_PARAMS, "publishTarget": "ctan"}

        def command_output(command: list[str]) -> str:
            if command[:3] == ["git", "branch", "--show-current"]:
                return "main"
            if command[:4] == ["git", "remote", "get-url", "github"]:
                return "https://example.invalid/repo"
            return ""

        with (
            mock.patch("workflow_dashboard.capture", side_effect=command_output),
            mock.patch("workflow_dashboard.shutil.which", return_value="/usr/local/bin/tool"),
            mock.patch(
                "workflow_dashboard.latest_github_release_context",
                return_value={"version": "1.2.3"},
            ),
            mock.patch(
                "workflow_dashboard.ctan_upload_environment_status",
                return_value={"ctanUploadReady": True, "ctanUploadMessage": "ready"},
            ),
            mock.patch("workflow_dashboard.threading.Thread.start"),
        ):
            job = dashboard.JobManager(None).start("release-pipeline", params)

        self.assertEqual(job.params["version"], "1.2.3")
        self.assertEqual(job.params["publishTarget"], "ctan")

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
        expected_version = dashboard.next_patch_version(payload["status"]["version"])
        self.assertEqual(payload["status"]["releaseContext"]["version"], expected_version)
        self.assertEqual(
            payload["status"]["releaseContext"]["message"],
            f"chore(release): v{expected_version}",
        )

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

    @mock.patch("workflow_dashboard.ctan_upload_environment_status")
    @mock.patch("workflow_dashboard.latest_github_release_context")
    def test_ctan_context_uses_remote_github_release(
        self,
        latest: mock.Mock,
        environment: mock.Mock,
    ) -> None:
        latest.return_value = {
            "version": "0.3.6",
            "date": "2026-08-01",
            "publishTarget": "ctan",
            "message": "chore(release): v0.3.6",
            "skipCompile": False,
        }
        environment.return_value = {
            "ctanUploadReady": True,
            "ctanUploadMessage": "CTAN 上传门禁已启用",
        }

        status, payload = self.request("/api/ctan-context")

        self.assertEqual(status, 200)
        self.assertEqual(payload["version"], "0.3.6")
        self.assertEqual(payload["publishTarget"], "ctan")
        self.assertTrue(payload["ctanUploadReady"])

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
