// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

VL_ATTR_COLD void Vaxi4_xbar_tb___024root___stl_sequent__TOP__0(Vaxi4_xbar_tb___024root* vlSelf);

VL_ATTR_COLD void Vaxi4_xbar_tb___024root___eval_stl(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_stl\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
        Vaxi4_xbar_tb___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vaxi4_xbar_tb___024root___eval_triggers_vec__stl(Vaxi4_xbar_tb___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi4_xbar_tb___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vaxi4_xbar_tb___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

VL_ATTR_COLD bool Vaxi4_xbar_tb___024root___eval_phase__stl(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_phase__stl\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    Vaxi4_xbar_tb___024root___eval_triggers_vec__stl(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vaxi4_xbar_tb___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vaxi4_xbar_tb___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        Vaxi4_xbar_tb___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool Vaxi4_xbar_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi4_xbar_tb___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vaxi4_xbar_tb___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge axi4_xbar_tb.clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vaxi4_xbar_tb___024root___ctor_var_reset(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___ctor_var_reset\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->axi4_xbar_tb__DOT__rst_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1121128169962788083ull);
    VL_SCOPED_RAND_RESET_W(868, vlSelf->axi4_xbar_tb__DOT__mst_req, __VscopeHash, 14816058496560004866ull);
    VL_SCOPED_RAND_RESET_W(176, vlSelf->axi4_xbar_tb__DOT__slv_resp, __VscopeHash, 16822972949463820768ull);
    VL_SCOPED_RAND_RESET_W(134, vlSelf->axi4_xbar_tb__DOT__addr_map, __VscopeHash, 4057234052230581778ull);
    VL_ZERO_RESET_W(442, vlSelf->axi4_xbar_tb__DOT____Vcellout__dut__slv_req);
    VL_ZERO_RESET_W(336, vlSelf->axi4_xbar_tb__DOT____Vcellout__dut__mst_resp);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__lm_wait[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__lm_served_count[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__lm_any_off = 0;
    vlSelf->axi4_xbar_tb__DOT__lm_any_srv = 0;
    vlSelf->axi4_xbar_tb__DOT__lm_off_s = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 16202183794806023771ull);
    vlSelf->axi4_xbar_tb__DOT__lm_srv_s = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 1864400738677718721ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            for (int __Vi2 = 0; __Vi2 < 64; ++__Vi2) {
                vlSelf->axi4_xbar_tb__DOT__rq_addr[__Vi0][__Vi1][__Vi2] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10352884790536275177ull);
            }
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            for (int __Vi2 = 0; __Vi2 < 64; ++__Vi2) {
                vlSelf->axi4_xbar_tb__DOT__rq_len[__Vi0][__Vi1][__Vi2] = 0;
            }
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            for (int __Vi2 = 0; __Vi2 < 64; ++__Vi2) {
                vlSelf->axi4_xbar_tb__DOT__rq_dec[__Vi0][__Vi1][__Vi2] = 0;
            }
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__rq_head[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__rq_tail[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__rq_beat[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            for (int __Vi2 = 0; __Vi2 < 64; ++__Vi2) {
                vlSelf->axi4_xbar_tb__DOT__wq_dec[__Vi0][__Vi1][__Vi2] = 0;
            }
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__wq_head[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__wq_tail[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__last_rid[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__cap_drain = 0;
    vlSelf->axi4_xbar_tb__DOT__cap_en = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 10181012902851289682ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__cap_tgt[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__cap_ar_cnt[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__cap_done_cnt[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__txn_sent[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__outstanding_r[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__outstanding_w[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__ar_hold = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3819929037913807640ull);
    vlSelf->axi4_xbar_tb__DOT__aw_hold = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 9290842883470389687ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__nxt_id[__Vi0] = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 11742499936767930776ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__nxt_addr[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10956683426606002574ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__nxt_len[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__nxt_dec[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__w_left[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__w_addr[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10767198330713664319ull);
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__s_rbeats[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__s_rdelay[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__s_rid[__Vi0] = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 2865211611946003416ull);
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__s_raddr[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7596674930871782368ull);
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__s_rn[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__s_wbeats[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__s_wid[__Vi0] = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 8901191846949942449ull);
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__s_bpend[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 32; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__pq_id[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 9424148848442886869ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 32; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__pq_adr[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15711371641666555262ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__pq_hd[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__pq_tl[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__lm_off = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 17966080467632961638ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf107b68c__0 = 0;
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___41 = VL_SCOPED_RAND_RESET_ASSIGN_I(32, __VscopeHash, 10464748719205584756ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hcb0a2858__0 = 0;
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___40 = VL_SCOPED_RAND_RESET_ASSIGN_I(32, __VscopeHash, 3658796341394764812ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___39 = VL_SCOPED_RAND_RESET_ASSIGN_I(32, __VscopeHash, 8211086261699233176ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h733c413f__0 = 0;
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h76251b52__0 = 0;
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vlvbound_ha20258df__0 = 0;
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___38 = VL_SCOPED_RAND_RESET_ASSIGN_I(32, __VscopeHash, 4478825530612641279ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___37 = VL_SCOPED_RAND_RESET_ASSIGN_I(1, __VscopeHash, 15471055066425726167ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___36 = VL_SCOPED_RAND_RESET_ASSIGN_I(32, __VscopeHash, 12798096995291879324ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___35 = VL_SCOPED_RAND_RESET_ASSIGN_I(1, __VscopeHash, 17514279360266644147ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___8 = VL_SCOPED_RAND_RESET_ASSIGN_I(32, __VscopeHash, 17610815760476787842ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___7 = VL_SCOPED_RAND_RESET_ASSIGN_I(32, __VscopeHash, 2478891768265486238ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vxrand___6 = VL_SCOPED_RAND_RESET_ASSIGN_I(32, __VscopeHash, 4807381954149822553ull);
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1 = 0;
    vlSelf->axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1 = 0;
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__r_out[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 16; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__dut__DOT__rid_cnt[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 16; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__dut__DOT__rid_dst[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__ar_dst[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__dut__DOT__ar_ok = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 1180135510790726488ull);
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__rr_ar[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__ar_win[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__dut__DOT__ar_win_v = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 224591576062080086ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__err_r_busy[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6000469154605163761ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__err_r_left[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__err_r_id[__Vi0] = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3206607340457964754ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__r_src[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__r_locked[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18290540668382192571ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__rr_r[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__r_pick[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__dut__DOT__r_pick_v = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 17493264315822644208ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__w_out[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 16; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__dut__DOT__wid_cnt[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 16; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__dut__DOT__wid_dst[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__aw_dst[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__dut__DOT__aw_ok = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 14791358275617957092ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 8; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__dut__DOT__awq[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__awq_hd[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__awq_tl[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 32; ++__Vi1) {
            vlSelf->axi4_xbar_tb__DOT__dut__DOT__wsq[__Vi0][__Vi1] = 0;
        }
    }
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__wsq_hd[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__wsq_tl[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__rr_aw[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__aw_win[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__dut__DOT__aw_win_v = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 13107741370611633138ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__w_dst[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__dut__DOT__w_go = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 4514973474733975172ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__err_b_busy[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18202625427880974787ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__err_b_id[__Vi0] = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 9808618938917526505ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__rr_b[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->axi4_xbar_tb__DOT__dut__DOT__b_pick[__Vi0] = 0;
    }
    vlSelf->axi4_xbar_tb__DOT__dut__DOT__b_pick_v = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 2688449277937546906ull);
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__0__a = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__1__a = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__2__a = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__3__a = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__Vfuncout = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__4__a = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__Vfuncout = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__a = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__5__beat = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__Vfuncout = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__8__a = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__Vfuncout = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__a = 0;
    vlSelf->__Vfunc_axi4_xbar_tb__DOT__expected_beat__9__beat = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
