// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxi4_xbar_tb.h for the primary calling header

#ifndef VERILATED_VAXI4_XBAR_TB___024ROOT_H_
#define VERILATED_VAXI4_XBAR_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"
class Vaxi4_xbar_tb_axi_demux__pi4;
class Vaxi4_xbar_tb_axi_err_slv__pi5;
class Vaxi4_xbar_tb_axi_mux__pi3;


class Vaxi4_xbar_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxi4_xbar_tb___024root final {
  public:
    // CELLS
    Vaxi4_xbar_tb_axi_mux__pi3* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux;
    Vaxi4_xbar_tb_axi_mux__pi3* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux;
    Vaxi4_xbar_tb_axi_demux__pi4* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux;
    Vaxi4_xbar_tb_axi_err_slv__pi5* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv;
    Vaxi4_xbar_tb_axi_demux__pi4* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux;
    Vaxi4_xbar_tb_axi_err_slv__pi5* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv;
    Vaxi4_xbar_tb_axi_demux__pi4* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux;
    Vaxi4_xbar_tb_axi_err_slv__pi5* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv;
    Vaxi4_xbar_tb_axi_demux__pi4* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux;
    Vaxi4_xbar_tb_axi_err_slv__pi5* __PVT__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv;

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
        CData/*3:0*/ axi4_xbar_tb__DOT__bp_r;
        CData/*3:0*/ axi4_xbar_tb__DOT__bp_b;
        CData/*1:0*/ axi4_xbar_tb__DOT__tmode;
        CData/*0:0*/ axi4_xbar_tb__DOT__cap_drain;
        CData/*3:0*/ axi4_xbar_tb__DOT__cap_en;
        CData/*3:0*/ axi4_xbar_tb__DOT__ar_hold;
        CData/*3:0*/ axi4_xbar_tb__DOT__aw_hold;
        CData/*3:0*/ axi4_xbar_tb__DOT__lm_off;
        CData/*0:0*/ axi4_xbar_tb__DOT__unnamedblk20__DOT__done;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_aw_error;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__dec_ar_error;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_aw_error;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__dec_ar_error;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_aw_error;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__dec_ar_error;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_aw_error;
        CData/*0:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__dec_ar_error;
        CData/*1:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules;
        CData/*1:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules;
        CData/*1:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules;
        CData/*1:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules;
        CData/*1:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules;
        CData/*1:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules;
        CData/*1:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_aw_decode__DOT__i_addr_decode_dync__DOT__matched_rules;
        CData/*1:0*/ axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_ar_decode__DOT__i_addr_decode_dync__DOT__matched_rules;
        CData/*0:0*/ __VstlFirstIteration;
        CData/*0:0*/ __VstlPhaseResult;
        CData/*0:0*/ __Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__rst_n__0;
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
        IData/*31:0*/ axi4_xbar_tb__DOT__cov_max_len;
        IData/*31:0*/ axi4_xbar_tb__DOT__bp_r_stalls;
        IData/*31:0*/ axi4_xbar_tb__DOT__bp_b_stalls;
        IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk9__DOT__unnamedblk10__DOT__i;
        IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__r;
    };
    struct {
        IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk14__DOT__unnamedblk15__DOT__rw;
        IData/*31:0*/ axi4_xbar_tb__DOT__unnamedblk24__DOT__miss;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__0__a;
        IData/*31:0*/ __Vfunc_axi4_xbar_tb__DOT__expected_beat__1__a;
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
        VlWide<6>/*191:0*/ axi4_xbar_tb__DOT__dut__DOT____Vcellinp__u_xbar__addr_map_i;
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
        VlUnpacked<SData/*15:0*/, 4> axi4_xbar_tb__DOT__bp_lfsr;
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
    };
    struct {
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__pq_hd;
        VlUnpacked<IData/*31:0*/, 2> axi4_xbar_tb__DOT__pq_tl;
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
