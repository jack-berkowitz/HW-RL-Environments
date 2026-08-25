# A model that builds the cache correctly and returns the wrong word

**Case study — `d_ca01_nonblocking_dcache`, clauses R3 / R5.**
Recorded by AGENT-DESIGN-43a92055. Reproduced from the committed tree.

The second functional failure this benchmark has produced from a solicited
frontier model. It is written up in the same shape as the `d_ca03` T10 case, and
**the most useful thing about it is where the two differ.**

---

## The result

    chat.sv      PASS   16/16
    claude.sv    PASS   16/16
    gemini.sv    FAIL    0/16   -> "phase 7: R3/R5: a LOAD returned the wrong
                                    value for its id"

**Every configuration.** All sixteen: `DATA_W {32,64}` × `SETS {8,16}` ×
`WAYS {2,4}` × `MAX_MISSES {2,8}`.

## One check, and only one

The failure is narrow in a way that is worth stating precisely, because it says
what the design got *right*. Phase 7 runs nine checks. `gemini` fails exactly one
of them and passes the other eight:

| check | clause | `gemini` |
|---|---|---|
| every accepted request is answered | R3 | **passes** |
| **a LOAD returns the addressed word** | **R3/R5** | **FAILS** |
| no response for an id with nothing outstanding | R3 | passes |
| no two requests in flight under one id | R6 | passes |
| memory addresses block-aligned | M1 | passes |
| memory transactions carry `BLOCK_WORDS` beats | M1/M2 | passes |
| no memory request while a transaction is in flight | M3 | passes |
| writeback blocks match architectural state | M2 | passes |

So this is not a design that fell over. **It accepts requests, tracks them,
answers every one exactly once with the right id, keeps its memory-side protocol
clean, and writes back correct data.** The miss machinery works. What it returns
to the requester is wrong.

That combination is the interesting part: **every structural clause holds and the
data clause does not.** A design that were merely broken would fail M1 or M3 or
the response count too. This one is architecturally coherent and arithmetically
wrong, which is the failure mode hardest to catch by inspection and easiest to
catch with a scoreboard.

## What is wrong — and what is not claimed

The response path is:

```systemverilog
assign rsp_data_o = req_q[best_done_id].rsp_data;                        // :262
...
req_q[best_issue_id].rsp_data <= next_data_array_line[issue_word*DATA_W +: DATA_W];  // :362
```

The word is captured from `next_data_array_line` — a combinational *next*-state
view of the data array — at issue time, rather than from committed array state.
Two places are worth a reader's attention: that capture, and the fill path where
`mem_fill_data` is assembled beat by beat (`:338`) and committed a cycle later
(`:348`).

**I am not asserting which of those is the defect.** Localising it would need a
waveform and a minimal reproducer, and neither has been built. **The measured
claim is the table above**, which does not depend on the diagnosis: one check
fails, eight pass, at all sixteen configurations. Naming a line without the
reproducer is how three earlier accusations in this repository turned out to be
wrong.

---

## Provenance — and the answer is no

**Was this failure reachable only because of a clause a second source or a
frozen-input find produced? No. Plainly no.**

Both clauses carry `AUTHORITY: stated task intent` and are foundational:

> **R3.** Every accepted request produces exactly one response, tagged with that
> request's `req_id_i`. For a LOAD, `rsp_data_o` is the addressed word.
>
> **R5.** Requests to the same word are ordered by the order in which they were
> accepted. A LOAD accepted after a STORE to the same word returns that stored
> value.

Checked against the history rather than asserted:

    the readback sweep (the stimulus)   9cb3360   08-17 22:39
    sb_data_err (the check)             9cb3360   08-17 22:39
                                        "shim and scoring testbench;
                                         reference passes 16/16"

**Both arrived in the first commit of the testbench.** The scoreboard that caught
`gemini` is the one that was written before any mutant, any control, any second
source and any frozen-input sweep existed. `d_ca01`'s second source *did* produce
two harness repairs — both were preconditions for the C1 and C2 stall phases, and
neither touched phase 7.

**So this is an ordinary catch, and saying otherwise would be inventing a lineage
for it.** Any competent scoreboard over this contract would have found it.

## Why that makes it worth recording, not less

Set beside `d_ca03`'s T10:

| | `d_ca03` T10 | `d_ca01` R3/R5 |
|---|---|---|
| clause existed from the start | no — A10 did, but was unexercised | yes |
| needed a frozen-input find | **yes** — `asid_i` at constant zero | no |
| needed an instrument off the scored surface | **yes** — reads `mem_*` | no |
| would an ordinary scoreboard catch it | **no** — same address either way | **yes** |
| caught | claude | gemini |

**A benchmark needs both, and the ratio is the diagnostic.** If every failure
looked like T10, the suite would be measuring exotica — clauses so obscure that
only apparatus archaeology reaches them, and a model could be excellent and still
lose. If every failure looked like R3/R5, the suite would be measuring what any
testbench already catches, and the apparatus work would be overhead.

Two failures, one of each kind, from three models on two tasks. **That is the
first evidence that the difficulty is distributed rather than concentrated at
either end** — and it is one observation, not a rate. Nine design tasks exist and
two have candidate verdicts through the scored path.

The honest summary of what T10 bought: **not that hard clauses are where models
fail, but that a clause can be unenforced without looking unenforced.** R3/R5 is
the control for that claim. It shows the ordinary path still works, so T10's
result cannot be dismissed as an artefact of a strange instrument — and equally,
T10 shows R3/R5's result cannot be generalised into "the obvious checks are
enough".

---

## What this does not say about `gemini`

`gemini` also fails `d_ca03` (rejected by the synthesis frontend) and `d_dsp02`
(vector 0 arithmetic on a subnormal). **Three failures on three tasks is not a
ranking.** These are single attempts at a fixed prompt with no retry, no
scaffolding and no iteration, and the sample is one submission per model per
task. What can be said is what was measured: on `d_ca01`, `gemini` produced a
structurally sound non-blocking cache whose loads return the wrong data, at every
configuration, and the other two models did not.

---

## Provenance

* Clause text: `spec/nonblocking_dcache_iface.sv`, R3 at line 147, R5 at 184.
* Check: `tb/nonblocking_dcache_tb.sv:665`, phase 7.
* Verdicts reproduced with
  `scripts/sim_candidate.sh d_ca01 candidates/d_ca01/<model>.sv verilator`.
* Run at `task_text_hash` `51337b00b54b64c7` — after R1b landed. R1b changes no
  behaviour required of a submission, and these three verdicts are unchanged
  across that boundary.
