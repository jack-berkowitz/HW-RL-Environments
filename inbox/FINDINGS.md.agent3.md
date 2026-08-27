
<!-- author: agent3 -->
## Capacity FLOORS get controls; capacity CEILINGS get written and forgotten

**Four instances, three found by sweeping for them once the pattern was named.**

| task | clause | the ceiling | checked |
|---|---|---|---|
| `d_nw01` | C3 | at most 4 R and 4 W beats per master port | **no** — 0 mentions in tb |
| `d_ca01` | C4 | at most 2 cache lines outside the arrays, 1 word per miss | **no** — 0 mentions |
| `d_ca04` | B1 | at most 4 further beats of storage across both domains | **no** — 0 mentions |
| `d_nw03` | B1 | over-buffering bound | **yes** — `nc_h_overbuffered` dies at 72 beats |

Against that, the **floors** in the same corpus are all enforced: d_ca03's P2
pins 16+16 TLB entries and `nc_g_itlb_one_entry` fails at one entry; d_nw01's C1
requires a minimum outstanding count and fails below it; d_ca04's C4 requires a
minimum accepted-with-reader-stopped.

**Why the asymmetry is structural, not accidental.** A floor is violated by a
design that does LESS, and doing less shows up as a behaviour the harness
already drives — fewer outstanding misses, a shallower queue, a slower rate. The
check falls out of the stimulus. A ceiling is violated by a design that does
MORE, and doing more is invisible from the delivered surface: a crossbar holding
sixteen beats per port answers every request correctly. Catching it needs a
measurement of internal state or a control built for it, and neither arrives for
free.

**So a ceiling is normative text that grades nothing.** All three unchecked ones
say so in strong terms — *"Storage beyond that is NON-CONFORMING, not a design
choice"* — and a submission that violates them passes with a clean sheet.

### d_ca04's B1 is the instructive one

Its testbench tracks occupancy and marks it **COVERAGE ONLY, never an
assertion**, giving the reason: sampled on `wr_clk` it sees a stale `rd_idx` and
OVERSTATES occupancy, so a bound asserted on it would fail conforming designs.
Someone hit the measurement problem, correctly declined to assert on a bad
measurement, and wrote down why.

That is the right call and it is still a hole. **A clause left unenforced for a
stated good reason is indistinguishable, from the results, from one left
unenforced by oversight** — both produce a passing submission that violates the
spec, and the results carry no trace of which. The honesty lives in the
testbench comment; it does not reach anything that reads the scores.

**These need controls, not annotations.** An annotation records where a clause is
reported; there is nothing to record when nothing reports it. The spec text now
says so in each of the three, which is disclosure, not enforcement.
