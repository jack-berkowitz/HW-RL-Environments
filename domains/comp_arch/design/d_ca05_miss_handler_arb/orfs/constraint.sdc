# d_ca05 miss_handler_arb timing constraints.
#
# The variable is named `clk_period` because ppa_candidate.sh's ABC line greps
# for it (F24); breaking the name silently unconstrains ABC rather than failing.
#
# THE 45 ns HERE IS NOT DERIVED FROM MEASUREMENT, AND d_ca03'S 25 ns IS.
# d_ca03's SDC carries a real derivation -- synth plus OpenSTA at two periods,
# the logic delay backed out of both, the closing period solved algebraically.
# Doing that needs the ORFS container and the container is Agent 1's, so this is
# a STARTING CONSTRAINT chosen to be loose enough that the first build completes,
# and nothing more. Any area recorded at 45 ns is NOT comparable to a build at
# the eventual pin.
#
# WHY LOOSER THAN d_ca03's 25 ns: this design carries two AXI adapters, an
# eight-way tag path and a 128-bit line, where d_ca03's critical path is a
# three-level walk. Erring loose costs slack; erring tight costs a failed build.
#
# The SCORED pin is 1.5x the reference's own measured period rounded up to the
# next 0.25 ns, per spec G1 -- NOT this starting constraint. Override with
# CLK_PERIOD_NS rather than editing this file.

current_design miss_handler_arb

set clk_period 45.0
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }

# The port is `clk`, not `clk_i`: the contract's port list does not use the CVA6
# suffix convention its anchor happens to carry.
create_clock -name core_clock -period $clk_period [get_ports clk]

set_clock_latency 0.290 [get_clocks core_clock]
set_clock_uncertainty 0.100 [get_clocks core_clock]

set clk_io_pct 0.2

# `all_inputs -no_clocks`, NOT `remove_from_collection`: the latter is a Synopsys
# collection command neither the synthesis-stage SDC reader nor the OpenSTA in
# openroad/orfs:latest implements. d_ai01's first timing run died on that line.
set non_clock_inputs [all_inputs -no_clocks]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock core_clock $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock core_clock [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $non_clock_inputs
set_load 0.05 [all_outputs]
