#!/usr/bin/env python3
"""A declared metric that nothing emits is an axis the task does not have.

AGENT-DESIGN-43a92055's axis audit, mechanised for the half that is checkable.
Three layers of one defect surfaced this week:

  d_ca03  capability invisible because metric_roles() read one schema form
  d_ca03  its free axis invisible because the renderer does one division
  d_nw03  L3 says latency is "REPORTED AS A METRIC"; the string `latency`
          appears zero times in both testbench files

This checks the layer a script can reach: a metric named in `scored_metrics:`
that no testbench emits, and a metric emitted that nothing declares.

THE SECOND DIRECTION IS THE DANGEROUS ONE and is why both are reported. A
declared-but-unemitted metric produces NO number, which is visible as an empty
column. An emitted-but-undeclared one is a measurement nobody chose to publish
-- d_nw01 emits `outstanding_master1` while declaring only `master0`, so the
capability is measured on both masters and published for one.

PPA FIELDS ARE NOT SIM METRICS. `area_um2` and `power_mw` declared under
scored_metrics can never appear in a sim record; they are outputs of the PPA
flow. That is a category error rather than an emit gap, so it is named
separately.

Reports; does not fail. Whether an axis SHOULD be declared is a contract
question, and a checker that guessed would repeat the tlb_hits error -- a metric
published as `capability` that P2 pins, found by reading the clause rather than
the name.
"""
import glob
import os
import json
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "scripts"))
PPA_ONLY = {"area_um2", "power_mw", "area", "power", "design_area_um2", "power_w"}


def emitted(task):
    """Metric names that ACTUALLY APPEAR in this task's run records.

    FOUR STATIC PARSES OF THE TESTBENCH WERE WRONG BEFORE THIS ONE, each in a
    different way, and the sequence is the argument:

      1. one name per METRIC: line   -- missed multi-metric $display
      2. every `name=`               -- swept in min/max/n sub-fields
      3. first token wins            -- missed composed <name>_<subfield>
      4. any static parse at all     -- d_nw01 builds names at RUNTIME with
                                        `outstanding_master%0d`, and d_nw03's
                                        liveness_worst_wait is emitted from a
                                        shared include, not from its own tb

    A metric name that only exists after format expansion cannot be read out of
    the source, so the question "is this metric ever produced" is not answerable
    from the testbench text. It IS answerable from the records, which are what
    the emit produced. Measure the output rather than infer it from the program.

    Every earlier version reported false positives, and one of them looked
    corroborated because an independent audit had flagged the same task names
    for unrelated reasons.
    """
    out = set()
    for f in glob.glob(os.path.join(REPO, "runs", task, "*__sim.json")):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        for v in (r.get("metrics") or {}).values():
            if isinstance(v, dict):
                out |= set(v)
            elif isinstance(v, str):
                out.add(v)
        for k in ("metrics",):
            m = r.get(k)
            if isinstance(m, dict):
                out |= {x for x in m if not isinstance(m[x], dict)}
    return out


def main():
    import report_table as RT
    rows = []
    for d in sorted(glob.glob(os.path.join(REPO, "domains", "*", "design", "d_*"))):
        task = os.path.basename(d)
        try:
            dec = {m for m, _e, _r in RT.scored_metrics(d)}
        except Exception:
            dec = set()
        emi = emitted(task)
        ppa = dec & PPA_ONLY
        missing = dec - emi - PPA_ONLY
        extra = emi - dec
        if dec or emi:
            rows.append((task, len(dec), len(emi), sorted(missing),
                         sorted(extra), sorted(ppa)))
    print(f"{len(rows)} design task(s) with declared or emitted metrics\n")
    for t, nd, ne, miss, extra, ppa in rows:
        flag = "  " if not (miss or extra or ppa) else "!!"
        print(f"{flag} {t:30s} declared {nd:2d}  emitted {ne:2d}")
        if miss:
            print(f"      DECLARED, NEVER EMITTED: {', '.join(miss)}")
        if extra:
            # INFORMATIONAL, NOT A FINDING LIST. It includes sub-fields of
            # composite metrics, guard flags, and metrics emitted only by
            # controls -- none of which a task is obliged to declare. Reported
            # so a genuinely undeclared axis is FINDABLE, not so the count means
            # something. d_nw01's outstanding_master1 was found this way.
            print(f"      emitted, not declared ({len(extra)}, informational): "
                  f"{', '.join(extra)}")
        if ppa:
            print(f"      PPA FIELD IN sim METRICS: {', '.join(ppa)}"
                  f"  (can never appear in a sim record)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
