// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

void Vaxi4_xbar_tb_axi_mux__pi3___ctor_var_reset(Vaxi4_xbar_tb_axi_mux__pi3* vlSelf);

Vaxi4_xbar_tb_axi_mux__pi3::Vaxi4_xbar_tb_axi_mux__pi3() = default;
Vaxi4_xbar_tb_axi_mux__pi3::~Vaxi4_xbar_tb_axi_mux__pi3() = default;

void Vaxi4_xbar_tb_axi_mux__pi3::ctor(Vaxi4_xbar_tb__Syms* symsp, const char* namep) {
    vlSymsp = symsp;
    vlNamep = strdup(Verilated::catName(vlSymsp->name(), namep));
    // Reset structure values
    Vaxi4_xbar_tb_axi_mux__pi3___ctor_var_reset(this);
}

void Vaxi4_xbar_tb_axi_mux__pi3::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

void Vaxi4_xbar_tb_axi_mux__pi3::dtor() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
