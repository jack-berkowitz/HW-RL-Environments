#!/usr/bin/env python3
"""Which clauses can a reference NEVER report?

Every clause a spec states should be EMITTABLE by the testbench that scores it.
Take the clause ids from spec/*_spec.md, take the clause ids appearing in any
fail(...) in tb/*_tb.sv, subtract. What remains is stated and unreportable.

WHY THIS EXISTS. v_ca06's read-side response check reported a wrong error CODE
as a D6 failure. D6 is precedence -- an error is due and must appear. D7 is code
preservation. One branch covered both, so D7 had NO PATH TO BEING REPORTED AT
ALL, and a submission that checked only precedence would have been credited with
checking preservation.

Four instruments agreed it was fine: every mutant killed, every conformant
variant passed, every witness string matched, every input varied. All four were
consistent with the check testing a different property than the one it named.
AGREEMENT AMONG INSTRUMENTS THAT SHARE A BLIND SPOT IS NOT CORROBORATION. This
check does not share that blind spot, because it never looks at a run.

THIS PRINTS A CANDIDATE LIST, NOT A VERDICT.
Hand-calibrated once, on v_ca07_clk_int_div, where the answer was known:

    H2, P4   FALSE POSITIVE -- obligations on the TESTER, not the design.
             Nothing to emit; a spec may address the measurer.
    P3       FALSE POSITIVE -- an explicitly unscored distinction, already
             documented, whose scored half is checked under another clause id.
    C3       REAL -- no check emits it, and the spec carries a "Measured:" line
             for it. A stated measurement with no instrument behind it.
    G2       REAL -- no check emits it.

TWO REAL OF FIVE. Across eleven verification tasks it returns about ninety ids.
NINETY IS NOT NINETY DEFECTS. A reader who takes the count as a defect count has
been harmed by this tool.

SECOND CALIBRATION, on v_ca06_axi_dw_downsizer, and it moves the guidance. Of its
seven hits, most are NOT tester obligations -- they are clauses EXERCISED AND
REPORTED UNDER ANOTHER CLAUSE'S ID. C3 ("a FIXED burst of exactly one beat is
accepted") is keyed on by mutant dw_m4, and dw_m4's witness reports D5. C1 and C2
(WRAP and multi-beat FIXED are refused) are exercised through the refused-burst
checks, which report C4.

THAT FAMILY IS THE DANGEROUS ONE, not the benign one. It is the D6/D7 defect seen
from the other side: the clause is tested, and the output names something else. It
was a hit of exactly this shape on v_ca06 -- D7 exercised, D6 reported -- that
cost a clause its scoring while four other instruments called the task clean. So
"it is checked under another id" is a reason to look at the message, not a reason
to dismiss the hit.

The one genuinely quiet false positive is a clause addressed to the TESTER rather
than to the design (v_ca07's H2 and P4). Those have nothing to emit by
construction.

WHAT IT DOES NOT DO. It cannot tell you which of the two families a hit belongs
to; that needs the clause read. It reports NO CONCLUSION, and exits non-zero,
where a task has no spec or no testbench: "nothing unreportable" and "nothing was
read" must not print the same. Design tasks come back NO CONCLUSION under this
layout, because their testbench is the submission and not tb/*_tb.sv -- adapting
that is a change to where it looks, not to what it computes.

  usage:  check_clause_emittable.py [path ...]      default: all task dirs
          check_clause_emittable.py --self-test
"""
import os, re, sys, glob

CLAUSE   = re.compile(r"^\s*-?\s*\*\*([A-Z][0-9]+[a-z]?)\b", re.M)
FAIL_STR = re.compile(r'fail\(\s*"([^"]+)"')
FAIL_TERN= re.compile(r'fail\(\s*[^,"]*\?\s*"([^"]+)"\s*:\s*"([^"]+)"')

def ids_in_spec(text):
    return set(CLAUSE.findall(text))

def ids_emittable(text):
    out = set()
    for m in FAIL_STR.finditer(text):
        for part in re.split(r"[/,]", m.group(1)):
            part = part.strip()
            if re.fullmatch(r"[A-Z][0-9]+[a-z]?", part):
                out.add(part)
    for m in FAIL_TERN.finditer(text):          # fail(cond ? "D5" : "D6", ...)
        for g in m.groups():
            if re.fullmatch(r"[A-Z][0-9]+[a-z]?", g.strip()):
                out.add(g.strip())
    return out

def analyse(task_dir):
    """-> (stated, emittable, unreportable) or None when it could not look."""
    spec = sorted(glob.glob(os.path.join(task_dir, "spec", "*_spec.md")))
    tb   = sorted(glob.glob(os.path.join(task_dir, "tb", "*_tb.sv")))
    if not spec or not tb:
        return None
    stated = set()
    for p in spec: stated |= ids_in_spec(open(p, encoding="utf-8").read())
    emit = set()
    for p in tb:   emit   |= ids_emittable(open(p, encoding="utf-8").read())
    if not stated:
        return None
    # X and L sections state what is NOT required and what is deliberately free.
    # They have nothing to emit by construction, so they are not candidates.
    excl = {c for c in stated if c[0] in "XL"}
    return stated, emit, sorted(stated - emit - excl)

def self_test():
    """Exercised, not assumed. An unfired branch reporting absence of a problem
       is the same defect this tool exists to find."""
    spec = ("- **D6 — precedence.** an error is due\n"
            "- **D7 — the code is preserved.** SLVERR stays SLVERR\n"
            "- **X1.** nothing is required while reset is low\n"
            "- **L2 — how long gating lasts.** free\n")
    tb_collapsed = 'if (a) fail("D5", "x"); else fail("D6", "y");'
    tb_split     = 'fail("D5","x"); fail("D6","y"); fail("D7","z");'
    tb_ternary   = 'fail(w == 0 ? "D6" : "D7", "y");'
    cases, bad = [], 0
    s = ids_in_spec(spec)
    cases.append(("D7 unreportable when D6's branch swallows it",
                  sorted(s - ids_emittable(tb_collapsed) - {"X1","L2"}) == ["D7"]))
    cases.append(("nothing unreportable once D7 has its own branch",
                  sorted(s - ids_emittable(tb_split) - {"X1","L2"}) == []))
    cases.append(("a ternary between two clause ids emits BOTH",
                  ids_emittable(tb_ternary) == {"D6", "D7"}))
    cases.append(("X and L are never candidates",
                  not ({"X1","L2"} & set(sorted(s - ids_emittable(tb_split) - {"X1","L2"})))))
    cases.append(("a task with no testbench is NO CONCLUSION, not clean",
                  analyse(os.path.join(os.sep, "nonexistent_task_dir")) is None))
    for name, ok in cases:
        print(f"  {'ok    ' if ok else 'FAILED'}  {name}")
        if not ok: bad += 1
    print(f"\n{len(cases)} case(s) exercised, {bad} failure(s)")
    return 1 if bad else 0

def main(argv):
    if "--self-test" in argv:
        return self_test()
    roots = [a for a in argv[1:] if not a.startswith("-")]
    if not roots:
        roots = sorted(glob.glob("domains/*/*/[dv]_*"))
    print("CANDIDATE LIST, NOT A VERDICT -- see the header. Calibrated once by")
    print("hand at 2 real of 5; the usual false positives are clauses addressed")
    print("to the TESTER and clauses checked under another clause's id.\n")
    print(f"{'task':<34} {'stated':>7} {'emittable':>10}  UNREPORTABLE (candidates)")
    tot = looked = 0
    noconc = []
    for d in roots:
        r = analyse(d)
        name = os.path.basename(d.rstrip("/"))
        if r is None:
            noconc.append(name); continue
        stated, emit, miss = r
        looked += 1; tot += len(miss)
        print(f"  {name:<32} {len(stated):>7} {len(emit):>10}  {', '.join(miss) if miss else '-'}")
    for name in noconc:
        print(f"  {name:<32}  NO CONCLUSION -- no spec/*_spec.md or no tb/*_tb.sv")
        print(f"  {'':<32}  was read. The scan did not look; it did not pass.")
    print(f"\n{looked} task(s) read, {tot} candidate(s). "
          f"{len(noconc)} NO CONCLUSION.")
    return 2 if noconc else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
