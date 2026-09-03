#!/usr/bin/env python3
"""Turn an SDK attempt trace into a readable transcript.

    python3 scripts/render_trace.py ~/dsp03_sdk/attempt_01 > attempt_01.md

trace.jsonl is a replayable record, not something a person reads: one attempt is
2.7MB of JSON holding 39 thinking blocks, 51 tool calls and 51 results. This
renders them back into the order they happened, which is the artifact -- the
reasoning and the actions interleaved, so a reader can see WHY each command was
run rather than just that it was.

Tool results are truncated by default: one of them is a 318KB vector file, and a
transcript nobody can scroll is the same as no transcript. --full keeps them.
"""
import argparse
import json
import os
import sys

ap = argparse.ArgumentParser()
ap.add_argument("attempt_dir")
ap.add_argument("--full", action="store_true", help="do not truncate tool results")
ap.add_argument("--max-result", type=int, default=800)
a = ap.parse_args()

d = os.path.abspath(os.path.expanduser(a.attempt_dir))
tp = os.path.join(d, "trace.jsonl")
if not os.path.isfile(tp):
    sys.exit(f"no trace.jsonl in {d}")

think = tools = 0
print(f"# {os.path.basename(d)}\n")
for ln in open(tp, errors="replace"):
    ln = ln.strip()
    if not ln:
        continue
    try:
        m = json.loads(ln)
    except Exception:
        continue
    c = m.get("content")
    if not isinstance(c, list):
        if m.get("_type") == "ResultMessage":
            print(f"\n---\n\n**Result** — error: {m.get('is_error')} · "
                  f"turns: {m.get('num_turns')} · cost: ${m.get('total_cost_usd')}\n")
        continue
    for b in c:
        if not isinstance(b, dict):
            continue
        t = b.get("_type")
        if t == "ThinkingBlock" and (b.get("thinking") or "").strip():
            think += 1
            print(f"### Reasoning {think}\n")
            print(b["thinking"].strip() + "\n")
        elif t == "TextBlock" and (b.get("text") or "").strip():
            print(f"### Says\n\n{b['text'].strip()}\n")
        elif t == "ToolUseBlock":
            tools += 1
            inp = b.get("input") or {}
            # Bash shows its command; file tools show the path, not the payload.
            if "command" in inp:
                body = inp["command"]
            elif "file_path" in inp:
                body = inp["file_path"] + (f"  ({len(inp.get('content',''))} bytes)"
                                           if "content" in inp else "")
            else:
                body = json.dumps(inp)[:300]
            print(f"### Tool {tools}: `{b.get('name')}`\n")
            print("```\n" + str(body).strip()[:2000] + "\n```\n")
        elif t == "ToolResultBlock":
            r = b.get("content")
            if isinstance(r, list):
                r = " ".join(x.get("text", "") for x in r if isinstance(x, dict))
            r = str(r or "").strip()
            if not r:
                continue
            if not a.full and len(r) > a.max_result:
                r = r[:a.max_result] + f"\n... [{len(r) - a.max_result:,} more chars]"
            print("**Result:**\n\n```\n" + r + "\n```\n")
print(f"\n---\n\n_{think} reasoning blocks, {tools} tool calls._\n", file=sys.stderr)
