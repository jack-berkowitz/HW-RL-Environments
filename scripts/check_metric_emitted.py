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
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "scripts"))
PPA_ONLY = {"area_um2", "power_mw", "area", "power", "design_area_um2", "power_w"}


def emitted(task_dir):
    """Every metric name on a METRIC: line, not just the first.

    THE FIRST VERSION CAPTURED ONE NAME PER LINE and was wrong on most tasks.
    d_ca03 emits four metrics from a single $display:

        $display("METRIC: total_cycles=%0d pte_reads=%0d tlb_hits=%0d hit_pct=%0d", ...)

    so it reported pte_reads, tlb_hits and hit_pct as DECLARED, NEVER EMITTED
    while all three sit in every d_ca03 run record. A checker whose failure mode
    is a false positive, nearly shipped because an independent audit had flagged
    the same tasks -- the agreement looked like corroboration and was
    coincidence, which is the shape this repo has now filed four times.
    """
    out = set()
    for f in glob.glob(os.path.join(task_dir, "tb", "*.sv")):
        for line in open(f, errors="replace"):
            if "METRIC:" not in line:
                continue
            body = line.split("METRIC:", 1)[1]
            # TWO EMIT SHAPES, and conflating them produced junk names.
            #   METRIC: total_cycles=%0d pte_reads=%0d      -> each name= is a metric
            #   METRIC: crossing_latency_rdclk min=%0d max=%0d n=%0d
            #                                               -> ONE metric, then sub-fields
            # The discriminator is the first token: if it carries no `=`, it is
            # the metric name and everything after it qualifies it. Without this
            # the checker reported `min`, `max`, `n`, `ok` and `expected` as
            # undeclared metrics -- noise that would have buried the two real
            # findings under fourteen false ones.
            toks = body.split()
            if toks and "=" not in toks[0]:
                out.add(re.sub(r"[^A-Za-z_0-9].*$", "", toks[0]))
            else:
                out |= set(re.findall(r"([A-Za-z_][A-Za-z_0-9]*)\s*=", body))
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
        emi = emitted(d)
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
            print(f"      EMITTED, NOT DECLARED:   {', '.join(extra)}")
        if ppa:
            print(f"      PPA FIELD IN sim METRICS: {', '.join(ppa)}"
                  f"  (can never appear in a sim record)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
