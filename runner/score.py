"""
The scoring primitive: a candidate implementation in, a structured verdict out.

    score(module, sv_source) -> Score

This is the single entry point used by both the model evaluation and (later) RL
rollouts. Keeping it one function is deliberate -- an eval that grades
differently from the training environment measures nothing useful.

Grading runs in three stages, each with its own distinct failure label:

    compile   iverilog elaborates the testbench against the candidate
    simulate  vvp runs it; the TB prints a single TEST_RESULT: line
    synth     yosys maps to sky130 standard cells; OpenSTA times the netlist

The failure taxonomy is the point of the return value. "Did it pass" collapses
everything interesting: a candidate that does not compile and a candidate that
compiles and misses timing by 0.1ns are both failures, but they say opposite
things about how far along the model is.

No third-party dependencies. Standard library only, so this runs anywhere the
tools do.
"""

from __future__ import annotations

import os
import re
import shutil
import signal
import subprocess
import tempfile
import time
from dataclasses import dataclass, field, asdict
from enum import Enum
from pathlib import Path

from .config import (
    COMPILE_TIMEOUT_S,
    SYNTH_TIMEOUT_S,
    SYNTH_SCRIPT,
    ParamSet,
    Task,
    TASKS,
)


# Verilator is the primary correctness simulator (testbenches/TierTwo/NOTES.md:
# "Correctness simulation now runs on Verilator 5.046"). Icarus is retained as a
# second opinion: it is 4-state where Verilator is 2-state, so it catches
# X-propagation bugs Verilator misses -- but it rejects constructs the reference
# solutions legitimately use, so it cannot be the primary.
DEFAULT_SIMULATOR = "verilator"


class Outcome(str, Enum):
    """Where a candidate stopped. Ordered from earliest failure to full pass."""

    COMPILE_ERROR = "compile_error"      # iverilog rejected it
    SIM_TIMEOUT = "sim_timeout"          # wall-clock kill; the DUT hung
    SIM_CRASH = "sim_crash"              # vvp died without printing a verdict
    NO_VERDICT = "no_verdict"            # ran to completion, printed no TEST_RESULT
    TEST_FAIL = "test_fail"              # the testbench rejected the design
    SYNTH_ERROR = "synth_error"          # functionally correct, would not synthesize
    TIMING_MISS = "timing_miss"          # synthesized, missed the target period
    PASS = "pass"                        # correct, synthesizable, meets timing

    # Upstream of grading. NO_CODE is the model's fault (it answered without a
    # usable module); API_ERROR is not, and must be excluded from pass rates.
    NO_CODE = "no_code"                  # response contained no extractable module
    API_ERROR = "api_error"              # the completion never arrived
    TRUNCATED = "truncated"              # hit the token ceiling before answering

    # The candidate tried to influence the verdict rather than earn it. Counted
    # as a failure, but tracked separately -- it is a qualitatively different
    # thing from a wrong design and worth reading the raw response over.
    CHEAT = "cheat"                      # forged verdict / escaped the sandbox

    # Not a property of the candidate: the harness or the testbench itself is at
    # fault. These must never be counted as model failures.
    HARNESS_ERROR = "harness_error"      # bad config, missing file, missing tool
    TB_WATCHDOG = "tb_watchdog"          # the TB's own watchdog fired


# Outcomes that mean "the candidate is functionally correct".
FUNCTIONALLY_CORRECT = {Outcome.PASS, Outcome.SYNTH_ERROR, Outcome.TIMING_MISS}

# Outcomes that say nothing about the candidate and must be excluded from any
# pass-rate denominator.
#
# TRUNCATED belongs here: a model that spent its whole budget reasoning and
# returned an empty message never submitted a design, so counting it as a failed
# design would understate the model and overstate the difficulty of the problem.
# It is a budget setting, not a capability measurement -- raise the ceiling or
# cap the reasoning and re-run those samples.
NOT_THE_CANDIDATES_FAULT = {Outcome.HARNESS_ERROR, Outcome.TB_WATCHDOG,
                            Outcome.API_ERROR, Outcome.TRUNCATED}

VERDICT_RE = re.compile(r"^TEST_RESULT:\s*(PASS|FAIL)(?::\s*(.*))?$", re.M)
# The testbenches abort this way when handed a configuration their _iface.sv
# forbids. That is a bug in config.py, not in the design under test.
ILLEGAL_CONFIG_RE = re.compile(r"^TEST_RESULT:\s*FAIL:\s*illegal\b", re.M)
# Every TB carries `initial #N; $display("TEST_RESULT: FAIL: timeout ...")`.
TB_TIMEOUT_RE = re.compile(r"^TEST_RESULT:\s*FAIL:\s*timeout\b", re.M)


@dataclass
class StageResult:
    ok: bool
    seconds: float
    returncode: int | None = None
    stdout: str = ""
    stderr: str = ""
    timed_out: bool = False


@dataclass
class Score:
    module: str
    config: str
    outcome: Outcome
    # Short human-readable reason, taken from the TB verdict where there is one.
    detail: str = ""

    # Functional
    compiled: bool = False
    test_passed: bool | None = None
    checks: int | None = None          # count the TB reports having executed

    # Physical (populated only when the synthesis stage runs)
    cell_count: int | None = None
    wns_ns: float | None = None
    tns_ns: float | None = None
    worst_slack_ns: float | None = None
    target_period_ns: float | None = None
    fmax_mhz: float | None = None

    seconds: float = 0.0
    simulator: str = ""
    stages: dict[str, StageResult] = field(default_factory=dict, repr=False)

    @property
    def functionally_correct(self) -> bool:
        return self.outcome in FUNCTIONALLY_CORRECT

    @property
    def gradeable(self) -> bool:
        """False when the harness failed, so the row must not enter a pass rate."""
        return self.outcome not in NOT_THE_CANDIDATES_FAULT

    def to_dict(self) -> dict:
        d = asdict(self)
        d.pop("stages", None)
        d["outcome"] = self.outcome.value
        return d


def _run(cmd: list[str], cwd: Path, timeout_s: int) -> StageResult:
    """
    Run a command, killing the whole process group on timeout.

    A generated FSM with an unreachable exit condition will simulate forever,
    and yosys can spawn children, so killing just the direct child is not
    enough to reclaim the machine.
    """
    started = time.monotonic()
    try:
        proc = subprocess.Popen(
            cmd,
            cwd=str(cwd),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            errors="replace",
            start_new_session=True,
        )
    except FileNotFoundError as exc:
        return StageResult(ok=False, seconds=0.0, returncode=None,
                           stderr=f"tool not found: {exc}")

    try:
        out, err = proc.communicate(timeout=timeout_s)
        return StageResult(
            ok=(proc.returncode == 0),
            seconds=time.monotonic() - started,
            returncode=proc.returncode,
            stdout=out,
            stderr=err,
        )
    except subprocess.TimeoutExpired:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            proc.kill()
        out, err = proc.communicate()
        return StageResult(
            ok=False,
            seconds=time.monotonic() - started,
            returncode=None,
            stdout=out,
            stderr=err,
            timed_out=True,
        )


# -----------------------------------------------------------------------------
# Anti-gaming
#
# The candidate is compiled into the same simulation as the grader, and the
# verdict is a line of stdout. That makes several things trivially forgeable by
# a model that would rather print a pass than earn one, so the source is
# screened before the compiler ever sees it.
#
# The screen is deliberately narrow. Every pattern below is something no
# synthesizable RTL implementation of these specs has any reason to contain, so
# a correct design is never caught by it -- verified against all eight in-repo
# reference solutions by runner.selftest.
# -----------------------------------------------------------------------------

# Comments and string literals are stripped before matching so that a `//` note
# mentioning $finish is not treated as an escape attempt.
_COMMENT_RE = re.compile(r"//[^\n]*|/\*.*?\*/", re.S)
_STRING_RE = re.compile(r'"(?:[^"\\]|\\.)*"')

_FORBIDDEN: tuple[tuple[str, re.Pattern[str]], ...] = (
    # The verdict itself. This is the whole game: _verdict() reads stdout, so a
    # candidate that prints a PASS line outranks whatever the testbench decided.
    ("forged verdict: candidate emits a TEST_RESULT line",
     re.compile(r"TEST_RESULT")),
    # Ending the simulation early stops the testbench before it can accumulate
    # the failures that would have condemned the design. $fatal counts: it ends
    # the run as surely as $finish does, and an assertion severe enough to kill
    # the simulation has no place in a design being graded by one.
    ("early termination: $finish/$stop/$fatal in the candidate",
     re.compile(r"\$(finish|stop|fatal)\b")),
    # Reaching outside the simulation: the testbench source, the reference
    # solutions and the golden model are all files on the same disk.
    ("file or shell access from the candidate",
     re.compile(r"\$(system|fopen|fclose|fdisplay|fwrite|fgets|fscanf|fread|"
                r"sformat|readmemh|readmemb|writememh|writememb|"
                r"value\$plusargs|test\$plusargs)\b")),
    # `include lets a candidate pull the testbench (and therefore the reference
    # model's expected values) into its own scope.
    ("`include directive in the candidate",
     re.compile(r"^\s*`include\b", re.M)),
    # A hierarchical path into the testbench reads the reference model directly:
    # the correct answer is sitting in a variable one scope up.
    ("hierarchical reference out of the candidate's scope",
     re.compile(r"\$root\b|\b\w+_tb\s*\.")),
)

# Paths that only appear in a candidate trying to find the grader.
_FORBIDDEN_PATHS = ("testbenches", "reference_solutions", "candidates",
                    "mutation_tests", "golden_mem", "mem_stub")


def check_candidate_source(source: str) -> str | None:
    """
    Screen untrusted RTL for attempts to influence the verdict.

    Returns a human-readable reason to reject, or None when the source is clean.
    Legitimate synthesis constructs -- $clog2, $bits, $signed, $unsigned, $size,
    $onehot, $countones, $isunknown, and plain $display debug -- are all
    untouched; only the escape hatches above are refused.
    """
    if not source:
        return None

    # A string literal mentioning a forbidden path is the giveaway, so check the
    # literals for paths first, then strip them for the pattern scan.
    for lit in _STRING_RE.findall(source):
        low = lit.lower()
        for bad in _FORBIDDEN_PATHS:
            if bad in low:
                return f"candidate references a harness path: {bad}"

    stripped = _STRING_RE.sub('""', _COMMENT_RE.sub(" ", source))

    for reason, pattern in _FORBIDDEN:
        # TEST_RESULT is checked against the original text: blanking string
        # literals would hide the exact case that matters most.
        haystack = source if "TEST_RESULT" in pattern.pattern else stripped
        if pattern.search(haystack):
            return reason
    return None


def _param_flags(task: Task, ps: ParamSet, simulator: str) -> list[str]:
    """
    Build the parameter overrides, in whichever dialect the simulator speaks.

    Overriding the testbench parameter (not the DUT's) is required: each TB
    forwards its own parameters into the DUT instantiation and also uses them to
    configure its reference model. Overriding the DUT alone would leave the
    reference model describing a different design.

    The two simulators disagree on spelling and the difference is silent, not an
    error -- Icarus wants the override scoped to the TB instance, Verilator wants
    it bare and applies it to the top module (which is the TB). Getting this
    wrong means the sweep quietly grades every configuration at its default.
    """
    flags: list[str] = []
    for name, value in sorted(ps.params.items()):
        if simulator == "icarus":
            flags += ["-P", f"{task.tb_module}.{name}={value}"]
        else:
            flags.append(f"-G{name}={value}")
    return flags


def _verdict(text: str) -> tuple[bool | None, str, int]:
    """
    Extract the TEST_RESULT line, and report how many there were.

    The count matters: taking the last match unconditionally is exactly the hole
    a candidate exploits by printing its own verdict after the testbench's. The
    caller treats any count above one as cheating rather than as a result.
    """
    matches = list(VERDICT_RE.finditer(text))
    if not matches:
        return None, "", 0
    last = matches[-1]
    passed = last.group(1) == "PASS"
    return passed, (last.group(2) or "").strip(), len(matches)


_CHECKS_RE = re.compile(r"(\d+)\s+(?:failing checks of|checks|vector checks|transactions)")


def _checks_reported(text: str) -> int | None:
    m = _CHECKS_RE.search(text)
    return int(m.group(1)) if m else None


def run_functional(
    task: Task,
    source: str,
    ps: ParamSet,
    workdir: Path,
    *,
    simulator: str = DEFAULT_SIMULATOR,
) -> Score:
    """Compile the TB against `source` and run it. Never raises on a bad candidate."""
    score = Score(module=task.name, config=ps.label, outcome=Outcome.HARNESS_ERROR,
                  simulator=simulator)
    started = time.monotonic()

    if simulator not in ("verilator", "icarus"):
        score.detail = f"unknown simulator '{simulator}'"
        return score
    if not task.testbench.is_file():
        score.detail = f"testbench missing: {task.testbench}"
        return score

    # The candidate is untrusted code that will be compiled into the same
    # simulation as the grader. Refuse it before the compiler ever sees it.
    cheat = check_candidate_source(source)
    if cheat:
        score.outcome = Outcome.CHEAT
        score.detail = cheat
        score.seconds = time.monotonic() - started
        return score

    # Everything the compile needs is copied into the throwaway workdir and
    # referenced by relative name. The candidate is untrusted code running in the
    # same simulation as the grader, so it must never be handed a path that
    # points back into the repo -- see check_candidate_source().
    tb = workdir / task.testbench.name
    shutil.copy2(task.testbench, tb)

    include_flags: list[str] = []
    for d in task.include_dirs:
        if not d.is_dir():
            score.detail = f"include dir missing: {d}"
            return score
        local = workdir / d.name
        if not local.exists():
            shutil.copytree(d, local)
        # iverilog wants -I attached to its argument.
        include_flags.append(f"-I{local.name}")

    cand = workdir / f"{task.name}.sv"
    cand.write_text(source)

    if simulator == "icarus":
        # -g2012 selects SystemVerilog-2012. The testbenches use string types,
        # $sformatf, automatic tasks and packed-array slicing; none of that
        # elaborates under the default Verilog-2005 mode.
        compile_cmd = [
            "iverilog", "-g2012", "-o", "sim.vvp",
            *include_flags,
            *_param_flags(task, ps, simulator),
            "-s", task.tb_module,
            tb.name, cand.name,
        ]
        sim_cmd = ["vvp", "sim.vvp"]
    else:
        # --binary builds a standalone executable; --timing is required because
        # the testbenches drive the clock from delay statements rather than an
        # external harness. -Wno-fatal keeps lint warnings on a model's RTL from
        # being scored as compile errors -- style is not what is being graded.
        # -Mdir must already exist.
        (workdir / "obj_dir").mkdir(exist_ok=True)
        compile_cmd = [
            "verilator", "--binary", "--timing", "-j", "0", "-Wno-fatal",
            "--x-assign", "unique", "--x-initial", "unique",
            *include_flags,
            *_param_flags(task, ps, simulator),
            "--top-module", task.tb_module,
            "-Mdir", "obj_dir", "-o", "sim",
            tb.name, cand.name,
        ]
        sim_cmd = ["obj_dir/sim"]

    comp = _run(compile_cmd, workdir, COMPILE_TIMEOUT_S)
    score.stages["compile"] = comp
    if not comp.ok:
        score.outcome = Outcome.COMPILE_ERROR
        score.detail = _first_error(comp.stderr or comp.stdout)
        score.seconds = time.monotonic() - started
        return score
    score.compiled = True

    run = _run(sim_cmd, workdir, ps.sim_timeout_s)
    score.stages["simulate"] = run
    text = run.stdout + "\n" + run.stderr
    score.checks = _checks_reported(text)

    if run.timed_out:
        score.outcome = Outcome.SIM_TIMEOUT
        score.detail = f"no verdict within {ps.sim_timeout_s}s"
        score.seconds = time.monotonic() - started
        return score

    # A testbench that rejects its own configuration, or whose internal watchdog
    # fires, is not evidence about the candidate.
    if ILLEGAL_CONFIG_RE.search(text):
        score.outcome = Outcome.HARNESS_ERROR
        score.detail = "testbench rejected the parameter configuration"
        score.seconds = time.monotonic() - started
        return score
    if TB_TIMEOUT_RE.search(text):
        score.outcome = Outcome.TB_WATCHDOG
        score.detail = "testbench watchdog fired"
        score.seconds = time.monotonic() - started
        return score

    passed, reason, n_verdicts = _verdict(text)
    # Exactly one verdict line is expected. More than one means something other
    # than the testbench printed one, and the only other thing in the simulation
    # is the candidate. check_candidate_source() should already have caught it;
    # this is the backstop for a spelling it did not anticipate.
    if n_verdicts > 1:
        score.outcome = Outcome.CHEAT
        score.detail = f"{n_verdicts} TEST_RESULT lines; the testbench prints one"
        score.seconds = time.monotonic() - started
        return score

    if passed is None:
        score.outcome = Outcome.SIM_CRASH if not run.ok else Outcome.NO_VERDICT
        score.detail = _first_error(run.stderr) or "no TEST_RESULT line"
    elif passed:
        score.outcome = Outcome.PASS
        score.test_passed = True
    else:
        score.outcome = Outcome.TEST_FAIL
        score.test_passed = False
        score.detail = reason

    score.seconds = time.monotonic() - started
    return score


# yosys `stat` reports a bare indented "<n> cells" line per module. `synth` also
# emits its own stat mid-run, so the LAST match is the one that reflects the
# final netlist.
_STAT_CELLS_RE = re.compile(r"^\s+(\d+) cells\s*$", re.M)


def run_synthesis(
    task: Task,
    source: str,
    workdir: Path,
    *,
    liberty: str | None = None,
    yosys: str = "yosys",
) -> tuple[int | None, StageResult]:
    """
    Map the candidate to standard cells and return the cell count.

    Timing is deliberately not done here -- see fmax.py. This stage answers only
    "does it synthesize, and how big is it", which is the part that needs no
    OpenSTA and therefore runs anywhere yosys does.
    """
    cand = workdir / f"{task.name}.sv"
    if not cand.is_file():
        cand.write_text(source)
    netlist = workdir / f"{task.name}_synth.v"

    script = [
        f"read_verilog -sv {cand}",
        f"synth -top {task.name}",
    ]
    if liberty:
        script += [
            f"dfflibmap -liberty {liberty}",
            f"abc -liberty {liberty}",
        ]
    script += [
        "opt_clean",
        f"write_verilog {netlist}",
        "stat",
    ]

    # Deliberately not -q: the `stat` report goes to stdout and is the only
    # evidence that mapping actually happened. Quiet mode suppresses it and
    # leaves a successful-looking run with nothing to parse.
    res = _run([yosys, "-p", "; ".join(script)], workdir, SYNTH_TIMEOUT_S)
    if not res.ok:
        return None, res

    matches = _STAT_CELLS_RE.findall(res.stdout)
    return (int(matches[-1]) if matches else None), res


def _first_error(text: str) -> str:
    """Condense a tool's stderr into one line for the result row."""
    if not text:
        return ""
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if "error" in stripped.lower() or "syntax" in stripped.lower():
            return stripped[:300]
    return text.strip().splitlines()[0][:300]


def score(
    module: str,
    sv_source: str,
    *,
    config: ParamSet | None = None,
    simulator: str = DEFAULT_SIMULATOR,
    synthesize: bool = False,
    liberty: str | None = None,
    keep_workdir: Path | None = None,
) -> Score:
    """
    Grade one candidate implementation of `module`.

    `config` selects the parameter configuration; the task's smoke configuration
    is used when omitted. Synthesis is off by default because it is pointless on
    a design that does not work, and callers that want it should normally gate it
    on `functionally_correct` themselves when sweeping.
    """
    task = TASKS.get(module)
    if task is None:
        return Score(module=module, config="-", outcome=Outcome.HARNESS_ERROR,
                     detail=f"unknown module '{module}'")
    ps = config or task.smoke()

    tmp = Path(tempfile.mkdtemp(prefix=f"score-{module}-"))
    started = time.monotonic()
    try:
        result = run_functional(task, sv_source, ps, tmp, simulator=simulator)

        if synthesize and result.functionally_correct:
            cells, res = run_synthesis(task, sv_source, tmp, liberty=liberty)
            result.stages["synth"] = res
            if not res.ok or cells is None:
                result.outcome = Outcome.SYNTH_ERROR
                result.detail = _first_error(res.stderr or res.stdout)
            elif cells == 0:
                result.outcome = Outcome.SYNTH_ERROR
                result.detail = "synthesis produced zero cells"
            else:
                result.cell_count = cells
            result.seconds = time.monotonic() - started

        if keep_workdir:
            keep_workdir.mkdir(parents=True, exist_ok=True)
            for item in tmp.iterdir():
                shutil.copy2(item, keep_workdir / item.name)
        return result
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def score_sweep(
    module: str,
    sv_source: str,
    *,
    configs: list[ParamSet] | None = None,
    simulator: str = DEFAULT_SIMULATOR,
    stop_on_fail: bool = True,
) -> list[Score]:
    """
    Grade one candidate across several parameter configurations.

    This is the sharpest functional instrument available: it separates "wrote a
    FIFO" from "wrote a 16-deep 32-bit FIFO". A single generation is graded many
    times, so it costs nothing extra from the model.

    `stop_on_fail` short-circuits after the first genuine failure, which is what
    you want when sweeping hundreds of candidates. Harness errors never
    short-circuit -- they are not the candidate's fault.
    """
    task = TASKS[module]
    chosen = configs if configs is not None else task.configs
    out: list[Score] = []
    for ps in chosen:
        result = score(module, sv_source, config=ps, simulator=simulator)
        out.append(result)
        if stop_on_fail and result.gradeable and not result.functionally_correct:
            break
    return out
