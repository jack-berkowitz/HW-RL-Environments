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
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_rst_n__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__wr_rst_n;
    vlSelfRef.__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_rst_n__0 
        = vlSelfRef.async_fifo_cdc_thru__DOT__rd_rst_n;
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

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___stl_sequent__TOP__0(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___stl_sequent__TOP__0\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*2:0*/ __VdfgRegularize_h4af1c392_0_0;
    __VdfgRegularize_h4af1c392_0_0 = 0;
    // Body
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain 
        = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q) 
           & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__wptr_bin 
        = ((((2U & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__wptr_q) 
                    >> 2U)) | (1U & VL_REDXOR_32((3U 
                                                  & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__wptr_q) 
                                                     >> 2U))))) 
            << 2U) | ((2U & (VL_REDXOR_32((7U & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__wptr_q) 
                                                 >> 1U))) 
                             << 1U)) | (1U & VL_REDXOR_4(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__wptr_q))));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__dst_ready 
        = (1U & ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                 | (~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__rptr 
        = ((((2U & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__3__KET____DOT__i_sync__DOT__reg_q)) 
             | (1U & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__2__KET____DOT__i_sync__DOT__reg_q) 
                      >> 1U))) << 2U) | ((2U & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__1__KET____DOT__i_sync__DOT__reg_q)) 
                                         | (1U & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__0__KET____DOT__i_sync__DOT__reg_q) 
                                                  >> 1U))));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__wptr 
        = ((((2U & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__3__KET____DOT__i_sync__DOT__reg_q)) 
             | (1U & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__2__KET____DOT__i_sync__DOT__reg_q) 
                      >> 1U))) << 2U) | ((2U & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__1__KET____DOT__i_sync__DOT__reg_q)) 
                                         | (1U & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__0__KET____DOT__i_sync__DOT__reg_q) 
                                                  >> 1U))));
    __VdfgRegularize_h4af1c392_0_0 = ((4U & (VL_REDXOR_32(
                                                          (3U 
                                                           & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__rptr_q) 
                                                              >> 2U))) 
                                             << 2U)) 
                                      | ((2U & (VL_REDXOR_32(
                                                             (7U 
                                                              & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__rptr_q) 
                                                                 >> 1U))) 
                                                << 1U)) 
                                         | (1U & VL_REDXOR_4(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__rptr_q))));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill 
        = ((~ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__rd_ready)) 
           & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain));
    vlSelfRef.async_fifo_cdc_thru__DOT__wr_ready = 
        (8U != (((((2U & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__3__KET____DOT__i_sync__DOT__reg_q)) 
                   | (1U & VL_REDXOR_32((3U & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__rptr) 
                                               >> 2U))))) 
                  << 2U) | ((2U & (VL_REDXOR_32((7U 
                                                 & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__rptr) 
                                                    >> 1U))) 
                                   << 1U)) | (1U & 
                                              VL_REDXOR_4(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__rptr)))) 
                ^ (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__wptr_bin)));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__rptr_bin 
        = ((8U & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__rptr_q)) 
           | (IData)(__VdfgRegularize_h4af1c392_0_0));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__dst_valid 
        = (0U != ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__rptr_bin) 
                  ^ ((((2U & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__3__KET____DOT__i_sync__DOT__reg_q)) 
                       | (1U & VL_REDXOR_32((3U & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__wptr) 
                                                   >> 2U))))) 
                      << 2U) | ((2U & (VL_REDXOR_32(
                                                    (7U 
                                                     & ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__wptr) 
                                                        >> 1U))) 
                                       << 1U)) | (1U 
                                                  & VL_REDXOR_4(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__wptr))))));
    vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill 
        = ((IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__dst_valid) 
           & (IData)(vlSelfRef.async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__dst_ready));
}

VL_ATTR_COLD void Vasync_fifo_cdc_thru___024root___eval_stl(Vasync_fifo_cdc_thru___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vasync_fifo_cdc_thru___024root___eval_stl\n"); );
    Vasync_fifo_cdc_thru__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
        Vasync_fifo_cdc_thru___024root___stl_sequent__TOP__0(vlSelf);
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
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @(negedge async_fifo_cdc_thru.wr_rst_n)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 3U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 3 is active: @(negedge async_fifo_cdc_thru.rd_rst_n)\n");
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
    vlSelf->async_fifo_cdc_thru__DOT__rd_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18131328364719261708ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__wptr_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3072659117414221251ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__wptr_bin = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 10773577863261108011ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__rptr = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7958033242277174252ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__0__KET____DOT__i_sync__DOT__reg_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 462275137772090190ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__1__KET____DOT__i_sync__DOT__reg_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 5970747973013600500ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__2__KET____DOT__i_sync__DOT__reg_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 10375752698348378065ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_src__DOT__gen_sync__BRA__3__KET____DOT__i_sync__DOT__reg_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 4592087684762308266ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__rptr_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 5494029266945498716ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__rptr_bin = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 4065728554503739403ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__wptr = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 6864276571491978743ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__dst_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18316013666760837675ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__dst_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5448535684016430709ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 647554227477532008ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14084628048163637036ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14586841216019163065ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12776546536785718666ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8573372089508777852ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__i_spill_register__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10221317477552057453ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__0__KET____DOT__i_sync__DOT__reg_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 14120202236479717108ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__1__KET____DOT__i_sync__DOT__reg_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 11645957854936567277ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__2__KET____DOT__i_sync__DOT__reg_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 5264591581572790881ull);
    vlSelf->async_fifo_cdc_thru__DOT__dut__DOT__u_cdc__DOT__i_dst__DOT__gen_sync__BRA__3__KET____DOT__i_sync__DOT__reg_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 1323242395939379264ull);
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
    vlSelf->__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_rst_n__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_rst_n__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
