"""Provider-native model registry for the domain benchmark pipeline.

Unlike ``runner.models``, these are IDs accepted directly by OpenAI and
Anthropic.  Prices are estimates used for the local spend guard; provider
billing remains authoritative.  Keep the source URL and checked date beside a
price change so a historical sweep can explain the estimate it displayed.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class DirectModel:
    label: str
    provider: str
    model_id: str
    max_output_tokens: int = 40_000
    input_usd_per_mtok: float | None = None
    output_usd_per_mtok: float | None = None
    price_checked: str | None = None
    note: str = ""

    def estimate(self, input_tokens: int, output_tokens: int) -> float | None:
        if self.input_usd_per_mtok is None or self.output_usd_per_mtok is None:
            return None
        return (
            input_tokens * self.input_usd_per_mtok
            + output_tokens * self.output_usd_per_mtok
        ) / 1_000_000


# Checked 2026-08-23 against the provider model pages. These are ordinary
# synchronous text-token rates, not batch, cached-input, fast, or priority
# rates. The pipeline sends unique, uncached, standard-tier requests.
MODELS: tuple[DirectModel, ...] = (
    DirectModel(
        "gpt-5.6-sol", "openai", "gpt-5.6-sol", 40_000, 4.0, 20.0,
        "2026-08-23",
        "OpenAI flagship; provider default reasoning effort",
    ),
    DirectModel(
        "gpt-5.6-terra", "openai", "gpt-5.6-terra", 40_000, 2.0, 12.0,
        "2026-08-23",
        "lower-cost GPT-5.6 tier",
    ),
    DirectModel(
        "gpt-5.6-luna", "openai", "gpt-5.6-luna", 40_000, 0.2, 1.2,
        "2026-08-23",
        "cost-sensitive GPT-5.6 tier",
    ),
    DirectModel(
        "opus-5", "anthropic", "claude-opus-5", 40_000, 5.0, 25.0,
        "2026-08-23",
        "Anthropic flagship; provider default effort",
    ),
    DirectModel(
        "sonnet-5", "anthropic", "claude-sonnet-5", 40_000, 2.0, 10.0,
        "2026-08-23",
        "lower-cost Claude 5 tier",
    ),
)

BY_LABEL = {model.label: model for model in MODELS}
BY_PROVIDER_ID = {(model.provider, model.model_id): model for model in MODELS}


def resolve_model(name: str) -> DirectModel:
    """Resolve a friendly label or an explicit ``provider:model-id`` value."""
    if name in BY_LABEL:
        return BY_LABEL[name]
    if ":" not in name:
        known = ", ".join(BY_LABEL)
        raise ValueError(
            f"unknown model {name!r}; use a known label ({known}) or "
            "provider:model-id"
        )
    provider, model_id = name.split(":", 1)
    provider = provider.strip().lower()
    model_id = model_id.strip()
    if provider not in {"openai", "anthropic"} or not model_id:
        raise ValueError(
            f"invalid model {name!r}; expected openai:<id> or anthropic:<id>"
        )
    known = BY_PROVIDER_ID.get((provider, model_id))
    if known:
        return known
    # Explicit IDs are useful when a provider releases a new model before the
    # checked-in roster changes. Unknown prices stay unknown: silently applying
    # a nearby model's rate would make the spend guard dishonest.
    label = model_id.removeprefix("claude-") if provider == "anthropic" else model_id
    return DirectModel(label, provider, model_id)


def resolve_models(names: list[str]) -> list[DirectModel]:
    out = [resolve_model(name) for name in names]
    keys = [(model.provider, model.model_id) for model in out]
    if len(set(keys)) != len(keys):
        raise ValueError("the same provider model was selected more than once")
    return out
