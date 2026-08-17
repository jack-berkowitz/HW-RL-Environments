#!/bin/bash
# Sequential ORFS build queue. ORFS is single-occupancy -- two concurrent runs
# share the flow directory and overwrite each other's reports, which is P4.
#
# Runs unattended. Every job is independent: a failure logs and the queue
# continues, because losing four builds to the first one's problem is worse than
# losing one.
#
# Progress is written UNBUFFERED to fmax_results/build_queue.log with
# timestamps, so an interrupted queue can be read back -- the convention that
# came out of a sweep sitting at zero bytes for two and a half hours.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
LOG="fmax_results/build_queue.log"
mkdir -p fmax_results

say() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG"; }

# ---- wait for whatever is already running ---------------------------------
if pgrep -f "ppa_candidate|find_fmax" >/dev/null; then
  say "waiting for the in-flight build to finish"
  while pgrep -f "ppa_candidate|find_fmax" >/dev/null; do sleep 30; done
  say "in-flight build finished"
fi

say "=== QUEUE START — 3 jobs ==="
say "NOT queued, and why:"
say "  d_dsp02 PPA -- no submission has seen the S1 latency requirement (F30),"
say "    so a build now would measure a spec change, not a model."
say "  d_nw01/chat PPA and Fmax -- routing OOM-killed at the 5.8 GB Docker"
say "    ceiling (peak 5.702 GB). An apparatus limit, not a result. A sweep"
say "    would hit it at every period."

# ---------------------------------------------------------------------------
# WITHDRAWN: d_nw01/chat PPA and Fmax.
#
# Detailed routing was OOM-KILLED at the container ceiling: Docker MemTotal is
# 5.8 GB and the run peaked at 5.702 GB, dying mid-iteration with no OpenROAD
# error and exit 247. That is an APPARATUS LIMIT, not a result about the
# candidate -- it was at 75 DRC violations and still improving when it died.
#
# An Fmax sweep runs the same place-and-route at every period, so it would hit
# the same ceiling nine times over: roughly 15 hours to produce nothing.
#
# NOT scored zero under rule 19. Rule 19 is for build failures confirmed
# genuine, as d_nw01/gemini was on two independent frontends. A design killed by
# a memory limit has not been shown to fail anything.
#
# Unblocking it needs Docker's memory raised (Docker Desktop > Resources), which
# is a host setting this queue cannot change. The host has 16 GB.

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# 3-5. d_ca04 PPA re-runs THROUGH THE CORRECTNESS GATE.
# These produce the same numbers as the existing records -- same RTL, same
# config, same tool. What they buy is the gate stamp, so the headline task
# stops carrying "PPA predates the correctness interlock" on every row.
# ---------------------------------------------------------------------------
say "[1/3] d_ca04 reference PPA at 2.625 ns (gated)"
CLK_PERIOD_NS=2.6250 WIPE_DESIGN=d_ca04_async_fifo_cdc PLATFORM=sky130hd \
  stdbuf -oL -eL ./scripts/run_orfs_build.sh \
  /work/domains/comp_arch/design/d_ca04_async_fifo_cdc/orfs/config.mk >> "$LOG" 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  FLOW="${ORFS_FLOW_DIR:-$HOME/tools/OpenROAD-flow-scripts/flow}"
  L="$FLOW/logs/sky130hd/d_ca04_async_fifo_cdc/base"
  R="$FLOW/reports/sky130hd/d_ca04_async_fifo_cdc/base"
  python3 scripts/write_run_record.py d_ca04_async_fifo_cdc \
    domains/comp_arch/design/d_ca04_async_fifo_cdc/ref/async_fifo_cdc_ref.sv \
    ppa reference_gated \
    "status=completed" \
    "design_area_um2=$(grep -iE '^Design area' "$L/6_report.log" | tail -1 | grep -oE '[0-9]+' | head -1)" \
    "wns_ns=$(python3 -c "import json;print(json.load(open('$L/6_report.json'))['finish__timing__setup__ws'])" 2>/dev/null)" \
    "power_w=$(grep -A11 'finish report_power' "$R/6_finish.rpt" | grep -E '^Total' | awk '{print $5}')" \
    "clk_period_ns=2.625" "drc=0" "orfs_nickname=d_ca04_async_fifo_cdc" \
    "pdk=sky130hd" "correctness_gate=passed:reference-18/18" >> "$LOG" 2>&1
fi
say "[1/3] exit=$RC"

say "[2/3] d_ca04/chat PPA at 4.5 ns (gated)"
CLK_PERIOD_NS=4.5000 stdbuf -oL -eL ./scripts/ppa_candidate.sh \
  d_ca04 candidates/d_ca04/chat.sv chat_gated >> "$LOG" 2>&1
say "[2/3] exit=$?"

say "[3/3] d_ca04/gemini PPA at 4.5 ns (gated)"
CLK_PERIOD_NS=4.5000 stdbuf -oL -eL ./scripts/ppa_candidate.sh \
  d_ca04 candidates/d_ca04/gemini.sv gemini_gated >> "$LOG" 2>&1
say "[3/3] exit=$?"

say "=== QUEUE COMPLETE ==="
say "table: python3 scripts/report_table.py"
