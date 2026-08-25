"""Enumerate conditional normative clauses across the eight design specs.

The denominator for F86's sweep. A clause is a CANDIDATE if its text carries a
condition -- a state the design may or may not enter -- rather than an
unconditional requirement.
"""
import re, glob, os

MARK = re.compile(r"\b(while|when|whenever|until|unless|so long as|once|if)\b", re.I)
# A clause heading: `// X1. ...` or `//   X1. ...`
HEAD = re.compile(r"^//\s*([A-Z]{1,2}\d+[a-z]?)\.\s+(.*)$")

specs = sorted(glob.glob("domains/*/design/d_*/spec/*_iface.sv"))
total = 0
rows = []
for sp in specs:
    task = sp.split("/")[3]
    if task.startswith("d_dsp01"):
        continue                      # withdrawn under F54
    lines = open(sp, encoding="utf-8").read().split("\n")
    cur, buf = None, []
    clauses = []
    for ln in lines:
        m = HEAD.match(ln)
        if m:
            if cur: clauses.append((cur, " ".join(buf)))
            cur, buf = m.group(1), [m.group(2)]
        elif cur and ln.startswith("//"):
            buf.append(ln.lstrip("/ ").rstrip())
        elif cur and not ln.strip():
            pass
    if cur: clauses.append((cur, " ".join(buf)))
    for cid, body in clauses:
        if MARK.search(body):
            total += 1
            rows.append((task, cid, body[:150]))
    print(f"{task:28s} clauses={len(clauses):3d}  conditional={sum(1 for c,b in clauses if MARK.search(b)):3d}")
print(f"\nDENOMINATOR: {total} conditional clauses across {len(specs)-1} specs")
import json
json.dump([{"task": t, "clause": c, "text": x} for t, c, x in rows],
          open(os.environ["OUT"], "w"), indent=1)
