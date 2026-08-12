"""
End-to-end evaluation: spec in, model samples, graded rows out.

    python3 -m runner.evaluate -k 5                    # the whole roster
    python3 -m runner.evaluate --models opus-5 --modules fifo -k 1
    python3 -m runner.evaluate --tier open -k 5
    python3 -m runner.evaluate --summarize results/eval.jsonl

The model sees the interface file and nothing else; the testbench, the reference
solutions and this file are all on the other side of the wall. What comes back is
screened for attempts to forge a verdict (see score.check_candidate_source) and
then graded by simulation. Nothing a model returns can talk its way to a pass.

One row per sample, appended to a JSONL file as it completes, so a sweep that
dies partway through keeps everything it already paid for -- and re-running the
same command resumes rather than re-paying.

The headline metric is pass@k over the parameter sweep -- a candidate counts as
correct only if it passes EVERY configuration, which is what separates "wrote a
FIFO" from "wrote a 16-deep 32-bit FIFO".
"""

from __future__ import annotations

import argparse
import json
import math
import os
import random
import sys
import threading
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

from .config import ALL_MODULES, TASKS
from .extract import build_prompt, extract_module
from .generate import Completion, GenerationError, complete
from .models import Model, pricing, select
from .score import DEFAULT_SIMULATOR, Outcome, score_sweep

_write_lock = threading.Lock()

# Outcomes that carry no information about the model and are re-run on resume.
RETRYABLE = {Outcome.API_ERROR.value, Outcome.HARNESS_ERROR.value,
             Outcome.TRUNCATED.value}


class SpendGuard:
    """
    A hard ceiling on what a sweep may spend.

    Necessary because the completion budget is generous by design: a model that
    reasons to the ceiling on every sample costs an order of magnitude more than
    one that answers in 2k tokens, and that is not knowable in advance. Samples
    are skipped rather than failed once the limit is hit, so a stopped sweep
    resumes cleanly after the limit is raised.
    """

    def __init__(self, limit_usd: float | None):
        self.limit = limit_usd
        self.spent = 0.0
        self._lock = threading.Lock()
        self.stopped = False

    def charge(self, amount: float | None) -> None:
        if not amount:
            return
        with self._lock:
            self.spent += amount
            if self.limit is not None and self.spent >= self.limit and not self.stopped:
                self.stopped = True
                print(f"\n*** spend limit reached: ${self.spent:.2f} of "
                      f"${self.limit:.2f} -- skipping remaining samples ***\n")

    def exhausted(self) -> bool:
        return self.stopped


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def evaluate_one(
    module: str,
    model: Model,
    sample_idx: int,
    *,
    temperature: float,
    max_tokens: int | None,
    providers: list[str] | None,
    seed: int | None,
    full_sweep: bool,
    simulator: str,
    sim_slots: threading.Semaphore,
    guard: SpendGuard,
) -> dict | None:
    """
    Generate one candidate and grade it. Returns a JSONL-ready row, or None if
    the spend limit was reached before this sample started.
    """
    if guard.exhausted():
        return None

    task = TASKS[module]
    prompt = build_prompt(module, task.iface.read_text())

    comp: Completion = complete(
        prompt,
        model.slug,
        temperature=model.temperature if model.temperature is not None else temperature,
        max_tokens=max_tokens if max_tokens is not None else model.max_tokens,
        seed=seed,
        providers=providers or (list(model.providers) or None),
        reasoning=model.reasoning,
    )

    row: dict = {
        "timestamp": _now(),
        "module": module,
        "tier": task.tier,
        "model": model.slug,
        "model_label": model.label,
        "model_tier": model.tier,
        "provider": comp.provider,
        "sample_idx": sample_idx,
        "temperature": comp.temperature,
        "seed": seed,
        "simulator": simulator,
        "prompt_tokens": comp.prompt_tokens,
        "completion_tokens": comp.completion_tokens,
        "cost_usd": comp.cost_usd,
        "latency_s": round(comp.latency_s, 2),
        "response": comp.text,
    }

    guard.charge(comp.cost_usd)

    finish = (comp.extra or {}).get("finish_reason")
    reasoning_tokens = (comp.extra or {}).get("reasoning_tokens")
    row["finish_reason"] = finish
    row["reasoning_tokens"] = reasoning_tokens

    if comp.error:
        row.update(outcome=Outcome.API_ERROR.value, detail=comp.error,
                   configs=[], functionally_correct=False, gradeable=False)
        return row

    # finish_reason == "error" is an upstream failure, not an answer: the
    # provider gave up mid-generation and returned an empty message. It arrives
    # with HTTP 200 and no `error` field, so it looks like a successful call --
    # which meant it was falling through to no_code and being counted as a
    # failed design. It is an API failure and must be excluded and retried.
    if finish == "error":
        row.update(outcome=Outcome.API_ERROR.value,
                   detail=f"provider returned finish_reason=error after "
                          f"{comp.completion_tokens} tokens with no content",
                   configs=[], functionally_correct=False, gradeable=False)
        return row

    # Any answer that stopped because it ran out of budget is not gradeable,
    # whether it came back empty or half-written.
    #
    # The half-written case is the subtle one and it was silently corrupting
    # results: a module cut off mid-line still extracts cleanly and then fails
    # to compile, so it scored compile_error -- indistinguishable from a model
    # that wrote genuinely broken RTL. finish_reason is the only reliable
    # signal, so it decides this before the source is ever looked at.
    if finish == "length":
        empty = not comp.text.strip()
        row.update(outcome=Outcome.TRUNCATED.value,
                   detail=("no content; " if empty else "answer cut off; ")
                          + f"{comp.completion_tokens} tokens hit the ceiling"
                          + (f" ({reasoning_tokens} reasoning)"
                             if reasoning_tokens else ""),
                   configs=[], functionally_correct=False, gradeable=False)
        return row

    source = extract_module(comp.text, module)
    if source is None:
        row.update(outcome=Outcome.NO_CODE.value,
                   detail="no extractable module in response",
                   configs=[], functionally_correct=False, gradeable=True)
        return row

    row["source"] = source
    configs = task.configs if full_sweep else [task.smoke()]
    # Grading is CPU-bound and can run for minutes; the API call it follows is
    # neither. Holding a separate, smaller pool of simulation slots keeps a wide
    # HTTP fan-out from turning into an equally wide fan-out of vvp processes.
    with sim_slots:
        results = score_sweep(module, source, configs=configs,
                              simulator=simulator, stop_on_fail=True)

    graded = [r for r in results if r.gradeable]
    correct = bool(graded) and all(r.functionally_correct for r in graded)
    # The reported outcome is the first genuine failure, or PASS if none.
    failing = next((r for r in graded if not r.functionally_correct), None)
    head = failing or (graded[-1] if graded else results[-1])

    row.update(
        outcome=head.outcome.value,
        detail=head.detail,
        functionally_correct=correct,
        gradeable=bool(graded),
        configs_run=len(results),
        configs=[{"config": r.config, "outcome": r.outcome.value,
                  "detail": r.detail, "seconds": round(r.seconds, 2)}
                 for r in results],
        grading_seconds=round(sum(r.seconds for r in results), 2),
    )
    return row


def completed_samples(out_path: Path) -> set[tuple[str, str, int]]:
    """
    (model, module, sample_idx) triples already graded in an existing run.

    Only rows that actually produced a verdict count. An api_error row cost
    nothing and told us nothing, so it is left to be retried -- which matters,
    since a sweep interrupted by rate limits or exhausted credit is exactly the
    case this exists for. A truncated row is retried for the same reason: the
    model never submitted a design, so there is nothing there to keep.
    """
    if not out_path.is_file():
        return set()
    done: set[tuple[str, str, int]] = set()
    for line in out_path.read_text().splitlines():
        if not line.strip():
            continue
        try:
            r = json.loads(line)
        except json.JSONDecodeError:
            continue  # a row torn by a kill mid-write; it will be regenerated
        if r.get("outcome") in RETRYABLE:
            continue
        if r.get("model") and r.get("module") and r.get("sample_idx") is not None:
            done.add((r["model"], r["module"], r["sample_idx"]))
    return done


def estimate_cost(models: list[Model], modules: list[str], k: int) -> float | None:
    """
    Rough spend for a sweep, from live catalog pricing.

    Deliberately approximate -- it exists to catch an order-of-magnitude
    surprise before it happens, not to bill anyone.
    """
    prices = pricing([m.slug for m in models])
    if not prices:
        return None
    # Specs run 100-190 lines; answers run 100-600 lines plus reasoning.
    in_tokens = 3_000
    total = 0.0
    for m in models:
        p_in, p_out = prices.get(m.slug, (0.0, 0.0))
        out_tokens = min(m.max_tokens, 8_000)
        total += len(modules) * k * (in_tokens * p_in + out_tokens * p_out)
    return total


def run(
    models: list[Model],
    modules: list[str],
    *,
    k: int,
    temperature: float,
    max_tokens: int | None,
    providers: list[str] | None,
    out_path: Path,
    api_workers: int,
    sim_workers: int,
    full_sweep: bool,
    base_seed: int | None,
    simulator: str,
    resume: bool = True,
    max_spend: float | None = None,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)

    jobs = [(mod, m, i) for m in models for mod in modules for i in range(k)]
    planned = len(jobs)

    already = completed_samples(out_path) if resume else set()
    if already:
        jobs = [j for j in jobs if (j[1].slug, j[0], j[2]) not in already]

    random.shuffle(jobs)  # spread load across providers rather than hammering one
    total = len(jobs)

    print(f"{planned} samples: {len(models)} models x {len(modules)} modules x k={k}")
    if already:
        print(f"resuming: {planned - total} already graded, {total} to run")
    est = estimate_cost(models, modules, k) if total else 0.0
    if est:
        print(f"rough estimate: ${est * (total / planned if planned else 0):.2f}")
    print(f"simulator={simulator}  api_workers={api_workers}  sim_workers={sim_workers}")
    print(f"writing -> {out_path}")
    if not total:
        print("nothing to do")
        return

    if max_spend is not None:
        print(f"spend limit: ${max_spend:.2f}")
    guard = SpendGuard(max_spend)
    sim_slots = threading.Semaphore(sim_workers)
    done = skipped = 0
    with out_path.open("a") as fh, ThreadPoolExecutor(max_workers=api_workers) as pool:
        futures = {
            pool.submit(
                evaluate_one, module, model, idx,
                temperature=temperature, max_tokens=max_tokens,
                providers=providers,
                seed=None if base_seed is None else base_seed + idx,
                full_sweep=full_sweep,
                simulator=simulator,
                sim_slots=sim_slots,
                guard=guard,
            ): (module, model, idx)
            for (module, model, idx) in jobs
        }
        for fut in as_completed(futures):
            module, model, idx = futures[fut]
            try:
                row = fut.result()
                if row is None:  # skipped by the spend guard
                    skipped += 1
                    continue
            except Exception as exc:  # never let one sample kill the sweep
                row = {"timestamp": _now(), "module": module, "model": model.slug,
                       "model_label": model.label,
                       "sample_idx": idx, "outcome": Outcome.HARNESS_ERROR.value,
                       "detail": f"{type(exc).__name__}: {exc}",
                       "functionally_correct": False, "gradeable": False}
            with _write_lock:
                fh.write(json.dumps(row) + "\n")
                fh.flush()
            done += 1
            mark = "PASS" if row.get("functionally_correct") else row.get("outcome", "?")
            print(f"[{done:4d}/{total}] {model.label:20s} {module:11s} "
                  f"#{idx:<3d} {mark}  (${guard.spent:.2f})", flush=True)

    if skipped:
        print(f"\n{skipped} sample(s) skipped by the spend limit; "
              f"re-run with a higher --max-spend to finish them")


# -----------------------------------------------------------------------------
# Reporting
# -----------------------------------------------------------------------------

def pass_at_k(n: int, c: int, k: int) -> float:
    """
    Unbiased pass@k estimator (Chen et al. 2021).

    The naive "did any of my k samples pass" is biased when n != k; this is the
    expected value over all size-k subsets of the n samples drawn.
    """
    if n - c < k:
        return 1.0
    return 1.0 - math.prod((n - c - i) / (n - i) for i in range(k))


def _label(r: dict) -> str:
    return r.get("model_label") or r.get("model", "?")


def _rate(rows: list[dict], k: int) -> tuple[float | None, int, int]:
    gradeable = [r for r in rows if r.get("gradeable")]
    n = len(gradeable)
    c = sum(1 for r in gradeable if r.get("functionally_correct"))
    return (pass_at_k(n, c, k) if n >= k else None), n, c


def summarize(path: Path, ks: list[int]) -> None:
    rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    if not rows:
        print("no rows")
        return

    modules = sorted({r["module"] for r in rows},
                     key=lambda m: (TASKS[m].tier if m in TASKS else "", m))
    by_model_module: dict[tuple[str, str], list[dict]] = defaultdict(list)
    by_model: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        by_model_module[(_label(r), r["module"])].append(r)
        by_model[_label(r)].append(r)

    headline = max(ks)
    print(f"\n{len(rows)} samples from {path}")
    print(f"per-module pass@{headline} (a candidate must pass every configuration)\n")

    head = f"{'model':20s}" + "".join(f"{m[:10]:>11s}" for m in modules) + f"{'overall':>11s}"
    print(head)
    print("-" * len(head))
    for model in sorted(by_model):
        line = f"{model:20s}"
        for mod in modules:
            rate, n, _ = _rate(by_model_module.get((model, mod), []), headline)
            line += f"{rate*100:10.0f}%" if rate is not None else f"{'-':>11s}"
        rate, n, c = _rate(by_model[model], headline)
        line += f"{c/n*100:10.0f}%" if n else f"{'-':>11s}"
        print(line)

    # pass@k across the ks asked for, per model, over everything it attempted.
    print(f"\noverall pass@k")
    head = f"{'model':20s} {'n':>5s} {'ok':>5s}" + "".join(
        f" {'pass@'+str(k):>8s}" for k in ks)
    print(head)
    print("-" * len(head))
    for model in sorted(by_model):
        _, n, c = _rate(by_model[model], 1)
        line = f"{model:20s} {n:5d} {c:5d}"
        for k in ks:
            # pass@k is per-problem; average the per-module estimates.
            per = [_rate(by_model_module[(model, m)], k)[0] for m in modules
                   if (model, m) in by_model_module]
            per = [x for x in per if x is not None]
            line += f" {sum(per)/len(per)*100:7.1f}%" if per else f" {'-':>8s}"
        print(line)

    # The failure taxonomy is the part that tells you what to fix.
    print("\nfailure taxonomy")
    print("-" * 44)
    tally: dict[str, int] = defaultdict(int)
    for r in rows:
        tally[r.get("outcome", "?")] += 1
    for outcome, count in sorted(tally.items(), key=lambda kv: -kv[1]):
        print(f"  {outcome:16s} {count:5d}  {count/len(rows)*100:5.1f}%")

    # Cheating is not a failure mode like the others -- it is a claim that the
    # numbers above are not measuring what they say. Call it out by name.
    cheats = [r for r in rows if r.get("outcome") == Outcome.CHEAT.value]
    if cheats:
        print(f"\n{len(cheats)} candidate(s) tried to forge a verdict:")
        seen: set[tuple[str, str]] = set()
        for r in cheats:
            key = (_label(r), r["module"])
            if key in seen:
                continue
            seen.add(key)
            print(f"  {_label(r):20s} {r['module']:11s} {r.get('detail', '')}")

    cost = sum(r.get("cost_usd") or 0.0 for r in rows)
    if cost:
        print(f"\ntotal cost: ${cost:.2f}")


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="runner.evaluate")
    p.add_argument("--summarize", type=Path, help="report on an existing JSONL and exit")
    p.add_argument("--ks", default="1,3", help="k values for pass@k in the report")
    p.add_argument("--models", default="",
                   help="filter the roster in runner/models.py, by label or slug")
    p.add_argument("--tier", choices=["frontier", "open"], default=None,
                   help="filter the roster by model tier")
    p.add_argument("--modules", default=",".join(ALL_MODULES))
    p.add_argument("-k", "--samples", type=int, default=3)
    p.add_argument("--temperature", type=float, default=1.0)
    p.add_argument("--max-tokens", type=int, default=None,
                   help="override every model's own budget")
    p.add_argument("--providers", default="", help="pin backends, comma-separated")
    p.add_argument("--api-workers", type=int, default=8,
                   help="concurrent OpenRouter requests")
    p.add_argument("--sim-workers", type=int, default=max(1, (os.cpu_count() or 4) // 2),
                   help="concurrent simulations; each can run for minutes")
    p.add_argument("--simulator", default=DEFAULT_SIMULATOR,
                   choices=["verilator", "icarus"])
    p.add_argument("--out", type=Path, default=Path("results/eval.jsonl"))
    p.add_argument("--smoke", action="store_true",
                   help="grade only the default config instead of the full sweep")
    p.add_argument("--no-resume", action="store_true",
                   help="re-run samples already present in --out")
    p.add_argument("--max-spend", type=float, default=None,
                   help="stop the sweep once this many USD have been spent")
    p.add_argument("--dry-run", action="store_true",
                   help="show what would be run, and the estimated cost, then exit")
    p.add_argument("--seed", type=int, default=None)
    args = p.parse_args(argv)

    ks = [int(x) for x in args.ks.split(",") if x.strip()]

    if args.summarize:
        summarize(args.summarize, ks)
        return 0

    modules = [m.strip() for m in args.modules.split(",") if m.strip()]
    unknown = [m for m in modules if m not in TASKS]
    if unknown:
        p.error(f"unknown modules: {', '.join(unknown)}")

    names = [m.strip() for m in args.models.split(",") if m.strip()]
    try:
        models = select(names or None, args.tier)
    except KeyError as exc:
        p.error(str(exc))
    if not models:
        p.error("no models selected")

    if args.dry_run:
        already = set() if args.no_resume else completed_samples(args.out)
        todo = [(mod, m, i) for m in models for mod in modules
                for i in range(args.samples)
                if (m.slug, mod, i) not in already]
        est = estimate_cost(models, modules, args.samples)
        print(f"{len(models)} models x {len(modules)} modules x k={args.samples} "
              f"= {len(models) * len(modules) * args.samples} samples "
              f"({len(todo)} not yet graded)")
        for m in models:
            print(f"  {m.label:20s} {m.slug:38s} max_tokens={m.max_tokens}")
        if est is not None:
            print(f"\nrough estimate for a full sweep: ${est:.2f}")
        return 0

    try:
        run(
            models=models,
            modules=modules,
            k=args.samples,
            temperature=args.temperature,
            max_tokens=args.max_tokens,
            providers=[x.strip() for x in args.providers.split(",") if x.strip()] or None,
            out_path=args.out,
            api_workers=args.api_workers,
            sim_workers=args.sim_workers,
            full_sweep=not args.smoke,
            base_seed=args.seed,
            simulator=args.simulator,
            resume=not args.no_resume,
            max_spend=args.max_spend,
        )
    except GenerationError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    summarize(args.out, ks)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
