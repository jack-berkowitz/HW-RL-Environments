// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vasync_fifo_cdc_thru.h for the primary calling header

#include "Vasync_fifo_cdc_thru__pch.h"

void Vasync_fifo_cdc_thru___024root___ctor_var_reset(Vasync_fifo_cdc_thru___024root* vlSelf);

Vasync_fifo_cdc_thru___024root::Vasync_fifo_cdc_thru___024root(Vasync_fifo_cdc_thru__Syms* symsp, const char* namep)
    : __VdlySched{*symsp->_vm_contextp__}
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vasync_fifo_cdc_thru___024root___ctor_var_reset(this);
}

void Vasync_fifo_cdc_thru___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vasync_fifo_cdc_thru___024root::~Vasync_fifo_cdc_thru___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
