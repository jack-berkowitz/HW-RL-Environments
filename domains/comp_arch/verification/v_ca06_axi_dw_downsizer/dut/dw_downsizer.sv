// ---------------------------------------------------------------------------
// GOLDEN -- scoring only. NEVER shipped to a submission.
//
// Class A port shim for axi_dw_downsizer: flattens the anchor's four
// `parameter type` request/response structs into plain signals and pins the
// scored configuration.
//
// WHAT IS EXPOSED, AND WHY. id, addr, len, SIZE and BURST on both address
// channels. size and burst are not incidental here -- the whole contract turns
// on them: a WRAP burst must be answered SLVERR, a multi-beat FIXED burst must
// be answered SLVERR, and size fixes how many bytes each beat carries and
// therefore how the re-segmentation lands. Pinning either would delete the
// task. lock/cache/prot/qos/region/atop/user are pinned to constants: the
// downsizer forwards them unchanged and nothing in this contract reads them.
//
// Wiring and renaming only -- no segmentation, no buffering, no logic of its own.
// ---------------------------------------------------------------------------
// =============================================================================
// id_width_conv.sv -- GOLDEN DUT for v_ca03.  NEVER SHIPPED TO A SUBMISSION.
// =============================================================================
// A port shim over the vendored anchor. Class A: struct pack/unpack and
// constant tie-off only -- no behaviour is added, removed or bridged.
//
// WHY THE PORT MAP IS FLAT
// ------------------------
// The anchor's ports are four `parameter type` structs. Shipping those would
// ship the vendored type names and force a submission to reconstruct them.
// The shim unpacks each channel into plain signals, which is exactly the
// pack/unpack a Class A shim is allowed.
//
// WHAT IS TIED OFF, AND WHY IT IS NOT PART OF THE CONTRACT
// --------------------------------------------------------
//   size    fixed to the full bus width, burst fixed to INCR
//   lock, cache, prot, qos, region, user, atop  tied to zero
// None of them participates in ID conversion, ordering or table occupancy --
// the three properties under test -- so exposing them would add port surface
// that no clause could constrain. Recorded here rather than left implicit.
//
// SCORED CONFIGURATION, bound here rather than exposed (rule 18)
// --------------------------------------------------------------
//   the REMAP path is selected, not the serialize path, by keeping
//   MAX_UNIQ_IDS <= 2**MST_ID_W. The two are different designs inside the
//   anchor; pinning one is required for a single contract to describe it.
// =============================================================================

// ---- INLINED axi/typedef.svh (harness passes no -I) ----
// Copyright (c) 2019 ETH Zurich, University of Bologna
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Authors:
// - Andreas Kurth <akurth@iis.ee.ethz.ch>
// - Thomas Benz <tbenz@iis.ee.ethz.ch>
// - Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// - Wolfgang Roenninger <wroennin@iis.ee.ethz.ch>
// - Riccardo Tedeschi <riccardo.tedeschi6@unibo.it>

// Macros to define AXI and AXI-Lite Channel and Request/Response Structs

`ifndef AXI_TYPEDEF_SVH_
`define AXI_TYPEDEF_SVH_

////////////////////////////////////////////////////////////////////////////////////////////////////
// AXI4+ATOP Channel and Request/Response Structs
//
// Usage Example:
// `AXI_TYPEDEF_AW_CHAN_T(axi_aw_t, axi_addr_t, axi_id_t, axi_user_t)
// `AXI_TYPEDEF_W_CHAN_T(axi_w_t, axi_data_t, axi_strb_t, axi_user_t)
// `AXI_TYPEDEF_B_CHAN_T(axi_b_t, axi_id_t, axi_user_t)
// `AXI_TYPEDEF_AR_CHAN_T(axi_ar_t, axi_addr_t, axi_id_t, axi_user_t)
// `AXI_TYPEDEF_R_CHAN_T(axi_r_t, axi_data_t, axi_id_t, axi_user_t)
// `AXI_TYPEDEF_REQ_T(axi_req_t, axi_aw_t, axi_w_t, axi_ar_t)
// `AXI_TYPEDEF_RESP_T(axi_resp_t, axi_b_t, axi_r_t)
`define AXI_DECL_AW_CHAN_T(addr_t, id_t, user_t) \
  struct packed {                                \
    id_t              id;                        \
    addr_t            addr;                      \
    axi_pkg::len_t    len;                       \
    axi_pkg::size_t   size;                      \
    axi_pkg::burst_t  burst;                     \
    logic             lock;                      \
    axi_pkg::cache_t  cache;                     \
    axi_pkg::prot_t   prot;                      \
    axi_pkg::qos_t    qos;                       \
    axi_pkg::region_t region;                    \
    axi_pkg::atop_t   atop;                      \
    user_t            user;                      \
  }
`define AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t, id_t, user_t) \
  typedef `AXI_DECL_AW_CHAN_T(addr_t, id_t, user_t) aw_chan_t;
`define AXI_DECL_W_CHAN_T(data_t, strb_t, user_t)  \
  struct packed {                                  \
    data_t data;                                   \
    strb_t strb;                                   \
    logic  last;                                   \
    user_t user;                                   \
  }
`define AXI_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t, user_t)  \
  typedef `AXI_DECL_W_CHAN_T(data_t, strb_t, user_t) w_chan_t;
`define AXI_DECL_B_CHAN_T(id_t, user_t)  \
  struct packed {                        \
    id_t            id;                  \
    axi_pkg::resp_t resp;                \
    user_t          user;                \
  }
`define AXI_TYPEDEF_B_CHAN_T(b_chan_t, id_t, user_t)  \
  typedef `AXI_DECL_B_CHAN_T(id_t, user_t) b_chan_t;
`define AXI_DECL_AR_CHAN_T(addr_t, id_t, user_t) \
  struct packed {                                \
    id_t              id;                        \
    addr_t            addr;                      \
    axi_pkg::len_t    len;                       \
    axi_pkg::size_t   size;                      \
    axi_pkg::burst_t  burst;                     \
    logic             lock;                      \
    axi_pkg::cache_t  cache;                     \
    axi_pkg::prot_t   prot;                      \
    axi_pkg::qos_t    qos;                       \
    axi_pkg::region_t region;                    \
    user_t            user;                      \
  }
`define AXI_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t, id_t, user_t)  \
  typedef `AXI_DECL_AR_CHAN_T(addr_t, id_t, user_t) ar_chan_t;
`define AXI_DECL_R_CHAN_T(data_t, id_t, user_t)  \
  struct packed {                                \
    id_t            id;                          \
    data_t          data;                        \
    axi_pkg::resp_t resp;                        \
    logic           last;                        \
    user_t          user;                        \
  }
`define AXI_TYPEDEF_R_CHAN_T(r_chan_t, data_t, id_t, user_t) \
  typedef `AXI_DECL_R_CHAN_T(data_t, id_t, user_t) r_chan_t;
`define AXI_DECL_REQ_T(aw_chan_t, w_chan_t, ar_chan_t)  \
  struct packed {                                       \
    aw_chan_t aw;                                       \
    logic     aw_valid;                                 \
    w_chan_t  w;                                        \
    logic     w_valid;                                  \
    logic     b_ready;                                  \
    ar_chan_t ar;                                       \
    logic     ar_valid;                                 \
    logic     r_ready;                                  \
  }
`define AXI_TYPEDEF_REQ_T(req_t, aw_chan_t, w_chan_t, ar_chan_t)  \
  typedef `AXI_DECL_REQ_T(aw_chan_t, w_chan_t, ar_chan_t) req_t;
`define AXI_DECL_RESP_T(b_chan_t, r_chan_t)  \
  struct packed {                            \
    logic     aw_ready;                      \
    logic     ar_ready;                      \
    logic     w_ready;                       \
    logic     b_valid;                       \
    b_chan_t  b;                             \
    logic     r_valid;                       \
    r_chan_t  r;                             \
  }
`define AXI_TYPEDEF_RESP_T(resp_t, b_chan_t, r_chan_t)  \
  typedef `AXI_DECL_RESP_T(b_chan_t, r_chan_t) resp_t;
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// All AXI4+ATOP Channels and Request/Response Structs in One Macro - Custom Type Name Version
//
// This can be used whenever the user is not interested in "precise" control of the naming of the
// individual channels.
//
// Usage Example:
// `AXI_TYPEDEF_ALL_CT(axi, axi_req_t, axi_rsp_t, addr_t, id_t, data_t, strb_t, user_t)
//
// This defines `axi_req_t` and `axi_rsp_t` request/response structs as well as `axi_aw_chan_t`,
// `axi_w_chan_t`, `axi_b_chan_t`, `axi_ar_chan_t`, and `axi_r_chan_t` channel structs.
`define AXI_TYPEDEF_ALL_CT(__name, __req, __rsp, __addr_t, __id_t, __data_t, __strb_t, __user_t) \
  `AXI_TYPEDEF_AW_CHAN_T(__name``_aw_chan_t, __addr_t, __id_t, __user_t)                         \
  `AXI_TYPEDEF_W_CHAN_T(__name``_w_chan_t, __data_t, __strb_t, __user_t)                         \
  `AXI_TYPEDEF_B_CHAN_T(__name``_b_chan_t, __id_t, __user_t)                                     \
  `AXI_TYPEDEF_AR_CHAN_T(__name``_ar_chan_t, __addr_t, __id_t, __user_t)                         \
  `AXI_TYPEDEF_R_CHAN_T(__name``_r_chan_t, __data_t, __id_t, __user_t)                           \
  `AXI_TYPEDEF_REQ_T(__req, __name``_aw_chan_t, __name``_w_chan_t, __name``_ar_chan_t)           \
  `AXI_TYPEDEF_RESP_T(__rsp, __name``_b_chan_t, __name``_r_chan_t)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// All AXI4+ATOP Channels and Request/Response Structs in One Macro
//
// This can be used whenever the user is not interested in "precise" control of the naming of the
// individual channels.
//
// Usage Example:
// `AXI_TYPEDEF_ALL(axi, addr_t, id_t, data_t, strb_t, user_t)
//
// This defines `axi_req_t` and `axi_resp_t` request/response structs as well as `axi_aw_chan_t`,
// `axi_w_chan_t`, `axi_b_chan_t`, `axi_ar_chan_t`, and `axi_r_chan_t` channel structs.
`define AXI_TYPEDEF_ALL(__name, __addr_t, __id_t, __data_t, __strb_t, __user_t)                                \
  `AXI_TYPEDEF_ALL_CT(__name, __name``_req_t, __name``_resp_t, __addr_t, __id_t, __data_t, __strb_t, __user_t)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// AXI4-Lite Channel and Request/Response Structs
//
// Usage Example:
// `AXI_LITE_TYPEDEF_AW_CHAN_T(axi_lite_aw_t, axi_lite_addr_t)
// `AXI_LITE_TYPEDEF_W_CHAN_T(axi_lite_w_t, axi_lite_data_t, axi_lite_strb_t)
// `AXI_LITE_TYPEDEF_B_CHAN_T(axi_lite_b_t)
// `AXI_LITE_TYPEDEF_AR_CHAN_T(axi_lite_ar_t, axi_lite_addr_t)
// `AXI_LITE_TYPEDEF_R_CHAN_T(axi_lite_r_t, axi_lite_data_t)
// `AXI_LITE_TYPEDEF_REQ_T(axi_lite_req_t, axi_lite_aw_t, axi_lite_w_t, axi_lite_ar_t)
// `AXI_LITE_TYPEDEF_RESP_T(axi_lite_resp_t, axi_lite_b_t, axi_lite_r_t)
`define AXI_LITE_DECL_AW_CHAN_T(addr_t)  \
  struct packed {                        \
    addr_t          addr;                \
    axi_pkg::prot_t prot;                \
  }
`define AXI_LITE_TYPEDEF_AW_CHAN_T(aw_chan_lite_t, addr_t)  \
  typedef `AXI_LITE_DECL_AW_CHAN_T(addr_t) aw_chan_lite_t;
`define AXI_LITE_DECL_W_CHAN_T(data_t, strb_t)  \
  struct packed {                               \
    data_t   data;                              \
    strb_t   strb;                              \
  }
`define AXI_LITE_TYPEDEF_W_CHAN_T(w_chan_lite_t, data_t, strb_t)  \
  typedef `AXI_LITE_DECL_W_CHAN_T(data_t, strb_t) w_chan_lite_t;
`define AXI_LITE_DECL_B_CHAN_T     \
  struct packed {                  \
    axi_pkg::resp_t resp;          \
  }
`define AXI_LITE_TYPEDEF_B_CHAN_T(b_chan_lite_t)  \
  typedef `AXI_LITE_DECL_B_CHAN_T   b_chan_lite_t;
`define AXI_LITE_DECL_AR_CHAN_T(addr_t)  \
  struct packed {                        \
    addr_t          addr;                \
    axi_pkg::prot_t prot;                \
  }
`define AXI_LITE_TYPEDEF_AR_CHAN_T(ar_chan_lite_t, addr_t)  \
  typedef `AXI_LITE_DECL_AR_CHAN_T(addr_t) ar_chan_lite_t;
`define AXI_LITE_DECL_R_CHAN_T(data_t)  \
  struct packed {                       \
    data_t          data;               \
    axi_pkg::resp_t resp;               \
  }
`define AXI_LITE_TYPEDEF_R_CHAN_T(r_chan_lite_t, data_t)  \
  typedef `AXI_LITE_DECL_R_CHAN_T(data_t) r_chan_lite_t;
`define AXI_LITE_DECL_REQ_T(aw_chan_lite_t, w_chan_lite_t, ar_chan_lite_t)  \
  struct packed {                                                           \
    aw_chan_lite_t aw;                                                      \
    logic          aw_valid;                                                \
    w_chan_lite_t  w;                                                       \
    logic          w_valid;                                                 \
    logic          b_ready;                                                 \
    ar_chan_lite_t ar;                                                      \
    logic          ar_valid;                                                \
    logic          r_ready;                                                 \
  }
`define AXI_LITE_TYPEDEF_REQ_T(req_lite_t, aw_chan_lite_t, w_chan_lite_t, ar_chan_lite_t)  \
  typedef `AXI_LITE_DECL_REQ_T(aw_chan_lite_t, w_chan_lite_t, ar_chan_lite_t) req_lite_t;
`define AXI_LITE_DECL_RESP_T(b_chan_lite_t, r_chan_lite_t)  \
  struct packed {                                           \
    logic          aw_ready;                                \
    logic          w_ready;                                 \
    b_chan_lite_t  b;                                       \
    logic          b_valid;                                 \
    logic          ar_ready;                                \
    r_chan_lite_t  r;                                       \
    logic          r_valid;                                 \
  }
`define AXI_LITE_TYPEDEF_RESP_T(resp_lite_t, b_chan_lite_t, r_chan_lite_t)  \
  typedef `AXI_LITE_DECL_RESP_T(b_chan_lite_t, r_chan_lite_t) resp_lite_t;
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// All AXI4-Lite Channels and Request/Response Structs in One Macro - Custom Type Name Version
//
// This can be used whenever the user is not interested in "precise" control of the naming of the
// individual channels.
//
// Usage Example:
// `AXI_LITE_TYPEDEF_ALL_CT(axi_lite, axi_lite_req_t, axi_lite_rsp_t, addr_t, data_t, strb_t)
//
// This defines `axi_lite_req_t` and `axi_lite_resp_t` request/response structs as well as
// `axi_lite_aw_chan_t`, `axi_lite_w_chan_t`, `axi_lite_b_chan_t`, `axi_lite_ar_chan_t`, and
// `axi_lite_r_chan_t` channel structs.
`define AXI_LITE_TYPEDEF_ALL_CT(__name, __req, __rsp, __addr_t, __data_t, __strb_t)         \
  `AXI_LITE_TYPEDEF_AW_CHAN_T(__name``_aw_chan_t, __addr_t)                                 \
  `AXI_LITE_TYPEDEF_W_CHAN_T(__name``_w_chan_t, __data_t, __strb_t)                         \
  `AXI_LITE_TYPEDEF_B_CHAN_T(__name``_b_chan_t)                                             \
  `AXI_LITE_TYPEDEF_AR_CHAN_T(__name``_ar_chan_t, __addr_t)                                 \
  `AXI_LITE_TYPEDEF_R_CHAN_T(__name``_r_chan_t, __data_t)                                   \
  `AXI_LITE_TYPEDEF_REQ_T(__req, __name``_aw_chan_t, __name``_w_chan_t, __name``_ar_chan_t) \
  `AXI_LITE_TYPEDEF_RESP_T(__rsp, __name``_b_chan_t, __name``_r_chan_t)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// All AXI4-Lite Channels and Request/Response Structs in One Macro
//
// This can be used whenever the user is not interested in "precise" control of the naming of the
// individual channels.
//
// Usage Example:
// `AXI_LITE_TYPEDEF_ALL(axi_lite, addr_t, data_t, strb_t)
//
// This defines `axi_lite_req_t` and `axi_lite_resp_t` request/response structs as well as
// `axi_lite_aw_chan_t`, `axi_lite_w_chan_t`, `axi_lite_b_chan_t`, `axi_lite_ar_chan_t`, and
// `axi_lite_r_chan_t` channel structs.
`define AXI_LITE_TYPEDEF_ALL(__name, __addr_t, __data_t, __strb_t)                                \
  `AXI_LITE_TYPEDEF_ALL_CT(__name, __name``_req_t, __name``_resp_t, __addr_t, __data_t, __strb_t)
////////////////////////////////////////////////////////////////////////////////////////////////////

`endif
// ---- end inlined ----
module dw_downsizer #(
    parameter int unsigned ADDR_W     = 32,
    parameter int unsigned ID_W       = 4,
    parameter int unsigned SLV_DATA_W = 64,   // upstream, wide
    parameter int unsigned MST_DATA_W = 16,   // downstream, narrow
    parameter int unsigned MAX_READS  = 4
) (
    input  logic clk_i,
    input  logic rst_ni,

    // ---- slave (upstream, WIDE) port ----
    input  logic [ID_W-1:0]          s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic [2:0]               s_awsize,
    input  logic [1:0]               s_awburst,
    input  logic                     s_awvalid,
    output logic                     s_awready,
    input  logic [SLV_DATA_W-1:0]    s_wdata,
    input  logic [SLV_DATA_W/8-1:0]  s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,
    output logic [ID_W-1:0]          s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,
    input  logic [ID_W-1:0]          s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic [2:0]               s_arsize,
    input  logic [1:0]               s_arburst,
    input  logic                     s_arvalid,
    output logic                     s_arready,
    output logic [ID_W-1:0]          s_rid,
    output logic [SLV_DATA_W-1:0]    s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,

    // ---- master (downstream, NARROW) port ----
    output logic [ID_W-1:0]          m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic [2:0]               m_awsize,
    output logic [1:0]               m_awburst,
    output logic                     m_awvalid,
    input  logic                     m_awready,
    output logic [MST_DATA_W-1:0]    m_wdata,
    output logic [MST_DATA_W/8-1:0]  m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,
    input  logic [ID_W-1:0]          m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,
    output logic [ID_W-1:0]          m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic [2:0]               m_arsize,
    output logic [1:0]               m_arburst,
    output logic                     m_arvalid,
    input  logic                     m_arready,
    input  logic [ID_W-1:0]          m_rid,
    input  logic [MST_DATA_W-1:0]    m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  typedef logic [ADDR_W-1:0]        addr_t;
  typedef logic [ID_W-1:0]          id_t;
  typedef logic [SLV_DATA_W-1:0]    sdata_t;
  typedef logic [SLV_DATA_W/8-1:0]  sstrb_t;
  typedef logic [MST_DATA_W-1:0]    mdata_t;
  typedef logic [MST_DATA_W/8-1:0]  mstrb_t;
  typedef logic [0:0]               user_t;

  `AXI_TYPEDEF_ALL(slv, addr_t, id_t, sdata_t, sstrb_t, user_t)
  `AXI_TYPEDEF_ALL(mst, addr_t, id_t, mdata_t, mstrb_t, user_t)

  slv_req_t  slv_req;  slv_resp_t slv_resp;
  mst_req_t  mst_req;  mst_resp_t mst_resp;

  // ---- slave port in ----
  always_comb begin
    slv_req = '0;
    slv_req.aw.id    = s_awid;    slv_req.aw.addr  = s_awaddr;
    slv_req.aw.len   = s_awlen;   slv_req.aw.size  = s_awsize;
    slv_req.aw.burst = s_awburst; slv_req.aw_valid = s_awvalid;
    slv_req.w.data   = s_wdata;   slv_req.w.strb   = s_wstrb;
    slv_req.w.last   = s_wlast;   slv_req.w_valid  = s_wvalid;
    slv_req.b_ready  = s_bready;
    slv_req.ar.id    = s_arid;    slv_req.ar.addr  = s_araddr;
    slv_req.ar.len   = s_arlen;   slv_req.ar.size  = s_arsize;
    slv_req.ar.burst = s_arburst; slv_req.ar_valid = s_arvalid;
    slv_req.r_ready  = s_rready;
  end
  assign s_awready = slv_resp.aw_ready;
  assign s_wready  = slv_resp.w_ready;
  assign s_bid     = slv_resp.b.id;
  assign s_bresp   = slv_resp.b.resp;
  assign s_bvalid  = slv_resp.b_valid;
  assign s_arready = slv_resp.ar_ready;
  assign s_rid     = slv_resp.r.id;
  assign s_rdata   = slv_resp.r.data;
  assign s_rresp   = slv_resp.r.resp;
  assign s_rlast   = slv_resp.r.last;
  assign s_rvalid  = slv_resp.r_valid;

  // ---- master port out ----
  assign m_awid    = mst_req.aw.id;
  assign m_awaddr  = mst_req.aw.addr;
  assign m_awlen   = mst_req.aw.len;
  assign m_awsize  = mst_req.aw.size;
  assign m_awburst = mst_req.aw.burst;
  assign m_awvalid = mst_req.aw_valid;
  assign m_wdata   = mst_req.w.data;
  assign m_wstrb   = mst_req.w.strb;
  assign m_wlast   = mst_req.w.last;
  assign m_wvalid  = mst_req.w_valid;
  assign m_bready  = mst_req.b_ready;
  assign m_arid    = mst_req.ar.id;
  assign m_araddr  = mst_req.ar.addr;
  assign m_arlen   = mst_req.ar.len;
  assign m_arsize  = mst_req.ar.size;
  assign m_arburst = mst_req.ar.burst;
  assign m_arvalid = mst_req.ar_valid;
  assign m_rready  = mst_req.r_ready;
  always_comb begin
    mst_resp = '0;
    mst_resp.aw_ready = m_awready;
    mst_resp.w_ready  = m_wready;
    mst_resp.b.id     = m_bid;   mst_resp.b.resp = m_bresp;
    mst_resp.b_valid  = m_bvalid;
    mst_resp.ar_ready = m_arready;
    mst_resp.r.id     = m_rid;   mst_resp.r.data = m_rdata;
    mst_resp.r.resp   = m_rresp; mst_resp.r.last = m_rlast;
    mst_resp.r_valid  = m_rvalid;
  end

  axi_dw_downsizer #(
    .AxiMaxReads         (MAX_READS),
    .AxiSlvPortDataWidth (SLV_DATA_W),
    .AxiMstPortDataWidth (MST_DATA_W),
    .AxiAddrWidth        (ADDR_W),
    .AxiIdWidth          (ID_W),
    .aw_chan_t           (slv_aw_chan_t),
    .mst_w_chan_t        (mst_w_chan_t),
    .slv_w_chan_t        (slv_w_chan_t),
    .b_chan_t            (slv_b_chan_t),
    .ar_chan_t           (slv_ar_chan_t),
    .mst_r_chan_t        (mst_r_chan_t),
    .slv_r_chan_t        (slv_r_chan_t),
    .axi_mst_req_t       (mst_req_t),
    .axi_mst_resp_t      (mst_resp_t),
    .axi_slv_req_t       (slv_req_t),
    .axi_slv_resp_t      (slv_resp_t)
  ) i_dw (
    .clk_i, .rst_ni,
    .slv_req_i  (slv_req),
    .slv_resp_o (slv_resp),
    .mst_req_o  (mst_req),
    .mst_resp_i (mst_resp)
  );
endmodule
