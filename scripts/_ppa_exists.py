#!/usr/bin/env python3
"""Has a PPA record already been written for task/label at period P?

WHY A SCRIPT AND NOT A GLOB. The two queue scripts asked this with
`ls runs/${task}_*/*__${label}_fx${per}__ppa.json`, which answers a question
about FILENAMES rather than about builds. Records written under the later
`_pin19p25` convention did not match, so 22 completed builds read as absent and
the queue would redo them. Same identify-by-filename defect that froze the
charts and disabled the superseded-pin guard -- this is its cost-only instance.

A WRONG SKIP IS WORSE THAN A WRONG REBUILD, so this prints the record it
matched on. A skip that names its evidence can be audited; "already built" on
its own cannot be told from a bug.

Exit 0 = a record exists (path on stdout). Exit 1 = none. Exit 2 = bad usage.
"""
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main(argv):
    if len(argv) != 4:
        print("usage: _ppa_exists.py <task> <label> <period_ns>", file=sys.stderr)
        return 2
    task, label, per = argv[1], argv[2], argv[3]
    try:
        per = float(per)
    except ValueError:
        print(f"period not a number: {per}", file=sys.stderr)
        return 2
    for f in sorted(glob.glob(os.path.join(REPO, "runs", f"{task}_*", "*__ppa.json"))):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        # The MODEL, with whatever period convention its label carries stripped.
        who = re.split(r"_(?:fx|pin|at)", str(r.get("label", "")))[0]
        if who != label:
            continue
        try:
            if abs(float(r.get("clk_period_ns")) - per) > 1e-9:
                continue
        except (TypeError, ValueError):
            continue
        print(os.path.relpath(f, REPO))
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
