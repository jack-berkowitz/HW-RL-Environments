// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VASYNC_FIFO_CDC_THRU__SYMS_H_
#define VERILATED_VASYNC_FIFO_CDC_THRU__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vasync_fifo_cdc_thru.h"

// INCLUDE MODULE CLASSES
#include "Vasync_fifo_cdc_thru___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) Vasync_fifo_cdc_thru__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vasync_fifo_cdc_thru* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vasync_fifo_cdc_thru___024root TOP;

    // CONSTRUCTORS
    Vasync_fifo_cdc_thru__Syms(VerilatedContext* contextp, const char* namep, Vasync_fifo_cdc_thru* modelp);
    ~Vasync_fifo_cdc_thru__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
