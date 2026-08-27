# ORFS design config for d_ai01 fp16_gemm_array.
#
# SYNTHESISED AT THE SCORED CONFIGURATION, AND IT GETS THERE BY AN EXPLICIT
# OVERRIDE THAT NAMES ITS AUTHORITY -- see VERILOG_TOP_PARAMS below.
#
# It used to get there by DEFAULT: the shim declared HEIGHT=8, WIDTH=8 and
# nothing on this line pinned it, so this comment warned that if the shim default
# ever drifted from `scored_configuration:` in task.yaml the PPA number would
# silently stop being the scored one.
#
# IT DULY DRIFTED. Jack moved P2 to HEIGHT=4 on 2026-08-25 (34f1d43) because
# HEIGHT=8 does not route on sky130hd -- 76,253 to 83,445 detailed-routing
# violations across three floorplans -- and the shim still defaults to 8. An ORFS
# run in that window would have synthesised 8x8, labelled it the scored number,
# and failed for a reason that is no longer the scored question. The comment is
# why it was caught; AGENT-DESIGN-43a92055 read it and checked.
#
# The pin is an override rather than a change to the shim default, because the
# spec now states that its declared defaults are NOT normative and P2 is the sole
# authority on geometry. Moving the default would put the scored configuration
# back in two places.
export PLATFORM        = sky130hd
export DESIGN_NAME     = fp16_gemm_array
export DESIGN_NICKNAME = d_ai01_fp16_gemm_array

# THE SCORED GEOMETRY, pinned. task.yaml `scored_configuration:` is the authority
# (HEIGHT 4, WIDTH 8); this line must equal it and nothing else may set it.
# For SYNTH_HDL_FRONTEND=slang these become `-G HEIGHT=4 -G WIDTH=8` on
# read_slang, applied in ORFS's synth_preamble.tcl. It is a Tcl dict: flat
# key-value pairs, not `KEY=VALUE`.
#
# build_config_hash.py hashes this field whenever it is set, so a 4x8 build and
# an 8x8 build of this task can no longer collide on one hash and be declared
# comparable under rule 17.
export VERILOG_TOP_PARAMS = HEIGHT 4 WIDTH 8

# FLOORPLAN AND PLACEMENT, matching every other design task in this repo.
# Without CORE_UTILIZATION or an explicit DIE_AREA/CORE_AREA, ORFS stops at
# `No floorplan initialization method specified` and the build dies at
# do-2_1_floorplan. That never surfaced because this task's recorded area is a
# SYNTHESIS figure -- task.yaml labels it "synthesis + OpenSTA only
# (place-and-route not run)" -- so nothing had ever asked this config to place
# anything. The gap only appeared when the reference Fmax sweep, which runs the
# full flow, tried to.
#
# CORE_UTILIZATION IS 30 HERE AND 10 EVERYWHERE ELSE. That is deliberate.
#
# The first attempt used 10 to match the other tasks. This design is 1,631,831
# um2 of cells -- 2.8x the next largest -- so 10% produced a 12,553,554 um2 core,
# and detailed routing ended its first optimisation pass with 82,569 DRC
# violations still open, moving 70,238 -> 67,540 -> 67,540 across the next 20%.
# Not slow: not converging. That run was killed after 1h40m without completing
# one of the seven place-and-route runs a sweep needs.
#
# 30 was chosen from measurement rather than convention: it puts this core at
# 5,439,437 um2, which is 0.94x d_ca01's 5,780,320 -- the largest core that has
# actually routed clean in this repo, at 37 minutes per run. The target is the
# biggest thing known to work here, not a number from a textbook.
#
# THIS DOES NOT BREAK ANY COMPARISON. Nothing here compares area across tasks:
# the specs say a submission is compared against its own task's reference and the
# other submissions to that task, the results table is one table per task, and
# d_dsp02's spec states outright that comparing across tasks was never
# meaningful. Rule 17 requires matching configuration between numbers BEING
# COMPARED, and every d_ai01 build -- reference and all candidates -- uses this
# file. d_ai01 has ppa: ABSENT, so no recorded number is invalidated.
#
# SYNTH_MEMORY_MAX_BITS was a different case and had to match: there the
# reference and the candidates of ONE task disagreed, which broke a comparison
# actually being made.
export CORE_UTILIZATION = 30
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100


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

# ABC's mapping target. COPIED VERBATIM from d_ca01's config.mk, deriving the
# value from this task's own SDC rather than restating a number.
#
# WITHOUT THIS LINE ABC WAS TOLD 50 PICOSECONDS INSTEAD OF 50 NANOSECONDS.
# d_ai01 was the last design task with no explicit line, so it fell through to
# ORFS's own fallback (scripts/variables.mk:220):
#
#   sed -nE "s/^set\s+clk_period\s+(\S+).*|.*-period\s+(\S+).*/\1\2/p" $(SDC_FILE)
#
# That lifts the raw number out of the SDC -- `50.0` -- and assigns it to a
# variable whose units are PICOseconds. It does not multiply by 1000. So every
# synthesis of this task that did not come through a caller setting
# CLK_PERIOD_NS mapped against a 20 GHz target, and ABC buys delay at any area
# cost: upsizing, buffering, duplication. Observed directly in the build log as
# `Setting clock period to 50.0` where every other task shows picoseconds.
#
# The callers masked it: run_orfs_build.sh:121 puts a correct period*1000 on the
# make command line whenever CLK_PERIOD_NS is set, and find_fmax.py sets it every
# iteration. A task that depends on its caller to mask a units error still
# produces a wrong number the moment someone builds it directly, which is what
# the reference probes did.
#
# The fallback's other failure mode is worse and is why d_ca04 carries an
# adapted line: on a MULTI-CLOCK SDC with no `set clk_period`, that same sed
# returns the literal string `$wr_period` rather than any number at all.
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

# The include path is the TOP-LEVEL refs/common_cells/include, NOT cvfpu's own:
# refs/cvfpu/src/common_cells is an empty uninitialised submodule, and pointing
# at it gives a "cannot find registers.svh" that reads like a missing file.
export VERILOG_INCLUDE_DIRS = /work/refs/common_cells/include
