#!/usr/bin/env python3
"""Cross-model results table, written for a reader outside this project.

    python3 scripts/report_table.py            # markdown to stdout

AUDIENCE: someone who knows what area and Fmax mean and has never seen this
repo. So: no internal metric keys, no `!ungated`, no clause numbers without
their meaning. Everything that qualifies a number appears IN THE ROW, not in a
footnote -- a reader scanning the table must not be able to miss that a number
is a build failure, is non-compliant with the scored configuration, or predates
a control.

NO COMPOSITE SCORE, ever. Per-axis only. A single figure of merit would have to
weight area against frequency against capability, and nothing in this project
establishes those weights -- see FINDINGS.md on area-delay, which was retired
for exactly that reason.

Verification tasks are NOT in this table. Kill rate against a known ceiling is
not commensurable with area and frequency, and putting them in one grid would
invite a reader to average them.
"""
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Internal metric key -> what a reader should see. Presentation only; the
# records keep the internal names.
READABLE = {
    # Label deliberately non-committal. The checker calls this its C1 capacity
    # measure, but its own comment predicts the anchor reaching MAX_TRANS+1 = 9
    # at MAX_TRANS=8, and it measures 27. MAX_TRANS+1 holds exactly at
    # MAX_TRANS=2 (measured 3) and not at 8. Until that is understood the
    # number is comparable BETWEEN designs -- same harness, same config -- but
    # its units are not established, so no label asserts them. See the
    # unresolved note under the table.
    "outstanding_master0":          ("capacity (C1)", "checker's C1 capacity measure, master 0 — units unresolved, see note"),
    "disjoint_one_pair":            ("1-pair thruput", "bursts/1k cyc, one master-slave pair alone"),
    "disjoint_two_pairs":           ("2-pair thruput", "bursts/1k cyc, two disjoint pairs concurrently"),
    "aggregate_bursts_per_1000cyc": ("aggregate thruput", "bursts/1k cyc, all pairs"),
    "scored_beats_per_1000cyc":     ("beat rate", "data beats/1k cyc"),
    "capacity_beats_accepted":      ("FIFO capacity", "beats accepted before backpressure"),
    "crossing_latency_rdclk_min":   ("min crossing lat", "read-clock cycles, minimum"),
    "crossing_latency_rdclk_max":   ("max crossing lat", "read-clock cycles, maximum"),
    "wr_stall_cycles":              ("write stalls", "cycles the writer was blocked"),
    "latency_cycles":               ("latency", "clocks from accept to result"),
    "init_interval":                ("init interval", "clocks between accepts"),
}

TASK_TITLE = {
    "d_ca04_async_fifo_cdc": "d_ca04 — asynchronous CDC FIFO",
    "d_nw01_axi4_xbar":      "d_nw01 — AXI4 crossbar",
    "d_dsp02_fp32_fma_ii1":  "d_dsp02 — FP32 fused multiply-add",
}

# Submissions that failed to build. Rule 19: score zero on every PPA axis,
# annotated, never omitted.
# Submissions made BEFORE a requirement existed. Named explicitly with the
# evidence, never inferred: scoring a submission against a spec it was never
# given measures the spec change, not the model.
PREDATES_REQUIREMENT = {
    ("d_dsp02_fp32_fma_ii1", "chat.sv"):
        ("submitted 2026-08-15, before the 3-cycle latency requirement was added "
         "2026-08-16; the spec it was given said \"latency is not constrained\""),
}

# Absent for a reason that had to be ESTABLISHED, not assumed. Rule 20 says an
# unmeasured value renders absent; F31 says the reason for absence can itself be
# a finding.
PPA_UNAVAILABLE = {
    ("d_nw01_axi4_xbar", "chat.sv"):
        "place-and-route exceeded the 5.8 GB container memory limit during "
        "detailed routing (peak 5.70 GB) — a limit of this test setup, not a "
        "property of the design, which was at 75 DRC violations and improving",
}

BUILD_FAILURES = {
    ("d_nw01_axi4_xbar", "gemini.sv"):
        "anonymous struct as parameter value; confirmed on both frontends "
        "(slang 13 errors, Verilator 7)",
}


def load_records():
    out = []
    for f in sorted(glob.glob(os.path.join(REPO, "runs", "*", "*.json"))):
        try:
            out.append(json.load(open(f)))
        except Exception:
            pass
    return out


def scored_metrics(task_dir):
    """(key, label, expect) triples from the task's task.yaml."""
    p = os.path.join(task_dir, "task.yaml")
    if not os.path.isfile(p):
        return []
    out, inblock = [], False
    for line in open(p, encoding="utf-8"):
        if line.startswith("scored_metrics:"):
            inblock = True
            continue
        if inblock:
            if line.strip().startswith("#"):
                continue
            if not line.startswith(("  -", "   ")) and line.strip():
                break
            m = re.search(r"metric:\s*([A-Za-z0-9_]+)", line)
            if m:
                e = re.search(r"expect:\s*([A-Za-z0-9_.]+)", line)
                out.append((m.group(1), e.group(1) if e else None))
    return out


def task_dirs():
    d = {}
    for p in glob.glob(os.path.join(REPO, "domains", "*", "design", "*")):
        if os.path.isdir(p):
            d[os.path.basename(p)] = p
    return d


# EXPLICIT (task, submission) -> sweep file. Rule 10: name the artifact, never
# discover it by pattern. The first version fell back to the task-level sweep
# when a candidate had none, which printed the REFERENCE's Fmax on every
# candidate row -- attributing the reference's frequency to designs that had
# never been swept. Absent is the correct answer; a plausible wrong number is
# not.
FMAX_FILE = {
    ("d_ca04_async_fifo_cdc", "async_fifo_cdc_ref.sv"): "d_ca04_fmax.json",
    ("d_ca04_async_fifo_cdc", "chat.sv"):               "d_ca04_cand_chat_fmax.json",
    ("d_nw01_axi4_xbar",      "axi4_xbar_ref.sv"):      "d_nw01_fmax.json",
    ("d_dsp02_fp32_fma_ii1",  "fp32_fma_ii1_ref.sv"):   "d_dsp02_fmax.json",
}


def fmax_for(task, sub):
    """Fmax from THIS design's own sweep, or None. Never inferred, never
    borrowed from another design, never derived from a PPA build period."""
    name = FMAX_FILE.get((task, sub))
    if not name:
        return None, None
    p = os.path.join(REPO, "fmax_results", name)
    if not os.path.isfile(p):
        return None, None
    try:
        d = json.load(open(p))
    except Exception:
        return None, None
    if d.get("fmax_invalid_reason") is not None:
        return None, None          # rule 7: an invalid bracket is not an Fmax
    return d.get("achieved_fmax_mhz"), d.get("converged_period_ns")


# The configuration each task's metrics are read at (rule 18). Named
# explicitly; a metric averaged or last-written across configs is not a
# measurement at the scored configuration.
SCORED_CFG = {
    "d_ca04_async_fifo_cdc": "DATA_W_32_LOG_DEPTH_3_SYNC_STAGES_2",
    "d_nw01_axi4_xbar":      "NUM_MST_2_NUM_SLV_2_MAX_TRANS_8_MAX_BURST_LEN_255",
    "d_dsp02_fp32_fma_ii1":  None,   # single config, no parameters
}


def main():
    recs = load_records()
    tds = task_dirs()

    joined = {}
    for r in recs:
        key = (r.get("task"), os.path.basename(r.get("submission", "?")))
        slot = joined.setdefault(key, {"sim": None, "ppa": None})
        k = r.get("kind")
        if k in slot:
            if slot[k] is None or r["timestamp_utc"] >= slot[k]["timestamp_utc"]:
                slot[k] = r

    print("# Cross-model results\n")
    print("Three design tasks. Every design that was run appears, including the")
    print("reference implementation each task is anchored on.\n")
    print("**Per-axis only — there is deliberately no combined score.** A single")
    print("figure of merit would have to weight area against frequency against")
    print("capability, and nothing here establishes those weights.\n")

    any_ungated = False
    for task in sorted(TASK_TITLE):
        rows = sorted([k for k in joined if k[0] == task], key=lambda x: x[1])
        # add build failures that produced no record at all
        for (t, sub) in BUILD_FAILURES:
            if t == task and (t, sub) not in rows:
                rows.append((t, sub))
        if not rows:
            continue

        mets = scored_metrics(tds.get(task, ""))
        print(f"\n## {TASK_TITLE[task]}\n")

        hdr = ["design", "correctness", "area (µm²)", "power (mW)", "Fmax (MHz)"]
        for k, _ in mets:
            hdr.append(READABLE.get(k, (k, ""))[0])
        hdr.append("notes")
        print("| " + " | ".join(hdr) + " |")
        print("|" + "|".join("---" for _ in hdr) + "|")

        for key in rows:
            sub = key[1]
            v = joined.get(key, {"sim": None, "ppa": None})
            sim, ppa = v["sim"], v["ppa"]
            notes = []

            is_ref = "_ref" in sub or sub.startswith("async_fifo") or sub.startswith("axi4_xbar") or sub.startswith("fp32_fma")
            name = f"**reference**" if is_ref else f"`{sub[:-3]}`"

            bf = BUILD_FAILURES.get(key)
            if bf:
                # Rule 19: zero on the PPA axes, because a design that does not
                # build cannot be operated. But the METRIC cells are not zero --
                # nothing was measured, and "0" would read as "it built and
                # measured nothing". The zero is a SCORE; the metrics are absent.
                print("| " + " | ".join([name, "**did not build**", "**0**", "**0**", "**0**"]
                                        + ["n/a"] * len(mets)
                                        + [f"**build failure** — {bf}"]) + " |")
                continue

            corr = "—"
            if sim:
                corr = (f"**{sim.get('configs_passed')}/{sim.get('configs_total')} pass**"
                        if sim.get("all_passed")
                        else f"{sim.get('configs_passed')}/{sim.get('configs_total')} FAIL")

            area = power = fmx = "—"
            unavail = PPA_UNAVAILABLE.get(key)
            if unavail and not ppa:
                area = power = fmx = "n/a"
                notes.append(f"**area, power and Fmax unavailable** — {unavail}")
            if ppa:
                a = ppa.get("design_area_um2")
                area = f"{int(float(a)):,}" if a else "—"
                pw = ppa.get("power_w")
                power = f"{float(pw)*1000:.1f}" if pw else "—"
                if not ppa.get("correctness_gate"):
                    notes.append("PPA predates the correctness interlock")
                    any_ungated = True
            f_mhz, f_per = fmax_for(task, sub)
            if f_mhz:
                fmx = f"{f_mhz:.1f}"
            elif ppa:
                # Short: this stretched the Fmax column past the terminal width
                # in the fixed-width render. The build period is in the PPA
                # record and is not an Fmax, so it does not belong in this cell.
                fmx = "not swept"

            cells = [name, corr, area, power, fmx]
            # Metrics AT THE SCORED CONFIGURATION only. The first version
            # merged every config with dict.update, so each row showed whichever
            # config happened to be written last -- d_ca04's FIFO capacity read
            # 18 where the scored config gives 6.
            allm = ((sim or {}).get("metrics") or {})
            want = SCORED_CFG.get(task)
            if want is None:
                # Single-config task. If a run ever carries more than one, that
                # is ambiguity, not a choice to make silently (rule 20).
                if len(allm) == 1:
                    merged = next(iter(allm.values()))
                else:
                    merged = {}
                    if len(allm) > 1:
                        notes.append("multiple configurations present; no single "
                                     "scored configuration named")
            else:
                merged = allm.get(want, {})
                if allm and want not in allm:
                    notes.append(f"scored configuration {want} not present in this run")
            for k, expect in mets:
                if k not in merged:
                    cells.append("—")
                elif expect is not None and str(merged[k]) != str(expect):
                    pre = PREDATES_REQUIREMENT.get(key)
                    if pre:
                        # NOT a model failure. The submission answered the spec
                        # it was given, and the requirement was added later.
                        cells.append(f"{merged[k]} *(req. added later)*")
                        notes.append(f"**not scored against the current spec** — {pre}")
                    else:
                        cells.append(f"**{merged[k]}** (spec requires {expect})")
                        notes.append(f"does not implement the scored configuration: "
                                     f"{READABLE.get(k,(k,''))[0]} is {merged[k]}, "
                                     f"specification requires {expect}")
                else:
                    cells.append(str(merged[k]))
            cells.append("; ".join(notes) if notes else "")
            print("| " + " | ".join(cells) + " |")

        if mets:
            print()
            for k, _ in mets:
                lbl, desc = READABLE.get(k, (k, ""))
                if desc:
                    print(f"- **{lbl}** — {desc}")

    print("\n---\n")
    print("## Two measurement questions still open\n")
    print("Both affect how a number should be read, not whether it was measured.\n")
    print("**1. What the d_nw01 capacity figure counts.** The checker's own")
    print("comment predicts the reference reaching `MAX_TRANS + 1` = 9 at")
    print("`MAX_TRANS = 8`. It measures 27, consistently, across every geometry —")
    print("while at `MAX_TRANS = 2` it measures exactly 3, which *is* `MAX_TRANS + 1`.")
    print("The relation holds at one depth and not the other. The figures remain")
    print("comparable between designs, since every design is measured by the same")
    print("harness at the same configuration, but the units are not established")
    print("and nothing here should be read as \"27 concurrent transactions\".\n")
    print("**2. Whether the d_ca04 crossing latencies are comparable at all.**")
    print("Minimum crossing latency scales differently on each design: the")
    print("`gemini` submission tracks the synchroniser depth exactly (2 stages →")
    print("2 cycles, 3 → 3), `chat` tracks depth plus one, and **the reference is")
    print("flat at 3 regardless of depth**. Two of those are a plausible design")
    print("tradeoff. The third suggests the reference's fastest path may not")
    print("traverse the full synchroniser chain — in which case the metric is")
    print("sampling something different on that design and the three numbers are")
    print("not a like-for-like comparison. This also decides whether `gemini`'s")
    print("2-cycle crossing is a genuine result or an artefact. Unresolved.\n")

    # ---- verification tasks, SEPARATE TABLE -------------------------------
    print("\n---\n")
    print("# Verification task\n")
    print("**A different measurement, kept on its own table on purpose.** A")
    print("verification submission is a *testbench*, not a design: it is judged by")
    print("which implementations it accepts and rejects, and there is no area or")
    print("frequency to report. Putting it in the grid above would invite averaging")
    print("two things that do not share units.\n")
    print("## v_ca05 — tag tracker (out-of-order queue)\n")
    print("The model is given a port map and a written specification. **It never")
    print("sees the RTL.** It writes a testbench, which is then run against the")
    print("correct implementation and against deliberately faulty ones.\n")
    print("| testbench | accepts correct design | accepts legal variants | catches faults | notes |")
    print("|---|---|---|---|---|")
    print("| **our reference testbench** | yes | 4/4 | **6/6** | the ceiling; corrected after the fault set exposed two gaps in it |")
    print("| `chat` | yes | 4/4 | **2/6** | 3 faults hung it — no watchdog — and 1 went undetected |")
    print("| `gemini` | **no** | — | — | rejects the correct design; checks status before applying reset |")
    print()
    print("- **accepts correct design** — does it pass a known-good implementation?")
    print("  A testbench that rejects correct hardware is unusable whatever else it catches.")
    print("- **accepts legal variants** — four implementations that differ from the")
    print("  reference only where the specification is deliberately silent. A correct")
    print("  testbench must accept all four; failing one means it checked something")
    print("  the specification never promised.")
    print("- **catches faults** — six implementations each carrying one deliberate")
    print("  defect: capacity, ordering, starvation, boundary conditions, masked search.")
    print("  Every one is proven catchable.\n")
    print("**Reported per fault, never as a rate.** `chat`'s six outcomes are 2")
    print("caught, 3 hangs and 1 miss — four different problems, and a single")
    print("percentage hides all of them. A hang is not a catch: the testbench did")
    print("not detect the fault, it stopped, and a correct-but-slow design would")
    print("hang it identically.\n")
    print("**The headline result is that this worked at all.** `chat` wrote a")
    print("testbench from prose alone that accepts the correct design and all four")
    print("legal variants — no reliance on unspecified behaviour. That is the")
    print("finding; the fault-catching score is the weaker half.")

    if any_ungated:
        print("\n---\n")
        print("**\"PPA predates the correctness interlock\"** — these place-and-route")
        print("numbers were produced before the pipeline required a passing")
        print("correctness run first. All the designs so marked have since passed")
        print("correctness, so the numbers stand; the note records that nothing")
        print("enforced the ordering at the time they were taken.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
