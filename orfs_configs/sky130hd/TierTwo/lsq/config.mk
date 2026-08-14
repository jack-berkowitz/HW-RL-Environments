# ORFS design config for the rob candidate.
# RTL and SDC are referenced from the project repo, mounted at /work in the
# container; nothing is copied into the OpenROAD-flow-scripts clone.
export PLATFORM    = sky130hd
export DESIGN_NAME = lsq
export DESIGN_NICKNAME = lsq

export VERILOG_FILES = /work/candidates/TierTwo/lsq.sv
export SDC_FILE      = /work/orfs_configs/sky130hd/TierTwo/lsq/constraint.sdc

export SYNTH_HDL_FRONTEND = slang

# NO TOOL OVERRIDES NEEDED HERE -- recorded because one was nearly added.
#
# At DEPTH=16 this design would not synthesise: Yosys's SAT-based `share` pass
# has cost quadratic in the arithmetic-operator count, and the DEPTH*DEPTH
# disambiguation sweep put ~550 AGE_W-wide magnitude comparators in front of it
# (~150k candidate pairs, each a SAT call). Synthesis sat at
#   3.15. Executing SHARE pass (SAT-based resource sharing)
# on 100% of one core for 26 minutes without emitting a netlist, twice.
#
# `export SYNTH_ARGS = -noshare` was the tempting fix. It turned out to be
# unnecessary: reducing DEPTH to 8 (already a legal value per lsq_iface.sv) cuts
# the sweep 4x, and synthesis then completes in ~5 minutes WITH `share` enabled.
# Stock settings are kept so this module's PPA stays comparable to the rest of
# the suite. Do not add the override without first showing `share` cannot finish.

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
