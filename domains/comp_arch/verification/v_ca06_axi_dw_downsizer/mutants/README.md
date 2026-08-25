# v_ca06 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/` and `dut2/`: those satisfy the spec and must survive; these violate
it and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a wrapper around the
unmodified golden. Each reads its guards from the **ports only** — transactions
accepted, refusals, FIXED single-beat requests, beat indices, downstream beats
forwarded — so nothing inside the golden is read and every guard can be restated
against another implementation.

## Every defect is GUARDED

    defect := wrong_behaviour AND rare_predicate over contract-level state

A **total** defect fires on the first transaction of its class, so any testbench
that exercises the class catches it whether or not it is checking the clause — it
measures coverage, not checking.

**Nine of these twelve are ordinal or depth conditions**, and that weighting is
measured rather than assumed. Two independent results — v_nw01, and the
incognito v_ai02 submission — show the same split: conditions that are a property
of a *single* transaction get caught (a value, a last beat, a mode), and ordinal
or depth conditions get missed. The incognito v_ai02 run caught rotation-value,
last-beat, mode-history and stall-release, and missed all six of third-line,
fifth-beat, five-beat-line, fourth-beat, 32nd-delivery and eight-cycle-stall.

## The set

| id | clause | guard — fires only when… | defect |
|---|---|---|---|
| `dw_m1_len_simple_formula_when_unaligned` | **B2** | the address is not aligned to its own size | the length divides the byte count instead of counting blocks spanned |
| `dw_m2_size_raised_when_narrow` | **B1** | the upstream size is narrower than the downstream bus | the downstream size is forced to the bus width instead of min(size, width) |
| `dw_m3_len_short_from_eighth_read` | **B2** | the eighth read since reset onward | the downstream burst is one beat short |
| `dw_m4_fixed_single_refused_from_second` | **C3** | the second FIXED single-beat request onward | a FIXED burst of one beat is refused, where C3 says it is served |
| `dw_m5_refused_served_from_third` | **C4** | the third refused burst onward | a refused burst is served: it issues a downstream transaction and answers OKAY |
| `dw_m6_slverr_only_on_last_beat` | **C4** | the refused read is three beats or longer | SLVERR appears only on the final beat; earlier beats say OKAY |
| `dw_m7_zero_strobe_beat_dropped_midburst` | **E3** | the unstrobed beat is neither first nor last | an all-unstrobed downstream beat is suppressed instead of emitted |
| `dw_m8_strb_wrong_every_thirty_second` | **E2** | the thirty-second downstream write beat, since reset | the beat carries the complement of its strobe |
| `dw_m9_rdata_lanes_swapped_deep_in_burst` | **D1** | the fifth upstream beat of a response onward | two byte lanes of the upstream read data are exchanged |
| `dw_m10_rlast_withheld_from_sixteenth_read` | **D4** | the sixteenth read since reset onward | the final upstream beat does not carry rlast |
| `dw_m11_downstream_error_dropped_from_second` | **D6, E6** | the second downstream error since reset onward | the upstream response says OKAY where the slave returned SLVERR or DECERR |
| `dw_m12_error_code_normalised_from_second` | **D7** | the second downstream DECERR since reset onward | a downstream DECERR is reported upstream as SLVERR — an error, of the wrong kind |


## The eleventh, and why it is here

`dw_m11` was added on 2026-08-24 to close **D6 and E6** — two contract clauses
the reference exercised and no mutant was keyed on, so a submission was neither
rewarded for checking them nor penalised for ignoring them. **No mutant was
swapped out for it.** The only redundancy relation in the set is `dw_m6`'s clause
signature nesting inside `dw_m5`'s, and nesting in clause coverage is not
redundancy in discrimination: `dw_m5` fires in phase H where `dw_m6` structurally
cannot, and a submission checking only the last beat's `resp` kills `dw_m5` and
misses `dw_m6`. Neither comes out, so the set is eleven and the outlier is
documented rather than hidden.

It keys on the error the **slave returned** — `m_rresp` / `m_bresp` on the
downstream response channels — never on the SLVERR the design manufactures for a
refused burst, which never appears there at all. That separation is what keeps it
off `C4`'s ground, where `dw_m5` and `dw_m6` already live.

**D7 needed its own, and that was measured before it was written.** `dw_m11`'s
clause profile is D6 ×10 and E6 ×2 with **zero D7** — structural, not a guard
wanting tuning: this mutant *erases* the error, and a beat carrying no error
cannot test *which* error it carries. `dw_m12` leaves an error present and
changes only its **kind**, which is the disjoint behaviour D7 needs. It fires
**D7 ×5 and nothing else**.

## The twelfth, and what had to land with it

`dw_m12` exists because **an independent reading of this specification got D7
wrong**: `dut2`, written from the spec alone, forced SLVERR for any downstream
error and violated D7 the moment D7 became observable. A clause a real
independent reading got wrong is a clause submissions will get wrong.

Two things landed in the same change, because a mutant whose guard is unreachable
is a `dw_m8` repeat:

1. **Two more DECERR-injecting reads.** The run had one DECERR; a guard keyed on
   the *second* would never have fired. Three now.
2. **The read-side check was reporting a code swap as D6.** D6 is *precedence* —
   an error is due and must appear. D7 is *code preservation*. Collapsing them
   named the wrong clause for the defect and would have credited a submission
   with checking something it did not. Three outcomes now, not two.

## Non-equivalence witnesses — rule 16

The first clause failure the reference reports against each mutant. Run the set
with `./witness.sh`, which carries both rule-24 controls and **refuses** rather
than warns: a failed control exits 2 without printing witnesses. The record is in
`RULE24.md`.

| id | first clause failure |
|---|---|
| `dw_m1_len_simple_formula_when_unaligned` | FAIL [B2] B:reads, UNALIGNED -- B2 follows bytes covered: downstream arlen 7, expected 5 (bytes covered, not beat count) (t=1525) |
| `dw_m2_size_raised_when_narrow` | FAIL [B1] A:reads, aligned: downstream arsize 1, expected min(size,1)=0 (t=85) |
| `dw_m3_len_short_from_eighth_read` | FAIL [B2] A:reads, aligned: downstream arlen 2, expected 3 (bytes covered, not beat count) (t=525) |
| `dw_m4_fixed_single_refused_from_second` | FAIL [D5] C2:FIXED of ONE beat is SERVED: R beat 0 carries resp 10, expected OKAY (t=2355) |
| `dw_m5_refused_served_from_third` | FAIL [C4] C:refused reads: refused read, R beat 0 carries resp 0, expected SLVERR on EVERY beat (t=2145) |
| `dw_m6_slverr_only_on_last_beat` | FAIL [C4] C:refused reads: refused read, R beat 0 carries resp 0, expected SLVERR on EVERY beat (t=1985) |
| `dw_m7_zero_strobe_beat_dropped_midburst` | FAIL [E3] F:writes, SPARSE strobes -- E2 and E3: downstream burst has 3 beats, expected exactly 4 -- an unstrobed beat is still a beat (t=4295) |
| `dw_m8_strb_wrong_every_thirty_second` | FAIL [E2] E:writes, aligned: downstream beat 3 strb 0, expected 11 (t=4075) |
| `dw_m9_rdata_lanes_swapped_deep_in_burst` | FAIL [D1] D:long reads: R beat 4 data 8283808186878584, expected 8283808186878485 on the lanes it covers (t=2585) |
| `dw_m10_rlast_withheld_from_sixteenth_read` | FAIL [D4] A:reads, aligned: rlast is 0 on beat 2 of a 3-beat response (t=1295) |

## Two things worth knowing about this set

**`dw_m1` is the defect the specification itself carried.** B2's length rule
originally divided the byte count; the correct rule counts aligned downstream
*blocks spanned*. The two agree on every aligned request, which is why eight
measured cases in step 1 walked past it, and it took writing the reference to
find. A mutant whose provenance is a real specification error is about as direct
a difficulty argument as this set can make.

**Address-transform defects modify the request presented to the golden, not the
golden's output.** Rewriting an output would leave the golden servicing a
downstream burst inconsistent with what it computed, and it would **hang** rather
than fail — and a hang is not a detection. Modifying the input keeps the golden
self-consistent while the observable transform is wrong against the real request.

## A guard that was unreachable rather than hard

`dw_m8` survived the first run, and the reason was the guard, not the testbench.
It was keyed on a **per-burst** beat index that resets with each AW, and no burst
in the reference is thirty-two beats long, so it could never fire. A cumulative
counter now backs it. Within-transaction and since-reset are different
quantities, and keying an "every Nth" guard on the wrong one makes it silently
unreachable — which reads exactly like a hard mutant until you look.

## Step 5c, and what its number does not license

The re-derivation here is `wrapper_pointed`: the same wrapper aimed at
`dut2/dw_downsizer_alt.sv`. It is 22 of 22, and `../task.yaml` under
`policy_derivation` records why that is **not** the same claim as v_ai02's 22 of
22. The guard logic is literally the same code on both bases, so there is nothing
anchor-specific for the check to catch and the property holds by construction.
It establishes that the defects survive an implementation with different latency,
structure and scheduling. It does not establish that the guards were
stress-tested against an independent reading of the contract.
