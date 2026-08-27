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

# THE DESIGN HALF, WHICH THIS SCAN COULD NOT SEE UNTIL NOW. analyse() globbed
# spec/*_spec.md only; 0 of 11 design tasks have one and all 11 have
# spec/*_iface.sv, so every design task returned NO CONCLUSION for the whole life
# of this file. It said so honestly -- "the scan did not look; it did not pass" --
# and that honesty is the only reason the gap was one command away rather than
# undiscoverable. Two agents cited this checker as a control in an argument
# without running it. Found by AGENT-DESIGN-43a92055.
#
# THREE CONVENTIONS DIFFER, NOT ONE, which is why this is not a wider glob:
#   stated:    markdown says **T5**;              an interface says `// T5.`
#   emittable: a verification tb calls fail("R1"); a design tb prints
#              $display("TEST_RESULT: FAIL: %s", why) with the id inside a STRING,
#              so any id appearing in any quoted string is emittable.
CLAUSE_SV = re.compile(r"^\s*//\s*([A-Z][0-9]+[a-z]?)\.", re.M)
_STRING   = re.compile(r'"([^"\n]*)"')
_IDTOK    = re.compile(r"\b([A-Z][0-9]+[a-z]?)\b")


def ids_in_spec_sv(text):
    return set(CLAUSE_SV.findall(text))


def ids_emittable_sv(text):
    """Any clause id appearing in a quoted string the testbench can print."""
    out = set()
    for lit in _STRING.findall(text):
        out |= set(_IDTOK.findall(lit))
    return out
FAIL_STR = re.compile(r'fail\(\s*"([^"]+)"')
FAIL_TERN= re.compile(r'fail\(\s*[^,"]*\?\s*"([^"]+)"\s*:\s*"([^"]+)"')

def ids_in_spec(text):
    return set(CLAUSE.findall(text))

def ids_emittable(text):
    out = set()
    # A COMPUTED CLAUSE ID. v_dsp02 selects the id in a case statement and passes
    # the VARIABLE to fail():
    #
    #     unique case (e.op)
    #       OP_SGNJ: cl = "S1";
    #       OP_CMP:  cl = "S7";
    #     endcase
    #     fail(cl, ...);
    #
    # Matching only fail("LITERAL" reported six clauses as unreportable that the
    # reference names on every run. Found by working the task I know LEAST well
    # second rather than last: its rate differed sharply from the first, and the
    # cause was this tool, not that task.
    for m in re.finditer(r"fail\(\s*([A-Za-z_]\w*)\s*,", text):
        var = m.group(1)
        # EVERY clause literal on the right-hand side of any assignment to that
        # variable. A first version matched `var = "S1";` and a single ternary,
        # and still missed S3/S4/S5 -- assigned by a NESTED ternary spanning two
        # lines. Enumerating the forms is the wrong shape; take the assignment
        # whole and pull the ids out of it.
        for a in re.finditer(r"\b%s\s*=\s*([^;]{0,300});" % re.escape(var), text, re.S):
            for lit in re.findall(r'"([A-Z][0-9]+[a-z]?)"', a.group(1)):
                out.add(lit)
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

# A clause may DECLARE where it is reported. "... and is reported under C4."
# is a claim, not a comment, and this verifies it: the named id must itself be
# emittable, or the clause has been annotated into a hole.
#
# WHY THE ANNOTATION EXISTS. The grouping family -- several clauses sharing one
# observation, one check and one reported id, so a submission testing any is
# credited with all -- is the dominant defect class in this corpus and is
# invisible to mutation, to conformant acceptance and to decontamination. Every
# remedy tried so far has been an instrument. This one is a sentence of prose,
# and it is cheaper than all of them.
#
# It records grouping honestly; it does not remove it. What changes is that the
# credit becomes VISIBLE -- to a submitter reading the spec, and to whoever reads
# a failure message -- instead of the grouping being discovered by someone
# noticing the wrong letter.
#
# WHAT IT DOES NOT DO, AND THIS SENTENCE USED TO SAY OTHERWISE. It said the credit
# becomes visible "so scoring can decide deliberately". Scoring cannot decide
# anything about clauses, because no clause id reaches a results record: the id
# exists at the fail() site, is printed into a log line, and is dropped there.
# score.py captures only ^TEST_RESULT: (PASS|FAIL), and I measured 841 run
# records with ZERO clause-shaped tokens in any verdict field. Reported by
# AGENT-VERIF-A2, who found their own scan of those records was VACUOUS -- it
# returned a clean answer about compound ids from a corpus that carries no ids at
# all -- and said so rather than reporting the clean answer.
#
# That is worse than an ordinary imprecision and it belongs to the citation family
# with the tense moved. A checker cited without being read is recoverable: the
# artefact exists and one command settles it. A CAPABILITY DESCRIBED BUT ABSENT
# has nothing to open. A future reader citing this sentence as evidence that
# scoring accounts for grouping would find no file to be wrong about.
#
# If clause ids are ever plumbed into the run record, change this paragraph.
#
# The form is deliberately one that reads as English, because a clause a human
# will not read is a clause that will not be kept true:
#     "... and is **reported under C4**."
FAILCALL = re.compile(r'fail\(\s*"([A-Z][0-9]+[a-z]?)"')
# THE SLASH FORM IS THE HOUSE CONVENTION AND IT USED TO TRUNCATE. This captured
# ONE id, so "REPORTED UNDER R3/R5" registered R3 and dropped R5 silently -- the
# truncation yields a well-formed declaration, so nothing looks wrong. Three in
# the corpus were half-read: d_ca01's R3/R5 and M1/M2, d_nw03's R3/C2. Found by
# AGENT-DESIGN-43a92055 while annotating.
#
# It matters because of what the column claims. "The id this clause names must be
# emittable" is satisfied by one id; "this grouping is real" is not -- with the
# second half dropped, an unemittable C2 would pass unnoticed. The corpus already
# expects pairs, and slashes are the only expressible form: two `reported under`
# markers in one clause block collide, because the dict is keyed by the enclosing
# clause and the last write wins.
DECLARED = re.compile(
    r"reported under\s*[`*]*([A-Z][0-9]+[a-z]?(?:\s*/\s*[A-Z][0-9]+[a-z]?)*)[`*]*", re.I)

def declarations(text, sv=False):
    """-> {clause id -> id it says reports it}. Keyed by the clause the marker
       sits inside, which is the clause block it belongs to.

    THE FOURTH CONVENTION. c2636d5 fixed the stated and emittable columns for
    design tasks and left this one markdown-only, so the block list came back
    empty on every _iface.sv, the loop body never ran, and this returned {}.
    Found by AGENT-VERIF-A2 against a live annotation: d_ca01's interface says
    "are reported under M2 alone" at line 223 and this reported nothing.

    THAT FAILURE HAS NO SENTINEL, which makes it worse than the one it followed.
    A task that could not be read returns NO CONCLUSION and says so. A task whose
    declarations could not be READ returns {} -- and {} is exactly what a task
    with no groupings returns. The honest-artefact luck that made the *_spec.md
    glob one command away does not hold here; nothing distinguishes "declared
    nothing" from "could not look".

    DECLARED itself needs no variant -- "reported under M2" matches the same in a
    comment as in markdown. Only the block boundaries are convention-bound.
    """
    out = {}
    blocks = []
    _blockre = CLAUSE_SV if sv else re.compile(r"^[-*]?\s*\*\*([A-Z][0-9]+[a-z]?)\b", re.M)
    for m in _blockre.finditer(text):
        blocks.append((m.start(), m.group(1)))
    blocks.append((len(text), None))
    for i, (pos, cid) in enumerate(blocks[:-1]):
        if cid is None:
            continue
        d = DECLARED.search(text[pos:blocks[i + 1][0]])
        if d:
            # Normalise the slash list; a marker naming only its own clause is
            # not a declaration that it is reported elsewhere.
            ids = [x.strip().upper() for x in d.group(1).split("/") if x.strip()]
            if ids and set(ids) != {cid.upper()}:
                out.setdefault(cid, "/".join(ids))
    return out


# ---- the SHARED-OBSERVATION population -------------------------------------
# The candidate list above cannot contain the founding instance of the grouping
# family. v_ca06's D6 and D7 were BOTH nameable -- both appeared in a fail() --
# and they shared one branch, so subtracting emittable from stated found
# nothing. The defect was that a submission checking precedence was credited
# with checking code preservation.
#
# What that looks like in source is several clause ids emitted from mutually
# exclusive branches of ONE observation:
#
#     if (s_rresp !== want_r) begin
#       if      (want_r == 2'b00)   fail("D5", ...);
#       else if (s_rresp == 2'b00)  fail("D6", ...);
#       else                        fail("D7", ...);
#     end
#
# So: scan for begin/end blocks and report every innermost block that emits two
# or more DISTINCT clause ids. That is a CANDIDATE LIST in the same sense as the
# rest of this tool -- a block emitting two ids may be two genuinely independent
# checks that happen to sit together, and a reader must look. What it cannot do
# is miss the shape, which subtracting sets can.
# THE UNIT IS AN if/else CHAIN, NOT A begin/end BLOCK, and the first version had
# it wrong. AGENT-DESIGN-43a92055 predicted the failure before running the tool:
# their testbenches are phase-structured, with checks batched in an end-of-run
# results block, and d_ca01's largest block emits nine distinct clause ids from
# one `begin` -- nine genuinely separate observations. Measured on a reduced
# form of exactly that structure:
#
#     results block  -> ['M1','M2','M3','R3','R5','R6']      <- pure noise
#     one condition  -> ['D5','D6','D7']                     <- the real thing
#
# Indistinguishable. A block is a scope; it is not an observation. What makes
# D5/D6/D7 one observation is that they are MUTUALLY EXCLUSIVE BRANCHES OF ONE
# CONDITION -- at most one can fire, so at most one clause is ever named for a
# single wrong value, and a submission checking any is credited with all. Six
# independent `if`s in a results block have the opposite property: each fires on
# its own evidence.
#
# So: find if/else chains and group the ids within one chain.
#
# ITS LIMIT, MEASURED NOT ASSUMED: branches wrapped in begin/end are not matched
# by this form. The corpus's instances are single-statement branches, which is
# what the shape looks like when written naturally, but a chain with begin/end
# branches will be MISSED rather than misreported. Missing is the right way for
# this to fail -- a candidate list that over-reports gets ignored, and this tool
# has already been ignored once for that reason.
CHAIN = re.compile(
    r"\bif\s*\([^;{]*?\)[^;]*?;"          # if (...) stmt;
    r"(?:\s*else\s+(?:if\s*\([^;{]*?\)\s*)?[^;]*?;)+",  # (else [if (...)] stmt;)+
    re.S)

# THE SECOND UNIT, AND ON MOST CORPORA IT IS THE PRIMARY ONE: THE CHECK MESSAGE.
# From AGENT-DESIGN-43a92055, who could not run the block version and answered the
# question a different way -- grep every check message for two or more clause ids.
# It finds a DIFFERENT population from the chain scan and neither subsumes the
# other:
#
#   message unit   one check that REPORTS FOR two clauses. The grouping is
#                  declared in the text and a human confirms it in one read.
#                  Found six genuine ones across four of their eight tasks, and
#                  correctly surfaced a seventh -- d_ai01's C2/C3 in a METRIC
#                  line, not a verdict -- which a reader discards immediately.
#
#   chain unit     several checks naming DIFFERENT single ids under one
#                  condition. v_ca06's D5/D6/D7 name one id each, so the message
#                  unit cannot see them; the founding case needs the branch scan.
#
# Their formulation of why the message is the better default is the one to keep:
# A BLOCK IS A SCOPING ACCIDENT; A MESSAGE IS ONE OBSERVATION REPORTING ONE
# VERDICT, which is precisely what the convention is about.
CLAUSE_TOK = re.compile(r"\b([A-Z][0-9]+[a-z]?)\b")
CHECKCALL = re.compile(r"\b(?:fail|chk)\s*\((.{0,400}?)\)\s*;", re.S)

def shared_messages(text):
    """-> [(reported ids, excerpt)] for checks whose call names >= 2 clause ids."""
    src = re.sub(r"//[^\n]*", "", text)
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    out, seen = [], set()
    for m in CHECKCALL.finditer(src):
        call = m.group(1)
        ids = sorted({i for i in CLAUSE_TOK.findall(call)
                      # a bare hex/width literal like 2'b10 is not a clause id
                      if not re.search(r"'[bhd]?\s*%s\b" % i, call)})
        if len(ids) >= 2 and tuple(ids) not in seen:
            seen.add(tuple(ids))
            txt = re.sub(r"\s+", " ", call)[:96]
            out.append((ids, txt))
    return out


def shared_messages_sv(text):
    """-> [(ids, excerpt)] for a DESIGN testbench, whose convention is different.

    A verification tb names the clause in the call: fail("R1", ...). A design tb
    prints $display("TEST_RESULT: FAIL: %s", why) and the id lives in the STRING
    assigned to `why`, so a shared observation is one string naming two or more
    clause ids. Measured: 6 of 10 design tasks have ZERO fail()/chk() sites, so
    CHECKCALL saw nothing in them at all.
    """
    src = re.sub(r"//[^\n]*", "", text)
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    out, seen = [], set()
    for lit in re.findall(r'"([^"\n]*)"', src):
        ids = sorted({i for i in CLAUSE_TOK.findall(lit)
                      if not re.search(r"'[bhd]?\s*%s\b" % i, lit)})
        if len(ids) >= 2 and tuple(ids) not in seen:
            seen.add(tuple(ids))
            out.append((ids, re.sub(r"\s+", " ", lit)[:96]))
    return out


def shared_convention(text):
    """Which reporting convention this testbench uses, or None if neither.

    WIDENING THE RANGE, WHICH IS THE ONLY REMEDY THAT WORKS HERE. AGENT-VERIF-A2
    put the general form better than I had it: an in-range failure value becomes
    recoverable only when the legitimate range has a value it never uses, and a
    COUNTING instrument has no such value -- every count is a real count, so
    saturation is the normal condition. analyse() escapes that only because it
    returns None on a task it could not read instead of an empty set. This does
    the same for the enumerator: a task whose convention is unreadable reports NO
    CONCLUSION rather than contributing 0 to a total that looks measured.
    """
    if re.search(r"\b(?:fail|chk)\s*\(", text):
        return "call"
    if re.search(r'\$display\s*\(\s*"[^"]*TEST_RESULT', text):
        return "display"
    return None


def shared_blocks(text):
    """-> [(0, sorted ids)] for if/else chains naming two or more clause ids."""
    src = re.sub(r"//[^\n]*", "", text)
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    out, seen = [], set()
    for m in CHAIN.finditer(src):
        ids = sorted({f.group(1) for f in FAILCALL.finditer(m.group(0))})
        if len(ids) >= 2 and tuple(ids) not in seen:
            seen.add(tuple(ids)); out.append((0, ids))
    return sorted(out, key=lambda r: (-len(r[1]), r[1]))


def analyse(task_dir):
    """-> (stated, emittable, unreportable) or None when it could not look."""
    spec = sorted(glob.glob(os.path.join(task_dir, "spec", "*_spec.md")))
    sv   = not spec and sorted(glob.glob(os.path.join(task_dir, "spec", "*_iface.sv")))
    if sv:
        spec = sv
    tb   = sorted(glob.glob(os.path.join(task_dir, "tb", "*_tb.sv")))
    if not spec or not tb:
        return None
    _stated_of = ids_in_spec_sv    if sv else ids_in_spec
    _emit_of   = ids_emittable_sv  if sv else ids_emittable
    stated = set()
    for p in spec: stated |= _stated_of(open(p, encoding="utf-8", errors="replace").read())
    emit = set()
    for p in tb:   emit   |= _emit_of(open(p, encoding="utf-8", errors="replace").read())
    if not stated:
        return None
    # X and L sections state what is NOT required and what is deliberately free.
    # They have nothing to emit by construction, so they are not candidates.
    # G IS EXCLUDED ON THE DESIGN HALF FOR THE SAME REASON X AND L ARE. G1-G5 are
    # the grading section -- "Correctness is a GATE, not a weighting", "WHAT IS
    # COMPARED", "WHAT IS NOT AVAILABLE TO OPTIMISE" -- they describe how a
    # submission is scored, not a requirement a testbench can fail. Listing them
    # as unreported would put five false candidates in every design task, and
    # annotating one with "reported under X" would be a false statement.
    excl = {c for c in stated if c[0] in ("XLG" if sv else "XL")}
    decl = {}
    for p in spec: decl.update(declarations(open(p, encoding="utf-8", errors="replace").read(), sv=bool(sv)))
    # A DECLARED clause is not a candidate -- its author has said where it is
    # reported -- but the declaration is CHECKED, not taken. Naming an id that
    # nothing can emit annotates the clause into a hole and is worse than
    # leaving it silent, because it reads as resolved.
    # EVERY id in a slash list must be emittable, not just the first. A grouping
    # is only verified if each clause it names can actually be reported.
    _parts = lambda u: [x for x in u.split("/") if x]
    bad = sorted(c for c, under in decl.items()
                 if any(x not in emit for x in _parts(under)))
    good = {c for c, under in decl.items()
            if all(x in emit for x in _parts(under))}
    return stated, emit, sorted(stated - emit - excl - good), decl, bad

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
    if "--shared" in argv:
        roots = [a for a in argv[1:] if not a.startswith("-")] or \
                sorted(glob.glob("domains/*/*/[dv]_*"))
        print("SHARED-OBSERVATION CANDIDATES -- clause ids named from MUTUALLY")
        print("EXCLUSIVE BRANCHES OF ONE CONDITION. At most one can fire, so at")
        print("most one clause is ever named for a single wrong value and a")
        print("submission checking any is credited with all.")
        print("Candidate list, not a verdict. Branches wrapped in begin/end are")
        print("MISSED, not misreported -- see the header for why that is the")
        print("right way for this to fail.\n")
        n = 0
        unreadable = []
        for d in roots:
            tbs = sorted(glob.glob(os.path.join(d, "tb", "*_tb.sv")))
            if not tbs:
                unreadable.append((os.path.basename(d.rstrip("/")), "no tb/*_tb.sv"))
                continue
            rows, msgs = [], []
            _seen_conv = set()
            for f in tbs:
                s = open(f, encoding="utf-8", errors="replace").read()
                conv = shared_convention(s)
                _seen_conv.add(conv)
                if conv == "call":
                    rows += shared_blocks(s); msgs += shared_messages(s)
                elif conv == "display":
                    msgs += shared_messages_sv(s)
            if _seen_conv == {None}:
                unreadable.append((os.path.basename(d.rstrip("/")),
                                   "no fail()/chk() and no $display TEST_RESULT"))
                continue
            if rows or msgs:
                print("  " + os.path.basename(d.rstrip("/")))
                for ids, txt in msgs:
                    print("      msg   %-16s %s" % (" + ".join(ids), txt))
                    n += 1
                for depth, ids in rows:
                    print("      chain %s" % " + ".join(ids))
                    n += 1
        for name, why in unreadable:
            print("  %-32s  NO CONCLUSION -- %s." % (name, why))
            print("  %-32s  The scan did not look; it did not find zero." % "")
        print("\n%d shared observation(s), %d NO CONCLUSION." % (n, len(unreadable)))
        return 2 if unreadable else 0
    roots = [a for a in argv[1:] if not a.startswith("-")]
    if not roots:
        roots = sorted(glob.glob("domains/*/*/[dv]_*"))
    print("CANDIDATE LIST, NOT A VERDICT -- see the header. Calibrated once by")
    print("hand at 2 real of 5; the usual false positives are clauses addressed")
    print("to the TESTER and clauses checked under another clause's id.\n")
    print(f"{'task':<34} {'stated':>7} {'emittable':>10}  UNREPORTABLE (candidates)")
    tot = looked = 0
    noconc = []
    broken = []
    for d in roots:
        r = analyse(d)
        name = os.path.basename(d.rstrip("/"))
        if r is None:
            noconc.append(name); continue
        stated, emit, miss, decl, bad = r
        looked += 1; tot += len(miss)
        print(f"  {name:<32} {len(stated):>7} {len(emit):>10}  {', '.join(miss) if miss else '-'}")
        if decl:
            print(f"  {'':<32} {'':>7} {'declared:':>10}  "
                  + ", ".join(f"{c}->{u}" for c, u in sorted(decl.items())))
        for c in bad:
            broken.append((name, c, decl[c]))
    for name in noconc:
        print(f"  {name:<32}  NO CONCLUSION -- no spec/*_spec.md, no spec/*_iface.sv,")
        print(f"  {'':<32}  or no tb/*_tb.sv")
        print(f"  {'':<32}  was read. The scan did not look; it did not pass.")
    print(f"\n{looked} task(s) read, {tot} candidate(s). "
          f"{len(noconc)} NO CONCLUSION.")
    # THE CANDIDATE COLUMN IS NOT A WORK LIST, AND SAYING SO IS PART OF THE
    # OUTPUT RATHER THAN A CAVEAT SOMEBODY REMEMBERS. AGENT-VERIF-A2 hand-worked
    # 44 of them and found 20 false positives -- 45%, and 89% on one task. A
    # clause can appear here because it is genuinely unreportable, or because it
    # is reported under another clause, or because it is not a check at all.
    # A regex cannot tell those apart.
    #
    # The DECLARATION column below is the exact one: "reported under X" either
    # names an id something can emit or it does not, and that is decidable. When
    # this scan is cited as a control, it is that column that is the control.
    print("  The candidate column is OVER-BROAD -- measured 45% false positives "
          "on a hand-worked\n  sample. It is not a work list. The REFUSED lines "
          "below are the exact result.")
    # AND IT IS ALSO NARROW, IN A WAY THAT MUST NOT BE "FIXED" BY TIGHTENING
    # emittable. A clause named only inside a compound string -- d_ca01's R5
    # appears solely in "R3/R5: a LOAD returned the wrong value", never alone --
    # counts as emittable, and that is CORRECT: it is reported, jointly. Ten such
    # ids exist corpus-wide, seven on the design half, found by
    # AGENT-DESIGN-43a92055 and AGENT-VERIF-A2.
    #
    # Dropping compound substrings from emittable would move all ten into the
    # candidate column, which asserts "stated and cannot be reported at all" --
    # false for every one of them. The real property, that their failure is not
    # separately ATTRIBUTABLE, is what --shared reports, and it reports all ten.
    # That is the division this tool was built on: the note above about v_ca06's
    # D6/D7 says the candidate column cannot contain a grouping by construction.
    print("  Read it WITH --shared. A clause named only inside a compound "
          "(\"R3/R5: ...\") is\n  emittable and correctly so; that its failure is "
          "not separately attributable is\n  what --shared reports, not this column.")
    for name, c, under in broken:
        print(f"REFUSED: {name}: {c} says it is reported under {under}, and no "
              f"fail() can emit {under}.")
        print("  A clause annotated into a hole is worse than one left silent:")
        print("  it reads as resolved.")
    return 2 if (noconc or broken) else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
