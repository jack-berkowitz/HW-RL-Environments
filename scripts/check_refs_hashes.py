#!/usr/bin/env python3
"""Verify vendored reference files still match the hashes in refs.lock.

THESE HASHES ATTEST LOCAL STATE, NOT PROVENANCE. They were computed from the
bytes on disk on 2026-08-17; nothing has ever been compared against upstream at
the pinned SHAs, and with egress closed nothing can be. A file that was already
wrong when hashed stays wrong and passes.

What this detects is DRIFT FROM THAT POINT: an edit, truncation or replacement
after the hashes were taken. That is worth having -- the vendored tree is the
oracle for every Class A task, and nothing else notices if it changes.
"""
import hashlib, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
lock = open(os.path.join(REPO, "refs.lock"), encoding="utf-8", errors="replace").read()
rows = re.findall(r"^  (refs/\S+): \{sha256: ([0-9a-f]{64}), bytes: (\d+)\}", lock, re.M)
if not rows:
    print("no file_hashes block in refs.lock"); sys.exit(2)

bad, gone, ok = [], [], 0
for path, want, nbytes in rows:
    fp = os.path.join(REPO, path)
    if not os.path.isfile(fp):
        gone.append(path); continue
    got = hashlib.sha256(open(fp, "rb").read()).hexdigest()
    if got != want:
        bad.append((path, want, got))
    else:
        ok += 1

print(f"  {ok} unchanged, {len(bad)} CHANGED, {len(gone)} missing "
      f"(of {len(rows)} recorded)")
for p, w, g in bad:
    print(f"    CHANGED {p}\n      recorded {w[:16]}  now {g[:16]}")
for p in gone:
    print(f"    MISSING {p}")
if bad or gone:
    print("\n  The vendored tree is the oracle for every Class A task. A change here")
    print("  changes what 'correct' means, and nothing else in the harness notices.")
    sys.exit(1)
sys.exit(0)
