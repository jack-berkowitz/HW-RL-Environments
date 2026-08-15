// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxi4_xbar_tb.h for the primary calling header

#ifndef VERILATED_VAXI4_XBAR_TB_AXI_DEMUX__PI4_H_
#define VERILATED_VAXI4_XBAR_TB_AXI_DEMUX__PI4_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"
class Vaxi4_xbar_tb_axi_demux_id_counters__pi10;


class Vaxi4_xbar_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxi4_xbar_tb_axi_demux__pi4 final {
  public:
    // CELLS
    Vaxi4_xbar_tb_axi_demux_id_counters__pi10* __PVT__i_demux_simple__DOT__genblk1__DOT__gen_aw_id_counter__DOT__i_aw_id_counter;
    Vaxi4_xbar_tb_axi_demux_id_counters__pi10* __PVT__i_demux_simple__DOT__genblk1__DOT__gen_ar_id_counter__DOT__i_ar_id_counter;

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ clk_i;
        CData/*0:0*/ rst_ni;
        CData/*0:0*/ test_i;
        CData/*1:0*/ slv_aw_select_i;
        CData/*1:0*/ slv_ar_select_i;
        CData/*0:0*/ __PVT__slv_aw_ready_chan;
        CData/*0:0*/ __PVT__slv_aw_ready_sel;
        CData/*0:0*/ __PVT__slv_ar_ready_chan;
        CData/*0:0*/ __PVT__slv_ar_ready_sel;
        CData/*1:0*/ __PVT__slv_aw_select;
        CData/*1:0*/ __PVT__slv_ar_select;
        CData/*0:0*/ __PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q;
        CData/*0:0*/ __PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        CData/*0:0*/ __PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain;
        CData/*0:0*/ __PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q;
        CData/*0:0*/ __PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        CData/*0:0*/ __PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain;
        CData/*1:0*/ __PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        CData/*0:0*/ __PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q;
        CData/*0:0*/ __PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        CData/*0:0*/ __PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain;
        CData/*1:0*/ __PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q;
        CData/*0:0*/ __PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q;
        CData/*0:0*/ __PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        CData/*0:0*/ __PVT__i_aw_select_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain;
        CData/*0:0*/ __PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q;
        CData/*0:0*/ __PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        CData/*0:0*/ __PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain;
        CData/*0:0*/ __PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q;
        CData/*0:0*/ __PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        CData/*0:0*/ __PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain;
        CData/*1:0*/ __PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        CData/*0:0*/ __PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q;
        CData/*0:0*/ __PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill;
        CData/*0:0*/ __PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain;
        CData/*1:0*/ __PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q;
        CData/*0:0*/ __PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q;
        CData/*0:0*/ __PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill;
        CData/*0:0*/ __PVT__i_ar_sel_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_d;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__lock_aw_valid_q;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__load_aw_lock;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__aw_valid;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__lookup_aw_select;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__aw_select_occupied;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__aw_id_cnt_full;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__atop_inject;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__w_select;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__w_select_q;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__w_select_valid;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__w_cnt_up;
        CData/*2:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__lookup_ar_select;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__ar_select_occupied;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__ar_id_cnt_full;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__ar_push;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_d;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__lock_ar_valid_q;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__load_ar_lock;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__ar_valid;
        CData/*2:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
        CData/*0:0*/ i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
    };
    struct {
        CData/*0:0*/ i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o;
        CData/*3:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_q;
        CData/*3:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_counter_open_w__DOT__i_counter__DOT__counter_d;
        CData/*0:0*/ i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT____Vxrand___0;
        CData/*0:0*/ i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1;
        CData/*1:0*/ i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1;
        CData/*0:0*/ i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__rr_q;
        CData/*2:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__req_d;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q;
        CData/*2:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT____Vxrand___0;
        CData/*0:0*/ i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1;
        CData/*1:0*/ i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1;
        CData/*0:0*/ i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gnt_nodes__BRA__1__KET__;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__rr_q;
        CData/*2:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__req_d;
        CData/*1:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q;
        CData/*2:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*0:0*/ __PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel;
        CData/*0:0*/ __VdfgRegularize_h9b082aa7_1_3;
        CData/*0:0*/ __VdfgRegularize_h9b082aa7_1_7;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_0;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_1;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_2;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_3;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_4;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_5;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_6;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_7;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_11;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_18;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_19;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_20;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_21;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_22;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_23;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_24;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_25;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_32;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_34;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_35;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_36;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_37;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_38;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_39;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_40;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_47;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_49;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_50;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_51;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_52;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_53;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_54;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_55;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_62;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_64;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_65;
    };
    struct {
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_66;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_67;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_68;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_69;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_70;
        CData/*6:0*/ __VdfgRegularize_hebeb780c_0_87;
        CData/*6:0*/ __VdfgRegularize_hebeb780c_0_89;
        CData/*6:0*/ __VdfgRegularize_hebeb780c_0_91;
        CData/*6:0*/ __VdfgRegularize_hebeb780c_0_93;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_96;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_97;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_98;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_100;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_101;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_102;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_104;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_105;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_106;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_108;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_109;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_110;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_119;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_123;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_129;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_133;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_139;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_143;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_149;
        CData/*0:0*/ __VdfgRegularize_hebeb780c_0_153;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_96;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_97;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_98;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__0__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_100;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_101;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_102;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
    };
    struct {
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__1__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_104;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_105;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_106;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__2__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_1_1;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__b_idx;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT___Vpast_4_1;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_b_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_108;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_109;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____VdfgRegularize_hebeb780c_0_110;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_b_mux__req_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_b_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_1_1;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__r_idx;
        CData/*1:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_2_1;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT___Vpast_4_1;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q;
        CData/*2:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__mst_r_valids;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_err_slv____VdfgExtracted_h2ee1ee4a__0;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux__i_demux_simple__DOT____Vcellout__genblk1__DOT__i_r_mux__req_o;
        CData/*0:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__i_xbar_unmuxed__DOT__gen_slv_port_demux__BRA__3__KET____DOT__i_axi_demux____PVT__i_demux_simple__DOT__genblk1__DOT__i_r_mux__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d;
        VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_33;
        VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_48;
        VlWide<21>/*650:0*/ __VdfgRegularize_hebeb780c_0_63;
        VlWide<3>/*71:0*/ __VdfgRegularize_hebeb780c_0_88;
        VlWide<3>/*71:0*/ __VdfgRegularize_hebeb780c_0_90;
        VlWide<3>/*71:0*/ __VdfgRegularize_hebeb780c_0_92;
        VlWide<3>/*71:0*/ __VdfgRegularize_hebeb780c_0_94;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_122;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_132;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_142;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_152;
    };
    struct {
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_159;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_187;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_190;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_193;
        VlWide<7>/*215:0*/ __VdfgRegularize_hebeb780c_0_196;
        VlWide<7>/*216:0*/ slv_req_i;
        VlWide<3>/*83:0*/ slv_resp_o;
        VlWide<21>/*650:0*/ mst_reqs_o;
        VlWide<8>/*251:0*/ mst_resps_i;
        VlWide<7>/*216:0*/ __PVT__slv_req_cut;
        VlWide<3>/*71:0*/ __Vcellout__i_aw_spill_reg__data_o;
        VlWide<3>/*65:0*/ __Vcellout__i_ar_spill_reg__data_o;
        VlWide<3>/*71:0*/ __PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        VlWide<3>/*71:0*/ __PVT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q;
        VlWide<3>/*65:0*/ __PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q;
        VlWide<3>/*65:0*/ __PVT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q;
        VlWide<28>/*867:0*/ __Vsampled_TOP__axi4_xbar_tb__DOT__mst_req;
    };

    // INTERNAL VARIABLES
    Vaxi4_xbar_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vaxi4_xbar_tb_axi_demux__pi4();
    ~Vaxi4_xbar_tb_axi_demux__pi4();
    void ctor(Vaxi4_xbar_tb__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(Vaxi4_xbar_tb_axi_demux__pi4);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
