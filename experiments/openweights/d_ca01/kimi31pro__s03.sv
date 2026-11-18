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
  localparam int unsigned BYTE_W      = DATA_W/8;
  localparam int unsigned BYTE_OFF_W  = $clog2(BYTE_W);
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned WAY_W       = $clog2(WAYS);
  localparam int unsigned MISS_W      = $clog2(MAX_MISSES);
  localparam int unsigned TAG_W       = 32-BYTE_OFF_W-2-SET_W;

  logic [DATA_W-1:0] data_mem [0:SETS-1][0:WAYS-1][0:BLOCK_WORDS-1];
  logic [TAG_W-1:0]  tag_mem  [0:SETS-1][0:WAYS-1];
  logic              valid_mem[0:SETS-1][0:WAYS-1];
  logic              dirty_mem[0:SETS-1][0:WAYS-1];
  logic              pend_mem [0:SETS-1][0:WAYS-1];

  logic              miss_valid     [0:MAX_MISSES-1];
  logic [31:0]       miss_addr      [0:MAX_MISSES-1];
  logic [3:0]        miss_id        [0:MAX_MISSES-1];
  logic              miss_op        [0:MAX_MISSES-1];
  logic [1:0]        miss_word      [0:MAX_MISSES-1];
  logic [SET_W-1:0]  miss_set       [0:MAX_MISSES-1];
  logic [WAY_W-1:0]  miss_way       [0:MAX_MISSES-1];
  logic [DATA_W-1:0] miss_store_data[0:MAX_MISSES-1];
  logic [BYTE_W-1:0] miss_store_mask[0:MAX_MISSES-1];
  logic              miss_wb_needed [0:MAX_MISSES-1];

  logic [DATA_W-1:0] fill_buf[0:BLOCK_WORDS-1];
  logic [DATA_W-1:0] wb_buf  [0:BLOCK_WORDS-1];
  logic [31:0]       wb_addr;
  logic              wb_valid;

  typedef enum logic [2:0] {
    M_IDLE,
    M_WB_REQ,
    M_WB_DATA,
    M_FILL_REQ,
    M_FILL_DATA
  } mem_state_t;

  mem_state_t mem_state;
  logic [MISS_W-1:0] active_miss;
  logic [MISS_W-1:0] sched_ptr;
  logic [1:0]        fill_count;
  logic [1:0]        wb_count;

  logic [SET_W-1:0] req_set;
  logic [TAG_W-1:0] req_tag;
  logic [1:0]       req_word;

  logic              hit_found;
  logic [WAY_W-1:0]  hit_way;
  logic              line_blocked;
  logic              way_found;
  logic [WAY_W-1:0]  way_sel;
  logic              victim_valid;
  logic              victim_dirty;
  logic [DATA_W-1:0] hit_data;

  logic              free_found;
  logic [MISS_W-1:0] free_sel;
  logic              sched_found;
  logic [MISS_W-1:0] sched_sel;

  logic req_fire;
  logic fill_complete;

  logic [15:0]       rsp_pending;
  logic [DATA_W-1:0] rsp_data_mem[0:15];
  logic              rsp_hold_valid;
  logic [3:0]        rsp_hold_id;
  logic [3:0]        rsp_rr_ptr;
  logic              rsp_any;
  logic [3:0]        rsp_sel;
  logic [DATA_W-1:0] fill_load_data;

  integer q_w;
  integer q_m;
  integer q_scan;
  integer q_cand;
  integer q_rscan;
  integer q_rcand;
  integer s;
  integer w;
  integer b;
  integer f;
  integer r;

  assign req_set  = req_addr_i[BYTE_OFF_W+2 +: SET_W];
  assign req_tag  = req_addr_i[31 -: TAG_W];
  assign req_word = req_addr_i[BYTE_OFF_W +: 2];

  always_comb begin
    hit_found    = 1'b0;
    hit_way      = '0;
    line_blocked = 1'b0;
    way_found    = 1'b0;
    way_sel      = '0;
    victim_valid = 1'b0;
    victim_dirty = 1'b0;

    for (q_w = 0; q_w < WAYS; q_w = q_w + 1) begin
      if (valid_mem[req_set][q_w] && (tag_mem[req_set][q_w] == req_tag)) begin
        hit_found = 1'b1;
        hit_way   = q_w;
      end
      if (pend_mem[req_set][q_w] && (tag_mem[req_set][q_w] == req_tag))
        line_blocked = 1'b1;
    end

    // Prefer invalid victims, then clean victims, then any non-pending line.
    for (q_w = 0; q_w < WAYS; q_w = q_w + 1) begin
      if (!way_found && !valid_mem[req_set][q_w] && !pend_mem[req_set][q_w]) begin
        way_found = 1'b1;
        way_sel   = q_w;
      end
    end
    for (q_w = 0; q_w < WAYS; q_w = q_w + 1) begin
      if (!way_found && valid_mem[req_set][q_w] &&
          !dirty_mem[req_set][q_w] && !pend_mem[req_set][q_w]) begin
        way_found = 1'b1;
        way_sel   = q_w;
      end
    end
    for (q_w = 0; q_w < WAYS; q_w = q_w + 1) begin
      if (!way_found && !pend_mem[req_set][q_w]) begin
        way_found = 1'b1;
        way_sel   = q_w;
      end
    end

    if (way_found) begin
      victim_valid = valid_mem[req_set][way_sel];
      victim_dirty = dirty_mem[req_set][way_sel];
    end
  end

  always_comb begin
    free_found = 1'b0;
    free_sel   = '0;
    for (q_m = 0; q_m < MAX_MISSES; q_m = q_m + 1) begin
      if (!free_found && !miss_valid[q_m]) begin
        free_found = 1'b1;
        free_sel   = q_m;
      end
    end
  end

  always_comb begin
    req_ready_o = 1'b0;
    if (rst_ni && req_valid_i) begin
      if (hit_found)
        req_ready_o = 1'b1;
      else if (!line_blocked && free_found && way_found) begin
        if (victim_valid && victim_dirty)
          req_ready_o = !wb_valid;
        else
          req_ready_o = 1'b1;
      end
    end
  end

  assign req_fire = req_valid_i && req_ready_o;
  assign hit_data = data_mem[req_set][hit_way][req_word];

  // Round-robin selection prevents a continuously reused low-numbered miss
  // slot from starving another outstanding miss.
  always_comb begin
    sched_found = 1'b0;
    sched_sel   = '0;
    q_cand      = 0;
    for (q_scan = 0; q_scan < MAX_MISSES; q_scan = q_scan + 1) begin
      q_cand = sched_ptr + q_scan;
      if (q_cand >= MAX_MISSES)
        q_cand = q_cand - MAX_MISSES;
      if (!sched_found && miss_valid[q_cand]) begin
        sched_found = 1'b1;
        sched_sel   = q_cand;
      end
    end
  end

  always_comb begin
    mem_req_valid_o = 1'b0;
    mem_req_we_o    = 1'b0;
    mem_req_addr_o  = 32'b0;
    mem_rd_ready_o  = 1'b0;
    mem_wr_valid_o  = 1'b0;
    mem_wr_data_o   = '0;

    case (mem_state)
      M_WB_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b1;
        mem_req_addr_o  = wb_addr;
      end
      M_WB_DATA: begin
        mem_wr_valid_o = 1'b1;
        mem_wr_data_o  = wb_buf[wb_count];
      end
      M_FILL_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b0;
        mem_req_addr_o  = miss_addr[active_miss];
      end
      M_FILL_DATA: begin
        mem_rd_ready_o = 1'b1;
      end
      default: begin
      end
    endcase
  end

  assign fill_complete = (mem_state == M_FILL_DATA) &&
                         mem_rd_valid_i && mem_rd_ready_o &&
                         (fill_count == BLOCK_WORDS-1);

  always_comb begin
    if (miss_word[active_miss] == fill_count)
      fill_load_data = mem_rd_data_i;
    else
      fill_load_data = fill_buf[miss_word[active_miss]];
  end

  // Responses are held per ID.  The output selector is locked whenever it
  // encounters backpressure, so both ID and data remain stable.
  always_comb begin
    rsp_any = 1'b0;
    rsp_sel = 4'b0;
    q_rcand = 0;
    for (q_rscan = 0; q_rscan < 16; q_rscan = q_rscan + 1) begin
      q_rcand = rsp_rr_ptr + q_rscan;
      if (q_rcand >= 16)
        q_rcand = q_rcand - 16;
      if (!rsp_any && rsp_pending[q_rcand]) begin
        rsp_any = 1'b1;
        rsp_sel = q_rcand;
      end
    end
  end

  always_comb begin
    if (rsp_hold_valid) begin
      rsp_valid_o = 1'b1;
      rsp_id_o    = rsp_hold_id;
      rsp_data_o  = rsp_data_mem[rsp_hold_id];
    end else begin
      rsp_valid_o = rsp_any;
      rsp_id_o    = rsp_sel;
      rsp_data_o  = rsp_any ? rsp_data_mem[rsp_sel] : '0;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rsp_pending    <= 16'b0;
      rsp_hold_valid <= 1'b0;
      rsp_hold_id    <= 4'b0;
      rsp_rr_ptr     <= 4'b0;
    end else begin
      if (rsp_valid_o && rsp_ready_i) begin
        rsp_pending[rsp_id_o] <= 1'b0;
        rsp_rr_ptr            <= rsp_id_o + 1'b1;
        if (rsp_hold_valid)
          rsp_hold_valid <= 1'b0;
      end

      if (!rsp_hold_valid && rsp_valid_o && !rsp_ready_i) begin
        rsp_hold_valid <= 1'b1;
        rsp_hold_id    <= rsp_id_o;
      end

      if (req_fire && hit_found) begin
        rsp_pending[req_id_i]  <= 1'b1;
        rsp_data_mem[req_id_i] <= req_op_i ? '0 : hit_data;
      end

      if (fill_complete) begin
        rsp_pending[miss_id[active_miss]] <= 1'b1;
        rsp_data_mem[miss_id[active_miss]] <=
          miss_op[active_miss] ? '0 : fill_load_data;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mem_state   <= M_IDLE;
      active_miss <= '0;
      sched_ptr   <= '0;
      fill_count  <= 2'b0;
      wb_count    <= 2'b0;
      wb_valid    <= 1'b0;
      wb_addr     <= 32'b0;

      for (s = 0; s < SETS; s = s + 1) begin
        for (w = 0; w < WAYS; w = w + 1) begin
          valid_mem[s][w] <= 1'b0;
          dirty_mem[s][w] <= 1'b0;
          pend_mem[s][w]  <= 1'b0;
        end
      end
      for (w = 0; w < MAX_MISSES; w = w + 1)
        miss_valid[w] <= 1'b0;
    end else begin
      case (mem_state)
        M_IDLE: begin
          if (sched_found) begin
            active_miss <= sched_sel;
            if (miss_wb_needed[sched_sel]) begin
              mem_state <= M_WB_REQ;
              wb_count  <= 2'b0;
            end else begin
              mem_state  <= M_FILL_REQ;
              fill_count <= 2'b0;
            end

            if (sched_sel == MAX_MISSES-1)
              sched_ptr <= '0;
            else
              sched_ptr <= sched_sel + 1'b1;
          end
        end

        M_WB_REQ: begin
          if (mem_req_ready_i) begin
            mem_state <= M_WB_DATA;
            wb_count  <= 2'b0;
          end
        end

        M_WB_DATA: begin
          if (mem_wr_ready_i) begin
            if (wb_count == BLOCK_WORDS-1) begin
              wb_valid   <= 1'b0;
              mem_state  <= M_FILL_REQ;
              fill_count <= 2'b0;
            end else begin
              wb_count <= wb_count + 1'b1;
            end
          end
        end

        M_FILL_REQ: begin
          if (mem_req_ready_i) begin
            mem_state  <= M_FILL_DATA;
            fill_count <= 2'b0;
          end
        end

        M_FILL_DATA: begin
          if (mem_rd_valid_i) begin
            if (fill_count == BLOCK_WORDS-1) begin
              for (f = 0; f < BLOCK_WORDS; f = f + 1) begin
                if (f == fill_count) begin
                  if (miss_op[active_miss] &&
                      (miss_word[active_miss] == fill_count)) begin
                    for (b = 0; b < BYTE_W; b = b + 1) begin
                      if (miss_store_mask[active_miss][b])
                        data_mem[miss_set[active_miss]][miss_way[active_miss]][f][8*b +: 8]
                          <= miss_store_data[active_miss][8*b +: 8];
                      else
                        data_mem[miss_set[active_miss]][miss_way[active_miss]][f][8*b +: 8]
                          <= mem_rd_data_i[8*b +: 8];
                    end
                  end else begin
                    data_mem[miss_set[active_miss]][miss_way[active_miss]][f]
                      <= mem_rd_data_i;
                  end
                end else begin
                  if (miss_op[active_miss] && (miss_word[active_miss] == f)) begin
                    for (b = 0; b < BYTE_W; b = b + 1) begin
                      if (miss_store_mask[active_miss][b])
                        data_mem[miss_set[active_miss]][miss_way[active_miss]][f][8*b +: 8]
                          <= miss_store_data[active_miss][8*b +: 8];
                      else
                        data_mem[miss_set[active_miss]][miss_way[active_miss]][f][8*b +: 8]
                          <= fill_buf[f][8*b +: 8];
                    end
                  end else begin
                    data_mem[miss_set[active_miss]][miss_way[active_miss]][f]
                      <= fill_buf[f];
                  end
                end
              end

              valid_mem[miss_set[active_miss]][miss_way[active_miss]] <= 1'b1;
              dirty_mem[miss_set[active_miss]][miss_way[active_miss]] <=
                miss_op[active_miss];
              pend_mem[miss_set[active_miss]][miss_way[active_miss]] <= 1'b0;
              miss_valid[active_miss] <= 1'b0;
              mem_state <= M_IDLE;
            end else begin
              fill_buf[fill_count] <= mem_rd_data_i;
              fill_count           <= fill_count + 1'b1;
            end
          end
        end

        default: begin
          mem_state <= M_IDLE;
        end
      endcase

      if (req_fire) begin
        if (hit_found) begin
          if (req_op_i) begin
            for (b = 0; b < BYTE_W; b = b + 1) begin
              if (req_mask_i[b])
                data_mem[req_set][hit_way][req_word][8*b +: 8]
                  <= req_data_i[8*b +: 8];
            end
            dirty_mem[req_set][hit_way] <= 1'b1;
          end
        end else begin
          miss_valid[free_sel]      <= 1'b1;
          miss_addr[free_sel]       <=
            {req_addr_i[31:BYTE_OFF_W+2], {(BYTE_OFF_W+2){1'b0}}};
          miss_id[free_sel]         <= req_id_i;
          miss_op[free_sel]         <= req_op_i;
          miss_word[free_sel]       <= req_word;
          miss_set[free_sel]        <= req_set;
          miss_way[free_sel]        <= way_sel;
          miss_store_data[free_sel] <= req_data_i;
          miss_store_mask[free_sel] <= req_mask_i;
          miss_wb_needed[free_sel]  <= victim_valid && victim_dirty;

          tag_mem[req_set][way_sel]   <= req_tag;
          valid_mem[req_set][way_sel] <= 1'b0;
          dirty_mem[req_set][way_sel] <= 1'b0;
          pend_mem[req_set][way_sel]  <= 1'b1;

          if (victim_valid && victim_dirty) begin
            wb_valid <= 1'b1;
            wb_addr  <= {tag_mem[req_set][way_sel], req_set,
                         {(BYTE_OFF_W+2){1'b0}}};
            for (f = 0; f < BLOCK_WORDS; f = f + 1)
              wb_buf[f] <= data_mem[req_set][way_sel][f];
          end
        end
      end
    end
  end

endmodule
