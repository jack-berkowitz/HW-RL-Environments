#!/usr/bin/env python3
"""Refuse a change that REMOVES a heading from an append-only document.

    check_append_only.py FILE...            compare working tree against HEAD
    check_append_only.py --staged FILE...   compare the index against HEAD
    check_append_only.py --allow-drop "exact heading text" FILE...

WHY THIS EXISTS
---------------
`f4782a2` destroyed 162 committed lines of `inbox/FINDINGS.agent2.md` -- an
entire scoping section and a closing read, both committed six commits earlier.
The edit was meant to replace one section:

    open(p, "w").write(t[:t.index("### The founding case ...")] + new)

`t[index:]` takes that heading TO END OF FILE. One section was replaced and
everything after it was collateral.

NOTHING CAUGHT IT FOR SIX COMMITS BECAUSE THE FILE GREW. 3081 lines before,
3557 after -- more was appended in the following commits than had been
destroyed, so every size check, every `git diff --stat`, and every read of the
tail looked healthy.

    section count before   42
    section count after    40      <- the only number that moved the wrong way

That is the whole check. **A document that is only ever appended to must never
lose a heading**, and a heading count that falls is the one signal a growing
file cannot hide.

WHAT IT DOES NOT CATCH, SAID PLAINLY
------------------------------------
Content deleted from INSIDE a section, leaving its heading in place. This checks
the section list, not the sections. It would have caught `f4782a2` because whole
headings went; it would not catch a truncation that stops one line after a
heading. The stronger check is a per-section byte count, and it costs a policy
decision -- sections legitimately shrink when someone tightens prose -- which
this one does not.

A RENAMED HEADING IS A REFUSAL, NOT AN EXEMPTION. Renaming looks identical to
deleting-plus-adding, and there is no way to tell them apart from the text. The
refusal names the vanished heading; `--allow-drop` acknowledges it deliberately,
in the command line, where it is visible in a shell history and a commit message
rather than inferred.
"""
import re
import subprocess
import sys

HEAD = re.compile(r"^#{1,6} .*$", re.M)


def headings(text):
    return [h.strip() for h in HEAD.findall(text)]


def at_ref(path, ref):
    """-> text of path at ref, or None when the file is new there."""
    try:
        return subprocess.run(["git", "show", "%s:%s" % (ref, path)],
                              capture_output=True, text=True, check=True).stdout
    except subprocess.CalledProcessError:
        return None


def compare(before, after):
    """-> headings present before and absent after, in order."""
    if before is None:
        return []
    a = headings(after)
    seen = {}
    for h in a:
        seen[h] = seen.get(h, 0) + 1
    gone = []
    for h in headings(before):
        if seen.get(h, 0) > 0:
            seen[h] -= 1
        else:
            gone.append(h)
    return gone


def main(argv):
    staged = "--staged" in argv
    allow = [argv[i + 1] for i, a in enumerate(argv) if a == "--allow-drop"]
    files = [a for i, a in enumerate(argv)
             if not a.startswith("--") and (i == 0 or argv[i - 1] != "--allow-drop")]
    if not files:
        sys.exit(__doc__.strip().splitlines()[0])
    rc = 0
    for f in files:
        before = at_ref(f, "HEAD")
        after = at_ref(f, "") if staged else open(f, encoding="utf-8", errors="replace").read()
        if staged:
            after = subprocess.run(["git", "show", ":%s" % f],
                                   capture_output=True, text=True).stdout
        gone = [h for h in compare(before, after) if h not in allow]
        if before is None:
            print("  %-34s new file -- nothing to compare" % f)
            continue
        n_b, n_a = len(headings(before)), len(headings(after))
        if gone:
            rc = 2
            print("  %-34s %d -> %d headings   REFUSED" % (f, n_b, n_a))
            for h in gone:
                print("      lost: %s" % h[:96])
        else:
            print("  %-34s %d -> %d headings   ok" % (f, n_b, n_a))
    if rc:
        print("REFUSED: a heading disappeared from a document that is only appended to.")
        print("  A growing file hides a destructive edit from every size check.")
        print("  If the removal is deliberate, pass --allow-drop with the exact")
        print("  heading text, so the decision is visible rather than inferred.")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
