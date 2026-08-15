#!/bin/bash
# Simulate LLM candidate answers against a domains/ task checker.
#
#   ./scripts/sim_candidate.sh <task> <candidate.sv | dir> [verilator|icarus] [--smoke]
#
# <task> is a task id (ai_d01) or a full path to the task directory.
# <candidate> is one .sv file, or a DIRECTORY of them -- a directory runs every
# answer and prints a pass rate, which is how you tell whether a task is hard
# enough to discriminate.
#
#   ./scripts/sim_candidate.sh ai_d01 candidates/ai_d01/opus5_t0.sv
#   ./scripts/sim_candidate.sh ai_d01 candidates/ai_d01
#   ./scripts/sim_candidate.sh nw_d01 candidates/nw_d01 icarus
#
# WHY THIS EXISTS RATHER THAN runner/: runner/config.py models tasks as
# interfaces/<tier>/ + testbenches/<tier>/ and has no notion of
# domains/<domain>/design/<id>_<module>/. Teaching it the new layout is Part 2
# work. This is the stopgap so candidates can be scored today.
#
# THREE THINGS THAT WILL SILENTLY GIVE WRONG ANSWERS, all handled here:
#   1. ai_d01's checker reads tb/vectors/*.hex by RELATIVE path, so the working
#      directory must be the task directory. From the repo root it loads no
#      vectors, every comparison comes out X, and it still prints a verdict.
#   2. The candidate replaces the DUT entirely -- do NOT also pass ref/ or the
#      vendored upstream RTL, or you get a duplicate-module error or, worse,
#      silently grade the reference.
#   3. Parameter override syntax differs: Verilator -GNAME=v, Icarus
#      -P<tb_module>.NAME=v.
#
# Exit: 0 every candidate passed every config, 1 something failed,
#       2 bad usage, 3 candidate rejected before simulating.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_ARG="${1:?usage: sim_candidate.sh <task> <candidate.sv|dir> [verilator|icarus] [--smoke]}"
CAND_ARG="${2:?missing candidate .sv or directory}"

SIM="verilator"; SMOKE=""
shift 2 2>/dev/null || true
for a in "$@"; do
  case "$a" in
    icarus|verilator) SIM="$a" ;;
    --smoke)          SMOKE="--smoke" ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done

# --- resolve the task: id shorthand or path ----------------------------------
if [ -d "$TASK_ARG" ]; then
  TASK_DIR="$(cd "$TASK_ARG" && pwd)"
elif [ -d "$REPO/$TASK_ARG" ]; then
  TASK_DIR="$(cd "$REPO/$TASK_ARG" && pwd)"
else
  TASK_DIR="$(ls -d "$REPO"/domains/*/design/"${TASK_ARG}"_* 2>/dev/null | head -1)"
  [ -n "$TASK_DIR" ] || { echo "cannot resolve task '$TASK_ARG'" >&2
    echo "known tasks: $(ls -d "$REPO"/domains/*/design/*/ 2>/dev/null | xargs -n1 basename | grep -oE '^[a-z]+_[a-z0-9]+' | sort -u | tr '\n' ' ')" >&2
    exit 2; }
fi

TB="$(ls "$TASK_DIR"/tb/*_tb.sv 2>/dev/null | head -1)"
[ -n "$TB" ] || { echo "no tb/*_tb.sv in $TASK_DIR" >&2; exit 2; }
TB_MOD="$(basename "$TB" .sv)"
DUT_MOD="$(grep -m1 '^module' "$TASK_DIR"/spec/*_iface.sv | sed 's/^module \([A-Za-z0-9_]*\).*/\1/')"
TASK_NAME="$(basename "$TASK_DIR")"

# --- legal configs per task. Keep in step with each task.yaml `configs:`. -----
case "$TASK_NAME" in
  ai_d01_int8_requant)
      CFGS=("LANES=1" "LANES=2" "LANES=4" "LANES=8") ;;
  d_ca04_async_fifo_cdc)
      CFGS=(); for w in 8 32 64; do for l in 2 3 4; do for y in 2 3; do
        CFGS+=("DATA_W=$w LOG_DEPTH=$l SYNC_STAGES=$y"); done; done; done ;;
  ca_d08_tiny_core)
      CFGS=("IMEM_AW=8 DMEM_AW=8" "IMEM_AW=10 DMEM_AW=10" "IMEM_AW=12 DMEM_AW=12") ;;
  nw_d01_axis_width_adapter)
      CFGS=(); for s in 1 2 4 8; do for m in 1 2 4 8; do CFGS+=("S_BYTES=$s M_BYTES=$m"); done; done ;;
  *)  echo "note: no config list registered for $TASK_NAME; running TB defaults"
      CFGS=("") ;;
esac
[ "$SMOKE" = "--smoke" ] && CFGS=("${CFGS[0]}")

# --- collect candidates ------------------------------------------------------
case "$CAND_ARG" in /*) CP="$CAND_ARG" ;; *) CP="$REPO/$CAND_ARG" ;; esac
[ -e "$CP" ] || { echo "no such candidate path: $CP" >&2; exit 2; }
CANDS=()
if [ -d "$CP" ]; then
  while IFS= read -r f; do CANDS+=("$f"); done < <(ls "$CP"/*.sv 2>/dev/null | sort)
  [ ${#CANDS[@]} -gt 0 ] || { echo "no .sv files in $CP" >&2; exit 2; }
else
  CANDS=("$CP")
fi

# Which task does a given DUT module belong to? Used to turn "wrong module"
# from a bare rejection into an actionable "you meant this task".
task_for_module() {
  local want="$1" d m
  for d in "$REPO"/domains/*/design/*/; do
    [ -d "$d" ] || continue
    m="$(grep -m1 '^module' "$d"spec/*_iface.sv 2>/dev/null | sed 's/^module \([A-Za-z0-9_]*\).*/\1/')"
    if [ "$m" = "$want" ]; then basename "$d" | grep -oE '^[a-z]+_[a-z0-9]+'; return; fi
  done
}

# If the candidate path looks like it belongs to a different task, say so before
# running anything -- this is the most common invocation mistake.
CAND_HINT="$(basename "${CP%/}" | grep -oE '^[a-z]+_[a-z0-9]+' || true)"
TASK_ID="$(basename "$TASK_DIR" | grep -oE '^[a-z]+_[a-z0-9]+')"
if [ -n "$CAND_HINT" ] && [ "$CAND_HINT" != "$TASK_ID" ] && [ -d "$REPO/candidates/$CAND_HINT" ]; then
  echo "WARNING: task is '$TASK_ID' but the candidate path is under 'candidates/$CAND_HINT'."
  echo "         Did you mean:  ./scripts/sim_candidate.sh $CAND_HINT $CAND_ARG"
  echo
fi

echo "task=$TASK_NAME  dut=$DUT_MOD  sim=$SIM  configs=${#CFGS[@]}  candidates=${#CANDS[@]}"
echo "================================================================================"

# --- run one candidate over every config; echoes "<pass> <total>|<firstfail>" -
run_one() {
  local cand="$1" p=0 t=0 first="" cerr="" CERR=""
  for cfg in "${CFGS[@]}"; do
    t=$((t+1))
    local tag out v
    tag="$(echo "$cfg" | tr ' =' '__')"
    if [ "$SIM" = "icarus" ]; then
      local pargs=""
      for kv in $cfg; do pargs="$pargs -P${TB_MOD}.${kv%%=*}=${kv##*=}"; done
      rm -f "/tmp/cand_${tag}.vvp"
      cerr="$(iverilog -g2012 -o "/tmp/cand_${tag}.vvp" $pargs "$TB" "$cand" 2>&1)"
      if [ -f "/tmp/cand_${tag}.vvp" ]; then out="$(timeout 600 vvp "/tmp/cand_${tag}.vvp" 2>&1)"
      else out="COMPILE_ERROR"; CERR="$(echo "$cerr" | grep -viE "warning" | grep -m1 . | cut -c1-90)"; fi
    else
      local gargs="" d="obj_cand_${tag}"
      for kv in $cfg; do gargs="$gargs -G$kv"; done
      rm -rf "$d"
      cerr="$(verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique \
        --top-module "$TB_MOD" $gargs "$TB" "$cand" -o sim --Mdir "$d" 2>&1)"
      if [ -x "$d/sim" ]; then out="$(timeout 600 "./$d/sim" 2>&1)"
      else out="COMPILE_ERROR"; CERR="$(echo "$cerr" | grep -m1 "%Error" | sed "s|.*/candidates/|candidates/|" | cut -c1-90)"; fi
      rm -rf "$d"
    fi
    v="$(echo "$out" | grep -oE 'TEST_RESULT: (PASS|FAIL)' | head -1 | awk '{print $2}')"
    [ "$out" = "COMPILE_ERROR" ] && v="COMPILE"
    [ -z "$v" ] && v="NO_VERDICT"
    # A PASS printed alongside a coverage hole is not a pass.
    if [ "$v" = "PASS" ] && echo "$out" | grep -q "COVERAGE HOLE"; then v="HOLES"; fi
    if [ "$v" = "PASS" ]; then p=$((p+1))
    elif [ -z "$first" ]; then
      if [ "$v" = "COMPILE" ]; then first="$cfg -> COMPILE: $CERR"
      else first="$cfg -> $v: $(echo "$out" | grep -m1 -E '^\[FAIL\]|COVERAGE HOLE' | sed 's/^\[FAIL\] //' | cut -c1-44)"; fi
    fi
  done
  echo "$p $t|$first"
}

cd "$TASK_DIR" || exit 2     # gotcha 1: vectors resolve relative to here

ALLPASS=0; NFAIL=0; NREJECT=0
printf '%-26s %-9s %s\n' "candidate" "configs" "first failure"
echo "--------------------------------------------------------------------------------"
for cand in "${CANDS[@]}"; do
  name="$(basename "$cand")"
  # cheap pre-checks: these are failed attempts, not harness breakage
  if grep -q "TEST_RESULT" "$cand"; then
    printf '%-26s %-9s %s\n' "$name" "REJECT" "forges a TEST_RESULT line"
    NREJECT=$((NREJECT+1)); continue
  fi
  if ! grep -qE "^[[:space:]]*module[[:space:]]+$DUT_MOD\b" "$cand"; then
    # Name the module it DOES declare, and if that module is another task's
    # DUT, name that task. A wrong-task invocation is a usage error, not a
    # failing implementation, and must not be reported as one.
    got="$(grep -m1 -E '^[[:space:]]*module[[:space:]]+' "$cand" | sed 's/^[[:space:]]*module[[:space:]]*\([A-Za-z0-9_]*\).*/\1/')"
    owner="$(task_for_module "$got")"
    if [ -n "$owner" ]; then
      printf '%-26s %-9s %s\n' "$name" "REJECT" "declares '$got' -- that is task $owner, not $TASK_ID"
    else
      printf '%-26s %-9s %s\n' "$name" "REJECT" "declares '${got:-<none>}', expected '$DUT_MOD'"
    fi
    NREJECT=$((NREJECT+1)); continue
  fi
  # Chat UIs paste U+00A0 (non-breaking space) in place of ordinary spaces.
  # Verilator's lexer rejects it with a misleading "unexpected $end", so the
  # answer looks broken when only the transport was. Normalise a COPY -- the
  # original answer file is never modified -- and say so in the report.
  nbsp="$(LC_ALL=C grep -c $'\xc2\xa0' "$cand" 2>/dev/null)"; nbsp="${nbsp:-0}"
  runfile="$cand"
  if [ "$nbsp" -gt 0 ] || [ -n "$(tail -c 1 "$cand")" ]; then
    runfile="/tmp/sanitised_$(basename "$cand")"
    LC_ALL=C sed $'s/\xc2\xa0/ /g' "$cand" > "$runfile"
    printf '\n' >> "$runfile"
    [ "$nbsp" -gt 0 ] && echo "  note: $name had non-breaking spaces on $nbsp lines; ran a normalised copy"
  fi
  res="$(run_one "$runfile")"
  pt="${res%%|*}"; ff="${res#*|}"
  set -- $pt; p=$1; t=$2
  printf '%-26s %-9s %s\n' "$name" "$p/$t" "$ff"
  if [ "$p" -eq "$t" ]; then ALLPASS=$((ALLPASS+1)); else NFAIL=$((NFAIL+1)); fi
done

echo "--------------------------------------------------------------------------------"
NRUN=$((ALLPASS + NFAIL))
if [ "$NREJECT" -gt 0 ] && [ "$NRUN" -eq 0 ]; then
  # Nothing was actually simulated. Reporting "0 passed" here would read as an
  # implementation failure for code that never ran.
  echo "NOTHING RUN: $NREJECT candidate(s) rejected as ineligible for task $TASK_ID."
  echo "This is a setup problem, not a result. No implementation was evaluated."
  exit 2
fi
if [ "$NREJECT" -gt 0 ]; then
  echo "$ALLPASS/$NRUN evaluated candidates passed every config (plus $NREJECT rejected as ineligible, not evaluated)"
else
  echo "$ALLPASS/$NRUN candidates passed every config"
fi
[ "$ALLPASS" -eq "$NRUN" ] && [ "$NREJECT" -eq 0 ] && exit 0 || exit 1
