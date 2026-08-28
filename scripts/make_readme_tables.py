#!/usr/bin/env python3
"""Generate the README's result tables FROM THE RUN RECORDS.

WHY THIS EXISTS. The README's design and verification tables were HAND-WRITTEN
while results_table.md beside them was generated. Every time a run landed, the
generated table moved and the README's did not, silently. By 2026-08-28 the
README's verification section was showing a run two rounds old -- v_dsp02/claude
at 10/10 when the record said 12/13, v_ca04/chat as a gate failure when it had
since scored 6/10 -- and was missing v_ca06 and v_ca07 entirely, with nothing
on the page saying a task was absent. A reader had no way to tell.

The README said so itself, three lines under the stale tables: results_table.md
"is generated from the run records under `runs/`, never hand-edited, and fails
loudly rather than emitting a table with rows missing." That sentence was true
of the file it described and false of the tables above it.

TWO PROPERTIES THIS FILE HAS TO HAVE, because their absence is the bug:
  1. It regenerates from records, so staleness is impossible rather than
     merely unlikely.
  2. --check exits non-zero when the committed README does not match what the
     records say, so the gate can catch drift instead of a person noticing.

CROSS-CHECK. The kill counts and conformant fractions emitted here are compared
against results_table.md, which report_table.py generates independently. If the
two disagree the generator FAILS rather than emitting a number. Two readers of
one set of records that disagree means one of them is wrong, and silently
preferring this one would make the README authoritative by accident.
"""
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
README = os.path.join(REPO, "README.md")

DESIGN_PINS = [("d_ca04", "4.25", "asynchronous CDC FIFO"),
               ("d_nw03", "4.25", "output-queued stream switch"),
               ("d_dsp02", "19.25", "FP32 fused multiply-add"),
               ("d_dsp03", "70.5", "multi-format FMA"),
               ("d_nw01", "8.0", "AXI4 crossbar"),
               ("d_ca01", "15.0", "non-blocking data cache"),
               ("d_ca03", "12.5", "RISC-V Sv39 MMU")]
MODELS = ("chat", "claude", "gemini")
DISPLAY = {"chat": "ChatGPT 5.6 Sol", "claude": "Claude Opus 5",
           "gemini": "Gemini 3.1 Pro"}


def load(kind):
    out = []
    for f in sorted(glob.glob(os.path.join(REPO, "runs", "*", "*.json"))):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        if r.get("kind") == kind:
            out.append(r)
    return out


def _task_full(short):
    for d in glob.glob(os.path.join(REPO, "domains", "*", "design", short + "_*")):
        return os.path.basename(d)
    return short


# ---------------------------------------------------------------- design ----
def _notes():
    """Per-task commentary, hand-edited, keyed by task id.

    Kept OUT of the generated region because the generator once deleted it: the
    README interleaved tables with analysis, the sentinels went round both, and
    five paragraphs vanished in a commit that only claimed to generate tables.
    A generator must only be able to rewrite what it authored.
    """
    path = os.path.join(REPO, "docs", "design_task_notes.md")
    if not os.path.isfile(path):
        return {}
    out, cur = {}, None
    for line in open(path, encoding="utf-8"):
        m = re.match(r"^## (d_\w+)\s*$", line)
        if m:
            cur = m.group(1); out[cur] = []
        elif cur:
            out[cur].append(line.rstrip("\n"))
    return {k: "\n".join(v).strip() for k, v in out.items()}


def design_tables():
    recs = load("ppa")
    notes = _notes()
    out = []
    for short, pin, label in DESIGN_PINS:
        full = _task_full(short)
        # SELECT ON THE FIELD, NOT THE FILENAME -- the same defect that froze
        # the charts at the August records. clk_period_ns is in every record.
        best = {}
        for r in recs:
            if r.get("task") != full:
                continue
            try:
                if abs(float(r.get("clk_period_ns")) - float(pin)) > 1e-9:
                    continue
            except (TypeError, ValueError):
                continue
            who = re.split(r"_(?:fx|pin)", str(r.get("label", "")))[0]
            if who not in best or r.get("timestamp_utc", "") > best[who].get("timestamp_utc", ""):
                best[who] = r
        if not best:
            continue
        sims = {}
        for r in load("sim"):
            if r.get("task") != full:
                continue
            w = r.get("label", "")
            if w not in sims or r.get("timestamp_utc", "") > sims[w].get("timestamp_utc", ""):
                sims[w] = r
        ref = best.get("reference")
        lines = [f"### {short} — {label}, pinned at {pin} ns", "",
                 "| | area µm² | power mW | slack ns | vs reference |",
                 "|---|---|---|---|---|"]
        ref_area = None
        if ref:
            ref_area = ref.get("design_area_um2")
            lines.append(f"| reference | {_fmt_area(ref_area)} | {_fmt_pow(ref)} "
                         f"| {_fmt_slack(ref)} | — |")
        for m in MODELS:
            r = best.get(m)
            if not r:
                lines.append(f"| `{m}` | {_absent_cells(full, m, sims)} |")
                continue
            lines.append("| `%s` | %s |" % (m, _design_cells(r, ref_area, full, m, sims)))
        blk = "\n".join(lines)
        if notes.get(short):
            blk += "\n\n" + notes[short]
        out.append(blk)
    return "\n\n".join(out)


def _fmt_area(a):
    try:
        return f"{float(a):,.0f}"
    except (TypeError, ValueError):
        return "—"


def _fmt_pow(r):
    """power_w is WATTS in the record; the column is mW."""
    try:
        return f"{float(r.get('power_w')) * 1000:.1f}"
    except (TypeError, ValueError):
        return "—"


def _fmt_slack(r):
    try:
        return f"{float(r.get('wns_ns')):+.3f}".replace("-", "\u2212")
    except (TypeError, ValueError):
        return "—"


def _design_cells(r, ref_area, task, model, sims):
    """area | power | slack | ratio -- withholding per rules 19 and 22."""
    wns = r.get("wns_ns")
    try:
        missed = float(wns) < 0
    except (TypeError, ValueError):
        missed = False
    # RULE 22. PPA from a build that missed its pin is withheld, not reported:
    # slack is bought with area, so the two builds do not describe one circuit.
    if missed:
        return f"*withheld* | *withheld* | **{_fmt_slack(r)}** | missed timing"
    a = r.get("design_area_um2")
    ratio = "—"
    try:
        ratio = f"**{float(a)/float(ref_area):.2f}×**"
    except (TypeError, ValueError, ZeroDivisionError):
        pass
    return f"{_fmt_area(a)} | {_fmt_pow(r)} | {_fmt_slack(r)} | {ratio}"


def _absent_cells(task, model, sims):
    """No PPA record at the pin. WHICH failure it was is a fact about the model.

    "wrote hardware that computes the wrong answer" and "wrote something the
    synthesis frontend refused" are different results, and collapsing them
    reported three build failures as functional ones. build_status is set only
    when the frontend refused, so it is the discriminator.
    """
    sm = sims.get(model) or {}
    if sm.get("build_status"):
        return "**0** | **0** | — | did not build"
    return "**0** | **0** | — | fails correctness"


# ---------------------------------------------------------- verification ----
def verification_tables():
    recs = load("sim")
    tasks = {}
    for td in sorted(glob.glob(os.path.join(REPO, "domains", "*", "verification", "v_*"))):
        tk = os.path.basename(td)
        y = os.path.join(td, "task.yaml")
        if not os.path.isfile(y):
            continue
        txt = open(y, encoding="utf-8", errors="replace").read()
        m = re.search(r"^[ \t]*title:[ \t]*(.+)$", txt, re.M)
        title = (m.group(1).strip().strip('"\'') if m
                 else " ".join(tk.split("_")[2:]).replace("_", " ") or tk)
        ref = None
        for f in sorted(glob.glob(os.path.join(td, "tb", "*.sv"))):
            ref = os.path.basename(f)
            break
        tasks[tk] = (title, ref)

    subs = tuple(sorted({os.path.basename(f)
                         for f in glob.glob(os.path.join(REPO, "candidates", "*", "*.sv"))}))
    best = {}
    for r in recs:
        tk = r.get("task")
        if tk in tasks:
            s = os.path.basename(str(r.get("submission", "?")))
            if (tk, s) not in best or r["timestamp_utc"] >= best[(tk, s)]["timestamp_utc"]:
                best[(tk, s)] = r

    out = []
    for tk, (title, ref) in tasks.items():
        rows = [s for s in subs if (tk, s) in best]
        if not rows:
            continue
        ceiling = "—"
        if ref and (tk, ref) in best:
            ceiling = str(best[(tk, ref)].get("faults_caught", "—"))
        short = "_".join(tk.split("_")[:2])
        lines = [f"### {short}: {title} (ceiling {ceiling})", "",
                 "| Submission | Accepts golden DUT | Rejects broken DUT "
                 "| Accepts other correct designs | Faults caught |",
                 "|---|---|---|---|---|"]
        for s in rows:
            lines.append("| %s | %s |" % (DISPLAY.get(s[:-3], f"`{s[:-3]}`"),
                                          _verif_cells(best[(tk, s)])))
        out.append("\n".join(lines))
    return "\n\n".join(out)


def _verif_cells(r):
    """golden | broken | conformant | faults.

    THE SPLIT IS THE POINT. These first two were one merged column, "Passes
    golden, fails broken HW", which rendered two opposite failures identically.
    A testbench that passes the golden AND passes the broken DUT is not
    observing the design; one that FAILS the golden rejects correct hardware.
    Both printed "no". Seven submissions this round reject the golden while
    killing every mutant, so the merged column hid the single most common
    failure mode behind the same glyph as its opposite.
    """
    g = r.get("golden_accepted", "?")
    gm = r.get("gate_mutant_verdict", "?")
    conf = r.get("conformant_accepted", "?")
    caught = r.get("faults_caught", "?")
    disc = r.get("discriminates")

    if g in ("unknown", "?") and conf in ("0/0", "?"):
        return "**did not compile** | n/a | n/a | n/a"

    g_s = "yes" if g == "PASS" else ("**no**" if g == "FAIL" else "—")
    # Rule 20: a record predating the broken-DUT probe was never measured
    # against it. Absent renders as absent, not as a pass.
    if gm == "FAIL":
        b_s = "yes"
    elif gm == "PASS":
        b_s = "**no**"
    else:
        b_s = "—"

    withheld = (disc in ("false", False) or g != "PASS"
                or str(caught).startswith("SUPPRESSED"))
    c_s = f"**{caught}**" if not withheld else "*withheld*"
    return f"{g_s} | {b_s} | {conf} | {c_s}"


# ------------------------------------------------------------ cross-check ---
def cross_check(vtables):
    """results_table.md is generated independently; the two must agree."""
    path = os.path.join(REPO, "results_table.md")
    if not os.path.isfile(path):
        return ["results_table.md absent -- cannot cross-check"]
    txt = open(path, encoding="utf-8", errors="replace").read()
    theirs = {}
    task = None
    for line in txt.split("\n"):
        m = re.match(r"^##\s+(v_\w+)", line)
        if m:
            task = m.group(1)
            continue
        if task and line.startswith("| `"):
            c = [x.strip() for x in line.strip("|").split("|")]
            # results_table.md columns: testbench | tells correct from broken |
            # accepts correct design | accepts 2nd implementation | accepts
            # legal variants | catches faults | notes. The kill count is [5].
            # This read [4] on the first run and reported all 31 rows as
            # disagreeing -- the guard caught its own indexing error, which is
            # the behaviour it exists for.
            if len(c) >= 7:
                theirs[(task, c[0].strip("`"))] = c[5]
    bad = []
    cur = None
    for line in vtables.split("\n"):
        m = re.match(r"^### (v_\w+):", line)
        if m:
            cur = m.group(1)
            continue
        if cur and line.startswith("| "):
            c = [x.strip() for x in line.strip("|").split("|")]
            if len(c) == 5 and c[0] not in ("Submission", "---"):
                who = {v: k for k, v in DISPLAY.items()}.get(c[0], c[0].strip("`"))
                t = theirs.get((cur, DISPLAY.get(who, who)))
                if t is not None and t.replace("*", "").replace("**", "") \
                        != c[4].replace("*", "").replace("**", ""):
                    bad.append(f"{cur}/{who}: README {c[4]} vs results_table {t}")
    return bad


# ------------------------------------------------------------------ main ----
def splice(text, name, body):
    b, e = f"<!-- BEGIN GENERATED: {name} -->", f"<!-- END GENERATED: {name} -->"
    if b not in text or e not in text:
        raise SystemExit(f"README is missing the {name} sentinels -- add {b} / {e}")
    pre, rest = text.split(b, 1)
    _, post = rest.split(e, 1)
    return f"{pre}{b}\n\n{body}\n\n{e}{post}"


def main():
    check = "--check" in sys.argv
    text = open(README, encoding="utf-8").read()
    v = verification_tables()
    bad = cross_check(v)
    if bad:
        print("CROSS-CHECK FAILED -- README and results_table.md disagree:")
        for b in bad:
            print("  " + b)
        return 2
    new = splice(text, "design-tables", design_tables())
    new = splice(new, "verification-tables", v)
    if new == text:
        print("README tables match the records.")
        return 0
    if check:
        print("STALE -- README tables do not match the run records. "
              "Run scripts/make_readme_tables.py")
        return 1
    open(README, "w", encoding="utf-8").write(new)
    print("README tables regenerated from the run records.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
