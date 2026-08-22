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

9. **Area and power are reported at own Fmax and at a common binding period**,
   and every area comparison splits three ways: off-spec configuration,
   capability gap, genuine optimisation. A headline ratio without that split is
   not a result. Composite metrics (area × delay) are not scoring axes and are
   only meaningful where area is elastic under constraint — which must be tested
   per design, not assumed.

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


---

**Nothing you write is trusted until it has been run.**
