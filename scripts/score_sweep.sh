#!/bin/bash
# Score every extracted answer under experiments/openweights/ with the corpus's
# own harnesses: sim_candidate.sh for design, sim_verification.sh for
# verification. Run records land in runs/<task>/ like any other; because the
# submission path is not under candidates/, no published table or chart counts
# them.
#
#   ./scripts/score_sweep.sh            # 4 at a time
#   JOBS=8 ./scripts/score_sweep.sh
#   ALLOW_NO_SLANG=1 ./scripts/score_sweep.sh   # only if you accept unscored design verdicts
#
# Parallel is safe since bc4fc43 (per-run scratch dirs). Resumable: an answer
# whose log already ends in "exit=" is skipped.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 2
OUT="experiments/openweights"; LOGS="$OUT/_logs"; JOBS="${JOBS:-4}"
mkdir -p "$LOGS"
export HWRL_NO_README_REGEN=1     # concurrent record writes must not each rewrite README.md

# THE SLANG GATE NEEDS DOCKER. Without it sim_candidate.sh prints "SKIPPING the
# slang gate" and records a Verilator-only verdict that is byte-identical to a
# gated one. Refuse rather than produce numbers that look scored and are not.
if ! timeout 10 docker info >/dev/null 2>&1; then
  if [ -z "${ALLOW_NO_SLANG:-}" ]; then
    echo "REFUSING: docker is not running, so design verdicts would skip the slang gate." >&2
    echo "Start Docker (or run on the PC), or set ALLOW_NO_SLANG=1 to proceed anyway." >&2
    exit 1
  fi
  echo "WARNING: docker down -- design verdicts are Verilator-only (ALLOW_NO_SLANG set)." >&2
fi
echo "simulator: $(verilator --version 2>/dev/null | head -1)"

list="$(mktemp)"; trap 'rm -f "$list"' EXIT
for sv in "$OUT"/*/*.sv; do
  [ -f "$sv" ] || continue
  log="$LOGS/$(basename "$(dirname "$sv")")__$(basename "$sv" .sv).log"
  grep -q '^exit=' "$log" 2>/dev/null && continue
  echo "$sv"
done > "$list"
n=$(grep -c . "$list" || true)
echo "to score: $n answer(s), $JOBS at a time"
[ "$n" = 0 ] && exit 0

# One answer per invocation. A standalone runner, not an exported function:
# the tool shell here is zsh, where `export -f` silently does nothing.
runner="$(mktemp)"; trap 'rm -f "$list" "$runner"' EXIT
cat > "$runner" <<'EOF'
#!/bin/bash
sv="$1"; logs="$2"
task="$(basename "$(dirname "$sv")")"
log="$logs/${task}__$(basename "$sv" .sv).log"
case "$task" in
  v_*) ./scripts/sim_verification.sh "$task" "$sv" > "$log" 2>&1 ;;
  *)   ./scripts/sim_candidate.sh    "$task" "$sv" > "$log" 2>&1 ;;
esac
echo "exit=$?" >> "$log"
echo "scored $task $(basename "$sv")"
EOF
xargs -P "$JOBS" -I{} bash "$runner" {} "$LOGS" < "$list"

# A batch is only done when every answer has a finished log.
missing=0
while IFS= read -r sv; do
  log="$LOGS/$(basename "$(dirname "$sv")")__$(basename "$sv" .sv).log"
  grep -q '^exit=' "$log" 2>/dev/null || { echo "NO FINISHED LOG: $sv"; missing=$((missing+1)); }
done < "$list"
[ "$missing" = 0 ] && echo "all $n scored" || { echo "*** $missing unfinished ***"; exit 1; }
