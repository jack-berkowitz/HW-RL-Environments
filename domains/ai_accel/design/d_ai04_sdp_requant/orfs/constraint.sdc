# d_ai04 sdp_requant timing constraints.
#
# SINGLE CLOCK. The variable is named `clk_period` because ppa_candidate.sh's ABC
# line greps for it (F24) -- the name matching is convention, and breaking it
# silently unconstrains ABC rather than failing.
#
# ---------------------------------------------------------------------------
# THE 40 ns HERE IS NOT DERIVED FROM MEASUREMENT, AND d_ca03'S IS.
# ---------------------------------------------------------------------------
# d_ca03's SDC carries a real derivation: synthesis followed by OpenSTA at two
# periods, the two arrivals differing by exactly the change in I/O budget, the
# logic delay backed out identically from both, and the closing period solved
# algebraically. I cannot do that here. Running it needs the ORFS container, and
# the container is Agent 1's -- so this number is a STARTING CONSTRAINT chosen to
# be loose enough that the first build completes, and nothing more.
#
# It is stated this way rather than dressed up because a plausible number in the
# place where a measured one belongs is the failure this repository keeps
# finding. Any area or power recorded at 40 ns is NOT comparable to a build at
# the eventual pinned period, exactly as d_ca03 says of its 25 ns.
#
# WHY 40 AND NOT 25. The scored path is one combinational cone per lane:
#
#     34-bit subtract  ->  34x16 signed multiply  ->  64-bit variable shift
#       ->  rounding increment  ->  int32 saturation compare  ->  output mux
#
# and in parallel with it, the float path's leading-zero count and barrel shift.
# The multiply alone is the largest single element any design task in this
# repository has put in one cycle, and sky130hd is a slow 130 nm library. A
# starting constraint that does not close produces a failed build rather than a
# loose one, so this errs loose deliberately.
#
# WHAT SHOULD REPLACE IT, and it is Agent 1's to run:
#   1. synth + OpenSTA at two periods far apart, e.g. 20 ns and 40 ns;
#   2. back the I/O budget out of each arrival -- if the two logic delays agree,
#      it is one path seen through two budgets rather than two paths;
#   3. solve 0.2*P + logic <= P - uncertainty for the closing period;
#   4. the SCORED pin is then 1.5x the reference's own measured period rounded up
#      to the next 0.25 ns, per spec G1 -- NOT this starting constraint.
#
# Override with CLK_PERIOD_NS rather than editing this file.

current_design sdp_requant

set clk_period 40.0
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }

# The port is `clk`, not `clk_i`. The spec's port list is the contract and it
# does not use the CVA6 suffix convention that d_ca03 inherited from its anchor.
create_clock -name core_clock -period $clk_period [get_ports clk]

set_clock_latency 0.290 [get_clocks core_clock]
set_clock_uncertainty 0.100 [get_clocks core_clock]

# I/O budget: 20 % of the period at each boundary, matching the other tasks so
# the numbers are comparable in shape even though the designs are not.
set clk_io_pct 0.2

# `all_inputs -no_clocks`, NOT `remove_from_collection`: the latter is a Synopsys
# collection command neither the synthesis-stage SDC reader nor the OpenSTA in
# openroad/orfs:latest implements. d_ai01's first timing run died on that line.
set non_clock_inputs [all_inputs -no_clocks]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock core_clock $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock core_clock [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $non_clock_inputs
set_load 0.05 [all_outputs]
