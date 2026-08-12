# ORFS design config for the rob candidate.
# RTL and SDC are referenced from the project repo, mounted at /work in the
# container; nothing is copied into the OpenROAD-flow-scripts clone.
export PLATFORM    = sky130hd
export DESIGN_NAME = rob
export DESIGN_NICKNAME = rob

export VERILOG_FILES = /work/candidates/TierTwo/rob.sv
export SDC_FILE      = /work/orfs_configs/sky130hd/TierTwo/rob/constraint.sdc

export SYNTH_HDL_FRONTEND = slang

export CORE_UTILIZATION = 20
export PLACE_DENSITY = 0.50
export TNS_END_PERCENT = 100

# ABC target period, in PICOSECONDS -- ABC's -D really is ps.
#
# ORFS's scripts/variables.mk derives this by sed-ing `set clk_period` out of
# the SDC and passing the raw number straight through, with no *1000 (only the
# ihp-sg13g2 platform config scales it). A 20 ns SDC therefore became `-D 20.0`,
# i.e. ABC was told to hit a 20 ps / 50 GHz clock. The small designs shrug that
# off -- they just get maximally-optimised netlists -- but on ncache ABC ground
# away until it was killed and synthesis never produced a netlist at all.
#
# Setting it here gives the variable an origin other than "undefined", which
# suppresses that sed. It is derived from this design's own SDC rather than
# hard-coded, so it cannot drift if the period changes. The Fmax sweep overrides
# it on the make command line (see scripts/run_orfs_build.sh), which wins.
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk '/^set clk_period/{printf "%d", $$3*1000; exit}' $(SDC_FILE))
