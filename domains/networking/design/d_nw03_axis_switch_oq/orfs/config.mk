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
# ABC WAS TOLD A PERIOD THE DESIGN IS NOT CONSTRAINED TO. This awk reads the
# STATIC TEXT of constraint.sdc, but the sdc overrides that same variable from
# $::env(CLK_PERIOD_NS) at build time -- so every build at a pin different from
# the file's default synthesised against one period while STA checked another.
# Measured across all ten design tasks: nine mismatched, d_ai01 worst at 50.0 ns
# told to ABC against 16.75 ns checked. The synthesis hint and the timing
# constraint disagreed, and nothing compared them.
#
# ovr= threads the same environment variable the sdc reads, so the two cannot
# diverge again. Unset, it yields the file's value exactly as before.
#
# $$CLK_PERIOD_NS, NOT $(CLK_PERIOD_NS), AND THAT IS LOAD-BEARING. make expands
# $$ to $ and hands the shell an env reference; build_config_hash.py evaluates
# this same $(shell ...) body in bash and does the identical .replace("$$","$").
# The make-variable form works under make and resolves to EMPTY under the hash
# script, which would make the recorded build_config_hash disagree with the
# configuration ORFS actually used -- the one thing that field exists to prevent.
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk -v ovr="$$CLK_PERIOD_NS" '/^set clk_period/{p=$$3} END{if(ovr!="") p=ovr; printf "%d", p*1000}' $(SDC_FILE))
