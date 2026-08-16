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

## WARNING — two directories here are holding pens, and sweeping them lies

`candidates/d_dsp02/` and `candidates/v_ca05/` exist so submissions have a home.
**Neither task is scoreable today**, and the fan-out driver does not know that.

`run_submissions.sh` auto-discovers any `candidates/<task>/` containing `.sv`
files, and treats **any** non-zero exit from `sim_candidate.sh` as
`correctness gate failed`. But `sim_candidate.sh` also exits non-zero when it
**cannot address the task at all**:

- **`v_ca05` does not resolve.** Task ids are looked up under
  `domains/*/design/` only, never `verification/`, so a `v_ca05` submission
  exits 2 with `cannot resolve task`.
- **`d_dsp02` resolves but has no `sim_flags_verilator.txt`** and is not
  registered, so it refuses too.

In both cases the driver prints `correctness gate failed; place-and-route
skipped` and counts the submission as not passing. **A structural inability to
run the task is reported as a property of the candidate**, and the closing
`N of M submission(s) passed` line understates the rate using a number that has
nothing to do with the submissions.

Same shape as the defects in `FINDINGS.md`: the run completes, the output looks
like a result, and nothing errors.

**Until the scoring paths exist, name tasks explicitly** —
`./scripts/run_submissions.sh d_ca04 d_nw01` — rather than letting it discover.

### And v_ca05 submissions are TESTBENCHES, not RTL

The whole intake assumes `candidates/<task>/<label>.sv` is a **DUT replacing the
reference**. A `v_ca05` submission is a testbench replacing the *checker*, which
inverts what the harness does with the file. This is recorded, not worked
around: the verification scoring path is not built yet.

## Are these committed?

The tier-based ones are, so the new ones follow suit — a candidate that
provoked an interesting failure is worth keeping next to the task it broke.
Raw sweep output is different: `results/*.jsonl` is gitignored precisely
because it carries full model responses and churns.
