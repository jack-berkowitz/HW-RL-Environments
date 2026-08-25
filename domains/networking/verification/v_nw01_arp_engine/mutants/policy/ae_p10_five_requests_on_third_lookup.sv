// v_nw01 POLICY-DIVERGENT PERTURBATION -- this MUST BE ACCEPTED.
//
// Opposite sign to mutants/: this satisfies the contract and must survive.
//
// It does NOT instantiate the golden. The protocol engine, the cache and the
// retry logic below are written from spec/arp_engine_spec.md alone. It shares
// the anchor's frame SERIALISER and DESERIALISER, which are mechanical byte
// packing that clause F fixes completely and that carries none of the
// contract's substance -- said plainly rather than claimed as full
// independence.
//
// It takes the OPPOSITE choice on the named latitude clauses:
//
//   L1  the golden's cache is DIRECT MAPPED by a hash of the address, so which
//       entry an insert displaces depends on that hash. This one is FULLY
//       ASSOCIATIVE with round-robin replacement, so a different set of older
//       entries survives.
//   L2  drives a recognisable pattern on resp_mac_o when resp_error_o is high,
//       where the golden leaves whatever it last held.
//   L3  different timing throughout: a cache hit is answered the cycle after
//       the lookup, and retries go out on a different phase inside the window
//       clause Q4 allows.
module arp_engine (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        s_hdr_valid_i,
  output logic        s_hdr_ready_o,
  input  logic [47:0] s_dest_mac_i,
  input  logic [47:0] s_src_mac_i,
  input  logic [15:0] s_eth_type_i,
  input  logic [7:0]  s_payload_data_i,
  input  logic        s_payload_valid_i,
  output logic        s_payload_ready_o,
  input  logic        s_payload_last_i,
  input  logic        s_payload_user_i,
  output logic        m_hdr_valid_o,
  input  logic        m_hdr_ready_i,
  output logic [47:0] m_dest_mac_o,
  output logic [47:0] m_src_mac_o,
  output logic [15:0] m_eth_type_o,
  output logic [7:0]  m_payload_data_o,
  output logic        m_payload_valid_o,
  input  logic        m_payload_ready_i,
  output logic        m_payload_last_o,
  output logic        m_payload_user_o,
  input  logic        req_valid_i,
  output logic        req_ready_o,
  input  logic [31:0] req_ip_i,
  output logic        resp_valid_o,
  input  logic        resp_ready_i,
  output logic        resp_error_o,
  output logic [47:0] resp_mac_o,
  input  logic [47:0] local_mac_i,
  input  logic [31:0] local_ip_i,
  input  logic [31:0] gateway_ip_i,
  input  logic [31:0] subnet_mask_i,
  input  logic        clear_cache_i
);
  localparam int RETRIES  = 4;
  localparam int INTERVAL = 70;    // inside Q4's 64..80 window, and not the golden's phase
  localparam int TIMEOUT  = 270;   // inside Q5's 256..300 window

  // ---- frame deserialiser (shared; clause F is mechanical) -----------------
  logic        rx_valid, rx_ready;
  logic [47:0] rx_dest_mac, rx_src_mac; logic [15:0] rx_eth_type;
  logic [15:0] rx_htype, rx_ptype, rx_oper; logic [7:0] rx_hlen, rx_plen;
  logic [47:0] rx_sha, rx_tha; logic [31:0] rx_spa, rx_tpa;

  arp_eth_rx #(.DATA_WIDTH(8), .KEEP_ENABLE(0), .KEEP_WIDTH(1)) i_rx (
    .clk(clk_i), .rst(rst_i),
    .s_eth_hdr_valid(s_hdr_valid_i), .s_eth_hdr_ready(s_hdr_ready_o),
    .s_eth_dest_mac(s_dest_mac_i), .s_eth_src_mac(s_src_mac_i), .s_eth_type(s_eth_type_i),
    .s_eth_payload_axis_tdata(s_payload_data_i), .s_eth_payload_axis_tkeep(1'b1),
    .s_eth_payload_axis_tvalid(s_payload_valid_i),
    .s_eth_payload_axis_tready(s_payload_ready_o),
    .s_eth_payload_axis_tlast(s_payload_last_i), .s_eth_payload_axis_tuser(s_payload_user_i),
    .m_frame_valid(rx_valid), .m_frame_ready(rx_ready),
    .m_eth_dest_mac(rx_dest_mac), .m_eth_src_mac(rx_src_mac), .m_eth_type(rx_eth_type),
    .m_arp_htype(rx_htype), .m_arp_ptype(rx_ptype), .m_arp_hlen(rx_hlen),
    .m_arp_plen(rx_plen), .m_arp_oper(rx_oper), .m_arp_sha(rx_sha), .m_arp_spa(rx_spa),
    .m_arp_tha(rx_tha), .m_arp_tpa(rx_tpa),
    .busy(), .error_header_early_termination(), .error_invalid_header());

  // ---- frame serialiser (shared) ------------------------------------------
  logic        tx_valid, tx_ready;
  logic [47:0] tx_dest_mac; logic [15:0] tx_oper;
  logic [47:0] tx_tha; logic [31:0] tx_tpa;

  arp_eth_tx #(.DATA_WIDTH(8), .KEEP_ENABLE(0), .KEEP_WIDTH(1)) i_tx (
    .clk(clk_i), .rst(rst_i),
    .s_frame_valid(tx_valid), .s_frame_ready(tx_ready),
    .s_eth_dest_mac(tx_dest_mac), .s_eth_src_mac(local_mac_i), .s_eth_type(16'h0806),
    .s_arp_htype(16'h0001), .s_arp_ptype(16'h0800), .s_arp_oper(tx_oper),
    .s_arp_sha(local_mac_i), .s_arp_spa(local_ip_i), .s_arp_tha(tx_tha), .s_arp_tpa(tx_tpa),
    .m_eth_hdr_valid(m_hdr_valid_o), .m_eth_hdr_ready(m_hdr_ready_i),
    .m_eth_dest_mac(m_dest_mac_o), .m_eth_src_mac(m_src_mac_o), .m_eth_type(m_eth_type_o),
    .m_eth_payload_axis_tdata(m_payload_data_o), .m_eth_payload_axis_tkeep(),
    .m_eth_payload_axis_tvalid(m_payload_valid_o),
    .m_eth_payload_axis_tready(m_payload_ready_i),
    .m_eth_payload_axis_tlast(m_payload_last_o), .m_eth_payload_axis_tuser(m_payload_user_o),
    .busy());

  // ---- the cache: FULLY ASSOCIATIVE, round-robin replacement (clause L1) ---
  logic [31:0] c_ip  [4];
  logic [47:0] c_mac [4];
  logic [3:0]  c_val;
  logic [1:0]  c_rr;

  function automatic int lookup_idx(input logic [31:0] ip);
    for (int i = 0; i < 4; i++) if (c_val[i] && c_ip[i] == ip) return i;
    return -1;
  endfunction

  // ---- the engine ----------------------------------------------------------
  typedef enum logic [2:0] {IDLE, HIT, ASK, WAIT, ANSWER, REPLY} st_e;
  st_e st;
  logic [31:0] want_ip, ask_ip;
  logic [47:0] got_mac;
  logic        got_err;
  int          timer, tries;
  logic [47:0] pend_sha; logic [31:0] pend_spa;

  // ---- mutant guard state: contract-level only ----------------------------
  // The SAME quantities the golden-base defects count, recomputed from this
  // implementation's own ports.
  int   g_lookup_q, g_timeout_q, g_rx_q, g_occ_q, g_att_q;
  logic g_out_q;
  // A clear that only counts once it has taken effect: resetting the occupancy
  // on the first cycle of the pulse would let the rest of the pulse through.
  wire  g_clr_eff = clear_cache_i && !(g_occ_q >= 4);
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      g_lookup_q <= 0; g_timeout_q <= 0; g_rx_q <= 0; g_occ_q <= 0;
      g_att_q <= 0; g_out_q <= 1'b0;
    end else begin
      if (clear_cache_i)                       g_rx_q  <= 0;
      else if (s_hdr_valid_i && s_hdr_ready_o) g_rx_q  <= g_rx_q + 1;
      if (g_clr_eff)                           g_occ_q <= 0;
      else if (s_hdr_valid_i && s_hdr_ready_o) g_occ_q <= g_occ_q + 1;
      if (m_hdr_valid_o && m_hdr_ready_i && g_out_q) g_att_q <= g_att_q + 1;
      if (req_valid_i && req_ready_o) begin
        g_lookup_q <= g_lookup_q + 1; g_out_q <= 1'b1; g_att_q <= 0;
      end
      if (resp_valid_o && resp_ready_i) begin
        g_out_q <= 1'b0;
        if (resp_error_o) g_timeout_q <= g_timeout_q + 1;
      end
    end
  end

  wire arp_ok = rx_valid && rx_eth_type == 16'h0806
                && rx_htype == 16'h0001 && rx_ptype == 16'h0800;   // clause A3
  wire in_subnet = (req_ip_i & subnet_mask_i) == (local_ip_i & subnet_mask_i);

  assign req_ready_o  = (st == IDLE);
  assign resp_valid_o = (st == ANSWER);
  assign resp_error_o = got_err;
  // clause L2 -- nothing is required of this when the error bit is set
  assign resp_mac_o   = got_err ? 48'hBAD0_BAD0_BAD0 : got_mac;
  assign rx_ready     = (st != REPLY);

  assign tx_valid    = (st == ASK) || (st == REPLY);
  assign tx_oper     = (st == REPLY) ? 16'd2 : 16'd1;
  assign tx_dest_mac = (st == REPLY) ? pend_sha : 48'hFF_FF_FF_FF_FF_FF;
  assign tx_tha      = (st == REPLY) ? pend_sha : 48'd0;
  assign tx_tpa      = (st == REPLY) ? pend_spa : ask_ip;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      st <= IDLE; c_val <= '0; c_rr <= '0; timer <= 0; tries <= 0;
      got_err <= 1'b0; got_mac <= '0;
    end else begin
      if (clear_cache_i) c_val <= '0;                       // clause C3

      // learn from every ARP frame, whatever its operation (clause C1)
      if (arp_ok && rx_ready) begin
        automatic int hit = lookup_idx(rx_spa);
        if (hit >= 0) c_mac[hit] <= rx_sha;
        else begin
          c_ip[c_rr] <= rx_spa; c_mac[c_rr] <= rx_sha; c_val[c_rr] <= 1'b1;
          c_rr <= c_rr + 2'd1;                              // round robin (L1)
        end
        // resolve an outstanding lookup (clause Q6)
        if (st == WAIT && rx_oper == 16'd2 && rx_spa == ask_ip) begin
          got_mac <= rx_sha; got_err <= 1'b0; st <= ANSWER;
        end
        // answer a request aimed at us (clause A1); ignore others (A2)
        if (rx_oper == 16'd1 && rx_tpa == local_ip_i) begin
          pend_sha <= rx_sha; pend_spa <= rx_spa; st <= REPLY;
        end
      end

      unique case (st)
        IDLE: if (req_valid_i) begin
          automatic int hit = lookup_idx(req_ip_i);
          want_ip <= req_ip_i;
          ask_ip  <= in_subnet ? req_ip_i : gateway_ip_i;   // clause Q3
          if (hit >= 0) begin
            got_mac <= c_mac[hit]; got_err <= 1'b0; st <= HIT;
          end else begin
            tries <= 0; st <= ASK;
          end
        end
        HIT: st <= ANSWER;                                  // answered next cycle (L3)
        ASK: if (tx_ready) begin
          tries <= tries + 1;
          timer <= (tries + 1 >= (RETRIES + ((g_lookup_q >= 3) ? 1 : 0))) ? TIMEOUT : INTERVAL;
          st <= WAIT;
        end
        WAIT: begin
          if (timer > 0) timer <= timer - 1;
          else if (tries < (RETRIES + ((g_lookup_q >= 3) ? 1 : 0))) st <= ASK;
          else begin got_err <= 1'b1; st <= ANSWER; end     // clause Q5
        end
        ANSWER: if (resp_ready_i) st <= IDLE;
        REPLY:  if (tx_ready) st <= IDLE;
        default: st <= IDLE;
      endcase
    end
  end
endmodule
