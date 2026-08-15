// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxi4_xbar_tb.h for the primary calling header

#ifndef VERILATED_VAXI4_XBAR_TB_AXI_ERR_SLV__PI5_H_
#define VERILATED_VAXI4_XBAR_TB_AXI_ERR_SLV__PI5_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vaxi4_xbar_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxi4_xbar_tb_axi_err_slv__pi5 final {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ clk_i;
        CData/*0:0*/ rst_ni;
        CData/*0:0*/ test_i;
        CData/*0:0*/ __PVT__w_fifo_empty;
        CData/*0:0*/ __PVT__w_fifo_push;
        CData/*0:0*/ __PVT__w_fifo_pop;
        CData/*0:0*/ __PVT__b_fifo_pop;
        CData/*0:0*/ __PVT__r_fifo_push;
        CData/*0:0*/ __PVT__r_fifo_pop;
        CData/*0:0*/ __PVT__r_busy_d;
        CData/*0:0*/ __PVT__r_busy_q;
        CData/*0:0*/ __PVT__r_busy_load;
        CData/*0:0*/ __VdfgExtracted_h2ee1ee4a__0;
        CData/*0:0*/ __VdfgRegularize_h247165ad_0_6;
        CData/*1:0*/ __PVT__i_w_fifo__DOT__read_pointer_n;
        CData/*1:0*/ __PVT__i_w_fifo__DOT__read_pointer_q;
        CData/*1:0*/ __PVT__i_w_fifo__DOT__write_pointer_n;
        CData/*1:0*/ __PVT__i_w_fifo__DOT__write_pointer_q;
        CData/*2:0*/ __PVT__i_w_fifo__DOT__status_cnt_n;
        CData/*2:0*/ __PVT__i_w_fifo__DOT__status_cnt_q;
        SData/*15:0*/ __PVT__i_w_fifo__DOT__mem_n;
        SData/*15:0*/ __PVT__i_w_fifo__DOT__mem_q;
        CData/*0:0*/ __PVT__i_b_fifo__DOT__read_pointer_n;
        CData/*0:0*/ __PVT__i_b_fifo__DOT__read_pointer_q;
        CData/*0:0*/ __PVT__i_b_fifo__DOT__write_pointer_n;
        CData/*0:0*/ __PVT__i_b_fifo__DOT__write_pointer_q;
        CData/*1:0*/ __PVT__i_b_fifo__DOT__status_cnt_n;
        CData/*1:0*/ __PVT__i_b_fifo__DOT__status_cnt_q;
        CData/*7:0*/ __PVT__i_b_fifo__DOT__mem_n;
        CData/*7:0*/ __PVT__i_b_fifo__DOT__mem_q;
        CData/*1:0*/ __PVT__i_r_fifo__DOT__read_pointer_n;
        CData/*1:0*/ __PVT__i_r_fifo__DOT__read_pointer_q;
        CData/*1:0*/ __PVT__i_r_fifo__DOT__write_pointer_n;
        CData/*1:0*/ __PVT__i_r_fifo__DOT__write_pointer_q;
        CData/*2:0*/ __PVT__i_r_fifo__DOT__status_cnt_n;
        CData/*2:0*/ __PVT__i_r_fifo__DOT__status_cnt_q;
        CData/*7:0*/ __VdfgRegularize_hebeb780c_0_111;
        CData/*7:0*/ __VdfgRegularize_hebeb780c_0_113;
        CData/*7:0*/ __VdfgRegularize_hebeb780c_0_115;
        CData/*7:0*/ __VdfgRegularize_hebeb780c_0_117;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_351;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_352;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_353;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_354;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_355;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_356;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_357;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_358;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__r_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q;
    };
    struct {
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__r_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__r_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_w_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_empty;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__w_fifo_pop;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_b_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__b_fifo_pop;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__i_r_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__r_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____PVT__r_fifo_pop;
        SData/*11:0*/ __PVT__r_fifo_data;
        SData/*11:0*/ i_r_fifo__DOT____Vlvbound_h93549ebf__0;
        SData/*11:0*/ i_r_fifo__DOT____Vxrand___0;
        QData/*47:0*/ __PVT__i_r_fifo__DOT__mem_n;
        QData/*47:0*/ __PVT__i_r_fifo__DOT__mem_q;
        SData/*8:0*/ __PVT__i_r_counter__DOT__i_counter__DOT__counter_q;
        SData/*8:0*/ __PVT__i_r_counter__DOT__i_counter__DOT__counter_d;
        VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_112;
        VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_114;
        VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_116;
        VlWide<3>/*72:0*/ __VdfgRegularize_hebeb780c_0_118;
        VlWide<7>/*216:0*/ slv_req_i;
        VlWide<3>/*83:0*/ slv_resp_o;
    };

    // INTERNAL VARIABLES
    Vaxi4_xbar_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vaxi4_xbar_tb_axi_err_slv__pi5();
    ~Vaxi4_xbar_tb_axi_err_slv__pi5();
    void ctor(Vaxi4_xbar_tb__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(Vaxi4_xbar_tb_axi_err_slv__pi5);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
