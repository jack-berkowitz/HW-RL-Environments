#!/usr/bin/env python3
"""find_fmax.py -- find a module's maximum clock frequency by binary search
over REAL full ORFS place-and-route runs.

Every candidate period gets its own complete synth -> floorplan -> place -> CTS
-> route -> report run. This is deliberate and is the whole point of the script:
WNS measured under one period constraint does NOT reliably predict pass/fail at
a tighter one, because placement and sizing decisions are period-dependent. No
STA-only extrapolation, no slack subtraction from a single run.

Structure
    Phase 1  bracket   -- from a seed period, halve while passing / double while
                          failing until a [pass, fail] pair exists
    Phase 2  search    -- bisect that interval to --resolution-ns
    Phase 3  confirm   -- re-run the winner from a clean directory

Reuse
    The build itself is delegated to scripts/run_orfs_build.sh (wipe + docker +
    make) and every ORFS metric name is read through scripts/collect_results.py
    --json. This file knows nothing about ORFS metric names or docker flags, so
    there is exactly one place to fix if either changes.

The stale-results trap
    Make keys off file timestamps and does NOT treat a changed SDC constraint as
    a reason to rebuild, so a period change without a wipe silently reuses the
    previous run's results. Two defences, both mandatory:
      1. every iteration wipes results/logs/objects/reports first (WIPE_DESIGN)
      2. after every run the period ORFS actually recorded is compared against
         the period requested; a mismatch is a tool_error, not a data point
    Defence 2 exists because defence 1 failing silently is exactly the failure
    mode that produces a confident, wrong Fmax.

Usage
    scripts/find_fmax.py --design rob
    scripts/find_fmax.py --design lsq --seed-period-ns 8 --resolution-ns 0.02

On a native x86_64 host (e.g. WSL2) export these first:
    export ORFS_FLOW_DIR=/path/to/OpenROAD-flow-scripts/flow
    export DOCKER_PLATFORM_ARGS=""      # the Rosetta --platform flag is Mac-only
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = os.path.dirname(SCRIPT_DIR)

STATUS_PASS = "pass"
STATUS_TIMING = "timing_fail"
STATUS_DRC = "drc_fail"
STATUS_TOOL = "tool_error"


# ---------------------------------------------------------------------------
# design resolution
# ---------------------------------------------------------------------------
def resolve_design(design, pdk):
    """Locate the design's ORFS config and work out its tier, the same way
    build_and_score.sh does -- by probing both tier directories rather than
    trusting a hardcoded list."""
    hits = []
    for tier in ("TierOne", "TierTwo"):
        cfg = os.path.join(REPO_DIR, "orfs_configs", pdk, tier, design, "config.mk")
        if os.path.isfile(cfg):
            hits.append((tier, cfg))
    if not hits:
        sys.exit(
            f"ERROR: no ORFS config for '{design}' under "
            f"orfs_configs/{pdk}/{{TierOne,TierTwo}}/{design}/config.mk"
        )
    if len(hits) > 1:
        sys.exit(f"ERROR: '{design}' exists in more than one tier -- ambiguous")
    return hits[0]


def read_config_var(cfg_path, name):
    """Pull `export NAME = value` out of a config.mk."""
    pat = re.compile(rf"^\s*export\s+{re.escape(name)}\s*=\s*(.*?)\s*$", re.M)
    m = pat.search(open(cfg_path).read())
    return m.group(1) if m else None


def validate_inputs(args, cfg_path):
    """--pdk and --rtl are already determined by config.mk. Accept them for
    interface compatibility, but verify rather than silently ignore: a flag that
    quietly does nothing is worse than one that isn't there."""
    plat = read_config_var(cfg_path, "PLATFORM")
    if plat and plat != args.pdk:
        sys.exit(
            f"ERROR: --pdk {args.pdk} disagrees with {cfg_path}\n"
            f"       (that config sets PLATFORM = {plat})"
        )
    if args.rtl:
        vf = read_config_var(cfg_path, "VERILOG_FILES") or ""
        want = os.path.basename(args.rtl.rstrip("/"))
        if want and want not in vf:
            sys.exit(
                f"ERROR: --rtl {args.rtl} is not what this design builds.\n"
                f"       {cfg_path} sets VERILOG_FILES = {vf}\n"
                f"       Point config.mk at the RTL you mean, rather than "
                f"passing a path the flow will ignore."
            )


def git_commit():
    try:
        out = subprocess.run(
            ["git", "-C", REPO_DIR, "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=15,
        )
        if out.returncode != 0:
            return None
        sha = out.stdout.strip()
        dirty = subprocess.run(
            ["git", "-C", REPO_DIR, "status", "--porcelain"],
            capture_output=True, text=True, timeout=30,
        )
        if dirty.returncode == 0 and dirty.stdout.strip():
            return sha + "-dirty"
        return sha
    except (OSError, subprocess.SubprocessError):
        return None


# ---------------------------------------------------------------------------
# one P&R run
# ---------------------------------------------------------------------------
def collect(design):
    """Read this design's ORFS metrics through collect_results.py, which is the
    single place that knows ORFS metric names."""
    r = subprocess.run(
        [sys.executable, os.path.join(SCRIPT_DIR, "collect_results.py"), "--json", design],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        return None
    try:
        recs = json.loads(r.stdout)
    except json.JSONDecodeError:
        return None
    for rec in recs:
        if rec.get("design") == design:
            return rec
    return None


def run_period(design, tier, pdk, period, iteration, log_dir, verbose):
    """Wipe, build at `period`, and classify the outcome.

    Returns a trajectory record. Classification:
        nonzero exit                 -> tool_error   (a timing failure is NOT a
                                        build failure: ORFS completes the flow
                                        and simply reports negative slack)
        metrics missing / bad period -> tool_error
        drc > 0                      -> drc_fail     (a period that only routes
                                        with violations is not a real Fmax)
        wns < 0                      -> timing_fail
        otherwise                    -> pass
    """
    cfg_container = f"/work/orfs_configs/{pdk}/{tier}/{design}/config.mk"
    env = os.environ.copy()
    env["CLK_PERIOD_NS"] = f"{period:.4f}"
    env["WIPE_DESIGN"] = design
    env["PLATFORM"] = pdk

    log_path = os.path.join(log_dir, f"{design}_iter{iteration:02d}_{period:.4f}ns.log")
    t0 = time.time()
    with open(log_path, "w") as lf:
        proc = subprocess.run(
            [os.path.join(SCRIPT_DIR, "run_orfs_build.sh"), cfg_container],
            env=env,
            stdout=lf,
            stderr=subprocess.STDOUT,
        )
    wall = time.time() - t0

    rec = {
        "iteration": iteration,
        "period_ns": round(period, 4),
        "wns_ns": None,
        "tns_ns": None,
        "drc": None,
        "pass": False,
        "status": STATUS_TOOL,
        "wall_time_s": round(wall, 1),
        "log": os.path.relpath(log_path, REPO_DIR),
        "note": None,
    }

    if proc.returncode != 0:
        rec["note"] = f"run_orfs_build.sh exited {proc.returncode}; see {rec['log']}"
        return rec

    m = collect(design)
    if not m or not m.get("completed"):
        rec["note"] = "ORFS produced no final metrics (6_report.json missing)"
        return rec

    # Defence 2 against stale results: did the flow actually run at the period
    # we asked for? If the wipe silently failed, or the SDC override did not
    # take, this is where it shows up -- as a tool error rather than as a
    # confident data point at the wrong frequency.
    actual = m.get("period")
    if actual is None or abs(float(actual) - period) > 1e-3:
        rec["note"] = (
            f"STALE RESULTS: asked for {period:.4f} ns but ORFS recorded "
            f"{actual} ns. The wipe or the CLK_PERIOD_NS override did not take; "
            f"this run is not a valid data point."
        )
        return rec

    rec["wns_ns"] = m.get("wns")
    rec["tns_ns"] = m.get("tns")
    rec["drc"] = m.get("drc")

    if rec["drc"] is not None and rec["drc"] > 0:
        rec["status"] = STATUS_DRC
        rec["note"] = f"routed with {rec['drc']} DRC violations"
    elif rec["wns_ns"] is None:
        rec["note"] = "no WNS in the metrics"
    elif rec["wns_ns"] >= 0:
        rec["status"] = STATUS_PASS
        rec["pass"] = True
    else:
        rec["status"] = STATUS_TIMING

    if verbose:
        print(
            f"  iter {iteration:>2}  {period:7.4f} ns  ->  {rec['status']:<11}"
            f"  WNS {rec['wns_ns'] if rec['wns_ns'] is not None else float('nan'):>8}"
            f"  DRC {rec['drc']}  ({rec['wall_time_s']:.0f}s)"
        )
    return rec


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(
        description="Find a module's Fmax by binary search over full ORFS P&R runs.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--design", required=True)
    ap.add_argument("--rtl", default=None,
                    help="optional; validated against config.mk's VERILOG_FILES")
    ap.add_argument("--pdk", default="sky130hd")
    ap.add_argument("--seed-period-ns", type=float, default=10.0)
    ap.add_argument("--resolution-ns", type=float, default=0.05)
    ap.add_argument("--max-iterations", type=int, default=10)
    ap.add_argument("--max-bracket-iterations", type=int, default=6)
    ap.add_argument("--output-dir", default=os.path.join(REPO_DIR, "fmax_results"))
    ap.add_argument("--no-confirm", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--skip-sim-check", action="store_true",
                    help="skip the Verilator gate (it is cheap; skip only if "
                         "you have just run it yourself)")
    args = ap.parse_args()

    if args.seed_period_ns <= 0 or args.resolution_ns <= 0:
        sys.exit("ERROR: --seed-period-ns and --resolution-ns must be positive")

    tier, cfg_path = resolve_design(args.design, args.pdk)
    validate_inputs(args, cfg_path)

    os.makedirs(args.output_dir, exist_ok=True)
    log_dir = os.path.join(args.output_dir, f"{args.design}_logs")
    os.makedirs(log_dir, exist_ok=True)

    print(f"design {args.design} ({tier}, {args.pdk})")
    print(f"config {os.path.relpath(cfg_path, REPO_DIR)}")

    # ---- dry run -------------------------------------------------------
    if args.dry_run:
        print("\n--dry-run: no ORFS runs will be executed.\n")
        print("Each iteration runs exactly:")
        print(f"  CLK_PERIOD_NS=<period> WIPE_DESIGN={args.design} PLATFORM={args.pdk} \\")
        print(f"    scripts/run_orfs_build.sh "
              f"/work/orfs_configs/{args.pdk}/{tier}/{args.design}/config.mk")
        print(f"  then: scripts/collect_results.py --json {args.design}")
        print("\nPlanned bracketing probe order from the seed "
              f"({args.seed_period_ns} ns), whichever direction is needed:")
        up, dn = [], []
        p = args.seed_period_ns
        for _ in range(args.max_bracket_iterations):
            p /= 2.0
            dn.append(round(p, 4))
        p = args.seed_period_ns
        for _ in range(args.max_bracket_iterations):
            p *= 2.0
            up.append(round(p, 4))
        print(f"  seed passes -> tighten: {dn}")
        print(f"  seed fails  -> loosen : {up}")
        print(f"\nThen bisection to {args.resolution_ns} ns, "
              f"at most {args.max_iterations} iterations, "
              f"then {'no confirming re-run' if args.no_confirm else 'a confirming re-run'}.")
        print("\nActual periods after the seed depend on results, so they "
              "cannot be listed in advance.")
        return 0

    # ---- simulation gate ----------------------------------------------
    # Reuse build_and_score.sh's Verilator gate rather than duplicating it, and
    # run it once rather than per-iteration: the RTL does not change during the
    # search, only the constraint does.
    if not args.skip_sim_check:
        print("\n=== simulation gate (once) ===")
        r = subprocess.run(
            [os.path.join(SCRIPT_DIR, "build_and_score.sh"), "--sim-only", args.design]
        )
        if r.returncode != 0:
            sys.exit(
                f"ERROR: {args.design} does not pass its testbench. "
                f"Fmax of RTL that does not work is meaningless -- fix it first."
            )

    t_start = time.time()
    bracket_pass = bracket_fail = None
    trajectory = []
    it = 0
    aborted = None

    def do(period):
        nonlocal it
        it += 1
        rec = run_period(args.design, tier, args.pdk, period, it, log_dir, True)
        trajectory.append(rec)
        return rec

    # ---- Phase 1: bracketing ------------------------------------------
    print(f"\n=== phase 1: bracketing from {args.seed_period_ns} ns ===")
    period_pass = None
    period_fail = None
    bracket_iters = 0

    seed = do(args.seed_period_ns)
    bracket_iters += 1
    if seed["status"] == STATUS_TOOL:
        aborted = f"seed run failed as a tool error: {seed['note']}"
    elif seed["pass"]:
        period_pass = args.seed_period_ns
        p = args.seed_period_ns
        while bracket_iters < args.max_bracket_iterations:
            p /= 2.0
            r = do(p)
            bracket_iters += 1
            if r["status"] == STATUS_TOOL:
                aborted = f"tool error while bracketing at {p:.4f} ns: {r['note']}"
                break
            if r["pass"]:
                period_pass = p
            else:
                period_fail = p
                break
        if period_fail is None and aborted is None:
            aborted = (
                f"still meeting timing at {period_pass:.4f} ns after "
                f"{bracket_iters} bracketing runs -- never found a failing "
                f"period. The design may be trivially fast for this PDK, or the "
                f"seed is far too loose. Re-run with a much smaller "
                f"--seed-period-ns (try {period_pass/4:.3f})."
            )
    else:
        period_fail = args.seed_period_ns
        p = args.seed_period_ns
        while bracket_iters < args.max_bracket_iterations:
            p *= 2.0
            r = do(p)
            bracket_iters += 1
            if r["status"] == STATUS_TOOL:
                aborted = f"tool error while bracketing at {p:.4f} ns: {r['note']}"
                break
            if r["pass"]:
                period_pass = p
                break
            period_fail = p
        if period_pass is None and aborted is None:
            aborted = (
                f"still failing at {period_fail:.4f} ns after {bracket_iters} "
                f"bracketing runs -- never found a passing period. Either this "
                f"design cannot close timing at all (check the last log for a "
                f"real problem rather than a tight constraint), or the seed is "
                f"far too tight."
            )

    # ---- Phase 2: binary search ---------------------------------------
    # Snapshot the bracket BEFORE bisection starts: `bracket` in the output
    # should mean what phase 1 established, not the final bisected interval.
    bracket_pass, bracket_fail = period_pass, period_fail

    # NOTE ON ORIENTATION: period_fail < period_pass, always. A LOOSER (larger)
    # period is the one that meets timing, so the failing bound is the tighter
    # one and bisection walks period_pass DOWN toward period_fail. Getting this
    # backwards makes the interval width negative and the loop exits without
    # ever bisecting -- which is exactly what happened on the first run here.
    search_iters = 0
    if aborted is None:
        print(f"\n=== phase 2: bisecting (fail {period_fail:.4f}, pass {period_pass:.4f}] ns ===")
        while (period_pass - period_fail) >= args.resolution_ns and \
                search_iters < args.max_iterations:
            mid = (period_pass + period_fail) / 2.0
            r = do(mid)
            search_iters += 1
            if r["status"] == STATUS_TOOL:
                aborted = (
                    f"tool error at {mid:.4f} ns during bisection: {r['note']}. "
                    f"Stopping rather than recording it as a timing failure."
                )
                break
            if r["pass"]:
                period_pass = mid
            else:
                period_fail = mid

    # ---- Phase 3: confirming re-run -----------------------------------
    confirm = {"ran": False, "passed": False, "fell_back": False}
    converged = period_pass
    if aborted is None and not args.no_confirm and converged is not None:
        print(f"\n=== phase 3: confirming {converged:.4f} ns from a clean build ===")
        r = do(converged)
        confirm["ran"] = True
        if r["pass"]:
            confirm["passed"] = True
        else:
            # Fall back to the next-loosest period that actually passed during
            # the search, rather than reporting a number a clean re-run could
            # not reproduce.
            passed = sorted(
                {t["period_ns"] for t in trajectory if t["pass"] and t["period_ns"] > converged}
            )
            if passed:
                converged = passed[0]
                confirm["fell_back"] = True
                print(f"  confirmation FAILED -- falling back to {converged:.4f} ns")
            else:
                aborted = (
                    f"confirming re-run at {converged:.4f} ns failed and no "
                    f"looser passing period was tested to fall back to."
                )

    # Match on the ROUNDED period: trajectory records store round(period, 4)
    # while `converged` is the raw bisection midpoint (e.g. 1.484375 vs 1.4844),
    # so an exact comparison never matches and the reported WNS comes out None.
    wns_at = None
    if converged is not None:
        key = round(converged, 4)
        for t in reversed(trajectory):
            if t["pass"] and abs(t["period_ns"] - key) < 1e-6:
                wns_at = t["wns_ns"]
                break

    total = time.time() - t_start
    result = {
        "design": args.design,
        "tier": tier,
        "pdk": args.pdk,
        "converged_period_ns": round(converged, 4) if converged is not None else None,
        "achieved_fmax_mhz": round(1000.0 / converged, 2) if converged else None,
        "wns_at_converged_ns": wns_at,
        "confirming_rerun": confirm,
        "bracket": {
            "seed_period_ns": args.seed_period_ns,
            "period_pass": round(bracket_pass, 4) if bracket_pass is not None else None,
            "period_fail": round(bracket_fail, 4) if bracket_fail is not None else None,
            "bracket_iterations": bracket_iters,
        },
        "final_interval": {
            "period_pass": round(period_pass, 4) if period_pass is not None else None,
            "period_fail": round(period_fail, 4) if period_fail is not None else None,
        },
        "search_iterations": search_iters,
        "resolution_ns": args.resolution_ns,
        "search_trajectory": trajectory,
        "total_wall_time_s": round(total, 1),
        "total_pnr_runs": len(trajectory),
        "rtl_git_commit": git_commit(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "aborted_reason": aborted,
    }

    out_path = os.path.join(args.output_dir, f"{args.design}_fmax.json")
    with open(out_path, "w") as fh:
        json.dump(result, fh, indent=2)

    # ---- summary -------------------------------------------------------
    print("\n" + "=" * 62)
    if aborted:
        print(f"FMAX SEARCH ABORTED for {args.design}")
        print(f"  reason : {aborted}")
    else:
        print(f"FMAX for {args.design} ({tier}, {args.pdk})")
        print(f"  converged period : {converged:.4f} ns")
        print(f"  achieved Fmax    : {1000.0/converged:.2f} MHz")
        print(f"  WNS at that period: {wns_at} ns")
        if confirm["fell_back"]:
            print("  NOTE: the confirming re-run FAILED; this is the "
                  "next-loosest period that passed.")
        elif confirm["ran"]:
            print("  confirming re-run: passed")
        else:
            print("  confirming re-run: skipped (--no-confirm)")
    print(f"  P&R runs         : {len(trajectory)} "
          f"({bracket_iters} bracketing, {search_iters} bisection"
          f"{', 1 confirming' if confirm['ran'] else ''})")
    print(f"  total wall time  : {total/60:.1f} min")
    print(f"  written to       : {os.path.relpath(out_path, REPO_DIR)}")
    print("=" * 62)
    return 1 if aborted else 0


if __name__ == "__main__":
    sys.exit(main())
