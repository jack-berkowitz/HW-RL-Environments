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

# --- RESOLVE THE SIMULATOR EXPLICITLY, AND REFUSE AN UNKNOWN ONE -------------
# `verilator` was taken from PATH and nothing checked which one it was, so the
# same repo on the same machine passed or failed by shell environment. Measured
# on 2026-08-26, both from this host:
#
#   Verilator 5.032 (Debian, /usr/bin/verilator)  d_dsp02 reference 0/1 COMPILE
#                                                 %Error-BLKANDNBLK at
#                                                 refs/cvfpu/src/fpnew_fma.sv:111
#   Verilator 5.051 (oss-cad-suite)               d_dsp02 reference 1/1 PASS
#
# 5.032 CANNOT COMPILE THE VENDORED cvfpu SOURCES AT ALL. cvfpu drives its
# pipeline arrays with a continuous `assign` to element [0] and non-blocking
# assignments to the rest inside always_ff; 5.032 calls that BLKANDNBLK and
# stops. Every task reading refs/cvfpu or refs/redmule is affected: d_ai01,
# d_dsp02, d_dsp03, v_dsp02.
#
# The floor is 5.046 because that is the LOWEST version measured to work here,
# not because 5.045 is known bad -- nobody has measured below it. Override
# with VERILATOR_MIN if you have measured a lower one, or SIM_VERILATOR_EXE to name
# a binary directly.
#
# LOWERED FROM 5.051 TO 5.046 on 2026-08-26, on a measurement, not a guess. The
# paragraph above invites exactly this evidence and AGENT-DESIGN supplied the
# prompt for it by reporting d_ai04 refused at 5.046. Measured on this host:
# d_ai01's tb/audit/probe_l3_latency_tb.sv built and ran the FULL cvfpu closure --
# 4 files from refs/cvfpu/src, plus redmule, hci, hwpe-stream and tech_cells_generic
# -- at rc=0 under Verilator 5.046, at both scored heights, with ZERO BLKANDNBLK.
# The hazard this floor exists for does not reproduce at 5.046. 5.032 is still
# known bad; 5.033..5.045 remain unmeasured.
#
# STILL OVER-BROAD, KNOWINGLY. This is a GLOBAL version floor guarding a hazard
# that is specific to refs/cvfpu and refs/redmule. The affected tasks are named
# four paragraphs up -- d_ai01, d_dsp02, d_dsp03, v_dsp02 -- and d_ai04 is not
# among them: its closure is one file with no vendored modules, so it was being
# refused for a hazard that cannot apply to it. Lowering the number unblocks that
# case without fixing its shape. The narrower fix is a per-task closure check.
#
# THE OVERRIDE IS **SIM_VERILATOR_EXE**, NOT VERILATOR_BIN. VERILATOR_BIN is read
# by Verilator's own Perl wrapper (/usr/bin/verilator:170) to choose which binary
# to exec, so setting it to the wrapper's own path makes it exec ITSELF and the
# process hangs in infinite recursion with no output. Names reserved by the
# wrapper and unusable here: VERILATOR_BIN, VERILATOR_ROOT, VERILATOR_GDB,
# VERILATOR_VALGRIND, VERILATOR_TEST_FLAGS.
VERILATOR_MIN_EXPLICIT="${VERILATOR_MIN+yes}"
VERILATOR_MIN="${VERILATOR_MIN:-5.046}"
if [ -n "${SIM_VERILATOR_EXE:-}" ]; then
  :
elif [ -x "$HOME/tools/oss-cad-suite/bin/verilator" ]; then
  SIM_VERILATOR_EXE="$HOME/tools/oss-cad-suite/bin/verilator"
else
  SIM_VERILATOR_EXE="$(command -v verilator 2>/dev/null || true)"
fi
VERILATOR_VERSION=""
if [ -n "${SIM_VERILATOR_EXE:-}" ] && [ -x "$SIM_VERILATOR_EXE" ]; then
  VERILATOR_VERSION="$("$SIM_VERILATOR_EXE" --version 2>/dev/null | head -1)"
fi
_vnum () { echo "$1" | grep -oE '[0-9]+\.[0-9]+' | head -1; }
if [ -z "$VERILATOR_VERSION" ]; then
  echo "REFUSED: no verilator found. Set SIM_VERILATOR_EXE." >&2; exit 2
fi
# THE VERSION FLOOR NO LONGER REFUSES HERE, AND THAT IS THE POINT. This block
# runs before the task is resolved (the case at "$TASK_NAME" is ~100 lines below),
# so at this moment the script does not know WHICH task was asked for, let alone
# whether that task reads the sources the hazard lives in. A gate that cannot see
# what it is guarding can only guard everything -- which is why d_ai04, whose
# closure is one file with no vendored modules, was refused for a cvfpu defect
# that could not reach it.
#
# The real question is asked twice, later and narrowly, at "TOOLCHAIN CAPABILITY":
#   1. does THIS build's closure actually read refs/cvfpu or refs/redmule?
#   2. if so, can THIS binary compile it -- asked of the compiler, not of a number?
#
# VERILATOR_MIN is kept as an explicit hard floor for anyone who wants one, but it
# is no longer consulted unless it was set deliberately in the environment.
if [ -n "${VERILATOR_MIN_EXPLICIT:-}" ]; then
  _have="$(_vnum "$VERILATOR_VERSION")"; _need="$(_vnum "$VERILATOR_MIN")"
  if [ "$(printf '%s\n%s\n' "$_need" "$_have" | sort -V | head -1)" != "$_need" ]; then
    echo "REFUSED: $SIM_VERILATOR_EXE is $VERILATOR_VERSION; VERILATOR_MIN=$VERILATOR_MIN was set explicitly." >&2
    exit 2
  fi
fi
export PATH="$(dirname "$SIM_VERILATOR_EXE"):$PATH"
export VERILATOR_VERSION

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

# --- resolve the DUT module name --------------------------------------------
# Primary source is the spec's own `module` declaration, which is authoritative.
#
# THE FALLBACK EXISTS BECAUSE ONE SPEC SHIPPED NO CODE -- PAST TENSE, AND THE
# FALLBACK STAYS. d_ai01's spec/fp16_gemm_array_iface.sv was 492 lines of which
# every one was a comment: the ports were described in a table rather than
# declared. The grep returned an empty string, TB resolved to `tb/_tb.sv`, and the
# runner refused -- correctly, but the effect was that d_ai01 had NEVER been
# runnable through the scored path and had zero sim records while carrying seven
# controls, a reference result and a HEIGHT discrimination result, all from ad-hoc
# runs. See F88.
#
# THAT SPEC NOW DECLARES ITS INTERFACE (64e3da6) and this fallback no longer fires
# for d_ai01. The mechanism is kept because the defect it catches is a property of
# specs in general rather than of that one task -- but the example above is now
# history, and a comment in the PRESENT TENSE about a file that has since changed
# is the same shape as the config.mk line that stated the invariant it existed to
# protect and stated it wrongly.
#
# The fallback derives the module from the task directory, which is named
# <id>_<module> by convention. It DOES NOT SILENTLY SUBSTITUTE: the source is
# printed, because a spec that declares no module is a defect in the spec and a
# fallback that hides it would convert a loud failure into a quiet one -- which
# is the whole subject of F87 and rule 36.
DUT_MOD="$(grep -m1 '^module' "$TASK_DIR"/spec/*_iface.sv 2>/dev/null | sed 's/^module \([A-Za-z0-9_]*\).*/\1/')"
DUT_MOD_SRC="spec"
if [ -z "$DUT_MOD" ]; then
  DUT_MOD="$(basename "$TASK_DIR" | sed -E 's/^[a-z]+_[a-z0-9]+_//')"
  DUT_MOD_SRC="TASK DIRECTORY -- spec/*_iface.sv declares no module"
  echo "note: DUT module '$DUT_MOD' derived from the $DUT_MOD_SRC." >&2
fi

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
  d_ai01_fp16_gemm_array)
      # TWO configs, matching `configs:` in task.yaml exactly: HEIGHT 4 and 8 at
      # WIDTH 8. HEIGHT is the parameterised axis because it changes the
      # OBSERVABLE SCHEDULE -- chain latency D*(H-1)+2 and the per-stage operand
      # skew -- while WIDTH is pure replication (spec P1). T3 REQUIRES a
      # submission to hold at BOTH, so running only the scored geometry would
      # score a clause the task explicitly declines to rest on.
      CFGS=("+HH=4" "+HH=8") ;;
  d_ca05_miss_handler_arb)
      # EXACTLY ONE config. NR_PORTS is a parameter so arbitration is written
      # against a count rather than unrolled, but spec P2 scores only 4: it is
      # the only setting measured against the anchor, and an unmeasured setting
      # is not a scored one. The cache geometry is NOT parameterised -- the task
      # package fixes it as concrete numbers so a submission never has to
      # reconstruct a configuration to get the widths right.
      #
      # If NR_PORTS is ever scored at a second value, this list must grow with it
      # or the sweep silently narrows -- the defect the *) branch refuses.
      CFGS=("") ;;
  d_ai04_sdp_requant)
      # EXACTLY ONE config, BY CONSTRUCTION rather than by omission -- the
      # distinction the *) branch below exists to enforce. sdp_requant declares
      # NO PARAMETERS AT ALL: spec P1 pins four lanes and the 16b/32b lane
      # widths, and every other axis is a runtime INPUT -- cfg_precision,
      # cfg_offset, cfg_scale, cfg_truncate, cfg_bypass, cfg_nan_to_zero -- so
      # it is swept by the stimulus rather than by elaboration.
      #
      # The coverage that would be configs elsewhere is in the vectors: 44
      # anchor-measured words carrying the contract, plus 800 swept words across
      # both modes, both signs, every binary16 subnormal boundary and truncate
      # values to 47. If a parameter is ever added here, this list must grow with
      # it or the sweep silently narrows.
      CFGS=("") ;;
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
  d_ca03_sv39_mmu)
      # EXACTLY ONE config, BY CONSTRUCTION and not by omission. task.yaml's
      # scored_configuration says the task does not parameterise geometry, and
      # the reason is load-bearing rather than incidental: TRANSLATION STORAGE is
      # NORMATIVE (spec P2), pinned at InstrTlbEntries 16 / DataTlbEntries 16 /
      # UseSharedTlb 0 per rule 25 and F69. It is pinned because correctness never
      # depends on TLB capacity -- the walk resolves every miss and A9 requires the
      # two paths to agree -- so if capacity were free the dominant strategy would
      # be ZERO ENTRIES: walk everything, satisfy every functional clause, take the
      # smallest area. Sweeping capacity here would rank submissions by who read
      # the capacity clause closely rather than by design quality.
      #
      # Coverage that would be configs elsewhere is in the stimulus instead. If a
      # parameter is ever added, this list must grow with it or the sweep silently
      # narrows -- the defect the *) branch refuses.
      CFGS=("") ;;
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
# The TESTBENCH'S OWN DIRECTORY is on the include path too. A tb that splits
# itself across .svh files includes them by bare name -- `include "x_seq.svh"` --
# and the only directory that can resolve that is its own. d_ca03's tb does
# exactly this and could not compile at all: "Cannot find include file:
# 'sv39_mmu_seq.svh'", with the file sitting beside the tb that names it. No
# other task had split its testbench yet, so the house include directory alone
# had always been enough, which is why the gap survived to the eighth task.
if [ "$SIM" = "icarus" ]; then EXTRA=("-I$REPO/testbenches/common" "-I$(dirname "$TB")")
else                          EXTRA=("+incdir+$REPO/testbenches/common" "+incdir+$(dirname "$TB")"); fi
FLAGFILE="$TASK_DIR/ref/sim_flags_${SIM}.txt"
if [ -f "$FLAGFILE" ]; then
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    EXTRA+=("${line//%REPO%/$REPO}")
  done < "$FLAGFILE"
fi

# --- TOOLCHAIN CAPABILITY, CHECKED AGAINST THIS BUILD'S ACTUAL CLOSURE --------
# The two narrow questions the old global version floor could not ask, because it
# ran before the task was known. See the note at VERILATOR_MIN.
#
#   1. does THIS build's closure actually read refs/cvfpu or refs/redmule?
#   2. if so, can THIS binary compile them?
#
# Question 1 is a PROPERTY OF THE BUILD, read out of EXTRA, not a list of task
# names. A hardcoded list would be right today and wrong the first time a task
# gains a vendored dependency, and this repo already carries that mistake in
# several places -- identify-by-enumeration is how d_ai04 got refused for a
# hazard it cannot reach.
#
# WHY A PROBE AND NOT A NUMBER. The floor was 5.051, then 5.046, hand-edited each
# time somebody measured a lower version that worked, while 5.033..5.045 were
# never measured and were refused on no evidence whatsoever. A version string is
# a proxy for "can this toolchain compile this closure"; the compiler answers the
# real question for the cost of one lint, and keeps answering it correctly for
# versions nobody has measured yet.
#
# WHY rc IS NOT THE SIGNAL. Linting cvfpu on a GOOD toolchain exits 1: ASCRANGE
# warnings in fpnew_pkg.sv are fatal by default, measured at 5.046 with 185 lines
# of output and zero BLKANDNBLK. The hazard is BLKANDNBLK specifically, so that
# is what is matched. Do NOT add -Wno-fatal or -Wno-lint here -- they suppress
# the very diagnostic this probe exists to find, and it would then pass on 5.032.
if [ "$SIM" = "verilator" ] \
   && printf '%s\n' ${EXTRA[@]+"${EXTRA[@]}"} | grep -qE 'refs/(cvfpu|redmule)'; then
  _probe_pkg="$REPO/refs/cvfpu/src/fpnew_pkg.sv"
  _probe_src="$REPO/refs/cvfpu/src/fpnew_fma.sv"
  if [ -f "$_probe_pkg" ] && [ -f "$_probe_src" ]; then
    # Cached per (toolchain version, probe-file bytes): one lint per toolchain,
    # not one per run. A changed vendored file re-measures on its own.
    _probe_key="$(printf '%s' "$VERILATOR_VERSION" | tr -c 'A-Za-z0-9.' '_')_$(shasum -a 256 "$_probe_src" 2>/dev/null | cut -c1-16)"
    _probe_cache="${TMPDIR:-/tmp}/hwrl_cvfpu_probe_${_probe_key}"
    if [ -f "$_probe_cache" ]; then
      _probe_bad="$(cat "$_probe_cache")"
    else
      if verilator --lint-only -Wno-style \
           +incdir+"$REPO/refs/cvfpu/src" +incdir+"$REPO/refs/common_cells/include" \
           "$_probe_pkg" "$_probe_src" 2>&1 | grep -q 'BLKANDNBLK'; then
        _probe_bad=1
      else
        _probe_bad=0
      fi
      printf '%s' "$_probe_bad" > "$_probe_cache" 2>/dev/null || true
    fi
    if [ "$_probe_bad" = "1" ]; then
      echo "REFUSED: $SIM_VERILATOR_EXE ($VERILATOR_VERSION) reports BLKANDNBLK on" >&2
      echo "  $_probe_src, and $TASK_NAME's closure reads refs/cvfpu or refs/redmule." >&2
      echo "  It would report a WORKING reference as failing, so a sim result from it" >&2
      echo "  is not a result. Set SIM_VERILATOR_EXE to a binary that compiles it." >&2
      echo "  Probe cached at $_probe_cache -- delete it to re-measure." >&2
      exit 2
    fi
  fi
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
      for kv in $cfg; do
        case "$kv" in
          +*) pargs="$pargs -D${kv#+}" ;;
          *)  pargs="$pargs -P${TB_MOD}.${kv%%=*}=${kv##*=}" ;;
        esac
      done
      rm -f "/tmp/cand_${tag}.vvp"
      cerr="$(iverilog -g2012 -o "/tmp/cand_${tag}.vvp" $pargs ${EXTRA[@]+"${EXTRA[@]}"} "$TB" "$cand" 2>&1)"
      if [ -f "/tmp/cand_${tag}.vvp" ]; then out="$(timeout 600 vvp "/tmp/cand_${tag}.vvp" 2>&1)"
      else out="COMPILE_ERROR"; CERR="$(echo "$cerr" | grep -viE "warning" | grep -m1 . | cut -c1-90)"; fi
    else
      local gargs="" d="obj_cand_${tag}"
      # A token written `+NAME=value` is a DEFINE, not a parameter. Most tasks
      # sweep elaboration parameters, but a testbench whose recorded-vector type
      # is sized by a macro cannot: d_ai01's `rec_t` is `[`VW-1:0][`VH-1:0]`, so
      # the geometry must be fixed BEFORE elaboration and -G arrives too late.
      # Two geometries are two elaborations there, not two parameterisations.
      for kv in $cfg; do
        case "$kv" in
          +*) gargs="$gargs -D${kv#+}" ;;
          *)  gargs="$gargs -G$kv" ;;
        esac
      done
      rm -rf "$d"
      cerr="$(verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique \
        --top-module "$TB_MOD" $gargs ${EXTRA[@]+"${EXTRA[@]}"} "$TB" "$cand" -o sim --Mdir "$d" 2>&1)"
      if [ -x "$d/sim" ]; then out="$(timeout 600 "./$d/sim" 2>&1)"
      else out="COMPILE_ERROR"; CERR="$(echo "$cerr" | grep -m1 "%Error" | sed "s|.*/candidates/|candidates/|" | cut -c1-90)"; fi
      rm -rf "$d"
      # COMPILE WARNINGS WERE DISCARDED ENTIRELY ON A SUCCESSFUL BUILD. cerr was
      # read only inside the failure branch above, so a clean build reported
      # nothing at all about what the compiler said.
      #
      # AGENT-VERIF-A2 lost a day to a combinational loop -- a testbench driving
      # ready from valid, closing ready -> design -> valid -> arm -> ready --
      # that Verilator reported as UNOPTFLAT and that was invisible among ~30
      # warnings about a vendored anchor under -Wno-fatal. On one task it
      # converged and every verdict was right; on another it produced 26 failures
      # across six clause ids, none of them a design defect. Their tell is the
      # durable part: four different one-hot variants gave the IDENTICAL 26
      # failures, and a defect that does not change when you change what provokes
      # it is a settle order rather than a design defect.
      #
      # That was invisible by DILUTION. Here it would have been invisible by
      # TOTAL SUPPRESSION, which is strictly harder to notice -- dilution at
      # least leaves the warning in the output for someone to grep.
      #
      # UNOPTFLAT IS NOT A STYLE WARNING. It reports a combinational loop, and a
      # loop in the testbench means every verdict from that run is a settle-order
      # artefact. It is surfaced by name, separately from the count, and carried
      # into the run record so it survives the terminal.
      NWARN=$(printf '%s\n' "$cerr" | grep -c '^%Warning')
      WCLASSES=$(printf '%s\n' "$cerr" | grep -oE '^%Warning-[A-Z0-9]+' \
                 | sed 's/^%Warning-//' | sort -u | paste -sd, - 2>/dev/null)
      # THE FAMILY, NOT ONE NAME. Keyed on UNOPTFLAT alone this detector did not
      # fire on the very shape it was built for: a testbench driving ready from
      # valid, closing ready -> design -> valid -> ready, which Verilator 5.046
      # reports as ALWCOMBORDER ("Always_comb variable driven after use"). A
      # constructed instance of A2's exact hazard produced zero UNOPTFLAT.
      # UNOPT and UNOPTFLAT cover the shapes it does name that way.
      NLOOP=$(printf '%s\n' "$cerr" | grep -cE 'UNOPTFLAT|ALWCOMBORDER|%Warning-UNOPT\b')
      if [ "${NLOOP:-0}" -gt 0 ]; then
        # TO STDERR, BECAUSE run_one's STDOUT IS ITS RETURN VALUE. This function
        # echoes "<pass> <total>|<firstfail>" and the caller parses it. A summary
        # line printed here lands in that string: with the LOOPSEEN abort removed,
        # the very first LOOP-flagged run put a FILENAME where the caller expected
        # a pass count -- `line 936: [: miss_handler_arb_ref.sv: integer expression
        # expected`. The bug was unreachable for as long as the subshell died two
        # lines below, so fixing that one exposed this one.
        #
        # The caller already reports it, from the file: see the COMBINATIONAL LOOP
        # line built beside comb_loop_configs. This stays as per-config detail for
        # a human watching, on the stream that is not load-bearing.
        printf '%-26s %-9s %s\n' "$name" "LOOP" \
          "combinational-loop warning x$NLOOP in cfg '${cfg:-default}' (UNOPTFLAT/ALWCOMBORDER) -- verdicts from this run are settle-order artefacts, not design results" >&2
        # THE INCREMENT THAT USED TO BE HERE KILLED THE DETECTOR IT FED.
        # `LOOPSEEN=$((LOOPSEEN+1))` sat on this line. LOOPSEEN is unset in this
        # scope -- it is assigned only in the CALLER, from the file below -- and
        # under `set -u` (line 32) an unset name in arithmetic aborts the subshell.
        # Verified on bash 3.2.57: the shape prints, then dies "unbound variable".
        #
        # So run_one exited HERE the moment a loop warning appeared, and the write
        # at `_unoptflat` further down never executed. comb_loop_configs could only
        # ever be 0: measured 52 records carrying the field, all 52 zero. That was
        # never "no combinational loops in the corpus", it was a detector dying
        # before it recorded. Any reading of that field as evidence of absence was
        # reading a constant.
        #
        # The comment immediately below already prescribed the fix: stats go to
        # files beside the subshell for the caller to total. This line was a
        # leftover from before that design. Found by the design session.
      fi
      # run_one executes inside a command substitution -- a SUBSHELL -- so a
      # variable set here is invisible to the caller. The same reason the raw
      # per-config output is written to RAW_DIR rather than returned. Stats go
      # to files beside it, for the caller to total.
      # ZERO WARNINGS FROM A BUILD THAT NEVER HAPPENED IS NOT A CLEAN BUILD.
      # This counted unconditionally, so a submission whose configs all died at
      # elaboration reported `warnings=0` -- byte-identical to a build that
      # compiled and had nothing to say.
      #
      # AGENT-DESIGN-43a92055 nearly published exactly that number while
      # DEMONSTRATING this class of defect: their first two loop builds printed
      # "UNOPTFLAT lines: 0" from builds that had failed with MODMISSING. They
      # caught it by checking whether a `sim` binary existed. The instrument
      # built to demonstrate vacuity committed one on its first two runs, and the
      # same hole was already here.
      #
      # Counts are now attributed to configs that PRODUCED A BINARY, and the
      # configs that did not are reported separately rather than averaged in.
      if [ "$out" = "COMPILE_ERROR" ]; then
        echo 1 >> "$RAW_DIR/_nobuild"
      else
        echo "$NWARN" >> "$RAW_DIR/_warn_counts"
        [ -n "$WCLASSES" ] && echo "$WCLASSES" >> "$RAW_DIR/_warn_classes"
        [ "${NLOOP:-0}" -gt 0 ] && echo 1 >> "$RAW_DIR/_unoptflat"
      fi
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
      # THE REASON IS DROPPED IF THE TESTBENCH SPELLS IT A THIRD WAY. This
      # matched `^[FAIL]` and `COVERAGE HOLE` only. d_ai01 emits
      # `TEST_RESULT: FAIL: <reason>` -- a shape neither pattern sees -- so its
      # candidates reported "+HH=4 -> FAIL:" with nothing after the colon, and
      # the run record's first_failure was an empty string. The testbench names
      # the clause; the runner threw it away, and "why did it fail" could not be
      # answered from any artefact.
      #
      # Third enumeration of message shapes in this file to go stale. Widened to
      # the union, longest-reason-wins rather than first-match, so a tb that
      # prints both a [FAIL] line and a TEST_RESULT reason yields the informative
      # one instead of whichever came first.
      else
        _r="$(echo "$out" | grep -m1 -E '^\[FAIL\]' | sed 's/^\[FAIL\] //')"
        _t="$(echo "$out" | grep -m1 -E 'TEST_RESULT: FAIL: ' | sed 's/.*TEST_RESULT: FAIL: //')"
        _h="$(echo "$out" | grep -m1 -E 'COVERAGE HOLE')"
        _best="$_r"
        [ "${#_t}" -gt "${#_best}" ] && _best="$_t"
        [ -z "$_best" ] && _best="$_h"
        first="$cfg -> $v: $(printf '%s' "$_best" | cut -c1-90)"
      fi
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
  # A NON-ZERO EXIT IS NOT THE SAME AS A REJECTION. slang reporting N>0 errors
  # is a verdict about the design; slang exiting non-zero with ZERO errors is
  # the TOOL failing, and under Rosetta that happens -- d_nw01/claude recorded
  # "0 error(s); first: exit 133", and 133 is 128+5, SIGTRAP, the same
  # emulation fault class that forces LEC_CHECK=0 at clock-tree synthesis.
  # Reporting it as a rejection blames the submission for the host (F56).
  #
  # F56 EXTENDED: SLANG CAN EMIT N>0 ERRORS THAT ARE ALL THE TOOL FAILING.
  # Counting errors is not enough, because the tool reports its own crashes as
  # diagnostics against the file. Both of these exit 133, measured:
  #
  #   d_ai01/gemini   7 errors, ALL SEVEN "internal error: evaluation does not
  #                   resolve to a constant" -> the HOST. Verilator accepts the
  #                   same bytes and runs it to a measured verdict.
  #   d_ca03/gemini  10 errors, ZERO "internal error" -- "declaration must come
  #                   before all statements", "cannot refer to automatic
  #                   variable from static initializer" -> a GENUINE rejection,
  #                   and Verilator rejects the same construct at the same line.
  #
  # SO THE EXIT CODE IS NOT THE DISCRIMINATOR. A rule keyed on 133 would have
  # discarded a correct d_ca03 verdict. The error TEXT is: an error the tool
  # emits about ITSELF is not a statement about the design.
  #
  # Errors are partitioned rather than counted. All internal -> TOOLFAIL. Any
  # real diagnostic present -> a rejection even alongside internal ones, since
  # one genuine syntax error is a genuine rejection whatever else crashed.
  #
  # If slang's phrasing ever moves, the durable form of this test is the one the
  # runner already performs moments later: a rejection that no independent
  # frontend corroborates deserves TOOLFAIL rather than a verdict.
  docker run --rm --platform linux/amd64 -v "$REPO:/work" $mnt "$SLANG_IMG" \
    bash -c "yosys -p 'read_slang --top $DUT_MOD$pkgs $rel' >/tmp/slang.log 2>&1; \
             rc=\$?; if [ \$rc -ne 0 ]; then \
               n=\$(grep -cE ': error:' /tmp/slang.log); \
               ni=\$(grep -cE ': error: internal error' /tmp/slang.log); \
               first=\$(grep -m1 -E ': error:' /tmp/slang.log | sed 's|.*/||'); \
               freal=\$(grep -E ': error:' /tmp/slang.log | grep -v ': error: internal error' | head -1 | sed 's|.*/||'); \
               if [ \"\$n\" -eq 0 ]; then echo \"TOOLFAIL exit \$rc\"; \
               elif [ \"\$ni\" -eq \"\$n\" ]; then echo \"TOOLFAIL exit \$rc -- all \$n diagnostic(s) are slang internal errors, not statements about the design; first: \$first\"; \
               else echo \"\$n error(s); first: \$freal\"; fi; fi" 2>/dev/null
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
  # THE SCAN READS CODE, NOT COMMENTARY. This grepped the raw file, so
  # d_nw01/controls/nc_i_overbuffered_r.sv was rejected outright for a COMMENT
  # reading "Grepping tb/axi4_xbar_tb.sv for an occupancy counter finds nothing"
  # -- prose explaining why the control matters, matched as if it were a
  # hierarchical reference. A scanner that cannot tell code from commentary
  # refuses a file for what it SAYS rather than what it DOES.
  #
  # leak_scan.py splits the tokens, because a string literal is safe for one
  # class and IS the attack for the other: $display("TEST_RESULT: PASS") forges
  # a verdict from inside a string, while axi4_xbar_tb.r_count inside a string
  # is inert. A comment-aware rewrite that blanked strings for both would have
  # opened verdict forgery, and this one did until it was tested.
  #
  # A token found only in commentary is REPORTED and not fatal. Silence would
  # teach the reader there was nothing to say.
  LEAKOUT="$(python3 "$REPO/scripts/leak_scan.py" "$cand" 2>/dev/null)"
  LEAKKIND="${LEAKOUT%%	*}"; leak="${LEAKOUT##*	}"
  if [ "$LEAKKIND" = "COMMENT" ]; then
    printf '%-26s %-9s %s\n' "$name" "note" \
      "mentions '$leak' in a comment only -- not a reference, not rejected"
  fi
  if [ "$LEAKKIND" = "CODE" ]; then
    case "$leak" in
      TEST_RESULT) why="forges a TEST_RESULT line" ;;
      *)           why="references harness-private '$leak' -- the submission may not see the testbench" ;;
    esac
    printf '%-26s %-9s %s\n' "$name" "REJECT" "$why"
    # A REFUSAL THAT LEAVES NO TRACE IS INDISTINGUISHABLE FROM A RUN THAT NEVER
    # HAPPENED. This used to `continue` straight past the recorder, so the
    # scored path could reject a file every time and nothing durable said so --
    # exactly what let d_nw01's nc_i control carry "passes both MAX_TRANS
    # configs" from a hand run while the scored path silently refused it.
    tt="$(python3 "$REPO/scripts/task_text_hash.py" "$TASK_DIR" 2>/dev/null | head -1)"
    python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$cand" sim \
      "$(basename "$cand" .sv)" "task_text_hash=$tt" \
      "build_status=rejected_leak_token" \
      "build_error=$why" >/dev/null 2>&1 || true
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
  #   EXEMPT if the file is shipped BY THE TASK -- its dependency closure is
  #   the task's and slang is not given it here.
  #   NOT EXEMPT if the file is a SUBMISSION -- self-containment is part of
  #   what is being measured, and ORFS synthesis uses slang, so a design
  #   slang rejects could never have produced a PPA number.
  #
  # The list below USED to read ref/|mutants/|conformant/, and controls/ was
  # then found separately too -- every nc_* negative control in all eight design
  # tasks was refused with "FAILED THE SYNTHESIS FRONTEND". Three instances found
  # one at a time is the enumeration failing in exactly the way the paragraph
  # above predicted it would. The test is now the property itself: anything
  # inside the task directory is shipped by the task, and a submission never is
  # -- submissions live under candidates/.
  case "$cand" in
    "$TASK_DIR"/*) ;;
    *) if [ "$SLANG" = "1" ]; then
         slang_why="$(slang_check "$runfile")"
         # A TOOL FAILURE IS RETRIED ONCE before being believed. If it
         # persists it is recorded as a TOOL failure and the submission gets
         # NO VERDICT -- it is not reported as failing to build.
         case "$slang_why" in
           TOOLFAIL*) slang_why="$(slang_check "$runfile")" ;;
         esac
         case "$slang_why" in
           TOOLFAIL*)
             printf '%-26s %-9s %s\n' "$name" "TOOLFAIL" "slang did not run: $slang_why"
             tt="$(python3 "$REPO/scripts/task_text_hash.py" "$TASK_DIR" 2>/dev/null | head -1)"
             python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$cand" sim \
               "$(basename "$cand" .sv)" "task_text_hash=$tt" \
               "simulator=$SIM" "simulator_version=$VERILATOR_VERSION" \
               "build_status=slang_tool_error" \
               "build_error=$slang_why -- host/tool failure, NOT a verdict" >/dev/null || true
             NSLANG=$((NSLANG+1)); continue ;;
         esac
         # AUTHORITY TIER: A REJECTION NO INDEPENDENT FRONTEND CORROBORATES IS A
         # TOOL FAILURE, NOT A VERDICT.
         #
         # The text match above is a FAST PATH -- it saves a build when slang
         # names its own crash. It is not the basis of the decision, because it
         # depends on slang's phrasing staying stable. This is the durable form,
         # and it costs almost nothing: verilator --lint-only on the same bytes.
         #
         # THE EXIT CODE CANNOT DO THIS JOB. Both of the measured cases exit 133:
         #   d_ai01/gemini  7 internal errors  -> verilator lint rc=0, 0 errors
         #                                     -> UNCORROBORATED -> TOOLFAIL
         #   d_ca03/gemini 10 real diagnostics -> verilator lint rc=1, 4 errors
         #                                     -> CORROBORATED -> rejection stands
         # A rule keyed on 133 would have discarded d_ca03's correct result.
         if [ -n "$slang_why" ]; then
           if verilator --lint-only -Wno-fatal -Wno-lint -Wno-style "$runfile" \
                >/dev/null 2>&1; then
             slang_why="TOOLFAIL slang rejected this and verilator --lint-only accepts the same bytes; an uncorroborated rejection is not a verdict -- ${slang_why}"
             printf '%-26s %-9s %s\n' "$name" "TOOLFAIL" "$(echo "$slang_why" | cut -c1-72)"
             tt="$(python3 "$REPO/scripts/task_text_hash.py" "$TASK_DIR" 2>/dev/null | head -1)"
             python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$cand" sim \
               "$(basename "$cand" .sv)" "task_text_hash=$tt" \
               "simulator=$SIM" "simulator_version=$VERILATOR_VERSION" \
               "build_status=slang_tool_error" \
               "build_error=$slang_why" >/dev/null || true
             NSLANG=$((NSLANG+1)); continue
           fi
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
             "simulator=$SIM" "simulator_version=$VERILATOR_VERSION" \
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
  # ONE SUMMARY LINE PER SUBMISSION, ALWAYS, SUCCESS OR FAILURE. Printing 83
  # warning lines would be its own kind of suppression; printing a COUNT and the
  # CLASS NAMES makes a NEW class visible without burying the verdict. That is
  # the cheapest form of the fix and it closes most of the gap.
  WARNTOTAL=$(awk '{n+=$1} END{print n+0}' "$RAW_DIR/_warn_counts" 2>/dev/null)
  # THE `cat` IS LOAD-BEARING; DO NOT "SIMPLIFY" IT BACK TO `tr ... < file`.
  # _warn_classes legitimately does not exist when no config emitted a warning
  # class, and a shell INPUT REDIRECT that fails is reported by bash itself,
  # before the command runs -- so the command's own 2>/dev/null never applies and
  # the error is printed anyway. That put
  #   sim_candidate.sh: line NNN: .../_warn_classes: No such file or directory
  # into every sim log of a clean run. The record was always correct (WARNCLASSES
  # ends up empty either way); only the log was alarming. Redirecting cat's
  # stderr works because cat is a command, not a redirect.
  WARNCLASSES="$(cat "$RAW_DIR/_warn_classes" 2>/dev/null | tr ',' '\n' | grep -v '^$' | sort -u | paste -sd, -)"
  LOOPSEEN=$(grep -c . "$RAW_DIR/_unoptflat" 2>/dev/null || echo 0)
  NBUILT=$(grep -c . "$RAW_DIR/_warn_counts" 2>/dev/null || echo 0)
  NNOBUILD=$(grep -c . "$RAW_DIR/_nobuild" 2>/dev/null || echo 0)
  if [ "${NBUILT:-0}" -eq 0 ]; then
    printf '  compile: NO CONFIG BUILT (%s failed) -- no warning count is available; this is not "clean"\n' "${NNOBUILD:-0}"
  else
    printf '  compile: warnings=%s over %s config(s) that built%s%s%s\n' \
      "${WARNTOTAL:-0}" "${NBUILT}" \
      "$([ "${NNOBUILD:-0}" -gt 0 ] && echo ", ${NNOBUILD} did NOT build")" \
      "${WARNCLASSES:+ classes=$WARNCLASSES}" \
      "$([ "${LOOPSEEN:-0}" -gt 0 ] && echo "  *** COMBINATIONAL LOOP warning in ${LOOPSEEN} config(s) ***")"
  fi
  tt="$(python3 "$REPO/scripts/task_text_hash.py" "$TASK_DIR" 2>/dev/null | head -1)"
  if ! rec="$(python3 "$REPO/scripts/write_run_record.py" "$TASK_NAME" "$cand" sim \
        "$(basename "$cand" .sv)" \
        "task_text_hash=$tt" \
        "simulator=$SIM" "simulator_version=$VERILATOR_VERSION" \
        "compile_warnings=${WARNTOTAL:-0}" \
        "compile_warning_classes=${WARNCLASSES:-}" \
        "comb_loop_configs=${LOOPSEEN:-0}" \
        "compile_configs_built=${NBUILT:-0}" \
        "compile_configs_failed=${NNOBUILD:-0}" \
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
