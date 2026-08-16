# d_dsp02 fp32_fma_ii1 timing constraints.
#
# SINGLE CLOCK, unlike d_ca04. The variable is named `clk_period` because that
# is what the generated candidate config's ABC line looks for -- but note that
# ppa_candidate.sh no longer re-derives that line, it copies the one below from
# this task's config.mk (F24). The name matching is convenience, not a
# dependency.
#
# THIS DESIGN IS COMBINATIONAL AT THE SPEC-MINIMAL BINDING. The reference shim
# binds NumPipeRegs=0, so there are no internal registers at all: the entire FMA
# is one combinational cone from the input flops to the output flops of whatever
# encloses it. Consequences that matter for reading the numbers:
#
#   * Fmax here measures the depth of that cone, not a pipeline stage. It will
#     be far lower than a pipelined FMA and that is the correct answer for the
#     configuration under test, not a defect.
#   * There is no register retiming to be had, so area should be much less
#     elastic under constraint than a storage-dominated design. d_dsp02 is
#     LOGIC-DOMINATED, which is why it was sequenced here.
#
# A pipelined binding is a legitimate alternative -- the spec says outright that
# latency is unconstrained -- and would be a different configuration, not a
# better result for the same one. Comparing across the two requires naming the
# axis (rule 17).

current_design fp32_fma_ii1

set clk_period 10
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }

create_clock -name core_clock -period $clk_period [get_ports clk]

set_clock_latency 0.290 [get_clocks core_clock]
set_clock_uncertainty 0.100 [get_clocks core_clock]

# I/O budget: 20 % of the period at each boundary, matching the other tasks so
# the numbers are comparable in shape even though the designs are not.
set clk_io_pct 0.2

# `all_inputs -no_clocks`, NOT `remove_from_collection`. The latter is a
# Synopsys collection command that the synthesis-stage SDC reader does not
# implement: the flow dies at 1_synth with
#   Error: 1_2_yosys.sdc, invalid command name "remove_from_collection"
# which reads like a broken SDC rather than an unsupported command. Every
# other task in this repo uses the -no_clocks form.
set non_clock_inputs [all_inputs -no_clocks]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock core_clock $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock core_clock [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $non_clock_inputs
set_load 0.05 [all_outputs]
