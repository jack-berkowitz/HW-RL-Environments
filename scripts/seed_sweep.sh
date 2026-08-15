#!/bin/bash
# seed_sweep.sh -- run one testbench across many random seeds.
#
# *** BROKEN BY THE TIER REMOVAL. NEEDS REPOINTING AT domains/. ***
# It resolved its testbench and DUT from testbenches/TierTwo/,
# candidates/TierTwo/ and reference_solutions/TierTwo/, all of which were
# deleted. Repointing is not a path substitution: a domains/ reference needs the
# per-task ref/sim_flags_verilator.txt search paths that sim_candidate.sh
# assembles, which this script has no equivalent of.
#
# It REFUSES rather than searching paths that no longer exist -- a sweep that
# silently finds nothing is worse than one that stops.
#
# THE METHODOLOGY IT ENCODES IS STILL LIVE and is why this file is kept rather
# than deleted: see testbenches/conventions/NOTES.md, "single-seed validation is
# not validation". The ncache reference passed the default seed and FAILED 4 of
# 6 others on a real bug. Nothing currently sweeps seeds for d_ca04 or d_nw01.
#
#   ./scripts/seed_sweep.sh ncache            # golden, 10 seeds
#   ./scripts/seed_sweep.sh ncache 30         # golden, 30 seeds
#   ./scripts/seed_sweep.sh ncache 10 candidate
#
# WHY THIS EXISTS
#   The Tier-2 testbenches drive constrained-random traffic via $urandom. A
#   single run explores ONE trajectory through that space. Validating a design
#   or a harness against one seed proves far less than it looks like it does:
#   the ncache reference passed the default seed and failed 4 of 6 other seeds,
#   on a real bug (a port-B request accepted with no MSHR left to allocate).
#   That bug reached a candidate and only surfaced on a different machine,
#   whose Verilator happened to pick a different seed.
#
#   Treat "passes one seed" as unvalidated. Sweep before believing a PASS.
#
# Verilator seeds its RNG per run via +verilator+seed+<n>, so the same binary
# gives a different traffic pattern per seed with no rebuild.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

MODULE="${1:?usage: seed_sweep.sh <module> [n_seeds] [golden|candidate]}"
NSEEDS="${2:-10}"
WHICH="${3:-golden}"

echo "REFUSED: seed_sweep.sh has not been repointed at the domains/ layout." >&2
echo "  It resolved from testbenches/TierTwo/ and reference_solutions/TierTwo/," >&2
echo "  which were removed. Repointing needs the per-task sim_flags mechanism" >&2
echo "  that sim_candidate.sh uses; see the header. Nothing was run." >&2
exit 2

TB="${REPO_DIR}/testbenches/TierTwo/${MODULE}_tb.sv"
if [ "${WHICH}" = "candidate" ]; then
  DUT="${REPO_DIR}/candidates/TierTwo/${MODULE}.sv"
else
  # the coherence reference is mesi_top.sv; every other module matches its name
  DUT="${REPO_DIR}/reference_solutions/TierTwo/${MODULE}.sv"
  [ -f "${DUT}" ] || DUT="${REPO_DIR}/reference_solutions/TierTwo/${MODULE}_top.sv"
fi

[ -f "${TB}" ]  || { echo "no testbench: ${TB}" >&2; exit 1; }
[ -f "${DUT}" ] || { echo "no DUT: ${DUT}" >&2; exit 1; }

TOP="$(basename "${TB}" .sv)"
OBJ="$(mktemp -d)"
trap 'rm -rf "${OBJ}"' EXIT

echo "sweeping ${MODULE} (${WHICH}) over ${NSEEDS} seeds"
verilator --binary --timing -j 0 -Wno-fatal \
  --x-assign unique --x-initial unique \
  --top-module "${TOP}" -Mdir "${OBJ}/obj" -o sim \
  -I"${REPO_DIR}/testbenches/common" "${TB}" "${DUT}" > "${OBJ}/build.log" 2>&1 || {
    echo "BUILD FAILED"; grep -m5 '%Error' "${OBJ}/build.log"; exit 1; }

fails=0
for i in $(seq 1 "${NSEEDS}"); do
  seed=$(( i * 7919 ))            # spread out rather than 1,2,3,...
  out="$("${OBJ}/obj/sim" +verilator+seed+${seed} 2>&1 || true)"
  verdict="$(echo "${out}" | grep -m1 '^TEST_RESULT' || echo 'TEST_RESULT: (none)')"
  case "${verdict}" in
    *PASS*) printf "  seed %-8s PASS\n" "${seed}" ;;
    *)      fails=$((fails+1))
            printf "  seed %-8s %s\n" "${seed}" "$(echo "${verdict}" | cut -c1-100)"
            echo "${out}" | grep -m1 '^\[FAIL\]' | sed 's/^/           /' || true ;;
  esac
done

echo
if [ "${fails}" -eq 0 ]; then
  echo "RESULT: ${MODULE} (${WHICH}) passed all ${NSEEDS} seeds"
else
  echo "RESULT: ${MODULE} (${WHICH}) FAILED ${fails} of ${NSEEDS} seeds"
  exit 1
fi
