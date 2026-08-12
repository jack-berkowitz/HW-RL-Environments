"""
The model roster.

    python3 -m runner.models            # show the roster
    python3 -m runner.models --check    # validate every slug against OpenRouter

The set of models under evaluation lives here rather than in a command line, so
a sweep is reproducible from the repo and a change to the lineup shows up in a
diff. `runner.evaluate` takes filters over this list, never raw slugs.

Slugs were validated against https://openrouter.ai/api/v1/models; run --check
before a paid sweep, because a renamed model fails one sample at a time and
looks like a model that cannot write Verilog.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass

# Reasoning-heavy models spend a large fraction of their budget before emitting
# any RTL, and the TierTwo answers are 200-600 lines. 8000 tokens truncates them
# mid-module, which scores as a compile error and reads as a capability gap.
# max_tokens is the TOTAL completion budget and reasoning is billed against it.
# At 24000 this was the binding constraint, not the models: gemini-3.1-pro hit
# the ceiling on 8 of 16 samples, and a run that hits it either returns an empty
# message or a module cut off mid-line. Both were being scored as design
# failures.
#
# 40000 sits well clear of the worst legitimate observation (gemini used 23558
# tokens on bpred and passed) while staying inside every enabled model's output
# limit -- the smallest is gemini's 65536. Unused budget is not billed, so the
# cost of the headroom is only paid by samples that actually need it.
REASONING_BUDGET = 40000
STANDARD_BUDGET = 16000

# NOTE: OpenRouter's `reasoning: {"max_tokens": N}` was tried here and is NOT
# honoured by these backends -- with an 8000 cap set, qwen3.8-max still spent
# 23777 reasoning tokens, deepseek-v4-pro 24000, gemini-3.1-pro 23036. The
# parameter is accepted and silently ignored, so it is not a usable control and
# relying on it would just hide the problem. Headroom plus truncation detection
# is what actually works.


@dataclass(frozen=True)
class Model:
    slug: str                          # OpenRouter model id
    label: str                         # short name for tables and --models
    tier: str                          # "frontier" | "open"
    max_tokens: int = STANDARD_BUDGET
    temperature: float | None = None   # None -> the run-level default
    providers: tuple[str, ...] = ()    # pin backends when a model is flaky
    # Reasoning budget, passed through to OpenRouter's unified `reasoning`
    # parameter. Needed because max_tokens is the TOTAL completion budget and
    # thinking is billed against it: an uncapped reasoning model can spend the
    # entire window and return an empty message, which is not a design failure
    # but looks exactly like one until you read finish_reason.
    reasoning: dict | None = None
    enabled: bool = True
    note: str = ""


# The lineup is the latest flagship of each family. "Flagship" rather than
# literally-newest-tag is the consistent rule: Google shipped gemini-3.6-flash
# after 3.1-pro, and DeepSeek shipped v4-flash-0731 after v4-pro, but a Flash
# tier answers a different question than Opus does. Swap the commented slug in
# either entry to compare against the newer, smaller model instead.
MODELS: list[Model] = [
    # -- frontier ------------------------------------------------------------
    Model("anthropic/claude-opus-5", "opus-5", "frontier", REASONING_BUDGET),
    Model("openai/gpt-5.6-sol", "gpt-5.6-sol", "frontier", REASONING_BUDGET,
          note="sol is the top tier of the 5.6 family; luna/terra are cheaper"),
    Model("google/gemini-3.1-pro-preview", "gemini-3.1-pro", "frontier",
          REASONING_BUDGET,
          note="latest Pro; google/gemini-3.6-flash is newer but Flash tier"),
    Model("moonshotai/kimi-k3", "kimi-k3", "frontier", REASONING_BUDGET),

    # -- open weight ---------------------------------------------------------
    # DISABLED on cost, not on capability -- and the distinction matters.
    #
    # It reasons far longer than anything else here. On multiplier it converged
    # at 21115 reasoning tokens and PASSED, so it does terminate. But on bpred,
    # lsq, rob and uart it saturated a 40000 ceiling with reasoning and emitted
    # zero content (4 of 5 samples at 40000; 10 of 11 at 24000). Each of those
    # dead attempts costs ~$0.245 and ~16 minutes of wall clock.
    #
    # Whether a larger ceiling (80000+) would let it finish the hard specs is
    # UNTESTED. It may well be a budget problem rather than a capability one, so
    # do not read its absence from the results as a verdict on the model. Every
    # other model in the roster answered comfortably inside 40000.
    Model("qwen/qwen3.8-max", "qwen3.8-max", "open", REASONING_BUDGET,
          enabled=False),
    Model("deepseek/deepseek-v4-pro", "deepseek-v4-pro", "open", REASONING_BUDGET,
          note="latest Pro; deepseek-v4-flash-0731 is newer but Flash tier"),

    # -- bench, not in the current sweep -------------------------------------
    # Kept so the lineup can be widened without re-deriving slugs and budgets.
    Model("anthropic/claude-sonnet-5", "sonnet-5", "frontier", REASONING_BUDGET,
          enabled=False),
    Model("openai/gpt-5.4", "gpt-5.4", "frontier", REASONING_BUDGET, enabled=False),
    Model("x-ai/grok-4.5", "grok-4.5", "frontier", REASONING_BUDGET, enabled=False),
    Model("qwen/qwen3-coder-plus", "qwen3-coder-plus", "open", STANDARD_BUDGET,
          enabled=False,
          note="code-specialised; a useful contrast with the reasoning models"),
    Model("z-ai/glm-5.2", "glm-5.2", "open", REASONING_BUDGET, enabled=False),
    Model("mistralai/codestral-2508", "codestral", "open", STANDARD_BUDGET,
          enabled=False, note="small code model; the floor of the range"),
]

BY_LABEL = {m.label: m for m in MODELS}
BY_SLUG = {m.slug: m for m in MODELS}


def enabled_models() -> list[Model]:
    return [m for m in MODELS if m.enabled]


def resolve(names: list[str]) -> list[Model]:
    """
    Turn user-supplied names into Model records.

    Accepts either label or slug so that `--models opus-5` and
    `--models anthropic/claude-opus-5` both work. Unknown names raise rather
    than being silently passed through to the API: a typo that reaches
    OpenRouter costs a failed sample per module per k.
    """
    out, unknown = [], []
    for name in names:
        m = BY_LABEL.get(name) or BY_SLUG.get(name)
        if m is None:
            unknown.append(name)
        else:
            out.append(m)
    if unknown:
        known = ", ".join(sorted(BY_LABEL))
        raise KeyError(f"unknown model(s): {', '.join(unknown)}. known: {known}")
    return out


def select(names: list[str] | None = None, tier: str | None = None) -> list[Model]:
    """The models a run should cover: the enabled roster, optionally filtered."""
    chosen = resolve(names) if names else enabled_models()
    if tier:
        chosen = [m for m in chosen if m.tier == tier]
    return chosen


# -----------------------------------------------------------------------------
# Catalog validation
# -----------------------------------------------------------------------------

def check(models: list[Model] | None = None) -> int:
    """Validate every slug against the live catalog and print current pricing."""
    from .generate import list_models

    roster = models or MODELS
    try:
        catalog = {m["id"]: m for m in list_models()}
    except Exception as exc:
        print(f"could not reach the OpenRouter catalog: {exc}")
        return 2

    print(f"{'label':20s} {'slug':38s} {'tier':9s} "
          f"{'$/Min':>8s} {'$/Mout':>8s} {'ctx':>9s}  status")
    print("-" * 104)

    missing = []
    for m in roster:
        entry = catalog.get(m.slug)
        if entry is None:
            missing.append(m.slug)
            print(f"{m.label:20s} {m.slug:38s} {m.tier:9s} "
                  f"{'-':>8s} {'-':>8s} {'-':>9s}  NOT IN CATALOG")
            continue
        p = entry.get("pricing", {}) or {}
        pin = float(p.get("prompt") or 0) * 1e6
        pout = float(p.get("completion") or 0) * 1e6
        ctx = entry.get("context_length") or 0
        state = "ok" if m.enabled else "disabled"
        print(f"{m.label:20s} {m.slug:38s} {m.tier:9s} "
              f"{pin:8.2f} {pout:8.2f} {ctx:9,d}  {state}")

    if missing:
        print(f"\n{len(missing)} slug(s) not in the catalog: {', '.join(missing)}")
        return 1
    print(f"\nall {len(roster)} slugs resolve")
    return 0


def pricing(slugs: list[str]) -> dict[str, tuple[float, float]]:
    """{slug: ($/token in, $/token out)} from the live catalog; {} if offline."""
    from .generate import list_models

    try:
        catalog = {m["id"]: m for m in list_models()}
    except Exception:
        return {}
    out = {}
    for s in slugs:
        entry = catalog.get(s)
        if entry:
            p = entry.get("pricing", {}) or {}
            out[s] = (float(p.get("prompt") or 0), float(p.get("completion") or 0))
    return out


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="runner.models")
    p.add_argument("--check", action="store_true",
                   help="validate slugs against the live OpenRouter catalog")
    p.add_argument("--tier", choices=["frontier", "open"], default=None)
    args = p.parse_args(argv)

    roster = [m for m in MODELS if not args.tier or m.tier == args.tier]
    if args.check:
        return check(roster)

    for m in roster:
        flag = " " if m.enabled else "#"
        note = f"  -- {m.note}" if m.note else ""
        print(f"{flag} {m.label:20s} {m.slug:38s} {m.tier:9s} "
              f"max_tokens={m.max_tokens}{note}")
    print(f"\n{len(enabled_models())} of {len(MODELS)} enabled")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
