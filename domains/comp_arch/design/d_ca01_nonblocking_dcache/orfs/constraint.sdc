current_design nonblocking_dcache
set clk_name      core_clock
set clk_port_name clk_i
set clk_period    10.0
if {[info exists ::env(CLK_PERIOD_NS)]} { set clk_period $::env(CLK_PERIOD_NS) }
set clk_io_pct    0.2
set clk_port [get_ports $clk_port_name]
create_clock -name $clk_name -period $clk_period $clk_port
set_clock_latency 0.290 [get_clocks $clk_name]
set non_clock_inputs [lsearch -inline -all -not -exact [all_inputs] $clk_port]
set_input_delay  [expr $clk_period * $clk_io_pct] -clock $clk_name $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_name [all_outputs]
