read_liberty /home/jack/tools/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synth_out.v
link_design trivial_test

create_clock -name clk -period 5.0 [get_ports clk]
# Exclude clk from all_inputs -- input delay relative to a clock defined on the
# same port is not allowed (OpenSTA warning 441).
set_input_delay 0.5 -clock clk [all_inputs -no_clocks]
set_output_delay 0.5 -clock clk [all_outputs]

report_checks -path_delay max -group_path_count 10
report_checks -path_delay min -group_path_count 10
