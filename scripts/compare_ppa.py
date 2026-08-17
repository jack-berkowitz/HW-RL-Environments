#!/usr/bin/env python3
"""Compare two PPA run records, refusing when their builds are not comparable.

    compare_ppa.py <record_a.json> <record_b.json> [--vary FIELD[,FIELD...]]

RULE 17. Provenance tells you where a number came from, not whether two numbers
may be subtracted. This is the only place a subtraction is allowed to happen.

WHAT IT REFUSES
---------------
Any difference in the resolved build configuration that is not named in
`--vary`. Naming the axis is mandatory and deliberate: an elasticity comparison
is `--vary CLK_PERIOD_NS`, a candidate-vs-reference comparison varies nothing,
and if you cannot say which axis you are varying you do not have a comparison.

THE TWO DEFECTS THIS CLOSES, both real:

  F24 -- a candidate built with ABC_CLOCK_PERIOD_IN_PS=<empty> was compared
  against a reference built at 5000 ps. Every number had a record, every record
  was accurate, every run passed its gate and was DRC clean. Nothing available
  at the time could tell you the builds were not comparable.

  F20's own audit -- a 2.625 ns run was compared against a 4.5 ns run and the
  difference reported as a "conflict" between a quoted figure and reality. The
  audit committed the error it was written about.

Records written before this existed carry no hash. They are reported as
UNCOMPARABLE rather than assumed fine -- the same choice collect_results makes
for a missing row, and for the same reason.
"""
import json
import sys


def fields_of(rec):
    raw = rec.get("build_config_fields") or ""
    out = {}
    for item in raw.split(";"):
        item = item.strip()
        if not item or "=" not in item:
            continue
        k, v = item.split("=", 1)
        out[k.strip()] = v.strip()
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    vary = []
    for a in sys.argv[1:]:
        if a.startswith("--vary"):
            vary = a.split("=", 1)[1].split(",") if "=" in a else []
    if "--vary" in sys.argv:
        i = sys.argv.index("--vary")
        if i + 1 < len(sys.argv):
            vary = sys.argv[i + 1].split(",")
            args = [a for a in args if a != sys.argv[i + 1]]
    if len(args) != 2:
        print(__doc__.strip().splitlines()[0])
        print("usage: compare_ppa.py <a.json> <b.json> [--vary FIELD,...]")
        return 2

    a, b = (json.load(open(p)) for p in args)
    na, nb = args[0].split("/")[-1], args[1].split("/")[-1]

    # TASK-TEXT check first: two answers to different questions are not
    # comparable however well their builds match.
    ta, tb = a.get("task_text_hash"), b.get("task_text_hash")
    if ta and tb and (ta == "unknown" or tb == "unknown"):
        print("UNCOMPARABLE: task-text version unknown for at least one submission")
        print("  A record written before task-text hashing cannot be shown to have")
        print("  answered the same question. Unknown is honest; assuming is not.")
        return 1
    if ta and tb and ta != tb:
        print(f"UNCOMPARABLE: different task text ({ta} vs {tb})")
        print("  These answer DIFFERENT QUESTIONS. Comparing them measures the")
        print("  edit to the task, not the difference between the submissions.")
        return 1

    ha, hb = a.get("build_config_hash"), b.get("build_config_hash")
    if not ha or not hb:
        which = [n for n, h in ((na, ha), (nb, hb)) if not h]
        print("UNCOMPARABLE: no build_config_hash in " + ", ".join(which))
        print("  Written before rule 17. Not assumed comparable -- rebuild")
        print("  through ppa_candidate.sh if the comparison matters.")
        return 1

    fa, fb = fields_of(a), fields_of(b)
    diffs = {k: (fa.get(k, "<absent>"), fb.get(k, "<absent>"))
             for k in set(fa) | set(fb) if fa.get(k) != fb.get(k)}

    # The varied axis may differ; nothing else may.
    allowed = set()
    for v in vary:
        allowed |= {k for k in diffs if v.strip().lower() in k.lower()}
    illegal = {k: v for k, v in diffs.items() if k not in allowed}

    print(f"  A: {na}  [{ha}]")
    print(f"  B: {nb}  [{hb}]")
    if vary:
        print(f"  varying: {', '.join(vary)}")

    if illegal:
        print("\nREFUSING TO COMPARE -- build configuration differs off-axis:")
        for k, (x, y) in sorted(illegal.items()):
            print(f"    {k}:  A={x!r}  B={y!r}")
        print("\n  These builds did not target the same thing, so the difference")
        print("  between their numbers is not a property of the designs.")
        print("  Name the axis with --vary, or rebuild them the same way.")
        return 1

    if diffs:
        print(f"  on-axis differences: {', '.join(sorted(diffs))}")
    else:
        print("  identical build configuration")

    print("\n  COMPARABLE.")
    for k in ("design_area_um2", "power_w", "wns_ns", "clk_period_ns"):
        x, y = a.get(k), b.get(k)
        if x in (None, "") or y in (None, ""):
            continue
        try:
            fx, fy = float(x), float(y)
        except ValueError:
            continue
        delta = f"{100*(fx-fy)/fy:+.2f} %" if fy else "n/a"
        print(f"    {k:18s} A={fx:<12g} B={fy:<12g} A/B={fx/fy:.4f}  {delta}"
              if fy else f"    {k:18s} A={fx} B={fy}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
