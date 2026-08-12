"""
OpenRouter client for sampling candidate implementations.

Standard library only. The volume here is small -- a few hundred completions per
sweep -- so there is no job queue, no caching layer, and no async framework. A
thread pool and a JSONL file are the right size for this.

Two things matter for reproducibility and are therefore not optional:

  * Provider pinning. By default OpenRouter may route the same model name to
    different backends at different quantizations, which injects variance into
    results that look like model differences. `allow_fallbacks` is forced off
    whenever an explicit provider order is given.
  * Full provenance. Model string, resolved provider, temperature, token usage
    and the raw completion are all recorded, so rows from today still mean
    something when re-run against new models months from now.
"""

from __future__ import annotations

import http.client
import json
import os
import random
import socket
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field, asdict

API_URL = "https://openrouter.ai/api/v1/chat/completions"
MODELS_URL = "https://openrouter.ai/api/v1/models"

RETRY_STATUS = {408, 409, 429, 500, 502, 503, 504}


class GenerationError(RuntimeError):
    pass


@dataclass
class Completion:
    model: str
    provider: str | None
    text: str
    prompt_tokens: int | None = None
    completion_tokens: int | None = None
    cost_usd: float | None = None
    latency_s: float = 0.0
    temperature: float = 1.0
    seed: int | None = None
    error: str | None = None
    raw_id: str | None = None
    extra: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return asdict(self)


def api_key() -> str:
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        raise GenerationError(
            "OPENROUTER_API_KEY is not set. Get a key at openrouter.ai/keys and "
            "export it; it is read from the environment and never stored here."
        )
    return key


def _post(payload: dict, timeout_s: int, key: str) -> dict:
    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        API_URL,
        data=body,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            # OpenRouter uses these for attribution on its dashboard.
            "HTTP-Referer": "https://github.com/local/HW-RL-Environments",
            "X-Title": "HW-RL-Environments",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout_s) as resp:
        return json.loads(resp.read().decode())


def complete(
    prompt: str,
    model: str,
    *,
    temperature: float = 1.0,
    max_tokens: int = 8000,
    seed: int | None = None,
    providers: list[str] | None = None,
    system: str | None = None,
    reasoning: dict | None = None,
    timeout_s: int = 600,
    max_retries: int = 4,
) -> Completion:
    """
    One completion. Never raises on an API failure -- the error is recorded in
    the returned Completion so a single bad row cannot abort a long sweep.
    """
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})

    payload: dict = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
        "usage": {"include": True},
    }
    if seed is not None:
        payload["seed"] = seed
    if reasoning:
        # max_tokens is the TOTAL completion budget and reasoning is billed
        # against it. A model that thinks past the ceiling returns
        # finish_reason="length" with content="" -- no answer at all. Capping
        # the thinking budget reserves room for the module itself.
        payload["reasoning"] = reasoning
    if providers:
        # Pinning the backend is the whole point; falling back would silently
        # undo it and reintroduce the variance we are trying to remove.
        payload["provider"] = {"order": providers, "allow_fallbacks": False}

    key = api_key()
    started = time.monotonic()
    last_err = ""

    for attempt in range(max_retries + 1):
        try:
            data = _post(payload, timeout_s, key)
            choice = (data.get("choices") or [{}])[0]
            message = choice.get("message") or {}
            text = message.get("content") or ""
            usage = data.get("usage") or {}
            details = usage.get("completion_tokens_details") or {}
            return Completion(
                model=model,
                provider=data.get("provider"),
                text=text,
                prompt_tokens=usage.get("prompt_tokens"),
                completion_tokens=usage.get("completion_tokens"),
                cost_usd=usage.get("cost"),
                latency_s=time.monotonic() - started,
                temperature=temperature,
                seed=seed,
                raw_id=data.get("id"),
                # finish_reason and the reasoning-token count are what separate
                # "answered badly" from "never answered". Without them an empty
                # response is indistinguishable from a model that replied with
                # prose, and the two need opposite fixes.
                extra={
                    "finish_reason": choice.get("finish_reason"),
                    "native_finish_reason": choice.get("native_finish_reason"),
                    "reasoning_tokens": details.get("reasoning_tokens"),
                    "reasoning_chars": len(message.get("reasoning") or ""),
                },
            )
        except urllib.error.HTTPError as exc:
            detail = ""
            try:
                detail = exc.read().decode()[:400]
            except Exception:
                pass
            last_err = f"HTTP {exc.code}: {detail}"
            if exc.code not in RETRY_STATUS or attempt == max_retries:
                break
        # Everything below the HTTP status layer: a connection dropped
        # mid-body, a truncated chunked response, a DNS blip, a malformed
        # payload. http.client.IncompleteRead is the one that actually bit --
        # it is not a URLError subclass, so it escaped this handler entirely
        # and killed a sample that a single retry would have recovered.
        except (urllib.error.URLError, http.client.HTTPException, socket.timeout,
                ConnectionError, TimeoutError, json.JSONDecodeError) as exc:
            last_err = f"{type(exc).__name__}: {exc}"
            if attempt == max_retries:
                break
        # Exponential backoff with jitter; rate limits are the common case and
        # they clear on their own.
        time.sleep(min(2 ** attempt + random.random(), 30))

    return Completion(
        model=model,
        provider=None,
        text="",
        latency_s=time.monotonic() - started,
        temperature=temperature,
        seed=seed,
        error=last_err or "unknown error",
    )


def list_models(timeout_s: int = 60) -> list[dict]:
    """Fetch OpenRouter's catalogue -- use it to confirm a model id before a sweep."""
    req = urllib.request.Request(MODELS_URL, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout_s) as resp:
        return json.loads(resp.read().decode()).get("data", [])
