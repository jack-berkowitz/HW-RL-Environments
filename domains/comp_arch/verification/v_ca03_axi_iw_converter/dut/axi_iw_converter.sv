// Copyright (c) 2014-2020 ETH Zurich, University of Bologna
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
// - Wolfgang Roenninger <wroennin@iis.ee.ethz.ch>

// ---- INLINED axi/typedef.svh (harness passes no -I; see task.yaml) ----
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
// ---- end inlined axi/typedef.svh ----

/// Convert between any two AXI ID widths.
///
/// Any combination of slave and master port ID width is valid.  When the master port ID width is
/// larger than or equal to the slave port ID width, slave port IDs are simply prepended with zeros
/// to the width of master port IDs.  For *reducing* the ID width, i.e., when the master port ID
/// width is smaller than the slave port ID width, there are two options.
///
/// ## Options for reducing the ID width
///
/// The two options for reducing ID widths differ in the maximum number of different IDs that can be
/// in flight at the slave port of this module, given in the `AxiSlvPortMaxUniqIds` parameter.
///
/// ### Fewer unique slave port IDs than master port IDs
///
/// If `AxiSlvPortMaxUniqIds <= 2**AxiMstPortIdWidth`, there are fewer unique slave port IDs than
/// master port IDs.  Therefore, IDs that are different at the slave port of this module can remain
/// different at the reduced-ID-width master port and thus remain *independently reorderable*.
/// Since the IDs are master port are nonetheless shorter than at the slave port, they need to be
/// *remapped*.  An instance of [`axi_id_remap`](module.axi_id_remap) handles this case.
///
/// ### More unique slave port IDs than master port IDs
///
/// If `AxiSlvPortMaxUniqIds > 2**AxiMstPortIdWidth`, there are more unique slave port IDs than
/// master port IDs.  Therefore, some IDs that are different at the slave port need to be assigned
/// to the same master port ID and thus become ordered with respect to each other.  An instance of
/// [`axi_id_serialize`](module.axi_id_serialize) handles this case.
module axi_iw_converter #(
  /// ID width of the AXI4+ATOP slave port
  parameter int unsigned AxiSlvPortIdWidth = 32'd0,
  /// ID width of the AXI4+ATOP master port
  parameter int unsigned AxiMstPortIdWidth = 32'd0,
  /// Maximum number of different IDs that can be in flight at the slave port.  Reads and writes are
  /// counted separately (except for ATOPs, which count as both read and write).
  ///
  /// It is legal for upstream to have transactions with more unique IDs than the maximum given by
  /// this parameter in flight, but a transaction exceeding the maximum will be stalled until all
  /// transactions of another ID complete.
  parameter int unsigned AxiSlvPortMaxUniqIds = 32'd0,
  /// Maximum number of in-flight transactions with the same ID at the slave port.
  ///
  /// This parameter is only relevant if `AxiSlvPortMaxUniqIds <= 2**AxiMstPortIdWidth`.  In that
  /// case, this parameter is passed to [`axi_id_remap` as `AxiMaxTxnsPerId`
  /// parameter](module.axi_id_remap#parameter.AxiMaxTxnsPerId).
  parameter int unsigned AxiSlvPortMaxTxnsPerId = 32'd0,
  /// Maximum number of in-flight transactions at the slave port.  Reads and writes are counted
  /// separately (except for ATOPs, which count as both read and write).
  ///
  /// This parameter is only relevant if `AxiSlvPortMaxUniqIds > 2**AxiMstPortIdWidth`.  In that
  /// case, this parameter is passed to
  /// [`axi_id_serialize`](module.axi_id_serialize#parameter.AxiSlvPortMaxTxns).
  parameter int unsigned AxiSlvPortMaxTxns = 32'd0,
  /// Maximum number of different IDs that can be in flight at the master port.  Reads and writes
  /// are counted separately (except for ATOPs, which count as both read and write).
  ///
  /// This parameter is only relevant if `AxiSlvPortMaxUniqIds > 2**AxiMstPortIdWidth`.  In that
  /// case, this parameter is passed to
  /// [`axi_id_serialize`](module.axi_id_serialize#parameter.AxiMstPortMaxUniqIds).
  parameter int unsigned AxiMstPortMaxUniqIds = 32'd0,
  /// Maximum number of in-flight transactions with the same ID at the master port.
  ///
  /// This parameter is only relevant if `AxiSlvPortMaxUniqIds > 2**AxiMstPortIdWidth`.  In that
  /// case, this parameter is passed to
  /// [`axi_id_serialize`](module.axi_id_serialize#parameter.AxiMstPortMaxTxnsPerId).
  parameter int unsigned AxiMstPortMaxTxnsPerId = 32'd0,
  /// Address width of both AXI4+ATOP ports
  parameter int unsigned AxiAddrWidth = 32'd0,
  /// Data width of both AXI4+ATOP ports
  parameter int unsigned AxiDataWidth = 32'd0,
  /// User signal width of both AXI4+ATOP ports
  parameter int unsigned AxiUserWidth = 32'd0,
  /// Request struct type of the AXI4+ATOP slave port
  parameter type slv_req_t = logic,
  /// Response struct type of the AXI4+ATOP slave port
  parameter type slv_resp_t = logic,
  /// Request struct type of the AXI4+ATOP master port
  parameter type mst_req_t = logic,
  /// Response struct type of the AXI4+ATOP master port
  parameter type mst_resp_t = logic
) (
  /// Rising-edge clock of both ports
  input  logic      clk_i,
  /// Asynchronous reset, active low
  input  logic      rst_ni,
  /// Slave port request
  input  slv_req_t  slv_req_i,
  /// Slave port response
  output slv_resp_t slv_resp_o,
  /// Master port request
  output mst_req_t  mst_req_o,
  /// Master port response
  input  mst_resp_t mst_resp_i
);

  typedef logic [AxiAddrWidth-1:0]      addr_t;
  typedef logic [AxiDataWidth-1:0]      data_t;
  typedef logic [AxiSlvPortIdWidth-1:0] slv_id_t;
  typedef logic [AxiMstPortIdWidth-1:0] mst_id_t;
  typedef logic [AxiDataWidth/8-1:0]    strb_t;
  typedef logic [AxiUserWidth-1:0]      user_t;
  `AXI_TYPEDEF_AW_CHAN_T(slv_aw_t, addr_t, slv_id_t, user_t)
  `AXI_TYPEDEF_AW_CHAN_T(mst_aw_t, addr_t, mst_id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(w_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(slv_b_t, slv_id_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(mst_b_t, mst_id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(slv_ar_t, addr_t, slv_id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(mst_ar_t, addr_t, mst_id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(slv_r_t, data_t, slv_id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(mst_r_t, data_t, mst_id_t, user_t)

  if (AxiMstPortIdWidth < AxiSlvPortIdWidth) begin : gen_downsize
    if (AxiSlvPortMaxUniqIds <= 2**AxiMstPortIdWidth) begin : gen_remap
      axi_id_remap #(
        .AxiSlvPortIdWidth    ( AxiSlvPortIdWidth       ),
        .AxiMstPortIdWidth    ( AxiMstPortIdWidth       ),
        .AxiSlvPortMaxUniqIds ( AxiSlvPortMaxUniqIds    ),
        .AxiMaxTxnsPerId      ( AxiSlvPortMaxTxnsPerId  ),
        .slv_req_t            ( slv_req_t               ),
        .slv_resp_t           ( slv_resp_t              ),
        .mst_req_t            ( mst_req_t               ),
        .mst_resp_t           ( mst_resp_t              )
      ) i_axi_id_remap (
        .clk_i,
        .rst_ni,
        .slv_req_i  ( slv_req_i  ),
        .slv_resp_o ( slv_resp_o ),
        .mst_req_o  ( mst_req_o  ),
        .mst_resp_i ( mst_resp_i )
      );
    end else begin : gen_serialize
      axi_id_serialize #(
        .AxiSlvPortIdWidth      ( AxiSlvPortIdWidth       ),
        .AxiSlvPortMaxTxns      ( AxiSlvPortMaxTxns       ),
        .AxiMstPortIdWidth      ( AxiMstPortIdWidth       ),
        .AxiMstPortMaxUniqIds   ( AxiMstPortMaxUniqIds    ),
        .AxiMstPortMaxTxnsPerId ( AxiMstPortMaxTxnsPerId  ),
        .AxiAddrWidth           ( AxiAddrWidth            ),
        .AxiDataWidth           ( AxiDataWidth            ),
        .AxiUserWidth           ( AxiUserWidth            ),
        .slv_req_t              ( slv_req_t               ),
        .slv_resp_t             ( slv_resp_t              ),
        .mst_req_t              ( mst_req_t               ),
        .mst_resp_t             ( mst_resp_t              )
      ) i_axi_id_serialize (
        .clk_i,
        .rst_ni,
        .slv_req_i  ( slv_req_i  ),
        .slv_resp_o ( slv_resp_o ),
        .mst_req_o  ( mst_req_o  ),
        .mst_resp_i ( mst_resp_i )
      );
      end
  end else if (AxiMstPortIdWidth > AxiSlvPortIdWidth) begin : gen_upsize
    axi_id_prepend #(
      .NoBus             ( 32'd1              ),
      .AxiIdWidthSlvPort ( AxiSlvPortIdWidth  ),
      .AxiIdWidthMstPort ( AxiMstPortIdWidth  ),
      .slv_aw_chan_t     ( slv_aw_t           ),
      .slv_w_chan_t      ( w_t                ),
      .slv_b_chan_t      ( slv_b_t            ),
      .slv_ar_chan_t     ( slv_ar_t           ),
      .slv_r_chan_t      ( slv_r_t            ),
      .mst_aw_chan_t     ( mst_aw_t           ),
      .mst_w_chan_t      ( w_t                ),
      .mst_b_chan_t      ( mst_b_t            ),
      .mst_ar_chan_t     ( mst_ar_t           ),
      .mst_r_chan_t      ( mst_r_t            )
    ) i_axi_id_prepend (
      .pre_id_i         ( '0                  ),
      .slv_aw_chans_i   ( slv_req_i.aw        ),
      .slv_aw_valids_i  ( slv_req_i.aw_valid  ),
      .slv_aw_readies_o ( slv_resp_o.aw_ready ),
      .slv_w_chans_i    ( slv_req_i.w         ),
      .slv_w_valids_i   ( slv_req_i.w_valid   ),
      .slv_w_readies_o  ( slv_resp_o.w_ready  ),
      .slv_b_chans_o    ( slv_resp_o.b        ),
      .slv_b_valids_o   ( slv_resp_o.b_valid  ),
      .slv_b_readies_i  ( slv_req_i.b_ready   ),
      .slv_ar_chans_i   ( slv_req_i.ar        ),
      .slv_ar_valids_i  ( slv_req_i.ar_valid  ),
      .slv_ar_readies_o ( slv_resp_o.ar_ready ),
      .slv_r_chans_o    ( slv_resp_o.r        ),
      .slv_r_valids_o   ( slv_resp_o.r_valid  ),
      .slv_r_readies_i  ( slv_req_i.r_ready   ),
      .mst_aw_chans_o   ( mst_req_o.aw        ),
      .mst_aw_valids_o  ( mst_req_o.aw_valid  ),
      .mst_aw_readies_i ( mst_resp_i.aw_ready ),
      .mst_w_chans_o    ( mst_req_o.w         ),
      .mst_w_valids_o   ( mst_req_o.w_valid   ),
      .mst_w_readies_i  ( mst_resp_i.w_ready  ),
      .mst_b_chans_i    ( mst_resp_i.b        ),
      .mst_b_valids_i   ( mst_resp_i.b_valid  ),
      .mst_b_readies_o  ( mst_req_o.b_ready   ),
      .mst_ar_chans_o   ( mst_req_o.ar        ),
      .mst_ar_valids_o  ( mst_req_o.ar_valid  ),
      .mst_ar_readies_i ( mst_resp_i.ar_ready ),
      .mst_r_chans_i    ( mst_resp_i.r        ),
      .mst_r_valids_i   ( mst_resp_i.r_valid  ),
      .mst_r_readies_o  ( mst_req_o.r_ready   )
    );
  end else begin : gen_passthrough
    assign mst_req_o  = slv_req_i;
    assign slv_resp_o = mst_resp_i;
  end

  // pragma translate_off
  `ifndef VERILATOR
  initial begin : p_assert
    assert(AxiAddrWidth > 32'd0)
      else $fatal(1, "Parameter AxiAddrWidth has to be larger than 0!");
    assert(AxiDataWidth > 32'd0)
      else $fatal(1, "Parameter AxiDataWidth has to be larger than 0!");
    assert(AxiUserWidth > 32'd0)
      else $fatal(1, "Parameter AxiUserWidth has to be larger than 0!");
    assert(AxiSlvPortIdWidth > 32'd0)
      else $fatal(1, "Parameter AxiSlvPortIdWidth has to be larger than 0!");
    assert(AxiMstPortIdWidth > 32'd0)
      else $fatal(1, "Parameter AxiMstPortIdWidth has to be larger than 0!");
    if (AxiSlvPortMaxUniqIds <= 2**AxiMstPortIdWidth) begin
      assert(AxiSlvPortMaxTxnsPerId > 32'd0)
        else $fatal(1, "Parameter AxiSlvPortMaxTxnsPerId has to be larger than 0!");
    end else begin
      assert(AxiMstPortMaxUniqIds > 32'd0)
        else $fatal(1, "Parameter AxiMstPortMaxUniqIds has to be larger than 0!");
      assert(AxiMstPortMaxTxnsPerId > 32'd0)
        else $fatal(1, "Parameter AxiMstPortMaxTxnsPerId has to be larger than 0!");
    end
    assert($bits(slv_req_i.aw.addr) == $bits(mst_req_o.aw.addr))
      else $fatal(1, "AXI AW address widths are not equal!");
    assert($bits(slv_req_i.w.data) == $bits(mst_req_o.w.data))
      else $fatal(1, "AXI W data widths are not equal!");
    assert($bits(slv_req_i.ar.addr) == $bits(mst_req_o.ar.addr))
      else $fatal(1, "AXI AR address widths are not equal!");
    assert($bits(slv_resp_o.r.data) == $bits(mst_resp_i.r.data))
      else $fatal(1, "AXI R data widths are not equal!");
  end
  `endif
  // pragma translate_on
endmodule


// ---- INLINED axi/assign.svh (harness passes no -I; see task.yaml) ----
// Copyright (c) 2014-2018 ETH Zurich, University of Bologna
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
// - Nils Wistoff <nwistoff@iis.ee.ethz.ch>

// Macros to assign AXI Interfaces and Structs

`ifndef AXI_ASSIGN_SVH_
`define AXI_ASSIGN_SVH_

////////////////////////////////////////////////////////////////////////////////////////////////////
// Internal implementation for assigning one AXI struct or interface to another struct or interface.
// The path to the signals on each side is defined by the `__sep*` arguments.  The `__opt_as`
// argument allows to use this standalone (with `__opt_as = assign`) or in assignments inside
// processes (with `__opt_as` void).
`define __AXI_TO_AW(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)   \
  __opt_as __lhs``__lhs_sep``id     = __rhs``__rhs_sep``id;         \
  __opt_as __lhs``__lhs_sep``addr   = __rhs``__rhs_sep``addr;       \
  __opt_as __lhs``__lhs_sep``len    = __rhs``__rhs_sep``len;        \
  __opt_as __lhs``__lhs_sep``size   = __rhs``__rhs_sep``size;       \
  __opt_as __lhs``__lhs_sep``burst  = __rhs``__rhs_sep``burst;      \
  __opt_as __lhs``__lhs_sep``lock   = __rhs``__rhs_sep``lock;       \
  __opt_as __lhs``__lhs_sep``cache  = __rhs``__rhs_sep``cache;      \
  __opt_as __lhs``__lhs_sep``prot   = __rhs``__rhs_sep``prot;       \
  __opt_as __lhs``__lhs_sep``qos    = __rhs``__rhs_sep``qos;        \
  __opt_as __lhs``__lhs_sep``region = __rhs``__rhs_sep``region;     \
  __opt_as __lhs``__lhs_sep``atop   = __rhs``__rhs_sep``atop;       \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_W(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)    \
  __opt_as __lhs``__lhs_sep``data   = __rhs``__rhs_sep``data;       \
  __opt_as __lhs``__lhs_sep``strb   = __rhs``__rhs_sep``strb;       \
  __opt_as __lhs``__lhs_sep``last   = __rhs``__rhs_sep``last;       \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_B(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)    \
  __opt_as __lhs``__lhs_sep``id     = __rhs``__rhs_sep``id;         \
  __opt_as __lhs``__lhs_sep``resp   = __rhs``__rhs_sep``resp;       \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_AR(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)   \
  __opt_as __lhs``__lhs_sep``id     = __rhs``__rhs_sep``id;         \
  __opt_as __lhs``__lhs_sep``addr   = __rhs``__rhs_sep``addr;       \
  __opt_as __lhs``__lhs_sep``len    = __rhs``__rhs_sep``len;        \
  __opt_as __lhs``__lhs_sep``size   = __rhs``__rhs_sep``size;       \
  __opt_as __lhs``__lhs_sep``burst  = __rhs``__rhs_sep``burst;      \
  __opt_as __lhs``__lhs_sep``lock   = __rhs``__rhs_sep``lock;       \
  __opt_as __lhs``__lhs_sep``cache  = __rhs``__rhs_sep``cache;      \
  __opt_as __lhs``__lhs_sep``prot   = __rhs``__rhs_sep``prot;       \
  __opt_as __lhs``__lhs_sep``qos    = __rhs``__rhs_sep``qos;        \
  __opt_as __lhs``__lhs_sep``region = __rhs``__rhs_sep``region;     \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_R(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)    \
  __opt_as __lhs``__lhs_sep``id     = __rhs``__rhs_sep``id;         \
  __opt_as __lhs``__lhs_sep``data   = __rhs``__rhs_sep``data;       \
  __opt_as __lhs``__lhs_sep``resp   = __rhs``__rhs_sep``resp;       \
  __opt_as __lhs``__lhs_sep``last   = __rhs``__rhs_sep``last;       \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_REQ(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)  \
  `__AXI_TO_AW(__opt_as, __lhs.aw, __lhs_sep, __rhs.aw, __rhs_sep)  \
  __opt_as __lhs.aw_valid = __rhs.aw_valid;                         \
  `__AXI_TO_W(__opt_as, __lhs.w, __lhs_sep, __rhs.w, __rhs_sep)     \
  __opt_as __lhs.w_valid = __rhs.w_valid;                           \
  __opt_as __lhs.b_ready = __rhs.b_ready;                           \
  `__AXI_TO_AR(__opt_as, __lhs.ar, __lhs_sep, __rhs.ar, __rhs_sep)  \
  __opt_as __lhs.ar_valid = __rhs.ar_valid;                         \
  __opt_as __lhs.r_ready = __rhs.r_ready;
`define __AXI_TO_RESP(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  __opt_as __lhs.aw_ready = __rhs.aw_ready;                         \
  __opt_as __lhs.ar_ready = __rhs.ar_ready;                         \
  __opt_as __lhs.w_ready = __rhs.w_ready;                           \
  __opt_as __lhs.b_valid = __rhs.b_valid;                           \
  `__AXI_TO_B(__opt_as, __lhs.b, __lhs_sep, __rhs.b, __rhs_sep)     \
  __opt_as __lhs.r_valid = __rhs.r_valid;                           \
  `__AXI_TO_R(__opt_as, __lhs.r, __lhs_sep, __rhs.r, __rhs_sep)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one AXI4+ATOP interface to another, as if you would do `assign slv = mst;`
//
// The channel assignments `AXI_ASSIGN_XX(dst, src)` assign all payload and the valid signal of the
// `XX` channel from the `src` to the `dst` interface and they assign the ready signal from the
// `src` to the `dst` interface.
// The interface assignment `AXI_ASSIGN(dst, src)` assigns all channels including handshakes as if
// `src` was the master of `dst`.
//
// Usage Example:
// `AXI_ASSIGN(slv, mst)
// `AXI_ASSIGN_AW(dst, src)
// `AXI_ASSIGN_R(dst, src)
`define AXI_ASSIGN_AW(dst, src)               \
  `__AXI_TO_AW(assign, dst.aw, _, src.aw, _)  \
  assign dst.aw_valid = src.aw_valid;         \
  assign src.aw_ready = dst.aw_ready;
`define AXI_ASSIGN_W(dst, src)                \
  `__AXI_TO_W(assign, dst.w, _, src.w, _)     \
  assign dst.w_valid  = src.w_valid;          \
  assign src.w_ready  = dst.w_ready;
`define AXI_ASSIGN_B(dst, src)                \
  `__AXI_TO_B(assign, dst.b, _, src.b, _)     \
  assign dst.b_valid  = src.b_valid;          \
  assign src.b_ready  = dst.b_ready;
`define AXI_ASSIGN_AR(dst, src)               \
  `__AXI_TO_AR(assign, dst.ar, _, src.ar, _)  \
  assign dst.ar_valid = src.ar_valid;         \
  assign src.ar_ready = dst.ar_ready;
`define AXI_ASSIGN_R(dst, src)                \
  `__AXI_TO_R(assign, dst.r, _, src.r, _)     \
  assign dst.r_valid  = src.r_valid;          \
  assign src.r_ready  = dst.r_ready;
`define AXI_ASSIGN(slv, mst)  \
  `AXI_ASSIGN_AW(slv, mst)    \
  `AXI_ASSIGN_W(slv, mst)     \
  `AXI_ASSIGN_B(mst, slv)     \
  `AXI_ASSIGN_AR(slv, mst)    \
  `AXI_ASSIGN_R(mst, slv)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning a AXI4+ATOP interface to a monitor modport, as if you would do `assign mon = axi_if;`
//
// The channel assignment `AXI_ASSIGN_MONITOR(mon_dv, axi_if)` assigns all signals from `axi_if`
// to the `mon_dv` interface.
//
// Usage Example:
// `AXI_ASSIGN_MONITOR(mon_dv, axi_if)
`define AXI_ASSIGN_MONITOR(mon_dv, axi_if)          \
  `__AXI_TO_AW(assign, mon_dv.aw, _, axi_if.aw, _)  \
  assign mon_dv.aw_valid  = axi_if.aw_valid;        \
  assign mon_dv.aw_ready  = axi_if.aw_ready;        \
  `__AXI_TO_W(assign, mon_dv.w, _, axi_if.w, _)     \
  assign mon_dv.w_valid   = axi_if.w_valid;         \
  assign mon_dv.w_ready   = axi_if.w_ready;         \
  `__AXI_TO_B(assign, mon_dv.b, _, axi_if.b, _)     \
  assign mon_dv.b_valid   = axi_if.b_valid;         \
  assign mon_dv.b_ready   = axi_if.b_ready;         \
  `__AXI_TO_AR(assign, mon_dv.ar, _, axi_if.ar, _)  \
  assign mon_dv.ar_valid  = axi_if.ar_valid;        \
  assign mon_dv.ar_ready  = axi_if.ar_ready;        \
  `__AXI_TO_R(assign, mon_dv.r, _, axi_if.r, _)     \
  assign mon_dv.r_valid   = axi_if.r_valid;         \
  assign mon_dv.r_ready   = axi_if.r_ready;
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting an interface from channel or request/response structs inside a process.
//
// The channel macros `AXI_SET_FROM_XX(axi_if, xx_struct)` set the payload signals of the `axi_if`
// interface from the signals in `xx_struct`.  They do not set the handshake signals.
// The request macro `AXI_SET_FROM_REQ(axi_if, req_struct)` sets all request channels (AW, W, AR)
// and the request-side handshake signals (AW, W, and AR valid and B and R ready) of the `axi_if`
// interface from the signals in `req_struct`.
// The response macro `AXI_SET_FROM_RESP(axi_if, resp_struct)` sets both response channels (B and R)
// and the response-side handshake signals (B and R valid and AW, W, and AR ready) of the `axi_if`
// interface from the signals in `resp_struct`.
//
// Usage Example:
// always_comb begin
//   `AXI_SET_FROM_REQ(my_if, my_req_struct)
// end
`define AXI_SET_FROM_AW(axi_if, aw_struct)      `__AXI_TO_AW(, axi_if.aw, _, aw_struct, .)
`define AXI_SET_FROM_W(axi_if, w_struct)        `__AXI_TO_W(, axi_if.w, _, w_struct, .)
`define AXI_SET_FROM_B(axi_if, b_struct)        `__AXI_TO_B(, axi_if.b, _, b_struct, .)
`define AXI_SET_FROM_AR(axi_if, ar_struct)      `__AXI_TO_AR(, axi_if.ar, _, ar_struct, .)
`define AXI_SET_FROM_R(axi_if, r_struct)        `__AXI_TO_R(, axi_if.r, _, r_struct, .)
`define AXI_SET_FROM_REQ(axi_if, req_struct)    `__AXI_TO_REQ(, axi_if, _, req_struct, .)
`define AXI_SET_FROM_RESP(axi_if, resp_struct)  `__AXI_TO_RESP(, axi_if, _, resp_struct, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning an interface from channel or request/response structs outside a process.
//
// The channel macros `AXI_ASSIGN_FROM_XX(axi_if, xx_struct)` assign the payload signals of the
// `axi_if` interface from the signals in `xx_struct`.  They do not assign the handshake signals.
// The request macro `AXI_ASSIGN_FROM_REQ(axi_if, req_struct)` assigns all request channels (AW, W,
// AR) and the request-side handshake signals (AW, W, and AR valid and B and R ready) of the
// `axi_if` interface from the signals in `req_struct`.
// The response macro `AXI_ASSIGN_FROM_RESP(axi_if, resp_struct)` assigns both response channels (B
// and R) and the response-side handshake signals (B and R valid and AW, W, and AR ready) of the
// `axi_if` interface from the signals in `resp_struct`.
//
// Usage Example:
// `AXI_ASSIGN_FROM_REQ(my_if, my_req_struct)
`define AXI_ASSIGN_FROM_AW(axi_if, aw_struct)     `__AXI_TO_AW(assign, axi_if.aw, _, aw_struct, .)
`define AXI_ASSIGN_FROM_W(axi_if, w_struct)       `__AXI_TO_W(assign, axi_if.w, _, w_struct, .)
`define AXI_ASSIGN_FROM_B(axi_if, b_struct)       `__AXI_TO_B(assign, axi_if.b, _, b_struct, .)
`define AXI_ASSIGN_FROM_AR(axi_if, ar_struct)     `__AXI_TO_AR(assign, axi_if.ar, _, ar_struct, .)
`define AXI_ASSIGN_FROM_R(axi_if, r_struct)       `__AXI_TO_R(assign, axi_if.r, _, r_struct, .)
`define AXI_ASSIGN_FROM_REQ(axi_if, req_struct)   `__AXI_TO_REQ(assign, axi_if, _, req_struct, .)
`define AXI_ASSIGN_FROM_RESP(axi_if, resp_struct) `__AXI_TO_RESP(assign, axi_if, _, resp_struct, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from an interface inside a process.
//
// The channel macros `AXI_SET_TO_XX(xx_struct, axi_if)` set the signals of `xx_struct` to the
// payload signals of that channel in the `axi_if` interface.  They do not set the handshake
// signals.
// The request macro `AXI_SET_TO_REQ(axi_if, req_struct)` sets all signals of `req_struct` (i.e.,
// request channel (AW, W, AR) payload and request-side handshake signals (AW, W, and AR valid and
// B and R ready)) to the signals in the `axi_if` interface.
// The response macro `AXI_SET_TO_RESP(axi_if, resp_struct)` sets all signals of `resp_struct`
// (i.e., response channel (B and R) payload and response-side handshake signals (B and R valid and
// AW, W, and AR ready)) to the signals in the `axi_if` interface.
//
// Usage Example:
// always_comb begin
//   `AXI_SET_TO_REQ(my_req_struct, my_if)
// end
`define AXI_SET_TO_AW(aw_struct, axi_if)     `__AXI_TO_AW(, aw_struct, ., axi_if.aw, _)
`define AXI_SET_TO_W(w_struct, axi_if)       `__AXI_TO_W(, w_struct, ., axi_if.w, _)
`define AXI_SET_TO_B(b_struct, axi_if)       `__AXI_TO_B(, b_struct, ., axi_if.b, _)
`define AXI_SET_TO_AR(ar_struct, axi_if)     `__AXI_TO_AR(, ar_struct, ., axi_if.ar, _)
`define AXI_SET_TO_R(r_struct, axi_if)       `__AXI_TO_R(, r_struct, ., axi_if.r, _)
`define AXI_SET_TO_REQ(req_struct, axi_if)   `__AXI_TO_REQ(, req_struct, ., axi_if, _)
`define AXI_SET_TO_RESP(resp_struct, axi_if) `__AXI_TO_RESP(, resp_struct, ., axi_if, _)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a process.
//
// The channel macros `AXI_ASSIGN_TO_XX(xx_struct, axi_if)` assign the signals of `xx_struct` to the
// payload signals of that channel in the `axi_if` interface.  They do not assign the handshake
// signals.
// The request macro `AXI_ASSIGN_TO_REQ(axi_if, req_struct)` assigns all signals of `req_struct`
// (i.e., request channel (AW, W, AR) payload and request-side handshake signals (AW, W, and AR
// valid and B and R ready)) to the signals in the `axi_if` interface.
// The response macro `AXI_ASSIGN_TO_RESP(axi_if, resp_struct)` assigns all signals of `resp_struct`
// (i.e., response channel (B and R) payload and response-side handshake signals (B and R valid and
// AW, W, and AR ready)) to the signals in the `axi_if` interface.
//
// Usage Example:
// `AXI_ASSIGN_TO_REQ(my_req_struct, my_if)
`define AXI_ASSIGN_TO_AW(aw_struct, axi_if)     `__AXI_TO_AW(assign, aw_struct, ., axi_if.aw, _)
`define AXI_ASSIGN_TO_W(w_struct, axi_if)       `__AXI_TO_W(assign, w_struct, ., axi_if.w, _)
`define AXI_ASSIGN_TO_B(b_struct, axi_if)       `__AXI_TO_B(assign, b_struct, ., axi_if.b, _)
`define AXI_ASSIGN_TO_AR(ar_struct, axi_if)     `__AXI_TO_AR(assign, ar_struct, ., axi_if.ar, _)
`define AXI_ASSIGN_TO_R(r_struct, axi_if)       `__AXI_TO_R(assign, r_struct, ., axi_if.r, _)
`define AXI_ASSIGN_TO_REQ(req_struct, axi_if)   `__AXI_TO_REQ(assign, req_struct, ., axi_if, _)
`define AXI_ASSIGN_TO_RESP(resp_struct, axi_if) `__AXI_TO_RESP(assign, resp_struct, ., axi_if, _)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from another struct inside a process.
//
// The channel macros `AXI_SET_XX_STRUCT(lhs, rhs)` set the fields of the `lhs` channel struct to
// the fields of the `rhs` channel struct.  They do not set the handshake signals, which are not
// part of channel structs.
// The request macro `AXI_SET_REQ_STRUCT(lhs, rhs)` sets all fields of the `lhs` request struct to
// the fields of the `rhs` request struct.  This includes all request channel (AW, W, AR) payload
// and request-side handshake signals (AW, W, and AR valid and B and R ready).
// The response macro `AXI_SET_RESP_STRUCT(lhs, rhs)` sets all fields of the `lhs` response struct
// to the fields of the `rhs` response struct.  This includes all response channel (B and R) payload
// and response-side handshake signals (B and R valid and AW, W, and R ready).
//
// Usage Example:
// always_comb begin
//   `AXI_SET_REQ_STRUCT(my_req_struct, another_req_struct)
// end
`define AXI_SET_AW_STRUCT(lhs, rhs)     `__AXI_TO_AW(, lhs, ., rhs, .)
`define AXI_SET_W_STRUCT(lhs, rhs)       `__AXI_TO_W(, lhs, ., rhs, .)
`define AXI_SET_B_STRUCT(lhs, rhs)       `__AXI_TO_B(, lhs, ., rhs, .)
`define AXI_SET_AR_STRUCT(lhs, rhs)     `__AXI_TO_AR(, lhs, ., rhs, .)
`define AXI_SET_R_STRUCT(lhs, rhs)       `__AXI_TO_R(, lhs, ., rhs, .)
`define AXI_SET_REQ_STRUCT(lhs, rhs)   `__AXI_TO_REQ(, lhs, ., rhs, .)
`define AXI_SET_RESP_STRUCT(lhs, rhs) `__AXI_TO_RESP(, lhs, ., rhs, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from another struct outside a process.
//
// The channel macros `AXI_ASSIGN_XX_STRUCT(lhs, rhs)` assign the fields of the `lhs` channel struct
// to the fields of the `rhs` channel struct.  They do not assign the handshake signals, which are
// not part of the channel structs.
// The request macro `AXI_ASSIGN_REQ_STRUCT(lhs, rhs)` assigns all fields of the `lhs` request
// struct to the fields of the `rhs` request struct.  This includes all request channel (AW, W, AR)
// payload and request-side handshake signals (AW, W, and AR valid and B and R ready).
// The response macro `AXI_ASSIGN_RESP_STRUCT(lhs, rhs)` assigns all fields of the `lhs` response
// struct to the fields of the `rhs` response struct.  This includes all response channel (B and R)
// payload and response-side handshake signals (B and R valid and AW, W, and R ready).
//
// Usage Example:
// `AXI_ASSIGN_REQ_STRUCT(my_req_struct, another_req_struct)
`define AXI_ASSIGN_AW_STRUCT(lhs, rhs)     `__AXI_TO_AW(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_W_STRUCT(lhs, rhs)       `__AXI_TO_W(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_B_STRUCT(lhs, rhs)       `__AXI_TO_B(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_AR_STRUCT(lhs, rhs)     `__AXI_TO_AR(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_R_STRUCT(lhs, rhs)       `__AXI_TO_R(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_REQ_STRUCT(lhs, rhs)   `__AXI_TO_REQ(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_RESP_STRUCT(lhs, rhs) `__AXI_TO_RESP(assign, lhs, ., rhs, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Internal implementation for assigning one Lite structs or interface to another struct or
// interface.  The path to the signals on each side is defined by the `__sep*` arguments.  The
// `__opt_as` argument allows to use this standalne (with `__opt_as = assign`) or in assignments
// inside processes (with `__opt_as` void).
`define __AXI_LITE_TO_AX(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)  \
  __opt_as __lhs``__lhs_sep``addr = __rhs``__rhs_sep``addr;             \
  __opt_as __lhs``__lhs_sep``prot = __rhs``__rhs_sep``prot;
`define __AXI_LITE_TO_W(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  __opt_as __lhs``__lhs_sep``data = __rhs``__rhs_sep``data;           \
  __opt_as __lhs``__lhs_sep``strb = __rhs``__rhs_sep``strb;
`define __AXI_LITE_TO_B(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  __opt_as __lhs``__lhs_sep``resp = __rhs``__rhs_sep``resp;
`define __AXI_LITE_TO_R(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  __opt_as __lhs``__lhs_sep``data = __rhs``__rhs_sep``data;           \
  __opt_as __lhs``__lhs_sep``resp = __rhs``__rhs_sep``resp;
`define __AXI_LITE_TO_REQ(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  `__AXI_LITE_TO_AX(__opt_as, __lhs.aw, __lhs_sep, __rhs.aw, __rhs_sep) \
  __opt_as __lhs.aw_valid = __rhs.aw_valid;                             \
  `__AXI_LITE_TO_W(__opt_as, __lhs.w, __lhs_sep, __rhs.w, __rhs_sep)    \
  __opt_as __lhs.w_valid = __rhs.w_valid;                               \
  __opt_as __lhs.b_ready = __rhs.b_ready;                               \
  `__AXI_LITE_TO_AX(__opt_as, __lhs.ar, __lhs_sep, __rhs.ar, __rhs_sep) \
  __opt_as __lhs.ar_valid = __rhs.ar_valid;                             \
  __opt_as __lhs.r_ready = __rhs.r_ready;
`define __AXI_LITE_TO_RESP(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)  \
  __opt_as __lhs.aw_ready = __rhs.aw_ready;                               \
  __opt_as __lhs.ar_ready = __rhs.ar_ready;                               \
  __opt_as __lhs.w_ready = __rhs.w_ready;                                 \
  __opt_as __lhs.b_valid = __rhs.b_valid;                                 \
  `__AXI_LITE_TO_B(__opt_as, __lhs.b, __lhs_sep, __rhs.b, __rhs_sep)      \
  __opt_as __lhs.r_valid = __rhs.r_valid;                                 \
  `__AXI_LITE_TO_R(__opt_as, __lhs.r, __lhs_sep, __rhs.r, __rhs_sep)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one AXI-Lite interface to another, as if you would do `assign slv = mst;`
//
// The channel assignments `AXI_LITE_ASSIGN_XX(dst, src)` assign all payload and the valid signal of
// the `XX` channel from the `src` to the `dst` interface and they assign the ready signal from the
// `src` to the `dst` interface.
// The interface assignment `AXI_LITE_ASSIGN(dst, src)` assigns all channels including handshakes as
// if `src` was the master of `dst`.
//
// Usage Example:
// `AXI_LITE_ASSIGN(slv, mst)
// `AXI_LITE_ASSIGN_AW(dst, src)
// `AXI_LITE_ASSIGN_R(dst, src)
`define AXI_LITE_ASSIGN_AW(dst, src)              \
  `__AXI_LITE_TO_AX(assign, dst.aw, _, src.aw, _) \
  assign dst.aw_valid = src.aw_valid;             \
  assign src.aw_ready = dst.aw_ready;
`define AXI_LITE_ASSIGN_W(dst, src)             \
  `__AXI_LITE_TO_W(assign, dst.w, _, src.w, _)  \
  assign dst.w_valid  = src.w_valid;            \
  assign src.w_ready  = dst.w_ready;
`define AXI_LITE_ASSIGN_B(dst, src)             \
  `__AXI_LITE_TO_B(assign, dst.b, _, src.b, _)  \
  assign dst.b_valid  = src.b_valid;            \
  assign src.b_ready  = dst.b_ready;
`define AXI_LITE_ASSIGN_AR(dst, src)              \
  `__AXI_LITE_TO_AX(assign, dst.ar, _, src.ar, _) \
  assign dst.ar_valid = src.ar_valid;             \
  assign src.ar_ready = dst.ar_ready;
`define AXI_LITE_ASSIGN_R(dst, src)             \
  `__AXI_LITE_TO_R(assign, dst.r, _, src.r, _)  \
  assign dst.r_valid  = src.r_valid;            \
  assign src.r_ready  = dst.r_ready;
`define AXI_LITE_ASSIGN(slv, mst) \
  `AXI_LITE_ASSIGN_AW(slv, mst)   \
  `AXI_LITE_ASSIGN_W(slv, mst)    \
  `AXI_LITE_ASSIGN_B(mst, slv)    \
  `AXI_LITE_ASSIGN_AR(slv, mst)   \
  `AXI_LITE_ASSIGN_R(mst, slv)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting a Lite interface from channel or request/response structs inside a process.
//
// The channel macros `AXI_LITE_SET_FROM_XX(axi_if, xx_struct)` set the payload signals of the
// `axi_if` interface from the signals in `xx_struct`.  They do not set the handshake signals.
// The request macro `AXI_LITE_SET_FROM_REQ(axi_if, req_struct)` sets all request channels (AW, W,
// AR) and the request-side handshake signals (AW, W, and AR valid and B and R ready) of the
// `axi_if` interface from the signals in `req_struct`.
// The response macro `AXI_LITE_SET_FROM_RESP(axi_if, resp_struct)` sets both response channels (B
// and R) and the response-side handshake signals (B and R valid and AW, W, and AR ready) of the
// `axi_if` interface from the signals in `resp_struct`.
//
// Usage Example:
// always_comb begin
//   `AXI_LITE_SET_FROM_REQ(my_if, my_req_struct)
// end
`define AXI_LITE_SET_FROM_AW(axi_if, aw_struct)      `__AXI_LITE_TO_AX(, axi_if.aw, _, aw_struct, .)
`define AXI_LITE_SET_FROM_W(axi_if, w_struct)        `__AXI_LITE_TO_W(, axi_if.w, _, w_struct, .)
`define AXI_LITE_SET_FROM_B(axi_if, b_struct)        `__AXI_LITE_TO_B(, axi_if.b, _, b_struct, .)
`define AXI_LITE_SET_FROM_AR(axi_if, ar_struct)      `__AXI_LITE_TO_AX(, axi_if.ar, _, ar_struct, .)
`define AXI_LITE_SET_FROM_R(axi_if, r_struct)        `__AXI_LITE_TO_R(, axi_if.r, _, r_struct, .)
`define AXI_LITE_SET_FROM_REQ(axi_if, req_struct)    `__AXI_LITE_TO_REQ(, axi_if, _, req_struct, .)
`define AXI_LITE_SET_FROM_RESP(axi_if, resp_struct)  `__AXI_LITE_TO_RESP(, axi_if, _, resp_struct, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning a Lite interface from channel or request/response structs outside a process.
//
// The channel macros `AXI_LITE_ASSIGN_FROM_XX(axi_if, xx_struct)` assign the payload signals of the
// `axi_if` interface from the signals in `xx_struct`.  They do not assign the handshake signals.
// The request macro `AXI_LITE_ASSIGN_FROM_REQ(axi_if, req_struct)` assigns all request channels
// (AW, W, AR) and the request-side handshake signals (AW, W, and AR valid and B and R ready) of the
// `axi_if` interface from the signals in `req_struct`.
// The response macro `AXI_LITE_ASSIGN_FROM_RESP(axi_if, resp_struct)` assigns both response
// channels (B and R) and the response-side handshake signals (B and R valid and AW, W, and AR
// ready) of the `axi_if` interface from the signals in `resp_struct`.
//
// Usage Example:
// `AXI_LITE_ASSIGN_FROM_REQ(my_if, my_req_struct)
`define AXI_LITE_ASSIGN_FROM_AW(axi_if, aw_struct)     `__AXI_LITE_TO_AX(assign, axi_if.aw, _, aw_struct, .)
`define AXI_LITE_ASSIGN_FROM_W(axi_if, w_struct)       `__AXI_LITE_TO_W(assign, axi_if.w, _, w_struct, .)
`define AXI_LITE_ASSIGN_FROM_B(axi_if, b_struct)       `__AXI_LITE_TO_B(assign, axi_if.b, _, b_struct, .)
`define AXI_LITE_ASSIGN_FROM_AR(axi_if, ar_struct)     `__AXI_LITE_TO_AX(assign, axi_if.ar, _, ar_struct, .)
`define AXI_LITE_ASSIGN_FROM_R(axi_if, r_struct)       `__AXI_LITE_TO_R(assign, axi_if.r, _, r_struct, .)
`define AXI_LITE_ASSIGN_FROM_REQ(axi_if, req_struct)   `__AXI_LITE_TO_REQ(assign, axi_if, _, req_struct, .)
`define AXI_LITE_ASSIGN_FROM_RESP(axi_if, resp_struct) `__AXI_LITE_TO_RESP(assign, axi_if, _, resp_struct, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from an interface inside a process.
//
// The channel macros `AXI_LITE_SET_TO_XX(xx_struct, axi_if)` set the signals of `xx_struct` to the
// payload signals of that channel in the `axi_if` interface.  They do not set the handshake
// signals.
// The request macro `AXI_LITE_SET_TO_REQ(axi_if, req_struct)` sets all signals of `req_struct`
// (i.e., request channel (AW, W, AR) payload and request-side handshake signals (AW, W, and AR
// valid and B and R ready)) to the signals in the `axi_if` interface.
// The response macro `AXI_LITE_SET_TO_RESP(axi_if, resp_struct)` sets all signals of `resp_struct`
// (i.e., response channel (B and R) payload and response-side handshake signals (B and R valid and
// AW, W, and AR ready)) to the signals in the `axi_if` interface.
//
// Usage Example:
// always_comb begin
//   `AXI_LITE_SET_TO_REQ(my_req_struct, my_if)
// end
`define AXI_LITE_SET_TO_AW(aw_struct, axi_if)     `__AXI_LITE_TO_AX(, aw_struct, ., axi_if.aw, _)
`define AXI_LITE_SET_TO_W(w_struct, axi_if)       `__AXI_LITE_TO_W(, w_struct, ., axi_if.w, _)
`define AXI_LITE_SET_TO_B(b_struct, axi_if)       `__AXI_LITE_TO_B(, b_struct, ., axi_if.b, _)
`define AXI_LITE_SET_TO_AR(ar_struct, axi_if)     `__AXI_LITE_TO_AX(, ar_struct, ., axi_if.ar, _)
`define AXI_LITE_SET_TO_R(r_struct, axi_if)       `__AXI_LITE_TO_R(, r_struct, ., axi_if.r, _)
`define AXI_LITE_SET_TO_REQ(req_struct, axi_if)   `__AXI_LITE_TO_REQ(, req_struct, ., axi_if, _)
`define AXI_LITE_SET_TO_RESP(resp_struct, axi_if) `__AXI_LITE_TO_RESP(, resp_struct, ., axi_if, _)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a process.
//
// The channel macros `AXI_LITE_ASSIGN_TO_XX(xx_struct, axi_if)` assign the signals of `xx_struct`
// to the payload signals of that channel in the `axi_if` interface.  They do not assign the
// handshake signals.
// The request macro `AXI_LITE_ASSIGN_TO_REQ(axi_if, req_struct)` assigns all signals of
// `req_struct` (i.e., request channel (AW, W, AR) payload and request-side handshake signals (AW,
// W, and AR valid and B and R ready)) to the signals in the `axi_if` interface.
// The response macro `AXI_LITE_ASSIGN_TO_RESP(axi_if, resp_struct)` assigns all signals of
// `resp_struct` (i.e., response channel (B and R) payload and response-side handshake signals (B
// and R valid and AW, W, and AR ready)) to the signals in the `axi_if` interface.
//
// Usage Example:
// `AXI_LITE_ASSIGN_TO_REQ(my_req_struct, my_if)
`define AXI_LITE_ASSIGN_TO_AW(aw_struct, axi_if)     `__AXI_LITE_TO_AX(assign, aw_struct, ., axi_if.aw, _)
`define AXI_LITE_ASSIGN_TO_W(w_struct, axi_if)       `__AXI_LITE_TO_W(assign, w_struct, ., axi_if.w, _)
`define AXI_LITE_ASSIGN_TO_B(b_struct, axi_if)       `__AXI_LITE_TO_B(assign, b_struct, ., axi_if.b, _)
`define AXI_LITE_ASSIGN_TO_AR(ar_struct, axi_if)     `__AXI_LITE_TO_AX(assign, ar_struct, ., axi_if.ar, _)
`define AXI_LITE_ASSIGN_TO_R(r_struct, axi_if)       `__AXI_LITE_TO_R(assign, r_struct, ., axi_if.r, _)
`define AXI_LITE_ASSIGN_TO_REQ(req_struct, axi_if)   `__AXI_LITE_TO_REQ(assign, req_struct, ., axi_if, _)
`define AXI_LITE_ASSIGN_TO_RESP(resp_struct, axi_if) `__AXI_LITE_TO_RESP(assign, resp_struct, ., axi_if, _)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from another struct inside a process.
//
// The channel macros `AXI_LITE_SET_XX_STRUCT(lhs, rhs)` set the fields of the `lhs` channel struct
// to the fields of the `rhs` channel struct.  They do not set the handshake signals, which are not
// part of channel structs.
// The request macro `AXI_LITE_SET_REQ_STRUCT(lhs, rhs)` sets all fields of the `lhs` request struct
// to the fields of the `rhs` request struct.  This includes all request channel (AW, W, AR) payload
// and request-side handshake signals (AW, W, and AR valid and B and R ready).
// The response macro `AXI_LITE_SET_RESP_STRUCT(lhs, rhs)` sets all fields of the `lhs` response
// struct to the fields of the `rhs` response struct.  This includes all response channel (B and R)
// payload and response-side handshake signals (B and R valid and AW, W, and R ready).
//
// Usage Example:
// always_comb begin
//   `AXI_LITE_SET_REQ_STRUCT(my_req_struct, another_req_struct)
// end
`define AXI_LITE_SET_AW_STRUCT(lhs, rhs)     `__AXI_LITE_TO_AX(, lhs, ., rhs, .)
`define AXI_LITE_SET_W_STRUCT(lhs, rhs)       `__AXI_LITE_TO_W(, lhs, ., rhs, .)
`define AXI_LITE_SET_B_STRUCT(lhs, rhs)       `__AXI_LITE_TO_B(, lhs, ., rhs, .)
`define AXI_LITE_SET_AR_STRUCT(lhs, rhs)     `__AXI_LITE_TO_AX(, lhs, ., rhs, .)
`define AXI_LITE_SET_R_STRUCT(lhs, rhs)       `__AXI_LITE_TO_R(, lhs, ., rhs, .)
`define AXI_LITE_SET_REQ_STRUCT(lhs, rhs)   `__AXI_LITE_TO_REQ(, lhs, ., rhs, .)
`define AXI_LITE_SET_RESP_STRUCT(lhs, rhs) `__AXI_LITE_TO_RESP(, lhs, ., rhs, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from another struct outside a process.
//
// The channel macros `AXI_LITE_ASSIGN_XX_STRUCT(lhs, rhs)` assign the fields of the `lhs` channel
// struct to the fields of the `rhs` channel struct.  They do not assign the handshake signals,
// which are not part of the channel structs.
// The request macro `AXI_LITE_ASSIGN_REQ_STRUCT(lhs, rhs)` assigns all fields of the `lhs` request
// struct to the fields of the `rhs` request struct.  This includes all request channel (AW, W, AR)
// payload and request-side handshake signals (AW, W, and AR valid and B and R ready).
// The response macro `AXI_LITE_ASSIGN_RESP_STRUCT(lhs, rhs)` assigns all fields of the `lhs`
// response struct to the fields of the `rhs` response struct.  This includes all response channel
// (B and R) payload and response-side handshake signals (B and R valid and AW, W, and R ready).
//
// Usage Example:
// `AXI_LITE_ASSIGN_REQ_STRUCT(my_req_struct, another_req_struct)
`define AXI_LITE_ASSIGN_AW_STRUCT(lhs, rhs)     `__AXI_LITE_TO_AX(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_W_STRUCT(lhs, rhs)       `__AXI_LITE_TO_W(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_B_STRUCT(lhs, rhs)       `__AXI_LITE_TO_B(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_AR_STRUCT(lhs, rhs)     `__AXI_LITE_TO_AX(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_R_STRUCT(lhs, rhs)       `__AXI_LITE_TO_R(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_REQ_STRUCT(lhs, rhs)   `__AXI_LITE_TO_REQ(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_RESP_STRUCT(lhs, rhs) `__AXI_LITE_TO_RESP(assign, lhs, ., rhs, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Macros for assigning flattened AXI ports to req/resp AXI structs
// Flat AXI ports are required by the Vivado IP Integrator. Vivado naming convention is followed.
//
// Usage Example:
// `AXI_ASSIGN_MASTER_TO_FLAT("my_bus", my_req_struct, my_rsp_struct)
`define AXI_ASSIGN_MASTER_TO_FLAT(pat, req, rsp) \
  assign m_axi_``pat``_awvalid  = req.aw_valid;  \
  assign m_axi_``pat``_awid     = req.aw.id;     \
  assign m_axi_``pat``_awaddr   = req.aw.addr;   \
  assign m_axi_``pat``_awlen    = req.aw.len;    \
  assign m_axi_``pat``_awsize   = req.aw.size;   \
  assign m_axi_``pat``_awburst  = req.aw.burst;  \
  assign m_axi_``pat``_awlock   = req.aw.lock;   \
  assign m_axi_``pat``_awcache  = req.aw.cache;  \
  assign m_axi_``pat``_awprot   = req.aw.prot;   \
  assign m_axi_``pat``_awqos    = req.aw.qos;    \
  assign m_axi_``pat``_awregion = req.aw.region; \
  assign m_axi_``pat``_awuser   = req.aw.user;   \
                                                 \
  assign m_axi_``pat``_wvalid   = req.w_valid;   \
  assign m_axi_``pat``_wdata    = req.w.data;    \
  assign m_axi_``pat``_wstrb    = req.w.strb;    \
  assign m_axi_``pat``_wlast    = req.w.last;    \
  assign m_axi_``pat``_wuser    = req.w.user;    \
                                                 \
  assign m_axi_``pat``_bready   = req.b_ready;   \
                                                 \
  assign m_axi_``pat``_arvalid  = req.ar_valid;  \
  assign m_axi_``pat``_arid     = req.ar.id;     \
  assign m_axi_``pat``_araddr   = req.ar.addr;   \
  assign m_axi_``pat``_arlen    = req.ar.len;    \
  assign m_axi_``pat``_arsize   = req.ar.size;   \
  assign m_axi_``pat``_arburst  = req.ar.burst;  \
  assign m_axi_``pat``_arlock   = req.ar.lock;   \
  assign m_axi_``pat``_arcache  = req.ar.cache;  \
  assign m_axi_``pat``_arprot   = req.ar.prot;   \
  assign m_axi_``pat``_arqos    = req.ar.qos;    \
  assign m_axi_``pat``_arregion = req.ar.region; \
  assign m_axi_``pat``_aruser   = req.ar.user;   \
                                                 \
  assign m_axi_``pat``_rready   = req.r_ready;   \
                                                 \
  assign rsp.aw_ready = m_axi_``pat``_awready;   \
  assign rsp.ar_ready = m_axi_``pat``_arready;   \
  assign rsp.w_ready  = m_axi_``pat``_wready;    \
                                                 \
  assign rsp.b_valid  = m_axi_``pat``_bvalid;    \
  assign rsp.b.id     = m_axi_``pat``_bid;       \
  assign rsp.b.resp   = m_axi_``pat``_bresp;     \
  assign rsp.b.user   = m_axi_``pat``_buser;     \
                                                 \
  assign rsp.r_valid  = m_axi_``pat``_rvalid;    \
  assign rsp.r.id     = m_axi_``pat``_rid;       \
  assign rsp.r.data   = m_axi_``pat``_rdata;     \
  assign rsp.r.resp   = m_axi_``pat``_rresp;     \
  assign rsp.r.last   = m_axi_``pat``_rlast;     \
  assign rsp.r.user   = m_axi_``pat``_ruser;

`define AXI_ASSIGN_SLAVE_TO_FLAT(pat, req, rsp)  \
  assign req.aw_valid  = s_axi_``pat``_awvalid;  \
  assign req.aw.id     = s_axi_``pat``_awid;     \
  assign req.aw.addr   = s_axi_``pat``_awaddr;   \
  assign req.aw.len    = s_axi_``pat``_awlen;    \
  assign req.aw.size   = s_axi_``pat``_awsize;   \
  assign req.aw.burst  = s_axi_``pat``_awburst;  \
  assign req.aw.lock   = s_axi_``pat``_awlock;   \
  assign req.aw.cache  = s_axi_``pat``_awcache;  \
  assign req.aw.prot   = s_axi_``pat``_awprot;   \
  assign req.aw.qos    = s_axi_``pat``_awqos;    \
  assign req.aw.region = s_axi_``pat``_awregion; \
  assign req.aw.user   = s_axi_``pat``_awuser;   \
                                                 \
  assign req.w_valid   = s_axi_``pat``_wvalid;   \
  assign req.w.data    = s_axi_``pat``_wdata;    \
  assign req.w.strb    = s_axi_``pat``_wstrb;    \
  assign req.w.last    = s_axi_``pat``_wlast;    \
  assign req.w.user    = s_axi_``pat``_wuser;    \
                                                 \
  assign req.b_ready   = s_axi_``pat``_bready;   \
                                                 \
  assign req.ar_valid  = s_axi_``pat``_arvalid;  \
  assign req.ar.id     = s_axi_``pat``_arid;     \
  assign req.ar.addr   = s_axi_``pat``_araddr;   \
  assign req.ar.len    = s_axi_``pat``_arlen;    \
  assign req.ar.size   = s_axi_``pat``_arsize;   \
  assign req.ar.burst  = s_axi_``pat``_arburst;  \
  assign req.ar.lock   = s_axi_``pat``_arlock;   \
  assign req.ar.cache  = s_axi_``pat``_arcache;  \
  assign req.ar.prot   = s_axi_``pat``_arprot;   \
  assign req.ar.qos    = s_axi_``pat``_arqos;    \
  assign req.ar.region = s_axi_``pat``_arregion; \
  assign req.ar.user   = s_axi_``pat``_aruser;   \
                                                 \
  assign req.r_ready   = s_axi_``pat``_rready;   \
                                                 \
  assign s_axi_``pat``_awready = rsp.aw_ready;   \
  assign s_axi_``pat``_arready = rsp.ar_ready;   \
  assign s_axi_``pat``_wready  = rsp.w_ready;    \
                                                 \
  assign s_axi_``pat``_bvalid  = rsp.b_valid;    \
  assign s_axi_``pat``_bid     = rsp.b.id;       \
  assign s_axi_``pat``_bresp   = rsp.b.resp;     \
  assign s_axi_``pat``_buser   = rsp.b.user;     \
                                                 \
  assign s_axi_``pat``_rvalid  = rsp.r_valid;    \
  assign s_axi_``pat``_rid     = rsp.r.id;       \
  assign s_axi_``pat``_rdata   = rsp.r.data;     \
  assign s_axi_``pat``_rresp   = rsp.r.resp;     \
  assign s_axi_``pat``_rlast   = rsp.r.last;     \
  assign s_axi_``pat``_ruser   = rsp.r.user;

`define AXI_ASSIGN_TO_FLAT_PORT(pat, req, rsp)  \
  .``pat``_awvalid  ( req.aw_valid  ), \
  .``pat``_awid     ( req.aw.id     ), \
  .``pat``_awaddr   ( req.aw.addr   ), \
  .``pat``_awlen    ( req.aw.len    ), \
  .``pat``_awsize   ( req.aw.size   ), \
  .``pat``_awburst  ( req.aw.burst  ), \
  .``pat``_awlock   ( req.aw.lock   ), \
  .``pat``_awcache  ( req.aw.cache  ), \
  .``pat``_awprot   ( req.aw.prot   ), \
  .``pat``_awqos    ( req.aw.qos    ), \
  .``pat``_awregion ( req.aw.region ), \
  .``pat``_awuser   ( req.aw.user   ), \
                                       \
  .``pat``_wvalid   ( req.w_valid   ), \
  .``pat``_wdata    ( req.w.data    ), \
  .``pat``_wstrb    ( req.w.strb    ), \
  .``pat``_wlast    ( req.w.last    ), \
  .``pat``_wuser    ( req.w.user    ), \
                                       \
  .``pat``_bready   ( req.b_ready   ), \
                                       \
  .``pat``_arvalid  ( req.ar_valid  ), \
  .``pat``_arid     ( req.ar.id     ), \
  .``pat``_araddr   ( req.ar.addr   ), \
  .``pat``_arlen    ( req.ar.len    ), \
  .``pat``_arsize   ( req.ar.size   ), \
  .``pat``_arburst  ( req.ar.burst  ), \
  .``pat``_arlock   ( req.ar.lock   ), \
  .``pat``_arcache  ( req.ar.cache  ), \
  .``pat``_arprot   ( req.ar.prot   ), \
  .``pat``_arqos    ( req.ar.qos    ), \
  .``pat``_arregion ( req.ar.region ), \
  .``pat``_aruser   ( req.ar.user   ), \
                                       \
  .``pat``_rready   ( req.r_ready   ), \
                                       \
  .``pat``_awready  ( rsp.aw_ready  ), \
  .``pat``_arready  ( rsp.ar_ready  ), \
  .``pat``_wready   ( rsp.w_ready   ), \
                                       \
  .``pat``_bvalid   ( rsp.b_valid   ), \
  .``pat``_bid      ( rsp.b.id      ), \
  .``pat``_bresp    ( rsp.b.resp    ), \
  .``pat``_buser    ( rsp.b.user    ), \
                                       \
  .``pat``_rvalid   ( rsp.r_valid   ), \
  .``pat``_rid      ( rsp.r.id      ), \
  .``pat``_rdata    ( rsp.r.data    ), \
  .``pat``_rresp    ( rsp.r.resp    ), \
  .``pat``_rlast    ( rsp.r.last    ), \
  .``pat``_ruser    ( rsp.r.user    )

`define AXI_ASSIGN_MASTER_TO_FLAT_PORT(name, req, rsp) \
  `AXI_ASSIGN_TO_FLAT_PORT(m_axi_``name``, req, rsp)

`define AXI_ASSIGN_SLAVE_TO_FLAT_PORT(name, req, rsp) \
  `AXI_ASSIGN_TO_FLAT_PORT(s_axi_``name``, req, rsp)


////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Macros instantiating signal highlighter from common verification
// https://github.com/pulp-platform/common_verification.git
// `AXI_HIGHLIGHT(__name, __aw_t, __w_t, __b_t, __ar_t, __r_t, __req, __resp)
`define AXI_HIGHLIGHT(__name, __aw_t, __w_t, __b_t, __ar_t, __r_t, __req, __resp) \
  signal_highlighter #(                                                           \
    .T ( __aw_t )                                                                 \
  ) i_signal_highlighter_``__name``_aw (                                          \
    .ready_i ( __resp.aw_ready ),                                                 \
    .valid_i ( __req.aw_valid  ),                                                 \
    .data_i  ( __req.aw        )                                                  \
  );                                                                              \
  signal_highlighter #(                                                           \
    .T ( __w_t )                                                                  \
  ) i_signal_highlighter_``__name``_w (                                           \
    .ready_i ( __resp.w_ready ),                                                  \
    .valid_i ( __req.w_valid  ),                                                  \
    .data_i  ( __req.w        )                                                   \
  );                                                                              \
  signal_highlighter #(                                                           \
    .T ( __b_t )                                                                  \
  ) i_signal_highlighter_``__name``_b (                                           \
    .ready_i ( __req.b_ready  ),                                                  \
    .valid_i ( __resp.b_valid ),                                                  \
    .data_i  ( __resp.b       )                                                   \
  );                                                                              \
  signal_highlighter #(                                                           \
    .T ( __ar_t )                                                                 \
  ) i_signal_highlighter_``__name``_ar (                                          \
    .ready_i ( __resp.ar_ready ),                                                 \
    .valid_i ( __req.ar_valid  ),                                                 \
    .data_i  ( __req.ar        )                                                  \
  );                                                                              \
  signal_highlighter #(                                                           \
    .T ( __r_t )                                                                  \
  ) i_signal_highlighter_``__name``_r (                                           \
    .ready_i ( __req.r_ready  ),                                                  \
    .valid_i ( __resp.r_valid ),                                                  \
    .data_i  ( __resp.r       )                                                   \
  );
////////////////////////////////////////////////////////////////////////////////////////////////////

`endif
// ---- end inlined axi/assign.svh ----

/// Interface variant of [`axi_iw_converter`](module.axi_iw_converter).
///
/// See the documentation of the main module for the definition of ports and parameters.
module axi_iw_converter_intf #(
  parameter int unsigned AXI_SLV_PORT_ID_WIDTH = 32'd0,
  parameter int unsigned AXI_MST_PORT_ID_WIDTH = 32'd0,
  parameter int unsigned AXI_SLV_PORT_MAX_UNIQ_IDS = 32'd0,
  parameter int unsigned AXI_SLV_PORT_MAX_TXNS_PER_ID = 32'd0,
  parameter int unsigned AXI_SLV_PORT_MAX_TXNS = 32'd0,
  parameter int unsigned AXI_MST_PORT_MAX_UNIQ_IDS = 32'd0,
  parameter int unsigned AXI_MST_PORT_MAX_TXNS_PER_ID = 32'd0,
  parameter int unsigned AXI_ADDR_WIDTH = 32'd0,
  parameter int unsigned AXI_DATA_WIDTH = 32'd0,
  parameter int unsigned AXI_USER_WIDTH = 32'd0
) (
  input  logic   clk_i,
  input  logic   rst_ni,
  AXI_BUS.Slave  slv,
  AXI_BUS.Master mst
);
  typedef logic [AXI_SLV_PORT_ID_WIDTH-1:0] slv_id_t;
  typedef logic [AXI_MST_PORT_ID_WIDTH-1:0] mst_id_t;
  typedef logic [AXI_ADDR_WIDTH-1:0]        axi_addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0]        axi_data_t;
  typedef logic [AXI_DATA_WIDTH/8-1:0]      axi_strb_t;
  typedef logic [AXI_USER_WIDTH-1:0]        axi_user_t;

  `AXI_TYPEDEF_AW_CHAN_T(slv_aw_chan_t, axi_addr_t, slv_id_t, axi_user_t)
  `AXI_TYPEDEF_W_CHAN_T(slv_w_chan_t, axi_data_t, axi_strb_t, axi_user_t)
  `AXI_TYPEDEF_B_CHAN_T(slv_b_chan_t, slv_id_t, axi_user_t)
  `AXI_TYPEDEF_AR_CHAN_T(slv_ar_chan_t, axi_addr_t, slv_id_t, axi_user_t)
  `AXI_TYPEDEF_R_CHAN_T(slv_r_chan_t, axi_data_t, slv_id_t, axi_user_t)
  `AXI_TYPEDEF_REQ_T(slv_req_t, slv_aw_chan_t, slv_w_chan_t, slv_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(slv_resp_t, slv_b_chan_t, slv_r_chan_t)

  `AXI_TYPEDEF_AW_CHAN_T(mst_aw_chan_t, axi_addr_t, mst_id_t, axi_user_t)
  `AXI_TYPEDEF_W_CHAN_T(mst_w_chan_t, axi_data_t, axi_strb_t, axi_user_t)
  `AXI_TYPEDEF_B_CHAN_T(mst_b_chan_t, mst_id_t, axi_user_t)
  `AXI_TYPEDEF_AR_CHAN_T(mst_ar_chan_t, axi_addr_t, mst_id_t, axi_user_t)
  `AXI_TYPEDEF_R_CHAN_T(mst_r_chan_t, axi_data_t, mst_id_t, axi_user_t)
  `AXI_TYPEDEF_REQ_T(mst_req_t, mst_aw_chan_t, mst_w_chan_t, mst_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(mst_resp_t, mst_b_chan_t, mst_r_chan_t)

  slv_req_t  slv_req;
  slv_resp_t slv_resp;
  mst_req_t  mst_req;
  mst_resp_t mst_resp;

  `AXI_ASSIGN_TO_REQ(slv_req, slv)
  `AXI_ASSIGN_FROM_RESP(slv, slv_resp)
  `AXI_ASSIGN_FROM_REQ(mst, mst_req)
  `AXI_ASSIGN_TO_RESP(mst_resp, mst)

  axi_iw_converter #(
    .AxiSlvPortIdWidth      ( AXI_SLV_PORT_ID_WIDTH         ),
    .AxiMstPortIdWidth      ( AXI_MST_PORT_ID_WIDTH         ),
    .AxiSlvPortMaxUniqIds   ( AXI_SLV_PORT_MAX_UNIQ_IDS     ),
    .AxiSlvPortMaxTxnsPerId ( AXI_SLV_PORT_MAX_TXNS_PER_ID  ),
    .AxiSlvPortMaxTxns      ( AXI_SLV_PORT_MAX_TXNS         ),
    .AxiMstPortMaxUniqIds   ( AXI_MST_PORT_MAX_UNIQ_IDS     ),
    .AxiMstPortMaxTxnsPerId ( AXI_MST_PORT_MAX_TXNS_PER_ID  ),
    .AxiAddrWidth           ( AXI_ADDR_WIDTH                ),
    .AxiDataWidth           ( AXI_DATA_WIDTH                ),
    .AxiUserWidth           ( AXI_USER_WIDTH                ),
    .slv_req_t              ( slv_req_t                     ),
    .slv_resp_t             ( slv_resp_t                    ),
    .mst_req_t              ( mst_req_t                     ),
    .mst_resp_t             ( mst_resp_t                    )
  ) i_axi_iw_converter (
    .clk_i,
    .rst_ni,
    .slv_req_i  ( slv_req  ),
    .slv_resp_o ( slv_resp ),
    .mst_req_o  ( mst_req  ),
    .mst_resp_i ( mst_resp )
  );
  // pragma translate_off
  `ifndef VERILATOR
    initial begin
      assert (slv.AXI_ID_WIDTH   == AXI_SLV_PORT_ID_WIDTH);
      assert (slv.AXI_ADDR_WIDTH == AXI_ADDR_WIDTH);
      assert (slv.AXI_DATA_WIDTH == AXI_DATA_WIDTH);
      assert (slv.AXI_USER_WIDTH == AXI_USER_WIDTH);
      assert (mst.AXI_ID_WIDTH   == AXI_MST_PORT_ID_WIDTH);
      assert (mst.AXI_ADDR_WIDTH == AXI_ADDR_WIDTH);
      assert (mst.AXI_DATA_WIDTH == AXI_DATA_WIDTH);
      assert (mst.AXI_USER_WIDTH == AXI_USER_WIDTH);
    end
  `endif
  // pragma translate_on
endmodule
