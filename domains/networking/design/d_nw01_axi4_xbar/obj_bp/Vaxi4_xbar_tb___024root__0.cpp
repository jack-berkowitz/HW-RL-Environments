// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

VlCoroutine Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__0(Vaxi4_xbar_tb___024root* vlSelf);
VlCoroutine Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__1(Vaxi4_xbar_tb___024root* vlSelf);
VlCoroutine Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__2(Vaxi4_xbar_tb___024root* vlSelf);

void Vaxi4_xbar_tb___024root___eval_initial(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_initial\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.axi4_xbar_tb__DOT__lm_wait[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__lm_wait[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__lm_wait[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__lm_wait[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U] = 0x00010000U;
    vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] = 0x00100000U;
    vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] = 0x00080000U;
    vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] = 8U;
    Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__1(vlSelf);
    Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__2(vlSelf);
}

void Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(Vaxi4_xbar_tb___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__0(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ axi4_xbar_tb__DOT__guard;
    axi4_xbar_tb__DOT__guard = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__c2_one;
    axi4_xbar_tb__DOT__c2_one = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__c2_two;
    axi4_xbar_tb__DOT__c2_two = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__agg_bursts;
    axi4_xbar_tb__DOT__agg_bursts = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_1__DOT____Vrepeat0;
    axi4_xbar_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_2__DOT____Vrepeat1;
    axi4_xbar_tb__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_3__DOT____Vrepeat2;
    axi4_xbar_tb__DOT__unnamedblk1_3__DOT____Vrepeat2 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_4__DOT____Vrepeat3;
    axi4_xbar_tb__DOT__unnamedblk1_4__DOT____Vrepeat3 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_5__DOT____Vrepeat4;
    axi4_xbar_tb__DOT__unnamedblk1_5__DOT____Vrepeat4 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_6__DOT____Vrepeat5;
    axi4_xbar_tb__DOT__unnamedblk1_6__DOT____Vrepeat5 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_7__DOT____Vrepeat6;
    axi4_xbar_tb__DOT__unnamedblk1_7__DOT____Vrepeat6 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_8__DOT____Vrepeat7;
    axi4_xbar_tb__DOT__unnamedblk1_8__DOT____Vrepeat7 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_9__DOT____Vrepeat8;
    axi4_xbar_tb__DOT__unnamedblk1_9__DOT____Vrepeat8 = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk1_10__DOT____Vrepeat9;
    axi4_xbar_tb__DOT__unnamedblk1_10__DOT____Vrepeat9 = 0;
    // Body
    vlSelfRef.axi4_xbar_tb__DOT__phase = "reset"s;
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 0U;
    axi4_xbar_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0x0000000aU;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             508);
        axi4_xbar_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (axi4_xbar_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
    }
    if ((IData)((0U != (0x00010100U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U])))) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__24__why = "response valid asserted while rst_n low (R1)"s;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__24__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__24__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__phase = "capacity"s;
    vlSelfRef.axi4_xbar_tb__DOT__tmode = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_drain = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[1U] = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[3U] = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = 0x0fU;
    axi4_xbar_tb__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0x00000180U;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_2__DOT____Vrepeat1)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             527);
        axi4_xbar_tb__DOT__unnamedblk1_2__DOT____Vrepeat1 
            = (axi4_xbar_tb__DOT__unnamedblk1_2__DOT____Vrepeat1 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = 0U;
    VL_WRITEF_NX("METRIC: outstanding_master0=%0d\n",0,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[0U]);
    if (VL_GTS_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[0U])) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why 
            = VL_SFORMATF_N_NX("master 0 accepted only %0d outstanding reads with no response drained; floor is 4 for MAX_TRANS=8 (C1)",0,
                               32,vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[0U]) ;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    VL_WRITEF_NX("METRIC: outstanding_master1=%0d\n",0,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[1U]);
    if (VL_GTS_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[1U])) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why 
            = VL_SFORMATF_N_NX("master 1 accepted only %0d outstanding reads with no response drained; floor is 4 for MAX_TRANS=8 (C1)",0,
                               32,vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[1U]) ;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    VL_WRITEF_NX("METRIC: outstanding_master2=%0d\n",0,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[2U]);
    if (VL_GTS_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[2U])) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why 
            = VL_SFORMATF_N_NX("master 2 accepted only %0d outstanding reads with no response drained; floor is 4 for MAX_TRANS=8 (C1)",0,
                               32,vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[2U]) ;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    VL_WRITEF_NX("METRIC: outstanding_master3=%0d\n",0,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[3U]);
    if (VL_GTS_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[3U])) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why 
            = VL_SFORMATF_N_NX("master 3 accepted only %0d outstanding reads with no response drained; floor is 4 for MAX_TRANS=8 (C1)",0,
                               32,vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[3U]) ;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__25__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__phase = "concurrency-1"s;
    vlSelfRef.axi4_xbar_tb__DOT__tmode = 2U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_drain = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 0U;
    axi4_xbar_tb__DOT__unnamedblk1_3__DOT____Vrepeat2 = 6U;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_3__DOT____Vrepeat2)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             565);
        axi4_xbar_tb__DOT__unnamedblk1_3__DOT____Vrepeat2 
            = (axi4_xbar_tb__DOT__unnamedblk1_3__DOT____Vrepeat2 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en));
    axi4_xbar_tb__DOT__unnamedblk1_4__DOT____Vrepeat3 = 0x00000bb8U;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_4__DOT____Vrepeat3)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             567);
        axi4_xbar_tb__DOT__unnamedblk1_4__DOT____Vrepeat3 
            = (axi4_xbar_tb__DOT__unnamedblk1_4__DOT____Vrepeat3 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = 0U;
    axi4_xbar_tb__DOT__c2_one = vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[0U];
    vlSelfRef.axi4_xbar_tb__DOT__phase = "concurrency-2"s;
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 0U;
    axi4_xbar_tb__DOT__unnamedblk1_5__DOT____Vrepeat4 = 6U;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_5__DOT____Vrepeat4)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             571);
        axi4_xbar_tb__DOT__unnamedblk1_5__DOT____Vrepeat4 
            = (axi4_xbar_tb__DOT__unnamedblk1_5__DOT____Vrepeat4 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[1U] = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = (3U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en));
    axi4_xbar_tb__DOT__unnamedblk1_6__DOT____Vrepeat5 = 0x00000bb8U;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_6__DOT____Vrepeat5)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             574);
        axi4_xbar_tb__DOT__unnamedblk1_6__DOT____Vrepeat5 
            = (axi4_xbar_tb__DOT__unnamedblk1_6__DOT____Vrepeat5 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = 0U;
    axi4_xbar_tb__DOT__c2_two = (vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[0U] 
                                 + vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[1U]);
    VL_WRITEF_NX("METRIC: disjoint_one_pair=%0d disjoint_two_pairs=%0d speedup_pct=%0d\n",0,
                 32,axi4_xbar_tb__DOT__c2_one,32,axi4_xbar_tb__DOT__c2_two,
                 32,((0U == axi4_xbar_tb__DOT__c2_one)
                      ? 0U : VL_DIVS_III(32, VL_MULS_III(32, (IData)(0x00000064U), axi4_xbar_tb__DOT__c2_two), axi4_xbar_tb__DOT__c2_one)));
    if ((0U == axi4_xbar_tb__DOT__c2_one)) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__26__why = "no progress on a single master/slave pair (C2)"s;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__26__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__26__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    } else if (VL_LTS_III(32, VL_MULS_III(32, (IData)(0x0000000aU), axi4_xbar_tb__DOT__c2_two), 
                          VL_MULS_III(32, (IData)(0x0000000fU), axi4_xbar_tb__DOT__c2_one))) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__27__why 
            = VL_SFORMATF_N_NX("disjoint pairs do not run in parallel: two pairs retired %0d vs %0d for one pair (%0d%%, need >=150%%) -- traffic is serialising through a shared resource (C2)",0,
                               32,axi4_xbar_tb__DOT__c2_two,
                               32,axi4_xbar_tb__DOT__c2_one,
                               32,VL_DIVS_III(32, VL_MULS_III(32, (IData)(0x00000064U), axi4_xbar_tb__DOT__c2_two), axi4_xbar_tb__DOT__c2_one)) ;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__27__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__27__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__phase = "throughput"s;
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 0U;
    axi4_xbar_tb__DOT__unnamedblk1_7__DOT____Vrepeat6 = 6U;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_7__DOT____Vrepeat6)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             590);
        axi4_xbar_tb__DOT__unnamedblk1_7__DOT____Vrepeat6 
            = (axi4_xbar_tb__DOT__unnamedblk1_7__DOT____Vrepeat6 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[1U] = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[3U] = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = 0x0fU;
    axi4_xbar_tb__DOT__unnamedblk1_8__DOT____Vrepeat7 = 0x00000bb8U;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_8__DOT____Vrepeat7)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             593);
        axi4_xbar_tb__DOT__unnamedblk1_8__DOT____Vrepeat7 
            = (axi4_xbar_tb__DOT__unnamedblk1_8__DOT____Vrepeat7 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__cap_en = 0U;
    axi4_xbar_tb__DOT__agg_bursts = 0U;
    axi4_xbar_tb__DOT__agg_bursts = vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[0U];
    axi4_xbar_tb__DOT__agg_bursts = (axi4_xbar_tb__DOT__agg_bursts 
                                     + vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[1U]);
    axi4_xbar_tb__DOT__agg_bursts = (axi4_xbar_tb__DOT__agg_bursts 
                                     + vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[2U]);
    axi4_xbar_tb__DOT__agg_bursts = (axi4_xbar_tb__DOT__agg_bursts 
                                     + vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[3U]);
    VL_WRITEF_NX("METRIC: aggregate_bursts_per_1000cyc=%0d\n",0,
                 32,VL_DIVS_III(32, VL_MULS_III(32, (IData)(0x000003e8U), axi4_xbar_tb__DOT__agg_bursts), (IData)(0x00000bb8U)));
    vlSelfRef.axi4_xbar_tb__DOT__tmode = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__cap_drain = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 0U;
    axi4_xbar_tb__DOT__unnamedblk1_9__DOT____Vrepeat8 = 0x0000000aU;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_9__DOT____Vrepeat8)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             601);
        axi4_xbar_tb__DOT__unnamedblk1_9__DOT____Vrepeat8 
            = (axi4_xbar_tb__DOT__unnamedblk1_9__DOT____Vrepeat8 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__phase = "all-to-all"s;
    axi4_xbar_tb__DOT__guard = 0U;
    {
        while (VL_GTS_III(32, 0x000927c0U, axi4_xbar_tb__DOT__guard)) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__done = 1U;
            if (((VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[0U]) 
                  | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U])) 
                 | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__done = 0U;
            }
            if (((VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[1U]) 
                  | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U])) 
                 | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__done = 0U;
            }
            if (((VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[2U]) 
                  | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U])) 
                 | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__done = 0U;
            }
            if (((VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[3U]) 
                  | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U])) 
                 | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__done = 0U;
            }
            if (vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__done) {
                goto __Vlabel0;
            }
            Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                                "@(posedge axi4_xbar_tb.clk)");
            co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                                 nullptr, 
                                                                 "@(posedge axi4_xbar_tb.clk)", 
                                                                 "tb/axi4_xbar_tb.sv", 
                                                                 611);
            axi4_xbar_tb__DOT__guard = ((IData)(1U) 
                                        + axi4_xbar_tb__DOT__guard);
        }
        __Vlabel0: ;
    }
    axi4_xbar_tb__DOT__unnamedblk1_10__DOT____Vrepeat9 = 0x000000c8U;
    while (VL_LTS_III(32, 0U, axi4_xbar_tb__DOT__unnamedblk1_10__DOT____Vrepeat9)) {
        Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                            "@(posedge axi4_xbar_tb.clk)");
        co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi4_xbar_tb.clk)", 
                                                             "tb/axi4_xbar_tb.sv", 
                                                             613);
        axi4_xbar_tb__DOT__unnamedblk1_10__DOT____Vrepeat9 
            = (axi4_xbar_tb__DOT__unnamedblk1_10__DOT____Vrepeat9 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__phase = "final"s;
    VL_WRITEF_NX("METRIC: checks=%0d\nMETRIC: liveness worst_wait=%0d (requester %0d) global_idle_max_seen=%0d\n// coverage: served_per_requester = %0d %0d %0d %0d\n",0,
                 32,vlSelfRef.axi4_xbar_tb__DOT__checks,
                 32,vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait,
                 32,vlSelfRef.axi4_xbar_tb__DOT__lm_worst_req,
                 32,vlSelfRef.axi4_xbar_tb__DOT__lm_global_idle,
                 32,vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[0U],
                 32,vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[1U],
                 32,vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[2U],
                 32,vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[3U]);
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_stall_fired) 
         | (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired))) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__28__why 
            = vlSelfRef.axi4_xbar_tb__DOT__lm_reason;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__28__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__28__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    if ((0U == vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[0U])) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why = "requester 0 was never served at all"s;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    if ((0U == vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[1U])) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why = "requester 1 was never served at all"s;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    if ((0U == vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[2U])) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why = "requester 2 was never served at all"s;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    if ((0U == vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[3U])) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why = "requester 3 was never served at all"s;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__29__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss = 0U;
    VL_WRITEF_NX("// coverage: rd_ok=%0d rd_decerr=%0d wr_ok=%0d wr_decerr=%0d\n// coverage: multi_beat_bursts=%0d cross_id_switches=%0d\n",0,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id);
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no successful read\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no successful write\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no unmapped read (DECERR path untested)\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no unmapped write\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no multi-beat burst\n",0);
    }
    VL_WRITEF_NX("// coverage: max_burst_seen=%0d (MAX_BURST_LEN=3) bp_r_stalls=%0d bp_b_stalls=%0d\n",0,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_max_len,
                 32,vlSelfRef.axi4_xbar_tb__DOT__bp_r_stalls,
                 32,vlSelfRef.axi4_xbar_tb__DOT__bp_b_stalls);
    if (VL_UNLIKELY((VL_GTS_III(32, 3U, vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: never drove a burst of the full MAX_BURST_LEN=3 (longest was %0d)\n",0,
                     32,vlSelfRef.axi4_xbar_tb__DOT__cov_max_len);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__bp_r_stalls)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: R backpressure never stalled a response (L3 untested)\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__bp_b_stalls)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: B backpressure never stalled a response (L3 untested)\n",0);
    }
    if (VL_UNLIKELY((VL_GTS_III(32, 0x00000064U, vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: too little cross-ID interleaving (%0d switches)\n",0,
                     32,vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id);
    }
    if (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss)) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__30__why 
            = VL_SFORMATF_N_NX("%0d coverage holes",0,
                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk24__DOT__miss) ;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__30__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__30__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    if (VL_GTS_III(32, 0x000007d0U, vlSelfRef.axi4_xbar_tb__DOT__checks)) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__31__why 
            = VL_SFORMATF_N_NX("insufficient coverage: only %0d checks",0,
                               32,vlSelfRef.axi4_xbar_tb__DOT__checks) ;
        vlSelfRef.axi4_xbar_tb__DOT__errors = ((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__errors);
        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__31__why;
        }
        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                         64,VL_TIME_UNITED_Q(1000),
                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__31__why));
        } else if (VL_UNLIKELY(((0x00000015U == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
        }
    }
    if ((0U == vlSelfRef.axi4_xbar_tb__DOT__errors)) {
        VL_WRITEF_NX("TEST_RESULT: PASS\n",0);
    } else {
        VL_WRITEF_NX("TEST_RESULT: FAIL: %@ (%0d failing checks of %0d)\n",0,
                     -1,&(vlSelfRef.axi4_xbar_tb__DOT__fail_reason),
                     32,vlSelfRef.axi4_xbar_tb__DOT__errors,
                     32,vlSelfRef.axi4_xbar_tb__DOT__checks);
    }
    VL_FINISH_MT("tb/axi4_xbar_tb.sv", 648, "");
    co_return;
}

VlCoroutine Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__1(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    co_await vlSelfRef.__VdlySched.delay(0x0000002e90edd000ULL, 
                                         nullptr, "tb/axi4_xbar_tb.sv", 
                                         652);
    VL_WRITEF_NX("// watchdog: phase=%@ checks=%0d\nTEST_RESULT: FAIL: timeout -- checker did not complete (phase=%@)\n",0,
                 -1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                 32,vlSelfRef.axi4_xbar_tb__DOT__checks,
                 -1,&(vlSelfRef.axi4_xbar_tb__DOT__phase));
    VL_FINISH_MT("tb/axi4_xbar_tb.sv", 655, "");
    co_return;
}

VlCoroutine Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__2(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__2\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000001388ULL, 
                                             nullptr, 
                                             "tb/axi4_xbar_tb.sv", 
                                             57);
        vlSelfRef.axi4_xbar_tb__DOT__clk = (1U & (~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__clk)));
    }
    co_return;
}

void Vaxi4_xbar_tb___024root___eval_triggers_vec__act(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_triggers_vec__act\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                      << 2U) 
                                                     | ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__rst_n)) 
                                                          & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__rst_n__0)) 
                                                         << 1U) 
                                                        | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__clk) 
                                                           & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0)))))));
    vlSelfRef.__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0 
        = vlSelfRef.axi4_xbar_tb__DOT__clk;
    vlSelfRef.__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__rst_n__0 
        = vlSelfRef.axi4_xbar_tb__DOT__rst_n;
}

bool Vaxi4_xbar_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___trigger_anySet__act\n"); );
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

void Vaxi4_xbar_tb___024root___act_sequent__TOP__0(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___act_sequent__TOP__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = (0xff000000U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xffbfffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((1U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                     | ((2U 
                                                         == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                         ? 
                                                        VL_GTS_III(32, 0x00000020U, 
                                                                   (vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U] 
                                                                    - vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U]))
                                                         : 
                                                        (0U 
                                                         == vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U]))) 
                                                    << 0x00000016U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xff7fffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((0U 
                                                      == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U]) 
                                                     & (~ vlSelfRef.axi4_xbar_tb__DOT__s_bpend[0U])) 
                                                    << 0x00000017U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xffdfffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U]) 
                                                    << 0x00000015U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xfffffbffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((1U 
                                                      != (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                     & ((2U 
                                                         == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                         ? 
                                                        (vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U] 
                                                         != vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U])
                                                         : 
                                                        ((0U 
                                                          != vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U]) 
                                                         & (0U 
                                                            == vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[0U])))) 
                                                    << 0x0000000aU));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xfffffc0fU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((2U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                      ? vlSelfRef.axi4_xbar_tb__DOT__pq_id[0U]
                                                     [
                                                     (0x0000001fU 
                                                      & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U], (IData)(0x00000020U)))]
                                                      : vlSelfRef.axi4_xbar_tb__DOT__s_rid[0U]) 
                                                    << 4U));
    VL_ASSIGNSEL_WQ(176, 64, 4U, vlSelfRef.axi4_xbar_tb__DOT__slv_resp, 
                    ((2U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                      ? ([&]() {
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__a 
                        = vlSelfRef.axi4_xbar_tb__DOT__pq_adr[0U]
                        [(0x0000001fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U], (IData)(0x00000020U)))];
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__Vfuncout 
                        = (QData)((IData)((0xfffffff0U 
                                           & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__a)));
                }(), vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__Vfuncout)
                      : ([&]() {
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__beat 
                        = (vlSelfRef.axi4_xbar_tb__DOT__s_rn[0U] 
                           - vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U]);
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__a 
                        = vlSelfRef.axi4_xbar_tb__DOT__s_raddr[0U];
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__Vfuncout 
                        = ((QData)((IData)((0xfffffff0U 
                                            & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__a))) 
                           + (0x0100000000000001ULL 
                              * VL_EXTENDS_QI(64,32, vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__beat)));
                }(), vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__Vfuncout)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U] = (0xfffffff3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U]);
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U] = ((0xfffffffdU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U]) 
                                                 | (((2U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                     | (1U 
                                                        == vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U])) 
                                                    << 1U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xffe00fffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (0xfffff000U 
                                                    & ((vlSelfRef.axi4_xbar_tb__DOT__s_bpend[0U] 
                                                        << 0x00000014U) 
                                                       | (vlSelfRef.axi4_xbar_tb__DOT__s_wid[0U] 
                                                          << 0x0000000eU))));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = (0x00ffffffU 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[4U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000bfffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (((1U 
                                                         == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                        | ((2U 
                                                            == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                            ? 
                                                           VL_GTS_III(32, 0x00000020U, 
                                                                      (vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U] 
                                                                       - vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U]))
                                                            : 
                                                           (0U 
                                                            == vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U]))) 
                                                       << 0x0000000eU)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x00007fffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (((0U 
                                                         == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U]) 
                                                        & (~ vlSelfRef.axi4_xbar_tb__DOT__s_bpend[1U])) 
                                                       << 0x0000000fU)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000dfffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U]) 
                                                       << 0x0000000dU)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000fffbU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (((1U 
                                                         != (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                        & ((2U 
                                                            == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                            ? 
                                                           (vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U] 
                                                            != vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U])
                                                            : 
                                                           ((0U 
                                                             != vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U]) 
                                                            & (0U 
                                                               == vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[1U])))) 
                                                       << 2U)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[4U] = ((0x0fffffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[4U]) 
                                                 | (((2U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                      ? vlSelfRef.axi4_xbar_tb__DOT__pq_id[1U]
                                                     [
                                                     (0x0000001fU 
                                                      & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U], (IData)(0x00000020U)))]
                                                      : vlSelfRef.axi4_xbar_tb__DOT__s_rid[1U]) 
                                                    << 0x0000001cU));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000fffcU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (((2U 
                                                         == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                         ? vlSelfRef.axi4_xbar_tb__DOT__pq_id[1U]
                                                        [
                                                        (0x0000001fU 
                                                         & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U], (IData)(0x00000020U)))]
                                                         : vlSelfRef.axi4_xbar_tb__DOT__s_rid[1U]) 
                                                       >> 4U)));
    VL_ASSIGNSEL_WQ(176, 64, 0x0000005cU, vlSelfRef.axi4_xbar_tb__DOT__slv_resp, 
                    ((2U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                      ? ([&]() {
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__a 
                        = vlSelfRef.axi4_xbar_tb__DOT__pq_adr[1U]
                        [(0x0000001fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U], (IData)(0x00000020U)))];
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__Vfuncout 
                        = (QData)((IData)((0xfffffff0U 
                                           & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__a)));
                }(), vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__Vfuncout)
                      : ([&]() {
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__beat 
                        = (vlSelfRef.axi4_xbar_tb__DOT__s_rn[1U] 
                           - vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U]);
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__a 
                        = vlSelfRef.axi4_xbar_tb__DOT__s_raddr[1U];
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__Vfuncout 
                        = ((QData)((IData)((0xfffffff0U 
                                            & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__a))) 
                           + (0x0100000000000001ULL 
                              * VL_EXTENDS_QI(64,32, vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__beat)));
                }(), vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__Vfuncout)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = (0xf3ffffffU 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xfdffffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((2U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                     | (1U 
                                                        == vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U])) 
                                                    << 0x00000019U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000e00fU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000fff0U 
                                                    & ((vlSelfRef.axi4_xbar_tb__DOT__s_bpend[1U] 
                                                        << 0x0000000cU) 
                                                       | (vlSelfRef.axi4_xbar_tb__DOT__s_wid[1U] 
                                                          << 6U))));
    if ((0U != (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))) {
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            (0xfe000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | (IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xffffffefU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 4U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0xfffffffdU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | (2U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en) 
                      << 1U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            (0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] = 
            ((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[0U], 0x00000010U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            (0x00680000U | (0x0007ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            (0x01ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            (0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfdffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x00000019U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x0000001dU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfbffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (0x04000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en) 
                               << 0x00000019U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            (0x02000000U | (0xe1ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 
            ((0x01ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[1U], 0x00000010U)) 
                << 0x00000019U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xfe000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[1U], 0x00000010U)) 
                >> 7U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 
            (0x0000d000U | (0xfe000fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            (0x0003ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfffbffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x00000012U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xffbfffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x00000016U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfff7ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (0x00080000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en) 
                               << 0x00000011U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            (0x00080000U | (0xffc3ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 
            ((0x0003ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[2U], 0x00000010U)) 
                << 0x00000012U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[2U], 0x00000010U)) 
                >> 0x0000000eU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 
            (0x000001a0U | (0xfffc001fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0x000007ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[27U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xfffff7ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x0000000bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xffff7fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x0000000fU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xffffefffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | (0x00001000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en) 
                               << 9U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            (0x00001800U | (0xffff87ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 
            ((0x000007ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[3U], 0x00000010U)) 
                << 0x0000000bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[3U], 0x00000010U)) 
                >> 0x00000015U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0x40000000U | (0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 
            (3U | (0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U]));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            (0xfe000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | (1U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xffffffefU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | (0x00000010U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b) 
                               << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0xfffffffdU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | (2U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                      << 1U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]))))) 
                << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] = 
            (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                        << 8U) | (QData)((IData)((0x000000ffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]))))) 
              >> 8U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                                   << 8U) | (QData)((IData)(
                                                            (0x000000ffU 
                                                             & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U])))) 
                                 >> 0x00000020U)) << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            (0x00680000U | (0xff07ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] = 
            ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U]) 
             | (0x00010000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                               << 0x00000010U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] = 
            ((0x00001fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]))))) 
                << 0x0000000dU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xffe00000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]))))) 
                 >> 0x00000013U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U])))) 
                                             >> 0x00000020U)) 
                                    << 0x0000000dU)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfe1fffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U] 
                << 0x00000015U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] = 
            (0x00000d00U | (0xffffe0ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xffffffdfU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__w_left[0U]) 
                << 5U));
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__a 
            = vlSelfRef.axi4_xbar_tb__DOT__w_addr[0U];
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout 
            = (QData)((IData)((0xfffffff0U & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__a)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0x0000ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | ((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout) 
                << 0x00000010U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] = 
            (((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout) 
              >> 0x00000010U) | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout 
                                          >> 0x00000020U)) 
                                 << 0x00000010U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] = 
            ((0xffff0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U]) 
             | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout 
                         >> 0x00000020U)) >> 0x00000010U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xffff007fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | (0xffffff80U & (0x0000ff00U | ((1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[0U]) 
                                              << 7U))));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            (0x01ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            (0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfdffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (0x02000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r) 
                               << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (0x20000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b) 
                               << 0x0000001cU)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfbffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (0x04000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                               << 0x00000019U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 
            ((0x0001ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]))))) 
                << 0x00000011U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xfe000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]))))) 
                 >> 0x0000000fU) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U])))) 
                                             >> 0x00000020U)) 
                                    << 0x00000011U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xe1ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U] 
                << 0x00000019U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 
            (0x0000d000U | (0xfffe0fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] = 
            ((0xfffffdffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U]) 
             | (0x00000200U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                               << 8U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] = 
            ((0x0000003fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]))))) 
                << 6U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xffffc000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]))))) 
                 >> 0x0000001aU) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U])))) 
                                             >> 0x00000020U)) 
                                    << 6U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfffc3fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U] 
                << 0x0000000eU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] = 
            (0x0000001aU | (0xffffffc1U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xbfffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__w_left[1U]) 
                << 0x0000001eU));
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__a 
            = vlSelfRef.axi4_xbar_tb__DOT__w_addr[1U];
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout 
            = (QData)((IData)((0xfffffff0U & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__a)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] = 
            ((0x000001ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U]) 
             | ((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout) 
                << 9U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] = 
            (((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout) 
              >> 0x00000017U) | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout 
                                          >> 0x00000020U)) 
                                 << 9U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] = 
            ((0xfffffe00U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U]) 
             | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout 
                         >> 0x00000020U)) >> 0x00000017U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] = 
            (0x000001feU | ((0xfffffe00U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U]) 
                            | (1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[1U])));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            (0x0003ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfffbffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (0x00040000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r) 
                               << 0x00000010U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xffbfffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (0x00400000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b) 
                               << 0x00000014U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfff7ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (0x00080000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                               << 0x00000011U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 
            ((0x000003ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]))))) 
                << 0x0000000aU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]))))) 
                 >> 0x00000016U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U])))) 
                                             >> 0x00000020U)) 
                                    << 0x0000000aU)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xffc3ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U] 
                << 0x00000012U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 
            (0x000001a0U | (0xfffffc1fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 
            ((0xfffffffbU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U]) 
             | (4U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 
            ((0x7fffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]))))) 
                << 0x0000001fU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] = 
            (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                        << 8U) | (QData)((IData)((0x000000ffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]))))) 
              >> 1U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                                   << 8U) | (QData)((IData)(
                                                            (0x000000ffU 
                                                             & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U])))) 
                                 >> 0x00000020U)) << 0x0000001fU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xffffff80U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U])))) 
                         >> 0x00000020U)) >> 1U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xfffff87fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U] 
                << 7U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 
            (0x34000000U | (0x83ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xff7fffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__w_left[2U]) 
                << 0x00000017U));
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__a 
            = vlSelfRef.axi4_xbar_tb__DOT__w_addr[2U];
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout 
            = (QData)((IData)((0xfffffff0U & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__a)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] = 
            ((3U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U]) 
             | ((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout) 
                << 2U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] = 
            (((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout) 
              >> 0x0000001eU) | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout 
                                          >> 0x00000020U)) 
                                 << 2U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 
            ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U]) 
             | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout 
                         >> 0x00000020U)) >> 0x0000001eU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0x01ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (0xfe000000U & (0xfc000000U | ((1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[2U]) 
                                              << 0x00000019U))));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] = 
            ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U]) 
             | (0x01ffffffU & (3U | ((1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[2U]) 
                                     >> 7U))));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0x000007ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[27U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xfffff7ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | (0x00000800U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r) 
                               << 8U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xffff7fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (0x00008000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b) 
                               << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xffffefffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | (0x00001000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                               << 9U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 
            ((7U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]))))) 
                << 3U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]))))) 
                 >> 0x0000001dU) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U])))) 
                                             >> 0x00000020U)) 
                                    << 3U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xffff87ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U] 
                << 0x0000000bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0x40000000U | (0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 
            (3U | (0xfffffff8U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] = 
            ((0xf7ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U]) 
             | (0x08000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                               << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U] = 
            ((0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]))))) 
                << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] = 
            (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                        << 8U) | (QData)((IData)((0x000000ffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]))))) 
              >> 8U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                                   << 8U) | (QData)((IData)(
                                                            (0x000000ffU 
                                                             & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U])))) 
                                 >> 0x00000020U)) << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[27U] = 
            (0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U] = 
            (0x00680000U | (0xff07ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__w_left[3U]) 
                << 0x00000010U));
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__a 
            = vlSelfRef.axi4_xbar_tb__DOT__w_addr[3U];
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout 
            = (QData)((IData)((0xfffffff0U & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__a)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0x07ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | ((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout) 
                << 0x0000001bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] = 
            (((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout) 
              >> 5U) | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout 
                                 >> 0x00000020U)) << 0x0000001bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] = 
            ((0xf8000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U]) 
             | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout 
                         >> 0x00000020U)) >> 5U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xf803ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (0xfffc0000U & (0x07f80000U | ((1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[3U]) 
                                              << 0x00000012U))));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
            << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                               >> 0x00000015U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
               << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                                  >> 0x00000015U)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
            << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                               >> 0x00000015U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
               << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                                  >> 0x00000015U)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar_error = 1U;
    if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] 
          >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar = 0U;
    }
    if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] 
          >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
            << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                               >> 0x0000000eU)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
               << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                                  >> 0x0000000eU)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
            << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                               >> 0x0000000eU)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
               << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                                  >> 0x0000000eU)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                      >> 0x00000019U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
               << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                         >> 0x00000019U)) < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                      >> 0x00000019U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
               << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                         >> 0x00000019U)) < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
            << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                               >> 7U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
               << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                                  >> 7U)) < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
            << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                               >> 7U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
               << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                                  >> 7U)) < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                               >> 0x00000012U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
               << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                                  >> 0x00000012U)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                               >> 0x00000012U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
               << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                                  >> 0x00000012U)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw_error = 1U;
    if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] 
          >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw = 0U;
    }
    if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] 
          >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                               >> 0x0000000bU)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
               << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                                  >> 0x0000000bU)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                               >> 0x0000000bU)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
               << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                                  >> 0x0000000bU)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__lm_off = ((((2U & 
                                              ((VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U]) 
                                                | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U]) 
                                                   | (((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_70)) 
                                                       & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                                          >> 0x0000000cU)) 
                                                      | ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_69)) 
                                                         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                            >> 0x0000001bU))))) 
                                               << 1U)) 
                                             | (1U 
                                                & (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U]) 
                                                   | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U]) 
                                                      | (((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_55)) 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                                             >> 0x00000013U)) 
                                                         | ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_54)) 
                                                            & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                                                               >> 2U))))))) 
                                            << 2U) 
                                           | ((2U & 
                                               ((VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U]) 
                                                 | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U]) 
                                                    | (((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_40)) 
                                                        & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                                           >> 0x0000001aU)) 
                                                       | ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_39)) 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                                                             >> 9U))))) 
                                                << 1U)) 
                                              | (1U 
                                                 & (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U]) 
                                                    | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U]) 
                                                       | (((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_25)) 
                                                           & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
                                                              >> 1U)) 
                                                          | ((~ (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_24)) 
                                                             & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                                                >> 0x00000010U))))))));
}

void Vaxi4_xbar_tb___024root___act_sequent__TOP__1(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___act_sequent__TOP__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
               << 1U) | (1U & (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                  << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                            << 2U)) 
                                | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                    << 1U) | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i))) 
                               >> (3U & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] 
                                         >> 8U))))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((3U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
                : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
              << 2U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[1U] 
        = ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
              ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
              : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
            >> 0x0000001eU) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                 ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                                 : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
                               << 2U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
        = ((0xffffffc0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
           | ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                 ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                 : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
               >> 0x0000001eU) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                    ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U]
                                    : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U]) 
                                  << 2U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
        = ((0xffffff3fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
           | (0xffffffc0U & ((((0U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                               & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_hebeb780c_0_9)) 
                              << 7U) | (0x00000040U 
                                        & ((((((2U 
                                                & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_hebeb780c_0_186[2U] 
                                                   >> 2U)) 
                                               | (1U 
                                                  & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_hebeb780c_0_181[2U] 
                                                     >> 3U))) 
                                              << 2U) 
                                             | ((2U 
                                                 & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__VdfgRegularize_hebeb780c_0_180[2U] 
                                                    >> 2U)) 
                                                | (1U 
                                                   & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_159[2U] 
                                                      >> 3U)))) 
                                            >> (3U 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] 
                                                   >> 0x00000012U))) 
                                           << 6U)))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
        = ((0x000000ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
           | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[0U] 
              << 8U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[0U] 
            >> 0x00000018U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[1U] 
                               << 8U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[1U] 
            >> 0x00000018U) | ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                  ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
                                  : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
                                << 0x00000013U) | (
                                                   (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                     | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                    << 0x00000012U) 
                                                   | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[2U] 
                                                      << 8U))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = (((0x000000ffU & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                              ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
                              : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
                            >> 0x0000000dU)) | ((0x000000ffU 
                                                 & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                     | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                    >> 0x0000000eU)) 
                                                | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[2U] 
                                                   >> 0x00000018U))) 
           | ((0x0007ff00U & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
                                : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
                              >> 0x0000000dU)) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                                    ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                                                    : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
                                                  << 0x00000013U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0xe0000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | ((0x000000ffU & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                                : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
                              >> 0x0000000dU)) | ((0x0007ff00U 
                                                   & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                                        ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                                                        : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
                                                      >> 0x0000000dU)) 
                                                  | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                                       ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U]
                                                       : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U]) 
                                                     << 0x00000013U))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0x9fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | (0xe0000000U & ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                               | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                              << 0x0000001eU) | (0x20000000U 
                                                 & ((((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                        << 3U) 
                                                       | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                          << 2U)) 
                                                      | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i) 
                                                          << 1U) 
                                                         | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i))) 
                                                     >> 
                                                     (3U 
                                                      & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U])) 
                                                    << 0x0000001dU)))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0x7fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
                : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
              << 0x0000001fU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
              ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
              : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
            >> 1U) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                        ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                        : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
                      << 0x0000001fU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
        = ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
              ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
              : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
            >> 1U) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                        ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U]
                        : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U]) 
                      << 0x0000001fU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = ((0xfffffff8U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
           | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U]
                : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U]) 
              >> 1U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = ((0xffffffe7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
           | (0xfffffff8U & ((((0U != (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q)) 
                               & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_11)) 
                              << 4U) | (8U & ((((((2U 
                                                   & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_152[2U] 
                                                      >> 2U)) 
                                                  | (1U 
                                                     & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_142[2U] 
                                                        >> 3U))) 
                                                 << 2U) 
                                                | ((2U 
                                                    & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_132[2U] 
                                                       >> 2U)) 
                                                   | (1U 
                                                      & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_122[2U] 
                                                         >> 3U)))) 
                                               >> (3U 
                                                   & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] 
                                                      >> 0x0000000aU))) 
                                              << 3U)))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = ((0x0000001fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
           | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[0U] 
              << 5U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[0U] 
            >> 0x0000001bU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[1U] 
                               << 5U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[1U] 
            >> 0x0000001bU) | ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                  ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
                                  : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
                                << 0x00000010U) | (
                                                   (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                     | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                    << 0x0000000fU) 
                                                   | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[2U] 
                                                      << 5U))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = (((0x0000001fU & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                              ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
                              : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
                            >> 0x00000010U)) | ((0x0000001fU 
                                                 & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q) 
                                                     | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
                                                    >> 0x00000011U)) 
                                                | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__mst_w_chan[2U] 
                                                   >> 0x0000001bU))) 
           | ((0x0000ffe0U & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[0U]
                                : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[0U]) 
                              >> 0x00000010U)) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                                    ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                                                    : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
                                                  << 0x00000010U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] 
        = (0x03ffffffU & ((0x0000001fU & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                            ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                                            : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
                                          >> 0x00000010U)) 
                          | ((0x0000ffe0U & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                               ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[1U]
                                               : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[1U]) 
                                             >> 0x00000010U)) 
                             | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)
                                  ? vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q[2U]
                                  : vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q[2U]) 
                                << 0x00000010U))));
}

void Vaxi4_xbar_tb___024root___act_sequent__TOP__2(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___act_sequent__TOP__2\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
        = vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_92[0U];
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U] 
        = vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_92[1U];
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0xffffff00U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_92[2U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0xfff000ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | (0xffffff00U & ((((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_24) 
                                 << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_25) 
                                           << 2U)) 
                               | ((2U & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_21)
                                           ? (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv.__VdfgRegularize_h247165ad_0_6)
                                           : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_19)
                                               ? (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies)
                                               : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_18) 
                                                  & (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies)))) 
                                         << 1U)) | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))) 
                              << 0x00000010U) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_91) 
                                                  << 9U) 
                                                 | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                                    << 8U)))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0x000fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_90[0U] 
              << 0x00000014U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_90[0U] 
            >> 0x0000000cU) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_90[1U] 
                               << 0x00000014U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_90[1U] 
            >> 0x0000000cU) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_89) 
                                << 0x0000001dU) | (
                                                   ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                                    << 0x0000001cU) 
                                                   | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_90[2U] 
                                                      << 0x00000014U))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | ((0x000fffffU & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_89) 
                              >> 3U)) | ((0x000fffffU 
                                          & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                             >> 4U)) 
                                         | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_90[2U] 
                                            >> 0x0000000cU))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0xffffff0fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | (((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_39) 
                 << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_40) 
                           << 2U)) | ((2U & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_36)
                                               ? (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv.__VdfgRegularize_h247165ad_0_6)
                                               : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_34)
                                                   ? 
                                                  ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                   >> 1U)
                                                   : 
                                                  ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_32) 
                                                   & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                      >> 1U)))) 
                                             << 1U)) 
                                      | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))) 
              << 4U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0x000000ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_88[0U] 
              << 8U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_88[0U] 
            >> 0x00000018U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_88[1U] 
                               << 8U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0xffff0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_88[1U] 
               >> 0x00000018U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_88[2U] 
                                  << 8U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0xf000ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | (0xffff0000U & ((((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_54) 
                                 << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_55) 
                                           << 2U)) 
                               | ((2U & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_51)
                                           ? (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv.__VdfgRegularize_h247165ad_0_6)
                                           : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_49)
                                               ? ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                  >> 2U)
                                               : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_47) 
                                                  & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                     >> 2U)))) 
                                         << 1U)) | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))) 
                              << 0x00000018U) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_87) 
                                                  << 0x00000011U) 
                                                 | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                                    << 0x00000010U)))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0x0fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_94[0U] 
              << 0x0000001cU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_94[0U] 
            >> 4U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_94[1U] 
                      << 0x0000001cU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U] 
        = ((vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_94[1U] 
            >> 4U) | (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_94[2U] 
                      << 0x0000001cU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
        = ((0x0000fff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
           | (0x0000ffffU & (vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_94[2U] 
                             >> 4U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
        = ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
           | (0x0000fff0U & ((((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_69) 
                                 << 3U) | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_70) 
                                           << 2U)) 
                               | ((2U & (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_66)
                                           ? (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv.__VdfgRegularize_h247165ad_0_6)
                                           : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_64)
                                               ? ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                  >> 3U)
                                               : ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_62) 
                                                  & ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux.__PVT__gen_mux__DOT__slv_w_readies) 
                                                     >> 3U)))) 
                                         << 1U)) | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o))) 
                              << 0x0000000cU) | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_93) 
                                                  << 5U) 
                                                 | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o) 
                                                    << 4U)))));
}

void Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf);
void Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf);
void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf);
void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf);
void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf);
void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf);
void Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__1(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf);
void Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__1(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__0(Vaxi4_xbar_tb_axi_err_slv__pi5* vlSelf);
void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf);
void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf);
void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf);
void Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__1(Vaxi4_xbar_tb_axi_demux__pi4* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);
void Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0(Vaxi4_xbar_tb_axi_demux_id_counters__pi10* vlSelf);

void Vaxi4_xbar_tb___024root___eval_act(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_act\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        Vaxi4_xbar_tb___024root___act_sequent__TOP__0(vlSelf);
        Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux));
        Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux));
        Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux));
        Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux));
        Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux));
        Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter));
        Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv));
        Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux));
        Vaxi4_xbar_tb_axi_mux__pi3___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter));
        Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter));
        Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter));
        Vaxi4_xbar_tb_axi_err_slv__pi5___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv));
        Vaxi4_xbar_tb___024root___act_sequent__TOP__1(vlSelf);
        Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux));
        Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux));
        Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux));
        Vaxi4_xbar_tb_axi_demux__pi4___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter));
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter__1((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter));
        Vaxi4_xbar_tb___024root___act_sequent__TOP__2(vlSelf);
        Vaxi4_xbar_tb_axi_demux_id_counters__pi10___act_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter__0((&vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter));
    }
}

void Vaxi4_xbar_tb___024root___nba_sequent__TOP__0(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___nba_sequent__TOP__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__s_w_inflight;
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        axi4_xbar_tb__DOT__s_w_inflight[__Vi0] = 0;
    }
    QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout;
    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a;
    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a = 0;
    IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat;
    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat = 0;
    QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout;
    __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a;
    __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a = 0;
    IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat;
    __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat = 0;
    IData/*31:0*/ __Vdly__axi4_xbar_tb__DOT__bp_b_stalls;
    __Vdly__axi4_xbar_tb__DOT__bp_b_stalls = 0;
    IData/*31:0*/ __Vdly__axi4_xbar_tb__DOT__bp_r_stalls;
    __Vdly__axi4_xbar_tb__DOT__bp_r_stalls = 0;
    IData/*31:0*/ __Vdly__axi4_xbar_tb__DOT__cov_max_len;
    __Vdly__axi4_xbar_tb__DOT__cov_max_len = 0;
    CData/*3:0*/ __Vdly__axi4_xbar_tb__DOT__ar_hold;
    __Vdly__axi4_xbar_tb__DOT__ar_hold = 0;
    CData/*3:0*/ __Vdly__axi4_xbar_tb__DOT__aw_hold;
    __Vdly__axi4_xbar_tb__DOT__aw_hold = 0;
    SData/*15:0*/ __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v0;
    __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v0;
    __VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v0 = 0;
    SData/*15:0*/ __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v1;
    __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v1 = 0;
    SData/*15:0*/ __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v2;
    __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v2 = 0;
    SData/*15:0*/ __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v3;
    __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v4;
    __VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v0;
    __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v0;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v1;
    __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v1;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v2;
    __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v2;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v3;
    __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v3;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v4;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v0;
    __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v0;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v1;
    __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v1;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v2;
    __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v2;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v3;
    __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v3;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v4;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v4 = 0;
    CData/*5:0*/ __VdlyVal__axi4_xbar_tb__DOT__pq_id__v0;
    __VdlyVal__axi4_xbar_tb__DOT__pq_id__v0 = 0;
    CData/*4:0*/ __VdlyDim0__axi4_xbar_tb__DOT__pq_id__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__pq_id__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__pq_id__v0;
    __VdlySet__axi4_xbar_tb__DOT__pq_id__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__pq_adr__v0;
    __VdlyVal__axi4_xbar_tb__DOT__pq_adr__v0 = 0;
    CData/*4:0*/ __VdlyDim0__axi4_xbar_tb__DOT__pq_adr__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__pq_adr__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__pq_tl__v0;
    __VdlyVal__axi4_xbar_tb__DOT__pq_tl__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__pq_tl__v1;
    __VdlySet__axi4_xbar_tb__DOT__pq_tl__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__pq_hd__v0;
    __VdlyVal__axi4_xbar_tb__DOT__pq_hd__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__pq_hd__v0;
    __VdlySet__axi4_xbar_tb__DOT__pq_hd__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__pq_hd__v1;
    __VdlySet__axi4_xbar_tb__DOT__pq_hd__v1 = 0;
    CData/*5:0*/ __VdlyVal__axi4_xbar_tb__DOT__pq_id__v1;
    __VdlyVal__axi4_xbar_tb__DOT__pq_id__v1 = 0;
    CData/*4:0*/ __VdlyDim0__axi4_xbar_tb__DOT__pq_id__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__pq_id__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__pq_id__v1;
    __VdlySet__axi4_xbar_tb__DOT__pq_id__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__pq_adr__v1;
    __VdlyVal__axi4_xbar_tb__DOT__pq_adr__v1 = 0;
    CData/*4:0*/ __VdlyDim0__axi4_xbar_tb__DOT__pq_adr__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__pq_adr__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__pq_tl__v2;
    __VdlyVal__axi4_xbar_tb__DOT__pq_tl__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__pq_tl__v3;
    __VdlySet__axi4_xbar_tb__DOT__pq_tl__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__pq_hd__v2;
    __VdlyVal__axi4_xbar_tb__DOT__pq_hd__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__pq_hd__v2;
    __VdlySet__axi4_xbar_tb__DOT__pq_hd__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__pq_hd__v3;
    __VdlySet__axi4_xbar_tb__DOT__pq_hd__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v0;
    __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v0;
    __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rn__v0;
    __VdlyVal__axi4_xbar_tb__DOT__s_rn__v0 = 0;
    CData/*5:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rid__v0;
    __VdlyVal__axi4_xbar_tb__DOT__s_rid__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_raddr__v0;
    __VdlyVal__axi4_xbar_tb__DOT__s_raddr__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v0;
    __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v1;
    __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_rdelay__v1;
    __VdlySet__axi4_xbar_tb__DOT__s_rdelay__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v1;
    __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v1;
    __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v2;
    __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v0;
    __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v0;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v0 = 0;
    CData/*5:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_wid__v0;
    __VdlyVal__axi4_xbar_tb__DOT__s_wid__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_w_inflight__v0;
    __VdlyVal__axi4_xbar_tb__DOT__s_w_inflight__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v1;
    __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v1;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_bpend__v0;
    __VdlySet__axi4_xbar_tb__DOT__s_bpend__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_bpend__v1;
    __VdlySet__axi4_xbar_tb__DOT__s_bpend__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v2;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v3;
    __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v3;
    __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rn__v1;
    __VdlyVal__axi4_xbar_tb__DOT__s_rn__v1 = 0;
    CData/*5:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rid__v1;
    __VdlyVal__axi4_xbar_tb__DOT__s_rid__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_raddr__v1;
    __VdlyVal__axi4_xbar_tb__DOT__s_raddr__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v4;
    __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v5;
    __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v5 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_rdelay__v5;
    __VdlySet__axi4_xbar_tb__DOT__s_rdelay__v5 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v4;
    __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v4 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v4;
    __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v6;
    __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v6 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v3;
    __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v3;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v3 = 0;
    CData/*5:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_wid__v1;
    __VdlyVal__axi4_xbar_tb__DOT__s_wid__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_w_inflight__v2;
    __VdlyVal__axi4_xbar_tb__DOT__s_w_inflight__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v4;
    __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v4 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v4;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v4 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_bpend__v3;
    __VdlySet__axi4_xbar_tb__DOT__s_bpend__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_bpend__v4;
    __VdlySet__axi4_xbar_tb__DOT__s_bpend__v4 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v5;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v5 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_head__v0;
    __VdlyVal__axi4_xbar_tb__DOT__rq_head__v0 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_head__v0;
    __VdlySet__axi4_xbar_tb__DOT__rq_head__v0 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v1;
    __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v1 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_beat__v1;
    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__last_rid__v0;
    __VdlyVal__axi4_xbar_tb__DOT__last_rid__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__last_rid__v0;
    __VdlySet__axi4_xbar_tb__DOT__last_rid__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_head__v0;
    __VdlyVal__axi4_xbar_tb__DOT__wq_head__v0 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__wq_head__v0;
    __VdlySet__axi4_xbar_tb__DOT__wq_head__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_head__v1;
    __VdlyVal__axi4_xbar_tb__DOT__rq_head__v1 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_head__v1;
    __VdlySet__axi4_xbar_tb__DOT__rq_head__v1 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v3;
    __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v3 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_beat__v3;
    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__last_rid__v1;
    __VdlyVal__axi4_xbar_tb__DOT__last_rid__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__last_rid__v1;
    __VdlySet__axi4_xbar_tb__DOT__last_rid__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_head__v1;
    __VdlyVal__axi4_xbar_tb__DOT__wq_head__v1 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__wq_head__v1;
    __VdlySet__axi4_xbar_tb__DOT__wq_head__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_head__v2;
    __VdlyVal__axi4_xbar_tb__DOT__rq_head__v2 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_head__v2;
    __VdlySet__axi4_xbar_tb__DOT__rq_head__v2 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v4;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v5;
    __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v5 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v5;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v5 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_beat__v5;
    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v5 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__last_rid__v2;
    __VdlyVal__axi4_xbar_tb__DOT__last_rid__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__last_rid__v2;
    __VdlySet__axi4_xbar_tb__DOT__last_rid__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_head__v2;
    __VdlyVal__axi4_xbar_tb__DOT__wq_head__v2 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__wq_head__v2;
    __VdlySet__axi4_xbar_tb__DOT__wq_head__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_head__v3;
    __VdlyVal__axi4_xbar_tb__DOT__rq_head__v3 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_head__v3;
    __VdlySet__axi4_xbar_tb__DOT__rq_head__v3 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v6;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v6 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v7;
    __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v7 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v7;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v7 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_beat__v7;
    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v7 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__last_rid__v3;
    __VdlyVal__axi4_xbar_tb__DOT__last_rid__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__last_rid__v3;
    __VdlySet__axi4_xbar_tb__DOT__last_rid__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_head__v3;
    __VdlyVal__axi4_xbar_tb__DOT__wq_head__v3 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__wq_head__v3;
    __VdlySet__axi4_xbar_tb__DOT__wq_head__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v0;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v0;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v0;
    __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v0;
    __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v0 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v0 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v0;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_len__v0;
    __VdlyVal__axi4_xbar_tb__DOT__rq_len__v0 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v0 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v0;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_len__v0;
    __VdlySet__axi4_xbar_tb__DOT__rq_len__v0 = 0;
    CData/*0:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v0;
    __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v0 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v0 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v0;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v0;
    __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v0 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v0;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v0;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v1;
    __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v1 = 0;
    CData/*0:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v0;
    __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v0 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v0 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v0;
    __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_left__v0;
    __VdlyVal__axi4_xbar_tb__DOT__w_left__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v0;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_addr__v0;
    __VdlyVal__axi4_xbar_tb__DOT__w_addr__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v0;
    __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v0 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v0;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_left__v1;
    __VdlyVal__axi4_xbar_tb__DOT__w_left__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v1;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v1;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v1;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v1;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v1;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v1 = 0;
    CData/*3:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v0;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_id__v0;
    __VdlySet__axi4_xbar_tb__DOT__nxt_id__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_len__v0;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v1;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_len__v1;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v0;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v0 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v0;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v0 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v1;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v1;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v2;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v2;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v2;
    __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v1;
    __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v1 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v1 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v1;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_len__v1;
    __VdlyVal__axi4_xbar_tb__DOT__rq_len__v1 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v1 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v1;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_len__v1;
    __VdlySet__axi4_xbar_tb__DOT__rq_len__v1 = 0;
    CData/*0:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v1;
    __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v1 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v1 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v1;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v1;
    __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v1 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v2;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v2;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v3;
    __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v3 = 0;
    CData/*0:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v1;
    __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v1 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v1 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v1;
    __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_left__v2;
    __VdlyVal__axi4_xbar_tb__DOT__w_left__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v2;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_addr__v1;
    __VdlyVal__axi4_xbar_tb__DOT__w_addr__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v1;
    __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v1 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v1;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v1 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_left__v3;
    __VdlyVal__axi4_xbar_tb__DOT__w_left__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v3;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v3;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v3;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v3;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v3;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v3 = 0;
    CData/*3:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v1;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_id__v1;
    __VdlySet__axi4_xbar_tb__DOT__nxt_id__v1 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_len__v2;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v3;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_len__v3;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v2;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v2;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v3;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v3;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v4;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v4 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v4;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v4;
    __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v2;
    __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v2 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v2 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v2;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_len__v2;
    __VdlyVal__axi4_xbar_tb__DOT__rq_len__v2 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v2 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v2;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_len__v2;
    __VdlySet__axi4_xbar_tb__DOT__rq_len__v2 = 0;
    CData/*0:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v2;
    __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v2 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v2 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v2;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v2;
    __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v2 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v4;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v4 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v4;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v5;
    __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v5 = 0;
    CData/*0:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v2;
    __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v2 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v2 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v2;
    __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_left__v4;
    __VdlyVal__axi4_xbar_tb__DOT__w_left__v4 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v4;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_addr__v2;
    __VdlyVal__axi4_xbar_tb__DOT__w_addr__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v2;
    __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v2 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v2;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v2 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_left__v5;
    __VdlyVal__axi4_xbar_tb__DOT__w_left__v5 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v5;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v5 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v5;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v5 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v5;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v5 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v5;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v5 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v5;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v5 = 0;
    CData/*3:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v2;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_id__v2;
    __VdlySet__axi4_xbar_tb__DOT__nxt_id__v2 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_len__v4;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v5;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v5 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_len__v5;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v5 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v4;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v4 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v4;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v4 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v5;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v5 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v5;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v5 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v6;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v6 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v6;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v6 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v6;
    __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v6 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v3;
    __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v3 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v3 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v3;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_len__v3;
    __VdlyVal__axi4_xbar_tb__DOT__rq_len__v3 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v3 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v3;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__rq_len__v3;
    __VdlySet__axi4_xbar_tb__DOT__rq_len__v3 = 0;
    CData/*0:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v3;
    __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v3 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v3 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v3;
    __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v3;
    __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v3 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v6;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v6 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v6;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v6 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v7;
    __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v7 = 0;
    CData/*0:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v3;
    __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v3 = 0;
    CData/*5:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v3 = 0;
    CData/*1:0*/ __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v3;
    __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_left__v6;
    __VdlyVal__axi4_xbar_tb__DOT__w_left__v6 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v6;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v6 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_addr__v3;
    __VdlyVal__axi4_xbar_tb__DOT__w_addr__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v3;
    __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v3 = 0;
    CData/*1:0*/ __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v3;
    __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v3 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__w_left__v7;
    __VdlyVal__axi4_xbar_tb__DOT__w_left__v7 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v7;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v7 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v7;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v7 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v7;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v7 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v7;
    __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v7 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v7;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v7 = 0;
    CData/*3:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v3;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_id__v3;
    __VdlySet__axi4_xbar_tb__DOT__nxt_id__v3 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_len__v6;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v6 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v7;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v7 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_len__v7;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v7 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v6;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v6 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v6;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v6 = 0;
    IData/*31:0*/ __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v7;
    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v7 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v7;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v7 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__txn_sent__v8;
    __VdlySet__axi4_xbar_tb__DOT__txn_sent__v8 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v8;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v8 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v9;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v9 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v10;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v10 = 0;
    CData/*0:0*/ __VdlySet__axi4_xbar_tb__DOT__w_left__v11;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v11 = 0;
    // Body
    __Vdly__axi4_xbar_tb__DOT__bp_b_stalls = vlSelfRef.axi4_xbar_tb__DOT__bp_b_stalls;
    __Vdly__axi4_xbar_tb__DOT__bp_r_stalls = vlSelfRef.axi4_xbar_tb__DOT__bp_r_stalls;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__last_rid__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__last_rid__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__last_rid__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__last_rid__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__wq_head__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__wq_head__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__wq_head__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__wq_head__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v5 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v7 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_head__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_head__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_head__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_head__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__pq_hd__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__pq_hd__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__pq_hd__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__pq_hd__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__pq_tl__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__pq_tl__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__pq_id__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__pq_id__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_bpend__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_bpend__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_bpend__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_bpend__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_rdelay__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_rdelay__v5 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v5 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v4 = 0U;
    __Vdly__axi4_xbar_tb__DOT__cov_max_len = vlSelfRef.axi4_xbar_tb__DOT__cov_max_len;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v5 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v7 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v5 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v7 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_len__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_len__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_len__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__rq_len__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v6 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v6 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__txn_sent__v8 = 0U;
    __Vdly__axi4_xbar_tb__DOT__ar_hold = vlSelfRef.axi4_xbar_tb__DOT__ar_hold;
    __Vdly__axi4_xbar_tb__DOT__aw_hold = vlSelfRef.axi4_xbar_tb__DOT__aw_hold;
    __VdlySet__axi4_xbar_tb__DOT__nxt_id__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_id__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_id__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_id__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v5 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v6 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v7 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v5 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v7 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v1 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v3 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v5 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v6 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v7 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v0 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v2 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v4 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v6 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v11 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v8 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v9 = 0U;
    __VdlySet__axi4_xbar_tb__DOT__w_left__v10 = 0U;
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__rst_n) 
         & (0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)))) {
        vlSelfRef.axi4_xbar_tb__DOT__lm_off_s = vlSelfRef.axi4_xbar_tb__DOT__lm_off;
        vlSelfRef.axi4_xbar_tb__DOT__lm_srv_s = (((
                                                   ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_0) 
                                                    | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_1)) 
                                                   << 3U) 
                                                  | (((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_2) 
                                                      | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_3)) 
                                                     << 2U)) 
                                                 | ((((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_4) 
                                                      | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_5)) 
                                                     << 1U) 
                                                    | ((IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_6) 
                                                       | (IData)(vlSymsp->TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux.__VdfgRegularize_hebeb780c_0_7))));
        vlSelfRef.axi4_xbar_tb__DOT__lm_any_off = (0U 
                                                   != (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_off_s));
        vlSelfRef.axi4_xbar_tb__DOT__lm_any_srv = (0U 
                                                   != (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_srv_s));
        if (vlSelfRef.axi4_xbar_tb__DOT__lm_any_srv) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_global_idle = 0U;
        } else if (vlSelfRef.axi4_xbar_tb__DOT__lm_any_off) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_global_idle 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_global_idle);
        }
        if ((VL_LTS_III(32, 0x00000fa0U, vlSelfRef.axi4_xbar_tb__DOT__lm_global_idle) 
             & (~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_stall_fired)))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_stall_fired = 1U;
            vlSelfRef.axi4_xbar_tb__DOT__lm_reason 
                = VL_SFORMATF_N_NX("DEADLOCK: %0d cycles with load offered and nothing retired anywhere",0,
                                   32,vlSelfRef.axi4_xbar_tb__DOT__lm_global_idle) ;
        }
        if ((1U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_srv_s))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_wait[0U] = 0U;
            vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[0U] 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[0U]);
        } else if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_off_s) 
                    & (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_any_srv))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_wait[0U] 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_wait[0U]);
            if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__lm_wait[0U], vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait)) {
                vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait 
                    = vlSelfRef.axi4_xbar_tb__DOT__lm_wait[0U];
                vlSelfRef.axi4_xbar_tb__DOT__lm_worst_req = 0U;
            }
            if ((VL_LTS_III(32, 0x00001f40U, vlSelfRef.axi4_xbar_tb__DOT__lm_wait[0U]) 
                 & (~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired)))) {
                vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired = 1U;
                vlSelfRef.axi4_xbar_tb__DOT__lm_reason 
                    = VL_SFORMATF_N_NX("STARVATION: requester 0 waited %0d cycles while others were served",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__lm_wait[0U]) ;
            }
        }
        if ((2U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_srv_s))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[1U] 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[1U]);
            vlSelfRef.axi4_xbar_tb__DOT__lm_wait[1U] = 0U;
        } else if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_off_s) 
                     >> 1U) & (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_any_srv))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_wait[1U] 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_wait[1U]);
            if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__lm_wait[1U], vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait)) {
                vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait 
                    = vlSelfRef.axi4_xbar_tb__DOT__lm_wait[1U];
                vlSelfRef.axi4_xbar_tb__DOT__lm_worst_req = 1U;
            }
            if ((VL_LTS_III(32, 0x00001f40U, vlSelfRef.axi4_xbar_tb__DOT__lm_wait[1U]) 
                 & (~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired)))) {
                vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired = 1U;
                vlSelfRef.axi4_xbar_tb__DOT__lm_reason 
                    = VL_SFORMATF_N_NX("STARVATION: requester 1 waited %0d cycles while others were served",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__lm_wait[1U]) ;
            }
        }
        if ((4U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_srv_s))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[2U] 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[2U]);
            vlSelfRef.axi4_xbar_tb__DOT__lm_wait[2U] = 0U;
        } else if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_off_s) 
                     >> 2U) & (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_any_srv))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_wait[2U] 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_wait[2U]);
            if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__lm_wait[2U], vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait)) {
                vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait 
                    = vlSelfRef.axi4_xbar_tb__DOT__lm_wait[2U];
                vlSelfRef.axi4_xbar_tb__DOT__lm_worst_req = 2U;
            }
            if ((VL_LTS_III(32, 0x00001f40U, vlSelfRef.axi4_xbar_tb__DOT__lm_wait[2U]) 
                 & (~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired)))) {
                vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired = 1U;
                vlSelfRef.axi4_xbar_tb__DOT__lm_reason 
                    = VL_SFORMATF_N_NX("STARVATION: requester 2 waited %0d cycles while others were served",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__lm_wait[2U]) ;
            }
        }
        if ((8U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_srv_s))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[3U] 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_served_count[3U]);
            vlSelfRef.axi4_xbar_tb__DOT__lm_wait[3U] = 0U;
        } else if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_off_s) 
                     >> 3U) & (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_any_srv))) {
            vlSelfRef.axi4_xbar_tb__DOT__lm_wait[3U] 
                = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__lm_wait[3U]);
            if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__lm_wait[3U], vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait)) {
                vlSelfRef.axi4_xbar_tb__DOT__lm_worst_wait 
                    = vlSelfRef.axi4_xbar_tb__DOT__lm_wait[3U];
                vlSelfRef.axi4_xbar_tb__DOT__lm_worst_req = 3U;
            }
            if ((VL_LTS_III(32, 0x00001f40U, vlSelfRef.axi4_xbar_tb__DOT__lm_wait[3U]) 
                 & (~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired)))) {
                vlSelfRef.axi4_xbar_tb__DOT__lm_starve_fired = 1U;
                vlSelfRef.axi4_xbar_tb__DOT__lm_reason 
                    = VL_SFORMATF_N_NX("STARVATION: requester 3 waited %0d cycles while others were served",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__lm_wait[3U]) ;
            }
        }
    }
    if (vlSelfRef.axi4_xbar_tb__DOT__rst_n) {
        if ((0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))) {
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                        >> 0x00000010U) & (~ (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                              >> 4U))))) {
                __Vdly__axi4_xbar_tb__DOT__bp_b_stalls 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__bp_b_stalls);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                        >> 4U) & (~ (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                     >> 0x0000001dU))))) {
                __Vdly__axi4_xbar_tb__DOT__bp_b_stalls 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__bp_b_stalls);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                        >> 0x00000018U) & (~ (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                              >> 0x00000016U))))) {
                __Vdly__axi4_xbar_tb__DOT__bp_b_stalls 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__bp_b_stalls);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                        >> 0x0000000cU) & (~ (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                              >> 0x0000000fU))))) {
                __Vdly__axi4_xbar_tb__DOT__bp_b_stalls 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__bp_b_stalls);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                        >> 8U) & (~ vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U])))) {
                __Vdly__axi4_xbar_tb__DOT__bp_r_stalls 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__bp_r_stalls);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                        >> 0x0000001cU) & (~ (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                              >> 0x00000019U))))) {
                __Vdly__axi4_xbar_tb__DOT__bp_r_stalls 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__bp_r_stalls);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                        >> 0x00000010U) & (~ (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                              >> 0x00000012U))))) {
                __Vdly__axi4_xbar_tb__DOT__bp_r_stalls 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__bp_r_stalls);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                        >> 4U) & (~ (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                     >> 0x0000000bU))))) {
                __Vdly__axi4_xbar_tb__DOT__bp_r_stalls 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__bp_r_stalls);
            }
        }
        if ((0U != (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))) {
            if ((1U & (((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                         >> 8U) & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
                       & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
                          >> 1U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[0U]);
                __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v0 = 1U;
            }
            if ((1U & (((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                         >> 0x0000001cU) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                            >> 0x00000019U)) 
                       & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                          >> 0x00000015U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v1 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[1U]);
                __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v1 = 1U;
            }
            if ((1U & (((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                         >> 0x00000010U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                            >> 0x00000012U)) 
                       & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                          >> 9U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[2U]);
                __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v2 = 1U;
            }
            if ((1U & (((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                         >> 4U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                   >> 0x0000000bU)) 
                       & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                          >> 0x0000001dU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v3 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[3U]);
                __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v3 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
                        >> 1U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                  >> 0x00000012U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[0U]);
                __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v0 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                        >> 0x0000001aU) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                           >> 6U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v1 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[1U]);
                __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v1 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                        >> 0x00000013U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                           >> 0x0000001aU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[2U]);
                __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v2 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                        >> 0x0000000cU) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                           >> 0x0000000eU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v3 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[3U]);
                __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v3 = 1U;
            }
        }
    } else {
        __Vdly__axi4_xbar_tb__DOT__bp_b_stalls = 0U;
        __Vdly__axi4_xbar_tb__DOT__bp_r_stalls = 0U;
        __VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v4 = 1U;
        __VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v4 = 1U;
    }
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__rst_n) 
         & (0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i = 0U;
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                    >> 8U) & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]))) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i 
                = (0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                  >> 4U));
            vlSelfRef.axi4_xbar_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi4_xbar_tb__DOT__checks);
            if (VL_LTES_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why 
                    = VL_SFORMATF_N_NX("master 0: R with id %0d outside the issued set",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else if ((vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                        == vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)])) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why 
                    = VL_SFORMATF_N_NX("master 0 id %0d: R beat with no outstanding read",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else {
                if (vlSelfRef.axi4_xbar_tb__DOT__rq_dec[0U]
                    [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                    [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                                                   [
                                                   (3U 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                    if ((3U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
                                      >> 2U)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why 
                            = VL_SFORMATF_N_NX("master 0 id %0d: unmapped read returned resp=%0b, expected DECERR (D2)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
                                                     >> 2U))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                } else {
                    if ((0U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
                                      >> 2U)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why 
                            = VL_SFORMATF_N_NX("master 0 id %0d: mapped read returned resp=%0b",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
                                                     >> 2U))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                    if (((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U])) 
                           << 0x0000003cU) | (((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U])) 
                                               << 0x0000001cU) 
                                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U])) 
                                                 >> 4U))) 
                         != ([&]() {
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat 
                                        = vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)];
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a 
                                        = vlSelfRef.axi4_xbar_tb__DOT__rq_addr[0U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                        [(0x0000003fU 
                                          & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                                                           [
                                                           (3U 
                                                            & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))];
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout 
                                        = ((QData)((IData)(
                                                           (0xfffffff0U 
                                                            & __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a))) 
                                           + (0x0100000000000001ULL 
                                              * VL_EXTENDS_QI(64,32, __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat)));
                                }(), __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why 
                            = VL_SFORMATF_N_NX("master 0 id %0d beat %0d: data=0x%0x expected 0x%0x (D1/O1)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U]
                                               [(3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)],
                                               64,(
                                                   ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U])) 
                                                    << 0x0000003cU) 
                                                   | (((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U])) 
                                                       << 0x0000001cU) 
                                                      | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U])) 
                                                         >> 4U))),
                                               64,([&]() {
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat 
                                            = vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U]
                                            [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)];
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a 
                                            = vlSelfRef.axi4_xbar_tb__DOT__rq_addr[0U]
                                            [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                            [(0x0000003fU 
                                              & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                                                               [
                                                               (3U 
                                                                & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))];
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout 
                                            = ((QData)((IData)(
                                                               (0xfffffff0U 
                                                                & __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a))) 
                                               + (0x0100000000000001ULL 
                                                  * 
                                                  VL_EXTENDS_QI(64,32, __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat)));
                                    }(), __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout)) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                }
                if (((1U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
                            >> 1U)) != (vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                                        == vlSelfRef.axi4_xbar_tb__DOT__rq_len[0U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                        [(0x0000003fU 
                                          & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                                                           [
                                                           (3U 
                                                            & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]))) {
                    vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why 
                        = VL_SFORMATF_N_NX("master 0 id %0d: RLAST on beat %0d of a %0d-beat burst (O4/D2)",0,
                                           32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                           32,vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U]
                                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)],
                                           32,((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__rq_len[0U]
                                               [(3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                               [(0x0000003fU 
                                                 & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                                                                  [
                                                                  (3U 
                                                                   & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))])) ;
                    vlSelfRef.axi4_xbar_tb__DOT__errors 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                    if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                        vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                            = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why;
                    }
                    if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                        VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                     64,VL_TIME_UNITED_Q(1000),
                                     -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                     -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why));
                    } else if (VL_UNLIKELY(((0x00000015U 
                                             == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                        VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                    }
                }
                if ((2U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U])) {
                    if (vlSelfRef.axi4_xbar_tb__DOT__rq_dec[0U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                        [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                                                       [
                                                       (3U 
                                                        & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec);
                    } else {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok);
                    }
                    if (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__rq_len[0U]
                                   [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                   [(0x0000003fU & 
                                     VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))])) {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1);
                    }
                    __VdlyVal__axi4_xbar_tb__DOT__rq_head__v0 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U]
                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v0 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                    __VdlySet__axi4_xbar_tb__DOT__rq_head__v0 = 1U;
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v0 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v1 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U]
                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v1 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v1 = 1U;
                }
                if ((vlSelfRef.axi4_xbar_tb__DOT__last_rid[0U] 
                     != vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id);
                    __VdlyVal__axi4_xbar_tb__DOT__last_rid__v0 
                        = vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i;
                    __VdlySet__axi4_xbar_tb__DOT__last_rid__v0 = 1U;
                }
            }
        }
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                    >> 0x00000010U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                       >> 4U)))) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i 
                = (0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                  >> 0x0000000cU));
            vlSelfRef.axi4_xbar_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi4_xbar_tb__DOT__checks);
            if (VL_LTES_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why 
                    = VL_SFORMATF_N_NX("master 0: B with id %0d outside the issued set",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else if ((vlSelfRef.axi4_xbar_tb__DOT__wq_head[0U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                        == vlSelfRef.axi4_xbar_tb__DOT__wq_tail[0U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)])) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why 
                    = VL_SFORMATF_N_NX("master 0 id %0d: B with no outstanding write",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else {
                if (vlSelfRef.axi4_xbar_tb__DOT__wq_dec[0U]
                    [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                    [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__wq_head[0U]
                                                   [
                                                   (3U 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                    if ((3U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                      >> 0x0000000aU)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why 
                            = VL_SFORMATF_N_NX("master 0 id %0d: unmapped write returned resp=%0b, expected DECERR (D2)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                     >> 0x0000000aU))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                    vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec);
                } else {
                    if ((0U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                      >> 0x0000000aU)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why 
                            = VL_SFORMATF_N_NX("master 0 id %0d: mapped write returned resp=%0b",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                     >> 0x0000000aU))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                    vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok);
                }
                __VdlyVal__axi4_xbar_tb__DOT__wq_head__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__wq_head[0U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v0 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                __VdlySet__axi4_xbar_tb__DOT__wq_head__v0 = 1U;
            }
        }
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i = 0U;
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                    >> 0x0000001cU) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                       >> 0x00000019U)))) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i 
                = (0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                                  >> 0x00000018U));
            vlSelfRef.axi4_xbar_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi4_xbar_tb__DOT__checks);
            if (VL_LTES_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why 
                    = VL_SFORMATF_N_NX("master 1: R with id %0d outside the issued set",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else if ((vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                        == vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)])) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why 
                    = VL_SFORMATF_N_NX("master 1 id %0d: R beat with no outstanding read",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else {
                if (vlSelfRef.axi4_xbar_tb__DOT__rq_dec[1U]
                    [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                    [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                                                   [
                                                   (3U 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                    if ((3U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                      >> 0x00000016U)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why 
                            = VL_SFORMATF_N_NX("master 1 id %0d: unmapped read returned resp=%0b, expected DECERR (D2)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                     >> 0x00000016U))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                } else {
                    if ((0U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                      >> 0x00000016U)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why 
                            = VL_SFORMATF_N_NX("master 1 id %0d: mapped read returned resp=%0b",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                     >> 0x00000016U))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                    if (((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U])) 
                           << 0x00000028U) | (((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U])) 
                                               << 8U) 
                                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U])) 
                                                 >> 0x00000018U))) 
                         != ([&]() {
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat 
                                        = vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)];
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a 
                                        = vlSelfRef.axi4_xbar_tb__DOT__rq_addr[1U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                        [(0x0000003fU 
                                          & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                                                           [
                                                           (3U 
                                                            & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))];
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout 
                                        = ((QData)((IData)(
                                                           (0xfffffff0U 
                                                            & __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a))) 
                                           + (0x0100000000000001ULL 
                                              * VL_EXTENDS_QI(64,32, __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat)));
                                }(), __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why 
                            = VL_SFORMATF_N_NX("master 1 id %0d beat %0d: data=0x%0x expected 0x%0x (D1/O1)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U]
                                               [(3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)],
                                               64,(
                                                   ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U])) 
                                                    << 0x00000028U) 
                                                   | (((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U])) 
                                                       << 8U) 
                                                      | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U])) 
                                                         >> 0x00000018U))),
                                               64,([&]() {
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat 
                                            = vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U]
                                            [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)];
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a 
                                            = vlSelfRef.axi4_xbar_tb__DOT__rq_addr[1U]
                                            [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                            [(0x0000003fU 
                                              & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                                                               [
                                                               (3U 
                                                                & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))];
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout 
                                            = ((QData)((IData)(
                                                               (0xfffffff0U 
                                                                & __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a))) 
                                               + (0x0100000000000001ULL 
                                                  * 
                                                  VL_EXTENDS_QI(64,32, __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat)));
                                    }(), __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout)) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                }
                if (((1U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                            >> 0x00000015U)) != (vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U]
                                                 [(3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__rq_len[1U]
                                                 [(3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                                 [(0x0000003fU 
                                                   & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                                                                    [
                                                                    (3U 
                                                                     & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]))) {
                    vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why 
                        = VL_SFORMATF_N_NX("master 1 id %0d: RLAST on beat %0d of a %0d-beat burst (O4/D2)",0,
                                           32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                           32,vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U]
                                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)],
                                           32,((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__rq_len[1U]
                                               [(3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                               [(0x0000003fU 
                                                 & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                                                                  [
                                                                  (3U 
                                                                   & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))])) ;
                    vlSelfRef.axi4_xbar_tb__DOT__errors 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                    if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                        vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                            = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why;
                    }
                    if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                        VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                     64,VL_TIME_UNITED_Q(1000),
                                     -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                     -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why));
                    } else if (VL_UNLIKELY(((0x00000015U 
                                             == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                        VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                    }
                }
                if ((0x00200000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U])) {
                    if (vlSelfRef.axi4_xbar_tb__DOT__rq_dec[1U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                        [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                                                       [
                                                       (3U 
                                                        & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec);
                    } else {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok);
                    }
                    if (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__rq_len[1U]
                                   [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                   [(0x0000003fU & 
                                     VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))])) {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1);
                    }
                    __VdlyVal__axi4_xbar_tb__DOT__rq_head__v1 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U]
                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v1 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                    __VdlySet__axi4_xbar_tb__DOT__rq_head__v1 = 1U;
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v2 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v3 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U]
                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v3 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v3 = 1U;
                }
                if ((vlSelfRef.axi4_xbar_tb__DOT__last_rid[1U] 
                     != vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id);
                    __VdlyVal__axi4_xbar_tb__DOT__last_rid__v1 
                        = vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i;
                    __VdlySet__axi4_xbar_tb__DOT__last_rid__v1 = 1U;
                }
            }
        }
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                    >> 4U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                              >> 0x0000001dU)))) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i 
                = (0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]);
            vlSelfRef.axi4_xbar_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi4_xbar_tb__DOT__checks);
            if (VL_LTES_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why 
                    = VL_SFORMATF_N_NX("master 1: B with id %0d outside the issued set",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else if ((vlSelfRef.axi4_xbar_tb__DOT__wq_head[1U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                        == vlSelfRef.axi4_xbar_tb__DOT__wq_tail[1U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)])) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why 
                    = VL_SFORMATF_N_NX("master 1 id %0d: B with no outstanding write",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else {
                if (vlSelfRef.axi4_xbar_tb__DOT__wq_dec[1U]
                    [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                    [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__wq_head[1U]
                                                   [
                                                   (3U 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec);
                    if ((3U != (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                                >> 0x0000001eU))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why 
                            = VL_SFORMATF_N_NX("master 1 id %0d: unmapped write returned resp=%0b, expected DECERR (D2)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                                                  >> 0x0000001eU)) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                } else {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok);
                    if ((0U != (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                                >> 0x0000001eU))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why 
                            = VL_SFORMATF_N_NX("master 1 id %0d: mapped write returned resp=%0b",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                                                  >> 0x0000001eU)) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                }
                __VdlyVal__axi4_xbar_tb__DOT__wq_head__v1 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__wq_head[1U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v1 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                __VdlySet__axi4_xbar_tb__DOT__wq_head__v1 = 1U;
            }
        }
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i = 0U;
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                    >> 0x00000010U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                       >> 0x00000012U)))) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i 
                = (0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                  >> 0x0000000cU));
            vlSelfRef.axi4_xbar_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi4_xbar_tb__DOT__checks);
            if (VL_LTES_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why 
                    = VL_SFORMATF_N_NX("master 2: R with id %0d outside the issued set",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else if ((vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                        == vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)])) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why 
                    = VL_SFORMATF_N_NX("master 2 id %0d: R beat with no outstanding read",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else {
                if (vlSelfRef.axi4_xbar_tb__DOT__rq_dec[2U]
                    [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                    [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                                                   [
                                                   (3U 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                    if ((3U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                      >> 0x0000000aU)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why 
                            = VL_SFORMATF_N_NX("master 2 id %0d: unmapped read returned resp=%0b, expected DECERR (D2)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                                     >> 0x0000000aU))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                } else {
                    if ((0U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                      >> 0x0000000aU)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why 
                            = VL_SFORMATF_N_NX("master 2 id %0d: mapped read returned resp=%0b",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                                     >> 0x0000000aU))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                    if (((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U])) 
                           << 0x00000034U) | (((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U])) 
                                               << 0x00000014U) 
                                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U])) 
                                                 >> 0x0000000cU))) 
                         != ([&]() {
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat 
                                        = vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)];
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a 
                                        = vlSelfRef.axi4_xbar_tb__DOT__rq_addr[2U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                        [(0x0000003fU 
                                          & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                                                           [
                                                           (3U 
                                                            & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))];
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout 
                                        = ((QData)((IData)(
                                                           (0xfffffff0U 
                                                            & __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a))) 
                                           + (0x0100000000000001ULL 
                                              * VL_EXTENDS_QI(64,32, __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat)));
                                }(), __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why 
                            = VL_SFORMATF_N_NX("master 2 id %0d beat %0d: data=0x%0x expected 0x%0x (D1/O1)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U]
                                               [(3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)],
                                               64,(
                                                   ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U])) 
                                                    << 0x00000034U) 
                                                   | (((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U])) 
                                                       << 0x00000014U) 
                                                      | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U])) 
                                                         >> 0x0000000cU))),
                                               64,([&]() {
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat 
                                            = vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U]
                                            [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)];
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a 
                                            = vlSelfRef.axi4_xbar_tb__DOT__rq_addr[2U]
                                            [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                            [(0x0000003fU 
                                              & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                                                               [
                                                               (3U 
                                                                & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))];
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout 
                                            = ((QData)((IData)(
                                                               (0xfffffff0U 
                                                                & __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a))) 
                                               + (0x0100000000000001ULL 
                                                  * 
                                                  VL_EXTENDS_QI(64,32, __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat)));
                                    }(), __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout)) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                }
                if (((1U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                            >> 9U)) != (vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                                        == vlSelfRef.axi4_xbar_tb__DOT__rq_len[2U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                        [(0x0000003fU 
                                          & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                                                           [
                                                           (3U 
                                                            & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]))) {
                    vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why 
                        = VL_SFORMATF_N_NX("master 2 id %0d: RLAST on beat %0d of a %0d-beat burst (O4/D2)",0,
                                           32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                           32,vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U]
                                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)],
                                           32,((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__rq_len[2U]
                                               [(3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                               [(0x0000003fU 
                                                 & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                                                                  [
                                                                  (3U 
                                                                   & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))])) ;
                    vlSelfRef.axi4_xbar_tb__DOT__errors 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                    if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                        vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                            = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why;
                    }
                    if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                        VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                     64,VL_TIME_UNITED_Q(1000),
                                     -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                     -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why));
                    } else if (VL_UNLIKELY(((0x00000015U 
                                             == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                        VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                    }
                }
                if ((0x00000200U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U])) {
                    if (vlSelfRef.axi4_xbar_tb__DOT__rq_dec[2U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                        [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                                                       [
                                                       (3U 
                                                        & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec);
                    } else {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok);
                    }
                    if (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__rq_len[2U]
                                   [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                   [(0x0000003fU & 
                                     VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))])) {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1);
                    }
                    __VdlyVal__axi4_xbar_tb__DOT__rq_head__v2 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U]
                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v2 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                    __VdlySet__axi4_xbar_tb__DOT__rq_head__v2 = 1U;
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v4 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v5 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U]
                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v5 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v5 = 1U;
                }
                if ((vlSelfRef.axi4_xbar_tb__DOT__last_rid[2U] 
                     != vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id);
                    __VdlyVal__axi4_xbar_tb__DOT__last_rid__v2 
                        = vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i;
                    __VdlySet__axi4_xbar_tb__DOT__last_rid__v2 = 1U;
                }
            }
        }
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                    >> 0x00000018U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                       >> 0x00000016U)))) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i 
                = (0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                  >> 0x00000014U));
            vlSelfRef.axi4_xbar_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi4_xbar_tb__DOT__checks);
            if (VL_LTES_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why 
                    = VL_SFORMATF_N_NX("master 2: B with id %0d outside the issued set",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else if ((vlSelfRef.axi4_xbar_tb__DOT__wq_head[2U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                        == vlSelfRef.axi4_xbar_tb__DOT__wq_tail[2U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)])) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why 
                    = VL_SFORMATF_N_NX("master 2 id %0d: B with no outstanding write",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else {
                if (vlSelfRef.axi4_xbar_tb__DOT__wq_dec[2U]
                    [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                    [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__wq_head[2U]
                                                   [
                                                   (3U 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec);
                    if ((3U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                      >> 0x00000012U)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why 
                            = VL_SFORMATF_N_NX("master 2 id %0d: unmapped write returned resp=%0b, expected DECERR (D2)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                     >> 0x00000012U))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                } else {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok);
                    if ((0U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                      >> 0x00000012U)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why 
                            = VL_SFORMATF_N_NX("master 2 id %0d: mapped write returned resp=%0b",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                     >> 0x00000012U))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                }
                __VdlyVal__axi4_xbar_tb__DOT__wq_head__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__wq_head[2U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v2 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                __VdlySet__axi4_xbar_tb__DOT__wq_head__v2 = 1U;
            }
        }
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i = 0U;
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                    >> 4U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                              >> 0x0000000bU)))) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i 
                = (0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]);
            vlSelfRef.axi4_xbar_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi4_xbar_tb__DOT__checks);
            if (VL_LTES_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why 
                    = VL_SFORMATF_N_NX("master 3: R with id %0d outside the issued set",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__12__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else if ((vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                        == vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)])) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why 
                    = VL_SFORMATF_N_NX("master 3 id %0d: R beat with no outstanding read",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__13__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else {
                if (vlSelfRef.axi4_xbar_tb__DOT__rq_dec[3U]
                    [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                    [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                                                   [
                                                   (3U 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                    if ((3U != (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                >> 0x0000001eU))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why 
                            = VL_SFORMATF_N_NX("master 3 id %0d: unmapped read returned resp=%0b, expected DECERR (D2)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                  >> 0x0000001eU)) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__14__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                } else {
                    if ((0U != (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                >> 0x0000001eU))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why 
                            = VL_SFORMATF_N_NX("master 3 id %0d: mapped read returned resp=%0b",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                  >> 0x0000001eU)) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__15__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                    if (((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U])) 
                           << 0x00000020U) | (QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U]))) 
                         != ([&]() {
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat 
                                        = vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)];
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a 
                                        = vlSelfRef.axi4_xbar_tb__DOT__rq_addr[3U]
                                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                        [(0x0000003fU 
                                          & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                                                           [
                                                           (3U 
                                                            & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))];
                                    __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout 
                                        = ((QData)((IData)(
                                                           (0xfffffff0U 
                                                            & __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__a))) 
                                           + (0x0100000000000001ULL 
                                              * VL_EXTENDS_QI(64,32, __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__beat)));
                                }(), __Vfunc_axi4_xbar_tb__DOT__expected_beat__16__Vfuncout))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why 
                            = VL_SFORMATF_N_NX("master 3 id %0d beat %0d: data=0x%0x expected 0x%0x (D1/O1)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U]
                                               [(3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)],
                                               64,(
                                                   ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U])) 
                                                    << 0x00000020U) 
                                                   | (QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U]))),
                                               64,([&]() {
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat 
                                            = vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U]
                                            [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)];
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a 
                                            = vlSelfRef.axi4_xbar_tb__DOT__rq_addr[3U]
                                            [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                            [(0x0000003fU 
                                              & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                                                               [
                                                               (3U 
                                                                & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))];
                                        __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout 
                                            = ((QData)((IData)(
                                                               (0xfffffff0U 
                                                                & __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__a))) 
                                               + (0x0100000000000001ULL 
                                                  * 
                                                  VL_EXTENDS_QI(64,32, __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__beat)));
                                    }(), __Vfunc_axi4_xbar_tb__DOT__expected_beat__18__Vfuncout)) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__17__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                }
                if (((1U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                            >> 0x0000001dU)) != (vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U]
                                                 [(3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__rq_len[3U]
                                                 [(3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                                 [(0x0000003fU 
                                                   & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                                                                    [
                                                                    (3U 
                                                                     & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]))) {
                    vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why 
                        = VL_SFORMATF_N_NX("master 3 id %0d: RLAST on beat %0d of a %0d-beat burst (O4/D2)",0,
                                           32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                           32,vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U]
                                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)],
                                           32,((IData)(1U) 
                                               + vlSelfRef.axi4_xbar_tb__DOT__rq_len[3U]
                                               [(3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                               [(0x0000003fU 
                                                 & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                                                                  [
                                                                  (3U 
                                                                   & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))])) ;
                    vlSelfRef.axi4_xbar_tb__DOT__errors 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                    if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                        vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                            = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why;
                    }
                    if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                        VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                     64,VL_TIME_UNITED_Q(1000),
                                     -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                     -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__19__why));
                    } else if (VL_UNLIKELY(((0x00000015U 
                                             == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                        VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                    }
                }
                if ((0x20000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U])) {
                    if (vlSelfRef.axi4_xbar_tb__DOT__rq_dec[3U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                        [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                                                       [
                                                       (3U 
                                                        & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec);
                    } else {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok);
                    }
                    if (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__rq_len[3U]
                                   [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                                   [(0x0000003fU & 
                                     VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))])) {
                        vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1);
                    }
                    __VdlyVal__axi4_xbar_tb__DOT__rq_head__v3 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U]
                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_head__v3 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                    __VdlySet__axi4_xbar_tb__DOT__rq_head__v3 = 1U;
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v6 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v7 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U]
                           [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                    __VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v7 
                        = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                    __VdlySet__axi4_xbar_tb__DOT__rq_beat__v7 = 1U;
                }
                if ((vlSelfRef.axi4_xbar_tb__DOT__last_rid[3U] 
                     != vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id);
                    __VdlyVal__axi4_xbar_tb__DOT__last_rid__v3 
                        = vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i;
                    __VdlySet__axi4_xbar_tb__DOT__last_rid__v3 = 1U;
                }
            }
        }
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                    >> 0x0000000cU) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                       >> 0x0000000fU)))) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i 
                = (0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                  >> 8U));
            vlSelfRef.axi4_xbar_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi4_xbar_tb__DOT__checks);
            if (VL_LTES_III(32, 4U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why 
                    = VL_SFORMATF_N_NX("master 3: B with id %0d outside the issued set",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__20__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else if ((vlSelfRef.axi4_xbar_tb__DOT__wq_head[3U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)] 
                        == vlSelfRef.axi4_xbar_tb__DOT__wq_tail[3U]
                        [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)])) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why 
                    = VL_SFORMATF_N_NX("master 3 id %0d: B with no outstanding write",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__21__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            } else {
                if (vlSelfRef.axi4_xbar_tb__DOT__wq_dec[3U]
                    [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]
                    [(0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__wq_head[3U]
                                                   [
                                                   (3U 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)], (IData)(0x00000040U)))]) {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec);
                    if ((3U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                      >> 6U)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why 
                            = VL_SFORMATF_N_NX("master 3 id %0d: unmapped write returned resp=%0b, expected DECERR (D2)",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                                     >> 6U))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__22__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                } else {
                    vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok 
                        = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok);
                    if ((0U != (3U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                      >> 6U)))) {
                        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why 
                            = VL_SFORMATF_N_NX("master 3 id %0d: mapped write returned resp=%0b",0,
                                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i,
                                               2,(3U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                                     >> 6U))) ;
                        vlSelfRef.axi4_xbar_tb__DOT__errors 
                            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                        if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                            vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                                = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why;
                        }
                        if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                         64,VL_TIME_UNITED_Q(1000),
                                         -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                         -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__23__why));
                        } else if (VL_UNLIKELY(((0x00000015U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                            VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                        }
                    }
                }
                __VdlyVal__axi4_xbar_tb__DOT__wq_head__v3 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__wq_head[3U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i)]);
                __VdlyDim0__axi4_xbar_tb__DOT__wq_head__v3 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i);
                __VdlySet__axi4_xbar_tb__DOT__wq_head__v3 = 1U;
            }
        }
    }
    if (vlSelfRef.axi4_xbar_tb__DOT__rst_n) {
        if ((2U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))) {
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] 
                        >> 0x0000000aU) & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]))) {
                __VdlyVal__axi4_xbar_tb__DOT__pq_hd__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U]);
                __VdlySet__axi4_xbar_tb__DOT__pq_hd__v0 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] 
                        >> 2U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
                                  >> 0x0000001dU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__pq_hd__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U]);
                __VdlySet__axi4_xbar_tb__DOT__pq_hd__v2 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
                        >> 1U) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] 
                                  >> 0x00000016U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__pq_id__v0 
                    = (0x0000003fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]);
                __VdlyDim0__axi4_xbar_tb__DOT__pq_id__v0 
                    = (0x0000001fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U], (IData)(0x00000020U)));
                __VdlySet__axi4_xbar_tb__DOT__pq_id__v0 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__pq_adr__v0 
                    = vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[1U];
                __VdlyDim0__axi4_xbar_tb__DOT__pq_adr__v0 
                    = (0x0000001fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U], (IData)(0x00000020U)));
                __VdlyVal__axi4_xbar_tb__DOT__pq_tl__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U]);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
                        >> 0x0000001eU) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] 
                                           >> 0x0000000eU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__pq_id__v1 
                    = (0x0000003fU & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
                                       << 3U) | (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
                                                 >> 0x0000001dU)));
                __VdlyDim0__axi4_xbar_tb__DOT__pq_id__v1 
                    = (0x0000001fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U], (IData)(0x00000020U)));
                __VdlySet__axi4_xbar_tb__DOT__pq_id__v1 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__pq_adr__v1 
                    = ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
                        << 3U) | (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
                                  >> 0x0000001dU));
                __VdlyDim0__axi4_xbar_tb__DOT__pq_adr__v1 
                    = (0x0000001fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U], (IData)(0x00000020U)));
                __VdlyVal__axi4_xbar_tb__DOT__pq_tl__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U]);
            }
        }
    } else {
        __VdlySet__axi4_xbar_tb__DOT__pq_hd__v1 = 1U;
        __VdlySet__axi4_xbar_tb__DOT__pq_hd__v3 = 1U;
        __VdlySet__axi4_xbar_tb__DOT__pq_tl__v1 = 1U;
        __VdlySet__axi4_xbar_tb__DOT__pq_tl__v3 = 1U;
    }
    if (vlSelfRef.axi4_xbar_tb__DOT__rst_n) {
        if ((((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
               >> 1U) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] 
                         >> 0x00000016U)) & (0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)))) {
            __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v0 
                = ((IData)(1U) + (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
                                  >> 0x00000018U));
            __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v0 = 1U;
            __VdlyVal__axi4_xbar_tb__DOT__s_rn__v0 
                = ((IData)(1U) + (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
                                  >> 0x00000018U));
            __VdlyVal__axi4_xbar_tb__DOT__s_rid__v0 
                = (0x0000003fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]);
            __VdlyVal__axi4_xbar_tb__DOT__s_raddr__v0 
                = vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[1U];
            __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v0 
                = ((0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                    ? 0U : 0U);
        } else if (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[0U])) {
            __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v1 
                = (vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[0U] 
                   - (IData)(1U));
            __VdlySet__axi4_xbar_tb__DOT__s_rdelay__v1 = 1U;
        } else if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] 
                           >> 0x0000000aU) & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]))) {
            __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v1 
                = (vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U] 
                   - (IData)(1U));
            __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v1 = 1U;
            __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v2 
                = ((0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                    ? 0U : 0U);
        }
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
                    >> 0x00000012U) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] 
                                       >> 0x00000017U)))) {
            __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v0 
                = ((IData)(1U) + (0x000000ffU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
                                                 >> 0x0000000fU)));
            __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v0 = 1U;
            __VdlyVal__axi4_xbar_tb__DOT__s_wid__v0 
                = (0x0000003fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
                                  >> 0x00000017U));
            __VdlyVal__axi4_xbar_tb__DOT__s_w_inflight__v0 
                = (0x0000003fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
                                  >> 0x00000017U));
        }
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
                    >> 7U) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] 
                              >> 0x00000015U)))) {
            if (((0U == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U]) 
                 & (0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)))) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__6__why = "slave 0: W beat with no AW outstanding (O3)"s;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__6__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__6__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            }
            if ((((1U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
                         >> 9U)) != (1U == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U])) 
                 & (0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)))) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__7__why 
                    = VL_SFORMATF_N_NX("slave 0: WLAST on beat %0d of a %0d-beat write (O3)",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U],
                                       32,vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U]) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__7__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__7__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            }
            __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v1 
                = (vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U] 
                   - (IData)(1U));
            __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v1 = 1U;
            if ((1U == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U])) {
                __VdlySet__axi4_xbar_tb__DOT__s_bpend__v0 = 1U;
            }
        }
        if ((vlSelfRef.axi4_xbar_tb__DOT__s_bpend[0U] 
             & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
                >> 6U))) {
            __VdlySet__axi4_xbar_tb__DOT__s_bpend__v1 = 1U;
        }
    } else {
        __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v2 = 1U;
    }
    if (vlSelfRef.axi4_xbar_tb__DOT__rst_n) {
        if ((((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
               >> 0x0000001eU) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] 
                                  >> 0x0000000eU)) 
             & (0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)))) {
            __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v3 
                = ((IData)(1U) + (0x000000ffU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
                                                 >> 0x00000015U)));
            __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v3 = 1U;
            __VdlyVal__axi4_xbar_tb__DOT__s_rn__v1 
                = ((IData)(1U) + (0x000000ffU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
                                                 >> 0x00000015U)));
            __VdlyVal__axi4_xbar_tb__DOT__s_rid__v1 
                = (0x0000003fU & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
                                   << 3U) | (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
                                             >> 0x0000001dU)));
            __VdlyVal__axi4_xbar_tb__DOT__s_raddr__v1 
                = ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
                    << 3U) | (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
                              >> 0x0000001dU));
            __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v4 
                = ((0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                    ? 4U : 0U);
        } else if (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[1U])) {
            __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v5 
                = (vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[1U] 
                   - (IData)(1U));
            __VdlySet__axi4_xbar_tb__DOT__s_rdelay__v5 = 1U;
        } else if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] 
                           >> 2U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
                                     >> 0x0000001dU)))) {
            __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v4 
                = (vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U] 
                   - (IData)(1U));
            __VdlySet__axi4_xbar_tb__DOT__s_rbeats__v4 = 1U;
            __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v6 
                = ((0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                    ? 4U : 0U);
        }
        if ((0x00008000U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
                            & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]))) {
            __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v3 
                = ((IData)(1U) + (0x000000ffU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
                                                 >> 0x0000000cU)));
            __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v3 = 1U;
            __VdlyVal__axi4_xbar_tb__DOT__s_wid__v1 
                = (0x0000003fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] 
                                  >> 0x00000014U));
            __VdlyVal__axi4_xbar_tb__DOT__s_w_inflight__v2 
                = (0x0000003fU & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] 
                                  >> 0x00000014U));
        }
        if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
                    >> 4U) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] 
                              >> 0x0000000dU)))) {
            if (((0U == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U]) 
                 & (0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)))) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__10__why = "slave 1: W beat with no AW outstanding (O3)"s;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__10__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__10__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            }
            if ((((1U & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
                         >> 6U)) != (1U == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U])) 
                 & (0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)))) {
                vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__11__why 
                    = VL_SFORMATF_N_NX("slave 1: WLAST on beat %0d of a %0d-beat write (O3)",0,
                                       32,vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U],
                                       32,vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U]) ;
                vlSelfRef.axi4_xbar_tb__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__errors);
                if ((""s == vlSelfRef.axi4_xbar_tb__DOT__fail_reason)) {
                    vlSelfRef.axi4_xbar_tb__DOT__fail_reason 
                        = vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__11__why;
                }
                if (VL_UNLIKELY((VL_GTES_III(32, 0x00000014U, vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] t=%0t phase=%@ : %@\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,-1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                                 -1,&(vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__11__why));
                } else if (VL_UNLIKELY(((0x00000015U 
                                         == vlSelfRef.axi4_xbar_tb__DOT__errors)))) {
                    VL_WRITEF_NX("[FAIL] ... further failures suppressed\n",0);
                }
            }
            __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v4 
                = (vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U] 
                   - (IData)(1U));
            __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v4 = 1U;
            if ((1U == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U])) {
                __VdlySet__axi4_xbar_tb__DOT__s_bpend__v3 = 1U;
            }
        }
        if ((vlSelfRef.axi4_xbar_tb__DOT__s_bpend[1U] 
             & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
                >> 3U))) {
            __VdlySet__axi4_xbar_tb__DOT__s_bpend__v4 = 1U;
        }
    } else {
        __VdlySet__axi4_xbar_tb__DOT__s_wbeats__v5 = 1U;
    }
    if (vlSelfRef.axi4_xbar_tb__DOT__rst_n) {
        __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v0 = 
            ((0x0000fffeU & (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U] 
                             << 1U)) | (1U & ((((vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U] 
                                                 >> 0x0fU) 
                                                ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U] 
                                                   >> 0x0dU)) 
                                               ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U] 
                                                  >> 0x0cU)) 
                                              ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U] 
                                                 >> 0x0aU))));
        __VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v0 = 1U;
        __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v1 = 
            ((0x0000fffeU & (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U] 
                             << 1U)) | (1U & ((((vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U] 
                                                 >> 0x0fU) 
                                                ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U] 
                                                   >> 0x0dU)) 
                                               ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U] 
                                                  >> 0x0cU)) 
                                              ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U] 
                                                 >> 0x0aU))));
        __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v2 = 
            ((0x0000fffeU & (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U] 
                             << 1U)) | (1U & ((((vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U] 
                                                 >> 0x0fU) 
                                                ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U] 
                                                   >> 0x0dU)) 
                                               ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U] 
                                                  >> 0x0cU)) 
                                              ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U] 
                                                 >> 0x0aU))));
        __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v3 = 
            ((0x0000fffeU & (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U] 
                             << 1U)) | (1U & ((((vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U] 
                                                 >> 0x0fU) 
                                                ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U] 
                                                   >> 0x0dU)) 
                                               ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U] 
                                                  >> 0x0cU)) 
                                              ^ (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U] 
                                                 >> 0x0aU))));
    } else {
        __VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v4 = 1U;
    }
    if (vlSelfRef.axi4_xbar_tb__DOT__rst_n) {
        if ((0U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))) {
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
                        >> 1U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                  >> 0x00000012U)))) {
                if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U], vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)) {
                    __Vdly__axi4_xbar_tb__DOT__cov_max_len 
                        = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U];
                }
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U]);
                __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v0 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__txn_sent[0U]);
                __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v0 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v0 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v0 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U]);
                __Vdly__axi4_xbar_tb__DOT__ar_hold 
                    = (0x0eU & (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
                __VdlyVal__axi4_xbar_tb__DOT__rq_len__v0 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v0 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v0 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U]);
                __VdlySet__axi4_xbar_tb__DOT__rq_len__v0 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v0 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[0U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v0 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v0 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U]);
                __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U])]);
                __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v0 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U]);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                        >> 0x00000010U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                           >> 0x00000013U)))) {
                if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U], vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)) {
                    __Vdly__axi4_xbar_tb__DOT__cov_max_len 
                        = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U];
                }
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U]);
                __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v0 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v1 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__txn_sent[0U]);
                __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v0 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[0U];
                __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v0 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__wq_tail[0U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v0 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U]);
                __Vdly__axi4_xbar_tb__DOT__aw_hold 
                    = (0x0eU & (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
                __VdlyVal__axi4_xbar_tb__DOT__w_left__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]);
                __VdlySet__axi4_xbar_tb__DOT__w_left__v0 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__w_addr__v0 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U];
                __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v0 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__wq_tail[0U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U])]);
                __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v0 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U]);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                        >> 5U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                  >> 0x00000011U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__w_left__v1 
                    = (vlSelfRef.axi4_xbar_tb__DOT__w_left[0U] 
                       - (IData)(1U));
                __VdlySet__axi4_xbar_tb__DOT__w_left__v1 = 1U;
            }
            if ((1U & (((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                         >> 8U) & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
                       & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
                          >> 1U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v1 
                    = ((vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U] 
                        - (IData)(1U)) + ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
                                                  >> 1U) 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                    >> 0x00000012U)))
                                           ? 1U : 0U));
                __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v1 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                        >> 0x00000010U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                           >> 4U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v1 
                    = ((vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U] 
                        - (IData)(1U)) + ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                                  >> 0x00000010U) 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                    >> 0x00000013U)))
                                           ? 1U : 0U));
                __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v1 = 1U;
            }
            if (((((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold)) 
                     & (~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold))) 
                    & (0U == vlSelfRef.axi4_xbar_tb__DOT__w_left[0U])) 
                   & VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[0U])) 
                  & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U])) 
                 & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r 
                    = VL_URANDOM_RANGE_I(0U, 0x00000063U);
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw 
                    = VL_URANDOM_RANGE_I(0U, 0x00000063U);
                __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v0 
                    = (0x0000000fU & VL_URANDOM_RANGE_I(0U, 3U));
                __VdlySet__axi4_xbar_tb__DOT__nxt_id__v0 = 1U;
                if ((0U == VL_URANDOM_RANGE_I(0U, 3U))) {
                    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v0 = 1U;
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v1 
                        = VL_URANDOM_RANGE_I(0U, 3U);
                    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v1 = 1U;
                }
                if (VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r)) {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v0 
                        = ((IData)(0x80000000U) + (IData)(
                                                          VL_SHIFTL_III(32,32,32, (IData)(
                                                                                VL_URANDOM_RANGE_I(0U, 0x000000ffU)), 3U)));
                    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v0 = 1U;
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v1 
                        = ((IData)(VL_SHIFTL_III(32,32,32, (IData)(
                                                                   VL_URANDOM_RANGE_I(0U, 1U)), 0x00000010U)) 
                           + (IData)(VL_SHIFTL_III(32,32,32, (IData)(
                                                                     VL_URANDOM_RANGE_I(0U, 0x000003ffU)), 3U)));
                    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v1 = 1U;
                }
                if (VL_GTS_III(32, 0x00000032U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw)) {
                    __Vdly__axi4_xbar_tb__DOT__ar_hold 
                        = (1U | (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
                } else {
                    __Vdly__axi4_xbar_tb__DOT__aw_hold 
                        = (1U | (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
                }
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                        >> 0x0000001aU) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                           >> 6U)))) {
                if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U], vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)) {
                    __Vdly__axi4_xbar_tb__DOT__cov_max_len 
                        = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U];
                }
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U]);
                __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v2 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__txn_sent[1U]);
                __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v1 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v1 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v1 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U]);
                __Vdly__axi4_xbar_tb__DOT__ar_hold 
                    = (0x0dU & (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
                __VdlyVal__axi4_xbar_tb__DOT__rq_len__v1 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v1 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v1 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U]);
                __VdlySet__axi4_xbar_tb__DOT__rq_len__v1 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v1 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[1U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v1 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v1 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U]);
                __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v1 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U])]);
                __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v1 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U]);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                        >> 9U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                  >> 7U)))) {
                if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U], vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)) {
                    __Vdly__axi4_xbar_tb__DOT__cov_max_len 
                        = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U];
                }
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U]);
                __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v2 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v3 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__txn_sent[1U]);
                __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v1 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[1U];
                __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v1 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__wq_tail[1U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v1 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U]);
                __Vdly__axi4_xbar_tb__DOT__aw_hold 
                    = (0x0dU & (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
                __VdlyVal__axi4_xbar_tb__DOT__w_left__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]);
                __VdlySet__axi4_xbar_tb__DOT__w_left__v2 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__w_addr__v1 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U];
                __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v1 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__wq_tail[1U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U])]);
                __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v1 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U]);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                        >> 0x0000001eU) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                           >> 5U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__w_left__v3 
                    = (vlSelfRef.axi4_xbar_tb__DOT__w_left[1U] 
                       - (IData)(1U));
                __VdlySet__axi4_xbar_tb__DOT__w_left__v3 = 1U;
            }
            if ((1U & (((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
                         >> 0x0000001cU) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                            >> 0x00000019U)) 
                       & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                          >> 0x00000015U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v3 
                    = ((vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U] 
                        - (IData)(1U)) + ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                                  >> 0x0000001aU) 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                                    >> 6U)))
                                           ? 1U : 0U));
                __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v3 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                        >> 4U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                  >> 0x0000001dU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v3 
                    = ((vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U] 
                        - (IData)(1U)) + ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                                                  >> 9U) 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                                    >> 7U)))
                                           ? 1U : 0U));
                __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v3 = 1U;
            }
            if (((((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                         >> 1U)) & (~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                                       >> 1U))) & (0U 
                                                   == vlSelfRef.axi4_xbar_tb__DOT__w_left[1U])) 
                   & VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[1U])) 
                  & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U])) 
                 & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r 
                    = VL_URANDOM_RANGE_I(0U, 0x00000063U);
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw 
                    = VL_URANDOM_RANGE_I(0U, 0x00000063U);
                __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v1 
                    = (0x0000000fU & VL_URANDOM_RANGE_I(0U, 3U));
                __VdlySet__axi4_xbar_tb__DOT__nxt_id__v1 = 1U;
                if ((0U == VL_URANDOM_RANGE_I(0U, 3U))) {
                    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v2 = 1U;
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v3 
                        = VL_URANDOM_RANGE_I(0U, 3U);
                    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v3 = 1U;
                }
                if (VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r)) {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v2 
                        = ((IData)(0x80000000U) + (IData)(
                                                          VL_SHIFTL_III(32,32,32, (IData)(
                                                                                VL_URANDOM_RANGE_I(0U, 0x000000ffU)), 3U)));
                    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v2 = 1U;
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v3 
                        = ((IData)(VL_SHIFTL_III(32,32,32, (IData)(
                                                                   VL_URANDOM_RANGE_I(0U, 1U)), 0x00000010U)) 
                           + (IData)(VL_SHIFTL_III(32,32,32, (IData)(
                                                                     VL_URANDOM_RANGE_I(0U, 0x000003ffU)), 3U)));
                    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v3 = 1U;
                }
                if (VL_GTS_III(32, 0x00000032U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw)) {
                    __Vdly__axi4_xbar_tb__DOT__ar_hold 
                        = (2U | (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
                } else {
                    __Vdly__axi4_xbar_tb__DOT__aw_hold 
                        = (2U | (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
                }
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                        >> 0x00000013U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                           >> 0x0000001aU)))) {
                if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U], vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)) {
                    __Vdly__axi4_xbar_tb__DOT__cov_max_len 
                        = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U];
                }
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v4 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U]);
                __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v4 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v4 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__txn_sent[2U]);
                __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v2 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v2 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v2 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U]);
                __Vdly__axi4_xbar_tb__DOT__ar_hold 
                    = (0x0bU & (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
                __VdlyVal__axi4_xbar_tb__DOT__rq_len__v2 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v2 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v2 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U]);
                __VdlySet__axi4_xbar_tb__DOT__rq_len__v2 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v2 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[2U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v2 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v2 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U]);
                __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U])]);
                __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v2 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U]);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                        >> 2U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                  >> 0x0000001bU)))) {
                if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U], vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)) {
                    __Vdly__axi4_xbar_tb__DOT__cov_max_len 
                        = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U];
                }
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v4 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U]);
                __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v4 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v5 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__txn_sent[2U]);
                __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v2 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[2U];
                __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v2 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__wq_tail[2U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v2 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U]);
                __Vdly__axi4_xbar_tb__DOT__aw_hold 
                    = (0x0bU & (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
                __VdlyVal__axi4_xbar_tb__DOT__w_left__v4 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]);
                __VdlySet__axi4_xbar_tb__DOT__w_left__v4 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__w_addr__v2 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U];
                __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v2 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__wq_tail[2U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U])]);
                __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v2 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U]);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                        >> 0x00000017U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                           >> 0x00000019U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__w_left__v5 
                    = (vlSelfRef.axi4_xbar_tb__DOT__w_left[2U] 
                       - (IData)(1U));
                __VdlySet__axi4_xbar_tb__DOT__w_left__v5 = 1U;
            }
            if ((1U & (((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                         >> 0x00000010U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                            >> 0x00000012U)) 
                       & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                          >> 9U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v5 
                    = ((vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U] 
                        - (IData)(1U)) + ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                                  >> 0x00000013U) 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                    >> 0x0000001aU)))
                                           ? 1U : 0U));
                __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v5 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                        >> 0x00000018U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                           >> 0x00000016U)))) {
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v5 
                    = ((vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U] 
                        - (IData)(1U)) + ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                                                  >> 2U) 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                    >> 0x0000001bU)))
                                           ? 1U : 0U));
                __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v5 = 1U;
            }
            if (((((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                         >> 2U)) & (~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                                       >> 2U))) & (0U 
                                                   == vlSelfRef.axi4_xbar_tb__DOT__w_left[2U])) 
                   & VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[2U])) 
                  & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U])) 
                 & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r 
                    = VL_URANDOM_RANGE_I(0U, 0x00000063U);
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw 
                    = VL_URANDOM_RANGE_I(0U, 0x00000063U);
                __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v2 
                    = (0x0000000fU & VL_URANDOM_RANGE_I(0U, 3U));
                __VdlySet__axi4_xbar_tb__DOT__nxt_id__v2 = 1U;
                if ((0U == VL_URANDOM_RANGE_I(0U, 3U))) {
                    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v4 = 1U;
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v5 
                        = VL_URANDOM_RANGE_I(0U, 3U);
                    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v5 = 1U;
                }
                if (VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r)) {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v4 
                        = ((IData)(0x80000000U) + (IData)(
                                                          VL_SHIFTL_III(32,32,32, (IData)(
                                                                                VL_URANDOM_RANGE_I(0U, 0x000000ffU)), 3U)));
                    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v4 = 1U;
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v5 
                        = ((IData)(VL_SHIFTL_III(32,32,32, (IData)(
                                                                   VL_URANDOM_RANGE_I(0U, 1U)), 0x00000010U)) 
                           + (IData)(VL_SHIFTL_III(32,32,32, (IData)(
                                                                     VL_URANDOM_RANGE_I(0U, 0x000003ffU)), 3U)));
                    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v5 = 1U;
                }
                if (VL_GTS_III(32, 0x00000032U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw)) {
                    __Vdly__axi4_xbar_tb__DOT__ar_hold 
                        = (4U | (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
                } else {
                    __Vdly__axi4_xbar_tb__DOT__aw_hold 
                        = (4U | (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
                }
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                        >> 0x0000000cU) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                           >> 0x0000000eU)))) {
                if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U], vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)) {
                    __Vdly__axi4_xbar_tb__DOT__cov_max_len 
                        = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U];
                }
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v6 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U]);
                __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v6 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v6 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__txn_sent[3U]);
                __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v3 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v3 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v3 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U]);
                __Vdly__axi4_xbar_tb__DOT__ar_hold 
                    = (7U & (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
                __VdlyVal__axi4_xbar_tb__DOT__rq_len__v3 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_len__v3 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_len__v3 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U]);
                __VdlySet__axi4_xbar_tb__DOT__rq_len__v3 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v3 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[3U];
                __VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v3 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v3 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U]);
                __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v3 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U])]);
                __VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v3 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U]);
            }
            if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                  >> 0x0000001bU) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                     >> 0x0000000fU))) {
                if (VL_GTS_III(32, vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U], vlSelfRef.axi4_xbar_tb__DOT__cov_max_len)) {
                    __Vdly__axi4_xbar_tb__DOT__cov_max_len 
                        = vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U];
                }
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v6 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U]);
                __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v6 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v7 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__txn_sent[3U]);
                __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v3 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[3U];
                __VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v3 
                    = (0x0000003fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__wq_tail[3U]
                                                    [
                                                    (3U 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U])], (IData)(0x00000040U)));
                __VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v3 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U]);
                __Vdly__axi4_xbar_tb__DOT__aw_hold 
                    = (7U & (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
                __VdlyVal__axi4_xbar_tb__DOT__w_left__v6 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]);
                __VdlySet__axi4_xbar_tb__DOT__w_left__v6 = 1U;
                __VdlyVal__axi4_xbar_tb__DOT__w_addr__v3 
                    = vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U];
                __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v3 
                    = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__wq_tail[3U]
                       [(3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U])]);
                __VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v3 
                    = (3U & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U]);
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                        >> 0x00000010U) & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                           >> 0x0000000dU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__w_left__v7 
                    = (vlSelfRef.axi4_xbar_tb__DOT__w_left[3U] 
                       - (IData)(1U));
                __VdlySet__axi4_xbar_tb__DOT__w_left__v7 = 1U;
            }
            if ((1U & (((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                         >> 4U) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                   >> 0x0000000bU)) 
                       & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                          >> 0x0000001dU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v7 
                    = ((vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U] 
                        - (IData)(1U)) + ((1U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                                  >> 0x0000000cU) 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                                    >> 0x0000000eU)))
                                           ? 1U : 0U));
                __VdlySet__axi4_xbar_tb__DOT__outstanding_r__v7 = 1U;
            }
            if ((1U & ((vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                        >> 0x0000000cU) & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                           >> 0x0000000fU)))) {
                __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v7 
                    = ((vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U] 
                        - (IData)(1U)) + (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                            >> 0x0000001bU) 
                                           & (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                              >> 0x0000000fU))
                                           ? 1U : 0U));
                __VdlySet__axi4_xbar_tb__DOT__outstanding_w__v7 = 1U;
            }
            if (((((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                         >> 3U)) & (~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                                       >> 3U))) & (0U 
                                                   == vlSelfRef.axi4_xbar_tb__DOT__w_left[3U])) 
                   & VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[3U])) 
                  & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U])) 
                 & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r 
                    = VL_URANDOM_RANGE_I(0U, 0x00000063U);
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw 
                    = VL_URANDOM_RANGE_I(0U, 0x00000063U);
                __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v3 
                    = (0x0000000fU & VL_URANDOM_RANGE_I(0U, 3U));
                __VdlySet__axi4_xbar_tb__DOT__nxt_id__v3 = 1U;
                if ((0U == VL_URANDOM_RANGE_I(0U, 3U))) {
                    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v6 = 1U;
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v7 
                        = VL_URANDOM_RANGE_I(0U, 3U);
                    __VdlySet__axi4_xbar_tb__DOT__nxt_len__v7 = 1U;
                }
                if (VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r)) {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v6 
                        = ((IData)(0x80000000U) + (IData)(
                                                          VL_SHIFTL_III(32,32,32, (IData)(
                                                                                VL_URANDOM_RANGE_I(0U, 0x000000ffU)), 3U)));
                    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v6 = 1U;
                } else {
                    __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v7 
                        = ((IData)(VL_SHIFTL_III(32,32,32, (IData)(
                                                                   VL_URANDOM_RANGE_I(0U, 1U)), 0x00000010U)) 
                           + (IData)(VL_SHIFTL_III(32,32,32, (IData)(
                                                                     VL_URANDOM_RANGE_I(0U, 0x000003ffU)), 3U)));
                    __VdlySet__axi4_xbar_tb__DOT__nxt_addr__v7 = 1U;
                }
                if (VL_GTS_III(32, 0x00000032U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw)) {
                    __Vdly__axi4_xbar_tb__DOT__ar_hold 
                        = (8U | (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
                } else {
                    __Vdly__axi4_xbar_tb__DOT__aw_hold 
                        = (8U | (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
                }
            }
        }
    } else {
        __VdlySet__axi4_xbar_tb__DOT__txn_sent__v8 = 1U;
        __Vdly__axi4_xbar_tb__DOT__ar_hold = (0x0eU 
                                              & (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
        __Vdly__axi4_xbar_tb__DOT__aw_hold = (0x0eU 
                                              & (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
        __VdlySet__axi4_xbar_tb__DOT__w_left__v8 = 1U;
        __Vdly__axi4_xbar_tb__DOT__ar_hold = (0x0dU 
                                              & (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
        __Vdly__axi4_xbar_tb__DOT__aw_hold = (0x0dU 
                                              & (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
        __VdlySet__axi4_xbar_tb__DOT__w_left__v9 = 1U;
        __Vdly__axi4_xbar_tb__DOT__ar_hold = (0x0bU 
                                              & (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
        __Vdly__axi4_xbar_tb__DOT__aw_hold = (0x0bU 
                                              & (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
        __VdlySet__axi4_xbar_tb__DOT__w_left__v10 = 1U;
        __Vdly__axi4_xbar_tb__DOT__ar_hold = (7U & (IData)(__Vdly__axi4_xbar_tb__DOT__ar_hold));
        __Vdly__axi4_xbar_tb__DOT__aw_hold = (7U & (IData)(__Vdly__axi4_xbar_tb__DOT__aw_hold));
        __VdlySet__axi4_xbar_tb__DOT__w_left__v11 = 1U;
    }
    vlSelfRef.axi4_xbar_tb__DOT__bp_b_stalls = __Vdly__axi4_xbar_tb__DOT__bp_b_stalls;
    vlSelfRef.axi4_xbar_tb__DOT__bp_r_stalls = __Vdly__axi4_xbar_tb__DOT__bp_r_stalls;
    if (__VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[0U] 
            = __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[1U] 
            = __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[2U] 
            = __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[3U] 
            = __VdlyVal__axi4_xbar_tb__DOT__cap_done_cnt__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_done_cnt__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__cap_done_cnt[3U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[0U] 
            = __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[1U] 
            = __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[2U] 
            = __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[3U] 
            = __VdlyVal__axi4_xbar_tb__DOT__cap_ar_cnt__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__cap_ar_cnt__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__cap_ar_cnt[3U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__pq_hd__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U] = __VdlyVal__axi4_xbar_tb__DOT__pq_hd__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__pq_hd__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__pq_hd__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U] = __VdlyVal__axi4_xbar_tb__DOT__pq_hd__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__pq_hd__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__pq_id__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__pq_id[0U][__VdlyDim0__axi4_xbar_tb__DOT__pq_id__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__pq_id__v0;
        vlSelfRef.axi4_xbar_tb__DOT__pq_adr[0U][__VdlyDim0__axi4_xbar_tb__DOT__pq_adr__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__pq_adr__v0;
        vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U] = __VdlyVal__axi4_xbar_tb__DOT__pq_tl__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__pq_tl__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__pq_id__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__pq_id[1U][__VdlyDim0__axi4_xbar_tb__DOT__pq_id__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__pq_id__v1;
        vlSelfRef.axi4_xbar_tb__DOT__pq_adr[1U][__VdlyDim0__axi4_xbar_tb__DOT__pq_adr__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__pq_adr__v1;
        vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U] = __VdlyVal__axi4_xbar_tb__DOT__pq_tl__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__pq_tl__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__s_wid[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_wid__v0;
        axi4_xbar_tb__DOT__s_w_inflight[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_w_inflight__v0;
        vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_bpend__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__s_bpend[0U] = 1U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_bpend__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__s_bpend[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v2) {
        axi4_xbar_tb__DOT__s_w_inflight[0U] = 0xffffffffU;
        vlSelfRef.axi4_xbar_tb__DOT__s_bpend[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_bpend__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__s_bpend[1U] = 1U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_bpend__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__s_bpend[1U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__s_wid[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_wid__v1;
        axi4_xbar_tb__DOT__s_w_inflight[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_w_inflight__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_wbeats__v4;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rbeats__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rn[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_rn__v0;
        vlSelfRef.axi4_xbar_tb__DOT__s_rid[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_rid__v0;
        vlSelfRef.axi4_xbar_tb__DOT__s_raddr[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_raddr__v0;
        vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v0;
        vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rbeats__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rbeats__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rn[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_rn__v1;
        vlSelfRef.axi4_xbar_tb__DOT__s_rid[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_rid__v1;
        vlSelfRef.axi4_xbar_tb__DOT__s_raddr[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_raddr__v1;
        vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rbeats__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_rbeats__v4;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rdelay__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rbeats__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[0U] = __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rbeats__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v4;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rdelay__v5) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v5;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_rbeats__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[1U] = __VdlyVal__axi4_xbar_tb__DOT__s_rdelay__v6;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__s_wbeats__v5) {
        axi4_xbar_tb__DOT__s_w_inflight[1U] = 0xffffffffU;
        vlSelfRef.axi4_xbar_tb__DOT__s_bpend[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[1U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U] = __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v0;
        vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U] = __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v1;
        vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U] = __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v2;
        vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U] = __VdlyVal__axi4_xbar_tb__DOT__bp_lfsr__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__bp_lfsr__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U] = 0xace1U;
        vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U] = 0xcbd0U;
        vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U] = 0xeabfU;
        vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U] = 0x09aeU;
    }
    vlSelfRef.axi4_xbar_tb__DOT__cov_max_len = __Vdly__axi4_xbar_tb__DOT__cov_max_len;
    if (__VdlySet__axi4_xbar_tb__DOT__rq_len__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_len[0U][__VdlyDim1__axi4_xbar_tb__DOT__rq_len__v0][__VdlyDim0__axi4_xbar_tb__DOT__rq_len__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_len__v0;
        vlSelfRef.axi4_xbar_tb__DOT__rq_dec[0U][__VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v0][__VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v0;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U][__VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_len__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_len[1U][__VdlyDim1__axi4_xbar_tb__DOT__rq_len__v1][__VdlyDim0__axi4_xbar_tb__DOT__rq_len__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_len__v1;
        vlSelfRef.axi4_xbar_tb__DOT__rq_dec[1U][__VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v1][__VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v1;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U][__VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_len__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_len[2U][__VdlyDim1__axi4_xbar_tb__DOT__rq_len__v2][__VdlyDim0__axi4_xbar_tb__DOT__rq_len__v2] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_len__v2;
        vlSelfRef.axi4_xbar_tb__DOT__rq_dec[2U][__VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v2][__VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v2] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v2;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U][__VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v2] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_len__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_len[3U][__VdlyDim1__axi4_xbar_tb__DOT__rq_len__v3][__VdlyDim0__axi4_xbar_tb__DOT__rq_len__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_len__v3;
        vlSelfRef.axi4_xbar_tb__DOT__rq_dec[3U][__VdlyDim1__axi4_xbar_tb__DOT__rq_dec__v3][__VdlyDim0__axi4_xbar_tb__DOT__rq_dec__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_dec__v3;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U][__VdlyDim0__axi4_xbar_tb__DOT__rq_tail__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_tail__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_addr[0U][__VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v0][__VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v0;
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[0U] = __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v0;
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_addr[1U][__VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v1][__VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_dec[0U][__VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v0][__VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v0;
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[0U] = __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v1;
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[1U] = __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_dec[1U][__VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v1][__VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_addr[2U][__VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v2][__VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v2] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[1U] = __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[2U] = __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v4;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_dec[2U][__VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v2][__VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v2] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_addr[3U][__VdlyDim1__axi4_xbar_tb__DOT__rq_addr__v3][__VdlyDim0__axi4_xbar_tb__DOT__rq_addr__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_addr__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[2U] = __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v5;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[3U] = __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v6;
    }
    vlSelfRef.axi4_xbar_tb__DOT__ar_hold = __Vdly__axi4_xbar_tb__DOT__ar_hold;
    vlSelfRef.axi4_xbar_tb__DOT__aw_hold = __Vdly__axi4_xbar_tb__DOT__aw_hold;
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__w_addr[0U] = __VdlyVal__axi4_xbar_tb__DOT__w_addr__v0;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[0U][__VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v0;
        vlSelfRef.axi4_xbar_tb__DOT__w_left[0U] = __VdlyVal__axi4_xbar_tb__DOT__w_left__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__w_addr[1U] = __VdlyVal__axi4_xbar_tb__DOT__w_addr__v1;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[1U][__VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__w_addr[2U] = __VdlyVal__axi4_xbar_tb__DOT__w_addr__v2;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[2U][__VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v2] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__last_rid__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__last_rid[0U] = __VdlyVal__axi4_xbar_tb__DOT__last_rid__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__last_rid__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__last_rid[1U] = __VdlyVal__axi4_xbar_tb__DOT__last_rid__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__last_rid__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__last_rid[2U] = __VdlyVal__axi4_xbar_tb__DOT__last_rid__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__last_rid__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__last_rid[3U] = __VdlyVal__axi4_xbar_tb__DOT__last_rid__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_addr__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[0U] = 1U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_addr__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_addr__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[1U] = 1U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_addr__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_addr__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[2U] = 1U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v4;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_addr__v5) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v5;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_addr__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[3U] = 1U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v6;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_addr__v7) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_addr__v7;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_head__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U][__VdlyDim0__axi4_xbar_tb__DOT__rq_head__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_head__v0;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U][__VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v0] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_head__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U][__VdlyDim0__axi4_xbar_tb__DOT__rq_head__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_head__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_head__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U][__VdlyDim0__axi4_xbar_tb__DOT__rq_head__v2] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_head__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_head__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U][__VdlyDim0__axi4_xbar_tb__DOT__rq_head__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_head__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__wq_head__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[0U][__VdlyDim0__axi4_xbar_tb__DOT__wq_head__v0] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_head__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__wq_head__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[1U][__VdlyDim0__axi4_xbar_tb__DOT__wq_head__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_head__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__wq_head__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[2U][__VdlyDim0__axi4_xbar_tb__DOT__wq_head__v2] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_head__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__wq_head__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[3U][__VdlyDim0__axi4_xbar_tb__DOT__wq_head__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_head__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_dec[3U][__VdlyDim1__axi4_xbar_tb__DOT__wq_dec__v3][__VdlyDim0__axi4_xbar_tb__DOT__wq_dec__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_dec__v3;
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[3U] = __VdlyVal__axi4_xbar_tb__DOT__txn_sent__v7;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__txn_sent__v8) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U][0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__w_addr[3U] = __VdlyVal__axi4_xbar_tb__DOT__w_addr__v3;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[3U][__VdlyDim0__axi4_xbar_tb__DOT__wq_tail__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__wq_tail__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__txn_sent__v8) {
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[0U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_beat__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U][__VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v1] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_head__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U][__VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v2] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_beat__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U][__VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v3] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_head__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U][__VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v4] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_beat__v5) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U][__VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v5] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v5;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_head__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U][__VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v6] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__rq_beat__v7) {
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U][__VdlyDim0__axi4_xbar_tb__DOT__rq_beat__v7] 
            = __VdlyVal__axi4_xbar_tb__DOT__rq_beat__v7;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v8) {
        vlSelfRef.axi4_xbar_tb__DOT__last_rid[0U] = 0xffffffffU;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[0U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[0U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[0U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[0U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U][1U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v4;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v5) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v5;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v6;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_r__v7) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_r__v7;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__txn_sent__v8) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v4;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v5) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v5;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v6;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__outstanding_w__v7) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U] 
            = __VdlyVal__axi4_xbar_tb__DOT__outstanding_w__v7;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__txn_sent__v8) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_id__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v0;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_id__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_id__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_id__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_id__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v8) {
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v9) {
        vlSelfRef.axi4_xbar_tb__DOT__last_rid[1U] = 0xffffffffU;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[0U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[0U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[0U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_len__v0) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U] = 3U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_len__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_len__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U] = 3U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_len__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_len__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U] = 3U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_len__v5) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v5;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_len__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U] = 3U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__nxt_len__v7) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U] = __VdlyVal__axi4_xbar_tb__DOT__nxt_len__v7;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v8) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v9) {
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v10) {
        vlSelfRef.axi4_xbar_tb__DOT__last_rid[2U] = 0xffffffffU;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[0U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[0U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[1U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__txn_sent[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[0U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v1) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[0U] = __VdlyVal__axi4_xbar_tb__DOT__w_left__v1;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v2) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[1U] = __VdlyVal__axi4_xbar_tb__DOT__w_left__v2;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v3) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[1U] = __VdlyVal__axi4_xbar_tb__DOT__w_left__v3;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v4) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[2U] = __VdlyVal__axi4_xbar_tb__DOT__w_left__v4;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v5) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[2U] = __VdlyVal__axi4_xbar_tb__DOT__w_left__v5;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v6) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[3U] = __VdlyVal__axi4_xbar_tb__DOT__w_left__v6;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v7) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[3U] = __VdlyVal__axi4_xbar_tb__DOT__w_left__v7;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v8) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v9) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v10) {
        vlSelfRef.axi4_xbar_tb__DOT__w_left[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U] = 0U;
    }
    if (__VdlySet__axi4_xbar_tb__DOT__w_left__v11) {
        vlSelfRef.axi4_xbar_tb__DOT__last_rid[3U] = 0xffffffffU;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_dec[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[1U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[2U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_head[3U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[1U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[1U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[1U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[1U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[2U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[2U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[2U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[2U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[3U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[3U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[3U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_head[3U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[1U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[2U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_tail[3U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[1U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[1U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[1U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[2U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[2U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[2U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[2U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[3U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[3U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[3U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__wq_tail[3U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[1U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[2U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U][0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U][1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U][2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__rq_beat[3U][3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__w_left[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U] = 0U;
    }
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = (0xff000000U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xffbfffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((1U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                     | ((2U 
                                                         == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                         ? 
                                                        VL_GTS_III(32, 0x00000020U, 
                                                                   (vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U] 
                                                                    - vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U]))
                                                         : 
                                                        (0U 
                                                         == vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U]))) 
                                                    << 0x00000016U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xff7fffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((0U 
                                                      == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U]) 
                                                     & (~ vlSelfRef.axi4_xbar_tb__DOT__s_bpend[0U])) 
                                                    << 0x00000017U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xffdfffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[0U]) 
                                                    << 0x00000015U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xfffffbffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((1U 
                                                      != (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                     & ((2U 
                                                         == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                         ? 
                                                        (vlSelfRef.axi4_xbar_tb__DOT__pq_tl[0U] 
                                                         != vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U])
                                                         : 
                                                        ((0U 
                                                          != vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U]) 
                                                         & (0U 
                                                            == vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[0U])))) 
                                                    << 0x0000000aU));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xfffffc0fU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((2U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                      ? vlSelfRef.axi4_xbar_tb__DOT__pq_id[0U]
                                                     [
                                                     (0x0000001fU 
                                                      & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U], (IData)(0x00000020U)))]
                                                      : vlSelfRef.axi4_xbar_tb__DOT__s_rid[0U]) 
                                                    << 4U));
    VL_ASSIGNSEL_WQ(176, 64, 4U, vlSelfRef.axi4_xbar_tb__DOT__slv_resp, 
                    ((2U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                      ? ([&]() {
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__a 
                        = vlSelfRef.axi4_xbar_tb__DOT__pq_adr[0U]
                        [(0x0000001fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[0U], (IData)(0x00000020U)))];
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__Vfuncout 
                        = (QData)((IData)((0xfffffff0U 
                                           & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__a)));
                }(), vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__Vfuncout)
                      : ([&]() {
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__beat 
                        = (vlSelfRef.axi4_xbar_tb__DOT__s_rn[0U] 
                           - vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U]);
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__a 
                        = vlSelfRef.axi4_xbar_tb__DOT__s_raddr[0U];
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__Vfuncout 
                        = ((QData)((IData)((0xfffffff0U 
                                            & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__a))) 
                           + (0x0100000000000001ULL 
                              * VL_EXTENDS_QI(64,32, vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__beat)));
                }(), vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__Vfuncout)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U] = (0xfffffff3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U]);
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U] = ((0xfffffffdU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[0U]) 
                                                 | (((2U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                     | (1U 
                                                        == vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[0U])) 
                                                    << 1U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xffe00fffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (0xfffff000U 
                                                    & ((vlSelfRef.axi4_xbar_tb__DOT__s_bpend[0U] 
                                                        << 0x00000014U) 
                                                       | (vlSelfRef.axi4_xbar_tb__DOT__s_wid[0U] 
                                                          << 0x0000000eU))));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = (0x00ffffffU 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[4U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000bfffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (((1U 
                                                         == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                        | ((2U 
                                                            == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                            ? 
                                                           VL_GTS_III(32, 0x00000020U, 
                                                                      (vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U] 
                                                                       - vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U]))
                                                            : 
                                                           (0U 
                                                            == vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U]))) 
                                                       << 0x0000000eU)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x00007fffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (((0U 
                                                         == vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U]) 
                                                        & (~ vlSelfRef.axi4_xbar_tb__DOT__s_bpend[1U])) 
                                                       << 0x0000000fU)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000dfffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__s_wbeats[1U]) 
                                                       << 0x0000000dU)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000fffbU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (((1U 
                                                         != (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                        & ((2U 
                                                            == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                            ? 
                                                           (vlSelfRef.axi4_xbar_tb__DOT__pq_tl[1U] 
                                                            != vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U])
                                                            : 
                                                           ((0U 
                                                             != vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U]) 
                                                            & (0U 
                                                               == vlSelfRef.axi4_xbar_tb__DOT__s_rdelay[1U])))) 
                                                       << 2U)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[4U] = ((0x0fffffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[4U]) 
                                                 | (((2U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                      ? vlSelfRef.axi4_xbar_tb__DOT__pq_id[1U]
                                                     [
                                                     (0x0000001fU 
                                                      & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U], (IData)(0x00000020U)))]
                                                      : vlSelfRef.axi4_xbar_tb__DOT__s_rid[1U]) 
                                                    << 0x0000001cU));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000fffcU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000ffffU 
                                                    & (((2U 
                                                         == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                                                         ? vlSelfRef.axi4_xbar_tb__DOT__pq_id[1U]
                                                        [
                                                        (0x0000001fU 
                                                         & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U], (IData)(0x00000020U)))]
                                                         : vlSelfRef.axi4_xbar_tb__DOT__s_rid[1U]) 
                                                       >> 4U)));
    VL_ASSIGNSEL_WQ(176, 64, 0x0000005cU, vlSelfRef.axi4_xbar_tb__DOT__slv_resp, 
                    ((2U == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))
                      ? ([&]() {
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__a 
                        = vlSelfRef.axi4_xbar_tb__DOT__pq_adr[1U]
                        [(0x0000001fU & VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__pq_hd[1U], (IData)(0x00000020U)))];
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__Vfuncout 
                        = (QData)((IData)((0xfffffff0U 
                                           & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__a)));
                }(), vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__Vfuncout)
                      : ([&]() {
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__beat 
                        = (vlSelfRef.axi4_xbar_tb__DOT__s_rn[1U] 
                           - vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U]);
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__a 
                        = vlSelfRef.axi4_xbar_tb__DOT__s_raddr[1U];
                    vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__Vfuncout 
                        = ((QData)((IData)((0xfffffff0U 
                                            & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__a))) 
                           + (0x0100000000000001ULL 
                              * VL_EXTENDS_QI(64,32, vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__beat)));
                }(), vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__Vfuncout)));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = (0xf3ffffffU 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U] = ((0xfdffffffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[2U]) 
                                                 | (((2U 
                                                      == (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode)) 
                                                     | (1U 
                                                        == vlSelfRef.axi4_xbar_tb__DOT__s_rbeats[1U])) 
                                                    << 0x00000019U));
    vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U] = ((0x0000e00fU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__slv_resp[5U]) 
                                                 | (0x0000fff0U 
                                                    & ((vlSelfRef.axi4_xbar_tb__DOT__s_bpend[1U] 
                                                        << 0x0000000cU) 
                                                       | (vlSelfRef.axi4_xbar_tb__DOT__s_wid[1U] 
                                                          << 6U))));
    vlSelfRef.axi4_xbar_tb__DOT__bp_r = ((0x0eU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r)) 
                                         | (0U != (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U])));
    vlSelfRef.axi4_xbar_tb__DOT__bp_r = ((0x0dU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r)) 
                                         | ((0U != 
                                             (3U & vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U])) 
                                            << 1U));
    vlSelfRef.axi4_xbar_tb__DOT__bp_r = ((0x0bU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r)) 
                                         | ((0U != 
                                             (3U & vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U])) 
                                            << 2U));
    vlSelfRef.axi4_xbar_tb__DOT__bp_r = ((7U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r)) 
                                         | ((0U != 
                                             (3U & vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U])) 
                                            << 3U));
    vlSelfRef.axi4_xbar_tb__DOT__bp_b = ((0x0eU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b)) 
                                         | (0U != (3U 
                                                   & (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[0U] 
                                                      >> 4U))));
    vlSelfRef.axi4_xbar_tb__DOT__bp_b = ((0x0dU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b)) 
                                         | ((0U != 
                                             (3U & 
                                              (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[1U] 
                                               >> 4U))) 
                                            << 1U));
    vlSelfRef.axi4_xbar_tb__DOT__bp_b = ((0x0bU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b)) 
                                         | ((0U != 
                                             (3U & 
                                              (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[2U] 
                                               >> 4U))) 
                                            << 2U));
    vlSelfRef.axi4_xbar_tb__DOT__bp_b = ((7U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b)) 
                                         | ((0U != 
                                             (3U & 
                                              (vlSelfRef.axi4_xbar_tb__DOT__bp_lfsr[3U] 
                                               >> 4U))) 
                                            << 3U));
}

void Vaxi4_xbar_tb___024root___nba_sequent__TOP__1(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___nba_sequent__TOP__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((0U != (IData)(vlSelfRef.axi4_xbar_tb__DOT__tmode))) {
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            (0xfe000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | (IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xffffffefU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 4U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0xfffffffdU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | (2U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en) 
                      << 1U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            (0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] = 
            ((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[0U], 0x00000010U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            (0x00680000U | (0x0007ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            (0x01ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            (0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfdffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x00000019U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x0000001dU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfbffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (0x04000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en) 
                               << 0x00000019U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            (0x02000000U | (0xe1ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 
            ((0x01ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[1U], 0x00000010U)) 
                << 0x00000019U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xfe000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[1U], 0x00000010U)) 
                >> 7U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 
            (0x0000d000U | (0xfe000fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            (0x0003ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfffbffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x00000012U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xffbfffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x00000016U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfff7ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (0x00080000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en) 
                               << 0x00000011U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            (0x00080000U | (0xffc3ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 
            ((0x0003ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[2U], 0x00000010U)) 
                << 0x00000012U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[2U], 0x00000010U)) 
                >> 0x0000000eU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 
            (0x000001a0U | (0xfffc001fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0x000007ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[27U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xfffff7ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x0000000bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xffff7fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_drain) 
                << 0x0000000fU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xffffefffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | (0x00001000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__cap_en) 
                               << 9U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            (0x00001800U | (0xffff87ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 
            ((0x000007ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[3U], 0x00000010U)) 
                << 0x0000000bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (((IData)(0x00000040U) + VL_SHIFTL_III(32,32,32, vlSelfRef.axi4_xbar_tb__DOT__cap_tgt[3U], 0x00000010U)) 
                >> 0x00000015U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0x40000000U | (0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 
            (3U | (0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U]));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            (0xfe000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | (1U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xffffffefU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | (0x00000010U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b) 
                               << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0xfffffffdU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | (2U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                      << 1U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            ((0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]))))) 
                << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] = 
            (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                        << 8U) | (QData)((IData)((0x000000ffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]))))) 
              >> 8U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                                   << 8U) | (QData)((IData)(
                                                            (0x000000ffU 
                                                             & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U])))) 
                                 >> 0x00000020U)) << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] = 
            (0x00680000U | (0xff07ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] = 
            ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U]) 
             | (0x00010000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                               << 0x00000010U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] = 
            ((0x00001fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]))))) 
                << 0x0000000dU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xffe00000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U]))))) 
                 >> 0x00000013U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[0U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[0U])))) 
                                             >> 0x00000020U)) 
                                    << 0x0000000dU)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfe1fffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[0U] 
                << 0x00000015U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] = 
            (0x00000d00U | (0xffffe0ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xffffffdfU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__w_left[0U]) 
                << 5U));
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__a 
            = vlSelfRef.axi4_xbar_tb__DOT__w_addr[0U];
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout 
            = (QData)((IData)((0xfffffff0U & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__a)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0x0000ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | ((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout) 
                << 0x00000010U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] = 
            (((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout) 
              >> 0x00000010U) | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout 
                                          >> 0x00000020U)) 
                                 << 0x00000010U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] = 
            ((0xffff0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U]) 
             | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout 
                         >> 0x00000020U)) >> 0x00000010U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            ((0xffff007fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]) 
             | (0xffffff80U & (0x0000ff00U | ((1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[0U]) 
                                              << 7U))));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            (0x01ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            (0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfdffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (0x02000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r) 
                               << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (0x20000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b) 
                               << 0x0000001cU)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] = 
            ((0xfbffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]) 
             | (0x04000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                               << 0x00000019U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 
            ((0x0001ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]))))) 
                << 0x00000011U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xfe000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]))))) 
                 >> 0x0000000fU) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U])))) 
                                             >> 0x00000020U)) 
                                    << 0x00000011U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xe1ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U] 
                << 0x00000019U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] = 
            (0x0000d000U | (0xfffe0fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] = 
            ((0xfffffdffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U]) 
             | (0x00000200U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                               << 8U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] = 
            ((0x0000003fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]))))) 
                << 6U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xffffc000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U]))))) 
                 >> 0x0000001aU) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[1U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[1U])))) 
                                             >> 0x00000020U)) 
                                    << 6U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfffc3fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[1U] 
                << 0x0000000eU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] = 
            (0x0000001aU | (0xffffffc1U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            ((0xbfffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]) 
             | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__w_left[1U]) 
                << 0x0000001eU));
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__a 
            = vlSelfRef.axi4_xbar_tb__DOT__w_addr[1U];
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout 
            = (QData)((IData)((0xfffffff0U & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__a)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] = 
            ((0x000001ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U]) 
             | ((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout) 
                << 9U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] = 
            (((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout) 
              >> 0x00000017U) | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout 
                                          >> 0x00000020U)) 
                                 << 9U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] = 
            ((0xfffffe00U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U]) 
             | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout 
                         >> 0x00000020U)) >> 0x00000017U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] = 
            (0x000001feU | ((0xfffffe00U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U]) 
                            | (1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[1U])));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            (0x0003ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfffbffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (0x00040000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r) 
                               << 0x00000010U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xffbfffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (0x00400000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b) 
                               << 0x00000014U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] = 
            ((0xfff7ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]) 
             | (0x00080000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                               << 0x00000011U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 
            ((0x000003ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]))))) 
                << 0x0000000aU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]))))) 
                 >> 0x00000016U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U])))) 
                                             >> 0x00000020U)) 
                                    << 0x0000000aU)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xffc3ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U] 
                << 0x00000012U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] = 
            (0x000001a0U | (0xfffffc1fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 
            ((0xfffffffbU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U]) 
             | (4U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 
            ((0x7fffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]))))) 
                << 0x0000001fU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] = 
            (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                        << 8U) | (QData)((IData)((0x000000ffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U]))))) 
              >> 1U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                                   << 8U) | (QData)((IData)(
                                                            (0x000000ffU 
                                                             & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U])))) 
                                 >> 0x00000020U)) << 0x0000001fU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xffffff80U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[2U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[2U])))) 
                         >> 0x00000020U)) >> 1U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xfffff87fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[2U] 
                << 7U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 
            (0x34000000U | (0x83ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0xff7fffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__w_left[2U]) 
                << 0x00000017U));
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__a 
            = vlSelfRef.axi4_xbar_tb__DOT__w_addr[2U];
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout 
            = (QData)((IData)((0xfffffff0U & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__a)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] = 
            ((3U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U]) 
             | ((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout) 
                << 2U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] = 
            (((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout) 
              >> 0x0000001eU) | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout 
                                          >> 0x00000020U)) 
                                 << 2U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] = 
            ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U]) 
             | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout 
                         >> 0x00000020U)) >> 0x0000001eU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            ((0x01ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]) 
             | (0xfe000000U & (0xfc000000U | ((1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[2U]) 
                                              << 0x00000019U))));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] = 
            ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U]) 
             | (0x01ffffffU & (3U | ((1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[2U]) 
                                     >> 7U))));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0x000007ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[27U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xfffff7ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | (0x00000800U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_r) 
                               << 8U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xffff7fffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (0x00008000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__bp_b) 
                               << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            ((0xffffefffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]) 
             | (0x00001000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__ar_hold) 
                               << 9U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 
            ((7U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]))))) 
                << 3U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xfffff800U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                           << 8U) | (QData)((IData)(
                                                    (0x000000ffU 
                                                     & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]))))) 
                 >> 0x0000001dU) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                                               << 8U) 
                                              | (QData)((IData)(
                                                                (0x000000ffU 
                                                                 & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U])))) 
                                             >> 0x00000020U)) 
                                    << 3U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xffff87ffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U] 
                << 0x0000000bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] = 
            (0x40000000U | (0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] = 
            (3U | (0xfffffff8U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] = 
            ((0xf7ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U]) 
             | (0x08000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__aw_hold) 
                               << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U] = 
            ((0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U]) 
             | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                          << 8U) | (QData)((IData)(
                                                   (0x000000ffU 
                                                    & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]))))) 
                << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] = 
            (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                        << 8U) | (QData)((IData)((0x000000ffU 
                                                  & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U]))))) 
              >> 8U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__nxt_addr[3U])) 
                                   << 8U) | (QData)((IData)(
                                                            (0x000000ffU 
                                                             & vlSelfRef.axi4_xbar_tb__DOT__nxt_len[3U])))) 
                                 >> 0x00000020U)) << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[27U] = 
            (0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT__nxt_id[3U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U] = 
            (0x00680000U | (0xff07ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[25U]));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__w_left[3U]) 
                << 0x00000010U));
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__a 
            = vlSelfRef.axi4_xbar_tb__DOT__w_addr[3U];
        vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout 
            = (QData)((IData)((0xfffffff0U & vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__a)));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0x07ffffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | ((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout) 
                << 0x0000001bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] = 
            (((IData)(vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout) 
              >> 5U) | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout 
                                 >> 0x00000020U)) << 0x0000001bU));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] = 
            ((0xf8000000U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U]) 
             | ((IData)((vlSelfRef.__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout 
                         >> 0x00000020U)) >> 5U));
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            ((0xf803ffffU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]) 
             | (0xfffc0000U & (0x07f80000U | ((1U == vlSelfRef.axi4_xbar_tb__DOT__w_left[3U]) 
                                              << 0x00000012U))));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
            << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                               >> 0x00000015U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
               << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                                  >> 0x00000015U)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
            << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                               >> 0x00000015U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
               << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                                  >> 0x00000015U)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar_error = 1U;
    if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] 
          >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar = 0U;
    }
    if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] 
          >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U] 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
            << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                               >> 0x0000000eU)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
               << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                                  >> 0x0000000eU)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
            << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                               >> 0x0000000eU)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
               << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                                  >> 0x0000000eU)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                      >> 0x00000019U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
               << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                         >> 0x00000019U)) < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                      >> 0x00000019U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
               << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                         >> 0x00000019U)) < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
            << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                               >> 7U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
               << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                                  >> 7U)) < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
            << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                               >> 7U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
               << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                                  >> 7U)) < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                               >> 0x00000012U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
               << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                                  >> 0x00000012U)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                               >> 0x00000012U)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
               << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                                  >> 0x00000012U)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw_error = 1U;
    if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] 
          >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw = 0U;
    }
    if (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] 
          >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U] 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar_error = 1U;
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                               >> 0x0000000bU)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[1U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
               << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                                  >> 0x0000000bU)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[2U]);
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar = 0U;
    }
    if (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                               >> 0x0000000bU)) >= vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[4U]) 
         & ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
               << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                                  >> 0x0000000bU)) 
             < vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U]) 
            | (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[3U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules));
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar_error = 0U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar 
            = (1U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i[5U]);
    }
}
