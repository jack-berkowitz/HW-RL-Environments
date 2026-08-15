// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_demux__pi4___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_aw_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_aw_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_ar_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_ar_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full 
        = (IData)(((((((((((((((((((IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                   | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                  | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                 | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                               | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                              | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                             | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                            | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                           | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                          | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                         | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                        | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                       | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                      | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                     | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                    >> 3U) | ((((((((((((((((7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                            | (7U == 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                           | (7U == 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                          | (7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                         | (7U == (7U 
                                                   & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                        | (7U == (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                       | (7U == (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                      | (7U == (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                     | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                    | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                   | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                  | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                 | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                               | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                              | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))));
    vlSelfRef.__PVT__slv_ar_select = ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full 
        = (IData)(((((((((((((((((((IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                   | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                  | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                 | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                               | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                              | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                             | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                            | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                           | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                          | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                         | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                        | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                       | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                      | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                     | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                    >> 3U) | ((((((((((((((((7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                            | (7U == 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                           | (7U == 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                          | (7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                         | (7U == (7U 
                                                   & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                        | (7U == (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                       | (7U == (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                      | (7U == (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                     | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                    | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                   | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                  | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                 | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                               | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                              | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_23 = (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_22 = (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) {
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U];
    } else {
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
    }
    vlSelfRef.__PVT__slv_aw_select = ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
    if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) {
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U];
    } else {
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_24 = ((IData)(vlSelfRef.__PVT__slv_aw_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_25 = ((IData)(vlSelfRef.__PVT__slv_ar_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 3U) | (6U & 
                                               (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                >> 0x0000001dU))))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied 
        = (1U & ((((((((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                       << 3U) | ((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                 << 2U)) | (((0U != 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                             << 1U) 
                                            | (0U != 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                    << 0x0000000cU) | (((((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 3U) | 
                                         ((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 2U)) | 
                                        (((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 1U) | 
                                         (0U != (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                       << 8U)) | ((
                                                   ((((0U 
                                                       != 
                                                       (7U 
                                                        & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                      << 3U) 
                                                     | ((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 2U)) 
                                                    | (((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 1U) 
                                                       | (0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                                   << 4U) 
                                                  | ((((0U 
                                                        != 
                                                        (7U 
                                                         & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                       << 3U) 
                                                      | ((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 2U)) 
                                                     | (((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 1U) 
                                                        | (0U 
                                                           != 
                                                           (7U 
                                                            & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))))) 
                 >> (0x0000000fU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 2U) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                               >> 0x0000001eU)))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select 
        = ((0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)))
            ? (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q)
            : (IData)(vlSelfRef.__PVT__slv_aw_select));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 3U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied 
        = (1U & ((((((((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                       << 3U) | ((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                 << 2U)) | (((0U != 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                             << 1U) 
                                            | (0U != 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                    << 0x0000000cU) | (((((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 3U) | 
                                         ((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 2U)) | 
                                        (((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 1U) | 
                                         (0U != (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                       << 8U)) | ((
                                                   ((((0U 
                                                       != 
                                                       (7U 
                                                        & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                      << 3U) 
                                                     | ((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 2U)) 
                                                    | (((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 1U) 
                                                       | (0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                                   << 4U) 
                                                  | ((((0U 
                                                        != 
                                                        (7U 
                                                         & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                       << 3U) 
                                                      | ((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 2U)) 
                                                     | (((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 1U) 
                                                        | (0U 
                                                           != 
                                                           (7U 
                                                            & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))))) 
                 >> (0x0000000fU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 4U))));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_demux__pi4___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_aw_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_aw_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_ar_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_ar_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full 
        = (IData)(((((((((((((((((((IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                   | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                  | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                 | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                               | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                              | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                             | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                            | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                           | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                          | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                         | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                        | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                       | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                      | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                     | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                    >> 3U) | ((((((((((((((((7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                            | (7U == 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                           | (7U == 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                          | (7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                         | (7U == (7U 
                                                   & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                        | (7U == (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                       | (7U == (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                      | (7U == (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                     | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                    | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                   | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                  | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                 | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                               | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                              | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))));
    vlSelfRef.__PVT__slv_ar_select = ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full 
        = (IData)(((((((((((((((((((IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                   | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                  | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                 | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                               | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                              | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                             | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                            | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                           | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                          | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                         | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                        | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                       | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                      | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                     | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                    >> 3U) | ((((((((((((((((7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                            | (7U == 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                           | (7U == 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                          | (7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                         | (7U == (7U 
                                                   & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                        | (7U == (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                       | (7U == (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                      | (7U == (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                     | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                    | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                   | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                  | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                 | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                               | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                              | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_38 = (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_37 = (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) {
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U];
    } else {
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
    }
    vlSelfRef.__PVT__slv_aw_select = ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
    if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) {
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U];
    } else {
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_39 = ((IData)(vlSelfRef.__PVT__slv_aw_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_40 = ((IData)(vlSelfRef.__PVT__slv_ar_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 3U) | (6U & 
                                               (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                >> 0x0000001dU))))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied 
        = (1U & ((((((((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                       << 3U) | ((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                 << 2U)) | (((0U != 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                             << 1U) 
                                            | (0U != 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                    << 0x0000000cU) | (((((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 3U) | 
                                         ((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 2U)) | 
                                        (((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 1U) | 
                                         (0U != (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                       << 8U)) | ((
                                                   ((((0U 
                                                       != 
                                                       (7U 
                                                        & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                      << 3U) 
                                                     | ((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 2U)) 
                                                    | (((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 1U) 
                                                       | (0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                                   << 4U) 
                                                  | ((((0U 
                                                        != 
                                                        (7U 
                                                         & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                       << 3U) 
                                                      | ((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 2U)) 
                                                     | (((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 1U) 
                                                        | (0U 
                                                           != 
                                                           (7U 
                                                            & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))))) 
                 >> (0x0000000fU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 2U) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                               >> 0x0000001eU)))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select 
        = ((0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)))
            ? (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q)
            : (IData)(vlSelfRef.__PVT__slv_aw_select));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 3U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied 
        = (1U & ((((((((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                       << 3U) | ((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                 << 2U)) | (((0U != 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                             << 1U) 
                                            | (0U != 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                    << 0x0000000cU) | (((((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 3U) | 
                                         ((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 2U)) | 
                                        (((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 1U) | 
                                         (0U != (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                       << 8U)) | ((
                                                   ((((0U 
                                                       != 
                                                       (7U 
                                                        & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                      << 3U) 
                                                     | ((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 2U)) 
                                                    | (((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 1U) 
                                                       | (0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                                   << 4U) 
                                                  | ((((0U 
                                                        != 
                                                        (7U 
                                                         & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                       << 3U) 
                                                      | ((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 2U)) 
                                                     | (((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 1U) 
                                                        | (0U 
                                                           != 
                                                           (7U 
                                                            & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))))) 
                 >> (0x0000000fU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 4U))));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_demux__pi4___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_aw_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_aw_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_ar_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_ar_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full 
        = (IData)(((((((((((((((((((IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                   | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                  | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                 | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                               | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                              | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                             | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                            | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                           | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                          | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                         | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                        | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                       | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                      | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                     | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                    >> 3U) | ((((((((((((((((7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                            | (7U == 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                           | (7U == 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                          | (7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                         | (7U == (7U 
                                                   & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                        | (7U == (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                       | (7U == (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                      | (7U == (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                     | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                    | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                   | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                  | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                 | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                               | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                              | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))));
    vlSelfRef.__PVT__slv_ar_select = ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full 
        = (IData)(((((((((((((((((((IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                   | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                  | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                 | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                               | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                              | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                             | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                            | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                           | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                          | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                         | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                        | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                       | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                      | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                     | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                    >> 3U) | ((((((((((((((((7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                            | (7U == 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                           | (7U == 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                          | (7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                         | (7U == (7U 
                                                   & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                        | (7U == (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                       | (7U == (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                      | (7U == (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                     | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                    | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                   | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                  | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                 | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                               | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                              | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_53 = (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_52 = (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) {
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U];
    } else {
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
    }
    vlSelfRef.__PVT__slv_aw_select = ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
    if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) {
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U];
    } else {
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_54 = ((IData)(vlSelfRef.__PVT__slv_aw_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_55 = ((IData)(vlSelfRef.__PVT__slv_ar_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 3U) | (6U & 
                                               (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                >> 0x0000001dU))))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied 
        = (1U & ((((((((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                       << 3U) | ((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                 << 2U)) | (((0U != 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                             << 1U) 
                                            | (0U != 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                    << 0x0000000cU) | (((((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 3U) | 
                                         ((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 2U)) | 
                                        (((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 1U) | 
                                         (0U != (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                       << 8U)) | ((
                                                   ((((0U 
                                                       != 
                                                       (7U 
                                                        & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                      << 3U) 
                                                     | ((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 2U)) 
                                                    | (((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 1U) 
                                                       | (0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                                   << 4U) 
                                                  | ((((0U 
                                                        != 
                                                        (7U 
                                                         & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                       << 3U) 
                                                      | ((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 2U)) 
                                                     | (((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 1U) 
                                                        | (0U 
                                                           != 
                                                           (7U 
                                                            & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))))) 
                 >> (0x0000000fU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 2U) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                               >> 0x0000001eU)))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select 
        = ((0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)))
            ? (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q)
            : (IData)(vlSelfRef.__PVT__slv_aw_select));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 3U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied 
        = (1U & ((((((((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                       << 3U) | ((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                 << 2U)) | (((0U != 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                             << 1U) 
                                            | (0U != 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                    << 0x0000000cU) | (((((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 3U) | 
                                         ((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 2U)) | 
                                        (((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 1U) | 
                                         (0U != (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                       << 8U)) | ((
                                                   ((((0U 
                                                       != 
                                                       (7U 
                                                        & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                      << 3U) 
                                                     | ((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 2U)) 
                                                    | (((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 1U) 
                                                       | (0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                                   << 4U) 
                                                  | ((((0U 
                                                        != 
                                                        (7U 
                                                         & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                       << 3U) 
                                                      | ((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 2U)) 
                                                     | (((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 1U) 
                                                        | (0U 
                                                           != 
                                                           (7U 
                                                            & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))))) 
                 >> (0x0000000fU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 4U))));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_demux__pi4___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_aw_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_aw_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_ar_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__slv_ar_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full 
        = (IData)(((((((((((((((((((IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                   | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                  | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                 | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                               | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                              | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                             | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                            | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                           | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                          | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                         | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                        | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                       | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                      | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                     | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                    >> 3U) | ((((((((((((((((7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                            | (7U == 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                           | (7U == 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                          | (7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                         | (7U == (7U 
                                                   & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                        | (7U == (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                       | (7U == (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                      | (7U == (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                     | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                    | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                   | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                  | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                 | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                               | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                              | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))));
    vlSelfRef.__PVT__slv_ar_select = ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full 
        = (IData)(((((((((((((((((((IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q) 
                                   | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                  | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                 | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                                | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                               | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                              | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                             | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                            | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                           | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                          | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                         | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                        | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                       | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                      | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                     | (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q)) 
                    >> 3U) | ((((((((((((((((7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                            | (7U == 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                           | (7U == 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                          | (7U == 
                                             (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                         | (7U == (7U 
                                                   & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                        | (7U == (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                       | (7U == (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                      | (7U == (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                     | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                    | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                   | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                  | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                 | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                                | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                               | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q)))) 
                              | (7U == (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_68 = (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_67 = (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) {
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U];
    } else {
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
        vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
    }
    vlSelfRef.__PVT__slv_aw_select = ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
    if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) {
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U];
    } else {
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
        vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
            = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_69 = ((IData)(vlSelfRef.__PVT__slv_aw_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_70 = ((IData)(vlSelfRef.__PVT__slv_ar_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 3U) | (6U & 
                                               (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                >> 0x0000001dU))))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied 
        = (1U & ((((((((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                       << 3U) | ((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                 << 2U)) | (((0U != 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                             << 1U) 
                                            | (0U != 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                    << 0x0000000cU) | (((((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 3U) | 
                                         ((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 2U)) | 
                                        (((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 1U) | 
                                         (0U != (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                       << 8U)) | ((
                                                   ((((0U 
                                                       != 
                                                       (7U 
                                                        & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                      << 3U) 
                                                     | ((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 2U)) 
                                                    | (((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 1U) 
                                                       | (0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                                   << 4U) 
                                                  | ((((0U 
                                                        != 
                                                        (7U 
                                                         & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                       << 3U) 
                                                      | ((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 2U)) 
                                                     | (((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 1U) 
                                                        | (0U 
                                                           != 
                                                           (7U 
                                                            & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))))) 
                 >> (0x0000000fU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 2U) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                               >> 0x0000001eU)))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select 
        = ((0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)))
            ? (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q)
            : (IData)(vlSelfRef.__PVT__slv_aw_select));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 3U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied 
        = (1U & ((((((((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__15__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                       << 3U) | ((0U != (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__14__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                 << 2U)) | (((0U != 
                                              (7U & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__13__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                             << 1U) 
                                            | (0U != 
                                               (7U 
                                                & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__12__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                    << 0x0000000cU) | (((((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__11__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 3U) | 
                                         ((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__10__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 2U)) | 
                                        (((0U != (7U 
                                                  & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__9__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                          << 1U) | 
                                         (0U != (7U 
                                                 & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__8__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                       << 8U)) | ((
                                                   ((((0U 
                                                       != 
                                                       (7U 
                                                        & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__7__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                      << 3U) 
                                                     | ((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__6__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 2U)) 
                                                    | (((0U 
                                                         != 
                                                         (7U 
                                                          & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__5__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                        << 1U) 
                                                       | (0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__4__KET____DOT__i_in_flight_cnt__DOT__counter_q))))) 
                                                   << 4U) 
                                                  | ((((0U 
                                                        != 
                                                        (7U 
                                                         & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__3__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                       << 3U) 
                                                      | ((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__2__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 2U)) 
                                                     | (((0U 
                                                          != 
                                                          (7U 
                                                           & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__1__KET____DOT__i_in_flight_cnt__DOT__counter_q))) 
                                                         << 1U) 
                                                        | (0U 
                                                           != 
                                                           (7U 
                                                            & (IData)(vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__gen_counters__BRA__0__KET____DOT__i_in_flight_cnt__DOT__counter_q))))))) 
                 >> (0x0000000fU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 4U))));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_demux__pi4___ctor_var_reset(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___ctor_var_reset\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->clk_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11908517815223722933ull);
    vlSelf->rst_ni = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3161515032326629241ull);
    vlSelf->test_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2676571483806808904ull);
    VL_SCOPED_RAND_RESET_W(217, vlSelf->slv_req_i, __VscopeHash, 4004120886065445541ull);
    vlSelf->slv_aw_select_i = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 15733865971500813911ull);
    vlSelf->slv_ar_select_i = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 4150762299084020481ull);
    VL_SCOPED_RAND_RESET_W(84, vlSelf->slv_resp_o, __VscopeHash, 13554179404449265617ull);
    VL_SCOPED_RAND_RESET_W(651, vlSelf->mst_reqs_o, __VscopeHash, 17304268228708533547ull);
    VL_SCOPED_RAND_RESET_W(252, vlSelf->mst_resps_i, __VscopeHash, 2160378334327186243ull);
    VL_SCOPED_RAND_RESET_W(217, vlSelf->__PVT__slv_req_cut, __VscopeHash, 15843050104549888746ull);
    vlSelf->__PVT__slv_aw_ready_chan = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14150273561725675691ull);
    vlSelf->__PVT__slv_aw_ready_sel = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6190343915622826241ull);
    vlSelf->__PVT__slv_ar_ready_chan = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3023874763890201979ull);
    vlSelf->__PVT__slv_ar_ready_sel = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 775522017268573485ull);
    vlSelf->__PVT__slv_aw_select = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 16197706161410604368ull);
    vlSelf->__PVT__slv_ar_select = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2111039448360882934ull);
    VL_ZERO_RESET_W(72, vlSelf->__Vcellout__i_aw_spill_reg__data_o);
    VL_ZERO_RESET_W(66, vlSelf->__Vcellout__i_ar_spill_reg__data_o);
    VL_SCOPED_RAND_RESET_W(72, vlSelf->__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q, __VscopeHash, 15520535035823395125ull);
    vlSelf->__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11979189335529014341ull);
    vlSelf->__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9235377368418888541ull);
    vlSelf->__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11306891724020146767ull);
    VL_SCOPED_RAND_RESET_W(72, vlSelf->__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q, __VscopeHash, 14971098445001671565ull);
    vlSelf->__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15004479688414517786ull);
    vlSelf->__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10792262922362291327ull);
    vlSelf->__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4293837855174969129ull);
    vlSelf->__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 8266112354464049033ull);
    vlSelf->__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6162749203194694428ull);
    vlSelf->__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14134938635528164636ull);
    vlSelf->__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15779350758302037680ull);
    vlSelf->__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 17740456004417898080ull);
    vlSelf->__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15173413154097028982ull);
    vlSelf->__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1760128802551533628ull);
    vlSelf->__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1343050646379261501ull);
    VL_SCOPED_RAND_RESET_W(66, vlSelf->__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q, __VscopeHash, 12648261296686431795ull);
    vlSelf->__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9568761315698731487ull);
    vlSelf->__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9648460682160679383ull);
    vlSelf->__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2134800009299267199ull);
    VL_SCOPED_RAND_RESET_W(66, vlSelf->__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q, __VscopeHash, 726007893355029680ull);
    vlSelf->__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 538046995158385089ull);
    vlSelf->__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14892982672327927993ull);
    vlSelf->__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13514411745612621787ull);
    vlSelf->__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 11880445386680223771ull);
    vlSelf->__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7757334205817690626ull);
    vlSelf->__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 229589686942995415ull);
    vlSelf->__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 105746459877925787ull);
    vlSelf->__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 17774058184160041045ull);
    vlSelf->__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8759635376808840244ull);
    vlSelf->__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1202467642496105208ull);
    vlSelf->__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11316616666744973042ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12366053439513412794ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16334501031178831282ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3193296697941506778ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8962079172657364886ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 13997889394828678211ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3259656008696509547ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1949801775783535299ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8131728436431833535ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__w_select = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 3633283346739992353ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2858542024567611177ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9442233349224670718ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4861892976780918711ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 14811227146735412477ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2715536246135656519ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2609568736266000011ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6620829698718188005ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8433106512794376918ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11445407543267409640ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7470620742562278026ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6694501863781134090ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7552572960557510305ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 14847432622883610811ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 448229195110119625ull);
    vlSelf->i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o = 0;
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 14762687525428941683ull);
    vlSelf->i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o = 0;
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 12457759222481939001ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 15057525424950398124ull);
    vlSelf->i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT____Vxrand___0 = VL_SCOPED_RAND_RESET_ASSIGN_I(1, __VscopeHash, 10659274504683234241ull);
    vlSelf->i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 = 0;
    vlSelf->i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 = 0;
    vlSelf->i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 6073270550631682864ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 17042190730840722842ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2675240421069998222ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7835553122002837454ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4277930924024662547ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 10344406234254879071ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4571159401859577322ull);
    vlSelf->i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT____Vxrand___0 = VL_SCOPED_RAND_RESET_ASSIGN_I(1, __VscopeHash, 12287611878608179947ull);
    vlSelf->i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 = 0;
    vlSelf->i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 = 0;
    vlSelf->i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8218886961597223992ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 1800000527530374048ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 826202728363088428ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 17343866440018764023ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2941380124414904450ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14318590590513030856ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 17012348976093852339ull);
    vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8256704651418303775ull);
    vlSelf->__VdfgRegularize_h9b082aa7_1_3 = 0;
    vlSelf->__VdfgRegularize_h9b082aa7_1_7 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_0 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_1 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_2 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_3 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_4 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_5 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_6 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_7 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_11 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_18 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_19 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_20 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_21 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_22 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_23 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_24 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_25 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_32 = 0;
    VL_ZERO_RESET_W(651, vlSelf->__VdfgRegularize_hebeb780c_0_33);
    vlSelf->__VdfgRegularize_hebeb780c_0_34 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_35 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_36 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_37 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_38 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_39 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_40 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_47 = 0;
    VL_ZERO_RESET_W(651, vlSelf->__VdfgRegularize_hebeb780c_0_48);
    vlSelf->__VdfgRegularize_hebeb780c_0_49 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_50 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_51 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_52 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_53 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_54 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_55 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_62 = 0;
    VL_ZERO_RESET_W(651, vlSelf->__VdfgRegularize_hebeb780c_0_63);
    vlSelf->__VdfgRegularize_hebeb780c_0_64 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_65 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_66 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_67 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_68 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_69 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_70 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_87 = 0;
    VL_ZERO_RESET_W(72, vlSelf->__VdfgRegularize_hebeb780c_0_88);
    vlSelf->__VdfgRegularize_hebeb780c_0_89 = 0;
    VL_ZERO_RESET_W(72, vlSelf->__VdfgRegularize_hebeb780c_0_90);
    vlSelf->__VdfgRegularize_hebeb780c_0_91 = 0;
    VL_ZERO_RESET_W(72, vlSelf->__VdfgRegularize_hebeb780c_0_92);
    vlSelf->__VdfgRegularize_hebeb780c_0_93 = 0;
    VL_ZERO_RESET_W(72, vlSelf->__VdfgRegularize_hebeb780c_0_94);
    vlSelf->__VdfgRegularize_hebeb780c_0_96 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_97 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_98 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_100 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_101 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_102 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_104 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_105 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_106 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_108 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_109 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_110 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_119 = 0;
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_122);
    vlSelf->__VdfgRegularize_hebeb780c_0_123 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_129 = 0;
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_132);
    vlSelf->__VdfgRegularize_hebeb780c_0_133 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_139 = 0;
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_142);
    vlSelf->__VdfgRegularize_hebeb780c_0_143 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_149 = 0;
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_152);
    vlSelf->__VdfgRegularize_hebeb780c_0_153 = 0;
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_159);
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_187);
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_190);
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_193);
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_196);
    VL_ZERO_RESET_W(868, vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req);
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_96 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_97 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_98 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_100 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_101 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_102 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_104 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_105 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_106 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_108 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_109 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_110 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
}
