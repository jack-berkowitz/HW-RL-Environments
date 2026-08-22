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
    return stem not in ("reference", "ref") and stem not in RT.WITHHELD_MODELS


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
    return funnel, faults


def sync_readme_alt():
    """Rewrite the two <img alt="..."> strings in README.md from the data."""
    path = os.path.join(REPO, "README.md")
    if not os.path.isfile(path):
        return False
    src = open(path, encoding="utf-8").read()
    funnel, faults = alt_texts()
    out = src
    for asset, alt in (("funnel_light.svg", funnel),
                       ("verification_faults_light.svg", faults)):
        pat = re.compile(r'(<img alt=")([^"]*)("\s+src="docs/assets/'
                         + re.escape(asset) + r'")')
        esc_alt = alt.replace("&", "&amp;").replace('"', "&quot;")
        out = pat.sub(lambda m: m.group(1) + esc_alt + m.group(3), out)
    if out != src:
        open(path, "w", encoding="utf-8").write(out)
        return True
    return False


def main():
    check = "--check" in sys.argv
    os.makedirs(OUT, exist_ok=True)
    stale = []
    for name, fn in (("funnel", funnel_svg), ("verification_faults", faults_svg)):
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
