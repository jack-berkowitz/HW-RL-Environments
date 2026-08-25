# Model answers for d_dsp02 fp32_fma_ii1.

RTL submissions, module name `fp32_fma_ii1` from `spec/fp32_fma_ii1_iface.sv`.

**HOLDING PEN — nothing runs against these yet.** The task has no
`ref/sim_flags_verilator.txt` and is not registered with `sim_candidate.sh`
(FINDINGS.md F22), so it is unscoreable until the plumbing is rebuilt.

Do not sweep this directory meanwhile: `sim_candidate.sh` refuses correctly, but
`run_submissions.sh` relabels any refusal as `correctness gate failed` and counts
it against the pass rate. See the warning in `candidates/README.md`.

---

## GRADING NOTE — H1b, and one verdict a grader will read backwards

**If a run fails with `H3 was never exercised`, that is a FAILURE, and it is very
probably an H1b violation. Do not read it as a pass.**

`H1b` forbids `out_valid` from depending combinationally on `out_ready`. **The
testbench cannot see that dependency.** It observes `out_valid` low and has no way
to tell "gated on ready" apart from "no result ready yet". So a design that
violates H1b does not trip an H1b check — there isn't one. What it trips is the
condition floor:

    METRIC: h3_guard_true=0 (0 means H3 was not exercised)
    FAIL: H3 was never exercised -- out_valid was never high while out_ready was low

Read literally, that sentence describes the *harness* rather than the design, and
it is easy to file as "coverage gap, not the candidate's fault". **That reading
inverts the verdict.** The reference reports `h3_guard_true=60`; so do `chat` and
`claude`. A submission reporting `0` has, on the evidence available, gated its
output valid on the consumer's ready — which is what `H1b` forbids and what
`controls/nc_h3_evades_antecedent.sv` does.

**What to do with it:**

* **Score it as a fail.** It is a fail today, mechanically.
* **Then read the design's `out_valid` assignment.** The floor tells you the
  antecedent was empty, not why. If `out_valid` references `out_ready` in a
  combinational path, report it as **H1b**, not as a coverage hole. If it does
  not, the design has some other reason for never offering a result under
  backpressure, and that is worth writing down.
* **`h3_guard_true` is printed on every run.** Compare it against the reference's
  60 rather than only reading PASS/FAIL — a count far below 60 is worth a look
  even when the run passes, because it means the clause was barely exercised.

**Why the clause exists at all.** H3's stability sentence was satisfiable by never
offering: a result never presented to a stalled consumer cannot be withdrawn from
one. H1 already forbids the input-side version of exactly this dependency; there
was no mirror on the output side. Measured, not argued —
`nc_h3_evades_antecedent` satisfied every clause under the previous contract
while driving the count to zero.

**Two distinct failure signatures, and they mean opposite things:**

    phase=h3      the CONSEQUENT was violated -- out_valid dropped or the result
                  moved while stalled. The clause has force and caught it.
    phase=final   the ANTECEDENT was suppressed -- "H3 was never exercised".
                  The design never offered under backpressure. Look at H1b.

**None of the three current submissions exploits this.** `chat` and `claude` pass
with `h3_guard_true=60`. `gemini` fails on vector 0 arithmetic — a subnormal
result, identical before and after the H3 stimulus existed, so pre-existing and
unrelated.
