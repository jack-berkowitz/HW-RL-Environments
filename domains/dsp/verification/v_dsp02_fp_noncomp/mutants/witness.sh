#!/usr/bin/env bash
# Rule 21 witness runner. Substitute each mutant for the golden -- the same
# rename the harness performs -- run the reference against it, and report the
# FIRST clause failure. That message is the witness.
set -u
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/v_dsp02_witness"; mkdir -p "$OUT"
TOP=fp_noncomp
python3 -c "
import re,sys
src=open('dut/${TOP}.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule ${TOP}\b', 'module ${TOP}_golden', src))
" "$OUT/golden_renamed.sv"
OTHER=$(ls dut/*.sv | grep -v "dut/${TOP}.sv$")
MUTS=$(grep -oE "^module fn_m[a-z0-9_]+" mutants/mutants.sv | awk '{print $2}')
for m in $MUTS; do
  python3 - "$m" "$OUT" "$TOP" <<'PY'
import re, sys
mut, out, top = sys.argv[1], sys.argv[2], sys.argv[3]
src = open("mutants/mutants.sv").read()
head = src[:src.index("\nmodule fn_")]          # file-scope helper functions
b = [x for x in re.split(r"(?=^module )", src, flags=re.M) if x.startswith("module %s " % mut)][0]
b = b.replace("module %s " % mut, "module %s " % top, 1)
b = re.sub(r"\b%s(\s*)#\(" % top, r"%s_golden\1#(" % top, b)
b = re.sub(r"\b%s(\s+)i_g\b" % top, r"%s_golden\1i_g" % top, b)
b = b.replace("module %s_golden " % top, "module %s " % top, 1)
open("%s/%s.sv" % (out, mut), "w").write(head + "\n" + b)
PY
  verilator --binary --timing -j 4 -Wno-fatal --top-module ${TOP}_tb -o run --Mdir "$OUT/$m" \
    $OTHER "$OUT/golden_renamed.sv" "$OUT/$m.sv" tb/fp_noncomp_spec_tb.sv > "$OUT/$m.build" 2>&1
  if [ $? -ne 0 ]; then echo "  $m : BUILD FAILED (see $OUT/$m.build)"; continue; fi
  w=$(timeout 300 "$OUT/$m/run" 2>&1 | grep -m1 -E "^\[?FAIL")
  if [ -z "$w" ]; then echo "  $m : NO FAILURE OBSERVED -- treat the REFERENCE as suspect"
  else echo "  $m : $w"; fi
done
