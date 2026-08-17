#!/bin/bash
set -uo pipefail
cd /Users/jackberkowitz/Desktop/hw_rl_benchmark
LOG="fmax_results/build_queue.log"
say() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG"; }
while pgrep -f "ppa_candidate|find_fmax" >/dev/null; do sleep 30; done
say "=== QUEUE 2 -- new candidates ==="
say "  NOT queued: d_ca04/kimi (build fail), d_dsp02/deepseek (build fail),"
say "    d_dsp02/gemini (fails correctness at vector 4)."
say "[A] d_ca04/deepseek PPA at 4.5 ns"
CLK_PERIOD_NS=4.5000 stdbuf -oL -eL ./scripts/ppa_candidate.sh \
  d_ca04 candidates/d_ca04/deepseek.sv deepseek_scored >> "$LOG" 2>&1
RCA=$?; say "[A] exit=$RCA"
if [ "$RCA" -eq 0 ]; then
  say "[B] d_ca04/deepseek Fmax sweep (seed 4.5 ns)"
  PYTHONUNBUFFERED=1 stdbuf -oL -eL python3 -u scripts/find_fmax.py \
    --design d_ca04_cand_deepseek_scored --seed-period-ns 4.5 \
    --max-bracket-iterations 4 --resolution-ns 0.5 --max-iterations 9 \
    --skip-sim-check >> "$LOG" 2>&1
  say "[B] exit=$?"
else
  say "[B] SKIPPED -- single PPA did not complete (F31)."
fi
say "=== QUEUE 2 COMPLETE ==="
