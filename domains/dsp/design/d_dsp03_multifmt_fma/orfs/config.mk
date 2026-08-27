# ORFS design config for d_dsp03 fp_multifmt_fma.
#
# SYNTHESISED AT THE SCORED CONFIGURATION, and it gets there by DEFAULT rather
# than by an override: the shim declares WIDTH=64, which is exactly S0. Nothing
# on this line pins it, so if the shim default ever drifts from
# `scored_configuration:` in task.yaml, the PPA number silently stops being the
# scored one. Both must move together.
#
# WIDTH=64 is also the LARGER of the two legal values, so this is the expensive
# geometry: two FP32 lanes or four 16-bit lanes through one shared datapath.
export PLATFORM        = sky130hd
export DESIGN_NAME     = fp_multifmt_fma
export DESIGN_NICKNAME = d_dsp03_multifmt_fma

# The dependency closure, EXPLICIT and in order, packages first. slang does not
# search library directories the way Verilator's -y does.
#
# EXTRACTED, NOT ASSEMBLED BY HAND. Verified by running the same read_slang the
# synthesis gate uses, with exactly this list: exit 0, 0 errors.
#
# SHORTER THAN THE VERILATOR BUILD, and that is not an oversight.
# fpnew_opgroup_multifmt_slice names eight different unit types --
# fpnew_cast_multi, fpnew_divsqrt_multi, fpnew_divsqrt_th_32,
# fpnew_divsqrt_th_64_multi, fpnew_mxdotp_multi_wrapper, fpnew_pace_fma_multi,
# fpnew_sdotp_multi_wrapper -- but every one sits inside an `OpGroup ==` generate
# branch that is false at ADDMUL, and slang does not elaborate a dead branch.
# This matters more than it looks: fpnew_divsqrt_th_32's own dependencies
# (pa_fdsu_top, pa_fpu_dp, pa_fpu_frbus) are NOT VENDORED in this repo, so a
# frontend that did elaborate dead branches could not build this design at all.
# The Verilator flow needs -y paths to refs/cvfpu/src/mxdotp and .../pace only
# because -y resolution is not branch-aware.
export VERILOG_FILES = /work/refs/common_cells/src/cf_math_pkg.sv \
                       /work/refs/cvfpu/src/fpnew_pkg.sv \
                       /work/refs/common_cells/src/lzc.sv \
                       /work/refs/cvfpu/src/fpnew_classifier.sv \
                       /work/refs/cvfpu/src/fpnew_rounding.sv \
                       /work/refs/cvfpu/src/fpnew_fma_multi.sv \
                       /work/refs/cvfpu/src/fpnew_opgroup_multifmt_slice.sv \
                       /work/domains/dsp/design/d_dsp03_multifmt_fma/ref/fp_multifmt_fma_ref.sv
export SDC_FILE      = /work/domains/dsp/design/d_dsp03_multifmt_fma/orfs/constraint.sdc

# cvfpu and common_cells both `include "common_cells/registers.svh"`. The include
# path is the TOP-LEVEL refs/common_cells/include, NOT cvfpu's own:
# refs/cvfpu/src/common_cells is an empty uninitialised submodule, and pointing
# at it gives a "cannot find registers.svh" that reads like a missing file
# rather than a missing checkout.
export SYNTH_HDL_FRONTEND = slang
export VERILOG_INCLUDE_DIRS = /work/refs/common_cells/include

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
