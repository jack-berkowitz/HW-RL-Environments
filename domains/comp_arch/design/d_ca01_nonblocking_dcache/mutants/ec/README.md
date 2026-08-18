# Bounded equivalence checking for the d_ca01 mutant set

`miter.sv` plus one `.sby` per mutant. `CONTROL_gold_vs_gold.sby` is the
control and must be read before any FAIL here is believed.

## How to run

```
docker run --rm --platform linux/amd64 -v "$REPO:/work" -v "$HERE:/ec2" \
  openroad/orfs bash -c "cd /tmp && sby -f -d /tmp/out /ec2/<task>.sby"
```

`DONE (FAIL)` means a counterexample was found: **the two designs differ on a
concrete input sequence, given identical initial state.** That is a proof of
non-equivalence. `DONE (PASS)` means only *no counterexample within the depth* —
it is NOT a proof of equivalence.

## Three things this configuration exists to work around, all measured

1. **There is no SMT solver in `openroad/orfs`.** Not yices, z3, boolector,
   bitwuzla, cvc5 or mathsat. `sby` and `eqy` are installed with no backend, so
   the `smtbmc` engine cannot run at all. The only usable engine is `abc bmc3`,
   which uses the bundled `yosys-abc`.
2. **`aigsmt none` is required.** Without it `sby` reaches a verdict and then
   fails while rendering the trace, because trace rendering also calls
   `yosys-smtbmc -s yices`. The verdict is correct and gets thrown away with
   `Could not determine aigsmt status`. The cost of disabling it is that there is
   no VCD -- the verdict survives, the waveform does not.
3. **`setundef -zero -undriven -init` is load-bearing.** Without it the two
   copies begin at independent free values and BMC reports a counterexample
   between the reference and ITSELF. The control caught exactly that: it read
   FAIL before this line was added and PASS after. A miter without an
   identical-initial-state constraint proves nothing.

## Why `eqy` itself is not used

`eqy`'s partitioning refuses this design: `sat` does not support partitions
containing memory, and with memories mapped to logic it did not finish in ten
minutes. The miter sidesteps partitioning entirely.
