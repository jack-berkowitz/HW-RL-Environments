// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxi4_xbar_tb.h for the primary calling header

#ifndef VERILATED_VAXI4_XBAR_TB_AXI_MUX__PI3_H_
#define VERILATED_VAXI4_XBAR_TB_AXI_MUX__PI3_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vaxi4_xbar_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxi4_xbar_tb_axi_mux__pi3 final {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ clk_i;
        CData/*0:0*/ rst_ni;
        CData/*0:0*/ test_i;
        CData/*3:0*/ __PVT__gen_mux__DOT__slv_aw_valids;
        CData/*3:0*/ __PVT__gen_mux__DOT__slv_w_readies;
        CData/*3:0*/ __PVT__gen_mux__DOT__slv_ar_valids;
        CData/*0:0*/ __PVT__gen_mux__DOT__mst_aw_ready;
        CData/*0:0*/ __PVT__gen_mux__DOT__aw_valid;
        CData/*0:0*/ __PVT__gen_mux__DOT__aw_ready;
        CData/*0:0*/ __PVT__gen_mux__DOT__lock_aw_valid_d;
        CData/*0:0*/ __PVT__gen_mux__DOT__lock_aw_valid_q;
        CData/*0:0*/ __PVT__gen_mux__DOT__load_aw_lock;
        CData/*0:0*/ __PVT__gen_mux__DOT__w_fifo_push;
        CData/*0:0*/ __PVT__gen_mux__DOT__w_fifo_pop;
        CData/*1:0*/ __PVT__gen_mux__DOT__w_fifo_data;
        CData/*0:0*/ __PVT__gen_mux__DOT__ar_valid;
        CData/*0:0*/ __PVT__gen_mux__DOT__ar_ready;
        CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1;
        CData/*1:0*/ gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1;
        CData/*0:0*/ gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__;
        CData/*1:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q;
        CData/*3:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d;
        CData/*1:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q;
        CData/*3:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*2:0*/ __PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_n;
        CData/*2:0*/ __PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q;
        CData/*2:0*/ __PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_n;
        CData/*2:0*/ __PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q;
        CData/*3:0*/ __PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n;
        CData/*3:0*/ __PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
        SData/*15:0*/ __PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n;
        SData/*15:0*/ __PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain;
        CData/*0:0*/ gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1;
        CData/*1:0*/ gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1;
        CData/*0:0*/ gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__;
        CData/*1:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q;
        CData/*3:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d;
        CData/*1:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q;
    };
    struct {
        CData/*3:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        CData/*0:0*/ __PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_9;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_359;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_360;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__rst_n;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_pop;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_push;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_pop;
    };
    struct {
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*3:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        VlWide<3>/*73:0*/ __Vxrand___0;
        IData/*31:0*/ __VdfgRegularize_h591265a2_0_1;
        IData/*31:0*/ __VdfgRegularize_h591265a2_0_2;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_180;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_181;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_186;
        VlWide<28>/*867:0*/ slv_reqs_i;
        VlWide<11>/*335:0*/ slv_resps_o;
        VlWide<7>/*220:0*/ mst_req_o;
        VlWide<3>/*87:0*/ mst_resp_i;
        VlWide<3>/*73:0*/ __PVT__gen_mux__DOT__mst_aw_chan;
        VlWide<3>/*73:0*/ __PVT__gen_mux__DOT__mst_w_chan;
        VlWide<3>/*73:0*/ __PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        VlWide<3>/*73:0*/ __PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q;
        VlWide<3>/*67:0*/ __PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        VlWide<3>/*67:0*/ __PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q;
    };

    // INTERNAL VARIABLES
    Vaxi4_xbar_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vaxi4_xbar_tb_axi_mux__pi3();
    ~Vaxi4_xbar_tb_axi_mux__pi3();
    void ctor(Vaxi4_xbar_tb__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(Vaxi4_xbar_tb_axi_mux__pi3);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
