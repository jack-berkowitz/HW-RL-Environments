#!/usr/bin/env python3
"""Outcome chart for the open-weight sweep: one stacked bar per model, design
and verification side by side, every answer accounted for.

    python3 scripts/plot_sweep.py OUT.html [--title "..."] [--note "..."]

Reads the same rows as summarize_sweep.py, so the chart and the table cannot
disagree. Uses the palette of the README charts (make_charts.THEMES) so it sits
beside them in a deck.

"Cut off" is drawn hatched and kept apart from the failures on purpose: an
answer truncated at the token cap says nothing about the model's RTL, and
colouring it like a failure would turn a configuration problem into a finding.
"""
import argparse
import html
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import summarize_sweep as S                                    # noqa: E402

C = dict(fg="#1a1a1a", mute="#666", grid="#d8d8d8", pass_="#2f6feb", fail="#e8663d",
         gate="#d9a520", nobuild="#8a8f98", nocode="#c9ccd1", lbl="#ffffff")
ORDER = {  # (outcome, legend label, fill, label ink)
    "design": [("pass", "correct", C["pass_"], C["lbl"]),
               ("fail", "wrong answer", C["fail"], C["lbl"]),
               ("did not build", "did not build", C["nobuild"], C["lbl"]),
               ("wrong module|no code", "no usable code", C["nocode"], C["fg"]),
               ("truncated", "cut off (config)", "hatch", C["fg"])],
    "verification": [("valid", "valid testbench", C["pass_"], C["lbl"]),
                     ("invalid", "rejects working design", C["fail"], C["lbl"]),
                     ("rejects correct design", "rejects a correct variant", C["gate"], C["fg"]),
                     ("did not build", "did not build", C["nobuild"], C["lbl"]),
                     ("wrong module|no code", "no usable code", C["nocode"], C["fg"]),
                     ("truncated", "cut off (config)", "hatch", C["fg"])],
}


def counts(rows, kind):
    out = {}
    for r in rows:
        s = r["side"]
        if s["kind"] != kind or r["outcome"] == "api error":
            continue
        o = r["outcome"]
        if o in ("wrong module", "no code"):
            o = "wrong module|no code"
        out.setdefault(s["model_tag"], {}).setdefault(o, 0)
        out[s["model_tag"]][o] += 1
    return out


def panel(rows, kind, labels, x0, y0, w):
    cnt = counts(rows, kind)
    models = [m for m in labels if m in cnt]
    mine = [r for r in rows if r["side"]["kind"] == kind and r["outcome"] != "api error"]
    n_tasks = len({r["side"]["task_short"] for r in mine})
    n_samp = max(r["side"]["sample"] for r in mine)
    each = "one answer each" if n_samp == 1 else f"{n_samp} answers each"
    title = "Design" if kind == "design" else "Verification"
    p = [f'<text x="{x0}" y="{y0}" font-size="15" font-weight="600" fill="{C["fg"]}">'
         f'{title} <tspan fill="{C["mute"]}" font-weight="400">· {n_tasks} tasks, {each}</tspan></text>']
    lab_w, bar_x, bar_w, bh, gap = 150, x0 + 150, w - 150, 30, 18
    y = y0 + 22
    for m in models:
        p.append(f'<text x="{bar_x - 10}" y="{y + bh / 2 + 5}" text-anchor="end" font-size="13" '
                 f'fill="{C["fg"]}">{html.escape(labels[m])}</text>')
        total = sum(cnt[m].values())
        x = bar_x
        for key, name, fill, ink in ORDER[kind]:
            v = cnt[m].get(key, 0)
            if not v:
                continue
            sw = bar_w * v / total
            fa = "url(#hatch)" if fill == "hatch" else fill
            stroke = f' stroke="{C["nobuild"]}" stroke-width="1"' if fill == "hatch" else ""
            p.append(f'<g><title>{html.escape(labels[m])} — {name}: {v} of {total}</title>'
                     f'<rect x="{x + 1:.1f}" y="{y}" width="{max(sw - 2, 1):.1f}" height="{bh}" rx="3" '
                     f'fill="{fa}"{stroke}/>')
            if sw >= 22:
                p.append(f'<text x="{x + sw / 2:.1f}" y="{y + bh / 2 + 5}" text-anchor="middle" '
                         f'font-size="13" font-weight="600" fill="{ink}">{v}</text>')
            p.append('</g>')
            x += sw
        y += bh + gap
    # legend, in the stacking order
    lx, ly = bar_x, y + 4
    for key, name, fill, _ink in ORDER[kind]:
        fa = "url(#hatch)" if fill == "hatch" else fill
        stroke = f' stroke="{C["nobuild"]}"' if fill == "hatch" else ""
        p.append(f'<rect x="{lx}" y="{ly - 10}" width="12" height="12" rx="2" fill="{fa}"{stroke}/>'
                 f'<text x="{lx + 17}" y="{ly}" font-size="12" fill="{C["mute"]}">{name}</text>')
        lx += 30 + 6.6 * len(name)
        if lx > bar_x + bar_w - 120:
            lx, ly = bar_x, ly + 20
    return "\n".join(p), ly + 10


def table(rows, labels):
    head = "<tr><th>model</th><th>kind</th>" + "".join(f"<th>{h}</th>" for h in
           ("correct / valid", "wrong / invalid", "did not build", "no usable code", "cut off")) + "</tr>"
    body = []
    for kind in ("design", "verification"):
        cnt = counts(rows, kind)
        for m in labels:
            if m not in cnt:
                continue
            c = cnt[m]
            good = c.get("pass" if kind == "design" else "valid", 0)
            bad = c.get("fail" if kind == "design" else "invalid", 0) + c.get("rejects correct design", 0)
            body.append(f"<tr><td>{html.escape(labels[m])}</td><td>{kind}</td><td>{good}</td><td>{bad}</td>"
                        f"<td>{c.get('did not build', 0)}</td><td>{c.get('wrong module|no code', 0)}</td>"
                        f"<td>{c.get('truncated', 0)}</td></tr>")
    return f"<table>{head}{''.join(body)}</table>"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--title", default="Open-weight models on the benchmark")
    ap.add_argument("--note", default="")
    a = ap.parse_args()
    rows = S.load()
    labels = {}
    for r in rows:
        s = r["side"]
        labels.setdefault(s["model_tag"], (s.get("model_label") or s["model_tag"]).split(" (")[0])
    W = 980
    d, h1 = panel(rows, "design", labels, 20, 30, W - 40)
    v, h2 = panel(rows, "verification", labels, 20, h1 + 40, W - 40)
    svg = (f'<svg viewBox="0 0 {W} {h2 + 10}" xmlns="http://www.w3.org/2000/svg" role="img" '
           f'font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif">'
           f'<defs><pattern id="hatch" width="6" height="6" patternUnits="userSpaceOnUse" '
           f'patternTransform="rotate(45)"><rect width="6" height="6" fill="#ffffff"/>'
           f'<line x1="0" y1="0" x2="0" y2="6" stroke="{C["nobuild"]}" stroke-width="2"/></pattern></defs>'
           f'{d}{v}</svg>')
    page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Open-Weight Sweep</title>
<style>
:root{{--bg:#fcfcfb;--fg:#1a1a1a;--mute:#666;--rule:#ddd}}
body{{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif}}
main{{max-width:1000px;margin:0 auto;padding:28px 16px 48px}}
h1{{font-size:22px;margin:0 0 4px}} p{{color:var(--mute);margin:0 0 14px;max-width:880px}}
svg{{width:100%;height:auto;display:block}}
table{{border-collapse:collapse;margin-top:18px;font-size:13px;font-variant-numeric:tabular-nums}}
th,td{{border:1px solid var(--rule);padding:5px 10px;text-align:right}} th{{background:#f1f1ee}}
td:first-child,td:nth-child(2),th:first-child,th:nth-child(2){{text-align:left}}
</style></head><body><main>
<h1>{html.escape(a.title)}</h1><p>{html.escape(a.note)}</p>
{svg}
{table(rows, labels)}
</main></body></html>"""
    open(a.out, "w").write(page)
    print("wrote", a.out)


if __name__ == "__main__":
    main()
