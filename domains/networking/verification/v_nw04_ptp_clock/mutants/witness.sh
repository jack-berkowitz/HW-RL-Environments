#!/usr/bin/env bash
# Rule 16 witness harness runner: first observable difference, golden vs mutant.
set -u
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/v_nw04_witness"; mkdir -p "$OUT"
MUTS=$(grep -oE "^module [a-z0-9_]+" mutants/mutants.sv | awk '{print $2}')
for m in $MUTS; do
  verilator --binary --timing -j 4 -Wno-fatal --top-module nonequiv_tb \
    -DMUT_MOD="$m" -o run --Mdir "$OUT/$m" \
    dut/*.sv mutants/mutants.sv mutants/nonequiv_tb.sv > "$OUT/$m.build" 2>&1
  if [ $? -ne 0 ]; then echo "  $m : BUILD FAILED (see $OUT/$m.build)"; continue; fi
  timeout 300 "$OUT/$m/run" 2>&1 | grep "^WITNESS" | sed 's/^WITNESS /  /'
  # A Verilator object directory per mutant is hundreds of megabytes on the
  # larger designs. Keeping ten of them filled this machine's disk mid-run.
  rm -rf "$OUT/$m"
done
