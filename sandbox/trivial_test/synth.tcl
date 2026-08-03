yosys read_verilog -sv trivial_test.sv
yosys synth -top trivial_test
yosys dfflibmap -liberty /home/jack/tools/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
yosys abc -liberty /home/jack/tools/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
yosys write_verilog synth_out.v
yosys stat
