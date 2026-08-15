# nw_d01 axis_width_adapter timing constraints.
# Fixed 20 ns period, matching the house Tier-One designs so this baseline is
# comparable with them. This is flow/PPA validation, not an Fmax search --
# scripts/find_fmax.py sweeps the period via CLK_PERIOD_NS without editing this.

current_design axis_width_adapter

set clk_name      core_clock
set clk_port_name clk
set clk_period    20.0

# Optional override, used by scripts/find_fmax.py to sweep the period without
# rewriting this file. Absent -> the default above, so every existing
# invocation behaves exactly as before. Note this scales the IO constraints
# too, since set_input_delay/set_output_delay below are derived from
# clk_period -- the search is over a self-consistent constraint set, not just
# a moved clock edge.
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }
set clk_io_pct    0.2

set clk_port [get_ports $clk_port_name]

create_clock -name $clk_name -period $clk_period $clk_port
set clk_io_name vclk_$clk_name
create_clock -name $clk_io_name -period $clk_period
set_clock_latency 0.290 [get_clocks $clk_name]
set_clock_latency 0.290 [get_clocks $clk_io_name]

set non_clock_inputs [all_inputs -no_clocks]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock $clk_io_name $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name [all_outputs]
