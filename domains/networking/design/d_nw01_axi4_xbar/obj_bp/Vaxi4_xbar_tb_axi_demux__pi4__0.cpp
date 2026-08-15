// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_14;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_14);
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_17;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_17);
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_120;
    __VdfgRegularize_hebeb780c_0_120 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_121;
    __VdfgRegularize_hebeb780c_0_121 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_124;
    __VdfgRegularize_hebeb780c_0_124 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_125;
    __VdfgRegularize_hebeb780c_0_125 = 0;
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_126;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_126);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_127;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_127);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_188;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_188);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_189;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_189);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_206;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_206);
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
            >> 0x00000010U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_chan));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
            >> 0x00000010U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
            >> 1U) & (IData)(vlSelfRef.__PVT__slv_ar_ready_chan));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
            >> 1U) & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__slv_req_cut[0U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         << 2U) | (
                                                   ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_23) 
                                                    << 1U) 
                                                   | (1U 
                                                      & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U])));
    vlSelfRef.__PVT__slv_req_cut[1U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         >> 0x0000001eU) 
                                        | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                           << 2U));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0xfffffff0U 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                            >> 0x0000001eU) 
                                           | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                              << 2U)));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0x0000000fU 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | (0xfffffff0U 
                                           & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U]));
    vlSelfRef.__PVT__slv_req_cut[3U] = ((0x0000000fU 
                                         & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U]) 
                                        | (0xfffffff0U 
                                           & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U]));
    vlSelfRef.__PVT__slv_req_cut[4U] = ((0x0000000fU 
                                         & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U]) 
                                        | ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                            << 0x00000011U) 
                                           | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_22) 
                                               << 0x00000010U) 
                                              | (0x0000fff0U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U]))));
    vlSelfRef.__PVT__slv_req_cut[5U] = ((0x0000000fU 
                                         & ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                             >> 0x0000000fU) 
                                            | ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_22) 
                                               >> 0x00000010U))) 
                                        | ((0x0001fff0U 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               >> 0x0000000fU)) 
                                           | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                              << 0x00000011U)));
    vlSelfRef.__PVT__slv_req_cut[6U] = (0x01ffffffU 
                                        & ((0x0000000fU 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                               >> 0x0000000fU)) 
                                           | ((0x0001fff0U 
                                               & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  >> 0x0000000fU)) 
                                              | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                 << 0x00000011U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids 
        = ((4U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[2U] 
                  >> 6U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                    << 1U)) | (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2)));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_121 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_120 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_121 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2);
        __VdfgRegularize_hebeb780c_0_120 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2);
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids 
        = ((4U & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_111) 
                  >> 5U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                    << 1U)) | (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1)));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_125 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_124 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_125 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1);
        __VdfgRegularize_hebeb780c_0_124 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1);
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
    } else if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)))) {
        if ((1U & ((vlSelfRef.__PVT__slv_req_cut[0U] 
                    >> 1U) & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                              | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                 == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select)))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q)))) {
        if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
             & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
            if ((((vlSelfRef.__PVT__slv_req_cut[4U] 
                   >> 0x00000010U) & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                                      | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                                         == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                 & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                    | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                       == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
                vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 1U;
            }
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
    } else if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
                & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
        if ((((vlSelfRef.__PVT__slv_req_cut[4U] >> 0x00000010U) 
              & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                 | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                    == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
             & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                   == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_119 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_121)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_120) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_121) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_120))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[2U] 
                                   >> 8U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_123 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_125)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_124) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_125) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_124))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_111) 
                                   >> 7U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) 
           | (0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_20 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__slv_aw_select)));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_127[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_127[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_127[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_127[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_127[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_127[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_14[0U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[1U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[2U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[3U] = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_14[4U] = (0x00010000U 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_14[5U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                >> 0x0000000fU) 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_14[6U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    } else {
        __VdfgRegularize_hebeb780c_0_14[4U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               << 0x00000011U);
        __VdfgRegularize_hebeb780c_0_14[5U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_14[6U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    }
    __VdfgRegularize_hebeb780c_0_14[7U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[8U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[9U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[10U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[11U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[12U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[13U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[14U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[15U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[16U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[17U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[18U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[19U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[20U] = 0U;
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U]));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_7 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? 2U : (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)) 
                          | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                              >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)))));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_3 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_96 = 
            (1U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                   >> 4U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = 2U;
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_96 = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx 
            = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)) 
                     | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                         >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    }
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                    >> 4U)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_21 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_19 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (1U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_18 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_20) {
        __VdfgRegularize_hebeb780c_0_189[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_189[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_189[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_189[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_189[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_189[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_17[0U] = __VdfgRegularize_hebeb780c_0_14[0U];
    __VdfgRegularize_hebeb780c_0_17[1U] = __VdfgRegularize_hebeb780c_0_14[1U];
    __VdfgRegularize_hebeb780c_0_17[2U] = ((0xffffffc0U 
                                            & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U]) 
                                           | (0x0000001fU 
                                              & __VdfgRegularize_hebeb780c_0_14[2U]));
    __VdfgRegularize_hebeb780c_0_17[3U] = ((0x0000003fU 
                                            & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U]) 
                                           | (0xffffffc0U 
                                              & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U]));
    __VdfgRegularize_hebeb780c_0_17[4U] = ((0xffff0000U 
                                            & __VdfgRegularize_hebeb780c_0_17[4U]) 
                                           | ((0x0000003fU 
                                               & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U]) 
                                              | (0x0000ffc0U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U])));
    __VdfgRegularize_hebeb780c_0_17[4U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_17[4U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[4U]));
    __VdfgRegularize_hebeb780c_0_17[5U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[5U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[5U]));
    __VdfgRegularize_hebeb780c_0_17[6U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[6U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[6U]));
    __VdfgRegularize_hebeb780c_0_17[7U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[7U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[7U]));
    __VdfgRegularize_hebeb780c_0_17[8U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[8U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[8U]));
    __VdfgRegularize_hebeb780c_0_17[9U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[9U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[9U]));
    __VdfgRegularize_hebeb780c_0_17[10U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[10U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[10U]));
    __VdfgRegularize_hebeb780c_0_17[11U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[11U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[11U]));
    __VdfgRegularize_hebeb780c_0_17[12U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[12U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[12U]));
    __VdfgRegularize_hebeb780c_0_17[13U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[13U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[13U]));
    __VdfgRegularize_hebeb780c_0_17[14U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[14U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[14U]));
    __VdfgRegularize_hebeb780c_0_17[15U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[15U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[15U]));
    __VdfgRegularize_hebeb780c_0_17[16U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[16U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[16U]));
    __VdfgRegularize_hebeb780c_0_17[17U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[17U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[17U]));
    __VdfgRegularize_hebeb780c_0_17[18U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[18U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[18U]));
    __VdfgRegularize_hebeb780c_0_17[19U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[19U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[19U]));
    __VdfgRegularize_hebeb780c_0_17[20U] = (0x000007ffU 
                                            & __VdfgRegularize_hebeb780c_0_14[20U]);
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U]) 
           & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
            & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
               >> 4U)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
             >> 4U) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_7 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                   >> 4U));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_97 = ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
                                                 & (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_123));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_98 = ((~ (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_123)) 
                                                 & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_19) {
        __VdfgRegularize_hebeb780c_0_126[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                 << 0x0000001bU) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                   >> 5U));
        __VdfgRegularize_hebeb780c_0_126[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                 << 0x0000001bU) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                   >> 5U));
        __VdfgRegularize_hebeb780c_0_126[2U] = ((__VdfgRegularize_hebeb780c_0_127[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                      >> 5U)));
        __VdfgRegularize_hebeb780c_0_126[3U] = ((__VdfgRegularize_hebeb780c_0_127[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_127[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_126[4U] = ((__VdfgRegularize_hebeb780c_0_127[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_127[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_126[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                 << 0x0000001bU) 
                                                | (0x07fffffeU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                      >> 5U)));
        __VdfgRegularize_hebeb780c_0_126[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                    >> 5U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                    << 0x0000001bU) 
                                                   | (0x07fffffeU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                         >> 5U))));
        __VdfgRegularize_hebeb780c_0_126[2U] = ((__VdfgRegularize_hebeb780c_0_127[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                       >> 5U)) 
                                                   | (0x000007feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                         >> 5U))));
        __VdfgRegularize_hebeb780c_0_126[3U] = ((__VdfgRegularize_hebeb780c_0_127[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_127[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_126[4U] = ((__VdfgRegularize_hebeb780c_0_127[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_127[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_21) {
        __VdfgRegularize_hebeb780c_0_188[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                 << 0x0000001bU) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                   >> 5U));
        __VdfgRegularize_hebeb780c_0_188[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                 << 0x0000001bU) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                   >> 5U));
        __VdfgRegularize_hebeb780c_0_188[2U] = ((__VdfgRegularize_hebeb780c_0_189[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                      >> 5U)));
        __VdfgRegularize_hebeb780c_0_188[3U] = ((__VdfgRegularize_hebeb780c_0_189[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_189[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_188[4U] = ((__VdfgRegularize_hebeb780c_0_189[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_189[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_188[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                 << 0x0000001bU) 
                                                | (0x07fffffeU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                      >> 5U)));
        __VdfgRegularize_hebeb780c_0_188[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                    >> 5U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                    << 0x0000001bU) 
                                                   | (0x07fffffeU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                         >> 5U))));
        __VdfgRegularize_hebeb780c_0_188[2U] = ((__VdfgRegularize_hebeb780c_0_189[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                       >> 5U)) 
                                                   | (0x000007feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                         >> 5U))));
        __VdfgRegularize_hebeb780c_0_188[3U] = ((__VdfgRegularize_hebeb780c_0_189[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_189[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_188[4U] = ((__VdfgRegularize_hebeb780c_0_189[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_189[2U] 
                                                   << 0x0000000bU));
    }
    __VdfgRegularize_hebeb780c_0_206[0U] = ((((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                               ? ((0x0000003fU 
                                                   & __VdfgRegularize_hebeb780c_0_17[3U]) 
                                                  | (0xffffffc0U 
                                                     & __VdfgRegularize_hebeb780c_0_17[3U]))
                                               : __VdfgRegularize_hebeb780c_0_17[3U]) 
                                             << 0x0000001bU) 
                                            | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0xffffffc0U 
                                                  & __VdfgRegularize_hebeb780c_0_17[2U]) 
                                                 | ((0x00000020U 
                                                     & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U]) 
                                                    | (0x0000001fU 
                                                       & __VdfgRegularize_hebeb780c_0_14[2U])))
                                                 : __VdfgRegularize_hebeb780c_0_17[2U]) 
                                               >> 5U));
    __VdfgRegularize_hebeb780c_0_206[1U] = ((((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                               ? ((0x0000003fU 
                                                   & __VdfgRegularize_hebeb780c_0_17[4U]) 
                                                  | (0xffffffc0U 
                                                     & __VdfgRegularize_hebeb780c_0_17[4U]))
                                               : __VdfgRegularize_hebeb780c_0_17[4U]) 
                                             << 0x0000001bU) 
                                            | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0x0000003fU 
                                                  & __VdfgRegularize_hebeb780c_0_17[3U]) 
                                                 | (0xffffffc0U 
                                                    & __VdfgRegularize_hebeb780c_0_17[3U]))
                                                 : __VdfgRegularize_hebeb780c_0_17[3U]) 
                                               >> 5U));
    __VdfgRegularize_hebeb780c_0_206[2U] = ((((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                               ? ((0x0000003fU 
                                                   & __VdfgRegularize_hebeb780c_0_17[5U]) 
                                                  | (0xffffffc0U 
                                                     & __VdfgRegularize_hebeb780c_0_17[5U]))
                                               : __VdfgRegularize_hebeb780c_0_17[5U]) 
                                             << 0x0000001bU) 
                                            | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0x0000003fU 
                                                  & __VdfgRegularize_hebeb780c_0_17[4U]) 
                                                 | (0xffffffc0U 
                                                    & __VdfgRegularize_hebeb780c_0_17[4U]))
                                                 : __VdfgRegularize_hebeb780c_0_17[4U]) 
                                               >> 5U));
    __VdfgRegularize_hebeb780c_0_206[3U] = ((((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                               ? ((0x0000003fU 
                                                   & __VdfgRegularize_hebeb780c_0_17[6U]) 
                                                  | (0xffffffc0U 
                                                     & __VdfgRegularize_hebeb780c_0_17[6U]))
                                               : __VdfgRegularize_hebeb780c_0_17[6U]) 
                                             << 0x0000001bU) 
                                            | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0x0000003fU 
                                                  & __VdfgRegularize_hebeb780c_0_17[5U]) 
                                                 | (0xffffffc0U 
                                                    & __VdfgRegularize_hebeb780c_0_17[5U]))
                                                 : __VdfgRegularize_hebeb780c_0_17[5U]) 
                                               >> 5U));
    __VdfgRegularize_hebeb780c_0_206[4U] = (0x000fffffU 
                                            & (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0x0000003fU 
                                                  & __VdfgRegularize_hebeb780c_0_17[6U]) 
                                                 | (0xffffffc0U 
                                                    & __VdfgRegularize_hebeb780c_0_17[6U]))
                                                 : __VdfgRegularize_hebeb780c_0_17[6U]) 
                                               >> 5U));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[2U] 
            = ((__VdfgRegularize_hebeb780c_0_126[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_97) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[3U] 
            = ((__VdfgRegularize_hebeb780c_0_126[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[4U] 
            = ((__VdfgRegularize_hebeb780c_0_126[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[5U] 
            = ((__VdfgRegularize_hebeb780c_0_126[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[6U] 
            = ((__VdfgRegularize_hebeb780c_0_126[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[2U] 
            = ((__VdfgRegularize_hebeb780c_0_126[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_97) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[3U] 
            = ((__VdfgRegularize_hebeb780c_0_126[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[4U] 
            = ((__VdfgRegularize_hebeb780c_0_126[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[5U] 
            = ((__VdfgRegularize_hebeb780c_0_126[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[6U] 
            = ((__VdfgRegularize_hebeb780c_0_126[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[2U] 
            = ((__VdfgRegularize_hebeb780c_0_188[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_96) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[3U] 
            = ((__VdfgRegularize_hebeb780c_0_188[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[4U] 
            = ((__VdfgRegularize_hebeb780c_0_188[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[5U] 
            = ((__VdfgRegularize_hebeb780c_0_188[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[6U] 
            = ((__VdfgRegularize_hebeb780c_0_188[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[2U] 
            = ((__VdfgRegularize_hebeb780c_0_188[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_96) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[3U] 
            = ((__VdfgRegularize_hebeb780c_0_188[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[4U] 
            = ((__VdfgRegularize_hebeb780c_0_188[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[5U] 
            = ((__VdfgRegularize_hebeb780c_0_188[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[6U] 
            = ((__VdfgRegularize_hebeb780c_0_188[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[2U] 
            = ((__VdfgRegularize_hebeb780c_0_206[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_98) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[3U] 
            = ((__VdfgRegularize_hebeb780c_0_206[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[4U] 
            = ((__VdfgRegularize_hebeb780c_0_206[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[5U] 
            = ((__VdfgRegularize_hebeb780c_0_206[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[6U] 
            = ((__VdfgRegularize_hebeb780c_0_206[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[2U] 
            = ((__VdfgRegularize_hebeb780c_0_206[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_98) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[3U] 
            = ((__VdfgRegularize_hebeb780c_0_206[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[4U] 
            = ((__VdfgRegularize_hebeb780c_0_206[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[5U] 
            = ((__VdfgRegularize_hebeb780c_0_206[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[6U] 
            = ((__VdfgRegularize_hebeb780c_0_206[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[4U] 
                                   << 4U));
    }
}

void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlWide<8>/*251:0*/ mst_resps_i;
    VL_ZERO_W(252, mst_resps_i);
    CData/*0:0*/ __Vcellinp__i_aw_select_spill_reg__ready_i;
    __Vcellinp__i_aw_select_spill_reg__ready_i = 0;
    CData/*0:0*/ __Vcellinp__i_ar_sel_spill_reg__ready_i;
    __Vcellinp__i_ar_sel_spill_reg__ready_i = 0;
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready;
    __PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready = 0;
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down;
    __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down = 0;
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready;
    __PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready = 0;
    VlWide<3>/*95:0*/ __Vtemp_11;
    // Body
    mst_resps_i[0U] = vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[0U];
    mst_resps_i[1U] = vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[1U];
    mst_resps_i[2U] = ((0xffff0000U & mst_resps_i[2U]) 
                       | ((0x0000fe00U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                          >> 2U)) | 
                          ((0x00000100U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                           << 8U)) 
                           | (0x000000ffU & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U]))));
    mst_resps_i[2U] = ((0xfff0ffffU & mst_resps_i[2U]) 
                       | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                             << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                       << 2U)) | ((2U 
                                                   & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                      << 1U)) 
                                                  | (1U 
                                                     & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1))) 
                          << 0x00000010U));
    mst_resps_i[2U] = ((0x000fffffU & mst_resps_i[2U]) 
                       | ((vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[3U] 
                           << 0x0000001cU) | (0x0ff00000U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                 >> 4U))));
    mst_resps_i[3U] = ((0x000fffffU & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[3U] 
                                       >> 4U)) | ((vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                                   << 0x0000001cU) 
                                                  | (0x0ff00000U 
                                                     & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[3U] 
                                                        >> 4U))));
    mst_resps_i[4U] = ((0x000fffffU & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                       >> 4U)) | ((
                                                   (0x0000fe00U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                                       << 6U)) 
                                                   | ((0x00000100U 
                                                       & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                          << 8U)) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                                         >> 0x00000018U))) 
                                                  << 0x00000014U));
    mst_resps_i[5U] = ((0xfffffff0U & mst_resps_i[5U]) 
                       | (((0x0000fe00U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                           << 6U)) 
                           | ((0x00000100U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                              << 8U)) 
                              | (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                 >> 0x00000018U))) 
                          >> 0x0000000cU));
    mst_resps_i[5U] = ((0xffffff0fU & mst_resps_i[5U]) 
                       | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                             << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                       << 2U)) | ((2U 
                                                   & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                      << 1U)) 
                                                  | (1U 
                                                     & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1))) 
                          << 4U));
    mst_resps_i[5U] = ((0x000000ffU & mst_resps_i[5U]) 
                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[0U] 
                          << 8U));
    mst_resps_i[6U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[0U] 
                        >> 0x00000018U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[1U] 
                                           << 8U));
    mst_resps_i[7U] = ((0x0ffe0000U & mst_resps_i[7U]) 
                       | (0x0fffffffU & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[1U] 
                                          >> 0x00000018U) 
                                         | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[2U] 
                                            << 8U))));
    mst_resps_i[7U] = ((0x0001ffffU & mst_resps_i[7U]) 
                       | (0x0ffe0000U & (((4U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                          << 0x0000001bU) 
                                         | (((4U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                             << 0x0000001aU) 
                                            | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_h247165ad_0_6) 
                                                << 0x00000019U) 
                                               | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_111) 
                                                  << 0x00000011U))))));
    __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)))) {
        __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down 
            = (IData)(((0x000000a0U == (0x000000a0U 
                                        & vlSelfRef.__PVT__slv_req_cut[2U])) 
                       & (mst_resps_i[2U] >> 0x00000011U)));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)))) {
        __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down 
            = (IData)(((0x000000a0U == (0x000000a0U 
                                        & vlSelfRef.__PVT__slv_req_cut[2U])) 
                       & (mst_resps_i[5U] >> 5U)));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)))) {
        __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down 
            = (IData)(((0x000000a0U == (0x000000a0U 
                                        & vlSelfRef.__PVT__slv_req_cut[2U])) 
                       & (mst_resps_i[7U] >> 0x00000019U)));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_91 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)
                                                  ? 
                                                 ((0x00000078U 
                                                   & ((((0U 
                                                         == 
                                                         (0x0000001fU 
                                                          & ((IData)(0x0000004cU) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000054U) 
                                                                 * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))))))
                                                         ? 0U
                                                         : 
                                                        (mst_resps_i
                                                         [
                                                         (((IData)(0x0000004fU) 
                                                           + 
                                                           (0x000000ffU 
                                                            & ((IData)(0x00000054U) 
                                                               * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                          >> 5U)] 
                                                         << 
                                                         ((IData)(0x00000020U) 
                                                          - 
                                                          (0x0000001fU 
                                                           & ((IData)(0x0000004cU) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))))))) 
                                                       | (mst_resps_i
                                                          [
                                                          (((IData)(0x0000004cU) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000054U) 
                                                                * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                           >> 5U)] 
                                                          >> 
                                                          (0x0000001fU 
                                                           & ((IData)(0x0000004cU) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))))))) 
                                                      << 3U)) 
                                                  | ((6U 
                                                      & ((((0U 
                                                            == 
                                                            (0x0000001fU 
                                                             & ((IData)(0x0000004aU) 
                                                                + 
                                                                (0x000000ffU 
                                                                 & ((IData)(0x00000054U) 
                                                                    * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))))))
                                                            ? 0U
                                                            : 
                                                           (mst_resps_i
                                                            [
                                                            (((IData)(0x0000004bU) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                             >> 5U)] 
                                                            << 
                                                            ((IData)(0x00000020U) 
                                                             - 
                                                             (0x0000001fU 
                                                              & ((IData)(0x0000004aU) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))))))) 
                                                          | (mst_resps_i
                                                             [
                                                             (((IData)(0x0000004aU) 
                                                               + 
                                                               (0x000000ffU 
                                                                & ((IData)(0x00000054U) 
                                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                              >> 5U)] 
                                                             >> 
                                                             (0x0000001fU 
                                                              & ((IData)(0x0000004aU) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))))))) 
                                                         << 1U)) 
                                                     | (1U 
                                                        & (mst_resps_i
                                                           [
                                                           (((IData)(0x00000049U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000054U) 
                                                                 * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                            >> 5U)] 
                                                           >> 
                                                           (0x0000001fU 
                                                            & ((IData)(0x00000049U) 
                                                               + 
                                                               (0x000000ffU 
                                                                & ((IData)(0x00000054U) 
                                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))))))))
                                                  : 0U);
    __PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
           & (mst_resps_i[(((IData)(0x00000052U) + 
                            (0x000000ffU & ((IData)(0x00000054U) 
                                            * (IData)(vlSelfRef.__PVT__slv_ar_select)))) 
                           >> 5U)] >> (0x0000001fU 
                                       & ((IData)(0x00000052U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000054U) 
                                                * (IData)(vlSelfRef.__PVT__slv_ar_select)))))));
    __PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
           & (mst_resps_i[(((IData)(0x00000053U) + 
                            (0x000000ffU & ((IData)(0x00000054U) 
                                            * (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                           >> 5U)] >> (0x0000001fU 
                                       & ((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000054U) 
                                                * (IData)(vlSelfRef.__PVT__slv_aw_select)))))));
    __Vtemp_11[0U] = (((IData)((((QData)((IData)(mst_resps_i
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000054U) 
                                                        * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                   >> 5U)])) 
                                 << ((0U == (0x0000001fU 
                                             & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000054U) 
                                                      * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                      ? 0x00000020U
                                      : ((IData)(0x00000040U) 
                                         - (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                | (((0U == (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                     ? 0ULL : ((QData)((IData)(mst_resps_i
                                                               [
                                                               (((IData)(0x00000023U) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                >> 5U)])) 
                                               << ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000054U) 
                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                   | ((QData)((IData)(mst_resps_i
                                                      [
                                                      (((IData)(4U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000054U) 
                                                            * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                       >> 5U)])) 
                                      >> (0x0000001fU 
                                          & ((IData)(4U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000054U) 
                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))))) 
                       << 4U) | ((0x0000000cU & (((
                                                   (0U 
                                                    == 
                                                    (0x0000001fU 
                                                     & ((IData)(2U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000054U) 
                                                            * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                                    ? 0U
                                                    : 
                                                   (mst_resps_i
                                                    [
                                                    (((IData)(3U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000054U) 
                                                          * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                     >> 5U)] 
                                                    << 
                                                    ((IData)(0x00000020U) 
                                                     - 
                                                     (0x0000001fU 
                                                      & ((IData)(2U) 
                                                         + 
                                                         (0x000000ffU 
                                                          & ((IData)(0x00000054U) 
                                                             * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                                  | (mst_resps_i
                                                     [
                                                     (((IData)(2U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000054U) 
                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                      >> 5U)] 
                                                     >> 
                                                     (0x0000001fU 
                                                      & ((IData)(2U) 
                                                         + 
                                                         (0x000000ffU 
                                                          & ((IData)(0x00000054U) 
                                                             * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))) 
                                                 << 2U)) 
                                 | ((2U & ((mst_resps_i
                                            [(((IData)(1U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                              >> 5U)] 
                                            >> (0x0000001fU 
                                                & ((IData)(1U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000054U) 
                                                       * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))) 
                                           << 1U)) 
                                    | (1U & (mst_resps_i
                                             [(7U & 
                                               (((IData)(0x00000054U) 
                                                 * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)) 
                                                >> 5U))] 
                                             >> (0x0000001fU 
                                                 & ((IData)(0x00000054U) 
                                                    * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))));
    __Vtemp_11[1U] = (((IData)((((QData)((IData)(mst_resps_i
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000054U) 
                                                        * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                   >> 5U)])) 
                                 << ((0U == (0x0000001fU 
                                             & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000054U) 
                                                      * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                      ? 0x00000020U
                                      : ((IData)(0x00000040U) 
                                         - (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                | (((0U == (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                     ? 0ULL : ((QData)((IData)(mst_resps_i
                                                               [
                                                               (((IData)(0x00000023U) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                >> 5U)])) 
                                               << ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000054U) 
                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                   | ((QData)((IData)(mst_resps_i
                                                      [
                                                      (((IData)(4U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000054U) 
                                                            * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                       >> 5U)])) 
                                      >> (0x0000001fU 
                                          & ((IData)(4U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000054U) 
                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))))) 
                       >> 0x0000001cU) | ((IData)((
                                                   (((QData)((IData)(mst_resps_i
                                                                     [
                                                                     (((IData)(0x00000043U) 
                                                                       + 
                                                                       (0x000000ffU 
                                                                        & ((IData)(0x00000054U) 
                                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                      >> 5U)])) 
                                                     << 
                                                     ((0U 
                                                       == 
                                                       (0x0000001fU 
                                                        & ((IData)(4U) 
                                                           + 
                                                           (0x000000ffU 
                                                            & ((IData)(0x00000054U) 
                                                               * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                                       ? 0x00000020U
                                                       : 
                                                      ((IData)(0x00000040U) 
                                                       - 
                                                       (0x0000001fU 
                                                        & ((IData)(4U) 
                                                           + 
                                                           (0x000000ffU 
                                                            & ((IData)(0x00000054U) 
                                                               * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                                    | (((0U 
                                                         == 
                                                         (0x0000001fU 
                                                          & ((IData)(4U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000054U) 
                                                                 * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                                         ? 0ULL
                                                         : 
                                                        ((QData)((IData)(mst_resps_i
                                                                         [
                                                                         (((IData)(0x00000023U) 
                                                                           + 
                                                                           (0x000000ffU 
                                                                            & ((IData)(0x00000054U) 
                                                                               * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                          >> 5U)])) 
                                                         << 
                                                         ((IData)(0x00000020U) 
                                                          - 
                                                          (0x0000001fU 
                                                           & ((IData)(4U) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                                       | ((QData)((IData)(mst_resps_i
                                                                          [
                                                                          (((IData)(4U) 
                                                                            + 
                                                                            (0x000000ffU 
                                                                             & ((IData)(0x00000054U) 
                                                                                * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                           >> 5U)])) 
                                                          >> 
                                                          (0x0000001fU 
                                                           & ((IData)(4U) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                                   >> 0x00000020U)) 
                                          << 4U));
    __Vtemp_11[2U] = ((IData)(((((QData)((IData)(mst_resps_i
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000054U) 
                                                        * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                   >> 5U)])) 
                                 << ((0U == (0x0000001fU 
                                             & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000054U) 
                                                      * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                      ? 0x00000020U
                                      : ((IData)(0x00000040U) 
                                         - (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                | (((0U == (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                     ? 0ULL : ((QData)((IData)(mst_resps_i
                                                               [
                                                               (((IData)(0x00000023U) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                >> 5U)])) 
                                               << ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000054U) 
                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                   | ((QData)((IData)(mst_resps_i
                                                      [
                                                      (((IData)(4U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000054U) 
                                                            * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                       >> 5U)])) 
                                      >> (0x0000001fU 
                                          & ((IData)(4U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000054U) 
                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                               >> 0x00000020U)) >> 0x0000001cU);
    if (vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_92[0U] 
            = __Vtemp_11[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_92[1U] 
            = __Vtemp_11[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_92[2U] 
            = ((0x000000f0U & ((((0U == (0x0000001fU 
                                         & ((IData)(0x00000044U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000054U) 
                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                  ? 0U : (mst_resps_i
                                          [(((IData)(0x00000047U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000054U) 
                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                            >> 5U)] 
                                          << ((IData)(0x00000020U) 
                                              - (0x0000001fU 
                                                 & ((IData)(0x00000044U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000054U) 
                                                        * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                | (mst_resps_i[(((IData)(0x00000044U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                >> 5U)] 
                                   >> (0x0000001fU 
                                       & ((IData)(0x00000044U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000054U) 
                                                * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))) 
                               << 4U)) | __Vtemp_11[2U]);
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_92[0U] = 0U;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_92[1U] = 0U;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_92[2U] = 0U;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_d 
        = (0x0000000fU & (((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down) 
                           ^ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up))
                           ? ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q) 
                                  - (IData)(1U)) : 
                              ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)))
                           : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = 1U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = 0U;
        if (__PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock = 1U;
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = 0U;
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = 1U;
            __Vcellinp__i_ar_sel_spill_reg__ready_i = 1U;
        } else {
            __Vcellinp__i_ar_sel_spill_reg__ready_i = 0U;
        }
    } else {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = 0U;
        if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)))) {
            if ((1U & ((vlSelfRef.__PVT__slv_req_cut[0U] 
                        >> 1U) & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                                  | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                     == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select)))))) {
                if ((1U & (~ (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready)))) {
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock = 1U;
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = 1U;
                }
                if (__PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready) {
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = 1U;
                }
            }
        }
        __Vcellinp__i_ar_sel_spill_reg__ready_i = (
                                                   (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)) 
                                                   & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_23) 
                                                      & (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                                                          | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                                             == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select))) 
                                                         & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready))));
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = 1U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = 0U;
        if (__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock = 1U;
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = 0U;
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = 0U;
            __Vcellinp__i_aw_select_spill_reg__ready_i = 1U;
        } else {
            __Vcellinp__i_aw_select_spill_reg__ready_i = 0U;
        }
    } else {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = 0U;
        if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
             & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
            if ((((vlSelfRef.__PVT__slv_req_cut[4U] 
                   >> 0x00000010U) & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                                      | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                                         == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                 & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                    | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                       == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
                if ((1U & (~ (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready)))) {
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock = 1U;
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = 1U;
                }
                if (__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready) {
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = 0U;
                }
            }
        }
        __Vcellinp__i_aw_select_spill_reg__ready_i 
            = ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
               & ((7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                  & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_22) 
                     & (((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                         | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                            == (IData)(vlSelfRef.__PVT__slv_aw_select))) 
                        & (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                            | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                               == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))) 
                           & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready))))));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_6 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
                                                   & (vlSelfRef.__VdfgRegularize_hebeb780c_0_92[0U] 
                                                      >> 1U)));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(__Vcellinp__i_ar_sel_spill_reg__ready_i)) 
           & (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(__Vcellinp__i_ar_sel_spill_reg__ready_i));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(__Vcellinp__i_ar_sel_spill_reg__ready_i)) 
           & (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(__Vcellinp__i_ar_sel_spill_reg__ready_i));
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(__Vcellinp__i_aw_select_spill_reg__ready_i)) 
           & (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(__Vcellinp__i_aw_select_spill_reg__ready_i));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(__Vcellinp__i_aw_select_spill_reg__ready_i)) 
           & (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(__Vcellinp__i_aw_select_spill_reg__ready_i));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1)) 
                                       | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1)) 
                                       | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_96) 
                                                     << 2U) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_97) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_98))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                                     << 2U) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_96) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_97) 
                                              | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_98)))) 
                                       | (vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[2U] 
                                          >> 4U))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                              | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i)))) 
                                       | vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[0U])))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | ((~ (vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[2U] 
                                              >> 4U)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_96) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_97) 
                                                | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_98)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | ((~ vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[0U]) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | ((~ (vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[2U] 
                                              >> 4U)) 
                                          | ((2U >= (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))
                                              ? ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_96) 
                                                   << 2U) 
                                                  | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_97) 
                                                      << 1U) 
                                                     | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_98))) 
                                                 >> (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))
                                              : (IData)(vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT____Vxrand___0))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | ((~ vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[0U]) 
                                          | ((2U >= (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))
                                              ? ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                                   << 2U) 
                                                  | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                      << 1U) 
                                                     | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i))) 
                                                 >> (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))
                                              : (IData)(vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT____Vxrand___0))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 
        = vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 
        = vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
              & (~ (vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[2U] 
                    >> 4U))));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
              & (~ vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[0U])));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d;
        if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q 
                = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d;
        }
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q 
                = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d;
        }
        if (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d;
        if (vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q 
                = vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        }
        if (((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_d;
        if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q 
                = vlSelfRef.__PVT__slv_aw_select;
        }
        if (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        if (vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q 
                = vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        }
        if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
        }
        if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
        }
        if (vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q 
                = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar_error)
                    ? 2U : (IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar));
        }
        if (vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q 
                = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw_error)
                    ? 2U : (IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw));
        }
        if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[1U] 
                    << 0x0000001eU) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
                                       >> 2U));
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                    << 0x0000001eU) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[1U] 
                                       >> 2U));
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = (3U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                         >> 2U));
        }
        if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[5U] 
                    << 0x0000000fU) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                       >> 0x00000011U));
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                    << 0x0000000fU) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[5U] 
                                       >> 0x00000011U));
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = (0x000000ffU & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                                  >> 0x00000011U));
        }
    } else {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0U;
        vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q = 0U;
        vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] = 0U;
        vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q = 0U;
        vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] = 0U;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_ar_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_ar_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_23 = (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_aw_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_aw_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_22 = (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_25 = ((IData)(vlSelfRef.__PVT__slv_ar_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_24 = ((IData)(vlSelfRef.__PVT__slv_aw_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
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
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__2(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__2\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__slv_ar_select = ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
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
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                     << 3U) | (6U & 
                                               (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                                >> 0x0000001dU))))));
    vlSelfRef.__PVT__slv_aw_select = ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                       ? (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q)
                                       : (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q));
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
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select 
        = (3U & (vlSelf->__PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter->__PVT__mst_select_q 
                 >> (0x0000001eU & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                    >> 3U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select 
        = ((0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)))
            ? (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q)
            : (IData)(vlSelfRef.__PVT__slv_aw_select));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_120;
    __VdfgRegularize_hebeb780c_0_120 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_121;
    __VdfgRegularize_hebeb780c_0_121 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_124;
    __VdfgRegularize_hebeb780c_0_124 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_125;
    __VdfgRegularize_hebeb780c_0_125 = 0;
    // Body
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids 
        = ((4U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[2U] 
                  >> 6U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                    << 1U)) | (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids 
        = ((4U & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_111) 
                  >> 5U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                    << 1U)) | (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1)));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_120 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_121 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_120 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2);
        __VdfgRegularize_hebeb780c_0_121 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2);
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
    }
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_124 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_125 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_124 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1);
        __VdfgRegularize_hebeb780c_0_125 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1);
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_119 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_121)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_120) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_121) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_120))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_112[2U] 
                                   >> 8U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_123 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_125)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_124) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_125) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_124))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_111) 
                                   >> 7U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_7 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_3 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? 2U : (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)) 
                          | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                              >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? 2U : (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)) 
                          | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                              >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)))));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_14;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_14);
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_17;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_17);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_126;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_126);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_127;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_127);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_188;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_188);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_189;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_189);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_206;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_206);
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
            >> 0x00000010U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_chan));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
            >> 0x00000010U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
            >> 1U) & (IData)(vlSelfRef.__PVT__slv_ar_ready_chan));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
            >> 1U) & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__slv_req_cut[0U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         << 2U) | (
                                                   ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_23) 
                                                    << 1U) 
                                                   | (1U 
                                                      & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U])));
    vlSelfRef.__PVT__slv_req_cut[1U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         >> 0x0000001eU) 
                                        | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                           << 2U));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0xfffffff0U 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                            >> 0x0000001eU) 
                                           | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                              << 2U)));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0x0000000fU 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | (0xfffffff0U 
                                           & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U]));
    vlSelfRef.__PVT__slv_req_cut[3U] = ((0x0000000fU 
                                         & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U]) 
                                        | (0xfffffff0U 
                                           & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U]));
    vlSelfRef.__PVT__slv_req_cut[4U] = ((0x0000000fU 
                                         & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U]) 
                                        | ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                            << 0x00000011U) 
                                           | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_22) 
                                               << 0x00000010U) 
                                              | (0x0000fff0U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U]))));
    vlSelfRef.__PVT__slv_req_cut[5U] = ((0x0000000fU 
                                         & ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                             >> 0x0000000fU) 
                                            | ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_22) 
                                               >> 0x00000010U))) 
                                        | ((0x0001fff0U 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               >> 0x0000000fU)) 
                                           | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                              << 0x00000011U)));
    vlSelfRef.__PVT__slv_req_cut[6U] = (0x01ffffffU 
                                        & ((0x0000000fU 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                               >> 0x0000000fU)) 
                                           | ((0x0001fff0U 
                                               & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  >> 0x0000000fU)) 
                                              | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                 << 0x00000011U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U]));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_96 = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                  >> 4U) 
                                                 & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                    >> 4U)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
               >> 4U)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U]) 
           & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
             >> 4U) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
            & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_7 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                   >> 4U));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
    } else if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)))) {
        if ((1U & ((vlSelfRef.__PVT__slv_req_cut[0U] 
                    >> 1U) & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                              | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                 == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select)))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q)))) {
        if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
             & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
            if ((((vlSelfRef.__PVT__slv_req_cut[4U] 
                   >> 0x00000010U) & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                                      | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                                         == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                 & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                    | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                       == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
                vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 1U;
            }
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
    } else if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
                & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
        if ((((vlSelfRef.__PVT__slv_req_cut[4U] >> 0x00000010U) 
              & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                 | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                    == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
             & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                   == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_97 = ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
                                                 & (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_123));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_98 = ((~ (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_123)) 
                                                 & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) 
           | (0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_20 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__slv_aw_select)));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_127[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_127[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_127[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_127[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_127[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_127[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_14[0U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[1U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[2U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[3U] = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_14[4U] = (0x00010000U 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_14[5U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                >> 0x0000000fU) 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_14[6U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    } else {
        __VdfgRegularize_hebeb780c_0_14[4U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               << 0x00000011U);
        __VdfgRegularize_hebeb780c_0_14[5U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_14[6U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    }
    __VdfgRegularize_hebeb780c_0_14[7U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[8U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[9U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[10U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[11U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[12U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[13U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[14U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[15U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[16U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[17U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[18U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[19U] = 0U;
    __VdfgRegularize_hebeb780c_0_14[20U] = 0U;
    vlSelfRef.__VdfgRegularize_hebeb780c_0_21 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_19 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (1U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_18 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_20) {
        __VdfgRegularize_hebeb780c_0_189[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_189[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_189[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_189[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_189[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_189[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_17[0U] = __VdfgRegularize_hebeb780c_0_14[0U];
    __VdfgRegularize_hebeb780c_0_17[1U] = __VdfgRegularize_hebeb780c_0_14[1U];
    __VdfgRegularize_hebeb780c_0_17[2U] = ((0xffffffc0U 
                                            & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U]) 
                                           | (0x0000001fU 
                                              & __VdfgRegularize_hebeb780c_0_14[2U]));
    __VdfgRegularize_hebeb780c_0_17[3U] = ((0x0000003fU 
                                            & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U]) 
                                           | (0xffffffc0U 
                                              & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U]));
    __VdfgRegularize_hebeb780c_0_17[4U] = ((0xffff0000U 
                                            & __VdfgRegularize_hebeb780c_0_17[4U]) 
                                           | ((0x0000003fU 
                                               & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U]) 
                                              | (0x0000ffc0U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U])));
    __VdfgRegularize_hebeb780c_0_17[4U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_17[4U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[4U]));
    __VdfgRegularize_hebeb780c_0_17[5U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[5U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[5U]));
    __VdfgRegularize_hebeb780c_0_17[6U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[6U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[6U]));
    __VdfgRegularize_hebeb780c_0_17[7U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[7U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[7U]));
    __VdfgRegularize_hebeb780c_0_17[8U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[8U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[8U]));
    __VdfgRegularize_hebeb780c_0_17[9U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_14[9U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_14[9U]));
    __VdfgRegularize_hebeb780c_0_17[10U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[10U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[10U]));
    __VdfgRegularize_hebeb780c_0_17[11U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[11U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[11U]));
    __VdfgRegularize_hebeb780c_0_17[12U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[12U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[12U]));
    __VdfgRegularize_hebeb780c_0_17[13U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[13U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[13U]));
    __VdfgRegularize_hebeb780c_0_17[14U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[14U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[14U]));
    __VdfgRegularize_hebeb780c_0_17[15U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[15U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[15U]));
    __VdfgRegularize_hebeb780c_0_17[16U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[16U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[16U]));
    __VdfgRegularize_hebeb780c_0_17[17U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[17U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[17U]));
    __VdfgRegularize_hebeb780c_0_17[18U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[18U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[18U]));
    __VdfgRegularize_hebeb780c_0_17[19U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_14[19U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_14[19U]));
    __VdfgRegularize_hebeb780c_0_17[20U] = (0x000007ffU 
                                            & __VdfgRegularize_hebeb780c_0_14[20U]);
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_19) {
        __VdfgRegularize_hebeb780c_0_126[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                 << 0x0000001bU) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                   >> 5U));
        __VdfgRegularize_hebeb780c_0_126[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                 << 0x0000001bU) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                   >> 5U));
        __VdfgRegularize_hebeb780c_0_126[2U] = ((__VdfgRegularize_hebeb780c_0_127[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                      >> 5U)));
        __VdfgRegularize_hebeb780c_0_126[3U] = ((__VdfgRegularize_hebeb780c_0_127[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_127[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_126[4U] = ((__VdfgRegularize_hebeb780c_0_127[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_127[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_126[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                 << 0x0000001bU) 
                                                | (0x07fffffeU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                      >> 5U)));
        __VdfgRegularize_hebeb780c_0_126[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                    >> 5U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                    << 0x0000001bU) 
                                                   | (0x07fffffeU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                         >> 5U))));
        __VdfgRegularize_hebeb780c_0_126[2U] = ((__VdfgRegularize_hebeb780c_0_127[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                       >> 5U)) 
                                                   | (0x000007feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                         >> 5U))));
        __VdfgRegularize_hebeb780c_0_126[3U] = ((__VdfgRegularize_hebeb780c_0_127[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_127[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_126[4U] = ((__VdfgRegularize_hebeb780c_0_127[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_127[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_21) {
        __VdfgRegularize_hebeb780c_0_188[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                 << 0x0000001bU) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                   >> 5U));
        __VdfgRegularize_hebeb780c_0_188[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                 << 0x0000001bU) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                   >> 5U));
        __VdfgRegularize_hebeb780c_0_188[2U] = ((__VdfgRegularize_hebeb780c_0_189[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                      >> 5U)));
        __VdfgRegularize_hebeb780c_0_188[3U] = ((__VdfgRegularize_hebeb780c_0_189[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_189[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_188[4U] = ((__VdfgRegularize_hebeb780c_0_189[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_189[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_188[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                 << 0x0000001bU) 
                                                | (0x07fffffeU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U] 
                                                      >> 5U)));
        __VdfgRegularize_hebeb780c_0_188[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                    >> 5U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                    << 0x0000001bU) 
                                                   | (0x07fffffeU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[3U] 
                                                         >> 5U))));
        __VdfgRegularize_hebeb780c_0_188[2U] = ((__VdfgRegularize_hebeb780c_0_189[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                       >> 5U)) 
                                                   | (0x000007feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[4U] 
                                                         >> 5U))));
        __VdfgRegularize_hebeb780c_0_188[3U] = ((__VdfgRegularize_hebeb780c_0_189[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_189[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_188[4U] = ((__VdfgRegularize_hebeb780c_0_189[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_189[2U] 
                                                   << 0x0000000bU));
    }
    __VdfgRegularize_hebeb780c_0_206[0U] = ((((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                               ? ((0x0000003fU 
                                                   & __VdfgRegularize_hebeb780c_0_17[3U]) 
                                                  | (0xffffffc0U 
                                                     & __VdfgRegularize_hebeb780c_0_17[3U]))
                                               : __VdfgRegularize_hebeb780c_0_17[3U]) 
                                             << 0x0000001bU) 
                                            | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0xffffffc0U 
                                                  & __VdfgRegularize_hebeb780c_0_17[2U]) 
                                                 | ((0x00000020U 
                                                     & vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[2U]) 
                                                    | (0x0000001fU 
                                                       & __VdfgRegularize_hebeb780c_0_14[2U])))
                                                 : __VdfgRegularize_hebeb780c_0_17[2U]) 
                                               >> 5U));
    __VdfgRegularize_hebeb780c_0_206[1U] = ((((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                               ? ((0x0000003fU 
                                                   & __VdfgRegularize_hebeb780c_0_17[4U]) 
                                                  | (0xffffffc0U 
                                                     & __VdfgRegularize_hebeb780c_0_17[4U]))
                                               : __VdfgRegularize_hebeb780c_0_17[4U]) 
                                             << 0x0000001bU) 
                                            | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0x0000003fU 
                                                  & __VdfgRegularize_hebeb780c_0_17[3U]) 
                                                 | (0xffffffc0U 
                                                    & __VdfgRegularize_hebeb780c_0_17[3U]))
                                                 : __VdfgRegularize_hebeb780c_0_17[3U]) 
                                               >> 5U));
    __VdfgRegularize_hebeb780c_0_206[2U] = ((((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                               ? ((0x0000003fU 
                                                   & __VdfgRegularize_hebeb780c_0_17[5U]) 
                                                  | (0xffffffc0U 
                                                     & __VdfgRegularize_hebeb780c_0_17[5U]))
                                               : __VdfgRegularize_hebeb780c_0_17[5U]) 
                                             << 0x0000001bU) 
                                            | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0x0000003fU 
                                                  & __VdfgRegularize_hebeb780c_0_17[4U]) 
                                                 | (0xffffffc0U 
                                                    & __VdfgRegularize_hebeb780c_0_17[4U]))
                                                 : __VdfgRegularize_hebeb780c_0_17[4U]) 
                                               >> 5U));
    __VdfgRegularize_hebeb780c_0_206[3U] = ((((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                               ? ((0x0000003fU 
                                                   & __VdfgRegularize_hebeb780c_0_17[6U]) 
                                                  | (0xffffffc0U 
                                                     & __VdfgRegularize_hebeb780c_0_17[6U]))
                                               : __VdfgRegularize_hebeb780c_0_17[6U]) 
                                             << 0x0000001bU) 
                                            | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0x0000003fU 
                                                  & __VdfgRegularize_hebeb780c_0_17[5U]) 
                                                 | (0xffffffc0U 
                                                    & __VdfgRegularize_hebeb780c_0_17[5U]))
                                                 : __VdfgRegularize_hebeb780c_0_17[5U]) 
                                               >> 5U));
    __VdfgRegularize_hebeb780c_0_206[4U] = (0x000fffffU 
                                            & (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_18)
                                                 ? 
                                                ((0x0000003fU 
                                                  & __VdfgRegularize_hebeb780c_0_17[6U]) 
                                                 | (0xffffffc0U 
                                                    & __VdfgRegularize_hebeb780c_0_17[6U]))
                                                 : __VdfgRegularize_hebeb780c_0_17[6U]) 
                                               >> 5U));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[2U] 
            = ((__VdfgRegularize_hebeb780c_0_126[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_97) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[3U] 
            = ((__VdfgRegularize_hebeb780c_0_126[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[4U] 
            = ((__VdfgRegularize_hebeb780c_0_126[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[5U] 
            = ((__VdfgRegularize_hebeb780c_0_126[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[6U] 
            = ((__VdfgRegularize_hebeb780c_0_126[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[2U] 
            = ((__VdfgRegularize_hebeb780c_0_126[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_97) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[3U] 
            = ((__VdfgRegularize_hebeb780c_0_126[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[4U] 
            = ((__VdfgRegularize_hebeb780c_0_126[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[5U] 
            = ((__VdfgRegularize_hebeb780c_0_126[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_122[6U] 
            = ((__VdfgRegularize_hebeb780c_0_126[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_126[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[2U] 
            = ((__VdfgRegularize_hebeb780c_0_188[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_96) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[3U] 
            = ((__VdfgRegularize_hebeb780c_0_188[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[4U] 
            = ((__VdfgRegularize_hebeb780c_0_188[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[5U] 
            = ((__VdfgRegularize_hebeb780c_0_188[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[6U] 
            = ((__VdfgRegularize_hebeb780c_0_188[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[2U] 
            = ((__VdfgRegularize_hebeb780c_0_188[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_96) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[3U] 
            = ((__VdfgRegularize_hebeb780c_0_188[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[4U] 
            = ((__VdfgRegularize_hebeb780c_0_188[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[5U] 
            = ((__VdfgRegularize_hebeb780c_0_188[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_187[6U] 
            = ((__VdfgRegularize_hebeb780c_0_188[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_188[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[2U] 
            = ((__VdfgRegularize_hebeb780c_0_206[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_98) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[3U] 
            = ((__VdfgRegularize_hebeb780c_0_206[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[4U] 
            = ((__VdfgRegularize_hebeb780c_0_206[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[5U] 
            = ((__VdfgRegularize_hebeb780c_0_206[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[6U] 
            = ((__VdfgRegularize_hebeb780c_0_206[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[2U] 
            = ((__VdfgRegularize_hebeb780c_0_206[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_98) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[3U] 
            = ((__VdfgRegularize_hebeb780c_0_206[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[4U] 
            = ((__VdfgRegularize_hebeb780c_0_206[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[5U] 
            = ((__VdfgRegularize_hebeb780c_0_206[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_159[6U] 
            = ((__VdfgRegularize_hebeb780c_0_206[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_206[4U] 
                                   << 4U));
    }
}

void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_28;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_28);
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_31;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_31);
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_130;
    __VdfgRegularize_hebeb780c_0_130 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_131;
    __VdfgRegularize_hebeb780c_0_131 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_134;
    __VdfgRegularize_hebeb780c_0_134 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_135;
    __VdfgRegularize_hebeb780c_0_135 = 0;
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_136;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_136);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_137;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_137);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_191;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_191);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_192;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_192);
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
            >> 9U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_chan));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
            >> 9U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
            >> 0x0000001aU) & (IData)(vlSelfRef.__PVT__slv_ar_ready_chan));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
            >> 0x0000001aU) & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__slv_req_cut[0U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         << 2U) | (
                                                   ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_38) 
                                                    << 1U) 
                                                   | (1U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                                                         >> 0x00000019U))));
    vlSelfRef.__PVT__slv_req_cut[1U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         >> 0x0000001eU) 
                                        | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                           << 2U));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0xfffffff0U 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                            >> 0x0000001eU) 
                                           | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                              << 2U)));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0x0000000fU 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                            << 7U) 
                                           | (0x00000070U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                 >> 0x00000019U))));
    vlSelfRef.__PVT__slv_req_cut[3U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                            >> 0x00000019U)) 
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                            << 7U) 
                                           | (0x00000070U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 >> 0x00000019U))));
    vlSelfRef.__PVT__slv_req_cut[4U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                            >> 0x00000019U)) 
                                        | ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                            << 0x00000011U) 
                                           | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_37) 
                                               << 0x00000010U) 
                                              | (0x0000fff0U 
                                                 & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                     << 7U) 
                                                    | (0x00000070U 
                                                       & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                          >> 0x00000019U)))))));
    vlSelfRef.__PVT__slv_req_cut[5U] = ((0x0000000fU 
                                         & ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                             >> 0x0000000fU) 
                                            | ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_37) 
                                               >> 0x00000010U))) 
                                        | ((0x0001fff0U 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               >> 0x0000000fU)) 
                                           | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                              << 0x00000011U)));
    vlSelfRef.__PVT__slv_req_cut[6U] = (0x01ffffffU 
                                        & ((0x0000000fU 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                               >> 0x0000000fU)) 
                                           | ((0x0001fff0U 
                                               & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  >> 0x0000000fU)) 
                                              | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                 << 0x00000011U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids 
        = ((4U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[2U] 
                  >> 6U)) | ((2U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2) 
                             | (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                      >> 1U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_131 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_130 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_131 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_130 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids 
        = ((4U & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_113) 
                  >> 5U)) | ((2U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1) 
                             | (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                      >> 1U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_135 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_134 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_135 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_134 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
    } else if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)))) {
        if ((1U & ((vlSelfRef.__PVT__slv_req_cut[0U] 
                    >> 1U) & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                              | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                 == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select)))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q)))) {
        if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
             & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
            if ((((vlSelfRef.__PVT__slv_req_cut[4U] 
                   >> 0x00000010U) & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                                      | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                                         == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                 & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                    | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                       == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
                vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 1U;
            }
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
    } else if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
                & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
        if ((((vlSelfRef.__PVT__slv_req_cut[4U] >> 0x00000010U) 
              & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                 | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                    == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
             & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                   == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_129 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_131)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_130) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_131) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_130))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[2U] 
                                   >> 8U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_133 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_135)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_134) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_135) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_134))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_113) 
                                   >> 7U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) 
           | (0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_35 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__slv_aw_select)));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_137[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_137[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_137[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_137[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_137[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_137[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_28[0U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[1U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[2U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[3U] = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_28[4U] = (0x00010000U 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_28[5U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                >> 0x0000000fU) 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_28[6U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    } else {
        __VdfgRegularize_hebeb780c_0_28[4U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               << 0x00000011U);
        __VdfgRegularize_hebeb780c_0_28[5U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_28[6U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    }
    __VdfgRegularize_hebeb780c_0_28[7U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[8U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[9U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[10U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[11U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[12U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[13U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[14U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[15U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[16U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[17U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[18U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[19U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[20U] = 0U;
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                    >> 0x00000019U)));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_7 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? 2U : (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)) 
                          | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                              >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)))));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_3 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_100 
            = (1U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                     >> 0x0000001dU));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = 2U;
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_100 = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx 
            = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)) 
                     | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                         >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    }
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                    >> 0x0000001dU)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_36 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_32 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_34 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (1U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_35) {
        __VdfgRegularize_hebeb780c_0_192[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_192[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_192[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_192[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_192[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_192[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_31[0U] = __VdfgRegularize_hebeb780c_0_28[0U];
    __VdfgRegularize_hebeb780c_0_31[1U] = __VdfgRegularize_hebeb780c_0_28[1U];
    __VdfgRegularize_hebeb780c_0_31[2U] = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                             << 7U) 
                                            | (0x00000040U 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                  >> 0x00000019U))) 
                                           | (0x0000001fU 
                                              & __VdfgRegularize_hebeb780c_0_28[2U]));
    __VdfgRegularize_hebeb780c_0_31[3U] = ((0x0000003fU 
                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                               >> 0x00000019U)) 
                                           | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                               << 7U) 
                                              | (0x00000040U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                    >> 0x00000019U))));
    __VdfgRegularize_hebeb780c_0_31[4U] = ((0xffff0000U 
                                            & __VdfgRegularize_hebeb780c_0_31[4U]) 
                                           | ((0x0000003fU 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                  >> 0x00000019U)) 
                                              | (0x0000ffc0U 
                                                 & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                     << 7U) 
                                                    | (0x00000040U 
                                                       & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                          >> 0x00000019U))))));
    __VdfgRegularize_hebeb780c_0_31[4U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_31[4U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[4U]));
    __VdfgRegularize_hebeb780c_0_31[5U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[5U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[5U]));
    __VdfgRegularize_hebeb780c_0_31[6U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[6U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[6U]));
    __VdfgRegularize_hebeb780c_0_31[7U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[7U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[7U]));
    __VdfgRegularize_hebeb780c_0_31[8U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[8U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[8U]));
    __VdfgRegularize_hebeb780c_0_31[9U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[9U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[9U]));
    __VdfgRegularize_hebeb780c_0_31[10U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[10U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[10U]));
    __VdfgRegularize_hebeb780c_0_31[11U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[11U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[11U]));
    __VdfgRegularize_hebeb780c_0_31[12U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[12U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[12U]));
    __VdfgRegularize_hebeb780c_0_31[13U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[13U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[13U]));
    __VdfgRegularize_hebeb780c_0_31[14U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[14U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[14U]));
    __VdfgRegularize_hebeb780c_0_31[15U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[15U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[15U]));
    __VdfgRegularize_hebeb780c_0_31[16U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[16U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[16U]));
    __VdfgRegularize_hebeb780c_0_31[17U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[17U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[17U]));
    __VdfgRegularize_hebeb780c_0_31[18U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[18U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[18U]));
    __VdfgRegularize_hebeb780c_0_31[19U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[19U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[19U]));
    __VdfgRegularize_hebeb780c_0_31[20U] = (0x000007ffU 
                                            & __VdfgRegularize_hebeb780c_0_28[20U]);
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
               >> 0x00000019U)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
             >> 0x00000019U) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
               >> 0x0000001dU)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
             >> 0x0000001dU) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_5 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                   >> 0x0000001dU));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_102 = ((~ (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_133)) 
                                                  & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_101 = ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
                                                  & (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_133));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_34) {
        __VdfgRegularize_hebeb780c_0_136[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 << 2U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                   >> 0x0000001eU));
        __VdfgRegularize_hebeb780c_0_136[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                 << 2U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                   >> 0x0000001eU));
        __VdfgRegularize_hebeb780c_0_136[2U] = ((__VdfgRegularize_hebeb780c_0_137[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                       << 2U) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                         >> 0x0000001eU))));
        __VdfgRegularize_hebeb780c_0_136[3U] = ((__VdfgRegularize_hebeb780c_0_137[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_137[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_136[4U] = ((__VdfgRegularize_hebeb780c_0_137[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_137[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_136[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 << 2U) 
                                                | (2U 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                      >> 0x0000001eU)));
        __VdfgRegularize_hebeb780c_0_136[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                    >> 0x0000001eU)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                    << 2U) 
                                                   | (2U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                         >> 0x0000001eU))));
        __VdfgRegularize_hebeb780c_0_136[2U] = ((__VdfgRegularize_hebeb780c_0_137[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                       >> 0x0000001eU)) 
                                                   | (0x000007feU 
                                                      & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                          << 2U) 
                                                         | (2U 
                                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                               >> 0x0000001eU))))));
        __VdfgRegularize_hebeb780c_0_136[3U] = ((__VdfgRegularize_hebeb780c_0_137[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_137[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_136[4U] = ((__VdfgRegularize_hebeb780c_0_137[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_137[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_36) {
        __VdfgRegularize_hebeb780c_0_191[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 << 2U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                   >> 0x0000001eU));
        __VdfgRegularize_hebeb780c_0_191[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                 << 2U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                   >> 0x0000001eU));
        __VdfgRegularize_hebeb780c_0_191[2U] = ((__VdfgRegularize_hebeb780c_0_192[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                       << 2U) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                         >> 0x0000001eU))));
        __VdfgRegularize_hebeb780c_0_191[3U] = ((__VdfgRegularize_hebeb780c_0_192[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_192[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_191[4U] = ((__VdfgRegularize_hebeb780c_0_192[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_192[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_191[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 << 2U) 
                                                | (2U 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                      >> 0x0000001eU)));
        __VdfgRegularize_hebeb780c_0_191[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                    >> 0x0000001eU)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                    << 2U) 
                                                   | (2U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                         >> 0x0000001eU))));
        __VdfgRegularize_hebeb780c_0_191[2U] = ((__VdfgRegularize_hebeb780c_0_192[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                       >> 0x0000001eU)) 
                                                   | (0x000007feU 
                                                      & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                          << 2U) 
                                                         | (2U 
                                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                               >> 0x0000001eU))))));
        __VdfgRegularize_hebeb780c_0_191[3U] = ((__VdfgRegularize_hebeb780c_0_192[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_192[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_191[4U] = ((__VdfgRegularize_hebeb780c_0_192[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_192[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_32) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[0U] 
            = __VdfgRegularize_hebeb780c_0_28[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[1U] 
            = __VdfgRegularize_hebeb780c_0_28[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[2U] 
            = ((0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[2U]) 
               | ((0x00000020U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                  >> 0x00000019U)) 
                  | (0x0000001fU & __VdfgRegularize_hebeb780c_0_28[2U])));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[3U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[3U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[3U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[4U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[4U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[4U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[5U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[5U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[5U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[6U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[6U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[6U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[7U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[7U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[7U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[8U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[8U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[8U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[9U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[9U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[9U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[10U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[10U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[10U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[11U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[11U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[11U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[12U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[12U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[12U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[13U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[13U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[13U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[14U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[14U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[14U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[15U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[15U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[15U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[16U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[16U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[16U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[17U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[17U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[17U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[18U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[18U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[18U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[19U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[19U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[19U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[20U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[20U]) 
               | (0x000007c0U & __VdfgRegularize_hebeb780c_0_31[20U]));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[0U] 
            = __VdfgRegularize_hebeb780c_0_31[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[1U] 
            = __VdfgRegularize_hebeb780c_0_31[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[2U] 
            = __VdfgRegularize_hebeb780c_0_31[2U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[3U] 
            = __VdfgRegularize_hebeb780c_0_31[3U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[4U] 
            = __VdfgRegularize_hebeb780c_0_31[4U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[5U] 
            = __VdfgRegularize_hebeb780c_0_31[5U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[6U] 
            = __VdfgRegularize_hebeb780c_0_31[6U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[7U] 
            = __VdfgRegularize_hebeb780c_0_31[7U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[8U] 
            = __VdfgRegularize_hebeb780c_0_31[8U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[9U] 
            = __VdfgRegularize_hebeb780c_0_31[9U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[10U] 
            = __VdfgRegularize_hebeb780c_0_31[10U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[11U] 
            = __VdfgRegularize_hebeb780c_0_31[11U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[12U] 
            = __VdfgRegularize_hebeb780c_0_31[12U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[13U] 
            = __VdfgRegularize_hebeb780c_0_31[13U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[14U] 
            = __VdfgRegularize_hebeb780c_0_31[14U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[15U] 
            = __VdfgRegularize_hebeb780c_0_31[15U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[16U] 
            = __VdfgRegularize_hebeb780c_0_31[16U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[17U] 
            = __VdfgRegularize_hebeb780c_0_31[17U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[18U] 
            = __VdfgRegularize_hebeb780c_0_31[18U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[19U] 
            = __VdfgRegularize_hebeb780c_0_31[19U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[20U] 
            = __VdfgRegularize_hebeb780c_0_31[20U];
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[2U] 
            = ((__VdfgRegularize_hebeb780c_0_136[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_101) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[3U] 
            = ((__VdfgRegularize_hebeb780c_0_136[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[4U] 
            = ((__VdfgRegularize_hebeb780c_0_136[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[5U] 
            = ((__VdfgRegularize_hebeb780c_0_136[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[6U] 
            = ((__VdfgRegularize_hebeb780c_0_136[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[2U] 
            = ((__VdfgRegularize_hebeb780c_0_136[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_101) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[3U] 
            = ((__VdfgRegularize_hebeb780c_0_136[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[4U] 
            = ((__VdfgRegularize_hebeb780c_0_136[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[5U] 
            = ((__VdfgRegularize_hebeb780c_0_136[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[6U] 
            = ((__VdfgRegularize_hebeb780c_0_136[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[2U] 
            = ((__VdfgRegularize_hebeb780c_0_191[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_100) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[3U] 
            = ((__VdfgRegularize_hebeb780c_0_191[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[4U] 
            = ((__VdfgRegularize_hebeb780c_0_191[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[5U] 
            = ((__VdfgRegularize_hebeb780c_0_191[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[6U] 
            = ((__VdfgRegularize_hebeb780c_0_191[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[2U] 
            = ((__VdfgRegularize_hebeb780c_0_191[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_100) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[3U] 
            = ((__VdfgRegularize_hebeb780c_0_191[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[4U] 
            = ((__VdfgRegularize_hebeb780c_0_191[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[5U] 
            = ((__VdfgRegularize_hebeb780c_0_191[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[6U] 
            = ((__VdfgRegularize_hebeb780c_0_191[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[4U] 
                                   << 4U));
    }
}

void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlWide<8>/*251:0*/ mst_resps_i;
    VL_ZERO_W(252, mst_resps_i);
    CData/*0:0*/ __Vcellinp__i_aw_select_spill_reg__ready_i;
    __Vcellinp__i_aw_select_spill_reg__ready_i = 0;
    CData/*0:0*/ __Vcellinp__i_ar_sel_spill_reg__ready_i;
    __Vcellinp__i_ar_sel_spill_reg__ready_i = 0;
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready;
    __PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready = 0;
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down;
    __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down = 0;
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready;
    __PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready = 0;
    VlWide<3>/*95:0*/ __Vtemp_11;
    // Body
    mst_resps_i[0U] = vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[0U];
    mst_resps_i[1U] = vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[1U];
    mst_resps_i[2U] = ((0xffff0000U & mst_resps_i[2U]) 
                       | ((0x0000fe00U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                          >> 2U)) | 
                          ((0x00000100U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                           << 7U)) 
                           | (0x000000ffU & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U]))));
    mst_resps_i[2U] = ((0xfff0ffffU & mst_resps_i[2U]) 
                       | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                             << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                       << 2U)) | ((2U 
                                                   & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies)) 
                                                  | (1U 
                                                     & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                        >> 1U)))) 
                          << 0x00000010U));
    mst_resps_i[2U] = ((0x000fffffU & mst_resps_i[2U]) 
                       | ((vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[3U] 
                           << 0x0000001cU) | (0x0ff00000U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                 >> 4U))));
    mst_resps_i[3U] = ((0x000fffffU & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[3U] 
                                       >> 4U)) | ((vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                                   << 0x0000001cU) 
                                                  | (0x0ff00000U 
                                                     & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[3U] 
                                                        >> 4U))));
    mst_resps_i[4U] = ((0x000fffffU & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                       >> 4U)) | ((
                                                   (0x0000fe00U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                                       << 6U)) 
                                                   | ((0x00000100U 
                                                       & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                          << 7U)) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                                         >> 0x00000018U))) 
                                                  << 0x00000014U));
    mst_resps_i[5U] = ((0xfffffff0U & mst_resps_i[5U]) 
                       | (((0x0000fe00U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                           << 6U)) 
                           | ((0x00000100U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                              << 7U)) 
                              | (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                 >> 0x00000018U))) 
                          >> 0x0000000cU));
    mst_resps_i[5U] = ((0xffffff0fU & mst_resps_i[5U]) 
                       | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                             << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                       << 2U)) | ((2U 
                                                   & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies)) 
                                                  | (1U 
                                                     & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                        >> 1U)))) 
                          << 4U));
    mst_resps_i[5U] = ((0x000000ffU & mst_resps_i[5U]) 
                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[0U] 
                          << 8U));
    mst_resps_i[6U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[0U] 
                        >> 0x00000018U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[1U] 
                                           << 8U));
    mst_resps_i[7U] = ((0x0ffe0000U & mst_resps_i[7U]) 
                       | (0x0fffffffU & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[1U] 
                                          >> 0x00000018U) 
                                         | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[2U] 
                                            << 8U))));
    mst_resps_i[7U] = ((0x0001ffffU & mst_resps_i[7U]) 
                       | (0x0ffe0000U & (((4U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                          << 0x0000001bU) 
                                         | (((4U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                             << 0x0000001aU) 
                                            | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_h247165ad_0_6) 
                                                << 0x00000019U) 
                                               | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_113) 
                                                  << 0x00000011U))))));
    __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)))) {
        __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down 
            = (IData)(((0x000000a0U == (0x000000a0U 
                                        & vlSelfRef.__PVT__slv_req_cut[2U])) 
                       & (mst_resps_i[2U] >> 0x00000011U)));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)))) {
        __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down 
            = (IData)(((0x000000a0U == (0x000000a0U 
                                        & vlSelfRef.__PVT__slv_req_cut[2U])) 
                       & (mst_resps_i[5U] >> 5U)));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)))) {
        __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down 
            = (IData)(((0x000000a0U == (0x000000a0U 
                                        & vlSelfRef.__PVT__slv_req_cut[2U])) 
                       & (mst_resps_i[7U] >> 0x00000019U)));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_89 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)
                                                  ? 
                                                 ((0x00000078U 
                                                   & ((((0U 
                                                         == 
                                                         (0x0000001fU 
                                                          & ((IData)(0x0000004cU) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000054U) 
                                                                 * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))))))
                                                         ? 0U
                                                         : 
                                                        (mst_resps_i
                                                         [
                                                         (((IData)(0x0000004fU) 
                                                           + 
                                                           (0x000000ffU 
                                                            & ((IData)(0x00000054U) 
                                                               * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                          >> 5U)] 
                                                         << 
                                                         ((IData)(0x00000020U) 
                                                          - 
                                                          (0x0000001fU 
                                                           & ((IData)(0x0000004cU) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))))))) 
                                                       | (mst_resps_i
                                                          [
                                                          (((IData)(0x0000004cU) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000054U) 
                                                                * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                           >> 5U)] 
                                                          >> 
                                                          (0x0000001fU 
                                                           & ((IData)(0x0000004cU) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))))))) 
                                                      << 3U)) 
                                                  | ((6U 
                                                      & ((((0U 
                                                            == 
                                                            (0x0000001fU 
                                                             & ((IData)(0x0000004aU) 
                                                                + 
                                                                (0x000000ffU 
                                                                 & ((IData)(0x00000054U) 
                                                                    * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))))))
                                                            ? 0U
                                                            : 
                                                           (mst_resps_i
                                                            [
                                                            (((IData)(0x0000004bU) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                             >> 5U)] 
                                                            << 
                                                            ((IData)(0x00000020U) 
                                                             - 
                                                             (0x0000001fU 
                                                              & ((IData)(0x0000004aU) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))))))) 
                                                          | (mst_resps_i
                                                             [
                                                             (((IData)(0x0000004aU) 
                                                               + 
                                                               (0x000000ffU 
                                                                & ((IData)(0x00000054U) 
                                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                              >> 5U)] 
                                                             >> 
                                                             (0x0000001fU 
                                                              & ((IData)(0x0000004aU) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))))))) 
                                                         << 1U)) 
                                                     | (1U 
                                                        & (mst_resps_i
                                                           [
                                                           (((IData)(0x00000049U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000054U) 
                                                                 * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))) 
                                                            >> 5U)] 
                                                           >> 
                                                           (0x0000001fU 
                                                            & ((IData)(0x00000049U) 
                                                               + 
                                                               (0x000000ffU 
                                                                & ((IData)(0x00000054U) 
                                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx)))))))))
                                                  : 0U);
    __PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
           & (mst_resps_i[(((IData)(0x00000052U) + 
                            (0x000000ffU & ((IData)(0x00000054U) 
                                            * (IData)(vlSelfRef.__PVT__slv_ar_select)))) 
                           >> 5U)] >> (0x0000001fU 
                                       & ((IData)(0x00000052U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000054U) 
                                                * (IData)(vlSelfRef.__PVT__slv_ar_select)))))));
    __PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
           & (mst_resps_i[(((IData)(0x00000053U) + 
                            (0x000000ffU & ((IData)(0x00000054U) 
                                            * (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                           >> 5U)] >> (0x0000001fU 
                                       & ((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000054U) 
                                                * (IData)(vlSelfRef.__PVT__slv_aw_select)))))));
    __Vtemp_11[0U] = (((IData)((((QData)((IData)(mst_resps_i
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000054U) 
                                                        * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                   >> 5U)])) 
                                 << ((0U == (0x0000001fU 
                                             & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000054U) 
                                                      * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                      ? 0x00000020U
                                      : ((IData)(0x00000040U) 
                                         - (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                | (((0U == (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                     ? 0ULL : ((QData)((IData)(mst_resps_i
                                                               [
                                                               (((IData)(0x00000023U) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                >> 5U)])) 
                                               << ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000054U) 
                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                   | ((QData)((IData)(mst_resps_i
                                                      [
                                                      (((IData)(4U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000054U) 
                                                            * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                       >> 5U)])) 
                                      >> (0x0000001fU 
                                          & ((IData)(4U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000054U) 
                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))))) 
                       << 4U) | ((0x0000000cU & (((
                                                   (0U 
                                                    == 
                                                    (0x0000001fU 
                                                     & ((IData)(2U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000054U) 
                                                            * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                                    ? 0U
                                                    : 
                                                   (mst_resps_i
                                                    [
                                                    (((IData)(3U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000054U) 
                                                          * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                     >> 5U)] 
                                                    << 
                                                    ((IData)(0x00000020U) 
                                                     - 
                                                     (0x0000001fU 
                                                      & ((IData)(2U) 
                                                         + 
                                                         (0x000000ffU 
                                                          & ((IData)(0x00000054U) 
                                                             * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                                  | (mst_resps_i
                                                     [
                                                     (((IData)(2U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000054U) 
                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                      >> 5U)] 
                                                     >> 
                                                     (0x0000001fU 
                                                      & ((IData)(2U) 
                                                         + 
                                                         (0x000000ffU 
                                                          & ((IData)(0x00000054U) 
                                                             * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))) 
                                                 << 2U)) 
                                 | ((2U & ((mst_resps_i
                                            [(((IData)(1U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                              >> 5U)] 
                                            >> (0x0000001fU 
                                                & ((IData)(1U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000054U) 
                                                       * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))) 
                                           << 1U)) 
                                    | (1U & (mst_resps_i
                                             [(7U & 
                                               (((IData)(0x00000054U) 
                                                 * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)) 
                                                >> 5U))] 
                                             >> (0x0000001fU 
                                                 & ((IData)(0x00000054U) 
                                                    * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))));
    __Vtemp_11[1U] = (((IData)((((QData)((IData)(mst_resps_i
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000054U) 
                                                        * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                   >> 5U)])) 
                                 << ((0U == (0x0000001fU 
                                             & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000054U) 
                                                      * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                      ? 0x00000020U
                                      : ((IData)(0x00000040U) 
                                         - (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                | (((0U == (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                     ? 0ULL : ((QData)((IData)(mst_resps_i
                                                               [
                                                               (((IData)(0x00000023U) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                >> 5U)])) 
                                               << ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000054U) 
                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                   | ((QData)((IData)(mst_resps_i
                                                      [
                                                      (((IData)(4U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000054U) 
                                                            * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                       >> 5U)])) 
                                      >> (0x0000001fU 
                                          & ((IData)(4U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000054U) 
                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))))) 
                       >> 0x0000001cU) | ((IData)((
                                                   (((QData)((IData)(mst_resps_i
                                                                     [
                                                                     (((IData)(0x00000043U) 
                                                                       + 
                                                                       (0x000000ffU 
                                                                        & ((IData)(0x00000054U) 
                                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                      >> 5U)])) 
                                                     << 
                                                     ((0U 
                                                       == 
                                                       (0x0000001fU 
                                                        & ((IData)(4U) 
                                                           + 
                                                           (0x000000ffU 
                                                            & ((IData)(0x00000054U) 
                                                               * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                                       ? 0x00000020U
                                                       : 
                                                      ((IData)(0x00000040U) 
                                                       - 
                                                       (0x0000001fU 
                                                        & ((IData)(4U) 
                                                           + 
                                                           (0x000000ffU 
                                                            & ((IData)(0x00000054U) 
                                                               * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                                    | (((0U 
                                                         == 
                                                         (0x0000001fU 
                                                          & ((IData)(4U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000054U) 
                                                                 * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                                         ? 0ULL
                                                         : 
                                                        ((QData)((IData)(mst_resps_i
                                                                         [
                                                                         (((IData)(0x00000023U) 
                                                                           + 
                                                                           (0x000000ffU 
                                                                            & ((IData)(0x00000054U) 
                                                                               * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                          >> 5U)])) 
                                                         << 
                                                         ((IData)(0x00000020U) 
                                                          - 
                                                          (0x0000001fU 
                                                           & ((IData)(4U) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                                       | ((QData)((IData)(mst_resps_i
                                                                          [
                                                                          (((IData)(4U) 
                                                                            + 
                                                                            (0x000000ffU 
                                                                             & ((IData)(0x00000054U) 
                                                                                * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                           >> 5U)])) 
                                                          >> 
                                                          (0x0000001fU 
                                                           & ((IData)(4U) 
                                                              + 
                                                              (0x000000ffU 
                                                               & ((IData)(0x00000054U) 
                                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                                   >> 0x00000020U)) 
                                          << 4U));
    __Vtemp_11[2U] = ((IData)(((((QData)((IData)(mst_resps_i
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000054U) 
                                                        * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                   >> 5U)])) 
                                 << ((0U == (0x0000001fU 
                                             & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000054U) 
                                                      * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                      ? 0x00000020U
                                      : ((IData)(0x00000040U) 
                                         - (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                | (((0U == (0x0000001fU 
                                            & ((IData)(4U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                     ? 0ULL : ((QData)((IData)(mst_resps_i
                                                               [
                                                               (((IData)(0x00000023U) 
                                                                 + 
                                                                 (0x000000ffU 
                                                                  & ((IData)(0x00000054U) 
                                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                                >> 5U)])) 
                                               << ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000054U) 
                                                           * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                   | ((QData)((IData)(mst_resps_i
                                                      [
                                                      (((IData)(4U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000054U) 
                                                            * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                       >> 5U)])) 
                                      >> (0x0000001fU 
                                          & ((IData)(4U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000054U) 
                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                               >> 0x00000020U)) >> 0x0000001cU);
    if (vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_90[0U] 
            = __Vtemp_11[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_90[1U] 
            = __Vtemp_11[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_90[2U] 
            = ((0x000000f0U & ((((0U == (0x0000001fU 
                                         & ((IData)(0x00000044U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000054U) 
                                                  * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))
                                  ? 0U : (mst_resps_i
                                          [(((IData)(0x00000047U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000054U) 
                                                   * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                            >> 5U)] 
                                          << ((IData)(0x00000020U) 
                                              - (0x0000001fU 
                                                 & ((IData)(0x00000044U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000054U) 
                                                        * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))))))) 
                                | (mst_resps_i[(((IData)(0x00000044U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000054U) 
                                                     * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx)))) 
                                                >> 5U)] 
                                   >> (0x0000001fU 
                                       & ((IData)(0x00000044U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000054U) 
                                                * (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))))))) 
                               << 4U)) | __Vtemp_11[2U]);
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_90[0U] = 0U;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_90[1U] = 0U;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_90[2U] = 0U;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_d 
        = (0x0000000fU & (((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down) 
                           ^ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up))
                           ? ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_down)
                               ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q) 
                                  - (IData)(1U)) : 
                              ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)))
                           : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = 1U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = 0U;
        if (__PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock = 1U;
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = 0U;
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = 1U;
            __Vcellinp__i_ar_sel_spill_reg__ready_i = 1U;
        } else {
            __Vcellinp__i_ar_sel_spill_reg__ready_i = 0U;
        }
    } else {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = 0U;
        if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)))) {
            if ((1U & ((vlSelfRef.__PVT__slv_req_cut[0U] 
                        >> 1U) & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                                  | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                     == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select)))))) {
                if ((1U & (~ (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready)))) {
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock = 1U;
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d = 1U;
                }
                if (__PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready) {
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_push = 1U;
                }
            }
        }
        __Vcellinp__i_ar_sel_spill_reg__ready_i = (
                                                   (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)) 
                                                   & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_38) 
                                                      & (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                                                          | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                                             == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select))) 
                                                         & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__ar_ready))));
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = 1U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = 0U;
        if (__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock = 1U;
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = 0U;
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = 0U;
            __Vcellinp__i_aw_select_spill_reg__ready_i = 1U;
        } else {
            __Vcellinp__i_aw_select_spill_reg__ready_i = 0U;
        }
    } else {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = 0U;
        if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
             & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
            if ((((vlSelfRef.__PVT__slv_req_cut[4U] 
                   >> 0x00000010U) & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                                      | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                                         == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                 & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                    | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                       == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
                if ((1U & (~ (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready)))) {
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock = 1U;
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d = 1U;
                }
                if (__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready) {
                    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject = 0U;
                }
            }
        }
        __Vcellinp__i_aw_select_spill_reg__ready_i 
            = ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
               & ((7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                  & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_37) 
                     & (((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                         | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                            == (IData)(vlSelfRef.__PVT__slv_aw_select))) 
                        & (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                            | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                               == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))) 
                           & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready))))));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_4 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                                & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                                                    >> 0x00000019U) 
                                                   & (vlSelfRef.__VdfgRegularize_hebeb780c_0_90[0U] 
                                                      >> 1U)));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(__Vcellinp__i_ar_sel_spill_reg__ready_i)) 
           & (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(__Vcellinp__i_ar_sel_spill_reg__ready_i));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(__Vcellinp__i_ar_sel_spill_reg__ready_i)) 
           & (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(__Vcellinp__i_ar_sel_spill_reg__ready_i));
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(__Vcellinp__i_aw_select_spill_reg__ready_i)) 
           & (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(__Vcellinp__i_aw_select_spill_reg__ready_i));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(__Vcellinp__i_aw_select_spill_reg__ready_i)) 
           & (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(__Vcellinp__i_aw_select_spill_reg__ready_i));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1)) 
                                       | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1)) 
                                       | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_100) 
                                                     << 2U) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_101) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_102))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                                     << 2U) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_100) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_101) 
                                              | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_102)))) 
                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[8U] 
                                          >> 0x0000001dU))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                              | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i)))) 
                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[6U] 
                                          >> 0x00000019U))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[8U] 
                                              >> 0x0000001dU)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_100) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_101) 
                                                | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_102)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[6U] 
                                              >> 0x00000019U)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[8U] 
                                              >> 0x0000001dU)) 
                                          | ((2U >= (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))
                                              ? ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_100) 
                                                   << 2U) 
                                                  | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_101) 
                                                      << 1U) 
                                                     | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_102))) 
                                                 >> (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))
                                              : (IData)(vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT____Vxrand___0))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[6U] 
                                              >> 0x00000019U)) 
                                          | ((2U >= (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))
                                              ? ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                                   << 2U) 
                                                  | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                      << 1U) 
                                                     | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i))) 
                                                 >> (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))
                                              : (IData)(vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT____Vxrand___0))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 
        = vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 
        = vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
              & (~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[8U] 
                    >> 0x0000001dU))));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
              & (~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[6U] 
                    >> 0x00000019U))));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d;
        if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q 
                = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d;
        }
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q 
                = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d;
        }
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d;
        if (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q 
                = vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        }
        if (((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_d;
        if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q 
                = vlSelfRef.__PVT__slv_aw_select;
        }
        if (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        if (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        if (vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q 
                = vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        }
        if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] 
                = vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
        }
        if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] 
                = vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
        }
        if (vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q 
                = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar_error)
                    ? 2U : (IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar));
        }
        if (vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q 
                = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw_error)
                    ? 2U : (IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw));
        }
        if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[7U] 
                    << 5U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                              >> 0x0000001bU));
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                    << 5U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[7U] 
                              >> 0x0000001bU));
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = (3U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                         >> 0x0000001bU));
        }
        if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[12U] 
                    << 0x00000016U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                       >> 0x0000000aU));
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
                    << 0x00000016U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[12U] 
                                       >> 0x0000000aU));
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = (0x000000ffU & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
                                  >> 0x0000000aU));
        }
    } else {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q = 0U;
        vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] = 0U;
        vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q = 0U;
        vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] = 0U;
        vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] = 0U;
        vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] = 0U;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_ar_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_ar_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_38 = (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_aw_ready_sel = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                               | (~ (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__slv_aw_ready_chan = (1U & ((~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_37 = (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_40 = ((IData)(vlSelfRef.__PVT__slv_ar_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_39 = ((IData)(vlSelfRef.__PVT__slv_aw_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
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
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_130;
    __VdfgRegularize_hebeb780c_0_130 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_131;
    __VdfgRegularize_hebeb780c_0_131 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_134;
    __VdfgRegularize_hebeb780c_0_134 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_135;
    __VdfgRegularize_hebeb780c_0_135 = 0;
    // Body
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids 
        = ((4U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[2U] 
                  >> 6U)) | ((2U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2) 
                             | (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                      >> 1U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids 
        = ((4U & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_113) 
                  >> 5U)) | ((2U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1) 
                             | (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                      >> 1U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_130 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_131 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_130 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_131 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
    }
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_134 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_135 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_134 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_135 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_129 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_131)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_130) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_131) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_130))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_114[2U] 
                                   >> 8U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_133 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_135)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_134) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_135) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_134))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_113) 
                                   >> 7U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_7 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_3 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? 2U : (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)) 
                          | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                              >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? 2U : (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)) 
                          | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                              >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)))));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_28;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_28);
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_31;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_31);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_136;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_136);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_137;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_137);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_191;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_191);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_192;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_192);
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
            >> 9U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_chan));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
            >> 9U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
            >> 0x0000001aU) & (IData)(vlSelfRef.__PVT__slv_ar_ready_chan));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
            >> 0x0000001aU) & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__slv_req_cut[0U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         << 2U) | (
                                                   ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_38) 
                                                    << 1U) 
                                                   | (1U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                                                         >> 0x00000019U))));
    vlSelfRef.__PVT__slv_req_cut[1U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         >> 0x0000001eU) 
                                        | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                           << 2U));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0xfffffff0U 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                            >> 0x0000001eU) 
                                           | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                              << 2U)));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0x0000000fU 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                            << 7U) 
                                           | (0x00000070U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                 >> 0x00000019U))));
    vlSelfRef.__PVT__slv_req_cut[3U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                            >> 0x00000019U)) 
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                            << 7U) 
                                           | (0x00000070U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 >> 0x00000019U))));
    vlSelfRef.__PVT__slv_req_cut[4U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                            >> 0x00000019U)) 
                                        | ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                            << 0x00000011U) 
                                           | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_37) 
                                               << 0x00000010U) 
                                              | (0x0000fff0U 
                                                 & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                     << 7U) 
                                                    | (0x00000070U 
                                                       & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                          >> 0x00000019U)))))));
    vlSelfRef.__PVT__slv_req_cut[5U] = ((0x0000000fU 
                                         & ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                             >> 0x0000000fU) 
                                            | ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_37) 
                                               >> 0x00000010U))) 
                                        | ((0x0001fff0U 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               >> 0x0000000fU)) 
                                           | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                              << 0x00000011U)));
    vlSelfRef.__PVT__slv_req_cut[6U] = (0x01ffffffU 
                                        & ((0x0000000fU 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                               >> 0x0000000fU)) 
                                           | ((0x0001fff0U 
                                               & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  >> 0x0000000fU)) 
                                              | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                 << 0x00000011U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                    >> 0x00000019U)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_100 = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                   >> 0x0000001dU) 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                    >> 0x0000001dU)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
               >> 0x0000001dU)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
               >> 0x00000019U)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
             >> 0x0000001dU) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
             >> 0x00000019U) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_5 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                   >> 0x0000001dU));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
    } else if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)))) {
        if ((1U & ((vlSelfRef.__PVT__slv_req_cut[0U] 
                    >> 1U) & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                              | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                 == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select)))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q)))) {
        if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
             & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
            if ((((vlSelfRef.__PVT__slv_req_cut[4U] 
                   >> 0x00000010U) & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                                      | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                                         == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                 & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                    | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                       == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
                vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 1U;
            }
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
    } else if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
                & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
        if ((((vlSelfRef.__PVT__slv_req_cut[4U] >> 0x00000010U) 
              & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                 | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                    == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
             & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                   == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_102 = ((~ (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_133)) 
                                                  & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_101 = ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
                                                  & (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_133));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) 
           | (0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_35 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__slv_aw_select)));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_137[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_137[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_137[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_137[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_137[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_137[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_28[0U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[1U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[2U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[3U] = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_28[4U] = (0x00010000U 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_28[5U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                >> 0x0000000fU) 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_28[6U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    } else {
        __VdfgRegularize_hebeb780c_0_28[4U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               << 0x00000011U);
        __VdfgRegularize_hebeb780c_0_28[5U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_28[6U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    }
    __VdfgRegularize_hebeb780c_0_28[7U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[8U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[9U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[10U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[11U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[12U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[13U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[14U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[15U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[16U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[17U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[18U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[19U] = 0U;
    __VdfgRegularize_hebeb780c_0_28[20U] = 0U;
    vlSelfRef.__VdfgRegularize_hebeb780c_0_36 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_32 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_34 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (1U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_35) {
        __VdfgRegularize_hebeb780c_0_192[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_192[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_192[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_192[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_192[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_192[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_31[0U] = __VdfgRegularize_hebeb780c_0_28[0U];
    __VdfgRegularize_hebeb780c_0_31[1U] = __VdfgRegularize_hebeb780c_0_28[1U];
    __VdfgRegularize_hebeb780c_0_31[2U] = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                             << 7U) 
                                            | (0x00000040U 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                  >> 0x00000019U))) 
                                           | (0x0000001fU 
                                              & __VdfgRegularize_hebeb780c_0_28[2U]));
    __VdfgRegularize_hebeb780c_0_31[3U] = ((0x0000003fU 
                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                               >> 0x00000019U)) 
                                           | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                               << 7U) 
                                              | (0x00000040U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                    >> 0x00000019U))));
    __VdfgRegularize_hebeb780c_0_31[4U] = ((0xffff0000U 
                                            & __VdfgRegularize_hebeb780c_0_31[4U]) 
                                           | ((0x0000003fU 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                  >> 0x00000019U)) 
                                              | (0x0000ffc0U 
                                                 & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                     << 7U) 
                                                    | (0x00000040U 
                                                       & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                          >> 0x00000019U))))));
    __VdfgRegularize_hebeb780c_0_31[4U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_31[4U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[4U]));
    __VdfgRegularize_hebeb780c_0_31[5U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[5U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[5U]));
    __VdfgRegularize_hebeb780c_0_31[6U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[6U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[6U]));
    __VdfgRegularize_hebeb780c_0_31[7U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[7U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[7U]));
    __VdfgRegularize_hebeb780c_0_31[8U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[8U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[8U]));
    __VdfgRegularize_hebeb780c_0_31[9U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_28[9U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_28[9U]));
    __VdfgRegularize_hebeb780c_0_31[10U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[10U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[10U]));
    __VdfgRegularize_hebeb780c_0_31[11U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[11U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[11U]));
    __VdfgRegularize_hebeb780c_0_31[12U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[12U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[12U]));
    __VdfgRegularize_hebeb780c_0_31[13U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[13U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[13U]));
    __VdfgRegularize_hebeb780c_0_31[14U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[14U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[14U]));
    __VdfgRegularize_hebeb780c_0_31[15U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[15U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[15U]));
    __VdfgRegularize_hebeb780c_0_31[16U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[16U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[16U]));
    __VdfgRegularize_hebeb780c_0_31[17U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[17U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[17U]));
    __VdfgRegularize_hebeb780c_0_31[18U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[18U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[18U]));
    __VdfgRegularize_hebeb780c_0_31[19U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_28[19U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_28[19U]));
    __VdfgRegularize_hebeb780c_0_31[20U] = (0x000007ffU 
                                            & __VdfgRegularize_hebeb780c_0_28[20U]);
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_34) {
        __VdfgRegularize_hebeb780c_0_136[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 << 2U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                   >> 0x0000001eU));
        __VdfgRegularize_hebeb780c_0_136[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                 << 2U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                   >> 0x0000001eU));
        __VdfgRegularize_hebeb780c_0_136[2U] = ((__VdfgRegularize_hebeb780c_0_137[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                       << 2U) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                         >> 0x0000001eU))));
        __VdfgRegularize_hebeb780c_0_136[3U] = ((__VdfgRegularize_hebeb780c_0_137[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_137[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_136[4U] = ((__VdfgRegularize_hebeb780c_0_137[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_137[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_136[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 << 2U) 
                                                | (2U 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                      >> 0x0000001eU)));
        __VdfgRegularize_hebeb780c_0_136[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                    >> 0x0000001eU)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                    << 2U) 
                                                   | (2U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                         >> 0x0000001eU))));
        __VdfgRegularize_hebeb780c_0_136[2U] = ((__VdfgRegularize_hebeb780c_0_137[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                       >> 0x0000001eU)) 
                                                   | (0x000007feU 
                                                      & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                          << 2U) 
                                                         | (2U 
                                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                               >> 0x0000001eU))))));
        __VdfgRegularize_hebeb780c_0_136[3U] = ((__VdfgRegularize_hebeb780c_0_137[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_137[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_136[4U] = ((__VdfgRegularize_hebeb780c_0_137[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_137[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_36) {
        __VdfgRegularize_hebeb780c_0_191[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 << 2U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                   >> 0x0000001eU));
        __VdfgRegularize_hebeb780c_0_191[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                 << 2U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                   >> 0x0000001eU));
        __VdfgRegularize_hebeb780c_0_191[2U] = ((__VdfgRegularize_hebeb780c_0_192[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                       << 2U) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                         >> 0x0000001eU))));
        __VdfgRegularize_hebeb780c_0_191[3U] = ((__VdfgRegularize_hebeb780c_0_192[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_192[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_191[4U] = ((__VdfgRegularize_hebeb780c_0_192[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_192[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_191[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                 << 2U) 
                                                | (2U 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                                      >> 0x0000001eU)));
        __VdfgRegularize_hebeb780c_0_191[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                    >> 0x0000001eU)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                    << 2U) 
                                                   | (2U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[9U] 
                                                         >> 0x0000001eU))));
        __VdfgRegularize_hebeb780c_0_191[2U] = ((__VdfgRegularize_hebeb780c_0_192[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                       >> 0x0000001eU)) 
                                                   | (0x000007feU 
                                                      & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[11U] 
                                                          << 2U) 
                                                         | (2U 
                                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[10U] 
                                                               >> 0x0000001eU))))));
        __VdfgRegularize_hebeb780c_0_191[3U] = ((__VdfgRegularize_hebeb780c_0_192[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_192[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_191[4U] = ((__VdfgRegularize_hebeb780c_0_192[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_192[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_32) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[0U] 
            = __VdfgRegularize_hebeb780c_0_28[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[1U] 
            = __VdfgRegularize_hebeb780c_0_28[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[2U] 
            = ((0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[2U]) 
               | ((0x00000020U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[8U] 
                                  >> 0x00000019U)) 
                  | (0x0000001fU & __VdfgRegularize_hebeb780c_0_28[2U])));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[3U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[3U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[3U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[4U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[4U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[4U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[5U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[5U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[5U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[6U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[6U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[6U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[7U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[7U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[7U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[8U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[8U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[8U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[9U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[9U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[9U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[10U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[10U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[10U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[11U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[11U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[11U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[12U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[12U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[12U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[13U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[13U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[13U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[14U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[14U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[14U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[15U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[15U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[15U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[16U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[16U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[16U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[17U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[17U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[17U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[18U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[18U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[18U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[19U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[19U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_31[19U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[20U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_31[20U]) 
               | (0x000007c0U & __VdfgRegularize_hebeb780c_0_31[20U]));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[0U] 
            = __VdfgRegularize_hebeb780c_0_31[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[1U] 
            = __VdfgRegularize_hebeb780c_0_31[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[2U] 
            = __VdfgRegularize_hebeb780c_0_31[2U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[3U] 
            = __VdfgRegularize_hebeb780c_0_31[3U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[4U] 
            = __VdfgRegularize_hebeb780c_0_31[4U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[5U] 
            = __VdfgRegularize_hebeb780c_0_31[5U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[6U] 
            = __VdfgRegularize_hebeb780c_0_31[6U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[7U] 
            = __VdfgRegularize_hebeb780c_0_31[7U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[8U] 
            = __VdfgRegularize_hebeb780c_0_31[8U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[9U] 
            = __VdfgRegularize_hebeb780c_0_31[9U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[10U] 
            = __VdfgRegularize_hebeb780c_0_31[10U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[11U] 
            = __VdfgRegularize_hebeb780c_0_31[11U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[12U] 
            = __VdfgRegularize_hebeb780c_0_31[12U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[13U] 
            = __VdfgRegularize_hebeb780c_0_31[13U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[14U] 
            = __VdfgRegularize_hebeb780c_0_31[14U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[15U] 
            = __VdfgRegularize_hebeb780c_0_31[15U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[16U] 
            = __VdfgRegularize_hebeb780c_0_31[16U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[17U] 
            = __VdfgRegularize_hebeb780c_0_31[17U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[18U] 
            = __VdfgRegularize_hebeb780c_0_31[18U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[19U] 
            = __VdfgRegularize_hebeb780c_0_31[19U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_33[20U] 
            = __VdfgRegularize_hebeb780c_0_31[20U];
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[2U] 
            = ((__VdfgRegularize_hebeb780c_0_136[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_101) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[3U] 
            = ((__VdfgRegularize_hebeb780c_0_136[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[4U] 
            = ((__VdfgRegularize_hebeb780c_0_136[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[5U] 
            = ((__VdfgRegularize_hebeb780c_0_136[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[6U] 
            = ((__VdfgRegularize_hebeb780c_0_136[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[2U] 
            = ((__VdfgRegularize_hebeb780c_0_136[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_101) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[3U] 
            = ((__VdfgRegularize_hebeb780c_0_136[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[4U] 
            = ((__VdfgRegularize_hebeb780c_0_136[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[5U] 
            = ((__VdfgRegularize_hebeb780c_0_136[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_132[6U] 
            = ((__VdfgRegularize_hebeb780c_0_136[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_136[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[2U] 
            = ((__VdfgRegularize_hebeb780c_0_191[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_100) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[3U] 
            = ((__VdfgRegularize_hebeb780c_0_191[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[4U] 
            = ((__VdfgRegularize_hebeb780c_0_191[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[5U] 
            = ((__VdfgRegularize_hebeb780c_0_191[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[6U] 
            = ((__VdfgRegularize_hebeb780c_0_191[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[2U] 
            = ((__VdfgRegularize_hebeb780c_0_191[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_100) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[3U] 
            = ((__VdfgRegularize_hebeb780c_0_191[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[4U] 
            = ((__VdfgRegularize_hebeb780c_0_191[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[5U] 
            = ((__VdfgRegularize_hebeb780c_0_191[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_190[6U] 
            = ((__VdfgRegularize_hebeb780c_0_191[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_191[4U] 
                                   << 4U));
    }
}

void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_43;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_43);
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_46;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_46);
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_140;
    __VdfgRegularize_hebeb780c_0_140 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_141;
    __VdfgRegularize_hebeb780c_0_141 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_144;
    __VdfgRegularize_hebeb780c_0_144 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_145;
    __VdfgRegularize_hebeb780c_0_145 = 0;
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_146;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_146);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_147;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_147);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_194;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_194);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_195;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_195);
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
            >> 2U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_chan));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
            >> 2U) & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
            >> 0x00000013U) & (IData)(vlSelfRef.__PVT__slv_ar_ready_chan));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
            >> 0x00000013U) & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__slv_req_cut[0U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         << 2U) | (
                                                   ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_53) 
                                                    << 1U) 
                                                   | (1U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
                                                         >> 0x00000012U))));
    vlSelfRef.__PVT__slv_req_cut[1U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         >> 0x0000001eU) 
                                        | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                           << 2U));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0xfffffff0U 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                            >> 0x0000001eU) 
                                           | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                              << 2U)));
    vlSelfRef.__PVT__slv_req_cut[2U] = ((0x0000000fU 
                                         & vlSelfRef.__PVT__slv_req_cut[2U]) 
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                            << 0x0000000eU) 
                                           | (0x00003ff0U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                 >> 0x00000012U))));
    vlSelfRef.__PVT__slv_req_cut[3U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                            >> 0x00000012U)) 
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                            << 0x0000000eU) 
                                           | (0x00003ff0U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                 >> 0x00000012U))));
    vlSelfRef.__PVT__slv_req_cut[4U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                            >> 0x00000012U)) 
                                        | ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                            << 0x00000011U) 
                                           | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_52) 
                                               << 0x00000010U) 
                                              | (0x0000fff0U 
                                                 & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
                                                     << 0x0000000eU) 
                                                    | (0x00003ff0U 
                                                       & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                          >> 0x00000012U)))))));
    vlSelfRef.__PVT__slv_req_cut[5U] = ((0x0000000fU 
                                         & ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                             >> 0x0000000fU) 
                                            | ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_52) 
                                               >> 0x00000010U))) 
                                        | ((0x0001fff0U 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               >> 0x0000000fU)) 
                                           | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                              << 0x00000011U)));
    vlSelfRef.__PVT__slv_req_cut[6U] = (0x01ffffffU 
                                        & ((0x0000000fU 
                                            & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                               >> 0x0000000fU)) 
                                           | ((0x0001fff0U 
                                               & (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  >> 0x0000000fU)) 
                                              | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                 << 0x00000011U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids 
        = ((4U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_116[2U] 
                  >> 6U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                    >> 1U)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                >> 2U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_141 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_140 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_141 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_140 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 2U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids 
        = ((4U & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_115) 
                  >> 5U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                    >> 1U)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                >> 2U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_145 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_144 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_145 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_144 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 2U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
    } else if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full)))) {
        if ((1U & ((vlSelfRef.__PVT__slv_req_cut[0U] 
                    >> 1U) & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied)) 
                              | ((IData)(vlSelfRef.__PVT__slv_ar_select) 
                                 == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select)))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid = 1U;
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q)))) {
        if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
             & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
            if ((((vlSelfRef.__PVT__slv_req_cut[4U] 
                   >> 0x00000010U) & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                                      | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                                         == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
                 & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                    | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                       == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
                vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up = 1U;
            }
        }
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 0U;
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q) {
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
    } else if (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full)) 
                & (7U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))))) {
        if ((((vlSelfRef.__PVT__slv_req_cut[4U] >> 0x00000010U) 
              & ((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                 | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                    == (IData)(vlSelfRef.__PVT__slv_aw_select)))) 
             & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                   == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))))) {
            vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid = 1U;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_139 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_141)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_140) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_141) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_140))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_116[2U] 
                                   >> 8U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_143 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_145)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_144) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_145) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_144))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_115) 
                                   >> 7U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) 
           | (0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_50 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__slv_aw_select)));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_147[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_147[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_147[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_147[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_147[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_147[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_43[0U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[1U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[2U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[3U] = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_43[4U] = (0x00010000U 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_43[5U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                >> 0x0000000fU) 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_43[6U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    } else {
        __VdfgRegularize_hebeb780c_0_43[4U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               << 0x00000011U);
        __VdfgRegularize_hebeb780c_0_43[5U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_43[6U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    }
    __VdfgRegularize_hebeb780c_0_43[7U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[8U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[9U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[10U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[11U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[12U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[13U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[14U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[15U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[16U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[17U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[18U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[19U] = 0U;
    __VdfgRegularize_hebeb780c_0_43[20U] = 0U;
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
                    >> 0x00000012U)));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_7 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__r_idx 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? 2U : (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)) 
                          | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                              >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)))));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d)));
    vlSelfRef.__VdfgRegularize_h9b082aa7_1_3 = ((1U 
                                                 > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                   >> 1U));
    vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o 
        = (IData)((0U != (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_104 
            = (1U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                     >> 0x00000016U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = 2U;
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_104 = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx 
            = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)) 
                     | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                         >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    }
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                    >> 0x00000016U)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_51 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_47 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_49 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (1U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_50) {
        __VdfgRegularize_hebeb780c_0_195[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_195[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_195[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_195[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_195[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_195[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_46[0U] = __VdfgRegularize_hebeb780c_0_43[0U];
    __VdfgRegularize_hebeb780c_0_46[1U] = __VdfgRegularize_hebeb780c_0_43[1U];
    __VdfgRegularize_hebeb780c_0_46[2U] = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                             << 0x0000000eU) 
                                            | (0x00003fc0U 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                  >> 0x00000012U))) 
                                           | (0x0000001fU 
                                              & __VdfgRegularize_hebeb780c_0_43[2U]));
    __VdfgRegularize_hebeb780c_0_46[3U] = ((0x0000003fU 
                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                               >> 0x00000012U)) 
                                           | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                               << 0x0000000eU) 
                                              | (0x00003fc0U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                    >> 0x00000012U))));
    __VdfgRegularize_hebeb780c_0_46[4U] = ((0xffff0000U 
                                            & __VdfgRegularize_hebeb780c_0_46[4U]) 
                                           | ((0x0000003fU 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                  >> 0x00000012U)) 
                                              | (0x0000ffc0U 
                                                 & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
                                                     << 0x0000000eU) 
                                                    | (0x00003fc0U 
                                                       & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                          >> 0x00000012U))))));
    __VdfgRegularize_hebeb780c_0_46[4U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_46[4U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_43[4U]));
    __VdfgRegularize_hebeb780c_0_46[5U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_43[5U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_43[5U]));
    __VdfgRegularize_hebeb780c_0_46[6U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_43[6U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_43[6U]));
    __VdfgRegularize_hebeb780c_0_46[7U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_43[7U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_43[7U]));
    __VdfgRegularize_hebeb780c_0_46[8U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_43[8U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_43[8U]));
    __VdfgRegularize_hebeb780c_0_46[9U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_43[9U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_43[9U]));
    __VdfgRegularize_hebeb780c_0_46[10U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[10U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[10U]));
    __VdfgRegularize_hebeb780c_0_46[11U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[11U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[11U]));
    __VdfgRegularize_hebeb780c_0_46[12U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[12U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[12U]));
    __VdfgRegularize_hebeb780c_0_46[13U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[13U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[13U]));
    __VdfgRegularize_hebeb780c_0_46[14U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[14U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[14U]));
    __VdfgRegularize_hebeb780c_0_46[15U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[15U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[15U]));
    __VdfgRegularize_hebeb780c_0_46[16U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[16U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[16U]));
    __VdfgRegularize_hebeb780c_0_46[17U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[17U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[17U]));
    __VdfgRegularize_hebeb780c_0_46[18U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[18U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[18U]));
    __VdfgRegularize_hebeb780c_0_46[19U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_43[19U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_43[19U]));
    __VdfgRegularize_hebeb780c_0_46[20U] = (0x000007ffU 
                                            & __VdfgRegularize_hebeb780c_0_43[20U]);
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
               >> 0x00000012U)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
             >> 0x00000012U) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_7)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
               >> 0x00000016U)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
             >> 0x00000016U) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))
            ? (((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3) 
                | ((2U > (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                      >> 2U))) ? ((IData)(vlSelfRef.__VdfgRegularize_h9b082aa7_1_3)
                                   ? 1U : 2U) : ((1U 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d))
                                                  ? 0U
                                                  : 
                                                 (((1U 
                                                    <= (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q)) 
                                                   & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                                                      >> 1U))
                                                   ? 1U
                                                   : 2U)))
            : (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_3 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                   >> 0x00000016U));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_106 = ((~ (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_143)) 
                                                  & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_105 = ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
                                                  & (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_143));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_49) {
        __VdfgRegularize_hebeb780c_0_146[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                 << 9U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                   >> 0x00000017U));
        __VdfgRegularize_hebeb780c_0_146[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                 << 9U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                   >> 0x00000017U));
        __VdfgRegularize_hebeb780c_0_146[2U] = ((__VdfgRegularize_hebeb780c_0_147[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
                                                       << 9U) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                         >> 0x00000017U))));
        __VdfgRegularize_hebeb780c_0_146[3U] = ((__VdfgRegularize_hebeb780c_0_147[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_147[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_146[4U] = ((__VdfgRegularize_hebeb780c_0_147[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_147[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_146[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                 << 9U) 
                                                | (0x000001feU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                      >> 0x00000017U)));
        __VdfgRegularize_hebeb780c_0_146[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                    >> 0x00000017U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                    << 9U) 
                                                   | (0x000001feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                         >> 0x00000017U))));
        __VdfgRegularize_hebeb780c_0_146[2U] = ((__VdfgRegularize_hebeb780c_0_147[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                       >> 0x00000017U)) 
                                                   | (0x000007feU 
                                                      & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
                                                          << 9U) 
                                                         | (0x000001feU 
                                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                               >> 0x00000017U))))));
        __VdfgRegularize_hebeb780c_0_146[3U] = ((__VdfgRegularize_hebeb780c_0_147[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_147[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_146[4U] = ((__VdfgRegularize_hebeb780c_0_147[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_147[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_51) {
        __VdfgRegularize_hebeb780c_0_194[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                 << 9U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                   >> 0x00000017U));
        __VdfgRegularize_hebeb780c_0_194[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                 << 9U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                   >> 0x00000017U));
        __VdfgRegularize_hebeb780c_0_194[2U] = ((__VdfgRegularize_hebeb780c_0_195[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
                                                       << 9U) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                         >> 0x00000017U))));
        __VdfgRegularize_hebeb780c_0_194[3U] = ((__VdfgRegularize_hebeb780c_0_195[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_195[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_194[4U] = ((__VdfgRegularize_hebeb780c_0_195[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_195[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_194[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                 << 9U) 
                                                | (0x000001feU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                      >> 0x00000017U)));
        __VdfgRegularize_hebeb780c_0_194[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                    >> 0x00000017U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                    << 9U) 
                                                   | (0x000001feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[16U] 
                                                         >> 0x00000017U))));
        __VdfgRegularize_hebeb780c_0_194[2U] = ((__VdfgRegularize_hebeb780c_0_195[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                       >> 0x00000017U)) 
                                                   | (0x000007feU 
                                                      & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
                                                          << 9U) 
                                                         | (0x000001feU 
                                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[17U] 
                                                               >> 0x00000017U))))));
        __VdfgRegularize_hebeb780c_0_194[3U] = ((__VdfgRegularize_hebeb780c_0_195[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_195[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_194[4U] = ((__VdfgRegularize_hebeb780c_0_195[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_195[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_47) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[0U] 
            = __VdfgRegularize_hebeb780c_0_43[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[1U] 
            = __VdfgRegularize_hebeb780c_0_43[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[2U] 
            = ((0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[2U]) 
               | ((0x00000020U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                  >> 0x00000012U)) 
                  | (0x0000001fU & __VdfgRegularize_hebeb780c_0_43[2U])));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[3U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[3U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[3U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[4U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[4U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[4U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[5U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[5U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[5U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[6U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[6U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[6U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[7U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[7U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[7U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[8U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[8U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[8U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[9U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[9U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[9U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[10U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[10U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[10U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[11U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[11U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[11U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[12U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[12U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[12U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[13U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[13U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[13U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[14U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[14U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[14U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[15U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[15U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[15U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[16U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[16U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[16U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[17U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[17U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[17U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[18U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[18U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[18U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[19U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[19U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_46[19U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[20U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_46[20U]) 
               | (0x000007c0U & __VdfgRegularize_hebeb780c_0_46[20U]));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[0U] 
            = __VdfgRegularize_hebeb780c_0_46[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[1U] 
            = __VdfgRegularize_hebeb780c_0_46[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[2U] 
            = __VdfgRegularize_hebeb780c_0_46[2U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[3U] 
            = __VdfgRegularize_hebeb780c_0_46[3U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[4U] 
            = __VdfgRegularize_hebeb780c_0_46[4U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[5U] 
            = __VdfgRegularize_hebeb780c_0_46[5U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[6U] 
            = __VdfgRegularize_hebeb780c_0_46[6U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[7U] 
            = __VdfgRegularize_hebeb780c_0_46[7U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[8U] 
            = __VdfgRegularize_hebeb780c_0_46[8U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[9U] 
            = __VdfgRegularize_hebeb780c_0_46[9U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[10U] 
            = __VdfgRegularize_hebeb780c_0_46[10U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[11U] 
            = __VdfgRegularize_hebeb780c_0_46[11U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[12U] 
            = __VdfgRegularize_hebeb780c_0_46[12U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[13U] 
            = __VdfgRegularize_hebeb780c_0_46[13U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[14U] 
            = __VdfgRegularize_hebeb780c_0_46[14U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[15U] 
            = __VdfgRegularize_hebeb780c_0_46[15U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[16U] 
            = __VdfgRegularize_hebeb780c_0_46[16U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[17U] 
            = __VdfgRegularize_hebeb780c_0_46[17U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[18U] 
            = __VdfgRegularize_hebeb780c_0_46[18U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[19U] 
            = __VdfgRegularize_hebeb780c_0_46[19U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_48[20U] 
            = __VdfgRegularize_hebeb780c_0_46[20U];
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[2U] 
            = ((__VdfgRegularize_hebeb780c_0_146[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_105) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[3U] 
            = ((__VdfgRegularize_hebeb780c_0_146[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_146[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[4U] 
            = ((__VdfgRegularize_hebeb780c_0_146[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_146[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[5U] 
            = ((__VdfgRegularize_hebeb780c_0_146[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_146[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[6U] 
            = ((__VdfgRegularize_hebeb780c_0_146[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_146[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[2U] 
            = ((__VdfgRegularize_hebeb780c_0_146[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_105) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[3U] 
            = ((__VdfgRegularize_hebeb780c_0_146[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_146[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[4U] 
            = ((__VdfgRegularize_hebeb780c_0_146[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_146[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[5U] 
            = ((__VdfgRegularize_hebeb780c_0_146[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_146[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_142[6U] 
            = ((__VdfgRegularize_hebeb780c_0_146[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_146[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[2U] 
            = ((__VdfgRegularize_hebeb780c_0_194[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_104) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[3U] 
            = ((__VdfgRegularize_hebeb780c_0_194[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_194[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[4U] 
            = ((__VdfgRegularize_hebeb780c_0_194[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_194[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[5U] 
            = ((__VdfgRegularize_hebeb780c_0_194[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_194[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[6U] 
            = ((__VdfgRegularize_hebeb780c_0_194[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_194[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[2U] 
            = ((__VdfgRegularize_hebeb780c_0_194[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_104) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[3U] 
            = ((__VdfgRegularize_hebeb780c_0_194[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_194[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[4U] 
            = ((__VdfgRegularize_hebeb780c_0_194[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_194[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[5U] 
            = ((__VdfgRegularize_hebeb780c_0_194[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_194[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_193[6U] 
            = ((__VdfgRegularize_hebeb780c_0_194[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_194[4U] 
                                   << 4U));
    }
}
