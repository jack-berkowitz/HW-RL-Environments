#!/bin/bash
# MAC QUEUE -- cheap-and-many. Sweeps then common-clock builds, per task.
#
#   bash scripts/mac_sweep_queue.sh [--plan]
#
# ORDER IS CHEAPEST FIRST, deliberately: d_ca04 sweeps run 2-5 min/iteration
# and d_nw01 candidates have run 213, a hundredfold spread. Completing the cheap
# tasks first fills whole rows in the report early, so a machine that has to be
# stopped has produced usable rows rather than fragments of expensive ones.
#
# d_nw01 IS ABSENT ON PURPOSE -- the PC owns it. Two machines building the same
# task collide on the ORFS nickname and flow directory.
# d_ca01 IS ABSENT -- already built at a fixed 10.0 ns by fixed_clock_ppa.sh.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$REPO"
export LEC_CHECK="${LEC_CHECK:-0}"
LOG="$REPO/fmax_results/macqueue_$(date +%Y%m%d_%H%M%S).log"
PLAN=0; [ "${1:-}" = "--plan" ] && PLAN=1
say () { echo "$(date '+%H:%M:%S') $*" | tee -a "$LOG"; }

buildable () {
  python3 - "$1" <<'PY'
import glob, json, os, subprocess, sys
sub=sys.argv[1]; best=None
for f in glob.glob("runs/*/*__sim.json"):
    try: r=json.load(open(f))
    except Exception: continue
    if r.get("submission")!=sub: continue
    if best is None or r.get("timestamp_utc","")>=best.get("timestamp_utc",""): best=r
if not best or best.get("all_passed") is not True: print("no"); raise SystemExit
task=best.get("task") or ""
d=glob.glob(f"domains/*/*/{task}")
if d:
    rr=subprocess.run(["python3","scripts/task_text_hash.py",d[0]],capture_output=True,text=True)
    cur=rr.stdout.strip().split("\n")[0] if rr.returncode==0 else None
    rh=best.get("task_text_hash")
    if cur and rh not in (None,"","unknown") and rh!=cur: print("stale"); raise SystemExit
# THE SWEEP MUST MEASURE THE FILE ON DISK. ppa_candidate.sh snapshots the
# candidate, so a config generated before a re-solicitation sweeps a superseded
# submission -- that cost 19 hours on d_ca01 and is why this is checked here.
import hashlib
disk=hashlib.sha256(open(sub,'rb').read()).hexdigest()[:16]
print("yes" if best.get("submission_sha256_16")==disk else "filechanged")
PY
}
sweep () {   # task model seed
  local task="$1" m="$2" seed="$3" nick="${1}_cand_${2}_v2"
  local cand="candidates/${task}/${m}.sv"
  [ -f "$cand" ] || { say "MISSING $cand"; return 0; }
  local ok; ok="$(buildable "$cand")"
  [ "$ok" = "yes" ] || { say "SKIP sweep ${task}/${m} -- gate: $ok"; return 0; }
  [ -f "$REPO/fmax_results/${nick}_fmax.json" ] && { say "SKIP sweep $nick (done)"; return 0; }
  say "SWEEP $nick (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  [ -f "orfs_runs/$nick/config.mk" ] || bash scripts/ppa_candidate.sh "$task" "$cand" "${m}_v2" >>"$LOG" 2>&1 || true
  python3 scripts/find_fmax.py --design "$nick" --seed-period-ns "$seed" \
     --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
}
refsweep () {
  local task="$1" seed="$2" nick="${1}_v2"
  [ -f "$REPO/fmax_results/${nick}_fmax.json" ] && { say "SKIP sweep $nick (done)"; return 0; }
  say "SWEEP $task reference (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  python3 scripts/find_fmax.py --design "$task" --seed-period-ns "$seed" \
     --resolution-ns 0.5 --skip-sim-check --output-dir "$REPO/fmax_results" >>"$LOG" 2>&1
}
period_for () { python3 - "$REPO" "$@" <<'PY'
import json, os, sys
repo=sys.argv[1]; per=[]
for n in sys.argv[2:]:
    p=os.path.join(repo,"fmax_results",f"{n}_fmax.json")
    if os.path.isfile(p):
        d=json.load(open(p))
        if d.get("converged_period_ns"): per.append(float(d["converged_period_ns"]))
print(f"{max(per):.4f}" if per else "")
PY
}
build_at () {   # task label period
  local task="$1" label="$2" per="$3"
  if [ "$label" != "reference" ]; then
    local ok; ok="$(buildable "candidates/${task}/${label}.sv")"
    [ "$ok" = "yes" ] || { say "SKIP build ${task}/${label} -- gate: $ok"; return 0; }
  fi
  ls "runs/${task}"_*/*"__${label}_cc${per}__ppa.json" >/dev/null 2>&1 && \
     { say "SKIP build ${task}/${label} at ${per} (done)"; return 0; }
  say "BUILD ${task}/${label} at ${per} ns"
  [ "$PLAN" = "1" ] && return 0
  if [ "$label" = "reference" ]; then
    local cfg; cfg="$(find domains -path "*${task}_*/orfs/config.mk" | head -1)"
    CLK_PERIOD_NS="$per" bash scripts/run_orfs_build.sh "/work/$cfg" >>"$LOG" 2>&1 || say "  FAILED ${task}/reference"
  else
    CLK_PERIOD_NS="$per" bash scripts/ppa_candidate.sh "$task" \
      "candidates/${task}/${label}.sv" "${label}_cc${per}" >>"$LOG" 2>&1 || say "  FAILED ${task}/${label}"
  fi
}
task_round () {   # task seed model...
  local task="$1" seed="$2"; shift 2
  say "--- $task ---"
  refsweep "$task" "$seed"
  for m in "$@"; do sweep "$task" "$m" "$seed"; done
  local nicks="${task}_v2"; for m in "$@"; do nicks="$nicks ${task}_cand_${m}_v2"; done
  local P; P="$(period_for $nicks)"
  if [ -z "$P" ]; then say "$task: no periods, no builds"; return 0; fi
  say "$task common clock = ${P} ns"
  build_at "$task" reference "$P"
  for m in "$@"; do build_at "$task" "$m" "$P"; done
}

say "=== MAC QUEUE START ==="
task_round d_ca04  4.5   chat claude
task_round d_nw03  4.0   chat claude gemini
task_round d_dsp03 12.0  chat claude
task_round d_dsp02 20.25 chat claude
say "=== MAC QUEUE DONE ==="
