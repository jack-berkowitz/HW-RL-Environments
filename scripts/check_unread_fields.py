#!/usr/bin/env python3
"""Which fields do the run recorders WRITE that nothing READS?

A FIELD WITH NO READER CANNOT BE WRONG, WHICH IS NOT THE SAME AS BEING RIGHT.
Every instrument in this repo works by finding a DISAGREEMENT -- a hash against
a recomputed hash, a witness against a fresh runner, a record against a flow
directory. A field nothing consults produces no disagreement anywhere, so a
wrong value in it is indistinguishable from a right one, forever, and no amount
of care at the moment of writing changes that.

THE INSTANCE THAT NAMES THE CLASS is version_boundary's `behavioural: true` in
d_ai01's task.yaml (F89). It correctly recorded that results do not carry across
a boundary -- and the results carried anyway, because nothing reads it. The
field was RIGHT. Being right changed nothing.

CONCRETE BITE, measured by this script: `configs_no_verdict` is nonzero on
exactly six records, all of them d_ai01 runs where the testbench printed
`RESULT: PASS` and the scored path read `TEST_RESULT:` and returned NO_VERDICT
(F90). The field that would have named the defect was written on every affected
record and consulted by nothing; the defect was found instead by a person
reading NO_VERDICT off a terminal.

WHAT IT DOES NOT DO. It cannot tell an unread field that MATTERS from one that
is genuinely decorative, and it does not try -- that needs the field read. It
reports what is written and unread; a human decides which of those is a defect.
A field being unread is also not automatically wrong: `git_sha` is unread AND
uninformative (it ends -dirty on 600 of 602 records), which are two separate
problems and only the second is fatal.

  usage:  check_unread_fields.py [--nonzero]     --nonzero: only fields that
                                                 actually carry a value
"""
import collections, glob, json, os, re, sys

# The recorder is excluded: it WRITES these, so finding the name there proves
# nothing. Everything else counts as a potential reader.
# THIS FILE EXCLUDES ITSELF, and the reason is not tidiness. On its first run it
# reported 7 unread fields where the honest answer was 9: its own docstring names
# `git_sha` and `configs_no_verdict` as examples, the scan found those strings in
# scripts/*.py, and it counted ITSELF as their reader. A tool that reports a
# field as consulted because it discusses that field has answered a different
# question -- and it would have gone on quietly shrinking its own findings every
# time someone added an example to the header.
WRITERS = {"scripts/write_run_record.py",
           os.path.relpath(os.path.abspath(__file__), os.getcwd())
           if os.path.abspath(__file__).startswith(os.getcwd())
           else "scripts/check_unread_fields.py",
           "scripts/check_unread_fields.py"}
SRC_GLOBS = ("scripts/*.py", "scripts/*.sh", "runner/*.py", "runner/*.sh")


def sources():
    out = {}
    for g in SRC_GLOBS:
        for p in glob.glob(g):
            if p in WRITERS:
                continue
            try:
                out[p] = open(p, errors="replace").read()
            except OSError:
                pass
    return out


def main(argv):
    only_nonzero = "--nonzero" in argv
    recs = glob.glob("runs/*/*.json")
    if not recs:
        print("NO CONCLUSION -- no run records found under runs/.")
        print("Nothing was read; this is not a clean result.")
        return 2
    keys, nonzero = collections.Counter(), collections.Counter()
    for f in recs:
        try:
            d = json.load(open(f))
        except Exception:
            continue
        for k, v in d.items():
            keys[k] += 1
            if v not in (None, "", 0, [], {}, False):
                nonzero[k] += 1
    src = sources()
    print(f"{len(keys)} distinct field(s) across {len(recs)} run record(s); "
          f"{len(src)} script(s) scanned for readers.\n")
    print(f"{'field':32s} {'records':>8} {'non-empty':>10}  readers")
    unread = []
    for k, n in sorted(keys.items(), key=lambda kv: -kv[1]):
        rs = [os.path.basename(p) for p, t in src.items()
              if re.search(r'["\'`]%s["\'`]' % re.escape(k), t)]
        if not rs:
            unread.append((k, n, nonzero[k]))
        if only_nonzero and not nonzero[k]:
            continue
        print(f"  {k:30s} {n:>8} {nonzero[k]:>10}  "
              f"{', '.join(sorted(rs)) if rs else '*** NO READER ***'}")
    print(f"\n{len(unread)} field(s) written and read by nothing:")
    for k, n, nz in unread:
        note = f"{nz} record(s) carry a value" if nz else \
               "never non-empty -- unread AND never exercised"
        print(f"  {k:30s} {n:>6} record(s), {note}")
    print("\nCANDIDATE LIST, NOT A VERDICT. An unread field is not automatically")
    print("a defect; a field that is unread AND would have named a real failure")
    print("is. Read each one before acting.")
    return 1 if unread else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
