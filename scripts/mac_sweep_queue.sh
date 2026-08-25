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
converged () {   # $1 = fmax json -> true only if a frequency was actually found
  [ -f "$1" ] || return 1
  python3 -c "
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception: sys.exit(1)
sys.exit(0 if d.get('achieved_fmax_mhz') else 1)" "$1" 2>/dev/null
}

reclaim () {   # $1 = orfs nickname -- drop flow output once the record exists
  # ORFS keeps every intermediate stage: ~2 GB for a d_ca01-sized design, 6 GB
  # for the pre-C3 crossbar. Thirteen sweeps at 4-7 builds each fills any disk,
  # and it filled this one tonight. Once the record is written the numbers are
  # extracted and this is scratch.
  #
  # THE RECORD IS NEVER TOUCHED, only the flow output. Cost: check_ppa_record.py
  # can no longer re-verify that record against its artefacts and reports
  # "flow dir gone" -- a state it already handles for several records.
  local fd="${ORFS_FLOW_DIR:-$HOME/tools/OpenROAD-flow-scripts/flow}"
  for sub in results objects logs reports; do
    [ -d "$fd/$sub/sky130hd/$1" ] && rm -rf "$fd/$sub/sky130hd/$1"
  done
}

sweep () {   # task model seed
  local task="$1" m="$2" seed="$3" nick="${1}_cand_${2}_v2"
  local cand="candidates/${task}/${m}.sv"
  [ -f "$cand" ] || { say "MISSING $cand"; return 0; }
  local ok; ok="$(buildable "$cand")"
  [ "$ok" = "yes" ] || { say "SKIP sweep ${task}/${m} -- gate: $ok"; return 0; }
  # A FILE IS NOT A RESULT. find_fmax writes its json even when the seed run
  # fails -- achieved_fmax_mhz null, aborted_reason set. Nine sweeps aborted
  # that way during a Docker outage; skipping on mere existence would mark all
  # nine "done" and leave a table with no Fmax at all.
  if converged "$REPO/fmax_results/${nick}_fmax.json"; then
    say "SKIP sweep $nick (converged)"; return 0
  fi
  say "SWEEP $nick (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  # REGENERATE IF THE SNAPSHOT IS STALE, not merely if the config is absent.
  # ppa_candidate.sh copies the candidate into orfs_runs/<nick>/, and skipping
  # regeneration whenever config.mk exists silently re-sweeps whatever RTL was
  # snapshotted first. The PC hit exactly this: orfs_runs/d_nw01_cand_claude/
  # still held pre-C3 RTL at 0f35254446decbc2, so a restart would have measured
  # the superseded design a second time. It has already cost 19h here and 1h22m
  # there; the check is two lines.
  # COMPARE AGAINST THE TRANSFORM, NOT THE RAW FILE. ppa_candidate.sh:122
  # writes the snapshot as `LC_ALL=C sed 's/\xc2\xa0/ /g'` (NBSP -> space) with
  # a newline appended, so the raw candidate and its snapshot NEVER hash equal.
  # A guard that compares raw bytes therefore fires on every sweep, and firing
  # means a full regeneration -- an extra ORFS build per sweep, while looking
  # like it is working. Caught on the PC before it ran here.
  local snap; snap="$(ls "orfs_runs/$nick"/*.sv 2>/dev/null | head -1)"
  if [ -n "$snap" ] && [ -f "orfs_runs/$nick/config.mk" ]; then
    local a b
    a="$(shasum -a 256 "$snap" | cut -c1-16)"
    b="$( { LC_ALL=C sed $'s/\xc2\xa0/ /g' "$cand"; printf '\n'; } | shasum -a 256 | cut -c1-16)"
    if [ "$a" != "$b" ]; then
      say "  snapshot $a != candidate $b -- regenerating $nick"
      rm -rf "orfs_runs/$nick" "$REPO/fmax_results/${nick}_logs"
    fi
  fi
  [ -f "orfs_runs/$nick/config.mk" ] || bash scripts/ppa_candidate.sh "$task" "$cand" "${m}_v2" >>"$LOG" 2>&1 || true
  python3 scripts/find_fmax.py --design "$nick" --seed-period-ns "$seed" \
     --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
  reclaim "$nick"
  say "  reclaimed $nick  (free: $(df -h /System/Volumes/Data | tail -1 | awk '{print $4}'))"
}
refsweep () {
  local task="$1" seed="$2" nick="${1}_v2"
  # A FILE IS NOT A RESULT. find_fmax writes its json even when the seed run
  # fails -- achieved_fmax_mhz null, aborted_reason set. Nine sweeps aborted
  # that way during a Docker outage; skipping on mere existence would mark all
  # nine "done" and leave a table with no Fmax at all.
  if converged "$REPO/fmax_results/${nick}_fmax.json"; then
    say "SKIP sweep $nick (converged)"; return 0
  fi
  say "SWEEP $task reference (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  python3 scripts/find_fmax.py --design "$task" --seed-period-ns "$seed" \
     --resolution-ns 0.5 --skip-sim-check --output-dir "$REPO/fmax_results" >>"$LOG" 2>&1
  reclaim "$task"
  say "  reclaimed $task  (free: $(df -h /System/Volumes/Data | tail -1 | awk '{print $4}'))"
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
    reclaim "${task}_cand_${label}_cc${per}"
  fi
  say "  free: $(df -h /System/Volumes/Data | tail -1 | awk '{print $4}')"
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
