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

# Disable adder extraction/mapping for this design.
#
# sky130hd sets ADDER_MAP_FILE by default, which makes synth.tcl run Yosys's
# `extract_fa` (find and extract full/half adders). That pass is pattern
# matching over the whole flattened netlist, and on this design it ran for
# ~12 minutes, peaked past 4 GB and was killed before emitting a netlist:
#   6. Executing EXTRACT_FA pass ...
#   make[1]: *** [Makefile:266: do-yosys] Error 247
# ncache is large and adder-poor (its arithmetic is byte-offset muxing and
# small comparators, not wide adds), so there is very little for the pass to
# find and a great deal for it to search. Emptying the variable skips
# extract_fa entirely -- the same knob designs/sky130hd/{gcd,ibex} use.
export ADDER_MAP_FILE :=
