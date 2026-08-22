# d_ca01 nonblocking data cache -- ORFS build configuration.
#
# VERILOG_FILES is EXPLICIT and ORDERED, not a library search. The simulation
# flags use `-y` search paths, which works for Verilator but not here: slang
# compiles a file list as one unit, while `-y` pulls each file as its own, so
# bsg_defines.sv's macros never reach the files that use them. The first
# attempt failed on `BSG_VIVADO_SYNTH_FAILS` expanding to nothing in
# bsg_mem_1rw_sync_mask_write_bit_synth.sv. The closure below was extracted
# from Verilator's own dependency output for the scored configuration, so it is
# what the design actually instantiates rather than what a directory contains.
export PLATFORM        = sky130hd
export DESIGN_NAME     = nonblocking_dcache
export DESIGN_NICKNAME = d_ca01_nonblocking_dcache

export VERILOG_FILES = /work/domains/comp_arch/design/d_ca01_nonblocking_dcache/ref/nonblocking_dcache_ref.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_defines.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_pkg.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_data_mem.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_decode.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_dma.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_mhu.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_miss_fifo.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_stat_mem.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_tag_mem.sv \
                       /work/refs/basejump_stl/bsg_cache/bsg_cache_non_blocking_tl_stage.sv \
                       /work/refs/basejump_stl/bsg_dataflow/bsg_fifo_1r1w_small.sv \
                       /work/refs/basejump_stl/bsg_dataflow/bsg_fifo_1r1w_small_hardened.sv \
                       /work/refs/basejump_stl/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.sv \
                       /work/refs/basejump_stl/bsg_dataflow/bsg_fifo_tracker.sv \
                       /work/refs/basejump_stl/bsg_dataflow/bsg_two_fifo.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1r1w.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1r1w_sync.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1r1w_sync_synth.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1r1w_synth.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1rw_sync.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1rw_sync_mask_write_bit_synth.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1rw_sync_mask_write_byte.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1rw_sync_mask_write_byte_synth.sv \
                       /work/refs/basejump_stl/bsg_mem/bsg_mem_1rw_sync_synth.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_circular_ptr.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_clkgate_optional.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_counter_clear_up.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_decode.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_decode_with_v.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_dff.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_dff_en.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_dff_en_bypass.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_dff_reset.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_dff_reset_en.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_dff_reset_set_clear.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_dlatch.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_encode_one_hot.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_expand_bitmask.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_lru_pseudo_tree_backup.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_lru_pseudo_tree_decode.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_lru_pseudo_tree_encode.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_mux.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_mux_bitwise.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_mux_segmented.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_priority_encode.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_priority_encode_one_hot_out.sv \
                       /work/refs/basejump_stl/bsg_misc/bsg_scan.sv

export SDC_FILE      = /work/domains/comp_arch/design/d_ca01_nonblocking_dcache/orfs/constraint.sdc
export SYNTH_HDL_FRONTEND = slang

# -DYOSYS IS LOAD-BEARING, not a hint. bsg_defines.sv defines
# BSG_VIVADO_SYNTH_FAILS as EMPTY only when one of DC / CDS_TOOL_DEFINE /
# SURELOG / YOSYS is defined; otherwise, under SYNTHESIS, it expands to the bare
# identifier `this_module_is_not_synthesizeable_in_vivado`, which lands directly
# before an always_ff and fails the parse. The repo's own .sby equivalence files
# already pass -DYOSYS for this reason.
export SYNTH_SLANG_ARGS = -DYOSYS
export VERILOG_INCLUDE_DIRS = /work/refs/basejump_stl/bsg_misc /work/refs/basejump_stl/bsg_cache

# The scored configuration (rule 18) is DATA_W=32 SETS=16 WAYS=4 MAX_MISSES=8.
# The reference module declares exactly those as its parameter defaults, so no
# override is needed here and none is given -- an override that merely restates
# a default is a second place for the two to drift apart.

export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk '/^set clk_period/{printf "%d", $$3*1000; exit}' $(SDC_FILE))
