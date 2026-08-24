// v_ca06 SECOND DUT -- an independent implementation. MUST BE ACCEPTED.
module dw_downsizer_alt #(
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
  // -------------------------------------------------------------------------
  // An INDEPENDENT implementation of spec/dw_downsizer_spec.md, written from
  // the specification and not from the anchor. It does not instantiate the
  // golden and shares no code with it.
  //
  // It differs from the anchor on every named latitude clause it can:
  //
  //   A4/L2  it holds ONE transaction at a time per direction. A4 makes
  //          MAX_READS an UPPER BOUND, not an obligation, and L2 says a ready
  //          may be low for reasons of internal arbitration -- so a design that
  //          never has two reads outstanding is conforming. The anchor keeps
  //          four adapters busy.
  //   L1     every path is registered, so its latencies differ from the
  //          anchor's throughout.
  //   L4     it buffers a WHOLE upstream W beat before emitting any downstream
  //          beat of it. The anchor forwards as it goes.
  //   X2     it drives a fixed recognisable pattern on payload outputs while
  //          their valid is low, where the anchor drives the computed value.
  //
  // A testbench that fails this is encoding the anchor's scheduling rather than
  // the contract.
  // -------------------------------------------------------------------------
  localparam int SBYTES = SLV_DATA_W/8;          // 8
  localparam int MBYTES = MST_DATA_W/8;          // 2
  localparam int MSIZE  = (MBYTES == 2) ? 1 : 0; // log2(MBYTES)

  function automatic int unsigned bbytes(input logic [2:0] sz);
    bbytes = 1 << sz;
  endfunction
  function automatic logic [31:0] algn(input logic [31:0] a, input logic [2:0] sz);
    algn = a & ~(( 32'd1 << sz) - 32'd1);
  endfunction
  function automatic logic bad_burst(input logic [1:0] b, input logic [7:0] l);
    bad_burst = (b == 2'b10) || ((b == 2'b00) && (l != 8'd0));
  endfunction
  // downstream size, length and total bytes -- clauses B1 and B2
  function automatic logic [2:0] ds_size(input logic [2:0] sz);
    ds_size = (sz < MSIZE[2:0]) ? sz : MSIZE[2:0];
  endfunction
  function automatic int unsigned tot_bytes(input logic [31:0] a, input logic [7:0] l,
                                            input logic [2:0] sz);
    tot_bytes = (int'(l) + 1) * bbytes(sz) - int'(a - algn(a, sz));
  endfunction
  // clause B2: a count of aligned downstream BLOCKS SPANNED. Dividing the byte
  // count gives -1 when the range does not fill one block.
  function automatic logic [7:0] ds_len_f(input logic [31:0] a, input logic [7:0] l,
                                          input logic [2:0] sz);
    automatic logic [31:0] lastb = a + 32'(tot_bytes(a, l, sz)) - 32'd1;
    ds_len_f = 8'((algn(lastb, ds_size(sz)) - algn(a, ds_size(sz))) >> ds_size(sz));
  endfunction

  // ================= READ =================
  typedef enum logic [1:0] {R_IDLE, R_ADDR, R_DATA, R_ERR} rst_e;
  rst_e            r_st;
  logic [ID_W-1:0] r_id;
  logic [31:0]     r_addr, r_ptr, r_end;   // byte pointers into the stream
  logic [7:0]      r_len, r_dslen, r_errbeat;
  logic [2:0]      r_size, r_dssize;
  logic            r_err_seen;
  logic [SLV_DATA_W-1:0] r_buf;
  logic [31:0]     r_upnext;               // first byte address of the NEXT upstream beat

  assign s_arready = (r_st == R_IDLE);
  assign m_arvalid = (r_st == R_ADDR);
  assign m_arid    = r_id;
  assign m_araddr  = r_addr;
  assign m_arlen   = r_dslen;
  assign m_arsize  = r_dssize;
  assign m_arburst = 2'b01;                // clause B4: always INCR
  // Not merely "in R_DATA": while an upstream beat is still waiting to be
  // taken we cannot process another downstream beat, and leaving ready high
  // consumes it anyway. That dropped every second beat.
  assign m_rready  = (r_st == R_DATA) && !s_rvalid_q;

  logic                  s_rvalid_q, s_rlast_q;
  logic [1:0]            s_rresp_q;
  logic [SLV_DATA_W-1:0] s_rdata_q;
  logic [ID_W-1:0]       s_rid_q;
  assign s_rvalid = s_rvalid_q;
  assign s_rlast  = s_rlast_q;
  assign s_rresp  = s_rresp_q;
  assign s_rid    = s_rid_q;
  // X2: a fixed pattern while valid is low, not the computed value
  assign s_rdata  = s_rvalid_q ? s_rdata_q : 64'hFACE_FACE_FACE_FACE;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      r_st <= R_IDLE; s_rvalid_q <= 1'b0; r_err_seen <= 1'b0; r_buf <= '0;
      r_id <= '0; r_addr <= '0; r_ptr <= '0; r_end <= '0; r_len <= '0;
      r_dslen <= '0; r_size <= '0; r_dssize <= '0; r_errbeat <= '0;
      s_rlast_q <= 1'b0; s_rresp_q <= '0; s_rdata_q <= '0; s_rid_q <= '0;
      r_upnext <= '0;
    end else begin
      if (s_rvalid_q && s_rready) begin s_rvalid_q <= 1'b0; s_rlast_q <= 1'b0; end
      case (r_st)
        R_IDLE: if (s_arvalid) begin
          r_id <= s_arid; r_addr <= s_araddr; r_len <= s_arlen; r_size <= s_arsize;
          r_err_seen <= 1'b0; r_buf <= '0;
          if (bad_burst(s_arburst, s_arlen)) begin
            r_errbeat <= s_arlen; r_st <= R_ERR;            // clause C4
          end else begin
            r_dssize <= ds_size(s_arsize);
            r_dslen  <= ds_len_f(s_araddr, s_arlen, s_arsize);
            r_ptr    <= s_araddr;
            r_end    <= s_araddr + 32'(tot_bytes(s_araddr, s_arlen, s_arsize));
            r_upnext <= algn(s_araddr, s_arsize) + 32'(bbytes(s_arsize));
            r_st     <= R_ADDR;
          end
        end
        R_ADDR: if (m_arready) r_st <= R_DATA;
        R_DATA: if (m_rvalid && !s_rvalid_q) begin
          automatic logic [SLV_DATA_W-1:0] nb = r_buf;
          automatic logic [31:0] p = r_ptr;
          automatic int unsigned nby = 0;
          // place this downstream beat's bytes into their upstream lanes (D2)
          // BOTH lanes are address-derived. Reading the downstream lane by the
          // loop index is only right when the beat base is bus-aligned, and at
          // size 0 a beat advances one byte at a time so the lane alternates.
          for (int b = 0; b < MBYTES; b++) begin
            automatic logic [31:0] a = algn(p, r_dssize) + 32'(b);
            if (a >= p && a < r_end)
              nb[8*(a % SBYTES) +: 8] = m_rdata[8*(a % MBYTES) +: 8];
          end
          nby = int'(algn(p, r_dssize)) + bbytes(r_dssize) - int'(p);
          if (m_rresp != 2'b00) r_err_seen <= 1'b1;
          r_buf <= nb;
          r_ptr <= p + 32'(nby);
          // an upstream beat completes when the pointer reaches its end (D1/D4)
          if ((p + 32'(nby) >= r_upnext) || (p + 32'(nby) >= r_end)) begin
            s_rvalid_q <= 1'b1; s_rdata_q <= nb; s_rid_q <= r_id;
            s_rresp_q  <= (r_err_seen || m_rresp != 2'b00) ? 2'b10 : 2'b00;  // D6
            s_rlast_q  <= (p + 32'(nby) >= r_end);
            r_buf      <= '0;
            r_upnext   <= r_upnext + 32'(bbytes(r_size));
            if (p + 32'(nby) >= r_end) r_st <= R_IDLE;
          end
        end
        R_ERR: if (!s_rvalid_q) begin                        // clause C4.4 and C4.5
          s_rvalid_q <= 1'b1; s_rdata_q <= '0; s_rid_q <= r_id;
          s_rresp_q  <= 2'b10; s_rlast_q <= (r_errbeat == 8'd0);
          if (r_errbeat == 8'd0) r_st <= R_IDLE;
          else r_errbeat <= r_errbeat - 8'd1;
        end
        default: r_st <= R_IDLE;
      endcase
    end
  end

  // ================= WRITE =================
  typedef enum logic [2:0] {W_IDLE, W_ADDR, W_TAKE, W_SEND, W_RESP, W_ABSORB, W_ERRB} wst_e;
  wst_e            w_st;
  logic [ID_W-1:0] w_id;
  logic [31:0]     w_addr, w_ptr, w_end;
  logic [7:0]      w_len, w_dslen, w_beats_left;
  logic [2:0]      w_size, w_dssize;
  logic            w_err_seen, w_up_last;
  logic [31:0]             w_upnext;   // first byte of the NEXT upstream beat
  logic [SLV_DATA_W-1:0]   w_hold;
  logic [SLV_DATA_W/8-1:0] w_hstrb;

  assign s_awready = (w_st == W_IDLE);
  assign m_awvalid = (w_st == W_ADDR);
  assign m_awid    = w_id;
  assign m_awaddr  = w_addr;
  assign m_awlen   = w_dslen;
  assign m_awsize  = w_dssize;
  assign m_awburst = 2'b01;
  // L4: a whole upstream beat is taken before any downstream beat of it goes out
  assign s_wready  = (w_st == W_TAKE) || (w_st == W_ABSORB);
  assign m_bready  = (w_st == W_RESP);

  logic                    m_wvalid_q, m_wlast_q;
  logic [MST_DATA_W-1:0]   m_wdata_q;
  logic [MST_DATA_W/8-1:0] m_wstrb_q;
  assign m_wvalid = m_wvalid_q;
  assign m_wlast  = m_wlast_q;
  assign m_wstrb  = m_wstrb_q;
  assign m_wdata  = m_wvalid_q ? m_wdata_q : 16'hBEEF;      // X2

  logic            s_bvalid_q; logic [1:0] s_bresp_q; logic [ID_W-1:0] s_bid_q;
  assign s_bvalid = s_bvalid_q; assign s_bresp = s_bresp_q; assign s_bid = s_bid_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      w_st <= W_IDLE; m_wvalid_q <= 1'b0; s_bvalid_q <= 1'b0; w_err_seen <= 1'b0;
      w_id <= '0; w_addr <= '0; w_ptr <= '0; w_end <= '0; w_len <= '0;
      w_dslen <= '0; w_size <= '0; w_dssize <= '0; w_beats_left <= '0;
      w_hold <= '0; w_hstrb <= '0; w_up_last <= 1'b0; w_upnext <= '0;
      m_wlast_q <= 1'b0; m_wdata_q <= '0; m_wstrb_q <= '0;
      s_bresp_q <= '0; s_bid_q <= '0;
    end else begin
      if (s_bvalid_q && s_bready) s_bvalid_q <= 1'b0;
      if (m_wvalid_q && m_wready) begin m_wvalid_q <= 1'b0; m_wlast_q <= 1'b0; end
      case (w_st)
        W_IDLE: if (s_awvalid) begin
          w_id <= s_awid; w_addr <= s_awaddr; w_len <= s_awlen; w_size <= s_awsize;
          w_err_seen <= 1'b0;
          if (bad_burst(s_awburst, s_awlen)) begin
            w_beats_left <= s_awlen; w_st <= W_ABSORB;       // C4.3: absorb it all
          end else begin
            w_dssize <= ds_size(s_awsize);
            w_dslen  <= ds_len_f(s_awaddr, s_awlen, s_awsize);
            w_ptr    <= s_awaddr;
            w_end    <= s_awaddr + 32'(tot_bytes(s_awaddr, s_awlen, s_awsize));
            w_upnext <= algn(s_awaddr, s_awsize) + 32'(bbytes(s_awsize));
            w_st     <= W_ADDR;
          end
        end
        W_ADDR: if (m_awready) w_st <= W_TAKE;
        W_TAKE: if (s_wvalid) begin
          w_hold <= s_wdata; w_hstrb <= s_wstrb; w_up_last <= s_wlast; w_st <= W_SEND;
        end
        W_SEND: if (!m_wvalid_q) begin
          automatic logic [MST_DATA_W-1:0]   d = '0;
          automatic logic [MST_DATA_W/8-1:0] st = '0;
          automatic logic [31:0] p = w_ptr;
          automatic int unsigned nby;
          for (int b = 0; b < MBYTES; b++) begin
            automatic logic [31:0] a = algn(p, w_dssize) + 32'(b);
            if (a >= p && a < w_end) begin
              d[8*(a % MBYTES) +: 8] = w_hold[8*(a % SBYTES) +: 8];
              st[a % MBYTES]         = w_hstrb[a % SBYTES];   // E2: per byte lane
            end
          end
          nby = int'(algn(p, w_dssize)) + bbytes(w_dssize) - int'(p);
          m_wvalid_q <= 1'b1; m_wdata_q <= d; m_wstrb_q <= st;   // E3: emitted even if st==0
          m_wlast_q  <= (p + 32'(nby) >= w_end);
          w_ptr      <= p + 32'(nby);
          if (p + 32'(nby) >= w_end) w_st <= W_RESP;
          else if (p + 32'(nby) >= w_upnext) begin
            // an UPSTREAM beat is exhausted -- its size, not the bus width
            w_upnext <= w_upnext + 32'(bbytes(w_size));
            w_st <= W_TAKE;
          end
        end
        W_RESP: if (m_bvalid) begin
          s_bvalid_q <= 1'b1; s_bid_q <= w_id;
          s_bresp_q  <= (m_bresp != 2'b00) ? 2'b10 : 2'b00;      // E6
          w_st <= W_IDLE;
        end
        W_ABSORB: if (s_wvalid) begin
          if (s_wlast || w_beats_left == 8'd0) w_st <= W_ERRB;
          else w_beats_left <= w_beats_left - 8'd1;
        end
        W_ERRB: if (!s_bvalid_q) begin
          s_bvalid_q <= 1'b1; s_bid_q <= w_id; s_bresp_q <= 2'b10;  // C4.4
          w_st <= W_IDLE;
        end
        default: w_st <= W_IDLE;
      endcase
    end
  end
endmodule
