#!/bin/bash
# Reproduce the d_ca01 step-1 anchor semantic probe.
#
# This is a per-task audit rig, not part of the scored path. It lives here
# rather than in scripts/ deliberately: scripts/ is the shared harness and this
# is evidence for one task's step 1.
#
#   ./run_probe.sh              deterministic evidence run (zeroed power-up)
#   ./run_probe.sh sweep        initialization-mode sweep, 12 seeds
#
# WHY THE DEFAULT PASSES +verilator+rand+reset+0:
# the anchor's tag and stat memories have NO RESET, and the anchor's own
# assertion (bsg_cache_non_blocking_tl_stage.sv:468) requires at least two
# unlocked ways. A random power-up sets lock bits and the anchor refuses to
# operate before initialization can finish. Zeroed power-up is a defined
# initial state; see NOTES.md, "initialization is a contract question".
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../../../../../.." && pwd)"
BSG="$REPO/refs/basejump_stl"
OBJ="${OBJ_DIR:-$HERE/obj_probe}"

mkdir -p "$OBJ"
verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique \
  --top-module anchor_semantic_probe \
  "+incdir+$BSG/bsg_misc" "+incdir+$BSG/bsg_cache" \
  -y "$BSG/bsg_cache" -y "$BSG/bsg_misc" -y "$BSG/bsg_dataflow" -y "$BSG/bsg_mem" \
  "$BSG/bsg_cache/bsg_cache_non_blocking_pkg.sv" \
  "$HERE/anchor_semantic_probe.sv" \
  -o sim --Mdir "$OBJ" > "$OBJ/build.log" 2>&1 || { echo "BUILD FAILED"; grep -m10 '%Error' "$OBJ/build.log"; exit 1; }

if [ "${1:-}" = "sweep" ]; then
  echo "=== initialization-mode sweep ==="
  for m in 0 1; do
    printf "  rand+reset+%s : " "$m"
    "$OBJ/sim" "+verilator+rand+reset+$m" 2>&1 \
      | grep -oE 'PROBE_RESULT: .*|unlocked ways' | head -1
  done
  for s in $(seq 1 12); do
    printf "  random seed=%-3s: " "$s"
    "$OBJ/sim" +verilator+rand+reset+2 "+verilator+seed+$s" 2>&1 \
      | grep -oE 'PROBE_RESULT: .*|unlocked ways' | head -1
  done
else
  "$OBJ/sim" +verilator+rand+reset+0 2>&1 | grep -vE '^## work'
fi
