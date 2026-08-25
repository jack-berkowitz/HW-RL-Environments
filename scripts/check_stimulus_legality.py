#!/usr/bin/env python3
"""Stimulus-legality scan: a testbench-driven *_valid that can DROP while the
transfer it announced is still pending.

AXI, AXI-Stream and every valid/ready handshake require that once VALID is
asserted it stays asserted until READY -- the initiator may not withdraw an
offer. A responder model that gates VALID on a rate or delay counter breaks
that, and the consequence is not a weak test: it makes the stimulus ILLEGAL,
so a DUT is entitled to any behaviour and an assertion inside the DUT reports
the harness's defect while looking like a design failure.

HEURISTIC. It flags a valid whose driving expression mentions a delay/rate/
stall/lfsr term. That is a candidate to read, not a verdict -- the term may
gate only the START of a transfer, which is legal.
"""
import glob, os, re

def strip(t):
    t = re.sub(r"/\*.*?\*/", " ", t, flags=re.S)
    t = re.sub(r"//[^\n]*", "", t)
    return t

GATE = re.compile(r"(delay|dly|rate|stall|lfsr|_wait|hold_off)", re.I)
ASSIGN = re.compile(r"^[ \t]*(?:assign\s+)?([\w.\[\]]*valid[\w.\[\]]*)\s*(<=|=)(?!=)([^;]+);",
                    re.M | re.I)

rows = []
for tdir in sorted(glob.glob("domains/*/design/*") + glob.glob("domains/*/verification/*")):
    files = glob.glob(os.path.join(tdir, "tb", "**", "*.sv"), recursive=True) + \
            glob.glob(os.path.join(tdir, "tb", "**", "*.svh"), recursive=True)
    files = [f for f in files if "/audit/" not in f]
    hits = []
    for f in files:
        txt = strip(open(f, errors="replace").read())
        for m in ASSIGN.finditer(txt):
            lhs, rhs = m.group(1), " ".join(m.group(3).split())
            if GATE.search(rhs):
                line = txt[:m.start()].count("\n") + 1
                hits.append((os.path.basename(f), line, lhs, rhs[:96]))
    if hits:
        rows.append((os.path.basename(tdir), hits))

for t, hits in rows:
    print(f"{t}")
    for f, ln, lhs, rhs in hits[:4]:
        print(f"    {f}:{ln}  {lhs} = {rhs}")
print(f"\n{len(rows)} task(s) with a rate-gated valid to read")
