#!/usr/bin/env bash
# Rule 16 witness harness runner. For each mutant, drive it and the golden from
# one shared input sequence and report the first cycle at which their observable
# outputs differ. A mutant with NO DIFFERENCE OBSERVED is not a mutant.
set -u
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/v_ca04_witness"; mkdir -p "$OUT"
MUTS=$(grep -oE "^module [a-z0-9_]+" mutants/mutants.sv | awk '{print $2}')
for m in $MUTS; do
  verilator --binary --timing -j 4 -Wno-fatal --top-module nonequiv_tb \
    -DMUT_MOD="$m" +incdir+dut/include -o run --Mdir "$OUT/$m" \
    dut/*.sv mutants/mutants.sv mutants/nonequiv_tb.sv > "$OUT/$m.build" 2>&1
  if [ $? -ne 0 ]; then echo "  $m : BUILD FAILED (see $OUT/$m.build)"; continue; fi
  timeout 300 "$OUT/$m/run" 2>&1 | grep "^WITNESS" | sed 's/^WITNESS /  /'
done
