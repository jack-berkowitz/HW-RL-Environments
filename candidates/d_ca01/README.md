# candidates/d_ca01 — `nonblocking_dcache`

Model answers for `domains/comp_arch/design/d_ca01_nonblocking_dcache`.

One file per attempt, `<label>.sv`, containing **only** `module nonblocking_dcache`
with the exact port list from `spec/nonblocking_dcache_iface.sv`.

Solicit with `probe/PASTE.md` in the task directory — it carries the framing and
the full interface.

Score with:

```
./scripts/sim_candidate.sh d_ca01 candidates/d_ca01/<label>.sv
```

16 configurations, full cross of `DATA_W {32,64}` x `SETS {8,16}` x
`WAYS {2,4}` x `MAX_MISSES {2,8}`. The scored configuration for PPA, latency and
throughput is `DATA_W=32 SETS=16 WAYS=4 MAX_MISSES=8` — and `MAX_MISSES=8` is
load-bearing: the capability mutant survives all eight `MAX_MISSES=2`
configurations and dies at all eight of the 8s, so a pass at the low setting is
not capability evidence.

---

## GRADING NOTE — R1b, and one verdict a grader will read backwards

**If a run fails with `R1 was never exercised`, that is a FAILURE, and it is very
probably an R1b violation. Do not read it as a pass.**

`R1b` forbids `rsp_valid_o` from depending combinationally on `rsp_ready_i`. **The
testbench cannot see that dependency.** It observes `rsp_valid_o` low and has no
way to tell "gated on ready" apart from "no response ready yet". So a design that
violates R1b does not trip an R1b check — there isn't one. What it trips is the
condition floor, which reports:

    FAIL: R1 was never exercised -- rsp_valid was never high while rsp_ready was low

Read literally, that sentence describes the *harness* rather than the design, and
it is easy to file as "coverage gap, not the candidate's fault". **That reading
inverts the verdict.** The reference reaches a non-zero count; so do `chat` and
`claude`. A submission that drives it to zero has, on the evidence available,
gated its output valid on the consumer's ready — which is exactly what `R1b`
forbids and exactly what `controls/nc_r1_evades_antecedent.sv` does.

**What to do with it:**

* **Score it as a fail.** It is a fail today, mechanically, and no manual step is
  needed to make it one.
* **Then read the design's `rsp_valid_o` assignment**, because the floor tells you
  the antecedent was empty and not *why*. If `rsp_valid_o` references
  `rsp_ready_i` in a combinational path, it is R1b — report it as R1b, not as a
  coverage hole. If it does not, the design has some other reason for never
  offering a response under backpressure and that is worth writing down.

**Why the clause exists at all.** R1's stability sentence was satisfiable by
never offering: a response never presented to a stalled consumer cannot be
withdrawn from one. A design could empty R1's antecedent instead of honouring its
consequent and no clause objected. Measured, not argued — `nc_r1_evades_antecedent`
passed every clause at all sixteen configurations under the previous contract.

**The mirror is deliberate, not a contradiction.** `L5` explicitly PERMITS the
identical construction on the *request* side (`req_ready_o` may depend
combinationally on `req_valid_i`), because the harness never derives
`req_valid_i` from `req_ready_o`, so no deadlock is reachable there.
`conformant/c02_ready_gated_on_valid.sv` is that permitted design and **passes
16/16**. If a submission gates ready on valid at the request side, that is
conforming. At the response side it is not.

**None of the three current submissions exploits this.** `chat` and `claude` pass
16/16. `gemini` fails on **R3/R5** — a LOAD returning the wrong value, an ordinary
data-correctness failure unrelated to R1b.
