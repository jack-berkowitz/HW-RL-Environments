#!/usr/bin/env bash
# Rule 16 witness harness: the first clause failure the reference reports against
# each mutant. Scoring support, never shipped.
#
# RULE 24 -- both halves, and it REFUSES rather than warns:
#   NEGATIVE control: the unmodified golden must produce NO clause failure
#     through this exact build-and-grep pipeline. Catches a runner that reports
#     a failure unconditionally.
#   POSITIVE control: every mutant must produce one. Catches the two faults
#     these runners have actually had -- a rename that silently matched nothing,
#     and a grep that did not match the testbench's failure format. Both turned
#     a real failure into silence.
#
# THE GOLDEN IS RENAMED OUT OF THE WAY. A mutant takes the top module's name and
# delegates to the golden; passing both under one name is a duplicate definition
# and verilator quietly runs the golden for every mutant, reporting ten clean
# sweeps of nothing. FINDINGS F66.
set -u
cd "$(dirname "$0")/.." || exit 1
D=dut
TB=tb/dw_downsizer_spec_tb.sv
OUT="${TMPDIR:-/tmp}/v_ca06_witness"; mkdir -p "$OUT"
OTHER=$(ls $D/*.sv | grep -v "/dw_downsizer.sv$")

build_run() {   # $1 Mdir tag, $2.. sources; echoes the first FAIL line
  local tag="$1"; shift
  rm -rf "$OUT/$tag"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module dw_downsizer_tb \
       -o run --Mdir "$OUT/$tag" +incdir+$D/include "$@" "$TB" > "$OUT/$tag.build" 2>&1; then
    echo "__BUILD_FAIL__"; return
  fi
  timeout 1200 "$OUT/$tag/run" 2>&1 | grep -m1 -E "^\[?FAIL"
  rm -rf "$OUT/$tag"
}

# ---- RULE 24 negative control ------------------------------------------------
neg=$(build_run _control $OTHER "$D/dw_downsizer.sv")
if [ "$neg" = "__BUILD_FAIL__" ]; then
  echo "  RULE24 negative control : FAIL -- control build failed"; exit 2
elif [ -n "$neg" ]; then
  echo "  RULE24 negative control : FAIL -- the golden produced: $neg"
  echo "  RULE24: refusing to report witnesses. The instrument has not"
  echo "          reproduced a known answer, so anything it prints is a number."
  exit 2
else
  echo "  RULE24 negative control : PASS (golden produced no clause failure)"
fi

python3 -c "
import re,sys
src=open('$D/dw_downsizer.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule dw_downsizer\b','module dw_downsizer_golden',src))
" "$OUT/golden_renamed.sv"

n_tot=0; n_fail=0
for MM in $(grep -oE "^module dw_m[0-9]+_[A-Za-z0-9_]+" mutants/mutants.sv | awk '{print $2}'); do
  n_tot=$((n_tot+1))
  python3 -c "
import re
src=open('mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $MM ')][0]
b=re.sub(r'\bdw_downsizer(\s*)#\(', r'dw_downsizer_golden\1#(', b)   # inner FIRST
b=b.replace('module $MM #(', 'module dw_downsizer #(', 1)
open('$OUT/$MM.sv','w').write(b)"
  w=$(build_run "$MM" $OTHER "$OUT/golden_renamed.sv" "$OUT/$MM.sv")
  if [ "$w" = "__BUILD_FAIL__" ]; then echo "  $MM : BUILD FAILED"
  elif [ -z "$w" ]; then echo "  $MM : NO FAILURE OBSERVED -- treat the REFERENCE as suspect"
  else echo "  $MM : $w"; n_fail=$((n_fail+1)); fi
done

echo "  RULE24 positive control : $n_fail of $n_tot mutants produced a clause failure"
if [ "$n_fail" -ne "$n_tot" ]; then
  echo "  RULE24: NOT a clean reproduction -- treat every line above as unlicensed."
  exit 2
fi
