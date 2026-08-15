#!/bin/bash
# build_and_score.sh -- run the full correctness + PPA pipeline for one
# candidate module in a single call.
#
# Usage:
#   ./scripts/build_and_score.sh <module.sv | module_name>
#
# Examples:
#   ./scripts/build_and_score.sh fifo
#   ./scripts/build_and_score.sh candidates/TierOne/fifo.sv
#   ./scripts/build_and_score.sh rob
#
# It also accepts a domains/ TASK ID, which is the layout every catalog-v3 task
# uses:
#
#   ./scripts/build_and_score.sh d_ca04                       # the reference
#   ./scripts/build_and_score.sh d_ca04 candidates/d_ca04/x.sv  # a candidate
#
# The two layouts are genuinely different -- a domains task has MANY legal
# parameter configurations rather than one, its ORFS config lives beside it
# instead of under orfs_configs/, and its reference may pull in vendored support
# RTL -- so the domains path delegates to the scripts that already model that
# (sim_candidate.sh for stage 1, ppa_candidate.sh for a candidate P&R) instead
# of duplicating the config lists here, where they would drift.
#
# Tier is auto-detected: candidates/ and testbenches/ are each split into
# TierOne/ and TierTwo/, so the script looks in both and uses whichever one
# actually has the module.
#
# Pipeline:
#   1. Simulate the candidate against its testbench with Verilator
#      (--binary mode: builds and runs a standalone executable directly
#      from the SV sources, no hand-written C++ harness needed). For Tier2
#      modules, -I points at testbenches/common/ so `include of the shared
#      reference models (golden memory model, memory-interface stub)
#      resolves the same way it did under Icarus. Aborts here on anything
#      other than "TEST_RESULT: PASS" -- a failing candidate isn't worth
#      spending a P&R run on.
#   2. Run the full ORFS flow via run_orfs_build.sh (synth -> floorplan ->
#      place -> CTS -> route -> report), targeting sky130hd. That script now
#      WIPES the design's results/logs/objects/reports first, so every build is
#      clean and the reported PPA always corresponds to the RTL and config
#      currently on disk. make keys off timestamps and does not rebuild on a
#      changed config.mk/SDC, so incremental builds here silently reported stale
#      numbers. Set NO_WIPE=1 to opt out for a deliberate resume.
#   3. Print PPA numbers via collect_results.py.
#
# Stops at the first failing stage and exits non-zero.
#
# NOTE ON THE MIGRATION FROM ICARUS: this stage previously ran on
# iverilog/vvp. Verilator is 2-state internally (no true X-propagation),
# unlike Icarus. --x-assign unique --x-initial unique below is a partial
# mitigation (uninitialized reads return pseudo-random garbage per run
# rather than a fixed value), not a substitute for real 4-state tracking --
# see testbenches/TierTwo/NOTES.md for the full writeup of that tradeoff and
# the re-validation done against Icarus's prior results before this switch.
#
# Assumes: verilator (>= 5.006, for mature --timing support) on PATH,
# Docker running (for the ORFS stage), and python3 with whatever
# collect_results.py needs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --sim-only runs stage 1 and stops. find_fmax.py uses it to reuse this
# script's Verilator gate once up front, instead of paying for a full P&R run
# just to confirm the RTL still simulates, or duplicating the invocation.
SIM_ONLY=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --sim-only) SIM_ONLY=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

if [ $# -lt 1 ]; then
  echo "Usage: $0 [--sim-only] <module.sv | module_name>" >&2
  exit 1
fi

# ---- normalize the argument to a bare module name ----
# Accepts "fifo", "fifo.sv", "candidates/fifo.sv", or a nested tier path
# like "candidates/TierOne/fifo.sv" -- basename strips all directory
# components regardless of depth, so this needs no change for the tier split.
RAW="$1"
MODULE="$(basename "${RAW}")"
MODULE="${MODULE%.sv}"

# ---- domains/ task id? then take that path and stop --------------------------
N_MATCH="$(ls -d "${REPO_DIR}"/domains/*/design/"${MODULE}"_* 2>/dev/null | wc -l | tr -d ' ')"
if [ "${N_MATCH}" -gt 1 ]; then
  echo "REJECTED: module id '${MODULE}' matches ${N_MATCH} task directories:" >&2
  ls -d "${REPO_DIR}"/domains/*/design/"${MODULE}"_* | sed 's|.*/|  |' >&2
  echo "Name the task unambiguously. Nothing was run." >&2
  exit 2
fi
TASK_DIR="$(ls -d "${REPO_DIR}"/domains/*/design/"${MODULE}"_* 2>/dev/null | head -1 || true)"
if [ -n "${TASK_DIR}" ]; then
  TASK_NAME="$(basename "${TASK_DIR}")"
  DUT="${2:-}"
  if [ -z "${DUT}" ]; then
    N_REF="$(ls "${TASK_DIR}"/ref/*_ref.sv 2>/dev/null | wc -l | tr -d ' ')"
    if [ "${N_REF}" -gt 1 ]; then
      echo "REJECTED: ${TASK_DIR} has ${N_REF} ref/*_ref.sv files; naming one is required." >&2
      ls "${TASK_DIR}"/ref/*_ref.sv | sed 's|.*/|  |' >&2
      exit 2
    fi
    DUT="$(ls "${TASK_DIR}"/ref/*_ref.sv 2>/dev/null | head -1 || true)"
    WHAT="reference"
    if [ -z "${DUT}" ]; then
      echo "ERROR: ${TASK_NAME} has no ref/*_ref.sv and no candidate was given." >&2
      echo "  Class B tasks whose oracle is a Python model have no RTL reference;" >&2
      echo "  pass a candidate explicitly:  $0 ${MODULE} candidates/${MODULE}/<file>.sv" >&2
      exit 1
    fi
  else
    WHAT="candidate $(basename "${DUT}")"
  fi

  echo "=== [1/3] Simulating ${TASK_NAME} (${WHAT}) over every legal config ==="
  "${SCRIPT_DIR}/sim_candidate.sh" "${MODULE}" "${DUT}"
  SIM_RC=$?
  if [ "${SIM_RC}" -ne 0 ]; then
    echo ""
    echo "=== ABORTED: ${WHAT} did not pass every config -- skipping ORFS ==="
    exit "${SIM_RC}"
  fi

  if [ "${SIM_ONLY}" = "1" ]; then
    echo ""
    echo "=== --sim-only: ${TASK_NAME} passed; stopping before ORFS ==="
    exit 0
  fi

  if [ ! -f "${TASK_DIR}/orfs/config.mk" ]; then
    echo ""
    echo "=== [2/3] SKIPPED: ${TASK_NAME} has no orfs/ harness ==="
    echo "  PPA is deferred for tasks without an external RTL golden model."
    echo "  See DESIGN_TASKS_NO_GOLDEN_RTL.md. Correctness above still stands."
    exit 0
  fi

  echo ""
  echo "=== [2/3] Running full ORFS build for ${TASK_NAME} (this is the slow part) ==="
  if [ -n "${2:-}" ]; then
    # A candidate needs a generated config pointing at IT, not at the reference.
    "${SCRIPT_DIR}/ppa_candidate.sh" "${MODULE}" "${DUT}"
    NICK="${MODULE}_cand_$(basename "${DUT}" .sv)"
  else
    "${SCRIPT_DIR}/run_orfs_build.sh" "/work/${TASK_DIR#${REPO_DIR}/}/orfs/config.mk"
    NICK="${TASK_NAME}"
  fi

  echo ""
  echo "=== [3/3] Collecting PPA results for ${NICK} ==="
  python3 "${SCRIPT_DIR}/collect_results.py" "${NICK}" || {
    echo "(collect_results.py could not summarise ${NICK}; the raw reports are under" >&2
    echo " \$ORFS_FLOW_DIR/reports/sky130hd/${NICK}/base/)" >&2; }
  exit 0
fi

# ---- locate candidate + testbench, auto-detecting TierOne vs TierTwo ----
CANDIDATE=""
TESTBENCH=""
TIER=""

for T in TierOne TierTwo; do
  c="${REPO_DIR}/candidates/${T}/${MODULE}.sv"
  t="${REPO_DIR}/testbenches/${T}/${MODULE}_tb.sv"
  if [ -f "$c" ] && [ -f "$t" ]; then
    if [ -n "${TIER}" ]; then
      echo "ERROR: module '${MODULE}' found in both TierOne and TierTwo -- ambiguous" >&2
      exit 1
    fi
    CANDIDATE="$c"
    TESTBENCH="$t"
    TIER="$T"
  elif [ -f "$c" ] && [ ! -f "$t" ]; then
    echo "ERROR: candidate exists at ${c} but no matching testbench at ${t}" >&2
    exit 1
  elif [ ! -f "$c" ] && [ -f "$t" ]; then
    echo "ERROR: testbench exists at ${t} but no matching candidate at ${c}" >&2
    exit 1
  fi
done

if [ -z "${TIER}" ]; then
  echo "ERROR: '${MODULE}' matched neither layout (derived from argument '${RAW}')." >&2
  echo "  Not found under candidates/{TierOne,TierTwo}/ as a tier module," >&2
  echo "  and not found under domains/*/design/ as a task id." >&2
  echo "  Known task ids: $(ls -d "${REPO_DIR}"/domains/*/design/*/ 2>/dev/null | xargs -n1 basename 2>/dev/null | grep -oE '^[a-z]+_[a-z0-9]+' | sort -u | tr '\n' ' ')" >&2
  exit 1
fi

echo "Found '${MODULE}' in ${TIER}"

CONFIG="${REPO_DIR}/orfs_configs/sky130hd/${TIER}/${MODULE}/config.mk"
if [ ! -f "${CONFIG}" ]; then
  echo "ERROR: expected ORFS config not found: ${CONFIG}" >&2
  if [ "${TIER}" = "TierTwo" ]; then
    echo "  (Tier2 modules don't have a PPA/ORFS harness yet as of this" >&2
    echo "   milestone -- expected until that work starts, not a bug here.)" >&2
  fi
  exit 1
fi

echo "=== [1/3] Simulating ${MODULE} (verilator, ${TIER}) ==="
SIM_DIR="$(mktemp -d)"
trap 'rm -rf "${SIM_DIR}"' EXIT

# TB_TOP matches your <module>_tb naming convention exactly -- passed
# explicitly rather than relying on Verilator's top-module auto-detection,
# same reasoning as pinning down the -I ordering issue earlier: cheap
# insurance against another multi-round CLI debugging cycle.
TB_TOP="$(basename "${TESTBENCH}" .sv)"

VERILATOR_FLAGS=(
  "--binary" "--timing" "-j" "0"
  "-Wno-fatal"                # candidate RTL style warnings shouldn't block a build
  "--x-assign" "unique" "--x-initial" "unique"   # partial 2-state mitigation, see NOTES.md
)

if [ "${TIER}" = "TierTwo" ]; then
  COMMON_DIR="${REPO_DIR}/testbenches/common"
  if [ -d "${COMMON_DIR}" ]; then
    VERILATOR_FLAGS+=("-I${COMMON_DIR}")
  fi
fi

verilator "${VERILATOR_FLAGS[@]}" --top-module "${TB_TOP}" \
  -Mdir "${SIM_DIR}/obj_dir" -o sim \
  "${TESTBENCH}" "${CANDIDATE}"

SIM_OUTPUT="$("${SIM_DIR}/obj_dir/sim")"
echo "${SIM_OUTPUT}"

# persist so collect_results.py can pull METRIC: lines later, regardless
# of pass/fail
mkdir -p "${REPO_DIR}/sim_logs/${TIER}"
echo "${SIM_OUTPUT}" > "${REPO_DIR}/sim_logs/${TIER}/${MODULE}.log"

if ! echo "${SIM_OUTPUT}" | grep -q "^TEST_RESULT: PASS$"; then
  echo ""
  echo "=== ABORTED: ${MODULE} did not pass its testbench -- skipping ORFS build ==="
  exit 1
fi

if [ "${SIM_ONLY}" = "1" ]; then
  echo ""
  echo "=== --sim-only: ${MODULE} passed its testbench; stopping before ORFS ==="
  exit 0
fi

echo ""
echo "=== [2/3] Running full ORFS build for ${MODULE} (this is the slow part) ==="
"${SCRIPT_DIR}/run_orfs_build.sh" "/work/orfs_configs/sky130hd/${TIER}/${MODULE}/config.mk"

echo ""
echo "=== [3/3] Collecting PPA results for ${MODULE} ==="
python3 "${SCRIPT_DIR}/collect_results.py" "${MODULE}"