"""Same test, whole-clause scope -- and VALIDATED AGAINST THE TWO KNOWN HITS FIRST.

The windowed version of this filter found 2 candidates and MISSED d_ca01 R1, a
confirmed instance. A filter that cannot find the case already proven is not
evidence about the cases that are not. Widened to the whole clause body: it
over-includes, and over-inclusion is the safe direction -- a candidate that reads
as FORCED costs a reading, a missed one leaves a live gap.
"""
import json, re, os

DESIGN_DRIVEN = re.compile(
    r"\b(\w+_o|out_valid|out_ready|rsp_valid|rsp_ready|in_ready|req_ready|busy)\b")
rows = json.load(open(os.environ["IN"]))
risk, forced = [], []
for r in rows:
    hits = sorted(set(DESIGN_DRIVEN.findall(r["text"])))
    (risk if hits else forced).append((r, hits))

KNOWN = {("d_dsp02_fp32_fma_ii1", "H3"), ("d_ca01_nonblocking_dcache", "R1")}
found = {(r["task"], r["clause"]) for r, _ in risk}
missing = KNOWN - found
print("VALIDATION against the two measured instances:")
for t, c in sorted(KNOWN):
    print(f"  {'caught ' if (t,c) in found else 'MISSED '} {t} {c}")
if missing:
    print("  REFUSED: the filter cannot find a case already proven. Its output on "
          "unproven cases is not evidence.")
    raise SystemExit(1)
print(f"\n{len(rows)} conditional clauses")
print(f"  {len(forced):3d}  no design-driven signal in the clause -> FORCED by construction")
print(f"  {len(risk):3d}  CANDIDATES -- a control decides each\n")
for r, hits in risk:
    print(f"  {r['task'][:22]:22s} {r['clause']:5s} {','.join(hits)[:34]:34s} {r['text'][:58]}")
json.dump([{"task": r["task"], "clause": r["clause"], "signals": h, "text": r["text"]}
           for r, h in risk], open(os.environ["OUT"], "w"), indent=1)
