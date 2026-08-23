# d_ai01 fp16_gemm_array timing constraints.
#
# SINGLE CLOCK. The variable is named `clk_period` because ppa_candidate.sh's ABC
# line greps for it (F24) -- the name matching is convention, and breaking it
# silently unconstrains ABC rather than failing.
#
# THIS DESIGN IS PIPELINED, unlike d_dsp02 and d_dsp03. The shim binds
# NumPipeRegs=3 with PipeConfig=DISTRIBUTED, and NumPipeRegs is CONTRACTUAL here
# rather than a spec-minimal convenience: it sets the per-stage delay D=4 that
# spec A3's operand skew is written in terms of. It cannot be reduced to buy
# frequency without changing the contract.
#
# 50 ns is a STARTING CONSTRAINT, not a measured Fmax, and it is DERIVED FROM
# MEASUREMENT rather than guessed. Synthesis to sky130hd (yosys `synth -flatten`,
# dfflibmap, abc) followed by OpenSTA at two periods:
#
#     period 20 ns:  data arrival 39.385   data required 19.689
#     period 40 ns:  data arrival 43.385   data required 39.689
#
# The arrival times differ by exactly 4.000 ns, which is the change in the input
# delay (0.2 * 20 -> 0.2 * 40). So these are not two different critical paths but
# ONE path seen through two I/O budgets, and backing the budget out gives the
# same logic delay from both:
#
#     20 ns:  39.385 - 0.2*20 = 35.385 ns
#     40 ns:  43.385 - 0.2*40 = 35.385 ns
#
# The required times differ by exactly the period, giving required = period -
# 0.311 (clock uncertainty plus library setup). The path therefore closes when
#
#     0.2*period + 35.385  <=  period - 0.311
#     0.8*period           >=  35.696
#     period               >=  44.62 ns
#
# 50 ns leaves +4.30 ns of slack at synthesis for place-and-route to spend.
#
# WHY THE PATH IS THIS LONG. It is an input-to-register path, not a stage-to-stage
# one: a lone redmule_ce measures 15.672 ns end to end, and the array is 35.385.
# The difference is the operand broadcast. w_i fans out to every one of the
# WIDTH*HEIGHT = 64 computing elements and x_i to a whole row each, unbuffered at
# the synthesis stage, so the boundary paths carry the fanout of the entire array
# before they reach the first register. That is a property of a broadcast array
# and is what this task is about.
#
# Tier-B pins a fixed period rather than sweeping, and THE FINAL PIN IS AGENT 1's
# -- override with CLK_PERIOD_NS rather than editing this file, which is how
# d_dsp02 came to be measured at 20.25 against a config.mk that says 10.

current_design fp16_gemm_array

set clk_period 50.0
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }

create_clock -name core_clock -period $clk_period [get_ports clk_i]

set_clock_latency 0.290 [get_clocks core_clock]
set_clock_uncertainty 0.100 [get_clocks core_clock]

# I/O budget: 20 % of the period at each boundary, matching the other tasks so
# the numbers are comparable in shape even though the designs are not.
set clk_io_pct 0.2

# `all_inputs -no_clocks`, NOT `remove_from_collection`: the latter is a Synopsys
# collection command neither the synthesis-stage SDC reader nor the OpenSTA in
# openroad/orfs:latest implements. Confirmed here, not inherited -- the first run
# of the measurement above died with `invalid command name
# "remove_from_collection"` on exactly that line.
set non_clock_inputs [all_inputs -no_clocks]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock core_clock $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock core_clock [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $non_clock_inputs
set_load 0.05 [all_outputs]
