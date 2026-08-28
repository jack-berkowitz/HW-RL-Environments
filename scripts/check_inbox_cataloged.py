#!/usr/bin/env python3
"""Inbox entries must have a DISPOSITION, and a claimed one must be checkable.

WHY. Peer agents deliver findings as inbox/*.md. Landing them in FINDINGS.md is
manual, so an entry that nobody gets to is indistinguishable from one nobody
needed: both are a heading in a file. Twelve of eighteen from one delivery
landed as F98-F109 and the other six sat, discoverable only because the sender
re-sent their titles.

WHY NOT MATCH TITLES. Landed findings are REWRITTEN, not copied -- the inbox
entry "A hash computed before a peer's edit and reported after it" appears
nowhere verbatim in F98-F109. Any similarity threshold here would produce false
greens (an entry "matched" by an unrelated finding) and false reds in a checker
whose whole job is to be trusted. Disposition is therefore EXPLICIT.

  NOT-FOR-CATALOG            in the entry body, or in a file's first 10 lines
                             to dispose of the whole file
  LANDED: F<n>               and F<n> MUST EXIST in FINDINGS.md

THE SECOND HALF OF THAT RULE IS THE POINT. A marker saying "landed as F103" is
a claim about the catalog; checking that F103 exists is what makes it a claim
the tree can verify. This is the lesson from the 2524a28d freeze, applied
locally: a digest in a report is a claim, a digest the tree can check is an
attestation. An unverified LANDED marker would let an entry be dismissed by
asserting it was filed.

THE BASELINE, and why it is not a loophole. There are 285 undisposed entries
today. Failing on all of them would make the gate fire constantly on a backlog
nobody can clear in one sitting -- the cries-wolf failure that
check_linkage_tree.sh warns about three comments above where this is wired in,
and the reason check_unread_fields is deliberately report-only. So the existing
population is recorded in a baseline and REPORTED; anything NOT in the baseline
FAILS. New deliveries cannot rot silently, and the backlog stays counted rather
than hidden. A baseline entry that disappears is reported too, so the file
cannot quietly accumulate ghosts.

Exit: 0 = clean, 1 = an undisposed entry not in the baseline, or a LANDED
marker naming a finding that does not exist. 2 = baseline is stale.
"""
import glob
import hashlib
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASELINE = os.path.join(REPO, "inbox", ".catalog_baseline")
NOT_FOR = re.compile(r"NOT-FOR-CATALOG", re.I)
LANDED = re.compile(r"^\s*(?:LANDED|CATALOG(?:U?ED)?):\s*(F\d+)", re.I | re.M)
# THE CONVENTION CASE HAD NO MARKER, so an entry destined for CONVENTIONS.md
# could only be silenced with NOT-FOR-CATALOG -- which attests nothing and is
# the disposal equivalent of making two counts agree by subtraction. Raised by
# AGENT-DESIGN-43a92055 with AGENT-VERIF-A2 seconding it; eleven staged
# convention blocks in inbox/CONVENTIONS.md.agent2.md hit it the moment they
# leave the baseline.
#
# Verified against CONVENTIONS.md the same way LANDED is verified against
# FINDINGS.md, because the second half of the rule is the whole rule: an
# unverified marker lets an entry be dismissed by assertion. That half applied
# to findings only, which made the gap asymmetric as well as unmarked.
LANDED_CONV = re.compile(r"^\s*LANDED-CONVENTION:\s*(.+?)\s*$", re.I | re.M)


def entries():
    """[(file, title, body, file_exempt)] for every top-level inbox entry."""
    out = []
    for path in sorted(glob.glob(os.path.join(REPO, "inbox", "*.md"))):
        text = open(path, encoding="utf-8", errors="replace").read()
        head = "\n".join(text.split("\n")[:10])
        exempt = bool(NOT_FOR.search(head))
        parts = re.split(r"^## (?=\S)", text, flags=re.M)[1:]
        for p in parts:
            title = p.split("\n", 1)[0].strip()
            body = p.split("\n", 1)[1] if "\n" in p else ""
            out.append((os.path.basename(path), title, body, exempt))
    return out


def ident(f, title):
    return hashlib.sha1(f"{f}\x00{title}".encode()).hexdigest()[:12]


def main(argv):
    findings = ""
    fp = os.path.join(REPO, "FINDINGS.md")
    if os.path.isfile(fp):
        findings = open(fp, encoding="utf-8", errors="replace").read()
    known = set(re.findall(r"^## (F\d+)\.", findings, re.M))
    cp = os.path.join(REPO, "CONVENTIONS.md")
    conv_txt = (open(cp, encoding="utf-8", errors="replace").read()
                if os.path.isfile(cp) else "")
    # Match on a normalised heading so a marker need not reproduce punctuation.
    def _norm(x):
        return re.sub(r"[^a-z0-9]+", " ", x.lower()).strip()
    conv_known = {_norm(h) for h in re.findall(r"^## (.+)$", conv_txt, re.M)}

    base = set()
    if os.path.isfile(BASELINE):
        for line in open(BASELINE, encoding="utf-8"):
            line = line.strip()
            if line and not line.startswith("#"):
                base.add(line.split()[0])

    undisposed, bad_marker, seen = [], [], set()
    for f, title, body, exempt in entries():
        i = ident(f, title)
        seen.add(i)
        if exempt or NOT_FOR.search(body):
            continue
        m = LANDED.search(body)
        if m:
            # A CLAIM THE TREE CAN CHECK, not a claim in a report.
            if m.group(1) not in known:
                bad_marker.append((i, f, title, m.group(1)))
            continue
        mc = LANDED_CONV.search(body)
        if mc:
            want = _norm(mc.group(1))
            if not any(want == k or want in k or k in want for k in conv_known):
                bad_marker.append((i, f, title, f"convention {mc.group(1)!r}"))
            continue
        undisposed.append((i, f, title))

    if "--update-baseline" in argv:
        with open(BASELINE, "w", encoding="utf-8") as fh:
            fh.write("# Undisposed inbox entries at baseline time. Entries here "
                     "REPORT; anything new FAILS.\n")
            fh.write("# Clear one by adding `LANDED: F<n>` or `NOT-FOR-CATALOG` "
                     "to it, then re-running with --update-baseline.\n")
            for i, f, t in sorted(undisposed, key=lambda x: (x[1], x[2])):
                fh.write(f"{i}  {f}  {t[:96]}\n")
        print(f"baseline written: {len(undisposed)} undisposed entries")
        return 0

    rc = 0
    new = [e for e in undisposed if e[0] not in base]
    if bad_marker:
        rc = 1
        print(f"FAIL: {len(bad_marker)} entr(ies) claim a finding that is not in "
              f"FINDINGS.md:")
        for i, f, t, n in bad_marker:
            print(f"  {f}: {t[:70]!r} claims {n}")
    if new:
        rc = 1
        print(f"FAIL: {len(new)} inbox entr(ies) with no disposition and not in "
              f"the baseline:")
        for i, f, t in new:
            print(f"  {f}: {t[:70]}")
        print("  Add `LANDED: F<n>` (the finding must exist) or "
              "`NOT-FOR-CATALOG` to each.")
    ghosts = base - seen
    if ghosts:
        if rc == 0:
            rc = 2
        print(f"baseline is stale: {len(ghosts)} recorded entr(ies) no longer "
              f"exist. Re-run with --update-baseline.")
    carried = len(undisposed) - len(new)
    if carried:
        print(f"backlog: {carried} undisposed inbox entries carried in the "
              f"baseline (reported, not failing).")
    if rc == 0 and not carried:
        print("every inbox entry has a checkable disposition.")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
