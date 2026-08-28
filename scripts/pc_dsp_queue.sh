#!/bin/bash
# PC QUEUE: d_dsp03 and d_dsp02 -- the two FMA tasks.
#
# OWNERSHIP. The Mac keeps d_nw03 only; a watcher there stops its queue before it
# would begin d_dsp03, so these two tasks are this machine's alone. Do not add
# d_ca04, d_nw03 or d_dsp02 work here while that queue runs: run_orfs_build.sh
# wipes $ORFS_FLOW_DIR/{results,logs,objects,reports}/<platform>/<design> before
# every build, so the second machine to start deletes the other's in-flight
# results. That is data loss, not a bookkeeping clash.
#
# WHY HERE. d_nw03/chat swept in 213 min on the Mac against 27.6 min for d_nw01
# here, which puts both FMA tasks at 20+ hours there.
#
# REFERENCES ARE REUSED, NOT RESWEPT. fmax_results/d_dsp03_fmax.json (46.875 ns)
# and d_dsp02_fmax.json (12.8125 ns) already converged, and neither task's ref/
# nor orfs/ has changed since -- verified with git diff against each sweep's
# recorded rtl_git_commit. A8 and A9 constrain what CANDIDATES may build; they do
# not touch the reference, so the physical answer cannot have moved. Delete those
# two files to force a resweep.
#
# gemini is excluded on both tasks: slang-rejected, so buildable() gates it out.
# It is left in no list here so the exclusion is visible rather than implicit.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$REPO"
export LEC_CHECK="${LEC_CHECK:-0}"   # kepler-formal is AVX-512; this host is not
LOG="$REPO/fmax_results/pcdsp_$(date +%Y%m%d_%H%M%S).log"
PLAN=0; [ "${1:-}" = "--plan" ] && PLAN=1
say () { echo "$(date '+%H:%M:%S') $*" | tee -a "$LOG"; }


buildable () {   # candidates/<task>/<model>.sv -> yes | no | stale
  python3 - "$1" <<'PY'
import glob, json, subprocess, sys
sub = sys.argv[1]; best = None
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

converged () {   # a sweep is done only if it CONVERGED, not if its file exists
  python3 - "$1" <<'PY'
import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception: raise SystemExit(1)
raise SystemExit(0 if d.get("converged_period_ns") is not None
                      and not d.get("aborted_reason") else 1)
PY
}

# RECLAIM ONLY AGAINST A CONFIRMED RECORD, NEVER UNCONDITIONALLY.
# The first version deleted the flow outputs whether or not the build produced
# anything. That turns a failed EXTRACTION into a lost BUILD: the routed design
# is gone and the only way back is another full run. It is the same shape that
# cost the Mac three completed references -- the build succeeded, the record
# write died, and the reclaim removed the evidence anyway.
# $2 is a record path or a glob; if nothing matches, the outputs are KEPT so the
# extraction can be retried or inspected.
flow_clean () {   # $1 = ORFS nickname, $2 = record glob that must match
  local n="$1" want="${2:-}" d
  [ -n "$n" ] && [ -n "${ORFS_FLOW_DIR:-}" ] || return 0
  if [ -n "$want" ] && ! ls $want >/dev/null 2>&1; then
    say "  KEEPING flow outputs for ${n} -- no record matched '${want}'"
    return 0
  fi
  for d in results objects logs reports; do rm -rf "${ORFS_FLOW_DIR}/${d}/sky130hd/${n}"; done
  say "  cleared flow outputs for ${n}"
}

ref_nick () {
  local cfg; cfg="$(find domains -path "*${1}_*/orfs/config.mk" | head -1)"
  [ -n "$cfg" ] || return 0
  awk '$0 ~ /^[[:space:]]*export[[:space:]]+DESIGN_NICKNAME[[:space:]]*[:?]?=/ {sub(/^[^=]*=/,"");gsub(/[[:space:]]/,"");n=$0}
       $0 ~ /^[[:space:]]*export[[:space:]]+DESIGN_NAME[[:space:]]*[:?]?=/      {sub(/^[^=]*=/,"");gsub(/[[:space:]]/,"");m=$0}
       END{print (n!=""?n:m)}' "$cfg"
}

refsweep () {   # task, seed
  # separate declarations: bash expands every word of a `local` BEFORE assigning
  # any of them, so referring to $task in the same statement is unbound under -u
  local task="$1" seed="$2"
  local j="$REPO/fmax_results/${task}_fmax.json"
  if converged "$j"; then
    say "SKIP sweep $task ref -- converged $(python3 -c "import json;print(json.load(open('$j'))['converged_period_ns'])") ns, ref/ and orfs/ unchanged since"
    return 0
  fi
  [ -f "$j" ] && { say "REDO sweep $task ref -- did not converge, discarding"; rm -f "$j"; }
  say "SWEEP $task reference (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  python3 scripts/find_fmax.py --design "$task" --seed-period-ns "$seed" \
      --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
  converged "$j" && flow_clean "$(ref_nick "$task")" \
    || say "  KEEPING flow outputs for $task ref -- sweep did not converge"
}

sweep () {   # task, model, seed
  local task="$1" model="$2" seed="$3" nick="${1}_cand_${2}"
  local cand="candidates/${task}/${model}.sv" j="$REPO/fmax_results/${nick}_fmax.json"
  [ -f "$cand" ] || { say "MISSING $cand"; return 0; }
  local ok; ok="$(buildable "$cand")"
  [ "$ok" = "yes" ] || { say "SKIP sweep $nick -- correctness gate: $ok"; return 0; }
  if converged "$j"; then say "SKIP sweep $nick (converged)"; return 0; fi
  [ -f "$j" ] && { say "REDO sweep $nick -- did not converge, discarding"; rm -f "$j"; }
  say "SWEEP $nick (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  # stale-snapshot guard: compare the TRANSFORMED candidate (NBSP -> space plus a
  # trailing newline, as ppa_candidate.sh writes it), never the raw bytes
  local want have="" f
  want="$( { LC_ALL=C sed $'s/\xc2\xa0/ /g' "$cand"; printf '\n'; } | sha256sum | cut -d' ' -f1 )"
  if [ -f "orfs_runs/$nick/config.mk" ]; then
    for f in "orfs_runs/$nick"/*.sv; do
      [ -f "$f" ] || continue
      [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$want" ] && { have=1; break; }
    done
  fi
  if [ -z "$have" ]; then
    say "REGEN orfs_runs/$nick (snapshot missing or stale)"
    rm -rf "orfs_runs/$nick"
    bash scripts/ppa_candidate.sh "$task" "$cand" "$model" >>"$LOG" 2>&1 || true
  fi
  python3 scripts/find_fmax.py --design "$nick" --seed-period-ns "$seed" \
      --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
  converged "$j" && flow_clean "$nick" \
    || say "  KEEPING flow outputs for $nick -- sweep did not converge"
}

period_for () { python3 - "$REPO" "$@" <<'PY'
import json, os, sys
repo = sys.argv[1]; per=[]
for n in sys.argv[2:]:
    p = os.path.join(repo,"fmax_results",f"{n}_fmax.json")
    if os.path.isfile(p):
        d = json.load(open(p))
        if d.get("converged_period_ns"): per.append(float(d["converged_period_ns"]))
if per:
    s = f"{max(per):.4f}".rstrip("0"); print(s + "0" if s.endswith(".") else s)
else: print("")
PY
}

build_at () {   # task, label, period  -- label "reference" or a model
  local task="$1" label="$2" per="$3"
  if [ "$label" != "reference" ]; then
    local ok; ok="$(buildable "candidates/${task}/${label}.sv")"
    [ "$ok" = "yes" ] || { say "SKIP build ${task}/${label} -- correctness gate: $ok"; return 0; }
  fi
  # ASK WHETHER THE BUILD EXISTS, NOT WHETHER A FILENAME DOES. The glob here was
  # `*__${label}_fx${per}__ppa.json`, so a record written under the later
  # `_pin19p25` convention read as ABSENT and this queue would rebuild work
  # already done. d_ai04/reference at 33.75 ns is the live instance: the glob
  # misses it, the check below finds it. Same identify-by-filename defect that
  # froze the charts and disabled the superseded-pin guard; here it costs
  # compute rather than correctness.
  #
  # The helper matches on the clk_period_ns FIELD and prints the record it
  # matched, so a skip names its evidence. A WRONG SKIP IS WORSE THAN A WRONG
  # REBUILD -- it leaves a gap that reads as completed work -- and "already
  # built" with no evidence cannot be told from a bug.
  _hit="$(python3 scripts/_ppa_exists.py "$task" "$label" "$per" 2>/dev/null)"
  if [ -n "$_hit" ]; then
    say "SKIP build ${task}/${label} at ${per} (already built: $_hit)"; return 0; fi
  say "BUILD ${task}/${label} at ${per} ns"
  [ "$PLAN" = "1" ] && return 0
  if [ "$label" = "reference" ]; then
    bash scripts/reference_ppa.sh "$task" "$per" "reference_fx${per}" >>"$LOG" 2>&1 \
      || say "  BUILD FAILED ${task}/reference"
    flow_clean "$(ref_nick "$task")" "runs/${task}_*/*__${label}_fx${per}__ppa.json"
  else
    CLK_PERIOD_NS="$per" bash scripts/ppa_candidate.sh "$task" \
      "candidates/${task}/${label}.sv" "${label}_fx${per}" >>"$LOG" 2>&1 \
      || say "  BUILD FAILED ${task}/${label}"
    flow_clean "${task}_cand_${label}_fx${per}" "runs/${task}_*/*__${label}_fx${per}__ppa.json"
  fi
}

# FIXED CLOCK, NO CANDIDATE SWEEPS.
# d_dsp03/chat swept at ~2.5 h PER ITERATION (2,486,613 um^2 of movable instance
# area even after A8) and was bracketing upward from 12 ns, putting the four
# candidate sweeps at 40-60 h. They could not have changed the answer: the
# common clock is set by whichever design in the row is SLOWEST, and d_dsp03's
# reference converged at 46.875 ns -- far slower than any candidate is likely to
# need. So the sweeps bought the per-candidate own-Fmax column and nothing else.
# That column stays blank here, deliberately; area and power at a shared clock is
# the primary comparison.
#
# EACH BUILD CONFIRMS THE CLOCK BY ITS OWN SLACK. A candidate that MISSES at the
# common clock is a RESULT, reported as a miss (rule 22) -- it is never silently
# rebuilt at something slower. d_dsp03/chat already failed at 12 ns, so missing
# 46.875 is a live possibility; if it does, bracket upward from there explicitly.
say "=== PC FIXED-CLOCK BUILDS START ==="

# References are back in: their gates were restored on the Mac and merged here
# (d_dsp03 True/8eb2ae18667fe22a, d_dsp02 True/617eb4240908e773). The earlier
# COMPILE records are superseded by newest-wins, not deleted -- they stand as
# evidence of the Verilator 5.032-vs-5.051 split described below.
#
# CHAT MISSES THIS CLOCK, AND THAT IS THE RESULT (rule 22). d_dsp03/chat built at
# 46.875 ns with WNS -3.211: post-A8 it is SLOWER than the reference, so no clock
# the reference closes at can also carry chat. The row is still reported at
# 46.875 with chat marked missing; the upward bracket below establishes where
# chat actually closes, explicitly rather than by silently reslowing the row.
for m in reference chat claude; do build_at d_dsp03 "$m" 46.875; done

# d_dsp02 at max(reference 12.8125, chat 20.25) -- the clock its existing
# reference_at_20p25 / chat_at_20p25 records already use.
for m in reference chat claude; do build_at d_dsp02 "$m" 20.25; done

# UPWARD BRACKET FOR THE MISS. 46.875 + 3.211 = 50.086 is the arithmetic floor,
# but repairing timing changes the netlist, so probe with margin rather than at
# the floor. A single probe answers "does chat close at all, and roughly where",
# which is what the row needs; it is not a full bisection to 0.5 ns.
build_at d_dsp03 chat 53.0

# d_ca04/reference and d_nw03/reference were DROPPED: the Mac is building both.
# d_nw03 especially -- its candidates are at "4.7500" and this queue would have
# emitted "4.75". Those hash identically HERE, because build_config_hash.py now
# canonicalises periods, but only on a tree carrying that fix.
say "=== PC FIXED-CLOCK BUILDS DONE ==="
