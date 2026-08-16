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

## Running the two newest tasks

Both now have a working path, but **neither goes through
`run_submissions.sh`** — name them explicitly with the right script.

### `d_dsp02` — RTL submissions

```bash
./scripts/sim_candidate.sh d_dsp02 candidates/d_dsp02/chat.sv
```

Works as of the F22 fix: the task now has `ref/sim_flags_verilator.txt` and a
registered config list (exactly one config — the interface declares no
parameters, and rounding mode is a runtime input swept by the 4290-vector set).

**A submission must be self-contained.** The reference shim is not — it imports
the vendored `fpnew_pkg` — so it fails the slang gate as a candidate and cannot
be used as a smoke test. That is correct behaviour, not a defect.

### `v_ca05` — TESTBENCH submissions

```bash
./scripts/sim_verification.sh v_ca05 candidates/v_ca05/chat.sv
```

A separate script, because the submission **is the checker** rather than the
thing being checked, and `sim_candidate.sh` resolves only `domains/*/design/`.

It scores two things and refuses to imply a third: the **validity gate** (does it
pass the golden DUT) and **unpromised reliance** (does it also pass all four
conformant perturbations). **Mutant kill rate is not measured — v_ca05 has no
mutant set.** A pass therefore means "does not reject correct hardware and relies
on nothing unpromised", and says nothing about whether the testbench finds bugs.

The submission must declare `module tag_tracker_tb` and print one final
`RESULT: PASS` or `RESULT: FAIL` line, as the blind task specifies.

## Do not let the fan-out driver discover these

`run_submissions.sh` auto-discovers any `candidates/<task>/` containing `.sv`
files and treats **any** non-zero exit from `sim_candidate.sh` as
`correctness gate failed`. `v_ca05` does not resolve there at all, so every
testbench submission would be counted as a failed RTL candidate and the closing
`N of M passed` line would understate the rate using a number unrelated to the
submissions.

**Name tasks explicitly** — `./scripts/run_submissions.sh d_ca04 d_nw01` — until
the driver learns about verification tasks.

## Are these committed?

The tier-based ones are, so the new ones follow suit — a candidate that
provoked an interesting failure is worth keeping next to the task it broke.
Raw sweep output is different: `results/*.jsonl` is gitignored precisely
because it carries full model responses and churns.
