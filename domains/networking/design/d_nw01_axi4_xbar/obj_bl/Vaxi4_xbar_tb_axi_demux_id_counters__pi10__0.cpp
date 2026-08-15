// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__push_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up)
                                 ? (0x0000ffffU & ((IData)(1U) 
                                                   << 
                                                   (0x0000000fU 
                                                    & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                       >> 4U))))
                                 : 0U);
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __PVT__pop_en;
    __PVT__pop_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta = 0;
    // Body
    __PVT__pop_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_7)
                      ? (0x0000ffffU & ((IData)(1U) 
                                        << (0x0000000fU 
                                            & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_91) 
                                               >> 3U))))
                      : 0U);
    if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & (~ (IData)(__PVT__pop_en)));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else if ((1U & (IData)(__PVT__pop_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 1U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 1U;
    } else {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0U;
    }
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down 
        = ((1U & (~ (IData)(vlSelfRef.__PVT__push_en))) 
           && (1U & (IData)(__PVT__pop_en)));
    if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 1U)));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 1U));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 1U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 1U)));
    if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 2U)));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 2U));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 2U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 2U)));
    if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 3U)));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 3U));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 3U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 3U)));
    if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 4U)));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 4U));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 4U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 4U)));
    if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 5U)));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 5U));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 5U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 5U)));
    if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 6U)));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 6U));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 6U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 6U)));
    if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 7U)));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 7U));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 7U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 7U)));
    if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 8U)));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 8U));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 8U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 8U)));
    if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 9U)));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 9U));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 9U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 9U)));
    if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0aU)));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0aU));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0aU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0aU)));
    if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0bU)));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0bU));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0bU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0bU)));
    if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0cU)));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0cU));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0cU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0cU)));
    if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0dU)));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0dU));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0dU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0dU)));
    if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0eU)));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0eU));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0eU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0eU)));
    if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0fU)));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0fU));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0fU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0fU)));
    vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffffcU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select));
        }
        if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffff3U 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 2U));
        }
        if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffffcfU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 4U));
        }
        if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffff3fU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 6U));
        }
        if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffcffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 8U));
        }
        if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffff3ffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000aU));
        }
        if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffcfffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000cU));
        }
        if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffff3fffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000eU));
        }
        if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffcffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000010U));
        }
        if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfff3ffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000012U));
        }
        if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffcfffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000014U));
        }
        if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xff3fffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000016U));
        }
        if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfcffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000018U));
        }
        if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xf3ffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001aU));
        }
        if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xcfffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001cU));
        }
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0x3fffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001eU));
        }
    } else {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__mst_select_q = (0xfffffffcU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffff3U 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffffcfU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffff3fU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffcffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffff3ffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffcfffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffff3fffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffcffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfff3ffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffcfffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xff3fffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfcffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xf3ffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xcfffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0x3fffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
    }
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __PVT__inject_en;
    __PVT__inject_en = 0;
    SData/*15:0*/ __PVT__pop_en;
    __PVT__pop_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta = 0;
    // Body
    vlSelfRef.__PVT__push_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push)
                                 ? (0x0000ffffU & ((IData)(1U) 
                                                   << 
                                                   (0x0000000fU 
                                                    & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                        << 2U) 
                                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                          >> 0x0000001eU)))))
                                 : 0U);
    __PVT__inject_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject)
                         ? (0x0000ffffU & ((IData)(1U) 
                                           << (0x0000000fU 
                                               & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  >> 4U))))
                         : 0U);
    __PVT__pop_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_6)
                      ? (0x0000ffffU & ((IData)(1U) 
                                        << (0x0000000fU 
                                            & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_92[2U] 
                                               >> 4U))))
                      : 0U);
    if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & ((1U & (IData)(__PVT__inject_en)) 
                     || (1U & (~ (IData)(__PVT__pop_en)))));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__inject_en)) ? (
                                                   (1U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((1U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((1U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & (~ (IData)(__PVT__pop_en)));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else if ((1U & (IData)(__PVT__pop_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 1U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 1U;
    } else {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0U;
    }
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down 
        = ((1U & (~ (IData)(vlSelfRef.__PVT__push_en))) 
           && ((1U & (~ (IData)(__PVT__inject_en))) 
               && (1U & (IData)(__PVT__pop_en))));
    if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 1U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 1U)))));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__inject_en)) ? (
                                                   (2U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((2U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((2U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 1U)));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 1U));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 1U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 1U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 1U))));
    if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 2U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 2U)))));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__inject_en)) ? (
                                                   (4U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((4U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((4U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 2U)));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 2U));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 2U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 2U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 2U))));
    if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 3U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 3U)))));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__inject_en)) ? (
                                                   (8U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((8U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((8U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 3U)));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 3U));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 3U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 3U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 3U))));
    if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 4U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 4U)))));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__inject_en))
                ? ((0x00000010U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000010U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000010U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 4U)));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 4U));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 4U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 4U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 4U))));
    if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 5U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 5U)))));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__inject_en))
                ? ((0x00000020U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000020U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000020U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 5U)));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 5U));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 5U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 5U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 5U))));
    if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 6U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 6U)))));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__inject_en))
                ? ((0x00000040U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000040U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000040U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 6U)));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 6U));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 6U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 6U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 6U))));
    if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 7U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 7U)))));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__inject_en))
                ? ((0x00000080U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000080U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000080U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 7U)));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 7U));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 7U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 7U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 7U))));
    if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 8U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 8U)))));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__inject_en))
                ? ((0x00000100U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000100U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000100U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 8U)));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 8U));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 8U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 8U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 8U))));
    if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 9U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 9U)))));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__inject_en))
                ? ((0x00000200U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000200U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000200U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 9U)));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 9U));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 9U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 9U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 9U))));
    if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0aU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0aU)))));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__inject_en))
                ? ((0x00000400U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000400U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000400U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0aU)));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0aU));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0aU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0aU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0aU))));
    if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0bU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0bU)))));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__inject_en))
                ? ((0x00000800U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000800U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000800U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0bU)));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0bU));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0bU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0bU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0bU))));
    if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0cU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0cU)))));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__inject_en))
                ? ((0x00001000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00001000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00001000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0cU)));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0cU));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0cU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0cU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0cU))));
    if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0dU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0dU)))));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__inject_en))
                ? ((0x00002000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00002000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00002000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0dU)));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0dU));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0dU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0dU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0dU))));
    if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0eU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0eU)))));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__inject_en))
                ? ((0x00004000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00004000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00004000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0eU)));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0eU));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0eU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0eU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0eU))));
    if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0fU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0fU)))));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__inject_en))
                ? ((0x00008000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00008000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00008000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0fU)));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0fU));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0fU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0fU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0fU))));
    vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffffcU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select));
        }
        if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffff3U 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 2U));
        }
        if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffffcfU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 4U));
        }
        if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffff3fU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 6U));
        }
        if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffcffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 8U));
        }
        if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffff3ffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000aU));
        }
        if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffcfffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000cU));
        }
        if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffff3fffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000eU));
        }
        if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffcffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000010U));
        }
        if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfff3ffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000012U));
        }
        if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffcfffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000014U));
        }
        if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xff3fffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000016U));
        }
        if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfcffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000018U));
        }
        if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xf3ffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001aU));
        }
        if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xcfffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001cU));
        }
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0x3fffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001eU));
        }
    } else {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__mst_select_q = (0xfffffffcU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffff3U 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffffcfU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffff3fU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffcffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffff3ffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffcfffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffff3fffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffcffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfff3ffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffcfffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xff3fffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfcffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xf3ffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xcfffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0x3fffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
    }
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__push_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up)
                                 ? (0x0000ffffU & ((IData)(1U) 
                                                   << 
                                                   (0x0000000fU 
                                                    & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                       >> 4U))))
                                 : 0U);
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __PVT__pop_en;
    __PVT__pop_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta = 0;
    // Body
    __PVT__pop_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_5)
                      ? (0x0000ffffU & ((IData)(1U) 
                                        << (0x0000000fU 
                                            & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_89) 
                                               >> 3U))))
                      : 0U);
    if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & (~ (IData)(__PVT__pop_en)));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else if ((1U & (IData)(__PVT__pop_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 1U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 1U;
    } else {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0U;
    }
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down 
        = ((1U & (~ (IData)(vlSelfRef.__PVT__push_en))) 
           && (1U & (IData)(__PVT__pop_en)));
    if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 1U)));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 1U));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 1U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 1U)));
    if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 2U)));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 2U));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 2U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 2U)));
    if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 3U)));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 3U));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 3U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 3U)));
    if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 4U)));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 4U));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 4U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 4U)));
    if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 5U)));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 5U));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 5U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 5U)));
    if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 6U)));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 6U));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 6U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 6U)));
    if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 7U)));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 7U));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 7U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 7U)));
    if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 8U)));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 8U));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 8U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 8U)));
    if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 9U)));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 9U));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 9U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 9U)));
    if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0aU)));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0aU));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0aU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0aU)));
    if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0bU)));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0bU));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0bU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0bU)));
    if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0cU)));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0cU));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0cU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0cU)));
    if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0dU)));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0dU));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0dU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0dU)));
    if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0eU)));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0eU));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0eU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0eU)));
    if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0fU)));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0fU));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0fU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0fU)));
    vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffffcU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select));
        }
        if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffff3U 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 2U));
        }
        if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffffcfU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 4U));
        }
        if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffff3fU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 6U));
        }
        if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffcffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 8U));
        }
        if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffff3ffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000aU));
        }
        if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffcfffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000cU));
        }
        if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffff3fffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000eU));
        }
        if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffcffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000010U));
        }
        if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfff3ffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000012U));
        }
        if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffcfffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000014U));
        }
        if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xff3fffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000016U));
        }
        if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfcffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000018U));
        }
        if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xf3ffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001aU));
        }
        if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xcfffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001cU));
        }
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0x3fffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001eU));
        }
    } else {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__mst_select_q = (0xfffffffcU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffff3U 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffffcfU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffff3fU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffcffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffff3ffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffcfffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffff3fffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffcffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfff3ffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffcfffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xff3fffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfcffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xf3ffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xcfffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0x3fffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
    }
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __PVT__inject_en;
    __PVT__inject_en = 0;
    SData/*15:0*/ __PVT__pop_en;
    __PVT__pop_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta = 0;
    // Body
    vlSelfRef.__PVT__push_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push)
                                 ? (0x0000ffffU & ((IData)(1U) 
                                                   << 
                                                   (0x0000000fU 
                                                    & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                        << 2U) 
                                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                          >> 0x0000001eU)))))
                                 : 0U);
    __PVT__inject_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject)
                         ? (0x0000ffffU & ((IData)(1U) 
                                           << (0x0000000fU 
                                               & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  >> 4U))))
                         : 0U);
    __PVT__pop_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_4)
                      ? (0x0000ffffU & ((IData)(1U) 
                                        << (0x0000000fU 
                                            & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_90[2U] 
                                               >> 4U))))
                      : 0U);
    if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & ((1U & (IData)(__PVT__inject_en)) 
                     || (1U & (~ (IData)(__PVT__pop_en)))));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__inject_en)) ? (
                                                   (1U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((1U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((1U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & (~ (IData)(__PVT__pop_en)));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else if ((1U & (IData)(__PVT__pop_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 1U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 1U;
    } else {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0U;
    }
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down 
        = ((1U & (~ (IData)(vlSelfRef.__PVT__push_en))) 
           && ((1U & (~ (IData)(__PVT__inject_en))) 
               && (1U & (IData)(__PVT__pop_en))));
    if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 1U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 1U)))));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__inject_en)) ? (
                                                   (2U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((2U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((2U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 1U)));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 1U));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 1U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 1U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 1U))));
    if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 2U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 2U)))));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__inject_en)) ? (
                                                   (4U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((4U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((4U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 2U)));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 2U));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 2U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 2U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 2U))));
    if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 3U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 3U)))));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__inject_en)) ? (
                                                   (8U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((8U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((8U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 3U)));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 3U));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 3U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 3U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 3U))));
    if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 4U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 4U)))));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__inject_en))
                ? ((0x00000010U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000010U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000010U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 4U)));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 4U));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 4U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 4U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 4U))));
    if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 5U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 5U)))));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__inject_en))
                ? ((0x00000020U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000020U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000020U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 5U)));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 5U));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 5U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 5U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 5U))));
    if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 6U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 6U)))));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__inject_en))
                ? ((0x00000040U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000040U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000040U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 6U)));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 6U));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 6U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 6U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 6U))));
    if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 7U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 7U)))));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__inject_en))
                ? ((0x00000080U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000080U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000080U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 7U)));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 7U));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 7U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 7U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 7U))));
    if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 8U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 8U)))));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__inject_en))
                ? ((0x00000100U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000100U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000100U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 8U)));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 8U));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 8U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 8U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 8U))));
    if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 9U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 9U)))));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__inject_en))
                ? ((0x00000200U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000200U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000200U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 9U)));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 9U));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 9U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 9U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 9U))));
    if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0aU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0aU)))));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__inject_en))
                ? ((0x00000400U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000400U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000400U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0aU)));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0aU));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0aU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0aU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0aU))));
    if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0bU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0bU)))));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__inject_en))
                ? ((0x00000800U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000800U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000800U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0bU)));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0bU));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0bU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0bU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0bU))));
    if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0cU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0cU)))));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__inject_en))
                ? ((0x00001000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00001000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00001000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0cU)));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0cU));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0cU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0cU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0cU))));
    if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0dU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0dU)))));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__inject_en))
                ? ((0x00002000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00002000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00002000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0dU)));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0dU));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0dU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0dU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0dU))));
    if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0eU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0eU)))));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__inject_en))
                ? ((0x00004000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00004000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00004000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0eU)));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0eU));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0eU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0eU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0eU))));
    if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0fU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0fU)))));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__inject_en))
                ? ((0x00008000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00008000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00008000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0fU)));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0fU));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0fU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0fU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0fU))));
    vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffffcU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select));
        }
        if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffff3U 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 2U));
        }
        if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffffcfU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 4U));
        }
        if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffff3fU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 6U));
        }
        if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffcffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 8U));
        }
        if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffff3ffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000aU));
        }
        if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffcfffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000cU));
        }
        if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffff3fffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000eU));
        }
        if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffcffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000010U));
        }
        if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfff3ffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000012U));
        }
        if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffcfffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000014U));
        }
        if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xff3fffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000016U));
        }
        if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfcffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000018U));
        }
        if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xf3ffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001aU));
        }
        if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xcfffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001cU));
        }
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0x3fffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001eU));
        }
    } else {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__mst_select_q = (0xfffffffcU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffff3U 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffffcfU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffff3fU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffcffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffff3ffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffcfffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffff3fffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffcffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfff3ffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffcfffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xff3fffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfcffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xf3ffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xcfffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0x3fffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
    }
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__push_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up)
                                 ? (0x0000ffffU & ((IData)(1U) 
                                                   << 
                                                   (0x0000000fU 
                                                    & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                       >> 4U))))
                                 : 0U);
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __PVT__pop_en;
    __PVT__pop_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta = 0;
    // Body
    __PVT__pop_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_3)
                      ? (0x0000ffffU & ((IData)(1U) 
                                        << (0x0000000fU 
                                            & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_87) 
                                               >> 3U))))
                      : 0U);
    if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & (~ (IData)(__PVT__pop_en)));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else if ((1U & (IData)(__PVT__pop_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 1U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 1U;
    } else {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0U;
    }
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down 
        = ((1U & (~ (IData)(vlSelfRef.__PVT__push_en))) 
           && (1U & (IData)(__PVT__pop_en)));
    if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 1U)));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 1U));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 1U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 1U)));
    if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 2U)));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 2U));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 2U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 2U)));
    if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 3U)));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 3U));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 3U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 3U)));
    if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 4U)));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 4U));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 4U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 4U)));
    if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 5U)));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 5U));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 5U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 5U)));
    if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 6U)));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 6U));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 6U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 6U)));
    if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 7U)));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 7U));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 7U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 7U)));
    if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 8U)));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 8U));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 8U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 8U)));
    if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 9U)));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 9U));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 9U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 9U)));
    if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0aU)));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0aU));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0aU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0aU)));
    if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0bU)));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0bU));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0bU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0bU)));
    if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0cU)));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0cU));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0cU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0cU)));
    if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0dU)));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0dU));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0dU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0dU)));
    if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0eU)));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0eU));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0eU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0eU)));
    if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0fU)));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0fU));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0fU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0fU)));
    vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffffcU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select));
        }
        if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffff3U 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 2U));
        }
        if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffffcfU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 4U));
        }
        if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffff3fU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 6U));
        }
        if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffcffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 8U));
        }
        if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffff3ffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000aU));
        }
        if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffcfffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000cU));
        }
        if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffff3fffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000eU));
        }
        if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffcffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000010U));
        }
        if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfff3ffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000012U));
        }
        if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffcfffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000014U));
        }
        if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xff3fffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000016U));
        }
        if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfcffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000018U));
        }
        if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xf3ffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001aU));
        }
        if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xcfffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001cU));
        }
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0x3fffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001eU));
        }
    } else {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__mst_select_q = (0xfffffffcU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffff3U 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffffcfU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffff3fU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffcffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffff3ffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffcfffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffff3fffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffcffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfff3ffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffcfffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xff3fffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfcffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xf3ffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xcfffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0x3fffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
    }
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __PVT__inject_en;
    __PVT__inject_en = 0;
    SData/*15:0*/ __PVT__pop_en;
    __PVT__pop_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta = 0;
    // Body
    vlSelfRef.__PVT__push_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push)
                                 ? (0x0000ffffU & ((IData)(1U) 
                                                   << 
                                                   (0x0000000fU 
                                                    & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                        << 2U) 
                                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                          >> 0x0000001eU)))))
                                 : 0U);
    __PVT__inject_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject)
                         ? (0x0000ffffU & ((IData)(1U) 
                                           << (0x0000000fU 
                                               & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  >> 4U))))
                         : 0U);
    __PVT__pop_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_2)
                      ? (0x0000ffffU & ((IData)(1U) 
                                        << (0x0000000fU 
                                            & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_88[2U] 
                                               >> 4U))))
                      : 0U);
    if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & ((1U & (IData)(__PVT__inject_en)) 
                     || (1U & (~ (IData)(__PVT__pop_en)))));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__inject_en)) ? (
                                                   (1U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((1U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((1U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & (~ (IData)(__PVT__pop_en)));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else if ((1U & (IData)(__PVT__pop_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 1U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 1U;
    } else {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0U;
    }
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down 
        = ((1U & (~ (IData)(vlSelfRef.__PVT__push_en))) 
           && ((1U & (~ (IData)(__PVT__inject_en))) 
               && (1U & (IData)(__PVT__pop_en))));
    if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 1U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 1U)))));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__inject_en)) ? (
                                                   (2U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((2U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((2U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 1U)));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 1U));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 1U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 1U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 1U))));
    if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 2U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 2U)))));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__inject_en)) ? (
                                                   (4U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((4U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((4U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 2U)));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 2U));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 2U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 2U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 2U))));
    if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 3U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 3U)))));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__inject_en)) ? (
                                                   (8U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((8U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((8U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 3U)));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 3U));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 3U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 3U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 3U))));
    if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 4U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 4U)))));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__inject_en))
                ? ((0x00000010U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000010U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000010U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 4U)));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 4U));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 4U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 4U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 4U))));
    if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 5U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 5U)))));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__inject_en))
                ? ((0x00000020U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000020U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000020U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 5U)));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 5U));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 5U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 5U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 5U))));
    if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 6U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 6U)))));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__inject_en))
                ? ((0x00000040U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000040U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000040U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 6U)));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 6U));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 6U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 6U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 6U))));
    if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 7U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 7U)))));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__inject_en))
                ? ((0x00000080U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000080U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000080U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 7U)));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 7U));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 7U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 7U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 7U))));
    if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 8U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 8U)))));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__inject_en))
                ? ((0x00000100U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000100U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000100U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 8U)));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 8U));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 8U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 8U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 8U))));
    if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 9U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 9U)))));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__inject_en))
                ? ((0x00000200U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000200U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000200U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 9U)));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 9U));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 9U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 9U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 9U))));
    if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0aU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0aU)))));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__inject_en))
                ? ((0x00000400U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000400U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000400U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0aU)));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0aU));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0aU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0aU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0aU))));
    if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0bU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0bU)))));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__inject_en))
                ? ((0x00000800U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000800U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000800U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0bU)));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0bU));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0bU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0bU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0bU))));
    if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0cU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0cU)))));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__inject_en))
                ? ((0x00001000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00001000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00001000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0cU)));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0cU));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0cU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0cU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0cU))));
    if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0dU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0dU)))));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__inject_en))
                ? ((0x00002000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00002000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00002000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0dU)));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0dU));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0dU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0dU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0dU))));
    if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0eU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0eU)))));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__inject_en))
                ? ((0x00004000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00004000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00004000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0eU)));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0eU));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0eU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0eU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0eU))));
    if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0fU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0fU)))));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__inject_en))
                ? ((0x00008000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00008000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00008000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0fU)));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0fU));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0fU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0fU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0fU))));
    vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffffcU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select));
        }
        if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffff3U 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 2U));
        }
        if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffffcfU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 4U));
        }
        if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffff3fU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 6U));
        }
        if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffcffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 8U));
        }
        if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffff3ffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000aU));
        }
        if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffcfffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000cU));
        }
        if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffff3fffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000eU));
        }
        if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffcffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000010U));
        }
        if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfff3ffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000012U));
        }
        if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffcfffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000014U));
        }
        if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xff3fffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000016U));
        }
        if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfcffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000018U));
        }
        if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xf3ffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001aU));
        }
        if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xcfffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001cU));
        }
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0x3fffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001eU));
        }
    } else {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__mst_select_q = (0xfffffffcU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffff3U 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffffcfU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffff3fU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffcffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffff3ffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffcfffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffff3fffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffcffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfff3ffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffcfffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xff3fffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfcffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xf3ffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xcfffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0x3fffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
    }
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__push_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up)
                                 ? (0x0000ffffU & ((IData)(1U) 
                                                   << 
                                                   (0x0000000fU 
                                                    & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                       >> 4U))))
                                 : 0U);
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __PVT__pop_en;
    __PVT__pop_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta = 0;
    // Body
    __PVT__pop_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_1)
                      ? (0x0000ffffU & ((IData)(1U) 
                                        << (0x0000000fU 
                                            & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_93) 
                                               >> 3U))))
                      : 0U);
    if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & (~ (IData)(__PVT__pop_en)));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else if ((1U & (IData)(__PVT__pop_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 1U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 1U;
    } else {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0U;
    }
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down 
        = ((1U & (~ (IData)(vlSelfRef.__PVT__push_en))) 
           && (1U & (IData)(__PVT__pop_en)));
    if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 1U)));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 1U));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 1U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 1U)));
    if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 2U)));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 2U));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 2U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 2U)));
    if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 3U)));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 3U));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 3U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 3U)));
    if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 4U)));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 4U));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 4U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 4U)));
    if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 5U)));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 5U));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 5U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 5U)));
    if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 6U)));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 6U));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 6U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 6U)));
    if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 7U)));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 7U));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 7U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 7U)));
    if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 8U)));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 8U));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 8U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 8U)));
    if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 9U)));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 9U));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 9U))) && (1U & ((IData)(__PVT__pop_en) 
                                        >> 9U)));
    if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0aU)));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0aU));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0aU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0aU)));
    if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0bU)));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0bU));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0bU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0bU)));
    if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0cU)));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0cU));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0cU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0cU)));
    if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0dU)));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0dU));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0dU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0dU)));
    if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0eU)));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0eU));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0eU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0eU)));
    if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0fU)));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0fU));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0fU))) && (1U & ((IData)(__PVT__pop_en) 
                                           >> 0x0fU)));
    vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffffcU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select));
        }
        if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffff3U 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 2U));
        }
        if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffffcfU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 4U));
        }
        if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffff3fU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 6U));
        }
        if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffcffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 8U));
        }
        if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffff3ffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000aU));
        }
        if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffcfffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000cU));
        }
        if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffff3fffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000000eU));
        }
        if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffcffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000010U));
        }
        if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfff3ffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000012U));
        }
        if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffcfffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000014U));
        }
        if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xff3fffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000016U));
        }
        if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfcffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x00000018U));
        }
        if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xf3ffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001aU));
        }
        if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xcfffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001cU));
        }
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0x3fffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_aw_select) 
                                                << 0x0000001eU));
        }
    } else {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__mst_select_q = (0xfffffffcU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffff3U 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffffcfU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffff3fU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffcffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffff3ffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffcfffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffff3fffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffcffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfff3ffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffcfffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xff3fffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfcffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xf3ffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xcfffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0x3fffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
    }
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __PVT__inject_en;
    __PVT__inject_en = 0;
    SData/*15:0*/ __PVT__pop_en;
    __PVT__pop_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_en;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_en = 0;
    CData/*0:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_down;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down = 0;
    CData/*2:0*/ __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta;
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta = 0;
    // Body
    vlSelfRef.__PVT__push_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push)
                                 ? (0x0000ffffU & ((IData)(1U) 
                                                   << 
                                                   (0x0000000fU 
                                                    & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                        << 2U) 
                                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                          >> 0x0000001eU)))))
                                 : 0U);
    __PVT__inject_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject)
                         ? (0x0000ffffU & ((IData)(1U) 
                                           << (0x0000000fU 
                                               & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  >> 4U))))
                         : 0U);
    __PVT__pop_en = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_0)
                      ? (0x0000ffffU & ((IData)(1U) 
                                        << (0x0000000fU 
                                            & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_94[2U] 
                                               >> 4U))))
                      : 0U);
    if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & ((1U & (IData)(__PVT__inject_en)) 
                     || (1U & (~ (IData)(__PVT__pop_en)))));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__inject_en)) ? (
                                                   (1U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((1U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((1U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en 
            = (1U & (~ (IData)(__PVT__pop_en)));
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta 
            = ((1U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else if ((1U & (IData)(__PVT__pop_en))) {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 1U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 1U;
    } else {
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_en = 0U;
        __PVT__gen_counters__BRA__0__KET____DOT__cnt_delta = 0U;
    }
    __PVT__gen_counters__BRA__0__KET____DOT__cnt_down 
        = ((1U & (~ (IData)(vlSelfRef.__PVT__push_en))) 
           && ((1U & (~ (IData)(__PVT__inject_en))) 
               && (1U & (IData)(__PVT__pop_en))));
    if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 1U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 1U)))));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__inject_en)) ? (
                                                   (2U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((2U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((2U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 1U)));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 1U));
        __PVT__gen_counters__BRA__1__KET____DOT__cnt_delta 
            = ((2U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__1__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 1U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 1U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 1U))));
    if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 2U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 2U)))));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__inject_en)) ? (
                                                   (4U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((4U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((4U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 2U)));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 2U));
        __PVT__gen_counters__BRA__2__KET____DOT__cnt_delta 
            = ((4U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__2__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 2U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 2U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 2U))));
    if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 3U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 3U)))));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__inject_en)) ? (
                                                   (8U 
                                                    & (IData)(__PVT__pop_en))
                                                    ? 1U
                                                    : 2U)
                : ((8U & (IData)(__PVT__pop_en)) ? 0U
                    : 1U));
    } else if ((8U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 3U)));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 3U));
        __PVT__gen_counters__BRA__3__KET____DOT__cnt_delta 
            = ((8U & (IData)(__PVT__pop_en)) ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__3__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 3U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 3U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 3U))));
    if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 4U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 4U)))));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__inject_en))
                ? ((0x00000010U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000010U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000010U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 4U)));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 4U));
        __PVT__gen_counters__BRA__4__KET____DOT__cnt_delta 
            = ((0x00000010U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__4__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 4U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 4U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 4U))));
    if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 5U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 5U)))));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__inject_en))
                ? ((0x00000020U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000020U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000020U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 5U)));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 5U));
        __PVT__gen_counters__BRA__5__KET____DOT__cnt_delta 
            = ((0x00000020U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__5__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 5U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 5U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 5U))));
    if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 6U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 6U)))));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__inject_en))
                ? ((0x00000040U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000040U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000040U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 6U)));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 6U));
        __PVT__gen_counters__BRA__6__KET____DOT__cnt_delta 
            = ((0x00000040U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__6__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 6U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 6U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 6U))));
    if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 7U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 7U)))));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__inject_en))
                ? ((0x00000080U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000080U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000080U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 7U)));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 7U));
        __PVT__gen_counters__BRA__7__KET____DOT__cnt_delta 
            = ((0x00000080U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__7__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 7U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 7U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 7U))));
    if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 8U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 8U)))));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__inject_en))
                ? ((0x00000100U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000100U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000100U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 8U)));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 8U));
        __PVT__gen_counters__BRA__8__KET____DOT__cnt_delta 
            = ((0x00000100U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__8__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 8U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 8U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 8U))));
    if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 9U)) || (1U & (~ ((IData)(__PVT__pop_en) 
                                                 >> 9U)))));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__inject_en))
                ? ((0x00000200U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000200U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000200U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 9U)));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 9U));
        __PVT__gen_counters__BRA__9__KET____DOT__cnt_delta 
            = ((0x00000200U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__9__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 9U))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                            >> 9U))) 
                                  && (1U & ((IData)(__PVT__pop_en) 
                                            >> 9U))));
    if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0aU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0aU)))));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__inject_en))
                ? ((0x00000400U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000400U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000400U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0aU)));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0aU));
        __PVT__gen_counters__BRA__10__KET____DOT__cnt_delta 
            = ((0x00000400U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__10__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0aU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0aU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0aU))));
    if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0bU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0bU)))));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__inject_en))
                ? ((0x00000800U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00000800U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00000800U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0bU)));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0bU));
        __PVT__gen_counters__BRA__11__KET____DOT__cnt_delta 
            = ((0x00000800U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__11__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0bU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0bU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0bU))));
    if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0cU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0cU)))));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__inject_en))
                ? ((0x00001000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00001000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00001000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0cU)));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0cU));
        __PVT__gen_counters__BRA__12__KET____DOT__cnt_delta 
            = ((0x00001000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__12__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0cU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0cU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0cU))));
    if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0dU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0dU)))));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__inject_en))
                ? ((0x00002000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00002000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00002000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0dU)));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0dU));
        __PVT__gen_counters__BRA__13__KET____DOT__cnt_delta 
            = ((0x00002000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__13__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0dU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0dU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0dU))));
    if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0eU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0eU)))));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__inject_en))
                ? ((0x00004000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00004000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00004000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0eU)));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0eU));
        __PVT__gen_counters__BRA__14__KET____DOT__cnt_delta 
            = ((0x00004000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__14__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0eU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0eU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0eU))));
    if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((1U & ((IData)(__PVT__inject_en) 
                            >> 0x0fU)) || (1U & (~ 
                                                 ((IData)(__PVT__pop_en) 
                                                  >> 0x0fU)))));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__inject_en))
                ? ((0x00008000U & (IData)(__PVT__pop_en))
                    ? 1U : 2U) : ((0x00008000U & (IData)(__PVT__pop_en))
                                   ? 0U : 1U));
    } else if ((0x00008000U & (IData)(__PVT__inject_en))) {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & (~ ((IData)(__PVT__pop_en) >> 0x0fU)));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 0U : 1U);
    } else {
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_en 
            = (1U & ((IData)(__PVT__pop_en) >> 0x0fU));
        __PVT__gen_counters__BRA__15__KET____DOT__cnt_delta 
            = ((0x00008000U & (IData)(__PVT__pop_en))
                ? 1U : 0U);
    }
    __PVT__gen_counters__BRA__15__KET____DOT__cnt_down 
        = ((1U & (~ ((IData)(vlSelfRef.__PVT__push_en) 
                     >> 0x0fU))) && ((1U & (~ ((IData)(__PVT__inject_en) 
                                               >> 0x0fU))) 
                                     && (1U & ((IData)(__PVT__pop_en) 
                                               >> 0x0fU))));
    vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__0__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__1__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__2__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__3__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__4__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__5__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__6__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__7__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__8__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__9__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__10__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__11__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__12__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__13__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__14__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
    vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d 
        = (0x0000000fU & ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_en)
                           ? ((IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  - (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta))
                               : ((IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                  + (IData)(__PVT__gen_counters__BRA__15__KET____DOT__cnt_delta)))
                           : (IData)(vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q)));
}

void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+                  Vaxi4_xbar_tb_axi_demux_id_counters__pi10___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q 
            = vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_d;
        if ((1U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffffcU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select));
        }
        if ((2U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffff3U 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 2U));
        }
        if ((4U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffffcfU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 4U));
        }
        if ((8U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffff3fU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 6U));
        }
        if ((0x00000010U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffffcffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 8U));
        }
        if ((0x00000020U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffff3ffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000aU));
        }
        if ((0x00000040U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffffcfffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000cU));
        }
        if ((0x00000080U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffff3fffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000000eU));
        }
        if ((0x00000100U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfffcffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000010U));
        }
        if ((0x00000200U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfff3ffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000012U));
        }
        if ((0x00000400U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xffcfffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000014U));
        }
        if ((0x00000800U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xff3fffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000016U));
        }
        if ((0x00001000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xfcffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x00000018U));
        }
        if ((0x00002000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xf3ffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001aU));
        }
        if ((0x00004000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0xcfffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001cU));
        }
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__push_en))) {
            vlSelfRef.__PVT__mst_select_q = ((0x3fffffffU 
                                              & vlSelfRef.__PVT__mst_select_q) 
                                             | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select) 
                                                << 0x0000001eU));
        }
    } else {
        vlSelfRef.__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q = 0U;
        vlSelfRef.__PVT__mst_select_q = (0xfffffffcU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffff3U 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffffcfU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffff3fU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffffcffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffff3ffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffffcfffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffff3fffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfffcffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfff3ffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xffcfffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xff3fffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xfcffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xf3ffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0xcfffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
        vlSelfRef.__PVT__mst_select_q = (0x3fffffffU 
                                         & vlSelfRef.__PVT__mst_select_q);
    }
}
