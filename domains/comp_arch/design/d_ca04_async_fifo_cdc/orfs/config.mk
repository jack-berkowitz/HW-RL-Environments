# ORFS design config for d_ca04 async_fifo_cdc.
#
# VERILOG_FILES points at THIS task's shim and the vendored upstream RTL it
# wraps, plus the common_cells support modules the FIFO instantiates
# (sync, binary_to_gray, gray_to_binary, spill_register). The shim alone has no
# logic. Paths spelled out in full: copying a config and inheriting its source
# paths is what broke `mesi`.
export PLATFORM        = sky130hd
export DESIGN_NAME     = async_fifo_cdc
export DESIGN_NICKNAME = d_ca04_async_fifo_cdc

export VERILOG_FILES = /work/domains/comp_arch/design/d_ca04_async_fifo_cdc/ref/async_fifo_cdc_ref.sv \
                       /work/refs/common_cells/src/cdc_fifo_gray.sv \
                       /work/refs/common_cells/src/sync.sv \
                       /work/refs/common_cells/src/binary_to_gray.sv \
                       /work/refs/common_cells/src/gray_to_binary.sv \
                       /work/refs/common_cells/src/spill_register.sv \
                       /work/refs/common_cells/src/spill_register_flushable.sv \
                       /work/refs/common_cells/src/cf_math_pkg.sv
export SDC_FILE      = /work/domains/comp_arch/design/d_ca04_async_fifo_cdc/orfs/constraint.sdc

# common_cells uses `include "common_cells/registers.svh"
export SYNTH_HDL_FRONTEND = slang
export VERILOG_INCLUDE_DIRS = /work/refs/common_cells/include

# Synthesised at DATA_W=32, LOG_DEPTH=3, SYNC_STAGES=2. The checker covers all
# 18 legal combinations, but a PPA baseline is only meaningful against a fixed
# geometry -- depth and width both change the storage array. A baseline at other
# parameters is NOT comparable.
export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100

# Picoseconds. Derived from the WRITE clock, the faster of the two.
# ABC WAS TOLD A PERIOD THE DESIGN IS NOT CONSTRAINED TO. This awk reads the
# STATIC TEXT of constraint.sdc, but the sdc overrides wr_period from
# $::env(CLK_PERIOD_NS) at build time -- so every build at the 4.25 ns pin
# synthesised against a 5.0 ns target while STA checked 4.25. The synthesis hint
# and the timing constraint disagreed, and nothing compared them.
#
# ovr= threads the same environment variable the sdc reads, so the two cannot
# diverge again. Unset, it yields the file's value exactly as before.
#
# $$CLK_PERIOD_NS, NOT $(CLK_PERIOD_NS), AND THAT IS LOAD-BEARING. make expands
# $$ to $ and hands the shell an env reference; build_config_hash.py evaluates
# this same $(shell ...) body in bash and does the identical .replace("$$","$").
# The $(...) make-variable form works under make and resolves to EMPTY under the
# hash script, which would make the recorded build_config_hash disagree with the
# configuration ORFS actually used -- the one thing that field exists to prevent.
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk -v ovr="$$CLK_PERIOD_NS" '/^set wr_period/{p=$$3} END{if(ovr!="") p=ovr; printf "%d", p*1000}' $(SDC_FILE))
