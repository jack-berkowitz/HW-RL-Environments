# d_nw03 axis_switch_oq timing constraints.
#
# SINGLE CLOCK. The variable is named `clk_period` because ppa_candidate.sh's
# ABC line is copied verbatim from this task's config.mk and that line greps for
# it (F24) -- the name matching is convention, and breaking it silently
# unconstrains ABC rather than failing.
#
# THIS DESIGN IS SEQUENTIAL, unlike d_dsp02 and d_dsp03. The period here is a
# pipeline stage through the switch's registers, not a whole combinational cone,
# so the number is not comparable to the FMA tasks' without naming the axis
# (rule 17).
#
# 10 ns is a STARTING CONSTRAINT, not a measured Fmax, and it is CHECKED rather
# than assumed. Synthesis at 10 ns reports:
#
#     worst slack max  +5.72       tns max  0.00
#
# so the post-synthesis critical path is about 4.3 ns and the constraint is
# loose here. It is deliberately left loose: place-and-route, clock tree and
# wire delay all eat into that, and a starting constraint that already fails at
# synthesis tells the flow nothing. Recorded so whoever pins the real period has
# the measurement rather than having to rediscover it.
#
# Chosen as 10 rather than d_nw01's 20 because a stream switch's stage is a
# register-to-register hop through an arbiter and a mux, where an AXI crossbar's
# is a full address-decode-and-route path -- and the +5.72 ns confirms it.
#
# Tier-B pins a fixed period rather than sweeping, and the final pin is
# Agent 1's -- override with CLK_PERIOD_NS rather than editing this file, which
# is how d_dsp02's reference came to be measured at 20.25 ns against a config.mk
# that says 10.

current_design axis_switch_oq

set clk_period 10.0
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }

create_clock -name core_clock -period $clk_period [get_ports clk_i]

set_clock_latency 0.290 [get_clocks core_clock]
set_clock_uncertainty 0.100 [get_clocks core_clock]

# I/O budget: 20 % of the period at each boundary, matching the other tasks so
# the numbers are comparable in shape even though the designs are not.
set clk_io_pct 0.2

# `all_inputs -no_clocks`, NOT `remove_from_collection`: the latter is a
# Synopsys collection command the synthesis-stage SDC reader does not implement,
# and the flow dies at 1_synth with `invalid command name`.
set non_clock_inputs [all_inputs -no_clocks]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock core_clock $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock core_clock [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $non_clock_inputs
set_load 0.05 [all_outputs]
