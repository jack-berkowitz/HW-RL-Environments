# candidates/ — where model answers go

Two layouts live here, because the repo is mid-migration.

| layout | for | example |
|---|---|---|
| `candidates/<tier>/<module>.sv` | the **old** tier-based tasks, driven by `runner/` | `candidates/TierOne/fifo.sv` |
| `candidates/<task_id>/<label>.sv` | the **new** `domains/` tasks | `candidates/ai_d01/opus5_run1.sv` |

## Putting an answer in

One file per attempt, named however you like — the filename is just a label in
the report, so use it to record what produced it:

```
candidates/ai_d01/opus5_t0.sv
candidates/ai_d01/opus5_t1_retry.sv
candidates/ai_d01/sonnet5_t0.sv
candidates/nw_d01/opus5_t0.sv
```

The file must contain **only** the module, declaring the exact name from the
task's `spec/*_iface.sv` — `int8_requant`, `axis_width_adapter`. Strip any
markdown fences the model emitted. Do not add the checker, the reference, or a
second module; the candidate replaces the DUT entirely.

## Running them

One answer:

```bash
./scripts/sim_candidate.sh ai_d01 candidates/ai_d01/opus5_t0.sv
```

Every answer for a task, with a pass-rate summary — this is the one that
answers "are these hard enough":

```bash
./scripts/sim_candidate.sh ai_d01 candidates/ai_d01
```

A task id (`ai_d01`) resolves to its directory under `domains/`; a full path
still works. Add `icarus` to run the other simulator, `--smoke` for one config
instead of the full sweep.

## What counts as passing

**Every legal config, zero coverage holes.** `LANES ∈ {1,2,4,8}` for `ai_d01`;
all 16 `S_BYTES`×`M_BYTES` pairs for `nw_d01`. A candidate that passes one
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
