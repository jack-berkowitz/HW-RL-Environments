"""Stateless direct OpenAI and Anthropic text generation.

The payload constructors are intentionally small and testable. A benchmark
request contains one user message with the canonical prompt, and no system
message, conversation identifier, tool, file, retrieval source, or memory.
"""

from __future__ import annotations

import json
import os
import random
import socket
import time
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass, field

from .direct_models import DirectModel

OPENAI_URL = "https://api.openai.com/v1/responses"
ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
RETRY_STATUS = {408, 409, 429, 500, 502, 503, 504}


class ProviderError(RuntimeError):
    pass


@dataclass
class Generation:
    provider: str
    requested_model: str
    resolved_model: str | None
    text: str
    input_tokens: int | None = None
    output_tokens: int | None = None
    estimated_cost_usd: float | None = None
    latency_s: float = 0.0
    finish_reason: str | None = None
    request_id: str | None = None
    error: str | None = None
    raw: dict = field(default_factory=dict)

    def to_dict(self, include_raw: bool = True) -> dict:
        data = asdict(self)
        if not include_raw:
            data.pop("raw", None)
        return data

    @property
    def truncated(self) -> bool:
        return self.finish_reason in {
            "length", "max_tokens", "max_output_tokens", "incomplete",
        }


def openai_payload(prompt: str, model: DirectModel, max_output_tokens: int) -> dict:
    return {
        "model": model.model_id,
        "input": [{
            "role": "user",
            "content": [{"type": "input_text", "text": prompt}],
        }],
        "max_output_tokens": max_output_tokens,
        "store": False,
        "service_tier": "default",
    }


def anthropic_payload(prompt: str, model: DirectModel, max_output_tokens: int) -> dict:
    return {
        "model": model.model_id,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_output_tokens,
    }


def api_key(provider: str) -> str:
    try:
        env_name = {
            "openai": "OPENAI_API_KEY",
            "anthropic": "ANTHROPIC_API_KEY",
        }[provider]
    except KeyError as exc:
        raise ProviderError(
            f"direct API transport does not support provider {provider!r}"
        ) from exc
    key = os.environ.get(env_name)
    if not key:
        raise ProviderError(
            f"{env_name} is not set; use an API key, never a consumer login or cookie"
        )
    return key


def _post_json(
    url: str,
    payload: dict,
    headers: dict[str, str],
    timeout_s: int,
) -> dict:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", **headers},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout_s) as response:
        return json.loads(response.read().decode("utf-8"))


def _openai_text(data: dict) -> str:
    if isinstance(data.get("output_text"), str):
        return data["output_text"]
    parts: list[str] = []
    for item in data.get("output") or []:
        if item.get("type") == "output_text" and isinstance(item.get("text"), str):
            parts.append(item["text"])
        for content in item.get("content") or []:
            if content.get("type") in {"output_text", "text"}:
                text = content.get("text")
                if isinstance(text, str):
                    parts.append(text)
    return "".join(parts)


def _anthropic_text(data: dict) -> str:
    return "".join(
        block.get("text", "")
        for block in data.get("content") or []
        if block.get("type") == "text" and isinstance(block.get("text"), str)
    )

def _finish_reason(provider: str, data: dict) -> str | None:
    if provider == "anthropic":
        return data.get("stop_reason")
    status = data.get("status")
    if status == "completed":
        return "stop"
    if status == "incomplete":
        details = data.get("incomplete_details") or {}
        return details.get("reason") or "incomplete"
    return status


def complete(
    prompt: str,
    model: DirectModel,
    *,
    max_output_tokens: int | None = None,
    timeout_s: int = 600,
    max_retries: int = 4,
) -> Generation:
    """Make one isolated request; API failures are returned, never disguised."""
    ceiling = max_output_tokens or model.max_output_tokens
    if ceiling <= 0:
        raise ValueError("max_output_tokens must be positive")

    if model.provider == "openai":
        url = OPENAI_URL
        payload = openai_payload(prompt, model, ceiling)
        headers = {"Authorization": f"Bearer {api_key(model.provider)}"}
    elif model.provider == "anthropic":
        url = ANTHROPIC_URL
        payload = anthropic_payload(prompt, model, ceiling)
        headers = {
            "x-api-key": api_key(model.provider),
            "anthropic-version": "2023-06-01",
        }
    else:
        raise ProviderError(f"unsupported provider: {model.provider}")

    started = time.monotonic()
    last_error = ""
    data: dict | None = None
    for attempt in range(max_retries + 1):
        try:
            data = _post_json(url, payload, headers, timeout_s)
            break
        except urllib.error.HTTPError as exc:
            detail = ""
            try:
                detail = exc.read().decode("utf-8", "replace")[:500]
            except Exception:
                pass
            last_error = f"HTTP {exc.code}: {detail}"
            if exc.code not in RETRY_STATUS or attempt == max_retries:
                break
        except (
            urllib.error.URLError, socket.timeout, ConnectionError,
            TimeoutError, json.JSONDecodeError,
        ) as exc:
            last_error = f"{type(exc).__name__}: {exc}"
            if attempt == max_retries:
                break
        time.sleep(min(2 ** attempt + random.random(), 30))

    elapsed = time.monotonic() - started
    if data is None:
        return Generation(
            provider=model.provider,
            requested_model=model.model_id,
            resolved_model=None,
            text="",
            latency_s=elapsed,
            error=last_error or "unknown provider error",
        )

    if data.get("error"):
        error = data["error"]
        detail = error.get("message") if isinstance(error, dict) else str(error)
        return Generation(
            provider=model.provider,
            requested_model=model.model_id,
            resolved_model=data.get("model"),
            text="",
            latency_s=elapsed,
            request_id=data.get("id"),
            error=detail,
            raw=data,
        )

    usage = data.get("usage") or {}
    if model.provider == "openai":
        input_tokens = usage.get("input_tokens")
        output_tokens = usage.get("output_tokens")
        text = _openai_text(data)
    else:
        input_tokens = usage.get("input_tokens")
        output_tokens = usage.get("output_tokens")
        text = _anthropic_text(data)

    cost = None
    if isinstance(input_tokens, int) and isinstance(output_tokens, int):
        cost = model.estimate(input_tokens, output_tokens)
    return Generation(
        provider=model.provider,
        requested_model=model.model_id,
        resolved_model=data.get("model"),
        text=text,
        input_tokens=input_tokens,
        output_tokens=output_tokens,
        estimated_cost_usd=cost,
        latency_s=elapsed,
        finish_reason=_finish_reason(model.provider, data),
        request_id=data.get("id"),
        raw=data,
    )
