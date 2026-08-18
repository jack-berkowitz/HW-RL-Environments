#!/bin/bash
# Determinism check for d_ca01. Run before any liveness verdict is trusted.
#
# Two builds of the same source, same seed, and the results must be identical.
# The two builds are NOT the same compilation: build B enables an inert observer
# process that reads signals and drives nothing. That matters -- building the
# identical source twice yields byte-identical binaries and the check cannot
# fail. The defect this exists for appeared exactly when two builds differed by
# an added debug process, and nothing else in the harness would have caught it.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK="$(cd "$HERE/../.." && pwd)"
REPO="$(cd "$HERE/../../../../../.." && pwd)"
BSG="$REPO/refs/basejump_stl"
OUT="${OBJ_DIR:-$HERE/obj_det}"
DUT="${1:-$TASK/ref/nonblocking_dcache_ref.sv}"
CFG="${2:--GDATA_W=32 -GSETS=16 -GWAYS=4 -GMAX_MISSES=8 -GSEED=7}"

build_run () {  # $1 = tag, $2 = extra defines
  rm -rf "$OUT/$1"
  verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial 0 \
    --top-module nonblocking_dcache_tb $CFG $2 \
    "+incdir+$REPO/testbenches/common" "+incdir+$BSG/bsg_misc" "+incdir+$BSG/bsg_cache" \
    -y "$BSG/bsg_cache" -y "$BSG/bsg_misc" -y "$BSG/bsg_dataflow" -y "$BSG/bsg_mem" \
    "$BSG/bsg_cache/bsg_cache_non_blocking_pkg.sv" \
    "$TASK/tb/nonblocking_dcache_tb.sv" "$DUT" \
    -o sim --Mdir "$OUT/$1" > "$OUT/$1.build" 2>&1 || { echo "BUILD $1 FAILED"; exit 1; }
  # strip host-timing lines and the observer's own metric, which build A lacks
  "$OUT/$1/sim" 2>&1 | grep -vE '^## work|walltime|Verilator: cpu|\$finish|METRIC: observer' > "$OUT/$1.out"
}

mkdir -p "$OUT"
build_run A ""
build_run B "+define+DETERMINISM_OBSERVER"

if cmp -s "$OUT/A.out" "$OUT/B.out"; then
  echo "DETERMINISM: IDENTICAL  ($(wc -l < "$OUT/A.out") lines)"
  echo "  verdict: $(grep -m1 TEST_RESULT "$OUT/A.out")"
  cmp -s "$OUT/A/sim" "$OUT/B/sim" \
    && echo "  WARNING: the two binaries are byte-identical -- the check could not have failed" \
    || echo "  binaries differ, so the comparison had something to detect"
else
  echo "DETERMINISM: DIFFER -- do not trust any liveness verdict from this harness"
  diff "$OUT/A.out" "$OUT/B.out" | head -20
  exit 1
fi
