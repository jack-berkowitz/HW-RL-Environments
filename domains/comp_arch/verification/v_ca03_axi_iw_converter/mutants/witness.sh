#!/usr/bin/env bash
# Rule 21 witness runner. For each mutant, substitute it for the golden -- the
# same rename the harness performs -- run the reference testbench against it,
# and report the FIRST clause failure. That message is the witness: the
# observable difference the contract itself names.
set -u
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/v_ca03_witness"; mkdir -p "$OUT"
TOP=id_width_conv
# BSD sed has no \b, so do the rename in python -- a sed that silently matches
# nothing leaves the golden under its own name and EVERY witness then runs the
# golden, reporting "no failure observed" for a mutant that is caught.
python3 -c "
import re,sys
src=open('dut/${TOP}.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule ${TOP}\b', 'module ${TOP}_golden', src))
" "$OUT/golden_renamed.sv"
OTHER=$(ls dut/*.sv | grep -v "dut/${TOP}.sv$")
MUTS=$(grep -oE "^module iw_m[a-z0-9_]+" mutants/mutants.sv | awk '{print $2}')
for m in $MUTS; do
  python3 - "$m" "$OUT" "$TOP" <<'PY'
import re, sys
mut, out, top = sys.argv[1], sys.argv[2], sys.argv[3]
src = open("mutants/mutants.sv").read()
blocks = [b for b in re.split(r"(?=^module )", src, flags=re.M) if b.startswith("module %s " % mut)]
b = blocks[0]
b = b.replace("module %s " % mut, "module %s " % top, 1)
b = re.sub(r"\b%s(\s*)#\(" % top, r"%s_golden\1#(" % top, b)
# the declaration itself must NOT be renamed back
b = b.replace("module %s_golden " % top, "module %s " % top, 1)
open("%s/%s.sv" % (out, mut), "w").write(b)
PY
  verilator --binary --timing -j 4 -Wno-fatal --top-module ${TOP}_tb -o run --Mdir "$OUT/$m" \
    +incdir+dut/include $OTHER "$OUT/golden_renamed.sv" "$OUT/$m.sv" \
    tb/id_width_conv_spec_tb.sv > "$OUT/$m.build" 2>&1
  if [ $? -ne 0 ]; then echo "  $m : BUILD FAILED (see $OUT/$m.build)"; continue; fi
  w=$(timeout 300 "$OUT/$m/run" 2>&1 | grep -m1 -E "^\[?FAIL")
  if [ -z "$w" ]; then echo "  $m : NO FAILURE OBSERVED -- treat the REFERENCE as suspect"
  else echo "  $m : $w"; fi
  # A Verilator object directory per mutant is hundreds of megabytes on the
  # larger designs. Keeping ten of them filled this machine's disk mid-run.
  rm -rf "$OUT/$m"
done
