# ORFS design config for the uart candidate.
# RTL and SDC are referenced from the project repo, mounted at /work in the
# container; nothing is copied into the OpenROAD-flow-scripts clone.
export PLATFORM    = sky130hd
export DESIGN_NAME = uart
export DESIGN_NICKNAME = uart

export VERILOG_FILES = /work/candidates/TierOne/uart.sv
export SDC_FILE      = /work/orfs_configs/sky130hd/TierOne/uart/constraint.sdc

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

export PLACE_PINS_ARGS = -exclude right:67-70 -exclude right:83-86 -exclude right:94-98

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
