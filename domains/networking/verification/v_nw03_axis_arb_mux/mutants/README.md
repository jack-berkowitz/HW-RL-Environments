# v_nw03 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: those satisfy the spec and must survive; these violate it and
must be caught.

Five wrap the unmodified golden. `fm_m2` instantiates the same vendored anchor
the golden wraps, with one parameter changed. None reimplements the design — a
hand-written faulty mux fails for incidental reasons and isolates nothing.

## The set

| id | class | defect | violates |
|---|---|---|---|
| `fm_m1` | **capability** | tdata above bit 15 silently dropped — behaves as though `DATA_WIDTH` were 16 | S4 |
| `fm_m2` | starvation | fixed priority instead of rotation; low-priority inputs never served | S10 |
| `fm_m3` | atomicity | two half-muxes with a beat-level mux between them; frames interleave | S3 |
| `fm_m4` | sideband | tuser taken from the neighbouring input | S4 |
| `fm_m5` | boundary | tlast also asserted on the first beat of every multi-beat frame | S4 |
| `fm_m6` | reset | golden never sees `rst_i`; beats held at reset survive it | S12 |

`fm_m1` is the CAPABILITY-class member: correct on every handshake, every frame
boundary and every arbitration decision, while silently supporting half the
declared width. It is the class that motivated the benchmark, and the one a
testbench misses by comparing only the bits it used to identify the beat.

`fm_m2` is the fault S13 exists for. A testbench that waits for a beat from
input 3 with no watchdog does not detect it — it hangs, and `HUNG` is its own
verdict, not a catch.

## Non-equivalence witnesses

`nonequiv_tb.sv` drives the golden and the mutant from identical input streams
and reports the first output beat at which the full record
`{tdata, tkeep, tuser, tlast}`, or the cycle of transfer, differs.

| id | witness (first differing beat) |
|---|---|
| `fm_m1` | beat 0: golden `1443000036`, mutant `0000000036` — high payload gone |
| `fm_m2` | beat 5: golden `1d9c80004e`, mutant `3c46801418` — a different input served |
| `fm_m3` | beat 0: golden `1443000036`, mutant `07fc0000a6` |
| `fm_m4` | beat 4: golden `3c33001031`, mutant `3c33001033` — tuser bit only |
| `fm_m5` | beat 0: golden `1443000036`, mutant `1443000037` — tlast bit only |
| `fm_m6` | beat 101, immediately after the mid-stream reset |

**The witness harness needed two fixes before it could witness anything, and
both were its own defects rather than the wrappers'.** It originally compared
only tdata and tlast, so `fm_m4` — which changes nothing but tuser — reported
*"NO DIFFERENCE OBSERVED, this wrapper may be a no-op"*. And it never asserted
reset mid-stream, so `fm_m6` had nothing to violate and its witness was an
incidental one-cycle artefact. A control that cannot see the thing it is
controlling for reports the reassuring answer.

## Isolation — which clause each mutant trips

Measured by running the reference testbench against each mutant and collecting
every clause that failed, with no print cap.

| id | first failure | all clauses tripped |
|---|---|---|
| `fm_m1` | S4 | S4 |
| `fm_m2` | S10 | S10 |
| `fm_m3` | **S3** | **S3, then S10 later** |
| `fm_m4` | S4 | S4 |
| `fm_m5` | S4 | S4 |
| `fm_m6` | S12 | S12 |

Five of six trip exactly one clause. **`fm_m3` trips S3 first and S10 later**,
and that is one defect with two symptoms rather than a second defect: sustained
interleaving changes which inputs start frames and when, so the fairness counter
eventually runs out too. Recorded rather than described as clean isolation.

`fm_m6` required a change to the reference testbench to attribute correctly. It
first reported as S3/S4/S5 — a stale beat surviving reset misaligns the whole
stream, so the payload comparison fires before anything reset-specific does. The
checker now retains the beats it discarded at reset and recognises one when it
reappears, so the diagnosis names S12, which is the clause actually violated.
Attribution matters: a scorer reading "payload mismatch" would look for a data
defect and never reach the reset.

## Reference testbench ceiling

**6 of 6.** Report a submission's kills against that ceiling, never as a bare
fraction.

**The ceiling is weaker evidence here than the same number was on `v_ca05`.**
There, the mutant set found two genuine holes in the reference testbench on
first use, and the 6/6 was earned by fixing them. Here the reference testbench
killed all six on its first run — the mutants did *not* do their job on the
reference, because the same author wrote the spec, the checker and the mutants
in one sitting and every mutant targets a clause the checker was already built
around. What the two testbenches actually did find were defects in the witness
harness and in the checker's clause attribution, both recorded above.

The honest statement is: 6/6 is the ceiling, and the set has not yet been
challenged by anything its author did not anticipate. The first submission is
the real test of the set.
