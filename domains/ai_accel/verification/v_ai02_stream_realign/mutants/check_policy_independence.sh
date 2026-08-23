#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The ten defects of mutants.sv are re-derived on the policy-divergent
# implementation (mutants/policy/), which makes every beat wait for the sink and
# drives a fixed pattern while pop_valid_o is low -- the opposite choice on both
# named latitude clauses. A verdict that differs from the same defect on the
# golden base means that mutant is perturbing latitude rather than contract.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/ai_accel/verification/v_ai02_stream_realign
D=$T/dut
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fails=0
BASE=("$D/hwpe_stream_package.sv" "$D/hwpe_stream_interfaces.sv" "$D/tc_clk.sv"
      "$D/hwpe_stream_source_realign.sv")
for f in "$D"/hwpe_stream_source_realign_m*.sv; do BASE+=("$f"); done

run_one() {   # $1 label, $2 expected, $3.. files
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module stream_realign_tb \
       -o run --Mdir "$W/obj" "$@" "$T/tb/stream_realign_tb.sv" >"$W/b.log" 2>&1; then
    printf '  %-34s BUILD FAIL\n' "$label"; grep '%Error' "$W/b.log" | head -2
    fails=$((fails+1)); return
  fi
  out=$(timeout 200 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$expect" ]; then printf '  %-34s %-4s as expected\n' "$label" "$got"
  else printf '  %-34s %-4s BUT EXPECTED %s\n' "$label" "$got" "$expect"; fails=$((fails+1)); fi
}

echo "reference testbench vs the GOLDEN base and its ten defects"
run_one "golden (clean)" PASS "${BASE[@]}" "$D/stream_realign.sv"
for M in $(grep -oE "^module sr_m[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re
src=open('$T/mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $M')][0]
open('$W/$M.sv','w').write(b.replace('module $M','module stream_realign',1))"
  run_one "$M" FAIL "${BASE[@]}" "$W/$M.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same ten defects"
sed 's/module sr_c1_first_beat_waits/module stream_realign/' \
    "$T/conformant/conformant_perturbations.sv" > "$W/clean_policy.sv"
run_one "policy base (clean)" PASS "$W/clean_policy.sv"
for f in "$T"/mutants/policy/*.sv; do
  run_one "$(basename "$f" .sv)" FAIL "$f"
done

echo
if [ "$fails" -eq 0 ]; then
  echo "OK: every defect is caught on BOTH bases, and both clean implementations"
  echo "    pass. No mutant is killed by the latitude choice."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
