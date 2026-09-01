# ORFS design config for d_ca06 queue.
#
# The reference is self-contained -- no vendored RTL, no include paths. It is
# the only design task in the corpus with no anchor: the contract was written
# from a hand-authored implementation rather than derived from an upstream one.
export PLATFORM        = sky130hd
export DESIGN_NAME     = queue
export DESIGN_NICKNAME = d_ca06_multiport_queue

export VERILOG_FILES = /work/domains/comp_arch/design/d_ca06_multiport_queue/ref/multiport_queue_ref.sv
export SDC_FILE      = /work/domains/comp_arch/design/d_ca06_multiport_queue/orfs/constraint.sdc

export SYNTH_HDL_FRONTEND = slang

# SCORED GEOMETRY, and it is pinned because it IS the area. The storage array is
# DEPTH x $bits(T) flip-flops and the read path is PORTS muxes across all of it,
# so both axes move area and delay directly. A baseline at another geometry
# answers a different question.
#
# PTR_WIDTH=4 (DEPTH=16), T=logic[31:0], PORTS=3, rather than the module's own
# defaults of 7 and 64: those give 8,192 storage flops and three 128:1 64-bit
# muxes, which is a place-and-route of a memory rather than a measurement of a
# queue. The checker covers the wider geometries; the PPA point is the small one.
#
# PINNED HERE, by the standard mechanism. The first version could not do this:
# `T` was a type parameter and VERILOG_TOP_PARAMS sets VALUE parameters only, so
# the geometry lived in a synthesis shim and DESIGN_NAME was the shim rather
# than the DUT. That broke the sweep's correctness gate, which resolves the
# reference by finding the file declaring DESIGN_NAME -- it found the shim,
# whose module the testbench does not instantiate.
#
# Deriving T from a value parameter DW removes the shim entirely and lets
# DESIGN_NAME be the module candidates actually write.
export VERILOG_TOP_PARAMS = PTR_WIDTH 4 DW 32 PORTS 3

export CORE_UTILIZATION = 10
export PLACE_DENSITY    = 0.50
export TNS_END_PERCENT  = 100

# Picoseconds, threaded from the same env var the SDC reads so the synthesis
# hint and the timing constraint cannot diverge (F24).
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk -v ovr="$$CLK_PERIOD_NS" '/^set clk_period/{p=$$3} END{if(ovr!="") p=ovr; printf "%d", p*1000}' $(SDC_FILE))
