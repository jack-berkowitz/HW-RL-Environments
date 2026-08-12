# Design-local replacement for platforms/sky130hd/fastroute.tcl.
#
# WHY THIS FILE EXISTS
#   ncache is routability-limited rather than area-limited: it global-routes at
#   ~73% average layer usage and ~24% cell utilization, yet still overflows a
#   handful of gcells by one or two tracks. After PLACE_DENSITY was dropped to
#   0.30 the residual was 15 overflowing gcell-layers (9 on met2, 6 on met4),
#   and GRT's own advice was:
#       [WARNING GRT-0704] Try reduce the layer adjustment from 20% to 14%
#
#   That 20% is HARD-CODED as `0.2` in platforms/sky130hd/fastroute.tcl. It is
#   NOT reachable through the ROUTING_LAYER_ADJUSTMENT variable: scripts/
#   floorplan.tcl sources FASTROUTE_TCL when it is set and only falls back to
#   set_global_routing_layer_adjustment/ROUTING_LAYER_ADJUSTMENT when it is not,
#   and sky130hd/config.mk sets FASTROUTE_TCL by default. Setting the variable
#   in config.mk is silently ignored on this platform.
#
#   Emptying FASTROUTE_TCL to reach that fallback is not equivalent either: the
#   fallback sets only `-signal` routing layers, so it would drop the
#   `-clock met3-met5` restriction below and let the 274 clock nets route on
#   met1/met2. Replacing the file keeps every other setting identical and
#   changes exactly one number.
#
# THE NUMBER
#   0.12, just under the 14% GRT computed, for margin. This derate reserves
#   capacity for detailed routing, so lowering it trades global-route success
#   against detailed-route risk -- if 5_2_route (DRT) starts failing or thrashing
#   on antenna/DRC, raise this back toward 0.2 rather than lowering it further.
#   variables.yaml suggests bisecting from 0.10 if more exploration is needed.
#
# NOTE FOR PPA COMPARISONS
#   This is a per-design deviation from the platform default. Any PPA number
#   produced with it is not directly comparable to a design built with the stock
#   0.2 unless that design gets the same treatment.

set_global_routing_layer_adjustment \
    $::env(MIN_ROUTING_LAYER)-$::env(MAX_ROUTING_LAYER) 0.12

set_routing_layers -clock  $::env(MIN_CLK_ROUTING_LAYER)-$::env(MAX_ROUTING_LAYER)
set_routing_layers -signal $::env(MIN_ROUTING_LAYER)-$::env(MAX_ROUTING_LAYER)
