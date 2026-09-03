#!/usr/bin/env python3
"""Independent Claude Code attempts at a design task, WITH the reasoning text.

    ~/.venv-claude-sdk/bin/python scripts/trace_attempts_sdk.py d_dsp03 10 ~/dsp03_traces

WHY THIS EXISTS AND `claude -p` DOES NOT SUFFICE. On Opus 4.7 and later the API
default for thinking display is "omitted", so every thinking block arrives with
an empty `thinking` field and a large signature -- measured here as 993
thinking_delta events carrying 0 characters. The CLI has no flag for it. The
Agent SDK does: ThinkingConfigEnabled takes display="summarized". Same agent
loop, same tools, same subscription billing, one option the CLI cannot express.

Ruled out first, so nobody re-tries them: the [1m] model variant (pinning plain
opus-5 changed nothing), --effort (thinking happened either way),
--include-partial-messages (deltas flowed, all empty), and
showThinkingSummaries: true in settings.json (applied, still empty).

CONTAMINATION. Each attempt runs in a scratch directory OUTSIDE the repo with
only PASTE.md in it. The model gets Verilator, not the task's tb/, ref/,
mutants or controls -- writing its own testbench is the work being observed. The
scan reads parsed fields and skips `signature`, because a 189KB base64 blob
matches a three-character path fragment by chance, and once did.
"""
import argparse
import asyncio
import dataclasses
import json
import os
import re
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

LEAK = re.compile(r"hw_rl_benchmark|fp_multifmt_fma_ref|/ref/|/tb/|/mutants/|/controls/", re.I)
OPAQUE = {"signature", "data"}


def encode(obj):
    """Best-effort JSON for SDK dataclasses, so a trace is replayable."""
    if dataclasses.is_dataclass(obj) and not isinstance(obj, type):
        out = {"_type": type(obj).__name__}
        for f in dataclasses.fields(obj):
            out[f.name] = encode(getattr(obj, f.name))
        return out
    if isinstance(obj, dict):
        return {k: encode(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [encode(v) for v in obj]
    if isinstance(obj, (str, int, float, bool)) or obj is None:
        return obj
    return str(obj)


def scan_leak(node):
    """Walk parsed content for repo references, skipping opaque base64."""
    if isinstance(node, str):
        m = LEAK.search(node)
        return [node[max(0, m.start() - 60):m.start() + 60]] if m else []
    if isinstance(node, list):
        return [h for v in node for h in scan_leak(v)]
    if isinstance(node, dict):
        return [h for k, v in node.items() if k not in OPAQUE for h in scan_leak(v)]
    return []


async def one_attempt(sdk, prompt, workdir, args):
    opts = sdk.ClaudeAgentOptions(
        cwd=workdir,
        model=args.model,
        effort=args.effort,
        # THE WHOLE POINT. display="summarized" is what the CLI cannot set.
        thinking={"type": "enabled", "budget_tokens": args.budget,
                  "display": "summarized"},
        allowed_tools=["Write", "Read", "Edit", "Bash"],
        permission_mode="acceptEdits",
        max_budget_usd=args.max_usd,
    )
    msgs, think_chars, tools, leaks = [], 0, 0, []
    result = None
    async for m in sdk.query(prompt=prompt, options=opts):
        d = encode(m)
        msgs.append(d)
        for b in (d.get("content") or []) if isinstance(d.get("content"), list) else []:
            if not isinstance(b, dict):
                continue
            if b.get("_type") == "ThinkingBlock":
                think_chars += len(b.get("thinking") or "")
            if b.get("_type") in ("ToolUseBlock", "ToolResultBlock"):
                tools += 1 if b.get("_type") == "ToolUseBlock" else 0
            leaks += scan_leak({k: v for k, v in b.items() if k not in OPAQUE})
        if d.get("_type") == "ResultMessage":
            result = d
    return msgs, think_chars, tools, leaks, result


async def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("task")
    ap.add_argument("n", type=int)
    ap.add_argument("outdir")
    ap.add_argument("--model", default="opus")
    ap.add_argument("--effort", default="high")
    ap.add_argument("--budget", type=int, default=32000)
    ap.add_argument("--max-usd", dest="max_usd", type=float, default=None)
    ap.add_argument("--concurrency", type=int, default=3,
                    help="attempts to run at once. Each has its own scratch dir "
                         "and its own CLI process, so there is nothing shared to "
                         "conflict over; the limits are rate limiting and RAM "
                         "(~250MB per process). 1 restores serial behaviour.")
    args = ap.parse_args()

    try:
        import claude_agent_sdk as sdk
    except ImportError:
        sys.exit("claude_agent_sdk not importable. Use the venv python:\n"
                 "  ~/.venv-claude-sdk/bin/python " + " ".join(sys.argv))

    import glob
    tdirs = glob.glob(os.path.join(REPO, "domains", "*", "design", args.task + "_*"))
    if not tdirs:
        sys.exit(f"no task dir for {args.task!r}")
    paste = os.path.join(tdirs[0], "probe", "PASTE.md")
    if not os.path.isfile(paste):
        sys.exit(f"missing {paste}")
    out = os.path.abspath(os.path.expanduser(args.outdir))
    if out == REPO or out.startswith(REPO + os.sep):
        sys.exit("REFUSING: output dir is inside the repo -- attempts must run outside it")
    if not shutil.which("verilator"):
        sys.exit("MISSING: verilator not on PATH")

    task_text = open(paste, encoding="utf-8").read()
    prompt = (task_text + "\n\nWrite your final answer to a file named submission.sv "
              "in this directory. Verilator is available if you want to compile or "
              "test your work.")
    print(f"task     : {args.task}\nmodel    : {args.model}\neffort   : {args.effort}")
    print(f"thinking : enabled, budget {args.budget}, display=summarized")
    print(f"prompt   : {paste} ({len(task_text):,} bytes)")
    print(f"output   : {out}\nparallel : {args.concurrency} at a time\n")
    os.makedirs(out, exist_ok=True)

    todo = []
    for i in range(1, args.n + 1):
        d = os.path.join(out, f"attempt_{i:02d}")
        if os.path.exists(d):
            print(f"[{i:02d}] exists, skipping")
            continue
        todo.append((i, d))
    if not todo:
        print("nothing to run")
    else:
        print(f"running {len(todo)} attempt(s), {args.concurrency} at a time\n")

    sem = asyncio.Semaphore(max(1, args.concurrency))

    async def run_one(i, d):
        # EACH ATTEMPT IS SELF-CONTAINED, which is what makes concurrency safe:
        # its own scratch directory, its own CLI process, no shared state and no
        # ordering between them. They are independent samples by design.
        async with sem:
            work = os.path.join(d, "work")
            os.makedirs(work, exist_ok=True)
            shutil.copy(paste, os.path.join(work, "TASK.md"))
            print(f"[{i:02d}] started", flush=True)
            try:
                msgs, chars, tools, leaks, result = await one_attempt(sdk, prompt, work, args)
            except Exception as e:              # one bad attempt must not end the batch
                print(f"[{i:02d}] ERROR: {type(e).__name__}: {e}", flush=True)
                open(os.path.join(d, "STATUS"), "w").write("ERROR")
                return
            with open(os.path.join(d, "trace.jsonl"), "w") as fh:
                for m in msgs:
                    fh.write(json.dumps(m) + "\n")
            status = "CONTAMINATED" if leaks else "clean"
            open(os.path.join(d, "STATUS"), "w").write(status)
            if leaks:
                open(os.path.join(d, "LEAKS.txt"), "w").write("\n".join(leaks[:20]))
            sub = os.path.join(work, "submission.sv")
            have = os.path.isfile(sub)
            if have:
                shutil.copy(sub, os.path.join(d, "submission.sv"))
            err = (result or {}).get("is_error")
            cost = (result or {}).get("total_cost_usd")
            print(f"[{i:02d}] done  reasoning_chars={chars:,} tools={tools} "
                  f"submission={'yes' if have else 'NO'} cost={cost} "
                  f"error={err} {status}", flush=True)

    await asyncio.gather(*(run_one(i, d) for i, d in todo))

    print("\n=== summary ===")
    for d in sorted(glob.glob(os.path.join(out, "attempt_*"))):
        st = open(os.path.join(d, "STATUS")).read().strip() if os.path.isfile(os.path.join(d, "STATUS")) else "?"
        tp = os.path.join(d, "trace.jsonl")
        chars = tools = 0
        if os.path.isfile(tp):
            for ln in open(tp):
                try:
                    m = json.loads(ln)
                except Exception:
                    continue
                for b in (m.get("content") or []) if isinstance(m.get("content"), list) else []:
                    if isinstance(b, dict):
                        if b.get("_type") == "ThinkingBlock":
                            chars += len(b.get("thinking") or "")
                        if b.get("_type") == "ToolUseBlock":
                            tools += 1
        sub = "yes" if os.path.isfile(os.path.join(d, "submission.sv")) else "NO"
        print(f"  {os.path.basename(d):12s} reasoning_chars={chars:<9,} tools={tools:<4} "
              f"submission={sub:<4} {st}")
    print(f"\nScore with:\n  for d in {out}/attempt_*; do [ -f \"$d/submission.sv\" ] && "
          f"{REPO}/scripts/sim_candidate.sh {args.task} \"$d/submission.sv\"; done")


if __name__ == "__main__":
    asyncio.run(main())
