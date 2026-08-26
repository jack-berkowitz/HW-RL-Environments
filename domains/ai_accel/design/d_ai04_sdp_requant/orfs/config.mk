# ORFS design config for d_ai04 sdp_requant.
#
# ONE CONFIGURATION, and one BY CONSTRUCTION rather than by omission. sdp_requant
# declares NO PARAMETERS: spec P1 pins four lanes and the 16b/32b lane widths,
# and every other axis -- cfg_precision, cfg_offset, cfg_scale, cfg_truncate,
# cfg_bypass, cfg_nan_to_zero -- is a runtime INPUT, swept by the stimulus rather
# than by elaboration. There is nothing for a scored_configuration to select
# between and nothing here that can drift from it.
export PLATFORM        = sky130hd
export DESIGN_NAME     = sdp_requant
export DESIGN_NICKNAME = d_ai04_sdp_requant

# FLOORPLAN AND PLACEMENT, the other design tasks' values VERBATIM and not chosen
# for this design. A floorplan target picked per-task would make area
# incomparable across the corpus, which is the same reason SYNTH_MEMORY_MAX_BITS
# had to match. Without CORE_UTILIZATION or an explicit DIE_AREA, ORFS stops at
# `No floorplan initialization method specified` and dies at do-2_1_floorplan.
export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100

export SYNTH_HDL_FRONTEND = slang

# THE CLOSURE IS ONE FILE, and that is the whole point of this anchor choice.
# d_ca03 needs fourteen files in dependency order because cva6_mmu instantiates
# a TLB, a shared TLB, a walker and a PMP. sdp_requant instantiates nothing: no
# vendored modules, no common_cells, no packages, no include path. The NVDLA
# anchor is a MEASUREMENT TARGET and is never built -- it does not appear here.
export VERILOG_FILES = /work/domains/ai_accel/design/d_ai04_sdp_requant/ref/sdp_requant_ref.sv

export SDC_FILE      = /work/domains/ai_accel/design/d_ai04_sdp_requant/orfs/constraint.sdc

# ABC's mapping target, derived from this task's own SDC rather than restating a
# number. Without this line ppa_candidate.sh REFUSES to build any candidate for
# this task (scripts/ppa_candidate.sh:152, the F24 guard): it copies this line
# into the generated candidate config so the candidate is mapped against the SAME
# ABC target as the reference, and with nothing to copy it stops rather than
# assume. That refusal is what blocked d_ca03/chat at 12.5 ns.
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk '/^set clk_period/{printf "%d", $$3*1000; exit}' $(SDC_FILE))

# NO VERILOG_INCLUDE_DIRS. Nothing in this design `include`s anything.
#
# NO ref/*_top.sv SPLIT EITHER, and the reason is worth recording because d_ca03
# needed one. There, controls wrap the reference and would collide on the module
# name, so the reference is split into an inner module plus a top that carries
# the contract name. Here each control in controls/ DECLARES `sdp_requant`
# itself and is compiled INSTEAD OF the reference, never alongside it -- so there
# is no collision to design around.
#
# ---------------------------------------------------------------------------
# NO AREA FIGURE IS RECORDED HERE, and its absence is deliberate.
# ---------------------------------------------------------------------------
# d_ca03's config.mk carries a measured 190,561 um^2 for whoever schedules it.
# This task has NO synthesis figure of any kind: the ORFS container is Agent 1's
# and I have not run it. Spec G1 forbids reporting PPA until the reference Fmax
# sweep sets the pinned period, and that sweep has not been run.
#
# What can be said without building it, as scheduling information only: the
# design is one combinational cone per lane feeding a two-slot buffer, with no
# memory and no vendored closure. The dominant element is a 34x16 signed
# multiply times four lanes. That is structurally far smaller than d_ca03's
# 3,467 pinned flip-flops, so no geometry cap is anticipated -- but ANTICIPATED
# is the correct word and it is not a measurement.
