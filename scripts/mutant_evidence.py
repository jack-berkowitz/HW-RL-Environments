#!/usr/bin/env python3
"""Read each task's per-mutant evidence of non-equivalence (rule 21).

    mutant_evidence.py            # every task, one line each; exit 1 if any
                                  # mutant ships without a recorded type
    mutant_evidence.py --json     # machine-readable

WHAT THIS CHECKS, AND WHAT IT CANNOT
------------------------------------
**Structural only.** It checks that every mutant declares an evidence TYPE and
that the type is one rule 21 accepts. It cannot check that the evidence is real:
it does not verify that the named witness vector actually fails, that the
bounded counterexample exists, or that the depth quoted was the depth run.

That limitation is the point of writing it down. F26's whole class is checks
whose stated scope exceeds their reach -- a check named "evidence check" that
only counts fields will be read as having validated the evidence. It has not.
A mutant can pass this and still carry a witness that never fails.

THE TWO RECORDED SHAPES, both compliant per rule 21:

    evidence: bmc_cex, cex_depth: 34     explicit -- a bounded counterexample
    witness: "vector 140"                implicit -- the type IS `witness`, and
                                         rule 21 states witness is full-standing
                                         and requires no re-validation

DEPTH IS PER MUTANT, NEVER PER TASK. d_ca01 carries depth 34 on three mutants
and depth 14 on three others. Collapsing those to one number per task would
report a bound that half the set never had.
"""
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ACCEPTED = ("witness", "bmc_cex")


def task_dirs():
    out = []
    for kind in ("design", "verification"):
        for d in sorted(__import__("glob").glob(
                os.path.join(REPO, "domains", "*", kind, "*"))):
            if os.path.isfile(os.path.join(d, "task.yaml")):
                out.append(d)
    return out


def mutants_for(task_dir):
    """[(id, evidence_type|None, depth|None)] for every mutant the task declares."""
    y = os.path.join(task_dir, "task.yaml")
    try:
        txt = open(y, encoding="utf-8").read()
    except OSError:
        return []
    # LINE-BASED, not a regex block. A lookahead for "the next top-level key"
    # matched the mutants header itself on one task and silently returned no
    # mutants -- a parser that finds nothing looks identical to a task with no
    # mutants, which is the failure this whole script exists to prevent.
    lines, inside, buf, items = txt.split("\n"), False, [], []
    for ln in lines:
        if re.match(r"^mutants:\s*$", ln):
            inside = True
            continue
        if inside:
            # a new top-level key ends the block
            if ln and not ln[0].isspace():
                break
            if re.match(r"^\s*-\s", ln):
                if buf:
                    items.append(" ".join(buf))
                buf = [ln.strip().lstrip("-").strip()]
            elif buf and ln.strip() and not ln.strip().startswith("#"):
                buf.append(ln.strip())
    if buf:
        items.append(" ".join(buf))

    out = []
    for flat in items:
        idm = re.search(r"\b(?:id|name):\s*([A-Za-z0-9_]+)", flat)
        if not idm:
            continue
        ev = re.search(r"\bevidence:\s*([A-Za-z_]+)", flat)
        dep = re.search(r"\bcex_depth:\s*(\d+)", flat)
        kind = ev.group(1) if ev else ("witness" if re.search(r"\bwitness:", flat) else None)
        out.append((idm.group(1), kind, int(dep.group(1)) if dep else None))
    return out


def summarise(task_dir):
    """`6/6 (bmc<=34 x3, bmc<=14 x3)` -- per-mutant, never one value per task."""
    ms = mutants_for(task_dir)
    if not ms:
        return None
    parts, counts = [], {}
    for _id, kind, depth in ms:
        key = f"bmc<={depth}" if kind == "bmc_cex" and depth else (kind or "UNRECORDED")
        counts[key] = counts.get(key, 0) + 1
    for k in sorted(counts, key=lambda x: (x == "UNRECORDED", x)):
        parts.append(f"{k} x{counts[k]}" if counts[k] > 1 else k)
    return f"{len(ms)} mutant(s): " + ", ".join(parts)


def main():
    as_json = "--json" in sys.argv
    rows, bad = {}, []
    for d in task_dirs():
        ms = mutants_for(d)
        if not ms:
            continue
        name = os.path.basename(d)
        rows[name] = [{"id": i, "evidence": k, "cex_depth": dp} for i, k, dp in ms]
        for i, k, _dp in ms:
            if k not in ACCEPTED:
                bad.append((name, i, k))
    if as_json:
        print(json.dumps(rows, indent=2))
        return 1 if bad else 0

    for name in sorted(rows):
        detail = ", ".join(
            f"{r['id']}={r['evidence'] or 'UNRECORDED'}"
            f"{'@' + str(r['cex_depth']) if r['cex_depth'] else ''}"
            for r in rows[name])
        print(f"  {name:30s} {detail}")
    if bad:
        print("\n  REFUSED -- mutant(s) with no recorded evidence type (rule 21):")
        for t, i, k in bad:
            print(f"    {t}: {i} -> {k or 'nothing recorded'}")
        print(f"\n  {len(bad)} unevidenced. A mutant of unknown status inflates the")
        print("  denominator of every kill rate computed from the set.")
        print("  NOTE: this check is STRUCTURAL. It confirms a type is recorded;")
        print("  it does NOT confirm the witness fails or the counterexample exists.")
        return 1
    print(f"\n  all mutants across {len(rows)} task(s) carry a recorded evidence type.")
    print("  STRUCTURAL ONLY -- a recorded type is not a verified one.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
