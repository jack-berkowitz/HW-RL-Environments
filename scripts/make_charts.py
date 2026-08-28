#!/usr/bin/env python3
"""Generate the README's SVG charts FROM THE RUN RECORDS.

    make_charts.py            # writes docs/assets/*.svg, light and dark
    make_charts.py --check    # regenerate to a temp buffer and diff; exit 1 if
                              # the committed SVGs are stale

WHY THIS IS A SCRIPT AND NOT HAND-DRAWN SVG
-------------------------------------------
The previous charts were hand-written. Hand-written charts drift from the
tables beside them, and they drift silently: the bar is a number typed twice.
Three defects shipped that way -- a design bar divided by 13 while showing 12,
a verification bar divided by 11 while showing 12 (it overflowed its 150px
track at 164px), and a "Results at a glance" paragraph still quoting 6.4x and
13.9x after the tables had been corrected to 6.0x and 14.2x.

Every number here is read from `runs/*/*.json` through report_table's own
loader, so a chart cannot disagree with the table unless the loader does.

WHAT IT DOES NOT DO. It does not decide what is scoreable. It asks
report_table for that, because a second opinion about validity is a second
source of truth, which is the defect this script exists to remove.
"""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import report_table as RT                                   # noqa: E402

REPO = RT.REPO
OUT = os.path.join(REPO, "docs", "assets")

# Light and dark are the SAME geometry with a swapped palette. Two hand-drawn
# files meant every fix had to be made twice, and once it was not.
THEMES = {
    "light": dict(fg="#1a1a1a", mute="#666", grid="#d8d8d8", bg="none",
                  bar="#2f6feb", bar2="#7aa5f0", dead="#e3e3e3", rule="#c00"),
    "dark":  dict(fg="#e8e8e8", mute="#9a9a9a", grid="#3a3a3a", bg="none",
                  bar="#5b8dfb", bar2="#2f4f8f", dead="#333", rule="#ff6b6b"),
}


def esc(s):
    return (str(s).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace('"', "&quot;"))


def current_task_hash(task):
    """The task text as it stands now, or None if it cannot be hashed."""
    if task in _TT_CACHE:
        return _TT_CACHE[task]
    val = None
    for d in glob.glob(os.path.join(REPO, "domains", "*", "*", task)):
        try:
            sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
            from task_text_hash import task_text_hash
            val = task_text_hash(d)[0]
        except Exception:
            val = None
    _TT_CACHE[task] = val
    return val


def answers_current_prompt(rec):
    """False only when the record demonstrably answers a SUPERSEDED task text.

    The report withholds those rows (rule 17 / F38). A chart that counted them
    anyway would show a submission as correct while the table beside it says
    "not scored against this prompt" -- the chart/table divergence this whole
    script exists to remove. d_dsp02's spec moved from 5ad30593403b4ae2 to
    13e3c4673f8a3270 and made this concrete for five submissions.

    "unknown" and absent both mean NO recorded hash, which is not evidence of
    staleness; those still count (rule 20, absence is not a negative).
    """
    cur = current_task_hash(rec.get("task") or "")
    rh = rec.get("task_text_hash")
    if not cur or rh in (None, "", "unknown"):
        return True
    return rh == cur


_TT_CACHE = {}


def latest_by(kind, pred):
    """Newest record per (task, submission) matching pred."""
    best = {}
    for r in RT.load_records():
        if r.get("kind") != kind or not pred(r):
            continue
        k = (r.get("task"), r.get("submission"))
        if k not in best or r.get("timestamp_utc", "") >= best[k].get("timestamp_utc", ""):
            best[k] = r
    return best


def model_of(rec):
    sub = rec.get("submission") or ""
    return os.path.basename(sub)[:-3] if sub.endswith(".sv") else rec.get("label", "?")


def candidate_files(prefix):
    """Every model submission on DISK for tasks starting with `prefix`.

    THE FILESYSTEM IS THE DENOMINATOR, NOT `runs/`. A submission that fails
    the synthesis frontend, or does not compile, may never produce a run
    record at all -- so counting submissions from records silently drops
    exactly the ones that did worst. Measured: 10 design rows had records
    against 16 files on disk, which would have published 8 correct of 10
    (80%) for a true 8 of 16 (50%). Absence of a record is an OUTCOME, and
    rule 20's prescription is that it renders, not that it disappears.

    `reference.sv` is the anchor, not a competitor, and is excluded. Nothing
    else is filtered by name: an allowlist of model slugs dropped v_ca03's
    `claude.sv` on its first run, because that slug was missing from a
    presentation map that had no business deciding what counts as a result."""
    out = []
    for d in sorted(glob.glob(os.path.join(REPO, "candidates", prefix + "*"))):
        for f in sorted(glob.glob(os.path.join(d, "*.sv"))):
            stem = os.path.basename(f)[:-3]
            # No reference filter is needed any more: `candidates/` holds
            # submissions only. The five `reference.sv` files that used to live
            # here were duplicates of each task's own tb/ and have been removed,
            # so membership of this directory is the definition of a submission.
            if stem in RT.WITHHELD_MODELS:
                continue
            out.append((os.path.basename(d), stem,
                        os.path.relpath(f, REPO)))
    return out


def is_submission(rec):
    """True when this record is one of the on-disk model submissions."""
    sub = rec.get("submission") or ""
    if not sub.startswith("candidates/"):
        return False
    stem = os.path.basename(sub)[:-3] if sub.endswith(".sv") else ""
    # Historical records still cite `candidates/<task>/reference.sv` from before
    # those duplicates were removed. Records are immutable, so the name check
    # stays HERE, where it filters history, and is gone from candidate_files(),
    # where it filtered the present.
    if stem in ("reference", "ref") or stem in RT.WITHHELD_MODELS:
        return False
    # THE SUBMISSION MUST STILL BE ON DISK. A record whose .sv has been withdrawn
    # is history, not a live row. Two chart paths disagreed on this: the funnel
    # enumerates candidates/ and dropped the withdrawn deepseek and qwen files
    # immediately, while this one iterates RECORDS and kept rendering them, so
    # the same page carried tables without those models and a chart with them.
    # candidate_files() already treats directory membership as the definition of
    # a submission; this makes the record path agree.
    return os.path.isfile(os.path.join(REPO, sub))


def verification_rows():
    """(task, model, caught, ceiling, state) for every scored submission.

    state: 'scored' | 'invalid' | 'gate' | 'nobuild' | 'unmeasured'
    """
    rows = []
    for (task, sub), r in sorted(latest_by(
            "sim", lambda r: str(r.get("task", "")).startswith("v_")
            and is_submission(r) and answers_current_prompt(r)).items()):
        m = model_of(r)
        caught = str(r.get("faults_caught", ""))
        disc = r.get("discriminates")
        golden = r.get("golden_accepted")
        if golden in ("unknown", None) and r.get("conformant_accepted") in ("0/0", None):
            state, n, ceil = "nobuild", 0, 0
        elif disc in ("false", False):
            state, n, ceil = "invalid", 0, 0
        elif caught.startswith("SUPPRESSED"):
            state, n, ceil = "gate", 0, 0
        elif "/" in caught:
            n, ceil = (int(x) for x in caught.split("/")[:2])
            state = "scored"
        else:
            state, n, ceil = "unmeasured", 0, 0
        rows.append((task, m, n, ceil, state))
    return rows


def funnel_counts():
    """Cumulative stages for each half, counted from records but DENOMINATED
    by the files on disk (see candidate_files)."""
    d_files = candidate_files("d_")
    d_sub = latest_by("sim", lambda r: str(r.get("task", "")).startswith("d_")
                      and is_submission(r) and answers_current_prompt(r))
    d_by_path = {r.get("submission"): r for r in d_sub.values()}
    d_total = len(d_files)
    d_built = sum(1 for _t, _m, p in d_files
                  if d_by_path.get(p, {}).get("configs_total"))
    d_correct = sum(1 for _t, _m, p in d_files
                    if d_by_path.get(p, {}).get("all_passed") is True)
    ppa = latest_by("ppa", lambda r: str(r.get("task", "")).startswith("d_")
                    and is_submission(r))
    p_by_path = {r.get("submission"): r for r in ppa.values()}
    d_ppa = sum(1 for _t, _m, p in d_files if p_by_path.get(p, {}).get("design_area_um2"))

    v_files = candidate_files("v_")
    vrows = {(t, m): (n, c, s) for t, m, n, c, s in verification_rows()}
    v_total = len(v_files)
    # A file with no record never built far enough to produce one.
    got = [vrows.get((_task_of(t), m), (0, 0, "norecord"))
           for t, m, _p in v_files]
    v_built = sum(1 for _n, _c, s in got if s not in ("nobuild", "norecord"))
    v_disc = sum(1 for _n, _c, s in got if s in ("scored", "gate"))
    v_scored = sum(1 for _n, _c, s in got if s == "scored")
    return ([("submitted", d_total), ("compiled", d_built),
             ("correct", d_correct), ("PPA measured", d_ppa)],
            [("submitted", v_total), ("compiled", v_built),
             ("tells correct from broken", v_disc), ("fault count", v_scored)])


def _task_of(candidate_dir):
    """candidates/v_ca05 -> the runs/ task name that starts with it."""
    for d in sorted(glob.glob(os.path.join(REPO, "runs", candidate_dir + "_*"))):
        return os.path.basename(d)
    return candidate_dir


def funnel_svg(theme):
    c = THEMES[theme]
    dsg, ver = funnel_counts()
    W, rowh, trackw, x0 = 900, 30, 300, 250
    H = 70 + rowh * (len(dsg) + len(ver) + 1)
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
         f'font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif">']
    p.append(f'<rect width="{W}" height="{H}" fill="{c["bg"]}"/>')
    y = 34
    for title, rows in (("Design tasks", dsg), ("Verification tasks", ver)):
        # DENOMINATOR IS THE FIRST STAGE OF THIS HALF, never a constant. The
        # overflow bug was a hard-coded divisor that stopped matching the data.
        denom = max(1, rows[0][1])
        p.append(f'<text x="20" y="{y}" fill="{c["fg"]}" font-size="15" '
                 f'font-weight="600">{esc(title)}</text>')
        y += 10
        for label, n in rows:
            y += rowh
            w = int(trackw * n / denom)
            p.append(f'<text x="{x0 - 12}" y="{y + 4}" fill="{c["mute"]}" '
                     f'font-size="13" text-anchor="end">{esc(label)}</text>')
            p.append(f'<rect x="{x0}" y="{y - 11}" width="{trackw}" height="16" '
                     f'rx="3" fill="{c["dead"]}"/>')
            if w:
                p.append(f'<rect x="{x0}" y="{y - 11}" width="{w}" height="16" '
                         f'rx="3" fill="{c["bar"]}"/>')
            p.append(f'<text x="{x0 + trackw + 12}" y="{y + 4}" fill="{c["fg"]}" '
                     f'font-size="13" font-weight="600">{n} of {denom}</text>')
        y += 22
    p.append('</svg>')
    return "\n".join(p)


def faults_svg(theme):
    c = THEMES[theme]
    rows = verification_rows()
    by_task = {}
    for t, m, n, ceil, st in rows:
        by_task.setdefault(t, []).append((m, n, ceil, st))
    W, barw, gap, groupgap, base = 900, 26, 8, 46, 210
    x = 60
    widths = []
    for t in sorted(by_task):
        widths.append(len(by_task[t]) * (barw + gap) + groupgap)
    W = max(W, int(60 + sum(widths) + 40))
    H = 300
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
         f'font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif">']
    p.append(f'<rect width="{W}" height="{H}" fill="{c["bg"]}"/>')
    maxv = max([ceil for _t, _m, _n, ceil, _s in rows if ceil] + [10])
    scale = 150.0 / maxv
    for gv in range(0, maxv + 1, 2):
        yy = base - gv * scale
        p.append(f'<line x1="52" y1="{yy}" x2="{W - 20}" y2="{yy}" '
                 f'stroke="{c["grid"]}" stroke-width="1"/>')
        p.append(f'<text x="44" y="{yy + 4}" fill="{c["mute"]}" font-size="11" '
                 f'text-anchor="end">{gv}</text>')
    for t in sorted(by_task):
        grp = by_task[t]
        gx0 = x
        ceil = max([ci for _m, _n, ci, _s in grp] or [0])
        for m, n, ci, st in grp:
            h = int(n * scale)
            lab = {"invalid": "invalid", "gate": "gate", "nobuild": "no build",
                   "unmeasured": "n/m"}.get(st, "")
            if h:
                p.append(f'<rect x="{x}" y="{base - h}" width="{barw}" height="{h}" '
                         f'rx="2" fill="{c["bar"]}"/>')
                p.append(f'<text x="{x + barw / 2}" y="{base - h - 6}" fill="{c["fg"]}" '
                         f'font-size="11" text-anchor="middle">{n}</text>')
            else:
                p.append(f'<rect x="{x}" y="{base - 6}" width="{barw}" height="6" '
                         f'rx="2" fill="{c["dead"]}"/>')
                p.append(f'<text x="{x + barw / 2}" y="{base - 12}" fill="{c["mute"]}" '
                         f'font-size="9" text-anchor="middle" '
                         f'transform="rotate(-90 {x + barw / 2} {base - 12})">{esc(lab)}</text>')
            p.append(f'<text x="{x + barw / 2}" y="{base + 14}" fill="{c["mute"]}" '
                     f'font-size="9" text-anchor="middle" '
                     f'transform="rotate(-40 {x + barw / 2} {base + 14})">'
                     f'{esc(RT.display_name(m).split()[0])}</text>')
            x += barw + gap
        if ceil:
            yy = base - ceil * scale
            p.append(f'<line x1="{gx0 - 4}" y1="{yy}" x2="{x - gap + 4}" y2="{yy}" '
                     f'stroke="{c["rule"]}" stroke-width="2" stroke-dasharray="5,3"/>')
        p.append(f'<text x="{(gx0 + x - gap) / 2}" y="{base + 62}" fill="{c["fg"]}" '
                 f'font-size="12" font-weight="600" text-anchor="middle">'
                 f'{esc(t.split("_")[0] + "_" + t.split("_")[1])}</text>')
        x += groupgap
    p.append(f'<text x="20" y="20" fill="{c["fg"]}" font-size="14" font-weight="600">'
             f'Seeded faults detected (dashed line = ceiling the reference achieves)</text>')
    p.append('</svg>')
    return "\n".join(p)


def alt_texts():
    """Alt text derived from the same counts as the bars.

    Hand-written alt text drifts exactly like a hand-written chart, and more
    quietly, because nobody rereads it. The README's funnel alt still claimed
    "12 submitted, 7 compiled" when the charts had moved to 22 and 16."""
    dsg, ver = funnel_counts()
    d = ", ".join(f"{lab} {n}" for lab, n in dsg)
    v = ", ".join(f"{lab} {n}" for lab, n in ver)
    funnel = (f"Cumulative stages, design and verification side by side. "
              f"Design: {d}. Verification: {v}.")
    rows = verification_rows()
    by = {}
    for task, m, n, ceil, st in rows:
        by.setdefault(task, []).append(
            f"{RT.display_name(m)} {n} of {ceil}" if st == "scored"
            else f"{RT.display_name(m)} not scoreable ({st})")
    faults = ("Seeded faults detected by each verification submission, against "
              "the ceiling its task's reference testbench achieves, shown as a "
              "dashed line per task. "
              + " ".join(f"{t.split('_')[0]}_{t.split('_')[1]}: "
                         + "; ".join(v) + "."
                         for t, v in sorted(by.items())))
    # THE DESIGN CHART ALTS WERE NOT IN THIS FUNCTION, and drifted for the
    # same reason the tables did. Only funnel and verification_faults were
    # generated, so after the pinned-period rename the area alt still read
    # "chat 1.80x, claude 1.05x" -- describing bars the chart no longer draws,
    # for the one class of reader who cannot see that it doesn't.
    def _bar_phrase(m, ratio, note):
        return f"{m} {ratio:.2f}x" if ratio else f"{m} {note}"

    drows = design_rows()
    area = ("Design area relative to each task's reference, at its pinned "
            "clock. " + " ".join(
                f"{lab} at {pin} ns, reference {ref_a:,.0f} um2: "
                + ", ".join(_bar_phrase(*b) for b in bars) + "."
                for _t, lab, pin, ref_a, bars, _pb in drows))
    power = ("Total power relative to each task's reference, at its pinned "
             "clock. " + " ".join(
                 f"{lab}: " + ", ".join(_bar_phrase(*b) for b in pbars) + "."
                 for _t, lab, _pin, _ra, _bars, pbars in drows))
    crows = capability_rows()
    cparts = []
    for _t, lab, _pin, keys, bars in crows:
        shown = [b for b in bars if b[1]]
        if not shown:
            continue
        if len(keys) > 1:
            cparts.append(f"{lab}, range over {len(keys)} declared metrics: "
                          + ", ".join(f"{b[0]} {b[1]:.2f}x to {b[2]:.2f}x"
                                      for b in shown) + ".")
        else:
            cparts.append(f"{lab} per {keys[0]}: "
                          + ", ".join(f"{b[0]} {b[1]:.2f}x" for b in shown) + ".")
    cap = ("Area per unit of capability, relative to each task's reference. "
           "Where a task declares several capability metrics the bar spans "
           "best to worst. " + " ".join(cparts))
    return funnel, faults, area, power, cap


def sync_readme_alt():
    """Rewrite EVERY generated <img alt="..."> string in README.md from data."""
    path = os.path.join(REPO, "README.md")
    if not os.path.isfile(path):
        return False
    src = open(path, encoding="utf-8").read()
    funnel, faults, area, power, cap = alt_texts()
    out = src
    for asset, alt in (("funnel_light.svg", funnel),
                       ("verification_faults_light.svg", faults),
                       ("design_area_light.svg", area),
                       ("design_power_light.svg", power),
                       ("design_capability_light.svg", cap)):
        pat = re.compile(r'(<img alt=")([^"]*)("\s+src="docs/assets/'
                         + re.escape(asset) + r'")')
        esc_alt = alt.replace("&", "&amp;").replace('"', "&quot;")
        out = pat.sub(lambda m: m.group(1) + esc_alt + m.group(3), out)
    if out != src:
        open(path, "w", encoding="utf-8").write(out)
        return True
    return False


# ---- design summary -------------------------------------------------------
# WHAT THIS CHART IS ALLOWED TO SHOW. Area RELATIVE TO THE REFERENCE, and only
# for submissions that closed timing at the task's pinned clock. Everything else
# is marked rather than plotted:
#
#   missed timing  -> slack is bought with area, so a design that missed and one
#                     that closed are not describing the same circuit (rule 22).
#                     Plotting its bar next to a closing one compares two
#                     different questions.
#   fails correctness -> scores zero on every PPA axis (rule 19). A zero-height
#                     bar would read as "very small", which is the opposite of
#                     what it means, so it gets a marker and a word.
#
# The reference line at 1.0 is the anchor: below it is smaller than the
# reference, above it is larger. Absolute µm² is in results_table.md; a ratio is
# what makes five tasks of different sizes readable on one axis.
DESIGN_PINS = [("d_ca04", "4.25", "async CDC FIFO"),
               ("d_nw03", "4.25", "stream switch"),
               ("d_dsp02", "19.25", "FP32 FMA"),
               ("d_dsp03", "70.5", "multi-format FMA"),
               ("d_nw01", "8.0", "AXI4 crossbar"),
               ("d_ca01", "15.0", "non-blocking D-cache"),
               ("d_ca03", "12.5", "Sv39 MMU")]
DESIGN_MODELS = ("chat", "claude", "gemini")


def design_rows():
    """[(task, label, pin, ref_area, [(model, ratio|None, note)])] for finished tasks."""
    out = []
    for short, pin, label in DESIGN_PINS:
        dirs = glob.glob(os.path.join(REPO, "domains", "*", "design", short + "_*"))
        if not dirs:
            continue
        task = os.path.basename(dirs[0])
        # SELECT BY THE FIELD, NOT BY THE FILENAME. This globbed
        # `*_fx{pin}__ppa.json` and split the label on "_fx", so it could only see
        # records written under the OLD label convention. When the pinned-period
        # work renamed those to `_pin19p25`, the glob stopped matching and the
        # charts silently kept rendering August records -- d_dsp02/claude at
        # 1.05x from area 63,197 while the current record says 61,305 and 1.02x.
        # Regenerating could not fix it; the SVGs came back byte-identical while
        # report_table, which selects on clk_period_ns and timestamp, had moved.
        #
        # AND IT FAILED CLOSED THE WRONG WAY. A task with only `pin`-named records
        # produced no bar and rendered "no result", which is indistinguishable
        # from a task never built -- absence reading as a measurement, the same
        # in-range failure value as configs_no_verdict.
        #
        # Identify-by-filename, found at four-plus sites in this repo. The period
        # is a FIELD in every record; matching it against the pin removes the
        # label convention from the decision entirely.
        best = {}
        for f in glob.glob(os.path.join(REPO, "runs", task, "*__ppa.json")):
            try:
                r = json.load(open(f))
            except Exception:
                continue
            try:
                if abs(float(r.get("clk_period_ns")) - float(pin)) > 1e-9:
                    continue
            except (TypeError, ValueError):
                continue
            who = re.split(r"_(?:fx|pin)", str(r.get("label", "")))[0]
            if who not in best or r.get("timestamp_utc", "") > best[who].get("timestamp_utc", ""):
                best[who] = r
        ref = best.get("reference")
        if not ref or not ref.get("design_area_um2"):
            continue
        ref_a = float(ref["design_area_um2"])
        ref_p = float(ref.get("power_w") or 0) or None
        bars, pbars = [], []
        for m in DESIGN_MODELS:
            r = best.get(m)
            if r is None:
                bars.append((m, None, "no result"))
                pbars.append((m, None, "no result"))
                continue
            wns = r.get("wns_ns")
            if wns is not None and float(wns) < 0:
                bars.append((m, None, "missed timing"))
                pbars.append((m, None, "missed timing"))
                continue
            a = r.get("design_area_um2")
            bars.append((m, float(a) / ref_a, "") if a else (m, None, "no area"))
            pw = r.get("power_w")
            pbars.append((m, float(pw) / ref_p, "") if (pw and ref_p)
                         else (m, None, "no power"))
        # A MODEL WITH NO PPA RECORD AT THE PIN IS NOT AUTOMATICALLY A
        # CORRECTNESS FAILURE. It may never have compiled, which is a different
        # fact about the model: "wrote wrong hardware" and "wrote something the
        # synthesis frontend rejects" are not the same result, and labelling
        # both "fails correctness" reported three build failures as functional
        # ones. The sim record says which -- build_status is set only when the
        # frontend refused it.
        sims = {}
        for f in glob.glob(os.path.join(REPO, "runs", task, "*__sim.json")):
            try:
                r = json.load(open(f))
            except Exception:
                continue
            w = r.get("label", "")
            if w not in sims or r.get("timestamp_utc", "") > sims[w].get("timestamp_utc", ""):
                sims[w] = r
        for m in DESIGN_MODELS:
            if best.get(m) is None:
                sm = sims.get(m) or {}
                note = "did not build" if sm.get("build_status") else "fails correctness"
                bars[DESIGN_MODELS.index(m)] = (m, None, note)
                pbars[DESIGN_MODELS.index(m)] = (m, None, note)
        out.append((task, label, pin, ref_a, bars, pbars))
    return out


def design_svg(theme, series="area"):
    """series="area" or "power" -- same shape, same exclusions, different axis."""
    c = THEMES[theme]
    rows = design_rows()
    W, x0, trackw = 900, 210, 480
    grouph, barh = 86, 15
    H = 84 + grouph * max(1, len(rows))
    # the axis spans 0..max ratio, with 1.0 (the reference) always on scale
    top = 1.0
    for row in rows:
        bars = row[4] if series == "area" else row[5]
        for _, ratio, _ in bars:
            if ratio:
                top = max(top, ratio)
    top = max(1.25, top * 1.08)
    def x_of(v):
        return x0 + trackw * (v / top)
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
         f'font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif">']
    p.append(f'<rect width="{W}" height="{H}" fill="{c["bg"]}"/>')
    p.append(f'<text x="20" y="26" fill="{c["fg"]}" font-size="15" font-weight="600">'
             + ('Design area' if series == "area" else 'Total power')
             + f' vs the reference, at each task\u2019s pinned clock</text>')
    p.append(f'<text x="20" y="45" fill="{c["mute"]}" font-size="12">'
             f'Lower is smaller. Only submissions that CLOSED TIMING are plotted \u2014 '
             f'see the notes for the rest.</text>')
    ytop, ybot = 58, H - 20
    # reference line at 1.0
    xr = x_of(1.0)
    p.append(f'<line x1="{xr}" y1="{ytop}" x2="{xr}" y2="{ybot}" stroke="{c["rule"]}" '
             f'stroke-width="1.5" stroke-dasharray="4 3"/>')
    p.append(f'<text x="{xr + 5}" y="{ytop + 10}" fill="{c["rule"]}" font-size="11">'
             f'reference (1.0\u00d7)</text>')
    y = ytop + 20
    for task, label, pin, ref_a, abars, pbars in rows:
        bars = abars if series == "area" else pbars
        p.append(f'<text x="20" y="{y + 10}" fill="{c["fg"]}" font-size="13" '
                 f'font-weight="600">{esc(label)}</text>')
        p.append(f'<text x="20" y="{y + 26}" fill="{c["mute"]}" font-size="11">'
                 f'{esc(task.split("_")[0] + "_" + task.split("_")[1])} @ {esc(pin)} ns'
                 f'</text>')
        yy = y
        for m, ratio, note in bars:
            p.append(f'<text x="{x0 - 10}" y="{yy + 11}" fill="{c["mute"]}" font-size="11" '
                     f'text-anchor="end">{esc(m)}</text>')
            p.append(f'<rect x="{x0}" y="{yy}" width="{trackw}" height="{barh}" rx="2" '
                     f'fill="{c["dead"]}" opacity="0.45"/>')
            if ratio:
                w = max(2, int(trackw * ratio / top))
                fill = c["bar"] if ratio <= 1.0 else c["bar2"]
                p.append(f'<rect x="{x0}" y="{yy}" width="{w}" height="{barh}" rx="2" '
                         f'fill="{fill}"/>')
                p.append(f'<text x="{x0 + w + 6}" y="{yy + 11}" fill="{c["fg"]}" '
                         f'font-size="11">{ratio:.2f}\u00d7</text>')
            else:
                p.append(f'<text x="{x0 + 6}" y="{yy + 11}" fill="{c["mute"]}" '
                         f'font-size="11" font-style="italic">{esc(note)}</text>')
            yy += barh + 5
        y += grouph
    p.append("</svg>")
    return "\n".join(p)


# ---- area per unit of capability ------------------------------------------
# THE QUESTION RAW AREA CANNOT ANSWER. A small design may be small because it
# does less. Area per unit of what the design DELIVERS asks how much it paid for
# what it provides, and it is the only one of the three charts where a submission
# can lose by being small.
#
# Measured, not hypothetical: d_ca04's submissions are 25-27% smaller than the
# reference at the same clock, and only 9-11% smaller per beat of FIFO capacity.
# Most of the headline gap is two spill registers the reference has and they do
# not. The raw number is true and answers a different question.
#
# ONLY TASKS THAT DECLARE A CAPABILITY METRIC APPEAR. d_dsp02 and d_ca03 declare
# none, so they are absent rather than shown with an invented axis -- "more is
# better and area buys it" is a claim about the contract, not something to infer
# from a metric name.
# ONE TASK DECLARES FOUR CAPABILITY METRICS AND THE ANSWER DEPENDS ON WHICH.
# d_nw01's chat is 2.59x the reference per burst delivered, 2.72x per disjoint
# pair, and 3.40x per outstanding transaction -- a 31% spread. Picking one and
# labelling it made the choice visible but still made it silently; a reader had
# no way to know that a different declared metric moves the number by a third.
#
# So a submission is drawn as a RANGE across every metric its task declares,
# endpoints labelled. Tasks declaring one metric collapse to a point and read
# exactly as before, which is three of the four here.
#
# The alternatives and why not: a geometric mean is a synthetic quantity no
# contract defines and would smuggle in the combined score this project refuses;
# worst-case-only penalises tasks for declaring MORE metrics, which is backwards
# since declaring more is better spec hygiene; one row per metric lets a
# four-metric task visually outweigh a one-metric task. A range says the true
# thing -- how much it paid per unit depends on which unit, and here is how much
# that matters.


def _capability_metrics(task_dir):
    # IMPORTED, NOT REIMPLEMENTED. The roles live in report_table.py and are a
    # claim about each task's CONTRACT -- which metric "more is better and area
    # buys it" applies to. A second copy here would drift from the table it is
    # supposed to illustrate, and the two would disagree about what a design is
    # being credited for.
    import importlib.util
    global _RT
    try:
        _RT
    except NameError:
        _spec = importlib.util.spec_from_file_location(
            "_rt", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "report_table.py"))
        _RT = importlib.util.module_from_spec(_spec)
        _spec.loader.exec_module(_RT)
    roles = _RT.metric_roles(task_dir)
    return sorted(k for k, v in roles.items() if v == "capability")


def _metric_value(task, label, key):
    """The metric across configs for one submission, from its newest sim record."""
    best = None
    for f in glob.glob(os.path.join(REPO, "runs", task, f"*__{label}__sim.json")):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        if best is None or r.get("timestamp_utc", "") > best.get("timestamp_utc", ""):
            best = r
    if not best:
        return None
    vals = []
    for cfg, m in (best.get("metrics") or {}).items():
        if key in m:
            try:
                vals.append(float(m[key]))
            except (TypeError, ValueError):
                pass
    return sum(vals) / len(vals) if vals else None


def capability_rows():
    out = []
    for short, pin, label in DESIGN_PINS:
        dirs = glob.glob(os.path.join(REPO, "domains", "*", "design", short + "_*"))
        if not dirs:
            continue
        task = os.path.basename(dirs[0])
        keys = _capability_metrics(dirs[0])
        if not keys:
            continue
        # SAME TWO DEFECTS AS design_rows, and the pairing made them worse.
        # The filename glob pinned the AREA numerator to old `_fx` records
        # while _metric_value read CURRENT sim records for the denominator, so
        # this chart divided an August area by an August-28 capability and
        # reported the quotient as a measurement. d_nw01's declared range read
        # 2.59x-3.40x built that way; on matched records it is 1.19x-6.79x.
        #
        # And there was no timing gate here at all. design_rows drops a
        # submission that missed its pin (rule 22); this one did not, so
        # d_ca01's `chat` drew a 0.67x capability bar while its area and power
        # were withheld two charts above for missing timing by 49 ps. A number
        # withheld on one axis cannot be published on another derived from it.
        best = {}
        for f in glob.glob(os.path.join(REPO, "runs", task, "*__ppa.json")):
            try:
                r = json.load(open(f))
            except Exception:
                continue
            try:
                if abs(float(r.get("clk_period_ns")) - float(pin)) > 1e-9:
                    continue
            except (TypeError, ValueError):
                continue
            w = re.split(r"_(?:fx|pin)", str(r.get("label", "")))[0]
            if w not in best or r.get("timestamp_utc", "") > best[w].get("timestamp_utc", ""):
                best[w] = r
        # RULE 22, applied here as it already was to area and power.
        for _w in [k for k in best if k != "reference"]:
            try:
                if float(best[_w].get("wns_ns")) < 0:
                    del best[_w]
            except (TypeError, ValueError):
                pass
        ref = best.get("reference")
        ref_lbl = None
        for cand in glob.glob(os.path.join(dirs[0], "ref", "*.sv")):
            ref_lbl = os.path.basename(cand)[:-3]
            if ref_lbl.endswith("_top"):
                break
        if not ref or not ref.get("design_area_um2"):
            continue
        ref_per = {}
        for k in keys:
            rc = _metric_value(task, ref_lbl, k)
            if rc:
                ref_per[k] = float(ref["design_area_um2"]) / rc
        if not ref_per:
            continue
        bars = []
        for m in DESIGN_MODELS:
            r = best.get(m)
            if r is None or r.get("design_area_um2") is None:
                bars.append((m, None, None, [], "not comparable"))
                continue
            if r.get("wns_ns") is not None and float(r["wns_ns"]) < 0:
                bars.append((m, None, None, [], "missed timing"))
                continue
            ratios = []
            for k, rp in ref_per.items():
                cap = _metric_value(task, m, k)
                if cap and rp:
                    ratios.append((k, (float(r["design_area_um2"]) / cap) / rp))
            if not ratios:
                bars.append((m, None, None, [], "no metric"))
                continue
            lo = min(ratios, key=lambda x: x[1])
            hi = max(ratios, key=lambda x: x[1])
            bars.append((m, lo[1], hi[1], ratios, ""))
        if any(b[1] for b in bars):
            out.append((task, label, pin, sorted(ref_per), bars))
    return out


def capability_svg(theme):
    c = THEMES[theme]
    rows = capability_rows()
    W, x0, trackw = 900, 250, 440
    grouph, barh = 86, 15
    H = 84 + grouph * max(1, len(rows))
    top = 1.0
    for _, _, _, _, bars in rows:
        for _, lo, hi, _, _ in bars:
            if hi:
                top = max(top, hi)
    top = max(1.25, top * 1.08)
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
         f'font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif">']
    p.append(f'<rect width="{W}" height="{H}" fill="{c["bg"]}"/>')
    p.append(f'<text x="20" y="26" fill="{c["fg"]}" font-size="15" font-weight="600">'
             f'Area PER UNIT OF CAPABILITY, vs the reference</text>')
    p.append(f'<text x="20" y="45" fill="{c["mute"]}" font-size="12">'
             f'Lower is cheaper for what it delivers. Where a task declares '
             f'several capability metrics, the bar spans best to worst.</text>')
    ytop, ybot = 58, H - 20
    xr = x0 + trackw * (1.0 / top)
    p.append(f'<line x1="{xr}" y1="{ytop}" x2="{xr}" y2="{ybot}" stroke="{c["rule"]}" '
             f'stroke-width="1.5" stroke-dasharray="4 3"/>')
    p.append(f'<text x="{xr + 5}" y="{ytop + 10}" fill="{c["rule"]}" font-size="11">'
             f'reference (1.0\u00d7)</text>')
    y = ytop + 20
    for task, label, pin, keys, bars in rows:
        p.append(f'<text x="20" y="{y + 10}" fill="{c["fg"]}" font-size="13" '
                 f'font-weight="600">{esc(label)}</text>')
        cap = (f'per {esc(keys[0])}' if len(keys) == 1
               else f'range over {len(keys)} declared metrics')
        p.append(f'<text x="20" y="{y + 26}" fill="{c["mute"]}" font-size="10">'
                 f'{cap}</text>')
        yy = y
        for m, lo, hi, ratios, note in bars:
            p.append(f'<text x="{x0 - 10}" y="{yy + 11}" fill="{c["mute"]}" font-size="11" '
                     f'text-anchor="end">{esc(m)}</text>')
            p.append(f'<rect x="{x0}" y="{yy}" width="{trackw}" height="{barh}" rx="2" '
                     f'fill="{c["dead"]}" opacity="0.45"/>')
            if lo:
                xlo = max(2, int(trackw * lo / top))
                xhi = max(2, int(trackw * hi / top))
                fill = c["bar"] if hi <= 1.0 else c["bar2"]
                if xhi - xlo < 3:
                    # ONE METRIC, OR ALL METRICS AGREE: a point, drawn as a bar
                    # so a single-metric task reads exactly as it did before.
                    p.append(f'<rect x="{x0}" y="{yy}" width="{xlo}" height="{barh}" '
                             f'rx="2" fill="{fill}"/>')
                    p.append(f'<text x="{x0 + xlo + 6}" y="{yy + 11}" fill="{c["fg"]}" '
                             f'font-size="11">{lo:.2f}\u00d7</text>')
                else:
                    # A RANGE. The bar runs to the BEST case and a lighter
                    # extension carries it to the worst, with both ends labelled
                    # -- so the eye reads the favourable number first and cannot
                    # miss how far the unfavourable one is.
                    p.append(f'<rect x="{x0}" y="{yy}" width="{xlo}" height="{barh}" '
                             f'rx="2" fill="{fill}"/>')
                    p.append(f'<rect x="{x0 + xlo}" y="{yy + 4}" width="{xhi - xlo}" '
                             f'height="{barh - 8}" fill="{fill}" opacity="0.42"/>')
                    p.append(f'<line x1="{x0 + xhi}" y1="{yy}" x2="{x0 + xhi}" '
                             f'y2="{yy + barh}" stroke="{fill}" stroke-width="2"/>')
                    p.append(f'<text x="{x0 + xhi + 6}" y="{yy + 11}" fill="{c["fg"]}" '
                             f'font-size="11">{lo:.2f}\u2013{hi:.2f}\u00d7</text>')
            else:
                p.append(f'<text x="{x0 + 6}" y="{yy + 11}" fill="{c["mute"]}" '
                         f'font-size="11" font-style="italic">{esc(note)}</text>')
            yy += barh + 5
        y += grouph
    p.append("</svg>")
    return "\n".join(p)


def main():
    check = "--check" in sys.argv
    os.makedirs(OUT, exist_ok=True)
    stale = []
    for name, fn in (("funnel", funnel_svg), ("verification_faults", faults_svg),
                     ("design_area", design_svg),
                     ("design_power", lambda th: design_svg(th, "power")),
                     ("design_capability", capability_svg)):
        for theme in THEMES:
            path = os.path.join(OUT, f"{name}_{theme}.svg")
            new = fn(theme) + "\n"
            old = open(path).read() if os.path.isfile(path) else None
            if check:
                if old != new:
                    stale.append(os.path.relpath(path, REPO))
            else:
                open(path, "w").write(new)
                print(f"  wrote {os.path.relpath(path, REPO)}")
    if check:
        if stale:
            print("  STALE -- these charts no longer match the run records:")
            for s in stale:
                print(f"    {s}")
            print("  Run scripts/make_charts.py. A chart that disagrees with the")
            print("  table beside it is the defect this check exists to catch.")
            return 1
        print("  charts match the run records.")
        if sync_readme_alt():
            print("  STALE -- README alt text did not match; updated it.")
            return 1
        print("  README alt text matches.")
    else:
        if sync_readme_alt():
            print("  updated README alt text")
    return 0


if __name__ == "__main__":
    sys.exit(main())
