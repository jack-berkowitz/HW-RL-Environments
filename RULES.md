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

    **From:** F24, F18

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
    7 errors)*. The confirmation matters — a frontend disagreement is not a
    build failure, and the way to tell is to check the second frontend.

    **From:** F27

20. **No reported value may be produced by a fallback, a default, or a merge
    across configurations.** A value that was not measured for *that specific
    design* at *that specific pinned configuration* renders as **absent**, and
    absent renders as absent.

    Four instances, all in the reporting path and none in measurement:

    | | what it invented |
    |---|---|
    | Fmax fallback | printed the **reference's** 380.9 MHz on candidate rows never swept |
    | metric merge | `dict.update` across 18 configs, so each row showed whichever config was written last |
    | F28 name drop | structured metrics filed under bare `min`/`max`/`n`, overwritable by any other metric |
    | absent crossing latency | read ABSENT for a metric emitted on every one of 18 configs |

    **The measurements were right every time.** What produced a wrong number was
    a reporting path that preferred a plausible value to no value. A fallback is
    the most dangerous form: it is written to be helpful, it fires exactly when
    data is missing, and its output is indistinguishable from a real
    measurement.

    Absent is never the unhelpful answer. A blank cell prompts someone to go and
    measure; a borrowed number does not.

    **From:** F28, F29

---

**Nothing you write is trusted until it has been run.**
