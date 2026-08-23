#!/bin/bash
# Build a task's REFERENCE at a fixed clock and write an immutable ppa record.
#
# WHY THIS EXISTS: neither overnight_ppa2.sh nor fixed_clock_ppa.sh writes a
# record for a reference build -- both call run_orfs_build.sh, which only builds.
# That is why runs/.../reference_at_9p0__ppa.json carries build_config_hash:None
# and cannot be compared mechanically under rule 17.
#
# Extraction below is copied verbatim from ppa_candidate.sh (the WNS json-first
# path, the $5 power column, the Design area integer) so the reference record and
# the candidate records cannot come to mean different things.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

TASK="$1"          # e.g. d_nw01
PER="$2"           # e.g. 9.0   -- MUST match the candidates' string exactly
LABEL="$3"         # e.g. reference_fx9.0

# ORFS_FLOW_DIR is resolved HERE, before the build, not at extraction time.
# It used to be read after run_orfs_build.sh returned, with a `:?` guard. On a
# host that had not exported it that guard fired AFTER a completed place-and-route
# -- three references built to 6_report and none produced a record. Every other
# script in this repo defaults it (run_orfs_build.sh:65); only this one demanded
# it, because it was written on a host whose profile exported it. Same default
# here, checked up front, so a misconfigured host costs a second and not an hour.
FLOW="${ORFS_FLOW_DIR:-$HOME/tools/OpenROAD-flow-scripts/flow}"
[ -d "$FLOW" ] || { echo "ORFS_FLOW_DIR does not resolve to a directory: $FLOW" >&2; exit 2; }
export ORFS_FLOW_DIR="$FLOW"

TASK_DIR="$(dirname "$(dirname "$(find domains -path "*${TASK}_*/orfs/config.mk" | head -1)")")"
CFG="$TASK_DIR/orfs/config.mk"
TASK_NAME="$(basename "$TASK_DIR")"
REF="$(ls "$TASK_DIR"/ref/*_ref.sv | head -1)"
NICK="$(awk '
  $0 ~ /^[[:space:]]*export[[:space:]]+DESIGN_NICKNAME[[:space:]]*[:?]?=/ {sub(/^[^=]*=/,"");gsub(/[[:space:]]/,"");n=$0}
  $0 ~ /^[[:space:]]*export[[:space:]]+DESIGN_NAME[[:space:]]*[:?]?=/      {sub(/^[^=]*=/,"");gsub(/[[:space:]]/,"");m=$0}
  END{print (n!=""?n:m)}' "$CFG")"

echo "task=$TASK_NAME  ref=$REF  nick=$NICK  clk=${PER}ns  label=$LABEL"

CLK_PERIOD_NS="$PER" bash scripts/run_orfs_build.sh "/work/${CFG#$REPO/}" || {
  echo "BUILD FAILED"; exit 1; }

RPT="$FLOW/reports/sky130hd/$NICK/base"
FLOG="$FLOW/logs/sky130hd/$NICK/base"

AREA="$(grep -iE '^Design area' "$FLOG/6_report.log" 2>/dev/null | tail -1 | grep -oE '[0-9]+' | head -1)"
SYNTH="$(grep -E 'Chip area' "$RPT/synth_stat.txt" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"
WNS="$(python3 -c "
import json,sys
try:
    d=json.load(open(sys.argv[1])); v=d.get('finish__timing__setup__ws'); print(v if v is not None else '')
except Exception: print('')
" "$FLOG/6_report.json" 2>/dev/null)"
[ -z "$WNS" ] && WNS="$(grep -E '^worst slack max' "$RPT/6_finish.rpt" 2>/dev/null | head -1 | grep -oE '[-0-9.]+' | head -1)"
PWR="$(grep -A11 'finish report_power' "$RPT/6_finish.rpt" 2>/dev/null | grep -E '^Total' | awk '{print $5}')"
[ -n "$AREA" ] && STATUS=completed || STATUS=DID_NOT_COMPLETE

BCH_OUT="$(python3 scripts/build_config_hash.py "$CFG" "$TASK_DIR/orfs/constraint.sdc" \
           CLK_PERIOD_NS="$PER" 2>/dev/null)"
BCH="$(echo "$BCH_OUT" | head -1)"
BCF="$(echo "$BCH_OUT" | tail -n +2 | tr -s ' ' | tr '\n' ';' | sed 's/^;//')"

# The reference's gate is its own sim record, not a candidate's.
GATE="$(python3 - "$REF" <<'PY'
import glob, json, os, sys
sub = os.path.relpath(sys.argv[1], os.getcwd())
best_f = best = None
for f in glob.glob("runs/*/*__sim.json"):
    try: r = json.load(open(f))
    except Exception: continue
    if r.get("submission") != sub: continue
    if best is None or r.get("timestamp_utc","") >= best.get("timestamp_utc",""):
        best, best_f = r, f
print(f"passed:{os.path.basename(best_f)}" if best and best.get("all_passed") is True
      else "UNVERIFIED")
PY
)"

echo "================ PPA: $TASK / $LABEL ================"
echo "  area=$AREA synth=$SYNTH wns=$WNS power=$PWR clk=$PER"
echo "  build_config_hash=$BCH"
echo "  gate=$GATE"

REC="$(python3 scripts/write_run_record.py "$TASK_NAME" "$REF" ppa "$LABEL" \
        "status=$STATUS" "design_area_um2=${AREA:-}" "synth_area_um2=${SYNTH:-}" \
        "wns_ns=${WNS:-}" "power_w=${PWR:-}" "clk_period_ns=${PER:-}" \
        "orfs_nickname=$NICK" "pdk=sky130hd" \
        "build_config_hash=$BCH" "build_config_fields=$BCF" \
        "correctness_gate=$GATE" 2>&1)"
echo "record: $REC"
