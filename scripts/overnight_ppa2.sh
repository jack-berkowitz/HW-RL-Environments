#!/bin/bash
# OVERNIGHT QUEUE, PART 2 -- d_nw03, d_dsp03, and d_nw01/claude.
#
# Chained behind scripts/overnight_ppa.sh rather than merged into it: that
# script is executing, and bash reads a script incrementally, so editing one
# mid-run can corrupt the running invocation. It also holds a ~4h Fmax sweep
# whose progress is lost if restarted, since find_fmax resumes per sweep and
# not per iteration.
#
# d_nw03 and d_dsp03 became buildable only in a6cdca2, which added their ORFS
# configs. They had none when part 1 was written.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
export LEC_CHECK=0
LOG="$REPO/fmax_results/overnight2_$(date +%Y%m%d_%H%M%S).log"
PLAN=0; [ "${1:-}" = "--plan" ] && PLAN=1
say () { echo "$(date '+%H:%M:%S') $*" | tee -a "$LOG"; }

# ONE ORFS AT A TIME, ACROSS BOTH SCRIPTS.
if [ "$PLAN" = "0" ]; then
  while pgrep -f "overnight_ppa.sh" >/dev/null; do sleep 60; done
fi

# CORRECTNESS GATE, CHECKED HERE AND NOT ASSUMED. A design that fails its
# contract, or whose record answers a superseded task text, has no reportable
# PPA (rule 22 for the first, rule 17/F38 for the second). Building it spends
# hours producing a number the report will refuse to print.
buildable () {   # $1 = candidates/<task>/<model>.sv
  python3 - "$1" <<'PY'
import glob, json, os, subprocess, sys
sub = sys.argv[1]
best = None
for f in glob.glob("runs/*/*__sim.json"):
    try: r = json.load(open(f))
    except Exception: continue
    if r.get("submission") != sub: continue
    if best is None or r.get("timestamp_utc","") >= best.get("timestamp_utc",""): best = r
if not best or best.get("all_passed") is not True:
    print("no"); raise SystemExit
task = best.get("task") or ""
d = glob.glob(f"domains/*/*/{task}")
if d:
    rr = subprocess.run(["python3","scripts/task_text_hash.py",d[0]],
                        capture_output=True, text=True)
    cur = rr.stdout.strip().split("\n")[0] if rr.returncode == 0 else None
    rh = best.get("task_text_hash")
    if cur and rh not in (None,"","unknown") and rh != cur:
        print("stale"); raise SystemExit
print("yes")
PY
}

sweep () {   # task, model, seed
  local task="$1" model="$2" seed="$3" nick="${1}_cand_${2}"
  local cand="candidates/${task}/${model}.sv"
  [ -f "$cand" ] || { say "MISSING $cand"; return 0; }
  local ok; ok="$(buildable "$cand")"
  [ "$ok" = "yes" ] || { say "SKIP sweep $nick -- correctness gate: $ok"; return 0; }
  if [ -f "$REPO/fmax_results/${nick}_fmax.json" ]; then say "SKIP sweep $nick (done)"; return 0; fi
  say "SWEEP $nick (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  [ -f "orfs_runs/$nick/config.mk" ] || bash scripts/ppa_candidate.sh "$task" "$cand" "$model" >>"$LOG" 2>&1 || true
  python3 scripts/find_fmax.py --design "$nick" --seed-period-ns "$seed" \
      --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
}
refsweep () {  # task, seed
  local task="$1" seed="$2"
  if [ -f "$REPO/fmax_results/${task}_fmax.json" ]; then say "SKIP sweep $task ref (done)"; return 0; fi
  say "SWEEP $task reference (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  python3 scripts/find_fmax.py --design "$task" --seed-period-ns "$seed" \
      --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
}
period_for () { python3 - "$REPO" "$@" <<'PY'
import json, os, sys
repo = sys.argv[1]; per=[]
for n in sys.argv[2:]:
    p = os.path.join(repo,"fmax_results",f"{n}_fmax.json")
    if os.path.isfile(p):
        d = json.load(open(p))
        if d.get("converged_period_ns"): per.append(float(d["converged_period_ns"]))
print(f"{max(per):.4f}" if per else "")
PY
}
build_at () {  # task, label, period
  local task="$1" label="$2" per="$3"
  # THE GATE APPLIES TO BUILDS, NOT ONLY TO SWEEPS. Without this a candidate
  # whose sweep was skipped for failing correctness still got built, because
  # the period came from its NEIGHBOURS' sweeps and the loop never re-asked.
  if [ "$label" != "reference" ]; then
    local ok; ok="$(buildable "candidates/${task}/${label}.sv")"
    [ "$ok" = "yes" ] || { say "SKIP build ${task}/${label} -- correctness gate: $ok"; return 0; }
  fi
  # ALREADY MEASURED AT THIS CLOCK? Any ppa record for this submission whose
  # clk_period_ns matches counts, whatever its label. Matching on the label
  # alone rebuilt d_nw01's reference and chat at 9.0 ns, both of which were
  # already measured there, for about an hour of P&R apiece.
  if [ "$(python3 - "$task" "$label" "$per" <<'PY2'
import glob, json, sys
task, label, per = sys.argv[1], sys.argv[2], float(sys.argv[3])
for f in glob.glob("runs/*/*__ppa.json"):
    try: r = json.load(open(f))
    except Exception: continue
    if not str(r.get("task","")).startswith(task): continue
    s = r.get("submission") or ""
    is_ref = "/ref/" in s or s.endswith("_ref.sv")
    if (label == "reference") != is_ref: continue
    if label != "reference" and f"/{label}.sv" not in s and f"__{label}_at_" not in f: continue
    try:
        if abs(float(r.get("clk_period_ns")) - per) < 1e-4 and r.get("design_area_um2"):
            print("yes"); raise SystemExit
    except (TypeError, ValueError): pass
print("no")
PY2
)" = "yes" ]; then say "SKIP build ${task}/${label} at ${per} (already measured)"; return 0; fi
  if ls "runs/${task}"_*/*"__${label}_at_${per}__ppa.json" >/dev/null 2>&1; then
    say "SKIP build ${task}/${label} at ${per}"; return 0; fi
  say "BUILD ${task}/${label} at ${per}ns"
  [ "$PLAN" = "1" ] && return 0
  if [ "$label" = "reference" ]; then
    local cfg; cfg="$(find domains -path "*${task}_*/orfs/config.mk" | head -1)"
    CLK_PERIOD_NS="$per" bash scripts/run_orfs_build.sh "/work/$cfg" >>"$LOG" 2>&1
  else
    CLK_PERIOD_NS="$per" bash scripts/ppa_candidate.sh "$task" \
      "candidates/${task}/${label}.sv" "${label}_at_${per}" >>"$LOG" 2>&1
  fi
}

say "=== PART 2 START ==="
refsweep d_nw03 4.0
sweep d_nw03 chat 4.0 ; sweep d_nw03 claude 4.0 ; sweep d_nw03 gemini 4.0
refsweep d_dsp03 12.0 ; sweep d_dsp03 chat 12.0
sweep d_nw01 claude 9.0

say "--- common-clock builds ---"
P="$(period_for d_nw03 d_nw03_cand_chat d_nw03_cand_claude d_nw03_cand_gemini)"
[ -n "$P" ] && for m in reference chat claude gemini; do build_at d_nw03 "$m" "$P"; done
P="$(period_for d_dsp03 d_dsp03_cand_chat)"
[ -n "$P" ] && for m in reference chat; do build_at d_dsp03 "$m" "$P"; done
P="$(period_for d_nw01 d_nw01_cand_chat_scored d_nw01_cand_claude)"
[ -n "$P" ] && for m in reference chat claude; do build_at d_nw01 "$m" "$P"; done
say "=== PART 2 DONE ==="
