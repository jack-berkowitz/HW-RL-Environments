# ORFS design config for the rob candidate.
# RTL and SDC are referenced from the project repo, mounted at /work in the
# container; nothing is copied into the OpenROAD-flow-scripts clone.
export PLATFORM    = sky130hd
export DESIGN_NAME = lsq
export DESIGN_NICKNAME = lsq

export VERILOG_FILES = /work/candidates/TierTwo/lsq.sv
export SDC_FILE      = /work/orfs_configs/sky130hd/TierTwo/lsq/constraint.sdc

export SYNTH_HDL_FRONTEND = slang

export CORE_UTILIZATION = 10
export PLACE_DENSITY = 0.50
export TNS_END_PERCENT = 100
