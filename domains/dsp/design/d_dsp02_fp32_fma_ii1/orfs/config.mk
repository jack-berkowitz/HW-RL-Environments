# ORFS design config for d_dsp02 fp32_fma_ii1.
#
# VERILOG_FILES lists the full dependency closure EXPLICITLY. slang does not
# search library directories the way Verilator's -y does, so every file has to
# be named, packages first. The closure was extracted rather than assembled by
# hand: fpnew_fma instantiates fpnew_classifier, fpnew_rounding and lzc, and
# lzc instantiates nothing further.
#
# Paths are spelled out in full. Copying a config and inheriting its source
# paths is what broke `mesi`.
export PLATFORM        = sky130hd
export DESIGN_NAME     = fp32_fma_ii1
export DESIGN_NICKNAME = d_dsp02_fp32_fma_ii1

export VERILOG_FILES = /work/refs/common_cells/src/cf_math_pkg.sv \
                       /work/refs/cvfpu/src/fpnew_pkg.sv \
                       /work/refs/common_cells/src/lzc.sv \
                       /work/refs/cvfpu/src/fpnew_classifier.sv \
                       /work/refs/cvfpu/src/fpnew_rounding.sv \
                       /work/refs/cvfpu/src/fpnew_fma.sv \
                       /work/domains/dsp/design/d_dsp02_fp32_fma_ii1/ref/fp32_fma_ii1_ref.sv
export SDC_FILE      = /work/domains/dsp/design/d_dsp02_fp32_fma_ii1/orfs/constraint.sdc

# cvfpu and common_cells both use `include "common_cells/registers.svh".
# The include path is the TOP-LEVEL refs/common_cells/include, NOT cvfpu's own:
# refs/cvfpu/src/common_cells is an empty uninitialised submodule, and pointing
# at it produces a "cannot find registers.svh" that reads like a missing file
# rather than a missing checkout.
export SYNTH_HDL_FRONTEND = slang
export VERILOG_INCLUDE_DIRS = /work/refs/common_cells/include

# Synthesised at the spec-minimal binding: NumPipeRegs=0, so the design is
# purely combinational. See constraint.sdc for what that means for Fmax and for
# elasticity -- this is the first LOGIC-DOMINATED design measured here, which is
# why it was sequenced after the storage-dominated ones.
#
# There are no parameters to fix a geometry at: fp32_fma_ii1 declares none.
# Format is fixed at binary32 by the spec and rounding mode is a runtime input.
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
