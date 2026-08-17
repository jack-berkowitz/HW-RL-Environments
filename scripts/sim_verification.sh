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
#   3. FAULT DETECTION -- per mutant, never as a rate. If a task has no mutant
#      set the script says so rather than printing a score over an empty set,
#      because "caught 0 of 0" reads like a result and is not one.
#      (This comment previously claimed v_ca05 HAS no mutant set while the code
#      below read six of them -- the doc and the code disagreeing about the same
#      file.)
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

# ---- harness parameters FROM task.yaml, never hardcoded --------------------
# These were literals, so the script silently produced nonsense for any task
# whose modules are not called tag_tracker -- and there is no second
# verification task yet, so nothing exposed it. Read from the task, and REFUSE
# when absent: a missing parameter must stop the run, not default to v_ca05's.
yget() {  # $1 = key under `harness:`
  python3 - "$TASK_DIR/task.yaml" "$1" <<'PYY'
import re, sys
try:
    t = open(sys.argv[1], encoding="utf-8").read()
except OSError:
    sys.exit(0)
m = re.search(r"^harness:\s*$(.*?)(?=^\S)", t, re.M | re.S)
if not m:
    sys.exit(0)
v = re.search(r"^\s+%s:\s*(.+?)\s*$" % re.escape(sys.argv[2]), m.group(1), re.M)
print(v.group(1).split("#")[0].strip() if v else "")
PYY
}

# Include directories, so a verification anchor with an `include compiles. The
# design half has ref/sim_flags_verilator.txt for this; the verification half had
# nothing, so any anchor with an include failed -- fpnew_noncomp.sv includes
# common_cells/registers.svh, which is the next verification task in line.
INCDIRS="$(yget include_dirs)"
VINC=()
for d in $INCDIRS; do VINC+=("+incdir+$REPO/$d"); done

GOLDEN_TOP="$(yget golden_top)"
TB_MOD="$(yget tb_module)"
CONF_PREFIX="$(yget conformant_prefix)"
MUT_PREFIX="$(yget mutant_prefix)"
for _v in GOLDEN_TOP TB_MOD CONF_PREFIX MUT_PREFIX; do
  if [ -z "${!_v}" ]; then
    echo "REFUSED: $TASK_DIR/task.yaml has no harness.$(echo "$_v" | tr 'A-Z' 'a-z')" >&2
    echo "  The harness will not guess module names. Add a harness: block with" >&2
    echo "  golden_top, tb_module, conformant_prefix and mutant_prefix." >&2
    exit 2
  fi
done
# 25 s against a measured 0.02-0.30 s for the reference testbench and 0.26 s for
# a real submission -- roughly 80x to 1000x margin. Deliberately generous: a
# watchdog tuned near real runtime stops being a liveness check and becomes a
# performance check on the submission, which nothing in the spec licenses.
# Override with SIM_TIMEOUT_S if a task's stimulus is genuinely longer.
SIM_TIMEOUT_S="${SIM_TIMEOUT_S:-25}"

# ---- SECOND-DUT GATE -------------------------------------------------------
# A verification task's second DUT is the analogue of a design task's second
# source: an INDEPENDENT correct implementation the submission must also accept.
# Without it, "passes the golden" cannot separate a testbench that checks the
# CONTRACT from one fitted to this implementation's incidental choices.
#
# The conformant perturbations do not substitute: they vary what the spec leaves
# open, but they are perturbations OF the golden, so a misconception shared
# between the golden and the checks stays invisible to them.
#
# Declared in task.yaml so the requirement is visible in the task rather than
# only here, and so a task records ABSENT deliberately instead of the harness
# silently not looking.
SECOND_DUT="$(python3 - "$TASK_DIR/task.yaml" <<'PYY'
import re, sys
try:
    t = open(sys.argv[1], encoding="utf-8").read()
except OSError:
    print("MISSING"); sys.exit(0)
m = re.search(r"^second_dut:\s*$(.*?)(?=^\S|\Z)", t, re.M | re.S)
if not m:
    print("MISSING")
else:
    s = re.search(r"^\s+status:\s*(\S+)", m.group(1), re.M)
    print(s.group(1) if s else "MISSING")
PYY
)"
SECOND_DUT_WARN=0
case "$SECOND_DUT" in
  MISSING)
    echo "REFUSED: $TASK_DIR/task.yaml declares no second_dut: status." >&2
    echo "  A verification task must state whether it has an independent second" >&2
    echo "  implementation. 'Passes the golden' cannot on its own distinguish a" >&2
    echo "  testbench that checks the CONTRACT from one fitted to this particular" >&2
    echo "  implementation. Record 'status: ABSENT' with the reason, or provide" >&2
    echo "  it. Silence is not an answer." >&2
    exit 2 ;;
  ABSENT)
    SECOND_DUT_WARN=1 ;;
  *)
    if [ ! -d "$TASK_DIR/dut2" ]; then
      echo "REFUSED: task.yaml says second_dut status '$SECOND_DUT' but" >&2
      echo "  $TASK_DIR/dut2 does not exist. Declared-and-absent is worse than" >&2
      echo "  absent-and-declared: nothing would have run against it." >&2
      exit 2
    fi ;;
esac


# --- collect submissions -----------------------------------------------------
SUBS=()
if [ -d "$SUB_ARG" ]; then
  for f in "$SUB_ARG"/*.sv; do [ -f "$f" ] && SUBS+=("$f"); done
  [ "${#SUBS[@]}" -gt 0 ] || { echo "no .sv submissions in $SUB_ARG"; exit 2; }
else
  # REFUSE a path that does not exist. Previously this fell through and printed
  # two tracebacks from the normalisation and variant helpers, then continued to
  # a scoreline -- the same shape as the task-resolution refusal, one argument
  # along.
  if [ ! -f "$SUB_ARG" ]; then
    echo "REFUSED: no such submission file: $SUB_ARG" >&2
    echo "  Pass a .sv file or a directory of them. Nothing was scored." >&2
    exit 2
  fi
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
  while read -r m; do DUTS+=("$m"); done < <(grep -oE "^module (${CONF_PREFIX}[A-Za-z0-9_]+)" "$CONF" | awk '{print $2}')
fi
# Mutants VIOLATE the spec and must be KILLED -- opposite sign to conformant.
MUT="$TASK_DIR/mutants/mutants.sv"
MUTS=()
if [ -f "$MUT" ]; then
  while read -r m; do MUTS+=("$m"); DUTS+=("$m"); done \
    < <(grep -oE "^module (${MUT_PREFIX}[A-Za-z0-9_]+)" "$MUT" | awk '{print $2}')
fi

build_variant() {   # $1 = golden | tt_cN_...  -> writes variant.sv + extra.sv
  case "$1" in ${MUT_PREFIX}*) SRC="$MUT" ;; *) SRC="$CONF" ;; esac
  if ! python3 "$REPO/scripts/_verif_variant.py" "$WORK" "$1" "$SRC" "$GOLDEN_TOP"; then
    echo "HARNESS ERROR building variant '$1' -- this is a SETUP problem, not a" >&2
    echo "  verdict about the submission. Nothing is scored." >&2
    exit 2
  fi
}

echo "task=$TASK_NAME  golden=$GOLDEN_TOP  tb=$TB_MOD  duts=${#DUTS[@]}  submissions=${#SUBS[@]}"
echo "================================================================================"
if [ "${SECOND_DUT_WARN:-0}" = "1" ]; then
  echo "NOTE: no second DUT. A pass shows the testbench accepts THIS implementation"
  echo "  and the variations the spec permits of it -- not that it checks the"
  echo "  contract independently of how the golden happens to be built."
  echo "================================================================================"
fi

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

  allok=1; buildfail=0; NKILL=0; NMUT=0; NHUNG=0; NCONF=0; NCONF_OK=0
  GOLDEN_VERDICT=unknown
  for v in "${DUTS[@]}"; do
    build_variant "$v"
    rm -rf "$WORK/obj"
    if ! verilator --binary -j 4 --timing -Wno-fatal --top-module "$TB_MOD" \
         -o run --Mdir "$WORK/obj" ${VINC[@]+"${VINC[@]}"} \
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
    # WATCHDOG. A submission with no timeout of its own hangs forever on the
    # starvation mutant -- it waits for a grant that never comes. A hang is NOT
    # a kill: the testbench did not detect starvation, it just stopped. Reported
    # as its own verdict so the two are never conflated.
    "$WORK/obj/run" >"$WORK/run.log" 2>&1 &
    rpid=$!
    waited=0
    while kill -0 "$rpid" 2>/dev/null && [ "$waited" -lt "$SIM_TIMEOUT_S" ]; do
      sleep 1; waited=$((waited+1))
    done
    if kill -0 "$rpid" 2>/dev/null; then
      kill -9 "$rpid" 2>/dev/null; wait "$rpid" 2>/dev/null
      verdict=TIMEOUT
    else
      wait "$rpid" 2>/dev/null
      out="$(cat "$WORK/run.log")"
      if echo "$out" | grep -qE "^RESULT: *PASS"; then verdict=PASS; else verdict=FAIL; fi
    fi
    case "$v" in
      ${MUT_PREFIX}*)   # a mutant must be CAUGHT: PASS here means the defect was missed
        case "$verdict" in
          FAIL)    printf "  %-26s killed\n" "$v"; NKILL=$((NKILL+1)) ;;
          TIMEOUT) printf "  %-26s HUNG  <- no watchdog; not a kill\n" "$v"
                   NHUNG=$((NHUNG+1)); allok=0 ;;
          *)       printf "  %-26s SURVIVED  <- defect not caught\n" "$v"; allok=0 ;;
        esac
        NMUT=$((NMUT+1)) ;;
      *)       # golden and conformant must be ACCEPTED
        [ "$verdict" = "PASS" ] || allok=0
        if [ "$v" = "golden" ]; then
          GOLDEN_VERDICT="$verdict"
        else
          NCONF=$((NCONF+1)); [ "$verdict" = "PASS" ] && NCONF_OK=$((NCONF_OK+1))
        fi
        printf "  %-26s %s\n" "$v" "$verdict" ;;
    esac
  done

  # ---- RUN RECORD. Rule 8 applies to the verification half too, and did not
  # hold there: every v_ca05 number was a literal print() and nothing outside
  # the terminal ever saw it. That is F20 reproduced on this side of the
  # harness -- a control built for the design path and never carried across.
  python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$sub" sim "$label" \
    "status=$([ "$allok" -eq 1 ] && echo completed || echo rejected)" \
    "all_passed=$([ "$allok" -eq 1 ] && echo true || echo false)" \
    "golden_accepted=$GOLDEN_VERDICT" \
    "conformant_accepted=$NCONF_OK/$NCONF" \
    "faults_caught=$([ "$GOLDEN_VERDICT" = "PASS" ] && echo "$NKILL/$NMUT" || echo "SUPPRESSED-gate-failed")" \
    "faults_hung=$NHUNG" \
    "did_not_compile=$buildfail" \
    "kind_note=verification: per-mutant results are in the log; a rate is not reported" \
    >/dev/null 2>&1 || true

  # A kill count from a submission that failed the VALIDITY GATE carries no
  # information: a testbench that rejects everything appears to catch
  # everything (rule 16). Printing "4/6 caught" beside a real 4/6 is the
  # reporting-layer form of F20 -- a number that looks like a measurement and
  # is not. Suppressed, with the reason, rather than shown.
  if [ "$GOLDEN_VERDICT" != "PASS" ] && [ "${NMUT:-0}" -gt 0 ]; then
    echo "  -- fault-detection result SUPPRESSED: this testbench REJECTS THE"
    echo "     GOLDEN DUT, so it rejects correct and faulty hardware alike and"
    echo "     its $NKILL/$NMUT tells you nothing (rule 16). Hangs likewise: a"
    echo "     hang is not detection, and $NHUNG of these hung."
  fi

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
      echo "     A failure on a '${CONF_PREFIX}*' row means it relies on unpromised behaviour."
    fi
  fi
  echo
done

echo "================================================================================"
echo "$NPASS of ${#SUBS[@]} submission(s) passed the validity gate."
echo
if [ "${NMUT:-0}" -eq 0 ]; then
  echo "MUTANT KILL RATE NOT MEASURED -- $TASK_NAME has no mutant set."
  echo "This score says the testbench does not reject correct hardware and relies"
  echo "on nothing unpromised, and NOTHING about whether it finds bugs."
else
  echo "Kill rate is reported PER MUTANT above, not as a total. Which mutant"
  echo "survived is the informative part; a rate averages that away."
  echo
  echo "A kill from a submission that FAILED the golden carries no information --"
  echo "a testbench that rejects everything appears to kill everything (rule 16)."
fi
