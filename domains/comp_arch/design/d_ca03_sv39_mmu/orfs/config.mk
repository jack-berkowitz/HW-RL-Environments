# ORFS design config for d_ca03 sv39_mmu.
#
# ONE CONFIGURATION. Unlike d_dsp03 or d_ai01 this task does not parameterise
# geometry: P1 pins Sv39 with XLEN=64, and P2 pins the translation storage at
# 16+16 fully-associative entries with no second level. There is nothing for a
# scored_configuration to select between, and nothing here can drift from it.
export PLATFORM        = sky130hd
export DESIGN_NAME     = sv39_mmu
export DESIGN_NICKNAME = d_ca03_sv39_mmu

# FLOORPLAN AND PLACEMENT, matching every other design task in this repo.
# Without CORE_UTILIZATION or an explicit DIE_AREA/CORE_AREA, ORFS stops at
# `No floorplan initialization method specified` and dies at do-2_1_floorplan,
# which is what a reference Fmax sweep on the raw task config hits. It never
# surfaced because this task's recorded area is a synthesis figure taken after
# synth+abc -- nothing had ever asked this config to place anything.
#
# Values are the other tasks' verbatim, not chosen for this design: a floorplan
# target picked per-task would make area incomparable across the corpus, the same
# reason SYNTH_MEMORY_MAX_BITS had to match. This file is NOT part of
# task_text_hash (which covers spec/ and PASTE.md), so adding these does not
# change the task text or invalidate any solicitation.
export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100

export SYNTH_HDL_FRONTEND = slang

# The dependency closure, EXPLICIT and in order, packages first. slang does not
# search library directories the way Verilator's -y does.
#
# EXTRACTED, NOT ASSEMBLED BY HAND: this is Verilator's own dependency output for
# the elaborated hierarchy, so it is what the design actually reads rather than
# what I believed it reads. VERIFIED by running read_slang with exactly this
# list, --top sv39_mmu, in openroad/orfs:latest -- clean, 0.61 s, 108 MB peak.
#
# TWO ENTRIES THAT ARE EASY TO MISS, recorded so the next reader does not
# rediscover them:
#   * pmp.sv and pmp_entry.sv live under core/pmp/src/, not with the MMU. The
#     walker instantiates pmp directly (cva6_ptw.sv:250) -- PMP is IN the page
#     walk path, which is why spec A8 exists.
#   * ONLY cv64a6_imafdc_sv39_config_pkg.sv may be listed. Every CVA6 config
#     file declares `package cva6_config_pkg`, so naming two of them is a
#     duplicate-package error, and naming the wrong one silently builds a
#     different machine -- `imafdch` would enable the hypervisor extension.
#
# TWO SHIM FILES, and the order matters. sv39_mmu_ref.sv declares
# `sv39_mmu_ref_inner`; sv39_mmu_top.sv declares the contract name `sv39_mmu`
# and instantiates it. The split lets the controls in controls/ wrap the
# reference without a module-name collision -- a control build compiles the
# control plus the inner file and leaves the top out.
export VERILOG_FILES = /work/refs/common_cells/src/cf_math_pkg.sv \
                       /work/refs/cva6/core/include/riscv_pkg.sv \
                       /work/refs/cva6/core/include/config_pkg.sv \
                       /work/refs/cva6/core/include/cv64a6_imafdc_sv39_config_pkg.sv \
                       /work/refs/cva6/core/include/build_config_pkg.sv \
                       /work/refs/cva6/core/include/ariane_pkg.sv \
                       /work/refs/common_cells/src/lzc.sv \
                       /work/refs/common_cells/src/lfsr.sv \
                       /work/refs/cva6/core/pmp/src/pmp_entry.sv \
                       /work/refs/cva6/core/pmp/src/pmp.sv \
                       /work/refs/cva6/core/cva6_mmu/cva6_tlb.sv \
                       /work/refs/cva6/core/cva6_mmu/cva6_shared_tlb.sv \
                       /work/refs/cva6/core/cva6_mmu/cva6_ptw.sv \
                       /work/refs/cva6/core/cva6_mmu/cva6_mmu.sv \
                       /work/domains/comp_arch/design/d_ca03_sv39_mmu/ref/sv39_mmu_ref.sv \
                       /work/domains/comp_arch/design/d_ca03_sv39_mmu/ref/sv39_mmu_top.sv

export SDC_FILE      = /work/domains/comp_arch/design/d_ca03_sv39_mmu/orfs/constraint.sdc

# The include path is the TOP-LEVEL refs/common_cells/include. cva6 and
# common_cells both `include "common_cells/registers.svh"`.
export VERILOG_INCLUDE_DIRS = /work/refs/common_cells/include

# AREA, measured, for whoever schedules this: 190,561 um^2 at sky130hd after
# synth+abc, of which 86,744 (45.5%) is the 3,467 flip-flops that P2's pinned
# storage requires. That is about an eighth of d_ai01 and well inside the
# envelope this repository has already built -- d_nw01_axi4_xbar at 2.09 mm^2 is
# the largest. No geometry cap is needed here.
