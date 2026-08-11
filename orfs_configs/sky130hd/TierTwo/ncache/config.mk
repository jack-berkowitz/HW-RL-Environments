# ORFS design config for the rob candidate.
# RTL and SDC are referenced from the project repo, mounted at /work in the
# container; nothing is copied into the OpenROAD-flow-scripts clone.
export PLATFORM    = sky130hd
export DESIGN_NAME = ncache
export DESIGN_NICKNAME = ncache

export VERILOG_FILES = /work/candidates/TierTwo/ncache.sv
export SDC_FILE      = /work/orfs_configs/sky130hd/TierTwo/ncache/constraint.sdc

export SYNTH_HDL_FRONTEND = slang

export CORE_UTILIZATION = 10
export PLACE_DENSITY = 0.50
export TNS_END_PERCENT = 100
