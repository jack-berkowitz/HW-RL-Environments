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
set -e
ORFS_FLOW_DIR="/Users/jackberkowitz/tools/OpenROAD-flow-scripts/flow"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${2:-}"
LEC_CHECK="${LEC_CHECK:-0}"
docker run --rm --platform linux/amd64 \
  -u $(id -u ${USER}):$(id -g ${USER}) \
  -v "${ORFS_FLOW_DIR}:/OpenROAD-flow-scripts/flow" \
  -v "${REPO_DIR}:/work" \
  openroad/orfs \
  bash -c "source /OpenROAD-flow-scripts/env.sh && cd /OpenROAD-flow-scripts/flow && make LEC_CHECK=${LEC_CHECK} DESIGN_CONFIG=$1 $TARGET"
