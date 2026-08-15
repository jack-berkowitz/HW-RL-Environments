// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_err_slv__pi5___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*6:0*/ __VdfgRegularize_h247165ad_0_1;
    __VdfgRegularize_h247165ad_0_1 = 0;
    // Body
    vlSelfRef.__PVT__r_fifo_data = (0x00000fffU & (
                                                   (0x2fU 
                                                    >= 
                                                    (0x0000003fU 
                                                     & ((IData)(0x0000000cU) 
                                                        * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q))))
                                                    ? (IData)(
                                                              (vlSelfRef.__PVT__i_r_fifo__DOT__mem_q 
                                                               >> 
                                                               (0x0000003fU 
                                                                & ((IData)(0x0000000cU) 
                                                                   * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q)))))
                                                    : (IData)(vlSelfRef.i_r_fifo__DOT____Vxrand___0)));
    __VdfgRegularize_h247165ad_0_1 = (6U | (0x00000078U 
                                            & (((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__mem_q) 
                                                >> 
                                                ((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q) 
                                                 << 2U)) 
                                               << 3U)));
    if (vlSelfRef.__PVT__r_busy_q) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_112[0U] 
            = (0xadcab1ecU | ((0U == (0x000000ffU & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))) 
                              << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_112[1U] = 0xa11ab1ebU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_112[2U] 
            = (0x00000100U | (0x000000fcU & (0x0000000cU 
                                             | (0x000000f0U 
                                                & ((IData)(vlSelfRef.__PVT__r_fifo_data) 
                                                   >> 4U)))));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_112[0U] = 0xadcab1ecU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_112[1U] = 0xa11ab1ebU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_112[2U] 
            = (0x0000000cU | (0x000000f0U & ((IData)(vlSelfRef.__PVT__r_fifo_data) 
                                             >> 4U)));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_111 = ((0U 
                                                   == (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q))
                                                   ? (IData)(__VdfgRegularize_h247165ad_0_1)
                                                   : 
                                                  (0x00000080U 
                                                   | (IData)(__VdfgRegularize_h247165ad_0_1)));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_err_slv__pi5___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*6:0*/ __VdfgRegularize_h247165ad_0_1;
    __VdfgRegularize_h247165ad_0_1 = 0;
    // Body
    vlSelfRef.__PVT__r_fifo_data = (0x00000fffU & (
                                                   (0x2fU 
                                                    >= 
                                                    (0x0000003fU 
                                                     & ((IData)(0x0000000cU) 
                                                        * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q))))
                                                    ? (IData)(
                                                              (vlSelfRef.__PVT__i_r_fifo__DOT__mem_q 
                                                               >> 
                                                               (0x0000003fU 
                                                                & ((IData)(0x0000000cU) 
                                                                   * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q)))))
                                                    : (IData)(vlSelfRef.i_r_fifo__DOT____Vxrand___0)));
    __VdfgRegularize_h247165ad_0_1 = (6U | (0x00000078U 
                                            & (((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__mem_q) 
                                                >> 
                                                ((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q) 
                                                 << 2U)) 
                                               << 3U)));
    if (vlSelfRef.__PVT__r_busy_q) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_114[0U] 
            = (0xadcab1ecU | ((0U == (0x000000ffU & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))) 
                              << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_114[1U] = 0xa11ab1ebU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_114[2U] 
            = (0x00000100U | (0x000000fcU & (0x0000000cU 
                                             | (0x000000f0U 
                                                & ((IData)(vlSelfRef.__PVT__r_fifo_data) 
                                                   >> 4U)))));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_114[0U] = 0xadcab1ecU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_114[1U] = 0xa11ab1ebU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_114[2U] 
            = (0x0000000cU | (0x000000f0U & ((IData)(vlSelfRef.__PVT__r_fifo_data) 
                                             >> 4U)));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_113 = ((0U 
                                                   == (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q))
                                                   ? (IData)(__VdfgRegularize_h247165ad_0_1)
                                                   : 
                                                  (0x00000080U 
                                                   | (IData)(__VdfgRegularize_h247165ad_0_1)));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_err_slv__pi5___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*6:0*/ __VdfgRegularize_h247165ad_0_1;
    __VdfgRegularize_h247165ad_0_1 = 0;
    // Body
    vlSelfRef.__PVT__r_fifo_data = (0x00000fffU & (
                                                   (0x2fU 
                                                    >= 
                                                    (0x0000003fU 
                                                     & ((IData)(0x0000000cU) 
                                                        * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q))))
                                                    ? (IData)(
                                                              (vlSelfRef.__PVT__i_r_fifo__DOT__mem_q 
                                                               >> 
                                                               (0x0000003fU 
                                                                & ((IData)(0x0000000cU) 
                                                                   * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q)))))
                                                    : (IData)(vlSelfRef.i_r_fifo__DOT____Vxrand___0)));
    __VdfgRegularize_h247165ad_0_1 = (6U | (0x00000078U 
                                            & (((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__mem_q) 
                                                >> 
                                                ((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q) 
                                                 << 2U)) 
                                               << 3U)));
    if (vlSelfRef.__PVT__r_busy_q) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_116[0U] 
            = (0xadcab1ecU | ((0U == (0x000000ffU & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))) 
                              << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_116[1U] = 0xa11ab1ebU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_116[2U] 
            = (0x00000100U | (0x000000fcU & (0x0000000cU 
                                             | (0x000000f0U 
                                                & ((IData)(vlSelfRef.__PVT__r_fifo_data) 
                                                   >> 4U)))));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_116[0U] = 0xadcab1ecU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_116[1U] = 0xa11ab1ebU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_116[2U] 
            = (0x0000000cU | (0x000000f0U & ((IData)(vlSelfRef.__PVT__r_fifo_data) 
                                             >> 4U)));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_115 = ((0U 
                                                   == (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q))
                                                   ? (IData)(__VdfgRegularize_h247165ad_0_1)
                                                   : 
                                                  (0x00000080U 
                                                   | (IData)(__VdfgRegularize_h247165ad_0_1)));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_err_slv__pi5___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*6:0*/ __VdfgRegularize_h247165ad_0_1;
    __VdfgRegularize_h247165ad_0_1 = 0;
    // Body
    vlSelfRef.__PVT__r_fifo_data = (0x00000fffU & (
                                                   (0x2fU 
                                                    >= 
                                                    (0x0000003fU 
                                                     & ((IData)(0x0000000cU) 
                                                        * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q))))
                                                    ? (IData)(
                                                              (vlSelfRef.__PVT__i_r_fifo__DOT__mem_q 
                                                               >> 
                                                               (0x0000003fU 
                                                                & ((IData)(0x0000000cU) 
                                                                   * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q)))))
                                                    : (IData)(vlSelfRef.i_r_fifo__DOT____Vxrand___0)));
    __VdfgRegularize_h247165ad_0_1 = (6U | (0x00000078U 
                                            & (((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__mem_q) 
                                                >> 
                                                ((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q) 
                                                 << 2U)) 
                                               << 3U)));
    if (vlSelfRef.__PVT__r_busy_q) {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_118[0U] 
            = (0xadcab1ecU | ((0U == (0x000000ffU & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))) 
                              << 1U));
        vlSelfRef.__VdfgRegularize_hebeb780c_0_118[1U] = 0xa11ab1ebU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_118[2U] 
            = (0x00000100U | (0x000000fcU & (0x0000000cU 
                                             | (0x000000f0U 
                                                & ((IData)(vlSelfRef.__PVT__r_fifo_data) 
                                                   >> 4U)))));
    } else {
        vlSelfRef.__VdfgRegularize_hebeb780c_0_118[0U] = 0xadcab1ecU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_118[1U] = 0xa11ab1ebU;
        vlSelfRef.__VdfgRegularize_hebeb780c_0_118[2U] 
            = (0x0000000cU | (0x000000f0U & ((IData)(vlSelfRef.__PVT__r_fifo_data) 
                                             >> 4U)));
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_117 = ((0U 
                                                   == (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q))
                                                   ? (IData)(__VdfgRegularize_h247165ad_0_1)
                                                   : 
                                                  (0x00000080U 
                                                   | (IData)(__VdfgRegularize_h247165ad_0_1)));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_err_slv__pi5___ctor_var_reset(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___ctor_var_reset\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->clk_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11908517815223722933ull);
    vlSelf->rst_ni = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3161515032326629241ull);
    vlSelf->test_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2676571483806808904ull);
    VL_SCOPED_RAND_RESET_W(217, vlSelf->slv_req_i, __VscopeHash, 4004120886065445541ull);
    VL_SCOPED_RAND_RESET_W(84, vlSelf->slv_resp_o, __VscopeHash, 13554179404449265617ull);
    vlSelf->__PVT__w_fifo_empty = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10169998054971065823ull);
    vlSelf->__PVT__w_fifo_push = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15777664561065099562ull);
    vlSelf->__PVT__w_fifo_pop = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8535331356646934531ull);
    vlSelf->__PVT__b_fifo_pop = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17664570909223435480ull);
    vlSelf->__PVT__r_fifo_push = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4746195088888830833ull);
    vlSelf->__PVT__r_fifo_pop = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3182086148458131404ull);
    vlSelf->__PVT__r_fifo_data = VL_SCOPED_RAND_RESET_I(12, __VscopeHash, 14030566895188113095ull);
    vlSelf->__PVT__r_busy_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13154906206474791768ull);
    vlSelf->__PVT__r_busy_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3741149728751660728ull);
    vlSelf->__PVT__r_busy_load = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15731841178208513063ull);
    vlSelf->__VdfgExtracted_h2ee1ee4a__0 = 0;
    vlSelf->__VdfgRegularize_h247165ad_0_6 = 0;
    vlSelf->__PVT__i_w_fifo__DOT__read_pointer_n = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 12887394251763241468ull);
    vlSelf->__PVT__i_w_fifo__DOT__read_pointer_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 12413052322418714628ull);
    vlSelf->__PVT__i_w_fifo__DOT__write_pointer_n = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 15556570544035244526ull);
    vlSelf->__PVT__i_w_fifo__DOT__write_pointer_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2322314790833130319ull);
    vlSelf->__PVT__i_w_fifo__DOT__status_cnt_n = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 870241709348881111ull);
    vlSelf->__PVT__i_w_fifo__DOT__status_cnt_q = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 10137763346178567396ull);
    vlSelf->__PVT__i_w_fifo__DOT__mem_n = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 1633100368619914825ull);
    vlSelf->__PVT__i_w_fifo__DOT__mem_q = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 15921747763259765634ull);
    vlSelf->__PVT__i_b_fifo__DOT__read_pointer_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15885069431484181703ull);
    vlSelf->__PVT__i_b_fifo__DOT__read_pointer_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8600004123340548361ull);
    vlSelf->__PVT__i_b_fifo__DOT__write_pointer_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6443658824025690523ull);
    vlSelf->__PVT__i_b_fifo__DOT__write_pointer_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17688458232184626187ull);
    vlSelf->__PVT__i_b_fifo__DOT__status_cnt_n = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 1170282868941551475ull);
    vlSelf->__PVT__i_b_fifo__DOT__status_cnt_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 3612604344210149851ull);
    vlSelf->__PVT__i_b_fifo__DOT__mem_n = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 11081134986136055623ull);
    vlSelf->__PVT__i_b_fifo__DOT__mem_q = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 3156790415753709098ull);
    vlSelf->i_r_fifo__DOT____Vlvbound_h93549ebf__0 = 0;
    vlSelf->i_r_fifo__DOT____Vxrand___0 = VL_SCOPED_RAND_RESET_ASSIGN_I(12, __VscopeHash, 14285876042589077828ull);
    vlSelf->__PVT__i_r_fifo__DOT__read_pointer_n = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 8851771365788231000ull);
    vlSelf->__PVT__i_r_fifo__DOT__read_pointer_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 724575265888881641ull);
    vlSelf->__PVT__i_r_fifo__DOT__write_pointer_n = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 7971831447339705599ull);
    vlSelf->__PVT__i_r_fifo__DOT__write_pointer_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 18437993587005391991ull);
    vlSelf->__PVT__i_r_fifo__DOT__status_cnt_n = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 1491828246682122945ull);
    vlSelf->__PVT__i_r_fifo__DOT__status_cnt_q = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 11833117763200251493ull);
    vlSelf->__PVT__i_r_fifo__DOT__mem_n = VL_SCOPED_RAND_RESET_Q(48, __VscopeHash, 17537950674149365696ull);
    vlSelf->__PVT__i_r_fifo__DOT__mem_q = VL_SCOPED_RAND_RESET_Q(48, __VscopeHash, 12654759760196810200ull);
    vlSelf->__PVT__i_r_counter__DOT__i_counter__DOT__counter_q = VL_SCOPED_RAND_RESET_I(9, __VscopeHash, 2574954731467683193ull);
    vlSelf->__PVT__i_r_counter__DOT__i_counter__DOT__counter_d = VL_SCOPED_RAND_RESET_I(9, __VscopeHash, 6093963652927014595ull);
    vlSelf->__VdfgRegularize_hebeb780c_0_111 = 0;
    VL_ZERO_RESET_W(73, vlSelf->__VdfgRegularize_hebeb780c_0_112);
    vlSelf->__VdfgRegularize_hebeb780c_0_113 = 0;
    VL_ZERO_RESET_W(73, vlSelf->__VdfgRegularize_hebeb780c_0_114);
    vlSelf->__VdfgRegularize_hebeb780c_0_115 = 0;
    VL_ZERO_RESET_W(73, vlSelf->__VdfgRegularize_hebeb780c_0_116);
    vlSelf->__VdfgRegularize_hebeb780c_0_117 = 0;
    VL_ZERO_RESET_W(73, vlSelf->__VdfgRegularize_hebeb780c_0_118);
    vlSelf->__VdfgRegularize_hebeb780c_0_351 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_352 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_353 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_354 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_355 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_356 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_357 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_358 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__r_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__r_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__r_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__r_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop = 0;
}
