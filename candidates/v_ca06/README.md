# Model answers for v_ca06 axi_dw_downsizer.

**TESTBENCHES, not RTL** — module `dw_downsizer_tb`, from the blind task in
`domains/comp_arch/verification/v_ca06_axi_dw_downsizer/probe/PASTE.md`.

Run one, or the whole directory:

```bash
./scripts/sim_verification.sh v_ca06 candidates/v_ca06/chat.sv
./scripts/sim_verification.sh v_ca06 candidates/v_ca06
```

**Eighteen DUT rows**, which is the most of any verification task here: the
golden, a gate-mutant that must be REJECTED, **five conformant perturbations and
a second DUT that must all be ACCEPTED**, and ten guarded mutants that must be
CAUGHT.

That six-to-ten ratio of legal-to-faulty is deliberate. The re-grade showed the
strongest submissions lost their score to **rejecting a legal variant**, not to
missing a defect — so this task was built with the legal implementations written
BEFORE the mutants, and the reference developed against six of them rather than
fitted to the anchor.

**Report kills against the reference ceiling of 10/10, never as a bare
fraction** — and read `mutants/README.md` first. Two things there change how the
number should be read: `dw_m1` is a defect the task's own SPECIFICATION carried
until the reference caught it, and `dw_m8` initially survived because its guard
was *unreachable* rather than hard.

Four verdicts are distinct and must not be merged:
- `killed` — the testbench detected the fault.
- `SURVIVED` — it did not.
- `REJECTED` — it passes the golden but rejects a LEGAL variant. Its kills are
  suppressed: a testbench that rejects correct hardware rejects faulty hardware
  too, so its count says nothing about detection.
- `INVALID` / `HUNG` — it does not discriminate at all, or never terminated.
  **Neither is a kill.** A correct-but-slow design hangs identically.

Same warning as every other verification task: **do not let
`run_submissions.sh` discover this directory.** It assumes every submission is
RTL and would count each testbench as a failed candidate.
