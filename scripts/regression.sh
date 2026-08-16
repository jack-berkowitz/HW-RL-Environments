#!/bin/bash
# The regression. Every structural check that guards a claim this project makes.
#
# WHY THIS FILE EXISTS: check_rule_linkage.py and check_ppa_record.py both
# documented themselves as "runs with the regression", and there was no
# regression -- they were referenced in prose and invoked by hand when someone
# remembered. A check nobody is obliged to run is a convention, not a control,
# which is the same sentence F20 ends on about rule 8's tooling.
#
# These are all CHEAP and none needs a simulator or ORFS. Run before committing.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

FAIL=0
run() {
  local name="$1"; shift
  printf '\n=== %s ===\n' "$name"
  if "$@"; then
    printf '    PASS\n'
  else
    printf '    *** FAIL ***\n'
    FAIL=1
  fi
}

# Rule/finding citation graph is complete in both directions (F16).
run "rule <-> finding linkage" python3 scripts/check_rule_linkage.py

# PPA records agree with an independent reading of the same run (F21).
# Skips records whose flow directory has been overwritten; those are reported
# as unverifiable rather than passing.
run "PPA record vs independent reading" python3 scripts/check_ppa_record.py --all

# Collection refuses provisional_ fields and reads only run records (F20).
run "results collection" python3 scripts/collect_results.py

printf '\n================================================================\n'
if [ "$FAIL" -eq 0 ]; then
  printf 'REGRESSION PASSED\n'
else
  printf 'REGRESSION FAILED -- do not commit numbers until this is clean.\n'
fi
exit "$FAIL"
