"""Generate and grade current domain tasks through isolated model transports.

Examples::

    python3 -m runner.domain_sweep --list-models
    python3 -m runner.domain_sweep --tasks d_ca01 --models gpt-5.6-luna --dry-run
    python3 -m runner.domain_sweep --tasks d_ca01 --models gpt-5.6-luna \
        --max-spend 1 --yes
    python3 -m runner.domain_sweep --transport subscription \
        --tasks d_ca01 --models gpt-5.6-luna --smoke

The canonical ``probe/PASTE.md`` is the only task/user content. Direct API runs
add no application context; subscription runs disable saved and project context
but retain any provider runtime context documented in their raw provenance.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import secrets
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from .direct_models import MODELS, DirectModel, resolve_models
from .direct_providers import Generation, ProviderError, api_key, complete
from .domain_tasks import (
    REPO_ROOT, DomainTask, TaskDiscoveryError, discover_tasks, select_tasks,
)
from .extract import extract_module
from .subscription_providers import (
    complete as subscription_complete,
    ensure_subscription_auth,
)

ARTIFACT_ROOT = REPO_ROOT / "results" / "generations"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _run_id() -> str:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return f"{stamp}-{secrets.token_hex(3)}"


def _safe_label(value: str) -> str:
    label = re.sub(r"[^A-Za-z0-9_.-]+", "-", value).strip("-.")
    return label or "model"


def _atomic_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    os.replace(temporary, path)


def _write_source(path: Path, source: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(source if source.endswith("\n") else source + "\n",
                         encoding="utf-8")
    os.replace(temporary, path)


@dataclass(frozen=True)
class Job:
    task: DomainTask
    model: DirectModel
    sample: int
    transport: str = "api"

    @property
    def key(self) -> str:
        base = f"{self.task.task_id}:{self.model.provider}:{self.model.model_id}:{self.sample}"
        return base if self.transport == "api" else f"{base}:{self.transport}"


class SpendGuard:
    """Stop scheduling after observed estimated cost reaches the local limit."""

    def __init__(self, limit: float | None):
        self.limit = limit
        self.spent = 0.0
        self._lock = threading.Lock()

    def can_start(self) -> bool:
        with self._lock:
            return self.limit is None or self.spent < self.limit

    def charge(self, amount: float | None) -> None:
        if amount is None:
            return
        with self._lock:
            self.spent += amount


def _rough_input_tokens(task: DomainTask) -> int:
    # A planning estimate only. Actual provider usage is recorded after a call.
    return max(1, (len(task.prompt_bytes) + 3) // 4)


def estimate_jobs(jobs: list[Job], max_output_tokens: int | None) -> float | None:
    total = 0.0
    for job in jobs:
        # Historical completions usually fit under 8k tokens; reasoning-heavy
        # outliers are why the actual request ceiling is much higher.
        output = min(max_output_tokens or job.model.max_output_tokens, 8_000)
        estimate = job.model.estimate(_rough_input_tokens(job.task), output)
        if estimate is None:
            return None
        total += estimate
    return total


def _configuration(
    tasks: list[DomainTask],
    models: list[DirectModel],
    samples: int,
    max_output_tokens: int | None,
    smoke: bool,
    ppa: bool,
    transport: str = "api",
) -> dict:
    configuration = {
        "tasks": [{
            "id": task.task_id,
            "kind": task.kind,
            "module": task.module,
            "prompt": str(task.prompt_path.relative_to(REPO_ROOT)),
            "prompt_sha256": task.prompt_sha256,
            "task_text_hash": task.task_text_hash,
        } for task in tasks],
        "models": [{
            "label": model.label,
            "provider": model.provider,
            "model_id": model.model_id,
            "max_output_tokens": max_output_tokens or model.max_output_tokens,
            "input_usd_per_mtok": model.input_usd_per_mtok,
            "output_usd_per_mtok": model.output_usd_per_mtok,
            "price_checked": model.price_checked,
        } for model in models],
        "samples": samples,
        "smoke": smoke,
        "ppa": ppa,
    }
    if transport != "api":
        configuration["transport"] = transport
        configuration["output_token_limit_enforced"] = False
    return configuration


def _configuration_hash(configuration: dict) -> str:
    encoded = json.dumps(configuration, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def _candidate_path(run_id: str, job: Job) -> Path:
    transport = "" if job.transport == "api" else f"__{_safe_label(job.transport)}"
    name = f"{run_id}{transport}__{_safe_label(job.model.label)}__s{job.sample:02d}.sv"
    return REPO_ROOT / "candidates" / job.task.task_id / name


def _raw_path(run_dir: Path, job: Job) -> Path:
    transport = "" if job.transport == "api" else f"{_safe_label(job.transport)}__"
    name = f"{transport}{_safe_label(job.model.provider)}__{_safe_label(job.model.model_id)}__s{job.sample:02d}.json"
    return run_dir / "raw" / job.task.task_id / name


def _run_command(command: list[str]) -> dict:
    started = _now()
    result = subprocess.run(
        command, cwd=REPO_ROOT, text=True, capture_output=True, check=False
    )
    return {
        "command": [str(part) for part in command],
        "started_at": started,
        "finished_at": _now(),
        "returncode": result.returncode,
        "stdout": result.stdout,
        "stderr": result.stderr,
    }


def _grade(job: Job, candidate: Path, *, smoke: bool, ppa: bool) -> dict:
    if job.task.kind == "design":
        command = [
            str(REPO_ROOT / "scripts" / "sim_candidate.sh"),
            job.task.task_id,
            str(candidate),
        ]
        if smoke:
            command.append("--smoke")
    else:
        command = [
            str(REPO_ROOT / "scripts" / "sim_verification.sh"),
            job.task.task_id,
            str(candidate),
            candidate.stem,
        ]
    simulation = _run_command(command)
    grade = {"simulation": simulation}
    if ppa and job.task.kind == "design" and simulation["returncode"] == 0:
        grade["ppa"] = _run_command([
            str(REPO_ROOT / "scripts" / "ppa_candidate.sh"),
            job.task.task_id,
            str(candidate),
            candidate.stem,
        ])
    return grade


def _record_generation(run_dir: Path, job: Job, generation: Generation) -> Path:
    path = _raw_path(run_dir, job)
    record = {
        "schema_version": 1,
        "recorded_at": _now(),
        "task": job.task.task_id,
        "task_kind": job.task.kind,
        "target_module": job.task.module,
        "prompt_path": str(job.task.prompt_path.relative_to(REPO_ROOT)),
        "prompt_sha256": job.task.prompt_sha256,
        "task_text_hash": job.task.task_text_hash,
        "sample": job.sample,
        "request": {
            "provider": job.model.provider,
            "model_id": job.model.model_id,
            "isolation": {
                "messages": 1,
                "role": "user",
                "system": False,
                "conversation_id": False,
                "tools": False,
                "retrieval": False,
            },
        },
        "generation": generation.to_dict(include_raw=True),
    }
    if job.transport != "api":
        provider_isolation = {
            "anthropic": {
                "account_or_project_customizations": False,
                "tools": False,
                "system": "empty replacement",
            },
            "openai": {
                "account_or_project_customizations": False,
                "tools": "Codex built-ins",
                "system": "Codex built-in",
            },
            "google": {
                "account_or_project_customizations": (
                    "dedicated GEMINI_CLI_HOME recommended"
                ),
                "tools": "Gemini headless defaults in an empty workspace",
                "system": "Gemini CLI default",
            },
        }[job.model.provider]
        record["request"]["transport"] = job.transport
        record["request"]["isolation"] = {
            "user_messages": 1,
            "user_prompt": "canonical probe/PASTE.md via stdin",
            "fresh_process": True,
            "empty_temporary_directory": True,
            "session_persistence": False,
            **provider_isolation,
        }
    _atomic_json(path, record)
    return path


def _load_manifest(run_dir: Path) -> dict:
    path = run_dir / "manifest.json"
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ValueError(f"no run named {run_dir.name!r}") from exc
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid manifest for run {run_dir.name!r}: {exc}") from exc


def execute(
    *,
    tasks: list[DomainTask],
    models: list[DirectModel],
    samples: int,
    api_workers: int,
    max_output_tokens: int | None,
    max_spend: float | None,
    smoke: bool,
    ppa: bool,
    run_id: str | None = None,
    transport: str = "api",
) -> tuple[str, dict]:
    run_id = run_id or _run_id()
    run_dir = ARTIFACT_ROOT / run_id
    configuration = _configuration(
        tasks, models, samples, max_output_tokens, smoke, ppa, transport
    )
    config_hash = _configuration_hash(configuration)
    manifest_path = run_dir / "manifest.json"
    if manifest_path.exists():
        manifest = _load_manifest(run_dir)
        if manifest.get("configuration_hash") != config_hash:
            raise ValueError(
                f"run {run_id} has different tasks, models, prompts, or settings"
            )
    else:
        manifest = {
            "schema_version": 1,
            "run_id": run_id,
            "created_at": _now(),
            "updated_at": _now(),
            "configuration": configuration,
            "configuration_hash": config_hash,
            "jobs": {},
        }
        _atomic_json(manifest_path, manifest)

    all_jobs = [
        Job(task, model, sample, transport)
        for task in tasks for model in models for sample in range(1, samples + 1)
    ]
    jobs = [job for job in all_jobs if manifest["jobs"].get(job.key, {}).get("terminal") is not True]
    guard = SpendGuard(max_spend)
    guard.spent = sum(
        (entry.get("estimated_cost_usd") or 0.0)
        for entry in manifest["jobs"].values()
    )
    manifest_lock = threading.Lock()

    def generate(job: Job) -> tuple[Job, Generation | None]:
        if not guard.can_start():
            return job, None
        generate_one = complete if transport == "api" else subscription_complete
        generation = generate_one(
            job.task.prompt_text,
            job.model,
            max_output_tokens=max_output_tokens,
        )
        guard.charge(generation.estimated_cost_usd)
        return job, generation

    with ThreadPoolExecutor(max_workers=api_workers) as pool:
        futures = [pool.submit(generate, job) for job in jobs]
        for future in as_completed(futures):
            job, generation = future.result()
            if generation is None:
                status = "spend_limit"
                entry = {"terminal": False, "status": status, "updated_at": _now()}
            else:
                raw_path = _record_generation(run_dir, job, generation)
                entry = {
                    "terminal": True,
                    "status": "generated",
                    "updated_at": _now(),
                    "raw_response": str(raw_path.relative_to(REPO_ROOT)),
                    "estimated_cost_usd": generation.estimated_cost_usd,
                    "input_tokens": generation.input_tokens,
                    "output_tokens": generation.output_tokens,
                    "request_id": generation.request_id,
                    "finish_reason": generation.finish_reason,
                }
                if generation.error:
                    error_status = "api_error" if transport == "api" else "transport_error"
                    entry.update(
                        status=error_status, error=generation.error, terminal=False
                    )
                elif generation.truncated:
                    entry.update(status="truncated", terminal=False)
                else:
                    source = extract_module(generation.text, job.task.module)
                    if source is None:
                        entry.update(status="no_code")
                    else:
                        candidate = _candidate_path(run_id, job)
                        _write_source(candidate, source)
                        entry["candidate"] = str(candidate.relative_to(REPO_ROOT))
                        entry["candidate_sha256"] = hashlib.sha256(
                            candidate.read_bytes()
                        ).hexdigest()
                        grade = _grade(job, candidate, smoke=smoke, ppa=ppa)
                        entry["grade"] = grade
                        sim_rc = grade["simulation"]["returncode"]
                        entry["status"] = "passed" if sim_rc == 0 else "failed"
                        if "ppa" in grade and grade["ppa"]["returncode"] != 0:
                            entry["status"] = "ppa_failed"
            with manifest_lock:
                manifest["jobs"][job.key] = entry
                manifest["updated_at"] = _now()
                manifest["estimated_cost_usd"] = guard.spent
                _atomic_json(manifest_path, manifest)
            print(f"{job.task.task_id:8s} {job.model.label:18s} s{job.sample:02d}  {entry['status']}")

    return run_id, manifest


def _split_csv(value: str) -> list[str]:
    return [part.strip() for part in value.split(",") if part.strip()]


def _print_models() -> None:
    print(f"{'label':18s} {'provider':10s} {'model id':24s} {'$/Min':>8s} {'$/Mout':>8s}")
    for model in MODELS:
        input_price = (
            f"{model.input_usd_per_mtok:8.2f}"
            if model.input_usd_per_mtok is not None else f"{'n/a':>8s}"
        )
        output_price = (
            f"{model.output_usd_per_mtok:8.2f}"
            if model.output_usd_per_mtok is not None else f"{'n/a':>8s}"
        )
        print(
            f"{model.label:18s} {model.provider:10s} {model.model_id:24s} "
            f"{input_price} {output_price}"
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="runner.domain_sweep")
    parser.add_argument("--list-models", action="store_true")
    parser.add_argument("--tasks", default="all", help="comma-separated task IDs or all")
    parser.add_argument("--models", default="", help="labels or provider:model-id values")
    parser.add_argument(
        "--transport", choices=("api", "subscription"), default="api",
        help="direct paid API (default) or included Codex/Claude/Gemini quota",
    )
    parser.add_argument("-k", "--samples", type=int, default=1)
    parser.add_argument("--api-workers", type=int, default=1)
    parser.add_argument("--max-output-tokens", type=int, default=None)
    parser.add_argument("--max-spend", type=float, default=None)
    parser.add_argument("--no-spend-limit", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--smoke", action="store_true",
                        help="one config for design tasks; verification remains full")
    parser.add_argument("--ppa", action="store_true")
    parser.add_argument("--yes", action="store_true", help="skip paid-run confirmation")
    parser.add_argument("--resume", metavar="RUN_ID")
    args = parser.parse_args(argv)

    if args.list_models:
        _print_models()
        return 0
    if not args.models:
        parser.error("--models is required (use --list-models)")
    if args.samples <= 0 or args.api_workers <= 0:
        parser.error("--samples and --api-workers must be positive")
    if args.max_output_tokens is not None and args.max_output_tokens <= 0:
        parser.error("--max-output-tokens must be positive")
    if args.max_spend is not None and args.max_spend <= 0:
        parser.error("--max-spend must be positive")
    if args.max_spend is not None and args.no_spend_limit:
        parser.error("choose --max-spend or --no-spend-limit, not both")
    if args.transport == "subscription" and (args.max_spend or args.no_spend_limit):
        parser.error("subscription runs use included quota; omit API spend flags")

    try:
        available = discover_tasks()
        tasks = select_tasks(available, _split_csv(args.tasks))
        models = resolve_models(_split_csv(args.models))
    except (TaskDiscoveryError, ValueError) as exc:
        parser.error(str(exc))

    if args.transport == "api" and any(model.provider == "google" for model in models):
        parser.error(
            "Google models currently require --transport subscription; "
            "direct Gemini API billing is not implemented"
        )

    jobs = [
        Job(task, model, sample, args.transport)
        for task in tasks for model in models for sample in range(1, args.samples + 1)
    ]
    estimate = estimate_jobs(jobs, args.max_output_tokens) if args.transport == "api" else 0.0
    print(
        f"{len(tasks)} tasks x {len(models)} models x k={args.samples} "
        f"= {len(jobs)} requests"
    )
    print(f"  transport: {args.transport}")
    print(f"  design: {sum(task.kind == 'design' for task in tasks)}")
    print(f"  verification: {sum(task.kind == 'verification' for task in tasks)}")
    for model in models:
        if args.transport == "subscription":
            output_limit = "provider-managed"
        else:
            output_limit = str(args.max_output_tokens or model.max_output_tokens)
        print(
            f"  {model.label:18s} {model.provider}:{model.model_id} "
            f"max_output={output_limit}"
        )
    if args.transport == "subscription":
        print("  incremental API cost: $0 (uses included subscription quota)")
        if args.max_output_tokens is not None:
            print("  note: subscription CLIs do not expose a hard output-token cap")
    elif estimate is None:
        print("  typical-cost estimate: unavailable for an unpriced explicit model ID")
    else:
        print(f"  typical-cost estimate: ${estimate:.2f} (assumes up to 8k output tokens/request)")
    if args.api_workers > 1 and args.max_spend is not None:
        print("  note: concurrent in-flight requests can finish just beyond the local spend limit")
    if args.dry_run:
        return 0

    if args.transport == "api" and args.max_spend is None and not args.no_spend_limit:
        parser.error("paid runs require --max-spend USD (or explicit --no-spend-limit)")
    if args.transport == "api" and args.max_spend is not None and estimate is None:
        parser.error("--max-spend requires configured prices; use a listed model label")
    try:
        for provider in sorted({model.provider for model in models}):
            if args.transport == "api":
                api_key(provider)
            else:
                ensure_subscription_auth(provider)
    except ProviderError as exc:
        parser.error(str(exc))

    if args.transport == "api" and not args.yes:
        if not sys.stdin.isatty():
            parser.error("paid non-interactive runs require --yes")
        answer = input("Send these paid, isolated API requests? [y/N] ").strip().lower()
        if answer not in {"y", "yes"}:
            print("cancelled; no API request was sent")
            return 1

    try:
        run_id, manifest = execute(
            tasks=tasks,
            models=models,
            samples=args.samples,
            api_workers=args.api_workers,
            max_output_tokens=args.max_output_tokens,
            max_spend=args.max_spend,
            smoke=args.smoke,
            ppa=args.ppa,
            run_id=args.resume,
            transport=args.transport,
        )
    except (ProviderError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print(f"\nrun: {run_id}")
    print(f"manifest: {ARTIFACT_ROOT / run_id / 'manifest.json'}")
    if args.transport == "api":
        print(f"estimated API cost: ${manifest.get('estimated_cost_usd', 0.0):.4f}")
    else:
        print("incremental API cost: $0 (subscription quota)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
