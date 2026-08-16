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


def main():
    if len(sys.argv) < 3:
        print(__doc__.strip().splitlines()[0])
        return 2
    cfg_path, sdc_path = sys.argv[1], sys.argv[2]
    overrides = dict(kv.split("=", 1) for kv in sys.argv[3:] if "=" in kv)

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
