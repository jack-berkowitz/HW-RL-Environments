// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

void Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VdfgRegularize_h247165ad_0_5;
    __VdfgRegularize_h247165ad_0_5 = 0;
    // Body
    vlSelfRef.__VdfgExtracted_h2ee1ee4a__0 = (vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[0U] 
                                              & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    vlSelfRef.__PVT__w_fifo_push = ((4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                    & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_20));
    vlSelfRef.__PVT__b_fifo_pop = ((0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                   & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[2U] 
                                      >> 3U));
    vlSelfRef.__PVT__r_fifo_push = ((4U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                    & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[0U]);
    __VdfgRegularize_h247165ad_0_5 = ((IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0) 
                                      & (0U == (0x000000ffU 
                                                & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))));
    if (vlSelfRef.__PVT__r_busy_q) {
        vlSelfRef.__PVT__r_busy_d = ((IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0)
                                      ? ((0U != (0x000000ffU 
                                                 & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))) 
                                         & (IData)(vlSelfRef.__PVT__r_busy_q))
                                      : (IData)(vlSelfRef.__PVT__r_busy_q));
        vlSelfRef.__PVT__r_busy_load = __VdfgRegularize_h247165ad_0_5;
    } else {
        vlSelfRef.__PVT__r_busy_d = ((0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                     | (IData)(vlSelfRef.__PVT__r_busy_q));
        vlSelfRef.__PVT__r_busy_load = (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q));
    }
    vlSelfRef.__PVT__w_fifo_empty = ((~ (IData)(vlSelfRef.__PVT__w_fifo_push)) 
                                     & (0U == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)));
    vlSelfRef.__PVT__i_w_fifo__DOT__mem_n = vlSelfRef.__PVT__i_w_fifo__DOT__mem_q;
    vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_n 
        = (1U & (((0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                  & (IData)(vlSelfRef.__PVT__b_fifo_pop))
                  ? ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q))
                  : (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_357 = ((4U 
                                                   != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__r_fifo_push));
    vlSelfRef.__PVT__i_r_fifo__DOT__mem_n = vlSelfRef.__PVT__i_r_fifo__DOT__mem_q;
    vlSelfRef.__PVT__r_fifo_pop = ((IData)(vlSelfRef.__PVT__r_busy_q) 
                                   & (IData)(__VdfgRegularize_h247165ad_0_5));
    vlSelfRef.__VdfgRegularize_h247165ad_0_6 = (1U 
                                                & (~ 
                                                   ((2U 
                                                     == (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                                    | (IData)(vlSelfRef.__PVT__w_fifo_empty))));
    vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_n 
        = (3U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q) 
                 + (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_357)));
    vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_n 
        = (3U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q) 
                 + ((0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                    & (IData)(vlSelfRef.__PVT__r_fifo_pop))));
    vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
        = vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q;
    if (vlSelfRef.__PVT__r_fifo_pop) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d = 0U;
    } else if (((~ (IData)(vlSelfRef.__PVT__r_busy_q)) 
                & (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
            = (0x000000ffU & (IData)(vlSelfRef.__PVT__r_fifo_data));
    } else if (((IData)(vlSelfRef.__PVT__r_busy_q) 
                & (IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0))) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
            = (0x000001ffU & ((IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q) 
                              - (IData)(1U)));
    }
    vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__r_fifo_push) & (4U 
                                                  != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.i_r_fifo__DOT____Vlvbound_h93549ebf__0 
            = ((0x00000f00U & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[2U] 
                                << 9U) | (0x00000100U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[1U] 
                                             >> 0x00000017U)))) 
               | (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[0U] 
                                 >> 0x00000017U)));
        if ((0x2fU >= (0x0000003fU & ((IData)(0x0000000cU) 
                                      * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))) {
            vlSelfRef.__PVT__i_r_fifo__DOT__mem_n = 
                (((~ (0x0000000000000fffULL << (0x0000003fU 
                                                & ((IData)(0x0000000cU) 
                                                   * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))) 
                  & vlSelfRef.__PVT__i_r_fifo__DOT__mem_n) 
                 | (0x0000ffffffffffffULL & ((QData)((IData)(vlSelfRef.i_r_fifo__DOT____Vlvbound_h93549ebf__0)) 
                                             << (0x0000003fU 
                                                 & ((IData)(0x0000000cU) 
                                                    * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))));
        }
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__r_fifo_pop) & (0U 
                                                 != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__r_fifo_push) & (IData)(vlSelfRef.__PVT__r_fifo_pop)) 
          & (4U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__w_fifo_pop = ((IData)(vlSelfRef.__VdfgRegularize_h247165ad_0_6) 
                                   & (0x00000050U == 
                                      (0x00000050U 
                                       & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[2U])));
    vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (2U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__b_fifo_pop) & (0U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = (3U & ((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__w_fifo_pop) & (IData)(vlSelfRef.__PVT__b_fifo_pop)) 
          & (2U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
        = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_push) & (4U 
                                                  != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__mem_n = (((~ 
                                                   ((IData)(0x000fU) 
                                                    << 
                                                    (0x0000000fU 
                                                     & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q), 2U)))) 
                                                  & (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__mem_n)) 
                                                 | (0x0000ffffU 
                                                    & ((0x0000000fU 
                                                        & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[6U] 
                                                           >> 0x00000014U)) 
                                                       << 
                                                       (0x0000000fU 
                                                        & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q), 2U)))));
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q)));
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)));
    } else {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
    }
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__w_fifo_push) & (IData)(vlSelfRef.__PVT__w_fifo_pop)) 
          & (4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q))) 
         & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
        = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q)));
    }
    if (((0U == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
         & (IData)(vlSelfRef.__PVT__w_fifo_push))) {
        if (vlSelfRef.__PVT__w_fifo_pop) {
            vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q;
            vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
            vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_358 = ((2U 
                                                   != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__w_fifo_pop));
    vlSelfRef.__PVT__i_b_fifo__DOT__mem_n = vlSelfRef.__PVT__i_b_fifo__DOT__mem_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (2U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__mem_n = (((~ 
                                                   ((IData)(0x0fU) 
                                                    << 
                                                    (7U 
                                                     & VL_SHIFTL_III(3,32,32, (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q), 2U)))) 
                                                  & (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__mem_n)) 
                                                 | (0x00ffU 
                                                    & ((0x0000000fU 
                                                        & (((0U 
                                                             == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                                            & (IData)(vlSelfRef.__PVT__w_fifo_push))
                                                            ? 
                                                           ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[6U] 
                                                             << 0x0000000cU) 
                                                            | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_187[6U] 
                                                               >> 0x00000014U))
                                                            : 
                                                           ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__mem_q) 
                                                            >> 
                                                            ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q) 
                                                             << 2U)))) 
                                                       << 
                                                       (7U 
                                                        & VL_SHIFTL_III(3,32,32, (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q), 2U)))));
    }
    vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_n 
        = (1U & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_358)
                  ? ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q))
                  : (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q)));
}

void Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((4U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_w_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_w_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_w_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_w_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_b_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_b_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((4U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__r_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_r_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_r_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_r_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_r_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((2U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_b_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[0].i_axi_err_slv.i_b_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
}

void Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__1(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*6:0*/ __VdfgRegularize_h247165ad_0_1;
    __VdfgRegularize_h247165ad_0_1 = 0;
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n;
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_n;
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_357) {
            vlSelfRef.__PVT__i_r_fifo__DOT__mem_q = vlSelfRef.__PVT__i_r_fifo__DOT__mem_n;
        }
        if (vlSelfRef.__PVT__r_busy_load) {
            vlSelfRef.__PVT__r_busy_q = vlSelfRef.__PVT__r_busy_d;
        }
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q 
            = vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d;
        if (((4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
             & (IData)(vlSelfRef.__PVT__w_fifo_push))) {
            vlSelfRef.__PVT__i_w_fifo__DOT__mem_q = vlSelfRef.__PVT__i_w_fifo__DOT__mem_n;
        }
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_358) {
            vlSelfRef.__PVT__i_b_fifo__DOT__mem_q = vlSelfRef.__PVT__i_b_fifo__DOT__mem_n;
        }
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n;
    } else {
        vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__mem_q = 0ULL;
        vlSelfRef.__PVT__r_busy_q = 0U;
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__i_b_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q = 0U;
    }
    vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_n));
    vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_n));
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

void Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VdfgRegularize_h247165ad_0_5;
    __VdfgRegularize_h247165ad_0_5 = 0;
    // Body
    vlSelfRef.__VdfgExtracted_h2ee1ee4a__0 = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[6U] 
                                               >> 0x00000019U) 
                                              & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    vlSelfRef.__PVT__w_fifo_push = ((4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                    & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_35));
    vlSelfRef.__PVT__b_fifo_pop = ((0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                   & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[2U] 
                                      >> 3U));
    vlSelfRef.__PVT__r_fifo_push = ((4U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                    & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[0U]);
    __VdfgRegularize_h247165ad_0_5 = ((IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0) 
                                      & (0U == (0x000000ffU 
                                                & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))));
    if (vlSelfRef.__PVT__r_busy_q) {
        vlSelfRef.__PVT__r_busy_d = ((IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0)
                                      ? ((0U != (0x000000ffU 
                                                 & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))) 
                                         & (IData)(vlSelfRef.__PVT__r_busy_q))
                                      : (IData)(vlSelfRef.__PVT__r_busy_q));
        vlSelfRef.__PVT__r_busy_load = __VdfgRegularize_h247165ad_0_5;
    } else {
        vlSelfRef.__PVT__r_busy_d = ((0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                     | (IData)(vlSelfRef.__PVT__r_busy_q));
        vlSelfRef.__PVT__r_busy_load = (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q));
    }
    vlSelfRef.__PVT__w_fifo_empty = ((~ (IData)(vlSelfRef.__PVT__w_fifo_push)) 
                                     & (0U == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)));
    vlSelfRef.__PVT__i_w_fifo__DOT__mem_n = vlSelfRef.__PVT__i_w_fifo__DOT__mem_q;
    vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_n 
        = (1U & (((0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                  & (IData)(vlSelfRef.__PVT__b_fifo_pop))
                  ? ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q))
                  : (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_355 = ((4U 
                                                   != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__r_fifo_push));
    vlSelfRef.__PVT__i_r_fifo__DOT__mem_n = vlSelfRef.__PVT__i_r_fifo__DOT__mem_q;
    vlSelfRef.__PVT__r_fifo_pop = ((IData)(vlSelfRef.__PVT__r_busy_q) 
                                   & (IData)(__VdfgRegularize_h247165ad_0_5));
    vlSelfRef.__VdfgRegularize_h247165ad_0_6 = (1U 
                                                & (~ 
                                                   ((2U 
                                                     == (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                                    | (IData)(vlSelfRef.__PVT__w_fifo_empty))));
    vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_n 
        = (3U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q) 
                 + (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_355)));
    vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_n 
        = (3U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q) 
                 + ((0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                    & (IData)(vlSelfRef.__PVT__r_fifo_pop))));
    vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
        = vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q;
    if (vlSelfRef.__PVT__r_fifo_pop) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d = 0U;
    } else if (((~ (IData)(vlSelfRef.__PVT__r_busy_q)) 
                & (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
            = (0x000000ffU & (IData)(vlSelfRef.__PVT__r_fifo_data));
    } else if (((IData)(vlSelfRef.__PVT__r_busy_q) 
                & (IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0))) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
            = (0x000001ffU & ((IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q) 
                              - (IData)(1U)));
    }
    vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__r_fifo_push) & (4U 
                                                  != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.i_r_fifo__DOT____Vlvbound_h93549ebf__0 
            = ((0x00000f00U & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[2U] 
                                << 9U) | (0x00000100U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[1U] 
                                             >> 0x00000017U)))) 
               | (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[0U] 
                                 >> 0x00000017U)));
        if ((0x2fU >= (0x0000003fU & ((IData)(0x0000000cU) 
                                      * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))) {
            vlSelfRef.__PVT__i_r_fifo__DOT__mem_n = 
                (((~ (0x0000000000000fffULL << (0x0000003fU 
                                                & ((IData)(0x0000000cU) 
                                                   * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))) 
                  & vlSelfRef.__PVT__i_r_fifo__DOT__mem_n) 
                 | (0x0000ffffffffffffULL & ((QData)((IData)(vlSelfRef.i_r_fifo__DOT____Vlvbound_h93549ebf__0)) 
                                             << (0x0000003fU 
                                                 & ((IData)(0x0000000cU) 
                                                    * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))));
        }
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__r_fifo_pop) & (0U 
                                                 != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__r_fifo_push) & (IData)(vlSelfRef.__PVT__r_fifo_pop)) 
          & (4U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__w_fifo_pop = ((IData)(vlSelfRef.__VdfgRegularize_h247165ad_0_6) 
                                   & (0x00000050U == 
                                      (0x00000050U 
                                       & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[2U])));
    vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (2U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__b_fifo_pop) & (0U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = (3U & ((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__w_fifo_pop) & (IData)(vlSelfRef.__PVT__b_fifo_pop)) 
          & (2U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
        = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_push) & (4U 
                                                  != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__mem_n = (((~ 
                                                   ((IData)(0x000fU) 
                                                    << 
                                                    (0x0000000fU 
                                                     & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q), 2U)))) 
                                                  & (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__mem_n)) 
                                                 | (0x0000ffffU 
                                                    & ((0x0000000fU 
                                                        & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[6U] 
                                                           >> 0x00000014U)) 
                                                       << 
                                                       (0x0000000fU 
                                                        & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q), 2U)))));
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q)));
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)));
    } else {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
    }
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__w_fifo_push) & (IData)(vlSelfRef.__PVT__w_fifo_pop)) 
          & (4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q))) 
         & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
        = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q)));
    }
    if (((0U == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
         & (IData)(vlSelfRef.__PVT__w_fifo_push))) {
        if (vlSelfRef.__PVT__w_fifo_pop) {
            vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q;
            vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
            vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_356 = ((2U 
                                                   != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__w_fifo_pop));
    vlSelfRef.__PVT__i_b_fifo__DOT__mem_n = vlSelfRef.__PVT__i_b_fifo__DOT__mem_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (2U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__mem_n = (((~ 
                                                   ((IData)(0x0fU) 
                                                    << 
                                                    (7U 
                                                     & VL_SHIFTL_III(3,32,32, (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q), 2U)))) 
                                                  & (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__mem_n)) 
                                                 | (0x00ffU 
                                                    & ((0x0000000fU 
                                                        & (((0U 
                                                             == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                                            & (IData)(vlSelfRef.__PVT__w_fifo_push))
                                                            ? 
                                                           ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[6U] 
                                                             << 0x0000000cU) 
                                                            | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_190[6U] 
                                                               >> 0x00000014U))
                                                            : 
                                                           ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__mem_q) 
                                                            >> 
                                                            ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q) 
                                                             << 2U)))) 
                                                       << 
                                                       (7U 
                                                        & VL_SHIFTL_III(3,32,32, (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q), 2U)))));
    }
    vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_n 
        = (1U & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_356)
                  ? ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q))
                  : (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q)));
}

void Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((4U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_w_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_w_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_w_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_w_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_b_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_b_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((4U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__r_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_r_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_r_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_r_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_r_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((2U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_b_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[1].i_axi_err_slv.i_b_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
}

void Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__1(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*6:0*/ __VdfgRegularize_h247165ad_0_1;
    __VdfgRegularize_h247165ad_0_1 = 0;
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n;
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_n;
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_355) {
            vlSelfRef.__PVT__i_r_fifo__DOT__mem_q = vlSelfRef.__PVT__i_r_fifo__DOT__mem_n;
        }
        if (vlSelfRef.__PVT__r_busy_load) {
            vlSelfRef.__PVT__r_busy_q = vlSelfRef.__PVT__r_busy_d;
        }
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q 
            = vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d;
        if (((4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
             & (IData)(vlSelfRef.__PVT__w_fifo_push))) {
            vlSelfRef.__PVT__i_w_fifo__DOT__mem_q = vlSelfRef.__PVT__i_w_fifo__DOT__mem_n;
        }
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_356) {
            vlSelfRef.__PVT__i_b_fifo__DOT__mem_q = vlSelfRef.__PVT__i_b_fifo__DOT__mem_n;
        }
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n;
    } else {
        vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__mem_q = 0ULL;
        vlSelfRef.__PVT__r_busy_q = 0U;
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__i_b_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q = 0U;
    }
    vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_n));
    vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_n));
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

void Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VdfgRegularize_h247165ad_0_5;
    __VdfgRegularize_h247165ad_0_5 = 0;
    // Body
    vlSelfRef.__VdfgExtracted_h2ee1ee4a__0 = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[13U] 
                                               >> 0x00000012U) 
                                              & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    vlSelfRef.__PVT__w_fifo_push = ((4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                    & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_50));
    vlSelfRef.__PVT__b_fifo_pop = ((0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                   & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[2U] 
                                      >> 3U));
    vlSelfRef.__PVT__r_fifo_push = ((4U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                    & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[0U]);
    __VdfgRegularize_h247165ad_0_5 = ((IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0) 
                                      & (0U == (0x000000ffU 
                                                & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))));
    if (vlSelfRef.__PVT__r_busy_q) {
        vlSelfRef.__PVT__r_busy_d = ((IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0)
                                      ? ((0U != (0x000000ffU 
                                                 & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))) 
                                         & (IData)(vlSelfRef.__PVT__r_busy_q))
                                      : (IData)(vlSelfRef.__PVT__r_busy_q));
        vlSelfRef.__PVT__r_busy_load = __VdfgRegularize_h247165ad_0_5;
    } else {
        vlSelfRef.__PVT__r_busy_d = ((0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                     | (IData)(vlSelfRef.__PVT__r_busy_q));
        vlSelfRef.__PVT__r_busy_load = (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q));
    }
    vlSelfRef.__PVT__w_fifo_empty = ((~ (IData)(vlSelfRef.__PVT__w_fifo_push)) 
                                     & (0U == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)));
    vlSelfRef.__PVT__i_w_fifo__DOT__mem_n = vlSelfRef.__PVT__i_w_fifo__DOT__mem_q;
    vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_n 
        = (1U & (((0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                  & (IData)(vlSelfRef.__PVT__b_fifo_pop))
                  ? ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q))
                  : (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_353 = ((4U 
                                                   != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__r_fifo_push));
    vlSelfRef.__PVT__i_r_fifo__DOT__mem_n = vlSelfRef.__PVT__i_r_fifo__DOT__mem_q;
    vlSelfRef.__PVT__r_fifo_pop = ((IData)(vlSelfRef.__PVT__r_busy_q) 
                                   & (IData)(__VdfgRegularize_h247165ad_0_5));
    vlSelfRef.__VdfgRegularize_h247165ad_0_6 = (1U 
                                                & (~ 
                                                   ((2U 
                                                     == (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                                    | (IData)(vlSelfRef.__PVT__w_fifo_empty))));
    vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_n 
        = (3U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q) 
                 + (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_353)));
    vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_n 
        = (3U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q) 
                 + ((0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                    & (IData)(vlSelfRef.__PVT__r_fifo_pop))));
    vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
        = vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q;
    if (vlSelfRef.__PVT__r_fifo_pop) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d = 0U;
    } else if (((~ (IData)(vlSelfRef.__PVT__r_busy_q)) 
                & (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
            = (0x000000ffU & (IData)(vlSelfRef.__PVT__r_fifo_data));
    } else if (((IData)(vlSelfRef.__PVT__r_busy_q) 
                & (IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0))) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
            = (0x000001ffU & ((IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q) 
                              - (IData)(1U)));
    }
    vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__r_fifo_push) & (4U 
                                                  != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.i_r_fifo__DOT____Vlvbound_h93549ebf__0 
            = ((0x00000f00U & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[2U] 
                                << 9U) | (0x00000100U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[1U] 
                                             >> 0x00000017U)))) 
               | (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[0U] 
                                 >> 0x00000017U)));
        if ((0x2fU >= (0x0000003fU & ((IData)(0x0000000cU) 
                                      * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))) {
            vlSelfRef.__PVT__i_r_fifo__DOT__mem_n = 
                (((~ (0x0000000000000fffULL << (0x0000003fU 
                                                & ((IData)(0x0000000cU) 
                                                   * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))) 
                  & vlSelfRef.__PVT__i_r_fifo__DOT__mem_n) 
                 | (0x0000ffffffffffffULL & ((QData)((IData)(vlSelfRef.i_r_fifo__DOT____Vlvbound_h93549ebf__0)) 
                                             << (0x0000003fU 
                                                 & ((IData)(0x0000000cU) 
                                                    * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))));
        }
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__r_fifo_pop) & (0U 
                                                 != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__r_fifo_push) & (IData)(vlSelfRef.__PVT__r_fifo_pop)) 
          & (4U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__w_fifo_pop = ((IData)(vlSelfRef.__VdfgRegularize_h247165ad_0_6) 
                                   & (0x00000050U == 
                                      (0x00000050U 
                                       & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[2U])));
    vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (2U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__b_fifo_pop) & (0U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = (3U & ((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__w_fifo_pop) & (IData)(vlSelfRef.__PVT__b_fifo_pop)) 
          & (2U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
        = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_push) & (4U 
                                                  != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__mem_n = (((~ 
                                                   ((IData)(0x000fU) 
                                                    << 
                                                    (0x0000000fU 
                                                     & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q), 2U)))) 
                                                  & (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__mem_n)) 
                                                 | (0x0000ffffU 
                                                    & ((0x0000000fU 
                                                        & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[6U] 
                                                           >> 0x00000014U)) 
                                                       << 
                                                       (0x0000000fU 
                                                        & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q), 2U)))));
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q)));
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)));
    } else {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
    }
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__w_fifo_push) & (IData)(vlSelfRef.__PVT__w_fifo_pop)) 
          & (4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q))) 
         & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
        = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q)));
    }
    if (((0U == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
         & (IData)(vlSelfRef.__PVT__w_fifo_push))) {
        if (vlSelfRef.__PVT__w_fifo_pop) {
            vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q;
            vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
            vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_354 = ((2U 
                                                   != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__w_fifo_pop));
    vlSelfRef.__PVT__i_b_fifo__DOT__mem_n = vlSelfRef.__PVT__i_b_fifo__DOT__mem_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (2U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__mem_n = (((~ 
                                                   ((IData)(0x0fU) 
                                                    << 
                                                    (7U 
                                                     & VL_SHIFTL_III(3,32,32, (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q), 2U)))) 
                                                  & (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__mem_n)) 
                                                 | (0x00ffU 
                                                    & ((0x0000000fU 
                                                        & (((0U 
                                                             == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                                            & (IData)(vlSelfRef.__PVT__w_fifo_push))
                                                            ? 
                                                           ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[6U] 
                                                             << 0x0000000cU) 
                                                            | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_193[6U] 
                                                               >> 0x00000014U))
                                                            : 
                                                           ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__mem_q) 
                                                            >> 
                                                            ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q) 
                                                             << 2U)))) 
                                                       << 
                                                       (7U 
                                                        & VL_SHIFTL_III(3,32,32, (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q), 2U)))));
    }
    vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_n 
        = (1U & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_354)
                  ? ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q))
                  : (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q)));
}

void Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((4U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_w_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_w_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_w_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_w_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_b_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_b_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((4U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__r_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_r_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_r_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_r_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_r_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((2U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_b_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[2].i_axi_err_slv.i_b_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
}

void Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__1(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*6:0*/ __VdfgRegularize_h247165ad_0_1;
    __VdfgRegularize_h247165ad_0_1 = 0;
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n;
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_n;
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_353) {
            vlSelfRef.__PVT__i_r_fifo__DOT__mem_q = vlSelfRef.__PVT__i_r_fifo__DOT__mem_n;
        }
        if (vlSelfRef.__PVT__r_busy_load) {
            vlSelfRef.__PVT__r_busy_q = vlSelfRef.__PVT__r_busy_d;
        }
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q 
            = vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d;
        if (((4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
             & (IData)(vlSelfRef.__PVT__w_fifo_push))) {
            vlSelfRef.__PVT__i_w_fifo__DOT__mem_q = vlSelfRef.__PVT__i_w_fifo__DOT__mem_n;
        }
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_354) {
            vlSelfRef.__PVT__i_b_fifo__DOT__mem_q = vlSelfRef.__PVT__i_b_fifo__DOT__mem_n;
        }
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n;
    } else {
        vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__mem_q = 0ULL;
        vlSelfRef.__PVT__r_busy_q = 0U;
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__i_b_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q = 0U;
    }
    vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_n));
    vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_n));
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

void Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VdfgRegularize_h247165ad_0_5;
    __VdfgRegularize_h247165ad_0_5 = 0;
    // Body
    vlSelfRef.__VdfgExtracted_h2ee1ee4a__0 = ((vlSymsp->TOP.axi4_xbar_tb__DOT__mst_req[20U] 
                                               >> 0x0000000bU) 
                                              & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel));
    vlSelfRef.__PVT__w_fifo_push = ((4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                    & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_65));
    vlSelfRef.__PVT__b_fifo_pop = ((0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                   & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[2U] 
                                      >> 3U));
    vlSelfRef.__PVT__r_fifo_push = ((4U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                    & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[0U]);
    __VdfgRegularize_h247165ad_0_5 = ((IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0) 
                                      & (0U == (0x000000ffU 
                                                & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))));
    if (vlSelfRef.__PVT__r_busy_q) {
        vlSelfRef.__PVT__r_busy_d = ((IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0)
                                      ? ((0U != (0x000000ffU 
                                                 & (IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q))) 
                                         & (IData)(vlSelfRef.__PVT__r_busy_q))
                                      : (IData)(vlSelfRef.__PVT__r_busy_q));
        vlSelfRef.__PVT__r_busy_load = __VdfgRegularize_h247165ad_0_5;
    } else {
        vlSelfRef.__PVT__r_busy_d = ((0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                     | (IData)(vlSelfRef.__PVT__r_busy_q));
        vlSelfRef.__PVT__r_busy_load = (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q));
    }
    vlSelfRef.__PVT__w_fifo_empty = ((~ (IData)(vlSelfRef.__PVT__w_fifo_push)) 
                                     & (0U == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)));
    vlSelfRef.__PVT__i_w_fifo__DOT__mem_n = vlSelfRef.__PVT__i_w_fifo__DOT__mem_q;
    vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_n 
        = (1U & (((0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                  & (IData)(vlSelfRef.__PVT__b_fifo_pop))
                  ? ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q))
                  : (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q)));
    vlSelfRef.__VdfgRegularize_hebeb780c_0_351 = ((4U 
                                                   != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__r_fifo_push));
    vlSelfRef.__PVT__i_r_fifo__DOT__mem_n = vlSelfRef.__PVT__i_r_fifo__DOT__mem_q;
    vlSelfRef.__PVT__r_fifo_pop = ((IData)(vlSelfRef.__PVT__r_busy_q) 
                                   & (IData)(__VdfgRegularize_h247165ad_0_5));
    vlSelfRef.__VdfgRegularize_h247165ad_0_6 = (1U 
                                                & (~ 
                                                   ((2U 
                                                     == (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                                    | (IData)(vlSelfRef.__PVT__w_fifo_empty))));
    vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_n 
        = (3U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q) 
                 + (IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_351)));
    vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_n 
        = (3U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q) 
                 + ((0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)) 
                    & (IData)(vlSelfRef.__PVT__r_fifo_pop))));
    vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
        = vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q;
    if (vlSelfRef.__PVT__r_fifo_pop) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d = 0U;
    } else if (((~ (IData)(vlSelfRef.__PVT__r_busy_q)) 
                & (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
            = (0x000000ffU & (IData)(vlSelfRef.__PVT__r_fifo_data));
    } else if (((IData)(vlSelfRef.__PVT__r_busy_q) 
                & (IData)(vlSelfRef.__VdfgExtracted_h2ee1ee4a__0))) {
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d 
            = (0x000001ffU & ((IData)(vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q) 
                              - (IData)(1U)));
    }
    vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__r_fifo_push) & (4U 
                                                  != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.i_r_fifo__DOT____Vlvbound_h93549ebf__0 
            = ((0x00000f00U & ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[2U] 
                                << 9U) | (0x00000100U 
                                          & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[1U] 
                                             >> 0x00000017U)))) 
               | (0x000000ffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[0U] 
                                 >> 0x00000017U)));
        if ((0x2fU >= (0x0000003fU & ((IData)(0x0000000cU) 
                                      * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))) {
            vlSelfRef.__PVT__i_r_fifo__DOT__mem_n = 
                (((~ (0x0000000000000fffULL << (0x0000003fU 
                                                & ((IData)(0x0000000cU) 
                                                   * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))) 
                  & vlSelfRef.__PVT__i_r_fifo__DOT__mem_n) 
                 | (0x0000ffffffffffffULL & ((QData)((IData)(vlSelfRef.i_r_fifo__DOT____Vlvbound_h93549ebf__0)) 
                                             << (0x0000003fU 
                                                 & ((IData)(0x0000000cU) 
                                                    * (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q))))));
        }
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__r_fifo_pop) & (0U 
                                                 != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__r_fifo_push) & (IData)(vlSelfRef.__PVT__r_fifo_pop)) 
          & (4U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__w_fifo_pop = ((IData)(vlSelfRef.__VdfgRegularize_h247165ad_0_6) 
                                   & (0x00000050U == 
                                      (0x00000050U 
                                       & vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[2U])));
    vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (2U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)));
    }
    if (((IData)(vlSelfRef.__PVT__b_fifo_pop) & (0U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = (3U & ((IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__w_fifo_pop) & (IData)(vlSelfRef.__PVT__b_fifo_pop)) 
          & (2U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q))) 
         & (0U != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
        = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_push) & (4U 
                                                  != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__mem_n = (((~ 
                                                   ((IData)(0x000fU) 
                                                    << 
                                                    (0x0000000fU 
                                                     & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q), 2U)))) 
                                                  & (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__mem_n)) 
                                                 | (0x0000ffffU 
                                                    & ((0x0000000fU 
                                                        & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[6U] 
                                                           >> 0x00000014U)) 
                                                       << 
                                                       (0x0000000fU 
                                                        & VL_SHIFTL_III(4,32,32, (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q), 2U)))));
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q)));
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)));
    } else {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
    }
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = (7U & ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q) 
                     - (IData)(1U)));
    }
    if (((((IData)(vlSelfRef.__PVT__w_fifo_push) & (IData)(vlSelfRef.__PVT__w_fifo_pop)) 
          & (4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q))) 
         & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
    }
    vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
        = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (~ (IData)(vlSelfRef.__PVT__w_fifo_empty)))) {
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
            = (3U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q)));
    }
    if (((0U == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
         & (IData)(vlSelfRef.__PVT__w_fifo_push))) {
        if (vlSelfRef.__PVT__w_fifo_pop) {
            vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q;
            vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q;
            vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n 
                = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q;
        }
    }
    vlSelfRef.__VdfgRegularize_hebeb780c_0_352 = ((2U 
                                                   != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)) 
                                                  & (IData)(vlSelfRef.__PVT__w_fifo_pop));
    vlSelfRef.__PVT__i_b_fifo__DOT__mem_n = vlSelfRef.__PVT__i_b_fifo__DOT__mem_q;
    if (((IData)(vlSelfRef.__PVT__w_fifo_pop) & (2U 
                                                 != (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q)))) {
        vlSelfRef.__PVT__i_b_fifo__DOT__mem_n = (((~ 
                                                   ((IData)(0x0fU) 
                                                    << 
                                                    (7U 
                                                     & VL_SHIFTL_III(3,32,32, (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q), 2U)))) 
                                                  & (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__mem_n)) 
                                                 | (0x00ffU 
                                                    & ((0x0000000fU 
                                                        & (((0U 
                                                             == (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
                                                            & (IData)(vlSelfRef.__PVT__w_fifo_push))
                                                            ? 
                                                           ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[6U] 
                                                             << 0x0000000cU) 
                                                            | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_196[6U] 
                                                               >> 0x00000014U))
                                                            : 
                                                           ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__mem_q) 
                                                            >> 
                                                            ((IData)(vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q) 
                                                             << 2U)))) 
                                                       << 
                                                       (7U 
                                                        & VL_SHIFTL_III(3,32,32, (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q), 2U)))));
    }
    vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_n 
        = (1U & ((IData)(vlSelfRef.__VdfgRegularize_hebeb780c_0_352)
                  ? ((IData)(1U) + (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q))
                  : (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q)));
}

void Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((4U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_w_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_w_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_w_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_w_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_b_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_b_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((4U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__r_fifo_push)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_r_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_r_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((0U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:149: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_r_fifo.empty_read: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_r_fifo.empty_read] empty_read: Trying to pop data although the FIFO is empty. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:149)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 149, "");
            }
        }
    }
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        if (vlSymsp->_vm_contextp__->assertOnGet(1, 1)) {
            if (VL_UNLIKELY(((1U & (~ ((2U != (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q)) 
                                       | (~ (IData)(vlSelfRef.__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop)))))))) {
                VL_WRITEF_NX("[%0t] %%Error: fifo_v3.sv:146: Assertion failed in %Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_b_fifo.full_write: [ASSERT FAILED] [%Naxi4_xbar_tb.dut.u_xbar.i_xbar_unmuxed.gen_slv_port_demux[3].i_axi_err_slv.i_b_fifo.full_write] full_write: Trying to push new data although the FIFO is full. (/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv:146)\n",0,
                             64,VL_TIME_UNITED_Q(1000),
                             -9,vlSymsp->name(),vlSymsp->name());
                VL_STOP_MT("/Users/jackberkowitz/Desktop/hw_rl_benchmark/refs/common_cells/src/fifo_v3.sv", 146, "");
            }
        }
    }
}

void Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__1(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+              Vaxi4_xbar_tb_axi_err_slv__pi5___nba_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*6:0*/ __VdfgRegularize_h247165ad_0_1;
    __VdfgRegularize_h247165ad_0_1 = 0;
    // Body
    if (vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) {
        vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_n;
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q 
            = vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_n;
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_351) {
            vlSelfRef.__PVT__i_r_fifo__DOT__mem_q = vlSelfRef.__PVT__i_r_fifo__DOT__mem_n;
        }
        if (vlSelfRef.__PVT__r_busy_load) {
            vlSelfRef.__PVT__r_busy_q = vlSelfRef.__PVT__r_busy_d;
        }
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q 
            = vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_d;
        if (((4U != (IData)(vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q)) 
             & (IData)(vlSelfRef.__PVT__w_fifo_push))) {
            vlSelfRef.__PVT__i_w_fifo__DOT__mem_q = vlSelfRef.__PVT__i_w_fifo__DOT__mem_n;
        }
        if (vlSelfRef.__VdfgRegularize_hebeb780c_0_352) {
            vlSelfRef.__PVT__i_b_fifo__DOT__mem_q = vlSelfRef.__PVT__i_b_fifo__DOT__mem_n;
        }
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_n;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q 
            = vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_n;
    } else {
        vlSelfRef.__PVT__i_r_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__write_pointer_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__read_pointer_q = 0U;
        vlSelfRef.__PVT__i_r_fifo__DOT__mem_q = 0ULL;
        vlSelfRef.__PVT__r_busy_q = 0U;
        vlSelfRef.__PVT__i_r_counter__DOT__i_counter__DOT__counter_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__i_b_fifo__DOT__mem_q = 0U;
        vlSelfRef.__PVT__i_b_fifo__DOT__status_cnt_q = 0U;
        vlSelfRef.__PVT__i_w_fifo__DOT__status_cnt_q = 0U;
    }
    vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__write_pointer_n));
    vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_q 
        = ((IData)(vlSymsp->TOP.axi4_xbar_tb__DOT__rst_n) 
           && (IData)(vlSelfRef.__PVT__i_b_fifo__DOT__read_pointer_n));
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
