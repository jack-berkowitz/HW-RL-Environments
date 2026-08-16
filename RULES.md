# Standing rules

**Revision 3 — 2026-08-15.** *Rev 1: rules 1–7 from the d_nw01 audits. Rev 2:
8–11 from the pipeline and oracle work. Rev 3: 12–13, and rule 10 restored after
being dropped in a consolidation edit.*

**THIS FILE IS THE ONLY PLACE THE RULES LIVE.** `BUILD_PROMPT_DESIGN.md`,
`BUILD_PROMPT_VERIFICATION.md` and `CONVENTIONS.md` reference it and must never
restate it.

That is rule 13, and it exists because the rules had been duplicated across three
documents: a retraction recorded in `FINDINGS.md` stayed live in a build prompt
and would have propagated a withdrawn heuristic into the next task looking like
current guidance, and the rule count drifted to 7 in one place against 10 in
another. **If two copies can disagree, eventually they will.**

Each rule exists because its absence produced a wrong result that survived
review. `FINDINGS.md` records which defect produced each.

---

1. **Every capability the design must support is a named parameter with a
   binding check.** Audit by probe, not by reading: write an otherwise-correct
   implementation that ignores exactly one parameter and confirm the checker
   fails it. A parameter no check enforces will be ignored, and the design that
   ignores it will pass.

2. **Every stated requirement has a coverage floor proving it was exercised.** A
   requirement written in prose that no test creates the condition for is
   decorative.

3. **Every check gets a negative control that fails THAT check and nothing
   else**, and it only counts if the harness can saturate what the check
   measures. A control that trips two checks validates neither; a
   throughput-shaped check whose bottleneck is the harness measures the harness.

4. **Coverage floors measure STIMULUS, not design behaviour.** The test: *could
   a correct implementation score zero here?* If yes, the floor is gating a
   design choice and must become a `METRIC:` line instead.

5. **Second source is mandatory** — an independent implementation making
   different free choices. Name three specific differences or it is a paraphrase.

   **When it fails a check, disambiguate before changing anything:**
   1. run the failing input through the **anchor**;
   2. second source disagrees with the anchor → **the second source is wrong**;
   3. second source agrees and the check still fails → **the check is
      over-constrained**.

   The wrong branch loosens a check to accommodate a bug, and a loosened check is
   invisible afterwards.

6. **No metric may be quoted from a run that failed its own gate.** A build that
   misses timing still produces area and power numbers. They are real numbers and
   they are not results.

7. **Closure status comes from `find_fmax`'s own classification**, never from
   grepping an intermediate log. And **if the bracket is wider than the requested
   resolution, there is no Fmax to report** — only an interval.

8. **Every run writes an immutable record; collection reads only those records**,
   never a live tool directory. A missing row is honest; a stale row is not.

9. **Area and power are reported at own Fmax and at a common binding period**,
   and every area comparison splits three ways: off-spec configuration,
   capability gap, genuine optimisation. A headline ratio without that split is
   not a result. Composite metrics (area × delay) are not scoring axes and are
   only meaningful where area is elastic under constraint — which must be tested
   per design, not assumed.

10. **The runner names its artifacts explicitly and refuses when they are absent;
    it never discovers them by pattern.** Globbing, sorting and silent defaults
    turn a missing artifact into a *different run* rather than an error.

11. **The oracle must be an artefact nobody on this project wrote. Locally
    authored code generates INPUTS, never expected values.** A local model
    producing expected values and merely cross-checked against the anchor leaves
    a shared misconception surviving the cross-check — both sides agreeing for
    the same wrong reason. Invert it: generate inputs locally, run them through
    the anchor, take the anchor's output as expected. A local bug then costs
    *coverage* and can never produce a wrong expected value.

    **Consequence: coverage floors carry the whole weight.** Expected values are
    safe by construction; input coverage is not.

12. **Standards latitude must be named.** Where a task is anchored on a standard
    that permits alternatives, every alternative the anchor forecloses is named
    in the spec as out of scope. Otherwise the vectors silently encode the
    anchor's choice and a conformant design fails a requirement nobody wrote
    down.

    **Audit the artefact, not the prose.** On `d_dsp02` the spec already said
    "tininess after rounding" and that still would not have caught it — the
    inherited choice was found by counting flag combinations across 4290 captured
    vectors.

13. **Single source of truth for the rules.** They live here and nowhere else.
    Any retraction or addition happens in this file, and every other document
    references it.

14. **When blocked, the deliverable is the report.** Stop and say so.

---

**Nothing you write is trusted until it has been run.**
