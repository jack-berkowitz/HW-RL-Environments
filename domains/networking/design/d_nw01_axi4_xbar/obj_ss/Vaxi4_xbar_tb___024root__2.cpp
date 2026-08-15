// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi4_xbar_tb.h for the primary calling header

#include "Vaxi4_xbar_tb__pch.h"

void Vaxi4_xbar_tb___024root___nba_sequent__TOP__1(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___nba_sequent__TOP__1\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xff807fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x007f8000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000adU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000b4U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000adU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000adU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000adU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 0x0000000fU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xffff8fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x00007000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000aaU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000acU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000aaU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000aaU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000aaU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 0x0000000cU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xfffff3ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x00000c00U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a8U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a9U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a8U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a8U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a8U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 0x0000000aU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xfffffdffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x00000200U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x000000a7U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x000000a7U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))) 
                             << 9U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xfffffe1fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x000001e0U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a3U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a6U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a3U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a3U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a3U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 5U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xffffffe3U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (0x0000001cU & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a0U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a2U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a0U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a0U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a0U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 2U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = ((0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x0000009cU) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x0000009fU) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x0000009cU) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x0000009cU) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x0000009cU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
              << 0x0000001eU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U] 
        = ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[5U]) 
           | (3U & ((((0U == (0x0000001fU & ((IData)(0x0000009cU) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                       ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                               [(((IData)(0x0000009fU) 
                                  + (0x000003ffU & 
                                     ((IData)(0x000000d9U) 
                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                 >> 5U)] << ((IData)(0x00000020U) 
                                             - (0x0000001fU 
                                                & ((IData)(0x0000009cU) 
                                                   + 
                                                   (0x000003ffU 
                                                    & ((IData)(0x000000d9U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                     | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                        [(((IData)(0x0000009cU) + (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                          >> 5U)] >> (0x0000001fU & 
                                      ((IData)(0x0000009cU) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                    >> 2U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = ((0xc3ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
           | (0x3c000000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000098U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000009bU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000098U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000098U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000098U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U])))))) 
                             << 0x0000001aU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = ((0xfff7ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
           | (0x00080000U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x00000091U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x00000091U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[0U]))))) 
                             << 0x00000013U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
        = (0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
        = (0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]);
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
          & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
            >> 5U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = (0x00000080U | ((0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
                              | (0xffffff00U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                                << 2U))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
            = (((0x0000007cU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                << 2U)) | (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                           >> 0x0000001eU)) 
               | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                          >> 5U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                      << 0x0000001bU) 
                                     | (0x07fffffeU 
                                        & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                           >> 5U)))) 
                  << 7U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
            = ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                           >> 5U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                       << 0x0000001bU) 
                                      | (0x07fffffeU 
                                         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                            >> 5U)))) 
                   >> 0x00000019U) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                              >> 5U)) 
                                       | (0x000007feU 
                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                             >> 5U))) 
                                      << 7U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 1U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            >> 0x0000001eU))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = (0x00000080U | ((0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                  << 9U) | (0x00000100U 
                                            & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                               >> 0x00000017U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
            = ((0x0000007fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                               >> 0x00000017U)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                        >> 0x0000001eU)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                        << 2U) 
                                                       | (2U 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                             >> 0x0000001eU)))) 
                                                   << 7U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
            = ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                           >> 0x0000001eU)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                << 2U) 
                                               | (2U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                     >> 0x0000001eU)))) 
                   >> 0x00000019U) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                              >> 0x0000001eU)) 
                                       | (0x000007feU 
                                          & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                                              << 2U) 
                                             | (2U 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                   >> 0x0000001eU))))) 
                                      << 7U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 2U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            >> 0x00000017U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = (0x00000080U | ((0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                  << 0x00000010U) | 
                                 (0x0000ff00U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                                 >> 0x00000010U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
            = ((0x0000007fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                               >> 0x00000010U)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                        >> 0x00000017U)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                        << 9U) 
                                                       | (0x000001feU 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                             >> 0x00000017U)))) 
                                                   << 7U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
            = ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                           >> 0x00000017U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                << 9U) 
                                               | (0x000001feU 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                     >> 0x00000017U)))) 
                   >> 0x00000019U) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                              >> 0x00000017U)) 
                                       | (0x000007feU 
                                          & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                                              << 9U) 
                                             | (0x000001feU 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                   >> 0x00000017U))))) 
                                      << 7U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 3U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            >> 0x00000010U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = (0x00000080U | ((0x0000007fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                  << 0x00000017U) | 
                                 (0x007fff00U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                                 >> 9U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[3U] 
            = ((0x0000007fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                               >> 9U)) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                  >> 0x00000010U)) 
                                           | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                               << 0x00000010U) 
                                              | (0x0000fffeU 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                    >> 0x00000010U)))) 
                                          << 7U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U] 
            = ((0xfffc0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[4U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                           >> 0x00000010U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                << 0x00000010U) 
                                               | (0x0000fffeU 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                     >> 0x00000010U)))) 
                   >> 0x00000019U) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                              >> 0x00000010U)) 
                                       | (0x000007feU 
                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                             >> 0x00000010U))) 
                                      << 7U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
        = (0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
        = (0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]);
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
         & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
               | (1U & vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U]));
    }
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
         & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
               | (0x00000040U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                 << 2U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 1U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
               | (1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                        >> 0x00000019U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 1U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
               | (0x00000040U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                 >> 0x00000017U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 2U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
               | (1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                        >> 0x00000012U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 2U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
               | (0x00000040U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                 >> 0x00000010U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 3U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[0U]) 
               | (1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                        >> 0x0000000bU)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 3U) & (0U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U] 
            = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[2U]) 
               | (0x00000040U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                 >> 9U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = (0x1fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0xbfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | (0x40000000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                             << 0x0000001dU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
        = ((0x1fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U]) 
           | ((VL_SHIFTL_III(6,6,32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U], 4U) 
               | (0x0000000fU & (((0U == (0x0000001fU 
                                          & ((IData)(0x00000040U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                   ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                           [(((IData)(0x00000043U) 
                                              + (0x000003ffU 
                                                 & ((IData)(0x000000d9U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                             >> 5U)] 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(0x00000040U) 
                                                     + 
                                                     (0x000003ffU 
                                                      & ((IData)(0x000000d9U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                                 | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                    [(((IData)(0x00000040U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                      >> 5U)] >> (0x0000001fU 
                                                  & ((IData)(0x00000040U) 
                                                     + 
                                                     (0x000003ffU 
                                                      & ((IData)(0x000000d9U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))))) 
              << 0x0000001dU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = ((0xfffffff8U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
           | (7U & ((VL_SHIFTL_III(6,6,32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U], 4U) 
                     | (0x0000000fU & (((0U == (0x0000001fU 
                                                & ((IData)(0x00000040U) 
                                                   + 
                                                   (0x000003ffU 
                                                    & ((IData)(0x000000d9U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                         ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                 [(
                                                   ((IData)(0x00000043U) 
                                                    + 
                                                    (0x000003ffU 
                                                     & ((IData)(0x000000d9U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                                   >> 5U)] 
                                                 << 
                                                 ((IData)(0x00000020U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(0x00000040U) 
                                                      + 
                                                      (0x000003ffU 
                                                       & ((IData)(0x000000d9U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                                       | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                          [(((IData)(0x00000040U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                            >> 5U)] 
                                          >> (0x0000001fU 
                                              & ((IData)(0x00000040U) 
                                                 + 
                                                 (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))))) 
                    >> 3U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0x1fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x00000020U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x0000003fU) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x00000020U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x00000020U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x00000020U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
              << 0x0000001dU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U] 
        = ((0xe0000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[8U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x00000020U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x0000003fU) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x00000020U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x00000020U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x00000020U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
              >> 3U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xe01fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x1fe00000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000018U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000001fU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000018U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000018U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000018U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 0x00000015U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xffe3ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x001c0000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000015U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000017U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000015U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000015U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000015U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 0x00000012U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xfffcffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x00030000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000013U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000014U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000013U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000013U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000013U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 0x00000010U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xffff7fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x00008000U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x00000012U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x00000012U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))) 
                             << 0x0000000fU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xffff87ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x00007800U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x0000000eU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x00000011U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x0000000eU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x0000000eU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x0000000eU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 0x0000000bU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xfffff8ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x00000700U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x0000000bU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000000dU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x0000000bU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x0000000bU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x0000000bU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 8U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xffffff0fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x000000f0U & ((((0U == (0x0000001fU 
                                       & ((IData)(7U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000000aU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(7U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(7U) + (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(7U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))) 
                             << 4U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U] 
        = ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[7U]) 
           | (0x0000000fU & (((0U == (0x0000001fU & 
                                      ((IData)(3U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U])))))
                               ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                       [(((IData)(6U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                         >> 5U)] << 
                                       ((IData)(0x00000020U) 
                                        - (0x0000001fU 
                                           & ((IData)(3U) 
                                              + (0x000003ffU 
                                                 & ((IData)(0x000000d9U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))) 
                             | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                [(((IData)(3U) + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                                  >> 5U)] >> (0x0000001fU 
                                              & ((IData)(3U) 
                                                 + 
                                                 (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))))));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = ((0x7fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
           | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
               [(((IData)(2U) + (0x000003ffU & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))) 
                 >> 5U)] >> (0x0000001fU & ((IData)(2U) 
                                            + (0x000003ffU 
                                               & ((IData)(0x000000d9U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win[1U]))))) 
              << 0x0000001fU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0xffff7fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | (0x00008000U & ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                             << 0x0000000eU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] 
        = ((0x000fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U]) 
           | (0x03f00000U & ((VL_SHIFTL_III(6,6,32, vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U], 4U) 
                              | (0x0000000fU & (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & ((IData)(0x000000d5U) 
                                                      + 
                                                      (0x000003ffU 
                                                       & ((IData)(0x000000d9U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                                  ? 0U
                                                  : 
                                                 (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                  [
                                                  (((IData)(0x000000d8U) 
                                                    + 
                                                    (0x000003ffU 
                                                     & ((IData)(0x000000d9U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                                   >> 5U)] 
                                                  << 
                                                  ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(0x000000d5U) 
                                                       + 
                                                       (0x000003ffU 
                                                        & ((IData)(0x000000d9U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                                   [
                                                   (((IData)(0x000000d5U) 
                                                     + 
                                                     (0x000003ffU 
                                                      & ((IData)(0x000000d9U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                                    >> 5U)] 
                                                   >> 
                                                   (0x0000001fU 
                                                    & ((IData)(0x000000d5U) 
                                                       + 
                                                       (0x000003ffU 
                                                        & ((IData)(0x000000d9U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))))) 
                             << 0x00000014U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0x000fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x000000b5U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x000000d4U) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x000000b5U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x000000b5U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x000000b5U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
              << 0x00000014U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U] 
        = ((0x03f00000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[13U]) 
           | (0x03ffffffU & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000b5U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000d4U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000b5U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000b5U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000b5U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             >> 0x0000000cU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xfff00fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x000ff000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000adU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000b4U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000adU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000adU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000adU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 0x0000000cU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xfffff1ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x00000e00U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000aaU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000acU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000aaU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000aaU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000aaU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 9U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xfffffe7fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x00000180U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a8U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a9U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a8U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a8U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a8U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 7U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x00000040U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x000000a7U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x000000a7U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))) 
                             << 6U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xffffffc3U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (0x0000003cU & ((((0U == (0x0000001fU 
                                       & ((IData)(0x000000a3U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x000000a6U) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x000000a3U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x000000a3U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x000000a3U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 2U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0x7fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | ((((0U == (0x0000001fU & ((IData)(0x000000a0U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                 ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                         [(((IData)(0x000000a2U) + 
                            (0x000003ffU & ((IData)(0x000000d9U) 
                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                           >> 5U)] << ((IData)(0x00000020U) 
                                       - (0x0000001fU 
                                          & ((IData)(0x000000a0U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
               | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                  [(((IData)(0x000000a0U) + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                    >> 5U)] >> (0x0000001fU & ((IData)(0x000000a0U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
              << 0x0000001fU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U] 
        = ((0xfffffffcU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[12U]) 
           | (3U & ((((0U == (0x0000001fU & ((IData)(0x000000a0U) 
                                             + (0x000003ffU 
                                                & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                       ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                               [(((IData)(0x000000a2U) 
                                  + (0x000003ffU & 
                                     ((IData)(0x000000d9U) 
                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                 >> 5U)] << ((IData)(0x00000020U) 
                                             - (0x0000001fU 
                                                & ((IData)(0x000000a0U) 
                                                   + 
                                                   (0x000003ffU 
                                                    & ((IData)(0x000000d9U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                     | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                        [(((IData)(0x000000a0U) + (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                          >> 5U)] >> (0x0000001fU & 
                                      ((IData)(0x000000a0U) 
                                       + (0x000003ffU 
                                          & ((IData)(0x000000d9U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                    >> 1U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0x87ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | (0x78000000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x0000009cU) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000009fU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x0000009cU) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x0000009cU) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x0000009cU) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 0x0000001bU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0xf87fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | (0x07800000U & ((((0U == (0x0000001fU 
                                       & ((IData)(0x00000098U) 
                                          + (0x000003ffU 
                                             & ((IData)(0x000000d9U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))
                                ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                        [(((IData)(0x0000009bU) 
                                           + (0x000003ffU 
                                              & ((IData)(0x000000d9U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                          >> 5U)] << 
                                        ((IData)(0x00000020U) 
                                         - (0x0000001fU 
                                            & ((IData)(0x00000098U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))))) 
                              | (vlSelfRef.axi4_xbar_tb__DOT__mst_req
                                 [(((IData)(0x00000098U) 
                                    + (0x000003ffU 
                                       & ((IData)(0x000000d9U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                   >> 5U)] >> (0x0000001fU 
                                               & ((IData)(0x00000098U) 
                                                  + 
                                                  (0x000003ffU 
                                                   & ((IData)(0x000000d9U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U])))))) 
                             << 0x00000017U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
           | (0x00010000U & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req
                              [(((IData)(0x00000091U) 
                                 + (0x000003ffU & ((IData)(0x000000d9U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))) 
                                >> 5U)] >> (0x0000001fU 
                                            & ((IData)(0x00000091U) 
                                               + (0x000003ffU 
                                                  & ((IData)(0x000000d9U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win[1U]))))) 
                             << 0x00000010U)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = (0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
        = (0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]);
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
          & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
            >> 5U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = (0x00000010U | ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                  << 0x0000001fU) | 
                                 (0x7fffffe0U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                                                 >> 1U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
            = ((0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                               >> 1U)) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                                  >> 5U)) 
                                           | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                               << 0x0000001bU) 
                                              | (0x07fffffeU 
                                                 & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                                    >> 5U)))) 
                                          << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
            = ((0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                           >> 5U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                       << 0x0000001bU) 
                                      | (0x07fffffeU 
                                         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[3U] 
                                            >> 5U)))) 
                   >> 0x0000001cU) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                              >> 5U)) 
                                       | (0x000007feU 
                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                             >> 5U))) 
                                      << 4U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 1U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
            >> 0x0000001eU))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = (0x00000010U | ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                  << 6U) | (0x00000020U 
                                            & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                                               >> 0x0000001aU)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
            = ((0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                               >> 0x0000001aU)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                        >> 0x0000001eU)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                        << 2U) 
                                                       | (2U 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                             >> 0x0000001eU)))) 
                                                   << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
            = ((0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                           >> 0x0000001eU)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                << 2U) 
                                               | (2U 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[9U] 
                                                     >> 0x0000001eU)))) 
                   >> 0x0000001cU) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                              >> 0x0000001eU)) 
                                       | (0x000007feU 
                                          & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                                              << 2U) 
                                             | (2U 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[10U] 
                                                   >> 0x0000001eU))))) 
                                      << 4U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 2U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
            >> 0x00000017U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = (0x00000010U | ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                  << 0x0000000dU) | 
                                 (0x00001fe0U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                                                 >> 0x00000013U)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
            = ((0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                               >> 0x00000013U)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                        >> 0x00000017U)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                        << 9U) 
                                                       | (0x000001feU 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                             >> 0x00000017U)))) 
                                                   << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
            = ((0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                           >> 0x00000017U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                << 9U) 
                                               | (0x000001feU 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[16U] 
                                                     >> 0x00000017U)))) 
                   >> 0x0000001cU) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                              >> 0x00000017U)) 
                                       | (0x000007feU 
                                          & ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                                              << 9U) 
                                             | (0x000001feU 
                                                & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[17U] 
                                                   >> 0x00000017U))))) 
                                      << 4U)));
    }
    if (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
           >> 3U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U])) 
         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
            >> 0x00000010U))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = (0x00000010U | ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
                              | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                  << 0x00000014U) | 
                                 (0x000fffe0U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                                                 >> 0x0000000cU)))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[10U] 
            = ((0x0000000fU & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                               >> 0x0000000cU)) | (
                                                   ((1U 
                                                     & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                        >> 0x00000010U)) 
                                                    | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                        << 0x00000010U) 
                                                       | (0x0000fffeU 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                             >> 0x00000010U)))) 
                                                   << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U] 
            = ((0xffff8000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[11U]) 
               | ((((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                           >> 0x00000010U)) | ((vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                << 0x00000010U) 
                                               | (0x0000fffeU 
                                                  & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[23U] 
                                                     >> 0x00000010U)))) 
                   >> 0x0000001cU) | (((1U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                              >> 0x00000010U)) 
                                       | (0x000007feU 
                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                             >> 0x00000010U))) 
                                      << 4U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
        = (0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
        = (0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]);
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
         & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
               | (0x20000000U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
                                 << 0x0000001dU)));
    }
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
         & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = ((0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
               | (8U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[2U] 
                        >> 1U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 1U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
               | (0x20000000U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                 << 4U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 1U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = ((0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
               | (8U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[8U] 
                        >> 0x0000001aU)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 2U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
               | (0x20000000U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                 << 0x0000000bU)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 2U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = ((0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
               | (8U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[15U] 
                        >> 0x00000013U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 3U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[6U]) 
               | (0x20000000U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                 << 0x00000012U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 3U) & (1U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U] 
            = ((0xfffffff7U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__slv_req[9U]) 
               | (8U & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[22U] 
                        >> 0x0000000cU)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = (0xfff00000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0xfffbffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                 & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))
                     ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                        >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))
                     : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___35))) 
                & (0U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___36))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[0U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000056U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000056U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[0U]))))))) 
              << 0x00000012U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0xfff7ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | (((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                 & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))
                     ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                        >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))
                     : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___37))) 
                & (0U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___38))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[0U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000057U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000057U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[0U]))))))) 
              << 0x00000013U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = ((0xfffdffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
           | (0x00020000U & (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
                              & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U]) 
                                 | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                    [(((IData)(0x00000055U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U]))) 
                                      >> 5U)] >> (0x0000001fU 
                                                  & ((IData)(0x00000055U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[0U]))))))) 
                             << 0x00000011U)));
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
         & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = (0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]);
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffffe00U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[0U] 
                   << 8U) | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_id[0U] 
                             << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0xfffffff1U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | (0xfffffffeU & (0x0000000cU | ((1U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_left[0U]) 
                                                << 1U))));
    } else if ((1U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffffeffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00000100U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004aU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004aU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))) 
                                 << 8U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xffffff0fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x000000f0U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x00000044U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000047U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000044U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))) 
                                 << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0x0000000fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000043U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                              >> 5U)])) 
                            << ((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                 ? 0x00000020U : ((IData)(0x00000040U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                           | (((0U == (0x0000001fU 
                                       & ((IData)(4U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                          [
                                                          (((IData)(0x00000023U) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000058U) 
                                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                           >> 5U)])) 
                                          << ((IData)(0x00000020U) 
                                              - (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                 [(
                                                   ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                   >> 5U)])) 
                                 >> (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))))) 
                  << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[1U] 
            = (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                          [(((IData)(0x00000043U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                            >> 5U)])) 
                          << ((0U == (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                               ? 0x00000020U : ((IData)(0x00000040U) 
                                                - (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                         | (((0U == (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                              ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                        [
                                                        (((IData)(0x00000023U) 
                                                          + 
                                                          (0x000000ffU 
                                                           & ((IData)(0x00000058U) 
                                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                         >> 5U)])) 
                                        << ((IData)(0x00000020U) 
                                            - (0x0000001fU 
                                               & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                            | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                               [(((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                 >> 5U)])) 
                               >> (0x0000001fU & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))))) 
                >> 0x0000001cU) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                              [
                                                              (((IData)(0x00000043U) 
                                                                + 
                                                                (0x000000ffU 
                                                                 & ((IData)(0x00000058U) 
                                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                               >> 5U)])) 
                                              << ((0U 
                                                   == 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                                   ? 0x00000020U
                                                   : 
                                                  ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                             | (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                                  ? 0ULL
                                                  : 
                                                 ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                  [
                                                                  (((IData)(0x00000023U) 
                                                                    + 
                                                                    (0x000000ffU 
                                                                     & ((IData)(0x00000058U) 
                                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                                   >> 5U)])) 
                                                  << 
                                                  ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                                | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                   [
                                                                   (((IData)(4U) 
                                                                     + 
                                                                     (0x000000ffU 
                                                                      & ((IData)(0x00000058U) 
                                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                                    >> 5U)])) 
                                                   >> 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                            >> 0x00000020U)) 
                                   << 4U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                             [(((IData)(0x00000043U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                               >> 5U)])) 
                             << ((0U == (0x0000001fU 
                                         & ((IData)(4U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                  ? 0x00000020U : ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                            | (((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                 ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                           [
                                                           (((IData)(0x00000023U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000058U) 
                                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                            >> 5U)])) 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(4U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                               | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                  [
                                                  (((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                                   >> 5U)])) 
                                  >> (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                           >> 0x00000020U)) >> 0x0000001cU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0xfffffff3U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | (0x0000000cU & ((((0U == (0x0000001fU 
                                           & ((IData)(2U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(3U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(2U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))))) 
                                 << 2U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0xfffffffdU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | (2U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                         [(((IData)(1U) + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))) 
                           >> 5U)] >> (0x0000001fU 
                                       & ((IData)(1U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]))))) 
                        << 1U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U] 
            = ((0xfffffffeU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[0U]) 
               | (1U & (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                        [(7U & (((IData)(0x00000058U) 
                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U]) 
                                >> 5U))] >> (0x0000001fU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[0U])))));
    }
    if (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
         & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffe03ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0xfffffc00U & (0x00000c00U | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[0U] 
                                                 << 0x00000010U) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_id[0U] 
                                                   << 0x0000000cU)))));
    } else if ((1U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00010000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x00000054U) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x00000054U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))))) 
                                 << 0x00000010U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xffff0fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x0000f000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004eU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000051U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004eU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U])))))) 
                                 << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffff3ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00000c00U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004cU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x0000004dU) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004cU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U])))))) 
                                 << 0x0000000aU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xfffffdffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00000200U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004bU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004bU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[0U]))))) 
                                 << 9U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
        = (0x000fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = (0xffffff00U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0xffffffbfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                  >> 1U) & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))
                             ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                                >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))
                             : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___35))) 
                & (1U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___36))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[1U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000056U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000056U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[1U]))))))) 
              << 6U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0xffffff7fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                  >> 1U) & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))
                             ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                                >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))
                             : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___37))) 
                & (1U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___38))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[1U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000057U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000057U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[1U]))))))) 
              << 7U));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = ((0xffffffdfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
           | (0x00000020U & (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
                              << 4U) & (((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U]) 
                                         | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000055U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U]))) 
                                              >> 5U)] 
                                            >> (0x0000001fU 
                                                & ((IData)(0x00000055U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[1U])))))) 
                                        << 5U))));
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 1U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = (0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]);
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xe0000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[1U] 
                   << 0x0000001cU) | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_id[1U] 
                                      << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xff1fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0xffe00000U & (0x00c00000U | ((1U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_left[1U]) 
                                                << 0x00000015U))));
    } else if ((2U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xefffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | (0x10000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004aU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004aU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))) 
                                 << 0x0000001cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xf0ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | (0x0f000000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x00000044U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000047U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000044U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))) 
                                 << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0x00ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000043U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                              >> 5U)])) 
                            << ((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                 ? 0x00000020U : ((IData)(0x00000040U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                           | (((0U == (0x0000001fU 
                                       & ((IData)(4U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                          [
                                                          (((IData)(0x00000023U) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000058U) 
                                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                           >> 5U)])) 
                                          << ((IData)(0x00000020U) 
                                              - (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                 [(
                                                   ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                   >> 5U)])) 
                                 >> (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))))) 
                  << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[3U] 
            = (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                          [(((IData)(0x00000043U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                            >> 5U)])) 
                          << ((0U == (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                               ? 0x00000020U : ((IData)(0x00000040U) 
                                                - (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                         | (((0U == (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                              ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                        [
                                                        (((IData)(0x00000023U) 
                                                          + 
                                                          (0x000000ffU 
                                                           & ((IData)(0x00000058U) 
                                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                         >> 5U)])) 
                                        << ((IData)(0x00000020U) 
                                            - (0x0000001fU 
                                               & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                            | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                               [(((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                 >> 5U)])) 
                               >> (0x0000001fU & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))))) 
                >> 8U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                     [
                                                     (((IData)(0x00000043U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                      >> 5U)])) 
                                     << ((0U == (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                          ? 0x00000020U
                                          : ((IData)(0x00000040U) 
                                             - (0x0000001fU 
                                                & ((IData)(4U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                    | (((0U == (0x0000001fU 
                                                & ((IData)(4U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                         ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                   [
                                                                   (((IData)(0x00000023U) 
                                                                     + 
                                                                     (0x000000ffU 
                                                                      & ((IData)(0x00000058U) 
                                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                                    >> 5U)])) 
                                                   << 
                                                   ((IData)(0x00000020U) 
                                                    - 
                                                    (0x0000001fU 
                                                     & ((IData)(4U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000058U) 
                                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                       | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                          [
                                                          (((IData)(4U) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000058U) 
                                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                           >> 5U)])) 
                                          >> (0x0000001fU 
                                              & ((IData)(4U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                   >> 0x00000020U)) 
                          << 0x00000018U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xff000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                             [(((IData)(0x00000043U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                               >> 5U)])) 
                             << ((0U == (0x0000001fU 
                                         & ((IData)(4U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                  ? 0x00000020U : ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                            | (((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                 ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                           [
                                                           (((IData)(0x00000023U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000058U) 
                                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                            >> 5U)])) 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(4U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                               | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                  [
                                                  (((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                                   >> 5U)])) 
                                  >> (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                           >> 0x00000020U)) >> 8U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xff3fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00c00000U & ((((0U == (0x0000001fU 
                                           & ((IData)(2U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(3U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(2U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U])))))) 
                                 << 0x00000016U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xffdfffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00200000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(1U) + 
                                     (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(1U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))))) 
                                 << 0x00000015U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
            = ((0xffefffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U]) 
               | (0x00100000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(7U & (((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]) 
                                          >> 5U))] 
                                  >> (0x0000001fU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[1U]))) 
                                 << 0x00000014U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 1U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = (0xc0000000U | (0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xffffffe0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x3fffffffU & ((0x3ffffff0U & (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[1U] 
                                                 << 4U)) 
                                 | (0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_id[1U]))));
    } else if ((2U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xffffffefU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x00000010U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x00000054U) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x00000054U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))) 
                                 << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffffff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x0000000fU & (((0U == (0x0000001fU 
                                          & ((IData)(0x0000004eU) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U])))))
                                   ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                           [(((IData)(0x00000051U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                                             >> 5U)] 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(0x0000004eU) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))))) 
                                 | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                    [(((IData)(0x0000004eU) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                                      >> 5U)] >> (0x0000001fU 
                                                  & ((IData)(0x0000004eU) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | ((((0U == (0x0000001fU & ((IData)(0x0000004cU) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U])))))
                     ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(0x0000004dU) 
                                + (0x000000ffU & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                               >> 5U)] << ((IData)(0x00000020U) 
                                           - (0x0000001fU 
                                              & ((IData)(0x0000004cU) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))))) 
                   | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x0000004cU) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x0000004cU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U])))))) 
                  << 0x0000001eU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[4U]) 
               | (0x20000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004bU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004bU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[1U]))))) 
                                 << 0x0000001dU)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
        = (0x000000ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = (0xf0000000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0xfbffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                  >> 2U) & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))
                             ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                                >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))
                             : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___35))) 
                & (2U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___36))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[2U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000056U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000056U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[2U]))))))) 
              << 0x0000001aU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0xf7ffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                  >> 2U) & ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))
                             ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                                >> (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))
                             : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___37))) 
                & (2U == ((2U >= (3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))
                           ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win
                          [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U])]
                           : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___38))) 
               & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U])
                   ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[2U])
                   : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(0x00000057U) + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(0x00000057U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[2U]))))))) 
              << 0x0000001bU));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = ((0xfdffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
           | (0x02000000U & (((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
                              << 0x00000017U) & (((2U 
                                                   == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U]) 
                                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                     [
                                                     (((IData)(0x00000055U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U]))) 
                                                      >> 5U)] 
                                                     >> 
                                                     (0x0000001fU 
                                                      & ((IData)(0x00000055U) 
                                                         + 
                                                         (0x000000ffU 
                                                          & ((IData)(0x00000058U) 
                                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[2U])))))) 
                                                 << 0x00000019U))));
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 2U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = (0x00000fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]);
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfffe0000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[2U] 
                   << 0x00000010U) | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_id[2U] 
                                      << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffff1ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0xfffffe00U & (0x00000c00U | ((1U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_left[2U]) 
                                                << 9U))));
    } else if ((4U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfffeffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x00010000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004aU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004aU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))) 
                                 << 0x00000010U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xffff0fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x0000f000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x00000044U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000047U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000044U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000044U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))) 
                                 << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0x00000fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | ((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000043U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                              >> 5U)])) 
                            << ((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                 ? 0x00000020U : ((IData)(0x00000040U) 
                                                  - 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                           | (((0U == (0x0000001fU 
                                       & ((IData)(4U) 
                                          + (0x000000ffU 
                                             & ((IData)(0x00000058U) 
                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                          [
                                                          (((IData)(0x00000023U) 
                                                            + 
                                                            (0x000000ffU 
                                                             & ((IData)(0x00000058U) 
                                                                * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                           >> 5U)])) 
                                          << ((IData)(0x00000020U) 
                                              - (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                              | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                 [(
                                                   ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                   >> 5U)])) 
                                 >> (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))))) 
                  << 0x0000000cU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[6U] 
            = (((IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                          [(((IData)(0x00000043U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                            >> 5U)])) 
                          << ((0U == (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                               ? 0x00000020U : ((IData)(0x00000040U) 
                                                - (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                         | (((0U == (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                              ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                        [
                                                        (((IData)(0x00000023U) 
                                                          + 
                                                          (0x000000ffU 
                                                           & ((IData)(0x00000058U) 
                                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                         >> 5U)])) 
                                        << ((IData)(0x00000020U) 
                                            - (0x0000001fU 
                                               & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                            | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                               [(((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                 >> 5U)])) 
                               >> (0x0000001fU & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))))) 
                >> 0x00000014U) | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                              [
                                                              (((IData)(0x00000043U) 
                                                                + 
                                                                (0x000000ffU 
                                                                 & ((IData)(0x00000058U) 
                                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                               >> 5U)])) 
                                              << ((0U 
                                                   == 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                                   ? 0x00000020U
                                                   : 
                                                  ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                             | (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & ((IData)(4U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                                  ? 0ULL
                                                  : 
                                                 ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                  [
                                                                  (((IData)(0x00000023U) 
                                                                    + 
                                                                    (0x000000ffU 
                                                                     & ((IData)(0x00000058U) 
                                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                                   >> 5U)])) 
                                                  << 
                                                  ((IData)(0x00000020U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                                | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                                   [
                                                                   (((IData)(4U) 
                                                                     + 
                                                                     (0x000000ffU 
                                                                      & ((IData)(0x00000058U) 
                                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                                    >> 5U)])) 
                                                   >> 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                            >> 0x00000020U)) 
                                   << 0x0000000cU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfffff000U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | ((IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                             [(((IData)(0x00000043U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                               >> 5U)])) 
                             << ((0U == (0x0000001fU 
                                         & ((IData)(4U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                  ? 0x00000020U : ((IData)(0x00000040U) 
                                                   - 
                                                   (0x0000001fU 
                                                    & ((IData)(4U) 
                                                       + 
                                                       (0x000000ffU 
                                                        & ((IData)(0x00000058U) 
                                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                            | (((0U == (0x0000001fU 
                                        & ((IData)(4U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                 ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                           [
                                                           (((IData)(0x00000023U) 
                                                             + 
                                                             (0x000000ffU 
                                                              & ((IData)(0x00000058U) 
                                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                            >> 5U)])) 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(4U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                               | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                  [
                                                  (((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                                   >> 5U)])) 
                                  >> (0x0000001fU & 
                                      ((IData)(4U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                           >> 0x00000020U)) >> 0x00000014U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffff3ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x00000c00U & ((((0U == (0x0000001fU 
                                           & ((IData)(2U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(3U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(2U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(2U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U])))))) 
                                 << 0x0000000aU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffffdffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x00000200U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(1U) + 
                                     (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(1U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))))) 
                                 << 9U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
            = ((0xfffffeffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U]) 
               | (0x00000100U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(7U & (((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]) 
                                          >> 5U))] 
                                  >> (0x0000001fU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[2U]))) 
                                 << 8U)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 2U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfe03ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0xfffc0000U & (0x000c0000U | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[2U] 
                                                 << 0x00000018U) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_id[2U] 
                                                   << 0x00000014U)))));
    } else if ((4U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfeffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x01000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x00000054U) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x00000054U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))))) 
                                 << 0x00000018U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xff0fffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x00f00000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004eU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000051U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004eU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U])))))) 
                                 << 0x00000014U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfff3ffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x000c0000U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004cU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x0000004dU) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004cU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U])))))) 
                                 << 0x00000012U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xfffdffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x00020000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004bU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004bU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[2U]))))) 
                                 << 0x00000011U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
        = (0x0fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]);
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] = 0U;
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
        = ((0x0000bfffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
           | (0x0000ffffU & ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_ok) 
                                 >> 3U) & ((2U >= (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))
                                            ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win_v) 
                                               >> (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))
                                            : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___35))) 
                               & (3U == ((2U >= (3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))
                                          ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_win
                                         [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U])]
                                          : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___36))) 
                              & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U])
                                  ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[3U])
                                  : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000056U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000056U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__ar_dst[3U]))))))) 
                             << 0x0000000eU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
        = ((0x00007fffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
           | (0x0000ffffU & ((((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_ok) 
                                 >> 3U) & ((2U >= (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))
                                            ? ((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win_v) 
                                               >> (3U 
                                                   & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))
                                            : (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___37))) 
                               & (3U == ((2U >= (3U 
                                                 & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))
                                          ? vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_win
                                         [(3U & vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U])]
                                          : vlSelfRef.axi4_xbar_tb__DOT__dut__DOT____Vxrand___38))) 
                              & ((2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U])
                                  ? (~ vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[3U])
                                  : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x00000057U) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x00000057U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__aw_dst[3U]))))))) 
                             << 0x0000000fU)));
    vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
        = ((0x0000dfffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
           | (0x0000ffffU & ((IData)((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_go) 
                                       >> 3U) & ((2U 
                                                  == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U]) 
                                                 | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                    [
                                                    (((IData)(0x00000055U) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U]))) 
                                                     >> 5U)] 
                                                    >> 
                                                    (0x0000001fU 
                                                     & ((IData)(0x00000055U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000058U) 
                                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__w_dst[3U])))))))) 
                             << 0x0000000dU)));
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v) 
          >> 3U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U] = 0U;
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000ffe0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x0000ffffU & ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_busy[3U] 
                                  << 4U) | vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_id[3U])));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0x1fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0xe0000000U & (0xc0000000U | ((1U 
                                                 == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_r_left[3U]) 
                                                << 0x0000001dU))));
    } else if ((8U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000ffefU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x00000010U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004aU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004aU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))) 
                                 << 4U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000fff0U & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x0000000fU & (((0U == (0x0000001fU 
                                          & ((IData)(0x00000044U) 
                                             + (0x000000ffU 
                                                & ((IData)(0x00000058U) 
                                                   * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                                   ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                           [(((IData)(0x00000047U) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                             >> 5U)] 
                                           << ((IData)(0x00000020U) 
                                               - (0x0000001fU 
                                                  & ((IData)(0x00000044U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                                 | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                    [(((IData)(0x00000044U) 
                                       + (0x000000ffU 
                                          & ((IData)(0x00000058U) 
                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                      >> 5U)] >> (0x0000001fU 
                                                  & ((IData)(0x00000044U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[8U] 
            = (IData)((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                        [(((IData)(0x00000043U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                          >> 5U)])) 
                        << ((0U == (0x0000001fU & ((IData)(4U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                             ? 0x00000020U : ((IData)(0x00000040U) 
                                              - (0x0000001fU 
                                                 & ((IData)(4U) 
                                                    + 
                                                    (0x000000ffU 
                                                     & ((IData)(0x00000058U) 
                                                        * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                       | (((0U == (0x0000001fU & ((IData)(4U) 
                                                  + 
                                                  (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                            ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                      [
                                                      (((IData)(0x00000023U) 
                                                        + 
                                                        (0x000000ffU 
                                                         & ((IData)(0x00000058U) 
                                                            * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                                       >> 5U)])) 
                                      << ((IData)(0x00000020U) 
                                          - (0x0000001fU 
                                             & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                          | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                             [(((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                               >> 5U)])) 
                             >> (0x0000001fU & ((IData)(4U) 
                                                + (0x000000ffU 
                                                   & ((IData)(0x00000058U) 
                                                      * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[9U] 
            = (IData)(((((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                         [(((IData)(0x00000043U) 
                                            + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                           >> 5U)])) 
                         << ((0U == (0x0000001fU & 
                                     ((IData)(4U) + 
                                      (0x000000ffU 
                                       & ((IData)(0x00000058U) 
                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                              ? 0x00000020U : ((IData)(0x00000040U) 
                                               - (0x0000001fU 
                                                  & ((IData)(4U) 
                                                     + 
                                                     (0x000000ffU 
                                                      & ((IData)(0x00000058U) 
                                                         * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                        | (((0U == (0x0000001fU & ((IData)(4U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                             ? 0ULL : ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                                       [
                                                       (((IData)(0x00000023U) 
                                                         + 
                                                         (0x000000ffU 
                                                          & ((IData)(0x00000058U) 
                                                             * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                                        >> 5U)])) 
                                       << ((IData)(0x00000020U) 
                                           - (0x0000001fU 
                                              & ((IData)(4U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                           | ((QData)((IData)(vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                              [(((IData)(4U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                                >> 5U)])) 
                              >> (0x0000001fU & ((IData)(4U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                       >> 0x00000020U));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0x3fffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | ((((0U == (0x0000001fU & ((IData)(2U) 
                                           + (0x000000ffU 
                                              & ((IData)(0x00000058U) 
                                                 * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))
                     ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                             [(((IData)(3U) + (0x000000ffU 
                                               & ((IData)(0x00000058U) 
                                                  * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                               >> 5U)] << ((IData)(0x00000020U) 
                                           - (0x0000001fU 
                                              & ((IData)(2U) 
                                                 + 
                                                 (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))))) 
                   | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                      [(((IData)(2U) + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                        >> 5U)] >> (0x0000001fU & ((IData)(2U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U])))))) 
                  << 0x0000001eU));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xdfffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x20000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(1U) + 
                                     (0x000000ffU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(1U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))))) 
                                 << 0x0000001dU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
            = ((0xefffffffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U]) 
               | (0x10000000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(7U & (((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]) 
                                          >> 5U))] 
                                  >> (0x0000001fU & 
                                      ((IData)(0x00000058U) 
                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__r_pick[3U]))) 
                                 << 0x0000001cU)));
    }
    if ((((IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v) 
          >> 3U) & (2U == vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000e03fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x0000ffc0U & (0x000000c0U | ((vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_busy[3U] 
                                                 << 0x0000000cU) 
                                                | (vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__err_b_id[3U] 
                                                   << 8U)))));
    } else if ((8U & (IData)(vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick_v))) {
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000efffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x00001000U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x00000054U) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x00000054U) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))))) 
                                 << 0x0000000cU)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000f0ffU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x00000f00U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004eU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x00000051U) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004eU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004eU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U])))))) 
                                 << 8U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000ff3fU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x000000c0U & ((((0U == (0x0000001fU 
                                           & ((IData)(0x0000004cU) 
                                              + (0x000000ffU 
                                                 & ((IData)(0x00000058U) 
                                                    * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U])))))
                                    ? 0U : (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                            [(((IData)(0x0000004dU) 
                                               + (0x000000ffU 
                                                  & ((IData)(0x00000058U) 
                                                     * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                              >> 5U)] 
                                            << ((IData)(0x00000020U) 
                                                - (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))))))) 
                                  | (vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                     [(((IData)(0x0000004cU) 
                                        + (0x000000ffU 
                                           & ((IData)(0x00000058U) 
                                              * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                       >> 5U)] >> (0x0000001fU 
                                                   & ((IData)(0x0000004cU) 
                                                      + 
                                                      (0x000000ffU 
                                                       & ((IData)(0x00000058U) 
                                                          * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U])))))) 
                                 << 6U)));
        vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
            = ((0x0000ffdfU & vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U]) 
               | (0x00000020U & ((vlSelfRef.axi4_xbar_tb__DOT__slv_resp
                                  [(((IData)(0x0000004bU) 
                                     + (0x000000ffU 
                                        & ((IData)(0x00000058U) 
                                           * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))) 
                                    >> 5U)] >> (0x0000001fU 
                                                & ((IData)(0x0000004bU) 
                                                   + 
                                                   (0x000000ffU 
                                                    & ((IData)(0x00000058U) 
                                                       * vlSelfRef.axi4_xbar_tb__DOT__dut__DOT__b_pick[3U]))))) 
                                 << 5U)));
    }
    vlSelfRef.axi4_xbar_tb__DOT__lm_off = ((((2U & 
                                              ((VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[3U]) 
                                                | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[3U]) 
                                                   | (((~ 
                                                        (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                                         >> 0x0000000eU)) 
                                                       & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[20U] 
                                                          >> 0x0000000cU)) 
                                                      | ((~ 
                                                          (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[10U] 
                                                           >> 0x0000000fU)) 
                                                         & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[24U] 
                                                            >> 0x0000001bU))))) 
                                               << 1U)) 
                                             | (1U 
                                                & (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[2U]) 
                                                   | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[2U]) 
                                                      | (((~ 
                                                           (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                            >> 0x0000001aU)) 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[13U] 
                                                             >> 0x00000013U)) 
                                                         | ((~ 
                                                             (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[7U] 
                                                              >> 0x0000001bU)) 
                                                            & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[18U] 
                                                               >> 2U))))))) 
                                            << 2U) 
                                           | ((2U & 
                                               ((VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[1U]) 
                                                 | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[1U]) 
                                                    | (((~ 
                                                         (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                                          >> 6U)) 
                                                        & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[6U] 
                                                           >> 0x0000001aU)) 
                                                       | ((~ 
                                                           (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[5U] 
                                                            >> 7U)) 
                                                          & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[11U] 
                                                             >> 9U))))) 
                                                << 1U)) 
                                              | (1U 
                                                 & (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_r[0U]) 
                                                    | (VL_LTS_III(32, 0U, vlSelfRef.axi4_xbar_tb__DOT__outstanding_w[0U]) 
                                                       | (((~ 
                                                            (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                             >> 0x00000012U)) 
                                                           & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[0U] 
                                                              >> 1U)) 
                                                          | ((~ 
                                                              (vlSelfRef.axi4_xbar_tb__DOT____Vcellout__dut__mst_resp[2U] 
                                                               >> 0x00000013U)) 
                                                             & (vlSelfRef.axi4_xbar_tb__DOT__mst_req[4U] 
                                                                >> 0x00000010U))))))));
}

void Vaxi4_xbar_tb___024root___nba_sequent__TOP__0(Vaxi4_xbar_tb___024root* vlSelf);

void Vaxi4_xbar_tb___024root___eval_nba(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_nba\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vaxi4_xbar_tb___024root___nba_sequent__TOP__0(vlSelf);
        Vaxi4_xbar_tb___024root___nba_sequent__TOP__1(vlSelf);
    }
}

void Vaxi4_xbar_tb___024root___timing_ready(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___timing_ready\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready("@(posedge axi4_xbar_tb.clk)");
    }
}

void Vaxi4_xbar_tb___024root___timing_resume(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___timing_resume\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_ha9bc5c2b__0.moveToResumeQueue(
                                                          "@(posedge axi4_xbar_tb.clk)");
    vlSelfRef.__VtrigSched_ha9bc5c2b__0.resume("@(posedge axi4_xbar_tb.clk)");
    if ((2ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vaxi4_xbar_tb___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

void Vaxi4_xbar_tb___024root___eval_triggers_vec__act(Vaxi4_xbar_tb___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi4_xbar_tb___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
bool Vaxi4_xbar_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);
void Vaxi4_xbar_tb___024root___eval_act(Vaxi4_xbar_tb___024root* vlSelf);

bool Vaxi4_xbar_tb___024root___eval_phase__act(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_phase__act\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    Vaxi4_xbar_tb___024root___eval_triggers_vec__act(vlSelf);
    Vaxi4_xbar_tb___024root___timing_ready(vlSelf);
    Vaxi4_xbar_tb___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vaxi4_xbar_tb___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vaxi4_xbar_tb___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vaxi4_xbar_tb___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vaxi4_xbar_tb___024root___timing_resume(vlSelf);
        Vaxi4_xbar_tb___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vaxi4_xbar_tb___024root___eval_phase__inact(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_phase__inact\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("tb/axi4_xbar_tb.sv", 40, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vaxi4_xbar_tb___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vaxi4_xbar_tb___024root___eval_phase__nba(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_phase__nba\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vaxi4_xbar_tb___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vaxi4_xbar_tb___024root___eval_nba(vlSelf);
        Vaxi4_xbar_tb___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vaxi4_xbar_tb___024root___eval(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vaxi4_xbar_tb___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("tb/axi4_xbar_tb.sv", 40, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 100 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VinactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VinactIterCount)))) {
                VL_FATAL_MT("tb/axi4_xbar_tb.sv", 40, "", "DIDNOTCONVERGE: Inactive region did not converge after '--converge-limit' of 100 tries");
            }
            vlSelfRef.__VinactIterCount = ((IData)(1U) 
                                           + vlSelfRef.__VinactIterCount);
            vlSelfRef.__VactIterCount = 0U;
            do {
                if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                    Vaxi4_xbar_tb___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                    VL_FATAL_MT("tb/axi4_xbar_tb.sv", 40, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 100 tries");
                }
                vlSelfRef.__VactIterCount = ((IData)(1U) 
                                             + vlSelfRef.__VactIterCount);
                vlSelfRef.__VactPhaseResult = Vaxi4_xbar_tb___024root___eval_phase__act(vlSelf);
            } while (vlSelfRef.__VactPhaseResult);
            vlSelfRef.__VinactPhaseResult = Vaxi4_xbar_tb___024root___eval_phase__inact(vlSelf);
        } while (vlSelfRef.__VinactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = Vaxi4_xbar_tb___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

void Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0(Vaxi4_xbar_tb___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root____VbeforeTrig_ha9bc5c2b__0\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((IData)(vlSelfRef.axi4_xbar_tb__DOT__clk) 
                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__axi4_xbar_tb__DOT__clk__0 
        = vlSelfRef.axi4_xbar_tb__DOT__clk;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha9bc5c2b__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vaxi4_xbar_tb___024root___eval_debug_assertions(Vaxi4_xbar_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi4_xbar_tb___024root___eval_debug_assertions\n"); );
    Vaxi4_xbar_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
