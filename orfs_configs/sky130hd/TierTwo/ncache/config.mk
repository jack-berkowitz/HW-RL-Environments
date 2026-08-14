# ORFS design config for the rob candidate.
# RTL and SDC are referenced from the project repo, mounted at /work in the
# container; nothing is copied into the OpenROAD-flow-scripts clone.
export PLATFORM    = sky130hd
export DESIGN_NAME = ncache
export DESIGN_NICKNAME = ncache

export VERILOG_FILES = /work/candidates/TierTwo/ncache.sv
export SDC_FILE      = /work/orfs_configs/sky130hd/TierTwo/ncache/constraint.sdc

export SYNTH_HDL_FRONTEND = slang

# Tool settings are deliberately left at platform/flow defaults, matching every
# other design in the suite (bpred, lsq, mesi, rob all use CORE_UTILIZATION 20 /
# PLACE_DENSITY 0.50). Three earlier per-design overrides were tried here and
# have been reverted, because tuning the tool per design makes ncache's PPA
# numbers incomparable to the designs that close on defaults:
#   * FASTROUTE_TCL pointing at a local copy with the layer derate at 0.12
#     instead of the platform's 0.2
#   * PLACE_DENSITY 0.30 instead of 0.50
#   * DETAILED_ROUTE_END_ITERATION 40 instead of the default 64
# bpred, rob and softmax all complete the full flow on stock settings. If ncache
# cannot, that is a property of ncache's RTL -- its average net is 139 um against
# 39-78 um for the rest of the suite -- and is legitimate benchmark signal rather
# than something to configure away.
export CORE_UTILIZATION = 20
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
