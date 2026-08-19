#!/usr/bin/env python3
"""Results table, assembled ONLY from immutable run records under runs/.

THIS SCRIPT NEVER READS THE LIVE ORFS OUTPUT DIRECTORY.

An earlier version did, and that directory is shared and mutable: any concurrent
build rewrites it. During an Fmax sweep the d_nw01 row read `DID NOT COMPLETE`
-- which is ALSO the genuine finding about that task's candidate. A stale entry
that coincidentally matches a real result is the most dangerous form of the
defect, because nothing about it looks wrong. It would have gone into a writeup
unchallenged.

So: one row per (task, submission), joining correctness, capability and PPA from
records written at the moment each run happened, each carrying the submission's
content hash and the git SHA it was measured at.

If a task has no record, it is reported ABSENT. Collection never falls back to
whatever is on disk. A missing row is honest; a stale row is not.

    python3 scripts/collect_results.py              # newest record per submission
    python3 scripts/collect_results.py --all        # every record, chronological
    python3 scripts/collect_results.py --metrics    # add capability columns
"""
import glob
import json
import re
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNS = os.path.join(REPO, "runs")

# The configuration each task's metrics are read at (rule 18/20). Named
# explicitly. A task whose scored config is absent from a run reports ABSENT
# for every metric rather than substituting another config's values.
SCORED_CFG = {
    "d_ca04_async_fifo_cdc": "DATA_W_32_LOG_DEPTH_3_SYNC_STAGES_2",
    "d_nw01_axi4_xbar":      "NUM_MST_2_NUM_SLV_2_MAX_TRANS_8_MAX_BURST_LEN_255",
    "d_dsp02_fp32_fma_ii1":  None,   # single config, no parameters
}

ARGS = sys.argv[1:]
SHOW_ALL = "--all" in ARGS
SHOW_METRICS = "--metrics" in ARGS


def load_records():
    recs = []
    for f in sorted(glob.glob(os.path.join(RUNS, "*", "*.json"))):
        try:
            with open(f) as fh:
                r = json.load(fh)
            r["_path"] = os.path.relpath(f, REPO)
            recs.append(r)
        except (OSError, json.JSONDecodeError) as e:
            print(f"warning: unreadable record {f}: {e}", file=sys.stderr)
    return recs


def scored_metrics(task_dir_name):
    """Read `scored_metrics:` from a task.yaml. Generic by design -- the metric
    names live with the task, not in a per-task branch here, so adding a task
    does not mean editing this file.

    Parsed without a YAML library: pyyaml is not installed in this environment
    and the block is a fixed shape.
    """
    import glob as _g
    hits = _g.glob(os.path.join(REPO, "domains", "*", "design", task_dir_name,
                                "task.yaml"))
    if not hits:
        return []
    out, inblock = [], False
    for line in open(hits[0], encoding="utf-8", errors="replace"):
        if line.startswith("scored_metrics:"):
            inblock = True
            continue
        if inblock:
            if line.strip().startswith("- {"):
                m = re.search(r"metric:\s*([A-Za-z0-9_]+).*?label:\s*\"?([^\",}]+)",
                              line)
                if m:
                    e = re.search(r"expect:\s*([A-Za-z0-9_.]+)", line)
                    out.append((m.group(1), m.group(2).strip(),
                                e.group(1) if e else None))
            elif line.strip() and not line.startswith((" ", "\t", "-")):
                break
    return out


def known_tasks():
    out = []
    for d in sorted(glob.glob(os.path.join(REPO, "domains", "*", "design", "*"))):
        if os.path.isdir(d):
            out.append(os.path.basename(d))
    return out


def fmt(v, width, dash="--"):
    if v in (None, "", "None"):
        return dash.rjust(width)
    return str(v).rjust(width)


def _timing_ok(ppa):
    """False only when a PPA record explicitly reports negative slack.

    RULE 22. A build that missed timing describes a circuit that cannot run at
    the clock it was built at, so its area and power are not reportable. Absent
    or unparseable slack is NOT treated as a failure -- that would invent a
    verdict from missing data, which is the opposite error.
    """
    if not ppa:
        return True
    v = ppa.get("wns_ns")
    if v in (None, "", "None"):
        return True
    try:
        return float(v) >= 0.0
    except ValueError:
        return True


def main():
    recs = load_records()
    if not recs:
        print("No run records under runs/.")
        print("Nothing is inferred from the ORFS output directory -- run")
        print("scripts/sim_candidate.sh or scripts/ppa_candidate.sh to produce records.")
        return

    # join sim + ppa per (task, submission), newest of each kind
    # Verification tasks are scored on different axes and reported separately
    # (report_table.py keeps them on their own table). Including them here would
    # put a kill count in a column headed "configs".
    design_tasks = set(known_tasks())
    recs = [r for r in recs if r.get("task") in design_tasks]

    joined = {}
    for r in recs:
        key = (r["task"], r.get("submission", "?"))
        slot = joined.setdefault(key, {"sim": None, "ppa": None})
        kind = r.get("kind")
        if kind in slot:
            if slot[kind] is None or r["timestamp_utc"] >= slot[kind]["timestamp_utc"]:
                slot[kind] = r

    # A `provisional_` field was read from the LIVE ORFS flow directory rather
    # than from a completed, gated run. It is never reportable. Refusing loudly
    # rather than skipping silently, for the same reason the runner refuses an
    # absent artifact instead of picking a neighbour: an exclusion enforced by
    # naming convention is enforced only on people who know the convention, and
    # the next reader of this table will not.
    for (task, sub), v in sorted(joined.items()):
        for kind in ("sim", "ppa"):
            rec = v[kind]
            if not rec:
                continue
            bad = sorted(k for k in rec if k.startswith("provisional_"))
            if bad:
                sys.exit(
                    f"REFUSING TO REPORT: run record for {task} / "
                    f"{os.path.basename(sub)} ({kind}) carries provisional "
                    f"field(s): {', '.join(bad)}.\n"
                    f"  These come from the live flow directory, which holds "
                    f"whatever ran last -- twice now that has been a different "
                    f"experiment, once a run that failed its own gate.\n"
                    f"  Re-run through ppa_candidate.sh so the number has a "
                    f"record, or delete the field. Do not hand-edit it into a "
                    f"reportable name."
                )

    rows = []
    for (task, sub), v in sorted(joined.items()):
        sim, ppa = v["sim"], v["ppa"]
        rows.append({
            "task": task,
            "submission": os.path.basename(sub),
            "sha": (sim or ppa or {}).get("submission_sha256_16", "")[:8],
            # .get, not [] -- a VERIFICATION record has no configs_passed, and
            # indexing crashed the whole table when v_ca05 started writing
            # records into the same tree. A missing field renders absent, which
            # is rule 20's prescription; it is not a fallback inventing a value.
            "configs": (f"{sim.get('configs_passed')}/{sim.get('configs_total')}"
                        if sim and sim.get("configs_total") is not None else None),
            # THREE states, not two. `all_passed` MISSING is not the same as
            # `all_passed` false: the first means nothing was measured, the
            # second means the design failed. Rendering absence as FAIL made
            # every design sim record written after 607d97f -- whose verdict
            # block was silently dropped -- read as a result about the design.
            # A blank cell sends someone to measure; FAIL sends them to debug
            # RTL that is fine. Rule 20: unmeasured renders absent, and here it
            # is named rather than blank so it cannot be mistaken for a gap in
            # the table itself.
            "correct": (None if not sim
                        else "PASS" if sim.get("all_passed") is True
                        else "FAIL" if sim.get("all_passed") is False
                        else "NO VERDICT"),
            "clk": (ppa or {}).get("clk_period_ns"),
            # RULE 22 -- withheld, not printed, when the build missed timing.
            # The same gate lives in report_table.py. It is duplicated on
            # purpose: this is the second renderer, and a control that only one
            # reader applies is bypassed by using the other one.
            "area": (None if not ppa else
                     (ppa.get("design_area_um2") if _timing_ok(ppa) else "withheld")),
            # Rounded for DISPLAY ONLY -- the record keeps full precision.
            # Unrounded it overran its column and printed flush against the
            # area, so "294555" and "0.00365752" read as one 13-digit number.
            "wns": (lambda v: (f"{float(v):.4f}" if v not in (None, "", "None")
                               else None))((ppa or {}).get("wns_ns")),
            "power": (None if not ppa else
                      (ppa.get("power_w") if _timing_ok(ppa) else "withheld")),
            # A PPA record written before the correctness gate moved into
            # ppa_candidate.sh carries no correctness_gate field. It is not
            # necessarily wrong -- d_ca04/gemini.sv later passed 18/18 -- but
            # nothing established that AT THE TIME, so it is shown as
            # UNVERIFIED rather than silently as a clean result.
            "ppa": ((ppa or {}).get("status") if not ppa else
                    (ppa.get("status") if ppa.get("correctness_gate")
                     else f"{ppa.get('status')}!ungated")),
            "when": (sim or ppa)["timestamp_utc"][:16].replace("T", " "),
        })

    cols = [("task", 24), ("submission", 18), ("sha", 9), ("configs", 8),
            ("correct", 11), ("clk", 7), ("area", 11), ("wns", 8),
            ("power", 10), ("ppa", 20), ("when", 18)]
    hdr = "".join(c.rjust(w) if c not in ("task", "submission") else c.ljust(w)
                  for c, w in cols)
    print(hdr)
    print("-" * len(hdr))
    for r in rows:
        line = ""
        for c, w in cols:
            v = r.get(c)
            line += (str(v or "--").ljust(w) if c in ("task", "submission")
                     else fmt(v, w))
        print(line)

    # tasks with no record at all -- reported, never inferred
    have = {t for t, _ in joined}
    missing = [t for t in known_tasks() if t not in have]
    if missing:
        print()
        print("ABSENT (no run record; nothing inferred from disk):")
        for t in missing:
            print(f"  {t}")

    # ---- scored performance metrics, per rule 18 ---------------------------
    # One section per task, columns named by that task's task.yaml. A metric a
    # task NAMES but no run PRODUCED reports ABSENT rather than blank -- rule 8's
    # reasoning: a missing value must be visibly missing, because a blank cell
    # reads as zero or as "not interesting" and neither is true.
    print()
    print("SCORED PERFORMANCE METRICS (rule 18 -- measured at the scored configuration)")
    any_task = False
    for (task, sub), v in sorted(joined.items()):
        cols = scored_metrics(task)
        if not cols:
            continue
        any_task = True
        sim = v["sim"]
        percfg = (sim or {}).get("metrics") or {}
        # RULE 20: metrics come from THE SCORED CONFIGURATION, never merged
        # across configs. This previously did setdefault across every config,
        # so a row showed whichever config happened to be encountered first --
        # d_nw01's capacity differs by 9x between MAX_TRANS 2 and 8, so the
        # merged value was a coin flip presented as a measurement.
        want = SCORED_CFG.get(task)
        if want is None:
            merged = percfg[list(percfg)[0]] if len(percfg) == 1 else {}
            if len(percfg) > 1:
                merged = {}          # ambiguous: absent, never a pick
        else:
            merged = percfg.get(want, {})
        hdr = "  " + f"{task}/{os.path.basename(sub)}".ljust(38)
        line = "  " + " ".ljust(38)
        for name, label, expect in cols:
            hdr += label.rjust(14)
            if name not in merged:
                line += "ABSENT".rjust(14)
            elif expect is not None and str(merged[name]) != str(expect):
                # Measured value disagrees with what the scored configuration
                # requires. Not a correctness failure -- the checker is silent
                # on this by design -- but the submission does not implement
                # the configuration the task scores at.
                line += f"{merged[name]}!={expect}".rjust(14)
            else:
                line += str(merged[name]).rjust(14)
        print(hdr)
        print(line)
    if not any_task:
        print("  (no task names scored_metrics, or no sim records exist)")

    if SHOW_METRICS:
        print()
        print("CAPABILITY METRICS (from the sim record, per config)")
        for (task, sub), v in sorted(joined.items()):
            sim = v["sim"]
            if not sim or not sim.get("metrics"):
                continue
            print(f"\n  {task}  {os.path.basename(sub)}")
            for cfg, m in sorted(sim["metrics"].items())[:4]:
                items = " ".join(f"{k}={val}" for k, val in sorted(m.items()))
                print(f"    {cfg}\n      {items}")
            if len(sim["metrics"]) > 4:
                print(f"    ... {len(sim['metrics']) - 4} more configs in {sim['_path']}")

    if SHOW_ALL:
        print()
        print("ALL RECORDS, chronological")
        for r in sorted(recs, key=lambda x: x["timestamp_utc"]):
            print(f"  {r['timestamp_utc']}  {r['kind']:<4} {r['task']:<24} "
                  f"{os.path.basename(r.get('submission','?')):<18} {r['_path']}")


if __name__ == "__main__":
    main()
