from __future__ import annotations

import hashlib
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from runner import direct_providers
from runner.direct_models import BY_LABEL, resolve_model
from runner.direct_providers import Generation
from runner.domain_tasks import DomainTask, discover_tasks
from runner import domain_sweep
from runner import subscription_providers


class PayloadIsolationTests(unittest.TestCase):
    def test_openai_payload_contains_only_the_canonical_user_prompt(self):
        prompt = "exact prompt\nwith spacing\n"
        payload = direct_providers.openai_payload(
            prompt, BY_LABEL["gpt-5.6-sol"], 1234
        )
        self.assertEqual(payload["input"], [{
            "role": "user",
            "content": [{"type": "input_text", "text": prompt}],
        }])
        self.assertFalse(payload["store"])
        for forbidden in (
            "instructions", "previous_response_id", "conversation", "tools",
            "file_search", "web_search",
        ):
            self.assertNotIn(forbidden, payload)

    def test_anthropic_payload_contains_only_the_canonical_user_prompt(self):
        prompt = "exact prompt\nwith spacing\n"
        payload = direct_providers.anthropic_payload(
            prompt, BY_LABEL["opus-5"], 1234
        )
        self.assertEqual(payload["messages"], [{"role": "user", "content": prompt}])
        for forbidden in ("system", "tools", "metadata", "container"):
            self.assertNotIn(forbidden, payload)

    @mock.patch.dict(os.environ, {"OPENAI_API_KEY": "not-recorded"})
    @mock.patch("runner.direct_providers._post_json")
    def test_openai_response_is_normalized(self, post):
        post.return_value = {
            "id": "resp_1",
            "model": "gpt-5.6-sol-2026-08-01",
            "status": "completed",
            "output": [{"type": "message", "content": [
                {"type": "output_text", "text": "module x; endmodule"}
            ]}],
            "usage": {"input_tokens": 100, "output_tokens": 200},
        }
        result = direct_providers.complete("prompt", BY_LABEL["gpt-5.6-sol"])
        self.assertEqual(result.text, "module x; endmodule")
        self.assertEqual(result.finish_reason, "stop")
        self.assertAlmostEqual(result.estimated_cost_usd, 0.0044)
        self.assertNotIn("not-recorded", json.dumps(result.to_dict()))


class SubscriptionTransportTests(unittest.TestCase):
    def test_codex_command_is_ephemeral_and_reads_prompt_from_stdin(self):
        command = subscription_providers._codex_command(
            "/bin/codex", "gpt-5.6-luna", Path("/tmp/work"), Path("/tmp/out")
        )
        self.assertEqual(command[-1], "-")
        for flag in (
            "--ephemeral", "--ignore-user-config", "--ignore-rules",
            "--skip-git-repo-check", "--output-last-message",
        ):
            self.assertIn(flag, command)
        self.assertIn("read-only", command)

    def test_claude_command_disables_context_tools_and_persistence(self):
        command = subscription_providers._claude_command(
            "/bin/claude", "claude-sonnet-5", Path("/tmp/mcp.json")
        )
        for flag in (
            "--safe-mode", "--no-session-persistence", "--strict-mcp-config",
            "--system-prompt", "--tools", "--disable-slash-commands",
            "--fallback-model",
        ):
            self.assertIn(flag, command)
        self.assertEqual(command[command.index("--tools") + 1], "")
        self.assertEqual(command[command.index("--system-prompt") + 1], "")
        self.assertEqual(command[command.index("--fallback-model") + 1], "")

    def test_gemini_command_is_headless_and_keeps_prompt_out_of_argv(self):
        command = subscription_providers._gemini_command("/bin/gemini", "pro")
        self.assertEqual(command[command.index("--prompt") + 1], "")
        self.assertEqual(command[command.index("--output-format") + 1], "json")
        self.assertEqual(command[command.index("--model") + 1], "pro")
        self.assertIn("--skip-trust", command)

    @mock.patch.dict(
        os.environ,
        {
            "OPENAI_API_KEY": "billed-openai",
            "ANTHROPIC_API_KEY": "billed-anthropic",
            "GEMINI_API_KEY": "billed-gemini",
            "GOOGLE_APPLICATION_CREDENTIALS": "/tmp/billed-google.json",
            "GOOGLE_CLOUD_PROJECT": "oauth-workspace-project",
            "KEEP_ME": "yes",
        },
    )
    def test_subscription_child_environment_removes_api_keys(self):
        openai_env = subscription_providers.subscription_environment("openai")
        anthropic_env = subscription_providers.subscription_environment("anthropic")
        google_env = subscription_providers.subscription_environment("google")
        self.assertNotIn("OPENAI_API_KEY", openai_env)
        self.assertNotIn("ANTHROPIC_API_KEY", anthropic_env)
        self.assertNotIn("GEMINI_API_KEY", google_env)
        self.assertNotIn("GOOGLE_APPLICATION_CREDENTIALS", google_env)
        self.assertEqual(
            google_env["GOOGLE_CLOUD_PROJECT"], "oauth-workspace-project"
        )
        self.assertEqual(openai_env["KEEP_ME"], "yes")
        self.assertEqual(anthropic_env["KEEP_ME"], "yes")
        self.assertEqual(google_env["KEEP_ME"], "yes")

    @mock.patch("runner.subscription_providers.shutil.which", return_value="/bin/codex")
    @mock.patch("runner.subscription_providers.subprocess.run")
    def test_codex_auth_must_explicitly_be_chatgpt(self, run, _which):
        run.return_value = mock.Mock(
            returncode=0, stdout="Logged in using ChatGPT\n", stderr=""
        )
        subscription_providers.ensure_subscription_auth("openai")

        run.return_value = mock.Mock(
            returncode=0, stdout="Logged in using an API key\n", stderr=""
        )
        with self.assertRaises(subscription_providers.ProviderError):
            subscription_providers.ensure_subscription_auth("openai")

    @mock.patch("runner.subscription_providers.shutil.which", return_value="/bin/claude")
    @mock.patch("runner.subscription_providers.subprocess.run")
    def test_claude_auth_requires_a_subscription_type(self, run, _which):
        run.return_value = mock.Mock(
            returncode=0,
            stdout=json.dumps({
                "loggedIn": True,
                "authMethod": "oauth_token",
                "apiProvider": "firstParty",
                "subscriptionType": "pro",
            }),
            stderr="",
        )
        subscription_providers.ensure_subscription_auth("anthropic")

        run.return_value = mock.Mock(
            returncode=0,
            stdout=json.dumps({
                "loggedIn": True,
                "authMethod": "api_key",
                "apiProvider": "firstParty",
            }),
            stderr="",
        )
        with self.assertRaises(subscription_providers.ProviderError):
            subscription_providers.ensure_subscription_auth("anthropic")

    @mock.patch("runner.subscription_providers.shutil.which", return_value="/bin/gemini")
    def test_gemini_auth_requires_google_account_oauth(self, _which):
        with tempfile.TemporaryDirectory() as temporary:
            config_dir = Path(temporary) / ".gemini"
            config_dir.mkdir()
            settings = config_dir / "settings.json"
            settings.write_text(json.dumps({
                "security": {"auth": {"selectedType": "oauth-personal"}},
            }))
            with mock.patch.dict(
                os.environ, {"GEMINI_CLI_HOME": temporary}, clear=False
            ):
                subscription_providers.ensure_subscription_auth("google")

            settings.write_text(json.dumps({
                "security": {"auth": {"selectedType": "gemini-api-key"}},
            }))
            with mock.patch.dict(
                os.environ, {"GEMINI_CLI_HOME": temporary}, clear=False
            ):
                with self.assertRaises(subscription_providers.ProviderError):
                    subscription_providers.ensure_subscription_auth("google")

    @mock.patch("runner.subscription_providers.shutil.which", return_value="/bin/gemini")
    @mock.patch("runner.subscription_providers.subprocess.run")
    def test_gemini_json_response_is_normalized(self, run, _which):
        run.return_value = mock.Mock(
            returncode=0,
            stdout=json.dumps({
                "response": "module x; endmodule",
                "stats": {"models": {
                    "gemini-3.1-pro-preview": {
                        "tokens": {
                            "prompt": 100,
                            "candidates": 20,
                            "thoughts": 30,
                        },
                    },
                }},
            }),
            stderr="",
        )
        result = subscription_providers._complete_once(
            "canonical prompt", BY_LABEL["gemini-pro"]
        )
        self.assertEqual(result.text, "module x; endmodule")
        self.assertEqual(result.resolved_model, "gemini-3.1-pro-preview")
        self.assertEqual((result.input_tokens, result.output_tokens), (100, 50))
        self.assertEqual(run.call_args.kwargs["input"], "canonical prompt")
        child_env = run.call_args.kwargs["env"]
        self.assertIn("GEMINI_CLI_SYSTEM_SETTINGS_PATH", child_env)

    def test_claude_selected_model_is_verified_from_reported_usage(self):
        self.assertTrue(subscription_providers._requested_model_was_used(
            "claude-opus-5", ["claude-opus-5-20260724"]
        ))
        self.assertFalse(subscription_providers._requested_model_was_used(
            "claude-opus-5", ["claude-haiku-4-5-20251001"]
        ))

    def test_codex_selected_model_is_parsed_from_cli_provenance(self):
        stderr = "workdir: /tmp/example\nmodel: gpt-5.6-luna\nprovider: openai\n"
        self.assertEqual(
            subscription_providers._codex_reported_model(stderr), "gpt-5.6-luna"
        )

    def test_claude_usage_includes_prompt_cache_tokens(self):
        data = {"usage": {
            "input_tokens": 1,
            "cache_creation_input_tokens": 5672,
            "cache_read_input_tokens": 3,
            "output_tokens": 20,
        }}
        self.assertEqual(subscription_providers._usage(data), (5676, 20))

    @mock.patch("runner.subscription_providers.time.sleep")
    @mock.patch("runner.subscription_providers._complete_once")
    def test_temporary_subscription_overload_is_retried(self, once, _sleep):
        once.side_effect = [
            Generation(
                "anthropic", "claude-opus-5", None, "",
                error="API Error: 529 Overloaded",
            ),
            Generation(
                "anthropic", "claude-opus-5", "claude-opus-5", "ok",
            ),
        ]
        result = subscription_providers.complete(
            "prompt", BY_LABEL["opus-5"], max_retries=2
        )
        self.assertEqual(result.text, "ok")
        self.assertEqual(once.call_count, 2)

    def test_google_model_alias_and_explicit_id_resolve(self):
        self.assertEqual(BY_LABEL["gemini-pro"].model_id, "pro")
        explicit = resolve_model("google:gemini-3.1-pro-preview")
        self.assertEqual(explicit.provider, "google")
        self.assertEqual(explicit.model_id, "gemini-3.1-pro-preview")

    @mock.patch.dict(os.environ, {"ANTHROPIC_API_KEY": "not-recorded"})
    @mock.patch("runner.direct_providers._post_json")
    def test_anthropic_response_is_normalized(self, post):
        post.return_value = {
            "id": "msg_1",
            "model": "claude-opus-5",
            "stop_reason": "end_turn",
            "content": [{"type": "text", "text": "module x; endmodule"}],
            "usage": {"input_tokens": 100, "output_tokens": 200},
        }
        result = direct_providers.complete("prompt", BY_LABEL["opus-5"])
        self.assertEqual(result.text, "module x; endmodule")
        self.assertEqual(result.finish_reason, "end_turn")
        self.assertAlmostEqual(result.estimated_cost_usd, 0.0055)
        self.assertNotIn("not-recorded", json.dumps(result.to_dict()))


class TaskDiscoveryTests(unittest.TestCase):
    def test_current_packaged_task_set_is_complete_and_typed(self):
        tasks = discover_tasks()
        repo_root = Path(__file__).resolve().parent.parent
        registered_directories = {
            prompt_path.parent.parent
            for prompt_path in repo_root.glob("domains/*/*/*/probe/PASTE.md")
            if (prompt_path.parent.parent / "task.yaml").is_file()
        }
        self.assertEqual({task.directory for task in tasks}, registered_directories)
        self.assertNotIn("d_dsp01", {task.task_id for task in tasks})
        self.assertEqual({task.kind for task in tasks}, {"design", "verification"})
        for task in tasks:
            self.assertEqual(
                task.prompt_sha256,
                hashlib.sha256(task.prompt_path.read_bytes()).hexdigest(),
            )


class SweepIntegrationTests(unittest.TestCase):
    def test_generation_is_extracted_saved_and_graded_without_reprompting(self):
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            prompt_path = repo / "domains" / "demo" / "design" / "d_demo_x" / "probe" / "PASTE.md"
            prompt_path.parent.mkdir(parents=True)
            prompt_text = "prompt bytes are canonical\n"
            prompt_path.write_text(prompt_text, encoding="utf-8")
            task = DomainTask(
                task_id="d_demo",
                kind="design",
                module="demo",
                directory=prompt_path.parent.parent,
                prompt_path=prompt_path,
                prompt_bytes=prompt_text.encode(),
                prompt_text=prompt_text,
                prompt_sha256=hashlib.sha256(prompt_text.encode()).hexdigest(),
                task_text_hash="0123456789abcdef",
            )
            generation = Generation(
                provider="openai",
                requested_model="gpt-5.6-sol",
                resolved_model="gpt-5.6-sol",
                text="Here it is:\n```systemverilog\nmodule demo;\nendmodule\n```",
                input_tokens=10,
                output_tokens=20,
                estimated_cost_usd=0.001,
                finish_reason="stop",
                request_id="resp_test",
                raw={"id": "resp_test"},
            )
            grade = {"simulation": {
                "command": ["sim_candidate.sh"],
                "returncode": 0,
                "stdout": "PASS",
                "stderr": "",
            }}
            artifact_root = repo / "results" / "generations"
            with (
                mock.patch.object(domain_sweep, "REPO_ROOT", repo),
                mock.patch.object(domain_sweep, "ARTIFACT_ROOT", artifact_root),
                mock.patch.object(domain_sweep, "complete", return_value=generation) as complete,
                mock.patch.object(domain_sweep, "_grade", return_value=grade) as grade_call,
            ):
                run_id, manifest = domain_sweep.execute(
                    tasks=[task],
                    models=[BY_LABEL["gpt-5.6-sol"]],
                    samples=1,
                    api_workers=1,
                    max_output_tokens=None,
                    max_spend=1.0,
                    smoke=False,
                    ppa=False,
                    run_id="test-run",
                )

            self.assertEqual(run_id, "test-run")
            complete.assert_called_once_with(
                prompt_text, BY_LABEL["gpt-5.6-sol"], max_output_tokens=None
            )
            grade_call.assert_called_once()
            entry = next(iter(manifest["jobs"].values()))
            self.assertEqual(entry["status"], "passed")
            candidate = repo / entry["candidate"]
            self.assertEqual(candidate.read_text(), "module demo;\nendmodule\n")
            raw = json.loads((repo / entry["raw_response"]).read_text())
            self.assertEqual(raw["prompt_sha256"], task.prompt_sha256)
            self.assertEqual(raw["request"]["isolation"]["messages"], 1)

    def test_subscription_generation_is_labeled_and_dispatched_separately(self):
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            prompt_path = repo / "domains" / "demo" / "probe" / "PASTE.md"
            prompt_path.parent.mkdir(parents=True)
            prompt_text = "subscription prompt\n"
            prompt_path.write_text(prompt_text, encoding="utf-8")
            task = DomainTask(
                "d_demo", "design", "demo", prompt_path.parent.parent,
                prompt_path, prompt_text.encode(), prompt_text,
                hashlib.sha256(prompt_text.encode()).hexdigest(), "task-hash",
            )
            generation = Generation(
                provider="openai",
                requested_model="gpt-5.6-luna",
                resolved_model="gpt-5.6-luna",
                text="module demo; endmodule",
                finish_reason="stop",
            )
            artifact_root = repo / "results" / "generations"
            with (
                mock.patch.object(domain_sweep, "REPO_ROOT", repo),
                mock.patch.object(domain_sweep, "ARTIFACT_ROOT", artifact_root),
                mock.patch.object(
                    domain_sweep, "subscription_complete", return_value=generation
                ) as generate,
                mock.patch.object(
                    domain_sweep, "_grade",
                    return_value={"simulation": {"returncode": 0}},
                ),
            ):
                _, manifest = domain_sweep.execute(
                    tasks=[task],
                    models=[BY_LABEL["gpt-5.6-luna"]],
                    samples=1,
                    api_workers=1,
                    max_output_tokens=None,
                    max_spend=None,
                    smoke=True,
                    ppa=False,
                    run_id="subscription-test",
                    transport="subscription",
                )

            generate.assert_called_once_with(
                prompt_text, BY_LABEL["gpt-5.6-luna"], max_output_tokens=None
            )
            entry = next(iter(manifest["jobs"].values()))
            self.assertIn("__subscription__", entry["candidate"])
            raw = json.loads((repo / entry["raw_response"]).read_text())
            self.assertEqual(raw["request"]["transport"], "subscription")
            self.assertTrue(raw["request"]["isolation"]["fresh_process"])

    @mock.patch("runner.domain_sweep._run_command")
    def test_verification_uses_the_verification_grader(self, run_command):
        run_command.return_value = {"returncode": 0}
        task = DomainTask(
            "v_demo", "verification", "demo_tb", Path("/task"), Path("/prompt"),
            b"p", "p", hashlib.sha256(b"p").hexdigest(), "hash",
        )
        job = domain_sweep.Job(task, BY_LABEL["opus-5"], 1)
        domain_sweep._grade(job, Path("/candidate.sv"), smoke=False, ppa=True)
        command = run_command.call_args.args[0]
        self.assertTrue(command[0].endswith("sim_verification.sh"))
        self.assertNotIn("ppa_candidate.sh", " ".join(command))


if __name__ == "__main__":
    unittest.main()
