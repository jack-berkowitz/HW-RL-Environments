#!/usr/bin/env python3
"""Is a run record eligible to be read as a result?

WHY THIS IS A MODULE AND NOT A ONE-LINE CHECK IN EACH READER. Five fields --
invalidated, invalidated_by, invalidated_reason, invalidated_simulator,
invalidated_superseded_by -- were written onto a record and read by NOTHING.
The record is d_ai01's REFERENCE captured as failing 0/2 under Verilator 5.032,
a toolchain artefact rather than a result, superseded twenty-nine minutes later.

IT IS SAFE TODAY BY ACCIDENT. Every reader here selects the newest record per
submission, and the superseding one is newer, so the invalidated row loses on
timestamp. That is not the same as honouring the flag: a record invalidated in
favour of an EARLIER one, or any reader that aggregates instead of selecting,
gets a reference that fails its own task. Whoever wrote those five fields was
entitled to expect them to mean something.

F91's shape exactly -- a field with no reader cannot be wrong, which is not the
same as being right.
"""
import os
import sys


def is_invalidated(rec):
    """True when a record has been explicitly withdrawn."""
    v = (rec or {}).get("invalidated")
    return v is True or (isinstance(v, str) and v.strip().lower() in ("true", "yes", "1"))


def valid_records(recs):
    return [r for r in recs if not is_invalidated(r)]


def main():
    import glob
    import json
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    bad = []
    for f in sorted(glob.glob(os.path.join(repo, "runs", "*", "*.json"))):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        if is_invalidated(r):
            bad.append((os.path.relpath(f, repo),
                        r.get("invalidated_by", "?"),
                        str(r.get("invalidated_superseded_by", "?"))))
    print(f"{len(bad)} invalidated record(s):")
    for p, by, sup in bad:
        print(f"  {p}\n    withdrawn by {by}\n    superseded by {sup}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
