#!/usr/bin/env python3
"""Refuse to stage a file that changed under you between writing and staging.

WHY THIS EXISTS (F61, and F76 as its fourth recurrence)
-------------------------------------------------------
Several agents share one working tree here. The compare-and-swap on
`git update-ref HEAD $NEW $OLD` guards the REF: it fails if anyone commits
between your read of HEAD and your write, and that guard works.

It is the wrong race. `fedb323` did not lose it -- the CAS was valid and HEAD had
not moved. What changed was the CONTENT: `RULES.md` on disk gained a peer's two
new rules between the moment I decided to stage it and the moment I did, and
`git add RULES.md` stages the FILE, so their work went into a commit of mine
under a subject about something else. The rules landed and their findings did
not, and HEAD failed linkage until they repaired it.

So: the ref race is guarded and the content race is not. All four of F61's
instances are the second kind.

WHAT THIS DOES
--------------
    stage_guard.py record <path>...    # right after you finish writing
    stage_guard.py verify <path>...    # right before `git add`

`record` stores `git hash-object` of each path. `verify` re-hashes and compares.
A path whose content moved since you recorded it means someone else wrote to it,
and verify exits 1 rather than letting the stage proceed.

NO RECORD IS A REFUSAL, NOT A PASS. A path with nothing to compare against exits
1 and says so. This is the distinction that made F79 worse than the failure it
was found chasing: an absent value and a matching one must not take the same
branch, because "I never checked" reads identically to "I checked and it was
fine" everywhere downstream. Same reason the stimulus-variation checker reports
"cannot conclude" for a signal missing from its dump.

WHAT IT DOES NOT DO
-------------------
It cannot help with a file that was never in git -- F61's fourth instance, a
solicited candidate lost before it was ever committed. There is nothing to hash
against. That one needs a different answer and this is not it.

It is also advisory: nothing forces a caller to run it. It is a guard for the
workflow that already stages by explicit path through a temp index, not a
replacement for that workflow.

MANIFEST location: $STAGE_GUARD_MANIFEST, else a per-repo file under the
system temp directory keyed by the repo path. Per-agent by construction, since
"what I last wrote" is not a shared fact.
"""
import hashlib
import json
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def manifest_path():
    env = os.environ.get("STAGE_GUARD_MANIFEST")
    if env:
        return env
    key = hashlib.sha256(REPO.encode()).hexdigest()[:12]
    return os.path.join(tempfile.gettempdir(), f"stage_guard_{key}.json")


def blob_hash(path):
    """git hash-object, so the comparison is in git's own terms."""
    if not os.path.isfile(path):
        return None
    out = subprocess.run(["git", "hash-object", "--", path],
                         cwd=REPO, capture_output=True, text=True)
    return out.stdout.strip() if out.returncode == 0 else None


def load():
    p = manifest_path()
    if not os.path.isfile(p):
        return {}
    try:
        return json.load(open(p))
    except Exception:
        return {}


def save(d):
    json.dump(d, open(manifest_path(), "w"), indent=1, sort_keys=True)


def rel(path):
    """Repo-relative when inside the repo, absolute otherwise -- a key of
    ../../../private/tmp/... is unreadable and would also collide between
    different callers' notions of where they are."""
    a = os.path.abspath(path)
    r = os.path.relpath(a, REPO)
    return a if r.startswith(os.pardir) else r


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("record", "verify"):
        print(__doc__.strip().splitlines()[0])
        print("usage: stage_guard.py {record|verify} <path>...")
        return 2
    mode, paths = sys.argv[1], sys.argv[2:]
    man = load()

    if mode == "record":
        for p in paths:
            h = blob_hash(p)
            if h is None:
                print(f"  cannot record (not a file): {p}")
                return 2
            man[rel(p)] = h
        save(man)
        for p in paths:
            print(f"  recorded {rel(p)} {man[rel(p)][:12]}")
        return 0

    bad = 0
    for p in paths:
        r = rel(p)
        now = blob_hash(p)
        was = man.get(r)
        if now is None:
            print(f"  REFUSE {r}: not a file")
            bad += 1
        elif was is None:
            # Not a pass. See the docstring.
            print(f"  REFUSE {r}: no recorded hash to compare against -- "
                  f"run `stage_guard.py record` when you write it")
            bad += 1
        elif was != now:
            print(f"  REFUSE {r}: changed since you wrote it "
                  f"({was[:12]} -> {now[:12]}). Someone else has edited this "
                  f"file; re-read and re-apply rather than staging over them.")
            bad += 1
        else:
            print(f"  ok {r} {now[:12]}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
