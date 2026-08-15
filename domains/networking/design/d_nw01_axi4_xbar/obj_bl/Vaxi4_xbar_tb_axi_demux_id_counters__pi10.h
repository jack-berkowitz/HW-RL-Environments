// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxi4_xbar_tb.h for the primary calling header

#ifndef VERILATED_VAXI4_XBAR_TB_AXI_DEMUX_ID_COUNTERS__PI10_H_
#define VERILATED_VAXI4_XBAR_TB_AXI_DEMUX_ID_COUNTERS__PI10_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vaxi4_xbar_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxi4_xbar_tb_axi_demux_id_counters__pi10 final {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ __PVT__clk_i;
    CData/*0:0*/ __PVT__rst_ni;
    CData/*3:0*/ __PVT__lookup_axi_id_i;
    CData/*1:0*/ __PVT__lookup_mst_select_o;
    CData/*0:0*/ __PVT__lookup_mst_select_occupied_o;
    CData/*0:0*/ __PVT__full_o;
    CData/*3:0*/ __PVT__push_axi_id_i;
    CData/*1:0*/ __PVT__push_mst_select_i;
    CData/*0:0*/ __PVT__push_i;
    CData/*3:0*/ __PVT__inject_axi_id_i;
    CData/*0:0*/ __PVT__inject_i;
    CData/*3:0*/ __PVT__pop_axi_id_i;
    CData/*0:0*/ __PVT__pop_i;
    CData/*0:0*/ __PVT__any_outstanding_trx_o;
    IData/*31:0*/ __PVT__mst_select_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    CData/*3:0*/ __PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q;
    CData/*3:0*/ __PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
    SData/*15:0*/ __PVT__push_en;

    // INTERNAL VARIABLES
    Vaxi4_xbar_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vaxi4_xbar_tb_axi_demux_id_counters__pi10();
    ~Vaxi4_xbar_tb_axi_demux_id_counters__pi10();
    void ctor(Vaxi4_xbar_tb__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(Vaxi4_xbar_tb_axi_demux_id_counters__pi10);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
