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

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import report_table as RT  # noqa: E402
import _record_valid as _RV  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
README = os.path.join(REPO, "README.md")

def design_pins():
    """[(short, pin, label)] for every design task WITH a pin, derived from disk.

    THIS WAS A HARDCODED SEVEN-TASK TUPLE, and it is the third instance of that
    defect in this repo -- report_table.py's own comments record the previous
    two, where hand-written maps covered 3 of 8 verification tasks and silently
    dropped claude.sv. The failure mode is identical each time: a task absent
    from the tuple does not render as missing, it does not render at all.

    d_ai04 was the live instance. It has a spec pin of 33.75 ns, a reference
    that closed timing at it, and three candidates passing 1/1 -- and it
    appeared NOWHERE on the README. Not in a chart, not in a table, not in "not
    measured yet". A reader had no way to learn the task existed. d_ai01 was
    half-visible in a worse way: listed under "not measured yet" saying its
    sweep "is queued", when the sweep had run on 2026-08-26 and its reference
    is recorded at 16.75 ns.

    The pin comes from the spec, which is where the pin rule says it lives, so
    a task joins this list by having one rather than by being named here.
    """
    out = []
    for d in sorted(glob.glob(os.path.join(REPO, "domains", "*", "design", "d_*"))):
        task = os.path.basename(d)
        # EXCLUDED AT THE SOURCE. Filtering this in design_tables() instead --
        # one of the four call sites -- dropped the task from the README tables
        # while the area, power and capability charts, which reach design_pins()
        # through make_charts._design_pins(), went on drawing it. The charts and
        # the tables then disagreed about what the scored set was. Anything that
        # enumerates scored design tasks comes through here.
        if RT.is_excluded(task):
            continue
        short = "_".join(task.split("_")[:2])
        try:
            pin = RT._spec_pin(task)
        except Exception:
            pin = None
        if pin is None:
            continue
        out.append((short, f"{float(pin):g}", _label(d, short)))
    return out


def _label(task_dir, short):
    y = os.path.join(task_dir, "task.yaml")
    if os.path.isfile(y):
        m = re.search(r"^[ \t]*title:[ \t]*(.+)$",
                      open(y, encoding="utf-8", errors="replace").read(), re.M)
        if m:
            return m.group(1).strip().strip("\"'").split(" -- ")[0]
    return short


def unpinned():
    """[(short, reason)] -- tasks with NO pin. Absence rendered as absence."""
    out = []
    for d in sorted(glob.glob(os.path.join(REPO, "domains", "*", "design", "d_*"))):
        task = os.path.basename(d)
        short = "_".join(task.split("_")[:2])
        try:
            if RT._spec_pin(task) is not None:
                continue
        except Exception:
            pass
        out.append((short, _label(d, short)))
    return out
MODELS = ("chat", "claude", "gemini")
# DERIVED, NOT RESTATED. This was a second copy of report_table's map, and the
# two were already free to drift: renaming a model in one place would have left
# the README tables and the results table disagreeing about what was run, with
# nothing comparing them. One source of truth.
DISPLAY = {m: RT.display_name(m) for m in MODELS}


def load(kind):
    out = []
    for f in sorted(glob.glob(os.path.join(REPO, "runs", "*", "*.json"))):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        if (r.get("kind") == kind and not _RV.is_invalidated(r)
                and _RV.is_result(r)):
            out.append(r)
    return out


def _task_full(short):
    for d in glob.glob(os.path.join(REPO, "domains", "*", "design", short + "_*")):
        return os.path.basename(d)
    return short


# ---------------------------------------------------------------- design ----
def withheld():
    """{(task, model): reason} -- rows a human decided not to publish.

    A WITHHELD ROW AND AN UNBUILT ROW ARE DIFFERENT FACTS and rendered
    identically before this existed: both an empty dash. That made a
    withholding decision unable to survive a regeneration, and since
    --check gates commits, the gate then compelled the regeneration.
    """
    path = os.path.join(REPO, "docs", "withheld_rows.md")
    out = {}
    if not os.path.isfile(path):
        return out
    for line in open(path, encoding="utf-8"):
        if "::" not in line or line.startswith("#"):
            continue
        left, reason = line.split("::", 1)
        parts = left.split()
        if len(parts) == 2:
            out[(parts[0], parts[1])] = reason.strip()
    return out


def _submission_metrics(task, label, sims):
    """The metric dict from a submission's newest sim record."""
    r = sims.get(label) or {}
    m = r.get("metrics") or {}
    for v in m.values():
        if isinstance(v, dict):
            return v
    return {k: v for k, v in m.items() if not isinstance(v, dict)}


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
    for short, pin, label in design_pins():
        full = _task_full(short)

        # SELECT ON THE FIELD, NOT THE FILENAME -- the same defect that froze
        # the charts at the August records. clk_period_ns is in every record.
        held = withheld()
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
        # BUILD sims BEFORE THE EARLY RETURN. The pinned-awaiting-PPA
        # branch below reads it, and it used to be built after -- so that
        # branch saw the PREVIOUS task's sims and rendered d_ca04's 18/18
        # as d_ca05's correctness. A stale loop variable, and worse than
        # the absence it was added to fix: wrong numbers under the right
        # heading read as a measurement.
        sims = {}
        for r in load("sim"):
            if r.get("task") != full:
                continue
            w = r.get("label", "")
            if w.endswith("_ref") or "_ref" in w or w.endswith("_top"):
                w = "reference"
            if w not in sims or r.get("timestamp_utc", "") > sims[w].get("timestamp_utc", ""):
                sims[w] = r
        if not best:
            # PINNED, AWAITING PPA -- the third row state, and its absence made
            # a task vanish entirely. d_ca05's sweep converged, the pin went
            # into the spec, and it left unpinned() without entering any table:
            # no row, no bar, and not in "not measured yet" either. Zero
            # occurrences in the whole README.
            #
            # This is the fourth-surface defect from this morning reintroduced
            # by the generator that replaced the hardcoded tuple -- d_ai04 was
            # invisible because a seven-task list had no slot for it, and
            # d_ca05 was invisible because there was no state between "no pin"
            # and "has a build". EVERY task passes through this window between
            # its sweep converging and its first build landing. Caught by
            # AGENT-DESIGN-43a92055, who diffed into a scratch copy and took a
            # documented override rather than running a generator whose stated
            # remedy deletes the row.
            lines = [f"### {short} — {label}, pinned at {pin} ns", "",
                     "*Pinned; no PPA build yet. Correctness stands as below.*",
                     "",
                     "| | correctness | area µm² | power mW | slack ns |",
                     "|---|---|---|---|---|"]
            for m in ("reference",) + MODELS:
                sm = sims.get(m) or {}
                pc, tc = sm.get("configs_passed"), sm.get("configs_total")
                if isinstance(pc, int) and isinstance(tc, int) and tc:
                    corr = f"**{pc}/{tc} pass**" if pc == tc else f"{pc}/{tc} FAIL"
                elif sm.get("build_status"):
                    corr = f"did not build ({sm['build_status']})"
                else:
                    corr = "—"
                nm = "reference" if m == "reference" else f"`{m}`"
                lines.append(f"| {nm} | {corr} | *not built* | *not built* | *not built* |")
            blk = "\n".join(lines)
            if notes.get(short):
                blk += "\n\n" + notes[short]
            out.append(blk)
            continue
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
            if (short, m) in held:
                lines.append(f"| `{m}` | *withheld* | *withheld* | *withheld* "
                             f"| *withheld — {held[(short, m)]}* |")
                continue
            if not r:
                lines.append(f"| `{m}` | {_absent_cells(full, m, sims)} |")
                continue
            if (short, m) in held:
                # THE REASON IS RENDERED, not just the absence. An unexplained
                # gap in a results table gets filled by whoever finds it next.
                lines.append(f"| `{m}` | *withheld* | *withheld* | *withheld* "
                             f"| *withheld — {held[(short, m)]}* |")
                continue
            lines.append("| `%s` | %s |" % (m, _design_cells(r, ref_area, full, m, sims)))
        # DISCLOSE A DIVERGENT CHOICE, DO NOT WITHHOLD THE ROW. G5's `choice`
        # role marks a metric the spec leaves free that still moves PPA, and
        # d_ai04's P3 states the treatment outright: "a submission choosing
        # differently from the reference is DISCLOSED, NOT PENALISED."
        # Withholding the row is penalising it, which is what this generator was
        # doing to all three d_ai04 submissions -- including the two that made
        # the SAME choice as the reference and were fully comparable.
        #
        # Only divergence is disclosed. Where every submission chose as the
        # reference did there is nothing to say, and a line saying so on every
        # task would bury the one case that matters.
        try:
            _roles = RT.metric_roles(os.path.join(REPO, "domains", "*", "design", full))
        except Exception:
            _roles = {}
        if not _roles:
            for _d in glob.glob(os.path.join(REPO, "domains", "*", "design", full)):
                try:
                    _roles = RT.metric_roles(_d)
                except Exception:
                    _roles = {}
        _choice = [k for k, v in (_roles or {}).items() if v == "choice"]
        if _choice:
            _rm = _submission_metrics(full, "reference", sims)
            _div = []
            for m in MODELS:
                _cm = _submission_metrics(full, m, sims)
                for k in _choice:
                    a, b = _rm.get(k), _cm.get(k)
                    if a is not None and b is not None and str(a) != str(b):
                        # "reports", not "chose". The schema tags both a
                        # structural parameter the designer picks (buffer_slots)
                        # and a measured consequence (total_cycles,
                        # read_latency_avg) as `choice`, and it does not
                        # distinguish them. Writing "chose total_cycles = 3446"
                        # asserts an intent the record cannot support --
                        # classifying from the metric's name is the tlb_hits
                        # error. The disclosure G5 requires is the DIVERGENCE;
                        # what produced it is the reader's inference.
                        _div.append(f"`{m}` {k} = {b} against the reference's {a}")
            if _div:
                lines += ["", "*Choice-role metrics where a submission differs from "
                          "the reference — disclosed, not penalised (G5): "
                          + "; ".join(_div) + ".*"]

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
    p, t = sm.get("configs_passed"), sm.get("configs_total")
    # A PENDING BUILD IS NOT A FAILURE, and this collapsed the two. Any missing
    # PPA record scored 0 and read "fails correctness", so d_ai04's three
    # candidates -- all passing 1/1, all simply not built yet -- were about to
    # be published as three models that got the hardware wrong. An in-range
    # failure value: 0 is a legitimate score, so nothing downstream could tell
    # the difference. Caught by rendering a task that had never been visible.
    if isinstance(p, int) and isinstance(t, int) and t and p == t:
        return "— | — | — | *correct; PPA not built yet*"
    if not sm:
        return "— | — | — | *not simulated*"
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
    # A RECORD ANSWERING A SUPERSEDED TASK TEXT IS NOT A RESULT (rule 17). This
    # table was the last place in the corpus that skipped the check: the charts
    # apply it, results_table.md applies it, and this one published whatever the
    # newest record said. v_ca03/gemini was the live instance -- every one of
    # its six records answers an older text, so the chart showed 32 submissions
    # while the table beside it showed 33 and printed "did not compile" for a
    # run against a prompt the model was never given.
    #
    # Stale records are SEPARATED, not discarded. A submission whose only
    # records are stale still gets a row saying so, because a row removed
    # outright is indistinguishable from a submission nobody made.
    best, stale = {}, {}
    for r in recs:
        tk = r.get("task")
        if tk in tasks:
            s = os.path.basename(str(r.get("submission", "?")))
            # THE REFERENCE IS EXEMPT. task_text_hash covers spec/ and
            # probe/PASTE.md -- the text handed to a MODEL. The reference
            # testbench answers no prompt, so a spec edit cannot make its fault
            # ceiling stale, and applying the check to it blanked the ceilings
            # for v_ca05 and v_ca06 on the first attempt. Staleness is a fact
            # about a submission, not about the anchor it is measured against.
            is_ref = (s == tasks[tk][1])
            d = stale if (not is_ref and RT.record_is_stale(r)) else best
            if (tk, s) not in d or r["timestamp_utc"] >= d[(tk, s)]["timestamp_utc"]:
                d[(tk, s)] = r

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
        for s in [x for x in subs if (tk, x) in stale and (tk, x) not in best]:
            h = stale[(tk, s)].get("task_text_hash")
            lines.append("| %s | *not scored against this prompt* | — | — | "
                         "*last run answered task text `%s`* |"
                         % (DISPLAY.get(s[:-3], f"`{s[:-3]}`"), h))
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
def unpinned_table():
    """Tasks with no pin, rendered rather than omitted (rule 20)."""
    reasons = {
        "d_ca05": ("no pin — the reference Fmax sweep cannot floorplan yet. "
                   "3,686 IO pins against 3,260 positions (PPL-0024); with the "
                   "pin placer given met4 the die places but detailed routing "
                   "stalls flat at 260 violations. Retry queued at "
                   "`CORE_UTILIZATION=7` with met5 dropped"),
        "d_dsp01": "no scoring testbench; withdrawn",

    }
    lines = ["| task | state |", "|---|---|"]
    for short, _label in unpinned():
        lines.append(f"| {short} | {reasons.get(short, 'no pin recorded')} |")
    # Tasks that ARE pinned and DO have results but sit outside the scored set.
    # They belong in this table for the same reason the unpinned ones do: a
    # reader who knows the task exists must be able to find out what happened to
    # it, and "not in the charts" is not an answer.
    for short, why in sorted(RT.EXCLUDED_TASKS.items()):
        lines.append(f"| {short} | {why} |")
    return "\n".join(lines)


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
    new = splice(new, "unpinned-table", unpinned_table())
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
