# Model answers for v_ca07 clk_int_div.

**TESTBENCHES, not RTL** — module `clk_ratio_div_tb`, from the blind task in
`domains/comp_arch/verification/v_ca07_clk_int_div/probe/PASTE.md`.

Run one, or the whole directory:

```bash
./scripts/sim_verification.sh v_ca07 candidates/v_ca07/chat.sv
./scripts/sim_verification.sh v_ca07 candidates/v_ca07
```

## Seventeen DUT rows

    1   golden                    must PASS -- this is the validity gate
    1   gate mutant               all outputs tied to '1; must be REJECTED
    5   conformant perturbations  cdc_c1..cdc_c5, all LEGAL, must be ACCEPTED
    1   second source             clk_ratio_div_alt, LEGAL, must be ACCEPTED
    10  guarded mutants           cd_m1..cd_m10, must be CAUGHT

**Seven legal rows against ten faulty ones.** That ratio is deliberate and it is
the same reason v_ca06 carries six-to-ten: the re-grade showed the strongest
submissions lost their score to **rejecting a legal variant**, not to missing a
defect. A testbench that pins one correct design and calls the others broken
scores worse here than one that catches nine of ten faults and accepts every
legal implementation.

The five conformant perturbations are the sharp end. `cdc_c4` counts zero while
disabled and `cdc_c5` freezes the count instead — **both are legal**, the
contract does not choose between them, and a testbench that requires either one
rejects correct hardware.

## What the reference establishes

    validity gate   PASS
    faults caught   10 of 10
    verdict         ACCEPTED -- the ceiling this task's reference sets

Run it yourself before reading a submission's score against it:

```bash
./scripts/sim_verification.sh v_ca07 \
  domains/comp_arch/verification/v_ca07_clk_int_div/tb/clk_ratio_div_spec_tb.sv
```

## Before scoring anything here

The kill count is reported **per mutant**, never as a rate — which mutant
survived is the informative part and a rate averages it away. And a kill from a
submission that failed the golden carries no information (rule 16): a testbench
that rejects everything appears to catch everything.

## Directory state

**Empty of submissions.** This directory and this file were created when the task
was confirmed complete; nothing has been solicited against `v_ca07` yet. The
task's text hash at that point was `0d5cc8575568fdb1` — a submission is an answer
to a specific text, so anything placed here should record the hash it was
solicited against.
