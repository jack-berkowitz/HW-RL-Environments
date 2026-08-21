# v_nw02 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: that one satisfies the spec and must survive; these violate it
and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of the
golden shim and — where the defect is internal — of a renamed copy of the
anchor. Each edit is an exact `old -> new` string pair that the generator
asserts matches **exactly once**. A silent no-op would produce a mutant
identical to the golden that every testbench "kills" by doing nothing, so the
match count is checked rather than assumed. Nothing here is hand-written, so a
mutant cannot fail for an incidental reason unrelated to its clause.

## The set

| id | clause | defect | why a happy-path test misses it |
|---|---|---|---|
| `af_m1_budget_off_by_one` | **W2** | admits a *fifth* outstanding downstream write | the bound is only reachable by withholding W beats; ordinary traffic never approaches it |
| `af_m2_debt_frees_on_b` | **W4** | the write debt falls when a B arrives, not when a W burst completes downstream | needs B decoupled from `wlast` downstream. If the subordinate answers promptly the two events coincide and the defect is invisible |
| `af_m3_rresp_class_on_bit4` | **C2/F5** | the read-response obligation is read from `atop[4]` instead of `atop[5]` | needs *both* atomic classes. Test only atomic loads and it looks correct |
| `af_m4_rbeats_short_by_one` | **F4** | a multi-beat atomic write gets `awlen` R beats, not `awlen+1` | correct at `awlen=0`. Only a multi-beat atomic write exposes it |
| `af_m5_rlast_also_on_first` | **F4** | `rlast` on the first injected beat as well as the last | the beat *count* is right; only per-beat `rlast` checking catches it |
| `af_m6_rinject_okay` | **F4** | manufactured R beats carry OKAY — the B still carries SLVERR | a testbench that checks the B response and trusts the R beats misses it entirely |
| `af_m7_absorbed_w_forwarded` | **F2** | the W beats of a filtered write *also* reach the master port | invisible upstream. Only a master-port monitor sees the leak |
| `af_m8_stale_response_id` | **F3/F4** | manufactured responses carry the **previous** atomic write's id | needs two atomic writes with different ids. One atomic write in the whole run and it looks correct |

Seven of the eight require the testbench to build state before the defect is
reachable. `af_m6` is the one a single directed atomic load would catch, and it
is kept as the anchor of the set rather than removed.

## Non-equivalence witnesses — rule 16

`nonequiv_tb.sv` drives the golden and one mutant from a **shared** input
sequence and compares the **entire** output vector every cycle. The driver
advances a beat only once *both* sides have accepted it, so the two see an
identical input sequence and any difference in ready timing is itself a
witness — which is what the two bound mutants need.

| id | first observable difference |
|---|---|
| `af_m1_budget_off_by_one` | cycle 146 — `s_awready`: the mutant admits a write the bound forbids |
| `af_m2_debt_frees_on_b` | cycle 5 — `s_wready`: the debt is still held against a burst that completed |
| `af_m3_rresp_class_on_bit4` | cycle 11 — R beat for id=2, an atomic **store**, which owes none |
| `af_m4_rbeats_short_by_one` | cycle 59 — R burst for id=4 ends a beat early |
| `af_m5_rlast_also_on_first` | cycle 57 — golden `last=0`, mutant `last=1`, on the first beat |
| `af_m6_rinject_okay` | cycle 34 — R beat for id=3: golden `resp=10`, mutant `resp=00` |
| `af_m7_absorbed_w_forwarded` | cycle 11 — master W valid=1 where the golden has 0 |
| `af_m8_stale_response_id` | cycle 12 — B id=0 where the golden gives id=2 |

**The witness harness was wrong twice before it could witness anything, and
both defects were its own.**

It first compared the raw output vector, unqualified. AXI payload while `valid`
is low is not observable by anything, and `af_m4` perturbs an AW field on a
channel it never asserts — so the harness "witnessed" a phantom `m_awlen`
difference instead of the missing R beat that the mutant actually causes. The
comparison is now masked by each channel's own `valid`.

It also deadlocked on every mutant. Once two sides diverge in ready timing the
shared driver waits for both to accept and neither moves; all eight reports
came back as watchdog messages that never printed *what* differed. It now
reports and stops as soon as a difference is latched.

Both are the same failure in different clothes: **"no difference observed" is a
claim about the harness until the harness has been shown able to see the
difference.**

## Reference testbench ceiling

**8 of 8.** Report a submission's kills against that ceiling, never as a bare
fraction.

The evidence behind this number is stronger than a raw 8/8 usually is, because
the mutants were checked against a *second, independent* base — see
`check_policy_independence.sh` and NOTES.md §5c. It is still weaker than it
looks in one specific way: one author wrote the spec, the mutants and the
reference testbench. The set has not yet been challenged by anything its author
did not anticipate. The first blind submission is the real test of the set.
