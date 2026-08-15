// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vasync_fifo_cdc_thru.h for the primary calling header

#ifndef VERILATED_VASYNC_FIFO_CDC_THRU___024ROOT_H_
#define VERILATED_VASYNC_FIFO_CDC_THRU___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vasync_fifo_cdc_thru__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vasync_fifo_cdc_thru___024root final {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ async_fifo_cdc_thru__DOT__wr_clk;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__rd_clk;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__wr_rst_n;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__rd_rst_n;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__wr_valid;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__wr_ready;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__rd_valid;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__rd_ready;
    CData/*3:0*/ async_fifo_cdc_thru__DOT__dut__DOT__wr_bin;
    CData/*3:0*/ async_fifo_cdc_thru__DOT__dut__DOT__wr_bin_next;
    CData/*3:0*/ async_fifo_cdc_thru__DOT__dut__DOT__wr_gray;
    CData/*3:0*/ async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_next;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__dut__DOT__wr_full;
    CData/*3:0*/ async_fifo_cdc_thru__DOT__dut__DOT__rd_bin;
    CData/*3:0*/ async_fifo_cdc_thru__DOT__dut__DOT__rd_bin_next;
    CData/*3:0*/ async_fifo_cdc_thru__DOT__dut__DOT__rd_gray;
    CData/*3:0*/ async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_next;
    CData/*0:0*/ async_fifo_cdc_thru__DOT__dut__DOT__rd_empty;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VstlPhaseResult;
    CData/*0:0*/ __Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__rd_rst_n__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__async_fifo_cdc_thru__DOT__wr_rst_n__0;
    CData/*0:0*/ __VactPhaseResult;
    CData/*0:0*/ __VinactPhaseResult;
    CData/*0:0*/ __VnbaPhaseResult;
    IData/*31:0*/ __VactIterCount;
    IData/*31:0*/ __VinactIterCount;
    IData/*31:0*/ __Vi;
    QData/*63:0*/ async_fifo_cdc_thru__DOT__wr_beats;
    QData/*63:0*/ async_fifo_cdc_thru__DOT__rd_beats;
    QData/*63:0*/ async_fifo_cdc_thru__DOT__wr_cycles;
    QData/*63:0*/ async_fifo_cdc_thru__DOT__rd_cycles;
    VlUnpacked<CData/*3:0*/, 2> async_fifo_cdc_thru__DOT__dut__DOT__wr_gray_sync;
    VlUnpacked<CData/*3:0*/, 2> async_fifo_cdc_thru__DOT__dut__DOT__rd_gray_sync;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h712dd71e__0;
    VlTriggerScheduler __VtrigSched_h0d3e050b__0;

    // INTERNAL VARIABLES
    Vasync_fifo_cdc_thru__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vasync_fifo_cdc_thru___024root(Vasync_fifo_cdc_thru__Syms* symsp, const char* namep);
    ~Vasync_fifo_cdc_thru___024root();
    VL_UNCOPYABLE(Vasync_fifo_cdc_thru___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
