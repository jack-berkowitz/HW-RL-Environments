"""Isolated generation through subscription-authenticated provider CLIs.

This transport consumes included Codex or Claude Code quota rather than API
credits.  Each request runs in a new empty directory with account and project
customizations disabled.  The canonical prompt is passed through stdin so it
does not appear in the process list.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import time
from pathlib import Path

from .direct_models import DirectModel
from .direct_providers import Generation, ProviderError


_BILLED_ENV = {
    "openai": ("OPENAI_API_KEY", "OPENAI_BASE_URL"),
    "anthropic": (
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_BASE_URL",
        "CLAUDE_CODE_USE_BEDROCK",
        "CLAUDE_CODE_USE_VERTEX",
        "CLAUDE_CODE_USE_FOUNDRY",
    ),
}


def subscription_environment(provider: str) -> dict[str, str]:
    """Return a child environment that cannot select API-key billing."""
    try:
        excluded = _BILLED_ENV[provider]
    except KeyError as exc:
        raise ProviderError(f"unsupported provider: {provider}") from exc
    environment = os.environ.copy()
    for name in excluded:
        environment.pop(name, None)
    return environment


def _executable(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise ProviderError(f"{name} CLI is not installed or not on PATH")
    return path


def ensure_subscription_auth(provider: str) -> None:
    """Refuse to run unless the CLI can confirm subscription authentication."""
    environment = subscription_environment(provider)
    if provider == "openai":
        command = [_executable("codex"), "login", "status"]
    elif provider == "anthropic":
        command = [_executable("claude"), "auth", "status"]
    else:
        raise ProviderError(f"unsupported provider: {provider}")

    try:
        result = subprocess.run(
            command,
            text=True,
            capture_output=True,
            check=False,
            timeout=30,
            env=environment,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise ProviderError(
            f"could not check {provider} subscription login: {exc}"
        ) from exc

    if provider == "openai":
        status = f"{result.stdout}\n{result.stderr}".lower()
        if result.returncode != 0 or "logged in using chatgpt" not in status:
            raise ProviderError(
                "Codex is not authenticated with ChatGPT; run `codex login`"
            )
        return

    try:
        status_data = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise ProviderError("Claude authentication status was not valid JSON") from exc
    subscription = status_data.get("subscriptionType")
    method = str(status_data.get("authMethod") or "").lower()
    if (
        result.returncode != 0
        or status_data.get("loggedIn") is not True
        or not subscription
        or "api" in method
    ):
        raise ProviderError(
            "Claude is not authenticated with a Claude subscription; "
            "unset ANTHROPIC_API_KEY and run `claude auth login`"
        )


def _codex_command(
    executable: str, model_id: str, workdir: Path, output_path: Path
) -> list[str]:
    return [
        executable,
        "exec",
        "--ephemeral",
        "--ignore-user-config",
        "--ignore-rules",
        "--skip-git-repo-check",
        "--sandbox",
        "read-only",
        "--color",
        "never",
        "--model",
        model_id,
        "--cd",
        str(workdir),
        "--output-last-message",
        str(output_path),
        "-",
    ]


def _claude_command(executable: str, model_id: str, mcp_path: Path) -> list[str]:
    return [
        executable,
        "-p",
        "--model",
        model_id,
        "--safe-mode",
        "--disable-slash-commands",
        "--no-session-persistence",
        "--fallback-model",
        "",
        "--tools",
        "",
        "--strict-mcp-config",
        "--mcp-config",
        str(mcp_path),
        "--system-prompt",
        "",
        "--output-format",
        "json",
    ]


def _usage(data: dict) -> tuple[int | None, int | None]:
    usage = data.get("usage") or {}
    input_tokens = usage.get("input_tokens")
    output_tokens = usage.get("output_tokens")
    if isinstance(input_tokens, int) and isinstance(output_tokens, int):
        cached = usage.get("cache_read_input_tokens") or 0
        created = usage.get("cache_creation_input_tokens") or 0
        if isinstance(cached, int) and isinstance(created, int):
            input_tokens += cached + created
        return input_tokens, output_tokens

    model_usage = data.get("modelUsage") or {}
    if isinstance(model_usage, dict):
        rows = [row for row in model_usage.values() if isinstance(row, dict)]
        inputs = [row.get("inputTokens") for row in rows]
        outputs = [row.get("outputTokens") for row in rows]
        if rows and all(isinstance(value, int) for value in inputs + outputs):
            return sum(inputs), sum(outputs)
    return None, None


def _reported_models(data: dict) -> list[str]:
    models: list[str] = []
    explicit = data.get("model")
    if isinstance(explicit, str):
        models.append(explicit)
    model_usage = data.get("modelUsage") or {}
    if isinstance(model_usage, dict):
        for model_id, row in model_usage.items():
            if isinstance(model_id, str):
                models.append(model_id)
            if isinstance(row, dict) and isinstance(row.get("canonicalModel"), str):
                models.append(row["canonicalModel"])
    return list(dict.fromkeys(models))


def _requested_model_was_used(requested: str, reported: list[str]) -> bool:
    return any(
        model == requested
        or model.startswith(f"{requested}-")
        or requested.startswith(f"{model}-")
        for model in reported
    )


def _codex_reported_model(stderr: str) -> str | None:
    match = re.search(r"^model:\s*(\S+)\s*$", stderr, re.MULTILINE)
    return match.group(1) if match else None


def _complete_once(
    prompt: str,
    model: DirectModel,
    *,
    max_output_tokens: int | None = None,
    timeout_s: int = 1800,
) -> Generation:
    """Run one fresh, non-persistent subscription CLI invocation."""
    del max_output_tokens  # Neither subscription CLI exposes a hard output-token cap.
    started = time.monotonic()
    environment = subscription_environment(model.provider)

    with tempfile.TemporaryDirectory(prefix="hwrl-subscription-") as temporary:
        workdir = Path(temporary)
        output_path = workdir / "last-message.txt"
        mcp_path = workdir / "mcp.json"
        mcp_path.write_text('{"mcpServers":{}}\n', encoding="utf-8")

        if model.provider == "openai":
            command = _codex_command(
                _executable("codex"), model.model_id, workdir, output_path
            )
        elif model.provider == "anthropic":
            command = _claude_command(_executable("claude"), model.model_id, mcp_path)
        else:
            raise ProviderError(f"unsupported provider: {model.provider}")

        try:
            result = subprocess.run(
                command,
                cwd=workdir,
                input=prompt,
                text=True,
                capture_output=True,
                check=False,
                timeout=timeout_s,
                env=environment,
            )
        except subprocess.TimeoutExpired:
            return Generation(
                provider=model.provider,
                requested_model=model.model_id,
                resolved_model=None,
                text="",
                latency_s=time.monotonic() - started,
                error=f"subscription CLI timed out after {timeout_s}s",
            )
        except OSError as exc:
            return Generation(
                provider=model.provider,
                requested_model=model.model_id,
                resolved_model=None,
                text="",
                latency_s=time.monotonic() - started,
                error=f"could not run subscription CLI: {exc}",
            )

        elapsed = time.monotonic() - started
        raw = {
            "transport": "subscription",
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
        }
        if result.returncode != 0:
            detail = (result.stderr or result.stdout).strip()[-1000:]
            return Generation(
                provider=model.provider,
                requested_model=model.model_id,
                resolved_model=None,
                text="",
                latency_s=elapsed,
                error=f"subscription CLI exited {result.returncode}: {detail}",
                raw=raw,
            )

        if model.provider == "openai":
            reported_model = _codex_reported_model(result.stderr)
            if reported_model is not None and reported_model != model.model_id:
                return Generation(
                    provider=model.provider,
                    requested_model=model.model_id,
                    resolved_model=reported_model,
                    text="",
                    latency_s=elapsed,
                    error=(
                        f"Codex used {reported_model!r} instead of selected "
                        f"model {model.model_id!r}"
                    ),
                    raw=raw,
                )
            try:
                text = output_path.read_text(encoding="utf-8")
            except FileNotFoundError:
                return Generation(
                    provider=model.provider,
                    requested_model=model.model_id,
                    resolved_model=model.model_id,
                    text="",
                    latency_s=elapsed,
                    error="Codex did not write a final message",
                    raw=raw,
                )
            return Generation(
                provider=model.provider,
                requested_model=model.model_id,
                resolved_model=reported_model or model.model_id,
                text=text,
                latency_s=elapsed,
                finish_reason="stop",
                raw=raw,
            )

        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            return Generation(
                provider=model.provider,
                requested_model=model.model_id,
                resolved_model=None,
                text="",
                latency_s=elapsed,
                error="Claude returned invalid JSON",
                raw=raw,
            )
        text = data.get("result")
        if not isinstance(text, str):
            return Generation(
                provider=model.provider,
                requested_model=model.model_id,
                resolved_model=data.get("model"),
                text="",
                latency_s=elapsed,
                error="Claude JSON did not contain a text result",
                raw=data,
            )
        reported_models = _reported_models(data)
        if reported_models and not _requested_model_was_used(
            model.model_id, reported_models
        ):
            return Generation(
                provider=model.provider,
                requested_model=model.model_id,
                resolved_model=None,
                text="",
                latency_s=elapsed,
                error=(
                    "Claude did not use the selected model; reported "
                    + ", ".join(reported_models)
                ),
                raw=data,
            )
        input_tokens, output_tokens = _usage(data)
        return Generation(
            provider=model.provider,
            requested_model=model.model_id,
            resolved_model=(
                model.model_id
                if _requested_model_was_used(model.model_id, reported_models)
                else data.get("model")
            ),
            text=text,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_s=elapsed,
            finish_reason="stop" if not data.get("is_error") else "error",
            error=str(data.get("error")) if data.get("is_error") else None,
            raw=data,
        )


def complete(
    prompt: str,
    model: DirectModel,
    *,
    max_output_tokens: int | None = None,
    timeout_s: int = 1800,
    max_retries: int = 2,
) -> Generation:
    """Retry temporary subscription-service failures in fresh sessions."""
    generation: Generation | None = None
    for attempt in range(max_retries + 1):
        generation = _complete_once(
            prompt,
            model,
            max_output_tokens=max_output_tokens,
            timeout_s=timeout_s,
        )
        error = (generation.error or "").lower()
        retryable = any(
            marker in error
            for marker in (" 429", " 529", "overloaded", "timed out", "timeout")
        )
        if not retryable or attempt == max_retries:
            return generation
        time.sleep(min(2 ** attempt, 4))
    assert generation is not None
    return generation
