#!/bin/bash
# Full place-and-route (ORFS) for a CANDIDATE implementation of a domains/ task.
#
#   ./scripts/ppa_candidate.sh <task> <candidate.sv> [label]
#
#   ./scripts/ppa_candidate.sh d_nw01 candidates/d_nw01/chat.sv
#   ./scripts/ppa_candidate.sh d_ca04 candidates/d_ca04/chat.sv gpt5run1
#
# For the REFERENCE build, use the task's own config directly instead:
#   ./scripts/run_orfs_build.sh /work/domains/<...>/orfs/config.mk
#
# WHY THIS EXISTS: each task's orfs/config.mk points VERILOG_FILES at that
# task's reference. Hand-editing a copy to aim it at a candidate is precisely
# the "copy a neighbour's config and inherit its source paths" mistake that
# broke `mesi`. This generates the config instead, so the source path cannot be
# stale and the results directory cannot collide with the reference's.
#
# Everything else is inherited from the task: the SDC (and therefore the clock
# period), platform, utilisation, and the ABC period scaling. A candidate is
# compared against its reference only if both were built the same way.
#
# Runtime is roughly 25 minutes per build on this Mac (amd64 image under
# emulation). Run it in the background.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_ARG="${1:?usage: ppa_candidate.sh <task> <candidate.sv> [label]}"
CAND_ARG="${2:?missing candidate .sv}"
LABEL="${3:-}"

# --- resolve the task --------------------------------------------------------
if [ -d "$TASK_ARG" ]; then TASK_DIR="$(cd "$TASK_ARG" && pwd)"
elif [ -d "$REPO/$TASK_ARG" ]; then TASK_DIR="$(cd "$REPO/$TASK_ARG" && pwd)"
else
  TASK_DIR="$(ls -d "$REPO"/domains/*/design/"${TASK_ARG}"_* 2>/dev/null | head -1)"
  [ -n "$TASK_DIR" ] || { echo "cannot resolve task '$TASK_ARG'" >&2; exit 2; }
fi
TASK_NAME="$(basename "$TASK_DIR")"
TASK_ID="$(echo "$TASK_NAME" | grep -oE '^[a-z]+_[a-z0-9]+')"

[ -f "$TASK_DIR/orfs/constraint.sdc" ] || {
  echo "task $TASK_ID has no orfs/ harness." >&2
  echo "Class B tasks have ORFS deferred by design -- see TASK_CATALOG.md." >&2
  exit 2; }

DUT_MOD="$(grep -m1 '^module' "$TASK_DIR"/spec/*_iface.sv | sed 's/^module \([A-Za-z0-9_]*\).*/\1/')"

# --- resolve the candidate ---------------------------------------------------
case "$CAND_ARG" in /*) CAND="$CAND_ARG" ;; *) CAND="$REPO/$CAND_ARG" ;; esac
[ -f "$CAND" ] || { echo "no such candidate: $CAND" >&2; exit 2; }
case "$CAND" in "$REPO"/*) ;; *) echo "candidate must live inside the repo (it is mounted at /work)" >&2; exit 2 ;; esac

if ! grep -qE "^[[:space:]]*module[[:space:]]+$DUT_MOD\b" "$CAND"; then
  got="$(grep -m1 -E '^[[:space:]]*module[[:space:]]+' "$CAND" | sed 's/^[[:space:]]*module[[:space:]]*\([A-Za-z0-9_]*\).*/\1/')"
  echo "REJECTED: candidate declares '${got:-<none>}', task $TASK_ID needs 'module $DUT_MOD'." >&2
  echo "Nothing was built. This is a setup problem, not a PPA result." >&2
  exit 2
fi

[ -n "$LABEL" ] || LABEL="$(basename "$CAND" .sv)"
NICK="${TASK_ID}_cand_${LABEL}"

# --- normalise chat-paste artifacts into the build copy ----------------------
# Same reasoning as sim_candidate.sh: U+00A0 comes from the copy-paste path, not
# the model. The original answer file is never modified.
# --- CORRECTNESS GATE, enforced HERE and not only in the driver -------------
# A PPA number for a design that fails its contract is not a result. That rule
# existed and lived in run_submissions.sh, which meant it applied only to people
# who used run_submissions.sh -- and calling this script directly bypassed it
# silently. That is exactly F20's root cause: a rule enforced by a tool nobody is
# obliged to use is a convention, not a control.
#
# d_ca04/gemini.sv reached the results table with area, power and WNS recorded
# and NO correctness verdict, because of that hole.
#
# Matched on the submission's CONTENT HASH, not its path: a file edited after
# passing must re-pass.
GATE_OVERRIDE=0
for a in "$@"; do [ "$a" = "--no-correctness-gate" ] && GATE_OVERRIDE=1; done

CAND_SHA="$(python3 -c "
import hashlib,sys
print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest()[:16])" "$CAND_ARG" 2>/dev/null)"

GATE_REC="$(python3 - "$REPO" "$TASK_NAME" "${CAND_SHA:-none}" <<'PYGATE'
import glob, json, os, sys
repo, task, sha = sys.argv[1], sys.argv[2], sys.argv[3]
for f in sorted(glob.glob(os.path.join(repo, "runs", task, "*__sim.json"))):
    try:
        d = json.load(open(f))
    except Exception:
        continue
    if d.get("submission_sha256_16") == sha and d.get("all_passed"):
        print(os.path.basename(f)); break
PYGATE
)"

if [ -z "$GATE_REC" ] && [ "$GATE_OVERRIDE" = "0" ]; then
  echo "REFUSED: no passing correctness record for this submission." >&2
  echo "  task   : $TASK_NAME" >&2
  echo "  file   : $CAND_ARG" >&2
  echo "  sha256 : ${CAND_SHA:-<unreadable>}" >&2
  echo "" >&2
  echo "  A PPA number for a design that fails or has never run its contract is" >&2
  echo "  not a result. Run the correctness gate first:" >&2
  echo "      ./scripts/sim_candidate.sh ${TASK_ARG} $CAND_ARG" >&2
  echo "" >&2
  echo "  For a deliberate exploratory build, pass --no-correctness-gate. The" >&2
  echo "  record is then marked correctness_gate=BYPASSED and collection will" >&2
  echo "  show it as such -- it does not become quotable by being labelled." >&2
  exit 3
fi
if [ "$GATE_OVERRIDE" = "1" ] && [ -z "$GATE_REC" ]; then
  echo "WARNING: correctness gate BYPASSED for $CAND_ARG -- record will say so." >&2
  GATE_STATUS="BYPASSED"
else
  GATE_STATUS="passed:$GATE_REC"
fi

RUNDIR="$REPO/orfs_runs/$NICK"
mkdir -p "$RUNDIR"
LC_ALL=C sed $'s/\xc2\xa0/ /g' "$CAND" > "$RUNDIR/$DUT_MOD.sv"
printf '\n' >> "$RUNDIR/$DUT_MOD.sv"

REL_SDC="${TASK_DIR#$REPO/}/orfs/constraint.sdc"

# If the task's SPEC ships a package, it is part of the problem statement -- the
# candidate was written against it and imports it -- so it must be synthesised
# alongside the candidate, packages first. Without this, slang fails with only
# "Design elaboration failed" and the candidate looks broken when the config is.
# The task's own orfs/config.mk lists it too; this is the candidate equivalent.
# Space-separated on one line -- make needs no continuations, and an earlier
# version emitted a literal \n into the config because the escaping did not
# survive the heredoc.
SPEC_PKGS=""
for pk in "$TASK_DIR"/spec/*_pkg.sv; do
  [ -f "$pk" ] || continue
  SPEC_PKGS="${SPEC_PKGS}/work/${pk#$REPO/} "
done

# Include paths the task declares for synthesis, if any.
INC_LINE=""
if [ -f "$TASK_DIR/orfs/config.mk" ]; then
  INC_LINE="$(grep -E '^export VERILOG_INCLUDE_DIRS' "$TASK_DIR/orfs/config.mk" || true)"
fi

# --- generate the config, inheriting everything except the source ------------
# Take the ABC period line from the task's own config so the candidate is
# mapped against the same target as the reference. Refuse rather than guess:
# a silently-empty ABC target is what F24 was.
ABC_LINE="$(grep -E '^export ABC_CLOCK_PERIOD_IN_PS' "$TASK_DIR/orfs/config.mk" 2>/dev/null | head -1)"
if [ -z "$ABC_LINE" ]; then
  echo "REFUSED: $TASK_DIR/orfs/config.mk has no ABC_CLOCK_PERIOD_IN_PS line." >&2
  echo "  Cannot guarantee the candidate is mapped against the same ABC target" >&2
  echo "  as the reference. Nothing was built. See FINDINGS.md F24." >&2
  exit 2
fi

cat > "$RUNDIR/config.mk" <<EOF
# GENERATED by scripts/ppa_candidate.sh -- do not hand-edit.
# task:      $TASK_ID ($DUT_MOD)
# candidate: ${CAND#$REPO/}
# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
#
# VERILOG_FILES points at the CANDIDATE, not at the task reference. The SDC and
# every other setting are inherited from the task so the numbers are comparable
# with that task's recorded baseline.
export PLATFORM        = sky130hd
export DESIGN_NAME     = $DUT_MOD
export DESIGN_NICKNAME = $NICK

export VERILOG_FILES = ${SPEC_PKGS}/work/orfs_runs/$NICK/$DUT_MOD.sv
export SDC_FILE      = /work/$REL_SDC
$INC_LINE

export SYNTH_HDL_FRONTEND = slang

# ORFS guards against accidentally inferring a large memory, defaulting to 4096
# bits, and ABORTS the build above it. That guard is aimed at designs that meant
# to instantiate a RAM macro; a candidate that writes a plain SystemVerilog array
# has asked for registers, and there is no macro in this flow to map it to.
#
# Raising it does NOT flatter the candidate. Synthesising 36 kbit as flip-flops
# produces a very large, slow result -- which is the honest consequence of what
# the design asked for, and the number we want to see. Aborting instead would
# hide a real area cost behind a tool guard.
#
# The reference builds are unaffected: they infer no memories, so this setting
# changes nothing for them and the comparison stays like-for-like.
export SYNTH_MEMORY_MAX_BITS = 65536

export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100
# COPIED VERBATIM FROM THE TASK'S OWN config.mk, never re-derived here.
# This line hardcoded /^set clk_period/, which does not exist in a MULTI-CLOCK
# SDC: d_ca04 declares wr_period and rd_period, so the awk returned empty and
# every candidate synthesised with ABC unconstrained while the reference used
# 5000 ps. The comparison was not like-for-like, and this script printed "both
# come from the task's own SDC, so they do" while it was false. See F24.
$ABC_LINE
EOF

echo "task      : $TASK_ID ($DUT_MOD)"
echo "candidate : ${CAND#$REPO/}"
echo "config    : orfs_runs/$NICK/config.mk"
echo "results   : \$ORFS_FLOW_DIR/{results,reports,logs}/sky130hd/$NICK/base/"
echo "expect ~25 min under emulation."
echo

"$REPO/scripts/run_orfs_build.sh" "/work/orfs_runs/$NICK/config.mk" || {
  echo "ORFS build failed -- see the log above." >&2; exit 1; }

# --- report ------------------------------------------------------------------
FLOW="${ORFS_FLOW_DIR:-/Users/jackberkowitz/tools/OpenROAD-flow-scripts/flow}"
RPT="$FLOW/reports/sky130hd/$NICK/base"
LOG="$FLOW/logs/sky130hd/$NICK/base"
echo
echo "================ PPA: $TASK_ID / $LABEL ================"
grep -E "Chip area" "$RPT/synth_stat.txt" 2>/dev/null
grep -iE "^Design area" "$LOG/6_report.log" 2>/dev/null | tail -1
grep -E "^tns |^wns |worst slack" "$RPT/6_finish.rpt" 2>/dev/null | head -3
grep -A11 "finish report_power" "$RPT/6_finish.rpt" 2>/dev/null | grep -E "^Total"

# --- immutable run record ----------------------------------------------------
# Collection reads these, never the live ORFS output directory. That directory
# is shared and mutable: during an Fmax sweep it reported DID NOT COMPLETE for a
# task whose candidate genuinely does not complete -- a stale value that
# coincidentally matched the truth. See scripts/write_run_record.py.
AREA="$(grep -iE '^Design area' "$LOG/6_report.log" 2>/dev/null | tail -1 | grep -oE '[0-9]+' | head -1)"
SYNTH="$(grep -E 'Chip area' "$RPT/synth_stat.txt" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"
# 'wns max' is the NEGATIVE-slack summary and reads 0.00 for every passing
# run, which silently discards the margin and disagrees with find_fmax.py.
# 'worst slack max' is the actual worst slack and is what find_fmax uses --
# the record and the sweep must not mean different things by WNS.
#
# Prefer 6_report.json: the .rpt rounds to two decimals, so a design closing at
# its own Fmax -- where slack is near zero by construction, which is the case
# that decides the gate -- records as "0.00" whichever side of zero it is on.
# d_nw01_ss at 9.0 ns has slack +0.00366 and the report prints 0.00.
WNS="$(python3 -c "
import json,sys
try:
    d=json.load(open(sys.argv[1]))
    v=d.get('finish__timing__setup__ws')
    print(v if v is not None else '')
except Exception:
    print('')
" "$LOG/6_report.json" 2>/dev/null)"
[ -z "$WNS" ] && WNS="$(grep -E '^worst slack max' "$RPT/6_finish.rpt" 2>/dev/null | head -1 | grep -oE '[-0-9.]+' | head -1)"
# Columns are Internal, Switching, Leakage, Total -- $4 is LEAKAGE. Recording
# leakage as total power understated it by five orders of magnitude.
PWR="$(grep -A11 'finish report_power' "$RPT/6_finish.rpt" 2>/dev/null | grep -E '^Total' | awk '{print $5}')"
PER="$(awk '/^set clk_period/{print $3; exit}' "$TASK_DIR/orfs/constraint.sdc" 2>/dev/null)"
[ -n "${CLK_PERIOD_NS:-}" ] && PER="$CLK_PERIOD_NS"
if [ -n "$AREA" ]; then STATUS=completed; else STATUS=DID_NOT_COMPLETE; fi
# RULE 17: hash the RESOLVED build configuration so a later comparison can
# refuse mechanically instead of assuming. Text-identical configs can resolve
# differently -- F24's ABC target is the worked example.
BCH_OUT="$(python3 "$REPO/scripts/build_config_hash.py" "$RUNDIR/config.mk" "$TASK_DIR/orfs/constraint.sdc" \
           ${CLK_PERIOD_NS:+CLK_PERIOD_NS=$CLK_PERIOD_NS} 2>/dev/null)"
BCH="$(echo "$BCH_OUT" | head -1)"
BCF="$(echo "$BCH_OUT" | tail -n +2 | tr -s ' ' | tr '\n' ';' | sed 's/^;//')"

REC="$(python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$CAND" ppa "$LABEL" \
        "status=$STATUS" "design_area_um2=${AREA:-}" "synth_area_um2=${SYNTH:-}" \
        "wns_ns=${WNS:-}" "power_w=${PWR:-}" "clk_period_ns=${PER:-}" \
        "orfs_nickname=$NICK" "pdk=${PLATFORM:-sky130hd}" \
        "build_config_hash=$BCH" "build_config_fields=$BCF" \
        "correctness_gate=$GATE_STATUS" 2>/dev/null)"
[ -n "$REC" ] && echo "record: $REC"

echo
echo "Compare against the task baseline in $TASK_DIR/NOTES.md."
echo "A candidate is only comparable to that baseline if the clock period and"
echo "parameters match -- both come from the task's own SDC, so they do."
