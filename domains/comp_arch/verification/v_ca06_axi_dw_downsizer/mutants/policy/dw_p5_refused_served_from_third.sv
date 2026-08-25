// step 5c: dw_m5_refused_served_from_third re-derived on the policy-divergent implementation.

// --------------------------------------------------------------------------
// dw_m5_refused_served_from_third -- violates C4
//   defect: a refused burst is SERVED instead: it issues a downstream transaction and answers OKAY
//   guard : fires only when the third refused burst and every one after it -- the first two are refused correctly
// --------------------------------------------------------------------------
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
  // ---- guard state: contract-level only -----------------------------------
  // Every quantity is counted from this module's PORTS -- transactions
  // accepted, refusals, FIXED single-beat requests, beat indices, downstream
  // beats forwarded. Nothing inside the golden is read.
  localparam int SBY = SLV_DATA_W/8, MBY = MST_DATA_W/8, MSZ = 1;
  function automatic logic [31:0] algn(input logic [31:0] a, input logic [2:0] sz);
    algn = a & ~((32'd1 << sz) - 32'd1);
  endfunction
  function automatic bit is_ref(input logic [1:0] b, input logic [7:0] l);
    is_ref = (b == 2'b10) || ((b == 2'b00) && (l != 8'd0));
  endfunction

  // g_dwbeat is the index WITHIN the current downstream burst and resets with
  // each AW. g_dwtot is CUMULATIVE since reset. A guard that wants "every
  // thirty-second beat delivered" needs the cumulative one: the per-burst index
  // never reaches 31 unless a single burst is that long, and it never is here.
  int g_nread, g_nwrite, g_nref, g_nfix1, g_rbeat, g_dwbeat, g_dwtot, g_upwbeat;
  logic [1:0] g_rburst, g_wburst;
  logic [7:0] g_rlen,  g_wlen;
  logic [2:0] g_rsize, g_wsize;
  logic [31:0] g_raddr, g_waddr;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      g_nread<=0; g_nwrite<=0; g_nref<=0; g_nfix1<=0; g_rbeat<=0; g_dwbeat<=0; g_dwtot<=0;
      g_upwbeat<=0; g_rburst<='0; g_wburst<='0; g_rlen<='0; g_wlen<='0;
      g_rsize<='0; g_wsize<='0; g_raddr<='0; g_waddr<='0;
    end else begin
      if (s_arvalid && s_arready) begin
        g_nread<=g_nread+1; g_rbeat<=0;
        g_rburst<=s_arburst; g_rlen<=s_arlen; g_rsize<=s_arsize; g_raddr<=s_araddr;
        if (is_ref(s_arburst, s_arlen)) g_nref<=g_nref+1;
        if (s_arburst==2'b00 && s_arlen==8'd0) g_nfix1<=g_nfix1+1;
      end
      if (s_awvalid && s_awready) begin
        g_nwrite<=g_nwrite+1; g_dwbeat<=0; g_upwbeat<=0;
        g_wburst<=s_awburst; g_wlen<=s_awlen; g_wsize<=s_awsize; g_waddr<=s_awaddr;
        if (is_ref(s_awburst, s_awlen)) g_nref<=g_nref+1;
        if (s_awburst==2'b00 && s_awlen==8'd0) g_nfix1<=g_nfix1+1;
      end
      if (s_rvalid && s_rready) g_rbeat <= s_rlast ? 0 : g_rbeat + 1;
      if (m_wvalid && m_wready) begin g_dwbeat <= g_dwbeat + 1; g_dwtot <= g_dwtot + 1; end
      if (s_wvalid && s_wready) g_upwbeat <= s_wlast ? 0 : g_upwbeat + 1;
    end
  end

  wire ar_r = is_ref(s_arburst, s_arlen) && (g_nref >= 2);
  wire aw_r = is_ref(s_awburst, s_awlen) && (g_nref >= 2);


  dw_downsizer_alt #(.ADDR_W(ADDR_W), .ID_W(ID_W), .SLV_DATA_W(SLV_DATA_W),
                 .MST_DATA_W(MST_DATA_W), .MAX_READS(MAX_READS)) i_g (
    .clk_i, .rst_ni,
    .s_awid(s_awid),
    .s_awaddr(s_awaddr),
    .s_awlen(s_awlen),
    .s_awsize(s_awsize),
    .s_awburst(aw_r ? 2'b01 : s_awburst),
    .s_awvalid(s_awvalid),
    .s_awready(s_awready),
    .s_wdata(s_wdata),
    .s_wstrb(s_wstrb),
    .s_wlast(s_wlast),
    .s_wvalid(s_wvalid),
    .s_wready(s_wready),
    .s_bid(s_bid),
    .s_bresp(s_bresp),
    .s_bvalid(s_bvalid),
    .s_bready(s_bready),
    .s_arid(s_arid),
    .s_araddr(s_araddr),
    .s_arlen(s_arlen),
    .s_arsize(s_arsize),
    .s_arburst(ar_r ? 2'b01 : s_arburst),
    .s_arvalid(s_arvalid),
    .s_arready(s_arready),
    .s_rid(s_rid),
    .s_rdata(s_rdata),
    .s_rresp(s_rresp),
    .s_rlast(s_rlast),
    .s_rvalid(s_rvalid),
    .s_rready(s_rready),
    .m_awid(m_awid),
    .m_awaddr(m_awaddr),
    .m_awlen(m_awlen),
    .m_awsize(m_awsize),
    .m_awburst(m_awburst),
    .m_awvalid(m_awvalid),
    .m_awready(m_awready),
    .m_wdata(m_wdata),
    .m_wstrb(m_wstrb),
    .m_wlast(m_wlast),
    .m_wvalid(m_wvalid),
    .m_wready(m_wready),
    .m_bid(m_bid),
    .m_bresp(m_bresp),
    .m_bvalid(m_bvalid),
    .m_bready(m_bready),
    .m_arid(m_arid),
    .m_araddr(m_araddr),
    .m_arlen(m_arlen),
    .m_arsize(m_arsize),
    .m_arburst(m_arburst),
    .m_arvalid(m_arvalid),
    .m_arready(m_arready),
    .m_rid(m_rid),
    .m_rdata(m_rdata),
    .m_rresp(m_rresp),
    .m_rlast(m_rlast),
    .m_rvalid(m_rvalid),
    .m_rready(m_rready)
  );
endmodule
