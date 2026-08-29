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


# A VERDICT FIELD IS WHAT MAKES A SIM RECORD A RESULT. Any one of these being
# present means the run reached a conclusion about something.
_VERDICT_FIELDS = ("configs_total", "configs_passed", "build_status",
                   "golden_accepted", "all_passed", "faults_caught")


def is_result(rec):
    """False for a `kind: sim` record that reached no verdict at all.

    45 records carry kind=sim with EXACTLY seven keys -- git_sha, kind, label,
    submission, submission_sha256_16, task, timestamp_utc -- and no verdict
    field of any sort. Their label is `task_text_hash=<digest>`: they were
    written to stamp a task text, not to record a simulation. A record of one
    kind wearing another kind's name.

    SAFE TODAY BY ACCIDENT, which is the reason to fix it rather than the reason
    not to. Every reader selects the newest record per submission, and measured
    across the corpus zero stamping records are newer than every real record for
    the same submission. But TEN of them name `nonblocking_dcache_ref.sv`, so
    one written after a real run would make d_ca01's REFERENCE render as having
    reached no verdict -- and "no verdict" is not distinguishable downstream
    from "no result", which is the in-range failure value again.

    Same shape as the invalidated flag: correct behaviour that depends on
    timestamps rather than on anything anyone decided.
    """
    if (rec or {}).get("kind") != "sim":
        return True
    return any(rec.get(k) is not None for k in _VERDICT_FIELDS)


def valid_records(recs):
    return [r for r in recs if not is_invalidated(r) and is_result(r)]


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
