# v_nw04 `ptp_time_base` — build notes

Tier-B. Anchor: Forencich `verilog-ethernet/rtl/ptp_clock.v`, MIT, zero
dependencies.

## Why this design

The arithmetic is **fractional and exact**. The time base advances by 6.4 ns per
cycle — a number with no whole-nanosecond representation — plus a drift of 2/65536
ns landing on one cycle in five, plus a signed offset applied to a counted number
of increments. A testbench cannot check any of that by inspection; it has to run
its own accumulator and decompose every observed advance into
period + adjustment? + drift?.

Two obligations are *counted* rather than continuous — the adjustment is applied
exactly `adj_count_i` times, the drift exactly once in every `drift_rate_i` — and
those are the clauses the mutants live on.

## Step 1 — semantic confirmation (measured, not read)

| question | measured |
|---|---|
| nominal rate | 419430.4 fns/cycle = 6.4 ns + 0.4 fns of drift, exactly as configured |
| are the two bases in step? | **no** — `ts64_o` and `ts96_o` take the drift on *different* cycles |
| counted adjustment | `adj_count_i=4` gives `adj_active_o` high on exactly 4 cycles |
| drift period | +16 fns at rate 3 over 30 cycles = 10 applications = 160 fns excess, exactly |
| one-second wrap | loaded s=7 ns=999999900; after 40 cycles s=8 ns=156, and **pps for exactly 1 cycle** |
| is the adjustment signed? | yes — `{4'hF,16'hF830}` behaves as −2000 fns |
| pps elsewhere? | 0 assertions in 300 cycles away from a wrap |
| control latency | `period_valid_i` → effect: **2 cycles**; `adj_valid_i` → `adj_active_o`: **1 cycle** |

### The wrap is 150 million cycles away

At 6.4 ns per cycle the one-second boundary is over 156 million cycles out.
It is reachable **only** by setting the base close to it. A testbench that does
not work that out never tests W1 or W3 at all. This is deliberate headroom.

## A spec bug the reference testbench found

The first spec said the two bases "advance by the same increment on the same
cycle", and the first reference testbench checked it. Against the golden it
failed immediately: `ts96_o` is driven from a one-cycle-delayed copy of the
increment, so the drift lands on different cycles in the two bases.

That was **my error in the spec**, not a defect in the design. I1, S4 and L2
were rewritten: each base is checked *on its own* — a legal increment every
cycle, the drift exactly every `drift_rate` cycles, the adjustment on exactly
`adj_count` increments — and the phase between them is named as latitude.

This is the value of a reference testbench that carries a model rather than a
recorded trace: it can be wrong in a way that shows up, and it showed up.

## Step 5c — the policy-divergent perturbation

**The named latitude is L1 (control latency) and L2 (increment phase).**

`conformant/conformant_perturbations.sv` (`pt_c1_zero_latency`) is an
**independent implementation** — a flat accumulator with a direct comparison
against one second, not the anchor's pipelined borrow-lookahead — and it takes
the opposite choice on both: every control input takes effect in the same cycle
its valid is asserted, and both bases are driven from the same increment on the
same cycle with `adj_active_o` exactly in phase.

**It failed the reference testbench on the first run, and the testbench was
wrong.** `start_adjust` armed its counters *after* driving `adj_valid_i`. With
the golden's one-cycle latency all twelve adjusted cycles were counted; with a
zero-latency design the first one was counted and then wiped, and the testbench
reported a correct design one short. That is precisely the testbench encoding
the golden's control latency rather than the contract. The counters are now
armed before the valid is driven.

**Policy independence: 18 of 18.** All eight defects re-derived on the divergent
implementation and re-run; every one is caught on both bases, and both clean
implementations pass. `mutants/check_policy_independence.sh` reruns it.

One defect needed the *stimulus* strengthened rather than the mutant changed.
`p4_wrap_one_ns_early` initially survived on the divergent base: at a 6.4 ns
step, the window between "one nanosecond early" and the true boundary is 1 ns
wide, and a walk-up starting at 999 999 800 ns never lands inside it. The
mutant was not latitude-sensitive — it was **unreachable**. The testbench now
starts at 999 999 929 ns, where the eleventh increment falls on 999 999 999.4,
inside the window and far enough past the set for the L1 settling window to have
closed. Both bases then catch it.

The same artefact is wired as the second DUT (`dut2/ptp_time_base_alt.sv`),
generated from it so the two cannot drift. One artefact, two roles, said plainly
rather than counted twice as independent evidence.

## Step 5 — negative controls

**(b) known-bad DUTs: caught, by name.** `negctl/stuck_dut.sv` (all 5 outputs
tied low, generated from the port map) and `negctl/reset_polarity_dut.sv`
(`rst_i` treated as active low) are both caught at **cycle 9**, each naming
clause I1 — not by the watchdog.

**(a) null testbench: rejected.** `negctl/null_tb.sv` drives nothing and never
instantiates the DUT. The harness now runs a gate-mutant with every output tied
high and requires a submission to reject it; the null testbench is reported
`INVALID: this submission does not DISCRIMINATE` and `EXCLUDED FROM SCORING`.
This gap was found and reported on v_nw02 and has since been fixed.

## Rule 4 — coverage floors

Every floor counts **stimulus**: period changes driven, counted adjustments
driven, *negative* adjustments driven, drift changes, timestamp sets, and flags
for driving the wrap and for asserting reset mid-run. None counts a DUT
response, so a faulty design cannot suppress the coverage that would convict it.

## Watchdogs

| | |
|---|---|
| TB simulation-time limit | 3 ms |
| reference run, wall | 0.01 s |
| `sim_timeout_s` | 60 s |

## What is not here

Tier-B drops the full kill-rate table across historical candidates and the
`bmc_cex` evidence path. All eight mutants carry a simulation witness; none
needed BMC. The second source was not dropped — it fell out of 5c for free.
