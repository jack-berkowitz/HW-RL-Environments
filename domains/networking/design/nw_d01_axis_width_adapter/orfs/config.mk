# ORFS design config for nw_d01 axis_width_adapter.
#
# VERILOG_FILES points at THIS task's shim AND the vendored upstream RTL it
# wraps -- both are required, the shim alone has no logic. Copying a config and
# inheriting its source paths is what broke `mesi`; the paths are spelled out in
# full for that reason and must be re-checked on any copy.
export PLATFORM        = sky130hd
export DESIGN_NAME     = axis_width_adapter
export DESIGN_NICKNAME = nw_d01_axis_width_adapter

export VERILOG_FILES = /work/domains/networking/design/nw_d01_axis_width_adapter/ref/axis_width_adapter_ref.sv \
                       /work/refs/verilog-axis/rtl/axis_adapter.v
export SDC_FILE      = /work/domains/networking/design/nw_d01_axis_width_adapter/orfs/constraint.sdc

# Full SV elaborator rather than Yosys's partial built-in parser. The shim is
# SystemVerilog wrapping Verilog-2001 with `default_nettype none, and width and
# port-direction semantics across that boundary are where the built-in frontend
# is most likely to mis-elaborate silently.
export SYNTH_HDL_FRONTEND = slang

# Synthesised at the shim's default S_BYTES=1, M_BYTES=4 (upsizing 1->4).
# The checker covers all 16 width pairs, but a PPA baseline is only meaningful
# against a fixed geometry. A baseline at a different S/M pair is NOT comparable
# to this one -- the datapath and the segment count both change. See NOTES.md.

export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100

# ABC target period, in PICOSECONDS -- ABC's -D really is ps. Derived from this
# design's own SDC so it cannot drift, and giving the variable a defined origin
# suppresses ORFS's own sed over the SDC text, which passes the raw ns number
# through unscaled and would ask ABC for a 20 ps / 50 GHz clock.
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk '/^set clk_period/{printf "%d", $$3*1000; exit}' $(SDC_FILE))
