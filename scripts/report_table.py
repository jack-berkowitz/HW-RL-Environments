#!/usr/bin/env python3
"""Cross-model results table, written for a reader outside this project.

    python3 scripts/report_table.py            # markdown to stdout

AUDIENCE: someone who knows what area and Fmax mean and has never seen this
repo. So: no internal metric keys, no `!ungated`, no clause numbers without
their meaning. Everything that qualifies a number appears IN THE ROW, not in a
footnote -- a reader scanning the table must not be able to miss that a number
is a build failure, is non-compliant with the scored configuration, or predates
a control.

NO COMPOSITE SCORE, ever. Per-axis only. A single figure of merit would have to
weight area against frequency against capability, and nothing in this project
establishes those weights -- see FINDINGS.md on area-delay, which was retired
for exactly that reason.

Verification tasks are NOT in this table. Kill rate against a known ceiling is
not commensurable with area and frequency, and putting them in one grid would
invite a reader to average them.
"""
import functools
import glob
import json
import io
import os
import traceback
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mutant_evidence import mutants_for   # noqa: E402
import _record_valid as _RV              # noqa: E402


def evidence_note(task_dir):
    """Per-mutant evidence, as `bmc<=34 x3, bmc<=14 x3`.

    RULE 21 -- the TYPE is recorded per mutant, so the summary is per mutant
    too. d_ca01 carries depth 34 on three and depth 14 on three others;
    collapsing those to one number would quote a bound half the set never had.
    A kill rate beside this is NOT evidence and does not imply the type.
    """
    ms = mutants_for(task_dir)
    if not ms:
        return ""
    counts = {}
    for _i, kind, depth in ms:
        key = (f"bmc<={depth}" if kind == "bmc_cex" and depth
               else (kind or "UNRECORDED"))
        counts[key] = counts.get(key, 0) + 1
    return ", ".join(f"{k} x{v}" if v > 1 else k
                     for k, v in sorted(counts.items(),
                                        key=lambda kv: (kv[0] == "UNRECORDED", kv[0])))

# Submissions are stored under a short slug; the table prints the model as
# released. One map so the two never drift apart.
DISPLAY_NAME = {
    "chat":     "ChatGPT 5.6 Sol",
    "claude":   "Claude Opus 5",
    "gemini":   "Gemini 3.1 Pro",
    "qwen":     "Qwen 3.7 Plus",
    "deepseek": "DeepSeek V4 Pro",
}
# Held back until there are enough results to report; excluded rather than
# shown as an unexplained blank.
WITHHELD_MODELS = {"kimi"}


def display_name(slug):
    return DISPLAY_NAME.get(slug, slug)

# Internal metric key -> what a reader should see. Presentation only; the
# records keep the internal names.
READABLE = {
    # Label deliberately non-committal. The checker calls this its C1 capacity
    # measure, but its own comment predicts the anchor reaching MAX_TRANS+1 = 9
    # at MAX_TRANS=8, and it measures 27. MAX_TRANS+1 holds exactly at
    # MAX_TRANS=2 (measured 3) and not at 8. Until that is understood the
    # number is comparable BETWEEN designs -- same harness, same config -- but
    # its units are not established, so no label asserts them. See the
    # unresolved note under the table.
    "outstanding_master0":          ("capacity (C1)", "checker's C1 capacity measure, master 0 — units unresolved, see note"),
    "disjoint_one_pair":            ("1-pair thruput", "bursts/1k cyc, one master-slave pair alone"),
    "disjoint_two_pairs":           ("2-pair thruput", "bursts/1k cyc, two disjoint pairs concurrently"),
    "aggregate_bursts_per_1000cyc": ("aggregate thruput", "bursts/1k cyc, all pairs"),
    "scored_beats_per_1000cyc":     ("beat rate", "data beats/1k cyc"),
    "capacity_beats_accepted":      ("FIFO capacity", "beats accepted before backpressure"),
    # F49: this figure does NOT discriminate at the scored SYNC_STAGES=2 -- a
    # design hardcoding two synchroniser flops reads identically to a correct
    # one there. The parameter is bound by the correctness sweep at
    # SYNC_STAGES=3, which every design in the table has passed; the hardcoded
    # probe scores 9/18 there and never reaches scoring.
    "crossing_latency_rdclk_min":   ("min crossing lat",
        "read-clock cycles, minimum. NOT a capability discriminator on its own: "
        "at the scored SYNC_STAGES=2 a design hardcoding two synchroniser flops "
        "reads identically to a correct one. The parameter is bound by the "
        "correctness sweep at SYNC_STAGES=3 (F49)"),
    "crossing_latency_rdclk_max":   ("max crossing lat", "read-clock cycles, maximum"),
    "wr_stall_cycles":              ("write stalls", "cycles the writer was blocked"),
    "latency_cycles":               ("latency", "clocks from accept to result"),
    "init_interval":                ("init interval", "clocks between accepts"),
}

# EVERY DESIGN TASK, DERIVED FROM DISK. This was a hand-written map of three,
# so d_ca01, d_dsp03 and d_nw03 were absent from the report entirely -- not
# marked pending, not listed as unmeasured, simply not there. Fourth allowlist
# of this shape in this file, after SUBMISSIONS (dropped claude.sv), VTASK_DIR
# (disabled the stale-prompt guard on 12 of 15 tasks) and VTASKS/VREF (covered
# 3 of 8 verification tasks). Every "what counts" list here is now derived.
TASK_TITLE = {}
for _td in sorted(glob.glob(os.path.join(REPO, "domains", "*", "design", "d_*"))):
    _tk = os.path.basename(_td)
    if not os.path.isfile(os.path.join(_td, "task.yaml")):
        continue
    _y = open(os.path.join(_td, "task.yaml"), encoding="utf-8", errors="replace").read()
    _m = re.search(r"^[ \t]*title:[ \t]*(.+)$", _y, re.M)
    _t = (_m.group(1).strip().strip('"\'') if _m
          else " ".join(_tk.split("_")[2:]).replace("_", " ") or _tk)
    TASK_TITLE[_tk] = f"{_tk.split('_')[0]}_{_tk.split('_')[1]} — {_t}"

# Submissions that failed to build. Rule 19: score zero on every PPA axis,
# annotated, never omitted.
# Submissions made BEFORE a requirement existed. Named explicitly with the
# evidence, never inferred: scoring a submission against a spec it was never
# given measures the spec change, not the model.
PREDATES_REQUIREMENT = {
    ("d_dsp02_fp32_fma_ii1", "chat.sv"):
        ("submitted 2026-08-15, before the 3-cycle latency requirement was added "
         "2026-08-16; the spec it was given said \"latency is not constrained\""),
}

# Absent for a reason that had to be ESTABLISHED, not assumed. Rule 20 says an
# unmeasured value renders absent; F31 says the reason for absence can itself be
# a finding.
PPA_UNAVAILABLE = {
    ("d_nw01_axi4_xbar", "chat.sv"):
        "place-and-route exceeded the 5.8 GB container memory limit during "
        "detailed routing (peak 5.70 GB) — a limit of this test setup, not a "
        "property of the design, which was at 75 DRC violations and improving",
}

BUILD_FAILURES = {
    ("d_nw01_axi4_xbar", "gemini.sv"):
        "anonymous struct as parameter value; rejected by slang, the "
        "synthesis frontend (13 errors)",
    ("d_dsp02_fp32_fma_ii1", "deepseek.sv"):
        "does not compile; rejected by slang, the synthesis frontend (17 errors, "
        "Verilator 3)",
    ("d_ca04_async_fifo_cdc", "kimi.sv"):
        "identifier used before its declaration, rejected by slang. Synthesis "
        "which is Verilator being permissive rather than the code being legal — "
        "synthesis uses slang, so it cannot be built",
    ("d_dsp02_fp32_fma_ii1", "qwen.sv"):
        "does not compile; rejected by slang, the synthesis frontend (2 errors)",
    ("d_nw01_axi4_xbar", "deepseek.sv"):
        "does not compile; rejected by slang, the synthesis frontend (5 errors)",
    ("d_nw01_axi4_xbar", "qwen.sv"):
        "does not compile; rejected by slang, the synthesis frontend (20 errors)",
}

# Correctness failures. Distinct from a build failure: the design compiles and
# is wrong, which is a different result about the model.
CORRECTNESS_FAILURES = {
    ("d_dsp02_fp32_fma_ii1", "gemini.sv"):
        "fails the contract at vector 4 (a=1.0, b=0)",
}


def load_records():
    """Every run record EXCEPT the explicitly invalidated ones.

    The invalidated* fields were written and read by nothing. Skipping here is
    safe today only because recency already masks the one such record -- see
    _record_valid.py. Reading the flag makes that a property of the code rather
    than of the timestamps.
    """
    out = []
    for f in sorted(glob.glob(os.path.join(REPO, "runs", "*", "*.json"))):
        try:
            r = json.load(open(f))
        except Exception:
            continue
        if _RV.is_invalidated(r) or not _RV.is_result(r):
            continue
        out.append(r)
    return out


def scored_metrics(task_dir):
    """(key, label, expect) triples from the task's task.yaml."""
    p = os.path.join(task_dir, "task.yaml")
    if not os.path.isfile(p):
        return []
    out, inblock = [], False
    for line in open(p, encoding="utf-8"):
        if line.startswith("scored_metrics:"):
            inblock = True
            continue
        if inblock:
            if line.strip().startswith("#"):
                continue
            if not line.startswith(("  -", "   ")) and line.strip():
                break
            m = re.search(r"metric:\s*([A-Za-z0-9_]+)", line)
            if m:
                e = re.search(r"expect:\s*([A-Za-z0-9_.]+)", line)
                r = re.search(r"role:\s*([a-z]+)", line)
                lab = re.search(r'label:\s*"([^"]*)"', line)
                if lab:
                    # The task's own label wins over the global READABLE map:
                    # a metric declared by a task the map has never heard of
                    # otherwise renders its raw key as a column heading.
                    READABLE.setdefault(m.group(1), (lab.group(1), ""))
                out.append((m.group(1), e.group(1) if e else None,
                            r.group(1) if r else None))
    return out


def metric_roles(task_dir):
    """metric -> role, for the roles a task declares.

    THREE ROLES, and they are not interchangeable:

      fixed       the specification requires the value in `expect`. Deviating is
                  a spec violation, not a design choice.
      choice      the specification leaves it free AND it moves PPA. Pipeline
                  depth is the type case: deeper costs area, buys frequency, and
                  at a COMMON CLOCK buys nothing -- so an area comparison against
                  a design that chose differently is not like-for-like.
      capability  more is better and area buys it. Reported raw AND per unit,
                  because the raw figure alone credits a design for being small
                  when it was merely doing less.

    Measured, not hypothetical: d_ca04's submissions are 26-29% smaller than the
    reference at the same clock, and 9-11% smaller per beat of FIFO capacity.
    Most of that headline gap is two spill registers the reference has and they
    do not. The raw number is true and answers a different question."""
    return {k: r for k, _e, r in scored_metrics(task_dir) if r}


def task_dirs():
    d = {}
    for p in glob.glob(os.path.join(REPO, "domains", "*", "design", "*")):
        if os.path.isdir(p):
            d[os.path.basename(p)] = p
    return d


# EXPLICIT (task, submission) -> sweep file. Rule 10: name the artifact, never
# discover it by pattern. The first version fell back to the task-level sweep
# when a candidate had none, which printed the REFERENCE's Fmax on every
# candidate row -- attributing the reference's frequency to designs that had
# never been swept. Absent is the correct answer; a plausible wrong number is
# not.
@functools.lru_cache(maxsize=None)
def _fx_git(*a):
    r = subprocess.run(("git",)+a, cwd=REPO, capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


@functools.lru_cache(maxsize=None)
def _fx_src_commit(path):
    """Commit that last touched this source, or None if dirty/untracked."""
    if not os.path.isfile(path):
        return None
    if _fx_git("status", "--porcelain", "--", path):
        return None
    return _fx_git("log", "-1", "--format=%H", "--", path) or None


@functools.lru_cache(maxsize=None)
def _fx_is_ancestor(a, b):
    if not a or not b:
        return False
    return subprocess.run(("git", "merge-base", "--is-ancestor", a, b),
                          cwd=REPO, capture_output=True).returncode == 0


def _fx_short(task):
    return "_".join(task.split("_")[:2])


def _fx_src(task, sub):
    if sub.endswith("_ref.sv"):
        g = glob.glob(os.path.join(REPO, "domains", "*", "design", task, "ref", sub))
        return g[0] if g else None
    p = os.path.join(REPO, "candidates", _fx_short(task), sub)
    return p if os.path.isfile(p) else None


def _fx_sweeps(task, sub):
    s = _fx_short(task)
    if sub.endswith("_ref.sv"):
        pats = ["%s_fmax.json" % s]
    else:
        lab = sub[:-3]
        pats = ["%s_cand_%s_fmax.json" % (s, lab), "%s_cand_%s_*_fmax.json" % (s, lab)]
    out = []
    for pat in pats:
        out += glob.glob(os.path.join(REPO, "fmax_results", pat))
    return sorted(set(out))


def fmax_for(task, sub):
    """Fmax from THIS design's own sweep of THESE bytes, or None. Never
    inferred, never borrowed from another design, never derived from a PPA
    build period.

    This replaced a hand-written {(task, submission): filename} map -- the
    seventh allowlist of that shape in this file, and the first one caught
    serving wrong numbers rather than merely missing rows. It had d_nw01/chat
    at 111.11 from a pre-C3 sweep (the current answer is 142.22) and
    d_ca04/chat at 222.22 from a pre-B1 sweep (currently 273.5), while five
    freshly converged sweeps had no entry at all and rendered blank.

    A sweep counts only if the commit that last touched the source is an
    ANCESTOR of the commit the sweep ran at. That is the same test that caught
    the second host sweeping d_nw03's candidates thirteen hours before those
    candidates existed -- a 44% Fmax difference on gemini that no filename
    would have revealed. A dirty or untracked source fails closed: we cannot
    say which bytes a past sweep saw, and under rule 20 not knowing is not a
    value."""
    src = _fx_src(task, sub)
    if not src:
        return None, None
    sc = _fx_src_commit(src)
    if not sc:
        return None, None
    best = None
    for p in _fx_sweeps(task, sub):
        try:
            d = json.load(open(p))
        except Exception:
            continue
        if d.get("fmax_invalid_reason") is not None:
            continue                                    # rule 7
        if d.get("achieved_fmax_mhz") is None:
            continue
        rc = (d.get("rtl_git_commit") or "").replace("-dirty", "").strip()
        if not _fx_is_ancestor(sc, rc):
            continue                                    # sweep predates these bytes
        ts = d.get("timestamp") or ""
        if best is None or ts >= best[0]:
            best = (ts, d)
    if best is None:
        return None, None
    return best[1].get("achieved_fmax_mhz"), best[1].get("converged_period_ns")


# The configuration each task's metrics are read at (rule 18). Named
# explicitly; a metric averaged or last-written across configs is not a
# measurement at the scored configuration.
def _derive_scored_cfg(task_dir):
    """The scored configuration key, built from task.yaml's own declaration.

    Rule 18 requires ONE scored configuration, and every task already names it
    in `scored_configuration:`. This was a hand-written map of three tasks, so
    d_ca01, d_dsp03 and d_nw03 fell through to "multiple configurations
    present; no single scored configuration named" and their metric columns
    rendered empty on every row -- the tasks looked instrumented and reported
    nothing. Fifth allowlist of this shape in this file.

    Derived and then CHECKED against the emitted keys by the caller: a key this
    builds that no run produced renders absent, which is how a wrong derivation
    announces itself rather than silently selecting nothing."""
    y = os.path.join(task_dir, "task.yaml")
    if not os.path.isfile(y):
        return None
    src = open(y, encoding="utf-8", errors="replace").read()
    m = re.search(r"^scored_configuration:\s*\n((?:[ \t]+.*\n)+)", src, re.M)
    if not m:
        return None
    pairs = []
    for line in m.group(1).splitlines():
        mm = re.match(r"\s+([A-Za-z_][A-Za-z0-9_]*):\s*([0-9]+)\s*(?:#.*)?$", line)
        if mm:
            pairs.append(f"{mm.group(1)}_{mm.group(2)}")
    return "_".join(pairs) or None


SCORED_CFG = {}
for _td in sorted(glob.glob(os.path.join(REPO, "domains", "*", "design", "d_*"))):
    SCORED_CFG[os.path.basename(_td)] = _derive_scored_cfg(_td)
SCORED_CFG["d_dsp02_fp32_fma_ii1"] = None   # single config, no parameters


_PIN_RE = re.compile(r"pinned period is\s+([0-9]+(?:\.[0-9]+)?)\s*ns", re.I)
_LABEL_PER_RE = re.compile(r"_fx([0-9]+(?:\.[0-9]+)?)$")
_PIN_CACHE = {}


def _spec_pin(task):
    """The period the spec pins this task at, or None if it states none."""
    if task in _PIN_CACHE:
        return _PIN_CACHE[task]
    val = None
    for d in glob.glob(os.path.join(REPO, "domains", "*", "design", task)):
        for f in sorted(glob.glob(os.path.join(d, "spec", "*.sv"))):
            m = _PIN_RE.search(open(f, errors="replace").read())
            if m:
                val = float(m.group(1))
                break
        if val is not None:
            break
    _PIN_CACHE[task] = val
    return val


def _label_period(label):
    """The period a `..._fx<N>` label was built at, or None."""
    m = _LABEL_PER_RE.search(label or "")
    return float(m.group(1)) if m else None


def _build_period(ppa):
    """The period a PPA record was BUILT at. Field first, label only as fallback.

    THE GUARD BELOW WAS BLIND TO 60 OF 96 RECORDS. It read the period out of
    the label, and _LABEL_PER_RE matches `_fx<N>` and nothing else -- so every
    record written under the later `_pin19p25` convention, plus the `_at_4p5`
    and bare-label ones, returned None and the superseded-pin check silently
    did not run. Its failure mode is an ABSENT note, so a row measured at a
    dead pin renders identically to one measured at the live pin.

    clk_period_ns is a field in every one of those records. Reading the field
    removes the naming convention from the decision. This is the same
    identify-by-filename defect that froze the charts, found in the scored
    table by sweeping for the pattern after fixing the charts.
    """
    try:
        return float(ppa.get("clk_period_ns"))
    except (TypeError, ValueError, AttributeError):
        return _label_period((ppa or {}).get("label", ""))


_OOP_CACHE = {}


def _out_of_path(task, sub):
    """A task.yaml `*_out_of_path_observation` for this submission, or None.

    Recorded by the task owner, guarded with IS_NOT_A_SCORED_VERDICT, and shown
    here ONLY inside a row that already says there is no scored verdict.
    """
    key = (task, sub)
    if key in _OOP_CACHE:
        return _OOP_CACHE[key]
    model = os.path.basename(sub or "")[:-3]
    out = None
    for d in glob.glob(os.path.join(REPO, "domains", "*", "design", task)):
        y = os.path.join(d, "task.yaml")
        if not os.path.exists(y):
            continue
        txt = open(y, errors="replace").read()
        # A YAML BLOCK ENDS WHERE THE INDENTATION RETURNS, not at the next line
        # that looks like a key. The first form of this used a `(?=^\s*\w+:)`
        # lookahead, which matched the block's OWN first child and captured a
        # single newline -- so it found the block, extracted nothing, and
        # rendered a row with the observation silently missing. That is the
        # failure this row exists to prevent, inside the code that prevents it.
        lines = txt.splitlines()
        key = f"{model}_out_of_path_observation:"
        for i, ln in enumerate(lines):
            if ln.strip().startswith(key):
                base = len(ln) - len(ln.lstrip())
                body = []
                for nxt in lines[i + 1:]:
                    if nxt.strip() and (len(nxt) - len(nxt.lstrip())) <= base:
                        break
                    body.append(nxt)
                blob = "\n".join(body)
                obs = re.search(r'observation:\s*"?([^"\n]+)', blob)
                if obs:
                    out = (obs.group(1).strip()
                           + " (hand-built invocation outside the scored path)")
                break
        break
    _OOP_CACHE[key] = out
    return out


_REFDIR_CACHE = {}


def _is_reference_file(task, sub):
    """True when `sub` names a file in this task's ref/ directory.

    A GUARD ON COUNT IS NOT A GUARD ON CORRECTNESS -- build_and_score.sh refused
    on more than one ref/*_ref.sv and still handed over the inner module of a
    two-file shim, because there was exactly one. So this asks where the file
    lives rather than how many match a pattern: references live in ref/,
    submissions live in candidates/, and nothing else is in either.
    """
    if task not in _REFDIR_CACHE:
        names = set()
        for d in glob.glob(os.path.join(REPO, "domains", "*", "design", task)) + \
                 glob.glob(os.path.join(REPO, "domains", "*", "verification", task)):
            cfg = os.path.join(d, "orfs", "config.mk")
            dn = None
            if os.path.exists(cfg):
                m = re.search(r"^\s*export\s+DESIGN_NAME\s*:?=\s*(\S+)",
                              open(cfg, errors="replace").read(), re.M)
                dn = m.group(1).strip() if m else None
            for f in glob.glob(os.path.join(d, "ref", "*.sv")):
                # LIVING IN ref/ IS NOT ENOUGH. A two-file shim puts BOTH halves
                # there -- sv39_mmu_ref.sv declaring sv39_mmu_ref_inner beside
                # sv39_mmu_top.sv declaring the contract module sv39_mmu -- and
                # labelling both "reference" put TWO reference rows in d_ca03,
                # one of them a build of the inner module produced by the
                # filename-based pick fixed in 5c3c1ff. The reference is the file
                # that DECLARES DESIGN_NAME, which is what reference_ppa.sh and
                # build_and_score.sh now select on. Same property, third site.
                if dn:
                    try:
                        if not re.search(r"^module\s+%s\b" % re.escape(dn),
                                         open(f, errors="replace").read(), re.M):
                            continue
                    except OSError:
                        continue
                names.add(os.path.basename(f))
        _REFDIR_CACHE[task] = names
    return os.path.basename(sub or "") in _REFDIR_CACHE[task]


def main():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from task_text_hash import task_text_hash
    # RESOLVED FROM DISK, FOR EVERY TASK. This was a hand-written map of three
    # verification tasks, so the stale-prompt guard covered 3 of 9 verification
    # tasks and 0 of 6 design tasks -- a task absent from the map was not
    # "checked and current", it was never checked, and it rendered as though it
    # were. d_dsp02's spec was rewritten (hash 5ad30593403b4ae2 ->
    # 13e3c4673f8a3270) and all five of its landed candidates kept rendering as
    # current results against a superseded text.
    #
    # Same defect as the SUBMISSIONS tuple that dropped claude.sv: an allowlist
    # whose failure mode is a silent omission rather than an error.
    CUR_TT = {}
    for _p in sorted(glob.glob(os.path.join(REPO, "domains", "*", "*", "*"))):
        if not os.path.isfile(os.path.join(_p, "task.yaml")):
            continue
        try:
            CUR_TT[os.path.basename(_p)] = task_text_hash(_p)[0]
        except Exception:
            # A task whose text cannot be hashed (no recognised prompt) yields
            # None, and None DISABLES the comparison rather than failing every
            # row: absence of a current hash is not evidence a record is stale.
            CUR_TT[os.path.basename(_p)] = None

    recs = load_records()
    tds = task_dirs()

    # A PPA RECORD BELONGS TO A FILE, NOT TO A PATH. Joining sim and ppa by
    # (task, submission path) pairs whatever was last built with whatever was
    # last simulated, and a re-solicited candidate reuses the path. d_ca01/chat
    # was published at 753,209 um2 from file cf95eab393791aa7 beside a
    # correctness verdict for 0acf79073ae3fa2e -- a real area, correctly
    # measured, attributed to a submission that no longer exists.
    #
    # The sim record defines the submission; a ppa record whose
    # submission_sha256_16 disagrees is DROPPED, so the row renders with no
    # area rather than someone else's.
    joined = {}
    for r in recs:
        key = (r.get("task"), os.path.basename(r.get("submission", "?")))
        slot = joined.setdefault(key, {"sim": None, "ppa": None})
        k = r.get("kind")
        if k in slot:
            if slot[k] is None or r["timestamp_utc"] >= slot[k]["timestamp_utc"]:
                slot[k] = r

    print("# Cross-model results\n")
    print(f"{len(TASK_TITLE)} design tasks. Every design that was run appears, including the")
    print("reference implementation each task is anchored on.\n")
    print("**Per-axis only — there is deliberately no combined score.** A single")
    print("figure of merit would have to weight area against frequency against")
    print("capability, and nothing here establishes those weights.\n")

    any_ungated = False
    for task in sorted(TASK_TITLE):
        rows = sorted([k for k in joined if k[0] == task], key=lambda x: x[1])
        # add build failures that produced no record at all
        for (t, sub) in BUILD_FAILURES:
            if t == task and (t, sub) not in rows:
                rows.append((t, sub))
        # AUDIT PROBES AND TASK-SHIPPED FILES ARE NOT SUBMISSIONS. Running one
        # writes a record like any other, and p3_ignores_sync_stages duly
        # appeared in the published d_ca04 table as though a model had produced
        # it. A probe exists to test the harness; listing it beside candidates
        # invites the reader to score it.
        rows = [(t_, s) for (t_, s) in rows
                if s.endswith("_ref.sv")          # the anchor DOES belong here
                or not re.match(r"^(p\d|c\d\d|m[A-Z0-9]|fm_|fn_|tt_|nc\d|"
                                r"stub_|probe_|ref_|.*second_source)", s)]

        # Models held back until there are enough results to report. EXCLUDED
        # rather than shown blank: a blank row invites the reader to wonder what
        # went wrong, and nothing went wrong -- there is simply not enough yet.
        rows = [(t, s) for (t, s) in rows
                if s[:-3] not in WITHHELD_MODELS]
        if not rows:
            continue

        mets = scored_metrics(tds.get(task, ""))
        print(f"\n## {TASK_TITLE[task]}\n")

        hdr = ["design", "correctness", "area (µm²)", "power (mW)", "Fmax (MHz)"]
        for k, _e, _r in mets:
            hdr.append(READABLE.get(k, (k, ""))[0])
        hdr.append("notes")
        print("| " + " | ".join(hdr) + " |")
        print("|" + "|".join("---" for _ in hdr) + "|")

        # REFERENCE DESIGN POINT for this task, so a choice can be compared
        # against it. Without this an area ratio is printed as a quality gap
        # when it may be a different design point measured honestly.
        _ref_allm, _ref_area = {}, None
        for _k2 in rows:
            _v2 = joined.get(_k2) or {}
            _s2 = _v2.get("sim") or {}
            if "/ref/" in (_k2[1] or "") or (_k2[1] or "").endswith("_ref.sv"):
                # KEEP THE PER-CONFIGURATION MAP, do not merge it. Merging
                # every configuration into one dict leaves whichever was written
                # last, so a row at DEPTH=8 was compared against the reference's
                # DEPTH=4 numbers and every design, including the reference
                # itself, was reported as sitting at a different design point.
                _ref_allm = _s2.get("metrics") or {}
                _p2 = _v2.get("ppa") or {}
                if _p2.get("design_area_um2"):
                    try: _ref_area = float(_p2["design_area_um2"])
                    except (TypeError, ValueError): pass
        _roles = metric_roles(tds.get(task, ""))

        _cur_tt = CUR_TT.get(task)
        _stale_design = []
        for key in list(rows):
            _s = (joined.get(key) or {}).get("sim") or {}
            _rh = _s.get("task_text_hash")
            # "unknown" is the ABSENCE of a recorded hash, not a different one.
            # A record written before hashing existed has not been shown to
            # answer a stale prompt; rule 20 says absence renders as absence,
            # never as a negative verdict.
            if _cur_tt and _rh not in (None, "", "unknown") and _rh != _cur_tt:
                _stale_design.append((key[1], _rh)); rows.remove(key)

        for key in rows:
            sub = key[1]
            v = joined.get(key, {"sim": None, "ppa": None})
            _s_sha = ((v.get("sim") or {}).get("submission_sha256_16"))
            _p_sha = ((v.get("ppa") or {}).get("submission_sha256_16"))
            if v.get("ppa") and _s_sha and _p_sha and _s_sha != _p_sha:
                v = dict(v); v["ppa"] = None      # stale build, not this file
            sim, ppa = v["sim"], v["ppa"]
            notes = []

            # THE SECOND SOURCE IS NOT THE REFERENCE. `"_ref" in sub` matches
            # `<top>_alt_ref.sv` too, so the alternative implementation -- a
            # deliberately different legal design, carried to prove the
            # testbench is not fitted to the reference's incidental choices --
            # rendered as a second row named **reference**, with different
            # metrics and no PPA. Two rows with one name and no way to tell
            # which is the anchor is worse than either row alone.
            is_alt_ref = "_alt_ref" in sub
            # `_top.sv` IS A REFERENCE TOO. d_ca03 and d_ai01 ship two-file
            # shims -- <design>_ref.sv holding the inner module and
            # <design>_top.sv declaring the contract module -- and it is the
            # _top file the harness actually runs. Without this, d_ai01's
            # reference rendered as a plain `fp16_gemm_array_top` row reading
            # 2/2 pass, indistinguishable from a submission, in the same table
            # whose whole purpose is comparing submissions AGAINST it.
            #
            # Same defect as reference_ppa.sh picking `ls ref/*_ref.sv | head -1`
            # and gating the file it picked: identifying the reference by its
            # filename rather than by what it is. Third site.
            # IDENTIFIED BY WHAT IT IS, NOT BY WHAT IT IS CALLED. This read
            # `"_ref" in sub` plus three hardcoded prefixes, and when d_ai01's
            # two-file shim broke it I added `endswith("_top.sv")` -- extending
            # the enumeration rather than replacing it, in the same session in
            # which I was fixing three other sites by property. A fifth pattern
            # would have been added the next time a task named a file something
            # else.
            #
            # The property: a reference lives in the task's own ref/ directory.
            # Nothing else does -- submissions live under candidates/.
            is_ref = (not is_alt_ref) and _is_reference_file(task, sub)
            # A NEGATIVE CONTROL THAT FAILS IS THE CONTROL WORKING, and it was
            # rendering as `0/2 FAIL` in the same column, same words, as a model
            # that failed. The table's stated policy is that every design which
            # ran appears -- correct -- but a reader cannot tell an artefact
            # BUILT TO FAIL from a submission that did, and the two mean opposite
            # things about the task. Every control in the repo is named nc_*;
            # there are 25 across seven design tasks.
            is_control = sub.startswith("nc_")
            name = ("**reference**" if is_ref
                    else "**second source**" if is_alt_ref
                    else f"`{sub[:-3]}` — *negative control, expected to fail*"
                    if is_control
                    else f"`{sub[:-3]}`")

            cf = CORRECTNESS_FAILURES.get(key)
            if cf and not BUILD_FAILURES.get(key):
                print("| " + " | ".join([name, "**FAILS**", "n/a", "n/a", "n/a"]
                                        + ["n/a"] * len(mets)
                                        + [f"**fails correctness** — {cf}; no PPA, "
                                           f"a number for a design that fails its "
                                           f"contract is not a result"]) + " |")
                continue

            # THE RECORD OUTRANKS THE MAP. BUILD_FAILURES is a hand-written
            # table of who failed to build, and it goes stale the moment a
            # candidate is re-solicited: d_nw01/gemini was listed here as
            # "rejected by slang (13 errors)" while its current submission
            # builds and fails 0/16, and d_nw01/claude -- which IS now slang
            # rejected -- was absent and rendered as a bare FAIL. Sixth
            # hand-written list in this file to go stale the same way.
            #
            # Records carry build_status since slang rejections started writing
            # one; the map is kept only for submissions that predate that.
            bf = BUILD_FAILURES.get(key)
            _bs = (sim or {}).get("build_status")
            if _bs == "slang_tool_error":
                # A TOOL FAILURE IS NOT A BUILD FAILURE AND MUST NOT SCORE ZERO.
                # This fell through to the generic branch below and rendered
                # "did not build" with 0/0/0 under rule 19 -- blaming the
                # submission for the host, which is the exact defect F56 and the
                # whole slang gate exist to prevent, reappearing at the point of
                # DISPLAY after being fixed at the point of measurement.
                #
                # The scored answer is that there is no scored verdict. The row
                # says so, in those words, and carries dashes rather than zeros:
                # a zero is a SCORE and nothing was scored.
                _oop = _out_of_path(task, sub)
                notes.append(
                    "**no scored verdict — synthesis frontend tool failure**, not "
                    "a statement about this design: "
                    + str((sim or {}).get("build_error") or "")[:160])
                if _oop:
                    # Jack's ruling: a Verilator verdict is NOT recordable as a
                    # scored verdict when slang has failed -- the scored path
                    # defines what counts. But "no verdict" where one is
                    # obtainable is an absence that reads like a fact (F91), so
                    # the out-of-path measurement is shown, labelled, with its
                    # provenance, in a form that cannot be read as a verdict.
                    notes.append("*out-of-path observation, NOT A SCORED VERDICT* — "
                                 + _oop)
                print("| " + " | ".join(
                    [name, "*no scored verdict (tool failure)*", "—", "—", "—"]
                    + ["—"] * len(mets)
                    + ["; ".join(notes)]) + " |")
                continue
            if _bs == "slang_rejected":
                bf = ((sim or {}).get("build_error")
                      or "rejected by slang, the synthesis frontend")
            elif _bs:
                bf = f"{_bs.replace('_', ' ')}: " + str((sim or {}).get("build_error") or "")
            elif sim is not None and (sim or {}).get("configs_total"):
                bf = None      # it built; whatever the map says is out of date
            if bf:
                # Rule 19: zero on the PPA axes, because a design that does not
                # build cannot be operated. But the METRIC cells are not zero --
                # nothing was measured, and "0" would read as "it built and
                # measured nothing". The zero is a SCORE; the metrics are absent.
                print("| " + " | ".join([name, "**did not build**", "**0**", "**0**", "**0**"]
                                        + ["n/a"] * len(mets)
                                        + [f"**build failure** — {bf}"]) + " |")
                continue

            corr = "—"
            if sim:
                corr = (f"**{sim.get('configs_passed')}/{sim.get('configs_total')} pass**"
                        if sim.get("all_passed")
                        else f"{sim.get('configs_passed')}/{sim.get('configs_total')} FAIL")
                # A CONFIG THAT PRODUCED NO VERDICT IS NOT A CONFIG THAT FAILED, and the
                # record has said so all along -- configs_no_verdict is written by
                # write_run_record and, until now, read by nothing. 7 records carry a
                # non-zero value, the newest from 2026-08-27, so this is live rather than
                # historical. Rolling it into the FAIL count makes a run that could not be
                # scored indistinguishable from one that was scored and lost.
                # A COMBINATIONAL LOOP MAKES A VERDICT A SETTLE-ORDER ARTEFACT,
                # and the field recording it was written on 104 records and read
                # by nothing. Verilator's UNOPTFLAT/ALWCOMBORDER mean the
                # simulator picked an evaluation order for a cycle the design
                # does not resolve; the pass or fail that follows is a property
                # of that choice, not of the hardware. d_ca05's reference passes
                # 1/1 with six such warnings, and the PC flagged the run's
                # verdicts as artefacts on exactly this ground.
                #
                # Third instance of F91 in this function after configs_no_verdict
                # and expected_verdict: written, carried, never read. The count
                # is surfaced rather than used to withhold, because the loop
                # makes the verdict UNRELIABLE rather than wrong, and deciding
                # which is the reader's job.
                _cl = sim.get("comb_loop_configs")
                try:
                    _cl = int(_cl)
                except (TypeError, ValueError):
                    _cl = 0
                # CORRECTED. This first said the verdicts were "artefacts of
                # that choice rather than results", which conflated UNOPTFLAT
                # with a convergence failure. Verilator reports UNOPTFLAT when a
                # signal has a circular combinational path and it must ITERATE
                # to settle; it still reaches the fixed point, which is the
                # value any correct simulator reaches. The unscorable case is
                # the model failing to converge, which is a different message
                # and is now counted separately as nonconverged_configs.
                #
                # Measured on d_ca05/claude: 4 UNOPTFLAT warnings, ZERO
                # convergence failures. Its 0/1 is a real result -- "p0 grants:
                # got 30, the anchor gives 20" is an arbitration difference --
                # and withholding it would have discarded a correct measurement.
                _nc = sim.get("nonconverged_configs")
                try:
                    _nc = int(_nc)
                except (TypeError, ValueError):
                    _nc = 0
                if _nc:
                    notes.append(f"**{_nc} configuration(s) DID NOT CONVERGE** — "
                                 f"the model never reached a fixed point, so no "
                                 f"verdict from those configurations is scorable "
                                 f"(rule 23)")
                elif _cl:
                    notes.append(f"{_cl} configuration(s) carried a combinational-"
                                 f"loop warning; Verilator iterated to a fixed "
                                 f"point and every configuration converged, so "
                                 f"the verdict stands")
                _nv = sim.get("configs_no_verdict")
                try:
                    _nv = int(_nv)
                except (TypeError, ValueError):
                    _nv = 0
                if _nv:
                    corr += f" ({_nv} no verdict)"
                # THE EXPECTED VERDICT, WHERE THE TASK DECLARES ONE. Controls are expected
                # to FAIL and a reader applies that rule, which is correct for every control
                # in the corpus except an INVERTED one -- d_ai01's nc_h_echo_band_only is
                # expected to PASS, and that PASS is the measurement. It is the single row
                # where a lost verdict reads as an ordinary failing control rather than as
                # something wrong.
                #
                # 0d11eaa put expected_verdict into the record and gave it no reader, which
                # is F91: a field nothing reads cannot be wrong, and that is not the same as
                # being right. This is the reader.
                _ev = sim.get("expected_verdict")
                if _ev:
                    _got = "PASS" if sim.get("all_passed") else "FAIL"
                    corr += (f" — as declared ({_ev})" if _got == _ev
                             else f" — **DECLARED {_ev}, GOT {_got}**")

            area = power = fmx = "—"
            unavail = PPA_UNAVAILABLE.get(key)
            if unavail and not ppa:
                area = power = fmx = "n/a"
                notes.append(f"**area, power and Fmax unavailable** — {unavail}")
            if ppa:
                # RULE 22 -- A BUILD THAT MISSED TIMING PRODUCES NO REPORTABLE
                # PPA. Area and power from a design that does not close at the
                # clock it was built at describe a circuit that cannot run
                # there, and the record is perfectly accurate about a build that
                # is invalid. Two published figures were exactly this before the
                # rule existed: d_nw01/chat at 2,141,894 um2 (wns -3.03) and
                # d_dsp02/chat at 440,336 um2 (wns -0.697). Both were found by
                # eye, and only because slack happened to be printed next to
                # area during an audit -- checking numbers against records would
                # have passed them, because the records were right.
                wns = ppa.get("wns_ns")
                timing_met = True
                if wns not in (None, "", "None"):
                    try:
                        timing_met = float(wns) >= 0.0
                    except ValueError:
                        timing_met = True          # unparseable: do not invent
                if not timing_met:
                    area = power = "withheld"
                    notes.append(
                        f"**PPA withheld — the build did not meet timing** "
                        f"(slack {float(wns):+.3f} ns at "
                        f"{ppa.get('clk_period_ns')} ns). Area and power from a "
                        f"design that does not close describe a circuit that "
                        f"cannot run at that clock (rule 22).")
                else:
                    a = ppa.get("design_area_um2")
                    area = f"{int(float(a)):,}" if a else "—"
                    pw = ppa.get("power_w")
                    power = f"{float(pw)*1000:.1f}" if pw else "—"
                if not ppa.get("correctness_gate"):
                    notes.append("PPA predates the correctness interlock")
                    any_ungated = True
                # A PPA NUMBER MEASURED AT A SUPERSEDED PIN IS AN ANSWER TO A
                # QUESTION THE TASK NO LONGER ASKS. Every candidate for a task
                # is built at one period, stated in the spec before
                # solicitation, so that area cannot be bought by relaxing the
                # clock -- that is what makes the column comparable at all.
                # d_ca01's reference was publishing 578,032 um2 at 100 MHz from
                # a reference_fx10.0 build while the spec pins the task at 15.0
                # ns, with nothing in the row saying so, in a table whose other
                # seven tasks are at their current pins.
                _pin = _spec_pin(task)
                _lab_per = _build_period(ppa)
                if _pin is not None and _lab_per is not None and \
                        abs(_pin - _lab_per) > 1e-9:
                    notes.append(
                        f"**measured at a superseded pin** — built at "
                        f"{_lab_per:g} ns; this task is pinned at {_pin:g} ns, "
                        f"so this is not comparable with rows at the pin")
            f_mhz, f_per = fmax_for(task, sub)
            if f_mhz:
                fmx = f"{f_mhz:.1f}"
            elif ppa:
                # Short: this stretched the Fmax column past the terminal width
                # in the fixed-width render. The build period is in the PPA
                # record and is not an Fmax, so it does not belong in this cell.
                fmx = "not swept"

            cells = [name, corr, area, power, fmx]
            # Metrics AT THE SCORED CONFIGURATION only. The first version
            # merged every config with dict.update, so each row showed whichever
            # config happened to be written last -- d_ca04's FIFO capacity read
            # 18 where the scored config gives 6.
            allm = ((sim or {}).get("metrics") or {})
            want = SCORED_CFG.get(task)
            if want is None:
                # Single-config task. If a run ever carries more than one, that
                # is ambiguity, not a choice to make silently (rule 20).
                if len(allm) == 1:
                    merged = next(iter(allm.values()))
                else:
                    merged = {}
                    if len(allm) > 1:
                        notes.append("multiple configurations present; no single "
                                     "scored configuration named")
            else:
                merged = allm.get(want, {})
                if allm and want not in allm:
                    notes.append(f"scored configuration {want} not present in this run")
            # Compare against the reference AT THE SAME CONFIGURATION, and
            # never compare the reference against itself.
            _is_ref = ("/ref/" in (sub or "")) or (sub or "").endswith("_ref.sv")
            _ref_m = {}
            if not _is_ref:
                _rv = _ref_allm.get(want) if want else None
                if isinstance(_rv, dict):
                    _ref_m = _rv
                elif len(_ref_allm) == 1:
                    _only = list(_ref_allm.values())[0]
                    _ref_m = _only if isinstance(_only, dict) else {}
                if not _ref_m:
                    _ref_m = {a: b for a, b in _ref_allm.items()
                              if not isinstance(b, dict)}
            _choice_differs = []
            for k, expect, _role in mets:
                # A CHOICE THAT DIFFERS FROM THE REFERENCE'S makes the area
                # ratio not like-for-like. Recorded here and reported in the
                # notes rather than silently folded into the number.
                if (_role == "choice" and k in merged and k in _ref_m
                        and str(merged[k]) != str(_ref_m[k])):
                    _choice_differs.append(f"{k} {merged[k]} vs reference {_ref_m[k]}")
                if k not in merged:
                    cells.append("—")
                elif expect is not None and str(merged[k]) != str(expect):
                    pre = PREDATES_REQUIREMENT.get(key)
                    if pre:
                        # NOT a model failure. The submission answered the spec
                        # it was given, and the requirement was added later.
                        cells.append(f"{merged[k]} *(req. added later)*")
                        notes.append(f"**not scored against the current spec** — {pre}")
                    else:
                        cells.append(f"**{merged[k]}** (spec requires {expect})")
                        notes.append(f"does not implement the scored configuration: "
                                     f"{READABLE.get(k,(k,''))[0]} is {merged[k]}, "
                                     f"specification requires {expect}")
                else:
                    cells.append(str(merged[k]))
            # NOT LIKE-FOR-LIKE, said plainly. The area is real and correctly
            # measured; what it is not is a comparison of two designs at the
            # same operating point.
            if _choice_differs and any(c not in ("n/a", "—", "**0**") for c in cells[2:4]):
                notes.append("**different design point** (" +
                             "; ".join(_choice_differs) +
                             "): area is correct but not like-for-like")
            # AREA PER UNIT OF CAPABILITY. Raw area credits a design for being
            # small when it was doing less; per-unit says how much it paid for
            # what it delivers. Both, never the normalised figure alone --
            # control logic is roughly fixed, so per-unit mildly flatters the
            # larger design.
            for k, _e2, r2 in mets:
                if r2 != "capability" or k not in merged:
                    continue
                try:
                    a_um = float((v.get("ppa") or {}).get("design_area_um2"))
                    cap = float(merged[k])
                    if cap > 0 and a_um > 0:
                        per = a_um / cap
                        extra = ""
                        if _ref_area and _ref_m.get(k) and not _is_ref:
                            rp = _ref_area / float(_ref_m[k])
                            if rp > 0:
                                extra = f", {per/rp:.2f}x the reference per unit"
                        notes.append(f"{per:,.0f} um2 per unit of {k}{extra}")
                except (TypeError, ValueError, ZeroDivisionError):
                    pass
            cells.append("; ".join(notes) if notes else "")
            print("| " + " | ".join(cells) + " |")

        # NAMED, NEVER DROPPED. A row removed without a line here would be
        # indistinguishable from a submission that was never made, which is the
        # disappearance this guard exists to prevent.
        for _s, _h in _stale_design:
            print(f"| `{display_name(os.path.basename(_s)[:-3])}` | "
                  f"*not scored against this prompt* | — | — | — | "
                  + "".join("— | " for _ in mets)
                  + f"last run answered task text `{_h}`; the task text is now "
                    f"`{_cur_tt}` |")

        if mets:
            for k, _e, _r in mets:
                lbl, desc = READABLE.get(k, (k, ""))
                if desc:
                    print(f"- **{lbl}** — {desc}")

    print("\n---\n")
    print("## Two measurement questions still open\n")
    print("Both affect how a number should be read, not whether it was measured.\n")
    print("**1. What the d_nw01 capacity figure counts.** The checker's own")
    print("comment predicts the reference reaching `MAX_TRANS + 1` = 9 at")
    print("`MAX_TRANS = 8`. It measures 27, consistently, across every geometry —")
    print("while at `MAX_TRANS = 2` it measures exactly 3, which *is* `MAX_TRANS + 1`.")
    print("The relation holds at one depth and not the other. The figures remain")
    print("comparable between designs, since every design is measured by the same")
    print("harness at the same configuration, but the units are not established")
    print("and nothing here should be read as \"27 concurrent transactions\".\n")
    print("**2. Whether the d_ca04 crossing latencies are comparable at all.**")
    print("Minimum crossing latency scales differently on each design: the")
    print("`gemini` submission tracks the synchroniser depth exactly (2 stages →")
    print("2 cycles, 3 → 3), `chat` tracks depth plus one, and **the reference is")
    print("flat at 3 regardless of depth**. Two of those are a plausible design")
    print("tradeoff. The third suggests the reference's fastest path may not")
    print("traverse the full synchroniser chain — in which case the metric is")
    print("sampling something different on that design and the three numbers are")
    print("not a like-for-like comparison. This also decides whether `gemini`'s")
    print("2-cycle crossing is a genuine result or an artefact. Unresolved.\n")

    # ---- verification tasks, SEPARATE TABLE, data-driven ------------------
    # EVERY VERIFICATION TASK WITH SUBMISSIONS, DERIVED FROM DISK. These were
    # two hand-written maps naming three tasks, so the verification section
    # covered 3 of 8 tasks that have submissions -- v_ca03, v_ca04, v_nw02,
    # v_nw04 and v_ai02 were simply absent from the report, with nothing saying
    # so. Third instance of this shape in one file, after the SUBMISSIONS tuple
    # that dropped claude.sv and the VTASK_DIR map that disabled the
    # stale-prompt guard on 12 of 15 tasks.
    #
    # The title comes from task.yaml where it has one, and the reference row is
    # whichever record was run from the task's own tb/ directory -- a role, not
    # a filename, so it cannot go stale when a file is renamed.
    VTASKS, VREF = {}, {}
    for _td in sorted(glob.glob(os.path.join(REPO, "domains", "*", "verification", "v_*"))):
        _tk = os.path.basename(_td)
        if not os.path.isfile(os.path.join(_td, "task.yaml")):
            continue
        _y = open(os.path.join(_td, "task.yaml"), encoding="utf-8", errors="replace").read()
        _m = re.search(r"^[ \t]*title:[ \t]*(.+)$", _y, re.M)
        _tb = re.search(r"^[ \t]*tb_module:[ \t]*(\S+)", _y, re.M)
        # Fall back to the descriptive half of the directory name, not the
        # whole thing: "v_ai02 — v_ai02_stream_realign" reads as a stutter.
        _title = (_m.group(1).strip().strip('"\'') if _m
                  else " ".join(_tk.split("_")[2:]).replace("_", " ") or _tk)
        VTASKS[_tk] = (f"{_tk.split('_')[0]}_{_tk.split('_')[1]} — {_title}",
                       _tb.group(1) if _tb else "")
        for _f in sorted(glob.glob(os.path.join(_td, "tb", "*.sv"))):
            VREF[_tk] = os.path.basename(_f)
            break
    # DERIVED FROM DISK, NOT LISTED HERE. A hardcoded tuple of model filenames
    # silently drops any model not in it, and it did: `claude.sv` submissions
    # existed for v_ca03 and were absent from this table because the tuple had
    # never been updated. A list of who counts as a competitor is a list that
    # goes stale every time a new model is added, and its failure mode is a
    # missing row rather than an error.
    #
    # This is only safe because `candidates/` now holds submissions and nothing
    # else: the reference testbenches that used to sit there as
    # `candidates/<task>/reference.sv` were byte-identical duplicates of each
    # task's own tb/, and they are gone. Membership of the directory IS the
    # definition of a submission, so there is nothing left to filter by name.
    SUBMISSIONS = tuple(sorted({
        os.path.basename(f)
        for f in glob.glob(os.path.join(REPO, "candidates", "*", "*.sv"))
    }))

    # RULE 17 / F38, applied to the report itself. The prompt document is part
    # of the task text: v_ca05, v_nw03 and v_dsp02 were all re-prompted, so a
    # record written against the old text answers a DIFFERENT question and must
    # not share a table with one written against the new text.


    print("\n---\n")
    print("# Verification tasks\n")
    print("**A different measurement, on its own table on purpose.** A verification")
    print("submission is a *testbench*: it is judged by which implementations it")
    print("accepts and rejects, and there is no area or frequency to report.")
    print("Averaging it with the design results would combine things that do not")
    print("share units.\n")
    print("The model is given a port map and a written specification. **It never")
    print("sees the RTL.**\n")

    vrecs = {}
    for r in recs:
        tk = r.get("task")
        if tk in VTASKS and r.get("kind") == "sim":
            sub = os.path.basename(r.get("submission", "?"))
            prev = vrecs.get((tk, sub))
            if not prev or r["timestamp_utc"] >= prev["timestamp_utc"]:
                vrecs[(tk, sub)] = r

    for tk, (title, tbmod) in VTASKS.items():
        rows = ([VREF[tk]] if tk in VREF else []) \
               + [s for s in SUBMISSIONS if (tk, s) in vrecs]
        rows = [s for s in rows if (tk, s) in vrecs]
        if not rows:
            continue
        print(f"\n## {title}\n")
        _cur = CUR_TT.get(tk)
        if _cur:
            print(f"Rows below answer task text `{_cur}` (spec + the prompt the")
            print("model is handed). A submission scored against a different")
            print("prompt is a different question and is not listed.\n")
            # GROUPING IS RECORDED, NOT SCORED, AND A READER CANNOT INFER THAT.
            # Several verification clauses share one observation, one check and
            # one reported id, so a submission testing any of them is credited
            # with all -- and eight checks in the corpus ALREADY name a combined
            # id today ("A3/A5", "F1/F2", "W2/W3" and five more), with v_dsp02
            # selecting its reported clause at RUNTIME from four by nested
            # ternary. None of that reaches these numbers: nothing in
            # report_table.py, collect_results.py or make_charts.py reads a
            # clause id at all. The columns below score mutant kills, the
            # discrimination gates and the acceptance outcomes.
            #
            # Said here because the omission is invisible otherwise. A reader who
            # sees clause ids in a spec and fault counts in a table will assume
            # the second is per-clause unless told, and the annotation convention
            # AGENT-VERIF-A2 is landing makes grouping legible in the SPEC while
            # leaving these numbers exactly as they were.
            print("*Clause grouping is recorded in the specifications, not scored"
                  " here.* Several clauses share one observation and one reported"
                  " id; the columns below count mutants killed and gate outcomes,"
                  " and read no clause id. A fault count is not a per-clause"
                  " score.\n")
        print("| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |")
        print("|---|---|---|---|---|---|---|")
        _stale = []
        for sub in list(rows):
            _rh = vrecs[(tk, sub)].get("task_text_hash")
            if _cur and _rh and _rh != _cur:
                _stale.append((sub, _rh)); rows.remove(sub)
        for sub in rows:
            r = vrecs[(tk, sub)]
            g = r.get("golden_accepted", "?")
            conf = r.get("conformant_accepted", "?")
            caught = r.get("faults_caught", "?")
            # RULE 23. `discriminates` is absent from every record written
            # before the gate existed. Rule 20: unmeasured renders ABSENT, not
            # "yes". Reading a missing field as a pass would silently certify
            # exactly the submissions the gate was built to catch.
            disc_raw = r.get("discriminates")
            disc = {"true": "yes", True: "yes",
                    "false": "**no**", False: "**no**"}.get(disc_raw, "—")
            # Rule 20: a record written before the second DUT was wired in has
            # not been measured against it. That renders absent, not "yes".
            d2raw = r.get("second_dut_accepted")
            d2 = {"PASS": "yes", "FAIL": "**no**", None: "—",
                  "not-run": "—", "unknown": "—"}.get(d2raw, "—")
            isref = (sub == VREF.get(tk))
            name = "**reference testbench**" if isref else f"`{display_name(sub[:-3])}`"
            note = ""
            # A submission that did not compile never set a golden verdict.
            if disc_raw in ("false", False) and g not in ("unknown", "?"):
                # INVALID. Not a low score -- a non-measurement. It returned
                # the SAME verdict on the golden and on a DUT with every
                # output tied to '1, so it cannot be distinguishing them, and
                # every number downstream of that is uninformative.
                gm = r.get("gate_mutant_verdict", "?")
                g_s = "yes" if g == "PASS" else "**no**"
                conf_s, caught_s = conf, "*withheld*"
                note = ("**INVALID** — same verdict on the golden DUT and on a "
                        f"deliberately broken one (golden={g}, broken={gm}), so "
                        "it is not measuring the design under test. Excluded "
                        "from scoring (rule 23)")
            elif g in ("unknown", "?") and conf in ("0/0", "?"):
                g_s, conf_s, caught_s, d2 = "**did not compile**", "n/a", "n/a", "n/a"
                note = "the testbench itself does not build"
            elif str(caught).startswith("SUPPRESSED") and g == "PASS":
                # Golden PASSED but the gate failed on a legal variant or the
                # second DUT. The count exists and is uninformative (rule 16).
                # This branch must NOT fire when the golden itself failed --
                # claiming "accepts correct design: yes" there would contradict
                # the row it is summarising.
                g_s, conf_s, caught_s = "yes", conf, "*withheld*"
                note = ("accepts the golden DUT but rejects a legal variant or "
                        "the second DUT, so it rejects some correct hardware — "
                        "its fault count carries no information")
            elif g == "PASS":
                g_s = "yes"
                conf_s = conf
                caught_s = f"**{caught}**"
                if isref:
                    note = "establishes the ceiling"
                elif conf.split("/")[0] != conf.split("/")[-1]:
                    note = "relies on behaviour the specification leaves open"
            else:
                g_s = "**no**"
                conf_s = conf
                caught_s = "*withheld*"
                d2 = d2 if d2raw == "FAIL" else d2
                note = ("rejects the correct design, so it rejects correct and "
                        "faulty hardware alike — a fault count from it carries "
                        "no information")
            print(f"| {name} | {disc} | {g_s} | {d2} | {conf_s} | {caught_s} | {note} |")
        for _s, _h in _stale:
            # DISTINGUISH the two reasons a row has no current-prompt record.
            # A file refused for TRANSPORT DAMAGE never reaches the harness and
            # so never writes one; labelling that "scored against an older
            # prompt" blames the task text for a paste corruption. Different
            # causes, different fixes -- re-paste vs re-run.
            _f = os.path.join(REPO, "candidates", tk.split("_")[0] + "_" +
                              tk.split("_")[1], _s)
            _dmg = False
            if os.path.isfile(_f):
                _dmg = subprocess.run(
                    [sys.executable, os.path.join(REPO, "scripts", "check_transport.py"), _f],
                    capture_output=True).returncode == 1
            if _dmg:
                print(f"| `{_s[:-3]}` | n/a | **damaged in transit** | n/a | n/a | n/a | "
                      "the file was corrupted on paste; a SETUP problem, "
                      "re-paste it — this is not a result about the model |")
            else:
                print(f"| `{_s[:-3]}` | — | *not scored against this prompt* | — | — | — | "
                      f"last run answered task text `{_h}` |")

    print()
    print("- **tells correct from broken** — the gate. Every testbench is run twice:")
    print("  once against the correct DUT and once against one with every output tied")
    print("  high. It must PASS the first and FAIL the second. A testbench that")
    print("  returns the same verdict on both is not observing the design at all, and")
    print("  no number after this column means anything. A file that drives nothing")
    print("  and prints PASS scores 0 here; before this column existed it was reported")
    print("  as merely having gaps in fault detection. A dash means the run predates")
    print("  the gate and was never measured against it.")
    print("- **accepts correct design** — does it pass a known-good implementation?")
    print("  A testbench that rejects correct hardware is unusable whatever else it")
    print("  catches, so this gates everything after it.")
    print("- **accepts 2nd implementation** — an INDEPENDENT correct design, not a")
    print("  variation of the reference: different internal structure, same contract.")
    print("  Passing the reference design alone cannot distinguish a testbench that")
    print("  checks the specification from one fitted to how this particular")
    print("  implementation happens to work. A dash means the run predates this")
    print("  column and was never measured against it.")
    print("- **accepts legal variants** — implementations differing from the reference")
    print("  only where the specification is deliberately silent. A correct testbench")
    print("  must accept all of them; failing one means it checked something the")
    print("  specification never promised.")
    print("- **catches faults** — implementations each carrying one deliberate defect.")
    print("  Every one is proven catchable by the reference testbench.\n")
    print("**Reported per fault, never as a rate**, and *withheld* where the")
    print("testbench failed the first column. A hang is likewise not a catch: the")
    print("testbench did not detect the fault, it stopped.\n")

    if any_ungated:

        print("\n---\n")
        print("**\"PPA predates the correctness interlock\"** — these place-and-route")
        print("numbers were produced before the pipeline required a passing")
        print("correctness run first. All the designs so marked have since passed")
        print("correctness, so the numbers stand; the note records that nothing")
        print("enforced the ordering at the time they were taken.")
    return 0


def _guarded_main():
    """Emit the table ONLY if it was generated in full.

    A NameError inside the row loop used to leave a SHORT TABLE: rows silently
    missing, exit status ignored, and every caller in this repo invoking the
    script as `report_table.py 2>/dev/null` so the traceback never appeared. A
    truncated artefact is worse than a crash -- a crash tells the reader
    something is wrong, and a table missing four rows tells them those designs
    were not run.

    That is the blank-reporting principle this file applies to its own subject,
    violated by its own harness: NO CONCLUSION rather than silence, CANDIDATE
    LIST rather than a bare count, "not measurable" rather than "nothing
    frozen". A partial table is a silence.

    So output is buffered and released only on success. On any exception the
    buffer is DISCARDED -- not flushed, because half a table is the thing being
    prevented -- and the failure goes to stderr with a non-zero exit.
    """
    buf = io.StringIO()
    real = sys.stdout
    try:
        sys.stdout = buf
        rc = main()
    except BaseException:
        sys.stdout = real
        sys.stderr.write(
            "\nreport_table.py FAILED -- NO TABLE WAS WRITTEN.\n"
            "The partial output was discarded deliberately: a table missing rows\n"
            "reads as 'those designs were not run', which is a different claim\n"
            "from 'the generator crashed'.\n\n")
        traceback.print_exc()
        return 3
    finally:
        sys.stdout = real
    real.write(buf.getvalue())
    return rc


if __name__ == "__main__":
    sys.exit(_guarded_main())
