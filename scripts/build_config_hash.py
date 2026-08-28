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

# TRACKED ONLY WHEN THE DESIGN SETS THEM, and the distinction from TRACKED is
# load-bearing rather than a convenience.
#
# d_ca05 overrides IO_PLACER_H/V to met3+met5 / met2+met4 because its 3,686 IO
# pins exceed the 3,260 positions one layer per direction provides. That changes
# where pins sit, hence routing, hence the silicon -- so it must change the
# digest, or two genuinely different builds would claim one configuration.
#
# WHY NOT IN TRACKED. A key in TRACKED is recorded as <unset> when absent, which
# changes the digest for every task that does not set it -- all nine others here.
# Their silicon would be unchanged while their hash moved, and every pre-change
# record would stop pairing with every post-change one on a difference that does
# not exist. That is a false non-comparability signal, and it would land on the
# five builds currently pending.
#
# THE PRINCIPLED HALF: an unset IO_PLACER is FULLY DETERMINED by PLATFORM, which
# is already tracked -- sky130hd fixes met3/met2. Omitting it when unset
# therefore loses no information. This is exactly what is NOT true of
# ABC_CLOCK_PERIOD_IN_PS, whose unset value is determined by nothing else in the
# list, which is why F24 required it to be recorded as <unset>. The rule is not
# "record everything" but "record what no other tracked key determines".
TRACKED_IF_SET = ["IO_PLACER_H", "IO_PLACER_V"]


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

    # Same "only when set" shape as VERILOG_TOP_PARAMS below, for the same
    # reason: the digest must move when the design overrides the platform, and
    # must not move for the nine tasks that do not.
    for var in TRACKED_IF_SET:
        m = re.search(r"^export\s+%s\s*:?=\s*(.*)$" % var, cfg, re.M)
        if m:
            val = overrides.get(var, resolve(m.group(1), sdc_path))
            fields.append(f"{var}={val}")

    # TOP-LEVEL PARAMETERS CHANGE THE DESIGN, so they must change the hash --
    # but ONLY WHEN SET. d_ai01's scored geometry moved to HEIGHT=4 while its
    # shim still defaults to 8, and the fix is an explicit VERILOG_TOP_PARAMS
    # pin. Untracked, a 4x8 build and an 8x8 build of the same task would carry
    # the SAME build_config_hash and rule 17 would declare two different designs
    # comparable -- the exact failure the hash exists to prevent, on the one
    # parameter the task is scored at.
    #
    # ADDED CONDITIONALLY, and that is deliberate. Putting it in TRACKED would
    # append `VERILOG_TOP_PARAMS=<unset>` to every blob and move every hash in
    # the corpus, making this week's finished design rows incomparable with
    # everything after. No config sets it today, so a config that does not set it
    # hashes exactly as it did before; a config that does gets it in the digest.
    m_top = re.search(r"^export\s+VERILOG_TOP_PARAMS\s*:?=\s*(.*)$", cfg, re.M)
    if m_top and m_top.group(1).strip():
        _tp = " ".join(m_top.group(1).split())
        fields.append(f"VERILOG_TOP_PARAMS={_tp}")

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

    # THE HASHED ABC VALUE IS NOT NECESSARILY THE ABC TARGET THE BUILD USED.
    #
    # run_orfs_build.sh puts ABC_CLOCK_PERIOD_IN_PS=<CLK_PERIOD_NS*1000> on the
    # MAKE COMMAND LINE whenever CLK_PERIOD_NS is set, and a make-line variable
    # beats the config. This script only ever sees the config.mk text resolved
    # against the SDC, so it recorded ABC=10000 on d_ca01 builds whose real
    # target was 15000 -- correctly measured numbers with a field beside them
    # describing a different synthesis.
    #
    # THE NOTE IS PRINTED AFTER THE DIGEST AND IS NOT IN THE BLOB, deliberately.
    # Folding the true value into the hash would be the more obvious fix and is
    # the wrong one: every existing record was hashed without it, so every future
    # build would become UNCOMPARABLE with the corpus under rule 17 -- including
    # the six design rows finished this week. The digest is a comparability key,
    # not a description; what was wrong here was the description.
    if "CLK_PERIOD_NS" in overrides:
        try:
            runtime_abc = int(round(float(overrides["CLK_PERIOD_NS"]) * 1000))
        except (TypeError, ValueError):
            runtime_abc = None
        if runtime_abc is not None:
            hashed = next((f.split("=", 1)[1] for f in fields
                           if f.startswith("ABC_CLOCK_PERIOD_IN_PS=")), None)
            agrees = hashed is not None and hashed.strip() == str(runtime_abc)
            print(f"  note.abc_runtime_target_ps={runtime_abc}"
                  f"{'' if agrees else '  (make-line override; the hashed '
                                       'ABC value above is the config.mk text '
                                       'resolved against the SDC, not this)'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
