# Carried over from Tier1's flat 20ns period. This is a starting point for
# calibration, not a validated target -- ROB is structurally different
# (pointer/comparator logic across DEPTH entries, 2-wide lanes) from the
# Tier1 modules this period was tuned against. Check WNS after the first
# run; if slack is large and positive, this period was never a real test.
current_design lsq

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