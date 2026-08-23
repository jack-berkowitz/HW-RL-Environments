#!/bin/bash
# FIXED-CLOCK PPA -- no Fmax sweeps.
#
#   bash scripts/fixed_clock_ppa.sh [--plan]
#
# WHY NO SWEEPS. A candidate Fmax sweep on d_ca01 costs ~5h PER ITERATION under
# Rosetta, so three candidates is 45-75h before a single comparable number
# exists. The common-clock rule does not need each design's own maximum: it
# needs ONE clock every design in the row closes at. The reference closes at
# 10.0 ns (+0.04 ns) and the previous chat.sv closed there with +0.236 ns, so
# 10.0 ns is the candidate common clock and each build CONFIRMS it by its own
# slack. A design that misses is reported as missing (rule 22), not silently
# rebuilt slower.
#
# The cost is the per-candidate own-Fmax column, which stays blank. That is a
# secondary axis; area and power at a shared clock is the primary comparison.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$REPO"
export LEC_CHECK="${LEC_CHECK:-0}"
LOG="$REPO/fmax_results/fixedclk_$(date +%Y%m%d_%H%M%S).log"
PLAN=0; [ "${1:-}" = "--plan" ] && PLAN=1
say () { echo "$(date '+%H:%M:%S') $*" | tee -a "$LOG"; }

buildable () {   # candidates/<task>/<model>.sv -> yes | no | stale
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
print("yes")
PY
}

build_at () {  # task, label(reference|model), period
  local task="$1" label="$2" per="$3"
  if [ "$label" != "reference" ]; then
    local ok; ok="$(buildable "candidates/${task}/${label}.sv")"
    [ "$ok" = "yes" ] || { say "SKIP ${task}/${label} -- correctness gate: $ok"; return 0; }
  fi
  if ls "runs/${task}"_*/*"__${label}_fx${per}__ppa.json" >/dev/null 2>&1; then
    say "SKIP ${task}/${label} at ${per} (already built)"; return 0; fi
  say "BUILD ${task}/${label} at ${per} ns"
  [ "$PLAN" = "1" ] && return 0
  if [ "$label" = "reference" ]; then
    local cfg; cfg="$(find domains -path "*${task}_*/orfs/config.mk" | head -1)"
    CLK_PERIOD_NS="$per" bash scripts/run_orfs_build.sh "/work/$cfg" >>"$LOG" 2>&1 \
      || say "  BUILD FAILED ${task}/reference"
  else
    CLK_PERIOD_NS="$per" bash scripts/ppa_candidate.sh "$task" \
      "candidates/${task}/${label}.sv" "${label}_fx${per}" >>"$LOG" 2>&1 \
      || say "  BUILD FAILED ${task}/${label}"
  fi
}

say "=== FIXED-CLOCK PPA START ==="
# d_ca01 at 10.0 ns -- reference measured +0.04 ns there
for m in reference chat claude gemini; do build_at d_ca01 "$m" 10.0; done
# d_nw01 at 9.0 ns -- the clock the previous chat closed at; only chat is eligible
# claude re-verified at 16/16 after a slang TOOL failure (exit 133, SIGTRAP
# under Rosetta) had been recorded as a rejection.
for m in reference chat claude;          do build_at d_nw01 "$m" 9.0;  done
# d_ca04 is small and already measured at 4.5 ns; claude is the only gap
for m in claude;                          do build_at d_ca04 "$m" 4.5;  done
say "=== FIXED-CLOCK PPA DONE ==="
