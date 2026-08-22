# ORFS design config for d_nw03 axis_switch_oq.
#
# SYNTHESISED AT THE SCORED CONFIGURATION, and it gets there by DEFAULT rather
# than by an override: the shim declares S_COUNT=4, M_COUNT=4, DATA_W=32, which
# is exactly S0. Nothing on this line pins the geometry, so if a shim default
# ever drifts from `scored_configuration:` in task.yaml, the PPA number silently
# stops being the scored one. Both must move together.
export PLATFORM        = sky130hd
export DESIGN_NAME     = axis_switch_oq
export DESIGN_NICKNAME = d_nw03_axis_switch_oq

# The dependency closure, EXPLICIT and in order. slang does not search library
# directories the way Verilator's -y does, so every file is named.
#
# EXTRACTED, NOT ASSEMBLED BY HAND. Verified by running the same read_slang the
# synthesis gate uses, with exactly this list: exit 0, 0 errors. Note it is
# SHORTER than the closure recorded in task.yaml, which lists axis_demux,
# axis_fifo and axis_arb_mux as well. Those are what Verilator's -y search
# pulled in, not what axis_switch instantiates; the ORFS list is the real one.
export VERILOG_FILES = /work/refs/verilog-axis/rtl/priority_encoder.v \
                       /work/refs/verilog-axis/rtl/arbiter.v \
                       /work/refs/verilog-axis/rtl/axis_register.v \
                       /work/refs/verilog-axis/rtl/axis_switch.v \
                       /work/domains/networking/design/d_nw03_axis_switch_oq/ref/axis_switch_oq_ref.sv
export SDC_FILE      = /work/domains/networking/design/d_nw03_axis_switch_oq/orfs/constraint.sdc

# slang, not the built-in frontend: the shim is SystemVerilog and the anchor is
# Verilog-2001, and only slang reads both in one elaboration here. No include
# directories are needed -- verilog-axis uses none.
export SYNTH_HDL_FRONTEND = slang

export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100

# Picoseconds, from this task's single clock.
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk '/^set clk_period/{printf "%d", $$3*1000; exit}' $(SDC_FILE))
