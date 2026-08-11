#!/usr/bin/env python3
"""Collect final PPA numbers from a set of completed ORFS runs, plus any
secondary informational metrics (branch misprediction rate, cache hit
rate, etc.) a Tier2 testbench chose to report.

PPA numbers are read from the per-stage metrics JSON that ORFS writes
under <flow>/logs/<platform>/<design>/base/ -- these are properties of
the physical implementation.

Accuracy/hit-rate metrics are read from sim_logs/<tier>/<design>.log,
written by build_and_score.sh from the testbench's own simulation output.
These are NOT part of PASS/CHECK status -- per the two-tier grading
principle (functional correctness is pass/fail; prediction accuracy or
cache hit rate is informational, since there's no single "correct" value
for a legitimate design choice) they're reported alongside PPA, not
folded into it.
"""
import json
import os
import sys

FLOW = os.environ.get(
    "ORFS_FLOW_DIR", "/Users/jackberkowitz/tools/OpenROAD-flow-scripts/flow"
)
PLATFORM = "sky130hd"
REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TIERS = ("TierOne", "TierTwo")


def discover_designs():
    """Every design with an ORFS config under orfs_configs/sky130hd/{Tier},
    as (design_name, tier) pairs. design_name is read from each config.mk's
    DESIGN_NAME line rather than assumed to match the folder name."""
    found = []
    configs_root = os.path.join(REPO_DIR, "orfs_configs", PLATFORM)
    for tier in TIERS:
        tier_dir = os.path.join(configs_root, tier)
        if not os.path.isdir(tier_dir):
            continue
        for entry in sorted(os.listdir(tier_dir)):
            config_path = os.path.join(tier_dir, entry, "config.mk")
            if not os.path.isfile(config_path):
                continue
            design_name = entry
            try:
                with open(config_path) as fh:
                    for line in fh:
                        line = line.strip()
                        if line.startswith("export DESIGN_NAME"):
                            design_name = line.split("=", 1)[1].strip()
                            break
            except OSError:
                pass
            found.append((design_name, tier))
    return found


DISCOVERED = discover_designs()
TIER_OF = dict(DISCOVERED)

# --json emits the same metrics dicts as machine-readable JSON instead of the
# table. Added so find_fmax.py can read WNS/DRC/period without a second parser
# living somewhere else -- this file stays the only place ORFS metric names are
# known.
JSON_MODE = "--json" in sys.argv[1:]
ARGV = [a for a in sys.argv[1:] if a != "--json"]

if ARGV:
    DESIGNS = [(d, TIER_OF.get(d, "?")) for d in ARGV]
else:
    DESIGNS = DISCOVERED
    if not DESIGNS and not JSON_MODE:
        print(
            f"No designs found under {REPO_DIR}/orfs_configs/{PLATFORM}/"
            f"{{{','.join(TIERS)}}}/ -- pass design names explicitly, or "
            f"check ORFS configs have been added yet.",
            file=sys.stderr,
        )


def load(design, stage):
    path = f"{FLOW}/logs/{PLATFORM}/{design}/base/{stage}.json"
    try:
        with open(path) as fh:
            return json.load(fh)
    except OSError:
        return {}


def period(design):
    """The clock period the run was actually constrained at."""
    path = f"{FLOW}/results/{PLATFORM}/{design}/base/clock_period.txt"
    try:
        with open(path) as fh:
            return float(fh.read().strip())
    except (OSError, ValueError):
        return float("nan")


def sim_log_path(design, tier):
    """Find sim_logs/<tier>/<design>.log -- tries the known tier first,
    falls back to checking both if the tier wasn't resolved (e.g. a
    design name passed explicitly on the command line that isn't in
    orfs_configs/ yet)."""
    if tier in TIERS:
        candidate = os.path.join(REPO_DIR, "sim_logs", tier, f"{design}.log")
        if os.path.isfile(candidate):
            return candidate
    for t in TIERS:
        candidate = os.path.join(REPO_DIR, "sim_logs", t, f"{design}.log")
        if os.path.isfile(candidate):
            return candidate
    return None


def load_sim_metrics(design, tier):
    """Parse `METRIC: name=value` lines from the testbench's own sim
    output. Returns {} for any design whose testbench doesn't emit these
    (i.e. most modules) -- not an error, just nothing to report."""
    path = sim_log_path(design, tier)
    metrics = {}
    if not path:
        return metrics
    try:
        with open(path) as fh:
            for line in fh:
                line = line.strip()
                if not line.startswith("METRIC:"):
                    continue
                body = line[len("METRIC:"):].strip()
                if "=" not in body:
                    continue
                k, v = body.split("=", 1)
                k, v = k.strip(), v.strip()
                try:
                    metrics[k] = float(v)
                except ValueError:
                    metrics[k] = v
    except OSError:
        pass
    return metrics


rows = []
metrics_by_design = {}
for d, tier in DESIGNS:
    fin, rt, syn = load(d, "6_report"), load(d, "5_2_route"), load(d, "1_synth")
    sim_metrics = load_sim_metrics(d, tier)
    if sim_metrics:
        metrics_by_design[(d, tier)] = sim_metrics
    if not fin:
        rows.append((d, tier, None))
        continue
    rows.append(
        (
            d,
            tier,
            {
                "period": period(d),
                "wns": fin.get("finish__timing__setup__ws"),
                "tns": fin.get("finish__timing__setup__tns"),
                "hold_ws": fin.get("finish__timing__hold__ws"),
                "core_area": fin.get("finish__design__core__area"),
                "die_area": fin.get("finish__design__die__area"),
                "cell_area": fin.get("finish__design__instance__area__stdcell"),
                "insts": fin.get("finish__design__instance__count"),
                "util": fin.get("finish__design__instance__utilization"),
                "power": fin.get("finish__power__total"),
                "drc": rt.get("detailedroute__route__drc_errors"),
                "synth_cells": syn.get("synth__design__instance__count__stdcell"),
            },
        )
    )

if JSON_MODE:
    out = []
    for d, tier, m in rows:
        rec = {"design": d, "tier": tier, "completed": m is not None}
        if m is not None:
            rec.update(m)
        out.append(rec)
    print(json.dumps(out, indent=2))
    sys.exit(0)

hdr = (
    f"{'design':<11}{'tier':<9}{'clk(ns)':>8}{'WNS(ns)':>9}{'TNS(ns)':>9}{'holdWNS':>9}"
    f"{'core um2':>10}{'cell um2':>10}{'insts':>7}{'util':>7}{'power(mW)':>11}"
    f"{'DRC':>5}  status"
)
print(hdr)
print("-" * len(hdr))
for d, tier, m in rows:
    if m is None:
        print(f"{d:<11}{tier:<9}{'--':>8}  DID NOT COMPLETE")
        continue
    ok = m["wns"] is not None and m["wns"] >= 0 and m["drc"] == 0
    print(
        f"{d:<11}{tier:<9}{m['period']:>8.1f}{m['wns']:>9.3f}{m['tns']:>9.3f}"
        f"{m['hold_ws']:>9.3f}{m['core_area']:>10.1f}{m['cell_area']:>10.1f}"
        f"{m['insts']:>7}{m['util']:>7.2f}{m['power'] * 1000:>11.4f}"
        f"{m['drc']:>5}  {'PASS' if ok else 'CHECK'}"
    )

if metrics_by_design:
    print()
    print("Informational metrics (not part of PASS/CHECK status):")
    for (d, tier), metrics in metrics_by_design.items():
        print(f"  {d} ({tier}):")
        for k, v in metrics.items():
            v_str = f"{v:.4f}" if isinstance(v, float) else str(v)
            print(f"    {k:<32} = {v_str}")