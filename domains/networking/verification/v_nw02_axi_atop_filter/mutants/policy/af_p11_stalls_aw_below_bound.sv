// v_nw02 POLICY-DIVERGENT PERTURBATION -- this MUST BE ACCEPTED.
//
// Opposite sign to mutants/: this satisfies the contract and must survive.
//
// It is NOT a wrapper around the golden. It is an independent implementation
// written from spec/atop_filter_spec.md alone, and it takes the OPPOSITE legal
// choice on both named latitude clauses:
//
//   L1  the golden emits the manufactured R beats FIRST and the manufactured B
//       afterwards (measured: R at cycles 5-8, B at cycle 12). This one emits
//       the B FIRST and holds every R beat until the B has been accepted.
//   L2  the golden drives zero on rdata/ruser/buser of a manufactured response.
//       This one drives a non-zero pattern.
//
// A reference testbench that fails this is encoding the golden's implementation
// rather than the contract, and the testbench is what needs fixing.
//
// It also makes different choices where the contract is silent: it does not
// accept a W beat before its AW, and it admits only one atomic write at a time.
module atop_filter #(
  parameter int unsigned ID_W   = 4,
  parameter int unsigned ADDR_W = 32,
  parameter int unsigned DATA_W = 32,
  parameter int unsigned USER_W = 1
) (
  input  logic clk_i, input logic rst_ni,
  input  logic [ID_W-1:0] s_awid_i, input logic [ADDR_W-1:0] s_awaddr_i,
  input  logic [7:0] s_awlen_i, input logic [2:0] s_awsize_i, input logic [1:0] s_awburst_i,
  input  logic s_awlock_i, input logic [3:0] s_awcache_i, input logic [2:0] s_awprot_i,
  input  logic [3:0] s_awqos_i, input logic [3:0] s_awregion_i, input logic [5:0] s_awatop_i,
  input  logic [USER_W-1:0] s_awuser_i, input logic s_awvalid_i, output logic s_awready_o,
  input  logic [DATA_W-1:0] s_wdata_i, input logic [DATA_W/8-1:0] s_wstrb_i,
  input  logic s_wlast_i, input logic [USER_W-1:0] s_wuser_i,
  input  logic s_wvalid_i, output logic s_wready_o,
  output logic [ID_W-1:0] s_bid_o, output logic [1:0] s_bresp_o,
  output logic [USER_W-1:0] s_buser_o, output logic s_bvalid_o, input logic s_bready_i,
  input  logic [ID_W-1:0] s_arid_i, input logic [ADDR_W-1:0] s_araddr_i,
  input  logic [7:0] s_arlen_i, input logic [2:0] s_arsize_i, input logic [1:0] s_arburst_i,
  input  logic s_arlock_i, input logic [3:0] s_arcache_i, input logic [2:0] s_arprot_i,
  input  logic [3:0] s_arqos_i, input logic [3:0] s_arregion_i,
  input  logic [USER_W-1:0] s_aruser_i, input logic s_arvalid_i, output logic s_arready_o,
  output logic [ID_W-1:0] s_rid_o, output logic [DATA_W-1:0] s_rdata_o,
  output logic [1:0] s_rresp_o, output logic s_rlast_o, output logic [USER_W-1:0] s_ruser_o,
  output logic s_rvalid_o, input logic s_rready_i,
  output logic [ID_W-1:0] m_awid_o, output logic [ADDR_W-1:0] m_awaddr_o,
  output logic [7:0] m_awlen_o, output logic [2:0] m_awsize_o, output logic [1:0] m_awburst_o,
  output logic m_awlock_o, output logic [3:0] m_awcache_o, output logic [2:0] m_awprot_o,
  output logic [3:0] m_awqos_o, output logic [3:0] m_awregion_o, output logic [5:0] m_awatop_o,
  output logic [USER_W-1:0] m_awuser_o, output logic m_awvalid_o, input logic m_awready_i,
  output logic [DATA_W-1:0] m_wdata_o, output logic [DATA_W/8-1:0] m_wstrb_o,
  output logic m_wlast_o, output logic [USER_W-1:0] m_wuser_o,
  output logic m_wvalid_o, input logic m_wready_i,
  input  logic [ID_W-1:0] m_bid_i, input logic [1:0] m_bresp_i, input logic [USER_W-1:0] m_buser_i,
  input  logic m_bvalid_i, output logic m_bready_o,
  output logic [ID_W-1:0] m_arid_o, output logic [ADDR_W-1:0] m_araddr_o,
  output logic [7:0] m_arlen_o, output logic [2:0] m_arsize_o, output logic [1:0] m_arburst_o,
  output logic m_arlock_o, output logic [3:0] m_arcache_o, output logic [2:0] m_arprot_o,
  output logic [3:0] m_arqos_o, output logic [3:0] m_arregion_o,
  output logic [USER_W-1:0] m_aruser_o, output logic m_arvalid_o, input logic m_arready_i,
  input  logic [ID_W-1:0] m_rid_i, input logic [DATA_W-1:0] m_rdata_i, input logic [1:0] m_rresp_i,
  input  logic m_rlast_i, input logic [USER_W-1:0] m_ruser_i,
  input  logic m_rvalid_i, output logic m_rready_o
);
  localparam int unsigned MAXW = 4;          // clause W2
  localparam logic [1:0] SLVERR = 2'b10;

  // Write kinds in AW order: 1 = filtered. Drives W routing only.
  logic kq [$];
  int   debt;
  int   atomic_pending;

  logic [ID_W-1:0] cap_id;
  logic [7:0]      cap_len;
  logic            cap_owes_r;
  logic            cap_valid;      // an absorbed atomic write awaiting its responses

  typedef enum logic [1:0] {RSP_IDLE, RSP_B, RSP_R} rsp_e;
  rsp_e rsp;
  logic [8:0] rbeat;
  // ---- MUTANT bookkeeping, on contract-level state only -------------------
  logic [7:0] a_seen_q, a_gap_q, a_full_q;
  wire        a_took = s_awvalid_i && s_awready_o && is_atomic;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin a_seen_q <= '0; a_gap_q <= '0; a_full_q <= '0; end
    else begin
      if (a_took) begin a_seen_q <= a_seen_q + 8'd1; a_gap_q <= '0; end
      else if (a_gap_q != 8'hFF) a_gap_q <= a_gap_q + 8'd1;
      a_full_q <= (debt >= MAXW) ? (a_full_q + 8'd1) : 8'd0;
    end
  end
  // ---- guards for the two W3 re-derivations -------------------------------
  // p11 counts CYCLES of its class, as af_m11 does. p12 counts PRESENTATIONS
  // -- the rising edge -- because af_m12 does: s_awvalid_i is HELD until the AW
  // is accepted, so a cycle ordinal counts how long ONE AW waited rather than
  // how many arrived, and on the anchor that made ordinals 1, 2 and 3
  // indistinguishable. Neither counter reads the defect's own effect.
  wire        b_cls = s_awvalid_i && !is_atomic && (debt < MAXW);
  wire        z_cls = s_awvalid_i && !is_atomic && (debt == 0);
  logic [7:0] b_hit_q, z_hit_q;
  logic       z_cls_q;
  wire        z_pres = z_cls && !z_cls_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin b_hit_q <= '0; z_hit_q <= '0; z_cls_q <= 1'b0; end
    else begin
      z_cls_q <= z_cls;
      if (b_cls)  b_hit_q <= b_hit_q + 8'd1;
      if (z_pres) z_hit_q <= z_hit_q + 8'd1;
    end
  end


  wire is_atomic  = (s_awatop_i[5:4] != 2'b00);
  wire head_valid = (kq.size() > 0);
  wire head_atom  = head_valid && kq[0];

  // ---- AW: forward the ordinary, swallow the atomic ---------------------------
  wire can_fwd_aw = (debt < MAXW) && !(b_cls && (b_hit_q >= 8'd4));
  wire take_atom  = s_awvalid_i && is_atomic && (atomic_pending == 0) && !cap_valid;

  assign m_awid_o = s_awid_i; assign m_awaddr_o = s_awaddr_i; assign m_awlen_o = s_awlen_i;
  assign m_awsize_o = s_awsize_i; assign m_awburst_o = s_awburst_i; assign m_awlock_o = s_awlock_i;
  assign m_awcache_o = s_awcache_i; assign m_awprot_o = s_awprot_i; assign m_awqos_o = s_awqos_i;
  assign m_awregion_o = s_awregion_i; assign m_awuser_o = s_awuser_i;
  assign m_awatop_o  = 6'b000000;                                    // clause F1
  assign m_awvalid_o = s_awvalid_i && !is_atomic && can_fwd_aw;
  assign s_awready_o = is_atomic ? take_atom : (m_awready_i && can_fwd_aw);

  // ---- W: route by the head of the kind queue --------------------------------
  assign m_wdata_o = s_wdata_i; assign m_wstrb_o = s_wstrb_i;
  assign m_wlast_o = s_wlast_i; assign m_wuser_o = s_wuser_i;
  assign m_wvalid_o = s_wvalid_i && head_valid && !head_atom;
  assign s_wready_o = head_valid ? (head_atom ? 1'b1 : m_wready_i) : 1'b0;

  // ---- AR and the read path pass through untouched (clause P3) ---------------
  assign m_arid_o = s_arid_i; assign m_araddr_o = s_araddr_i; assign m_arlen_o = s_arlen_i;
  assign m_arsize_o = s_arsize_i; assign m_arburst_o = s_arburst_i; assign m_arlock_o = s_arlock_i;
  assign m_arcache_o = s_arcache_i; assign m_arprot_o = s_arprot_i; assign m_arqos_o = s_arqos_i;
  assign m_arregion_o = s_arregion_i; assign m_aruser_o = s_aruser_i;
  assign m_arvalid_o = s_arvalid_i; assign s_arready_o = m_arready_i;

  // ---- B: manufactured FIRST, forwarded held meanwhile (clause L1) -----------
  always_comb begin
    if (rsp == RSP_B) begin
      s_bvalid_o = 1'b1; s_bid_o = cap_id; s_bresp_o = SLVERR;
      s_buser_o  = {USER_W{1'b1}};            // clause L2 -- golden drives zero
      m_bready_o = 1'b0;
    end else begin
      s_bvalid_o = m_bvalid_i; s_bid_o = m_bid_i; s_bresp_o = m_bresp_i;
      s_buser_o  = m_buser_i;  m_bready_o = s_bready_i;
    end
  end

  // ---- R: manufactured only AFTER the B has been taken -----------------------
  always_comb begin
    if (rsp == RSP_R) begin
      s_rvalid_o = 1'b1; s_rid_o = cap_id; s_rresp_o = SLVERR;
      s_rlast_o  = (rbeat == 9'd0);
      s_rdata_o  = 32'(DATA_W'(32'hDEAD_BEEF));  // clause L2 -- golden drives zero
      s_ruser_o  = {USER_W{1'b1}};
      m_rready_o = 1'b0;
    end else begin
      s_rvalid_o = m_rvalid_i; s_rid_o = m_rid_i; s_rresp_o = m_rresp_i;
      s_rlast_o  = m_rlast_i;  s_rdata_o = m_rdata_i; s_ruser_o = m_ruser_i;
      m_rready_o = s_rready_i;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      kq.delete(); debt <= 0; atomic_pending <= 0;
      cap_id <= '0; cap_len <= '0; cap_owes_r <= 1'b0; cap_valid <= 1'b0;
      rsp <= RSP_IDLE; rbeat <= '0;
    end else begin
      // accept an AW
      if (s_awvalid_i && s_awready_o) begin
        kq.push_back(is_atomic);
        if (is_atomic) begin
          atomic_pending <= atomic_pending + 1;
          cap_id  <= s_awid_i;
          cap_len <= s_awlen_i;
          cap_owes_r <= s_awatop_i[5];        // clause C2
        end else begin
          debt <= debt + 1;                   // clause W1
        end
      end
      // a W beat moves
      if (s_wvalid_i && s_wready_o) begin
        if (s_wlast_i) begin
          void'(kq.pop_front());
          if (head_atom) begin
            atomic_pending <= atomic_pending - 1;
            cap_valid <= 1'b1;                // its responses are now owed
          end
        end
      end
      if (m_wvalid_o && m_wready_i && m_wlast_o) debt <= debt - 1;   // clause W4

      unique case (rsp)
        RSP_IDLE: if (cap_valid) begin rsp <= RSP_B; rbeat <= 9'(cap_len); end
        RSP_B: if (s_bready_i) begin                     // clause F3, B goes first
          if (cap_owes_r) rsp <= RSP_R;                  // clause F4
          else begin rsp <= RSP_IDLE; cap_valid <= 1'b0; end
        end
        RSP_R: if (s_rready_i) begin
          if (rbeat == 9'd0) begin rsp <= RSP_IDLE; cap_valid <= 1'b0; end
          else rbeat <= rbeat - 9'd1;
        end
        default: rsp <= RSP_IDLE;
      endcase
    end
  end
endmodule
