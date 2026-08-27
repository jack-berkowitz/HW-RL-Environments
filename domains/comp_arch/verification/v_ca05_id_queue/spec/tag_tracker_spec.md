# `tag_tracker` — specification

**Pilot revision history is at the bottom of this file. It is the deliverable.**

A capacity-bounded store of `(tag, payload)` entries supporting three concurrent
access paths: insertion, content-addressed search, and tag-ordered removal.

Ships with the port map and this document. **No RTL is shipped.**

---

## 0. Parameters

| name | meaning |
|---|---|
| `TAG_W` | width of a tag; tags range over `[0, 2**TAG_W)` |
| `SLOTS` | total entries storable across all tags |
| `N_MATCH` | number of independent search ports |
| `payload_t` | payload type |
| `FULL_RATE` | when 1, push and pop of the same tag may complete in the same cycle |
| `CUT_POP_PATH` | when 1, `push_gnt_o` does not depend combinationally on `pop_req_i` |

**Authority:** parameter names and widths are fixed by the shipped port map.

---

## 1. Storage and ordering

**R1 — capacity.** The design shall accept `SLOTS` entries. Entries are shared
across tags: any distribution summing to `SLOTS` shall be accepted, including
`SLOTS` entries all carrying the same tag.
*Authority: task intent — capacity is the property under test.*

**R2 — per-tag FIFO order.** For a given tag, entries shall be removed in the
order they were inserted.
*Authority: task intent.*

*R8 requires that `pop_data_o` carry **the oldest entry for that tag**, which is
this clause restated as an output requirement, so a violation of R2 is
**reported under R8**. A submission that checks R8 is credited with this clause;
that is deliberate and recorded here so it is visible rather than discovered
from a failure message.*

**R3 — no cross-tag ordering.** Order between entries of *different* tags is
**not specified** and shall not be checked.
*Authority: rule 12 — a design may store entries in any structure it likes; only
per-tag order is a contract term.*

---

## 2. Push

**R4.** A push is requested with `push_req_i`, carrying `push_tag_i` and
`push_data_i`. The entry is committed on a cycle where `push_req_i && push_gnt_o`.
*Authority: standard ready/valid handshake.*

**R5.** `push_gnt_o` shall be low when the store holds `SLOTS` entries.
*Authority: follows from R1.*

**R6.** `push_gnt_o` may be low for reasons other than fullness — port conflict,
internal arbitration. A testbench shall not require `push_gnt_o` to be high
merely because space exists.
*Authority: rule 12 — arbitration policy is deliberately unconstrained.*

---

## 3. Pop

**R7.** A pop is requested with `pop_req_i` and `pop_tag_i`. It completes on a
cycle where `pop_req_i && pop_gnt_o`.

**R8.** On a completing pop, `pop_data_valid_o` shall be high if at least one
entry with `pop_tag_i` is present, and low otherwise. When high, `pop_data_o`
shall carry the oldest entry for that tag (R2).

**R9.** `pop_en_i` selects removal. When `pop_en_i` is high on a completing pop
with `pop_data_valid_o` high, the entry is removed. When `pop_en_i` is low, the
entry is inspected and **not** removed.
*Authority: task intent — peek and pop are distinct operations.*

*An entry wrongly removed by a peek, or wrongly kept by a pop, is observable
only on the NEXT pop of that tag — as a `pop_data_valid_o` or `pop_data_o` that
disagrees with the store — so a violation of this clause is **reported under
R8**. A submission that checks R8 is credited with this clause; that is
deliberate and recorded here so it is visible rather than discovered from a
failure message.*

**R10.** A pop of a tag with no entries shall complete with `pop_data_valid_o`
low. It is not an error. **`pop_data_o` IS FREE when `pop_data_valid_o` is
low** — any value it carries satisfies this clause, so no expectation is placed
on it.
*Authority: rule 12 — no value is more correct than another for an absent entry.*

*This clause's whole checkable content is the `pop_data_valid_o` half — the
`pop_data_o` half is free, per the sentence above — and that half is exactly
what R8 states for the absent case, so a violation of R10 is
**reported under R8**. A submission that checks
R8 is credited with this clause; that is deliberate and recorded here so it is
visible rather than discovered from a failure message.*

---

## 4. Search

**R11.** Search port `k` is requested with `match_req_i[k]`, carrying
`match_data_i[k]` and `match_mask_i[k]`. It completes on a cycle where
`match_req_i[k] && match_gnt_o[k]`.

**R12.** On a completing search, `match_hit_o[k]` shall be high if and only if
the store holds at least one entry whose payload satisfies

```
(payload & match_mask_i[k]) == (match_data_i[k] & match_mask_i[k])
```

**Search is over payloads across all tags; it does not filter by tag.**
*Authority: task intent — this is a content-addressed lookup.*

**R13.** A mask of all zeros matches every stored entry, so `match_hit_o[k]`
shall be high whenever the store is non-empty.
*Authority: follows from R12 as written.*

*The all-zero mask is one input to R12's if-and-only-if, not a separate rule:
R13 follows from R12 as written, so a violation of R13 is a violation of R12
on that input and is **reported under R12**. A submission that checks R12 is
credited with this clause; that is deliberate and recorded here so it is visible
rather than discovered from a failure message.*

---

## 5. Status

**R14.** `empty_o` shall be high exactly when the store holds zero entries.
`full_o` shall be high exactly when it holds `SLOTS`.
*Authority: task intent.*

---

## 6. Reset

**R15.** While `rst_ni` is low the store shall be emptied; after release,
`empty_o` shall be high and `full_o` low.
*Authority: standard synchronous-reset-active-low convention, fixed by the port
map's `rst_ni`.*

---

## 7. Named latitude (rule 12)

The following are **explicitly out of scope** and shall not be checked:

1. **Arbitration policy** between push, pop and search in one cycle.
2. **Cross-tag ordering** (R3).
3. **`pop_data_o` when `pop_data_valid_o` is low** (R10).
4. **Combinational-vs-registered timing** of any output within its cycle, beyond
   what `CUT_POP_PATH` states.
5. **Internal structure** — linked list, per-tag FIFOs, CAM, anything.
6. **Latency**: the number of cycles between request and grant is unconstrained.

---

## 8. Revision history — THE PILOT RESULT

**Spec revisions required: 0. Testbench revisions required: 1.**
**The 0 is not trustworthy, and the reason is recorded below.**

### Round 1 — FAIL, and the cause was the testbench

Every stored-state check failed: `empty_o` high with entries outstanding, `full_o`
never asserting, pops returning nothing. The store looked completely inert.

**Not a spec defect and not a DUT defect.** The testbench deasserted `push_req_i`
in the same timestep as the `@(posedge clk)` it had just waited on, so the DUT
sampled the request already withdrawn. A one-cycle pulse committed nothing; a
held request committed every cycle. Isolated by instrumenting the free-list
directly rather than re-reading the driver code.

### Round 2 — PASS

1273 checks, 0 failures, no change to this document.

### Why 0 spec revisions does not mean the spec bar is met

**The author of this document had already read the RTL.** `dut/tag_tracker.sv` is
a decontaminated `id_queue` produced during v_ca05 step 1 — renaming every
identifier requires reading all of it. A spec written from that position
pre-empts exactly the gaps the pilot exists to count, so a pass is the expected
outcome whether or not the spec is adequate.

The inference is therefore **one-sided**: a high revision count would have been a
real result, and a zero is uninformative.

### What the latitude clauses were absorbing — the measurable part

Probing the assumptions a blind reader would plausibly make instead
(`sim/naive_tb.sv`) shows **three clauses in this document are load-bearing**,
and every one was written from RTL knowledge:

| clause | what it licenses | without it |
|---|---|---|
| **R4** | commit requires `push_req_i && push_gnt_o` | `push_gnt_o` is **high with no request pending** — it is a space-available flag, not an acknowledgement. A testbench treating grant as an ack records phantom pushes and its scoreboard diverges immediately. |
| **R10** | pop of an absent tag **completes**, `pop_data_valid_o` low | the DUT **does** grant it. A testbench treating grant-with-valid-low as a protocol violation fails the golden DUT — a correct testbench failing the validity gate, which is precisely the failure mode the pilot was commissioned to look for. |
| **R3** | no cross-tag ordering | a testbench assuming one global FIFO fails on legal behaviour. |

Two further assumptions were probed and **held**: `match_gnt_o` does not
free-run, and `pop_data_o` reads zero rather than stale when invalid. Neither is
promised by this document, so both are latent — a design change could break a
testbench that relies on them without violating any requirement written here.

### The conclusion this pilot supports

**Not** "a spec-only verification task works." It supports the narrower claim
that **the spec bar is set by a small number of identifiable clauses**, three of
which are named above, and that those clauses are not ones a spec author
naturally writes — they are answers to questions you only know to ask after
seeing the implementation.

A clean measurement needs a spec author who has not read the RTL, or a module
nobody here has read. Until then the honest statement is: *this spec passes
because its author knew what to pin.*
