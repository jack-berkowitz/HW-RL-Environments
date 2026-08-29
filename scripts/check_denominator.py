#!/usr/bin/env python3
"""Scored submissions in one task must share a configuration denominator.

WHY. `configs_passed/configs_total` renders as "16/16 pass" and "1/1 pass"
side by side, and both read as a clean sweep. They are not the same claim: one
survived sixteen parameterisations and the other survived one. A reader
comparing them is comparing a number to a different number with the same shape.

WHAT COUNTS AS SCORED. The reference and the model candidates -- the rows that
appear in the results tables. Controls, mutants and alternative references
legitimately run narrower sets: a neutralised control exists to be checked at
the one configuration whose behaviour it neutralises, and requiring it to sweep
sixteen would be requiring it to be a different artefact.

MEASURED WHEN WRITTEN: one task disagrees, d_ca01, and only among controls --
nonblocking_dcache_alt_ref, c01_neutralised and c03_neutralised at 1 against
sixteen scored submissions at 16. So this check is quiet today, and it is worth
having for the reason the invalidated flag and the stamping records were worth
fixing: nothing about the current agreement is enforced by anything.

Exit 0 = scored submissions agree per task. 1 = a task's scored submissions
disagree. 2 = no records found, which is a broken invocation rather than a pass.
"""
import collections
import glob
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS = ("chat.sv", "claude.sv", "gemini.sv")


def scored_subs(task_dir_name):
    """Reference filename for a task, from its own ref/ directory."""
    for d in glob.glob(os.path.join(REPO, "domains", "*", "design", task_dir_name)):
        for f in sorted(glob.glob(os.path.join(d, "ref", "*.sv"))):
            return os.path.basename(f)
    return None


def main():
    best = {}
    for f in sorted(glob.glob(os.path.join(REPO, "runs", "*", "*__sim.json"))):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        if r.get("configs_total") is None:
            continue
        k = (r.get("task"), os.path.basename(str(r.get("submission", ""))))
        if k not in best or r.get("timestamp_utc", "") > best[k].get("timestamp_utc", ""):
            best[k] = r
    if not best:
        print("no sim records with a configuration count -- nothing checked",
              file=sys.stderr)
        return 2

    by = collections.defaultdict(dict)
    for (t, s), r in best.items():
        by[t][s] = r.get("configs_total")

    rc, checked = 0, 0
    for task in sorted(by):
        ref = scored_subs(task)
        want = {s: n for s, n in by[task].items()
                if s in MODELS or (ref and s == ref)}
        if len(want) < 2:
            continue
        checked += 1
        tot = set(want.values())
        if len(tot) > 1:
            rc = 1
            print(f"FAIL {task}: scored submissions disagree on configs_total")
            for s, n in sorted(want.items(), key=lambda x: -(x[1] or 0)):
                print(f"  {n:3d} configs   {s}")
            print("  A pass over fewer configurations is a weaker claim, and "
                  "renders identically.")
    print(f"{checked} task(s) checked, {'0' if rc == 0 else 'at least 1'} "
          f"disagreement(s).")
    return rc


if __name__ == "__main__":
    sys.exit(main())
