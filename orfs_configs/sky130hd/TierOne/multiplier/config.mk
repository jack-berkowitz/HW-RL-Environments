# ORFS design config for the multiplier candidate.
# RTL and SDC are referenced from the project repo, mounted at /work in the
# container; nothing is copied into the OpenROAD-flow-scripts clone.
export PLATFORM    = sky130hd
export DESIGN_NAME = multiplier
export DESIGN_NICKNAME = multiplier

export VERILOG_FILES = /work/candidates/multiplier.sv
export SDC_FILE      = /work/orfs_configs/sky130hd/multiplier/constraint.sdc

# The candidates are SystemVerilog (always_ff/always_comb, size casts,
# unpacked arrays). ORFS defaults to `read_verilog -defer -sv`, which does
# parse all five files without error; slang is selected anyway because it is
# a full SV elaborator rather than Yosys's partial built-in parser, so width
# and cast semantics are less likely to be silently mis-elaborated. Drop this
# line to fall back to the built-in frontend.
export SYNTH_HDL_FRONTEND = slang

export CORE_UTILIZATION = 10
export PLACE_DENSITY = 0.50
export TNS_END_PERCENT = 100
