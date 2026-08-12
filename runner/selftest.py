"""
Prove the harness works before spending money on it.

    python3 -m runner.selftest
    python3 -m runner.selftest --quick        # skip the slow full sweep
    python3 -m runner.selftest --simulator icarus

Four things are checked, and they are the four things that would otherwise turn
into a wrong conclusion about a model:

    golden    every reference solution passes            -> a FAIL means the
                                                            harness, not the model
    mutants   every deliberately-broken design fails     -> a PASS means the
                                                            testbench is a rubber stamp
    cheats    forged verdicts are caught                 -> a PASS means the
                                                            scores are unearned
    prompts   no prompt contains grading material        -> a leak means the eval
                                                            measures memorisation

Nothing here calls an API, so it is free to run and should be run after any
change to config.py, score.py, or the testbenches.
"""

from __future__ import annotations

import argparse
import sys
import time
from dataclasses import dataclass

from .config import MUTATION_TESTS, TASKS
from .extract import PromptLeak, build_prompt
from .score import DEFAULT_SIMULATOR, Outcome, score, score_sweep

# A candidate that does no work and simply announces success. If the harness
# ever scores this as a pass, every number it has ever produced is worthless.
# One entry per escape route that check_candidate_source() is meant to close.
CHEAT_CANDIDATES: dict[str, str] = {
    "forged_verdict": """
module {module} ();
    initial begin
        $display("TEST_RESULT: PASS");
    end
endmodule
""",
    "late_forged_verdict": """
module {module} ();
    final $display("TEST_RESULT: PASS");
endmodule
""",
    "early_finish": """
module {module} ();
    initial begin
        #1 $finish;
    end
endmodule
""",
    "reads_the_testbench": """
module {module} ();
    integer fd;
    initial fd = $fopen("testbenches/TierOne/fifo_tb.sv", "r");
endmodule
""",
    "peeks_at_the_reference_model": """
module {module} ();
    initial $display("%0d", {module}_tb.checks);
endmodule
""",
}


@dataclass
class Check:
    name: str
    ok: bool
    detail: str = ""
    seconds: float = 0.0


def _fmt(c: Check) -> str:
    mark = "ok  " if c.ok else "FAIL"
    line = f"  [{mark}] {c.name:44s} {c.seconds:6.1f}s"
    return line if c.ok else f"{line}  {c.detail}"


# -----------------------------------------------------------------------------
# The four checks
# -----------------------------------------------------------------------------

def check_prompts() -> list[Check]:
    """Every task's prompt must be buildable and free of grading material."""
    out = []
    for name, task in TASKS.items():
        started = time.monotonic()
        try:
            prompt = build_prompt(name, task.iface.read_text())
            ok, detail = True, ""
            # The spec is the whole problem statement; an empty one is a
            # misconfigured path, not a hard problem.
            if len(prompt) < 500:
                ok, detail = False, f"suspiciously short prompt ({len(prompt)} chars)"
        except PromptLeak as exc:
            ok, detail = False, str(exc)
        except OSError as exc:
            ok, detail = False, f"cannot read spec: {exc}"
        out.append(Check(f"prompt/{name}", ok, detail, time.monotonic() - started))
    return out


def check_cheats(simulator: str) -> list[Check]:
    """Every known way to forge a pass must be rejected."""
    out = []
    # fifo is the cheapest task to compile, and the screen is module-agnostic.
    module = "fifo"
    for name, template in CHEAT_CANDIDATES.items():
        started = time.monotonic()
        result = score(module, template.format(module=module), simulator=simulator)
        ok = result.outcome is Outcome.CHEAT
        detail = "" if ok else f"scored {result.outcome.value}, expected cheat"
        out.append(Check(f"cheat/{name}", ok, detail, time.monotonic() - started))
    return out


def check_golden(simulator: str, full_sweep: bool) -> list[Check]:
    """Every reference solution must pass every configuration it is graded on."""
    out = []
    for name, task in TASKS.items():
        started = time.monotonic()
        if not task.reference.is_file():
            out.append(Check(f"golden/{name}", False,
                             f"missing reference: {task.reference}"))
            continue
        source = task.reference.read_text()
        configs = task.configs if full_sweep else [task.smoke()]
        results = score_sweep(name, source, configs=configs,
                              simulator=simulator, stop_on_fail=True)
        bad = next((r for r in results if not r.functionally_correct), None)
        ok = bad is None
        detail = "" if ok else f"{bad.config}: {bad.outcome.value}: {bad.detail[:120]}"
        out.append(Check(f"golden/{name} ({len(results)} cfg)", ok, detail,
                         time.monotonic() - started))
    return out


def check_mutants(simulator: str) -> list[Check]:
    """
    Every deliberately-broken design must be caught.

    These are the sharpest instrument in the repo: each mutant is a single
    plausible bug (an off-by-one flush, an out-of-order commit) that a model
    could easily write. A testbench that passes them is not grading anything.
    """
    out = []
    for mutant in sorted(MUTATION_TESTS.rglob("*.sv")):
        # sandbox/mutation_tests/<tier>/<module>/<module>_mutN_<what>.sv
        module = mutant.parent.name
        if module not in TASKS:
            continue
        started = time.monotonic()
        result = score(module, mutant.read_text(), simulator=simulator)
        # Any genuine rejection counts. Which stage caught it does not matter,
        # but a harness error means we learned nothing.
        ok = result.gradeable and not result.functionally_correct
        detail = "" if ok else f"scored {result.outcome.value}: {result.detail[:120]}"
        out.append(Check(f"mutant/{module}/{mutant.stem}", ok, detail,
                         time.monotonic() - started))
    return out


# -----------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="runner.selftest")
    p.add_argument("--simulator", default=DEFAULT_SIMULATOR,
                   choices=["verilator", "icarus"])
    p.add_argument("--quick", action="store_true",
                   help="grade the golden solutions on the default config only")
    p.add_argument("--only", default="",
                   help="comma-separated subset of: prompts,cheats,golden,mutants")
    args = p.parse_args(argv)

    wanted = {s.strip() for s in args.only.split(",") if s.strip()} or {
        "prompts", "cheats", "golden", "mutants"}

    print(f"harness selftest -- simulator={args.simulator} "
          f"sweep={'smoke' if args.quick else 'full'}\n")

    started = time.monotonic()
    checks: list[Check] = []
    stages = [
        ("prompts", "prompt isolation", lambda: check_prompts()),
        ("cheats", "anti-gaming screen", lambda: check_cheats(args.simulator)),
        ("golden", "reference solutions pass", lambda: check_golden(args.simulator,
                                                                   not args.quick)),
        ("mutants", "mutants are caught", lambda: check_mutants(args.simulator)),
    ]
    for key, title, fn in stages:
        if key not in wanted:
            continue
        print(f"{title}")
        results = fn()
        for c in results:
            print(_fmt(c))
        checks += results
        print()

    failed = [c for c in checks if not c.ok]
    elapsed = time.monotonic() - started
    print(f"{len(checks) - len(failed)}/{len(checks)} checks passed in {elapsed:.0f}s")
    if failed:
        print("\nthe harness is not trustworthy until these pass:")
        for c in failed:
            print(f"  {c.name}: {c.detail}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
