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
    every finding cites the rule(s) it produced        (FINDINGS.md "**Rules:**")
    every cited rule exists                            (RULES.md  numbering)

This is the ONLY automatable control available for contract defects. Apparatus
defects are caught by negative controls and known-failing inputs; a contract
defect leaves the apparatus working perfectly, so nothing fires. A broken link
here is the one machine-detectable symptom.

Exit 0 if the graph is complete, 1 otherwise. Runs with the regression.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rules_txt = open(os.path.join(REPO, "RULES.md"), encoding="utf-8").read()
find_txt = open(os.path.join(REPO, "FINDINGS.md"), encoding="utf-8").read()

# ---- parse ----------------------------------------------------------------
rule_ids = set(int(n) for n in re.findall(r"^(\d+)\. \*\*", rules_txt, re.M))
rule_from = {}
for m in re.finditer(r"^(\d+)\. \*\*.*?\n(.*?)(?=^\d+\. \*\*|\n---)", rules_txt, re.S | re.M):
    n = int(m.group(1))
    fm = re.search(r"\*\*From:\*\*\s*(.+)", m.group(2))
    rule_from[n] = fm.group(1).strip() if fm else None

finding_ids = set(re.findall(r"^#{2,3} ([PF]\d+)\.", find_txt, re.M))
finding_rules = {}
for m in re.finditer(r"^#{2,3} ([PF]\d+)\..*?\n(.*?)(?=^#{2,3} [PF]\d+\.|\n---\n# |\Z)",
                     find_txt, re.S | re.M):
    fid = m.group(1)
    rm = re.search(r"\*\*Rules:\*\*\s*(.+)", m.group(2))
    finding_rules[fid] = rm.group(1).strip() if rm else None

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

# ---- every finding cites a rule, and cited rules exist ---------------------
for fid in sorted(finding_ids):
    src = finding_rules.get(fid)
    if not src:
        errors.append(f"finding {fid} cites no rule (add a '**Rules:**' line, or state why none)")
        continue
    for n in re.findall(r"\b(\d+)\b", src):
        if int(n) not in rule_ids:
            errors.append(f"finding {fid} cites rule {n}, which does not exist in RULES.md")

# ---- report ---------------------------------------------------------------
print(f"rules: {len(rule_ids)}   findings: {len(finding_ids)}")
if errors:
    print(f"\nLINKAGE BROKEN -- {len(errors)} problem(s):")
    for e in errors:
        print(f"  {e}")
    sys.exit(1)
print("linkage complete: every rule cites a finding, every finding cites a rule.")
