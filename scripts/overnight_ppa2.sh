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
# LEC_CHECK=0 works around an ILLEGAL-INSTRUCTION fault in the equivalence
# checker, and it is NOT specific to Rosetta. An earlier version of this comment
# claimed "on a native x86 host there is no such fault and the check should be
# ON". That was asserted without testing and is FALSE: the bundled
# `kepler-formal` binary carries 1262 AVX-512 instructions, and a native Alder
# Lake i5 -- which has AVX-512 fused off -- SIGILLs on it exactly as Apple
# Silicon under emulation does. Measured on the second machine, not inferred.
#
# So the default stays 0 everywhere, and this defers to an inherited value only
# so a host KNOWN to have AVX-512 can turn the check back on. Do not assume
# native x86 is such a host; check the CPU flags first.
export LEC_CHECK="${LEC_CHECK:-0}"
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

# A SWEEP IS "DONE" ONLY IF IT CONVERGED -- NOT IF ITS FILE EXISTS.
# find_fmax writes fmax_results/<nick>_fmax.json even when the seed run fails as
# a tool error: converged_period_ns and achieved_fmax_mhz come out null and
# aborted_reason is set. Skipping on [ -f <json> ] therefore marks a FAILED sweep
# as complete, and a restart produces a queue that finishes cleanly with no Fmax
# in it. Four such files had to be deleted by hand here after the AVX-512 aborts;
# nine were produced on the Mac during its disk outage.
converged () {   # $1 = path to a *_fmax.json; true only if it really converged
  python3 - "$1" <<'PY'
import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception: raise SystemExit(1)
raise SystemExit(0 if d.get("converged_period_ns") is not None
                      and not d.get("aborted_reason") else 1)
PY
}

# FLOW-OUTPUT CLEANUP. ORFS keeps every intermediate stage -- roughly 2 GB for a
# d_ca01-sized design and 6 GB for the pre-C3 crossbar. Left to accumulate this
# filled the Mac's disk, wedged Docker and destroyed 13 in-flight sweeps. By the
# time this runs the numbers are already extracted into the ppa/fmax record, and
# check_ppa_record.py handles a missing flow dir ("flow dir gone").
# NOTE: run_orfs_build.sh wipes a design's outputs BEFORE each build, so this is
# about cross-design accumulation, not about the design just built.
flow_clean () {   # $1 = ORFS design nickname
  local n="$1" plat="${PLATFORM:-sky130hd}" d
  [ -n "$n" ] || return 0
  [ -n "${ORFS_FLOW_DIR:-}" ] || return 0
  for d in results objects logs reports; do
    rm -rf "${ORFS_FLOW_DIR}/${d}/${plat}/${n}"
  done
  say "  cleared flow outputs for ${n}"
}

# The reference's ORFS output directory is named after DESIGN_NICKNAME (falling
# back to DESIGN_NAME) exactly as run_orfs_build.sh derives it -- read it from the
# task's own config so cleanup cannot target the wrong directory.
ref_nick () {   # $1 = task
  local cfg; cfg="$(find domains -path "*${1}_*/orfs/config.mk" | head -1)"
  [ -n "$cfg" ] || return 0
  awk '
    $0 ~ /^[[:space:]]*export[[:space:]]+DESIGN_NICKNAME[[:space:]]*[:?]?=/ {
      sub(/^[^=]*=/,""); gsub(/[[:space:]]/,""); nick=$0 }
    $0 ~ /^[[:space:]]*export[[:space:]]+DESIGN_NAME[[:space:]]*[:?]?=/ {
      sub(/^[^=]*=/,""); gsub(/[[:space:]]/,""); name=$0 }
    END { print (nick != "" ? nick : name) }
  ' "$cfg"
}

sweep () {   # task, model, seed
  local task="$1" model="$2" seed="$3" nick="${1}_cand_${2}"
  local cand="candidates/${task}/${model}.sv"
  [ -f "$cand" ] || { say "MISSING $cand"; return 0; }
  local ok; ok="$(buildable "$cand")"
  [ "$ok" = "yes" ] || { say "SKIP sweep $nick -- correctness gate: $ok"; return 0; }
  if converged "$REPO/fmax_results/${nick}_fmax.json"; then say "SKIP sweep $nick (done)"; return 0; fi
  if [ -f "$REPO/fmax_results/${nick}_fmax.json" ]; then
    say "REDO sweep $nick -- previous attempt did not converge, discarding its json"
    rm -f "$REPO/fmax_results/${nick}_fmax.json"
  fi
  say "SWEEP $nick (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  # STALE SNAPSHOT GUARD -- COMPARE CONTENT, NOT PRESENCE.
  # ppa_candidate.sh copies the candidate into orfs_runs/<nick>/<dut>.sv. Keying
  # regeneration on config.mk's mere existence meant that after a candidate was
  # re-solicited, the sweep silently rebuilt the PREVIOUS copy -- the RTL on disk
  # and the RTL being measured were different files, with nothing in the log to
  # say so. Caught on d_nw01/claude: snapshot 0f35254446decbc2 against candidate
  # 79f8e5bb3cc9d3f4. This trap has cost work four times; the Mac's
  # mac_sweep_queue.sh now carries the same check.
  # Compare against the TRANSFORMED candidate, not the raw file: ppa_candidate.sh
  # writes the snapshot as `sed 's/\xc2\xa0/ /g'` (NBSP -> space) plus a trailing
  # newline, so a raw sha never matches and a naive check would regenerate on
  # every sweep -- and regeneration runs a full ORFS build, so that is expensive,
  # not merely redundant. Reproduce the transform instead of stamping a marker
  # file, so the check stays correct even if orfs_runs/ is populated by hand.
  local want have="" f
  want="$( { LC_ALL=C sed $'s/\xc2\xa0/ /g' "$cand"; printf '\n'; } | sha256sum | cut -d' ' -f1 )"
  if [ -f "orfs_runs/$nick/config.mk" ]; then
    for f in "orfs_runs/$nick"/*.sv; do
      [ -f "$f" ] || continue
      [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$want" ] && { have=1; break; }
    done
  fi
  if [ -z "$have" ]; then
    say "REGEN orfs_runs/$nick -- snapshot missing or stale (candidate ${want:0:16})"
    rm -rf "orfs_runs/$nick"
    bash scripts/ppa_candidate.sh "$task" "$cand" "$model" >>"$LOG" 2>&1 || true
  fi
  python3 scripts/find_fmax.py --design "$nick" --seed-period-ns "$seed" \
      --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
  flow_clean "$nick"
}
refsweep () {  # task, seed
  local task="$1" seed="$2"
  if converged "$REPO/fmax_results/${task}_fmax.json"; then say "SKIP sweep $task ref (done)"; return 0; fi
  if [ -f "$REPO/fmax_results/${task}_fmax.json" ]; then
    say "REDO sweep $task ref -- previous attempt did not converge, discarding its json"
    rm -f "$REPO/fmax_results/${task}_fmax.json"
  fi
  say "SWEEP $task reference (seed ${seed}ns)"
  [ "$PLAN" = "1" ] && return 0
  python3 scripts/find_fmax.py --design "$task" --seed-period-ns "$seed" \
      --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
  flow_clean "$(ref_nick "$task")"
}
# EMIT THE CANONICAL PERIOD, NOT "%.4f". This used to print 9.0000 where
# fixed_clock_ppa.sh prints 9.0. build_config_hash.py hashes that string, so the
# same clock produced two hashes and rule 17 refused to compare builds that were
# byte-identical. build_config_hash.py now normalises defensively, but emitting
# the canonical form here keeps the LABEL agreeing with the hash as well --
# otherwise records read claude_at_9.0000 while hashing as 9.0.
# Canonical = round to 4 dp, strip trailing zeros, keep one decimal.
period_for () { python3 - "$REPO" "$@" <<'PY'
import json, os, sys
repo = sys.argv[1]; per=[]
for n in sys.argv[2:]:
    p = os.path.join(repo,"fmax_results",f"{n}_fmax.json")
    if os.path.isfile(p):
        d = json.load(open(p))
        if d.get("converged_period_ns"): per.append(float(d["converged_period_ns"]))
if per:
    s = f"{max(per):.4f}".rstrip("0")
    print(s + "0" if s.endswith(".") else s)
else:
    print("")
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
    flow_clean "$(ref_nick "$task")"
  else
    CLK_PERIOD_NS="$per" bash scripts/ppa_candidate.sh "$task" \
      "candidates/${task}/${label}.sv" "${label}_at_${per}" >>"$LOG" 2>&1
    flow_clean "${task}_cand_${label}_at_${per}"
  fi
}

say "=== PART 2 START ==="
# d_nw03 AND d_dsp03 DROPPED ON THIS MACHINE (PC, branch ppa/pc-part2).
# NOT because they are unwanted -- because the Mac owns them. Its queue
# (scripts/mac_sweep_queue.sh) covers d_ca04, d_nw03, d_dsp03 and d_dsp02, and is
# written and chained. Running them here as well is a DATA-LOSS hazard, not a
# bookkeeping one: run_orfs_build.sh wipes
# $ORFS_FLOW_DIR/{results,logs,objects,reports}/<platform>/<design> before every
# build, so whichever machine started second would delete the other's in-flight
# results mid-run. Restore these lines only when the Mac's queue is not running.
#
# This PC runs d_nw01 alone.
sweep d_nw01 claude 9.0

say "--- common-clock builds ---"
# d_nw03 and d_dsp03 build groups dropped with their sweeps -- see above. Both
# must stay out while the Mac's queue is running, for the same wipe hazard.
P="$(period_for d_nw01 d_nw01_cand_chat_scored d_nw01_cand_claude)"
[ -n "$P" ] && for m in reference chat claude; do build_at d_nw01 "$m" "$P"; done
say "=== PART 2 DONE ==="
