# candidates/ — where model answers go

One layout: `candidates/<task_id>/<label>.sv`, one directory per task.

| layout | for | example |
|---|---|---|
| `candidates/<task_id>/<label>.sv` | the `domains/` tasks | `candidates/d_nw01/chat.sv` |

## Putting an answer in

One file per attempt, named however you like — the filename is just a label in
the report, so use it to record what produced it:

```
candidates/d_nw01/chat.sv
candidates/d_nw01/opus5_t0.sv
candidates/d_ca04/chat.sv
```

The file must contain **only** the module, declaring the exact name from the
task's `spec/*_iface.sv` — `int8_requant`, `axis_width_adapter`. Strip any
markdown fences the model emitted. Do not add the checker, the reference, or a
second module; the candidate replaces the DUT entirely.

## Running them

One answer:

```bash
./scripts/sim_candidate.sh d_nw01 candidates/d_nw01/chat.sv
```

Every answer for a task, with a pass-rate summary — this is the one that
answers "are these hard enough":

```bash
./scripts/sim_candidate.sh d_ca04 candidates/d_ca04
```

A task id (`d_ca04`) resolves to its directory under `domains/`; a full path
still works. Add `icarus` to run the other simulator, `--smoke` for one config
instead of the full sweep.

## What counts as passing

**Every legal config, zero coverage holes.** 16 configs for `d_nw01`
(`NUM_MST`×`NUM_SLV`×`MAX_TRANS`×`MAX_BURST_LEN`); 18 for `d_ca04`. A candidate that passes one
config and fails another has not solved the task, and a run that reports PASS
while printing `// COVERAGE HOLE:` never reached the states that matter.

Two things are rejected before simulation, and both count as a failed attempt
rather than a broken harness: a candidate that prints its own `TEST_RESULT`
line (forged verdict), and one that declares the wrong module name.

## Are these committed?

The tier-based ones are, so the new ones follow suit — a candidate that
provoked an interesting failure is worth keeping next to the task it broke.
Raw sweep output is different: `results/*.jsonl` is gitignored precisely
because it carries full model responses and churns.
