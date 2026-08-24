# d_ca03 sv39_mmu timing constraints.
#
# SINGLE CLOCK. The variable is named `clk_period` because ppa_candidate.sh's ABC
# line greps for it (F24) -- the name matching is convention, and breaking it
# silently unconstrains ABC rather than failing.
#
# 25 ns is a STARTING CONSTRAINT, not a measured Fmax, and it is DERIVED FROM
# MEASUREMENT rather than guessed. Synthesis to sky130hd followed by OpenSTA at
# two periods:
#
#     period 10 ns:  data arrival 18.852   data required  9.787
#     period 20 ns:  data arrival 20.852   data required 19.787
#
# The arrivals differ by exactly 2.000 ns, which is the change in the input delay
# (0.2*10 -> 0.2*20). So these are not two different critical paths but ONE path
# seen through two I/O budgets, and backing the budget out gives the same logic
# delay from both:
#
#     10 ns:  18.852 - 0.2*10 = 16.852 ns
#     20 ns:  20.852 - 0.2*20 = 16.852 ns
#
# Required is period - 0.213 (clock uncertainty plus library setup), so the path
# closes when
#
#     0.2*period + 16.852  <=  period - 0.213
#     0.8*period           >=  17.065
#     period               >=  21.33 ns
#
# 25 ns leaves +2.94 ns of slack at synthesis for place-and-route to spend.
#
# WHY THE PERIOD MATTERS MORE HERE THAN ON MOST TASKS. Spec L1 scores CYCLES over
# the fixed sequence, and G2 compares area at a PINNED period. A design cannot
# buy frequency by adding pipeline stages, because the extra stages show up on the
# cycle axis. The two axes together are what stop either being gamed: serialising
# work shrinks area and costs cycles; pipelining harder costs area and buys
# nothing, because the period is fixed rather than swept.
#
# Tier-B pins a fixed period rather than sweeping, and THE FINAL PIN IS AGENT 1's
# -- override with CLK_PERIOD_NS rather than editing this file.

current_design sv39_mmu

set clk_period 25.0
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }

create_clock -name core_clock -period $clk_period [get_ports clk_i]

set_clock_latency 0.290 [get_clocks core_clock]
set_clock_uncertainty 0.100 [get_clocks core_clock]

# I/O budget: 20 % of the period at each boundary, matching the other tasks so
# the numbers are comparable in shape even though the designs are not.
set clk_io_pct 0.2

# `all_inputs -no_clocks`, NOT `remove_from_collection`: the latter is a Synopsys
# collection command neither the synthesis-stage SDC reader nor the OpenSTA in
# openroad/orfs:latest implements. Confirmed here, not inherited -- d_ai01's first
# timing run died on exactly that line.
set non_clock_inputs [all_inputs -no_clocks]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock core_clock $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock core_clock [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $non_clock_inputs
set_load 0.05 [all_outputs]
