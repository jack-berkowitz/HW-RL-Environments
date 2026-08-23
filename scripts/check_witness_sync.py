#!/usr/bin/env python3
"""Assert every recorded witness string is what the runner actually prints.

WHY THIS EXISTS
---------------
Each verification task's `task.yaml` records, per mutant, the observable
difference that convicts it. Those strings are the evidence rule 21 accepts, and
they were transcribed BY HAND from a runner's output. A transcription is not a
measurement: it can be abridged, it can be stale, and nothing about the file says
which. One was found abridged during the F66 audit -- same clause, same values,
but not the line the runner prints -- and the only reason it was found is that
somebody diffed all fifty by hand, once, in a way that was not wired to anything.

So the diff is mechanical from here.

TWO MODES, AND THE FAST ONE IS NOT THE CHECK
--------------------------------------------
    (default)   STRUCTURAL. Every mutant has a witness, every witness has a
                mutant, no placeholders, and each task's mutants/RULE24.md
                records a control that PASSED on both halves. No simulation, so
                this is safe to run in a commit gate.

    --fresh     AUTHORITATIVE. Runs each mutants/witness.sh and diffs its output
                against task.yaml verbatim. Tens of minutes. This is the one that
                can actually catch a stale string; the structural mode only
                catches a missing one.

That split is deliberate and copies check_linkage_tree.sh's: a gate that is too
slow to run gets routed around within a week, and a gate that only checks shape
must not be mistaken for the thing that checks content.

Exit: 0 clean, 1 a mismatch, 2 bad usage.
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def tasks():
    for d in sorted(glob.glob(os.path.join(REPO, "domains", "*", "verification", "*"))):
        if os.path.isfile(os.path.join(d, "REJECTED.md")):
            continue
        if os.path.isfile(os.path.join(d, "task.yaml")):
            yield d


def recorded(task_dir):
    """{mutant_id: witness string} from task.yaml's `mutants:` block ONLY.

    conformant_perturbations: carries `witness:` entries too, and they are a
    different kind of evidence -- the observable difference a LEGAL variant
    shows, which must survive rather than be caught. Scooping both blocks
    reports every conformant perturbation as an undeclared mutant.
    """
    txt = open(os.path.join(task_dir, "task.yaml"), encoding="utf-8").read()
    m = re.search(r"^mutants:\n", txt, re.M)
    if not m:
        return {}
    rest = txt[m.end():]
    nxt = re.search(r"^[a-z_]+:", rest, re.M)
    block = rest[:nxt.start()] if nxt else rest
    out = {}
    for e in re.finditer(r"\{id:\s*([A-Za-z0-9_]+),.*?witness:\s*\"(.*?)\"\s*\}",
                         block, re.S):
        out[e.group(1)] = " ".join(e.group(2).split())
    return out


def declared(task_dir):
    """Mutant ids the generated mutants.sv actually declares."""
    p = os.path.join(task_dir, "mutants", "mutants.sv")
    if not os.path.isfile(p):
        return set()
    txt = open(p, encoding="utf-8").read()
    return set(re.findall(r"^module\s+([A-Za-z]{2}_m\d+_[A-Za-z0-9_]+)", txt, re.M))


def norm(s):
    """Compare on content, not on the simulator's time stamp."""
    s = re.sub(r"\s*\(t=\d+\)", "", s)
    return " ".join(s.split())


def parse_run(out):
    """{id: message} from either runner family's output."""
    got = {}
    for line in out.split("\n"):
        line = line.strip()
        m = re.match(r"^([A-Za-z]{2}_m\d+_[A-Za-z0-9_]+)\s*:\s*(.+)$", line)
        if m:
            got[m.group(1)] = m.group(2).strip()
    return got


def main():
    fresh = "--fresh" in sys.argv[1:]
    only = [a for a in sys.argv[1:] if not a.startswith("-")]
    for a in sys.argv[1:]:
        if a.startswith("-") and a != "--fresh":
            sys.exit("usage: check_witness_sync.py [--fresh] [task-id ...]")

    problems = []
    checked = 0
    for d in tasks():
        tid = os.path.basename(d)
        if only and not any(o in tid for o in only):
            continue
        checked += 1
        rec, dec = recorded(d), declared(d)

        missing = dec - set(rec)
        extra = set(rec) - dec
        for mid in sorted(missing):
            problems.append("%s: mutant %s has no witness in task.yaml" % (tid, mid))
        for mid in sorted(extra):
            problems.append("%s: task.yaml records a witness for %s, which "
                            "mutants.sv does not declare" % (tid, mid))
        for mid, w in sorted(rec.items()):
            if not w or w.lower() in ("tbd", "todo", "unknown", "n/a"):
                problems.append("%s: %s has a placeholder witness (%r)" % (tid, mid, w))

        r24 = os.path.join(d, "mutants", "RULE24.md")
        if not os.path.isfile(r24):
            problems.append("%s: no mutants/RULE24.md -- rule 24 requires the "
                            "reproduction recorded beside the numbers" % tid)
        else:
            t = open(r24, encoding="utf-8").read()
            if "negative control : PASS" not in t:
                problems.append("%s: RULE24.md records no PASSING negative control" % tid)
            if not re.search(r"positive control : (\d+) of \1\b", t):
                problems.append("%s: RULE24.md records no clean positive control" % tid)

        if not fresh:
            continue

        run = os.path.join(d, "mutants", "witness.sh")
        if not os.path.isfile(run):
            problems.append("%s: no mutants/witness.sh to reproduce from" % tid)
            continue
        p = subprocess.run([run], capture_output=True, text=True, cwd=REPO)
        got = parse_run(p.stdout)
        if "negative control : PASS" not in p.stdout:
            problems.append("%s: the runner's negative control did not pass; its "
                            "output is not evidence of anything" % tid)
            continue
        for mid in sorted(dec):
            if mid not in got:
                problems.append("%s: %s produced no line in a fresh run" % (tid, mid))
            elif norm(got[mid]) != norm(rec.get(mid, "")):
                problems.append(
                    "%s: %s recorded vs fresh differ\n      recorded: %s\n      fresh   : %s"
                    % (tid, mid, norm(rec.get(mid, "")), norm(got[mid])))

    mode = "fresh" if fresh else "structural"
    print("witness sync (%s): %d task(s) checked" % (mode, checked))
    if problems:
        print("\nWITNESS SYNC BROKEN -- %d problem(s):" % len(problems))
        for x in problems:
            print("  " + x)
        if not fresh:
            print("\n  NOTE: this was the STRUCTURAL mode. It cannot see a witness "
                  "string that is\n  stale rather than missing -- run with --fresh "
                  "for that.")
        return 1
    if not fresh:
        print("  structural only: every mutant has a witness and every control is "
              "recorded.\n  Whether each string is still what the runner prints is "
              "--fresh's question.")
    else:
        print("  every recorded witness matches a fresh runner pass, verbatim.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
