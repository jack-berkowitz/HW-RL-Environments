#!/usr/bin/env python3
"""Hash the RESOLVED build configuration a PPA number was produced under.

    build_config_hash.py <config.mk> <constraint.sdc> [KEY=VAL ...]

Prints `<16-hex-digest>` plus the resolved fields, one per line, so a record can
carry both the digest and what went into it. A digest nobody can decompose is
useless when a comparison refuses.

WHY (rule 17, from F24)
-----------------------
Provenance tells you where a number came from, not whether two numbers may be
subtracted. Every number in F24 had a run record, every record was accurate,
every run passed its gate and was DRC clean -- and two of them still were not
comparable, because a hardcoded `awk '/^set clk_period/'` found nothing in a
two-clock SDC and mapped one build with ABC unconstrained.

RESOLVED is the operative word. `ABC_CLOCK_PERIOD_IN_PS := $(shell awk ...)` is
identical as TEXT in the two configs that differed; it is the *value that awk
returns against that SDC* which differs, and only that value is comparable. So
the shell substitutions are evaluated here rather than hashed as strings.
"""
import hashlib
import os
import re
import subprocess
import sys

# Variables that change the resulting silicon. Anything absent is recorded as
# <unset> rather than skipped -- an unset ABC target is exactly the F24 defect,
# and it must change the digest.
TRACKED = [
    "PLATFORM", "DESIGN_NAME", "CORE_UTILIZATION", "PLACE_DENSITY",
    "TNS_END_PERCENT", "SYNTH_HDL_FRONTEND", "SYNTH_MEMORY_MAX_BITS",
    "ABC_CLOCK_PERIOD_IN_PS", "ASPECT_RATIO", "CORE_MARGIN",
]


def resolve(value, sdc_path):
    """Evaluate the $(shell ...) forms ORFS configs use, against this SDC."""
    m = re.search(r"\$\(shell\s+(.*)\)\s*$", value.strip())
    if not m:
        return value.strip()
    cmd = m.group(1).replace("$(SDC_FILE)", sdc_path).replace("$$", "$")
    try:
        out = subprocess.run(["bash", "-c", cmd], capture_output=True,
                             text=True, timeout=10)
        return out.stdout.strip() or "<empty>"
    except (OSError, subprocess.SubprocessError):
        return "<unresolvable>"


def clock_periods(sdc_path):
    """Every `set <name>_period <v>` in the SDC, so a multi-clock design is not
    reduced to one number -- which is how F24 hid."""
    try:
        txt = open(sdc_path, errors="replace").read()
    except OSError:
        return []
    return sorted(f"{n}={v}" for n, v in
                  re.findall(r"^set\s+(\w*period\w*)\s+([\d.]+)", txt, re.M))


# PERIODS ARE NORMALISED BEFORE HASHING, BECAUSE THE HASH IS OVER A STRING.
# Two callers passing the SAME clock in different formats produced different
# hashes, so rule 17 refused to compare builds that were physically identical:
#   fixed_clock_ppa.sh  -> CLK_PERIOD_NS=9.0      -> 2a133c2a85f8933a
#   overnight_ppa2.sh   -> CLK_PERIOD_NS=9.0000   -> d0a75612c6e3be79
# (period_for and mac_sweep_queue.sh both format with printf "%.4f"). The two
# d_nw01/claude builds behind those hashes came out byte-identical -- 110645
# um^2, 1.56e-02 W, WNS 0.213807 -- and were still declared incomparable.
#
# Fixing it here rather than in each caller means every caller converges without
# having to remember, including ones not yet written. Canonical form is the
# MINIMAL decimal: round to 4 dp (the resolution bisection actually produces),
# strip trailing zeros, keep one decimal place. Chosen because it is what the
# existing corpus already uses -- "9.0" and "10.0" preserve six records on disk
# where "%.4f" would have preserved one.
_PERIOD_KEYS = ("CLK_PERIOD_NS", "ABC_CLOCK_PERIOD_IN_PS")


def canon_period(v):
    """9.0 / 9.0000 -> '9.0';  7.03125 -> '7.0312';  10 -> '10.0'."""
    try:
        s = f"{float(v):.4f}".rstrip("0")
    except (TypeError, ValueError):
        return v                      # not numeric -- pass through untouched
    return s + "0" if s.endswith(".") else s


def main():
    if len(sys.argv) < 3:
        print(__doc__.strip().splitlines()[0])
        return 2
    cfg_path, sdc_path = sys.argv[1], sys.argv[2]
    overrides = dict(kv.split("=", 1) for kv in sys.argv[3:] if "=" in kv)
    for k in _PERIOD_KEYS:
        if k in overrides:
            overrides[k] = canon_period(overrides[k])

    try:
        cfg = open(cfg_path, errors="replace").read()
    except OSError as e:
        print(f"cannot read config: {e}", file=sys.stderr)
        return 2

    fields = []
    for var in TRACKED:
        m = re.search(r"^export\s+%s\s*:?=\s*(.*)$" % var, cfg, re.M)
        val = resolve(m.group(1), sdc_path) if m else "<unset>"
        if var in overrides:
            val = overrides[var]
        fields.append(f"{var}={val}")

    for p in clock_periods(sdc_path):
        fields.append(f"sdc.{p}")
    for k, v in sorted(overrides.items()):
        if k not in TRACKED:
            fields.append(f"override.{k}={v}")

    blob = "\n".join(fields)
    digest = hashlib.sha256(blob.encode()).hexdigest()[:16]
    print(digest)
    for f in fields:
        print(f"  {f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
