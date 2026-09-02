#!/usr/bin/env python3
"""What is actually in a `claude -p --output-format stream-json` trace?

Written because two hand-guessed probes returned zero and neither zero was
trustworthy: grep -c '"type":"thinking"' matches one exact byte sequence, and
walking message.content misses anything carried in partial-message deltas. A
check whose failure mode is silence has to enumerate rather than match.

    python3 scripts/probe_trace_shape.py /tmp/probe2.jsonl
"""
import collections
import json
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/probe2.jsonl"
ev, blk, delta = collections.Counter(), collections.Counter(), collections.Counter()
lines = 0
for ln in open(path, errors="replace"):
    ln = ln.strip()
    if not ln:
        continue
    lines += 1
    try:
        e = json.loads(ln)
    except Exception:
        ev["UNPARSEABLE"] += 1
        continue
    ev[(e.get("type"), e.get("subtype"))] += 1
    for b in (e.get("message") or {}).get("content") or []:
        if isinstance(b, dict):
            blk[b.get("type")] += 1
    inner = e.get("event") or {}
    if inner.get("type"):
        delta[(inner.get("type"),
               (inner.get("delta") or {}).get("type"),
               (inner.get("content_block") or {}).get("type"))] += 1

# THE RUN'S OWN VERDICT, FIRST. Counting content-block types while ignoring
# is_error reported "no thinking blocks" for three runs whose single text block
# was "Not logged in - Please run /login". The block census was accurate and the
# conclusion drawn from it was worthless. A trace that errored is not evidence
# about thinking, so the error is printed before any census.
errs = []
for ln in open(path, errors="replace"):
    ln = ln.strip()
    if not ln:
        continue
    try:
        e = json.loads(ln)
    except Exception:
        continue
    if e.get("type") == "result":
        errs.append((e.get("is_error"), str(e.get("result"))[:200],
                     e.get("num_turns"), e.get("total_cost_usd")))
for is_err, res, turns, cost in errs:
    flag = "*** RUN FAILED ***" if is_err else "run ok"
    print(f"{flag}  turns={turns} cost={cost}")
    print(f"   result: {res}")
if any(e[0] for e in errs):
    print("   -> Nothing below says anything about the model. Fix the run first.")
print()
print(f"lines: {lines}")
print("EVENT TYPES (type, subtype):")
for k, v in ev.most_common():
    print(f"   {v:5d}  {k}")
print("CONTENT BLOCKS:")
for k, v in blk.most_common():
    print(f"   {v:5d}  {k}")
print("STREAM EVENTS (type, delta.type, content_block.type):")
for k, v in delta.most_common(15):
    print(f"   {v:5d}  {k}")

hit = [k for k in list(blk) + [d[1] for d in delta] + [d[2] for d in delta]
       if k and "thinking" in str(k)]
print()
print("VERDICT: reasoning IS in the trace as " + ", ".join(sorted(set(hit)))
      if hit else
      "VERDICT: NO thinking blocks or deltas anywhere in this trace.")
