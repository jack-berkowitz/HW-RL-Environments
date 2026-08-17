#!/usr/bin/env python3
"""Assert the rule/finding graph is complete, in both directions.

WHY THIS EXISTS
---------------
`RULES.md` is the single source of truth for the standing rules (rule 13), which
makes it a single point of failure with no control on it. The consolidation edit
that CREATED it silently dropped one of the rules it was consolidating -- see
FINDINGS.md F16 -- and no test would have caught that: every document was
well-formed and the list looked complete.

So the graph is checked mechanically instead of remembered:

    every rule cites the finding(s) that produced it   (RULES.md  "**From:**")
    every cited finding exists                         (FINDINGS.md headings)
    every finding cites what it produced               (FINDINGS.md "**Rules:**"
                                                        or "**Convention:**")
    every cited rule exists                            (RULES.md  numbering)
    every cited convention exists                      (CONVENTIONS.md headings)
    no rule list exists outside RULES.md               (rule 13, see F19)

A finding may produce a RULE or a CONVENTION, and the distinction is the boundary
in rule 13: RULES.md is how we know a result is trustworthy, CONVENTIONS.md is
how we avoid a known pothole. Craft belongs in the latter -- an unsigned
concatenation destroying a sign is a real defect and produces no methodology.
Both are traceable, so both satisfy "this finding changed something"; what is NOT
acceptable is a finding that changed nothing.

This is the ONLY automatable control available for contract defects. Apparatus
defects are caught by negative controls and known-failing inputs; a contract
defect leaves the apparatus working perfectly, so nothing fires. A broken link
here is the one machine-detectable symptom.

WHAT THIS DOES NOT CHECK -- do not over-read a green run
--------------------------------------------------------
It asserts STRUCTURAL completeness, not correctness of content. A rule citing the
WRONG finding passes. A rule whose text no longer matches the finding it cites
passes. A rule that should exist and does not passes, because nothing references
it.

The duplication check is deliberately narrow. It rejects a rule *table* outside
RULES.md, which is what F19 actually found and is a structural property. It does
NOT attempt to detect a rule RESTATED as prose or as a section heading -- that is
a content question, and a cheap proxy for it would flag every legitimate
reference and miss every careful paraphrase. Per this document's own opening
line, an automated proxy for a property you cannot observe is a guess with a
number attached. Restatement is caught by review, and F19 is the record of what
it costs when review misses it.

And more broadly: a complete graph says the rules are internally consistent. It
says nothing about whether they COVER the space of ways this project can be
wrong -- see FINDINGS.md, "A stated limitation of the rule set". d_dsp02 produced
an entire defect class the existing rules had not anticipated, and this checker
was green throughout.

Exit 0 if the graph is complete, 1 otherwise. Runs with the regression.
"""
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rules_txt = open(os.path.join(REPO, "RULES.md"), encoding="utf-8").read()
find_txt = open(os.path.join(REPO, "FINDINGS.md"), encoding="utf-8").read()
conv_txt = open(os.path.join(REPO, "CONVENTIONS.md"), encoding="utf-8").read()

# ---- parse ----------------------------------------------------------------
rule_ids = set(int(n) for n in re.findall(r"^(\d+)\. \*\*", rules_txt, re.M))
rule_from = {}
for m in re.finditer(r"^(\d+)\. \*\*.*?\n(.*?)(?=^\d+\. \*\*|\n---)", rules_txt, re.S | re.M):
    n = int(m.group(1))
    fm = re.search(r"\*\*From:\*\*\s*(.+)", m.group(2))
    rule_from[n] = fm.group(1).strip() if fm else None

finding_ids = set(re.findall(r"^#{2,3} ([PF]\d+)\.", find_txt, re.M))
finding_rules = {}
finding_convs = {}
for m in re.finditer(r"^#{2,3} ([PF]\d+)\..*?\n(.*?)(?=^#{2,3} [PF]\d+\.|\n---\n# |\Z)",
                     find_txt, re.S | re.M):
    fid = m.group(1)
    rm = re.search(r"\*\*Rules:\*\*\s*(.+)", m.group(2))
    cm = re.search(r"\*\*Convention:\*\*\s*(.+)", m.group(2))
    finding_rules[fid] = rm.group(1).strip() if rm else None
    finding_convs[fid] = cm.group(1).strip() if cm else None


def norm(s):
    """Compare headings on words only -- em dashes and backticks drift."""
    return re.sub(r"[^a-z0-9 ]+", "", s.lower()).split()


conv_heads = [h.strip() for h in re.findall(r"^#{2,3} (.+)$", conv_txt, re.M)]
conv_norm = [norm(h) for h in conv_heads]

errors = []

# ---- every rule cites something, and cited findings exist ------------------
for n in sorted(rule_ids):
    src = rule_from.get(n)
    if not src:
        errors.append(f"rule {n} cites no originating finding (add a '**From:**' line)")
        continue
    cited = re.findall(r"\b([PF]\d+)\b", src)
    if not cited and "no originating defect" not in src and "elasticity" not in src \
       and "hand-computed" not in src:
        errors.append(f"rule {n} '**From:**' names no finding id and no explicit exemption: {src!r}")
    for fid in cited:
        if fid not in finding_ids:
            errors.append(f"rule {n} cites {fid}, which does not exist in FINDINGS.md")

# ---- every finding cites a rule OR a convention, and the target exists -----
for fid in sorted(finding_ids):
    src = finding_rules.get(fid)
    conv = finding_convs.get(fid)
    if not src and not conv:
        errors.append(f"finding {fid} cites nothing it produced "
                      f"(add '**Rules:**' or '**Convention:**')")
        continue
    for n in re.findall(r"\b(\d+)\b", src or ""):
        if int(n) not in rule_ids:
            errors.append(f"finding {fid} cites rule {n}, which does not exist in RULES.md")
    if conv and norm(conv) not in conv_norm:
        errors.append(f"finding {fid} cites convention {conv!r}, "
                      f"which is not a heading in CONVENTIONS.md")

# ---- rule 13: no rule RESTATEMENT may exist outside RULES.md ---------------
# The first version rejected only a rule-list TABLE, which is the form F19
# happened to find. TASK_CATALOG.md then carried the same defect as a NUMBERED
# LIST with its own numbering, and passed -- the check was shaped like the
# instance rather than like the rule.
#
# Detection is phrase reuse, not semantics: take a distinctive span of each
# rule's opening sentence and look for it elsewhere. A legitimate reference
# cites "rule N" and does not reproduce the sentence, so this does not fire on
# citations. It cannot catch a careful paraphrase -- stated, not papered over.
def rule_fingerprints(txt):
    out = {}
    for m in re.finditer(r"^(\d+)\. \*\*(.+?)\*\*", txt, re.M | re.S):
        n, head = int(m.group(1)), " ".join(m.group(2).split())
        words = re.sub(r"[^a-z0-9 ]", "", head.lower()).split()
        if len(words) >= 6:
            out[n] = " ".join(words[:8])
    return out


FINGERPRINTS = rule_fingerprints(rules_txt)

for fname in sorted(glob.glob(os.path.join(REPO, "*.md")) +
                    glob.glob(os.path.join(REPO, "domains", "*", "*", "*", "*.md"))):
    base = os.path.relpath(fname, REPO)
    if base == "RULES.md":
        continue
    try:
        txt = open(fname, encoding="utf-8", errors="replace").read()
    except OSError:
        continue
    flat = " ".join(re.sub(r"[^a-z0-9 ]", "", txt.lower()).split())
    hits = sorted(n for n, fp in FINGERPRINTS.items() if fp in flat)
    if re.search(r"^\|\s*#\s*\|\s*rule\s*\|", txt, re.M | re.I):
        errors.append(f"{base} contains a rule-list table; the rules live only "
                      f"in RULES.md (rule 13, F19)")
    if len(hits) >= 2:
        errors.append(f"{base} RESTATES rules {hits} verbatim -- the rules live "
                      f"only in RULES.md (rule 13, F19/F32). Cite 'rule N' "
                      f"instead of reproducing the text.")

# ---- report ---------------------------------------------------------------
print(f"rules: {len(rule_ids)}   findings: {len(finding_ids)}   "
      f"conventions: {len(conv_heads)}")
if errors:
    print(f"\nLINKAGE BROKEN -- {len(errors)} problem(s):")
    for e in errors:
        print(f"  {e}")
    sys.exit(1)
print("linkage complete: every rule cites a finding, every finding cites a rule "
      "or a convention, and no rule list exists outside RULES.md.")
