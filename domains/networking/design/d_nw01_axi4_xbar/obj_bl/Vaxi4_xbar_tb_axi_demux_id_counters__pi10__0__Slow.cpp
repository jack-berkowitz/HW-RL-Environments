// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___ctor_var_reset(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___ctor_var_reset\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->__PVT__clk_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11908517815223722933ull);
    vlSelf->__PVT__rst_ni = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3161515032326629241ull);
    vlSelf->__PVT__lookup_axi_id_i = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 6174215947457116094ull);
    vlSelf->__PVT__lookup_mst_select_o = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 12675257972778877153ull);
    vlSelf->__PVT__lookup_mst_select_occupied_o = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15074005385133559292ull);
    vlSelf->__PVT__full_o = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6064445919729732869ull);
    vlSelf->__PVT__push_axi_id_i = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 12393835014276854626ull);
    vlSelf->__PVT__push_mst_select_i = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 7045807418057150243ull);
    vlSelf->__PVT__push_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11480269964481196755ull);
    vlSelf->__PVT__inject_axi_id_i = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7740952722679919407ull);
    vlSelf->__PVT__inject_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1472618394025244678ull);
    vlSelf->__PVT__pop_axi_id_i = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 9139569235965395553ull);
    vlSelf->__PVT__pop_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13879259752587937209ull);
    vlSelf->__PVT__any_outstanding_trx_o = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1489123247604329937ull);
    vlSelf->__PVT__mst_select_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10577836586488208451ull);
    vlSelf->__PVT__push_en = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 11988914856272675127ull);
    vlSelf->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8284141982876759501ull);
    vlSelf->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8226178979814516339ull);
    vlSelf->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 17969224325596236558ull);
    vlSelf->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 11562101479957454086ull);
    vlSelf->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 6619877393431866619ull);
    vlSelf->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 4158808518203628673ull);
    vlSelf->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 5216183386390035858ull);
    vlSelf->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3108116741194587185ull);
    vlSelf->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 16103592369677062426ull);
    vlSelf->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 11209831983428324492ull);
    vlSelf->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 10671778098270438496ull);
    vlSelf->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 13701218432223009016ull);
    vlSelf->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 6506916281851335157ull);
    vlSelf->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7792433425890853477ull);
    vlSelf->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 10041459783035520288ull);
    vlSelf->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 14755942851582119042ull);
    vlSelf->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 5203349113766531281ull);
    vlSelf->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 10736043972926092897ull);
    vlSelf->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 14984154158446306974ull);
    vlSelf->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 2819906972207176801ull);
    vlSelf->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 4217176113452834456ull);
    vlSelf->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 4989369006811519385ull);
    vlSelf->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 13970098524971577833ull);
    vlSelf->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 5970066094286061893ull);
    vlSelf->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7540587345518651298ull);
    vlSelf->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 12955485477190245552ull);
    vlSelf->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 4730475514342419730ull);
    vlSelf->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8362308419361148770ull);
    vlSelf->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 11651693277601054870ull);
    vlSelf->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3116266917357071662ull);
    vlSelf->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 1574616096267498571ull);
    vlSelf->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 4019131841751117394ull);
}
