# v_ca04 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: that one satisfies the spec and must survive; these violate it
and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of the
golden shim, with each edit asserted to match **exactly once**. Three are pure
parameter changes on the arbiter — that is the honest way to build an
arbitration defect, because a hand-written faulty crossbar fails for incidental
reasons and isolates nothing.

## The set

| id | clause | defect | why a beat through an idle crossbar misses it |
|---|---|---|---|
| `xb_m1_fixed_priority` | **A2** | fixed priority instead of round robin | needs several inputs contending at once; with one input offering it is perfect |
| `xb_m2_marginal_starvation` | **A2** | every input *is* eventually served — the rotation just advances every 64 cycles | a testbench that checks "each input is served eventually" passes it. Only the **window** catches it |
| `xb_m3_idx_off_by_one` | **R3** | `out_idx_o` names the input one place along | only catchable if the true source is known independently of what the design claims |
| `xb_m4_sel_top_bit_dropped` | **R1** | the top selector bit is ignored | outputs 0 and 1 behave perfectly. Only traffic bound for 2 or 3 exposes it |
| `xb_m5_lockin_off` | **A3** | an offered beat can be re-aimed before it moves | needs an output **stalled**, *and* the input already being offered to outrank the one that arrives. Get that order wrong and nothing happens |
| `xb_m6_duplicate_delivery` | **R1/R4** | the core advances on every second acceptance, so each beat is delivered twice | needs the input side monitored, not just the output side |
| `xb_m7_payload_from_neighbour` | **R2** | each input's payload comes from the next input along | `out_idx_o` is right and the beat count is right; only the payload is wrong |
| `xb_m8_head_of_line` | **I2** | no input is accepted unless *every* output is ready | invisible while all outputs are ready. Needs one stalled and traffic bound elsewhere |

## Non-equivalence witnesses — rule 16

`nonequiv_tb.sv` drives the golden and one mutant from a shared input sequence
and compares their observable outputs every cycle. Payload is masked by its own
`valid`, and `in_ready_o` by `in_valid_i`, because clause H3 says a ready bit
carries no meaning while its input is not offering.

| id | first observable difference |
|---|---|
| `xb_m1_fixed_priority` | cycle 2 — output 0 serves input 0 again where the golden serves input 1 |
| `xb_m2_marginal_starvation` | cycle 2 — same first symptom; the two differ from each other only later |
| `xb_m3_idx_off_by_one` | cycle 1 — same payload, `idx` 0 against 1 |
| `xb_m4_sel_top_bit_dropped` | cycle 42 — `out_valid_o` 1111 against 0011 |
| `xb_m5_lockin_off` | cycle 185 — the golden holds input 3's beat, the mutant re-aims to input 1 |
| `xb_m6_duplicate_delivery` | cycle 1 — `in_ready_o` 0001 against 0000 |
| `xb_m7_payload_from_neighbour` | cycle 1 — `idx` identical, payload `5a000000` against `5a100000` |
| `xb_m8_head_of_line` | cycle 43 — `in_ready_o` 1110 against 0000 |

**`xb_m5` reported NO DIFFERENCE OBSERVED on the first run**, and the harness was
the thing at fault. Nothing in the stimulus varied the set of contenders while
an output was stalled, and that is the only situation in which an unlocked
decision can be seen to change. A phase that brings a new contender in mid-stall
was added; the mutant differs at cycle 185. *"No difference observed" is a claim
about the harness until the harness has been shown able to see the difference.*

## Reference testbench ceiling

**8 of 8**, and `xb_m5` was earned twice over: after the witness harness was
fixed, the **reference testbench still passed it**. Instrumenting rather than
guessing showed why — an unlocked arbiter only re-aims when the input already
being offered outranks the one arriving, so a probe that brings contenders in
from the lowest index up watches the right signals and sees nothing. The probe
now brings them in from the highest index **down**, on every output in turn.

The set was checked against a **second, independent base**: all eight defects
re-derived on the policy-divergent implementation and re-run, 18 of 18 verdicts
matching. See `check_policy_independence.sh` and NOTES.md §5c.
