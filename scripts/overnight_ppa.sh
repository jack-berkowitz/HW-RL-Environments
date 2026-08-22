#!/bin/bash
# OVERNIGHT PPA + FMAX QUEUE.
#
#   bash scripts/overnight_ppa.sh            run it
#   bash scripts/overnight_ppa.sh --plan     print the job list and exit
#
# SEQUENTIAL BY CONSTRUCTION. One ORFS build at a time. Two containers competing
# for this machine is how a sweep gets slowed into a false timing failure, and
# concurrent load has already corrupted one batch of results here (F56).
#
# RESUMABLE. Every job checks for its own output first and skips if present, so
# an interrupted run can be restarted without repeating hours of P&R.
#
# TWO PHASES, and the second DEPENDS on the first. Phase 1 finds each design's
# own Fmax. Phase 2 builds every design in a task at ONE clock -- the slowest
# own-Fmax in that task -- because area and power are only comparable at a
# shared operating point, and a design built at a clock it cannot close has no
# reportable number at all (rule 22).
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
export LEC_CHECK=0          # Rosetta: CTS dies with SIGILL without this
LOG="$REPO/fmax_results/overnight_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$REPO/fmax_results"
PLAN=0; [ "${1:-}" = "--plan" ] && PLAN=1

say () { echo "$(date '+%H:%M:%S') $*" | tee -a "$LOG"; }

# ---- PHASE 1: Fmax sweeps for designs that do not have one ------------------
# task_id : candidate label : seed period ns
# d_dsp02 IS DELIBERATELY ABSENT. Its spec was rewritten (task text
# 5ad30593403b4ae2 -> 13e3c4673f8a3270), so all five landed submissions answer a
# superseded prompt and the report withholds their rows. Building PPA now would
# spend hours of P&R attaching fresh area and power to correctness that cannot
# be reported. The order that works is: re-run the submissions against the new
# spec, then build. Agent 3 owns d_dsp02 and is doing the re-runs.
SWEEPS=(
  "d_ca01:chat:10"
  "d_ca01:claude:10"
  "d_ca04:claude:4.5"
)

fmax_of () {  # $1 = nick -> prints achieved MHz, or nothing
  local j="$REPO/fmax_results/$1_fmax.json"
  [ -f "$j" ] || return 1
  python3 -c "
import json,sys
d=json.load(open('$j'))
v=d.get('achieved_fmax_mhz')
print(v if v else '', end='')" 2>/dev/null
}

run_sweep () {
  local task="$1" label="$2" seed="$3"
  local nick="${task}_cand_${label}"
  if fmax_of "$nick" >/dev/null 2>&1 && [ -n "$(fmax_of "$nick")" ]; then
    say "SKIP sweep $nick (already $(fmax_of "$nick") MHz)"; return 0
  fi
  local cand="candidates/${task}/${label}.sv"
  if [ ! -f "$cand" ]; then say "MISSING $cand -- skipping"; return 0; fi
  # ppa_candidate.sh generates orfs_runs/<nick>/config.mk pointed at this
  # candidate. Generating it is what makes the source path un-stale; a
  # hand-copied config inherits the neighbour's VERILOG_FILES.
  if [ ! -f "orfs_runs/$nick/config.mk" ]; then
    say "generating config for $nick"
    [ "$PLAN" = "1" ] || bash scripts/ppa_candidate.sh "$task" "$cand" "$label" >>"$LOG" 2>&1 || true
  fi
  say "SWEEP $nick (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  python3 scripts/find_fmax.py --design "$nick" --seed-period-ns "$seed" \
      --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
  say "  -> $(fmax_of "$nick" || echo 'no result') MHz"
}

# ---- PHASE 2: one clock per task, slowest own-Fmax in the row ---------------
# task : nicks whose Fmax must be considered : candidates to build
declare -a TASKS=("d_ca01" "d_ca04")

period_for () {  # slowest (largest) period across the task's measured designs
  local task="$1"; shift
  python3 - "$REPO" "$task" "$@" <<'PY'
import json, os, sys, glob
repo, task = sys.argv[1], sys.argv[2]
nicks = sys.argv[3:]
periods = []
for n in nicks:
    p = os.path.join(repo, "fmax_results", f"{n}_fmax.json")
    if not os.path.isfile(p):
        continue
    d = json.load(open(p))
    if d.get("converged_period_ns"):
        periods.append(float(d["converged_period_ns"]))
# THE SLOWEST DESIGN SETS THE CLOCK. Anything faster is asked to close at a
# period it already beats; anything slower would be reported at a clock it
# cannot meet, which rule 22 forbids outright.
print(f"{max(periods):.4f}" if periods else "")
PY
}

build_at () {   # task, label ("reference" or a model), period
  local task="$1" label="$2" per="$3"
  local tag="${task}_${label}_at_${per}"
  if ls "runs/${task}"_*/*"__${label}_at_${per}__ppa.json" >/dev/null 2>&1; then
    say "SKIP build $tag (record exists)"; return 0
  fi
  say "BUILD $task/$label at ${per}ns"
  [ "$PLAN" = "1" ] && return 0
  if [ "$label" = "reference" ]; then
    local cfg
    cfg="$(find domains -path "*${task}_*/orfs/config.mk" | head -1)"
    CLK_PERIOD_NS="$per" bash scripts/run_orfs_build.sh "/work/$cfg" >>"$LOG" 2>&1
  else
    CLK_PERIOD_NS="$per" bash scripts/ppa_candidate.sh "$task" \
        "candidates/${task}/${label}.sv" "${label}_at_${per}" >>"$LOG" 2>&1
  fi
}

say "=== OVERNIGHT QUEUE START (log: $LOG) ==="
say "--- phase 1: Fmax sweeps ---"
for s in "${SWEEPS[@]}"; do
  IFS=: read -r t l sd <<<"$s"
  run_sweep "$t" "$l" "$sd"
done

say "--- phase 2: common-clock PPA builds ---"
# d_ca01: reference sweep already done; candidates from phase 1
P="$(period_for d_ca01 d_ca01 d_ca01_cand_chat d_ca01_cand_claude)"
if [ -n "$P" ]; then
  for m in reference chat claude; do build_at d_ca01 "$m" "$P"; done
else say "d_ca01: no periods available, skipped"; fi

# d_ca04: four candidates already measured at 4.5; claude may lower the clock
P="$(period_for d_ca04 d_ca04 d_ca04_cand_chat d_ca04_cand_deepseek_scored \
      d_ca04_cand_gemini_own_fmax d_ca04_cand_qwen_at_4p5 d_ca04_cand_claude)"
if [ -n "$P" ]; then
  for m in reference chat deepseek gemini qwen claude; do build_at d_ca04 "$m" "$P"; done
else say "d_ca04: no periods available, skipped"; fi

# d_dsp02: intentionally not built here -- see the note on SWEEPS above.
say "d_dsp02: SKIPPED BY DESIGN (stale task text; re-run its sims first)"

say "=== OVERNIGHT QUEUE DONE ==="
