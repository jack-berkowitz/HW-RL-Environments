# Model answers for v_dsp02 fp_noncomp.

**TESTBENCHES, not RTL** — module `fp_noncomp_tb`, from the blind task in
`domains/dsp/verification/v_dsp02_fp_noncomp/probe/BLIND_TB_TASK.md`.

```bash
./scripts/sim_verification.sh v_dsp02 candidates/v_dsp02/chat.sv
./scripts/sim_verification.sh v_dsp02 candidates/v_dsp02
```

Twelve DUT rows: golden, 5 conformant perturbations that must be ACCEPTED, 6
mutants that must be CAUGHT. Report catches against the 6/6 reference ceiling,
never as a bare fraction, and read `mutants/README.md` on what that ceiling is
worth first.

**The clause to watch is S4 with §10.** `fn_m2` is a faithful implementation of
IEEE 754-2019 `minimum`/`maximum`, which propagates NaN where the 2008/RISC-V
`minNum`/`maxNum` this contract requires does not. A submission that accepts
`fn_m2` shows the citation in S4 is decorative; one that catches it shows the
citation is load-bearing.

`killed` / `SURVIVED` / `HUNG` are three distinct verdicts. A hang is not a
catch. Do not let `run_submissions.sh` discover this directory.
