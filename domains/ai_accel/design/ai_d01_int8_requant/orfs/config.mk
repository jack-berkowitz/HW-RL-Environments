# ORFS design config for ai_d01 int8_requant.
#
# VERILOG_FILES points at THIS task's reference, not a neighbour's. Copying a
# config and inheriting its source path is what broke `mesi`; the path below is
# spelled out in full for that reason and must be re-checked on any copy.
export PLATFORM        = sky130hd
export DESIGN_NAME     = int8_requant
export DESIGN_NICKNAME = ai_d01_int8_requant

export VERILOG_FILES = /work/domains/ai_accel/design/ai_d01_int8_requant/ref/int8_requant_ref.sv
export SDC_FILE      = /work/domains/ai_accel/design/ai_d01_int8_requant/orfs/constraint.sdc

# Full SV elaborator rather than Yosys's partial built-in parser: this design
# leans on signed 64-bit intermediates, size casts and an automatic function,
# and width/sign semantics are exactly where the built-in frontend is most
# likely to mis-elaborate silently.
export SYNTH_HDL_FRONTEND = slang

# The DUT is synthesised at its default LANES=4. The checker covers 1/2/4/8, but
# a PPA baseline is only meaningful against a fixed geometry -- see NOTES.md.
# Baselines taken at a different LANES are NOT comparable to this one.

export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100

# ABC target period, in PICOSECONDS -- ABC's -D really is ps. Derived from this
# design's own SDC rather than hard-coded so it cannot drift if the period
# changes. Giving the variable an origin other than "undefined" also suppresses
# ORFS's own sed over the SDC text, which passes the raw ns number through
# unscaled and would otherwise ask ABC for a 20 ps / 50 GHz clock.
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk '/^set clk_period/{printf "%d", $$3*1000; exit}' $(SDC_FILE))
