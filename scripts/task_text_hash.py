#!/usr/bin/env python3
"""Hash the exact task text a submission was answering.

    task_text_hash.py <task-dir>      -> <16-hex>  then the files that fed it

WHY (rule 17, applied to specs instead of build configs)
--------------------------------------------------------
`v_ca05/chat` scored 2/6 and later 5/6. Those answer DIFFERENT TASK TEXTS -- the
prompt was revised between them -- so they are not two points on a progression,
they are two different questions. Printed side by side they read as improvement.

Rule 17 says two PPA numbers may only be compared when their build
configurations match, asserted mechanically. The same argument applies to the
thing the model was asked: **a submission is an answer to a specific text, and
comparing answers to different texts measures the edit.**

So every submission record carries this hash, and a comparison across differing
hashes reports UNCOMPARABLE exactly as compare_ppa.py does.

WHAT IS HASHED
--------------
The artefacts a submission actually sees: the spec/interface files and, for a
verification task, the prompt document. NOT task.yaml, NOT the checker, NOT the
mutants -- those change scoring, not the question. Changing what is scored is
rule 18's business; this tracks what was ASKED.

UNKNOWN IS A VALID ANSWER. A record written before this existed has no hash, and
that renders as `unknown` rather than being back-filled with today's value --
back-filling would assert the submission answered a text nobody has checked it
against.
"""
import hashlib
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def text_files(task_dir):
    """The artefacts a submission sees. Named explicitly per kind, not globbed
    -- rule 10; a stray file appearing in spec/ must not silently change the
    hash of every past submission."""
    out = []
    spec = os.path.join(task_dir, "spec")
    if os.path.isdir(spec):
        for f in sorted(os.listdir(spec)):
            if f.endswith((".sv", ".svh", ".md")):
                out.append(os.path.join(spec, f))
    # verification tasks additionally ship a prompt document
    probe = os.path.join(task_dir, "probe", "BLIND_TB_TASK.md")
    if os.path.isfile(probe):
        out.append(probe)
    return out


def task_text_hash(task_dir):
    files = text_files(task_dir)
    if not files:
        return None, []
    h = hashlib.sha256()
    detail = []
    for f in files:
        b = open(f, "rb").read()
        fh = hashlib.sha256(b).hexdigest()
        h.update(os.path.relpath(f, task_dir).encode())
        h.update(fh.encode())
        detail.append((os.path.relpath(f, task_dir), fh[:12], len(b)))
    return h.hexdigest()[:16], detail


def main():
    if len(sys.argv) != 2:
        print("usage: task_text_hash.py <task-dir>")
        return 2
    d = sys.argv[1]
    if not os.path.isdir(d):
        print(f"no such task dir: {d}", file=sys.stderr)
        return 2
    digest, detail = task_text_hash(d)
    if digest is None:
        print("NO-TASK-TEXT")
        print("  no spec/ files and no probe/BLIND_TB_TASK.md", file=sys.stderr)
        return 1
    print(digest)
    for rel, fh, n in detail:
        print(f"  {rel}  {fh}  {n}B")
    return 0


if __name__ == "__main__":
    sys.exit(main())
