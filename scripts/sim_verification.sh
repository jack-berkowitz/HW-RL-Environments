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
# Explicit identifier for the gate mutant. It is NOT a scored mutant and must
# never enter a kill-rate numerator or denominator, so it is matched by this
# constant rather than by position in DUTS or by a name prefix.
GATE_ID="__gate_mutant__"
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
    f = re.search(r"^\s+file:\s*(\S+)", m.group(1), re.M)
    print(s.group(1) if s else "MISSING")
    print(f.group(1) if f else "")
PYY
)"
SECOND_DUT_FILE="$(printf '%s\n' "$SECOND_DUT" | sed -n 2p)"
SECOND_DUT="$(printf '%s\n' "$SECOND_DUT" | sed -n 1p)"
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
  BUILT_UNWIRED)
    # This state used to be reachable and was the bug: three tasks declared it,
    # the gate accepted it because dut2/ existed, and nothing ever compiled
    # against the second DUT (F40). The harness now always runs a declared
    # second DUT, so "built but not wired" can no longer be true of anything.
    echo "REFUSED: second_dut status BUILT_UNWIRED is no longer a reachable" >&2
    echo "  state. A declared second DUT is compiled and run; if it is present" >&2
    echo "  say WIRED, and if there is none say ABSENT with the reason." >&2
    echo "  This status described the F40 defect, not a property of the task." >&2
    exit 2 ;;
  *)
    if [ -z "$SECOND_DUT_FILE" ] || [ ! -f "$TASK_DIR/$SECOND_DUT_FILE" ]; then
      echo "REFUSED: task.yaml says second_dut status '$SECOND_DUT' but its" >&2
      echo "  file: is missing or does not resolve under $TASK_DIR." >&2
      echo "  Declared-and-absent is worse than absent-and-declared: nothing" >&2
      echo "  would have run against it." >&2
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

# ---- THE VALIDITY GATE ------------------------------------------------------
# A submission must produce DIFFERENT verdicts on the golden and on a
# mechanically generated gate mutant: PASS the golden, FAIL the mutant. One that
# cannot tell them apart did not measure anything, whatever else it reports.
#
# This replaced a gate that was satisfiable without discriminating. negctl/
# null_tb.sv instantiates no DUT, drives nothing, prints RESULT: PASS -- and the
# harness reported "1 of 1 submission(s) passed the validity gate" and scored it
# 0/8. An instantiate-and-ignore testbench did the same.
#
# NOT a DUT-instantiation check. Instantiation is a source-level property and is
# satisfied by instantiating the DUT and ignoring it; every source-level or
# lint-style gate is gameable by construction. A required DIFFERENCE IN OUTCOME
# has no source-level counterfeit.
#
# The mutant is GENERATED, not authored: one script, any golden, every output
# tied to '1. It is not the per-task Tier-B authoring control, which may
# legitimately be subtle; this is a floor and is deliberately maximally obvious.
GATE_MUT="$WORK/gate_mutant.sv"
GATE_OK_TO_RUN=1
if ! python3 "$REPO/scripts/make_gate_mutant.py" \
        "$DUT_DIR/$GOLDEN_TOP.sv" "$GOLDEN_TOP" "$GATE_MUT" >/dev/null 2>&1; then
  echo "REFUSED: could not generate the validity-gate mutant from" >&2
  echo "  $DUT_DIR/$GOLDEN_TOP.sv. Without it the gate cannot run, and a run" >&2
  echo "  without the gate cannot report a validity verdict. Nothing scored." >&2
  exit 2
fi

# THE GATE MUTANT MUST ELABORATE. A syntactically broken one is useless as a
# gate: it fails to build, every submission fails identically, and the failure
# surfaces as "the submission does not build" -- blaming the submission for a
# harness defect. Worse, a broken mutant makes null_tb.sv show PASS-golden /
# FAIL-mutant, which SATISFIES a naive gate. Checked here, and a failure is a
# REFUSAL, never a verdict about anyone's submission.
if ! verilator --lint-only -Wno-lint -Wno-fatal --timing --top-module "$GOLDEN_TOP" \
     ${VINC[@]+"${VINC[@]}"} "${SUPPORT[@]}" "$GATE_MUT" >"$WORK/gate_lint.log" 2>&1; then
  echo "REFUSED: the generated validity-gate mutant does not elaborate." >&2
  echo "  This is a HARNESS SETUP problem, not a verdict about any submission." >&2
  echo "  A gate mutant that fails to build cannot discriminate: every" >&2
  echo "  submission would fail it identically, including one that checks" >&2
  echo "  nothing. Nothing was scored." >&2
  grep -m3 "%Error" "$WORK/gate_lint.log" | sed 's|^|    |' >&2
  exit 2
fi

# One passthrough + one wrapper per perturbation, each presenting itself as
# `tag_tracker` and delegating to `tag_tracker_golden`.
DUTS=("golden" "$GATE_ID")
if [ -f "$CONF" ]; then
  while read -r m; do DUTS+=("$m"); done < <(grep -oE "^module (${CONF_PREFIX}[A-Za-z0-9_]+)" "$CONF" | awk '{print $2}')
fi
# The second DUT is an ADDITIONAL must-accept implementation. Until this line
# existed the gate above proved only that dut2/ was on disk -- "we built the
# control" and "the control is in the path and is read" are different claims.
if [ -n "$SECOND_DUT_FILE" ] && [ -f "$TASK_DIR/$SECOND_DUT_FILE" ]; then
  DUTS+=("dut2")
fi
# Mutants VIOLATE the spec and must be KILLED -- opposite sign to conformant.
MUT="$TASK_DIR/mutants/mutants.sv"
MUTS=()
if [ -f "$MUT" ]; then
  while read -r m; do MUTS+=("$m"); DUTS+=("$m"); done \
    < <(grep -oE "^module (${MUT_PREFIX}[A-Za-z0-9_]+)" "$MUT" | awk '{print $2}')
fi

build_variant() {   # $1 = golden | tt_cN_...  -> writes variant.sv + extra.sv
  case "$1" in
    ${MUT_PREFIX}*) SRC="$MUT" ;;
    dut2)           SRC="$TASK_DIR/$SECOND_DUT_FILE" ;;
    "$GATE_ID")     SRC="$GATE_MUT" ;;
    *)              SRC="$CONF" ;;
  esac
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

  # IDENTITY OF THE BYTES WE ACTUALLY READ, taken now rather than at record
  # time. The record is written after every variant has run; hashing the path
  # then reports whatever is on disk at that later moment, which is a different
  # file if the candidate was replaced mid-run.
  SUB_SHA="$(python3 -c "
import hashlib,sys
print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest()[:16])" "$sub")"

  # Transport damage is a SETUP problem, not a result. Refuse before compiling
  # so a paste artifact is never attributed to the model.
  if ! python3 "$REPO/scripts/check_transport.py" "$sub" >"$WORK/tp.log" 2>&1; then
    sed 's/^/  /' "$WORK/tp.log"
    echo
    continue
  fi

  if ! grep -qE "^\s*module\s+$TB_MOD\b" "$WORK/sub.sv"; then
    echo "  REJECTED: does not declare module $TB_MOD"
    # A REJECTION IS A RESULT AND MUST LEAVE A RECORD. `continue` used to skip
    # the record writer, so this submission produced NOTHING in runs/ and any
    # table counting from records omitted it -- the same defect fixed on the
    # design side for slang rejections. v_ca04/gemini was invisible this way.
    #
    # No golden/gate verdict and no fault count are written: nothing ran.
    # `build_status` says what happened, and absence everywhere else renders
    # as NO VERDICT rather than as a claim about the testbench's checking.
    tt="$(python3 "$REPO/scripts/task_text_hash.py" "$TASK_DIR" 2>/dev/null | head -1)"
    python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$sub" sim "$label" \
      "submission_sha256_16=$SUB_SHA" \
      "task_text_hash=$tt" \
      "build_status=wrong_module_name" \
      "build_error=does not declare module $TB_MOD" >/dev/null || \
      echo "  RECORD NOT WRITTEN for $label" >&2
    echo
    continue
  fi

  allok=1; buildfail=0; NKILL=0; NMUT=0; NHUNG=0; NCONF=0; NCONF_OK=0
  DUT2_VERDICT="not-run"
  GATE_VERDICT="not-run"   # fail closed: anything but FAIL is not a gate pass
  CONF_FAILED=(); MUT_SURVIVED=(); MUT_HUNG=()
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
      wait "$rpid" 2>/dev/null; rc=$?
      out="$(cat "$WORK/run.log")"
      # THREE outcomes, not two. A simulation that DIED -- killed by the OS,
      # out of memory, a runtime abort -- prints no RESULT line at all.
      # Reading "no PASS" as FAIL turns a machine event into a verdict about
      # the submission, and it is LOAD DEPENDENT: v_nw02's reference testbench
      # scored PASS standalone and FAIL inside a batch running alongside an
      # ORFS build. Byte-identical file, opposite verdict. An absent verdict
      # is ABSENT (rule 20), not a failure.
      #
      # GREP THE FILE, NEVER `echo "$out" | grep -q`. With `set -o pipefail`
      # (line 42) that pipeline returns the FIRST failure in it, and `grep -q`
      # exits the instant it matches -- so `echo` is still writing, takes
      # SIGPIPE, and the pipeline reports 141 WHILE GREP MATCHED. Measured:
      # gp=1 gf=141 gfile=0 on a 97 KB log whose line 1709 is `RESULT: FAIL`.
      # It only bites above the ~64 KB pipe buffer, so short logs always
      # worked and long ones lost their verdict -- which is why this looked
      # like load and read as "the submission failed".
      if   grep -qE "^RESULT: *PASS" "$WORK/run.log"; then verdict=PASS
      elif grep -qE "^RESULT: *FAIL" "$WORK/run.log"; then verdict=FAIL
      else verdict=CRASH; CRASH_RC="$rc"
      fi
    fi
    case "$v" in
      "$GATE_ID")
        # THE VALIDITY GATE. This DUT has every output tied to '1. A submission
        # that observes ANY output at all must reject it. Producing the same
        # verdict here as on the golden means the submission did not
        # discriminate, and nothing it reports afterwards is a measurement.
        #
        # FAIL CLOSED. Only an explicit FAIL counts as discriminating. TIMEOUT
        # and a missing verdict are NOT passes: an absent result must never read
        # as a gate pass, which is the same defect as a missing sim verdict
        # rendering as a score.
        GATE_VERDICT="$verdict"
        case "$verdict" in
          FAIL)    printf "  %-26s rejected (gate)\n" "gate-mutant" ;;
          TIMEOUT) printf "  %-26s HUNG on the gate mutant\n" "gate-mutant" ;;
          CRASH)   printf "  %-26s DIED (no verdict) on the gate mutant\n" "gate-mutant" ;;
          *)       printf "  %-26s ACCEPTED  <- did not discriminate\n" "gate-mutant" ;;
        esac
        # NOT a scored mutant: never touches NKILL or NMUT.
        ;;
      ${MUT_PREFIX}*)   # a mutant must be CAUGHT: PASS here means the defect was missed
        case "$verdict" in
          FAIL)    printf "  %-26s killed\n" "$v"; NKILL=$((NKILL+1)) ;;
          TIMEOUT) printf "  %-26s HUNG  <- no watchdog; not a kill\n" "$v"
                   MUT_HUNG+=("$v"); NHUNG=$((NHUNG+1)); allok=0 ;;
          CRASH)   printf "  %-26s DIED  <- no verdict; not a kill\n" "$v"
                   MUT_HUNG+=("$v"); NHUNG=$((NHUNG+1)); allok=0 ;;
          *)       printf "  %-26s SURVIVED  <- defect not caught\n" "$v"
                   MUT_SURVIVED+=("$v"); allok=0 ;;
        esac
        NMUT=$((NMUT+1)) ;;
      *)       # golden, second DUT and conformant must all be ACCEPTED
        [ "$verdict" = "PASS" ] || allok=0
        if [ "$v" = "golden" ]; then
          GOLDEN_VERDICT="$verdict"
        elif [ "$v" = "dut2" ]; then
          # Kept SEPARATE from the conformant tally on purpose: a conformant
          # failure means the testbench relies on something the spec leaves
          # open, while a dut2 failure means it is fitted to the golden's
          # implementation. Different defects, so not one number.
          DUT2_VERDICT="$verdict"
        else
          NCONF=$((NCONF+1))
          if [ "$verdict" = "PASS" ]; then NCONF_OK=$((NCONF_OK+1)); else CONF_FAILED+=("$v"); fi
        fi
        printf "  %-26s %s\n" "$v" "$verdict" ;;
    esac
  done

  # THE VALIDITY GATE: golden, second DUT and conformant. Computed here because
  # both the suppression below and the summary depend on it, and they must not
  # disagree -- suppressing only on `golden` while REJECTING on conformant would
  # print a kill count beside a REJECTED verdict.
  # DISCRIMINATION comes first: PASS the golden, FAIL the gate mutant. Anything
  # else is INVALID, not "valid with gaps". Fail closed -- only an explicit FAIL
  # on the mutant counts, so TIMEOUT / no-verdict / not-run all read as INVALID.
  DISCRIMINATES=1
  [ "$GOLDEN_VERDICT" = "PASS" ] || DISCRIMINATES=0
  [ "$GATE_VERDICT"   = "FAIL" ] || DISCRIMINATES=0

  GATE_OK=1
  [ "$GOLDEN_VERDICT" = "PASS" ] || GATE_OK=0
  [ "$DISCRIMINATES" -eq 1 ] || GATE_OK=0
  [ "${#CONF_FAILED[@]}" -eq 0 ] || GATE_OK=0
  case "$DUT2_VERDICT" in PASS|not-run) ;; *) GATE_OK=0 ;; esac

  # ---- RUN RECORD. Rule 8 applies to the verification half too, and did not
  # hold there: every v_ca05 number was a literal print() and nothing outside
  # the terminal ever saw it. That is F20 reproduced on this side of the
  # harness -- a control built for the design path and never carried across.
  python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$sub" sim "$label" \
    "submission_sha256_16=$SUB_SHA" \
    "status=$([ "$allok" -eq 1 ] && echo completed || echo rejected)" \
    "all_passed=$([ "$allok" -eq 1 ] && echo true || echo false)" \
    "golden_accepted=$GOLDEN_VERDICT" \
    "second_dut_accepted=$DUT2_VERDICT" \
    "gate_mutant_verdict=$GATE_VERDICT" \
    "discriminates=$([ "${DISCRIMINATES:-0}" -eq 1 ] && echo true || echo false)" \
    "conformant_accepted=$NCONF_OK/$NCONF" \
    "faults_caught=$([ "${GATE_OK:-0}" -eq 1 ] && echo "$NKILL/$NMUT" || echo "SUPPRESSED-gate-failed")" \
    "faults_hung=$NHUNG" \
    "did_not_compile=$buildfail" \
    "kind_note=verification: per-mutant results are in the log; a rate is not reported" \
    "task_text_hash=$(python3 "$REPO/scripts/task_text_hash.py" "$TASK_DIR" 2>/dev/null | head -1)" \
    >/dev/null 2>&1 || true

  # A kill count from a submission that failed the VALIDITY GATE carries no
  # information: a testbench that rejects everything appears to catch
  # everything (rule 16). Printing "4/6 caught" beside a real 4/6 is the
  # reporting-layer form of F20 -- a number that looks like a measurement and
  # is not. Suppressed, with the reason, rather than shown.
  if [ "$GATE_OK" -eq 0 ] && [ "${NMUT:-0}" -gt 0 ]; then
    echo "  -- fault-detection result SUPPRESSED: this testbench REJECTS CORRECT"
    echo "     HARDWARE (golden, second DUT, or a legal variant), so it rejects"
    echo "     correct and faulty designs alike and its $NKILL/$NMUT tells you"
    echo "     nothing (rule 16). Hangs likewise: a hang is not detection, and"
    echo "     $NHUNG of these hung."
  fi

  # ---- SUMMARY -------------------------------------------------------------
  # THE VALIDITY GATE AND FAULT DETECTION ARE SEPARATE OUTCOMES, and this
  # summary used to collapse them: `allok` is cleared by ANY failure including
  # a surviving mutant, so a testbench that passed the golden, every
  # conformant row and dut2, and missed one mutant, printed "REJECTED" with an
  # explanation naming golden and conformant failures that had not occurred.
  # gemini on v_nw03 -- 9 of 10, the second-best result in the project -- read
  # as a rejection. That is F36's shape: computed correctly per row, then
  # misrepresented at the summary.
  #
  # The reason text is now DERIVED from the rows that actually failed. If
  # nothing failed, nothing is claimed.
  # A GOLDEN THAT NEVER PRODUCED A VERDICT IS NOT A REJECTION. The simulation
  # died without printing RESULT, so there is nothing to interpret. This branch
  # precedes the INVALID one deliberately: saying "it does not discriminate" of
  # a run that produced no verdict states a property of the submission that was
  # never measured. Two causes, and this cannot tell them apart -- the machine
  # (killed under load, out of memory) or the submission (a runtime abort).
  # Both are reported; neither is scored.
  if [ "$buildfail" -eq 0 ] && [ "$GOLDEN_VERDICT" = "CRASH" ]; then
    echo "  => NO VERDICT. The run against the correct DUT produced no RESULT"
    echo "     line: the simulation died rather than reporting PASS or FAIL"
    printf "     (exit %s). NOT a statement about this testbench's checking.\n" \
           "${CRASH_RC:-unknown}"
    echo "     Either the machine killed it (load, memory) or the submission"
    echo "     aborted at runtime. Re-run it alone before reading anything into"
    echo "     it. A byte-identical file has scored PASS standalone and died"
    echo "     inside a batch sharing the machine with an ORFS build."
    echo "     EXCLUDED FROM SCORING, and not counted against the submission."
  elif [ "$buildfail" -eq 0 ] && [ "$DISCRIMINATES" -eq 0 ]; then
    echo "  => INVALID: this submission does not DISCRIMINATE."
    echo "     It must PASS the golden DUT and FAIL a DUT with every output tied"
    echo "     to '1. It did not, so it is not measuring the design under test."
    printf "     golden=%s  gate-mutant=%s\n" "$GOLDEN_VERDICT" "$GATE_VERDICT"
    if [ "$GOLDEN_VERDICT" = "PASS" ] && [ "$GATE_VERDICT" = "PASS" ]; then
      echo "     Accepting both means it accepts anything: a testbench that"
      echo "     drives nothing, or instantiates the DUT and checks nothing,"
      echo "     lands here."
    elif [ "$GOLDEN_VERDICT" = "FAIL" ] && [ "$GATE_VERDICT" = "FAIL" ]; then
      echo "     Rejecting both means it rejects anything, which is the same"
      echo "     non-measurement pointing the other way."
    elif [ "$GATE_VERDICT" = "TIMEOUT" ] || [ "$GATE_VERDICT" = "not-run" ] \
         || [ "$GATE_VERDICT" = "CRASH" ]; then
      echo "     No verdict from the gate mutant. An absent result is NOT a gate"
      echo "     pass; the gate fails closed."
    fi
    echo "     EXCLUDED FROM SCORING. Its fault-detection numbers are not a score."
  elif [ "$buildfail" -eq 1 ]; then
    echo "  => DID NOT COMPILE. This is NOT a verdict about the testbench's"
    echo "     checking: nothing ran, so nothing was measured. Line numbers above"
    echo "     refer to the submission."
    echo "     Common causes seen here: a SystemVerilog RESERVED WORD used as an"
    echo "     identifier (context, do, ref, expect, this, final, table), and"
    echo "     transport corruption from the paste (see the note below)."
  elif [ "$GATE_OK" -eq 0 ]; then
    echo "  => REJECTED: failed the VALIDITY GATE."
    [ "$GOLDEN_VERDICT" = "PASS" ] || \
      echo "     - rejects the GOLDEN DUT: it rejects correct hardware."
    if [ "${#CONF_FAILED[@]}" -gt 0 ]; then
      echo "     - rejects ${#CONF_FAILED[@]} of $NCONF conformant perturbation(s): ${CONF_FAILED[*]}"
      echo "       These differ from the golden only where the spec is silent, so"
      echo "       rejecting one means relying on unpromised behaviour."
    fi
    case "$DUT2_VERDICT" in PASS|not-run) ;; *)
      echo "     - rejects the SECOND DUT: an independent correct implementation."
      echo "       The testbench is fitted to the golden rather than the contract." ;;
    esac
  else
    # Gate passed. Fault detection is reported, never used to reject.
    if [ "$NMUT" -eq 0 ]; then
      echo "  => VALID: passes the golden DUT, every conformant perturbation and"
      echo "     the second DUT. No mutant set was run, so fault detection is"
      echo "     UNMEASURED -- this says nothing about whether it finds bugs."
    elif [ "$NKILL" -eq "$NMUT" ] && [ "$NHUNG" -eq 0 ]; then
      echo "  => ACCEPTED: passes the validity gate and catches all $NMUT/$NMUT faults."
      echo "     This is the ceiling the reference testbench establishes."
    else
      echo "  => VALID, with gaps in fault detection. NOT a rejection: this"
      echo "     testbench accepts correct hardware and every legal variant."
      echo "     Caught $NKILL of $NMUT faults against a ceiling of $NMUT."
      [ "${#MUT_SURVIVED[@]}" -eq 0 ] || \
        echo "     - missed: ${MUT_SURVIVED[*]}"
      [ "${#MUT_HUNG[@]}" -eq 0 ] || \
        echo "     - hung (not a catch: it stopped, it did not detect): ${MUT_HUNG[*]}"
    fi
    NPASS=$((NPASS+1))
  fi
  echo
done

echo "================================================================================"
echo "$NPASS of ${#SUBS[@]} submission(s) DISCRIMINATE: they pass the golden DUT"
echo "and reject a DUT with every output tied to '1. One that does not is INVALID"
echo "and is excluded from scoring, whatever else it reports."
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
