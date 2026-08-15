// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

void Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
               >> 0x00000017U)) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
              >> 0x00000017U));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
               >> 0x00000016U)) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
              >> 0x00000016U));
    vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies = 0U;
    if ((0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q))) {
        vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies 
            = (((~ ((IData)(1U) << (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))) 
                & (IData)(vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies)) 
               | (0x0fU & ((1U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                  >> 0x00000015U)) 
                           << (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))));
    }
    vlSelfRef.__VdfgRegularize_h591265a2_0_2 = ((0x00000400U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U])
                                                 ? 
                                                ((IData)(1U) 
                                                 << 
                                                 (3U 
                                                  & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                     >> 8U)))
                                                 : 0U);
    vlSelfRef.__VdfgRegularize_h591265a2_0_1 = ((0x00100000U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U])
                                                 ? 
                                                ((IData)(1U) 
                                                 << 
                                                 (3U 
                                                  & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                     >> 0x00000012U)))
                                                 : 0U);
}

extern const VlUnpacked<CData/*0:0*/, 16> Vaxi4_xbar_tb__ConstPool__TABLE_hcf36e0d3_0;
extern const VlUnpacked<CData/*0:0*/, 16> Vaxi4_xbar_tb__ConstPool__TABLE_h817c6e32_0;
extern const VlUnpacked<CData/*0:0*/, 16> Vaxi4_xbar_tb__ConstPool__TABLE_h467a502d_0;
extern const VlUnpacked<CData/*0:0*/, 16> Vaxi4_xbar_tb__ConstPool__TABLE_h2a9b3ba1_0;
extern const VlUnpacked<CData/*0:0*/, 16> Vaxi4_xbar_tb__ConstPool__TABLE_h3d69090c_0;

void Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__1(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__gen_mux__DOT__mst_aw_valid;
    __PVT__gen_mux__DOT__mst_aw_valid = 0;
    CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i;
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i = 0;
    CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i;
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i = 0;
    CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i;
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__;
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__;
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_1;
    __VdfgRegularize_h591265a2_1_1 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_2;
    __VdfgRegularize_h591265a2_1_2 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_7;
    __VdfgRegularize_h591265a2_1_7 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_8;
    __VdfgRegularize_h591265a2_1_8 = 0;
    CData/*3:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_160;
    __VdfgRegularize_hebeb780c_0_160 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_161;
    __VdfgRegularize_hebeb780c_0_161 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_162;
    __VdfgRegularize_hebeb780c_0_162 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_163;
    __VdfgRegularize_hebeb780c_0_163 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_164;
    __VdfgRegularize_hebeb780c_0_164 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_165;
    __VdfgRegularize_hebeb780c_0_165 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_166;
    __VdfgRegularize_hebeb780c_0_166 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_167;
    __VdfgRegularize_hebeb780c_0_167 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_168;
    __VdfgRegularize_hebeb780c_0_168 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_169;
    __VdfgRegularize_hebeb780c_0_169 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_182;
    __VdfgRegularize_hebeb780c_0_182 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_183;
    __VdfgRegularize_hebeb780c_0_183 = 0;
    VlWide<10>/*319:0*/ __Vtemp_52;
    IData/*31:0*/ __VExpandSel_WordIdx_11;
    IData/*31:0*/ __VExpandSel_LoShift_11;
    CData/*0:0*/ __VExpandSel_Aligned_11;
    IData/*31:0*/ __VExpandSel_HiShift_11;
    IData/*31:0*/ __VExpandSel_HiMask_11;
    // Body
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_119)) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
           & (0U == (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select)));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_129)) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
           & (0U == (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select)));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_139)) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
           & (0U == (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select)));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_149)) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__PVT__gen_mux__DOT__slv_aw_valids = 
        ((((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                  >> 0x0000000fU)) | (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                            >> 0x00000010U))) 
          << 2U) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                           >> 0x0000000fU)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                                                >> 0x0000000fU))));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_168 = (1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_167 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_166 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_165 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 3U));
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_168 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                                                  >> 0x0000000fU));
        __VdfgRegularize_hebeb780c_0_167 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                                  >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_166 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                                  >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_165 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                                  >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__slv_aw_valids;
    }
    if (__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[0U] 
            = (1U | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_102) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                                             >> 1U)));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[0U] 
            = (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_102) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                                             >> 1U)));
    }
    __VdfgRegularize_hebeb780c_0_169 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_168)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_167) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    if (__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[0U] 
            = (1U | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_106) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                                             >> 1U)));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[0U] 
            = (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_106) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                                             >> 1U)));
    }
    if (__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[0U] 
            = (1U | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_110) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                                             >> 1U)));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[0U] 
            = (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_110) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                                             >> 1U)));
    }
    vlSelfRef.__PVT__gen_mux__DOT__slv_ar_valids = 
        ((((IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i) 
           << 3U) | ((IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i) 
                     << 2U)) | (((IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i) 
                                 << 1U) | (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[0U])));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_163 = (1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_162 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_161 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_160 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 3U));
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_163 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[0U]);
        __VdfgRegularize_hebeb780c_0_162 = (1U & (IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i));
        __VdfgRegularize_hebeb780c_0_161 = (1U & (IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i));
        __VdfgRegularize_hebeb780c_0_160 = (1U & (IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i));
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__slv_ar_valids;
    }
    __VdfgRegularize_hebeb780c_0_183 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_166)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_165) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_168) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_167))) 
                 | (((IData)(__VdfgRegularize_hebeb780c_0_166) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_165)) 
                    & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q) 
                       >> 1U))));
    __VdfgRegularize_hebeb780c_0_164 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_163)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_162) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    __VdfgRegularize_hebeb780c_0_182 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_161)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_160) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_163) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_162))) 
                 | (((IData)(__VdfgRegularize_hebeb780c_0_161) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_160)) 
                    & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q) 
                       >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_9 = (1U 
                                                & (((((2U 
                                                       & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                                          >> 3U)) 
                                                      | (1U 
                                                         & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
                                                            >> 4U))) 
                                                     << 2U) 
                                                    | ((2U 
                                                        & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
                                                           >> 3U)) 
                                                       | (1U 
                                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[2U] 
                                                             >> 4U)))) 
                                                   >> (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data)));
    __Vtemp_52[0U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[3U] 
                       << 0x0000001bU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[2U] 
                                          >> 5U));
    __Vtemp_52[1U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                       << 0x0000001bU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[3U] 
                                          >> 5U));
    __Vtemp_52[2U] = ((0xfffffc00U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
                                      << 5U)) | (0x000003ffU 
                                                 & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                                                    >> 5U)));
    __Vtemp_52[3U] = (((0x000003e0U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
                                       << 5U)) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
                                                  >> 0x0000001bU)) 
                      | (0xfffffc00U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
                                        << 5U)));
    __Vtemp_52[4U] = ((0xfff00000U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
                                      << 0x0000000fU)) 
                      | (((0x000003e0U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
                                          << 5U)) | 
                          (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
                           >> 0x0000001bU)) | (0x000ffc00U 
                                               & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
                                                  << 5U))));
    __Vtemp_52[5U] = (((0x000f8000U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
                                       << 0x0000000fU)) 
                       | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
                          >> 0x00000011U)) | (0xfff00000U 
                                              & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
                                                 << 0x0000000fU)));
    __Vtemp_52[6U] = (((0x000f8000U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
                                       << 0x0000000fU)) 
                       | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
                          >> 0x00000011U)) | (((0xfffffc00U 
                                                & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                                   << 5U)) 
                                               | (0x000003ffU 
                                                  & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
                                                     >> 5U))) 
                                              << 0x00000014U));
    __Vtemp_52[7U] = ((((0xfffffc00U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                        << 5U)) | (0x000003ffU 
                                                   & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
                                                      >> 5U))) 
                       >> 0x0000000cU) | ((((0x000003e0U 
                                             & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                                << 5U)) 
                                            | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                               >> 0x0000001bU)) 
                                           | (0xfffffc00U 
                                              & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                                 << 5U))) 
                                          << 0x00000014U));
    __Vtemp_52[8U] = (((((0x000003e0U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                         << 5U)) | 
                         (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                          >> 0x0000001bU)) | (0xfffffc00U 
                                              & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                                 << 5U))) 
                       >> 0x0000000cU) | ((((0x000003e0U 
                                             & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                                << 5U)) 
                                            | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                               >> 0x0000001bU)) 
                                           | (0x000ffc00U 
                                              & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                                 << 5U))) 
                                          << 0x00000014U));
    __Vtemp_52[9U] = ((((0x000003e0U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                        << 5U)) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                                   >> 0x0000001bU)) 
                       | (0x000ffc00U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                         << 5U))) >> 0x0000000cU);
    __VExpandSel_WordIdx_11 = (0x0000000fU & (((IData)(0x0000004aU) 
                                               * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data)) 
                                              >> 5U));
    __VExpandSel_LoShift_11 = (0x0000001fU & ((IData)(0x0000004aU) 
                                              * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data)));
    __VExpandSel_Aligned_11 = (0U == __VExpandSel_LoShift_11);
    if (__VExpandSel_Aligned_11) {
        __VExpandSel_HiShift_11 = 0U;
        __VExpandSel_HiMask_11 = 0U;
    } else {
        __VExpandSel_HiShift_11 = ((IData)(0x00000020U) 
                                   - __VExpandSel_LoShift_11);
        __VExpandSel_HiMask_11 = 0xffffffffU;
    }
    if ((0x0127U >= (0x000001ffU & ((IData)(0x0000004aU) 
                                    * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))))) {
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
            = (((__Vtemp_52[((IData)(1U) + __VExpandSel_WordIdx_11)] 
                 << __VExpandSel_HiShift_11) & __VExpandSel_HiMask_11) 
               | (__Vtemp_52[__VExpandSel_WordIdx_11] 
                  >> __VExpandSel_LoShift_11));
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[1U] 
            = (((__Vtemp_52[((IData)(2U) + __VExpandSel_WordIdx_11)] 
                 << __VExpandSel_HiShift_11) & __VExpandSel_HiMask_11) 
               | (__Vtemp_52[((IData)(1U) + __VExpandSel_WordIdx_11)] 
                  >> __VExpandSel_LoShift_11));
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[2U] 
            = (0x000003ffU & (((((7U <= __VExpandSel_WordIdx_11)
                                  ? 0U : __Vtemp_52
                                 [((IData)(3U) + __VExpandSel_WordIdx_11)]) 
                                << __VExpandSel_HiShift_11) 
                               & __VExpandSel_HiMask_11) 
                              | (__Vtemp_52[((IData)(2U) 
                                             + __VExpandSel_WordIdx_11)] 
                                 >> __VExpandSel_LoShift_11)));
    } else {
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
            = vlSelfRef.__Vxrand___0[0U];
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[1U] 
            = vlSelfRef.__Vxrand___0[1U];
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[2U] 
            = (0x000003ffU & vlSelfRef.__Vxrand___0[2U]);
    }
    __VdfgRegularize_h591265a2_1_1 = ((2U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 2U));
    __VdfgRegularize_h591265a2_1_2 = ((1U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 1U));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ 
        = (1U & ((~ ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                 >> 3U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d)) 
                 | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 1U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__aw_valid = (IData)(
                                                      (0U 
                                                       != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d)));
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready));
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop = ((0U 
                                                  != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                                 & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_9) 
                                                    & ((vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                        >> 0x00000015U) 
                                                       & (vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
                                                          >> 1U))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ 
        = (1U & ((~ ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                 >> 3U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d)) 
                 | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 1U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    __VdfgRegularize_h591265a2_1_7 = ((2U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 2U));
    __VdfgRegularize_h591265a2_1_8 = ((1U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 1U));
    vlSelfRef.__PVT__gen_mux__DOT__ar_valid = (IData)(
                                                      (0U 
                                                       != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d)));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__) {
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
                = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_186[5U] 
                    << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
                = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_186[6U] 
                    << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[5U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                = (0x00000300U | (0x000000ffU & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[6U] 
                                                 >> 0x00000010U)));
        } else {
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
                = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_181[5U] 
                    << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
                = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_181[6U] 
                    << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[5U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                = (0x00000200U | (0x000000ffU & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[6U] 
                                                 >> 0x00000010U)));
        }
    } else if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
            = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_180[5U] 
                << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
            = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_180[6U] 
                << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[5U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
            = (0x00000100U | (0x000000ffU & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[6U] 
                                             >> 0x00000010U)));
    } else {
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[5U] 
                << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[6U] 
                << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[5U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
            = (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[6U] 
                              >> 0x00000010U));
    }
    __Vtableidx1 = ((((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid) 
                      << 3U) | ((8U == (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                << 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready) 
                                            << 1U) 
                                           | (IData)(vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_q)));
    vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_d 
        = Vaxi4_xbar_tb__ConstPool__TABLE_hcf36e0d3_0
        [__Vtableidx1];
    vlSelfRef.__PVT__gen_mux__DOT__load_aw_lock = Vaxi4_xbar_tb__ConstPool__TABLE_h817c6e32_0
        [__Vtableidx1];
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push = Vaxi4_xbar_tb__ConstPool__TABLE_h467a502d_0
        [__Vtableidx1];
    __PVT__gen_mux__DOT__mst_aw_valid = Vaxi4_xbar_tb__ConstPool__TABLE_h2a9b3ba1_0
        [__Vtableidx1];
    vlSelfRef.__PVT__gen_mux__DOT__aw_ready = Vaxi4_xbar_tb__ConstPool__TABLE_h3d69090c_0
        [__Vtableidx1];
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_182)) 
           & (IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_182));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_164)) 
           & (IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_164));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_n 
        = (7U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q) 
                 + ((0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                    & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready) 
            & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid))
            ? (((IData)(__VdfgRegularize_h591265a2_1_8) 
                | ((IData)(__VdfgRegularize_h591265a2_1_7) 
                   | ((3U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                         >> 3U)))) ? ((IData)(__VdfgRegularize_h591265a2_1_8)
                                       ? 1U : ((IData)(__VdfgRegularize_h591265a2_1_7)
                                                ? 2U
                                                : 3U))
                : ((1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d))
                    ? 0U : (((1U <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                             & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                >> 1U)) ? 1U : (((2U 
                                                  <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                                    >> 2U))
                                                 ? 2U
                                                 : 3U))))
            : (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((IData)(__PVT__gen_mux__DOT__mst_aw_valid) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
        = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
         & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop) 
         & (0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = (0x0000000fU & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q) 
                              - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop)) 
          & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n 
        = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q;
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
         & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n 
            = (((~ ((IData)(3U) << (0x0000000fU & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q), 1U)))) 
                & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n)) 
               | (0x0000ffffU & ((3U & (vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                                        >> 8U)) << 
                                 (0x0000000fU & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q), 1U)))));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_360 = ((8U 
                                                   != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready) 
            & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid))
            ? (((IData)(__VdfgRegularize_h591265a2_1_2) 
                | ((IData)(__VdfgRegularize_h591265a2_1_1) 
                   | ((3U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                         >> 3U)))) ? ((IData)(__VdfgRegularize_h591265a2_1_2)
                                       ? 1U : ((IData)(__VdfgRegularize_h591265a2_1_1)
                                                ? 2U
                                                : 3U))
                : ((1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d))
                    ? 0U : (((1U <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                             & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                >> 1U)) ? 1U : (((2U 
                                                  <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                                    >> 2U))
                                                 ? 2U
                                                 : 3U))))
            : (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q));
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_n 
        = (7U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q) 
                 + (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_360)));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_183)) 
           & (IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_183));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_169)) 
           & (IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_169));
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((8U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_w_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_w_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_w_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_w_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
                                            ? (2U | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
                                            : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
                                            ? (2U | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
                                            : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                      << 3U) 
                                                     | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                        << 2U)) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                      << 3U) 
                                                     | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                        << 2U)) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                              | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                 | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o))))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                              | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                 | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o))))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid)) 
                                       | ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                   | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o))))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid)) 
                                       | ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                   | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o))))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid)) 
                                       | ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready)) 
                                          | (((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                << 3U) 
                                               | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                  << 2U)) 
                                              | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                  << 1U) 
                                                 | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o))) 
                                             >> ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
                                                  ? 
                                                 (2U 
                                                  | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
                                                  : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid)) 
                                       | ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready)) 
                                          | (((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                << 3U) 
                                               | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                  << 2U)) 
                                              | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                  << 1U) 
                                                 | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o))) 
                                             >> ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
                                                  ? 
                                                 (2U 
                                                  | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
                                                  : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[0].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    vlSelfRef.gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1 
        = ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? (2U | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
            : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    vlSelfRef.gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1 
        = ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? (2U | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
            : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    vlSelfRef.gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1 
        = ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1 
        = ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1 
        = ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid) 
              & (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready))));
    vlSelfRef.gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1 
        = ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid) 
              & (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready))));
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__1(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VdfgRegularize_h591265a2_0_2 = ((0x00000400U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U])
                                                 ? 
                                                ((IData)(1U) 
                                                 << 
                                                 (3U 
                                                  & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                     >> 8U)))
                                                 : 0U);
    vlSelfRef.__VdfgRegularize_h591265a2_0_1 = ((0x00100000U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U])
                                                 ? 
                                                ((IData)(1U) 
                                                 << 
                                                 (3U 
                                                  & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                     >> 0x00000012U)))
                                                 : 0U);
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__2(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__2\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_n;
        if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
        }
        if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_n;
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_360) {
            vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n;
        }
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        if (vlSelfRef.__PVT__gen_mux__DOT__load_aw_lock) {
            vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_q 
                = vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_d;
        }
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n;
        if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
        }
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d;
        if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U];
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U];
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U];
        }
        if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
                if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__) {
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                        = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_186[1U] 
                            << 0x0000001fU) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[0U] 
                                               >> 1U));
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                        = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                            << 0x0000001fU) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[1U] 
                                               >> 1U));
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                        = (0x0000000cU | (3U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                                >> 1U)));
                } else {
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                        = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_181[1U] 
                            << 0x0000001fU) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[0U] 
                                               >> 1U));
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                        = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
                            << 0x0000001fU) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[1U] 
                                               >> 1U));
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                        = (8U | (3U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
                                       >> 1U)));
                }
            } else if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                    = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_180[1U] 
                        << 0x0000001fU) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[0U] 
                                           >> 1U));
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                    = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
                        << 0x0000001fU) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[1U] 
                                           >> 1U));
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                    = (4U | (3U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
                                   >> 1U)));
            } else {
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                    = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[1U] 
                        << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[0U] 
                                           >> 1U));
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                    = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[2U] 
                        << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[1U] 
                                           >> 1U));
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                    = (3U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[2U] 
                             >> 1U));
            }
        }
    } else {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] = 0U;
    }
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__gen_mux__DOT__ar_ready = (1U & 
                                               ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready = (1U 
                                                   & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                      | (~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data = (3U 
                                                  & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q) 
                                                     >> 
                                                     ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q) 
                                                      << 1U)));
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
              >> 0x00000016U));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
              >> 0x00000017U));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
               >> 0x00000016U)) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
               >> 0x00000017U)) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies = 0U;
    if ((0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q))) {
        vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies 
            = (((~ ((IData)(1U) << (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))) 
                & (IData)(vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies)) 
               | (0x0fU & ((1U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                  >> 0x00000015U)) 
                           << (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))));
    }
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__1(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__gen_mux__DOT__mst_aw_valid;
    __PVT__gen_mux__DOT__mst_aw_valid = 0;
    CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i;
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i = 0;
    CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i;
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i = 0;
    CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i;
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__;
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__;
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_1;
    __VdfgRegularize_h591265a2_1_1 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_2;
    __VdfgRegularize_h591265a2_1_2 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_7;
    __VdfgRegularize_h591265a2_1_7 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_8;
    __VdfgRegularize_h591265a2_1_8 = 0;
    CData/*3:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_160;
    __VdfgRegularize_hebeb780c_0_160 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_161;
    __VdfgRegularize_hebeb780c_0_161 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_162;
    __VdfgRegularize_hebeb780c_0_162 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_163;
    __VdfgRegularize_hebeb780c_0_163 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_164;
    __VdfgRegularize_hebeb780c_0_164 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_165;
    __VdfgRegularize_hebeb780c_0_165 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_166;
    __VdfgRegularize_hebeb780c_0_166 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_167;
    __VdfgRegularize_hebeb780c_0_167 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_168;
    __VdfgRegularize_hebeb780c_0_168 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_169;
    __VdfgRegularize_hebeb780c_0_169 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_182;
    __VdfgRegularize_hebeb780c_0_182 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_183;
    __VdfgRegularize_hebeb780c_0_183 = 0;
    VlWide<10>/*319:0*/ __Vtemp_52;
    IData/*31:0*/ __VExpandSel_WordIdx_11;
    IData/*31:0*/ __VExpandSel_LoShift_11;
    CData/*0:0*/ __VExpandSel_Aligned_11;
    IData/*31:0*/ __VExpandSel_HiShift_11;
    IData/*31:0*/ __VExpandSel_HiMask_11;
    // Body
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_119)) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_129)) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
           & (0U == (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__slv_ar_select)));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_139)) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
           & (0U == (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__slv_ar_select)));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_149)) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid) 
           & (0U == (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__slv_ar_select)));
    vlSelfRef.__PVT__gen_mux__DOT__slv_aw_valids = 
        ((((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                  >> 0x0000000fU)) | (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                            >> 0x00000010U))) 
          << 2U) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                           >> 0x0000000fU)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                                                >> 0x0000000fU))));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_168 = (1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_167 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_166 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_165 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 3U));
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_168 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                                                  >> 0x0000000fU));
        __VdfgRegularize_hebeb780c_0_167 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                                  >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_166 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                                  >> 0x00000010U));
        __VdfgRegularize_hebeb780c_0_165 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                                  >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__slv_aw_valids;
    }
    if (__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[0U] 
            = (1U | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_102) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                                             >> 1U)));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[0U] 
            = (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_102) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_180[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_33[6U] 
                                             >> 1U)));
    }
    __VdfgRegularize_hebeb780c_0_169 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_168)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_167) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    if (__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[0U] 
            = (1U | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_106) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                                             >> 1U)));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[0U] 
            = (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_106) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_181[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_48[6U] 
                                             >> 1U)));
    }
    if (__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[0U] 
            = (1U | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                     << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_110) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                                             >> 1U)));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[0U] 
            = (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
               << 1U);
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[0U] 
                >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                                   << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
            = (((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                 << 0x0000001fU) | (0x7ffffff0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[2U] 
                                                   >> 1U))) 
               | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_110) 
                   << 3U) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[1U] 
                              >> 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__Vcellout__i_ar_spill_reg__data_o[2U] 
                                                 << 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[3U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[4U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[5U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                               >> 1U)) | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                                           << 0x0000001fU) 
                                          | (0x7ffffff0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[5U] 
                                                >> 1U))));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_186[6U] 
            = ((0x0000000fU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                               >> 1U)) | (0x00fffff0U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_63[6U] 
                                             >> 1U)));
    }
    vlSelfRef.__PVT__gen_mux__DOT__slv_ar_valids = 
        ((((IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i) 
           << 3U) | ((IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i) 
                     << 2U)) | (((IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i) 
                                 << 1U) | (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[0U])));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_163 = (1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_162 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_161 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_160 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 3U));
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_163 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[0U]);
        __VdfgRegularize_hebeb780c_0_162 = (1U & (IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_valids_i));
        __VdfgRegularize_hebeb780c_0_161 = (1U & (IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_valids_i));
        __VdfgRegularize_hebeb780c_0_160 = (1U & (IData)(__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_valids_i));
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__slv_ar_valids;
    }
    __VdfgRegularize_hebeb780c_0_183 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_166)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_165) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_168) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_167))) 
                 | (((IData)(__VdfgRegularize_hebeb780c_0_166) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_165)) 
                    & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q) 
                       >> 1U))));
    __VdfgRegularize_hebeb780c_0_164 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_163)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_162) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    __VdfgRegularize_hebeb780c_0_182 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_161)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_160) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_163) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_162))) 
                 | (((IData)(__VdfgRegularize_hebeb780c_0_161) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_160)) 
                    & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q) 
                       >> 1U))));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_9 = (1U 
                                                & (((((2U 
                                                       & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                                          >> 3U)) 
                                                      | (1U 
                                                         & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
                                                            >> 4U))) 
                                                     << 2U) 
                                                    | ((2U 
                                                        & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
                                                           >> 3U)) 
                                                       | (1U 
                                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[2U] 
                                                             >> 4U)))) 
                                                   >> (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data)));
    __Vtemp_52[0U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[3U] 
                       << 0x0000001bU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[2U] 
                                          >> 5U));
    __Vtemp_52[1U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                       << 0x0000001bU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[3U] 
                                          >> 5U));
    __Vtemp_52[2U] = ((0xfffffc00U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
                                      << 5U)) | (0x000003ffU 
                                                 & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                                                    >> 5U)));
    __Vtemp_52[3U] = (((0x000003e0U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
                                       << 5U)) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[2U] 
                                                  >> 0x0000001bU)) 
                      | (0xfffffc00U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
                                        << 5U)));
    __Vtemp_52[4U] = ((0xfff00000U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
                                      << 0x0000000fU)) 
                      | (((0x000003e0U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
                                          << 5U)) | 
                          (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[3U] 
                           >> 0x0000001bU)) | (0x000ffc00U 
                                               & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
                                                  << 5U))));
    __Vtemp_52[5U] = (((0x000f8000U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
                                       << 0x0000000fU)) 
                       | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[2U] 
                          >> 0x00000011U)) | (0xfff00000U 
                                              & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
                                                 << 0x0000000fU)));
    __Vtemp_52[6U] = (((0x000f8000U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
                                       << 0x0000000fU)) 
                       | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[3U] 
                          >> 0x00000011U)) | (((0xfffffc00U 
                                                & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                                   << 5U)) 
                                               | (0x000003ffU 
                                                  & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
                                                     >> 5U))) 
                                              << 0x00000014U));
    __Vtemp_52[7U] = ((((0xfffffc00U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                        << 5U)) | (0x000003ffU 
                                                   & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
                                                      >> 5U))) 
                       >> 0x0000000cU) | ((((0x000003e0U 
                                             & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                                << 5U)) 
                                            | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                                               >> 0x0000001bU)) 
                                           | (0xfffffc00U 
                                              & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                                 << 5U))) 
                                          << 0x00000014U));
    __Vtemp_52[8U] = (((((0x000003e0U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                         << 5U)) | 
                         (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[2U] 
                          >> 0x0000001bU)) | (0xfffffc00U 
                                              & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                                 << 5U))) 
                       >> 0x0000000cU) | ((((0x000003e0U 
                                             & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                                << 5U)) 
                                            | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                               >> 0x0000001bU)) 
                                           | (0x000ffc00U 
                                              & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                                 << 5U))) 
                                          << 0x00000014U));
    __Vtemp_52[9U] = ((((0x000003e0U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                        << 5U)) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[3U] 
                                                   >> 0x0000001bU)) 
                       | (0x000ffc00U & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                         << 5U))) >> 0x0000000cU);
    __VExpandSel_WordIdx_11 = (0x0000000fU & (((IData)(0x0000004aU) 
                                               * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data)) 
                                              >> 5U));
    __VExpandSel_LoShift_11 = (0x0000001fU & ((IData)(0x0000004aU) 
                                              * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data)));
    __VExpandSel_Aligned_11 = (0U == __VExpandSel_LoShift_11);
    if (__VExpandSel_Aligned_11) {
        __VExpandSel_HiShift_11 = 0U;
        __VExpandSel_HiMask_11 = 0U;
    } else {
        __VExpandSel_HiShift_11 = ((IData)(0x00000020U) 
                                   - __VExpandSel_LoShift_11);
        __VExpandSel_HiMask_11 = 0xffffffffU;
    }
    if ((0x0127U >= (0x000001ffU & ((IData)(0x0000004aU) 
                                    * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))))) {
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
            = (((__Vtemp_52[((IData)(1U) + __VExpandSel_WordIdx_11)] 
                 << __VExpandSel_HiShift_11) & __VExpandSel_HiMask_11) 
               | (__Vtemp_52[__VExpandSel_WordIdx_11] 
                  >> __VExpandSel_LoShift_11));
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[1U] 
            = (((__Vtemp_52[((IData)(2U) + __VExpandSel_WordIdx_11)] 
                 << __VExpandSel_HiShift_11) & __VExpandSel_HiMask_11) 
               | (__Vtemp_52[((IData)(1U) + __VExpandSel_WordIdx_11)] 
                  >> __VExpandSel_LoShift_11));
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[2U] 
            = (0x000003ffU & (((((7U <= __VExpandSel_WordIdx_11)
                                  ? 0U : __Vtemp_52
                                 [((IData)(3U) + __VExpandSel_WordIdx_11)]) 
                                << __VExpandSel_HiShift_11) 
                               & __VExpandSel_HiMask_11) 
                              | (__Vtemp_52[((IData)(2U) 
                                             + __VExpandSel_WordIdx_11)] 
                                 >> __VExpandSel_LoShift_11)));
    } else {
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
            = vlSelfRef.__Vxrand___0[0U];
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[1U] 
            = vlSelfRef.__Vxrand___0[1U];
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[2U] 
            = (0x000003ffU & vlSelfRef.__Vxrand___0[2U]);
    }
    __VdfgRegularize_h591265a2_1_1 = ((2U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 2U));
    __VdfgRegularize_h591265a2_1_2 = ((1U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 1U));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ 
        = (1U & ((~ ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                 >> 3U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d)) 
                 | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 1U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__aw_valid = (IData)(
                                                      (0U 
                                                       != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d)));
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready));
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop = ((0U 
                                                  != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                                 & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_9) 
                                                    & ((vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                        >> 0x00000015U) 
                                                       & (vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
                                                          >> 1U))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ 
        = (1U & ((~ ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                 >> 3U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d)) 
                 | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 1U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    __VdfgRegularize_h591265a2_1_7 = ((2U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 2U));
    __VdfgRegularize_h591265a2_1_8 = ((1U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 1U));
    vlSelfRef.__PVT__gen_mux__DOT__ar_valid = (IData)(
                                                      (0U 
                                                       != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d)));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__) {
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
                = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_186[5U] 
                    << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[4U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
                = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_186[6U] 
                    << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[5U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                = (0x00000300U | (0x000000ffU & (vlSelfRef.__VdfgRegularize_hebeb780c_0_186[6U] 
                                                 >> 0x00000010U)));
        } else {
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
                = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_181[5U] 
                    << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[4U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
                = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_181[6U] 
                    << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[5U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                = (0x00000200U | (0x000000ffU & (vlSelfRef.__VdfgRegularize_hebeb780c_0_181[6U] 
                                                 >> 0x00000010U)));
        }
    } else if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
            = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_180[5U] 
                << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[4U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
            = ((vlSelfRef.__VdfgRegularize_hebeb780c_0_180[6U] 
                << 0x00000010U) | (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[5U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
            = (0x00000100U | (0x000000ffU & (vlSelfRef.__VdfgRegularize_hebeb780c_0_180[6U] 
                                             >> 0x00000010U)));
    } else {
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[5U] 
                << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[4U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[6U] 
                << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[5U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
            = (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[6U] 
                              >> 0x00000010U));
    }
    __Vtableidx1 = ((((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid) 
                      << 3U) | ((8U == (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                << 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready) 
                                            << 1U) 
                                           | (IData)(vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_q)));
    vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_d 
        = Vaxi4_xbar_tb__ConstPool__TABLE_hcf36e0d3_0
        [__Vtableidx1];
    vlSelfRef.__PVT__gen_mux__DOT__load_aw_lock = Vaxi4_xbar_tb__ConstPool__TABLE_h817c6e32_0
        [__Vtableidx1];
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push = Vaxi4_xbar_tb__ConstPool__TABLE_h467a502d_0
        [__Vtableidx1];
    __PVT__gen_mux__DOT__mst_aw_valid = Vaxi4_xbar_tb__ConstPool__TABLE_h2a9b3ba1_0
        [__Vtableidx1];
    vlSelfRef.__PVT__gen_mux__DOT__aw_ready = Vaxi4_xbar_tb__ConstPool__TABLE_h3d69090c_0
        [__Vtableidx1];
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_182)) 
           & (IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_182));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_164)) 
           & (IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_164));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_n 
        = (7U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q) 
                 + ((0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                    & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready) 
            & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid))
            ? (((IData)(__VdfgRegularize_h591265a2_1_8) 
                | ((IData)(__VdfgRegularize_h591265a2_1_7) 
                   | ((3U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                         >> 3U)))) ? ((IData)(__VdfgRegularize_h591265a2_1_8)
                                       ? 1U : ((IData)(__VdfgRegularize_h591265a2_1_7)
                                                ? 2U
                                                : 3U))
                : ((1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d))
                    ? 0U : (((1U <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                             & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                >> 1U)) ? 1U : (((2U 
                                                  <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                                    >> 2U))
                                                 ? 2U
                                                 : 3U))))
            : (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((IData)(__PVT__gen_mux__DOT__mst_aw_valid) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
        = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
         & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop) 
         & (0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = (0x0000000fU & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q) 
                              - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop)) 
          & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n 
        = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q;
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
         & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n 
            = (((~ ((IData)(3U) << (0x0000000fU & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q), 1U)))) 
                & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n)) 
               | (0x0000ffffU & ((3U & (vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                                        >> 8U)) << 
                                 (0x0000000fU & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q), 1U)))));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_360 = ((8U 
                                                   != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready) 
            & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid))
            ? (((IData)(__VdfgRegularize_h591265a2_1_2) 
                | ((IData)(__VdfgRegularize_h591265a2_1_1) 
                   | ((3U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                         >> 3U)))) ? ((IData)(__VdfgRegularize_h591265a2_1_2)
                                       ? 1U : ((IData)(__VdfgRegularize_h591265a2_1_1)
                                                ? 2U
                                                : 3U))
                : ((1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d))
                    ? 0U : (((1U <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                             & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                >> 1U)) ? 1U : (((2U 
                                                  <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                                    >> 2U))
                                                 ? 2U
                                                 : 3U))))
            : (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q));
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_n 
        = (7U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q) 
                 + (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_360)));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_183)) 
           & (IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_183));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_169)) 
           & (IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_169));
}

void Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
               >> 0x0000000fU)) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
              >> 0x0000000fU));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
               >> 0x0000000eU)) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
              >> 0x0000000eU));
    vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies = 0U;
    if ((0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q))) {
        vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies 
            = (((~ ((IData)(1U) << (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))) 
                & (IData)(vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies)) 
               | (0x0fU & ((1U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                  >> 0x0000000dU)) 
                           << (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))));
    }
    vlSelfRef.__VdfgRegularize_h591265a2_0_2 = ((4U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U])
                                                 ? 
                                                ((IData)(1U) 
                                                 << 
                                                 (3U 
                                                  & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U]))
                                                 : 0U);
    vlSelfRef.__VdfgRegularize_h591265a2_0_1 = ((0x00001000U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U])
                                                 ? 
                                                ((IData)(1U) 
                                                 << 
                                                 (3U 
                                                  & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                                     >> 0x0000000aU)))
                                                 : 0U);
}

void Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__1(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__gen_mux__DOT__mst_aw_valid;
    __PVT__gen_mux__DOT__mst_aw_valid = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__;
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__;
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ = 0;
    CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_1;
    __VdfgRegularize_h591265a2_1_1 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_2;
    __VdfgRegularize_h591265a2_1_2 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_7;
    __VdfgRegularize_h591265a2_1_7 = 0;
    CData/*0:0*/ __VdfgRegularize_h591265a2_1_8;
    __VdfgRegularize_h591265a2_1_8 = 0;
    CData/*3:0*/ __Vtableidx2;
    __Vtableidx2 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_170;
    __VdfgRegularize_hebeb780c_0_170 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_171;
    __VdfgRegularize_hebeb780c_0_171 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_172;
    __VdfgRegularize_hebeb780c_0_172 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_173;
    __VdfgRegularize_hebeb780c_0_173 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_174;
    __VdfgRegularize_hebeb780c_0_174 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_175;
    __VdfgRegularize_hebeb780c_0_175 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_176;
    __VdfgRegularize_hebeb780c_0_176 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_177;
    __VdfgRegularize_hebeb780c_0_177 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_178;
    __VdfgRegularize_hebeb780c_0_178 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_179;
    __VdfgRegularize_hebeb780c_0_179 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_184;
    __VdfgRegularize_hebeb780c_0_184 = 0;
    CData/*0:0*/ __VdfgRegularize_hebeb780c_0_185;
    __VdfgRegularize_hebeb780c_0_185 = 0;
    VlWide<10>/*319:0*/ __Vtemp_16;
    IData/*31:0*/ __VExpandSel_WordIdx_5;
    IData/*31:0*/ __VExpandSel_LoShift_5;
    CData/*0:0*/ __VExpandSel_Aligned_5;
    IData/*31:0*/ __VExpandSel_HiShift_5;
    IData/*31:0*/ __VExpandSel_HiMask_5;
    // Body
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_119));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_129));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_139));
    vlSelfRef.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_149));
    __Vtemp_16[0U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[3U] 
                       << 0x0000001bU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[2U] 
                                          >> 5U));
    __Vtemp_16[1U] = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[4U] 
                       << 0x0000001bU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[3U] 
                                          >> 5U));
    __Vtemp_16[2U] = ((0xfffffc00U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[2U] 
                                      << 5U)) | (0x000003ffU 
                                                 & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[4U] 
                                                    >> 5U)));
    __Vtemp_16[3U] = (((0x000003e0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[3U] 
                                       << 5U)) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[2U] 
                                                  >> 0x0000001bU)) 
                      | (0xfffffc00U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[3U] 
                                        << 5U)));
    __Vtemp_16[4U] = ((0xfff00000U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[2U] 
                                      << 0x0000000fU)) 
                      | (((0x000003e0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[4U] 
                                          << 5U)) | 
                          (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[3U] 
                           >> 0x0000001bU)) | (0x000ffc00U 
                                               & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[4U] 
                                                  << 5U))));
    __Vtemp_16[5U] = (((0x000f8000U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[3U] 
                                       << 0x0000000fU)) 
                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[2U] 
                          >> 0x00000011U)) | (0xfff00000U 
                                              & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[3U] 
                                                 << 0x0000000fU)));
    __Vtemp_16[6U] = (((0x000f8000U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[4U] 
                                       << 0x0000000fU)) 
                       | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[3U] 
                          >> 0x00000011U)) | (((0xfffffc00U 
                                                & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[2U] 
                                                   << 5U)) 
                                               | (0x000003ffU 
                                                  & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[4U] 
                                                     >> 5U))) 
                                              << 0x00000014U));
    __Vtemp_16[7U] = ((((0xfffffc00U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[2U] 
                                        << 5U)) | (0x000003ffU 
                                                   & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[4U] 
                                                      >> 5U))) 
                       >> 0x0000000cU) | ((((0x000003e0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[3U] 
                                                << 5U)) 
                                            | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[2U] 
                                               >> 0x0000001bU)) 
                                           | (0xfffffc00U 
                                              & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[3U] 
                                                 << 5U))) 
                                          << 0x00000014U));
    __Vtemp_16[8U] = (((((0x000003e0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[3U] 
                                         << 5U)) | 
                         (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[2U] 
                          >> 0x0000001bU)) | (0xfffffc00U 
                                              & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[3U] 
                                                 << 5U))) 
                       >> 0x0000000cU) | ((((0x000003e0U 
                                             & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[4U] 
                                                << 5U)) 
                                            | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[3U] 
                                               >> 0x0000001bU)) 
                                           | (0x000ffc00U 
                                              & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[4U] 
                                                 << 5U))) 
                                          << 0x00000014U));
    __Vtemp_16[9U] = ((((0x000003e0U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[4U] 
                                        << 5U)) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[3U] 
                                                   >> 0x0000001bU)) 
                       | (0x000ffc00U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[4U] 
                                         << 5U))) >> 0x0000000cU);
    __VExpandSel_WordIdx_5 = (0x0000000fU & (((IData)(0x0000004aU) 
                                              * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data)) 
                                             >> 5U));
    __VExpandSel_LoShift_5 = (0x0000001fU & ((IData)(0x0000004aU) 
                                             * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data)));
    __VExpandSel_Aligned_5 = (0U == __VExpandSel_LoShift_5);
    if (__VExpandSel_Aligned_5) {
        __VExpandSel_HiShift_5 = 0U;
        __VExpandSel_HiMask_5 = 0U;
    } else {
        __VExpandSel_HiShift_5 = ((IData)(0x00000020U) 
                                  - __VExpandSel_LoShift_5);
        __VExpandSel_HiMask_5 = 0xffffffffU;
    }
    if ((0x0127U >= (0x000001ffU & ((IData)(0x0000004aU) 
                                    * (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))))) {
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
            = (((__Vtemp_16[((IData)(1U) + __VExpandSel_WordIdx_5)] 
                 << __VExpandSel_HiShift_5) & __VExpandSel_HiMask_5) 
               | (__Vtemp_16[__VExpandSel_WordIdx_5] 
                  >> __VExpandSel_LoShift_5));
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[1U] 
            = (((__Vtemp_16[((IData)(2U) + __VExpandSel_WordIdx_5)] 
                 << __VExpandSel_HiShift_5) & __VExpandSel_HiMask_5) 
               | (__Vtemp_16[((IData)(1U) + __VExpandSel_WordIdx_5)] 
                  >> __VExpandSel_LoShift_5));
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[2U] 
            = (0x000003ffU & (((((7U <= __VExpandSel_WordIdx_5)
                                  ? 0U : __Vtemp_16
                                 [((IData)(3U) + __VExpandSel_WordIdx_5)]) 
                                << __VExpandSel_HiShift_5) 
                               & __VExpandSel_HiMask_5) 
                              | (__Vtemp_16[((IData)(2U) 
                                             + __VExpandSel_WordIdx_5)] 
                                 >> __VExpandSel_LoShift_5)));
    } else {
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
            = vlSelfRef.__Vxrand___0[0U];
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[1U] 
            = vlSelfRef.__Vxrand___0[1U];
        vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[2U] 
            = (0x000003ffU & vlSelfRef.__Vxrand___0[2U]);
    }
    vlSelfRef.__PVT__gen_mux__DOT__slv_ar_valids = 
        ((((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[0U] 
                  << 1U)) | (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[0U])) 
          << 2U) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[0U] 
                           << 1U)) | (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[0U])));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_173 = (1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_172 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_171 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_170 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 3U));
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_173 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[0U]);
        __VdfgRegularize_hebeb780c_0_172 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[0U]);
        __VdfgRegularize_hebeb780c_0_171 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[0U]);
        __VdfgRegularize_hebeb780c_0_170 = (1U & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[0U]);
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__slv_ar_valids;
    }
    vlSelfRef.__PVT__gen_mux__DOT__slv_aw_valids = 
        ((((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[4U] 
                  >> 0x0000000eU)) | (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[4U] 
                                            >> 0x0000000fU))) 
          << 2U) | ((2U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[4U] 
                           >> 0x0000000eU)) | (1U & 
                                               (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[4U] 
                                                >> 0x0000000fU))));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q) {
        __VdfgRegularize_hebeb780c_0_178 = (1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q));
        __VdfgRegularize_hebeb780c_0_177 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 1U));
        __VdfgRegularize_hebeb780c_0_176 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 2U));
        __VdfgRegularize_hebeb780c_0_175 = (1U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                                  >> 3U));
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
    } else {
        __VdfgRegularize_hebeb780c_0_178 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[4U] 
                                                  >> 0x0000000fU));
        __VdfgRegularize_hebeb780c_0_177 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[4U] 
                                                  >> 0x0000000fU));
        __VdfgRegularize_hebeb780c_0_176 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[4U] 
                                                  >> 0x0000000fU));
        __VdfgRegularize_hebeb780c_0_175 = (1U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[4U] 
                                                  >> 0x0000000fU));
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d 
            = vlSelfRef.__PVT__gen_mux__DOT__slv_aw_valids;
    }
    __VdfgRegularize_hebeb780c_0_174 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_173)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_172) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    __VdfgRegularize_hebeb780c_0_179 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_178)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_177) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop = ((0U 
                                                  != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                                 & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_11) 
                                                    & ((vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                                        >> 0x0000000dU) 
                                                       & (vlSelfRef.__PVT__gen_mux__DOT__mst_w_chan[0U] 
                                                          >> 1U))));
    __VdfgRegularize_hebeb780c_0_184 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_171)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_170) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_173) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_172))) 
                 | (((IData)(__VdfgRegularize_hebeb780c_0_171) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_170)) 
                    & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q) 
                       >> 1U))));
    __VdfgRegularize_hebeb780c_0_185 = (1U & ((~ (IData)(__VdfgRegularize_hebeb780c_0_176)) 
                                              | ((IData)(__VdfgRegularize_hebeb780c_0_175) 
                                                 & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ ((IData)(__VdfgRegularize_hebeb780c_0_178) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_177))) 
                 | (((IData)(__VdfgRegularize_hebeb780c_0_176) 
                     | (IData)(__VdfgRegularize_hebeb780c_0_175)) 
                    & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q) 
                       >> 1U))));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_n 
        = (7U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q) 
                 + ((0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                    & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ 
        = (1U & ((~ ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                 >> 3U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d)) 
                 | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 1U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    __VdfgRegularize_h591265a2_1_7 = ((2U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 2U));
    __VdfgRegularize_h591265a2_1_8 = ((1U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 1U));
    vlSelfRef.__PVT__gen_mux__DOT__ar_valid = (IData)(
                                                      (0U 
                                                       != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d)));
    __VdfgRegularize_h591265a2_1_1 = ((2U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 2U));
    __VdfgRegularize_h591265a2_1_2 = ((1U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                         >> 1U));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ 
        = (1U & ((~ ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                 >> 3U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d)) 
                 | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                     >> 1U) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q))));
    vlSelfRef.__PVT__gen_mux__DOT__aw_valid = (IData)(
                                                      (0U 
                                                       != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d)));
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_ready) 
            & (IData)(vlSelfRef.__PVT__gen_mux__DOT__ar_valid))
            ? (((IData)(__VdfgRegularize_h591265a2_1_8) 
                | ((IData)(__VdfgRegularize_h591265a2_1_7) 
                   | ((3U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                         >> 3U)))) ? ((IData)(__VdfgRegularize_h591265a2_1_8)
                                       ? 1U : ((IData)(__VdfgRegularize_h591265a2_1_7)
                                                ? 2U
                                                : 3U))
                : ((1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d))
                    ? 0U : (((1U <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                             & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                >> 1U)) ? 1U : (((2U 
                                                  <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                                    >> 2U))
                                                 ? 2U
                                                 : 3U))))
            : (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q));
    if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__) {
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
                = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[5U] 
                    << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[4U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
                = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[6U] 
                    << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[5U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                = (0x00000300U | (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[6U] 
                                                 >> 0x00000010U)));
        } else {
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
                = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[5U] 
                    << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[4U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
                = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[6U] 
                    << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[5U] 
                                       >> 0x00000010U));
            vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                = (0x00000200U | (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[6U] 
                                                 >> 0x00000010U)));
        }
    } else if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[5U] 
                << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[4U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[6U] 
                << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[5U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
            = (0x00000100U | (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[6U] 
                                             >> 0x00000010U)));
    } else {
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[5U] 
                << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[4U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U] 
            = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[6U] 
                << 0x00000010U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[5U] 
                                   >> 0x00000010U));
        vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
            = (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[6U] 
                              >> 0x00000010U));
    }
    __Vtableidx2 = ((((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid) 
                      << 3U) | ((8U == (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                << 2U)) | (((IData)(vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready) 
                                            << 1U) 
                                           | (IData)(vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_q)));
    vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_d 
        = Vaxi4_xbar_tb__ConstPool__TABLE_hcf36e0d3_0
        [__Vtableidx2];
    vlSelfRef.__PVT__gen_mux__DOT__load_aw_lock = Vaxi4_xbar_tb__ConstPool__TABLE_h817c6e32_0
        [__Vtableidx2];
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push = Vaxi4_xbar_tb__ConstPool__TABLE_h467a502d_0
        [__Vtableidx2];
    __PVT__gen_mux__DOT__mst_aw_valid = Vaxi4_xbar_tb__ConstPool__TABLE_h2a9b3ba1_0
        [__Vtableidx2];
    vlSelfRef.__PVT__gen_mux__DOT__aw_ready = Vaxi4_xbar_tb__ConstPool__TABLE_h3d69090c_0
        [__Vtableidx2];
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_184)) 
           & (IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_184));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_174)) 
           & (IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_174));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((IData)(__PVT__gen_mux__DOT__mst_aw_valid) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
        = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
         & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop) 
         & (0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = (0x0000000fU & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q) 
                              - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_pop)) 
          & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n 
        = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q;
    if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push) 
         & (8U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n 
            = (((~ ((IData)(3U) << (0x0000000fU & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q), 1U)))) 
                & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n)) 
               | (0x0000ffffU & ((3U & (vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U] 
                                        >> 8U)) << 
                                 (0x0000000fU & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q), 1U)))));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_359 = ((8U 
                                                   != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_push));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d 
        = (((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready) 
            & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_valid))
            ? (((IData)(__VdfgRegularize_h591265a2_1_2) 
                | ((IData)(__VdfgRegularize_h591265a2_1_1) 
                   | ((3U > (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                      & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                         >> 3U)))) ? ((IData)(__VdfgRegularize_h591265a2_1_2)
                                       ? 1U : ((IData)(__VdfgRegularize_h591265a2_1_1)
                                                ? 2U
                                                : 3U))
                : ((1U & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d))
                    ? 0U : (((1U <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                             & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                >> 1U)) ? 1U : (((2U 
                                                  <= (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q)) 
                                                 & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d) 
                                                    >> 2U))
                                                 ? 2U
                                                 : 3U))))
            : (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q));
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__ 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__ 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__aw_ready));
    vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_n 
        = (7U & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q) 
                 + (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_359)));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_185)) 
           & (IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__2__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_185));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((~ (IData)(__VdfgRegularize_hebeb780c_0_179)) 
           & (IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__));
    vlSelfRef.__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o 
        = ((IData)(__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__) 
           & (IData)(__VdfgRegularize_hebeb780c_0_179));
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((8U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_w_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_w_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_w_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_w_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 4)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q) 
                                           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:174: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock_req: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock_req] lock_req: It is disallowed to deassert unserved request signals when LockIn is enabled. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:174)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 174, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:315: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.req0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.req0] req0: Req in implies req out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:315)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 315, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid)) 
                                       | (0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:317: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.req1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.req1] req1: Req out implies req in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:317)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 317, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
                                            ? (2U | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
                                            : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1)) 
                                       | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
                                            ? (2U | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
                                            : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel)) 
                                          == (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:169: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gen_int_rr.gen_lock.lock] lock: Lock implies same arbiter decision in next cycle if output is not ready. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:169)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 169, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                      << 3U) 
                                                     | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                        << 2U)) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT0_I(
                                                   ((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                      << 3U) 
                                                     | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                        << 2U)) 
                                                    | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                        << 1U) 
                                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:305: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.hot_one: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.hot_one] hot_one: Grant signal must be hot1 or zero. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:305)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 305, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                              | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                 | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o))))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                           | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                              | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                 | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o))))) 
                                       | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:307: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt0: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt0] gnt0: Grant out implies grant in. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:307)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 307, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid)) 
                                       | ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                   | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o))))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid)) 
                                       | ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready)) 
                                          | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                             | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                   | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o))))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:310: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt1: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt1] gnt1: Req out and grant in implies grant out. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:310)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 310, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid)) 
                                       | ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready)) 
                                          | (((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                << 3U) 
                                               | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                  << 2U)) 
                                              | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o) 
                                                  << 1U) 
                                                 | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o))) 
                                             >> ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
                                                  ? 
                                                 (2U 
                                                  | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
                                                  : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_aw_arbiter.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid)) 
                                       | ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready)) 
                                          | (((((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                << 3U) 
                                               | ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                  << 2U)) 
                                              | (((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o) 
                                                  << 1U) 
                                                 | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o))) 
                                             >> ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
                                                  ? 
                                                 (2U 
                                                  | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
                                                  : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel)))))))))) {
                VL_WRITEF_NX("[%0t] %%Error: rr_arb_tree.sv:313: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt_idx: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.gen_mst_port_mux[1].i_axi_mux.gen_mux.i_ar_arbiter.gen_arbiter.gnt_idx] gnt_idx: Idx_o / gnt_o do not match. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv:313)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/rr_arb_tree.sv", 313, "");
            }
        }
    }
    vlSelfRef.gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1 
        = ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? (2U | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
            : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    vlSelfRef.gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1 
        = ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel)
            ? (2U | (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__))
            : (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    vlSelfRef.gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid) 
              & (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready))));
    vlSelfRef.gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1 
        = ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n) 
           & ((IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid) 
              & (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready))));
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__1(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VdfgRegularize_h591265a2_0_2 = ((4U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U])
                                                 ? 
                                                ((IData)(1U) 
                                                 << 
                                                 (3U 
                                                  & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U]))
                                                 : 0U);
    vlSelfRef.__VdfgRegularize_h591265a2_0_1 = ((0x00001000U 
                                                 & vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U])
                                                 ? 
                                                ((IData)(1U) 
                                                 << 
                                                 (3U 
                                                  & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                                     >> 0x0000000aU)))
                                                 : 0U);
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__2(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__2\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_n;
        if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
        }
        if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) 
             | (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain))) {
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        }
        if (((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) 
             | (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain))) {
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        }
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_n;
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_359) {
            vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q 
                = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n;
        }
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        if (vlSelfRef.__PVT__gen_mux__DOT__load_aw_lock) {
            vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_q 
                = vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_d;
        }
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q 
            = vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d;
        if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill) {
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U];
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U];
            vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] 
                = vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U];
        }
        if (vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                = vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[0U];
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                = vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[1U];
            vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                = vlSelfRef.__PVT__gen_mux__DOT__mst_aw_chan[2U];
        }
        if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill) {
            if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
                if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__) {
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[1U] 
                            << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[0U] 
                                               >> 1U));
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[2U] 
                            << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[1U] 
                                               >> 1U));
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                        = (0x0000000cU | (3U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[2U] 
                                                >> 1U)));
                } else {
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[1U] 
                            << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[0U] 
                                               >> 1U));
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[2U] 
                            << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[1U] 
                                               >> 1U));
                    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                        = (8U | (3U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[2U] 
                                       >> 1U)));
                }
            } else if (vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel) {
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                    = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[1U] 
                        << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[0U] 
                                           >> 1U));
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                    = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[2U] 
                        << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[1U] 
                                           >> 1U));
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                    = (4U | (3U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[2U] 
                                   >> 1U)));
            } else {
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] 
                    = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[1U] 
                        << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[0U] 
                                           >> 1U));
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] 
                    = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[2U] 
                        << 0x0000001fU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[1U] 
                                           >> 1U));
                vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] 
                    = (3U & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[2U] 
                             >> 1U));
            }
        }
    } else {
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__lock_aw_valid_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U] = 0U;
        vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U] = 0U;
    }
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__gen_mux__DOT__ar_ready = (1U & 
                                               ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready = (1U 
                                                   & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                      | (~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data = (3U 
                                                  & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q) 
                                                     >> 
                                                     ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q) 
                                                      << 1U)));
}

void Vaxi4_xbar_tb_axi_mux__pi3___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___nba_comb__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
              >> 0x0000000eU));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
              >> 0x0000000fU));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
               >> 0x0000000eU)) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
               >> 0x0000000fU)) & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies = 0U;
    if ((0U != (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q))) {
        vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies 
            = (((~ ((IData)(1U) << (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))) 
                & (IData)(vlSelfRef.__PVT__gen_mux__DOT__slv_w_readies)) 
               | (0x0fU & ((1U & (vlSymsp->TOP.axi4_xbar_tb__DOT__slv_resp[5U] 
                                  >> 0x0000000dU)) 
                           << (IData)(vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data))));
    }
}
