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
# PIN POSITIONS, NOT DIE AREA. The d_ca05 Fmax sweep aborted in 24 s at
# 3_2_place_iop: PPL-0024, 3,686 IO pins against 3,260 available positions,
# with OpenROAD proposing the die perimeter grow from 3,590.92 to 5,012.96 um.
#
# The interface is genuinely that wide -- 29 port declarations expanding to
# 3,686 bits: four AXI req/rsp structs, cache_line_t [SET_ASSOC-1:0], and three
# [NR_PORTS-1:0][...] arrays. This is an internal cache-module boundary being
# synthesised as if it were a chip boundary.
#
# GROWING THE DIE IS THE WRONG FIX FOR THE RIGHT REASON. sky130hd offers the
# pin placer ONE layer per direction (IO_PLACER_H ?= met3, IO_PLACER_V ?= met2)
# while MAX_ROUTING_LAYER is met5, so met4 and met5 are routable but never
# offered as pin positions. The shortfall is 426 pins, 13%. A second layer per
# direction roughly doubles available positions to ~6,500 against 3,686 needed,
# and leaves the die alone.
#
# Odd layers are horizontal in sky130, even vertical, so the pairs preserve
# preferred routing directions. CORE_UTILIZATION and PLACE_DENSITY are
# UNCHANGED and identical to the eight other tasks at util=10: this touches
# where pins may sit, not how big the die is or how densely it is filled.
#
# This is the only task overriding the pin placer. The asymmetry is deliberate
# and is a placement key, not an area key -- d_ca05's Design area stays
# measured the same way as every other task's. It DOES change
# build_config_hash, so the reference and all three candidates must be built
# under this config for the comparison to be within one configuration (rule 17).
# REVISED after the first attempt placed pins and then failed to route: 55 DRT
# iterations flat at 260 violations, ten consecutive end-of-iteration totals
# identical. Not slow -- not converging.
#
# met5 WAS THE MISTAKE, and the pitch table says why. sky130hd:
#   met2 V 0.46um   met3 H 0.68um   met4 V 0.92um   met5 H 3.40um (width 1.60)
# met5 is a power-distribution layer. On a ~898um edge at 3.4um pitch it
# contributes only ~260 usable positions -- about 8% of what the pair added --
# while consuming the whole top routing layer, and a pin there has nothing
# above it and must drop met4->met3->met2->met1 to reach a cell. met4 supplies
# the actual capacity at ~975. The first version counted positions without
# weighting them by pitch or by escape cost.
export IO_PLACER_H     = met3
export IO_PLACER_V     = met2 met4

# AND MORE PERIMETER, because the violation distribution was UNIFORM across
# met1-met5 (133/128/125/124/121) rather than concentrated on the new layers.
# That reads as global congestion, not a few unroutable pins -- so freeing met5
# alone may not be enough. Perimeter scales as sqrt(1/util): 10 -> 7 gives
# ~1.20x, about 4,290um against the 5,013um OpenROAD asked for, and ~20% more
# positions on every layer including the two that were always there.
#
# design_area_um2 is SUMMED CELL AREA, not die area, so this does not inflate
# the reported metric. It does move it a little through longer wires and more
# buffering, which is the real and smaller cost.
#
# TWO VARIABLES CHANGE AT ONCE AND A SUCCESS WILL NOT ATTRIBUTE CLEANLY. That
# is deliberate: each attempt costs 12.5h, and the evidence for which one is
# binding is a grep of log text rather than a DRC report, because routing never
# finished to write one.
export CORE_UTILIZATION = 7
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

export VERILOG_INCLUDE_DIRS = /work/refs/common_cells/include

# NO AREA FIGURE IS RECORDED, and the absence is deliberate. d_ca03's config.mk
# carries a measured 190,561 um^2; this task has no synthesis figure of any kind.
# The ORFS container is Agent 1's and I have not run it, and spec G1 forbids
# reporting PPA until the reference Fmax sweep sets the pinned period.
