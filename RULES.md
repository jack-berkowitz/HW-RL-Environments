# Standing rules

**Revision 4 — 2026-08-15.** *Rev 1: rules 1–7 from the d_nw01 audits. Rev 2:
8–11 from the pipeline and oracle work. Rev 3: 12–13, and rule 10 restored after
being dropped in a consolidation edit. Rev 4: 15, plus bidirectional
rule/finding citations and the linkage check that enforces them.*

**THIS FILE IS THE ONLY PLACE THE RULES LIVE.** `BUILD_PROMPT_DESIGN.md`,
`BUILD_PROMPT_VERIFICATION.md` and `CONVENTIONS.md` reference it and must never
restate it.

That is rule 13, and it exists because the rules had been duplicated across three
documents: a retraction recorded in `FINDINGS.md` stayed live in a build prompt
and would have propagated a withdrawn heuristic into the next task looking like
current guidance, and the rule count drifted to 7 in one place against 10 in
another. **If two copies can disagree, eventually they will.**

Each rule exists because its absence produced a wrong result that survived
review. **Every rule cites the finding that produced it, and every such finding
cites its rule.** `scripts/check_rule_linkage.py` asserts that graph is complete,
so a dropped rule or an orphaned finding is detectable without anyone
remembering to look — which is the only automatable control we have for contract
defects. It runs with the regression.

---

1. **Every capability the design must support is a named parameter with a
   binding check.** Audit by probe, not by reading: write an otherwise-correct
   implementation that ignores exactly one parameter and confirm the checker
   fails it. A parameter no check enforces will be ignored, and the design that
   ignores it will pass.

    **From:** F1, F2, F3, F4, F5

2. **Every stated requirement has a coverage floor proving it was exercised.** A
   requirement written in prose that no test creates the condition for is
   decorative.

    **From:** F6, F7

3. **Every check gets a negative control that fails THAT check and nothing
   else**, and it only counts if the harness can saturate what the check
   measures. A control that trips two checks validates neither; a
   throughput-shaped check whose bottleneck is the harness measures the harness.

    **From:** F9, F10, F11, F12

4. **Coverage floors measure STIMULUS, not design behaviour.** The test: *could
   a correct implementation score zero here?* If yes, the floor is gating a
   design choice and must become a `METRIC:` line instead.

    **From:** F13

5. **Second source is mandatory** — an independent implementation making
   different free choices. Name three specific differences or it is a paraphrase.

   **When it fails a check, disambiguate before changing anything:**
   1. run the failing input through the **anchor**;
   2. second source disagrees with the anchor → **the second source is wrong**;
   3. second source agrees and the check still fails → **the check is
      over-constrained**.

   The wrong branch loosens a check to accommodate a bug, and a loosened check is
   invisible afterwards.

    **DIFFERENCES MAY BE MEASURED OR INSPECTION-VERIFIABLE.** At least TWO must
    be measured -- a number from a run, not from a reading. An
    inspection-verifiable difference must name the specific FILE AND CONSTRUCT,
    so a reader checks it in one lookup instead of taking it on trust.

    **They must be INDEPENDENT.** A measurement that is a consequence of another
    difference restates it and does not count twice. On `d_dsp02` the second
    source's ASSIGNW/FUNC counts (137/26 against 30/16) look like a third
    difference and are not: they compare a shim plus a vendored closure against a
    monolith, which is the closure difference in another unit. Counting a
    consequence twice is how three is reached dishonestly.

    **Why the relaxation.** A second source that reaches identical results by a
    different route is BEHAVIOURALLY INVISIBLE -- that is the success condition,
    not a measurement failure. The only instruments that see architectural
    difference are area and timing, which means synthesis, which is contended by
    PPA queues. A rule satisfiable only through a contended resource gets
    satisfied by declaration instead, and three asserted differences read the
    same in the record as three measured ones while meaning nothing. An honest
    two beats a decorative three. Where an instrument was unavailable, say which
    and why, and upgrade the record if it frees up.

    **From:** F11

6. **No metric may be quoted from a run that failed its own gate.** A build that
   misses timing still produces area and power numbers. They are real numbers and
   they are not results.

    **From:** AD elasticity table built from non-closing runs

7. **Closure status comes from `find_fmax`'s own classification**, never from
   grepping an intermediate log. And **if the bracket is wider than the requested
   resolution, there is no Fmax to report** — only an interval.

    **From:** P3, P5

8. **Every run writes an immutable record; collection reads only those records**,
   never a live tool directory. A missing row is honest; a stale row is not.

   **And every control is enforced at the TOOL boundary, not in a driver that
   calls it.** A control living in a wrapper applies only to people who use that
   wrapper; anyone invoking the underlying tool directly bypasses it silently,
   and nothing reports that it was bypassed.

   This is the generalisation F20 should have made and did not. F20 concluded
   that *"a rule enforced by a tool nobody is obliged to use is a convention,
   not a control"* — and then the very next control was built in
   `run_submissions.sh` rather than in `ppa_candidate.sh`, and was bypassed
   within the week by calling the tool directly. **The lesson did not generalise
   because it was recorded about one tool instead of about tool boundaries.**

   Test to apply: *can this control be skipped by calling something one level
   down?* If yes it is a convention, whatever the document says.

    **From:** P4, F20, F27

9. **Area and power are reported at one common binding period**, and every area
   comparison splits three ways: off-spec configuration, capability gap, genuine
   optimisation. A headline ratio without that split is not a result. Composite
   metrics (area × delay) are not scoring axes and are only meaningful where area
   is elastic under constraint — which must be tested per design, not assumed.

   **Amended.** This rule used to require reporting "at own Fmax and at a common
   binding period". The own-Fmax half never followed from F8, which is entirely
   about decomposing an area ratio, and as of 91c63bb it contradicts every design
   specification: the pinned period is derived from one reference sweep, stated
   before solicitation, and submissions are not swept at all. A per-design Fmax
   cannot be reported beside area and power in any case, because those come from
   a build at the pinned period and an Fmax comes from a different build at a
   different one. Dropping the clause leaves the rule saying what F8 actually
   established.

    **From:** F8

10. **The runner names its artifacts explicitly and refuses when they are absent;
    it never discovers them by pattern.** Globbing, sorting and silent defaults
    turn a missing artifact into a *different run* rather than an error.

    **From:** P1, P2, F16

11. **The oracle must be an artefact nobody on this project wrote. Locally
    authored code generates INPUTS, never expected values.** A local model
    producing expected values and merely cross-checked against the anchor leaves
    a shared misconception surviving the cross-check — both sides agreeing for
    the same wrong reason. Invert it: generate inputs locally, run them through
    the anchor, take the anchor's output as expected. A local bug then costs
    *coverage* and can never produce a wrong expected value.

    **Consequence: coverage floors carry the whole weight.** Expected values are
    safe by construction; input coverage is not.

    **From:** d_dsp02 hand-computed IEEE case

12. **Standards latitude must be named.** Where a task is anchored on a standard
    that permits alternatives, every alternative the anchor forecloses is named
    in the spec as out of scope. Otherwise the vectors silently encode the
    anchor's choice and a conformant design fails a requirement nobody wrote
    down.

    **Audit the artefact, not the prose.** On `d_dsp02` the spec already said
    "tininess after rounding" and that still would not have caught it — the
    inherited choice was found by counting flag combinations across 4290 captured
    vectors.

    **From:** F14

13. **Single source of truth for the rules.** They live here and nowhere else.
    Any retraction or addition happens in this file, and every other document
    references it.

    **From:** F15, F16

14. **When blocked, the deliverable is the report.** Stop and say so.

    **From:** working principle, no originating defect


15. **Every contract term cites its source of authority** — a standard clause,
    a stated task intent, or a design decision recorded as such. **"Because the
    anchor does it" is not an authority.**

    This turns F14's class into something checkable *at write time* rather than
    discoverable by audit: either you can produce a citation, or you are making a
    decision and should make it consciously. It also answers the question a
    reviewer will eventually ask — *how do you know your specs describe a
    contract and not an implementation?*

    Worked example, `d_dsp02` A4: the canonical-NaN requirement cites RISC-V,
    notes that IEEE-754 only *recommends* payload propagation, and states that
    the alternative is out of scope. Before that pass it cited nothing and was
    simply what cvfpu happened to do.

    **From:** F14

16. **A control that fails everything validates nothing.** A negative control
    must pass some checks and fail exactly the one it targets. One that trips
    every check cannot distinguish a working apparatus from one that reports
    whatever the input says.

    **From:** F25

17. **Any two PPA numbers compared must have matching build configuration,
    asserted mechanically rather than assumed.** Records carry a hash of the
    **resolved** build configuration — ABC target, SDC, PDK, utilisation,
    placement density, parameters, every variable that reaches the flow. A
    comparison refuses when the hashes differ **except on the axis being
    varied, and that axis is named explicitly.**

    **Provenance tells you where a number came from, not whether two numbers may
    be subtracted.** This is the class neither provenance nor gate-passing can
    catch: in F24 every number had a record, every record was accurate, every run
    passed its gate and was DRC clean, and the two builds still were not
    comparable — one mapped with ABC unconstrained because a hardcoded `awk`
    found no `clk_period` in a two-clock SDC.

    It closes two defects at once. F24's silently empty ABC target, and the
    provenance audit's own error of comparing a 2.625 ns run against a 4.5 ns
    run as though they were the same measurement — **the audit committing the
    mistake it was written about.**

    **From:** F20, F24

18. **Every task has exactly one SCORED CONFIGURATION, named in the spec.** PPA,
    latency and throughput are measured only there. **Free an axis only when the
    choice on that axis is itself the measurement; otherwise pin it.**

    **This is a change to the spec and to what is measured, not to what the
    checker checks.** The two must not be collapsed:

    - **Correctness sweeps stay multi-configuration.** `MAX_TRANS` at 2 and 8,
      `DATA_W` at 8/32/64, and the rest remain exactly as they are. A design
      must work across the legal parameter space.
    - **PPA, latency and throughput are measured at one configuration only.**
    - **The checker still checks only what correctness requires.** The scored
      configuration is a stated *spec* requirement, so a submission built
      elsewhere fails something it was told rather than a hidden assumption.

    **Why the previous guidance had to change.** "Pin only what the checker
    checks, leave the rest free" was the right correction to over-constraint,
    and it was optimised for correctness scoring. It made PPA scoring
    intractable: a freed axis buys design-space freedom and pays for it with a
    baseline *curve*, a sampling decision, and an axis-naming step on every
    comparison — forever, on every task. Rule 18 resolves the tension by
    separating the two concerns rather than trading one off against the other.

    **Choosing it, in order:** representative of real use; exercises the
    interesting part of the design space; closes timing with margin at a period
    both the anchor and a plausible alternative can hit; **not the anchor's
    default merely because it is the default.** Record the rationale in the spec
    beside the pinned value, with its authority (rule 15).

    A consequence worth stating: **pinning an axis retires any conformant
    perturbation whose licence was that axis being free.** Re-derive the
    conformant set against the new spec — every perturbation's licence clause
    must still exist.

    **AMENDMENT (F49): engineering merit does not establish discrimination.**
    The criteria above choose a point that is representative and buildable. They
    say nothing about whether the capability checks can still tell anything apart
    there, and a capability parameter's LOW setting is where a defective design
    most easily satisfies the requirement — so a pass there is not capability
    evidence. **Check the chosen point against the capability checks, and where
    it is blind, either move it or record that those checks carry no evidence at
    the scored configuration.** `d_ca04` scores at `SYNC_STAGES=2`, which F3
    measured as the setting where its probe reads identically to a correct
    design; the measurement lives in `FINDINGS.md`, the choice lives in a
    `task.yaml`, and nothing joined them.

    **From:** F24, F18, F49

19. **A build failure scores ZERO on every PPA axis, and is labelled as a build
    failure.** Not "no data", not omitted, not deferred, not blank.

    Zero is the honest score: a design that does not build cannot be operated,
    so its area, power and frequency are not unknown — they are unavailable to
    any user of the design. Omitting the row instead lets a non-building
    submission quietly disappear from a comparison it should be losing.

    **But it must be visibly distinct from a design that built and scored
    badly**, in the record and in every table. Those are different results about
    the model and collapsing them destroys the distinction: one produced RTL
    that synthesises and is merely worse, the other produced RTL that is not
    RTL. The annotation carries the frontend and the actual error.

    Worked example: `d_nw01/gemini.sv` scores zero, annotated *build fail
    (slang/Verilator, anonymous struct as parameter value — confirmed genuine,
    7 errors)*.

    **Agreement between frontends is SUFFICIENT evidence, not necessary.**
    `d_ca04/kimi.sv` is rejected by slang for using an identifier before its
    declaration and accepted by Verilator with zero errors. That is Verilator
    being permissive, not the code being legal — and ORFS synthesises with
    slang, so the design cannot be built regardless. Reading "one frontend
    accepts it" as "not a real failure" inverts the test.

    **From:** F27

20. **No reported value may be produced by a fallback, a default, or a merge
    across configurations.** A value that was not measured for *that specific
    design* at *that specific pinned configuration* renders as **absent**, and
    absent renders as absent.

    Five instances. The first four are in the reporting path; the fifth is in
    MEASUREMENT, and this list once said there were none there:

    | | what it invented |
    |---|---|
    | Fmax fallback | printed the **reference's** 380.9 MHz on candidate rows never swept |
    | metric merge | `dict.update` across 18 configs, so each row showed whichever config was written last |
    | F28 name drop | structured metrics filed under bare `min`/`max`/`n`, overwritable by any other metric |
    | absent crossing latency | read ABSENT for a metric emitted on every one of 18 configs |
    | **F56 verdict default** | a verdict the harness failed to READ was classified **FAIL** |

    **The measurements were right every time.** What produced a wrong number was
    a reporting path that preferred a plausible value to no value. A fallback is
    the most dangerous form: it is written to be helpful, it fires exactly when
    data is missing, and its output is indistinguishable from a real
    measurement.

    Absent is never the unhelpful answer. A blank cell prompts someone to go and
    measure; a borrowed number does not.

    **This rule binds at the point of MEASUREMENT, not only at rendering.**
    That was not obvious and the omission cost a batch: `else verdict=FAIL` is a
    default, and it was not read as one because it lived in a runner rather
    than a renderer. A default in a renderer is recoverable -- re-run the
    renderer against the record. A default in measurement is not: the record
    then contains the invented value, and every downstream check confirms it
    faithfully. **A crashed, killed, or timed-out run has no verdict, and no
    verdict is never a failing verdict.**

    **Failing to OBTAIN a value is not a value.** F56's default fired not
    because a run produced no verdict but because a `pipefail` pipeline threw
    away `grep`'s success and returned SIGPIPE instead. The `else` branch could
    not tell "the answer is no" from "I could not read the answer", so it
    published the first as though it were the second -- a well-formed,
    plausible, fabricated result. Any branch that assigns a verdict on the
    failure path of a READ is this defect.

    **From:** F28, F29, F56

21. **Every mutant carries recorded evidence of non-equivalence, and the TYPE is
    recorded per mutant.** Two accepted values:

    - **`witness`** — a named clause fails at a named configuration under a
      named stimulus. Non-equivalence demonstrated *under that stimulus*.
    - **`bmc_cex`** — a bounded counterexample: a concrete input sequence on
      which mutant and reference differ from an **identical initial state**. A
      proof of non-equivalence.

    **`witness` is a FULL-STANDING evidence type and no existing task requires
    re-validation.** The requirement is that the type is *recorded*, not that it
    is `bmc_cex`. `d_dsp02`'s six mutants carry `witness: "vector N"` and are
    compliant as they stand. What the rule forbids is leaving the type
    unrecorded, so a reader cannot tell which claim a kill count rests on.

    **The kill rate is not evidence and never implies the type.** A mutant every
    checker kills may still be equivalent on the axis the checker measures; a
    mutant nothing kills may be profoundly non-equivalent and merely
    unexercised. A table carrying one must not be read as carrying the other.

    **A mutant that can obtain neither is CUT from the set, and the cut is
    recorded** with its reason. A mutant of unknown status inflates the
    denominator of every kill rate computed from the set.

    **Depth is per mutant, and it is the depth at which the counterexample was
    FOUND.** It is not a statement about how far the miter has been shown sound.
    Where a control establishes soundness to a different depth, that figure is
    recorded separately and the two are never combined into one number.
    `d_ca01`'s bounds are depth 34 for `m01`, `m02`, `mCAP1` and the control, and
    depth 14 for `m03`–`m05` — a per-mutant column, not one value per task.

    **Every BMC invocation carries a wall-clock cap, and the cap lives in the
    `.sby` file rather than in a wrapper.** A cap that exists only in the command
    someone typed is a convention, not a control. Exceeding it is recorded as
    **timeout at the attempted depth** — never as a passing result and never as a
    failing one. **A timed-out control is a measured bound, not an absence of
    evidence.**

    **A timeout on the control does not invalidate the counterexamples.** A
    counterexample is self-certifying: a concrete input sequence, checkable in
    isolation. A control that cannot prove the absence of a counterexample to
    some depth states a limit on what has been ruled out; it is not a red result
    and must not be read as one.

    Current cap **900 s**, justified by measurement rather than guessed: every
    counterexample on `d_ca01` landed in under 25 s, so 900 s is 36× the slowest
    real result and cannot clip a run that was going to succeed, while the
    gold-vs-gold control that failed to finish in 600 s trips it immediately. A
    future task whose counterexamples run genuinely long raises the cap **with
    the measurement that justifies it recorded**, as with any threshold here.

    **Provenance, stated because it differs from every other rule in this file.**
    This one was not extracted from a defect that survived review. It was written
    on the merits from what `d_ca01` measured — that a formal flow can be present
    and unrunnable, that an unconstrained miter proves a design non-equivalent to
    itself, and that "non-equivalent under this stimulus" is the exact claim the
    diff-rate retraction refused. It is not carried over from a prior agreed
    decision.

    **From:** F47, F49

22. **No PPA figure is reported from a build that did not meet timing.** Area
    and power from a design that fails its timing constraint describe a circuit
    that cannot run at the clock it was built at. The number is real; the
    operating point is imaginary.

    **The record stays; the report withholds.** Records are immutable and a
    failing build is a legitimate thing to have measured -- it is how a design's
    Fmax gets bracketed at all. What is forbidden is a table quoting it as
    though it were an achievable operating point. Slack is the gate, and it is
    applied where the number is RENDERED, not where it is recorded.

    **This is not a hypothetical.** Two published figures were exactly this:
    `d_nw01/chat` at 2,141,894 um2 with -3.03 ns of slack, and
    `d_dsp02/chat` at 440,336 um2 with -0.697 ns. Both were compared against a
    reference that DID close, and both ratios were quoted. The second survived a
    provenance audit that checked every number against its record and found no
    discrepancy -- because there was none. **The record was accurate about a
    build that was invalid**, which is precisely the failure a provenance check
    cannot see.

    **Absent slack is not a failure.** A record with no `wns_ns`, or an
    unparseable one, renders normally. Treating missing data as a negative
    verdict would invent a result, which is the opposite error and equally bad.

    **Both renderers enforce it independently.** `report_table.py` and
    `collect_results.py` each apply the gate. That duplication is deliberate: a
    control applied by only one of two readers is bypassed by using the other,
    and rule 8's test -- *can this be skipped by calling something one level
    down?* -- is answered by putting it in both.

    **From:** F51

23. **A verification submission is scored only if it is SHOWN to discriminate.**
    Every submission runs against the golden DUT and against a mechanically
    generated **gate mutant**, and must return DIFFERENT verdicts: PASS on the
    golden, FAIL on the mutant. The same verdict on both means it did not tell
    a correct DUT from a broken one, and it is **INVALID** -- which is not a low
    score, and which suppresses the kill rate rather than reporting it.

    **The gate must have no source-level counterfeit.** A structural condition
    -- "instantiates the DUT", "contains an assertion" -- is satisfied by
    writing the line that satisfies it. `atop_filter dut ();` instantiates the
    DUT and tests nothing. Only a required difference in OUTCOME cannot be
    faked: to produce two verdicts you must observe something that differs.

    **A DIFFERENCE, not a failure.** "Must fail the mutant" would accept a
    testbench that reports FAIL unconditionally. Both constant functions --
    always-PASS and always-FAIL -- are non-discriminating, and both are INVALID.

    **The mutant is generated, never authored.** `scripts/make_gate_mutant.py`
    copies the golden's module header verbatim and ties every output to `'1`.
    Verbatim because a reconstructed interface drifts and then every submission
    fails for the wrong reason; `'1` because it makes data outputs wrong while
    leaving handshakes ASSERTED, so submissions report a mismatch instead of
    hanging, and a hang diagnoses nothing.

    **It is not a scored mutant** and never enters a kill rate, in either
    position. It is identified by the explicit identifier `__gate_mutant__`,
    never by position or path. It is also **not** the Tier-B step 5b authoring
    control, which is a separate artifact and may legitimately be subtle. The
    gate is a floor: it is deliberately obvious, because a subtle gate produces
    false INVALIDs on narrow-but-legitimate work, which is the expensive
    direction.

    **A gate that cannot build is a refusal, not a verdict.** If the generated
    mutant fails to elaborate, every submission fails it identically -- and a
    null testbench would then show PASS-golden/FAIL-mutant and satisfy the gate
    it was meant to fail. Elaboration is therefore checked BEFORE anything is
    scored, and a failure exits 2 with nothing scored and no record written.
    Blaming a submission for a harness defect is its own error.

    **Enforced in the RECORD, not in the renderers.** When a submission does
    not discriminate, `sim_verification.sh` writes
    `faults_caught=SUPPRESSED-gate-failed` -- there is no number in the record
    for a renderer to print. Rule 22 needed the gate duplicated across
    `report_table.py` and `collect_results.py` because slack is a legitimate
    recorded field that the report must decline to quote. Here the value never
    exists, which answers rule 8's test -- *can this be skipped by calling
    something one level down?* -- more completely than duplication can: there
    is no level down that has the number.

    **From:** F55


24. **Any apparatus used to produce a number must first reproduce known-good
    reference output, and that reproduction must be RECORDED alongside the
    numbers it licenses.** A number read off an apparatus that has not
    reproduced a known answer is not a measurement. It is a number.

    **Scope is MEASUREMENT APPARATUS**, not testbenches specifically: simulation
    probes and capture rigs, checkers and coverage floors, and ad-hoc
    measurement scripts. The last is not padding — it is where this was actually
    needed. A shell loop reusing one `--Mdir` across the artifacts it measured
    re-ran the previous binary whenever a build failed, and reported a capability
    mutant killing **6** vectors where the true number is **907**. A rule scoped
    to "probes" would not have covered it.

    **Both halves are load-bearing.** Reproducing a known answer is a habit that
    decays invisibly — nothing about a run says whether the operator checked
    first. Recording the reproduction next to the numbers is what makes the check
    auditable by someone who was not there:

        COUNTER VALIDATION: the reference must score 0 before any number below
        is read.  reference -> 0 kills on the pre-band 4290

    **It generalises rule 2's absence case from checkers to instruments.** A
    check that cannot fail proves nothing when it passes; an apparatus that has
    not reproduced a known answer proves nothing when it reports one. The same
    idea from opposite ends.

    **WHAT IT DOES NOT CLAIM.** Reproduction is necessary and NOT sufficient. A
    control that reproduces correctly inside its target region can still be wrong
    outside it: `nc_d_band_unbounded_tininess` matched the reference on every
    band vector and killed 20 vectors on a set with zero band coverage. That is
    rule 4's and F59's defect — a measurement quoted beyond the region it
    covers — and this rule does not reach it. Read as a guarantee of correctness
    it is a false one; it guarantees only that the instrument was pointed at a
    known answer before it was believed.

    **NO ENFORCEMENT SCRIPT, AND THAT IS A DECISION.** One was designed and
    deliberately not built. It can gate PRESENCE -- numbers with no reproduction
    marker beside them, or a marker whose expected and actual disagree -- but it
    cannot gate CORRESPONDENCE: that the apparatus which reproduced the known
    answer is the same apparatus, in the same configuration, that produced the
    number. **All of this session's instances would have passed it.** The
    `--Mdir` loop genuinely reproduced the reference at 0 kills, and then a later
    iteration silently ran a different binary; a truthful marker from the first
    iteration sits beside a number from the fifth.

    Closing that gap requires rigs to emit the marker and the number FROM ONE
    INVOCATION with a build identity in both. That is a reporting change, not a
    check, and engineering a script around the limit would produce a gate that
    reads as load-bearing and is not.

    **Revisit when several rigs emit markers natively** -- at that point a script
    enforces a convention that exists rather than inventing one.

    **AN AD-HOC QUERY USED AS EVIDENCE IS APPARATUS.** The scope above names
    ad-hoc measurement scripts; it reaches further down than "script". A single
    command line, a glob, a one-liner counter — if a number or a status will be
    read off it and believed, it is an instrument and it must reproduce a
    known-good answer before its output is read. Four instances in one session,
    none of which announced itself: a git pathspec glob that returned a false
    empty and read as a clean working tree; a zsh glob abort that reported every
    design task as having no spec; an awk counter that returned zero
    configurations for a task with two; and a string replacement that changed no
    bytes and printed success, found while writing the finding itself.

    **Silent zero and silent empty are the shapes to distrust.** `0`, empty
    output and "no matches" are the same tokens a correct run produces when the
    answer genuinely is nothing, so they never present as failures. A wrong
    non-zero number gets questioned; a wrong zero gets believed. After an
    in-place edit specifically, grep for the text you believe you wrote, with a
    fixed-string match, and ASSERT rather than print — a "recorded" claim that
    recorded nothing defeats the recording half of this rule directly.

    **From:** F60, F64

25. **Every capability a module has is either priced by an existing axis or
    bounded in the specification.** Before a design task is published, enumerate
    what the module can DO -- how much it holds, how many things it tracks, how
    long it may take, how much it may spend -- and for each, ask whether latency,
    area or power already charges for it. Anything that does not fall out of
    those axes needs a stated bound.

    **AND A BOUND NOBODY CHECKS IS NOT A BOUND.** Stating the ceiling is half
    the work; the other half is a control that violates it and must fail.
    `d_nw03`'s B1 caps output buffering at two frames and calls more
    non-conforming — a clause written in direct response to F62 — and a design
    holding four times that passes every check at both configurations with zero
    per-step failures. The lesson was learned in the right place and stopped one
    step short of enforcement, because a clause with a clear rationale reads as
    settled.

    **Build the control on whichever side the specification bounds.** Every
    capability control in this repository tests UNDER-provisioning, so a family
    of them is structurally blind to a design that provides too much. Floor,
    build one that undershoots; ceiling, one that overshoots; both, build both.

    **An unpriced axis makes a submission unfalsifiable and the comparison
    meaningless.** `d_nw01` required outstanding capacity, ordering and liveness,
    and said nothing about how much data the crossbar might buffer to deliver
    them. A submission buffered a full 256-beat burst per master, 20,480 bits of
    flip-flops, and was correct on every axis the task checked while measuring
    14.2x the reference's area. It was a conforming answer to an incomplete
    specification, and the PPA gap was measuring the specification.

    **Bound it in the spec, do not add a metric for it.** A capability metric
    credits the spending, which then demands an exchange rate -- how much area is
    a buffered beat worth -- and rule 22's refusal to weight area against
    frequency applies with equal force here. A bound costs one normative clause
    and no columns; a metric costs a column on every table and an answer nobody
    has.

    **Say which resource is bounded.** Tracking a transaction costs a counter;
    holding its data costs storage. `d_nw01`'s C3 bounds beats held, not
    transactions tracked, and says so, because a design that confuses them
    either over-builds or fails a capacity floor it could have met cheaply.

    **A ceiling is as normative as a floor.** `MAX_BURST_LEN` was already written
    this way -- nothing above it is ever driven, so provisioning beyond it is
    wasted area rather than insurance. Buffering simply never received the same
    sentence.

    **AND THE SAME DEFECT WITH THE SIGN FLIPPED: A PARAMETER FREE ON THE COST
    SIDE MUST BE SCORED ON THE BENEFIT SIDE, OR BOUNDED.** `d_nw01` shows an
    unpriced axis letting a submission OVER-provision. The mirror case lets it
    UNDER-provision, and it reads as generosity rather than as a hole: `d_ca03`
    drafted TLB capacity, associativity and second-level sizing as
    "microarchitectural freedom". But correctness there never depends on the TLB
    — the page-table walk resolves every miss — and latency is unscored, so the
    dominant strategy is ZERO ENTRIES, direct-mapped, no second level. Fully
    conforming, smallest area, and the column then ranks submissions by who read
    the clause rather than by design quality.

    **The test to apply before publishing.** For each free parameter, name the
    axis that CHARGES for spending on it and the axis that CREDITS the benefit.
    If the crediting axis does not exist, the parameter has a degenerate optimum
    at one end and must be pinned. Structures where this bites: TLBs, branch
    predictors, prefetchers, victim buffers, store merge buffers, way predictors,
    MSHR counts — anything whose benefit is hit rate or latency.

    **PREFER SCORING THE CREDITING AXIS TO PINNING THE COST SIDE.** Pinning
    removes a design choice; scoring keeps it. Where a task already has a fixed
    probe sequence and a harness that controls response timing, total cycles over
    that sequence is a deterministic second axis costing no new apparatus --
    `d_ca03` needed no address trace, no working-set definition and no memory
    model. Adding it converted three dominant strategies back into trades: a
    swept comparator costs ~16 cycles per TLB hit, one PMP comparator ~8 per
    check, a per-entry flush clear 139 cycles against a generation counter's one.
    Report the axes SEPARATELY; folding them into a scalar needs a
    cycle-per-square-micron exchange rate, which is rule 22's refusal again.

    **A crediting axis over a sequence that does not exercise the benefit is not
    an axis.** Measured on `d_ca03`: the functional probes alone are 20% TLB hits,
    where serialising a lookup costs almost nothing; the capacity replays reach
    32%; four reuse passes reach 55%, where the penalty is 2.26x on total cycles.
    Measure the hit ratio before relying on the axis, and lengthen the reuse
    portion until it discriminates.

    **Pin only when nothing can credit the benefit.** Pinning `d_ca03`'s storage
    fixes 45.5% of its area — 3,467 flip-flops, 86,744 of 190,657 um^2 — and is
    still worth doing alongside the cycle axis, because capacity has no crediting
    axis even with cycles scored: correctness never depends on it and the walk
    resolves every miss.

    **From:** F62, F69

26. **Every control input of a pipelined design requires a stated transition
    behaviour.** For any design whose pipeline depth is greater than one, each
    control input must have its behaviour AT THE TRANSITION written down — either
    scored, with the rule stated, or named UNSCORED with an explicit window.
    Silence at a transition is a defect, not a default.

    **Why silence is not neutral.** A pipelined design holds state its contract
    does not name, and a control input is precisely a thing that acts on that
    unnamed state. A reader implementing the text has to do something when the
    control moves; every choice is as conformant as any other. The reference
    picks one, the text appears to require it, and an independent implementation
    that picks differently looks defective when it is not.

    **The signature, when this has gone wrong.** Two implementations agree
    exactly on the steady-state rule and against a constant stimulus, then
    diverge under a time-varying one for EXACTLY ONE PIPELINE DEPTH after each
    control transition, with values far apart rather than within an ulp. That is
    in-flight state draining, not arithmetic.

    **Do NOT fix it by modelling the pipeline.** Writing the state into the
    contract hands every submission a required microarchitecture, which is
    usually the design freedom the task exists to measure. Narrow instead: name
    the window in whatever tick the contract already counts in, and exclude it.
    Nothing should be scored that the text cannot specify.

    **From:** F68



27. **A harness latches completion; it never polls a level. And fixing an
    instrument obliges re-deriving what was concluded with it.** Any handshake or
    completion signal a rig reads — `valid`, `done`, an exception flag — is
    latched from request to retirement, and the latched value is what gets
    recorded or compared. `if (valid)` once per clock is correct only for a signal
    guaranteed to be held, and a multi-cycle unit behind a valid/ready interface
    guarantees nothing of the kind.

    **Verify the pulse width BEFORE writing the sampling code.** One
    cycle-by-cycle trace settles whether a level read is admissible at all, and it
    costs nothing next to the cost of not doing it.

    **THE COROLLARY IS THE EXPENSIVE HALF.** When an instrument defect is found,
    enumerate everything measured with it before the fix and re-run each item.
    Repairing the rig and leaving the conclusions is how a NORMATIVE CLAUSE ends
    up standing on a retracted reading: `d_ca03`'s L2 was relaxed to carve out
    flush-cancelled requests because a polling harness recorded `valid=0`; the
    harness was fixed to latch, the same step then recorded `valid=1` with the
    correct address, and the relaxation survived anyway until the obligation was
    measured directly — at which point the unit turned out to re-walk and retire
    in 15 cycles, the opposite of what the clause said.

    **Symptoms to distrust.** A probe reporting that a control input does nothing;
    an oracle returning zero for every case while its flags vary; a control that
    disagrees with a recorded vector on exactly the steps involving a control
    transition. All three were this defect.

    **From:** F70

28. **Every output you score needs a clause that determines it, and every clause
    you write needs a stimulus that reaches it.** A scoring list is not a
    specification. Naming `valid_o`, `paddr_o` and `exc_valid_o` as "the scored
    surface" says what gets compared, not what the values must be — and the gap
    is invisible while the reference is the only implementation, because the
    vectors record whatever it happens to do and the comparison passes for
    anything that agrees.

    Walk it in both directions before shipping a task. **Forwards:** for every
    output on the scored list, name the clause that fixes it in each retirement
    case the task can reach — success, each fault class, each control transition.
    An output with no such clause is under-specified, or should not be scored at
    all because its value reports an implementation choice. **Backwards:** for
    every clause that pins a value, name the stimulus that reaches it, and report
    that witness next to the verdict rather than inferring it from the clause's
    existence.

    `d_ca03` failed both directions at once. Forwards: nothing said whether
    `valid_o` accompanies a fault, and nothing said what `paddr_o` holds when one
    is raised — the second turned out to report whether the design checks A/D in
    the walker or on the hit path, which another clause explicitly leaves free.
    Backwards: the instruction port was declared scored and the harness never
    asserted `fetch_req`, so two pinned fault causes and half the pinned TLB
    budget went unexercised across 118 requests.

    **The backwards direction is VARIATION, not assignment.** This is the part
    that is easy to get wrong and cheap to get right. The obvious check — "assert
    every scored port was driven at least once" — catches ONE of `d_ca03`'s three
    instances. `fetch_req` was never assigned, so it is caught. `asid_i` is
    assigned every single cycle, at the constant zero, and sails through while the
    whole ASID and global-page clause goes untested; five further inputs sail
    through with it, taking three pinned fault causes and an entire
    memory-protection path with them. An input that never changes value has not
    been tested, however continuously it was assigned.

    An input may legitimately be constant. The only thing separating a deliberate
    constant from an overlooked one is a written reason, so a constant must be
    **declared with the citation that permits it**, and an undeclared constant
    must FAIL rather than warn. Three of `d_ca03`'s eight constants were
    legitimate and five were defects; nothing in the source distinguished them.

    **What finds it.** A second source, and essentially nothing else. Both
    directions were invisible to seven negative controls and to my own review of
    the specification, because a control is built from the reference and inherits
    its answer to every question the text left open.

    **From:** F71, F72

29. **A test declared independent of a freedom must be validated against
    something that exercises the freedom, not against the reference.** Validating
    against the reference tests one implementation, and it is the implementation
    least likely to surprise you, because the freedom was usually written down
    after looking at it.

    Not checking the thing a freedom controls is not the same as being
    independent of it. `d_ca03`'s capacity check asserted that replaying 16
    resident pages issues no page-table read, and claimed policy independence
    because it never checks *which* entry is displaced. But passing requires a
    replacement policy that spreads a cold fill, and the specification permits
    policies that do not — the anchor's own advances only on a lookup hit, so a
    cold fill lands all sixteen pages in one entry. The same check run against
    the second TLB of the same design issued 96 reads where the first issued
    none. The check had been validated correctly, against a known-good answer, on
    the one port whose preamble happened to satisfy it.

    A second instance of the same structure driven differently was enough here.
    A second source, or a control built to take the other choice, does as well.

    **And when the claim falls, say what is left open.** Once policy
    independence failed there was no behavioural test that could establish the
    second TLB's capacity at all, since an under-provisioned design is
    indistinguishable from the reference. The budget is now priced on the cycle
    axis and the specification states plainly that it is not enforced pending a
    structural check. An open hole recorded in the contract beats a false claim
    that reads as closed.

    **From:** F73

30. **State only the scope that ran, and identify the run behind any claim that
    something was established.** A summary may not name coverage the run did not
    have; a past-tense claim that a state was established must name the run and
    the tree state that established it. Both halves are about the sentence, not
    the instrument.

    **The scope half.** A summary line is written once and read many times, by
    people who will not go and count. When the eleven verdicts a script produced
    were all on one base and its closing line said "on BOTH bases", every
    individual verdict was correct and the sentence was false -- and it read as
    twenty-two of twenty-two to everyone downstream, including the agent that had
    just run it. A summary states what ran. If a script cannot name its own
    coverage, it prints the count it actually performed and nothing about the
    coverage it did not.

    **The provenance half.** "The golden-base half comes from
    sim_verification.sh" is a claim about a run, and a claim about a run is
    checkable only if the run is identified. Name the record and the tree it came
    from -- a timestamp, a task_text_hash, a commit, and whether the tree was
    dirty. A past-tense assertion with no run behind it is indistinguishable from
    an intention, and the two were confused within a day of each other here.

    **Why no existing control catches this.** Rule 24 points at apparatus and
    rule 17 points at configuration; both were satisfied in the instances that
    produced this rule. The contract was right, the apparatus was right, the
    number was right, and the prose claimed more than what ran. Nothing in the
    stack is pointed at prose, so this rule is the only thing standing there.

    **From:** F67

31. **An impossibility claim must name its instrument, that instrument's
    assumption, and what a different instrument would have to see.** "X cannot be
    measured" is itself a measurement, and it inherits every assumption of the
    experiment behind it — but unlike a false negative it does not get retested,
    because it converts into a specification clause and clauses get read and
    believed rather than re-run.

    Three things, or it is an untested hypothesis and must be labelled one:
    **the instrument** actually run; **what that instrument assumes**, which is
    usually the thing nobody chose and so is invisible; and **what a different
    instrument would have to observe** for the claim to fail. The third is
    load-bearing — if you cannot state it, one experiment has failed and nothing
    has been established.

    `d_ca03` came two steps from shipping a pinned 16-entry instruction TLB as
    permanently unenforceable, on the strength of a probe that filled the TLB
    COLD. The anchor's replacement tree advances only on a lookup hit, so the
    probe was measuring the replacement policy and not the capacity. Re-touching
    each page after installing it makes the reference retain all 16, and a
    one-entry control then fails on that check alone. Naming the assumption —
    "this fill produces no hits, and the policy may need one" — would have found
    it in the same sentence that made the claim.

    **The family.** Same error as rules on level-versus-event and on ad-hoc
    queries as apparatus: an instrument measuring a different observable than the
    claim is about, returning a plausible number. What makes this member the
    expensive one is that its output is a clause rather than a result.

    **From:** F74

32. **A counter or flag that feeds a verdict must be shown to reach both states
    against a known input, and a coverage flag must derive from a recorded
    outcome rather than from the schedule.** A check that cannot fire and a check
    that passes print the same thing, so nothing about a green run distinguishes
    them.

    `d_ca03`'s testbench declared `wr_attempts`, compared it, incremented `errs`
    on it and printed a message — and nothing anywhere assigned it. The clause
    forbidding the unit from ever writing a page table entry had been reporting
    PASS on a property it never tested, across every run, for the reference, a
    second source and seven negative controls. The check was shaped exactly like
    a real one, which is why confirming "is this property checked?" found four
    pieces of evidence and stopped.

    Four of its coverage floors were set from `seq[i].ev` — the schedule the
    testbench had just built — so they asserted that an array the rig constructed
    contains what the rig put in it. **If a flag can be evaluated without running
    the design, it is not coverage.** The other eight derived from recorded
    reference outcomes and were genuine; all twelve printed in the same block,
    indistinguishable at a glance.

    **For an absence-shaped property** — "never writes", "no deadlock", "issues
    no read", "no false assertion" — constructing the presence and watching the
    check fire is PART OF THE CHECK, not an optional extra. This is the
    write-side of the rules on instruments reporting the wrong observable: there
    the instrument answers a different question, here it cannot answer at all.

    **From:** F75

33. **A normative clause derived from an external standard must be measured
    against the anchor before it ships. The anchor is the oracle; the standard is
    not.** Where they disagree the contract must state what the ANCHOR does, and
    say that it diverges — a submission is scored against the anchor, so a clause
    that is true of the standard and false of the anchor fails a correct design.

    **An AUTHORITY line is not evidence for the clause.** It is evidence for what
    the standard says, which is a different claim, and it is the thing that makes
    the defect survive review: the clause reads correctly, cites a real authority,
    and the authority genuinely says what it claims. The only thing wrong with it
    is a fact about one RTL module, and reading the clause cannot reveal that.

    `d_ca03`'s A8 said PMP is checked on the walker's reads "and so is the final
    translated address". The second half was never true of the anchor. A
    W-denied store translates, an X-denied fetch translates, and a warm TLB hit
    through an R-denied region translates issuing zero page-table reads. RISC-V
    does check the physical access by access type — but the anchor is an MMU, and
    the access happens somewhere else. The clause was correct about the standard
    and false about the thing being scored, and it survived because the sequence
    pinned one permitting region for its whole length so no request could
    discriminate.

    **The inverse of the leaves-it-open rule, and it needs the opposite
    question.** That rule asks "what did the reference decide that I did not write
    down?" — and no amount of asking it surfaces this, because this clause WAS
    written down. Ask instead: **"which of my clauses have I never actually seen
    the anchor obey?"** Then measure across the configurations that would separate
    the standard's rule from the anchor's behaviour, not in the direction the
    standard predicts.

    **From:** F77

34. **The stimulus-variation check and a capability-reduced control are BUILD
    STEPS for a design task, not audits of one.** A task is not finished until
    both have been run and both have been shown to discriminate. Running them
    afterwards finds the same defect again by hand, once per task.

    **The evidence is four instances in four tasks**, each one a capacity or
    permission surface declared scored and not actually scored:

    | task | surface | found by |
    |---|---|---|
    | `d_ai01` | HEIGHT load-bearing? | a capability-reduced control (`nc_g`) |
    | `d_ca03` | instruction TLB capacity | a capability-reduced control |
    | `d_ca03` | the whole PMP path, plus supervisor/SUM/MXR and ASID | the variation check |
    | `d_ca03` | `flush_i` abort — a clause revised twice, never exercised | outcome-derived coverage |

    Every one was invisible to review, to the reference, and to the existing
    negative controls, because a control built from the reference inherits its
    answer to every question the text left open.

    **What each instrument is for, and why one does not substitute for the
    other.** The variation check asks whether the STIMULUS reaches a clause: every
    input the contract gives meaning to must take more than one value, and a
    constant must be declared with the clause permitting it. The
    capability-reduced control asks whether the CHECK discriminates once the
    stimulus is there: a design that provides less than a pinned budget, ports
    left full width so it answers every request correctly and only discards
    capacity, must FAIL — and preferably fail on that check alone with zero
    per-step failures, which is what proves the perturbation is isolated.

    A task can pass the first and fail the second: `d_ca03`'s instruction TLB was
    reached by stimulus and still unenforced, because the residency check had been
    declared impossible. It can pass the second and fail the first: a control
    cannot discriminate on a clause no request ever visits.

    **Both are cheap.** The variation monitor is about sixty lines and mostly a
    name table. The control is a copy of the second source with one literal
    altered. Neither needs synthesis, so neither inverts the grading order the way
    a structural check would. There is no cost argument for deferring them.

    **And validate the instruments themselves**, since both are absence-shaped: a
    reconstruction of a known-failing input for the variation check, and a
    negative control proving it can pass rather than being stuck-fail. A static
    scan is a candidate list, never a verdict — cross-check it against a runtime
    monitor, because the scanner written for this was wrong four times before it
    agreed with one.

    **From:** F72, F77

35. **A harness must obey the protocol it imposes on the design.** Apparatus
    that drives the DUT outside its contract is not a weak test — it is an
    invalid one, because a design given illegal stimulus may do anything, and
    whatever goes wrong is attributed to the design.

    **An assertion firing inside vendored RTL is evidence about the STIMULUS at
    least as often as about the design**, and the reason the wrong reading wins
    is EFFORT, not likelihood.

    Attributing the assertion to the design costs nothing and ends the
    investigation: a failing assertion in the DUT already looks like a design
    defect, needs no argument to be believed, and the next step is to fix the
    design. Attributing it to the stimulus costs reading the protocol, finding
    the responder, and establishing what it may and may not do — and it only
    pays off if you were right. So the default is not the more probable reading;
    it is the cheaper one, and it terminates the search before the alternative is
    considered. Reach for the stimulus reading FIRST, precisely because nothing
    else will make you.

    `d_nw01`'s slave model drops `r_valid` while a beat is pending, which AXI
    forbids and which the task's own H3 requires of submissions. The anchor's
    arbiter asserts on exactly that assumption, so sustained response
    backpressure is illegal stimulus against that harness — which leaves L3,
    a clause about response backpressure, never tested in the condition it
    names. `d_ca01` has the same construction, with a comment showing the author
    hit the symptom and worked around it by gating the output.

    **Ask it of every handshake the contract names**, in both directions: where
    a spec says "once valid is asserted it holds until ready", the testbench's
    own responders are bound by that sentence too. No instrument in this
    repository asks this — the variation check asks whether an input moves, the
    capability controls ask whether a check discriminates, and legality is a
    relation between a signal and a protocol rather than a property of either.

    **From:** F81

---
