# d_dsp03 fp_multifmt_fma timing constraints.
#
# SINGLE CLOCK. The variable is named `clk_period` because ppa_candidate.sh's
# ABC line is copied verbatim from this task's config.mk and that line greps for
# it (F24) -- the name matching is convention, and breaking it silently
# unconstrains ABC rather than failing.
#
# THIS DESIGN IS COMBINATIONAL AT THE SPEC-MINIMAL BINDING. The reference shim
# binds NumPipeRegs=0, so there are no internal registers: the whole multi-format
# FMA is one combinational cone. Consequences for reading the numbers:
#
#   * Fmax measures the depth of that cone, not a pipeline stage. It will be far
#     lower than a pipelined FMA, and that is the correct answer for the
#     configuration under test rather than a defect.
#   * There is no register retiming to be had, so area should be much less
#     elastic under constraint than a storage-dominated design.
#   * A pipelined binding is legitimate -- L2 leaves latency unconstrained --
#     and would be a DIFFERENT CONFIGURATION, not a better result for the same
#     one. Comparing across the two requires naming the axis (rule 17).
#
# 65 ns is a STARTING CONSTRAINT, not a measured Fmax, and it is DERIVED FROM
# MEASUREMENT rather than guessed. The first version said 20 ns, reasoning from
# d_dsp02 -- the same shape, a combinational cvfpu FMA at NumPipeRegs=0, whose
# reference measured 20.25 ns. That was wrong by 3x.
#
# Synthesis at 20 ns and at 50 ns produced the SAME NETLIST (identical area to
# four decimals) and these slacks:
#
#     20 ns:  worst slack -23.58    50 ns:  worst slack -5.58
#
# Both resolve to the same combinational delay, which is the number that matters:
#
#     slack = (period - out_delay) - (in_delay + logic),  in = out = 0.2*period
#           = 0.6*period - logic
#     20 ns:  0.6*20 - logic = -23.58  ->  logic = 35.58 ns
#     50 ns:  0.6*50 - logic =  -5.58  ->  logic = 35.58 ns
#
# THE I/O BUDGET EATS 40 % OF THE PERIOD, so a purely combinational design needs
# period >= logic / 0.6 = 59.3 ns before it can meet timing at all. Reading the
# raw slack without backing out the I/O delays makes the path look like 43.6 ns
# at one constraint and 55.6 at another, which is what it looked like here until
# the two runs were reconciled -- the netlist never changed.
#
# 65 ns leaves ~3.4 ns of headroom at synthesis for place-and-route to spend.
#
# WHY IT IS 2.15x d_dsp02 AND NOT 1x. The lanes are parallel, so width alone
# would not do this. The depth comes from sharing: fpnew_fma_multi selects
# exponent and mantissa widths per format, which puts muxes inside the alignment
# and normalisation paths rather than beside them, and the slice adds lane
# packing on top. Format-parametric sharing is what this task is ABOUT, and this
# is what it costs.
#
# Tier-B pins a fixed period rather than sweeping, and the final pin is
# Agent 1's -- override with CLK_PERIOD_NS rather than editing this file, which
# is how d_dsp02 came to be measured at 20.25 against a config.mk that says 10.

current_design fp_multifmt_fma

set clk_period 65.0
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
