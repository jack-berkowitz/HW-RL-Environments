#!/bin/bash
# Score a submitted TESTBENCH for a verification task.
#
#   ./scripts/sim_verification.sh v_ca05 candidates/v_ca05/chat.sv [label]
#   ./scripts/sim_verification.sh v_ca05 candidates/v_ca05      # whole directory
#
# WHY THIS IS A SEPARATE SCRIPT
# -----------------------------
# sim_candidate.sh scores RTL: the submission REPLACES THE DUT and is judged by
# the task's checker. A verification submission is the inverse -- it IS the
# checker, and is judged by which DUTs it accepts and rejects. Bolting a mode
# onto sim_candidate.sh would have meant one script with two opposite meanings
# for its central argument.
#
# It also resolves tasks under domains/*/verification/, which sim_candidate.sh
# does not: it looks only under domains/*/design/, so `v_ca05` exits 2 there
# with "cannot resolve task" -- and run_submissions.sh relabels that as
# "correctness gate failed", reporting a harness limitation as a property of the
# candidate. See candidates/README.md.
#
# WHAT IS SCORED, AND WHAT IS NOT
# -------------------------------
#   1. VALIDITY GATE -- does the testbench PASS the golden DUT?
#      A testbench that rejects correct hardware is worthless regardless of what
#      else it catches, so this gates everything below it.
#
#   2. UNPROMISED RELIANCE -- does it also pass every CONFORMANT PERTURBATION?
#      Those change only behaviour the spec leaves open, so a correct testbench
#      must accept them. A failure here means the submission checked something
#      the specification never promised. See conformant/README.md.
#
#   3. MUTANT KILL RATE -- NOT AVAILABLE. v_ca05 has no mutant set; step 3 of
#      the verification build prompt was never done. This script reports that
#      explicitly rather than printing a score over an empty set, because
#      "killed 0 of 0" reads like a result and is not one.
#
# So a PASS here means "does not reject correct hardware and relies on nothing
# unpromised". It does NOT mean the testbench is any good at finding bugs --
# that is precisely what the missing mutants would measure.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

TASK_ARG="${1:?usage: sim_verification.sh <task> <submission.sv|dir> [label]}"
SUB_ARG="${2:?missing submission}"
LABEL="${3:-}"

# --- resolve the task under verification/, never design/ ---------------------
if [ -d "$TASK_ARG" ]; then
  TASK_DIR="$(cd "$TASK_ARG" && pwd)"
else
  N="$(ls -d "$REPO"/domains/*/verification/"${TASK_ARG}"_* 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$N" -gt 1 ]; then
    echo "REJECTED: '$TASK_ARG' matches $N verification tasks. Nothing was run." >&2
    exit 2
  fi
  TASK_DIR="$(ls -d "$REPO"/domains/*/verification/"${TASK_ARG}"_* 2>/dev/null | head -1)"
  [ -n "$TASK_DIR" ] || { echo "cannot resolve verification task '$TASK_ARG'" >&2
    echo "known: $(ls -d "$REPO"/domains/*/verification/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ' ')" >&2
    exit 2; }
fi
TASK_NAME="$(basename "$TASK_DIR")"

DUT_DIR="$TASK_DIR/dut"
CONF="$TASK_DIR/conformant/conformant_perturbations.sv"
[ -d "$DUT_DIR" ] || { echo "REFUSED: no dut/ under $TASK_DIR" >&2; exit 2; }

# The golden top and the TB module the submission must declare. Named
# explicitly, never discovered by pattern -- rule 10.
GOLDEN_TOP="tag_tracker"
TB_MOD="tag_tracker_tb"

# --- collect submissions -----------------------------------------------------
SUBS=()
if [ -d "$SUB_ARG" ]; then
  for f in "$SUB_ARG"/*.sv; do [ -f "$f" ] && SUBS+=("$f"); done
  [ "${#SUBS[@]}" -gt 0 ] || { echo "no .sv submissions in $SUB_ARG"; exit 2; }
else
  SUBS=("$SUB_ARG")
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Golden, renamed so a perturbation can take its place under the original name.
# The submission instantiates `tag_tracker` by name -- the blind task tells it
# to -- so substitution has to happen at the module-name level.
python3 -c 'import re,sys; src=open(sys.argv[1],encoding="utf-8").read(); \
open(sys.argv[2],"w",encoding="utf-8").write(re.sub(r"\b"+sys.argv[3]+r"\b", sys.argv[3]+"_golden", src))' \
    "$DUT_DIR/$GOLDEN_TOP.sv" "$WORK/golden_renamed.sv" "$GOLDEN_TOP"
SUPPORT=()
for f in "$DUT_DIR"/*.sv; do
  [ "$(basename "$f")" = "$GOLDEN_TOP.sv" ] && continue
  SUPPORT+=("$f")
done

# One passthrough + one wrapper per perturbation, each presenting itself as
# `tag_tracker` and delegating to `tag_tracker_golden`.
DUTS=("golden")
if [ -f "$CONF" ]; then
  while read -r m; do DUTS+=("$m"); done < <(grep -oE "^module (tt_c[A-Za-z0-9_]+)" "$CONF" | awk '{print $2}')
fi

build_variant() {   # $1 = golden | tt_cN_...  -> writes variant.sv + extra.sv
  python3 "$REPO/scripts/_verif_variant.py" "$WORK" "$1" "$CONF" "$GOLDEN_TOP" || exit 2
}

echo "task=$TASK_NAME  golden=$GOLDEN_TOP  tb=$TB_MOD  duts=${#DUTS[@]}  submissions=${#SUBS[@]}"
echo "================================================================================"

NPASS=0
for sub in "${SUBS[@]}"; do
  label="${LABEL:-$(basename "$sub" .sv)}"
  echo "---- $label ----"

  # NBSP normalisation on a COPY -- chat interfaces substitute U+00A0 and both
  # Verilator and slang report it as something else entirely. CONVENTIONS.md.
  python3 -c "
import sys,io
src=open(sys.argv[1],encoding='utf-8',errors='replace').read()
open(sys.argv[2],'w',encoding='utf-8').write(src.replace(' ',' '))" "$sub" "$WORK/sub.sv"

  # Transport damage is a SETUP problem, not a result. Refuse before compiling
  # so a paste artifact is never attributed to the model.
  if ! python3 "$REPO/scripts/check_transport.py" "$sub" >"$WORK/tp.log" 2>&1; then
    sed 's/^/  /' "$WORK/tp.log"
    echo
    continue
  fi

  if ! grep -qE "^\s*module\s+$TB_MOD\b" "$WORK/sub.sv"; then
    echo "  REJECTED: does not declare module $TB_MOD"
    echo
    continue
  fi

  allok=1; buildfail=0
  for v in "${DUTS[@]}"; do
    build_variant "$v"
    rm -rf "$WORK/obj"
    if ! verilator --binary -j 4 --timing -Wno-fatal --top-module "$TB_MOD" \
         -o run --Mdir "$WORK/obj" \
         "${SUPPORT[@]}" "$WORK/variant.sv" "$WORK/extra.sv" "$WORK/sub.sv" \
         >"$WORK/build.log" 2>&1; then
      # A BUILD failure is NOT a verdict about the DUT. Kept distinct from
      # FAIL, and the error is printed in full: truncating it to 60 characters
      # cut off before the message every time, leaving only a temp path.
      allok=0
      if [ "$buildfail" -eq 0 ]; then
        # The submission is the same file on every row, so a compile error is
        # identical five times over. Print it once.
        buildfail=1
        echo "  DID NOT COMPILE (same on every DUT -- the submission does not build):"
        grep -E '%Error' "$WORK/build.log" | head -5 \
          | sed "s|$WORK/sub.sv|<submission>|g; s|^|      |"
      fi
      continue
    fi
    out="$("$WORK/obj/run" 2>&1)"
    if echo "$out" | grep -qE "^RESULT: *PASS"; then verdict=PASS; else verdict=FAIL; fi
    # golden and every conformant perturbation must PASS
    [ "$verdict" = "PASS" ] || allok=0
    printf "  %-26s %s\n" "$v" "$verdict"
  done

  if [ "$allok" -eq 1 ]; then
    echo "  => ACCEPTED: passes the golden DUT and every conformant perturbation."
    NPASS=$((NPASS+1))
  else
    if [ "$buildfail" -eq 1 ]; then
      echo "  => DID NOT COMPILE. This is NOT a verdict about the testbench's"
      echo "     checking: nothing ran, so nothing was measured. Line numbers above"
      echo "     refer to the submission."
      echo "     Common causes seen here: a SystemVerilog RESERVED WORD used as an"
      echo "     identifier (context, do, ref, expect, this, final, table), and"
      echo "     transport corruption from the paste (see the note below)."
    else
      echo "  => REJECTED: see the FAIL rows above."
      echo "     A failure on 'golden' means the testbench rejects correct hardware."
      echo "     A failure on a 'tt_c*' row means it relies on unpromised behaviour."
    fi
  fi
  echo
done

echo "================================================================================"
echo "$NPASS of ${#SUBS[@]} submission(s) passed the validity gate."
echo
echo "MUTANT KILL RATE NOT MEASURED -- $TASK_NAME has no mutant set."
echo "This score says the testbench does not reject correct hardware and relies on"
echo "nothing unpromised. It says NOTHING about whether it finds bugs, which is"
echo "what the mutants would measure. Do not report it as a verification score."
