// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

void Vaxi4_xbar_tb___024root___ctor_var_reset(Vaxi4_xbar_tb___024root* vlSelf);

Vaxi4_xbar_tb___024root::Vaxi4_xbar_tb___024root(Vaxi4_xbar_tb__Syms* symsp, const char* namep)
    : __VdlySched{*symsp->_vm_contextp__}
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vaxi4_xbar_tb___024root___ctor_var_reset(this);
}

void Vaxi4_xbar_tb___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vaxi4_xbar_tb___024root::~Vaxi4_xbar_tb___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
