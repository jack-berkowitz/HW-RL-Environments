#!/bin/bash
# Simulate LLM candidate answers against a domains/ task checker.
#
#   ./scripts/sim_candidate.sh <task> <candidate.sv | dir> [verilator|icarus] [--smoke]
#
# <task> is a task id (d_ca04) or a full path to the task directory.
# <candidate> is one .sv file, or a DIRECTORY of them -- a directory runs every
# answer and prints a pass rate, which is how you tell whether a task is hard
# enough to discriminate.
#
#   ./scripts/sim_candidate.sh d_nw01 candidates/d_nw01/chat.sv
#   ./scripts/sim_candidate.sh d_ca04 candidates/d_ca04
#   ./scripts/sim_candidate.sh d_ca04 candidates/d_ca04 icarus
#
# WHY THIS EXISTS RATHER THAN runner/: runner/config.py models tasks as
# interfaces/<tier>/ + testbenches/<tier>/ and has no notion of
# domains/<domain>/design/<id>_<module>/. Teaching it the new layout is Part 2
# work. This is the stopgap so candidates can be scored today.
#
# THREE THINGS THAT WILL SILENTLY GIVE WRONG ANSWERS, all handled here:
#   1. a checker may read tb/vectors/*.hex by RELATIVE path, so the working
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

SIM="verilator"; SMOKE=""; SLANG=1
shift 2 2>/dev/null || true
for a in "$@"; do
  case "$a" in
    icarus|verilator) SIM="$a" ;;
    --smoke)          SMOKE="--smoke" ;;
    --no-slang)       SLANG=0 ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done

# --- resolve the task: id shorthand or path ----------------------------------
if [ -d "$TASK_ARG" ]; then
  TASK_DIR="$(cd "$TASK_ARG" && pwd)"
elif [ -d "$REPO/$TASK_ARG" ]; then
  TASK_DIR="$(cd "$REPO/$TASK_ARG" && pwd)"
else
  N_MATCH="$(ls -d "$REPO"/domains/*/design/"${TASK_ARG}"_* 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$N_MATCH" -gt 1 ]; then
    echo "REJECTED: task id '$TASK_ARG' matches $N_MATCH directories:" >&2
    ls -d "$REPO"/domains/*/design/"${TASK_ARG}"_* | sed 's|.*/|  |' >&2
    echo "Name the task unambiguously. Nothing was run." >&2
    exit 2
  fi
  TASK_DIR="$(ls -d "$REPO"/domains/*/design/"${TASK_ARG}"_* 2>/dev/null | head -1)"
  [ -n "$TASK_DIR" ] || { echo "cannot resolve task '$TASK_ARG'" >&2
    echo "known tasks: $(ls -d "$REPO"/domains/*/design/*/ 2>/dev/null | xargs -n1 basename | grep -oE '^[a-z]+_[a-z0-9]+' | sort -u | tr '\n' ' ')" >&2
    exit 2; }
fi

DUT_MOD="$(grep -m1 '^module' "$TASK_DIR"/spec/*_iface.sv | sed 's/^module \([A-Za-z0-9_]*\).*/\1/')"

# --- select the SCORING testbench -------------------------------------------
# This was `ls tb/*_tb.sv | head -1`, which picks alphabetically. d_nw01 has
# three tb/*_tb.sv files and `axi4_xbar_liveness_tb.sv` sorts ahead of
# `axi4_xbar_tb.sv`, so the runner silently scored the read-only liveness rig
# instead of the data checker and reported 8/8 PASS for it. A weaker checker
# substituted without a word is the worst failure this harness can have: it
# does not error, it just stops testing most of the contract.
#
# The scoring TB is now REQUIRED to be tb/<dut>_tb.sv. Auxiliary rigs (liveness
# probes, capability audits, second sources) live alongside it under any other
# name and are run deliberately, never picked up by accident.
TB="$TASK_DIR/tb/${DUT_MOD}_tb.sv"
if [ ! -f "$TB" ]; then
  CAND_TBS="$(ls "$TASK_DIR"/tb/*_tb.sv 2>/dev/null)"
  [ -n "$CAND_TBS" ] || { echo "no tb/*_tb.sv in $TASK_DIR" >&2; exit 2; }
  echo "REJECTED: no scoring testbench tb/${DUT_MOD}_tb.sv in $TASK_DIR." >&2
  echo "Found instead:" >&2; echo "$CAND_TBS" | sed 's|.*/|  |' >&2
  echo "Rename the scoring TB to match the DUT module, or this run would score" >&2
  echo "whichever file happened to sort first. Nothing was run." >&2
  exit 2
fi
TB_MOD="$(basename "$TB" .sv)"
TASK_NAME="$(basename "$TASK_DIR")"

# --- legal configs per task. Keep in step with each task.yaml `configs:`. -----
case "$TASK_NAME" in
  d_nw01_axi4_xbar)
      CFGS=(); for m in 2 4; do for sv in 2 4; do for t in 2 8; do for bl in 3 255; do
        CFGS+=("NUM_MST=$m NUM_SLV=$sv MAX_TRANS=$t MAX_BURST_LEN=$bl"); done; done; done; done ;;
  d_ca04_async_fifo_cdc)
      CFGS=(); for w in 8 32 64; do for l in 2 3 4; do for y in 2 3; do
        CFGS+=("DATA_W=$w LOG_DEPTH=$l SYNC_STAGES=$y"); done; done; done ;;
  d_dsp02_fp32_fma_ii1)
      # EXACTLY ONE config, and one BY CONSTRUCTION rather than by omission --
      # the distinction the refusal below exists to enforce. fp32_fma_ii1
      # declares no parameters at all: the format is fixed at binary32 by the
      # spec, and rounding mode is a runtime INPUT (rnd_mode) rather than a
      # parameter, so it is swept by the stimulus and not by elaboration.
      #
      # The coverage that would be configs elsewhere lives in the 4290-vector
      # set instead, with stimulus-side floors per rule 4. If a parameter is
      # ever added here, this list must grow with it or the sweep silently
      # narrows -- which is the defect the *) branch refuses.
      CFGS=("") ;;
  d_ca01_nonblocking_dcache)
      # Full cross of the four swept parameters = 16 configs. Kept in step with
      # `configs:` in the task's task.yaml; if one changes the other must.
      # ADDR_W, ID_W and BLOCK_WORDS are localparams in the interface, not
      # parameters -- a quantity that is never swept is a constant, and
      # declaring it as a parameter would claim a flexibility nothing binds.
      CFGS=(); for dw in 32 64; do for st in 8 16; do for wy in 2 4; do for mm in 2 8; do
        CFGS+=("DATA_W=$dw SETS=$st WAYS=$wy MAX_MISSES=$mm"); done; done; done; done ;;
  d_nw03_axis_switch_oq)
      # Full cross of the three swept parameters = 8 configs. Kept in step with
      # `configs:` in the task's task.yaml; if one changes the other must.
      # KEEP_W and DEST_W are derived localparams in the interface, not
      # parameters -- a quantity that is never swept is a constant.
      CFGS=(); for sc in 2 4; do for mc in 2 4; do for dw in 8 32; do
        CFGS+=("S_COUNT=$sc M_COUNT=$mc DATA_W=$dw"); done; done; done ;;
  d_dsp03_multifmt_fma)
      # ONE swept parameter, two values = 2 configs. Kept in step with
      # `configs:` in the task's task.yaml; if one changes the other must.
      # The per-format geometry and the lane count are DERIVED, not parameters:
      # lanes = WIDTH/format_width, so declaring either would claim a
      # flexibility nothing binds.
      #
      # WIDTH is the capacity parameter and it is bound by RESULT BITS, not by a
      # rate: at WIDTH=64 a vectorial 16-bit operation has four lanes and the
      # vector set carries ~1000 four-lane cases whose lanes all differ. Both
      # values are scored for correctness; S0 pins WIDTH=64 for PPA because that
      # is where the capability check discriminates.
      CFGS=(); for w in 32 64; do CFGS+=("WIDTH=$w"); done ;;
  *)  # REFUSE. This used to print a note and run the TB's own defaults, which
      # reported "1 config" for a task with eight legal ones -- a partial sweep
      # presented as a full one. That is the same defect as picking a testbench
      # by sort order: the run does not fail, it just silently tests less.
      echo "REJECTED: no config list registered for $TASK_NAME." >&2
      echo "Add its legal configs to the case block in scripts/sim_candidate.sh," >&2
      echo "keeping them in step with the task's task.yaml. Nothing was run." >&2
      exit 2 ;;
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

# --- extra build flags declared by the task ---------------------------------
# A task whose REFERENCE pulls in vendored support modules declares them once in
# ref/sim_flags_<sim>.txt rather than every caller re-deriving them. One token
# per line, %REPO% expands to the repo root, # and blank lines ignored.
# Harmless for a self-contained candidate: -y is only consulted for modules that
# are otherwise unresolved.
# testbenches/common/ is the house shared-include directory -- liveness_monitor.svh
# and the Tier-Two memory models live there. Added unconditionally so a checker
# that includes from it builds without every task restating the path; three more
# v3 tasks (d_ca01, d_nw02, d_nw04) reuse the liveness monitor.
if [ "$SIM" = "icarus" ]; then EXTRA=("-I$REPO/testbenches/common")
else                          EXTRA=("+incdir+$REPO/testbenches/common"); fi
FLAGFILE="$TASK_DIR/ref/sim_flags_${SIM}.txt"
if [ -f "$FLAGFILE" ]; then
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    EXTRA+=("${line//%REPO%/$REPO}")
  done < "$FLAGFILE"
fi

echo "task=$TASK_NAME  dut=$DUT_MOD  sim=$SIM  configs=${#CFGS[@]}  candidates=${#CANDS[@]}${EXTRA:+  extra_flags=${#EXTRA[@]}}"
echo "================================================================================"

# --- run one candidate over every config; echoes "<pass> <total>|<firstfail>" -
run_one() {
  local cand="$1" p=0 t=0 first="" cerr="" CERR=""
  # RAW_DIR is created by the CALLER: run_one executes inside a command
  # substitution, i.e. a subshell, so anything it sets here would be invisible
  # outside. Raw per-config output is kept so the run record can carry the
  # METRIC and coverage lines -- they used to print to stdout and vanish, which
  # is why collect_results.py's METRIC columns were structurally always empty.
  for cfg in "${CFGS[@]}"; do
    t=$((t+1))
    local tag out v
    tag="$(echo "$cfg" | tr ' =' '__')"
    if [ "$SIM" = "icarus" ]; then
      local pargs=""
      for kv in $cfg; do pargs="$pargs -P${TB_MOD}.${kv%%=*}=${kv##*=}"; done
      rm -f "/tmp/cand_${tag}.vvp"
      cerr="$(iverilog -g2012 -o "/tmp/cand_${tag}.vvp" $pargs ${EXTRA[@]+"${EXTRA[@]}"} "$TB" "$cand" 2>&1)"
      if [ -f "/tmp/cand_${tag}.vvp" ]; then out="$(timeout 600 vvp "/tmp/cand_${tag}.vvp" 2>&1)"
      else out="COMPILE_ERROR"; CERR="$(echo "$cerr" | grep -viE "warning" | grep -m1 . | cut -c1-90)"; fi
    else
      local gargs="" d="obj_cand_${tag}"
      for kv in $cfg; do gargs="$gargs -G$kv"; done
      rm -rf "$d"
      cerr="$(verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique \
        --top-module "$TB_MOD" $gargs ${EXTRA[@]+"${EXTRA[@]}"} "$TB" "$cand" -o sim --Mdir "$d" 2>&1)"
      if [ -x "$d/sim" ]; then out="$(timeout 600 "./$d/sim" 2>&1)"
      else out="COMPILE_ERROR"; CERR="$(echo "$cerr" | grep -m1 "%Error" | sed "s|.*/candidates/|candidates/|" | cut -c1-90)"; fi
      rm -rf "$d"
    fi
    printf '%s\n' "$out" > "$RAW_DIR/${tag}.txt"
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

# --- SYNTHESIS-FRONTEND GATE -------------------------------------------------
# Simulation uses Verilator; ORFS synthesis uses slang. They DISAGREE about what
# is legal, so a submission can pass every config here and then fail synthesis on
# a parse error -- which surfaces much later as an unexplained mid-pipeline
# failure. A Gemini d_nw01 answer hit exactly this: illegal for both, but it also
# carried an anonymous-struct type parameter Verilator accepts and slang rejects.
#
# Gates at the same point as simulation, and reports SLANG rather than COMPILE so
# a frontend-portability failure is never confused with a correctness failure.
#
# VALIDATED against known inputs before being trusted (standing rule 3):
#   d_nw01 chat.sv    exit 0,   0 errors  -> pass
#   d_nw01 gemini.sv  exit 133, 13 errors -> fail
#   d_ca04 chat.sv    exit 0,   0 errors  -> pass
# Detection keys on the EXIT STATUS, not on grepping stdout: yosys aborts on a
# slang error, and with stdout piped it is block-buffered and the message is lost
# -- an early version of this check reported "0 errors" for the known-bad file.
SLANG_IMG="openroad/orfs"
slang_check() {   # $1 = design file (host path); echoes a reason on failure
  local f="$1" pkgs="" rel
  for pk in "$TASK_DIR"/spec/*_pkg.sv; do
    [ -f "$pk" ] || continue
    pkgs="$pkgs /work/${pk#$REPO/}"
  done
  case "$f" in "$REPO"/*) rel="/work/${f#$REPO/}" ;; *) rel="/hostfile/$(basename "$f")" ;; esac
  local mnt=""
  [ "${rel#/hostfile/}" != "$rel" ] && mnt="-v $(dirname "$f"):/hostfile"
  docker run --rm --platform linux/amd64 -v "$REPO:/work" $mnt "$SLANG_IMG" \
    bash -c "yosys -p 'read_slang --top $DUT_MOD$pkgs $rel' >/tmp/slang.log 2>&1; \
             rc=\$?; if [ \$rc -ne 0 ]; then \
               n=\$(grep -cE ': error:' /tmp/slang.log); \
               first=\$(grep -m1 -E ': error:' /tmp/slang.log | sed 's|.*/||'); \
               echo \"\$n error(s); first: \${first:-exit \$rc}\"; fi" 2>/dev/null
}
if [ "$SLANG" = "1" ] && ! docker info >/dev/null 2>&1; then
  echo "note: docker unavailable -- SKIPPING the slang synthesis-frontend gate."
  echo "      a candidate that passes here may still fail ORFS on a parse error."
  SLANG=0
fi

cd "$TASK_DIR" || exit 2     # gotcha 1: vectors resolve relative to here

ALLPASS=0; NFAIL=0; NREJECT=0; NSLANG=0
printf '%-26s %-9s %s\n' "candidate" "configs" "first failure"
echo "--------------------------------------------------------------------------------"
for cand in "${CANDS[@]}"; do
  name="$(basename "$cand")"

  # TRANSPORT DAMAGE -- a SETUP problem, checked before anything else. A damaged
  # paste produces the same symptom as a design that does not build, and
  # attributing that to the model is wrong. d_dsp02/gemini.sv arrived with one
  # injected fragment ("sum_is_zero = 1 me;") and was reported as a slang
  # failure, i.e. as a result about the submission.
  if ! python3 "$REPO/scripts/check_transport.py" "$cand" >/tmp/tp_$$.log 2>&1; then
    printf '%-26s %-9s %s\n' "$name" "DAMAGED" \
      "$(sed -n '4p' /tmp/tp_$$.log | sed 's/^ *//')"
    sed -n '5,6p' /tmp/tp_$$.log | sed 's/^/    /'
    rm -f /tmp/tp_$$.log
    NREJECT=$((NREJECT+1)); continue
  fi
  rm -f /tmp/tp_$$.log
  # cheap pre-checks: these are failed attempts, not harness breakage
  # LEAK TOKENS -- the full set, ported from runner/extract.py::_LEAKS. Until
  # now the domains path enforced ONE of the six (TEST_RESULT), so every
  # candidate solicited was checked for verdict forgery and nothing else: a
  # submission reaching into the testbench hierarchy ("<dut>_tb.signal") or
  # including a shared reference model would have passed. All candidates
  # solicited before this change were re-scanned retroactively against the full
  # set and are clean, so no earlier result is affected.
  #
  # -F: these are literal strings, not patterns. "_tb." contains a regex
  # metacharacter and would otherwise match "_tbX".
  leak=""
  for tok in "TEST_RESULT" "_tb." "_tb " "golden_mem" "mem_stub" "reference_solutions"; do
    if LC_ALL=C grep -qF -- "$tok" "$cand"; then leak="$tok"; break; fi
  done
  if [ -n "$leak" ]; then
    case "$leak" in
      TEST_RESULT) why="forges a TEST_RESULT line" ;;
      *)           why="references harness-private '$leak' -- the submission may not see the testbench" ;;
    esac
    printf '%-26s %-9s %s\n' "$name" "REJECT" "$why"
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

  # Synthesis frontend, before spending a full config sweep on something that
  # cannot be synthesised. Runs on $runfile, i.e. AFTER the U+00A0 normalisation
  # above -- an earlier version ran on the raw paste and rejected a candidate
  # that passes 16/16 and synthesises cleanly, because slang reports the
  # non-breaking spaces as "UTF-8 sequence in source text". ppa_candidate.sh
  # normalises before synthesising too, so this now sees exactly what ORFS will.
  # THE EXEMPTION, and its terms. slang_check elaborates `spec/*_pkg.sv + ONE
  # file`. That closure is complete for a SUBMISSION -- a candidate is required
  # to be self-contained -- and it is not complete for anything the TASK ships,
  # whose dependencies live in the task's own orfs/config.mk. Files under ref/
  # were exempted for that reason; mutants/ and conformant/ have the identical
  # property and were not, so d_ca01's mutants returned "7 error(s) ...
  # 'bsg_cache_non...'" and its conformant perturbations 8 -- a missing vendored
  # dependency reported as if the task's own files were malformed. Each was
  # found separately, which is the tell that the exemption was enumerating
  # directories instead of stating the property.
  #
  # Running those with --no-slang instead is F22's shape: a result produced
  # OUTSIDE the scored path, printed in the same units as results produced
  # inside it. So the exemption is extended rather than worked around, on the
  # same terms:
  #
  #   EXEMPT if the file is shipped BY THE TASK (ref/, mutants/, conformant/)
  #   -- its dependency closure is the task's and slang is not given it here.
  #   NOT EXEMPT if the file is a SUBMISSION -- self-containment is part of
  #   what is being measured, and ORFS synthesis uses slang, so a design
  #   slang rejects could never have produced a PPA number.
  case "$cand" in
    "$TASK_DIR"/ref/*|"$TASK_DIR"/mutants/*|"$TASK_DIR"/conformant/*) ;;
    *) if [ "$SLANG" = "1" ]; then
         slang_why="$(slang_check "$runfile")"
         if [ -n "$slang_why" ]; then
           printf '%-26s %-9s %s\n' "$name" "SLANG" "$(echo "$slang_why" | cut -c1-72)"
           # A FRONTEND REJECTION IS A RESULT, AND IT MUST LEAVE A RECORD.
           # This used to `continue` straight past the record writer, so a
           # submission that failed here produced NOTHING in runs/ -- and a
           # report counting submissions from records therefore dropped
           # exactly the ones that did worst. Six of this project's
           # submissions were invisible that way, and the funnel read 8
           # correct of 10 for a true 8 of 18.
           #
           # NO configs_total IS WRITTEN AT ALL, deliberately. Key/values
           # arrive as STRINGS, so `configs_total=0` would store "0", and "0"
           # is truthy in Python -- a reader testing `if rec.get(...)` would
           # count this build failure as a compiled submission. Absence is the
           # only encoding that cannot be misread, and it is also the true one:
           # nothing was configured because nothing ran. `all_passed` likewise
           # stays absent and renders as NO VERDICT, not as a failure of the
           # DESIGN. What failed is the build, and that is what the record says.
           tt="$(python3 "$REPO/scripts/task_text_hash.py" "$TASK_DIR" 2>/dev/null | head -1)"
           python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$cand" sim \
             "$(basename "$cand" .sv)" \
             "task_text_hash=$tt" \
             "build_status=slang_rejected" \
             "build_error=$(echo "$slang_why" | tr '\n' ' ' | cut -c1-200)" >/dev/null || \
             echo "  RECORD NOT WRITTEN for $name (slang reject)" >&2
           NSLANG=$((NSLANG+1)); continue
         fi
       fi ;;
  esac

  RAW_DIR="$(mktemp -d)"
  res="$(run_one "$runfile")"
  pt="${res%%|*}"; ff="${res#*|}"
  set -- $pt; p=$1; t=$2
  printf '%-26s %-9s %s\n' "$name" "$p/$t" "$ff"
  # Immutable run record. Collection reads ONLY these, never the live ORFS
  # directory -- see scripts/write_run_record.py for why.
  # The label goes in the LABEL position and the raw directory is passed as the
  # only positional. Both were wrong here: task_text_hash sat where the label
  # belongs, and -- worse -- the second line was missing its continuation
  # backslash, so the command ended after argv[4] and the third line ran as a
  # SEPARATE command ("chat: command not found"), swallowed by 2>/dev/null.
  # Every design sim record written after that carried no verdict.
  #
  # stderr is NO LONGER discarded on this call. It hid a shell syntax error for
  # a day and turned a failed command into a well-formed empty record. The
  # inner task_text_hash.py keeps its own 2>/dev/null -- that one is a nested
  # substitution whose diagnostics would otherwise land inside the label.
  tt="$(python3 "$REPO/scripts/task_text_hash.py" "$TASK_DIR" 2>/dev/null | head -1)"
  if ! rec="$(python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$cand" sim \
        "$(basename "$cand" .sv)" \
        "task_text_hash=$tt" \
        "$RAW_DIR")"; then
    echo "  RECORD NOT WRITTEN for $name -- see the error above. The run happened;" >&2
    echo "  nothing downstream can cite it until this is fixed." >&2
  fi
  [ -n "$rec" ] && echo "  record: $rec"
  rm -rf "$RAW_DIR"
  if [ "$p" -eq "$t" ]; then ALLPASS=$((ALLPASS+1)); else NFAIL=$((NFAIL+1)); fi
done

echo "--------------------------------------------------------------------------------"
NRUN=$((ALLPASS + NFAIL))
if [ "$NSLANG" -gt 0 ]; then
  echo "--------------------------------------------------------------------------------"
  echo "$NSLANG candidate(s) FAILED THE SYNTHESIS FRONTEND (slang) and were not simulated."
  echo "USUALLY this is a result about the submission -- the design does not build, so"
  echo "it has no correctness, capability or PPA numbers."
  echo "BUT CHECK FIRST: a damaged paste produces the identical symptom, and"
  echo "attributing that to the model is wrong. d_dsp02/gemini.sv failed here for"
  echo "exactly that reason -- one injected fragment, 'sum_is_zero = 1 me;'."
  echo "    python3 scripts/check_transport.py <candidate file>"
  echo "Verilator and slang disagree about what is legal; ORFS synthesis uses slang, so a"
  echo "design rejected here could never have produced a PPA number. Re-run with"
  echo "--no-slang to simulate anyway and see how far it gets."
fi
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
[ "$ALLPASS" -eq "$NRUN" ] && [ "$NREJECT" -eq 0 ] && [ "$NSLANG" -eq 0 ] && exit 0 || exit 1
