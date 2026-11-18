// Non-blocking write-back, write-allocate data cache.
// See header comments in the body for the allocation/scheduling scheme.

module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,   // {32, 64}
  parameter int unsigned SETS       = 16,   // {8, 16}
  parameter int unsigned WAYS       = 4,    // {2, 4}
  parameter int unsigned MAX_MISSES = 8     // {2, 8}
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,        // active low, asynchronous assert

  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,
  input  logic                     req_op_i,       // 0 = LOAD, 1 = STORE
  input  logic [31:0]              req_addr_i,     // byte address, word aligned
  input  logic [DATA_W-1:0]        req_data_i,
  input  logic [(DATA_W/8)-1:0]    req_mask_i,

  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,
  output logic [31:0]              mem_req_addr_o,

  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  // --------------------------------------------------------------------------
  // Local parameters
  // --------------------------------------------------------------------------
  localparam int unsigned BLOCK_WORDS = 4;                 // fixed by contract
  localparam int unsigned BYTE_BITS   = $clog2(DATA_W/8);  // 2 or 3
  localparam int unsigned BO_BITS     = $clog2(BLOCK_WORDS) + BYTE_BITS;
  localparam int unsigned SET_B       = $clog2(SETS);
  localparam int unsigned TAG_BITS    = 32 - BO_BITS - SET_B;
  localparam int unsigned LINE_BITS   = 32 - BO_BITS;      // tag + set
  localparam int unsigned WORD_B      = $clog2(BLOCK_WORDS);
  localparam int unsigned WAY_B       = $clog2(WAYS);
  localparam int unsigned NW          = MAX_MISSES;        // miss registers
  localparam int unsigned MS_B        = $clog2(NW);
  localparam int unsigned RSP_D       = 4;                 // response FIFO depth
  localparam int unsigned FIFO_B      = $clog2(RSP_D);
  localparam int unsigned CNT_B       = $clog2(RSP_D+1);

  // --------------------------------------------------------------------------
  // Byte merge helper
  // --------------------------------------------------------------------------
  function automatic logic [DATA_W-1:0] merge_bytes(
    input logic [DATA_W-1:0]     s,
    input logic [DATA_W-1:0]     d,
    input logic [(DATA_W/8)-1:0] m
  );
    logic [DATA_W-1:0] ext;
    for (int b = 0; b < DATA_W/8; b++)
      ext[8*b +: 8] = {8{m[b]}};
    return (s & ext) | (d & ~ext);
  endfunction

  // --------------------------------------------------------------------------
  // Tag / data arrays
  // --------------------------------------------------------------------------
  logic [SETS-1:0][WAYS-1:0]                               tag_vld_q;
  logic [SETS-1:0][WAYS-1:0]                               tag_dirty_q;
  logic [SETS-1:0][WAYS-1:0][TAG_BITS-1:0]                 tag_q;
  logic [SETS-1:0][WAYS-1:0][BLOCK_WORDS-1:0][DATA_W-1:0]  data_q;

  // --------------------------------------------------------------------------
  // Miss registers (MSHR file). Per pending miss: line address, one pending
  // load (id+word) and ONE merged store word (word+data+mask). No line data.
  // --------------------------------------------------------------------------
  logic [NW-1:0]                 mshr_vld_q;
  logic [NW-1:0][LINE_BITS-1:0]  mshr_line_q;
  logic [NW-1:0]                 mshr_hld_q;   // pending load
  logic [NW-1:0][3:0]            mshr_lid_q;
  logic [NW-1:0][WORD_B-1:0]     mshr_lwd_q;
  logic [NW-1:0]                 mshr_hst_q;   // pending merged store word
  logic [NW-1:0][WORD_B-1:0]     mshr_swd_q;
  logic [NW-1:0][DATA_W-1:0]    mshr_sd_q;
  logic [NW-1:0][(DATA_W/8)-1:0] mshr_sm_q;

  // --------------------------------------------------------------------------
  // Memory-side FSM. Victim is chosen only AFTER the fill data has arrived,
  // so an unserved fill never puts any resident line "on death row".
  // --------------------------------------------------------------------------
  typedef enum logic [2:0] {
    ST_IDLE, ST_FILL_REQ, ST_FILL_DATA, ST_EVAL, ST_WB_REQ, ST_WB_DATA, ST_INSTALL
  } state_e;
  state_e                state_q;

  logic [MS_B-1:0]       srv_ms_q;     // miss register being serviced
  logic [SET_B-1:0]      srv_set_q;
  logic [WAY_B-1:0]      srv_way_q;    // victim way (latched at ST_EVAL)
  logic [TAG_BITS-1:0]   srv_tag_q;    // victim tag  (latched at ST_EVAL)
  logic [WORD_B-1:0]     beat_q;
  logic [BLOCK_WORDS-1:0][DATA_W-1:0] fill_q;   // the ONE fill buffer line
  logic [SETS-1:0][WAY_B-1:0] rr_q;             // per-set round-robin
  logic [MS_B-1:0]       ptr_q;        // fair service pointer

  // --------------------------------------------------------------------------
  // Response FIFO (registered valid -> R1b clean)
  // --------------------------------------------------------------------------
  logic [3:0]        fifo_id_q  [RSP_D];
  logic [DATA_W-1:0] fifo_dat_q [RSP_D];
  logic [FIFO_B-1:0] fhead_q, ftail_q;
  logic [CNT_B-1:0]  fuse_q;

  // --------------------------------------------------------------------------
  // Request decode
  // --------------------------------------------------------------------------
  logic [SET_B-1:0]    r_set;
  logic [TAG_BITS-1:0] r_tag;
  logic [WORD_B-1:0]   r_wrd;
  logic [LINE_BITS-1:0] r_line;
  assign r_set  = req_addr_i[BO_BITS +: SET_B];
  assign r_tag  = req_addr_i[31 -: TAG_BITS];
  assign r_wrd  = req_addr_i[BYTE_BITS +: WORD_B];
  assign r_line = req_addr_i[31 -: LINE_BITS];

  // --------------------------------------------------------------------------
  // Hit lookup
  // --------------------------------------------------------------------------
  logic [WAYS-1:0] hit_v;
  logic            hit;
  logic [WAY_B-1:0] hit_way;
  always_comb begin
    for (int w = 0; w < WAYS; w++)
      hit_v[w] = tag_vld_q[r_set][w] && (tag_q[r_set][w] == r_tag);
  end
  always_comb begin
    hit     = |hit_v;
    hit_way = '0;
    for (int w = WAYS-1; w >= 0; w--)
      if (hit_v[w]) hit_way = WAY_B'(w);
  end

  // --------------------------------------------------------------------------
  // Miss register match / free slot
  // --------------------------------------------------------------------------
  logic [NW-1:0]   m_match_v;
  logic            m_hit;
  logic [MS_B-1:0] m_hit_idx;
  always_comb begin
    for (int i = 0; i < NW; i++)
      m_match_v[i] = mshr_vld_q[i] && (mshr_line_q[i] == r_line);
  end
  always_comb begin
    m_hit     = |m_match_v;
    m_hit_idx = '0;
    for (int i = NW-1; i >= 0; i--)
      if (m_match_v[i]) m_hit_idx = MS_B'(i);
  end
  logic            has_free;
  logic [MS_B-1:0] free_idx;
  always_comb begin
    has_free  = 1'b0;
    free_idx  = '0;
    for (int i = NW-1; i >= 0; i--)
      if (!mshr_vld_q[i]) begin
        has_free = 1'b1;
        free_idx = MS_B'(i);
      end
  end

  // --------------------------------------------------------------------------
  // Fair (round-robin) miss service pick
  // --------------------------------------------------------------------------
  logic            srv_avail;
  logic [MS_B-1:0] srv_pick;
  always_comb begin
    srv_avail = 1'b0;
    srv_pick  = '0;
    for (int i = NW-1; i >= 0; i--)
      if ((i >= int'(ptr_q)) && mshr_vld_q[i]) begin
        srv_avail = 1'b1;
        srv_pick  = MS_B'(i);
      end
    if (!srv_avail)
      for (int i = NW-1; i >= 0; i--)
        if ((i < int'(ptr_q)) && mshr_vld_q[i]) begin
          srv_avail = 1'b1;
          srv_pick  = MS_B'(i);
        end
  end

  // --------------------------------------------------------------------------
  // Victim selection (used in ST_EVAL, i.e. after fill data arrived)
  // --------------------------------------------------------------------------
  logic [WAYS-1:0] ev_inv_v;
  logic            vic_dirty;
  logic [WAY_B-1:0] vic_way;
  always_comb begin
    for (int w = 0; w < WAYS; w++)
      ev_inv_v[w] = !tag_vld_q[srv_set_q][w];
    vic_way   = '0;
    vic_dirty = 1'b0;
    if (|ev_inv_v) begin
      for (int w = WAYS-1; w >= 0; w--)
        if (ev_inv_v[w]) vic_way = WAY_B'(w);
    end else begin
      vic_way   = rr_q[srv_set_q];
      vic_dirty = tag_dirty_q[srv_set_q][rr_q[srv_set_q]];
    end
  end

  // --------------------------------------------------------------------------
  // "Doomed way" window: from victim selection (ST_EVAL) through install.
  // Stores hitting this way are redirected into a miss register so they are
  // never lost; loads of the victim line still hit the array (correct data).
  // --------------------------------------------------------------------------
  logic            doomed;
  logic [WAY_B-1:0] dway;
  always_comb begin
    doomed = (state_q == ST_EVAL)   || (state_q == ST_WB_REQ) ||
             (state_q == ST_WB_DATA) || (state_q == ST_INSTALL);
    dway   = (state_q == ST_EVAL) ? vic_way : srv_way_q;
  end
  logic redir_store;
  assign redir_store = doomed && req_op_i && hit &&
                       (hit_way == dway) && (r_set == srv_set_q);

  // --------------------------------------------------------------------------
  // Response channel
  // --------------------------------------------------------------------------
  assign rsp_valid_o = (fuse_q != '0);
  assign rsp_id_o    = fifo_id_q[fhead_q];
  assign rsp_data_o  = fifo_dat_q[fhead_q];

  logic deq_go;
  assign deq_go = rsp_valid_o && rsp_ready_i;

  logic room;
  assign room = (fuse_q < CNT_B'(RSP_D)) || deq_go;

  logic install_go;
  assign install_go = (state_q == ST_INSTALL) &&
                      (!mshr_hld_q[srv_ms_q] || room);

  // data returned to the attached load at install time
  logic [DATA_W-1:0] inst_rsp_dat;
  always_comb begin
    if (mshr_hst_q[srv_ms_q] && (mshr_swd_q[srv_ms_q] == mshr_lwd_q[srv_ms_q]))
      inst_rsp_dat = merge_bytes(mshr_sd_q[srv_ms_q],
                                 fill_q[mshr_lwd_q[srv_ms_q]],
                                 mshr_sm_q[srv_ms_q]);
    else
      inst_rsp_dat = fill_q[mshr_lwd_q[srv_ms_q]];
  end

  // --------------------------------------------------------------------------
  // Acceptance decision (combinational; req_ready may depend on anything
  // except that rsp_valid must not depend on rsp_ready - it does not).
  // --------------------------------------------------------------------------
  logic req_rdy;
  always_comb begin
    req_rdy = 1'b0;
    if (!install_go) begin
      if (m_hit) begin
        if (!req_op_i)
          // load to a line with a pending miss: attach if slot free
          req_rdy = !mshr_hld_q[m_hit_idx];
        else
          // store: needs a response slot; must not overtake a pending load
          // of the same word (same-address ordering); one merged word max.
          req_rdy = room
                 && !(mshr_hld_q[m_hit_idx] && (mshr_lwd_q[m_hit_idx] == r_wrd))
                 && (!mshr_hst_q[m_hit_idx] || (mshr_swd_q[m_hit_idx] == r_wrd));
      end else if (hit && !redir_store) begin
        // genuine hit
        req_rdy = room;
      end else begin
        // miss (or a store hitting the doomed victim way -> treated as miss)
        if (!req_op_i)
          req_rdy = has_free;
        else
          req_rdy = has_free && room;
      end
    end
  end
  assign req_ready_o = req_rdy;

  logic req_fire;
  assign req_fire = req_valid_i && req_rdy;

  // --------------------------------------------------------------------------
  // Response FIFO enqueue source (at most one enqueue per cycle by construction)
  // --------------------------------------------------------------------------
  logic req_fire_enq;
  assign req_fire_enq = req_fire &&
                        (req_op_i || (!m_hit && hit && !redir_store));

  logic            enq_go;
  logic [3:0]      enq_id;
  logic [DATA_W-1:0] enq_dat;
  always_comb begin
    if (install_go && mshr_hld_q[srv_ms_q]) begin
      enq_go = 1'b1;
      enq_id = mshr_lid_q[srv_ms_q];
      enq_dat = inst_rsp_dat;
    end else begin
      enq_go = req_fire_enq;
      enq_id = req_id_i;
      enq_dat = req_op_i ? '0 : data_q[r_set][hit_way][r_wrd];
    end
  end

  // --------------------------------------------------------------------------
  // Memory port
  // --------------------------------------------------------------------------
  assign mem_req_valid_o = (state_q == ST_FILL_REQ) || (state_q == ST_WB_REQ);
  assign mem_req_we_o    = (state_q == ST_WB_REQ);
  assign mem_req_addr_o  = (state_q == ST_WB_REQ)
                         ? {srv_tag_q, srv_set_q, {BO_BITS{1'b0}}}
                         : {mshr_line_q[srv_ms_q], {BO_BITS{1'b0}}};
  assign mem_wr_valid_o  = (state_q == ST_WB_DATA);
  assign mem_wr_data_o   = data_q[srv_set_q][srv_way_q][beat_q];
  assign mem_rd_ready_o  = (state_q == ST_FILL_DATA);

  // --------------------------------------------------------------------------
  // Sequential core
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tag_vld_q   <= '0;
      tag_dirty_q <= '0;
      mshr_vld_q  <= '0;
      mshr_hld_q  <= '0;
      mshr_hst_q  <= '0;
      state_q     <= ST_IDLE;
      fuse_q      <= '0;
      fhead_q     <= '0;
      ftail_q     <= '0;
      ptr_q       <= '0;
      rr_q        <= '0;
      beat_q      <= '0;
    end else begin

      // ---------------- response FIFO ----------------
      if (enq_go && !deq_go)      fuse_q <= fuse_q + 1'b1;
      else if (!enq_go && deq_go) fuse_q <= fuse_q - 1'b1;
      if (deq_go) fhead_q <= fhead_q + 1'b1;
      if (enq_go) begin
        fifo_id_q[ftail_q]  <= enq_id;
        fifo_dat_q[ftail_q] <= enq_dat;
        ftail_q <= ftail_q + 1'b1;
      end

      // ---------------- request acceptance ----------------
      if (req_fire) begin
        if (!m_hit && hit && !redir_store) begin
          // genuine hit
          if (req_op_i) begin
            data_q[r_set][hit_way][r_wrd] <= merge_bytes(req_data_i,
                                                         data_q[r_set][hit_way][r_wrd],
                                                         req_mask_i);
            tag_dirty_q[r_set][hit_way]   <= 1'b1;
          end
        end else if (m_hit) begin
          // line has a pending miss
          if (req_op_i) begin
            if (!mshr_hst_q[m_hit_idx]) begin
              mshr_hst_q[m_hit_idx] <= 1'b1;
              mshr_swd_q[m_hit_idx] <= r_wrd;
              mshr_sd_q[m_hit_idx]  <= req_data_i;
              mshr_sm_q[m_hit_idx]  <= req_mask_i;
            end else begin
              mshr_sd_q[m_hit_idx] <= merge_bytes(req_data_i,
                                                  mshr_sd_q[m_hit_idx],
                                                  mshr_sm_q[m_hit_idx]);
              mshr_sm_q[m_hit_idx] <= mshr_sm_q[m_hit_idx] | req_mask_i;
            end
          end else begin
            mshr_hld_q[m_hit_idx] <= 1'b1;
            mshr_lid_q[m_hit_idx] <= req_id_i;
            mshr_lwd_q[m_hit_idx] <= r_wrd;
          end
        end else begin
          // allocate a miss register (also used for redirected victim stores)
          mshr_vld_q[free_idx] <= 1'b1;
          mshr_line_q[free_idx] <= r_line;
          mshr_hld_q[free_idx]  <= !req_op_i;
          mshr_lid_q[free_idx]  <= req_id_i;
          mshr_lwd_q[free_idx]  <= r_wrd;
          mshr_hst_q[free_idx]  <= req_op_i;
          mshr_swd_q[free_idx]  <= r_wrd;
          mshr_sd_q[free_idx]   <= req_data_i;
          mshr_sm_q[free_idx]   <= req_mask_i;
        end
      end

      // ---------------- FSM ----------------
      case (state_q)
        ST_IDLE: begin
          if (srv_avail) begin
            srv_ms_q  <= srv_pick;
            srv_set_q <= mshr_line_q[srv_pick][SET_B-1:0];
            state_q   <= ST_FILL_REQ;
          end
        end
        ST_FILL_REQ: begin
          if (mem_req_ready_i) begin
            beat_q  <= '0;
            state_q <= ST_FILL_DATA;
          end
        end
        ST_FILL_DATA: begin
          if (mem_rd_valid_i) begin
            fill_q[beat_q] <= mem_rd_data_i;
            if (beat_q == WORD_B'(BLOCK_WORDS-1))
              state_q <= ST_EVAL;
            else
              beat_q <= beat_q + 1'b1;
          end
        end
        ST_EVAL: begin
          srv_way_q <= vic_way;
          srv_tag_q <= tag_q[srv_set_q][vic_way];
          state_q   <= vic_dirty ? ST_WB_REQ : ST_INSTALL;
          if (rr_q[srv_set_q] == WAY_B'(WAYS-1))
            rr_q[srv_set_q] <= '0;
          else
            rr_q[srv_set_q] <= rr_q[srv_set_q] + 1'b1;
        end
        ST_WB_REQ: begin
          if (mem_req_ready_i) begin
            beat_q  <= '0;
            state_q <= ST_WB_DATA;
          end
        end
        ST_WB_DATA: begin
          if (mem_wr_ready_i) begin
            if (beat_q == WORD_B'(BLOCK_WORDS-1))
              state_q <= ST_INSTALL;
            else
              beat_q <= beat_q + 1'b1;
          end
        end
        ST_INSTALL: begin
          if (install_go) begin
            tag_q[srv_set_q][srv_way_q]       <= mshr_line_q[srv_ms_q][LINE_BITS-1:SET_B];
            tag_vld_q[srv_set_q][srv_way_q]   <= 1'b1;
            tag_dirty_q[srv_set_q][srv_way_q] <= mshr_hst_q[srv_ms_q];
            for (int k = 0; k < BLOCK_WORDS; k++) begin
              if (mshr_hst_q[srv_ms_q] && (mshr_swd_q[srv_ms_q] == WORD_B'(k)))
                data_q[srv_set_q][srv_way_q][k] <= merge_bytes(mshr_sd_q[srv_ms_q],
                                                                fill_q[k],
                                                                mshr_sm_q[srv_ms_q]);
              else
                data_q[srv_set_q][srv_way_q][k] <= fill_q[k];
            end
            mshr_vld_q[srv_ms_q] <= 1'b0;
            ptr_q <= (srv_ms_q == MS_B'(NW-1)) ? '0 : (srv_ms_q + 1'b1);
            state_q <= ST_IDLE;
          end
        end
        default: state_q <= ST_IDLE;
      endcase
    end
  end

endmodule
