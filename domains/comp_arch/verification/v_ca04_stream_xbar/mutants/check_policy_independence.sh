#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The eight defects of mutants.sv are re-derived on the policy-divergent
# implementation (mutants/policy/), which rotates DOWNWARD and REGISTERS its
# outputs -- the opposite choice on both named latitude clauses. A verdict that
# differs from the same defect on the golden base means that mutant is
# perturbing latitude rather than contract.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/comp_arch/verification/v_ca04_stream_xbar
D=$T/dut
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fails=0
BASE=("$D/aa_asserts_off.sv" "$D/cf_math_pkg.sv" "$D/lzc.sv" "$D/rr_arb_tree.sv"
      "$D/spill_register.sv" "$D/spill_register_flushable.sv" "$D/stream_demux.sv"
      "$D/stream_xbar.sv")

run_one() {   # $1 label, $2 expected, $3.. files
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module route_xbar_tb \
       -I"$D/include" -o run --Mdir "$W/obj" "$@" "$T/tb/route_xbar_tb.sv" >"$W/b.log" 2>&1; then
    printf '  %-34s BUILD FAIL\n' "$label"; grep '%Error' "$W/b.log" | head -2
    fails=$((fails+1)); return
  fi
  out=$(timeout 200 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$expect" ]; then printf '  %-34s %-4s as expected\n' "$label" "$got"
  else printf '  %-34s %-4s BUT EXPECTED %s\n' "$label" "$got" "$expect"; fails=$((fails+1)); fi
}

echo "reference testbench vs the GOLDEN base and its eight defects"
run_one "golden (clean)" PASS "${BASE[@]}" "$D/route_xbar.sv"
for M in $(grep -oE "^module xb_m[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re
src=open('$T/mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $M')][0]
open('$W/$M.sv','w').write(b.replace('module $M','module route_xbar',1))"
  run_one "$M" FAIL "${BASE[@]}" "$W/$M.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same eight defects"
sed 's/module xb_c1_registered_down_rotation/module route_xbar/' \
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
