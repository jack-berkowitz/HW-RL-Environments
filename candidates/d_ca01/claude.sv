// =============================================================================
// nonblocking_dcache.sv
//
// Set-associative, write-back, write-allocate data cache that keeps accepting
// requests while misses are outstanding.
//
// Structure
// ---------
//   * One in-order lookup stage (S1) owns every access to the tag and data
//     arrays.  Because all array traffic is serialised there in acceptance
//     order, R5 (same-address ordering) holds by construction.
//   * A miss file of MAX_MISSES entries records misses whose data has not yet
//     arrived: line address, id, op, word index, and one word of merged store
//     data with its byte mask (C4).  S1 keeps accepting -- and answering --
//     hits underneath them (C1, C2).
//   * One memory engine services the miss file in round-robin order, one
//     transaction at a time (M3): optional writeback of the victim, then the
//     fill.  Writeback beats stream straight out of the data array and fill
//     beats stream straight into it, so NO block-data buffer exists anywhere
//     outside the arrays -- comfortably inside the two-line ceiling of C4.
//   * Two response slots (one for hits, one for the completing fill) with an
//     alternating arbiter, so a ready response is never held behind one that
//     is not (R4) and neither source can starve the other (C3).
//
// Ordering hazards are handled by three rules:
//   1. S1 does not allocate a second miss for a line that already has one; it
//      waits instead, so a line can never be resident twice.
//   2. The victim is invalidated when its service starts, so a fill in
//      progress can never be hit, and the request that lost the line simply
//      misses and allocates.
//   3. The memory engine has priority over an S1 store that is hitting the
//      exact way it is about to evict; S1 retries the next cycle.
// =============================================================================

module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,   // {32, 64}
  parameter int unsigned SETS       = 16,   // {8, 16}
  parameter int unsigned WAYS       = 4,    // {2, 4}
  parameter int unsigned MAX_MISSES = 8     // {2, 8}
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,        // active low, asynchronous assert

  // ---- request ------------------------------------------------------------
  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,      // ID_W = 4
  input  logic                     req_op_i,      // 0 = LOAD, 1 = STORE
  input  logic [31:0]              req_addr_i,    // ADDR_W = 32, byte address, word aligned
  input  logic [DATA_W-1:0]        req_data_i,    // STORE data
  input  logic [(DATA_W/8)-1:0]    req_mask_i,    // STORE byte enables

  // ---- response -----------------------------------------------------------
  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  // ---- memory: request ----------------------------------------------------
  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,  // 0 = fill, 1 = writeback
  output logic [31:0]              mem_req_addr_o,// block aligned

  // ---- memory: fill data in ----------------------------------------------
  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  // ---- memory: writeback data out ----------------------------------------
  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  // ---------------------------------------------------------------------------
  // Geometry.  BLOCK_WORDS is fixed at 4 by the contract.
  // ---------------------------------------------------------------------------
  localparam int unsigned BLOCK_WORDS = 4;

  localparam int unsigned BW_LOG  = 2;                  // $clog2(BLOCK_WORDS)
  localparam int unsigned BYTES_W = DATA_W / 8;
  localparam int unsigned BOFF_W  = (DATA_W == 32) ? 2 : 3;
  localparam int unsigned IDX_W   = (SETS == 8) ? 3 : 4;
  localparam int unsigned WAY_W   = (WAYS == 2) ? 1 : 2;
  localparam int unsigned MSH_W   = (MAX_MISSES == 2) ? 1 : 3;

  localparam int unsigned OFF_LSB = BOFF_W;             // word-in-block field
  localparam int unsigned IDX_LSB = BOFF_W + BW_LOG;    // set field
  localparam int unsigned TAG_LSB = IDX_LSB + IDX_W;    // tag field
  localparam int unsigned TAG_W   = 32 - TAG_LSB;
  localparam int unsigned LAD_W   = 32 - IDX_LSB;       // {tag, set} = line addr

  // unit increments, sized to their counters
  localparam logic [WAY_W-1:0]  WAY_ONE  = {{(WAY_W-1){1'b0}}, 1'b1};
  localparam logic [MSH_W-1:0]  MSH_ONE  = {{(MSH_W-1){1'b0}}, 1'b1};
  localparam logic [BW_LOG-1:0] BEAT_ONE = {{(BW_LOG-1){1'b0}}, 1'b1};
  localparam logic [BW_LOG-1:0] BEAT_LAST= BW_LOG'(BLOCK_WORDS - 1);

  // memory engine states
  localparam logic [2:0] ST_IDLE  = 3'd0;
  localparam logic [2:0] ST_WBREQ = 3'd1;
  localparam logic [2:0] ST_WBDAT = 3'd2;
  localparam logic [2:0] ST_FLREQ = 3'd3;
  localparam logic [2:0] ST_FLDAT = 3'd4;
  localparam logic [2:0] ST_DONE  = 3'd5;

  // ---------------------------------------------------------------------------
  // Arrays
  // ---------------------------------------------------------------------------
  logic [TAG_W-1:0]  tag_q [SETS][WAYS];
  logic              val_q [SETS][WAYS];
  logic              drt_q [SETS][WAYS];
  logic [DATA_W-1:0] dat_q [SETS][WAYS][BLOCK_WORDS];
  logic [WAY_W-1:0]  vic_q [SETS];                      // round-robin victim (L1)

  // ---------------------------------------------------------------------------
  // Miss file (L2 leaves the structure free; this is a small register file)
  // ---------------------------------------------------------------------------
  logic               m_val  [MAX_MISSES];
  logic [LAD_W-1:0]   m_lad  [MAX_MISSES];
  logic [3:0]         m_id   [MAX_MISSES];
  logic               m_op   [MAX_MISSES];
  logic [BW_LOG-1:0]  m_woff [MAX_MISSES];
  logic [DATA_W-1:0]  m_data [MAX_MISSES];              // one word only (C4)
  logic [BYTES_W-1:0] m_mask [MAX_MISSES];

  // ---------------------------------------------------------------------------
  // Lookup stage
  // ---------------------------------------------------------------------------
  logic               s1_v;
  logic [3:0]         s1_id;
  logic               s1_op;
  logic [31:0]        s1_addr;
  logic [DATA_W-1:0]  s1_data;
  logic [BYTES_W-1:0] s1_mask;

  logic [IDX_W-1:0]   s1_set;
  logic [TAG_W-1:0]   s1_tag;
  logic [BW_LOG-1:0]  s1_woff;
  logic [LAD_W-1:0]   s1_lad;

  assign s1_set  = s1_addr[IDX_LSB +: IDX_W];
  assign s1_tag  = s1_addr[TAG_LSB +: TAG_W];
  assign s1_woff = s1_addr[OFF_LSB +: BW_LOG];
  assign s1_lad  = s1_addr[IDX_LSB +: LAD_W];

  logic             s1_hit;
  logic [WAY_W-1:0] s1_way;

  always_comb begin
    int w;
    s1_hit = 1'b0;
    s1_way = '0;
    for (w = 0; w < int'(WAYS); w++) begin
      if (val_q[s1_set][w] && (tag_q[s1_set][w] == s1_tag)) begin
        s1_hit = 1'b1;
        s1_way = WAY_W'(unsigned'(w));
      end
    end
  end

  // miss-file occupancy as seen by the lookup stage
  logic             ms_conflict;   // this line already has a miss in flight
  logic             ms_free;
  logic [MSH_W-1:0] ms_free_idx;

  always_comb begin
    int i;
    ms_conflict = 1'b0;
    ms_free     = 1'b0;
    ms_free_idx = '0;
    for (i = int'(MAX_MISSES) - 1; i >= 0; i--) begin
      if (m_val[i] && (m_lad[i] == s1_lad)) ms_conflict = 1'b1;
      if (!m_val[i]) begin
        ms_free     = 1'b1;
        ms_free_idx = MSH_W'(unsigned'(i));
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Response slots and arbitration.  Alternating priority: neither a stream of
  // hits nor a stream of fills can lock the other out (C3).
  // ---------------------------------------------------------------------------
  logic              hrsp_v, frsp_v, pri_f;
  logic [3:0]        hrsp_id, frsp_id;
  logic [DATA_W-1:0] hrsp_data, frsp_data;
  logic              grant_f, grant_h, rsp_fire, hrsp_free;

  assign grant_f     = frsp_v & (~hrsp_v | pri_f);
  assign grant_h     = hrsp_v & ~grant_f;
  assign rsp_valid_o = hrsp_v | frsp_v;
  assign rsp_id_o    = grant_f ? frsp_id   : hrsp_id;
  assign rsp_data_o  = grant_f ? frsp_data : hrsp_data;
  assign rsp_fire    = rsp_valid_o & rsp_ready_i;
  assign hrsp_free   = ~hrsp_v | (grant_h & rsp_ready_i);

  // ---------------------------------------------------------------------------
  // Memory engine selection: round-robin over the miss file
  // ---------------------------------------------------------------------------
  logic [2:0]        st_q;
  logic [MSH_W-1:0]  svc_ptr_q;
  logic [MSH_W-1:0]  sv_idx_q;
  logic [IDX_W-1:0]  sv_set_q;
  logic [WAY_W-1:0]  sv_way_q;
  logic [TAG_W-1:0]  sv_tag_q;
  logic [31:0]       sv_faddr_q, sv_waddr_q;
  logic [BW_LOG-1:0] beat_q;
  logic [DATA_W-1:0] rsp_word_q;

  logic             svc_any, svc_start, svc_wb;
  logic [MSH_W-1:0] svc_idx;
  logic [LAD_W-1:0] svc_lad;
  logic [IDX_W-1:0] svc_set;
  logic [TAG_W-1:0] svc_tag;
  logic [WAY_W-1:0] vic_way;

  always_comb begin
    int k, idx;
    svc_any = 1'b0;
    svc_idx = '0;
    for (k = int'(MAX_MISSES) - 1; k >= 0; k--) begin
      idx = (int'(svc_ptr_q) + k) % int'(MAX_MISSES);
      if (m_val[idx]) begin
        svc_any = 1'b1;
        svc_idx = MSH_W'(unsigned'(idx));
      end
    end
  end

  assign svc_lad = m_lad[svc_idx];
  assign svc_set = svc_lad[IDX_W-1:0];
  assign svc_tag = svc_lad[LAD_W-1:IDX_W];

  // victim: an invalid way if there is one, else the round-robin pointer (L1)
  always_comb begin
    int w;
    vic_way = vic_q[svc_set];
    for (w = int'(WAYS) - 1; w >= 0; w--) begin
      if (!val_q[svc_set][w]) vic_way = WAY_W'(unsigned'(w));
    end
  end

  assign svc_start = (st_q == ST_IDLE) & svc_any;
  assign svc_wb    = val_q[svc_set][vic_way] & drt_q[svc_set][vic_way];

  // A store hitting the very way that is about to be evicted would race the
  // invalidate; the engine wins and the store retries next cycle.
  logic s1_blocked;
  assign s1_blocked = svc_start & s1_hit & s1_op &
                      (s1_set == svc_set) & (s1_way == vic_way);

  // ---------------------------------------------------------------------------
  // Lookup-stage completion and the request handshake
  // ---------------------------------------------------------------------------
  logic s1_hit_done, s1_miss_done, s1_done;

  assign s1_hit_done  = s1_v &  s1_hit & hrsp_free & ~s1_blocked;
  assign s1_miss_done = s1_v & ~s1_hit & ~ms_conflict & ms_free;
  assign s1_done      = s1_hit_done | s1_miss_done;

  assign req_ready_o  = ~s1_v | s1_done;

  // ---------------------------------------------------------------------------
  // Memory port
  // ---------------------------------------------------------------------------
  assign mem_req_valid_o = (st_q == ST_WBREQ) | (st_q == ST_FLREQ);
  assign mem_req_we_o    = (st_q == ST_WBREQ);
  assign mem_req_addr_o  = (st_q == ST_WBREQ) ? sv_waddr_q : sv_faddr_q;
  assign mem_wr_valid_o  = (st_q == ST_WBDAT);
  assign mem_wr_data_o   = dat_q[sv_set_q][sv_way_q][beat_q];
  assign mem_rd_ready_o  = (st_q == ST_FLDAT);

  // ---------------------------------------------------------------------------
  // Sequential
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    int i, w, b;
    logic [DATA_W-1:0] sword;
    logic [DATA_W-1:0] fword;

    if (!rst_ni) begin
      s1_v      <= 1'b0;
      hrsp_v    <= 1'b0;
      frsp_v    <= 1'b0;
      pri_f     <= 1'b0;
      st_q      <= ST_IDLE;
      beat_q    <= '0;
      svc_ptr_q <= '0;
      for (i = 0; i < int'(MAX_MISSES); i++) m_val[i] <= 1'b0;
      // P1 is a precondition, but clearing the tags costs almost nothing and
      // makes the design conformant on its own terms as well.
      for (i = 0; i < int'(SETS); i++) begin
        vic_q[i] <= '0;
        for (w = 0; w < int'(WAYS); w++) begin
          val_q[i][w] <= 1'b0;
          drt_q[i][w] <= 1'b0;
        end
      end
    end else begin
      // ---- response drain ---------------------------------------------------
      if (rsp_fire) begin
        pri_f <= ~pri_f;
        if (grant_f) frsp_v <= 1'b0;
        else         hrsp_v <= 1'b0;
      end

      // ---- lookup stage: retire, then accept --------------------------------
      if (s1_done) s1_v <= 1'b0;
      if (req_valid_i && req_ready_o) begin
        s1_v    <= 1'b1;
        s1_id   <= req_id_i;
        s1_op   <= req_op_i;
        s1_addr <= req_addr_i;
        s1_data <= req_data_i;
        s1_mask <= req_mask_i;
      end

      // ---- hit: answer, and for a store merge into the line ------------------
      if (s1_hit_done) begin
        sword = dat_q[s1_set][s1_way][s1_woff];
        hrsp_v    <= 1'b1;
        hrsp_id   <= s1_id;
        hrsp_data <= sword;                       // store data is free (R3)
        if (s1_op) begin
          for (b = 0; b < int'(BYTES_W); b++) begin
            if (s1_mask[b]) sword[b*8 +: 8] = s1_data[b*8 +: 8];
          end
          dat_q[s1_set][s1_way][s1_woff] <= sword;
          drt_q[s1_set][s1_way]          <= 1'b1;
        end
      end

      // ---- miss: record it and carry on -------------------------------------
      if (s1_miss_done) begin
        m_val [ms_free_idx] <= 1'b1;
        m_lad [ms_free_idx] <= s1_lad;
        m_id  [ms_free_idx] <= s1_id;
        m_op  [ms_free_idx] <= s1_op;
        m_woff[ms_free_idx] <= s1_woff;
        m_data[ms_free_idx] <= s1_data;
        m_mask[ms_free_idx] <= s1_mask;
      end

      // ---- memory engine -----------------------------------------------------
      case (st_q)
        ST_IDLE: begin
          if (svc_start) begin
            sv_idx_q   <= svc_idx;
            sv_set_q   <= svc_set;
            sv_way_q   <= vic_way;
            sv_tag_q   <= svc_tag;
            sv_faddr_q <= {svc_lad, {IDX_LSB{1'b0}}};
            sv_waddr_q <= {tag_q[svc_set][vic_way], svc_set, {IDX_LSB{1'b0}}};
            // the victim leaves the cache now, so nothing can hit the line
            // being replaced while its fill is in flight
            val_q[svc_set][vic_way] <= 1'b0;
            drt_q[svc_set][vic_way] <= 1'b0;
            vic_q[svc_set]          <= vic_way + WAY_ONE;
            svc_ptr_q               <= svc_idx + MSH_ONE;
            beat_q                  <= '0;
            st_q                    <= svc_wb ? ST_WBREQ : ST_FLREQ;
          end
        end

        ST_WBREQ: begin
          if (mem_req_ready_i) begin
            beat_q <= '0;
            st_q   <= ST_WBDAT;
          end
        end

        ST_WBDAT: begin
          if (mem_wr_ready_i) begin
            beat_q <= beat_q + BEAT_ONE;
            if (beat_q == BEAT_LAST) st_q <= ST_FLREQ;
          end
        end

        ST_FLREQ: begin
          if (mem_req_ready_i) begin
            beat_q <= '0;
            st_q   <= ST_FLDAT;
          end
        end

        ST_FLDAT: begin
          if (mem_rd_valid_i) begin
            fword = mem_rd_data_i;
            if (m_op[sv_idx_q] && (m_woff[sv_idx_q] == beat_q)) begin
              for (b = 0; b < int'(BYTES_W); b++) begin
                if (m_mask[sv_idx_q][b]) fword[b*8 +: 8] = m_data[sv_idx_q][b*8 +: 8];
              end
            end
            dat_q[sv_set_q][sv_way_q][beat_q] <= fword;
            if (m_woff[sv_idx_q] == beat_q) rsp_word_q <= fword;
            beat_q <= beat_q + BEAT_ONE;
            if (beat_q == BEAT_LAST) begin
              tag_q[sv_set_q][sv_way_q] <= sv_tag_q;
              val_q[sv_set_q][sv_way_q] <= 1'b1;
              drt_q[sv_set_q][sv_way_q] <= m_op[sv_idx_q];
              st_q                      <= ST_DONE;
            end
          end
        end

        ST_DONE: begin
          if (!frsp_v || (grant_f && rsp_ready_i)) begin
            frsp_v            <= 1'b1;
            frsp_id           <= m_id[sv_idx_q];
            frsp_data         <= rsp_word_q;
            m_val[sv_idx_q]   <= 1'b0;
            st_q              <= ST_IDLE;
          end
        end

        default: st_q <= ST_IDLE;
      endcase
    end
  end

endmodule