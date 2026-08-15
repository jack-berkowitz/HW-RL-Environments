// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vaxi4_xbar_tb__pch.h"

//============================================================
// Constructors

Vaxi4_xbar_tb::Vaxi4_xbar_tb(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vaxi4_xbar_tb__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vaxi4_xbar_tb::Vaxi4_xbar_tb(const char* _vcname__)
    : Vaxi4_xbar_tb(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vaxi4_xbar_tb::~Vaxi4_xbar_tb() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vaxi4_xbar_tb___024root___eval_debug_assertions(Vaxi4_xbar_tb___024root* vlSelf);
#endif  // VL_DEBUG
void Vaxi4_xbar_tb___024root___eval_static(Vaxi4_xbar_tb___024root* vlSelf);
void Vaxi4_xbar_tb___024root___eval_initial(Vaxi4_xbar_tb___024root* vlSelf);
void Vaxi4_xbar_tb___024root___eval_settle(Vaxi4_xbar_tb___024root* vlSelf);
void Vaxi4_xbar_tb___024root___eval(Vaxi4_xbar_tb___024root* vlSelf);

void Vaxi4_xbar_tb::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vaxi4_xbar_tb::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vaxi4_xbar_tb___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vaxi4_xbar_tb___024root___eval_static(&(vlSymsp->TOP));
        Vaxi4_xbar_tb___024root___eval_initial(&(vlSymsp->TOP));
        Vaxi4_xbar_tb___024root___eval_settle(&(vlSymsp->TOP));
        vlSymsp->__Vm_didInit = true;
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vaxi4_xbar_tb___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vaxi4_xbar_tb::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty() && !contextp()->gotFinish(); }

uint64_t Vaxi4_xbar_tb::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vaxi4_xbar_tb::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vaxi4_xbar_tb___024root___eval_final(Vaxi4_xbar_tb___024root* vlSelf);

VL_ATTR_COLD void Vaxi4_xbar_tb::final() {
    Vaxi4_xbar_tb___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vaxi4_xbar_tb::hierName() const { return vlSymsp->name(); }
const char* Vaxi4_xbar_tb::modelName() const { return "Vaxi4_xbar_tb"; }
unsigned Vaxi4_xbar_tb::threads() const { return 1; }
void Vaxi4_xbar_tb::prepareClone() const { contextp()->prepareClone(); }
void Vaxi4_xbar_tb::atClone() const {
    contextp()->threadPoolpOnClone();
}
