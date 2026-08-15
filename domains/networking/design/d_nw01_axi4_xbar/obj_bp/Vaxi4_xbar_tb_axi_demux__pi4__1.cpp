// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__1\n"); );
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
                                           << 6U)) 
                           | (0x000000ffU & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U]))));
    mst_resps_i[2U] = ((0xfff0ffffU & mst_resps_i[2U]) 
                       | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                             << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                       << 2U)) | ((2U 
                                                   & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                      >> 1U)) 
                                                  | (1U 
                                                     & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                        >> 2U)))) 
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
                                                          << 6U)) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                                         >> 0x00000018U))) 
                                                  << 0x00000014U));
    mst_resps_i[5U] = ((0xfffffff0U & mst_resps_i[5U]) 
                       | (((0x0000fe00U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                           << 6U)) 
                           | ((0x00000100U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                              << 6U)) 
                              | (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                 >> 0x00000018U))) 
                          >> 0x0000000cU));
    mst_resps_i[5U] = ((0xffffff0fU & mst_resps_i[5U]) 
                       | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                             << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                       << 2U)) | ((2U 
                                                   & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                      >> 1U)) 
                                                  | (1U 
                                                     & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                        >> 2U)))) 
                          << 4U));
    mst_resps_i[5U] = ((0x000000ffU & mst_resps_i[5U]) 
                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_116[0U] 
                          << 8U));
    mst_resps_i[6U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_116[0U] 
                        >> 0x00000018U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_116[1U] 
                                           << 8U));
    mst_resps_i[7U] = ((0x0ffe0000U & mst_resps_i[7U]) 
                       | (0x0fffffffU & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_116[1U] 
                                          >> 0x00000018U) 
                                         | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_116[2U] 
                                            << 8U))));
    mst_resps_i[7U] = ((0x0001ffffU & mst_resps_i[7U]) 
                       | (0x0ffe0000U & (((4U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                          << 0x0000001bU) 
                                         | (((4U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                             << 0x0000001aU) 
                                            | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_h247165ad_0_6) 
                                                << 0x00000019U) 
                                               | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_115) 
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_87 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)
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
        vlSelfRef.__VdfgRegularize_hebeb780c_0_88[0U] 
            = __Vtemp_11[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_88[1U] 
            = __Vtemp_11[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_88[2U] 
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
        vlSelfRef.__VdfgRegularize_hebeb780c_0_88[0U] = 0U;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_88[1U] = 0U;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_88[2U] = 0U;
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
                                                   & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_53) 
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
                  & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_52) 
                     & (((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                         | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                            == (IData)(vlSelfRef.__PVT__slv_aw_select))) 
                        & (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                            | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                               == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))) 
                           & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready))))));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_2 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                                & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
                                                    >> 0x00000012U) 
                                                   & (vlSelfRef.__VdfgRegularize_hebeb780c_0_88[0U] 
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

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1)) 
                                       | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1)) 
                                       | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_104) 
                                                     << 2U) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_105) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_106))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                                     << 2U) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_104) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_105) 
                                              | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_106)))) 
                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[15U] 
                                          >> 0x00000016U))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                              | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i)))) 
                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[13U] 
                                          >> 0x00000012U))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[15U] 
                                              >> 0x00000016U)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_104) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_105) 
                                                | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_106)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[13U] 
                                              >> 0x00000012U)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[15U] 
                                              >> 0x00000016U)) 
                                          | ((2U >= (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))
                                              ? ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_104) 
                                                   << 2U) 
                                                  | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_105) 
                                                      << 1U) 
                                                     | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_106))) 
                                                 >> (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))
                                              : (IData)(vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT____Vxrand___0))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[13U] 
                                              >> 0x00000012U)) 
                                          | ((2U >= (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))
                                              ? ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                                   << 2U) 
                                                  | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                      << 1U) 
                                                     | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i))) 
                                                 >> (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))
                                              : (IData)(vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT____Vxrand___0))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 
        = vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 
        = vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
              & (~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[15U] 
                    >> 0x00000016U))));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
              & (~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[13U] 
                    >> 0x00000012U))));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__1\n"); );
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
                = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar_error)
                    ? 2U : (IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar));
        }
        if (vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q 
                = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw_error)
                    ? 2U : (IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw));
        }
        if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[14U] 
                    << 0x0000000cU) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
                                       >> 0x00000014U));
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                    << 0x0000000cU) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[14U] 
                                       >> 0x00000014U));
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = (3U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                         >> 0x00000014U));
        }
        if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[19U] 
                    << 0x0000001dU) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[18U] 
                                       >> 3U));
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                    << 0x0000001dU) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[19U] 
                                       >> 3U));
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = (0x000000ffU & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                                  >> 3U));
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_53 = (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_52 = (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_55 = ((IData)(vlSelfRef.__PVT__slv_ar_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_54 = ((IData)(vlSelfRef.__PVT__slv_aw_ready_chan) 
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

void Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_140;
    __VdfgRegularize_hebeb780c_0_140 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_141;
    __VdfgRegularize_hebeb780c_0_141 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_144;
    __VdfgRegularize_hebeb780c_0_144 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_145;
    __VdfgRegularize_hebeb780c_0_145 = 0;
    // Body
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids 
        = ((4U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_116[2U] 
                  >> 6U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                    >> 1U)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                >> 2U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids 
        = ((4U & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_115) 
                  >> 5U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                    >> 1U)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                >> 2U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_140 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_141 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_140 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_141 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 2U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
    }
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_144 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_145 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_144 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_145 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 2U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
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

void Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_43;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_43);
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_46;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_46);
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
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
                    >> 0x00000012U)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_104 = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                   >> 0x00000016U) 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                    >> 0x00000016U)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
               >> 0x00000016U)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
               >> 0x00000012U)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o));
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_3 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[15U] 
                                                   >> 0x00000016U));
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_106 = ((~ (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_143)) 
                                                  & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_105 = ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
                                                  & (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_143));
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

void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_58;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_58);
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_61;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_61);
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_150;
    __VdfgRegularize_hebeb780c_0_150 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_151;
    __VdfgRegularize_hebeb780c_0_151 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_154;
    __VdfgRegularize_hebeb780c_0_154 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_155;
    __VdfgRegularize_hebeb780c_0_155 = 0;
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_156;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_156);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_157;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_157);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_197;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_197);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_198;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_198);
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
            >> 0x0000001bU) & (IData)(vlSelfRef.__PVT__slv_aw_ready_chan));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
            >> 0x0000001bU) & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
            >> 0x0000000cU) & (IData)(vlSelfRef.__PVT__slv_ar_ready_chan));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
            >> 0x0000000cU) & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__slv_req_cut[0U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         << 2U) | (
                                                   ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_68) 
                                                    << 1U) 
                                                   | (1U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                                                         >> 0x0000000bU))));
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
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                            << 0x00000015U) 
                                           | (0x001ffff0U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                 >> 0x0000000bU))));
    vlSelfRef.__PVT__slv_req_cut[3U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                            >> 0x0000000bU)) 
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                            << 0x00000015U) 
                                           | (0x001ffff0U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 >> 0x0000000bU))));
    vlSelfRef.__PVT__slv_req_cut[4U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                            >> 0x0000000bU)) 
                                        | ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                            << 0x00000011U) 
                                           | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_67) 
                                               << 0x00000010U) 
                                              | (0x0000fff0U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                    >> 0x0000000bU)))));
    vlSelfRef.__PVT__slv_req_cut[5U] = ((0x0000000fU 
                                         & ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                             >> 0x0000000fU) 
                                            | ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_67) 
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
        = ((4U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[2U] 
                  >> 6U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                    >> 2U)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                >> 3U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_151 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_150 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_151 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 3U));
        __VdfgRegularize_hebeb780c_0_150 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 3U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
    }
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids 
        = ((4U & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_117) 
                  >> 5U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                    >> 2U)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                >> 3U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_155 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_154 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_155 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 3U));
        __VdfgRegularize_hebeb780c_0_154 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 3U));
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_149 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_151)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_150) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_151) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_150))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[2U] 
                                   >> 8U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_153 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_155)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_154) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_155) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_154))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_117) 
                                   >> 7U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) 
           | (0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_65 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__slv_aw_select)));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_157[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_157[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_157[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_157[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_157[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_157[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_58[0U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[1U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[2U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[3U] = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_58[4U] = (0x00010000U 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_58[5U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                >> 0x0000000fU) 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_58[6U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    } else {
        __VdfgRegularize_hebeb780c_0_58[4U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               << 0x00000011U);
        __VdfgRegularize_hebeb780c_0_58[5U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_58[6U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    }
    __VdfgRegularize_hebeb780c_0_58[7U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[8U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[9U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[10U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[11U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[12U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[13U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[14U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[15U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[16U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[17U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[18U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[19U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[20U] = 0U;
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                    >> 0x0000000bU)));
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
        vlSelfRef.__VdfgRegularize_hebeb780c_0_108 
            = (1U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                     >> 0x0000000fU));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx = 2U;
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_108 = 0U;
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__b_idx 
            = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d)) 
                     | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d) 
                         >> 1U) & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    }
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                    >> 0x0000000fU)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_66 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_62 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_64 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (1U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_65) {
        __VdfgRegularize_hebeb780c_0_198[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_198[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_198[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_198[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_198[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_198[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_61[0U] = __VdfgRegularize_hebeb780c_0_58[0U];
    __VdfgRegularize_hebeb780c_0_61[1U] = __VdfgRegularize_hebeb780c_0_58[1U];
    __VdfgRegularize_hebeb780c_0_61[2U] = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                             << 0x00000015U) 
                                            | (0x001fffc0U 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                  >> 0x0000000bU))) 
                                           | (0x0000001fU 
                                              & __VdfgRegularize_hebeb780c_0_58[2U]));
    __VdfgRegularize_hebeb780c_0_61[3U] = ((0x0000003fU 
                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                               >> 0x0000000bU)) 
                                           | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                               << 0x00000015U) 
                                              | (0x001fffc0U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                    >> 0x0000000bU))));
    __VdfgRegularize_hebeb780c_0_61[4U] = ((0xffff0000U 
                                            & __VdfgRegularize_hebeb780c_0_61[4U]) 
                                           | ((0x0000003fU 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                  >> 0x0000000bU)) 
                                              | (0x0000ffc0U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                    >> 0x0000000bU))));
    __VdfgRegularize_hebeb780c_0_61[4U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_61[4U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[4U]));
    __VdfgRegularize_hebeb780c_0_61[5U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[5U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[5U]));
    __VdfgRegularize_hebeb780c_0_61[6U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[6U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[6U]));
    __VdfgRegularize_hebeb780c_0_61[7U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[7U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[7U]));
    __VdfgRegularize_hebeb780c_0_61[8U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[8U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[8U]));
    __VdfgRegularize_hebeb780c_0_61[9U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[9U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[9U]));
    __VdfgRegularize_hebeb780c_0_61[10U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[10U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[10U]));
    __VdfgRegularize_hebeb780c_0_61[11U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[11U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[11U]));
    __VdfgRegularize_hebeb780c_0_61[12U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[12U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[12U]));
    __VdfgRegularize_hebeb780c_0_61[13U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[13U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[13U]));
    __VdfgRegularize_hebeb780c_0_61[14U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[14U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[14U]));
    __VdfgRegularize_hebeb780c_0_61[15U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[15U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[15U]));
    __VdfgRegularize_hebeb780c_0_61[16U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[16U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[16U]));
    __VdfgRegularize_hebeb780c_0_61[17U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[17U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[17U]));
    __VdfgRegularize_hebeb780c_0_61[18U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[18U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[18U]));
    __VdfgRegularize_hebeb780c_0_61[19U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[19U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[19U]));
    __VdfgRegularize_hebeb780c_0_61[20U] = (0x000007ffU 
                                            & __VdfgRegularize_hebeb780c_0_58[20U]);
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
               >> 0x0000000bU)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
             >> 0x0000000bU) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))
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
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
               >> 0x0000000fU)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
             >> 0x0000000fU) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_1 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                   >> 0x0000000fU));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_110 = ((~ (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_153)) 
                                                  & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_109 = ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
                                                  & (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_153));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_64) {
        __VdfgRegularize_hebeb780c_0_156[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 << 0x00000010U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                   >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_156[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                 << 0x00000010U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                   >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_156[2U] = ((__VdfgRegularize_hebeb780c_0_157[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                      >> 0x00000010U)));
        __VdfgRegularize_hebeb780c_0_156[3U] = ((__VdfgRegularize_hebeb780c_0_157[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_157[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_156[4U] = ((__VdfgRegularize_hebeb780c_0_157[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_157[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_156[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 << 0x00000010U) 
                                                | (0x0000fffeU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                      >> 0x00000010U)));
        __VdfgRegularize_hebeb780c_0_156[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                    >> 0x00000010U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                    << 0x00000010U) 
                                                   | (0x0000fffeU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                         >> 0x00000010U))));
        __VdfgRegularize_hebeb780c_0_156[2U] = ((__VdfgRegularize_hebeb780c_0_157[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                       >> 0x00000010U)) 
                                                   | (0x000007feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                         >> 0x00000010U))));
        __VdfgRegularize_hebeb780c_0_156[3U] = ((__VdfgRegularize_hebeb780c_0_157[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_157[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_156[4U] = ((__VdfgRegularize_hebeb780c_0_157[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_157[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_66) {
        __VdfgRegularize_hebeb780c_0_197[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 << 0x00000010U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                   >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_197[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                 << 0x00000010U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                   >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_197[2U] = ((__VdfgRegularize_hebeb780c_0_198[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                      >> 0x00000010U)));
        __VdfgRegularize_hebeb780c_0_197[3U] = ((__VdfgRegularize_hebeb780c_0_198[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_198[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_197[4U] = ((__VdfgRegularize_hebeb780c_0_198[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_198[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_197[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 << 0x00000010U) 
                                                | (0x0000fffeU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                      >> 0x00000010U)));
        __VdfgRegularize_hebeb780c_0_197[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                    >> 0x00000010U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                    << 0x00000010U) 
                                                   | (0x0000fffeU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                         >> 0x00000010U))));
        __VdfgRegularize_hebeb780c_0_197[2U] = ((__VdfgRegularize_hebeb780c_0_198[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                       >> 0x00000010U)) 
                                                   | (0x000007feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                         >> 0x00000010U))));
        __VdfgRegularize_hebeb780c_0_197[3U] = ((__VdfgRegularize_hebeb780c_0_198[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_198[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_197[4U] = ((__VdfgRegularize_hebeb780c_0_198[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_198[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_62) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[0U] 
            = __VdfgRegularize_hebeb780c_0_58[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[1U] 
            = __VdfgRegularize_hebeb780c_0_58[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[2U] 
            = ((0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[2U]) 
               | ((0x00000020U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                  >> 0x0000000bU)) 
                  | (0x0000001fU & __VdfgRegularize_hebeb780c_0_58[2U])));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[3U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[3U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[3U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[4U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[4U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[4U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[5U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[5U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[5U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[6U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[6U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[6U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[7U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[7U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[7U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[8U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[8U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[8U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[9U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[9U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[9U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[10U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[10U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[10U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[11U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[11U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[11U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[12U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[12U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[12U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[13U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[13U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[13U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[14U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[14U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[14U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[15U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[15U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[15U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[16U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[16U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[16U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[17U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[17U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[17U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[18U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[18U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[18U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[19U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[19U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[19U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[20U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[20U]) 
               | (0x000007c0U & __VdfgRegularize_hebeb780c_0_61[20U]));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[0U] 
            = __VdfgRegularize_hebeb780c_0_61[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[1U] 
            = __VdfgRegularize_hebeb780c_0_61[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[2U] 
            = __VdfgRegularize_hebeb780c_0_61[2U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[3U] 
            = __VdfgRegularize_hebeb780c_0_61[3U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[4U] 
            = __VdfgRegularize_hebeb780c_0_61[4U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[5U] 
            = __VdfgRegularize_hebeb780c_0_61[5U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[6U] 
            = __VdfgRegularize_hebeb780c_0_61[6U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[7U] 
            = __VdfgRegularize_hebeb780c_0_61[7U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[8U] 
            = __VdfgRegularize_hebeb780c_0_61[8U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[9U] 
            = __VdfgRegularize_hebeb780c_0_61[9U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[10U] 
            = __VdfgRegularize_hebeb780c_0_61[10U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[11U] 
            = __VdfgRegularize_hebeb780c_0_61[11U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[12U] 
            = __VdfgRegularize_hebeb780c_0_61[12U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[13U] 
            = __VdfgRegularize_hebeb780c_0_61[13U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[14U] 
            = __VdfgRegularize_hebeb780c_0_61[14U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[15U] 
            = __VdfgRegularize_hebeb780c_0_61[15U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[16U] 
            = __VdfgRegularize_hebeb780c_0_61[16U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[17U] 
            = __VdfgRegularize_hebeb780c_0_61[17U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[18U] 
            = __VdfgRegularize_hebeb780c_0_61[18U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[19U] 
            = __VdfgRegularize_hebeb780c_0_61[19U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[20U] 
            = __VdfgRegularize_hebeb780c_0_61[20U];
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[2U] 
            = ((__VdfgRegularize_hebeb780c_0_156[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_109) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[3U] 
            = ((__VdfgRegularize_hebeb780c_0_156[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[4U] 
            = ((__VdfgRegularize_hebeb780c_0_156[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[5U] 
            = ((__VdfgRegularize_hebeb780c_0_156[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[6U] 
            = ((__VdfgRegularize_hebeb780c_0_156[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[2U] 
            = ((__VdfgRegularize_hebeb780c_0_156[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_109) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[3U] 
            = ((__VdfgRegularize_hebeb780c_0_156[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[4U] 
            = ((__VdfgRegularize_hebeb780c_0_156[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[5U] 
            = ((__VdfgRegularize_hebeb780c_0_156[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[6U] 
            = ((__VdfgRegularize_hebeb780c_0_156[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[2U] 
            = ((__VdfgRegularize_hebeb780c_0_197[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_108) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[3U] 
            = ((__VdfgRegularize_hebeb780c_0_197[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[4U] 
            = ((__VdfgRegularize_hebeb780c_0_197[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[5U] 
            = ((__VdfgRegularize_hebeb780c_0_197[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[6U] 
            = ((__VdfgRegularize_hebeb780c_0_197[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[2U] 
            = ((__VdfgRegularize_hebeb780c_0_197[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_108) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[3U] 
            = ((__VdfgRegularize_hebeb780c_0_197[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[4U] 
            = ((__VdfgRegularize_hebeb780c_0_197[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[5U] 
            = ((__VdfgRegularize_hebeb780c_0_197[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[6U] 
            = ((__VdfgRegularize_hebeb780c_0_197[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[4U] 
                                   << 4U));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_11 = (1U 
                                                 & (((((2U 
                                                        & (vlSelfRef.__VdfgRegularize_hebeb780c_0_152[2U] 
                                                           >> 3U)) 
                                                       | (1U 
                                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[2U] 
                                                             >> 4U))) 
                                                      << 2U) 
                                                     | ((2U 
                                                         & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[2U] 
                                                            >> 3U)) 
                                                        | (1U 
                                                           & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[2U] 
                                                              >> 4U)))) 
                                                    >> (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__w_fifo_data)));
}

void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__1\n"); );
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
                                           << 5U)) 
                           | (0x000000ffU & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U]))));
    mst_resps_i[2U] = ((0xfff0ffffU & mst_resps_i[2U]) 
                       | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                             << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                       << 2U)) | ((2U 
                                                   & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                      >> 2U)) 
                                                  | (1U 
                                                     & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                        >> 3U)))) 
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
                                                          << 5U)) 
                                                      | (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                                         >> 0x00000018U))) 
                                                  << 0x00000014U));
    mst_resps_i[5U] = ((0xfffffff0U & mst_resps_i[5U]) 
                       | (((0x0000fe00U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                           << 6U)) 
                           | ((0x00000100U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                              << 5U)) 
                              | (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[4U] 
                                 >> 0x00000018U))) 
                          >> 0x0000000cU));
    mst_resps_i[5U] = ((0xffffff0fU & mst_resps_i[5U]) 
                       | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                             << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                       << 2U)) | ((2U 
                                                   & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                      >> 2U)) 
                                                  | (1U 
                                                     & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                        >> 3U)))) 
                          << 4U));
    mst_resps_i[5U] = ((0x000000ffU & mst_resps_i[5U]) 
                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[0U] 
                          << 8U));
    mst_resps_i[6U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[0U] 
                        >> 0x00000018U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[1U] 
                                           << 8U));
    mst_resps_i[7U] = ((0x0ffe0000U & mst_resps_i[7U]) 
                       | (0x0fffffffU & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[1U] 
                                          >> 0x00000018U) 
                                         | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[2U] 
                                            << 8U))));
    mst_resps_i[7U] = ((0x0001ffffU & mst_resps_i[7U]) 
                       | (0x0ffe0000U & (((4U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                          << 0x0000001bU) 
                                         | (((4U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                             << 0x0000001aU) 
                                            | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_h247165ad_0_6) 
                                                << 0x00000019U) 
                                               | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_117) 
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_93 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)
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
        vlSelfRef.__VdfgRegularize_hebeb780c_0_94[0U] 
            = __Vtemp_11[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_94[1U] 
            = __Vtemp_11[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_94[2U] 
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
        vlSelfRef.__VdfgRegularize_hebeb780c_0_94[0U] = 0U;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_94[1U] = 0U;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_94[2U] = 0U;
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
                                                   & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_68) 
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
                  & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_67) 
                     & (((0U == (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))) 
                         | ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select) 
                            == (IData)(vlSelfRef.__PVT__slv_aw_select))) 
                        & (((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied)) 
                            | ((IData)(vlSelfRef.__PVT__slv_aw_select) 
                               == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select))) 
                           & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__aw_ready))))));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_0 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                                & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                                                    >> 0x0000000bU) 
                                                   & (vlSelfRef.__VdfgRegularize_hebeb780c_0_94[0U] 
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

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1)) 
                                       | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1)) 
                                       | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_108) 
                                                     << 2U) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_109) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_110))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                                     << 2U) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_108) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_109) 
                                              | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_110)))) 
                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[22U] 
                                          >> 0x0000000fU))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                              | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i)))) 
                                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[20U] 
                                          >> 0x0000000bU))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[22U] 
                                              >> 0x0000000fU)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_108) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_109) 
                                                | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_110)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[20U] 
                                              >> 0x0000000bU)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[22U] 
                                              >> 0x0000000fU)) 
                                          | ((2U >= (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))
                                              ? ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_108) 
                                                   << 2U) 
                                                  | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_109) 
                                                      << 1U) 
                                                     | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_110))) 
                                                 >> (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx))
                                              : (IData)(vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT____Vxrand___0))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_b_mux.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o)) 
                                       | ((~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[20U] 
                                              >> 0x0000000bU)) 
                                          | ((2U >= (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))
                                              ? ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0) 
                                                   << 2U) 
                                                  | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                      << 1U) 
                                                     | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i))) 
                                                 >> (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx))
                                              : (IData)(vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT____Vxrand___0))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_demux.i_demux_simple.genblk1.i_r_mux.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1 
        = vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1 
        = vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
              & (~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[22U] 
                    >> 0x0000000fU))));
    vlSelfRef.i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
              & (~ (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__Vsampled_TOP__axi4_xbar_tb__DOT__mst_req[20U] 
                    >> 0x0000000bU))));
}

void Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__1\n"); );
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
                = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar_error)
                    ? 2U : (IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar));
        }
        if (vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q 
                = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw_error)
                    ? 2U : (IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw));
        }
        if (vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[21U] 
                    << 0x00000013U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                                       >> 0x0000000dU));
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                    << 0x00000013U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[21U] 
                                       >> 0x0000000dU));
            vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = (3U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                         >> 0x0000000dU));
        }
        if (vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[25U] 
                    << 4U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                              >> 0x0000001cU));
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[26U] 
                    << 4U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[25U] 
                              >> 0x0000001cU));
            vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = (0x000000ffU & ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[27U] 
                                   << 4U) | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[26U] 
                                             >> 0x0000001cU)));
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_68 = (((IData)(vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_67 = (((IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                  | (IData)(vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                    | (IData)(vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_70 = ((IData)(vlSelfRef.__PVT__slv_ar_ready_chan) 
                                                 & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_69 = ((IData)(vlSelfRef.__PVT__slv_aw_ready_chan) 
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

void Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_150;
    __VdfgRegularize_hebeb780c_0_150 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_151;
    __VdfgRegularize_hebeb780c_0_151 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_154;
    __VdfgRegularize_hebeb780c_0_154 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_155;
    __VdfgRegularize_hebeb780c_0_155 = 0;
    // Body
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids 
        = ((4U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[2U] 
                  >> 6U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                    >> 2U)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                >> 3U))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids 
        = ((4U & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_117) 
                  >> 5U)) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                    >> 2U)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                >> 3U))));
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_150 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_151 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_150 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 3U));
        __VdfgRegularize_hebeb780c_0_151 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_2 
                                                  >> 3U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
    }
    if (vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_154 = (1U & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_155 = (1U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_154 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 3U));
        __VdfgRegularize_hebeb780c_0_155 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_h591265a2_0_1 
                                                  >> 3U));
        vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_149 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_151)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_150) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_151) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_150))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_118[2U] 
                                   >> 8U)) & ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q) 
                                              >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_153 = (1U 
                                                  & ((~ (IData)(__VdfgRegularize_hebeb780c_0_155)) 
                                                     | ((IData)(__VdfgRegularize_hebeb780c_0_154) 
                                                        & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_155) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_154))) 
                 | (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q)
                      ? ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                         >> 2U) : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_hebeb780c_0_117) 
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

void Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_demux__pi4___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_58;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_58);
    VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_61;
    VL_ZERO_W(651, __VdfgRegularize_hebeb780c_0_61);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_156;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_156);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_157;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_157);
    VlWide<5>/*147:0*/ __VdfgRegularize_hebeb780c_0_197;
    VL_ZERO_W(148, __VdfgRegularize_hebeb780c_0_197);
    VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_198;
    VL_ZERO_W(73, __VdfgRegularize_hebeb780c_0_198);
    // Body
    vlSelfRef.__PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
            >> 0x0000001bU) & (IData)(vlSelfRef.__PVT__slv_aw_ready_chan));
    vlSelfRef.__PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
            >> 0x0000001bU) & (IData)(vlSelfRef.__PVT__slv_aw_ready_sel));
    vlSelfRef.__PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
            >> 0x0000000cU) & (IData)(vlSelfRef.__PVT__slv_ar_ready_chan));
    vlSelfRef.__PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
            >> 0x0000000cU) & (IData)(vlSelfRef.__PVT__slv_ar_ready_sel));
    vlSelfRef.__PVT__slv_req_cut[0U] = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                                         << 2U) | (
                                                   ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_68) 
                                                    << 1U) 
                                                   | (1U 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                                                         >> 0x0000000bU))));
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
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                            << 0x00000015U) 
                                           | (0x001ffff0U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                 >> 0x0000000bU))));
    vlSelfRef.__PVT__slv_req_cut[3U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                            >> 0x0000000bU)) 
                                        | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                            << 0x00000015U) 
                                           | (0x001ffff0U 
                                              & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 >> 0x0000000bU))));
    vlSelfRef.__PVT__slv_req_cut[4U] = ((0x0000000fU 
                                         & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                            >> 0x0000000bU)) 
                                        | ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                            << 0x00000011U) 
                                           | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_67) 
                                               << 0x00000010U) 
                                              | (0x0000fff0U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                    >> 0x0000000bU)))));
    vlSelfRef.__PVT__slv_req_cut[5U] = ((0x0000000fU 
                                         & ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                             >> 0x0000000fU) 
                                            | ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_67) 
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
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                    >> 0x0000000bU)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_108 = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                   >> 0x0000000fU) 
                                                  & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                    >> 0x0000000fU)));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
               >> 0x0000000fU)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
               >> 0x0000000bU)) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
             >> 0x0000000fU) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))
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
        = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
             >> 0x0000000bU) & (IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o))
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_1 = ((IData)(vlSelfRef.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o) 
                                                & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                   >> 0x0000000fU));
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
    vlSelfRef.__VdfgRegularize_hebeb780c_0_110 = ((~ (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_153)) 
                                                  & (IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_109 = ((IData)(__PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
                                                  & (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_153));
    vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid 
        = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up) 
           | (0U != (7U & (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_65 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__slv_aw_select)));
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_157[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_157[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_157[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_157[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_157[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_157[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_58[0U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[1U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[2U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[3U] = 0U;
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid) 
         & (0U == (IData)(vlSelfRef.__PVT__slv_aw_select)))) {
        __VdfgRegularize_hebeb780c_0_58[4U] = (0x00010000U 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_58[5U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U])) 
                                                >> 0x0000000fU) 
                                               | (((0xffff8000U 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                   | (0x00007fffU 
                                                      & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_58[6U] = ((((0xffff8000U 
                                                  & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U]) 
                                                 | (0x00007fffU 
                                                    & vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U])) 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    } else {
        __VdfgRegularize_hebeb780c_0_58[4U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                               << 0x00000011U);
        __VdfgRegularize_hebeb780c_0_58[5U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                  << 0x00000011U));
        __VdfgRegularize_hebeb780c_0_58[6U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                >> 0x0000000fU) 
                                               | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                  << 0x00000011U));
    }
    __VdfgRegularize_hebeb780c_0_58[7U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[8U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[9U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[10U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[11U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[12U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[13U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[14U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[15U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[16U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[17U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[18U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[19U] = 0U;
    __VdfgRegularize_hebeb780c_0_58[20U] = 0U;
    vlSelfRef.__VdfgRegularize_hebeb780c_0_66 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_62 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_64 = ((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid) 
                                                 & (1U 
                                                    == (IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__w_select)));
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_65) {
        __VdfgRegularize_hebeb780c_0_198[0U] = (1U 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_198[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_198[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    } else {
        __VdfgRegularize_hebeb780c_0_198[0U] = (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                << 1U);
        __VdfgRegularize_hebeb780c_0_198[1U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[0U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                   << 1U));
        __VdfgRegularize_hebeb780c_0_198[2U] = ((vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[1U] 
                                                 >> 0x0000001fU) 
                                                | (vlSelfRef.__Vcellout__i_aw_spill_reg__data_o[2U] 
                                                   << 1U));
    }
    __VdfgRegularize_hebeb780c_0_61[0U] = __VdfgRegularize_hebeb780c_0_58[0U];
    __VdfgRegularize_hebeb780c_0_61[1U] = __VdfgRegularize_hebeb780c_0_58[1U];
    __VdfgRegularize_hebeb780c_0_61[2U] = (((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                             << 0x00000015U) 
                                            | (0x001fffc0U 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                  >> 0x0000000bU))) 
                                           | (0x0000001fU 
                                              & __VdfgRegularize_hebeb780c_0_58[2U]));
    __VdfgRegularize_hebeb780c_0_61[3U] = ((0x0000003fU 
                                            & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                               >> 0x0000000bU)) 
                                           | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                               << 0x00000015U) 
                                              | (0x001fffc0U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                    >> 0x0000000bU))));
    __VdfgRegularize_hebeb780c_0_61[4U] = ((0xffff0000U 
                                            & __VdfgRegularize_hebeb780c_0_61[4U]) 
                                           | ((0x0000003fU 
                                               & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                  >> 0x0000000bU)) 
                                              | (0x0000ffc0U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                    >> 0x0000000bU))));
    __VdfgRegularize_hebeb780c_0_61[4U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_61[4U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[4U]));
    __VdfgRegularize_hebeb780c_0_61[5U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[5U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[5U]));
    __VdfgRegularize_hebeb780c_0_61[6U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[6U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[6U]));
    __VdfgRegularize_hebeb780c_0_61[7U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[7U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[7U]));
    __VdfgRegularize_hebeb780c_0_61[8U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[8U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[8U]));
    __VdfgRegularize_hebeb780c_0_61[9U] = ((0x0000ffffU 
                                            & __VdfgRegularize_hebeb780c_0_58[9U]) 
                                           | (0xffff0000U 
                                              & __VdfgRegularize_hebeb780c_0_58[9U]));
    __VdfgRegularize_hebeb780c_0_61[10U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[10U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[10U]));
    __VdfgRegularize_hebeb780c_0_61[11U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[11U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[11U]));
    __VdfgRegularize_hebeb780c_0_61[12U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[12U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[12U]));
    __VdfgRegularize_hebeb780c_0_61[13U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[13U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[13U]));
    __VdfgRegularize_hebeb780c_0_61[14U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[14U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[14U]));
    __VdfgRegularize_hebeb780c_0_61[15U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[15U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[15U]));
    __VdfgRegularize_hebeb780c_0_61[16U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[16U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[16U]));
    __VdfgRegularize_hebeb780c_0_61[17U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[17U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[17U]));
    __VdfgRegularize_hebeb780c_0_61[18U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[18U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[18U]));
    __VdfgRegularize_hebeb780c_0_61[19U] = ((0x0000ffffU 
                                             & __VdfgRegularize_hebeb780c_0_58[19U]) 
                                            | (0xffff0000U 
                                               & __VdfgRegularize_hebeb780c_0_58[19U]));
    __VdfgRegularize_hebeb780c_0_61[20U] = (0x000007ffU 
                                            & __VdfgRegularize_hebeb780c_0_58[20U]);
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_64) {
        __VdfgRegularize_hebeb780c_0_156[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 << 0x00000010U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                   >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_156[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                 << 0x00000010U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                   >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_156[2U] = ((__VdfgRegularize_hebeb780c_0_157[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                      >> 0x00000010U)));
        __VdfgRegularize_hebeb780c_0_156[3U] = ((__VdfgRegularize_hebeb780c_0_157[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_157[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_156[4U] = ((__VdfgRegularize_hebeb780c_0_157[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_157[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_156[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 << 0x00000010U) 
                                                | (0x0000fffeU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                      >> 0x00000010U)));
        __VdfgRegularize_hebeb780c_0_156[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                    >> 0x00000010U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                    << 0x00000010U) 
                                                   | (0x0000fffeU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                         >> 0x00000010U))));
        __VdfgRegularize_hebeb780c_0_156[2U] = ((__VdfgRegularize_hebeb780c_0_157[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                       >> 0x00000010U)) 
                                                   | (0x000007feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                         >> 0x00000010U))));
        __VdfgRegularize_hebeb780c_0_156[3U] = ((__VdfgRegularize_hebeb780c_0_157[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_157[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_156[4U] = ((__VdfgRegularize_hebeb780c_0_157[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_157[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_66) {
        __VdfgRegularize_hebeb780c_0_197[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 << 0x00000010U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                   >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_197[1U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                 << 0x00000010U) 
                                                | (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                   >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_197[2U] = ((__VdfgRegularize_hebeb780c_0_198[0U] 
                                                 << 0x0000000bU) 
                                                | (0x000007ffU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                      >> 0x00000010U)));
        __VdfgRegularize_hebeb780c_0_197[3U] = ((__VdfgRegularize_hebeb780c_0_198[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_198[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_197[4U] = ((__VdfgRegularize_hebeb780c_0_198[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_198[2U] 
                                                   << 0x0000000bU));
    } else {
        __VdfgRegularize_hebeb780c_0_197[0U] = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                 << 0x00000010U) 
                                                | (0x0000fffeU 
                                                   & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                                      >> 0x00000010U)));
        __VdfgRegularize_hebeb780c_0_197[1U] = ((1U 
                                                 & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                    >> 0x00000010U)) 
                                                | ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                    << 0x00000010U) 
                                                   | (0x0000fffeU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[23U] 
                                                         >> 0x00000010U))));
        __VdfgRegularize_hebeb780c_0_197[2U] = ((__VdfgRegularize_hebeb780c_0_198[0U] 
                                                 << 0x0000000bU) 
                                                | ((1U 
                                                    & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                       >> 0x00000010U)) 
                                                   | (0x000007feU 
                                                      & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[24U] 
                                                         >> 0x00000010U))));
        __VdfgRegularize_hebeb780c_0_197[3U] = ((__VdfgRegularize_hebeb780c_0_198[0U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_198[1U] 
                                                   << 0x0000000bU));
        __VdfgRegularize_hebeb780c_0_197[4U] = ((__VdfgRegularize_hebeb780c_0_198[1U] 
                                                 >> 0x00000015U) 
                                                | (__VdfgRegularize_hebeb780c_0_198[2U] 
                                                   << 0x0000000bU));
    }
    if (vlSelfRef.__VdfgRegularize_hebeb780c_0_62) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[0U] 
            = __VdfgRegularize_hebeb780c_0_58[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[1U] 
            = __VdfgRegularize_hebeb780c_0_58[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[2U] 
            = ((0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[2U]) 
               | ((0x00000020U & (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[22U] 
                                  >> 0x0000000bU)) 
                  | (0x0000001fU & __VdfgRegularize_hebeb780c_0_58[2U])));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[3U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[3U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[3U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[4U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[4U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[4U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[5U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[5U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[5U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[6U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[6U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[6U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[7U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[7U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[7U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[8U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[8U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[8U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[9U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[9U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[9U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[10U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[10U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[10U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[11U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[11U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[11U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[12U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[12U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[12U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[13U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[13U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[13U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[14U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[14U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[14U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[15U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[15U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[15U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[16U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[16U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[16U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[17U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[17U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[17U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[18U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[18U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[18U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[19U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[19U]) 
               | (0xffffffc0U & __VdfgRegularize_hebeb780c_0_61[19U]));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[20U] 
            = ((0x0000003fU & __VdfgRegularize_hebeb780c_0_61[20U]) 
               | (0x000007c0U & __VdfgRegularize_hebeb780c_0_61[20U]));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[0U] 
            = __VdfgRegularize_hebeb780c_0_61[0U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[1U] 
            = __VdfgRegularize_hebeb780c_0_61[1U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[2U] 
            = __VdfgRegularize_hebeb780c_0_61[2U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[3U] 
            = __VdfgRegularize_hebeb780c_0_61[3U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[4U] 
            = __VdfgRegularize_hebeb780c_0_61[4U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[5U] 
            = __VdfgRegularize_hebeb780c_0_61[5U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[6U] 
            = __VdfgRegularize_hebeb780c_0_61[6U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[7U] 
            = __VdfgRegularize_hebeb780c_0_61[7U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[8U] 
            = __VdfgRegularize_hebeb780c_0_61[8U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[9U] 
            = __VdfgRegularize_hebeb780c_0_61[9U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[10U] 
            = __VdfgRegularize_hebeb780c_0_61[10U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[11U] 
            = __VdfgRegularize_hebeb780c_0_61[11U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[12U] 
            = __VdfgRegularize_hebeb780c_0_61[12U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[13U] 
            = __VdfgRegularize_hebeb780c_0_61[13U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[14U] 
            = __VdfgRegularize_hebeb780c_0_61[14U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[15U] 
            = __VdfgRegularize_hebeb780c_0_61[15U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[16U] 
            = __VdfgRegularize_hebeb780c_0_61[16U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[17U] 
            = __VdfgRegularize_hebeb780c_0_61[17U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[18U] 
            = __VdfgRegularize_hebeb780c_0_61[18U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[19U] 
            = __VdfgRegularize_hebeb780c_0_61[19U];
        vlSelfRef.__VdfgRegularize_hebeb780c_0_63[20U] 
            = __VdfgRegularize_hebeb780c_0_61[20U];
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (1U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[2U] 
            = ((__VdfgRegularize_hebeb780c_0_156[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_109) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[3U] 
            = ((__VdfgRegularize_hebeb780c_0_156[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[4U] 
            = ((__VdfgRegularize_hebeb780c_0_156[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[5U] 
            = ((__VdfgRegularize_hebeb780c_0_156[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[6U] 
            = ((__VdfgRegularize_hebeb780c_0_156[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[2U] 
            = ((__VdfgRegularize_hebeb780c_0_156[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_109) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[3U] 
            = ((__VdfgRegularize_hebeb780c_0_156[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[4U] 
            = ((__VdfgRegularize_hebeb780c_0_156[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[5U] 
            = ((__VdfgRegularize_hebeb780c_0_156[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_152[6U] 
            = ((__VdfgRegularize_hebeb780c_0_156[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_156[4U] 
                                   << 4U));
    }
    if (((IData)(vlSelfRef.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
         & (2U == (IData)(vlSelfRef.__PVT__slv_ar_select)))) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[0U] 
            = (1U | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[2U] 
            = ((__VdfgRegularize_hebeb780c_0_197[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_108) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[3U] 
            = ((__VdfgRegularize_hebeb780c_0_197[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[4U] 
            = ((__VdfgRegularize_hebeb780c_0_197[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[5U] 
            = ((__VdfgRegularize_hebeb780c_0_197[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[6U] 
            = ((__VdfgRegularize_hebeb780c_0_197[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[4U] 
                                   << 4U));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[0U] 
            = (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[1U] 
            = ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[2U] 
            = ((__VdfgRegularize_hebeb780c_0_197[0U] 
                << 4U) | (((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_108) 
                           << 3U) | ((vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                      >> 0x0000001fU) 
                                     | (vlSelfRef.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                        << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[3U] 
            = ((__VdfgRegularize_hebeb780c_0_197[0U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[1U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[4U] 
            = ((__VdfgRegularize_hebeb780c_0_197[1U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[2U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[5U] 
            = ((__VdfgRegularize_hebeb780c_0_197[2U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[3U] 
                                   << 4U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_196[6U] 
            = ((__VdfgRegularize_hebeb780c_0_197[3U] 
                >> 0x0000001cU) | (__VdfgRegularize_hebeb780c_0_197[4U] 
                                   << 4U));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_11 = (1U 
                                                 & (((((2U 
                                                        & (vlSelfRef.__VdfgRegularize_hebeb780c_0_152[2U] 
                                                           >> 3U)) 
                                                       | (1U 
                                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[2U] 
                                                             >> 4U))) 
                                                      << 2U) 
                                                     | ((2U 
                                                         & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[2U] 
                                                            >> 3U)) 
                                                        | (1U 
                                                           & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[2U] 
                                                              >> 4U)))) 
                                                    >> (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__w_fifo_data)));
}
