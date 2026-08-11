#!/bin/bash
# Usage: ./scripts/run_orfs_build.sh <design_config_container_path> [make target, default: all]
#
# Two mounts: the OpenROAD-flow-scripts clone goes to its expected container
# path (so platforms/, Makefile and scripts/ all resolve normally) and the
# project repo goes to /work, so design configs can point straight at
# /work/candidates/<module>.sv with no copying or symlinking.
#
# LEC_CHECK=0 is a workaround for this Mac, not a design choice. The
# openroad/orfs image overrides ORFS's own default and turns on the bundled
# kepler-formal equivalence check; that binary dies with SIGILL under
# --platform linux/amd64 (Rosetta), which surfaces as
#   "Error: cts.tcl, 81 child killed: illegal instruction"
# and kills CTS for every design. It is a self-check on OpenROAD's own
# repair_timing transform, so switching it off changes nothing about the
# netlist, the layout or the PPA numbers. Override with LEC_CHECK=1 when
# re-running somewhere the binary is native (e.g. WSL2/x86_64).
# PORTABILITY: ORFS_FLOW_DIR and DOCKER_PLATFORM_ARGS are overridable so the
# same script works on the Mac (Rosetta, needs --platform linux/amd64) and on a
# native x86_64 WSL2 box (where the flag is unnecessary). Export
# DOCKER_PLATFORM_ARGS="" there, and ORFS_FLOW_DIR to wherever the clone lives.
#
# CLK_PERIOD_NS: forwarded into the container when set. It has to reach the
# flow by TWO paths, because ORFS gets the period twice from different places:
#   1. P&R / STA read the SDC, so constraint.sdc picks the value up via
#      $::env(CLK_PERIOD_NS).
#   2. SYNTHESIS does not. scripts/variables.mk derives ABC_CLOCK_PERIOD_IN_PS
#      by running `sed` over the SDC *text*, which cannot evaluate a Tcl
#      conditional -- so without the make-side override below, ABC would keep
#      optimising for whatever literal period is written in the file while P&R
#      was constrained to something else. Passing it on the make command line
#      makes $(origin ABC_CLOCK_PERIOD_IN_PS) "command line", which suppresses
#      that sed entirely.
# Unset -> the SDC default and the sed, i.e. existing behaviour untouched.
#
# UNITS: the variable is named _IN_PS but this ORFS revision's generic
# extraction feeds it the SDC's raw ns number (awk prints $1 with no *1000;
# only the ihp-sg13g2 platform config scales it). We pass ns to match, because
# every PPA number already collected in this repo was produced that way and
# changing it would silently make the Fmax search non-comparable with them.
# Worth revisiting deliberately, but not as a side effect of this script.
#
# WIPE_DESIGN: when set to a design name, that design's results/logs/objects/
# reports are deleted BEFORE the build. This is mandatory whenever the period
# changes: make keys off file timestamps and does not treat a changed constraint
# as a reason to rebuild, so without the wipe the flow silently reuses the
# previous period's results.
set -e
ORFS_FLOW_DIR="${ORFS_FLOW_DIR:-/Users/jackberkowitz/tools/OpenROAD-flow-scripts/flow}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${2:-}"
LEC_CHECK="${LEC_CHECK:-0}"
PLATFORM="${PLATFORM:-sky130hd}"

if [ -z "${DOCKER_PLATFORM_ARGS+x}" ]; then
  DOCKER_PLATFORM_ARGS="--platform linux/amd64"
fi

if [ -n "${WIPE_DESIGN:-}" ]; then
  for d in results logs objects reports; do
    rm -rf "${ORFS_FLOW_DIR}/${d}/${PLATFORM}/${WIPE_DESIGN}"
  done
  echo "wiped ${PLATFORM}/${WIPE_DESIGN} (results, logs, objects, reports)"
fi

DOCKER_ENV_ARGS=()
MAKE_PERIOD_ARG=""
if [ -n "${CLK_PERIOD_NS:-}" ]; then
  DOCKER_ENV_ARGS+=("-e" "CLK_PERIOD_NS=${CLK_PERIOD_NS}")
  MAKE_PERIOD_ARG="ABC_CLOCK_PERIOD_IN_PS=${CLK_PERIOD_NS}"
  echo "constraining to CLK_PERIOD_NS=${CLK_PERIOD_NS} (SDC + synthesis)"
fi

docker run --rm ${DOCKER_PLATFORM_ARGS} \
  -u $(id -u ${USER}):$(id -g ${USER}) \
  "${DOCKER_ENV_ARGS[@]+"${DOCKER_ENV_ARGS[@]}"}" \
  -v "${ORFS_FLOW_DIR}:/OpenROAD-flow-scripts/flow" \
  -v "${REPO_DIR}:/work" \
  openroad/orfs \
  bash -c "source /OpenROAD-flow-scripts/env.sh && cd /OpenROAD-flow-scripts/flow && make LEC_CHECK=${LEC_CHECK} ${MAKE_PERIOD_ARG} DESIGN_CONFIG=$1 $TARGET"
