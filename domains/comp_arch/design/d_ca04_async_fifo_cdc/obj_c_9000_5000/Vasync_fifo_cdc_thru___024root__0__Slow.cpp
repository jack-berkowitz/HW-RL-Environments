// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vasync_fifo_cdc_thru.h for the primary calling header

#include "Vasync_fifo_cdc_thru__pch.h"

void Vasync_fifo_cdc_thru___024root___timing_ready(Vasync_fifo_cdc_thru___024root* vlSelf);

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___eval_static(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_static\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_clk = 0U;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_clk = 0U;
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_beats = 0ULL;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_beats = 0ULL;
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles = 0ULL;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles = 0ULL;
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_clk__0 = 0U;
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_clk__0 = 0U;
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_rst_n__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n;
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_rst_n__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n;
    Vasync_fifo_cdc_thru___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___eval_static__TOP(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_static__TOP\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_clk = 0U;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_clk = 0U;
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_beats = 0ULL;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_beats = 0ULL;
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_cycles = 0ULL;
    vlSelfRef.async_fifo_cdc_thru__DOT__rd_cycles = 0ULL;
}

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___eval_final(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_final\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vasync_fifo_cdc_thru___024root___eval_phase__stl(Vasync_fifo_cdc_thru___024root* vlSelf);

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___eval_settle(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_settle\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vasync_fifo_cdc_thru___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("tb/async_fifo_cdc_thru.sv", 21, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 100 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = Vasync_fifo_cdc_thru___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___eval_triggers_vec__stl(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_triggers_vec__stl\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
}

VL_ATTR_COLD bool Vasync_fifo_cdc_thru___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vasync_fifo_cdc_thru___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vasync_fifo_cdc_thru___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___trigger_anySet__stl\n"); );
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

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___eval_stl(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_stl\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __Vinline__act_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire;
    __Vinline__act_comb__TOP__0_async_fifo_cdc_thru__DOT__dut__DOT__wr_fire = 0;
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
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

VL_ATTR_COLD bool Vasync_fifo_cdc_thru___024root___eval_phase__stl(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_phase__stl\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    Vasync_fifo_cdc_thru___024root___eval_triggers_vec__stl(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vasync_fifo_cdc_thru___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vasync_fifo_cdc_thru___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        Vasync_fifo_cdc_thru___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool Vasync_fifo_cdc_thru___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vasync_fifo_cdc_thru___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge async_fifo_cdc_thru.wr_clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(posedge async_fifo_cdc_thru.rd_clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @(negedge async_fifo_cdc_thru.rd_rst_n)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 3U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 3 is active: @(negedge async_fifo_cdc_thru.wr_rst_n)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 4U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 4 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___ctor_var_reset(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___ctor_var_reset\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->async_fifo_cdc_thru__DOT__wr_rst_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6593875788757945989ull);
    vlSelf->async_fifo_cdc_thru__DOT__rd_rst_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11829992827769131818ull);
    vlSelf->async_fifo_cdc_thru__DOT__wr_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8340212146140796519ull);
    vlSelf->async_fifo_cdc_thru__DOT__wr_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3938982178440377596ull);
    vlSelf->async_fifo_cdc_thru__DOT__rd_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3416021909023843234ull);
    vlSelf->async_fifo_cdc_thru__DOT__rd_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18131328364719261708ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__wr_bin = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7381013357837514793ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 11268668370820271387ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__wr_gray = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8138963947747649506ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3800685313355235907ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__wr_full = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13699721851720382889ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__rd_bin = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8107837408812767122ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 15415470597355813659ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__rd_gray = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 6266270325211771832ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 12467805772625063350ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__rd_empty = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9975531522405019462ull);
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync[__Vi0] = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 9618384014096967510ull);
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync[__Vi0] = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8028875121724792654ull);
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_rst_n__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_rst_n__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
