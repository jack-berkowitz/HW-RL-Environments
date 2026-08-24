#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The ten guarded defects of mutants.sv are re-derived on the policy-divergent
# implementation in dut2/ -- an independent design written from the spec, not a
# wrapper around the anchor. A verdict that differs from the same defect on the
# golden base means that mutant is perturbing latitude rather than contract.
#
# HOW. Every mutant here wraps an implementation and reads its guards from the
# PORTS only, so the re-derived defect is the SAME WRAPPER pointed at the other
# design. Restricting guards to contract-level state is what makes that possible.
#
# RULE 24: each "(clean)" line is a CONTROL -- a conforming implementation must
# PASS. A failing control aborts rather than being counted with the defects,
# because a run whose control failed licenses nothing.
#
# THE GOLDEN MUST BE RENAMED OUT OF THE WAY. A mutant takes the top module's
# name and delegates to the golden; passing both under one name is a duplicate
# definition and verilator quietly runs the golden for every mutant, reporting
# ten clean sweeps of nothing. See FINDINGS F66.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/comp_arch/verification/v_ca06_axi_dw_downsizer
D=$T/dut
TB=$T/tb/dw_downsizer_spec_tb.sv
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fails=0
OTHER=$(ls $D/*.sv | grep -v "/dw_downsizer.sv$")

run_one() {   # $1 label, $2 expected, $3.. files
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module dw_downsizer_tb \
       -o run --Mdir "$W/obj" +incdir+$D/include "$@" "$TB" >"$W/b.log" 2>&1; then
    printf '  %-46s BUILD FAIL\n' "$label"; grep '%Error' "$W/b.log" | head -2
    fails=$((fails+1)); return
  fi
  out=$(timeout 1200 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$expect" ]; then printf '  %-46s %-4s as expected\n' "$label" "$got"
  else printf '  %-46s %-4s BUT EXPECTED %s\n' "$label" "$got" "$expect"; fails=$((fails+1)); fi
}
ctl() {  # a failing CONTROL is not a result
  if [ "$fails" -ne "$1" ]; then
    echo "  RULE24: a CLEAN implementation was reported as failing. That is the"
    echo "          control, not a result -- the instrument has not reproduced a"
    echo "          known answer, so no verdict below it is a measurement."
    exit 2
  fi
}

python3 -c "
import re,sys
src=open('$D/dw_downsizer.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule dw_downsizer\b','module dw_downsizer_golden',src))
" "$W/golden_renamed.sv"

echo "RULE 24: each \"(clean)\" line below is a CONTROL -- a conforming"
echo "         implementation must PASS. Each defect line is the positive half."
echo
echo "reference testbench vs the GOLDEN base and its ten defects"
r=$fails; run_one "golden (clean)" PASS $OTHER "$D/dw_downsizer.sv"; ctl "$r"
for MM in $(grep -oE "^module dw_m[0-9]+_[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re,sys
src=open('$T/mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $MM ')][0]
b=re.sub(r'\bdw_downsizer(\s*)#\(', r'dw_downsizer_golden\1#(', b)   # inner FIRST
b=b.replace('module $MM #(', 'module dw_downsizer #(', 1)
open('$W/$MM.sv','w').write(b)"
  run_one "$MM" FAIL $OTHER "$W/golden_renamed.sv" "$W/$MM.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same ten defects"
sed 's/module dw_downsizer_alt/module dw_downsizer/' "$T/dut2/dw_downsizer_alt.sv" > "$W/clean_policy.sv"
r=$fails; run_one "policy base (clean)" PASS $OTHER "$W/clean_policy.sv"; ctl "$r"
for f in "$T"/mutants/policy/*.sv; do
  run_one "$(basename "$f" .sv)" FAIL $OTHER "$T/dut2/dw_downsizer_alt.sv" "$f"
done

echo
if [ "$fails" -eq 0 ]; then
  echo "OK: every defect is caught on BOTH bases, and both clean implementations"
  echo "    pass. No mutant is killed by the latitude choice."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
