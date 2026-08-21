#!/usr/bin/env python3
"""probe/PASTE.md must carry spec/*_iface.sv VERBATIM. Verify it, repo-wide.

WHY THIS EXISTS. PASTE.md is not a convenience copy. It is the document a model
is actually handed, and `scripts/task_text_hash.py` hashes it TOGETHER WITH
spec/ to produce the task_text_hash stamped into every run record and every PPA
record. So it is load-bearing twice over, and it is also DERIVED -- which means
editing the interface silently rots it, and the hash then goes on asserting
"same question" across a question that changed. That is precisely the failure
task_text_hash.py's own docstring says the hash exists to prevent.

Found the hard way: d_dsp03's PASTE.md was generated before clause T5 was added
to the interface and never regenerated, so the prompt was missing a normative
tool requirement that a conformant design had already been rejected for.

The contract this enforces: for a DESIGN task, PASTE.md is a prose header, then
ONE fenced ```systemverilog block containing the interface byte for byte, then
the fence. Everything a submission must obey lives in the interface; the header
may motivate and must not add terms (rule 13).

DESIGN TASKS ONLY. Verification prompts have a different and legitimate shape --
they ship spec/<mod>_spec.md alongside the interface, hand the model a STRIPPED
port list rather than the annotated interface, and carry several fenced blocks.
Checking them against this rule reports five false positives on work that is
correct, so they are listed and skipped rather than judged by a design task's
convention.

Usage:  python3 scripts/check_paste_sync.py [--fix]
Exit 0 if every task is in sync, 1 otherwise.
"""
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FENCE_OPEN = re.compile(r"^```(?:systemverilog|verilog|sv)?\s*$")
FENCE_CLOSE = re.compile(r"^```\s*$")


def fenced_body(paste_text):
    """The single fenced block's contents, or None if the shape is wrong."""
    lines = paste_text.splitlines(keepends=True)
    start = None
    for i, ln in enumerate(lines):
        if FENCE_OPEN.match(ln):
            start = i
            break
    if start is None:
        return None
    for j in range(len(lines) - 1, start, -1):
        if FENCE_CLOSE.match(lines[j]):
            return "".join(lines[start + 1:j])
    return None


def rebuild(paste_text, iface_text):
    """Header kept verbatim, body replaced. Never invents a header."""
    lines = paste_text.splitlines(keepends=True)
    start = next(i for i, ln in enumerate(lines) if FENCE_OPEN.match(ln))
    return "".join(lines[:start + 1]) + iface_text + "```\n"


def main():
    fix = "--fix" in sys.argv[1:]
    bad = 0
    checked = 0
    skipped = []
    for task in sorted(glob.glob(os.path.join(REPO, "domains", "*", "*", "*"))):
        kind = os.path.basename(os.path.dirname(task))
        if kind != "design":
            if os.path.isfile(os.path.join(task, "probe", "PASTE.md")):
                skipped.append(os.path.basename(task))
            continue
        paste = os.path.join(task, "probe", "PASTE.md")
        ifaces = sorted(glob.glob(os.path.join(task, "spec", "*_iface.sv")))
        if not os.path.isfile(paste) or not ifaces:
            continue
        checked += 1
        name = os.path.basename(task)
        if len(ifaces) > 1:
            print(f"{name:32s} SKIP  {len(ifaces)} interfaces; ambiguous")
            continue
        paste_text = open(paste).read()
        iface_text = open(ifaces[0]).read()
        body = fenced_body(paste_text)
        if body is None:
            print(f"{name:32s} SHAPE no single ```systemverilog block")
            bad += 1
            continue
        if body == iface_text:
            print(f"{name:32s} ok")
            continue
        bad += 1
        n = sum(1 for _ in __import__("difflib").unified_diff(
            body.splitlines(), iface_text.splitlines(), n=0)) 
        print(f"{name:32s} STALE prompt differs from the interface ({n} diff lines)")
        if fix:
            open(paste, "w").write(rebuild(paste_text, iface_text))
            print(f"{'':32s}       regenerated from {os.path.relpath(ifaces[0], REPO)}")
    if skipped:
        print(f"\nskipped {len(skipped)} verification prompt(s) -- different shape "
              f"by design, not checked here:")
        for n in skipped:
            print(f"  {n}")
    print(f"\n{checked} design task(s) with a prompt; {bad} out of sync")
    return 1 if bad and not fix else 0


if __name__ == "__main__":
    sys.exit(main())
