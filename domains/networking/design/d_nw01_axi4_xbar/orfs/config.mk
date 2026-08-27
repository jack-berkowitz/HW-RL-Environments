# ORFS design config for d_nw01 axi4_xbar.
#
# Synthesised at NUM_MST=2, NUM_SLV=2 -- the smallest legal geometry. A 4x4 AXI4
# crossbar is a very different P&R proposition and the catalog warns ORFS
# runtime grows a lot on these; the baseline is only comparable within one
# geometry anyway. Recorded in NOTES.md.
export PLATFORM        = sky130hd
export DESIGN_NAME     = axi4_xbar
export DESIGN_NICKNAME = d_nw01_axi4_xbar

export VERILOG_FILES = /work/domains/networking/design/d_nw01_axi4_xbar/spec/axi4_xbar_pkg.sv \
                       /work/refs/common_cells/src/cf_math_pkg.sv \
                       /work/refs/axi/src/axi_pkg.sv \
                       /work/refs/common_cells/src/lzc.sv \
                       /work/refs/common_cells/src/counter.sv \
                       /work/refs/common_cells/src/delta_counter.sv \
                       /work/refs/common_cells/src/fifo_v3.sv \
                       /work/refs/common_cells/src/spill_register_flushable.sv \
                       /work/refs/common_cells/src/spill_register.sv \
                       /work/refs/common_cells/src/stream_register.sv \
                       /work/refs/common_cells/src/rr_arb_tree.sv \
                       /work/refs/common_cells/src/addr_decode_dync.sv \
                       /work/refs/common_cells/src/addr_decode.sv \
                       /work/refs/axi/src/axi_id_prepend.sv \
                       /work/refs/axi/src/axi_err_slv.sv \
                       /work/refs/axi/src/axi_demux_id_counters.sv \
                       /work/refs/axi/src/axi_demux_simple.sv \
                       /work/refs/axi/src/axi_cut.sv \
                       /work/refs/axi/src/axi_multicut.sv \
                       /work/refs/axi/src/axi_demux.sv \
                       /work/refs/axi/src/axi_mux.sv \
                       /work/refs/axi/src/axi_atop_filter.sv \
                       /work/refs/axi/src/axi_xbar_unmuxed.sv \
                       /work/refs/axi/src/axi_xbar.sv \
                       /work/domains/networking/design/d_nw01_axi4_xbar/ref/axi4_xbar_ref.sv
export SDC_FILE      = /work/domains/networking/design/d_nw01_axi4_xbar/orfs/constraint.sdc

# slang is required here, not merely preferred: the shim uses `type` parameters,
# packed structs and the AXI_TYPEDEF_ALL macros, none of which Yosys's built-in
# frontend elaborates correctly.
export SYNTH_HDL_FRONTEND = slang
export VERILOG_INCLUDE_DIRS = /work/refs/axi/include /work/refs/common_cells/include
# slang does NOT do library search the way Yosys -y does: every file in the
# dependency closure must be listed explicitly and IN ORDER (packages first).
# An earlier version relied on a search path and synthesis died at elaboration
# with only "Design elaboration failed". The list below was extracted from the
# working Verilator build's dependency file rather than assembled by hand.

export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100
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
