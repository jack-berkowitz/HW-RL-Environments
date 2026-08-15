// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vasync_fifo_cdc_thru__pch.h"

//============================================================
// Constructors

Vasync_fifo_cdc_thru::Vasync_fifo_cdc_thru(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vasync_fifo_cdc_thru__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vasync_fifo_cdc_thru::Vasync_fifo_cdc_thru(const char* _vcname__)
    : Vasync_fifo_cdc_thru(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vasync_fifo_cdc_thru::~Vasync_fifo_cdc_thru() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vasync_fifo_cdc_thru___024root___eval_debug_assertions(Vasync_fifo_cdc_thru___024root* vlSelf);
#endif  // VL_DEBUG
void Vasync_fifo_cdc_thru___024root___eval_static(Vasync_fifo_cdc_thru___024root* vlSelf);
void Vasync_fifo_cdc_thru___024root___eval_initial(Vasync_fifo_cdc_thru___024root* vlSelf);
void Vasync_fifo_cdc_thru___024root___eval_settle(Vasync_fifo_cdc_thru___024root* vlSelf);
void Vasync_fifo_cdc_thru___024root___eval(Vasync_fifo_cdc_thru___024root* vlSelf);

void Vasync_fifo_cdc_thru::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vasync_fifo_cdc_thru::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vasync_fifo_cdc_thru___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vasync_fifo_cdc_thru___024root___eval_static(&(vlSymsp->TOP));
        Vasync_fifo_cdc_thru___024root___eval_initial(&(vlSymsp->TOP));
        Vasync_fifo_cdc_thru___024root___eval_settle(&(vlSymsp->TOP));
        vlSymsp->__Vm_didInit = true;
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vasync_fifo_cdc_thru___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vasync_fifo_cdc_thru::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty() && !contextp()->gotFinish(); }

uint64_t Vasync_fifo_cdc_thru::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vasync_fifo_cdc_thru::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vasync_fifo_cdc_thru___024root___eval_final(Vasync_fifo_cdc_thru___024root* vlSelf);

VL_ATTR_COLD void Vasync_fifo_cdc_thru::final() {
    Vasync_fifo_cdc_thru___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vasync_fifo_cdc_thru::hierName() const { return vlSymsp->name(); }
const char* Vasync_fifo_cdc_thru::modelName() const { return "Vasync_fifo_cdc_thru"; }
unsigned Vasync_fifo_cdc_thru::threads() const { return 1; }
void Vasync_fifo_cdc_thru::prepareClone() const { contextp()->prepareClone(); }
void Vasync_fifo_cdc_thru::atClone() const {
    contextp()->threadPoolpOnClone();
}
