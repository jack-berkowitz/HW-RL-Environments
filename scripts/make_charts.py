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
import math
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
                  bar="#2f6feb", bar2="#7aa5f0", dead="#e3e3e3", rule="#c00",
                  f_invalid="#e8663d", f_gate="#d9a520", f_nobuild="#8a8f98",
                  barlbl="#ffffff"),
    "dark":  dict(fg="#e8e8e8", mute="#9a9a9a", grid="#3a3a3a", bg="none",
                  bar="#5b8dfb", bar2="#2f4f8f", dead="#333", rule="#ff6b6b",
                  f_invalid="#ff7a52", f_gate="#e8b53a", f_nobuild="#7d838d",
                  barlbl="#0d1b3a"),
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
            # A task held out of the scored set contributes no submissions to
            # any denominator. This is the single choke point: funnel_counts,
            # every design chart and the faults chart all read this function, so
            # excluding here cannot leave one chart disagreeing with another.
            if RT.is_excluded(os.path.basename(d)):
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
    # A SCORABLE PPA, NOT MERELY A PPA FIELD. This counted every submission
    # carrying design_area_um2, which made the last stage of a CUMULATIVE funnel
    # LARGER than the stage above it -- 22 "PPA measured" under 21 "correct" --
    # and nothing flagged a funnel that went up. Two ways in:
    #
    #   * d_ca01/gemini has an area from a synthesis run but is not correct, so
    #     the number describes hardware that does not do the job.
    #   * five builds closed with NEGATIVE slack (d_ca01/chat -0.049,
    #     d_ca03/chat -35.46, d_dsp02/chat -22.92, d_nw03/chat -0.184,
    #     d_nw03/gemini -0.266). Rule 22: a build that missed timing yields no
    #     reportable PPA, because area and power at an unmet clock are not
    #     comparable with area and power at the pin.
    #
    # 22 - 1 - 5 = 16, which is what a reader counting the published per-task
    # tables gets by hand.
    def _scorable_ppa(path):
        if d_by_path.get(path, {}).get("all_passed") is not True:
            return False
        pr = p_by_path.get(path, {})
        if not pr.get("design_area_um2"):
            return False
        try:
            w = float(pr.get("wns_ns"))
        except (TypeError, ValueError):
            return False
        # Negative zero is a miss that prints as a pass.
        return w >= 0 and not (w == 0 and math.copysign(1.0, w) < 0)

    d_ppa = sum(1 for _t, _m, p in d_files if _scorable_ppa(p))

    v_files = candidate_files("v_")
    vrows = {(t, m): (n, c, s) for t, m, n, c, s in verification_rows()}
    v_total = len(v_files)
    # A file with no record never built far enough to produce one.
    got = [vrows.get((_task_of(t), m), (0, 0, "norecord"))
           for t, m, _p in v_files]
    v_built = sum(1 for _n, _c, s in got if s not in ("nobuild", "norecord"))
    v_disc = sum(1 for _n, _c, s in got if s in ("scored", "gate"))
    v_scored = sum(1 for _n, _c, s in got if s == "scored")
    # A CUMULATIVE FUNNEL CANNOT WIDEN. Every stage is a subset of the one above
    # it, so a rise is always a counting bug, never data -- and the published
    # chart carried one (22 "PPA measured" beneath 21 "correct") through many
    # regenerations because nothing compared adjacent stages. Cheap to check,
    # and it fails loudly rather than rendering the impossible.
    def _monotone(stages, kind):
        for (an, av), (bn, bv) in zip(stages, stages[1:]):
            if bv > av:
                raise ValueError(
                    f"{kind} funnel widens: '{bn}'={bv} exceeds '{an}'={av}. "
                    f"Each stage must be a subset of the one before it.")
        return stages

    return (_monotone([("submitted", d_total), ("compiled", d_built),
                       ("correct", d_correct), ("scorable PPA", d_ppa)],
                      "design"),
            _monotone([("submitted", v_total), ("compiled", v_built),
                       # "discriminates" rather than "tells correct from
                       # broken": half the characters at the same meaning, and
                       # it is the name the records already use for the field.
                       # NOT "rejects correct hardware" -- this stage counts the
                       # testbenches that SURVIVE it, and the 16 here are
                       # precisely the ones that do NOT reject correct hardware.
                       # A funnel stage has to name what got through.
                       ("discriminates", v_disc),
                       ("fault count", v_scored)],
                      "verification"))


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
    """Seeded faults per submission, with the FAILURE MODE distinguishable.

    Two defects this rewrite fixes, both raised off the rendered chart rather
    than off the code.

    THE FAILURE MODES WERE INDISTINGUISHABLE. Every unscored submission drew the
    same 6px grey stub with a rotated 9pt label, so "rejects the golden DUT",
    "rejects a conformant design" and "does not compile" -- three different
    findings about a model -- looked identical at a glance, and the label was the
    only thing separating them. Half the corpus is in those states, so the chart
    was illegible exactly where it carried the most information. Each now has its
    own colour and a legend, and the stub is tall enough to read.

    THE CEILING RAN OFF THE TOP. Gridlines stepped `range(0, maxv+1, 2)`, so with
    v_dsp02's ceiling at 13 the topmost labelled line was 12 and the dashed rule
    sat above every gridline, touching the plot edge. The axis now covers the
    ceiling with headroom and always labels the maximum.
    """
    c = THEMES[theme]
    rows = verification_rows()
    by_task = {}
    for t, m, n, ceil, st in rows:
        by_task.setdefault(t, []).append((m, n, ceil, st))

    STATE = {"invalid":   ("rejects the golden DUT",   "f_invalid", "invalid"),
             "gate":      ("rejects a correct design", "f_gate",    "gate"),
             "nobuild":   ("does not compile",         "f_nobuild", "no build"),
             "unmeasured": ("not measured",            "f_nobuild", "n/m")}

    W, barw, gap, groupgap, base = 900, 26, 8, 46, 250
    x = 60
    W = max(W, int(60 + sum(len(by_task[t]) * (barw + gap) + groupgap
                            for t in by_task) + 40))
    H = 396
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
         f'font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif">']
    p.append(f'<rect width="{W}" height="{H}" fill="{c["bg"]}"/>')

    # HEADROOM ABOVE THE CEILING so the dashed rule is never the topmost pixel.
    maxv = max([ceil for _t, _m, _n, ceil, _s in rows if ceil]
               + [n for _t, _m, n, _c, _s in rows if n] + [10])
    step = 2 if maxv <= 16 else 4
    topv = maxv + (step - maxv % step) % step        # round up to a whole step
    scale = 160.0 / topv
    for gv in range(0, topv + 1, step):
        yy = base - gv * scale
        p.append(f'<line x1="52" y1="{yy}" x2="{W - 20}" y2="{yy}" '
                 f'stroke="{c["grid"]}" stroke-width="1"/>')
        p.append(f'<text x="44" y="{yy + 4}" fill="{c["mute"]}" font-size="11" '
                 f'text-anchor="end">{gv}</text>')

    for t in sorted(by_task):
        grp = by_task[t]
        gx0 = x
        ceil = max([ci for _m, _n, ci, _s in grp] or [0])
        ceil_y = base - ceil * scale if ceil else None
        for m, n, ci, st in grp:
            if n:
                h = int(n * scale)
                p.append(f'<rect x="{x}" y="{base - h}" width="{barw}" height="{h}" '
                         f'rx="2" fill="{c["bar"]}"/>')
                # A bar one fault under the ceiling put its value label straight
                # through the dashed rule: v_dsp02's 12 was drawn at y=107 with
                # the 13-line at y=101, so the number read as struck out. When
                # the two are within a label height, the value goes INSIDE the
                # bar instead. Only then -- moving every label would cost the
                # short bars, which have no room inside.
                ly_ = base - h - 6
                if ceil_y is not None and abs(ly_ - ceil_y) < 12 and h >= 24:
                    p.append(f'<text x="{x + barw / 2}" y="{base - h + 15}" '
                             f'fill="{c["barlbl"]}" font-size="11" font-weight="600" '
                             f'text-anchor="middle">{n}</text>')
                else:
                    p.append(f'<text x="{x + barw / 2}" y="{ly_}" fill="{c["fg"]}" '
                             f'font-size="11" text-anchor="middle">{n}</text>')
            else:
                # NO TEXT ABOVE THE STUB. The rotated per-bar label duplicated
                # what the colour already says and, at 9pt on its side, was the
                # least readable thing on the chart. Colour + legend carry it.
                _lbl, key, _short = STATE.get(st, ("", "dead", ""))
                p.append(f'<rect x="{x}" y="{base - 14}" width="{barw}" height="14" '
                         f'rx="2" fill="{c[key]}"/>')
            # THE SYSTEM, NOT THE LAB. `.split()[0]` reduced every tick to
            # "ChatGPT" / "Claude" / "Gemini", so the chart named three vendors
            # and no models -- a reader could not tell which system produced a
            # bar, and two of the three names did not even carry a version. The
            # short form keeps the version; the full configuration, reasoning
            # setting included, is in the key beneath the legend. Steeper
            # rotation because the longer strings would otherwise reach into the
            # neighbouring bar at this pitch.
            # ANCHOR AT THE END, NOT THE MIDDLE. A rotation pivots about the
            # anchor, so text-anchor="middle" sent half of every label back up
            # across the axis and over the bars -- measured: "Gemini 3.1"
            # reached y=243 with the axis at y=250, drawn in mute grey on top of
            # a blue bar, which reads as the label being clipped. With the end
            # anchored at the tick the whole string hangs below and to the left,
            # topmost y=262, and its 27px horizontal footprint stays inside the
            # 34px bar pitch so neighbours cannot overlap either.
            tx, ty = x + barw / 2, base + 12
            p.append(f'<text x="{tx}" y="{ty}" fill="{c["mute"]}" '
                     f'font-size="8.5" text-anchor="end" '
                     f'transform="rotate(-55 {tx} {ty})">'
                     f'{esc(RT.short_name(m))}</text>')
            x += barw + gap
        if ceil:
            yy = base - ceil * scale
            p.append(f'<line x1="{gx0 - 4}" y1="{yy}" x2="{x - gap + 4}" y2="{yy}" '
                     f'stroke="{c["rule"]}" stroke-width="2" stroke-dasharray="5,3"/>')
            p.append(f'<text x="{x - gap + 8}" y="{yy + 4}" fill="{c["rule"]}" '
                     f'font-size="10">{ceil}</text>')
        p.append(f'<text x="{(gx0 + x - gap) / 2}" y="{base + 80}" fill="{c["fg"]}" '
                 f'font-size="12" font-weight="600" text-anchor="middle">'
                 f'{esc(t.split("_")[0] + "_" + t.split("_")[1])}</text>')
        x += groupgap

    p.append(f'<text x="20" y="22" fill="{c["fg"]}" font-size="14" font-weight="600">'
             f'Seeded faults detected. Dashed line is the ceiling the reference achieves.</text>')

    # LEGEND. Without it the colours are decoration; with it they are the finding.
    lx, ly = 20, 40
    for key, txt in (("bar", "scored: faults caught"),
                     ("f_invalid", "rejects the golden DUT"),
                     ("f_gate", "rejects a correct design"),
                     ("f_nobuild", "does not compile")):
        p.append(f'<rect x="{lx}" y="{ly - 9}" width="11" height="11" rx="2" '
                 f'fill="{c[key]}"/>')
        p.append(f'<text x="{lx + 16}" y="{ly}" fill="{c["mute"]}" font-size="11">'
                 f'{esc(txt)}</text>')
        lx += 20 + 7.0 * len(txt)

    # THE KEY. Full names once, rather than under all 32 bars where they would
    # not fit. Ordering is not claimed: a task missing a submission would make a
    # "left to right" reading wrong, and one task has only two.
    seen, names = set(), []
    for _t, m, _n, _c, _s in rows:
        if m not in seen:
            seen.add(m)
            names.append(f"{RT.short_name(m)} = {RT.display_name(m)}")
    p.append(f'<text x="20" y="58" fill="{c["mute"]}" font-size="10.5">'
             f'{esc(",   ".join(names))}</text>')
    p.append('</svg>')
    return "\n".join(p)



def timing_rows():
    """(task, model, pin_ns, wns_ns, need_over_pin) for every CORRECT design.

    need_over_pin = (pin - wns) / pin: the clock period the design actually
    needs, as a multiple of the period its task pins. 1.00 is exactly at the
    pin, below it has margin, above it missed.

    WHY A RATIO AND NOT THE SLACK. The pins run from 4.25 ns to 70.5 ns, so a
    raw slack of -0.27 ns and one of -35.46 ns are not comparable quantities --
    the first is 6% over on a tight clock, the second is 3.8x over. Dividing by
    the pin is what makes one axis hold all ten tasks.

    Only correct submissions appear. A design that fails correctness has no
    timing story worth telling: it is not slow, it is wrong.
    """
    d_files = candidate_files("d_")
    sim = latest_by("sim", lambda r: str(r.get("task", "")).startswith("d_")
                    and is_submission(r) and answers_current_prompt(r))
    s_by = {r.get("submission"): r for r in sim.values()}
    ppa = latest_by("ppa", lambda r: str(r.get("task", "")).startswith("d_")
                    and is_submission(r))
    p_by = {r.get("submission"): r for r in ppa.values()}
    out = []
    for t, m, path in d_files:
        if s_by.get(path, {}).get("all_passed") is not True:
            continue
        pr = p_by.get(path, {})
        try:
            wns = float(pr.get("wns_ns"))
            pin = float(pr.get("clk_period_ns"))
        except (TypeError, ValueError):
            continue
        if pin <= 0:
            continue
        out.append((t, m, pin, wns, (pin - wns) / pin))
    out.sort(key=lambda r: r[4])
    return out


def timing_svg(theme):
    """The timing story: correctness is not the filter, the clock is.

    21 of 30 submissions are correct and 16 of those close timing, so the stage
    that removes the most working designs is the one the funnel used to hide by
    counting any build with an area field as a measured PPA.
    """
    c = THEMES[theme]
    rows = timing_rows()
    CAP = 1.25                       # axis top; two bars run past it
    W, x0, x1 = 900, 250, 840
    scale = (x1 - x0) / CAP
    pitch, barh, top = 15, 11, 118
    H = top + pitch * len(rows) + 56
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
         f'font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif">']
    p.append(f'<rect width="{W}" height="{H}" fill="{c["bg"]}"/>')
    met = sum(1 for *_r, rat in rows if rat <= 1.0)
    p.append(f'<text x="20" y="30" fill="{c["fg"]}" font-size="15" font-weight="700">'
             f'Correctness is not the filter. The clock is.</text>')
    p.append(f'<text x="20" y="52" fill="{c["mute"]}" font-size="11.5">'
             f'{esc(f"Clock period each correct design actually needs, as a multiple of the period its task pins. ")}'
             f'</text>')
    p.append(f'<text x="20" y="69" fill="{c["mute"]}" font-size="11.5">'
             f'{esc(f"{len(rows)} of 30 submissions are correct; {met} of those close timing at the pin.")}</text>')
    # legend
    p.append(f'<rect x="20" y="84" width="11" height="11" rx="2" fill="{c["bar"]}"/>')
    p.append(f'<text x="36" y="93" fill="{c["mute"]}" font-size="11">meets the pinned clock</text>')
    p.append(f'<rect x="196" y="84" width="11" height="11" rx="2" fill="{c["f_invalid"]}"/>')
    p.append(f'<text x="212" y="93" fill="{c["mute"]}" font-size="11">misses it</text>')

    ybot = top + pitch * len(rows)
    for gv in (0.25, 0.5, 0.75, 1.0, 1.25):
        gx = x0 + gv * scale
        isPin = abs(gv - 1.0) < 1e-9
        p.append(f'<line x1="{gx}" y1="{top - 6}" x2="{gx}" y2="{ybot + 2}" '
                 f'stroke="{c["rule"] if isPin else c["grid"]}" '
                 f'stroke-width="{2 if isPin else 1}"'
                 f'{" stroke-dasharray=\"5,3\"" if isPin else ""}/>')
        p.append(f'<text x="{gx}" y="{ybot + 16}" fill="{c["rule"] if isPin else c["mute"]}" '
                 f'font-size="10" text-anchor="middle">{gv:g}x</text>')
    p.append(f'<text x="{x0 + 1.0 * scale}" y="{top - 12}" fill="{c["rule"]}" '
             f'font-size="10.5" font-weight="600" text-anchor="middle">'
             f'the pinned clock</text>')

    for i, (t, m, pin, wns, rat) in enumerate(rows):
        y = top + i * pitch
        miss = rat > 1.0
        col = c["f_invalid"] if miss else c["bar"]
        w = min(rat, CAP) * scale
        p.append(f'<rect x="{x0}" y="{y}" width="{w:.1f}" height="{barh}" rx="2" fill="{col}"/>')
        short = t.split("_")[0] + "_" + t.split("_")[1]
        p.append(f'<text x="{x0 - 8}" y="{y + barh - 1}" fill="{c["mute"]}" '
                 f'font-size="10.5" text-anchor="end">'
                 f'{esc(short)}  {esc(RT.short_name(m))}</text>')
        if rat > CAP:
            # BROKEN BAR. 2.19x and 3.84x would set the scale for everyone else
            # and crush the 0.83-1.06 band where sixteen of the twenty-one sit.
            for k in range(3):
                zx = x1 - 12 + k * 5
                p.append(f'<path d="M{zx} {y} l5 {barh/2:.1f} l-5 {barh/2:.1f}" '
                         f'fill="none" stroke="{c["bg"] if c["bg"]!="none" else "#808080"}" '
                         f'stroke-width="1.5" opacity="0.55"/>')
            p.append(f'<text x="{x1 + 6}" y="{y + barh - 1}" fill="{col}" '
                     f'font-size="10.5" font-weight="700">{rat:.2f}x</text>')
        else:
            p.append(f'<text x="{x0 + w + 6:.1f}" y="{y + barh - 1}" '
                     f'fill="{col if miss else c["mute"]}" font-size="10.5"'
                     f'{" font-weight=\"700\"" if miss else ""}>{rat:.2f}x</text>')
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
    trows = timing_rows()
    tmet = sum(1 for *_x, rat in trows if rat <= 1.0)
    timing = ("Clock period each correct design actually needs, as a multiple of "
              "the period its task pins; 1.00x is exactly at the pin. "
              f"{len(trows)} submissions pass correctness and {tmet} of those "
              "close timing. " + "; ".join(
                  f"{t.split('_')[0]}_{t.split('_')[1]} {RT.display_name(m)} "
                  f"{rat:.2f}x" for t, m, _p, _w, rat in trows) + ".")
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
    return funnel, timing, faults, area, power, cap


def sync_readme_alt():
    """Rewrite EVERY generated <img alt="..."> string in README.md from data."""
    path = os.path.join(REPO, "README.md")
    if not os.path.isfile(path):
        return False
    src = open(path, encoding="utf-8").read()
    funnel, timing, faults, area, power, cap = alt_texts()
    out = src
    for asset, alt in (("funnel_light.svg", funnel),
                       ("timing_light.svg", timing),
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
# DERIVED FROM DISK, NOT LISTED HERE -- see make_readme_tables.design_pins for
# the full argument. A hardcoded seven-task tuple made d_ai04 invisible on every
# chart despite having a pin and a reference build, and it is the third instance
# of this shape in the repo.
def _design_pins():
    import make_readme_tables as _M
    return _M.design_pins()
DESIGN_MODELS = ("chat", "claude", "gemini")


def design_rows():
    """[(task, label, pin, ref_area, [(model, ratio|None, note)])] for finished tasks."""
    out = []
    for short, pin, label in _design_pins():
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
        # THE CHARTS MUST HONOUR THE SAME HOLD LIST AS THE TABLES. Withholding a
        # row from the table and drawing it as a bar two sections above is not a
        # withholding; the number is published either way, and the chart is the
        # more prominent of the two.
        import make_readme_tables as _MT
        _held = _MT.withheld()
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
            # WITHHELD IS ITS OWN STATE. Deleting the record instead made these
            # rows fall through to the absent-record branch and render "fails
            # correctness" -- turning a human's decision not to publish into a
            # false accusation against the model, which is worse than publishing
            # the number. Same in-range-failure-value trap as the empty dash,
            # walked into while fixing the empty dash.
            if (short, m) in _held:
                bars[DESIGN_MODELS.index(m)] = (m, None, "withheld")
                pbars[DESIGN_MODELS.index(m)] = (m, None, "withheld")
                continue
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
    import make_readme_tables as _MT
    _held = _MT.withheld()
    out = []
    for short, pin, label in _design_pins():
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
            # THE HOLD LIST APPLIES HERE TOO, and this is the THIRD time this
            # exact shape has bitten in this file. design_rows was taught to
            # honour withheld rows; capability_rows was not, so the moment
            # d_ca03 gained a capability metric the chart published
            # "claude 0.84x" while the table beside it said withheld.
            #
            # Suppressing a number in one artefact and drawing it in another is
            # not suppression. The pattern is that every NEW consumer of the
            # records starts out not knowing about the decision, so the decision
            # has to live where the records are read, not where they are
            # rendered -- which is the fix this comment does not implement.
            if (short, m) in _held:
                bars.append((m, None, None, [], "withheld"))
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
    for name, fn in (("funnel", funnel_svg), ("timing", timing_svg),
                     ("verification_faults", faults_svg),
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
