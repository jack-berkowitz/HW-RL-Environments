# d_dsp03 — agentic attempts, for PPA comparison

Four submissions produced by Claude Opus 5 through the Agent SDK
(`scripts/trace_attempts_sdk.py`), each an INDEPENDENT attempt at d_dsp03 with
Bash and Verilator available. Reasoning traces stay on the operator's machine;
only the RTL is here, because only the RTL is needed to build.

## NOT COMPARABLE TO THE PUBLISHED CORPUS, and that is the point of this
directory rather than `candidates/d_dsp03/`.

The published 30 design submissions were solicited ONE-SHOT: a model got
PASTE.md and returned a file, with no feedback. These attempts ran agentically —
the model wrote its own testbench and Python reference model, generated test
vectors, compiled with Verilator and iterated, over 30 to 51 tool calls. A score
from that process measures something different, and putting these under
`candidates/` would silently move the corpus denominator, which is derived from
the filesystem.

## Provenance

| file | attempt | lines | correctness |
|---|---|---|---|
| attempt_01.sv | 01 | 460 | **2/2 pass** (verified) |
| attempt_05.sv | 05 | 411 | not yet run |
| attempt_06.sv | 06 | 478 | not yet run |
| attempt_09.sv | 09 | 531 | not yet run |

Ten attempts were launched. Four produced a submission, two completed without
writing one, and four ended in a harness error. That distribution is a result,
not a defect to hide: the same task is passed one-shot by chat and claude and
failed by gemini.

## Building

The scored configuration is the pin, 70.5 ns. Correctness first, then PPA:

    ./scripts/sim_candidate.sh d_dsp03 experiments/d_dsp03_sdk_attempts/attempt_05.sv
    ./scripts/ppa_candidate.sh d_dsp03 experiments/d_dsp03_sdk_attempts/attempt_05.sv sdk05

Reference numbers to compare against, at the same pin: area 177,557 um2,
power 91.1 mW, slack +1.995 ns. The one-shot submissions land at chat 3.28x
area and claude 1.28x.
