#!/bin/bash
# Collect INDEPENDENT Claude Code attempts at a design task, with the model's
# reasoning and tool calls recorded.
#
#   ./scripts/trace_attempts.sh d_dsp03 10 ~/dsp03_traces
#
# Each attempt runs in its own scratch directory OUTSIDE this repo, gets only
# the task's probe/PASTE.md, and is scored afterwards by the normal path.
#
# WHY OUTSIDE THE REPO. `claude -p` without --bare loads CLAUDE.md, hooks, auto
# memory, MCP servers and plugins from the working directory and ~/.claude --
# that is exactly what makes it bill the SUBSCRIPTION rather than an API key.
# Run it in this repo and the model inherits the benchmark's own context and can
# read ref/ with Bash, which is the answer key. A clean directory keeps the
# subscription billing and removes the leak.
#
# WHAT THE MODEL IS NOT GIVEN: the scoring testbench (tb/), the reference (ref/),
# the mutants or the controls. It gets the same PASTE.md a solicited model gets,
# and Verilator. Writing its own testbench is the work.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK="${1:-}"; N="${2:-}"; OUT="${3:-}"
if [ -z "$TASK" ] || [ -z "$N" ] || [ -z "$OUT" ]; then
  echo "usage: $0 <task> <n_attempts> <output_dir>" >&2
  echo "   eg: $0 d_dsp03 10 ~/dsp03_traces" >&2
  exit 2
fi

# ---- preflight. Every one of these is a way the run silently produces nothing.
fail=0
command -v claude >/dev/null   || { echo "MISSING: claude CLI not on PATH"; fail=1; }
command -v verilator >/dev/null|| { echo "MISSING: verilator not on PATH"; fail=1; }
TASKDIR="$(ls -d "$REPO"/domains/*/design/"${TASK}"_* 2>/dev/null | head -1)"
[ -n "$TASKDIR" ] || { echo "MISSING: no task dir for '$TASK'"; fail=1; }
PASTE="$TASKDIR/probe/PASTE.md"
[ -f "$PASTE" ] || { echo "MISSING: $PASTE"; fail=1; }
case "$OUT" in "$REPO"|"$REPO"/*) echo "REFUSING: output dir is inside the repo -- attempts must run outside it"; fail=1;; esac
[ "$fail" = 0 ] || exit 1

DUT="$(grep -m1 '^dut_module:' "$TASKDIR/task.yaml" | awk '{print $2}')"
echo "task     : $TASK  ($(basename "$TASKDIR"))"
echo "module   : $DUT"
echo "prompt   : $PASTE  ($(wc -c < "$PASTE" | tr -d ' ') bytes)"
echo "attempts : $N"
echo "output   : $OUT"
mkdir -p "$OUT"

for i in $(seq -w 1 "$N"); do
  d="$OUT/attempt_$i"
  if [ -e "$d" ]; then echo "[$i] exists, skipping"; continue; fi
  mkdir -p "$d/work"
  cp "$PASTE" "$d/work/TASK.md"
  echo "[$i] running..."
  ( cd "$d/work" && claude -p "$(cat TASK.md)

Write your final answer to a file named submission.sv in this directory. \
Verilator is available if you want to compile or test your work." \
      --output-format stream-json --verbose \
      --allowedTools "Write,Read,Edit,Bash" \
      --permission-mode acceptEdits \
  ) > "$d/trace.jsonl" 2> "$d/stderr.log"
  rc=$?
  echo "$rc" > "$d/exit_code"

  # ---- contamination scan. A trace that reached the repo measures nothing.
  if grep -qiE "hw_rl_benchmark|/ref/|fp_multifmt_fma_ref|_ref\.sv|/tb/|/mutants/" "$d/trace.jsonl" 2>/dev/null; then
    echo "CONTAMINATED" > "$d/STATUS"
    echo "[$i] *** CONTAMINATED -- trace references the benchmark repo, do not use ***"
  else
    echo "clean" > "$d/STATUS"
  fi

  if [ -f "$d/work/submission.sv" ]; then
    cp "$d/work/submission.sv" "$d/submission.sv"
    echo "[$i] rc=$rc  submission.sv $(wc -l < "$d/submission.sv" | tr -d ' ') lines  $(cat "$d/STATUS")"
  else
    echo "[$i] rc=$rc  NO submission.sv produced  $(cat "$d/STATUS")"
  fi
done

echo
echo "=== summary ==="
for d in "$OUT"/attempt_*; do
  [ -d "$d" ] || continue
  n=$(basename "$d")
  th=$(grep -c '"type":"thinking"' "$d/trace.jsonl" 2>/dev/null || echo 0)
  tu=$(grep -c '"type":"tool_use"' "$d/trace.jsonl" 2>/dev/null || echo 0)
  sub=$([ -f "$d/submission.sv" ] && echo yes || echo NO)
  printf "  %-12s thinking_blocks=%-4s tool_calls=%-4s submission=%-4s %s\n" \
         "$n" "$th" "$tu" "$sub" "$(cat "$d/STATUS" 2>/dev/null)"
done
echo
echo "Next: score them with"
echo "  for d in $OUT/attempt_*; do [ -f \"\$d/submission.sv\" ] && \\"
echo "    $REPO/scripts/sim_candidate.sh $TASK \"\$d/submission.sv\"; done"
