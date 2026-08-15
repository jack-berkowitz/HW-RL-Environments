// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxi4_xbar_tb.h for the primary calling header

#ifndef VERILATED_VAXI4_XBAR_TB___024ROOT_H_
#define VERILATED_VAXI4_XBAR_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vaxi4_xbar_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxi4_xbar_tb___024root final {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ axi4_xbar_tb__DOT__clk;
        CData/*0:0*/ axi4_xbar_tb__DOT__rst_n;
        CData/*0:0*/ axi4_xbar_tb__DOT__lm_stall_fired;
        CData/*0:0*/ axi4_xbar_tb__DOT__lm_starve_fired;
        CData/*0:0*/ axi4_xbar_tb__DOT__lm_any_off;
        CData/*0:0*/ axi4_xbar_tb__DOT__lm_any_srv;
        CData/*3:0*/ axi4_xbar_tb__DOT__lm_off_s;
        CData/*3:0*/ axi4_xbar_tb__DOT__lm_srv_s;
        CData/*1:0*/ axi4_xbar_tb__DOT__tmode;
        CData/*0:0*/ axi4_xbar_tb__DOT__cap_drain;
        CData/*3:0*/ axi4_xbar_tb__DOT__cap_en;
        CData/*3:0*/ axi4_xbar_tb__DOT__ar_hold;
        CData/*3:0*/ axi4_xbar_tb__DOT__aw_hold;
        CData/*3:0*/ axi4_xbar_tb__DOT__lm_off;
        CData/*0:0*/ axi4_xbar_tb__DOT__unnamedblk16__DOT__done;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___37;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___35;
        CData/*3:0*/ axi4_xbar_tb__DOT__dut__DOT__ar_ok;
        CData/*2:0*/ axi4_xbar_tb__DOT__dut__DOT__ar_win_v;
        CData/*3:0*/ axi4_xbar_tb__DOT__dut__DOT__r_pick_v;
        CData/*3:0*/ axi4_xbar_tb__DOT__dut__DOT__aw_ok;
        CData/*2:0*/ axi4_xbar_tb__DOT__dut__DOT__aw_win_v;
        CData/*3:0*/ axi4_xbar_tb__DOT__dut__DOT__w_go;
        CData/*3:0*/ axi4_xbar_tb__DOT__dut__DOT__b_pick_v;
        CData/*0:0*/ __VstlFirstIteration;
        CData/*0:0*/ __VstlPhaseResult;
        CData/*0:0*/ __Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0;
        CData/*0:0*/ __VactPhaseResult;
        CData/*0:0*/ __VinactPhaseResult;
        CData/*0:0*/ __VnbaPhaseResult;
        IData/*31:0*/ axi4_xbar_tb__DOT__errors;
        IData/*31:0*/ axi4_xbar_tb__DOT__checks;
        IData/*31:0*/ axi4_xbar_tb__DOT__lm_global_idle;
        IData/*31:0*/ axi4_xbar_tb__DOT__lm_worst_wait;
        IData/*31:0*/ axi4_xbar_tb__DOT__lm_worst_req;
        IData/*31:0*/ axi4_xbar_tb__DOT__cov_rd_ok;
        IData/*31:0*/ axi4_xbar_tb__DOT__cov_rd_dec;
        IData/*31:0*/ axi4_xbar_tb__DOT__cov_wr_ok;
        IData/*31:0*/ axi4_xbar_tb__DOT__cov_wr_dec;
        IData/*31:0*/ axi4_xbar_tb__DOT__cov_burst_gt1;
        IData/*31:0*/ axi4_xbar_tb__DOT__cov_cross_id;
        IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk5__DOT__unnamedblk6__DOT__i;
        IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk10__DOT__unnamedblk11__DOT__r;
        IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk10__DOT__unnamedblk11__DOT__rw;
        IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk20__DOT__miss;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf107b68c__0;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___41;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hcb0a2858__0;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___40;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___39;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h733c413f__0;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h76251b52__0;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vlvbound_ha20258df__0;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___38;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___36;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___8;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___7;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vxrand___6;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vlvbound_hf128da05__1;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT____Vlvbound_h06f52684__1;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT__unnamedblk6__DOT__unnamedblk7__DOT__unnamedblk8__DOT__s;
        IData/*31:0*/ axi4_xbar_tb__DOT__dut__DOT__unnamedblk14__DOT__unnamedblk15__DOT__unnamedblk16__DOT__s;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__0__a;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__1__a;
    };
    struct {
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__2__a;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__3__a;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__4__a;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__5__a;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__5__beat;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__8__a;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__9__a;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__9__beat;
        IData/*31:0*/ __VactIterCount;
        IData/*31:0*/ __VinactIterCount;
        IData/*31:0*/ __Vi;
        VlWide<28>/*867:0*/ axi4_xbar_tb__DOT__mst_req;
        VlWide<6>/*175:0*/ axi4_xbar_tb__DOT__slv_resp;
        VlWide<5>/*133:0*/ axi4_xbar_tb__DOT__addr_map;
        VlWide<14>/*441:0*/ axi4_xbar_tb__DOT____Vcellout__dut__slv_req;
        VlWide<11>/*335:0*/ axi4_xbar_tb__DOT____Vcellout__dut__mst_resp;
        QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__0__Vfuncout;
        QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__1__Vfuncout;
        QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__2__Vfuncout;
        QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__3__Vfuncout;
        QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__4__Vfuncout;
        QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__5__Vfuncout;
        QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__8__Vfuncout;
        QData/*63:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__9__Vfuncout;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__lm_wait;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__lm_served_count;
        VlUnpacked<VlUnpacked<VlUnpacked<IData/*31:0*/, 64>, 4>, 4> axi4_xbar_tb__DOT__rq_addr;
        VlUnpacked<VlUnpacked<VlUnpacked<IData/*31:0*/, 64>, 4>, 4> axi4_xbar_tb__DOT__rq_len;
        VlUnpacked<VlUnpacked<VlUnpacked<CData/*0:0*/, 64>, 4>, 4> axi4_xbar_tb__DOT__rq_dec;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 4>, 4> axi4_xbar_tb__DOT__rq_head;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 4>, 4> axi4_xbar_tb__DOT__rq_tail;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 4>, 4> axi4_xbar_tb__DOT__rq_beat;
        VlUnpacked<VlUnpacked<VlUnpacked<CData/*0:0*/, 64>, 4>, 4> axi4_xbar_tb__DOT__wq_dec;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 4>, 4> axi4_xbar_tb__DOT__wq_head;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 4>, 4> axi4_xbar_tb__DOT__wq_tail;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__last_rid;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__cap_tgt;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__cap_ar_cnt;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__cap_done_cnt;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__txn_sent;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__outstanding_r;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__outstanding_w;
        VlUnpacked<CData/*3:0*/, 4> axi4_xbar_tb__DOT__nxt_id;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__nxt_addr;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__nxt_len;
        VlUnpacked<CData/*0:0*/, 4> axi4_xbar_tb__DOT__nxt_dec;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__w_left;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__w_addr;
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__s_rbeats;
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__s_rdelay;
        VlUnpacked<CData/*5:0*/, 2> axi4_xbar_tb__DOT__s_rid;
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__s_raddr;
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__s_rn;
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__s_wbeats;
        VlUnpacked<CData/*5:0*/, 2> axi4_xbar_tb__DOT__s_wid;
        VlUnpacked<CData/*0:0*/, 2> axi4_xbar_tb__DOT__s_bpend;
        VlUnpacked<VlUnpacked<CData/*5:0*/, 32>, 2> axi4_xbar_tb__DOT__pq_id;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 32>, 2> axi4_xbar_tb__DOT__pq_adr;
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__pq_hd;
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__pq_tl;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__r_out;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 16>, 4> axi4_xbar_tb__DOT__dut__DOT__rid_cnt;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 16>, 4> axi4_xbar_tb__DOT__dut__DOT__rid_dst;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__ar_dst;
    };
    struct {
        VlUnpacked<IData/*31:0*/, 3> axi4_xbar_tb__DOT__dut__DOT__rr_ar;
        VlUnpacked<IData/*31:0*/, 3> axi4_xbar_tb__DOT__dut__DOT__ar_win;
        VlUnpacked<CData/*0:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__err_r_busy;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__err_r_left;
        VlUnpacked<CData/*3:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__err_r_id;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__r_src;
        VlUnpacked<CData/*0:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__r_locked;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__rr_r;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__r_pick;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__w_out;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 16>, 4> axi4_xbar_tb__DOT__dut__DOT__wid_cnt;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 16>, 4> axi4_xbar_tb__DOT__dut__DOT__wid_dst;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__aw_dst;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 8>, 4> axi4_xbar_tb__DOT__dut__DOT__awq;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__awq_hd;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__awq_tl;
        VlUnpacked<VlUnpacked<IData/*31:0*/, 32>, 3> axi4_xbar_tb__DOT__dut__DOT__wsq;
        VlUnpacked<IData/*31:0*/, 3> axi4_xbar_tb__DOT__dut__DOT__wsq_hd;
        VlUnpacked<IData/*31:0*/, 3> axi4_xbar_tb__DOT__dut__DOT__wsq_tl;
        VlUnpacked<IData/*31:0*/, 3> axi4_xbar_tb__DOT__dut__DOT__rr_aw;
        VlUnpacked<IData/*31:0*/, 3> axi4_xbar_tb__DOT__dut__DOT__aw_win;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__w_dst;
        VlUnpacked<CData/*0:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__err_b_busy;
        VlUnpacked<CData/*3:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__err_b_id;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__rr_b;
        VlUnpacked<IData/*31:0*/, 4> axi4_xbar_tb__DOT__dut__DOT__b_pick;
        VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
        VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
        VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
        VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    };
    std::string axi4_xbar_tb__DOT__fail_reason;
    std::string axi4_xbar_tb__DOT__phase;
    std::string axi4_xbar_tb__DOT__lm_reason;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__6__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__7__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__10__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__11__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__12__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__13__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__14__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__15__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__17__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__19__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__20__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__21__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__22__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__23__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__24__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__25__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__26__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__27__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__28__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__29__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__30__why;
    std::string __Vtask_axi4_xbar_tb__DOT__note_fail__31__why;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_ha9bc5c2b__0;

    // INTERNAL VARIABLES
    Vaxi4_xbar_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vaxi4_xbar_tb___024root(Vaxi4_xbar_tb__Syms* symsp, const char* namep);
    ~Vaxi4_xbar_tb___024root();
    VL_UNCOPYABLE(Vaxi4_xbar_tb___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
