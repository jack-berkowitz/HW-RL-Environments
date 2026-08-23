# v_nw03 mutant set — these MUST BE CAUGHT

Each mutant wraps the unmodified golden and injects exactly one defect.

## Every defect in this set is GUARDED

    defect := wrong_behaviour AND rare_predicate over contract-level state

The guards name which frame it is, how deep into that frame, how many inputs are
contending in the same cycle, and how many resets have completed — all counted
from the port handshakes, so each can be restated against an independent design.

`fm_m2` is the clearest change of shape. It used to be the anchor rebuilt with
fixed priority, which starves the low inputs on *every* contended cycle. It now
leaves the anchor round-robin and imposes priority **only while three or more
inputs are offering at once** — under two-way contention the rotation is
untouched and every fairness check passes.

## The set

| id | clause | guard — fires only when… | defect |
|---|---|---|---|
| `fm_m1_drops_high_payload` | **S4** | the fifth frame forwarded, and every one after it | the top half of tdata is zeroed |
| `fm_m2_priority_arbitration` | **S10** | three or more inputs are offering in the same cycle | fixed priority replaces the rotation -- two-way contention is still fair |
| `fm_m3_frame_interleaved` | **S3** | the fifth frame onward, at its third beat or later | an in-progress frame is re-aimed at the other half of the inputs |
| `fm_m4_tuser_crossed` | **S4** | the fifth frame onward | tuser is taken from the next input along |
| `fm_m5_early_tlast` | **S4** | the third frame onward | tlast is also asserted on a frame's FIRST beat |
| `fm_m6_reset_ignored` | **S12** | the SECOND reset, and every one after it | rst_i does not reach the design |
| `fm_m7_tuser_wrong_on_last` | **S4** | the final beat of a frame four beats or longer | tuser is inverted there |
| `fm_m8_tkeep_full_on_last` | **S4** | the final beat of a frame four beats or longer | tkeep is forced to all ones |
| `fm_m9_marginal_starvation` | **S10** | a 300-cycle window out of every 320 | the last input is not admitted -- it is served in the remaining 20 |
| `fm_m10_deep_beat_corruption` | **S4** | the fourth beat onward of a frame, from the fifth frame | one payload bit is flipped |

## Witnesses — rule 21

| id | first clause failure |
|---|---|
| `fm_m1_drops_high_payload` | FAIL [S4] input 0 tdata: expected ab750060 got 00000060 (t=225000) |
| `fm_m2_priority_arbitration` | FAIL [S10] input 1 has started no frame in 109 completed output frames (window 16) (t=2835000) |
| `fm_m3_frame_interleaved` | FAIL [S3] mid-frame switch: frame from input 3 interrupted by input 1 (t=395000) |
| `fm_m4_tuser_crossed` | FAIL [S4] input 1 tuser: expected 1 got 0 (t=265000) |
| `fm_m5_early_tlast` | FAIL [S4] input 2 tlast: expected 0 got 1 (t=135000) |
| `fm_m6_reset_ignored` | FAIL [S12] m_tvalid_o high on the first cycle after reset release (t=20175000) |
| `fm_m7_tuser_wrong_on_last` | FAIL [S4] input 0 tuser: expected 0 got 1 (t=105000) |
| `fm_m8_tkeep_full_on_last` | FAIL [S4] input 2 tkeep: expected c got f (t=165000) |
| `fm_m9_marginal_starvation` | FAIL [S10] input 3 has started no frame in 113 completed output frames (window 16) (t=2695000) |
| `fm_m10_deep_beat_corruption` | FAIL [S4] input 0 tdata: expected d5ca0090 got e9ba0060 (t=285000) |

## A guard that was measured before it was kept

`fm_m3` was first keyed on the **fifth beat of a frame**: an in-progress frame
could be re-aimed only that deep in. It survived, and the obvious reading —
"the reference's frames are too short" — was wrong.

Instrumenting the mutant under the reference showed the fifth beat was reached
**112 times**, with both halves of the inputs valid on 1827 beats, and **zero
mid-frame switches**. The depth was reachable; the switch was not. The guard was
re-keyed onto frame ordinal plus beat depth, which the reference provably
reaches.

Guessing at why a mutant survives is cheap and usually wrong. Two builds of
instrumentation settled it.

The reference's frames were also all one to five beats, so S3 atomicity was only
ever checked on short frames. It now drives six-to-ten-beat frames under full
contention with mid-frame backpressure.
