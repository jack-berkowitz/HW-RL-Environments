# ORFS design config for d_ai01 fp16_gemm_array.
#
# SYNTHESISED AT THE SCORED CONFIGURATION, and it gets there by DEFAULT rather
# than by an override: the shim declares HEIGHT=16, WIDTH=16. Nothing on this
# line pins it, so if the shim default ever drifts from `scored_configuration:`
# in task.yaml, the PPA number silently stops being the scored one. Both must
# move together. (Same failure mode d_dsp03's config.mk documents.)
export PLATFORM        = sky130hd
export DESIGN_NAME     = fp16_gemm_array
export DESIGN_NICKNAME = d_ai01_fp16_gemm_array

export SYNTH_HDL_FRONTEND = slang

# TWO shim files, and the order matters. fp16_gemm_array_ref.sv declares
# `fp16_gemm_array_ref_inner`; fp16_gemm_array_top.sv declares the contract name
# `fp16_gemm_array` and instantiates it. The split lets the negative controls in
# controls/ wrap the reference without a module-name collision -- a control
# build compiles the control plus the inner file and leaves the top out.

# The dependency closure, EXPLICIT and in order, packages first. slang does not
# search library directories the way Verilator's -y does.
#
# EXTRACTED, NOT ASSEMBLED BY HAND. The list is Verilator's own dependency
# output (obj_dir/*.d) for the elaborated hierarchy, which is what the design
# actually reads rather than what I believed it reads.
#
# VERIFIED by running read_slang with exactly this list, --top fp16_gemm_array,
# in openroad/orfs:latest:
#   exit 0, 0 errors, 45.4 s, 1292 MB peak
#   stat reported 256 $mul at the 16x16 geometry this list was first
#                          verified against <- one multiplier per computing
#                          element, i.e. the full
#                              array elaborated; a collapsed geometry or a dead
#                              generate branch would show here as a smaller
#                              count. This is the check that the file list
#                              builds the design I meant, not merely A design.
#
# read_slang is BUILT IN to the Yosys in this image (0.67). `plugin -i slang`
# fails with "cannot open shared object file" -- there is no slang.so to load.
#
# hwpe_stream_package and hci_package are here only because redmule_pkg imports
# them at its top (redmule_pkg.sv:10). Nothing in the engine hierarchy uses a
# symbol from either, but the import is unconditional, so the packages must be
# readable or redmule_pkg does not compile.
#
# cluster_clk_cells.sv supplies `cluster_clock_gating`, instantiated by
# redmule_ce for its stage-2 gate. It lives under src/deprecated/ and the module
# name does not match its filename, so Verilator's -y cannot find it either --
# it has to be named explicitly in both flows.
export VERILOG_FILES = /work/refs/common_cells/src/cf_math_pkg.sv \
                       /work/refs/cvfpu/src/fpnew_pkg.sv \
                       /work/refs/hwpe-stream/rtl/hwpe_stream_package.sv \
                       /work/refs/hci/rtl/common/hci_package.sv \
                       /work/refs/redmule/rtl/redmule_pkg.sv \
                       /work/refs/common_cells/src/lzc.sv \
                       /work/refs/cvfpu/src/lfsr_sr.sv \
                       /work/refs/cvfpu/src/fpnew_classifier.sv \
                       /work/refs/cvfpu/src/fpnew_rounding.sv \
                       /work/refs/tech_cells_generic/src/rtl/tc_clk.sv \
                       /work/refs/tech_cells_generic/src/deprecated/cluster_clk_cells.sv \
                       /work/refs/redmule/rtl/redmule_fma.sv \
                       /work/refs/redmule/rtl/redmule_noncomp.sv \
                       /work/refs/redmule/rtl/redmule_ce.sv \
                       /work/refs/redmule/rtl/redmule_row.sv \
                       /work/refs/redmule/rtl/redmule_engine.sv \
                       /work/domains/ai_accel/design/d_ai01_fp16_gemm_array/ref/fp16_gemm_array_ref.sv \
                       /work/domains/ai_accel/design/d_ai01_fp16_gemm_array/ref/fp16_gemm_array_top.sv

export SDC_FILE      = /work/domains/ai_accel/design/d_ai01_fp16_gemm_array/orfs/constraint.sdc

# The include path is the TOP-LEVEL refs/common_cells/include, NOT cvfpu's own:
# refs/cvfpu/src/common_cells is an empty uninitialised submodule, and pointing
# at it gives a "cannot find registers.svh" that reads like a missing file.
export VERILOG_INCLUDE_DIRS = /work/refs/common_cells/include
