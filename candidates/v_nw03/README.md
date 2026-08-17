# Model answers for v_nw03 frame_arb_mux.

**TESTBENCHES, not RTL** — module `frame_arb_mux_tb`, from the blind task in
`domains/networking/verification/v_nw03_axis_arb_mux/probe/BLIND_TB_TASK.md`.

Run one, or the whole directory:

```bash
./scripts/sim_verification.sh v_nw03 candidates/v_nw03/chat.sv
./scripts/sim_verification.sh v_nw03 candidates/v_nw03
```

Twelve DUT rows: the golden, 5 conformant perturbations that must be ACCEPTED,
and 6 mutants that must be CAUGHT. Unlike `v_ca05` at the time its holding pen
was written, the mutant set exists, so fault detection IS measured here.

**Report kills against the reference ceiling of 6/6, never as a bare fraction** —
and read `mutants/README.md` on what that ceiling is worth before doing so.

Three verdicts are distinct and must not be merged:
- `killed` — the testbench detected the fault.
- `SURVIVED` — it did not.
- `HUNG` — it never terminated. **Not a kill.** A correct-but-slow design hangs
  it identically, so scoring a hang as detection distinguishes nothing.

Same warning as every other verification task: **do not let
`run_submissions.sh` discover this directory.** It assumes every submission is
RTL and would count each testbench as a failed candidate.
