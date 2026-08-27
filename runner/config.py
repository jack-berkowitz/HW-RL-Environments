"""
*** NON-FUNCTIONAL AFTER THE TIER REMOVAL — EVERY TASK IN THIS REGISTRY IS GONE. ***

This is the OpenRouter eval pipeline, and it is built ENTIRELY on the
TierOne/TierTwo layout: it resolves interfaces/<tier>/<name>_iface.sv and
testbenches/<tier>/<name>_tb.sv, and its TASKS registry lists only tier modules
(fifo, arbiter, multiplier, softmax, uart, rob, lsq, bpred). Those directories
and those tasks were deleted. It knows nothing about domains/.

It is kept, not deleted, because the CROSS-MODEL BREADTH RUN needs a pipeline of
this shape and this one already has the pieces worth reusing: model fan-out
(models.py), answer extraction with leak detection (extract.py::_LEAKS), and
scoring (score.py). What it does not have is any notion of a domains/ task.

WHAT IS ACTUALLY MISSING for the cross-model run, recorded here so it is not
discovered mid-experiment:
  1. a TASKS registry for domains/ tasks (d_ca04, d_nw01) — this file
  2. capability/coverage metrics in the result row — scoring stops at PASS/FAIL
  3. an ORFS leg — nothing here calls ppa_candidate.sh
  4. leak detection on the domains path — sim_candidate.sh checks ONLY a forged
     TEST_RESULT, not the other five tokens in extract.py::_LEAKS
  5. persisted sim logs — collect_results.py reads sim_logs/<design>.log and
     nothing in the domains path writes one

The domains path (scripts/sim_candidate.sh + scripts/ppa_candidate.sh) is
independent of this package and is unaffected.
"""

from __future__ import annotations

"""
Task definitions: what modules exist, what parameter configurations they are
graded under, and where the tools live.

The parameter names here are the *testbench* parameters. Each TB passes its own
parameters straight down into the DUT instantiation, so overriding the TB
parameter with `iverilog -P <tb>.<NAME>=<value>` is sufficient to reconfigure
both sides. Overriding the DUT directly would desynchronise the reference model
from the design under test.

Every configuration listed here must be legal per the corresponding _iface.sv
header. The testbenches self-check their configuration and abort with
TEST_RESULT: FAIL on an illegal one, so an illegal entry here shows up as a
grading failure against a correct design -- keep them in sync with the specs.
"""

from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

INTERFACES = REPO_ROOT / "interfaces"
TESTBENCHES = REPO_ROOT / "testbenches"
CANDIDATES = REPO_ROOT / "candidates"
REFERENCE_SOLUTIONS = REPO_ROOT / "reference_solutions"
MUTATION_TESTS = REPO_ROOT / "sandbox" / "mutation_tests"
SYNTH_SCRIPT = REPO_ROOT / "synth_and_time.tcl"

# Shared reference models (`golden_mem.sv`, `mem_stub.sv`) that some TierTwo
# testbenches `include rather than duplicate.
COMMON_TB = TESTBENCHES / "common"


@dataclass(frozen=True)
class ParamSet:
    """One legal configuration of a module, plus how long it takes to grade."""

    params: dict[str, int]
    # Wall-clock ceiling for the simulation of this specific configuration.
    # Exhaustive phases dominate: multiplier at BIT_WIDTH=8 runs 65536
    # transactions, uart runs every payload value through a full frame.
    sim_timeout_s: int = 300

    @property
    def label(self) -> str:
        if not self.params:
            return "default"
        return ",".join(f"{k}={v}" for k, v in sorted(self.params.items()))


@dataclass(frozen=True)
class Task:
    name: str
    # Which difficulty directory the spec and testbench live under. The repo is
    # split interfaces/<tier>/ and testbenches/<tier>/; a task without the right
    # tier resolves to a path that does not exist.
    tier: str = "TierOne"
    # Index into `configs` for the single configuration used by the smoke tier.
    smoke_index: int = 0
    configs: list[ParamSet] = field(default_factory=list)
    # Extra -I directories for the compile. Only the TierTwo testbenches that
    # `include a shared memory model need this.
    include_dirs: tuple[Path, ...] = ()
    # Default target clock period (ns) for the fixed-target synthesis report.
    # The Fmax search does not use this; it exists so a single synth run has
    # something to report timing_met against.
    target_period_ns: float = 5.0

    @property
    def iface(self) -> Path:
        return INTERFACES / self.tier / f"{self.name}_iface.sv"

    @property
    def testbench(self) -> Path:
        return TESTBENCHES / self.tier / f"{self.name}_tb.sv"

    @property
    def reference(self) -> Path:
        """
        The in-repo known-good implementation, used by the selftest.

        reference_solutions/ wins where it exists: those files are the ones
        written to prove the testbench passes something correct and fails the
        mutants. candidates/ holds working implementations for TierOne but for
        TierTwo it holds independent attempts that are not all correct.
        """
        golden = REFERENCE_SOLUTIONS / self.tier / f"{self.name}.sv"
        return golden if golden.is_file() else CANDIDATES / self.tier / f"{self.name}.sv"

    @property
    def tb_module(self) -> str:
        return f"{self.name}_tb"

    def smoke(self) -> ParamSet:
        return self.configs[self.smoke_index]


# -----------------------------------------------------------------------------
# The tasks.
#
# `configs[0]` is the testbench's own default configuration in every case, which
# makes it the cheapest thing to run and the natural smoke test.
# -----------------------------------------------------------------------------

TASKS: dict[str, Task] = {
    "fifo": Task(
        name="fifo",
        tier="TierOne",
        configs=[
            ParamSet({"DEPTH": 16, "DATA_WIDTH": 32,
                      "ALMOST_FULL_THRESH": 12, "ALMOST_EMPTY_THRESH": 4}),
            ParamSet({"DEPTH": 8, "DATA_WIDTH": 8,
                      "ALMOST_FULL_THRESH": 6, "ALMOST_EMPTY_THRESH": 2}),
            ParamSet({"DEPTH": 32, "DATA_WIDTH": 16,
                      "ALMOST_FULL_THRESH": 28, "ALMOST_EMPTY_THRESH": 3}),
            ParamSet({"DEPTH": 64, "DATA_WIDTH": 64,
                      "ALMOST_FULL_THRESH": 60, "ALMOST_EMPTY_THRESH": 8}),
            # Degenerate thresholds: AF at its minimum and AE at its maximum
            # means almost_full is set at count>=1 and almost_empty is clear
            # only at count==DEPTH. Catches implementations that hardcode the
            # "sensible" threshold relationship.
            ParamSet({"DEPTH": 16, "DATA_WIDTH": 8,
                      "ALMOST_FULL_THRESH": 1, "ALMOST_EMPTY_THRESH": 15}),
        ],
    ),
    "arbiter": Task(
        name="arbiter",
        tier="TierOne",
        configs=[
            ParamSet({"NUM_REQ": 4, "VARIANT": 1}),
            ParamSet({"NUM_REQ": 2, "VARIANT": 0}),
            ParamSet({"NUM_REQ": 4, "VARIANT": 0}),
            ParamSet({"NUM_REQ": 8, "VARIANT": 1}),
            ParamSet({"NUM_REQ": 4, "VARIANT": 2}),
            ParamSet({"NUM_REQ": 16, "VARIANT": 2}),
        ],
    ),
    "multiplier": Task(
        name="multiplier",
        tier="TierOne",
        configs=[
            ParamSet({"BIT_WIDTH": 16, "SIGNED_MODE": 1}),
            ParamSet({"BIT_WIDTH": 16, "SIGNED_MODE": 0}),
            ParamSet({"BIT_WIDTH": 32, "SIGNED_MODE": 1}),
            # BIT_WIDTH=8 triggers the exhaustive 256x256 phase in the TB:
            # 65536 transactions of up to 40 cycles each. Slowest config by far.
            ParamSet({"BIT_WIDTH": 8, "SIGNED_MODE": 1}, sim_timeout_s=1800),
            ParamSet({"BIT_WIDTH": 8, "SIGNED_MODE": 0}, sim_timeout_s=1800),
        ],
    ),
    "softmax": Task(
        name="softmax",
        tier="TierOne",
        configs=[
            ParamSet({"NUM_ELEMENTS": 8}, sim_timeout_s=600),
            ParamSet({"NUM_ELEMENTS": 4}, sim_timeout_s=600),
            ParamSet({"NUM_ELEMENTS": 16}, sim_timeout_s=900),
        ],
    ),
    "uart": Task(
        name="uart",
        tier="TierOne",
        configs=[
            # BIT_CYCLES = CLK_FREQ_HZ / BAUD_RATE must be an integer >= 8.
            ParamSet({"DATA_BITS": 8, "PARITY": 0, "STOP_BITS": 1}, sim_timeout_s=600),
            ParamSet({"DATA_BITS": 8, "PARITY": 1, "STOP_BITS": 1}, sim_timeout_s=600),
            ParamSet({"DATA_BITS": 7, "PARITY": 2, "STOP_BITS": 2}, sim_timeout_s=600),
            ParamSet({"DATA_BITS": 8, "PARITY": 2, "STOP_BITS": 2}, sim_timeout_s=600),
            # A slower baud (BIT_CYCLES=32) exercises a different divider width.
            ParamSet({"CLK_FREQ_HZ": 32_000_000, "BAUD_RATE": 1_000_000,
                      "DATA_BITS": 8, "PARITY": 1, "STOP_BITS": 1},
                     sim_timeout_s=900),
        ],
    ),

    # -------------------------------------------------------------------------
    # TierTwo: microarchitectural blocks. Each testbench runs >=10k randomized
    # cycles against a full reference model and additionally gates on coverage,
    # so a run that never reaches the hard states is failed rather than passed.
    #
    # Only the testbench's own default configuration is registered. The coverage
    # gates are tuned to these parameters; an unvalidated sweep config can fail a
    # correct design by never reaching a required state, which would read as a
    # model failure. Add more only after runner.selftest confirms the reference
    # solutions pass them.
    # -------------------------------------------------------------------------
    "rob": Task(
        name="rob",
        tier="TierTwo",
        configs=[
            ParamSet({"DEPTH": 16, "PC_W": 32, "TAG_W": 6, "VAL_W": 32},
                     sim_timeout_s=900),
        ],
    ),
    "lsq": Task(
        name="lsq",
        tier="TierTwo",
        # lsq_tb.sv does `include "mem_stub.sv"`, which in turn includes
        # golden_mem.sv. Without this the compile fails before the DUT is seen.
        include_dirs=(COMMON_TB,),
        configs=[
            ParamSet({"DEPTH": 16, "ADDR_W": 10, "DATA_W": 32, "AGE_W": 16},
                     sim_timeout_s=900),
        ],
    ),
    "bpred": Task(
        name="bpred",
        tier="TierTwo",
        configs=[
            ParamSet({"PC_W": 32, "GHR_W": 8, "PHT_ENTRIES": 256,
                      "BTB_SETS": 16, "BTB_WAYS": 2, "RAS_DEPTH": 8},
                     sim_timeout_s=900),
        ],
    ),
}

ALL_MODULES = list(TASKS)

# Verilator's --binary mode elaborates to C++ and then compiles it, so "compile"
# here includes a full g++ build of the testbench -- minutes, not seconds, for
# the larger TierTwo harnesses. Icarus needs a fraction of this but shares the
# ceiling; the limit exists to catch pathological candidates (deep parameter
# recursion, runaway generate loops), not to pace the normal case.
COMPILE_TIMEOUT_S = 600

# Synthesis + STA on designs this size is seconds, but abc can occasionally
# wander on a badly-structured netlist.
SYNTH_TIMEOUT_S = 900
