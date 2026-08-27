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


def fenced_blocks(paste_text):
    """Every fenced block's contents, in document order.

    THE TWO-FILE SHAPE. fenced_body() returns everything between the FIRST open
    and the LAST close, which is correct for a one-block prompt and silently wrong
    for two -- it swallows the intermediate fences and the comparison then fails
    as STALE rather than as a shape error. d_nw01 and d_ca05 are the two design
    tasks whose interface opens `import <task>_pkg::*;`, and their packages --
    229 and 142 lines of typedefs the port list is written in -- were NAMED in the
    prompt and not supplied. A model was told the types live in a file it was
    never given.

    Order is load-bearing, not cosmetic: SystemVerilog requires the package to be
    elaborated before the module that imports it, so the package block comes
    first. Checking [pkg, iface] as an ordered pair is what makes the prompt
    compile in the order it is read.
    """
    lines = paste_text.splitlines(keepends=True)
    out, cur, inside = [], [], False
    for ln in lines:
        if not inside and FENCE_OPEN.match(ln):
            inside, cur = True, []
            continue
        if inside and FENCE_CLOSE.match(ln):
            out.append("".join(cur))
            inside = False
            continue
        if inside:
            cur.append(ln)
    return out


def rebuild(paste_text, iface_text):
    """Header kept verbatim, body replaced. Never invents a header."""
    lines = paste_text.splitlines(keepends=True)
    start = next(i for i, ln in enumerate(lines) if FENCE_OPEN.match(ln))
    return "".join(lines[:start + 1]) + iface_text + "```\n"


def rebuild_pair(paste_text, pkg_text, iface_text):
    """Two-block rebuild: header, package block, interface block.

    --fix COULD NOT REPAIR THE TASKS IT POLICES. The package branch returns
    before reaching the fix branch, so on d_nw01 and d_ca05 --fix reported STALE
    and did nothing -- silently, and on exactly the two prompts most likely to go
    stale, because they have two sources to drift from instead of one. d_nw01's
    interface block changed four times in a day and --fix declined each time.
    Reported by AGENT-DESIGN-43a92055, who rebuilt both by hand.

    The header is kept verbatim to the first fence, as the one-block form does --
    rule 13 says the header may motivate and must not add terms, so regeneration
    must never author one. Everything from the first fence on is replaced, which
    also discards any stray blocks between them rather than preserving something
    the checker would then refuse.
    """
    lines = paste_text.splitlines(keepends=True)
    start = next(i for i, ln in enumerate(lines) if FENCE_OPEN.match(ln))
    head = "".join(lines[:start])
    return (head
            + "```systemverilog\n" + pkg_text + "```\n"
            + "\n"
            + "```systemverilog\n" + iface_text + "```\n")


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
        # A task whose interface imports a package must ship that package IN the
        # prompt, as its own block, before the interface. Referencing it by path
        # is not shipping it -- see fenced_blocks().
        pkgs = sorted(glob.glob(os.path.join(task, "spec", "*_pkg.sv")))
        if pkgs:
            if len(pkgs) > 1:
                print(f"{name:32s} SKIP  {len(pkgs)} packages; ambiguous")
                continue
            pkg_text = open(pkgs[0]).read()
            blocks = fenced_blocks(paste_text)
            want = [pkg_text, iface_text]
            if len(blocks) != 2:
                print(f"{name:32s} SHAPE {len(blocks)} fenced block(s); this task "
                      f"imports {os.path.basename(pkgs[0])[:-3]} and needs 2, "
                      f"package then interface")
                bad += 1
                if fix and blocks:
                    open(paste, "w").write(rebuild_pair(paste_text, pkg_text, iface_text))
                    print(f"{'':32s}       regenerated both blocks from "
                          f"{os.path.relpath(pkgs[0], REPO)} and "
                          f"{os.path.relpath(ifaces[0], REPO)}")
                continue
            if blocks == want:
                print(f"{name:32s} ok    (package + interface)")
                continue
            which = "package" if blocks[0] != pkg_text else "interface"
            bad += 1
            print(f"{name:32s} STALE the {which} block differs from "
                  f"spec/{os.path.basename(pkgs[0] if which == 'package' else ifaces[0])}")
            if fix:
                open(paste, "w").write(rebuild_pair(paste_text, pkg_text, iface_text))
                print(f"{'':32s}       regenerated both blocks from "
                      f"{os.path.relpath(pkgs[0], REPO)} and "
                      f"{os.path.relpath(ifaces[0], REPO)}")
            continue
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
