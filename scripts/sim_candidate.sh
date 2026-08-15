#!/bin/bash
# Simulate an LLM candidate against a domains/ task checker.
#
#   ./scripts/sim_candidate.sh <task_dir> <candidate.sv> [verilator|icarus] [--smoke]
#
# e.g.
#   ./scripts/sim_candidate.sh domains/ai_accel/design/ai_d01_int8_requant ~/ans/int8.sv
#   ./scripts/sim_candidate.sh domains/networking/design/nw_d01_axis_width_adapter ~/ans/adapt.sv icarus
#
# Runs EVERY legal config by default (Step 4's bar: a candidate passes only if
# it passes all of them), --smoke runs just the first.
#
# WHY THIS EXISTS RATHER THAN runner/: runner/config.py models tasks as
# interfaces/<tier>/ + testbenches/<tier>/ and has no notion of
# domains/<domain>/design/<id>_<module>/. Teaching it the new layout is Part 2
# work. This script is the stopgap so candidates can be scored today.
#
# THREE THINGS THAT WILL BITE YOU, all handled here:
#   1. ai_d01's checker reads tb/vectors/*.hex by RELATIVE path, so the working
#      directory must be the task directory. Running from the repo root silently
#      loads nothing and every comparison comes out X.
#   2. The candidate must declare the module name from spec/, verbatim
#      (int8_requant, axis_width_adapter). It replaces the DUT entirely -- do
#      NOT also pass ref/ or the vendored upstream RTL, or you will get a
#      duplicate-module error, or worse, silently grade the reference.
#   3. Parameter override syntax differs: Verilator -GNAME=v, Icarus
#      -P<tb_module>.NAME=v.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_DIR="${1:?usage: sim_candidate.sh <task_dir> <candidate.sv> [verilator|icarus] [--smoke]}"
CAND="${2:?missing candidate .sv}"
# Flags are order-independent: anything after the candidate is scanned, so
# `... answer.sv --smoke` and `... answer.sv icarus --smoke` both work.
SIM="verilator"
SMOKE=""
shift 2 2>/dev/null || true
for a in "$@"; do
  case "$a" in
    icarus|verilator) SIM="$a" ;;
    --smoke)          SMOKE="--smoke" ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done

case "$TASK_DIR" in /*) ;; *) TASK_DIR="$REPO/$TASK_DIR" ;; esac
case "$CAND"     in /*) ;; *) CAND="$(cd "$(dirname "$CAND")" && pwd)/$(basename "$CAND")" ;; esac
[ -d "$TASK_DIR" ] || { echo "no such task dir: $TASK_DIR" >&2; exit 2; }
[ -f "$CAND" ]     || { echo "no such candidate: $CAND" >&2; exit 2; }

TASK_ID="$(basename "$TASK_DIR" | grep -oE "^[a-z]+_[a-z0-9]+")"
TB="$(ls "$TASK_DIR"/tb/*_tb.sv 2>/dev/null | head -1)"
[ -n "$TB" ] || { echo "no tb/*_tb.sv in $TASK_DIR" >&2; exit 2; }
TB_MOD="$(basename "$TB" .sv)"
DUT_MOD="$(grep -m1 '^module' "$TASK_DIR"/spec/*_iface.sv | sed 's/^module \([A-Za-z0-9_]*\).*/\1/')"

# --- legal configs per task. Keep in step with each task.yaml `configs:`. -----
case "$(basename "$TASK_DIR")" in
  ai_d01_int8_requant)
      CFGS=("LANES=1" "LANES=4" "LANES=2" "LANES=8") ;;
  nw_d01_axis_width_adapter)
      CFGS=()
      for s in 1 2 4 8; do for m in 1 2 4 8; do CFGS+=("S_BYTES=$s M_BYTES=$m"); done; done ;;
  *)  echo "note: no config list registered for $(basename "$TASK_DIR"); running TB defaults"
      CFGS=("") ;;
esac
[ "$SMOKE" = "--smoke" ] && CFGS=("${CFGS[0]}")

# --- forged-verdict guard ----------------------------------------------------
# runner/score.py already treats this as cheating; catch it here too, because a
# candidate that prints its own TEST_RESULT will otherwise look like a pass.
if grep -q "TEST_RESULT" "$CAND"; then
  echo "REJECTED: candidate emits TEST_RESULT itself (forged verdict)" >&2
  exit 3
fi
if ! grep -qE "^[[:space:]]*module[[:space:]]+$DUT_MOD\b" "$CAND"; then
  echo "REJECTED: candidate does not declare 'module $DUT_MOD'" >&2
  exit 3
fi

echo "task=$TASK_ID  dut=$DUT_MOD  tb=$TB_MOD  sim=$SIM  configs=${#CFGS[@]}"
printf '%-28s %-8s %-7s %s\n' "config" "verdict" "holes" "first failure / reason"
echo "--------------------------------------------------------------------------------"

cd "$TASK_DIR" || exit 2     # gotcha 1: vectors resolve relative to here
PASSES=0; TOTAL=0
for cfg in "${CFGS[@]}"; do
  TOTAL=$((TOTAL+1))
  TAG="$(echo "$cfg" | tr ' =' '__')"
  OUT=""
  if [ "$SIM" = "icarus" ]; then
    PARGS=""
    for kv in $cfg; do PARGS="$PARGS -P${TB_MOD}.${kv%%=*}=${kv##*=}"; done
    rm -f "/tmp/cand_${TAG}.vvp"
    iverilog -g2012 -o "/tmp/cand_${TAG}.vvp" $PARGS "$TB" "$CAND" >/dev/null 2>&1
    if [ -f "/tmp/cand_${TAG}.vvp" ]; then OUT="$(timeout 600 vvp "/tmp/cand_${TAG}.vvp" 2>&1)"
    else OUT="COMPILE_ERROR"; fi
  else
    GARGS=""
    for kv in $cfg; do GARGS="$GARGS -G$kv"; done
    D="obj_cand_${TAG}"; rm -rf "$D"
    verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique \
      --top-module "$TB_MOD" $GARGS "$TB" "$CAND" -o sim --Mdir "$D" >/dev/null 2>&1
    if [ -x "$D/sim" ]; then OUT="$(timeout 600 "./$D/sim" 2>&1)"
    else OUT="COMPILE_ERROR"; fi
  fi

  V="$(echo "$OUT" | grep -oE 'TEST_RESULT: (PASS|FAIL)' | head -1 | awk '{print $2}')"
  [ "$OUT" = "COMPILE_ERROR" ] && V="COMPILE"
  [ -z "$V" ] && V="NO_VERDICT"
  H="$(echo "$OUT" | grep -c 'COVERAGE HOLE')"
  MSG="$(echo "$OUT" | grep -m1 -E '^\[FAIL\]|COVERAGE HOLE' | cut -c1-40)"
  [ "$V" = "PASS" ] && PASSES=$((PASSES+1))
  printf '%-28s %-8s %-7s %s\n' "${cfg:-default}" "$V" "$H" "$MSG"
done

echo "--------------------------------------------------------------------------------"
echo "PASSED $PASSES/$TOTAL configs"
# A candidate is correct only if it passes EVERY legal config with no holes.
[ "$PASSES" -eq "$TOTAL" ] && exit 0 || exit 1
