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
                                                             468);
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
                                                             487);
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
                                                             525);
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
                                                             527);
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
                                                             531);
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
                                                             534);
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
                                                             550);
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
                                                             553);
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
                                                             561);
        axi4_xbar_tb__DOT__unnamedblk1_9__DOT____Vrepeat8 
            = (axi4_xbar_tb__DOT__unnamedblk1_9__DOT____Vrepeat8 
               - (IData)(1U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__rst_n = 1U;
    vlSelfRef.axi4_xbar_tb__DOT__phase = "all-to-all"s;
    axi4_xbar_tb__DOT__guard = 0U;
    {
        while (VL_GTS_III(32, 0x000927c0U, axi4_xbar_tb__DOT__guard)) {
            vlSelfRef.axi4_xbar_tb__DOT__unnamedblk16__DOT__done = 1U;
            if (((VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[0U]) 
                  | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U])) 
                 | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk16__DOT__done = 0U;
            }
            if (((VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[1U]) 
                  | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U])) 
                 | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk16__DOT__done = 0U;
            }
            if (((VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[2U]) 
                  | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U])) 
                 | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk16__DOT__done = 0U;
            }
            if (((VL_GTS_III(32, 0x000005dcU, vlSelfRef.axi4_xbar_tb__DOT__txn_sent[3U]) 
                  | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U])) 
                 | VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U]))) {
                vlSelfRef.axi4_xbar_tb__DOT__unnamedblk16__DOT__done = 0U;
            }
            if (vlSelfRef.axi4_xbar_tb__DOT__unnamedblk16__DOT__done) {
                goto __Vlabel0;
            }
            Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(vlSelf, 
                                                                "@(posedge axi4_xbar_tb.clk)");
            co_await vlSelfRef.__VtrigSched_ha9bc5c2b__0.trigger(0U, 
                                                                 nullptr, 
                                                                 "@(posedge axi4_xbar_tb.clk)", 
                                                                 "tb/axi4_xbar_tb.sv", 
                                                                 571);
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
                                                             573);
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
    vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss = 0U;
    VL_WRITEF_NX("// coverage: rd_ok=%0d rd_decerr=%0d wr_ok=%0d wr_decerr=%0d\n// coverage: multi_beat_bursts=%0d cross_id_switches=%0d\n",0,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1,
                 32,vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id);
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_rd_ok)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no successful read\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_wr_ok)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no successful write\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_rd_dec)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no unmapped read (DECERR path untested)\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_wr_dec)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no unmapped write\n",0);
    }
    if (VL_UNLIKELY(((0U == vlSelfRef.axi4_xbar_tb__DOT__cov_burst_gt1)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: no multi-beat burst\n",0);
    }
    if (VL_UNLIKELY((VL_GTS_III(32, 0x00000064U, vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id)))) {
        vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss 
            = ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss);
        VL_WRITEF_NX("// COVERAGE HOLE: too little cross-ID interleaving (%0d switches)\n",0,
                     32,vlSelfRef.axi4_xbar_tb__DOT__cov_cross_id);
    }
    if (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss)) {
        vlSelfRef.__Vtask_axi4_xbar_tb__DOT__note_fail__30__why 
            = VL_SFORMATF_N_NX("%0d coverage holes",0,
                               32,vlSelfRef.axi4_xbar_tb__DOT__unnamedblk20__DOT__miss) ;
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
    VL_FINISH_MT("tb/axi4_xbar_tb.sv", 600, "");
    co_return;
}

VlCoroutine Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__1(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    co_await vlSelfRef.__VdlySched.delay(0x0000002e90edd000ULL, 
                                         nullptr, "tb/axi4_xbar_tb.sv", 
                                         604);
    VL_WRITEF_NX("// watchdog: phase=%@ checks=%0d\nTEST_RESULT: FAIL: timeout -- checker did not complete (phase=%@)\n",0,
                 -1,&(vlSelfRef.axi4_xbar_tb__DOT__phase),
                 32,vlSelfRef.axi4_xbar_tb__DOT__checks,
                 -1,&(vlSelfRef.axi4_xbar_tb__DOT__phase));
    VL_FINISH_MT("tb/axi4_xbar_tb.sv", 607, "");
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
                                             56);
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
                                                      << 1U) 
                                                     | ((IData)(vlSelfRef.axi4_xbar_tb__DOT__clk) 
                                                        & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0))))));
    vlSelfRef.__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0 
        = vlSelfRef.axi4_xbar_tb__DOT__clk;
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
    // Locals
    IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m = 0;
    IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m = 0;
    IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout;
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a;
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a = 0;
    IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout;
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a;
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a = 0;
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
            (1U | vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] = 
            (0x00000010U | vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U]);
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
            (0x02000000U | vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] = 
            (0x20000000U | vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U]);
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
            (0x00040000U | vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] = 
            (0x00400000U | vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U]);
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
            (0x00000800U | vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U]);
        vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] = 
            (0x00008000U | vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U]);
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
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
        = (0x0eU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
    if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[0U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U] = 2U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s 
            = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_b[0U], (IData)(2U));
        if ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v)) 
              & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                 [(((IData)(0x00000054U) + (0x000000ffU 
                                            & ((IData)(0x00000058U) 
                                               * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                   >> 5U)] >> (0x0000001fU & ((IData)(0x00000054U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))) 
             & (0U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000052U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000052U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000052U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000052U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
                = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
        }
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s 
            = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_b[0U]), (IData)(2U));
        if ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v)) 
              & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                 [(((IData)(0x00000054U) + (0x000000ffU 
                                            & ((IData)(0x00000058U) 
                                               * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                   >> 5U)] >> (0x0000001fU & ((IData)(0x00000054U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))) 
             & (0U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000052U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000052U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000052U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000052U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
                = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
        = (0x0dU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
    if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[1U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U] = 2U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s 
            = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_b[1U], (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
                  >> 1U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x00000054U) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x00000054U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))) 
             & (1U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000052U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000052U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000052U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000052U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
                = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
        }
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s 
            = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_b[1U]), (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
                  >> 1U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x00000054U) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x00000054U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))) 
             & (1U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000052U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000052U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000052U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000052U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
                = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
        = (0x0bU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
    if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[2U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U] = 2U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s 
            = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_b[2U], (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
                  >> 2U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x00000054U) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x00000054U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))) 
             & (2U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000052U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000052U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000052U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000052U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
                = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
        }
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s 
            = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_b[2U]), (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
                  >> 2U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x00000054U) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x00000054U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))) 
             & (2U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000052U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000052U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000052U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000052U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
                = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
        = (7U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
    if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[3U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U] = 2U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
            = (8U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s 
            = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_b[3U], (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
                  >> 3U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x00000054U) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x00000054U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))) 
             & (3U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000052U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000052U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000052U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000052U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
                = (8U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
        }
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s 
            = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_b[3U]), (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
                  >> 3U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x00000054U) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x00000054U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))) 
             & (3U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000052U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000053U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000052U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000052U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000052U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v 
                = (8U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v));
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
        = (0x0eU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_locked[0U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_src[0U];
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    } else if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[0U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U] = 2U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s 
            = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_r[0U], (IData)(2U));
        if ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v)) 
              & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                 [(((IData)(0x0000004aU) + (0x000000ffU 
                                            & ((IData)(0x00000058U) 
                                               * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                   >> 5U)] >> (0x0000001fU & ((IData)(0x0000004aU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))) 
             & (0U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000048U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000049U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000048U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000048U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000048U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
                = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
        }
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s 
            = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_r[0U]), (IData)(2U));
        if ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v)) 
              & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                 [(((IData)(0x0000004aU) + (0x000000ffU 
                                            & ((IData)(0x00000058U) 
                                               * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                   >> 5U)] >> (0x0000001fU & ((IData)(0x0000004aU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))) 
             & (0U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000048U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000049U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000048U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000048U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000048U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
                = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
        = (0x0dU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_locked[1U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_src[1U];
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    } else if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[1U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U] = 2U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s 
            = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_r[1U], (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
                  >> 1U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x0000004aU) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x0000004aU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))) 
             & (1U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000048U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000049U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000048U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000048U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000048U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
                = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
        }
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s 
            = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_r[1U]), (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
                  >> 1U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x0000004aU) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x0000004aU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))) 
             & (1U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000048U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000049U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000048U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000048U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000048U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
                = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
        = (0x0bU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_locked[2U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_src[2U];
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    } else if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[2U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U] = 2U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s 
            = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_r[2U], (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
                  >> 2U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x0000004aU) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x0000004aU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))) 
             & (2U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000048U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000049U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000048U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000048U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000048U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
                = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
        }
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s 
            = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_r[2U]), (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
                  >> 2U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x0000004aU) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x0000004aU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))) 
             & (2U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000048U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000049U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000048U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000048U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000048U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
                = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
        }
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
        = (7U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_locked[3U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_src[3U];
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
            = (8U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    } else if (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[3U]) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U] = 2U;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
            = (8U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
    } else {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s 
            = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_r[3U], (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
                  >> 3U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x0000004aU) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x0000004aU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))) 
             & (3U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000048U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000049U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000048U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000048U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000048U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
                = (8U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
        }
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s 
            = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_r[3U]), (IData)(2U));
        if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
                  >> 3U)) & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x0000004aU) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                               >> 5U)] >> (0x0000001fU 
                                           & ((IData)(0x0000004aU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))) 
             & (3U == (3U & (((0U == (0x0000001fU & 
                                      ((IData)(0x00000048U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                       [(((IData)(0x00000049U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(0x00000048U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                [(((IData)(0x00000048U) 
                                   + (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(0x00000048U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s)))))))))) {
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U] 
                = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
            vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v 
                = (8U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v));
        }
    }
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
        = vlSelfRef.axi4_xbar_tb__DOT__mst_req[1U];
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout = 2U;
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
          >= vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U]) 
         & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
            < vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U]))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout 
            = (7U & vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U]);
    }
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
          >= ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
               << 0x0000001dU) | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                  >> 3U))) & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
                                              < ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                                  << 0x0000001dU) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] 
                                                    >> 3U))))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout 
            = (7U & (vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
                     >> 3U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U] 
        = __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok = 
        ((0x0eU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok)) 
         | (((vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
              >> 1U) & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_out[0U])) 
            & ((0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rid_cnt[0U]
                [(0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U])]) 
               | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rid_dst[0U]
                  [(0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U])] 
                  == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
        = ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            << 7U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[7U] 
                      >> 0x00000019U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout = 2U;
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
          >= vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U]) 
         & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
            < vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U]))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout 
            = (7U & vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U]);
    }
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
          >= ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
               << 0x0000001dU) | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                  >> 3U))) & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
                                              < ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                                  << 0x0000001dU) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] 
                                                    >> 3U))))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout 
            = (7U & (vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
                     >> 3U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U] 
        = __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok = 
        ((0x0dU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok)) 
         | ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
               >> 0x0000001aU) & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_out[1U])) 
             & ((0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rid_cnt[1U]
                 [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                  >> 0x00000019U))]) 
                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rid_dst[1U]
                   [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                    >> 0x00000019U))] 
                   == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))) 
            << 1U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
        = ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            << 0x0000000eU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[14U] 
                               >> 0x00000012U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout = 2U;
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
          >= vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U]) 
         & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
            < vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U]))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout 
            = (7U & vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U]);
    }
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
          >= ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
               << 0x0000001dU) | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                  >> 3U))) & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
                                              < ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                                  << 0x0000001dU) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] 
                                                    >> 3U))))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout 
            = (7U & (vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
                     >> 3U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U] 
        = __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok = 
        ((0x0bU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok)) 
         | ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
               >> 0x00000013U) & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_out[2U])) 
             & ((0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rid_cnt[2U]
                 [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                  >> 0x00000012U))]) 
                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rid_dst[2U]
                   [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                    >> 0x00000012U))] 
                   == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))) 
            << 2U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
        = ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            << 0x00000015U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[21U] 
                               >> 0x0000000bU));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout = 2U;
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
          >= vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U]) 
         & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
            < vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U]))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout 
            = (7U & vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U]);
    }
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
          >= ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
               << 0x0000001dU) | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                  >> 3U))) & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__a 
                                              < ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                                  << 0x0000001dU) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] 
                                                    >> 3U))))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout 
            = (7U & (vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
                     >> 3U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U] 
        = __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__32__Vfuncout;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok = 
        ((7U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok)) 
         | ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
               >> 0x0000000cU) & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_out[3U])) 
             & ((0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rid_cnt[3U]
                 [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                  >> 0x0000000bU))]) 
                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rid_dst[3U]
                   [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                    >> 0x0000000bU))] 
                   == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))) 
            << 3U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
        = ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
            << 0x0000000bU) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[5U] 
                               >> 0x00000015U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout = 2U;
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
          >= vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U]) 
         & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
            < vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U]))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout 
            = (7U & vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U]);
    }
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
          >= ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
               << 0x0000001dU) | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                  >> 3U))) & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
                                              < ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                                  << 0x0000001dU) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] 
                                                    >> 3U))))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout 
            = (7U & (vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
                     >> 3U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U] 
        = __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok = 
        ((0x0eU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok)) 
         | ((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
               >> 0x00000010U) & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_out[0U])) 
             & VL_GTS_III(32, 8U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__awq_tl[0U] 
                                   - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__awq_hd[0U]))) 
            & ((0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wid_cnt[0U]
                [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                 >> 0x00000015U))]) 
               | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wid_dst[0U]
                  [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                   >> 0x00000015U))] 
                  == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
        = ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
            << 0x00000012U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[12U] 
                               >> 0x0000000eU));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout = 2U;
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
          >= vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U]) 
         & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
            < vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U]))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout 
            = (7U & vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U]);
    }
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
          >= ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
               << 0x0000001dU) | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                  >> 3U))) & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
                                              < ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                                  << 0x0000001dU) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] 
                                                    >> 3U))))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout 
            = (7U & (vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
                     >> 3U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U] 
        = __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok = 
        ((0x0dU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok)) 
         | (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                >> 9U) & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_out[1U])) 
              & VL_GTS_III(32, 8U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__awq_tl[1U] 
                                    - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__awq_hd[1U]))) 
             & ((0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wid_cnt[1U]
                 [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                  >> 0x0000000eU))]) 
                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wid_dst[1U]
                   [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                    >> 0x0000000eU))] 
                   == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))) 
            << 1U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
        = ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
            << 0x00000019U) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[19U] 
                               >> 7U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout = 2U;
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
          >= vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U]) 
         & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
            < vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U]))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout 
            = (7U & vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U]);
    }
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
          >= ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
               << 0x0000001dU) | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                  >> 3U))) & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
                                              < ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                                  << 0x0000001dU) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] 
                                                    >> 3U))))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout 
            = (7U & (vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
                     >> 3U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U] 
        = __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok = 
        ((0x0bU & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok)) 
         | (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                >> 2U) & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_out[2U])) 
              & VL_GTS_III(32, 8U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__awq_tl[2U] 
                                    - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__awq_hd[2U]))) 
             & ((0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wid_cnt[2U]
                 [(0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                  >> 7U))]) | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wid_dst[2U]
                                               [(0x0000000fU 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                                    >> 7U))] 
                                               == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))) 
            << 2U));
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
        = vlSelfRef.axi4_xbar_tb__DOT__mst_req[26U];
    __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout = 2U;
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
          >= vlSelfRef.axi4_xbar_tb__DOT__addr_map[1U]) 
         & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
            < vlSelfRef.axi4_xbar_tb__DOT__addr_map[0U]))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout 
            = (7U & vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U]);
    }
    if (((__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
          >= ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
               << 0x0000001dU) | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                  >> 3U))) & (__Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__a 
                                              < ((vlSelfRef.axi4_xbar_tb__DOT__addr_map[3U] 
                                                  << 0x0000001dU) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__addr_map[2U] 
                                                    >> 3U))))) {
        __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout 
            = (7U & (vlSelfRef.axi4_xbar_tb__DOT__addr_map[4U] 
                     >> 3U));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U] 
        = __Vfunc_axi4_xbar_tb__DOT__dut__DOT__decode__33__Vfuncout;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok = 
        ((7U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok)) 
         | (((((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                >> 0x0000001bU) & VL_GTS_III(32, 8U, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_out[3U])) 
              & VL_GTS_III(32, 8U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__awq_tl[3U] 
                                    - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__awq_hd[3U]))) 
             & ((0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wid_cnt[3U]
                 [(0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[27U])]) 
                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wid_dst[3U]
                   [(0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT__mst_req[27U])] 
                   == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))) 
            << 3U));
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
        = (6U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[0U], (IData)(4U));
    if ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v)) 
          & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
             >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[0U]), (IData)(4U));
    if ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v)) 
          & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
             >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(2U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[0U]), (IData)(4U));
    if ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v)) 
          & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
             >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(3U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[0U]), (IData)(4U));
    if ((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v)) 
          & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
             >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
        = (5U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[1U], (IData)(4U));
    if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
              >> 1U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                         >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[1U]), (IData)(4U));
    if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
              >> 1U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                         >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(2U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[1U]), (IData)(4U));
    if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
              >> 1U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                         >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(3U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[1U]), (IData)(4U));
    if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
              >> 1U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                         >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
        = (3U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[2U], (IData)(4U));
    if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
              >> 2U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                         >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[2U]), (IData)(4U));
    if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
              >> 2U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                         >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(2U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[2U]), (IData)(4U));
    if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
              >> 2U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                         >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(3U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_ar[2U]), (IData)(4U));
    if ((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
              >> 2U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                         >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m))) 
         & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst
            [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m)]))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk3__DOT__unnamedblk4__DOT__unnamedblk5__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
        = (6U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[0U], (IData)(4U));
    if (((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v)) 
           & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
              >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[0U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[0U]), (IData)(4U));
    if (((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v)) 
           & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
              >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[0U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(2U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[0U]), (IData)(4U));
    if (((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v)) 
           & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
              >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[0U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(3U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[0U]), (IData)(4U));
    if (((((~ (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v)) 
           & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
              >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[0U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[0U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (1U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
        = (5U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[1U], (IData)(4U));
    if (((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
               >> 1U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                          >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[1U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[1U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[1U]), (IData)(4U));
    if (((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
               >> 1U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                          >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[1U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[1U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(2U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[1U]), (IData)(4U));
    if (((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
               >> 1U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                          >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[1U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[1U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(3U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[1U]), (IData)(4U));
    if (((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
               >> 1U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                          >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[1U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[1U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (2U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
        = (3U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[2U], (IData)(4U));
    if (((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
               >> 2U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                          >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[2U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[2U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(1U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[2U]), (IData)(4U));
    if (((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
               >> 2U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                          >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[2U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[2U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(2U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[2U]), (IData)(4U));
    if (((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
               >> 2U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                          >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[2U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[2U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
        = VL_MODDIVS_III(32, ((IData)(3U) + vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__rr_aw[2U]), (IData)(4U));
    if (((((~ ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
               >> 2U)) & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                          >> (3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m))) 
          & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst
             [(3U & axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)])) 
         & VL_GTS_III(32, 0x00000020U, (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_tl[2U] 
                                        - vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__wsq_hd[2U])))) {
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 
            = axi4_xbar_tb__DOT__dut__DOT__unnamedblk10__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[2U] 
            = vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v 
            = (4U | (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = (0xe0000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xfffffffdU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (2U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                    << 1U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
        = ((0xffffffc0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
           | (0x0000003fU & (VL_SHIFTL_III(6,6,32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U], 4U) 
                             | (0x0000000fU & (((0U 
                                                 == 
                                                 (0x0000001fU 
                                                  & ((IData)(0x00000040U) 
                                                     + 
                                                     (0x000003ffU 
                                                      & ((IData)(0x000000d9U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
                                                 ? 0U
                                                 : 
                                                (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000003ffU 
                                                     & ((IData)(0x000000d9U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                                   >> 5U)] 
                                                 << 
                                                 ((IData)(0x00000020U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(0x00000040U) 
                                                      + 
                                                      (0x000003ffU 
                                                       & ((IData)(0x000000d9U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
                                               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                  [
                                                  (((IData)(0x00000040U) 
                                                    + 
                                                    (0x000003ffU 
                                                     & ((IData)(0x000000d9U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                                   >> 5U)] 
                                                  >> 
                                                  (0x0000001fU 
                                                   & ((IData)(0x00000040U) 
                                                      + 
                                                      (0x000003ffU 
                                                       & ((IData)(0x000000d9U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[1U] 
        = (((0U == (0x0000001fU & ((IData)(0x00000020U) 
                                   + (0x000003ffU & 
                                      ((IData)(0x000000d9U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
             ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                     [(((IData)(0x0000003fU) + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                       >> 5U)] << ((IData)(0x00000020U) 
                                   - (0x0000001fU & 
                                      ((IData)(0x00000020U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
           | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[
              (((IData)(0x00000020U) + (0x000003ffU 
                                        & ((IData)(0x000000d9U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
               >> 5U)] >> (0x0000001fU & ((IData)(0x00000020U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x00000018U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x0000001fU) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x00000018U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x00000018U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x00000018U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))) 
              << 0x00000018U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xff1fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (0x00e00000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000015U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000017U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000015U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000015U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000015U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))) 
                             << 0x00000015U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xffe7ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (0x00180000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000013U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000014U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000013U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000013U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000013U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))) 
                             << 0x00000013U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xfffbffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (0x00040000U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x00000012U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x00000012U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))) 
                             << 0x00000012U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xfffc3fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (0x0003c000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x0000000eU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000011U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x0000000eU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x0000000eU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x0000000eU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))) 
                             << 0x0000000eU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xffffc7ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (0x00003800U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x0000000bU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000000dU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x0000000bU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x0000000bU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x0000000bU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))) 
                             << 0x0000000bU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xfffff87fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (0x00000780U & ((((0U == (0x0000001fU 
                                       & ((IData)(7U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000000aU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(7U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(7U) + (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(7U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))) 
                             << 7U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xffffff87U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (0x00000078U & ((((0U == (0x0000001fU 
                                       & ((IData)(3U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(6U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(3U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(3U) + (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(3U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U])))))) 
                             << 3U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = ((0xfffffffbU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
           | (4U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                     [(((IData)(2U) + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))) 
                       >> 5U)] >> (0x0000001fU & ((IData)(2U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[0U]))))) 
                    << 2U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = ((0xfffbffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
           | (0x00040000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                             << 0x00000012U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0xe07fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | (0x1f800000U & ((VL_SHIFTL_III(6,6,32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U], 4U) 
                              | (0x0000000fU & (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & ((IData)(0x000000d5U) 
                                                      + 
                                                      (0x000003ffU 
                                                       & ((IData)(0x000000d9U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                                  ? 0U
                                                  : 
                                                 (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                  [
                                                  (((IData)(0x000000d8U) 
                                                    + 
                                                    (0x000003ffU 
                                                     & ((IData)(0x000000d9U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                                   >> 5U)] 
                                                  << 
                                                  ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(0x000000d5U) 
                                                       + 
                                                       (0x000003ffU 
                                                        & ((IData)(0x000000d9U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                   [
                                                   (((IData)(0x000000d5U) 
                                                     + 
                                                     (0x000003ffU 
                                                      & ((IData)(0x000000d9U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                                    >> 5U)] 
                                                   >> 
                                                   (0x0000001fU 
                                                    & ((IData)(0x000000d5U) 
                                                       + 
                                                       (0x000003ffU 
                                                        & ((IData)(0x000000d9U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))))) 
                             << 0x00000017U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0x007fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x000000b5U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x000000d4U) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x000000b5U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x000000b5U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x000000b5U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
              << 0x00000017U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0xff800000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x000000b5U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x000000d4U) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x000000b5U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x000000b5U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x000000b5U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
              >> 9U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xff807fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x007f8000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000adU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000b4U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000adU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000adU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000adU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 0x0000000fU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xffff8fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x00007000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000aaU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000acU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000aaU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000aaU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000aaU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 0x0000000cU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xfffff3ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x00000c00U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a8U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a9U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a8U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a8U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a8U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 0x0000000aU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xfffffdffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x00000200U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x000000a7U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x000000a7U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))) 
                             << 9U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xfffffe1fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x000001e0U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a3U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a6U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a3U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a3U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a3U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 5U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xffffffe3U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x0000001cU & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a0U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a2U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a0U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a0U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a0U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 2U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = ((0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x0000009cU) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x0000009fU) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x0000009cU) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x0000009cU) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x0000009cU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
              << 0x0000001eU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (3U & ((((0U == (0x0000001fU & ((IData)(0x0000009cU) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                       ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                               [(((IData)(0x0000009fU) 
                                  + (0x000003ffU & 
                                     ((IData)(0x000000d9U) 
                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                 >> 5U)] << ((IData)(0x00000020U) 
                                             - (0x0000001fU 
                                                & ((IData)(0x0000009cU) 
                                                   + 
                                                   (0x000003ffU 
                                                    & ((IData)(0x000000d9U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                     | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                        [(((IData)(0x0000009cU) + (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                          >> 5U)] >> (0x0000001fU & 
                                      ((IData)(0x0000009cU) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                    >> 2U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = ((0xc3ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
           | (0x3c000000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000098U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000009bU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000098U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000098U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000098U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 0x0000001aU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = ((0xfff7ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
           | (0x00080000U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x00000091U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x00000091U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))) 
                             << 0x00000013U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
        = (0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = (0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]);
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
          & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
            >> 5U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = (0x00000080U | ((0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
                              | (0xffffff00U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                                << 2U))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
            = (((0x0000007cU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                << 2U)) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                           >> 0x0000001eU)) 
               | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                          >> 5U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                      << 0x0000001bU) 
                                     | (0x07fffffeU 
                                        & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                           >> 5U)))) 
                  << 7U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
            = ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                           >> 5U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                       << 0x0000001bU) 
                                      | (0x07fffffeU 
                                         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                            >> 5U)))) 
                   >> 0x00000019U) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                              >> 5U)) 
                                       | (0x000007feU 
                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                             >> 5U))) 
                                      << 7U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 1U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            >> 0x0000001eU))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = (0x00000080U | ((0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                  << 9U) | (0x00000100U 
                                            & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                               >> 0x00000017U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
            = ((0x0000007fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                               >> 0x00000017U)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                        >> 0x0000001eU)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                        << 2U) 
                                                       | (2U 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                             >> 0x0000001eU)))) 
                                                   << 7U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
            = ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                           >> 0x0000001eU)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                << 2U) 
                                               | (2U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                     >> 0x0000001eU)))) 
                   >> 0x00000019U) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                              >> 0x0000001eU)) 
                                       | (0x000007feU 
                                          & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                                              << 2U) 
                                             | (2U 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                   >> 0x0000001eU))))) 
                                      << 7U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 2U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            >> 0x00000017U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = (0x00000080U | ((0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                  << 0x00000010U) | 
                                 (0x0000ff00U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                                 >> 0x00000010U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
            = ((0x0000007fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                               >> 0x00000010U)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                        >> 0x00000017U)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                        << 9U) 
                                                       | (0x000001feU 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                             >> 0x00000017U)))) 
                                                   << 7U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
            = ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                           >> 0x00000017U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                << 9U) 
                                               | (0x000001feU 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                     >> 0x00000017U)))) 
                   >> 0x00000019U) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                              >> 0x00000017U)) 
                                       | (0x000007feU 
                                          & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                                              << 9U) 
                                             | (0x000001feU 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                   >> 0x00000017U))))) 
                                      << 7U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 3U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            >> 0x00000010U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = (0x00000080U | ((0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                  << 0x00000017U) | 
                                 (0x007fff00U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                                 >> 9U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
            = ((0x0000007fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                               >> 9U)) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                  >> 0x00000010U)) 
                                           | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                               << 0x00000010U) 
                                              | (0x0000fffeU 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                    >> 0x00000010U)))) 
                                          << 7U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
            = ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                           >> 0x00000010U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                << 0x00000010U) 
                                               | (0x0000fffeU 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                     >> 0x00000010U)))) 
                   >> 0x00000019U) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                              >> 0x00000010U)) 
                                       | (0x000007feU 
                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                             >> 0x00000010U))) 
                                      << 7U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = (0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
        = (0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]);
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
         & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
               | (1U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]));
    }
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
         & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
               | (0x00000040U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                 << 2U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 1U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
               | (1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                        >> 0x00000019U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 1U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
               | (0x00000040U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                 >> 0x00000017U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 2U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
               | (1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                        >> 0x00000012U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 2U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
               | (0x00000040U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                 >> 0x00000010U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 3U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
               | (1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                        >> 0x0000000bU)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 3U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
               | (0x00000040U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                 >> 9U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = (0x1fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0xbfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | (0x40000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                             << 0x0000001dU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
        = ((0x1fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U]) 
           | ((VL_SHIFTL_III(6,6,32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U], 4U) 
               | (0x0000000fU & (((0U == (0x0000001fU 
                                          & ((IData)(0x00000040U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                   ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                           [(((IData)(0x00000043U) 
                                              + (0x000003ffU 
                                                 & ((IData)(0x000000d9U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                             >> 5U)] 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(0x00000040U) 
                                                     + 
                                                     (0x000003ffU 
                                                      & ((IData)(0x000000d9U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                                 | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                    [(((IData)(0x00000040U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                      >> 5U)] >> (0x0000001fU 
                                                  & ((IData)(0x00000040U) 
                                                     + 
                                                     (0x000003ffU 
                                                      & ((IData)(0x000000d9U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))))) 
              << 0x0000001dU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = ((0xfffffff8U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
           | (7U & ((VL_SHIFTL_III(6,6,32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U], 4U) 
                     | (0x0000000fU & (((0U == (0x0000001fU 
                                                & ((IData)(0x00000040U) 
                                                   + 
                                                   (0x000003ffU 
                                                    & ((IData)(0x000000d9U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                         ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000003ffU 
                                                     & ((IData)(0x000000d9U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                                   >> 5U)] 
                                                 << 
                                                 ((IData)(0x00000020U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(0x00000040U) 
                                                      + 
                                                      (0x000003ffU 
                                                       & ((IData)(0x000000d9U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                                       | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                          [(((IData)(0x00000040U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                            >> 5U)] 
                                          >> (0x0000001fU 
                                              & ((IData)(0x00000040U) 
                                                 + 
                                                 (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))))) 
                    >> 3U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0x1fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x00000020U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x0000003fU) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x00000020U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x00000020U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x00000020U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
              << 0x0000001dU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
        = ((0xe0000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x00000020U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x0000003fU) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x00000020U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x00000020U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x00000020U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
              >> 3U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xe01fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x1fe00000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000018U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000001fU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000018U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000018U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000018U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 0x00000015U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xffe3ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x001c0000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000015U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000017U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000015U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000015U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000015U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 0x00000012U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xfffcffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x00030000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000013U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000014U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000013U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000013U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000013U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 0x00000010U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xffff7fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x00008000U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x00000012U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x00000012U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))) 
                             << 0x0000000fU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xffff87ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x00007800U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x0000000eU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000011U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x0000000eU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x0000000eU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x0000000eU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 0x0000000bU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xfffff8ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x00000700U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x0000000bU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000000dU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x0000000bU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x0000000bU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x0000000bU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 8U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xffffff0fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x000000f0U & ((((0U == (0x0000001fU 
                                       & ((IData)(7U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000000aU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(7U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(7U) + (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(7U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 4U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x0000000fU & (((0U == (0x0000001fU & 
                                      ((IData)(3U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                       [(((IData)(6U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(3U) 
                                              + (0x000003ffU 
                                                 & ((IData)(0x000000d9U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                [(((IData)(3U) + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(3U) 
                                                 + 
                                                 (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0x7fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
               [(((IData)(2U) + (0x000003ffU & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                 >> 5U)] >> (0x0000001fU & ((IData)(2U) 
                                            + (0x000003ffU 
                                               & ((IData)(0x000000d9U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))) 
              << 0x0000001fU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0xffff7fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | (0x00008000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                             << 0x0000000eU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] 
        = ((0x000fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U]) 
           | (0x03f00000U & ((VL_SHIFTL_III(6,6,32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U], 4U) 
                              | (0x0000000fU & (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & ((IData)(0x000000d5U) 
                                                      + 
                                                      (0x000003ffU 
                                                       & ((IData)(0x000000d9U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                                  ? 0U
                                                  : 
                                                 (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                  [
                                                  (((IData)(0x000000d8U) 
                                                    + 
                                                    (0x000003ffU 
                                                     & ((IData)(0x000000d9U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                                   >> 5U)] 
                                                  << 
                                                  ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(0x000000d5U) 
                                                       + 
                                                       (0x000003ffU 
                                                        & ((IData)(0x000000d9U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                   [
                                                   (((IData)(0x000000d5U) 
                                                     + 
                                                     (0x000003ffU 
                                                      & ((IData)(0x000000d9U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                                    >> 5U)] 
                                                   >> 
                                                   (0x0000001fU 
                                                    & ((IData)(0x000000d5U) 
                                                       + 
                                                       (0x000003ffU 
                                                        & ((IData)(0x000000d9U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))))) 
                             << 0x00000014U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0x000fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x000000b5U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x000000d4U) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x000000b5U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x000000b5U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x000000b5U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
              << 0x00000014U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] 
        = ((0x03f00000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U]) 
           | (0x03ffffffU & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000b5U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000d4U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000b5U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000b5U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000b5U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             >> 0x0000000cU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xfff00fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x000ff000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000adU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000b4U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000adU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000adU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000adU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 0x0000000cU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xfffff1ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x00000e00U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000aaU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000acU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000aaU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000aaU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000aaU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 9U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xfffffe7fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x00000180U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a8U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a9U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a8U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a8U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a8U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 7U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x00000040U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x000000a7U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x000000a7U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))) 
                             << 6U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xffffffc3U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x0000003cU & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a3U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a6U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a3U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a3U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a3U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 2U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0x7fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x000000a0U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x000000a2U) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x000000a0U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x000000a0U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x000000a0U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
              << 0x0000001fU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (3U & ((((0U == (0x0000001fU & ((IData)(0x000000a0U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                       ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                               [(((IData)(0x000000a2U) 
                                  + (0x000003ffU & 
                                     ((IData)(0x000000d9U) 
                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                 >> 5U)] << ((IData)(0x00000020U) 
                                             - (0x0000001fU 
                                                & ((IData)(0x000000a0U) 
                                                   + 
                                                   (0x000003ffU 
                                                    & ((IData)(0x000000d9U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                     | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                        [(((IData)(0x000000a0U) + (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                          >> 5U)] >> (0x0000001fU & 
                                      ((IData)(0x000000a0U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                    >> 1U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0x87ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | (0x78000000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x0000009cU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000009fU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x0000009cU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x0000009cU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x0000009cU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 0x0000001bU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0xf87fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | (0x07800000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000098U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000009bU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000098U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000098U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000098U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 0x00000017U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | (0x00010000U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x00000091U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x00000091U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))) 
                             << 0x00000010U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = (0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = (0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]);
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
          & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
            >> 5U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = (0x00000010U | ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                  << 0x0000001fU) | 
                                 (0x7fffffe0U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                                 >> 1U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
            = ((0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                               >> 1U)) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                                  >> 5U)) 
                                           | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                               << 0x0000001bU) 
                                              | (0x07fffffeU 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                                    >> 5U)))) 
                                          << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
            = ((0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                           >> 5U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                       << 0x0000001bU) 
                                      | (0x07fffffeU 
                                         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                            >> 5U)))) 
                   >> 0x0000001cU) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                              >> 5U)) 
                                       | (0x000007feU 
                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                             >> 5U))) 
                                      << 4U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 1U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            >> 0x0000001eU))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = (0x00000010U | ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                  << 6U) | (0x00000020U 
                                            & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                               >> 0x0000001aU)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
            = ((0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                               >> 0x0000001aU)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                        >> 0x0000001eU)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                        << 2U) 
                                                       | (2U 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                             >> 0x0000001eU)))) 
                                                   << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
            = ((0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                           >> 0x0000001eU)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                << 2U) 
                                               | (2U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                     >> 0x0000001eU)))) 
                   >> 0x0000001cU) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                              >> 0x0000001eU)) 
                                       | (0x000007feU 
                                          & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                                              << 2U) 
                                             | (2U 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                   >> 0x0000001eU))))) 
                                      << 4U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 2U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            >> 0x00000017U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = (0x00000010U | ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                  << 0x0000000dU) | 
                                 (0x00001fe0U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                                 >> 0x00000013U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
            = ((0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                               >> 0x00000013U)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                        >> 0x00000017U)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                        << 9U) 
                                                       | (0x000001feU 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                             >> 0x00000017U)))) 
                                                   << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
            = ((0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                           >> 0x00000017U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                << 9U) 
                                               | (0x000001feU 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                     >> 0x00000017U)))) 
                   >> 0x0000001cU) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                              >> 0x00000017U)) 
                                       | (0x000007feU 
                                          & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                                              << 9U) 
                                             | (0x000001feU 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                   >> 0x00000017U))))) 
                                      << 4U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 3U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            >> 0x00000010U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = (0x00000010U | ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                  << 0x00000014U) | 
                                 (0x000fffe0U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                                 >> 0x0000000cU)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
            = ((0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                               >> 0x0000000cU)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                        >> 0x00000010U)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                        << 0x00000010U) 
                                                       | (0x0000fffeU 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                             >> 0x00000010U)))) 
                                                   << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
            = ((0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                           >> 0x00000010U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                << 0x00000010U) 
                                               | (0x0000fffeU 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                     >> 0x00000010U)))) 
                   >> 0x0000001cU) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                              >> 0x00000010U)) 
                                       | (0x000007feU 
                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                             >> 0x00000010U))) 
                                      << 4U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = (0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = (0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]);
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
         & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
               | (0x20000000U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
                                 << 0x0000001dU)));
    }
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
         & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = ((0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
               | (8U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                        >> 1U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 1U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
               | (0x20000000U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                 << 4U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 1U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = ((0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
               | (8U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                        >> 0x0000001aU)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 2U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
               | (0x20000000U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                 << 0x0000000bU)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 2U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = ((0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
               | (8U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                        >> 0x00000013U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 3U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
               | (0x20000000U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                 << 0x00000012U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 3U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = ((0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
               | (8U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                        >> 0x0000000cU)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = (0xfff00000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0xfffbffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                 & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))
                     ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                        >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))
                     : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___35))) 
                & (0U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___36))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[0U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000056U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000056U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))))))) 
              << 0x00000012U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0xfff7ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                 & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))
                     ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                        >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))
                     : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___37))) 
                & (0U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___38))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[0U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000057U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000057U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))))))) 
              << 0x00000013U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0xfffdffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | (0x00020000U & (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
                              & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U]) 
                                 | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                    [(((IData)(0x00000055U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U]))) 
                                      >> 5U)] >> (0x0000001fU 
                                                  & ((IData)(0x00000055U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U]))))))) 
                             << 0x00000011U)));
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
         & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = (0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]);
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffffe00U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[0U] 
                   << 8U) | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_id[0U] 
                             << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0xfffffff1U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | (0xfffffffeU & (0x0000000cU | ((1U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_left[0U]) 
                                                << 1U))));
    } else if ((1U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffffeffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00000100U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004aU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004aU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))) 
                                 << 8U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xffffff0fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x000000f0U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x00000044U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000047U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000044U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))) 
                                 << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000043U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                              >> 5U)])) 
                            << ((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                 ? 0x00000020U : ((IData)(0x00000040U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                           | (((0U == (0x0000001fU 
                                       & ((IData)(4U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                          [
                                                          (((IData)(0x00000023U) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000058U) 
                                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                           >> 5U)])) 
                                          << ((IData)(0x00000020U) 
                                              - (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                 [(
                                                   ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                   >> 5U)])) 
                                 >> (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))))) 
                  << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U] 
            = (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                          [(((IData)(0x00000043U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                            >> 5U)])) 
                          << ((0U == (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                               ? 0x00000020U : ((IData)(0x00000040U) 
                                                - (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                         | (((0U == (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                              ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                        [
                                                        (((IData)(0x00000023U) 
                                                          + 
                                                          (0x000000ffU 
                                                           & ((IData)(0x00000058U) 
                                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                         >> 5U)])) 
                                        << ((IData)(0x00000020U) 
                                            - (0x0000001fU 
                                               & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                            | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                               [(((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                 >> 5U)])) 
                               >> (0x0000001fU & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))))) 
                >> 0x0000001cU) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                              [
                                                              (((IData)(0x00000043U) 
                                                                + 
                                                                (0x000000ffU 
                                                                 & ((IData)(0x00000058U) 
                                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                               >> 5U)])) 
                                              << ((0U 
                                                   == 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                                   ? 0x00000020U
                                                   : 
                                                  ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                             | (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                                  ? 0ULL
                                                  : 
                                                 ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                  [
                                                                  (((IData)(0x00000023U) 
                                                                    + 
                                                                    (0x000000ffU 
                                                                     & ((IData)(0x00000058U) 
                                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                                   >> 5U)])) 
                                                  << 
                                                  ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                                | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                   [
                                                                   (((IData)(4U) 
                                                                     + 
                                                                     (0x000000ffU 
                                                                      & ((IData)(0x00000058U) 
                                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                                    >> 5U)])) 
                                                   >> 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                            >> 0x00000020U)) 
                                   << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                             [(((IData)(0x00000043U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                               >> 5U)])) 
                             << ((0U == (0x0000001fU 
                                         & ((IData)(4U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                  ? 0x00000020U : ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                            | (((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                 ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                           [
                                                           (((IData)(0x00000023U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000058U) 
                                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                            >> 5U)])) 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(4U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                               | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                  [
                                                  (((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                   >> 5U)])) 
                                  >> (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                           >> 0x00000020U)) >> 0x0000001cU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0xfffffff3U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | (0x0000000cU & ((((0U == (0x0000001fU 
                                           & ((IData)(2U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(3U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(2U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))) 
                                 << 2U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0xfffffffdU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | (2U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                         [(((IData)(1U) + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                           >> 5U)] >> (0x0000001fU 
                                       & ((IData)(1U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))) 
                        << 1U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | (1U & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                        [(7U & (((IData)(0x00000058U) 
                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]) 
                                >> 5U))] >> (0x0000001fU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))));
    }
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
         & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffe03ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0xfffffc00U & (0x00000c00U | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[0U] 
                                                 << 0x00000010U) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_id[0U] 
                                                   << 0x0000000cU)))));
    } else if ((1U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00010000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x00000054U) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x00000054U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))))) 
                                 << 0x00000010U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xffff0fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x0000f000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004eU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000051U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004eU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U])))))) 
                                 << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffff3ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00000c00U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004cU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x0000004dU) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004cU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U])))))) 
                                 << 0x0000000aU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffffdffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00000200U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004bU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004bU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))))) 
                                 << 9U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = (0x000fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = (0xffffff00U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                  >> 1U) & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))
                             ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                                >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))
                             : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___35))) 
                & (1U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___36))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[1U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000056U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000056U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))))))) 
              << 6U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0xffffff7fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                  >> 1U) & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))
                             ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                                >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))
                             : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___37))) 
                & (1U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___38))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[1U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000057U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000057U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))))))) 
              << 7U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0xffffffdfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | (0x00000020U & (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
                              << 4U) & (((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U]) 
                                         | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000055U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U]))) 
                                              >> 5U)] 
                                            >> (0x0000001fU 
                                                & ((IData)(0x00000055U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U])))))) 
                                        << 5U))));
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 1U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = (0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]);
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xe0000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[1U] 
                   << 0x0000001cU) | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_id[1U] 
                                      << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xff1fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0xffe00000U & (0x00c00000U | ((1U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_left[1U]) 
                                                << 0x00000015U))));
    } else if ((2U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xefffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | (0x10000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004aU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004aU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))) 
                                 << 0x0000001cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xf0ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | (0x0f000000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x00000044U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000047U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000044U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))) 
                                 << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000043U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                              >> 5U)])) 
                            << ((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                 ? 0x00000020U : ((IData)(0x00000040U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                           | (((0U == (0x0000001fU 
                                       & ((IData)(4U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                          [
                                                          (((IData)(0x00000023U) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000058U) 
                                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                           >> 5U)])) 
                                          << ((IData)(0x00000020U) 
                                              - (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                 [(
                                                   ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                   >> 5U)])) 
                                 >> (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))))) 
                  << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U] 
            = (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                          [(((IData)(0x00000043U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                            >> 5U)])) 
                          << ((0U == (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                               ? 0x00000020U : ((IData)(0x00000040U) 
                                                - (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                         | (((0U == (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                              ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                        [
                                                        (((IData)(0x00000023U) 
                                                          + 
                                                          (0x000000ffU 
                                                           & ((IData)(0x00000058U) 
                                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                         >> 5U)])) 
                                        << ((IData)(0x00000020U) 
                                            - (0x0000001fU 
                                               & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                            | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                               [(((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                 >> 5U)])) 
                               >> (0x0000001fU & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))))) 
                >> 8U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                     [
                                                     (((IData)(0x00000043U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                      >> 5U)])) 
                                     << ((0U == (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                          ? 0x00000020U
                                          : ((IData)(0x00000040U) 
                                             - (0x0000001fU 
                                                & ((IData)(4U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                    | (((0U == (0x0000001fU 
                                                & ((IData)(4U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                         ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                   [
                                                                   (((IData)(0x00000023U) 
                                                                     + 
                                                                     (0x000000ffU 
                                                                      & ((IData)(0x00000058U) 
                                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                                    >> 5U)])) 
                                                   << 
                                                   ((IData)(0x00000020U) 
                                                    - 
                                                    (0x0000001fU 
                                                     & ((IData)(4U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000058U) 
                                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                       | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                          [
                                                          (((IData)(4U) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000058U) 
                                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                           >> 5U)])) 
                                          >> (0x0000001fU 
                                              & ((IData)(4U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                   >> 0x00000020U)) 
                          << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xff000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                             [(((IData)(0x00000043U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                               >> 5U)])) 
                             << ((0U == (0x0000001fU 
                                         & ((IData)(4U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                  ? 0x00000020U : ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                            | (((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                 ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                           [
                                                           (((IData)(0x00000023U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000058U) 
                                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                            >> 5U)])) 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(4U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                               | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                  [
                                                  (((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                   >> 5U)])) 
                                  >> (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                           >> 0x00000020U)) >> 8U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xff3fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00c00000U & ((((0U == (0x0000001fU 
                                           & ((IData)(2U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(3U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(2U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))) 
                                 << 0x00000016U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xffdfffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00200000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(1U) + 
                                     (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(1U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))) 
                                 << 0x00000015U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xffefffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00100000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(7U & (((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]) 
                                          >> 5U))] 
                                  >> (0x0000001fU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                 << 0x00000014U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 1U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = (0xc0000000U | (0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xffffffe0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x3fffffffU & ((0x3ffffff0U & (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[1U] 
                                                 << 4U)) 
                                 | (0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_id[1U]))));
    } else if ((2U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xffffffefU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x00000010U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x00000054U) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x00000054U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))) 
                                 << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x0000000fU & (((0U == (0x0000001fU 
                                          & ((IData)(0x0000004eU) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U])))))
                                   ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                           [(((IData)(0x00000051U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                                             >> 5U)] 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(0x0000004eU) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))))) 
                                 | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                    [(((IData)(0x0000004eU) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                                      >> 5U)] >> (0x0000001fU 
                                                  & ((IData)(0x0000004eU) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | ((((0U == (0x0000001fU & ((IData)(0x0000004cU) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U])))))
                     ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x0000004dU) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                               >> 5U)] << ((IData)(0x00000020U) 
                                           - (0x0000001fU 
                                              & ((IData)(0x0000004cU) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))))) 
                   | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x0000004cU) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x0000004cU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U])))))) 
                  << 0x0000001eU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | (0x20000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004bU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004bU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))) 
                                 << 0x0000001dU)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = (0x000000ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = (0xf0000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0xfbffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                  >> 2U) & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))
                             ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                                >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))
                             : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___35))) 
                & (2U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___36))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[2U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000056U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000056U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))))))) 
              << 0x0000001aU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0xf7ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                  >> 2U) & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))
                             ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                                >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))
                             : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___37))) 
                & (2U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___38))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[2U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000057U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000057U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))))))) 
              << 0x0000001bU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0xfdffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | (0x02000000U & (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
                              << 0x00000017U) & (((2U 
                                                   == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U]) 
                                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                     [
                                                     (((IData)(0x00000055U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U]))) 
                                                      >> 5U)] 
                                                     >> 
                                                     (0x0000001fU 
                                                      & ((IData)(0x00000055U) 
                                                         + 
                                                         (0x000000ffU 
                                                          & ((IData)(0x00000058U) 
                                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U])))))) 
                                                 << 0x00000019U))));
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 2U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = (0x00000fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]);
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfffe0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[2U] 
                   << 0x00000010U) | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_id[2U] 
                                      << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffff1ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0xfffffe00U & (0x00000c00U | ((1U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_left[2U]) 
                                                << 9U))));
    } else if ((4U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x00010000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004aU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004aU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))) 
                                 << 0x00000010U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xffff0fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x0000f000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x00000044U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000047U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000044U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))) 
                                 << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0x00000fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000043U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                              >> 5U)])) 
                            << ((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                 ? 0x00000020U : ((IData)(0x00000040U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                           | (((0U == (0x0000001fU 
                                       & ((IData)(4U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                          [
                                                          (((IData)(0x00000023U) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000058U) 
                                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                           >> 5U)])) 
                                          << ((IData)(0x00000020U) 
                                              - (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                 [(
                                                   ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                   >> 5U)])) 
                                 >> (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))))) 
                  << 0x0000000cU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U] 
            = (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                          [(((IData)(0x00000043U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                            >> 5U)])) 
                          << ((0U == (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                               ? 0x00000020U : ((IData)(0x00000040U) 
                                                - (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                         | (((0U == (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                              ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                        [
                                                        (((IData)(0x00000023U) 
                                                          + 
                                                          (0x000000ffU 
                                                           & ((IData)(0x00000058U) 
                                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                         >> 5U)])) 
                                        << ((IData)(0x00000020U) 
                                            - (0x0000001fU 
                                               & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                            | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                               [(((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                 >> 5U)])) 
                               >> (0x0000001fU & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))))) 
                >> 0x00000014U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                              [
                                                              (((IData)(0x00000043U) 
                                                                + 
                                                                (0x000000ffU 
                                                                 & ((IData)(0x00000058U) 
                                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                               >> 5U)])) 
                                              << ((0U 
                                                   == 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                                   ? 0x00000020U
                                                   : 
                                                  ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                             | (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                                  ? 0ULL
                                                  : 
                                                 ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                  [
                                                                  (((IData)(0x00000023U) 
                                                                    + 
                                                                    (0x000000ffU 
                                                                     & ((IData)(0x00000058U) 
                                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                                   >> 5U)])) 
                                                  << 
                                                  ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                                | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                   [
                                                                   (((IData)(4U) 
                                                                     + 
                                                                     (0x000000ffU 
                                                                      & ((IData)(0x00000058U) 
                                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                                    >> 5U)])) 
                                                   >> 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                            >> 0x00000020U)) 
                                   << 0x0000000cU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfffff000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                             [(((IData)(0x00000043U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                               >> 5U)])) 
                             << ((0U == (0x0000001fU 
                                         & ((IData)(4U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                  ? 0x00000020U : ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                            | (((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                 ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                           [
                                                           (((IData)(0x00000023U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000058U) 
                                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                            >> 5U)])) 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(4U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                               | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                  [
                                                  (((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                   >> 5U)])) 
                                  >> (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                           >> 0x00000020U)) >> 0x00000014U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffff3ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x00000c00U & ((((0U == (0x0000001fU 
                                           & ((IData)(2U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(3U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(2U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))) 
                                 << 0x0000000aU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffffdffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x00000200U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(1U) + 
                                     (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(1U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))) 
                                 << 9U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffffeffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x00000100U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(7U & (((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]) 
                                          >> 5U))] 
                                  >> (0x0000001fU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                 << 8U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 2U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfe03ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0xfffc0000U & (0x000c0000U | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[2U] 
                                                 << 0x00000018U) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_id[2U] 
                                                   << 0x00000014U)))));
    } else if ((4U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfeffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x01000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x00000054U) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x00000054U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))))) 
                                 << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xff0fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x00f00000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004eU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000051U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004eU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U])))))) 
                                 << 0x00000014U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfff3ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x000c0000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004cU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x0000004dU) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004cU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U])))))) 
                                 << 0x00000012U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfffdffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x00020000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004bU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004bU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))))) 
                                 << 0x00000011U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = (0x0fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
        = ((0x0000bfffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
           | (0x0000ffffU & ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                                 >> 3U) & ((2U >= (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))
                                            ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                                               >> (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))
                                            : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___35))) 
                               & (3U == ((2U >= (3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))
                                          ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win
                                         [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U])]
                                          : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___36))) 
                              & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U])
                                  ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[3U])
                                  : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000056U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000056U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))))))) 
                             << 0x0000000eU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
        = ((0x00007fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
           | (0x0000ffffU & ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                                 >> 3U) & ((2U >= (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))
                                            ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                                               >> (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))
                                            : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___37))) 
                               & (3U == ((2U >= (3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))
                                          ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win
                                         [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U])]
                                          : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___38))) 
                              & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U])
                                  ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[3U])
                                  : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000057U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000057U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))))))) 
                             << 0x0000000fU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
        = ((0x0000dfffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
           | (0x0000ffffU & ((IData)((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
                                       >> 3U) & ((2U 
                                                  == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U]) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                    [
                                                    (((IData)(0x00000055U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U]))) 
                                                     >> 5U)] 
                                                    >> 
                                                    (0x0000001fU 
                                                     & ((IData)(0x00000055U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000058U) 
                                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U])))))))) 
                             << 0x0000000dU)));
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 3U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000ffe0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x0000ffffU & ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[3U] 
                                  << 4U) | vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_id[3U])));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0x1fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0xe0000000U & (0xc0000000U | ((1U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_left[3U]) 
                                                << 0x0000001dU))));
    } else if ((8U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000ffefU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x00000010U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004aU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004aU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))) 
                                 << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000fff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x0000000fU & (((0U == (0x0000001fU 
                                          & ((IData)(0x00000044U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                                   ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                           [(((IData)(0x00000047U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                             >> 5U)] 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(0x00000044U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                                 | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                    [(((IData)(0x00000044U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                      >> 5U)] >> (0x0000001fU 
                                                  & ((IData)(0x00000044U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U] 
            = (IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                        [(((IData)(0x00000043U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                          >> 5U)])) 
                        << ((0U == (0x0000001fU & ((IData)(4U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                             ? 0x00000020U : ((IData)(0x00000040U) 
                                              - (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                       | (((0U == (0x0000001fU & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                            ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                      [
                                                      (((IData)(0x00000023U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000058U) 
                                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                                       >> 5U)])) 
                                      << ((IData)(0x00000020U) 
                                          - (0x0000001fU 
                                             & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                          | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                             [(((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                               >> 5U)])) 
                             >> (0x0000001fU & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U] 
            = (IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                         [(((IData)(0x00000043U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                           >> 5U)])) 
                         << ((0U == (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                              ? 0x00000020U : ((IData)(0x00000040U) 
                                               - (0x0000001fU 
                                                  & ((IData)(4U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                        | (((0U == (0x0000001fU & ((IData)(4U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                             ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                       [
                                                       (((IData)(0x00000023U) 
                                                         + 
                                                         (0x000000ffU 
                                                          & ((IData)(0x00000058U) 
                                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                                        >> 5U)])) 
                                       << ((IData)(0x00000020U) 
                                           - (0x0000001fU 
                                              & ((IData)(4U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                           | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                              [(((IData)(4U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                                >> 5U)])) 
                              >> (0x0000001fU & ((IData)(4U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                       >> 0x00000020U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | ((((0U == (0x0000001fU & ((IData)(2U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                     ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(3U) + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                               >> 5U)] << ((IData)(0x00000020U) 
                                           - (0x0000001fU 
                                              & ((IData)(2U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                   | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(2U) + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(2U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))) 
                  << 0x0000001eU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x20000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(1U) + 
                                     (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(1U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))) 
                                 << 0x0000001dU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xefffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x10000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(7U & (((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]) 
                                          >> 5U))] 
                                  >> (0x0000001fU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                 << 0x0000001cU)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 3U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000e03fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x0000ffc0U & (0x000000c0U | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[3U] 
                                                 << 0x0000000cU) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_id[3U] 
                                                   << 8U)))));
    } else if ((8U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000efffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x00001000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x00000054U) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x00000054U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))))) 
                                 << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000f0ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x00000f00U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004eU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000051U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004eU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U])))))) 
                                 << 8U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000ff3fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x000000c0U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004cU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x0000004dU) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004cU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U])))))) 
                                 << 6U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000ffdfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x00000020U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004bU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004bU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))))) 
                                 << 5U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT__lm_off = ((((2U & 
                                              ((VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U]) 
                                                | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U]) 
                                                   | (((~ 
                                                        (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                                         >> 0x0000000eU)) 
                                                       & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                                          >> 0x0000000cU)) 
                                                      | ((~ 
                                                          (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                                           >> 0x0000000fU)) 
                                                         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                            >> 0x0000001bU))))) 
                                               << 1U)) 
                                             | (1U 
                                                & (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U]) 
                                                   | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U]) 
                                                      | (((~ 
                                                           (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                            >> 0x0000001aU)) 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                                             >> 0x00000013U)) 
                                                         | ((~ 
                                                             (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                              >> 0x0000001bU)) 
                                                            & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                                                               >> 2U))))))) 
                                            << 2U) 
                                           | ((2U & 
                                               ((VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U]) 
                                                 | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U]) 
                                                    | (((~ 
                                                         (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                                          >> 6U)) 
                                                        & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                                           >> 0x0000001aU)) 
                                                       | ((~ 
                                                           (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                                            >> 7U)) 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                                                             >> 9U))))) 
                                                << 1U)) 
                                              | (1U 
                                                 & (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U]) 
                                                    | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U]) 
                                                       | (((~ 
                                                            (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                             >> 0x00000012U)) 
                                                           & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
                                                              >> 1U)) 
                                                          | ((~ 
                                                              (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                               >> 0x00000013U)) 
                                                             & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                                                >> 0x00000010U))))))));
}
