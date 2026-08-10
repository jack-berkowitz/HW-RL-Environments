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
# Tier is auto-detected: candidates/ and testbenches/ are each split into
# TierOne/ and TierTwo/, so the script looks in both and uses whichever one
# actually has the module.
#
# Pipeline:
#   1. Simulate the candidate against its testbench with iverilog/vvp
#      (default testbench parameters, no -P overrides). For Tier2 modules,
#      also compiles in the shared reference models under testbenches/common/
#      (golden memory model, memory-interface stub) that those testbenches
#      depend on. Aborts here on anything other than "TEST_RESULT: PASS" --
#      a failing candidate isn't worth spending a P&R run on.
#   2. Run the full ORFS flow via run_orfs_build.sh (synth -> floorplan ->
#      place -> CTS -> route -> report), targeting sky130hd.
#   3. Print PPA numbers via collect_results.py.
#
# Stops at the first failing stage and exits non-zero.
#
# Assumes: iverilog/vvp on PATH, Docker running (for the ORFS stage), and
# python3 with whatever collect_results.py needs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <module.sv | module_name>" >&2
  exit 1
fi

# ---- normalize the argument to a bare module name ----
# Accepts "fifo", "fifo.sv", "candidates/fifo.sv", or a nested tier path
# like "candidates/TierOne/fifo.sv" -- basename strips all directory
# components regardless of depth, so this needs no change for the tier split.
RAW="$1"
MODULE="$(basename "${RAW}")"
MODULE="${MODULE%.sv}"

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
  echo "ERROR: module '${MODULE}' not found under candidates/{TierOne,TierTwo}/ (derived from argument '${RAW}')" >&2
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

echo "=== [1/3] Simulating ${MODULE} (iverilog -g2012, ${TIER}) ==="
SIM_DIR="$(mktemp -d)"
trap 'rm -rf "${SIM_DIR}"' EXIT

IVERILOG_FLAGS=("-g2012")
if [ "${TIER}" = "TierTwo" ]; then
  COMMON_DIR="${REPO_DIR}/testbenches/common"
  if [ -d "${COMMON_DIR}" ]; then
    IVERILOG_FLAGS+=("-I${COMMON_DIR}")
  fi
fi

SIM_SOURCES=("${TESTBENCH}" "${CANDIDATE}")

iverilog "${IVERILOG_FLAGS[@]}" -o "${SIM_DIR}/sim" "${SIM_SOURCES[@]}"

iverilog -g2012 -o "${SIM_DIR}/sim" "${SIM_SOURCES[@]}"
SIM_OUTPUT="$(vvp "${SIM_DIR}/sim")"
echo "${SIM_OUTPUT}"

if ! echo "${SIM_OUTPUT}" | grep -q "^TEST_RESULT: PASS$"; then
  echo ""
  echo "=== ABORTED: ${MODULE} did not pass its testbench -- skipping ORFS build ==="
  exit 1
fi

echo ""
echo "=== [2/3] Running full ORFS build for ${MODULE} (this is the slow part) ==="
"${SCRIPT_DIR}/run_orfs_build.sh" "/work/orfs_configs/sky130hd/${TIER}/${MODULE}/config.mk"

echo ""
echo "=== [3/3] Collecting PPA results for ${MODULE} ==="
python3 "${SCRIPT_DIR}/collect_results.py" "${MODULE}"