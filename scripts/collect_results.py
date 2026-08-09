#!/usr/bin/env python3
"""Collect final PPA numbers from a set of completed ORFS runs.

Reads the per-stage metrics JSON that ORFS writes under
<flow>/logs/<platform>/<design>/base/ and prints one row per design.
"""
import json
import os
import sys

FLOW = os.environ.get(
    "ORFS_FLOW_DIR", "/Users/jackberkowitz/tools/OpenROAD-flow-scripts/flow"
)
PLATFORM = "sky130hd"
DESIGNS = sys.argv[1:] or ["arbiter", "fifo", "multiplier", "softmax", "uart"]


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


rows = []
for d in DESIGNS:
    fin, rt, syn = load(d, "6_report"), load(d, "5_2_route"), load(d, "1_synth")
    if not fin:
        rows.append((d, None))
        continue
    rows.append(
        (
            d,
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

hdr = (
    f"{'design':<11}{'clk(ns)':>8}{'WNS(ns)':>9}{'TNS(ns)':>9}{'holdWNS':>9}"
    f"{'core um2':>10}{'cell um2':>10}{'insts':>7}{'util':>7}{'power(mW)':>11}"
    f"{'DRC':>5}  status"
)
print(hdr)
print("-" * len(hdr))
for d, m in rows:
    if m is None:
        print(f"{d:<11}{'--':>8}  DID NOT COMPLETE")
        continue
    ok = m["wns"] is not None and m["wns"] >= 0 and m["drc"] == 0
    print(
        f"{d:<11}{m['period']:>8.1f}{m['wns']:>9.3f}{m['tns']:>9.3f}"
        f"{m['hold_ws']:>9.3f}{m['core_area']:>10.1f}{m['cell_area']:>10.1f}"
        f"{m['insts']:>7}{m['util']:>7.2f}{m['power'] * 1000:>11.4f}"
        f"{m['drc']:>5}  {'PASS' if ok else 'CHECK'}"
    )
