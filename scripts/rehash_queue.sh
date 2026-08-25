#!/bin/bash
# Bring every design row onto ONE build_config_hash.
#
# All six rows had a reference built without SYNTH_MEMORY_MAX_BITS=65536 while
# its candidates had it -- see reference_ppa.sh. Five rows need the reference
# rebuilt and nothing else; the generated config was verified to reproduce the
# candidates' hash exactly on all five before any build was queued.
#
# d_nw03 needs the WHOLE row. Its four records carry override.CLK_PERIOD_NS=
# 4.7500, written before the period canonicaliser landed; the same period now
# renders 4.75, so the candidates are stale against the current hash function
# too and a reference-only rebuild would still not match.
#
# Labels are reused deliberately. write_run_record timestamps every record and
# the readers take newest-per-label, so a rebuild supersedes without deleting
# the record it replaces.
set -uo pipefail
cd /Users/jackberkowitz/Desktop/hw_rl_benchmark
export ORFS_FLOW_DIR="$HOME/tools/OpenROAD-flow-scripts/flow"
LOG="fmax_results/rehash_$(date +%Y%m%d_%H%M%S).log"
say () { echo "$(date +%H:%M:%S) $*" | tee -a "$LOG"; }

# F65: reclaim ONLY after confirming the record landed. Cleanup that ignores
# exit status deletes the artefacts that make a failure cheap to recover from.
reclaim_if () {   # $1 = task_name  $2 = label  $3 = count before
  local n; n="$(ls runs/$1/*__${2}__ppa.json 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$n" -gt "$3" ]; then
    say "  RECORD OK $1/$2"
    for sub in results objects logs reports; do
      rm -rf "$ORFS_FLOW_DIR/$sub/sky130hd/$1" "$ORFS_FLOW_DIR/$sub/sky130hd/${1}_cand"*
    done
  else
    say "  NO RECORD $1/$2 -- flow output KEPT"
  fi
  say "  free: $(df -h /System/Volumes/Data | tail -1 | awk '{print $4}')"
}

ref () {   # short  period  label
  local tn; tn="$(ls -d domains/*/design/${1}_* | head -1 | xargs basename)"
  local b;  b="$(ls runs/$tn/*__${3}__ppa.json 2>/dev/null | wc -l | tr -d ' ')"
  say "REF $1 @ $2  ($3)"
  timeout 7200 bash scripts/reference_ppa.sh "$1" "$2" "$3" >>"$LOG" 2>&1
  reclaim_if "$tn" "$3" "$b"
}

cand () {  # short  model  period
  local tn; tn="$(ls -d domains/*/design/${1}_* | head -1 | xargs basename)"
  local lab="${2}_cc${3}"
  local b;  b="$(ls runs/$tn/*__${lab}__ppa.json 2>/dev/null | wc -l | tr -d ' ')"
  say "CAND $1/$2 @ $3  ($lab)"
  CLK_PERIOD_NS="$3" timeout 7200 bash scripts/ppa_candidate.sh "$1" \
      "candidates/${1}/${2}.sv" "$lab" >>"$LOG" 2>&1
  reclaim_if "$tn" "$lab" "$b"
}

say "=== REHASH QUEUE START ==="
# cheapest first, so an interrupted night still leaves whole rows clean
ref  d_ca04 3.6562 reference_cc3.6562
ref  d_nw03 4.7500 reference_cc4.7500
cand d_nw03 chat   4.7500
cand d_nw03 claude 4.7500
cand d_nw03 gemini 4.7500
ref  d_ca01 10.0   reference_fx10.0
say "=== REHASH QUEUE DONE (mac share) ==="
