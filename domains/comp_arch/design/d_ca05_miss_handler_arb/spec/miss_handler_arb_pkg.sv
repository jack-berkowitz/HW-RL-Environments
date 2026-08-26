// =============================================================================
// miss_handler_arb_pkg.sv -- the types d_ca05's contract is written in.
//
// SHIPS WITH THE TASK and is part of its text. A submission imports this package
// and needs nothing else: no CVA6 configuration package, no AXI library, no
// knowledge of where the anchor came from. Every width below is a CONCRETE
// NUMBER measured from the reference configuration rather than a parameter to
// be resolved -- if it were a parameter, a submission would have to reconstruct
// the same configuration to get the same widths, and would be graded partly on
// having done that.
// =============================================================================

package miss_handler_arb_pkg;

  // ---- cache geometry, fixed by P1 -----------------------------------------
  localparam int unsigned SET_ASSOC    = 8;
  localparam int unsigned INDEX_WIDTH  = 12;
  localparam int unsigned TAG_WIDTH    = 44;
  localparam int unsigned LINE_WIDTH   = 128;
  localparam int unsigned OFFSET_WIDTH = 4;
  localparam int unsigned NUM_WORDS    = 256;   // 2^(INDEX_WIDTH-OFFSET_WIDTH)

  // ---- AXI geometry, fixed by P1 -------------------------------------------
  localparam int unsigned AXI_ID_W   = 4;
  localparam int unsigned AXI_ADDR_W = 64;
  localparam int unsigned AXI_DATA_W = 64;
  localparam int unsigned AXI_USER_W = 1;

  typedef logic [AXI_ID_W-1:0]     axi_id_t;
  typedef logic [AXI_ADDR_W-1:0]   axi_addr_t;
  typedef logic [AXI_DATA_W-1:0]   axi_data_t;
  typedef logic [AXI_DATA_W/8-1:0] axi_strb_t;
  typedef logic [AXI_USER_W-1:0]   axi_user_t;

  // ---- AXI channels --------------------------------------------------------
  // Field-for-field the AXI4 channels, including `atop`: an atomic memory
  // operation leaves this unit as an AXI ATOP write, and the memory performs
  // it. See A7.
  typedef struct packed {
    axi_id_t     id;
    axi_addr_t   addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    logic [3:0]  region;
    logic [5:0]  atop;
    axi_user_t   user;
  } axi_aw_t;

  typedef struct packed {
    axi_id_t     id;
    axi_addr_t   addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    logic [3:0]  region;
    axi_user_t   user;
  } axi_ar_t;

  typedef struct packed {
    axi_data_t data; axi_strb_t strb; logic last; axi_user_t user;
  } axi_w_t;

  typedef struct packed {
    axi_id_t id; logic [1:0] resp; axi_user_t user;
  } axi_b_t;

  typedef struct packed {
    axi_id_t id; axi_data_t data; logic [1:0] resp; logic last; axi_user_t user;
  } axi_r_t;

  typedef struct packed {
    axi_aw_t aw; logic aw_valid;
    axi_w_t  w;  logic w_valid;
    logic    b_ready;
    axi_ar_t ar; logic ar_valid;
    logic    r_ready;
  } axi_req_t;

  typedef struct packed {
    logic    aw_ready; logic ar_ready; logic w_ready;
    logic    b_valid;  axi_b_t b;
    logic    r_valid;  axi_r_t r;
  } axi_rsp_t;

  // ---- the cache array ------------------------------------------------------
  typedef struct packed {
    logic [TAG_WIDTH-1:0]  tag;
    logic [LINE_WIDTH-1:0] data;
    logic                  valid;
    logic                  dirty;
  } cache_line_t;

  typedef struct packed {
    logic [(TAG_WIDTH+7)/8-1:0]  tag;
    logic [(LINE_WIDTH+7)/8-1:0] data;
    logic [SET_ASSOC-1:0]        vldrty;
  } cl_be_t;

  // ---- a requester's miss request -------------------------------------------
  // 141 bits. `bypass` selects the bypass path over a cacheline refill; the two
  // are arbitrated separately (A2, A3).
  typedef struct packed {
    logic        valid;
    logic [63:0] addr;
    logic [7:0]  be;
    logic [1:0]  size;
    logic        we;
    logic [63:0] wdata;
    logic        bypass;
  } miss_req_t;

  // ---- atomics ---------------------------------------------------------------
  typedef enum logic [3:0] {
    AMO_NONE = 4'b0000, AMO_LR   = 4'b0001, AMO_SC   = 4'b0010, AMO_SWAP = 4'b0011,
    AMO_ADD  = 4'b0100, AMO_AND  = 4'b0101, AMO_OR   = 4'b0110, AMO_XOR  = 4'b0111,
    AMO_MAX  = 4'b1000, AMO_MAXU = 4'b1001, AMO_MIN  = 4'b1010, AMO_MINU = 4'b1011,
    AMO_CAS1 = 4'b1100, AMO_CAS2 = 4'b1101
  } amo_t;

  typedef struct packed {
    logic        req;
    amo_t        amo_op;
    logic [1:0]  size;
    logic [63:0] operand_a;   // address
    logic [63:0] operand_b;   // data
  } amo_req_t;

  typedef struct packed {
    logic        ack;
    logic [63:0] result;
  } amo_resp_t;

endpackage
