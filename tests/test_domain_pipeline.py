from __future__ import annotations

import hashlib
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from runner import direct_providers
from runner.direct_models import BY_LABEL
from runner.direct_providers import Generation
from runner.domain_tasks import DomainTask, discover_tasks
from runner import domain_sweep


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
        self.assertEqual(len(tasks), 14)
        self.assertEqual(sum(task.kind == "design" for task in tasks), 5)
        self.assertEqual(sum(task.kind == "verification" for task in tasks), 9)
        self.assertNotIn("d_ca04", {task.task_id for task in tasks})
        self.assertNotIn("d_nw01", {task.task_id for task in tasks})
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
