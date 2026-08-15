// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vasync_fifo_cdc_thru.h for the primary calling header

#include "Vasync_fifo_cdc_thru__pch.h"

VlCoroutine Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__0(Vasync_fifo_cdc_thru___024root* vlSelf);
VlCoroutine Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__1(Vasync_fifo_cdc_thru___024root* vlSelf);
VlCoroutine Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__2(Vasync_fifo_cdc_thru___024root* vlSelf);
VlCoroutine Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__3(Vasync_fifo_cdc_thru___024root* vlSelf);

void Vasync_fifo_cdc_thru___024root___eval_initial(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_initial\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__1(vlSelf);
    Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__2(vlSelf);
    Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__3(vlSelf);
}

void Vasync_fifo_cdc_thru___024root____VbeforeTrig_h712dd71e__0(Vasync_fifo_cdc_thru___024root* vlSelf, const char* __VeventDescription);
void Vasync_fifo_cdc_thru___024root____VbeforeTrig_h0d3e050b__0(Vasync_fifo_cdc_thru___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__0(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ async_fifo_cdc_thru__DOT__unnamedblk1_1__DOT____Vrepeat0;
    async_fifo_cdc_thru__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    IData/*31:0*/ async_fifo_cdc_thru__DOT__unnamedblk1_2__DOT____Vrepeat1;
    async_fifo_cdc_thru__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0;
    // Body
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_valid = 1U;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready = 1U;
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n = 0U;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n = 0U;
    async_fifo_cdc_thru__DOT__unnamedblk1_1__DOT____Vrepeat0 = 8U;
    while (VL_LTS_III(32, 0U, async_fifo_cdc_thru__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vasync_fifo_cdc_thru___024root____VbeforeTrig_h712dd71e__0(vlSelf, 
                                                                   "@(posedge async_fifo_cdc_thru.wr_clk)");
        co_await vlSelfRef.__VtrigSched_h712dd71e__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge async_fifo_cdc_thru.wr_clk)", 
                                                             "tb/async_fifo_cdc_thru.sv", 
                                                             61);
        async_fifo_cdc_thru__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (async_fifo_cdc_thru__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
    }
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n = 1U;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n = 1U;
    async_fifo_cdc_thru__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0x00004e20U;
    while (VL_LTS_III(32, 0U, async_fifo_cdc_thru__DOT__unnamedblk1_2__DOT____Vrepeat1)) {
        Vasync_fifo_cdc_thru___024root____VbeforeTrig_h0d3e050b__0(vlSelf, 
                                                                   "@(posedge async_fifo_cdc_thru.rd_clk)");
        co_await vlSelfRef.__VtrigSched_h0d3e050b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge async_fifo_cdc_thru.rd_clk)", 
                                                             "tb/async_fifo_cdc_thru.sv", 
                                                             63);
        async_fifo_cdc_thru__DOT__unnamedblk1_2__DOT____Vrepeat1 
            = (async_fifo_cdc_thru__DOT__unnamedblk1_2__DOT____Vrepeat1 
               - (IData)(1U));
    }
    VL_WRITEF_NX("METRIC: thru wr_beats=%0d/%0d rd_beats=%0d/%0d wr_pct=%0d rd_pct=%0d\n",0,
                 64,vlSelfRef.async_fifo_cdc_thru__DOT__wr_beats,
                 64,vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles,
                 64,vlSelfRef.async_fifo_cdc_thru__DOT__rd_beats,
                 64,vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles,
                 64,((0ULL == vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles)
                      ? 0ULL : VL_DIVS_QQQ(64, VL_MULS_QQQ(64, 0x0000000000000064ULL, vlSelfRef.async_fifo_cdc_thru__DOT__wr_beats), vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles)),
                 64,((0ULL == vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles)
                      ? 0ULL : VL_DIVS_QQQ(64, VL_MULS_QQQ(64, 0x0000000000000064ULL, vlSelfRef.async_fifo_cdc_thru__DOT__rd_beats), vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles)));
    VL_FINISH_MT("tb/async_fifo_cdc_thru.sv", 68, "");
    co_return;
}

VlCoroutine Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__1(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    co_await vlSelfRef.__VdlySched.delay(0x000000001dcd6500ULL, 
                                         nullptr, "tb/async_fifo_cdc_thru.sv", 
                                         72);
    VL_WRITEF_NX("METRIC: thru TIMEOUT\n",0);
    VL_FINISH_MT("tb/async_fifo_cdc_thru.sv", 74, "");
    co_return;
}

VlCoroutine Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__2(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__2\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000001388ULL, 
                                             nullptr, 
                                             "tb/async_fifo_cdc_thru.sv", 
                                             32);
        vlSelfRef.async_fifo_cdc_thru__DOT__rd_clk 
            = (1U & (~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_clk)));
    }
    co_return;
}

VlCoroutine Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__3(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_initial__TOP__Vtiming__3\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000002328ULL, 
                                             nullptr, 
                                             "tb/async_fifo_cdc_thru.sv", 
                                             31);
        vlSelfRef.async_fifo_cdc_thru__DOT__wr_clk 
            = (1U & (~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_clk)));
    }
    co_return;
}

void Vasync_fifo_cdc_thru___024root___eval_triggers_vec__act(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_triggers_vec__act\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                      << 4U) 
                                                     | (((((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n)) 
                                                           & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_rst_n__0)) 
                                                          << 3U) 
                                                         | (((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n)) 
                                                             & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_rst_n__0)) 
                                                            << 2U)) 
                                                        | ((((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_clk) 
                                                             & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_clk__0))) 
                                                            << 1U) 
                                                           | ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_clk) 
                                                              & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_clk__0))))))));
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_clk__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__wr_clk;
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_clk__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__rd_clk;
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_rst_n__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n;
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_rst_n__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n;
}

bool Vasync_fifo_cdc_thru___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___trigger_anySet__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vasync_fifo_cdc_thru___024root___act_comb__TOP__0(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___act_comb__TOP__0\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ async_fifo_cdc_thru__DOT__dut__DOT__wr_fire;
    async_fifo_cdc_thru__DOT__dut__DOT__wr_fire = 0;
    // Body
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid = 
        ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_empty)) 
         & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n));
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready = 
        ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_full)) 
         & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next 
        = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin;
    if (((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid) 
         & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready))) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next 
            = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin)));
    }
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next 
        = (VL_SHIFTR_III(4,4,32, (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next), 1U) 
           ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next));
    async_fifo_cdc_thru__DOT__dut__DOT__wr_fire = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_valid) 
                                                   & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next 
        = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin;
    if (async_fifo_cdc_thru__DOT__dut__DOT__wr_fire) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next 
            = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin)));
    }
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next 
        = (VL_SHIFTR_III(4,4,32, (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next), 1U) 
           ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next));
}

void Vasync_fifo_cdc_thru___024root___eval_act(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_act\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __Vinline__act_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire;
    __Vinline__act_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire = 0;
    // Body
    if ((3ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid 
            = ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_empty)) 
               & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n));
        vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready 
            = ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_full)) 
               & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n));
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin;
        if (((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid) 
             & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready))) {
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next 
                = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin)));
        }
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next 
            = (VL_SHIFTR_III(4,4,32, (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next), 1U) 
               ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next));
        __Vinline__act_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire 
            = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_valid) 
               & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready));
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin;
        if (__Vinline__act_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire) {
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next 
                = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin)));
        }
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next 
            = (VL_SHIFTR_III(4,4,32, (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next), 1U) 
               ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next));
    }
}

void Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__0(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__0\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*3:0*/ __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0;
    __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 = 0;
    CData/*0:0*/ __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0;
    __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 = 0;
    CData/*3:0*/ __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v1;
    __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v1 = 0;
    CData/*0:0*/ __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2;
    __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2 = 0;
    // Body
    __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 = 0U;
    __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2 = 0U;
    if (vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n) {
        __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray;
        __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 = 1U;
        __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v1 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[0U];
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next;
    } else {
        __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2 = 1U;
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin = 0U;
    }
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_empty 
        = ((1U & (~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n))) 
           || ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next) 
               == vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[1U]));
    if (__VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[0U] 
            = __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0;
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[1U] 
            = __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v1;
    }
    if (__VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[0U] = 0U;
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[1U] = 0U;
    }
}

void Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__1(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__1\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*3:0*/ __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0;
    __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 = 0;
    CData/*0:0*/ __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0;
    __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 = 0;
    CData/*3:0*/ __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v1;
    __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v1 = 0;
    CData/*0:0*/ __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2;
    __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2 = 0;
    // Body
    __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 = 0U;
    __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2 = 0U;
    if (vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n) {
        __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray;
        __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 = 1U;
        __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v1 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[0U];
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next;
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next;
    } else {
        __VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2 = 1U;
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin = 0U;
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray = 0U;
    }
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_full 
        = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n) 
           && ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next) 
               == ((0x0000000cU & ((~ (vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[1U] 
                                       >> 2U)) << 2U)) 
                   | (3U & vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[1U]))));
    if (__VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[0U] 
            = __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0;
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[1U] 
            = __VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v1;
    }
    if (__VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[0U] = 0U;
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[1U] = 0U;
    }
}

void Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__2(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__2\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n) {
        vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles 
            = (1ULL + vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles);
        if (((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_valid) 
             & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready))) {
            vlSelfRef.async_fifo_cdc_thru__DOT__wr_beats 
                = (1ULL + vlSelfRef.async_fifo_cdc_thru__DOT__wr_beats);
        }
    }
}

void Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__3(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__3\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n) {
        vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles 
            = (1ULL + vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles);
        if (((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid) 
             & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready))) {
            vlSelfRef.async_fifo_cdc_thru__DOT__rd_beats 
                = (1ULL + vlSelfRef.async_fifo_cdc_thru__DOT__rd_beats);
        }
    }
}

void Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__4(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___nba_sequent__TOP__4\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray 
        = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n)
            ? (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next)
            : 0U);
}

void Vasync_fifo_cdc_thru___024root___nba_comb__TOP__0(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___nba_comb__TOP__0\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ async_fifo_cdc_thru__DOT__dut__DOT__wr_fire;
    async_fifo_cdc_thru__DOT__dut__DOT__wr_fire = 0;
    // Body
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready = 
        ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_full)) 
         & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n));
    async_fifo_cdc_thru__DOT__dut__DOT__wr_fire = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_valid) 
                                                   & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next 
        = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin;
    if (async_fifo_cdc_thru__DOT__dut__DOT__wr_fire) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next 
            = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin)));
    }
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next 
        = (VL_SHIFTR_III(4,4,32, (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next), 1U) 
           ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next));
}

void Vasync_fifo_cdc_thru___024root___nba_comb__TOP__1(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___nba_comb__TOP__1\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid = 
        ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_empty)) 
         & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next 
        = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin;
    if (((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid) 
         & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready))) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next 
            = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin)));
    }
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next 
        = (VL_SHIFTR_III(4,4,32, (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next), 1U) 
           ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next));
}

void Vasync_fifo_cdc_thru___024root___eval_nba(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_nba\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*3:0*/ __Vinline__nba_sequent__TOP__0___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0;
    __Vinline__nba_sequent__TOP__0___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 = 0;
    CData/*0:0*/ __Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0;
    __Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 = 0;
    CData/*3:0*/ __Vinline__nba_sequent__TOP__0___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v1;
    __Vinline__nba_sequent__TOP__0___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v1 = 0;
    CData/*0:0*/ __Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2;
    __Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2 = 0;
    CData/*3:0*/ __Vinline__nba_sequent__TOP__1___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0;
    __Vinline__nba_sequent__TOP__1___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 = 0;
    CData/*0:0*/ __Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0;
    __Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 = 0;
    CData/*3:0*/ __Vinline__nba_sequent__TOP__1___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v1;
    __Vinline__nba_sequent__TOP__1___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v1 = 0;
    CData/*0:0*/ __Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2;
    __Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2 = 0;
    CData/*0:0*/ __Vinline__nba_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire;
    __Vinline__nba_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire = 0;
    // Body
    if ((6ULL & vlSelfRef.__VnbaTriggered[0U])) {
        __Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 = 0U;
        __Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2 = 0U;
        if (vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n) {
            __Vinline__nba_sequent__TOP__0___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 
                = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray;
            __Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0 = 1U;
            __Vinline__nba_sequent__TOP__0___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v1 
                = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[0U];
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin 
                = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next;
        } else {
            __Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2 = 1U;
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin = 0U;
        }
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_empty 
            = ((1U & (~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n))) 
               || ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next) 
                   == vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[1U]));
        if (__Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0) {
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[0U] 
                = __Vinline__nba_sequent__TOP__0___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v0;
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[1U] 
                = __Vinline__nba_sequent__TOP__0___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v1;
        }
        if (__Vinline__nba_sequent__TOP__0___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync__v2) {
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[0U] = 0U;
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[1U] = 0U;
        }
    }
    if ((9ULL & vlSelfRef.__VnbaTriggered[0U])) {
        __Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 = 0U;
        __Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2 = 0U;
        if (vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n) {
            __Vinline__nba_sequent__TOP__1___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 
                = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray;
            __Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0 = 1U;
            __Vinline__nba_sequent__TOP__1___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v1 
                = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[0U];
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin 
                = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next;
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray 
                = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next;
        } else {
            __Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2 = 1U;
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin = 0U;
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray = 0U;
        }
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_full 
            = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n) 
               && ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next) 
                   == ((0x0000000cU & ((~ (vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[1U] 
                                           >> 2U)) 
                                       << 2U)) | (3U 
                                                  & vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[1U]))));
        if (__Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0) {
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[0U] 
                = __Vinline__nba_sequent__TOP__1___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v0;
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[1U] 
                = __Vinline__nba_sequent__TOP__1___VdlyVal__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v1;
        }
        if (__Vinline__nba_sequent__TOP__1___VdlySet__async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync__v2) {
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[0U] = 0U;
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[1U] = 0U;
        }
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        if (vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n) {
            vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles 
                = (1ULL + vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles);
            if (((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_valid) 
                 & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready))) {
                vlSelfRef.async_fifo_cdc_thru__DOT__wr_beats 
                    = (1ULL + vlSelfRef.async_fifo_cdc_thru__DOT__wr_beats);
            }
        }
    }
    if ((2ULL & vlSelfRef.__VnbaTriggered[0U])) {
        if (vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n) {
            vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles 
                = (1ULL + vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles);
            if (((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid) 
                 & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready))) {
                vlSelfRef.async_fifo_cdc_thru__DOT__rd_beats 
                    = (1ULL + vlSelfRef.async_fifo_cdc_thru__DOT__rd_beats);
            }
        }
    }
    if ((6ULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray 
            = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n)
                ? (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next)
                : 0U);
    }
    if ((0x000000000000000bULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready 
            = ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_full)) 
               & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n));
        __Vinline__nba_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire 
            = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_valid) 
               & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready));
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin;
        if (__Vinline__nba_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire) {
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next 
                = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin)));
        }
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next 
            = (VL_SHIFTR_III(4,4,32, (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next), 1U) 
               ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next));
    }
    if ((7ULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid 
            = ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_empty)) 
               & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n));
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next 
            = vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin;
        if (((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_valid) 
             & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready))) {
            vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next 
                = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin)));
        }
        vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next 
            = (VL_SHIFTR_III(4,4,32, (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next), 1U) 
               ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next));
    }
}

void Vasync_fifo_cdc_thru___024root___timing_ready(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___timing_ready\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h712dd71e__0.ready("@(posedge async_fifo_cdc_thru.wr_clk)");
    }
    if ((2ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h0d3e050b__0.ready("@(posedge async_fifo_cdc_thru.rd_clk)");
    }
}

void Vasync_fifo_cdc_thru___024root___timing_resume(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___timing_resume\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_h712dd71e__0.moveToResumeQueue(
                                                          "@(posedge async_fifo_cdc_thru.wr_clk)");
    vlSelfRef.__VtrigSched_h0d3e050b__0.moveToResumeQueue(
                                                          "@(posedge async_fifo_cdc_thru.rd_clk)");
    vlSelfRef.__VtrigSched_h712dd71e__0.resume("@(posedge async_fifo_cdc_thru.wr_clk)");
    vlSelfRef.__VtrigSched_h0d3e050b__0.resume("@(posedge async_fifo_cdc_thru.rd_clk)");
    if ((0x0000000000000010ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vasync_fifo_cdc_thru___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vasync_fifo_cdc_thru___024root___eval_phase__act(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_phase__act\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    Vasync_fifo_cdc_thru___024root___eval_triggers_vec__act(vlSelf);
    Vasync_fifo_cdc_thru___024root___timing_ready(vlSelf);
    Vasync_fifo_cdc_thru___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vasync_fifo_cdc_thru___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vasync_fifo_cdc_thru___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vasync_fifo_cdc_thru___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vasync_fifo_cdc_thru___024root___timing_resume(vlSelf);
        Vasync_fifo_cdc_thru___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vasync_fifo_cdc_thru___024root___eval_phase__inact(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_phase__inact\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("tb/async_fifo_cdc_thru.sv", 21, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vasync_fifo_cdc_thru___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vasync_fifo_cdc_thru___024root___eval_phase__nba(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_phase__nba\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vasync_fifo_cdc_thru___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vasync_fifo_cdc_thru___024root___eval_nba(vlSelf);
        Vasync_fifo_cdc_thru___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vasync_fifo_cdc_thru___024root___eval(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vasync_fifo_cdc_thru___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("tb/async_fifo_cdc_thru.sv", 21, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 100 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VinactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VinactIterCount)))) {
                VL_FATAL_MT("tb/async_fifo_cdc_thru.sv", 21, "", "DIDNOTCONVERGE: Inactive region did not converge after '--converge-limit' of 100 tries");
            }
            vlSelfRef.__VinactIterCount = ((IData)(1U) 
                                           + vlSelfRef.__VinactIterCount);
            vlSelfRef.__VactIterCount = 0U;
            do {
                if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                    Vasync_fifo_cdc_thru___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                    VL_FATAL_MT("tb/async_fifo_cdc_thru.sv", 21, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 100 tries");
                }
                vlSelfRef.__VactIterCount = ((IData)(1U) 
                                             + vlSelfRef.__VactIterCount);
                vlSelfRef.__VactPhaseResult = Vasync_fifo_cdc_thru___024root___eval_phase__act(vlSelf);
            } while (vlSelfRef.__VactPhaseResult);
            vlSelfRef.__VinactPhaseResult = Vasync_fifo_cdc_thru___024root___eval_phase__inact(vlSelf);
        } while (vlSelfRef.__VinactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = Vasync_fifo_cdc_thru___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

void Vasync_fifo_cdc_thru___024root____VbeforeTrig_h712dd71e__0(Vasync_fifo_cdc_thru___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root____VbeforeTrig_h712dd71e__0\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__wr_clk) 
                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_clk__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__wr_clk;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h712dd71e__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

void Vasync_fifo_cdc_thru___024root____VbeforeTrig_h0d3e050b__0(Vasync_fifo_cdc_thru___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root____VbeforeTrig_h0d3e050b__0\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)((((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_clk) 
                                   & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_clk__0))) 
                                  << 1U)));
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_clk__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__rd_clk;
    if ((2ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h0d3e050b__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vasync_fifo_cdc_thru___024root___eval_debug_assertions(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_debug_assertions\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
