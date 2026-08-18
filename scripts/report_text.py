#!/usr/bin/env python3
"""Fixed-width results table -> results_table.txt (and stdout).

Markdown pipe tables are unreadable in a terminal: the pipes do not align and a
long note column pushes every row past the width of the window. This renders the
same data as aligned columns, computing each width from its content.

WHERE THE QUALIFIERS GO. A short status token sits IN THE ROW -- a reader
scanning the table cannot miss that a number is a build failure, is unavailable,
or predates a control. The full sentence sits directly beneath that task's own
table, two lines away, not in a footnote at the end of the document. Keeping the
whole sentence in the row is what made the markdown version unreadable, and
pushing it to the document end is what the in-the-row requirement was written
against.

Data comes from report_table.py's tables, so the two cannot disagree.
"""
import io
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import report_table as RT   # noqa: E402

REPO = RT.REPO
OUT = os.path.join(REPO, "results_table.txt")


def capture():
    buf = io.StringIO()
    old = sys.stdout
    sys.stdout = buf
    try:
        RT.main()
    finally:
        sys.stdout = old
    return buf.getvalue()


# Short in-row tokens, longest match first.
TOKENS = [
    ("build failure",                        "ZERO: did not build"),
    ("area, power and Fmax unavailable",     "n/a: exceeded memory"),
    ("not scored against the current spec",  "STALE: spec changed"),
    ("does not implement the scored",        "OFF-SPEC"),
    ("PPA predates the correctness",         "pre-gate"),
    ("scored configuration",                 "cfg absent"),
    # verification half
    ("establishes the ceiling",              "ceiling"),
    ("testbench itself does not build",      "ZERO: did not build"),
    ("rejects the correct design",           "INVALID: rejects golden"),
    ("behaviour the specification leaves open", "over-constrained"),
]


def shorten(note):
    if not note.strip():
        return ""
    out = []
    for needle, tok in TOKENS:
        if needle.lower() in note.lower() and tok not in out:
            out.append(tok)
    if out:
        return ", ".join(out)
    if len(note) <= 22:
        return note
    cut = note[:22].rsplit(" ", 1)[0]
    return (cut + " ...") if len(cut) >= 8 else "see below"


def render(md):
    lines = md.splitlines()
    out, i = [], 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("|") and i + 1 < len(lines) and set(lines[i + 1].replace("|", "")) <= set("-: "):
            # collect the table
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not set("".join(cells)) <= set("-: "):
                    rows.append(cells)
                i += 1
            if not rows:
                continue
            hdr = rows[0]
            body = rows[1:]
            notes_idx = len(hdr) - 1 if hdr[-1].lower() == "notes" else None

            # strip markdown emphasis, shorten the notes column
            clean = []
            for r in [hdr] + body:
                r = list(r) + [""] * (len(hdr) - len(r))
                r = [re.sub(r"\*+", "", c).replace("`", "") for c in r]
                if notes_idx is not None and r is not clean and len(clean) > 0:
                    r[notes_idx] = shorten(r[notes_idx])
                clean.append(r)
            if notes_idx is not None:
                clean[0][notes_idx] = "status"

            w = [max(len(row[c]) for row in clean) for c in range(len(hdr))]
            sep = "  "
            out.append(sep.join(clean[0][c].ljust(w[c]) if c == 0
                                else clean[0][c].rjust(w[c]) for c in range(len(hdr))))
            out.append("-" * (sum(w) + 2 * (len(w) - 1)))
            for row in clean[1:]:
                out.append(sep.join(row[c].ljust(w[c]) if c == 0
                                    else row[c].rjust(w[c]) for c in range(len(hdr))))

            # the full sentences, immediately under this table
            longs = []
            for r in body:
                if notes_idx is not None and r[notes_idx].strip():
                    txt = re.sub(r"\*+", "", r[notes_idx]).replace("`", "")
                    name = re.sub(r"\*+|`", "", r[0])
                    longs.append(f"  {name}: {txt}")
            if longs:
                out.append("")
                for l in longs:
                    for j, chunk in enumerate(wrap(l, 96)):
                        out.append(chunk if j == 0 else "      " + chunk.strip())
            continue

        # non-table line: strip markdown decoration
        s = re.sub(r"^#+\s*", "", ln)
        s = re.sub(r"\*\*(.+?)\*\*", r"\1", s)
        s = re.sub(r"\*(.+?)\*", r"\1", s).replace("`", "")
        if re.match(r"^#+\s", ln):
            out.append("")
            out.append(s.upper())
            out.append("=" * len(s))
        else:
            out.extend(wrap(s, 96) if s.strip() else [""])
        i += 1
    return "\n".join(out)


def wrap(s, n):
    words, line, res = s.split(), "", []
    lead = len(s) - len(s.lstrip())
    pad = " " * lead
    for wd in words:
        if len(line) + len(wd) + 1 > n and line:
            res.append(pad + line.strip())
            line = ""
        line += wd + " "
    if line.strip():
        res.append(pad + line.strip())
    return res or [""]


def main():
    txt = render(capture())
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(txt + "\n")
    print(txt)
    print(f"\n[written to {os.path.relpath(OUT, REPO)}]")


if __name__ == "__main__":
    main()
