# Model answers for v_ca03 id_width_conv.

**TESTBENCHES, not RTL** — module `id_width_conv_tb`, from
`domains/comp_arch/verification/v_ca03_axi_iw_converter/probe/PASTE.md`.

```bash
./scripts/sim_verification.sh v_ca03 candidates/v_ca03/chat.sv
./scripts/sim_verification.sh v_ca03 candidates/v_ca03
```

Twelve DUT rows: golden, 5 conformant perturbations that must be ACCEPTED,
`dut2`, and 5 mutants that must be CAUGHT. Report catches against the **5/5**
reference ceiling, never as a bare fraction, and read `mutants/README.md` on
what that ceiling is worth first.

**This task differs from the other three.** Nine of eleven clauses require the
submission to maintain a model — the set of outstanding identifiers, a count per
identifier, a FIFO per identifier, the live mapping, and the retirement edge.
A scoreboard with one expected value per transaction is not enough here.

`killed` / `SURVIVED` / `HUNG` are three distinct verdicts. A hang is not a
catch. Do not let `run_submissions.sh` discover this directory.
