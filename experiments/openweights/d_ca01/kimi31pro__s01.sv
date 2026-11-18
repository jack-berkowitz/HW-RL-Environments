module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,
  parameter int unsigned SETS       = 16,
  parameter int unsigned WAYS       = 4,
  parameter int unsigned MAX_MISSES = 8
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,

  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,
  input  logic                     req_op_i,
  input  logic [31:0]              req_addr_i,
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

  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned MASK_W      = DATA_W / 8;
  localparam int unsigned BYTE_OFF_W  = $clog2(MASK_W);
  localparam int unsigned BLOCK_OFF_W = BYTE_OFF_W + 2;
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned WAY_W       = $clog2(WAYS);
  localparam int unsigned TAG_W       = 32 - BLOCK_OFF_W - SET_W;
  localparam int unsigned MSHR_W      = $clog2(MAX_MISSES);
  localparam int unsigned N_IDS       = 16;

  logic [TAG_W-1:0] line_tag   [0:SETS-1][0:WAYS-1];
  logic             line_valid [0:SETS-1][0:WAYS-1];
  logic             line_dirty [0:SETS-1][0:WAYS-1];
  logic [DATA_W-1:0] data_mem  [0:SETS-1][0:WAYS-1][0:BLOCK_WORDS-1];

  logic [1:0]       req_word;
  logic [SET_W-1:0] req_set;
  logic [TAG_W-1:0] req_tag;

  logic [MAX_MISSES-1:0] mshr_valid;
  logic [3:0]            mshr_id   [0:MAX_MISSES-1];
  logic                  mshr_op   [0:MAX_MISSES-1];
  logic [SET_W-1:0]      mshr_set  [0:MAX_MISSES-1];
  logic [TAG_W-1:0]      mshr_tag  [0:MAX_MISSES-1];
  logic [1:0]            mshr_word [0:MAX_MISSES-1];
  logic [DATA_W-1:0]     mshr_data [0:MAX_MISSES-1];
  logic [MASK_W-1:0]     mshr_mask [0:MAX_MISSES-1];

  logic                 req_hit;
  logic [WAY_W-1:0]     req_hit_way;
  logic [DATA_W-1:0]    req_hit_data;
  logic                 req_line_pending;
  logic                 free_mshr;
  logic [MSHR_W-1:0]    free_mshr_idx;

  logic [N_IDS-1:0]     rsp_pending;
  logic [DATA_W-1:0]    rsp_pending_data [0:N_IDS-1];
  logic [3:0]           rsp_rr;
  logic                 rsp_sel_valid;
  logic [3:0]           rsp_sel;

  typedef enum logic [2:0] {
    M_IDLE,
    M_REQ_WB,
    M_WB_DATA,
    M_REQ_FILL,
    M_FILL_DATA
  } mem_state_t;

  mem_state_t           mem_state;
  logic [MSHR_W-1:0]    mem_mshr;
  logic [WAY_W-1:0]     mem_way;
  logic [TAG_W-1:0]     mem_victim_tag;
  logic [1:0]           mem_beat;

  logic [MSHR_W-1:0]    sched_rr;
  logic                 sched_valid;
  logic [MSHR_W-1:0]    sched_idx;
  logic                 victim_found;
  logic [WAY_W-1:0]     victim_way;
  logic                 victim_valid;
  logic                 victim_dirty;
  logic [TAG_W-1:0]     victim_tag;
  logic                 victim_need_wb;

  integer req_scan_m;
  integer req_scan_w;
  integer sched_scan_offset;
  integer sched_scan_index;
  integer sched_scan_way;
  integer rsp_scan_offset;
  integer rsp_scan_index;
  integer reset_s;
  integer reset_w;

  function automatic logic [DATA_W-1:0] merge_bytes(
    input logic [DATA_W-1:0] original,
    input logic [DATA_W-1:0] store_data,
    input logic [MASK_W-1:0] store_mask
  );
    integer byte_idx;
    begin
      merge_bytes = original;
      for (byte_idx = 0; byte_idx < MASK_W; byte_idx = byte_idx + 1) begin
        if (store_mask[byte_idx]) begin
          merge_bytes[8*byte_idx +: 8] = store_data[8*byte_idx +: 8];
        end
      end
    end
  endfunction

  assign req_word = req_addr_i[BYTE_OFF_W +: 2];
  assign req_set  = req_addr_i[BLOCK_OFF_W +: SET_W];
  assign req_tag  = req_addr_i[31 : BLOCK_OFF_W + SET_W];

  /*
   * A miss consumes a tracking entry immediately, but its victim is not
   * selected until that entry reaches the memory scheduler.  Consequently,
   * even several misses mapping to one set do not reduce the C1 capacity.
   * Requests to a line already being fetched are held off; this also gives
   * same-address requests their required acceptance ordering.
   */
  always_comb begin
    req_hit          = 1'b0;
    req_hit_way      = '0;
    req_hit_data     = '0;
    req_line_pending = 1'b0;
    free_mshr        = 1'b0;
    free_mshr_idx    = '0;

    for (req_scan_m = 0; req_scan_m < MAX_MISSES;
         req_scan_m = req_scan_m + 1) begin
      if (!free_mshr && !mshr_valid[req_scan_m]) begin
        free_mshr     = 1'b1;
        free_mshr_idx = req_scan_m[MSHR_W-1:0];
      end
    end

    if (req_valid_i) begin
      for (req_scan_m = 0; req_scan_m < MAX_MISSES;
           req_scan_m = req_scan_m + 1) begin
        if (mshr_valid[req_scan_m] &&
            (mshr_set[req_scan_m] == req_set) &&
            (mshr_tag[req_scan_m] == req_tag)) begin
          req_line_pending = 1'b1;
        end
      end

      for (req_scan_w = 0; req_scan_w < WAYS;
           req_scan_w = req_scan_w + 1) begin
        if (!req_hit && line_valid[req_set][req_scan_w] &&
            (line_tag[req_set][req_scan_w] == req_tag)) begin
          req_hit      = 1'b1;
          req_hit_way  = req_scan_w[WAY_W-1:0];
          req_hit_data = data_mem[req_set][req_scan_w][req_word];
        end
      end
    end

    req_ready_o = 1'b0;
    if (rst_ni && req_valid_i && !req_line_pending) begin
      if (req_hit) begin
        req_ready_o = 1'b1;
      end else if (free_mshr) begin
        req_ready_o = 1'b1;
      end
    end
  end

  /* Round-robin selection prevents a continuously refilled low-index entry
   * from starving another outstanding miss. */
  always_comb begin
    sched_valid      = 1'b0;
    sched_idx        = '0;
    sched_scan_index = 0;
    victim_found     = 1'b0;
    victim_way       = '0;
    victim_valid     = 1'b0;
    victim_dirty     = 1'b0;
    victim_tag       = '0;
    victim_need_wb   = 1'b0;

    for (sched_scan_offset = 0; sched_scan_offset < MAX_MISSES;
         sched_scan_offset = sched_scan_offset + 1) begin
      sched_scan_index =
          (int'(sched_rr) + sched_scan_offset) % MAX_MISSES;
      if (!sched_valid && mshr_valid[sched_scan_index]) begin
        sched_valid = 1'b1;
        sched_idx   = sched_scan_index[MSHR_W-1:0];
      end
    end

    if (sched_valid) begin
      /* Prefer an invalid way; otherwise use way zero.  Replacement policy
       * is unrestricted by the interface contract. */
      for (sched_scan_way = 0; sched_scan_way < WAYS;
           sched_scan_way = sched_scan_way + 1) begin
        if (!victim_found &&
            !line_valid[mshr_set[sched_idx]][sched_scan_way]) begin
          victim_found = 1'b1;
          victim_way   = sched_scan_way[WAY_W-1:0];
        end
      end

      if (!victim_found) begin
        victim_found = 1'b1;
        victim_way   = '0;
      end

      victim_valid = line_valid[mshr_set[sched_idx]][victim_way];
      victim_dirty = line_dirty[mshr_set[sched_idx]][victim_way];
      victim_tag   = line_tag[mshr_set[sched_idx]][victim_way];

      /* A hit store may be accepted on the same edge that its line is
       * selected for eviction.  Its array write must make that victim dirty
       * for scheduling purposes even though the stored dirty bit is still
       * old in this combinational view. */
      victim_need_wb = victim_valid &&
        (victim_dirty ||
         (req_valid_i && req_ready_o && req_hit && req_op_i &&
          (req_set == mshr_set[sched_idx]) &&
          (req_hit_way == victim_way)));
    end
  end

  /* Responses are held by ID until selected into a stable output register.
   * Round-robin selection prevents response starvation. */
  always_comb begin
    rsp_sel_valid   = 1'b0;
    rsp_sel         = '0;
    rsp_scan_index  = 0;

    for (rsp_scan_offset = 0; rsp_scan_offset < N_IDS;
         rsp_scan_offset = rsp_scan_offset + 1) begin
      rsp_scan_index = (int'(rsp_rr) + rsp_scan_offset) % N_IDS;
      if (!rsp_sel_valid && rsp_pending[rsp_scan_index]) begin
        rsp_sel_valid = 1'b1;
        rsp_sel       = rsp_scan_index[3:0];
      end
    end
  end

  always_comb begin
    mem_req_valid_o = 1'b0;
    mem_req_we_o    = 1'b0;
    mem_req_addr_o  = '0;
    mem_rd_ready_o  = 1'b0;
    mem_wr_valid_o  = 1'b0;
    mem_wr_data_o   = '0;

    if (mem_state == M_REQ_WB) begin
      mem_req_valid_o = 1'b1;
      mem_req_we_o    = 1'b1;
      mem_req_addr_o  =
        {mem_victim_tag, mshr_set[mem_mshr], {BLOCK_OFF_W{1'b0}}};
    end else if (mem_state == M_REQ_FILL) begin
      mem_req_valid_o = 1'b1;
      mem_req_we_o    = 1'b0;
      mem_req_addr_o  =
        {mshr_tag[mem_mshr], mshr_set[mem_mshr], {BLOCK_OFF_W{1'b0}}};
    end

    if (mem_state == M_FILL_DATA) begin
      mem_rd_ready_o = 1'b1;
    end

    if (mem_state == M_WB_DATA) begin
      mem_wr_valid_o = 1'b1;
      mem_wr_data_o  =
        data_mem[mshr_set[mem_mshr]][mem_way][mem_beat];
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mshr_valid     <= '0;
      rsp_pending    <= '0;
      rsp_valid_o    <= 1'b0;
      rsp_id_o       <= '0;
      rsp_data_o     <= '0;
      rsp_rr         <= '0;
      sched_rr       <= '0;
      mem_state      <= M_IDLE;
      mem_mshr       <= '0;
      mem_way        <= '0;
      mem_victim_tag <= '0;
      mem_beat       <= '0;

      for (reset_s = 0; reset_s < SETS; reset_s = reset_s + 1) begin
        for (reset_w = 0; reset_w < WAYS; reset_w = reset_w + 1) begin
          line_valid[reset_s][reset_w] <= 1'b0;
          line_dirty[reset_s][reset_w] <= 1'b0;
        end
      end
    end else begin
      /* Response output register.  Nothing changes it while a presented
       * response is backpressured. */
      if (rsp_valid_o && rsp_ready_i) begin
        rsp_valid_o <= 1'b0;
      end

      if ((!rsp_valid_o || rsp_ready_i) && rsp_sel_valid) begin
        rsp_valid_o          <= 1'b1;
        rsp_id_o             <= rsp_sel;
        rsp_data_o           <= rsp_pending_data[rsp_sel];
        rsp_pending[rsp_sel] <= 1'b0;
        rsp_rr               <= rsp_sel + 4'd1;
      end

      if (req_valid_i && req_ready_o) begin
        if (req_hit) begin
          rsp_pending[req_id_i] <= 1'b1;

          if (req_op_i) begin
            data_mem[req_set][req_hit_way][req_word] <=
              merge_bytes(data_mem[req_set][req_hit_way][req_word],
                          req_data_i, req_mask_i);
            line_dirty[req_set][req_hit_way] <= 1'b1;
            rsp_pending_data[req_id_i] <= '0;
          end else begin
            rsp_pending_data[req_id_i] <= req_hit_data;
          end
        end else begin
          mshr_valid[free_mshr_idx] <= 1'b1;
          mshr_id[free_mshr_idx]    <= req_id_i;
          mshr_op[free_mshr_idx]    <= req_op_i;
          mshr_set[free_mshr_idx]   <= req_set;
          mshr_tag[free_mshr_idx]   <= req_tag;
          mshr_word[free_mshr_idx]  <= req_word;
          mshr_data[free_mshr_idx]  <= req_data_i;
          mshr_mask[free_mshr_idx]  <= req_mask_i;
        end
      end

      case (mem_state)
        M_IDLE: begin
          if (sched_valid) begin
            mem_mshr       <= sched_idx;
            mem_way        <= victim_way;
            mem_victim_tag <= victim_tag;
            mem_beat       <= '0;
            sched_rr       <= sched_idx + 1'b1;

            /* Reserve the victim by invalidating it.  Its data remains in
             * the array and is used directly as the writeback buffer. */
            line_tag[mshr_set[sched_idx]][victim_way]
              <= mshr_tag[sched_idx];
            line_valid[mshr_set[sched_idx]][victim_way] <= 1'b0;
            line_dirty[mshr_set[sched_idx]][victim_way] <= 1'b0;

            if (victim_need_wb) begin
              mem_state <= M_REQ_WB;
            end else begin
              mem_state <= M_REQ_FILL;
            end
          end
        end

        M_REQ_WB: begin
          if (mem_req_ready_i) begin
            mem_state <= M_WB_DATA;
            mem_beat  <= '0;
          end
        end

        M_WB_DATA: begin
          if (mem_wr_ready_i) begin
            if (mem_beat == 2'd3) begin
              mem_state <= M_REQ_FILL;
              mem_beat  <= '0;
            end else begin
              mem_beat <= mem_beat + 2'd1;
            end
          end
        end

        M_REQ_FILL: begin
          if (mem_req_ready_i) begin
            mem_state <= M_FILL_DATA;
            mem_beat  <= '0;
          end
        end

        M_FILL_DATA: begin
          if (mem_rd_valid_i) begin
            if (mshr_op[mem_mshr] &&
                (mshr_word[mem_mshr] == mem_beat)) begin
              data_mem[mshr_set[mem_mshr]][mem_way][mem_beat] <=
                merge_bytes(mem_rd_data_i, mshr_data[mem_mshr],
                            mshr_mask[mem_mshr]);
            end else begin
              data_mem[mshr_set[mem_mshr]][mem_way][mem_beat]
                <= mem_rd_data_i;
            end

            if (mem_beat == 2'd3) begin
              mem_state <= M_IDLE;
              mem_beat  <= '0;

              line_valid[mshr_set[mem_mshr]][mem_way] <= 1'b1;
              line_dirty[mshr_set[mem_mshr]][mem_way]
                <= mshr_op[mem_mshr];

              mshr_valid[mem_mshr] <= 1'b0;
              rsp_pending[mshr_id[mem_mshr]] <= 1'b1;

              if (mshr_op[mem_mshr]) begin
                rsp_pending_data[mshr_id[mem_mshr]] <= '0;
              end else if (mshr_word[mem_mshr] == 2'd3) begin
                rsp_pending_data[mshr_id[mem_mshr]] <= mem_rd_data_i;
              end else begin
                rsp_pending_data[mshr_id[mem_mshr]] <=
                  data_mem[mshr_set[mem_mshr]][mem_way]
                          [mshr_word[mem_mshr]];
              end
            end else begin
              mem_beat <= mem_beat + 2'd1;
            end
          end
        end

        default: begin
          mem_state <= M_IDLE;
        end
      endcase
    end
  end

endmodule
