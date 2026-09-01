# d_ca06 queue timing constraints. Single clock.
#
# The storage array is the design: DEPTH entries of T, every one a flop, plus
# PORTS combinational read muxes across the whole array. Both the mux depth and
# the reset fanout scale with DEPTH, so the scored geometry is pinned in
# config.mk and a number at another geometry is not comparable.

current_design queue_top

set clk_period 4.0
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }

create_clock -name core_clock -period $clk_period [get_ports clk]
set_clock_latency 0.290 [get_clocks core_clock]

set clk_io_pct 0.2
set_input_delay  [expr $clk_period * $clk_io_pct] -clock core_clock \
    [get_ports {rst_n write_data[*] write_valid[*] read_accept[*]}]
set_output_delay [expr $clk_period * $clk_io_pct] -clock core_clock \
    [get_ports {write_accept[*] read_data[*] read_valid[*]}]
