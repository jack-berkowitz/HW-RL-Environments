# v_nw04 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: that one satisfies the spec and must survive; these violate it
and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of a
renamed copy of the anchor wrapped by a renamed copy of the golden shim. Each
edit is an exact `old -> new` string pair the generator asserts matches
**exactly once**. A silent no-op would produce a mutant identical to the golden
that every testbench "kills" by doing nothing, so the count is checked rather
than assumed.

## The set

| id | clause | defect | why running the clock and watching it tick misses it |
|---|---|---|---|
| `pt_m1_drift_period_off_by_one` | **D2** | the drift lands every `drift_rate+1` increments | the rate is still nearly right; only measuring the *spacing* between drift-carrying increments shows it |
| `pt_m2_adjust_one_short` | **A2** | the adjustment is applied `adj_count-1` times | one application out of twelve; only an exact count catches it |
| `pt_m3_adj_active_one_long` | **A3** | `adj_active_o` is high for `adj_count+1` cycles while `adj_count` increments are adjusted | the flag and the applications disagree by one. A testbench that trusts the flag instead of counting the adjusted increments — or counts only one of the two — misses it |
| `pt_m4_wrap_one_ns_early` | **W1** | the one-second wrap happens one nanosecond early | the boundary is 150 million cycles away, and the window between "one ns early" and the true boundary is **1 ns wide** against a 6.4 ns step. Reaching it at all needs §S; landing *inside* it needs arithmetic |
| `pt_m5_pps_two_cycles` | **W3** | `pps_o` is asserted for two cycles per wrap | needs the wrap reached at all, then the pulse counted rather than merely observed |
| `pt_m6_fns_truncated_in_ts96` | **I1/F3** | the 96-bit base drops the bottom four fractional bits of every increment | 6 fns in 419430 — about 14 parts per million. Any comparison with a tolerance accepts it; only exact arithmetic rejects it. It leaves `ts64_o` untouched |
| `pt_m7_adjust_unsigned` | **A5** | the offset adjustment is treated as unsigned | a *positive* adjustment behaves perfectly. Only a negative one exposes it |
| `pt_m8_reset_keeps_period` | **R2** | reset leaves the last programmed period in place | needs a period programmed, then a reset, then the rate measured again |

None of the eight is reachable by simply letting the clock run.

## Non-equivalence witnesses — rule 16

`nonequiv_tb.sv` drives the golden and one mutant from the same input sequence
and compares the **entire** output vector every cycle. Every output of this
module is meaningful on every cycle — there is no `valid` to qualify against —
so the comparison is the whole vector, not a chosen subset.

| id | first observable difference |
|---|---|
| `pt_m1_drift_period_off_by_one` | cycle 7 — `ts64_o` short by 2 fns: one drift application missed |
| `pt_m2_adjust_one_short` | cycle 48 — `adj_active_o` golden 1 / mutant 0 |
| `pt_m3_adj_active_one_long` | cycle 42 — `adj_active_o` golden 0 / mutant 1 |
| `pt_m4_wrap_one_ns_early` | cycle 162 — `ts96_o` ns golden 1 / mutant 2 |
| `pt_m5_pps_two_cycles` | cycle 163 — `pps_o` golden 0 / mutant 1 |
| `pt_m6_fns_truncated_in_ts96` | cycle 2 — `ts96_o` fns short by 8 |
| `pt_m7_adjust_unsigned` | cycle 66 — `ts64_o` ahead by 1048576 fns, exactly 2²⁰ |
| `pt_m8_reset_keeps_period` | cycle 204 — `ts64_o` advancing at the programmed rate, not the default |

## The mutant that was dropped

`m3` began as **`adj_active_shifted`**: `adj_active_o` marking a window one
cycle away from the cycles actually adjusted. Writing the reference testbench
showed that the golden already hands its two time bases the same increment on
*different* cycles, so the alignment of a status flag against the adjusted
increments is not something this contract can fix without fixing a pipeline.
It was **latitude, not contract**, and it was replaced by a defect that breaks
the *count* — which is contract. Clause A3 was rewritten to say so.

## Reference testbench ceiling

**8 of 8.** Report a submission's kills against that ceiling, never as a bare
fraction.

The set was checked against a **second, independent base**: all eight defects
re-derived on the policy-divergent implementation and re-run, 18 of 18 verdicts
matching, with both clean implementations passing. See
`check_policy_independence.sh` and NOTES.md §5c. It remains true that one author
wrote the spec, the mutants and the reference testbench, and that the set has
not yet been challenged by anything its author did not anticipate.
