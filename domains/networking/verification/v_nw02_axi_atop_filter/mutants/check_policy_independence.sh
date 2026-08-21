#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The eight defects of mutants.sv are re-derived on top of the policy-divergent
# implementation (mutants/policy/), which makes the opposite legal choice on
# both named latitude clauses. Each is then run against the reference
# testbench. A verdict that differs from the same defect on the golden base
# means that mutant is perturbing latitude rather than contract.
#
# Also runs the clean policy implementation itself, which must PASS.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/networking/verification/v_nw02_axi_atop_filter
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
fails=0

run_one() {  # $1 = label, $2 = dut file, $3 = expected (PASS|FAIL)
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module atop_filter_tb \
       -o run --Mdir "$W/obj" "$2" "$T/tb/atop_filter_tb.sv" >"$W/build.log" 2>&1; then
    printf '  %-28s BUILD FAIL\n' "$1"; grep '%Error' "$W/build.log" | head -2; fails=$((fails+1)); return
  fi
  out=$(timeout 120 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$3" ]; then
    printf '  %-28s %-4s as expected\n' "$1" "$got"
  else
    printf '  %-28s %-4s BUT EXPECTED %s\n' "$1" "$got" "$3"; fails=$((fails+1))
  fi
}

echo "reference testbench vs the policy-divergent base and its eight defects"
sed 's/module af_c1_b_before_r/module atop_filter/' \
    "$T/conformant/conformant_perturbations.sv" > "$W/clean.sv"
run_one "policy base (clean)" "$W/clean.sv" PASS
for f in "$T"/mutants/policy/*.sv; do
  run_one "$(basename "$f" .sv)" "$f" FAIL
done
echo
if [ "$fails" -eq 0 ]; then
  echo "OK: every defect is caught on BOTH bases, so none of them is killed by"
  echo "    the latitude choice. The clean policy implementation still passes."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
