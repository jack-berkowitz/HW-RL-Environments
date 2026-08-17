// =============================================================================
// axi4_xbar_pkg.sv -- TYPE DEFINITIONS SHIPPED WITH THE SPEC (d_nw01)
// =============================================================================
// These are part of the problem statement, not a hint. An AXI4 crossbar's ports
// are five channels in each direction on every port; spelling them out as flat
// vectors would make the interface unreadable and would force an arbitrary bit
// ordering into the contract. Named structs are how AXI is written in practice.
//
// Field names and ORDER follow the AXI4 specification. The order matters: these
// are PACKED structs, so the layout is normative and a design that reorders
// fields is not interoperable even if every field is individually correct.
//
// The parameters below are FIXED for this task. They are not free choices.
// =============================================================================

package axi4_xbar_pkg;

  // ---- fixed geometry -------------------------------------------------------
  parameter int unsigned ADDR_W   = 32;
  parameter int unsigned DATA_W   = 64;
  parameter int unsigned STRB_W   = DATA_W / 8;
  parameter int unsigned SLV_ID_W = 4;    // ID width presented BY each master
  parameter int unsigned USER_W   = 1;

  typedef logic [ADDR_W-1:0]   addr_t;
  typedef logic [DATA_W-1:0]   data_t;
  typedef logic [STRB_W-1:0]   strb_t;
  typedef logic [USER_W-1:0]   user_t;
  typedef logic [SLV_ID_W-1:0] slv_id_t;

  // Slave-side IDs are widened so a response can name the master it belongs to.
  // The width is fixed at SLV_ID_W + MST_IDX_W rather than varying with the
  // parameter -- a SystemVerilog package cannot be parameterised, and one fixed
  // layout has to keep the struct definitions below valid at every legal
  // configuration.
  //
  // *** THIS CAPS NUM_MST AT 4. ***
  // MST_IDX_W = 2 supplies exactly enough index bits for 4 masters:
  //     NUM_MST = 2  -> needs 1 bit, one spare
  //     NUM_MST = 4  -> needs 2 bits, exact
  //     NUM_MST = 8  -> needs 3 bits, WHICH THIS LAYOUT CANNOT SUPPLY.
  // At NUM_MST = 8 two masters would share an index, their responses would
  // misroute, and the failure would look like an ordering bug rather than a
  // width bug. NUM_MST > 4 is therefore ILLEGAL and the checker aborts on it
  // rather than producing a plausible-looking wrong answer. Raising the cap
  // means widening MST_IDX_W here and re-verifying every geometry.
  parameter int unsigned MST_IDX_W = 2;
  parameter int unsigned MST_ID_W  = SLV_ID_W + MST_IDX_W;
  typedef logic [MST_ID_W-1:0] mst_id_t;

  // ---- AXI4 burst / response encodings -------------------------------------
  parameter logic [1:0] BURST_FIXED = 2'b00;
  parameter logic [1:0] BURST_INCR  = 2'b01;
  parameter logic [1:0] BURST_WRAP  = 2'b10;

  parameter logic [1:0] RESP_OKAY   = 2'b00;
  parameter logic [1:0] RESP_EXOKAY = 2'b01;
  parameter logic [1:0] RESP_SLVERR = 2'b10;
  parameter logic [1:0] RESP_DECERR = 2'b11;   // returned for an unmapped address

  // ---- channels, slave side (what a master drives into the crossbar) -------
  // ===========================================================================
  // CHANNEL SIGNAL DIRECTIONS — normative, AMBA AXI4 §A3.1
  // ===========================================================================
  // WHICH STRUCT A HANDSHAKE SIGNAL LIVES IN FOLLOWS FROM ITS DIRECTION, and
  // the two are easy to conflate. `b_ready` is the case that catches people:
  // B is called "the response channel", but BREADY is driven by the MASTER, so
  // it belongs to the REQUEST struct, not the response.
  //
  //   channel  VALID driven by   READY driven by   -> req_t holds   resp_t holds
  //   AW       master            slave                aw, aw_valid    aw_ready
  //   W        master            slave                w,  w_valid     w_ready
  //   B        SLAVE             MASTER               b_ready         b, b_valid
  //   AR       master            slave                ar, ar_valid    ar_ready
  //   R        SLAVE             MASTER               r_ready         r, r_valid
  //
  // Authority: AMBA AXI4 §A3.1 fixes the directions. The grouping into these
  // two structs follows from them and is not a free choice.
  //
  // WHY THIS IS STATED RATHER THAN LEFT TO BE READ OFF THE STRUCTS. Two
  // independent submissions reached for `slv_resp_t.b_ready` and failed to
  // elaborate, losing their entire result (FINDINGS.md F35, F38). That is a
  // packaging-lookup error, and packaging is on NONE of the axes this task
  // measures -- outstanding-ID tracking, per-ID response ordering, deadlock
  // freedom, arbitration. A barrier that is not on the measured axes and costs
  // 100 % of the score is noise, and removing it makes none of those four
  // easier.
  // ===========================================================================

  typedef struct packed {
    slv_id_t      id;
    addr_t        addr;
    logic [7:0]   len;      // beats - 1
    logic [2:0]   size;     // log2(bytes per beat)
    logic [1:0]   burst;
    logic         lock;
    logic [3:0]   cache;
    logic [2:0]   prot;
    logic [3:0]   qos;
    logic [3:0]   region;
    logic [5:0]   atop;     // tied 0 for this task; ATOPs are out of scope
    user_t        user;
  } slv_aw_t;

  typedef struct packed {
    data_t        data;
    strb_t        strb;
    logic         last;
    user_t        user;
  } w_t;

  typedef struct packed {
    slv_id_t      id;
    logic [1:0]   resp;
    user_t        user;
  } slv_b_t;

  typedef struct packed {
    slv_id_t      id;
    addr_t        addr;
    logic [7:0]   len;
    logic [2:0]   size;
    logic [1:0]   burst;
    logic         lock;
    logic [3:0]   cache;
    logic [2:0]   prot;
    logic [3:0]   qos;
    logic [3:0]   region;
    user_t        user;
  } slv_ar_t;

  typedef struct packed {
    slv_id_t      id;
    data_t        data;
    logic [1:0]   resp;
    logic         last;
    user_t        user;
  } slv_r_t;

  // Aggregated request / response, one per port. Field order is normative.
  typedef struct packed {
    slv_aw_t  aw;   logic aw_valid;
    w_t       w;    logic w_valid;
    logic     b_ready;
    slv_ar_t  ar;   logic ar_valid;
    logic     r_ready;
  } slv_req_t;

  typedef struct packed {
    logic     aw_ready;
    logic     ar_ready;
    logic     w_ready;
    logic     b_valid;  slv_b_t b;
    logic     r_valid;  slv_r_t r;
  } slv_resp_t;

  // ---- channels, master side (what the crossbar drives at a slave) ---------
  // Identical to the slave-side channels except the id field is widened. The
  // upper MST_IDX_W bits name the originating master; the lower SLV_ID_W bits
  // are the id that master issued and are what must be presented back to it.
  typedef struct packed {
    mst_id_t      id;
    addr_t        addr;
    logic [7:0]   len;
    logic [2:0]   size;
    logic [1:0]   burst;
    logic         lock;
    logic [3:0]   cache;
    logic [2:0]   prot;
    logic [3:0]   qos;
    logic [3:0]   region;
    logic [5:0]   atop;
    user_t        user;
  } mst_aw_t;

  typedef struct packed {
    mst_id_t      id;
    logic [1:0]   resp;
    user_t        user;
  } mst_b_t;

  typedef struct packed {
    mst_id_t      id;
    addr_t        addr;
    logic [7:0]   len;
    logic [2:0]   size;
    logic [1:0]   burst;
    logic         lock;
    logic [3:0]   cache;
    logic [2:0]   prot;
    logic [3:0]   qos;
    logic [3:0]   region;
    user_t        user;
  } mst_ar_t;

  typedef struct packed {
    mst_id_t      id;
    data_t        data;
    logic [1:0]   resp;
    logic         last;
    user_t        user;
  } mst_r_t;

  typedef struct packed {
    mst_aw_t  aw;   logic aw_valid;
    w_t       w;    logic w_valid;
    logic     b_ready;
    mst_ar_t  ar;   logic ar_valid;
    logic     r_ready;
  } mst_req_t;

  typedef struct packed {
    logic     aw_ready;
    logic     ar_ready;
    logic     w_ready;
    logic     b_valid;  mst_b_t b;
    logic     r_valid;  mst_r_t r;
  } mst_resp_t;

  // ---- address map ----------------------------------------------------------
  // One rule per master port. A request whose address falls in [start, end) is
  // routed to `mst_port`. Ranges do not overlap.
  typedef struct packed {
    logic [$clog2(8)-1:0] mst_port;
    addr_t                start_addr;
    addr_t                end_addr;
  } xbar_rule_t;

endpackage
