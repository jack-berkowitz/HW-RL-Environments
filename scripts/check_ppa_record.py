#!/usr/bin/env python3
"""Assert a PPA run record matches an independent reading of the same run.

WHY THIS EXISTS
---------------
`ppa_candidate.sh` produced THREE wrong fields in a single turn (FINDINGS.md
F21): WNS taken from the negative-slack summary, which reads 0.00 for every
passing run; power taken from the Leakage column instead of Total, understating
it by five orders of magnitude; and WNS rounded to two decimals in exactly the
near-zero regime that decides the gate.

Rule 3 says every check gets a negative control. **That applies to the tool that
produces the numbers as much as to a checker that consumes them** -- arguably
more, because F20's remedy was to make this script the ONLY source of PPA
numbers, and promoting a path to authoritative raises the cost of its bugs. A
provisional number invites checking; a record does not.

WHAT IT CHECKS
--------------
The shell parsers in `ppa_candidate.sh` read `6_report.log` and `6_finish.rpt`.
ORFS independently emits `6_report.json`. Those are two readings of the same
completed run, so they must agree field by field. Disagreement means a parser is
wrong -- which is precisely how F21 was caught, by hand, once.

Tolerances exist because the .rpt is human-formatted and rounds; the JSON is
authoritative on precision. A field that disagrees beyond rounding is an error.

    ./scripts/check_ppa_record.py <record.json>      # one record
    ./scripts/check_ppa_record.py --all              # every record with a
                                                     # surviving flow directory

Exits non-zero on any mismatch. Runs with the regression.

LIMITATION, STATED SO A GREEN RUN IS NOT OVER-READ
--------------------------------------------------
This can only check records whose flow directory still exists. The flow
directory is wiped by the next build, so in practice it validates the MOST
RECENT run per design and silently skips the rest. It is a check on the parser,
not on the archive: it establishes that the tool reads correctly today, not that
every historical record was written correctly. Records it cannot check are
reported as SKIPPED and counted, never as passing.
"""
import glob
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLOW = os.environ.get("ORFS_FLOW_DIR",
                      os.path.expanduser("~/tools/OpenROAD-flow-scripts/flow"))

# record field -> (6_report.json key, relative tolerance)
# Tolerances are loose enough for the .rpt's 2-decimal rounding and no looser.
FIELDS = [
    ("design_area_um2", "finish__design__instance__area", 0.001),
    ("wns_ns",          "finish__timing__setup__ws",      None),   # absolute
    ("power_w",         "finish__power__total",           0.02),
]
WNS_ABS_TOL = 0.006      # the .rpt rounds to 2dp; JSON is authoritative


def check(rec_path, verbose=True):
    """Return 'ok' | 'skip' | 'fail'."""
    rec = json.load(open(rec_path))
    nick = rec.get("orfs_nickname") or rec.get("design_nickname")
    if not nick:
        # Records do not currently carry the nickname; derive it from the task.
        nick = rec.get("task", "")
    pdk = rec.get("pdk", "sky130hd")
    j = os.path.join(FLOW, "logs", pdk, nick, "base", "6_report.json")
    if not os.path.isfile(j):
        if verbose:
            print(f"  SKIP  {os.path.basename(rec_path)}  "
                  f"(no surviving flow dir for '{nick}')")
        return "skip"

    # ---- IDENTITY, before any comparison ------------------------------------
    # A SHARED NICKNAME IS NOT EVIDENCE THAT TWO ARTEFACTS ARE READINGS OF THE
    # SAME RUN. The Fmax sweep reuses one nickname across every iteration, so
    # the flow directory holds whichever period ran LAST, while the record
    # describes the period it was written from. Comparing them and calling the
    # difference a MISMATCH is two numbers subtracted without establishing they
    # measure the same thing -- the F20 correction's own error, reproduced
    # inside the check written for F21.
    #
    # d_dsp02/chat_scored: record 12.8125 ns (area 440336, wns -0.697) against a
    # flow directory at 20.25 ns (area 360899, wns +0.119). Nothing was wrong
    # with the record.
    #
    # ORFS writes results/<pdk>/<nick>/base/clock_period.txt in INTEGER
    # picoseconds, which is the one identity fact both sides can supply today.
    cp = os.path.join(FLOW, "results", pdk, nick, "base", "clock_period.txt")
    rec_ns = rec.get("clk_period_ns")
    if os.path.isfile(cp) and rec_ns not in (None, "", "None"):
        try:
            flow_ns = float(open(cp).read().strip()) / 1000.0
            rec_ns_f = float(rec_ns)
        except ValueError:
            flow_ns = rec_ns_f = None
        if flow_ns is not None:
            # clock_period.txt is truncated to whole ps, so 12.8125 ns -> 12812.
            if abs(flow_ns - rec_ns_f) > 0.0011:
                if verbose:
                    print(f"  SKIP  {os.path.basename(rec_path)}")
                    print(f"          period mismatch: record {rec_ns_f} ns, "
                          f"flow dir {flow_ns} ns -- DIFFERENT RUNS sharing the "
                          f"nickname '{nick}'.")
                    print(f"          Not a discrepancy in the record; there is "
                          f"nothing here to compare it against.")
                return "skip_period"

    truth = json.load(open(j))
    bad = []
    for field, key, rel in FIELDS:
        got = rec.get(field)
        want = truth.get(key)
        if got in (None, "", "None") or want is None:
            continue
        got, want = float(got), float(want)
        if rel is None:
            ok = abs(got - want) <= WNS_ABS_TOL
        else:
            ok = abs(got - want) <= max(abs(want) * rel, 1e-12)
        if not ok:
            bad.append(f"{field}: record={got!r} independent={want!r}")

    if bad:
        print(f"  FAIL  {os.path.basename(rec_path)}")
        for b in bad:
            print(f"          {b}")
        return "fail"
    if verbose:
        print(f"  ok    {os.path.basename(rec_path)}  ({nick})")
    return "ok"


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__.strip().splitlines()[0])
        print("usage: check_ppa_record.py <record.json> | --all")
        return 2
    if args[0] == "--all":
        paths = sorted(glob.glob(os.path.join(REPO, "runs", "*", "*__ppa.json")))
        if not paths:
            print("no PPA run records found")
            return 0
    else:
        paths = args

    tally = {"ok": 0, "skip": 0, "skip_period": 0, "fail": 0}
    for p in paths:
        tally[check(p)] += 1

    # TWO SKIP CAUSES, REPORTED SEPARATELY. They were briefly collapsed under
    # "(flow dir gone)", which was false for the period-mismatch case -- that
    # flow directory is present, it just holds a different run. Reporting a
    # present-but-different artefact as absent is the same defect as rendering
    # a missing verdict as FAIL: two states, one label, and the reader cannot
    # tell which happened.
    print(f"\n  {tally['ok']} verified, "
          f"{tally['skip']} unverifiable (flow dir gone), "
          f"{tally['skip_period']} unverifiable (flow dir holds a DIFFERENT run), "
          f"{tally['fail']} MISMATCHED")
    if tally["skip_period"]:
        print("  NOTE: a period-mismatched record is NOT confirmed. It is not "
              "contradicted either -- there is simply no comparable artefact. "
              "Numbers from it stay withdrawn until rebuilt.")
    if tally["fail"]:
        print("\n  A record disagrees with an independent reading of the same run.")
        print("  The parser in ppa_candidate.sh is wrong, or the record is stale.")
        print("  Do NOT quote the number until this resolves -- see FINDINGS.md F21.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
