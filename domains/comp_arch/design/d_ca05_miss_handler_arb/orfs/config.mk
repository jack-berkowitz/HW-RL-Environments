# ORFS design config for d_ca05 miss_handler_arb.
#
# ONE CONFIGURATION. NR_PORTS is a parameter so arbitration must be written
# against a count rather than unrolled, but spec P2 scores only 4 and only 4 is
# measured -- an unmeasured setting is not a scored one.
export PLATFORM        = sky130hd
export DESIGN_NAME     = miss_handler_arb
export DESIGN_NICKNAME = d_ca05_miss_handler_arb

# FLOORPLAN AND PLACEMENT, the other design tasks' values VERBATIM and not chosen
# for this design -- a per-task floorplan target would make area incomparable
# across the corpus. Without CORE_UTILIZATION or an explicit DIE_AREA, ORFS stops
# at `No floorplan initialization method specified`.
export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100

export SYNTH_HDL_FRONTEND = slang

# THE CLOSURE, EXPLICIT AND IN ORDER, packages first: slang does not search
# library directories the way Verilator's -y does. Kept in step with
# ref/sim_flags_verilator.txt; if one changes the other must.
#
# axi_pkg IS PULP'S AND IS EASY TO MISS. Nothing in miss_handler.sv names it;
# axi_adapter.sv does -- BURST_INCR, BURST_WRAP, CACHE_MODIFIABLE -- and
# axi_adapter is instantiated twice inside miss_handler. Omitting it gives 43
# errors of the form "Package/class for ':: reference' not found", none of which
# names the missing package.
#
# ONLY cv64a6_imafdc_sv39_config_pkg.sv may be listed. Every CVA6 config file
# declares `package cva6_config_pkg`, so naming two is a duplicate-package error
# and naming the wrong one silently builds a different machine.
export VERILOG_FILES = /work/domains/comp_arch/design/d_ca05_miss_handler_arb/spec/miss_handler_arb_pkg.sv \
                       /work/refs/axi/src/axi_pkg.sv \
                       /work/refs/cva6/core/include/riscv_pkg.sv \
                       /work/refs/cva6/core/include/config_pkg.sv \
                       /work/refs/cva6/core/include/cv64a6_imafdc_sv39_config_pkg.sv \
                       /work/refs/cva6/core/include/build_config_pkg.sv \
                       /work/refs/cva6/core/include/ariane_pkg.sv \
                       /work/refs/cva6/core/include/std_cache_pkg.sv \
                       /work/refs/common_cells/src/lfsr_8bit.sv \
                       /work/refs/cva6/core/cache_subsystem/axi_adapter.sv \
                       /work/refs/cva6/core/cache_subsystem/miss_handler.sv \
                       /work/domains/comp_arch/design/d_ca05_miss_handler_arb/ref/miss_handler_arb_ref.sv

export SDC_FILE      = /work/domains/comp_arch/design/d_ca05_miss_handler_arb/orfs/constraint.sdc

# ABC's mapping target, derived from this task's own SDC. Without this line
# ppa_candidate.sh REFUSES to build any candidate (scripts/ppa_candidate.sh:152,
# the F24 guard): it copies this line into the generated candidate config so the
# candidate is mapped against the SAME ABC target as the reference.
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk '/^set clk_period/{printf "%d", $$3*1000; exit}' $(SDC_FILE))

export VERILOG_INCLUDE_DIRS = /work/refs/common_cells/include

# NO AREA FIGURE IS RECORDED, and the absence is deliberate. d_ca03's config.mk
# carries a measured 190,561 um^2; this task has no synthesis figure of any kind.
# The ORFS container is Agent 1's and I have not run it, and spec G1 forbids
# reporting PPA until the reference Fmax sweep sets the pinned period.
