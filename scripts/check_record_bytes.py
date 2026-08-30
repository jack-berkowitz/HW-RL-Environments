#!/usr/bin/env python3
"""Every run record must describe bytes that are COMMITTED.

A record carries submission_sha256_16 for the file it scored. If the committed
file at that path hashes differently, the record describes something no other
host can obtain -- the result is unreproducible and, worse, a DIFFERENT file
sits at the name the record points to.

WHY THIS EXISTS. d_ca05's three candidates were re-solicited, simulated, and
their records committed -- while the .sv files themselves were left
uncommitted. The commit named runs/ and docs/assets/ explicitly and never named
candidates/. So the repository held passing records for bytes it did not
contain, and a build prompt went out quoting their hashes as shared state.

THE EXPLICIT-PATH COMMIT RULE GUARDS AGAINST COMMITTING TOO MUCH AND HAS NO
GUARD AGAINST COMMITTING TOO LITTLE. Naming paths deliberately is what prevents
`git add -A` sweeping in someone else's work; it also means a forgotten path is
silent, because the commit succeeds and everything derived from the missing file
lands cleanly.

THE DANGEROUS DIRECTION IS NOT THE LOUD ONE. The stale committed claude.sv had
FAILED five times, so the correctness gate would have refused it -- recoverable.
The stale committed chat.sv had a PASSING record from an earlier solicitation,
so a PPA build would have accepted it and produced a clean, plausible number
answering the PREVIOUS spec text. Nothing downstream distinguishes that from the
intended result.

Compares against the COMMITTED tree, not the working tree: a working-tree
comparison passes on exactly the machine where the file was never committed,
which is the machine running the check.

Exit 0 = every record's submission is committed at the recorded bytes.
1 = at least one record describes bytes the tree does not hold.
2 = usage/environment error.
"""
import glob
import hashlib
import json
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def committed_blob(path, ref="HEAD"):
    try:
        r = subprocess.run(["git", "-C", REPO, "show", f"{ref}:{path}"],
                           capture_output=True)
        return r.stdout if r.returncode == 0 else None
    except OSError:
        return None


def main(argv):
    ref = "HEAD"
    for a in argv[1:]:
        if not a.startswith("-"):
            ref = a
    # ONLY THE NEWEST RECORD PER SUBMISSION PATH BINDS. An older record
    # describing bytes since replaced by a newer solicitation at the same path
    # is HISTORY, not a defect -- records are append-only and a re-solicitation
    # is supposed to supersede. Checking every record reported 462 of 984, which
    # is the corpus doing what it is designed to do, and would have buried the
    # one live case that matters.
    newest = {}
    for f in sorted(glob.glob(os.path.join(REPO, "runs", "*", "*.json"))):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        sub, want = r.get("submission"), r.get("submission_sha256_16")
        if not sub or not want:
            continue
        k = str(sub)
        if k not in newest or r.get("timestamp_utc", "") > newest[k][0].get("timestamp_utc", ""):
            newest[k] = (r, f)

    bad, checked, absent = [], 0, []
    for sub, (r, f) in sorted(newest.items()):
        want = r.get("submission_sha256_16")
        # Only files inside the repo are the repo's to guarantee.
        sub = str(sub)
        if sub.startswith("/") or ".." in sub:
            continue
        checked += 1
        blob = committed_blob(sub, ref)
        rec = os.path.relpath(f, REPO)
        if blob is None:
            absent.append((rec, sub))
            continue
        got = hashlib.sha256(blob).hexdigest()[:16]
        if got != want:
            bad.append((rec, sub, want, got))

    # TWO DIRECTIONS, AND THEY NEED OPPOSITE REMEDIES.
    #   working tree == record, HEAD differs  -> the FILE was never committed;
    #                                            commit it, the result is sound
    #   working tree == HEAD,   record differs -> the RECORD is stale; the file
    #                                            moved after the run, so re-run
    # Collapsing them would send someone to commit a file that is already
    # committed, or to re-run against bytes nobody has.
    import hashlib as _h
    for i, (rec, sub, want, got) in enumerate(list(bad)):
        try:
            disk = _h.sha256(open(os.path.join(REPO, sub), "rb").read()).hexdigest()[:16]
        except OSError:
            continue
        bad[i] = (rec, sub, want, got, "UNCOMMITTED FILE" if disk == want
                  else "STALE RECORD -- re-run")

    rc = 0
    if bad:
        rc = 1
        print(f"FAIL: {len(bad)} record(s) describe bytes the committed tree "
              f"does not hold:")
        for row in bad[:40]:
            rec, sub, want, got = row[0], row[1], row[2], row[3]
            kind = row[4] if len(row) > 4 else "?"
            print(f"  {sub}\n      record says {want}, {ref} has {got}  -> {kind}\n"
                  f"      in {rec}")
        if len(bad) > 40:
            print(f"  ... and {len(bad)-40} more")
    if absent:
        print(f"note: {len(absent)} record(s) name a path not present in {ref} "
              f"(deleted or renamed submissions):")
        for rec, sub in absent[:8]:
            print(f"  {sub}")
        if len(absent) > 8:
            print(f"  ... and {len(absent)-8} more")
    print(f"{checked} record(s) checked against {ref}; {len(bad)} mismatch(es).")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
