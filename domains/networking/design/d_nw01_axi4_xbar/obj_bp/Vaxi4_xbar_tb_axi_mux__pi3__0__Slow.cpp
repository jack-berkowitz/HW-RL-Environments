// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_mux__pi3___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___stl_sequent__TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain 
        = ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q)) 
           & (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q));
    vlSelfRef.__PVT__gen_mux__DOT__ar_ready = (1U & 
                                               ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                | (~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__gen_mux__DOT__mst_aw_ready = (1U 
                                                   & ((~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q)) 
                                                      | (~ (IData)(vlSelfRef.__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q))));
    vlSelfRef.__PVT__gen_mux__DOT__w_fifo_data = (3U 
                                                  & ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q) 
                                                     >> 
                                                     ((IData)(vlSelfRef.__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q) 
                                                      << 1U)));
}

VL_ATTR_COLD void Vaxi4_xbar_tb_axi_mux__pi3___ctor_var_reset(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+            Vaxi4_xbar_tb_axi_mux__pi3___ctor_var_reset\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    VL_SCOPED_RAND_RESET_ASSIGN_W(74, vlSelf->__Vxrand___0, __VscopeHash, 3515101862192997490ull);
    vlSelf->clk_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11908517815223722933ull);
    vlSelf->rst_ni = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3161515032326629241ull);
    vlSelf->test_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2676571483806808904ull);
    VL_SCOPED_RAND_RESET_W(868, vlSelf->slv_reqs_i, __VscopeHash, 2343014050758847307ull);
    VL_SCOPED_RAND_RESET_W(336, vlSelf->slv_resps_o, __VscopeHash, 10034357854166999909ull);
    VL_SCOPED_RAND_RESET_W(221, vlSelf->mst_req_o, __VscopeHash, 1855752647772730929ull);
    VL_SCOPED_RAND_RESET_W(88, vlSelf->mst_resp_i, __VscopeHash, 871945132230624525ull);
    vlSelf->__PVT__gen_mux__DOT__slv_aw_valids = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3827753971600511830ull);
    vlSelf->__PVT__gen_mux__DOT__slv_w_readies = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8107119230925126582ull);
    vlSelf->__PVT__gen_mux__DOT__slv_ar_valids = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3055971391295464931ull);
    VL_SCOPED_RAND_RESET_W(74, vlSelf->__PVT__gen_mux__DOT__mst_aw_chan, __VscopeHash, 2673914666824431013ull);
    vlSelf->__PVT__gen_mux__DOT__mst_aw_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13881090112870766643ull);
    vlSelf->__PVT__gen_mux__DOT__aw_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11198839079267204961ull);
    vlSelf->__PVT__gen_mux__DOT__aw_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6758433559410564485ull);
    vlSelf->__PVT__gen_mux__DOT__lock_aw_valid_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14503724711221985500ull);
    vlSelf->__PVT__gen_mux__DOT__lock_aw_valid_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1872698637659287103ull);
    vlSelf->__PVT__gen_mux__DOT__load_aw_lock = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4285151636710116870ull);
    vlSelf->__PVT__gen_mux__DOT__w_fifo_push = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4637793973865808729ull);
    vlSelf->__PVT__gen_mux__DOT__w_fifo_pop = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4628300090681408808ull);
    vlSelf->__PVT__gen_mux__DOT__w_fifo_data = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 964693305670028593ull);
    VL_SCOPED_RAND_RESET_W(74, vlSelf->__PVT__gen_mux__DOT__mst_w_chan, __VscopeHash, 9280055292674401442ull);
    vlSelf->__PVT__gen_mux__DOT__ar_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16598622473070472598ull);
    vlSelf->__PVT__gen_mux__DOT__ar_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2542662839230623458ull);
    vlSelf->__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vcellinp__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_r_readies_i = 0;
    vlSelf->__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__VdfgRegularize_h591265a2_0_1 = 0;
    vlSelf->__VdfgRegularize_h591265a2_0_2 = 0;
    vlSelf->gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1 = 0;
    vlSelf->gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1 = 0;
    vlSelf->gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1 = 0;
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3988104799858365666ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__rr_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 11313379664574763557ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__req_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 9743998809683188324ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 4390152478802075683ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1793527247012040917ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4862743891396523475ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 514474363711396578ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16640246645661410288ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13552007210409033470ull);
    vlSelf->__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_n = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 6831047720621335728ull);
    vlSelf->__PVT__gen_mux__DOT__i_w_fifo__DOT__read_pointer_q = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 17737584439654224406ull);
    vlSelf->__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_n = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 4947993502586243367ull);
    vlSelf->__PVT__gen_mux__DOT__i_w_fifo__DOT__write_pointer_q = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 18057307371245627872ull);
    vlSelf->__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_n = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 16224398253092385425ull);
    vlSelf->__PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 1565181841721890896ull);
    vlSelf->__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_n = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 14823483581477553548ull);
    vlSelf->__PVT__gen_mux__DOT__i_w_fifo__DOT__mem_q = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 16430962556737302680ull);
    VL_SCOPED_RAND_RESET_W(74, vlSelf->__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q, __VscopeHash, 13469459006683244744ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14255168867229918732ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 997616740367829576ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7071701021554337955ull);
    VL_SCOPED_RAND_RESET_W(74, vlSelf->__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q, __VscopeHash, 13182951533282827512ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3894759313840981160ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8245471046352746194ull);
    vlSelf->__PVT__gen_mux__DOT__i_aw_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15248698085318413207ull);
    vlSelf->gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1 = 0;
    vlSelf->gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1 = 0;
    vlSelf->gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1 = 0;
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9458483317490189446ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__rr_q = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 16230833832014974057ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__req_d = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 11541484017970642593ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__rr_d = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2360437315643754756ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6846117902374347380ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1577230558813135382ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 5486724179811232887ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9501373112701227614ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14168626805758330500ull);
    VL_SCOPED_RAND_RESET_W(68, vlSelf->__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_data_q, __VscopeHash, 3830938680597428062ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13003964834207817893ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2739282910944878613ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__a_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1587575011832533971ull);
    VL_SCOPED_RAND_RESET_W(68, vlSelf->__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_data_q, __VscopeHash, 11646551020154053907ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_full_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5310904142920363313ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_fill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10467198514941348952ull);
    vlSelf->__PVT__gen_mux__DOT__i_ar_spill_reg__DOT__spill_register_flushable_i__DOT__gen_spill_reg__DOT__b_drain = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16868358114772116325ull);
    vlSelf->__VdfgRegularize_hebeb780c_0_9 = 0;
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_180);
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_181);
    VL_ZERO_RESET_W(216, vlSelf->__VdfgRegularize_hebeb780c_0_186);
    vlSelf->__VdfgRegularize_hebeb780c_0_359 = 0;
    vlSelf->__VdfgRegularize_hebeb780c_0_360 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__rst_n = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__0__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_aw_arbiter__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_aw_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_aw_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_ready = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__aw_valid = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_aw_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_w_fifo__DOT__status_cnt_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_push = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__w_fifo_pop = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_1_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__0__KET____DOT__gen_level__BRA__0__KET____DOT__sel = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__index_nodes__BRA__4__KET__ = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_levels__BRA__1__KET____DOT__gen_level__BRA__0__KET____DOT__sel = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_2_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux__gen_mux__DOT__i_ar_arbiter__DOT___Vpast_4_1 = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__req_q = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__slv_ar_valids = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__3__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__2__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__1__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____Vcellout__gen_mux__DOT__gen_id_prepend__BRA__0__KET____DOT__i_id_prepend__slv_ar_readies_o = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_ready = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__ar_valid = 0;
    vlSelf->__Vsampled_TOP__axi4_xbar_tb__DOT__dut__DOT__u_xbar__DOT__gen_mst_port_mux__BRA__1__KET____DOT__i_axi_mux____PVT__gen_mux__DOT__i_ar_arbiter__DOT__gen_arbiter__DOT__gen_int_rr__DOT__gen_lock__DOT__lock_d = 0;
}
