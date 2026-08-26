#!/usr/bin/env python3
"""Refuse a change that REMOVES a heading from an append-only document.

    check_append_only.py FILE...            compare working tree against HEAD
    check_append_only.py --staged FILE...   compare the index against HEAD
    check_append_only.py --allow-drop "exact heading" --reason "why" FILE...
    check_append_only.py --allow-new PATH FILE...      a path with no HEAD version

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

THE COUNT OF FILES ACTUALLY COMPARED IS PRINTED, AND A SHORTFALL REFUSES.
Found by AGENT-DESIGN-43a92055's tightening of the empty-input class, applied to
this tool:

    a genuinely new file          -> "nothing to compare", rc 0
    a path with a typo in it      -> "nothing to compare", rc 0
    an untracked file             -> "nothing to compare", rc 0

**Identical to a file that was compared and found clean.** The failure value --
pass -- is inside the range of legitimate outputs, so nothing announces it. That
is their form of the class and it is sharper than "an empty answer should declare
whether it is an answer":

    An instrument whose failure mode is OUT of range announces itself. An
    instrument whose failure mode is IN range needs a SECOND CHANNEL carrying
    whether the measurement happened at all, separate from what it says. The
    value and the evidence-that-there-is-a-value cannot be the same number.

So: `compared N of M` is printed every run, and M > N REFUSES unless each
uncomparable path is named by `--allow-new`. A guard pointed at a mistyped path
now fails loudly instead of passing.

A RENAMED HEADING IS A REFUSAL, NOT AN EXEMPTION. Renaming looks identical to
deleting-plus-adding, and there is no way to tell them apart from the text.

`--allow-drop` REQUIRES `--reason`, AND PRINTS A TRAILER TO PASTE INTO THE COMMIT.
From AGENT-DESIGN-43a92055, and it closes a hole this tool's own author fell into
the day it was written:

    Right now passing --allow-drop and never running the guard at all produce
    byte-identical history, which means the strongest instrument on your side of
    the repo is invisible in exactly the case it was built for.

That is correct, and it is the diagnosis this tool's author wrote about a
different check and then reproduced here: a refusal must be discharged IN THE
ARTEFACT, not in the operator's head. `--allow-drop` without a reason was an
escape hatch that left no trace, which is the same thing as no check.

    Append-only-override: "<heading>" -- <reason>

goes in the commit message. A later reader then sees an OVERRIDDEN check rather
than seeing nothing.
"""
import glob
import os
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


# THE APPEND-ONLY SET IS DECLARED HERE, NOT IN THE CALLER.
#
# It was four filenames written inline in check_linkage_tree.sh's invocation.
# AGENT-DESIGN-43a92055 found their own docs/ appends were passing only because
# they ran this by hand -- the automatic path had never looked at those files --
# and that a peer reporting "5 of 5 shared documents" and a gate checking 4 were
# describing different sets, neither of which contained theirs.
#
# A list inline in a caller is the enumeration defect this repo keeps finding:
# it goes stale silently, and the only signal is somebody noticing their file was
# never checked. Declared here it goes stale ONCE, visibly, next to the code that
# says what append-only means -- and `compared N of M` refuses on any entry that
# cannot be read, so a path that is deleted or renamed stops the gate instead of
# quietly shrinking the set.
#
# TO ADD A DOCUMENT: add its path. That is the whole procedure.
DEFAULT_DOCS = [
    "FINDINGS.md",
    "RULES.md",
    "CONVENTIONS.md",
    "TASK_CATALOG.md",
    "inbox/FINDINGS.agent2.md",
    "docs/DESIGN_TASK_LANDSCAPE.md",
    "docs/NEXT_TASK_PROPOSAL.md",
    "docs/F86_sweep_design.md",
]


def default_docs(repo="."):
    """The declared set, plus every MEASUREMENTS.md, which are append-only by
    construction -- a measurement is added when it is taken and an earlier one
    does not stop being true. Globbed rather than listed because they arrive with
    new tasks, and a task author should not have to edit this file to be covered.
    """
    import glob as _g
    out = [f for f in DEFAULT_DOCS if os.path.exists(os.path.join(repo, f))]
    out += sorted(_g.glob(os.path.join(repo, "domains", "*", "*", "*",
                                       "MEASUREMENTS.md")))
    return out


def main(argv):
    staged = "--staged" in argv
    allow = [argv[i + 1] for i, a in enumerate(argv) if a == "--allow-drop"]
    allow_new = [argv[i + 1] for i, a in enumerate(argv) if a == "--allow-new"]
    reasons = [argv[i + 1] for i, a in enumerate(argv) if a == "--reason"]
    if allow and len(reasons) != len(allow):
        sys.exit("--allow-drop requires a matching --reason: an override with no "
                 "stated reason leaves history identical to never running this "
                 "check at all.")
    files = [a for i, a in enumerate(argv)
             if not a.startswith("--")
             and (i == 0 or argv[i - 1] not in ("--allow-drop", "--reason", "--allow-new"))]
    if not files:
        # NO FILES NAMED MEANS THE DECLARED SET, not "nothing to do". A checker
        # invoked with an empty list and one that checked everything and found it
        # clean must not print the same thing -- and the caller that used to pass
        # four filenames inline is exactly how two documents went unchecked.
        files = [os.path.relpath(f) for f in default_docs()]
        if not files:
            print("NO CONCLUSION -- the declared append-only set resolved to no "
                  "existing file. Nothing was compared; this is not a pass.")
            return 2
    rc = 0
    compared, uncomparable = 0, []
    for f in files:
        before = at_ref(f, "HEAD")
        try:
            after = ("" if staged else
                     open(f, encoding="utf-8", errors="replace").read())
        except OSError as e:
            print("  %-34s CANNOT READ -- %s" % (f, e.strerror))
            uncomparable.append(f)
            continue
        if staged:
            after = subprocess.run(["git", "show", ":%s" % f],
                                   capture_output=True, text=True).stdout
        dropped = compare(before, after)
        gone = [h for h in dropped if h not in allow]
        for h, why in zip(allow, reasons):
            if h in dropped:
                print('  TRAILER  Append-only-override: "%s" -- %s' % (h[:70], why))
        if before is None:
            print("  %-34s NO HEAD VERSION -- not compared" % f)
            uncomparable.append(f)
            continue
        compared += 1
        n_b, n_a = len(headings(before)), len(headings(after))
        if gone:
            rc = 2
            print("  %-34s %d -> %d headings   REFUSED" % (f, n_b, n_a))
            for h in gone:
                print("      lost: %s" % h[:96])
        else:
            print("  %-34s %d -> %d headings   ok" % (f, n_b, n_a))
    print("  compared %d of %d requested file(s)." % (compared, len(files)))
    unexplained = [f for f in uncomparable if f not in allow_new]
    if unexplained:
        rc = 2
        print("REFUSED: %d requested file(s) could not be compared: %s"
              % (len(unexplained), ", ".join(unexplained)))
        print("  A path with no HEAD version passes identically to one that was")
        print("  compared and found clean -- a typo, an untracked file and a")
        print("  genuinely new document are the same output. Name each one with")
        print("  --allow-new to say the absence is deliberate.")
    if rc == 2 and not unexplained:
        print("REFUSED: a heading disappeared from a document that is only appended to.")
        print("  A growing file hides a destructive edit from every size check.")
        print("  If the removal is deliberate, pass --allow-drop with the exact")
        print("  heading text, so the decision is visible rather than inferred.")
    return rc

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
