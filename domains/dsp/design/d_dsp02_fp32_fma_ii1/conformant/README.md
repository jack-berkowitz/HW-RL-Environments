# d_dsp02 conformant perturbations — must PASS, not be killed

The design-side counterpart to `v_ca05/conformant/`. Opposite sign to
`mutants/`: these satisfy the contract, so a correct **checker** must accept
them, and a failure here is a defect in the checker rather than in the design.

| id | perturbation | licensed by | latency | checker |
|---|---|---|---|---|
| `cPIPE3` | `NumPipeRegs=3`, `PipeConfig=DISTRIBUTED` | spec: *"LATENCY IS NOT CONSTRAINED AND NOT CHECKED"* | **3 cycles** vs 0 | **1/1 PASS** |

## It is observably different, and that took two attempts to show

Total simulation time is **43 µs for both** bindings — three extra cycles against
4290 vectors at II=1 is invisible at that resolution, and stopping there would
have been an F25-style no-op control reported as a pass.

Measured directly instead: **input-to-output latency is 0 cycles at
`NumPipeRegs=0` and 3 cycles at `NumPipeRegs=3`.** That is the property the
perturbation exists to vary, and it is the one the checker had to tolerate.

## What its passing establishes

**The checker does not assume zero latency.** C3 constrains the *initiation
interval* — one result per cycle once full — which a pipelined unit still meets.
A checker that had quietly conflated II with latency would fail this, and the
spec would have been licensing something the apparatus could not accept.

That distinction is not hypothetical here: the spec pins C3 at II=1 and
explicitly frees latency, so the two must be independently enforceable.

## As a PPA point

`cPIPE3` is a **second configuration of one contract**, not a better result for
the same one. Any comparison against the `NumPipeRegs=0` binding must name the
axis under rule 17 — the registers change area and Fmax by construction, and
subtracting the two numbers without naming why they differ is exactly what F24
was about.
