# v_nw01 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: that one satisfies the spec and must survive; these violate it
and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of the
golden shim and — where the defect is internal — of a renamed copy of the
anchor. Each edit is an exact `old -> new` pair asserted to match **exactly
once**. Four are pure changes to the pinned timers and the subnet mask: that is
the honest way to build a retry or routing defect, because a hand-written faulty
engine fails for incidental reasons and isolates nothing.

## The set

| id | clause | defect | why one successful lookup misses it |
|---|---|---|---|
| `ae_m1_one_retry_short` | **Q4** | three request frames are sent, not four | needs a lookup deliberately left unanswered, and the frames *counted* |
| `ae_m2_retry_interval_long` | **Q4** | requests are 96 cycles apart, not 64 | needs the *spacing between* frames measured, not just their number |
| `ae_m3_timeout_short` | **Q5** | gives up 128 cycles after the last request, not 256 | needs the interval from the final request to the error timed |
| `ae_m4_subnet_ignored` | **Q3** | every address looks local, so an off-subnet lookup asks for the target | every in-subnet lookup behaves perfectly; only an address outside the subnet exposes it |
| `ae_m5_replies_not_learned` | **C1** | only requests are learned from; a reply teaches nothing | needs a reply distinguished from a request *as a source of learning* |
| `ae_m6_answers_any_target` | **A2** | a request for somebody else's address is answered too | needs a frame aimed at a station that is not us |
| `ae_m7_reply_target_is_us` | **A1** | the reply names our own address as its target | the reply is sent, to the right station, with the right operation — only one field is wrong |
| `ae_m8_ethtype_ignored` | **A3** | a frame that is not ARP is processed anyway | needs a frame with a non-ARP ethertype, which a testbench that only speaks ARP never sends |

None falls to a single successful lookup, and three cannot be seen at all
without leaving a lookup unanswered for hundreds of cycles.

## Witnesses

Each mutant's first failure under the reference testbench, which names the
clause and the measurement:

| id | first failure |
|---|---|
| `ae_m1_one_retry_short` | `Q4: an unanswered lookup transmitted 3 request(s); exactly 4 are required` |
| `ae_m2_retry_interval_long` | `Q4: requests 0 and 1 are 97 cycles apart; the window is 64..80` |
| `ae_m3_timeout_short` | `Q5: gave up 128 cycles after the last request; the window is 256..300` |
| `ae_m4_subnet_ignored` | `Q3: asked for 08080808, expected c0a801fe` |
| `ae_m5_replies_not_learned` | `Q6: a matching reply did not resolve the lookup` |
| `ae_m6_answers_any_target` | `A2: a request for somebody else's address produced 1 frame(s)` |
| `ae_m7_reply_target_is_us` | `A1: reply TPA c0a80101, expected the requester's SPA c0a80107` |
| `ae_m8_ethtype_ignored` | `A3: a frame with eth_type 0800 produced 1 frame(s); it must be ignored` |

The generator's uniqueness assertion earned its place here: `m7`'s target
assignment appears **twice** in the anchor, once on the ARP path and once on the
InARP path, and the run stopped rather than silently mutating both.

## Reference testbench ceiling

**8 of 8**, checked against a second, independent base: all eight defects
re-derived on the policy-divergent engine and re-run, 18 of 18 verdicts
matching, both clean implementations passing. See
`check_policy_independence.sh` and NOTES.md.
