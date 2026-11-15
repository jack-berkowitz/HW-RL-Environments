#!/usr/bin/env python3
"""Per-model results for the open-weight sweep, axis by axis, never blended.

    python3 scripts/summarize_sweep.py             # prints, and writes experiments/openweights/summary.md
    python3 scripts/summarize_sweep.py --ppa-plan  # PPA build commands for the PC

THE DENOMINATOR IS EVERY COMPLETED RESPONSE, not every scored file: an answer
with no extractable code, the wrong module or a truncated reply is a failure of
that sample, and dropping it would flatter the model that failed most. API
errors are the opposite -- the model never answered -- so they are excluded and
reported separately.

A verdict is matched to its answer by path AND content hash, so a record left
over from an earlier version of a file can never be counted for the current one.

pass@k is the unbiased estimator (Chen et al. 2021) averaged over tasks:
1 - C(n-c, k) / C(n, k) for n samples with c passing.
"""
import argparse
import glob
import json
import os
import re
import sys
from math import comb

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "experiments", "openweights")
DONE = {"ok", "no_code", "wrong_module", "truncated"}


def truthy(v):
    return v is True or str(v).lower() == "true"


def newest_records():
    """{(relpath, sha16): newest sim record} for sweep answers."""
    best = {}
    for f in glob.glob(os.path.join(REPO, "runs", "*", "*__sim.json")):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        sub = str(r.get("submission", ""))
        if "experiments/openweights/" not in sub:
            continue
        rel = sub[sub.index("experiments/openweights/"):]
        k = (rel, r.get("submission_sha256_16"))
        if k not in best or r.get("timestamp_utc", "") > best[k].get("timestamp_utc", ""):
            best[k] = r
    return best


def classify(kind, side, rec):
    """Outcome of one completed response, using the corpus's own categories."""
    if side.get("status") != "ok":
        return {"no_code": "no code", "wrong_module": "wrong module",
                "truncated": "truncated"}[side["status"]]
    if rec is None:
        return "unscored"
    if kind == "design":
        if rec.get("build_status") == "slang_rejected":
            return "did not build"
        built = int(rec.get("compile_configs_built") or 0)
        if truthy(rec.get("all_passed")):
            return "pass"
        return "fail" if built > 0 else "did not build"
    # verification -- mirrors make_charts.verification_rows()
    g, conf, fc = rec.get("golden_accepted"), rec.get("conformant_accepted"), str(rec.get("faults_caught", ""))
    if g in ("unknown", None) and conf in ("0/0", None):
        return "did not build"
    if not truthy(rec.get("discriminates")):
        return "invalid"
    if fc.startswith("SUPPRESSED"):
        return "rejects correct design"
    return "valid" if "/" in fc else "unmeasured"


def pass_at_k(n, c, k):
    if n < k:
        return None
    return 1.0 - comb(n - c, k) / comb(n, k)


def load():
    recs = newest_records()
    rows = []
    for side_path in sorted(glob.glob(os.path.join(OUT, "*", "*__s[0-9][0-9].json"))):
        side = json.load(open(side_path))
        if side.get("status") not in DONE:
            rows.append(dict(side=side, outcome="api error", rec=None))
            continue
        rec = None
        if side.get("sv"):
            rec = recs.get((side["sv"], side.get("sv_sha256_16")))
        rows.append(dict(side=side, outcome=classify(side["kind"], side, rec), rec=rec))
    return rows


def summarize(rows, k):
    models = sorted({r["side"]["model_tag"] for r in rows})
    lines = []
    lab = {r["side"]["model_tag"]: r["side"].get("model_label") or r["side"]["model_tag"] for r in rows}
    for kind in ("design", "verification"):
        good = "pass" if kind == "design" else "valid"
        lines.append(f"\n## {kind.capitalize()}\n")
        hdr = ["model", "answers", "API errors", "extracted", "built", f"{good}@1", f"{good}@{k}",
               f"tasks with ≥1 {good}"]
        if kind == "verification":
            hdr.append("faults caught (valid only)")
        lines.append("| " + " | ".join(hdr) + " |")
        lines.append("|" + "---|" * len(hdr))
        for m in models:
            rs = [r for r in rows if r["side"]["model_tag"] == m and r["side"]["kind"] == kind]
            done = [r for r in rs if r["outcome"] != "api error"]
            if not done:
                continue
            ext = sum(r["side"]["status"] == "ok" for r in done)
            built = sum(r["outcome"] not in ("no code", "wrong module", "truncated", "did not build",
                                             "unscored") for r in done)
            unscored = sum(r["outcome"] == "unscored" for r in done)
            per_task = {}
            for r in done:
                t = r["side"]["task_short"]
                n, c = per_task.get(t, (0, 0))
                per_task[t] = (n + 1, c + (r["outcome"] == good))
            p1 = [pass_at_k(n, c, 1) for n, c in per_task.values()]
            pk = [pass_at_k(n, c, k) for n, c in per_task.values()]
            p1 = sum(p1) / len(p1)
            pk_ok = [x for x in pk if x is not None]
            pk = (sum(pk_ok) / len(pk_ok)) if len(pk_ok) == len(per_task) else None
            hit = sum(c > 0 for n, c in per_task.values())
            cells = [lab[m], str(len(done)), str(len(rs) - len(done)), f"{ext}/{len(done)}",
                     f"{built}/{len(done)}" + (f" ({unscored} unscored)" if unscored else ""),
                     f"{p1:.2f}", "—" if pk is None else f"{pk:.2f}", f"{hit}/{len(per_task)}"]
            if kind == "verification":
                fr = []
                for r in done:
                    if r["outcome"] == "valid":
                        a, b = str(r["rec"]["faults_caught"]).split("/")[:2]
                        fr.append(int(a) / int(b))
                cells.append(f"{100 * sum(fr) / len(fr):.0f}% mean" if fr else "—")
            lines.append("| " + " | ".join(cells) + " |")
        # per-task matrix
        tasks = sorted({r["side"]["task_short"] for r in rows if r["side"]["kind"] == kind})
        lines.append(f"\n{good} / answers, per task:\n")
        lines.append("| task | " + " | ".join(lab[m] for m in models) + " |")
        lines.append("|---|" + "---|" * len(models))
        for t in tasks:
            cells = []
            for m in models:
                rs = [r for r in rows if r["side"]["model_tag"] == m and r["side"]["task_short"] == t
                      and r["outcome"] != "api error"]
                cells.append(f"{sum(r['outcome'] == good for r in rs)}/{len(rs)}" if rs else "—")
            lines.append(f"| {t} | " + " | ".join(cells) + " |")
    counts = {}
    for r in rows:
        counts[r["outcome"]] = counts.get(r["outcome"], 0) + 1
    lines.append("\nOutcome counts: " + ", ".join(f"{o}={n}" for o, n in sorted(counts.items())))
    return "\n".join(lines)


def ppa_plan(rows):
    """One PPA build per (model, task): the LOWEST-NUMBERED passing sample --
    a fixed rule, so the build isn't cherry-picked from the best-looking one."""
    sys.path.insert(0, os.path.join(REPO, "scripts"))
    import make_readme_tables as MT
    pins = {s: p for s, p, _ in MT.design_pins()}
    pick = {}
    for r in sorted(rows, key=lambda r: r["side"]["sample"]):
        s = r["side"]
        if s["kind"] == "design" and r["outcome"] == "pass":
            pick.setdefault((s["model_tag"], s["task_short"]), s)
    cmds = []
    for (m, t), s in sorted(pick.items()):
        pin = pins.get(t)
        if pin is None:
            continue
        lab = f"{m}__s{s['sample']:02d}_pin{str(pin).replace('.', 'p')}"
        if "." not in str(pin):
            lab += "p0"
        cmds.append(f"CLK_PERIOD_NS={pin} ./scripts/ppa_candidate.sh {t} {s['sv']} {lab}")
    return cmds


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--k", type=int, default=8)
    ap.add_argument("--ppa-plan", action="store_true")
    a = ap.parse_args()
    rows = load()
    if not rows:
        sys.exit("no sweep responses found under experiments/openweights/")
    if a.ppa_plan:
        cmds = ppa_plan(rows)
        print("\n".join(cmds) if cmds else "# no passing design answers yet")
        return 0
    text = "# Open-weight sweep\n" + summarize(rows, a.k)
    print(text)
    open(os.path.join(OUT, "summary.md"), "w").write(text + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
