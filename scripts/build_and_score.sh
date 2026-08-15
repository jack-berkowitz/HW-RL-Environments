#!/bin/bash
# build_and_score.sh -- run the full correctness + PPA pipeline for one
# candidate module in a single call.
#
# Usage:
#   ./scripts/build_and_score.sh <module.sv | module_name>
#
# Examples:
#   ./scripts/build_and_score.sh fifo
#   ./scripts/build_and_score.sh d_ca04
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
# Pipeline:
#   1. Simulate the candidate against its testbench with Verilator
#      (--binary mode: builds and runs a standalone executable directly
#      from the SV sources, no hand-written C++ harness needed). -I points at
#      testbenches/common/ so `include of shared headers (the liveness
#      monitor) resolves. Aborts here on anything
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
# see testbenches/conventions/NOTES.md for the full writeup of that tradeoff and
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
# Accepts a task id ("d_ca04") or a path under domains/*/design/.
RAW="$1"
MODULE="$(basename "${RAW}")"
MODULE="${MODULE%.sv}"

# ---- domains/ task id? then take that path and stop --------------------------
N_MATCH="$(ls -d "${REPO_DIR}"/domains/*/design/"${MODULE}"_* 2>/dev/null | wc -l | tr -d ' ' || true)"
N_MATCH="${N_MATCH:-0}"
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
    N_REF="$(ls "${TASK_DIR}"/ref/*_ref.sv 2>/dev/null | wc -l | tr -d ' ' || true)"
    N_REF="${N_REF:-0}"
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

# ---- no tier layout any more --------------------------------------------
# TierOne/TierTwo were removed. Everything now lives under domains/, and the
# domains branch above handles it and exits. Reaching here means the argument
# resolved to nothing, so REFUSE -- do not fall back to a layout that no longer
# exists. (Standing rule: the runner names its artifacts explicitly and refuses
# when they are absent; it never discovers them by pattern.)
echo "ERROR: '${MODULE}' did not resolve to a task (from argument '${RAW}')." >&2
echo "  Expected a task id or path under domains/*/design/." >&2
echo "  Known task ids: $(ls -d "${REPO_DIR}"/domains/*/design/*/ 2>/dev/null | xargs -n1 basename 2>/dev/null | grep -oE '^[a-z]+_[a-z0-9]+' | sort -u | tr '\n' ' ')" >&2
echo "  The TierOne/TierTwo layout was removed; there is no fallback." >&2
exit 1
