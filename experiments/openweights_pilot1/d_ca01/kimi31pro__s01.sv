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
  localparam int unsigned BYTE_W      = $clog2(DATA_W/8);
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned WAY_W       = $clog2(WAYS);
  localparam int unsigned MISS_W      = $clog2(MAX_MISSES);
  localparam int unsigned BLOCK_OFF_W = BYTE_W + 2;
  localparam int unsigned TAG_W       = 32 - SET_W - BLOCK_OFF_W;

  typedef enum logic [2:0] {
    MEM_IDLE,
    MEM_WB_REQ,
    MEM_WB_DATA,
    MEM_FILL_REQ,
    MEM_FILL_DATA
  } mem_state_t;

  mem_state_t mem_state;

  logic [DATA_W-1:0] data_array [0:SETS-1][0:WAYS-1][0:BLOCK_WORDS-1];
  logic [TAG_W-1:0]  tag_array  [0:SETS-1][0:WAYS-1];
  logic              valid_array[0:SETS-1][0:WAYS-1];
  logic              dirty_array[0:SETS-1][0:WAYS-1];

  logic [WAY_W-1:0] repl_ptr[0:SETS-1];

  // A miss is queued without immediately allocating a way.  Consequently,
  // MAX_MISSES misses can be carried even when several map to the same set.
  logic                     miss_valid      [0:MAX_MISSES-1];
  logic [31:0]              miss_line_addr  [0:MAX_MISSES-1];
  logic [SET_W-1:0]         miss_set        [0:MAX_MISSES-1];
  logic [TAG_W-1:0]         miss_tag        [0:MAX_MISSES-1];
  logic [WAY_W-1:0]         miss_way        [0:MAX_MISSES-1];
  logic [1:0]               miss_word       [0:MAX_MISSES-1];
  logic [3:0]               miss_id         [0:MAX_MISSES-1];
  logic                     miss_op         [0:MAX_MISSES-1];
  logic [DATA_W-1:0]        miss_store_data [0:MAX_MISSES-1];
  logic [(DATA_W/8)-1:0]    miss_store_mask [0:MAX_MISSES-1];

  logic [MISS_W-1:0] active_miss;
  logic [MISS_W-1:0] miss_rr;
  logic [31:0]       active_wb_addr;

  logic [DATA_W-1:0] fill_buf[0:BLOCK_WORDS-1];
  logic [DATA_W-1:0] wb_buf  [0:BLOCK_WORDS-1];
  logic [1:0]        fill_count;
  logic [1:0]        wb_count;

  // IDs are unique while in flight, so the ID itself indexes the response
  // storage.  A miss and any number of independent hits can coexist here.
  logic              id_valid[0:15];
  logic              id_ready[0:15];
  logic [DATA_W-1:0] id_data [0:15];
  logic [3:0]        rsp_rr;

  logic [SET_W-1:0] req_set;
  logic [1:0]       req_word;
  logic [TAG_W-1:0] req_tag;
  logic [31:0]      req_line_addr;

  logic              req_hit;
  logic [WAY_W-1:0]  req_hit_way;
  logic              req_line_pending;
  logic              req_free_miss;
  logic [MISS_W-1:0] req_free_miss_idx;
  logic              req_fire;

  logic              sched_valid;
  logic [MISS_W-1:0] sched_idx;
  logic [SET_W-1:0]  sched_set;
  logic [WAY_W-1:0]  sched_way;
  logic              sched_way_found;
  logic [WAYS-1:0]   sched_exclude;

  logic              rsp_sel_valid;
  logic [3:0]        rsp_sel_id;

  function automatic logic [DATA_W-1:0] merge_store_word(
    input logic [DATA_W-1:0]     old_word,
    input logic [DATA_W-1:0]     store_word,
    input logic [(DATA_W/8)-1:0] store_mask
  );
    integer b;
    begin
      merge_store_word = old_word;
      for (b = 0; b < (DATA_W/8); b = b + 1) begin
        if (store_mask[b]) begin
          merge_store_word[8*b +: 8] = store_word[8*b +: 8];
        end
      end
    end
  endfunction

  assign req_set = req_addr_i[BLOCK_OFF_W +: SET_W];
  assign req_word = req_addr_i[BYTE_W +: 2];
  assign req_tag = req_addr_i[31:(BLOCK_OFF_W + SET_W)];
  assign req_line_addr =
      {req_addr_i[31:BLOCK_OFF_W], {BLOCK_OFF_W{1'b0}}};

  assign req_fire = req_valid_i && req_ready_o;

  // Request lookup and admission.  A second request to an already pending
  // line is held off; this also gives a simple implementation of R5.
  always_comb begin : request_comb
    integer w;
    integer m;

    req_ready_o       = 1'b0;
    req_hit           = 1'b0;
    req_hit_way       = '0;
    req_line_pending  = 1'b0;
    req_free_miss     = 1'b0;
    req_free_miss_idx = '0;

    if (req_valid_i) begin
      for (w = 0; w < WAYS; w = w + 1) begin
        if (!req_hit && valid_array[req_set][w] &&
            (tag_array[req_set][w] == req_tag)) begin
          req_hit     = 1'b1;
          req_hit_way = w[WAY_W-1:0];
        end
      end

      for (m = 0; m < MAX_MISSES; m = m + 1) begin
        if (miss_valid[m] &&
            (miss_line_addr[m] == req_line_addr)) begin
          req_line_pending = 1'b1;
        end
        if (!req_free_miss && !miss_valid[m]) begin
          req_free_miss     = 1'b1;
          req_free_miss_idx = m[MISS_W-1:0];
        end
      end

      if (rst_ni && !id_valid[req_id_i]) begin
        if (req_hit) begin
          req_ready_o = 1'b1;
        end else if (!req_line_pending && req_free_miss) begin
          req_ready_o = 1'b1;
        end
      end
    end
  end

  // Round-robin selection of the next miss to service.  The selected victim
  // avoids a way being hit by the simultaneously presented request, allowing
  // the hit and the victim selection to occur on the same edge.
  always_comb begin : schedule_comb
    integer off;
    integer cand;
    integer w;

    sched_valid     = 1'b0;
    sched_idx       = '0;
    sched_set       = '0;
    sched_way       = '0;
    sched_way_found = 1'b0;
    sched_exclude   = '0;
    cand            = 0;

    for (off = 0; off < MAX_MISSES; off = off + 1) begin
      cand = miss_rr + off;
      if (cand >= MAX_MISSES) begin
        cand = cand - MAX_MISSES;
      end
      if (!sched_valid && miss_valid[cand]) begin
        sched_valid = 1'b1;
        sched_idx   = cand[MISS_W-1:0];
      end
    end

    if (sched_valid) begin
      sched_set = miss_set[sched_idx];

      if (req_valid_i && req_hit && (req_set == sched_set)) begin
        sched_exclude[req_hit_way] = 1'b1;
      end

      // Prefer an invalid way.
      for (w = 0; w < WAYS; w = w + 1) begin
        if (!sched_way_found && !sched_exclude[w] &&
            !valid_array[sched_set][w]) begin
          sched_way_found = 1'b1;
          sched_way       = w[WAY_W-1:0];
        end
      end

      // Otherwise use round-robin replacement.
      if (!sched_way_found) begin
        for (off = 0; off < WAYS; off = off + 1) begin
          cand = repl_ptr[sched_set] + off;
          if (cand >= WAYS) begin
            cand = cand - WAYS;
          end
          if (!sched_way_found && !sched_exclude[cand]) begin
            sched_way_found = 1'b1;
            sched_way       = cand[WAY_W-1:0];
          end
        end
      end
    end
  end

  // Fair selection among responses that are actually ready.  An unfinished
  // miss therefore cannot obstruct a later hit.
  always_comb begin : response_select_comb
    integer off;
    integer cand;

    rsp_sel_valid = 1'b0;
    rsp_sel_id    = '0;
    cand          = 0;

    for (off = 0; off < 16; off = off + 1) begin
      cand = rsp_rr + off;
      if (cand >= 16) begin
        cand = cand - 16;
      end
      if (!rsp_sel_valid && id_valid[cand] && id_ready[cand]) begin
        rsp_sel_valid = 1'b1;
        rsp_sel_id    = cand[3:0];
      end
    end
  end

  always_comb begin : memory_output_comb
    mem_req_valid_o = 1'b0;
    mem_req_we_o    = 1'b0;
    mem_req_addr_o  = 32'b0;
    mem_rd_ready_o  = 1'b0;
    mem_wr_valid_o  = 1'b0;
    mem_wr_data_o   = '0;

    case (mem_state)
      MEM_WB_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b1;
        mem_req_addr_o  = active_wb_addr;
      end

      MEM_WB_DATA: begin
        mem_wr_valid_o = 1'b1;
        mem_wr_data_o  = wb_buf[wb_count];
      end

      MEM_FILL_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b0;
        mem_req_addr_o  = miss_line_addr[active_miss];
      end

      MEM_FILL_DATA: begin
        mem_rd_ready_o = 1'b1;
      end

      default: begin
        mem_req_valid_o = 1'b0;
        mem_req_we_o    = 1'b0;
        mem_req_addr_o  = 32'b0;
        mem_rd_ready_o  = 1'b0;
        mem_wr_valid_o  = 1'b0;
        mem_wr_data_o   = '0;
      end
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : sequential
    integer i;
    integer s;
    integer w;
    integer m;
    integer b;

    if (!rst_ni) begin
      mem_state      <= MEM_IDLE;
      active_miss    <= '0;
      miss_rr        <= '0;
      active_wb_addr <= 32'b0;
      fill_count     <= 2'b0;
      wb_count       <= 2'b0;

      rsp_valid_o <= 1'b0;
      rsp_id_o    <= 4'b0;
      rsp_data_o  <= '0;
      rsp_rr      <= 4'b0;

      for (i = 0; i < 16; i = i + 1) begin
        id_valid[i] <= 1'b0;
        id_ready[i] <= 1'b0;
        id_data[i]  <= '0;
      end

      for (m = 0; m < MAX_MISSES; m = m + 1) begin
        miss_valid[m] <= 1'b0;
      end

      for (s = 0; s < SETS; s = s + 1) begin
        repl_ptr[s] <= '0;
        for (w = 0; w < WAYS; w = w + 1) begin
          valid_array[s][w] <= 1'b0;
          dirty_array[s][w] <= 1'b0;
        end
      end
    end else begin
      // Response output register.  Once presented while stalled, neither its
      // validity nor its payload can change.
      if (rsp_valid_o && rsp_ready_i) begin
        rsp_valid_o <= 1'b0;
      end

      if ((!rsp_valid_o || rsp_ready_i) && rsp_sel_valid) begin
        rsp_valid_o <= 1'b1;
        rsp_id_o    <= rsp_sel_id;
        rsp_data_o  <= id_data[rsp_sel_id];
        rsp_rr      <= rsp_sel_id + 1'b1;

        id_valid[rsp_sel_id] <= 1'b0;
        id_ready[rsp_sel_id] <= 1'b0;
      end

      if (req_fire) begin
        id_valid[req_id_i] <= 1'b1;

        if (req_hit) begin
          id_ready[req_id_i] <= 1'b1;

          if (req_op_i) begin
            id_data[req_id_i] <= '0;
            dirty_array[req_set][req_hit_way] <= 1'b1;
            for (b = 0; b < (DATA_W/8); b = b + 1) begin
              if (req_mask_i[b]) begin
                data_array[req_set][req_hit_way][req_word][8*b +: 8]
                    <= req_data_i[8*b +: 8];
              end
            end
          end else begin
            id_data[req_id_i]
                <= data_array[req_set][req_hit_way][req_word];
          end
        end else begin
          id_ready[req_id_i] <= 1'b0;
          id_data[req_id_i]  <= '0;

          miss_valid[req_free_miss_idx]      <= 1'b1;
          miss_line_addr[req_free_miss_idx]  <= req_line_addr;
          miss_set[req_free_miss_idx]        <= req_set;
          miss_tag[req_free_miss_idx]        <= req_tag;
          miss_way[req_free_miss_idx]        <= '0;
          miss_word[req_free_miss_idx]       <= req_word;
          miss_id[req_free_miss_idx]         <= req_id_i;
          miss_op[req_free_miss_idx]         <= req_op_i;
          miss_store_data[req_free_miss_idx] <= req_data_i;
          miss_store_mask[req_free_miss_idx] <= req_mask_i;
        end
      end

      case (mem_state)
        MEM_IDLE: begin
          if (sched_valid) begin
            active_miss         <= sched_idx;
            miss_way[sched_idx] <= sched_way;
            miss_rr             <= sched_idx + 1'b1;

            tag_array[sched_set][sched_way]   <= miss_tag[sched_idx];
            valid_array[sched_set][sched_way] <= 1'b0;
            dirty_array[sched_set][sched_way] <= 1'b0;
            repl_ptr[sched_set]               <= sched_way + 1'b1;

            if (valid_array[sched_set][sched_way]) begin
              active_wb_addr <= {
                tag_array[sched_set][sched_way],
                sched_set,
                {BLOCK_OFF_W{1'b0}}
              };
            end else begin
              active_wb_addr <= 32'b0;
            end

            if (valid_array[sched_set][sched_way] &&
                dirty_array[sched_set][sched_way]) begin
              for (w = 0; w < BLOCK_WORDS; w = w + 1) begin
                wb_buf[w] <= data_array[sched_set][sched_way][w];
              end
              mem_state <= MEM_WB_REQ;
            end else begin
              mem_state <= MEM_FILL_REQ;
            end
          end
        end

        MEM_WB_REQ: begin
          if (mem_req_ready_i) begin
            wb_count  <= 2'b0;
            mem_state <= MEM_WB_DATA;
          end
        end

        MEM_WB_DATA: begin
          if (mem_wr_ready_i) begin
            if (wb_count == 2'd3) begin
              mem_state <= MEM_FILL_REQ;
            end else begin
              wb_count <= wb_count + 1'b1;
            end
          end
        end

        MEM_FILL_REQ: begin
          if (mem_req_ready_i) begin
            fill_count <= 2'b0;
            mem_state  <= MEM_FILL_DATA;
          end
        end

        MEM_FILL_DATA: begin
          if (mem_rd_valid_i) begin
            fill_buf[fill_count] <= mem_rd_data_i;

            if (fill_count == 2'd3) begin
              // The final beat is word 3.  Commit it directly while words
              // 0..2 come from the single fill buffer.
              for (w = 0; w < BLOCK_WORDS; w = w + 1) begin
                if (w == (BLOCK_WORDS-1)) begin
                  if (miss_op[active_miss] &&
                      (miss_word[active_miss] == w[1:0])) begin
                    data_array[miss_set[active_miss]]
                              [miss_way[active_miss]][w]
                        <= merge_store_word(
                             mem_rd_data_i,
                             miss_store_data[active_miss],
                             miss_store_mask[active_miss]);
                  end else begin
                    data_array[miss_set[active_miss]]
                              [miss_way[active_miss]][w]
                        <= mem_rd_data_i;
                  end
                end else begin
                  if (miss_op[active_miss] &&
                      (miss_word[active_miss] == w[1:0])) begin
                    data_array[miss_set[active_miss]]
                              [miss_way[active_miss]][w]
                        <= merge_store_word(
                             fill_buf[w],
                             miss_store_data[active_miss],
                             miss_store_mask[active_miss]);
                  end else begin
                    data_array[miss_set[active_miss]]
                              [miss_way[active_miss]][w]
                        <= fill_buf[w];
                  end
                end
              end

              valid_array[miss_set[active_miss]][miss_way[active_miss]]
                  <= 1'b1;
              dirty_array[miss_set[active_miss]][miss_way[active_miss]]
                  <= miss_op[active_miss];

              id_ready[miss_id[active_miss]] <= 1'b1;
              if (miss_op[active_miss]) begin
                id_data[miss_id[active_miss]] <= '0;
              end else if (miss_word[active_miss] == 2'd3) begin
                id_data[miss_id[active_miss]] <= mem_rd_data_i;
              end else begin
                id_data[miss_id[active_miss]]
                    <= fill_buf[miss_word[active_miss]];
              end

              miss_valid[active_miss] <= 1'b0;
              mem_state               <= MEM_IDLE;
            end else begin
              fill_count <= fill_count + 1'b1;
            end
          end
        end

        default: begin
          mem_state <= MEM_IDLE;
        end
      endcase
    end
  end

endmodule
