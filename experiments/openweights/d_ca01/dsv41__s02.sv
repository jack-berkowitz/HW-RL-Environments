module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,   // {32, 64}
  parameter int unsigned SETS       = 16,   // {8, 16}
  parameter int unsigned WAYS       = 4,    // {2, 4}
  parameter int unsigned MAX_MISSES = 8     // {2, 8}
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
  localparam int unsigned BYTE_OFF_W  = $clog2(DATA_W/8);
  localparam int unsigned SET_IDX_W   = $clog2(SETS);
  localparam int unsigned WAY_IDX_W   = $clog2(WAYS);
  localparam int unsigned TAG_W       = 32 - BYTE_OFF_W - 2 - SET_IDX_W;
  localparam int unsigned MISS_PTR_W  = $clog2(MAX_MISSES);
  localparam int unsigned MISS_CNT_W  = $clog2(MAX_MISSES + 1);

  localparam int unsigned RSP_DEPTH   = 8;
  localparam int unsigned RSP_PTR_W   = $clog2(RSP_DEPTH);
  localparam int unsigned RSP_CNT_W   = $clog2(RSP_DEPTH + 1);

  localparam logic [2:0] ST_IDLE     = 3'd0;
  localparam logic [2:0] ST_WB_REQ   = 3'd1;
  localparam logic [2:0] ST_WB_DATA  = 3'd2;
  localparam logic [2:0] ST_FILL_REQ = 3'd3;
  localparam logic [2:0] ST_FILL_DATA= 3'd4;
  localparam logic [2:0] ST_RSP      = 3'd5;

  logic [DATA_W-1:0] data_array [0:SETS-1][0:WAYS-1][0:BLOCK_WORDS-1];
  logic [TAG_W-1:0]  tags       [0:SETS-1][0:WAYS-1];
  logic              valid      [0:SETS-1][0:WAYS-1];
  logic              dirty      [0:SETS-1][0:WAYS-1];
  logic [WAY_IDX_W-1:0] rr      [0:SETS-1];

  logic [MISS_PTR_W-1:0] miss_head;
  logic [MISS_PTR_W-1:0] miss_tail;
  logic [MISS_CNT_W-1:0] miss_count;

  logic [3:0]               miss_id   [0:MAX_MISSES-1];
  logic                     miss_op   [0:MAX_MISSES-1];
  logic [31:0]              miss_addr [0:MAX_MISSES-1];
  logic [DATA_W-1:0]        miss_wdata[0:MAX_MISSES-1];
  logic [(DATA_W/8)-1:0]    miss_mask [0:MAX_MISSES-1];

  logic [RSP_PTR_W-1:0] rsp_head;
  logic [RSP_PTR_W-1:0] rsp_tail;
  logic [RSP_CNT_W-1:0] rsp_count;

  logic [DATA_W-1:0] rsp_fifo_data [0:RSP_DEPTH-1];
  logic [3:0]        rsp_fifo_id   [0:RSP_DEPTH-1];

  logic [2:0] state;

  logic [31:0] cur_block_addr;
  logic [31:0] wb_addr;

  logic [SET_IDX_W-1:0] cur_set;
  logic [WAY_IDX_W-1:0] cur_way;
  logic [TAG_W-1:0]     cur_tag;
  logic [1:0]           cur_word_off;
  logic                 cur_op;
  logic [3:0]           cur_id;
  logic [DATA_W-1:0]    cur_store_data;
  logic [(DATA_W/8)-1:0] cur_store_mask;
  logic [DATA_W-1:0]    cur_load_data;

  logic [1:0] fill_beat;
  logic [1:0] wb_beat;

  logic [DATA_W-1:0] wb_data [0:BLOCK_WORDS-1];

  logic               pending_rsp_valid;
  logic [3:0]         pending_rsp_id;
  logic [DATA_W-1:0]  pending_rsp_data;

  logic req_hit;
  logic [WAY_IDX_W-1:0] req_hit_way;
  logic head_hit;
  logic [WAY_IDX_W-1:0] head_hit_way;

  logic [DATA_W-1:0] fill_write_data;

  integer hi_req, hi_head, bi;
  integer si, wi, b;

  wire [SET_IDX_W-1:0] req_set;
  wire [1:0]           req_word_off;
  wire [TAG_W-1:0]     req_tag;

  wire [3:0]           head_id;
  wire                 head_op;
  wire [31:0]          head_addr;
  wire [DATA_W-1:0]    head_wdata;
  wire [(DATA_W/8)-1:0] head_mask;
  wire [SET_IDX_W-1:0] head_set;
  wire [1:0]           head_word_off;
  wire [TAG_W-1:0]     head_tag;
  wire [31:0]          head_block_addr;

  wire req_hit_eff;
  wire sched_idle;
  wire hit_allowed;
  wire miss_allowed;
  wire miss_fifo_full;
  wire rsp_pop;
  wire rsp_can_push;
  wire miss_push;
  wire hit_push;
  wire miss_pop;
  wire rsp_push_miss;
  wire rsp_push;

  assign req_set      = req_addr_i[BYTE_OFF_W+2 +: SET_IDX_W];
  assign req_word_off = req_addr_i[BYTE_OFF_W +: 2];
  assign req_tag      = req_addr_i[31 -: TAG_W];

  assign head_id       = miss_id[miss_head];
  assign head_op       = miss_op[miss_head];
  assign head_addr     = miss_addr[miss_head];
  assign head_wdata    = miss_wdata[miss_head];
  assign head_mask     = miss_mask[miss_head];
  assign head_set      = head_addr[BYTE_OFF_W+2 +: SET_IDX_W];
  assign head_word_off = head_addr[BYTE_OFF_W +: 2];
  assign head_tag      = head_addr[31 -: TAG_W];
  assign head_block_addr = {head_tag, head_set, {(BYTE_OFF_W+2){1'b0}}};

  always_comb begin
    req_hit     = 1'b0;
    req_hit_way = '0;
    for (hi_req = 0; hi_req < WAYS; hi_req = hi_req + 1) begin
      if (valid[req_set][hi_req] && (tags[req_set][hi_req] == req_tag)) begin
        req_hit     = 1'b1;
        req_hit_way = hi_req[WAY_IDX_W-1:0];
      end
    end
  end

  always_comb begin
    head_hit     = 1'b0;
    head_hit_way = '0;
    for (hi_head = 0; hi_head < WAYS; hi_head = hi_head + 1) begin
      if (valid[head_set][hi_head] && (tags[head_set][hi_head] == head_tag)) begin
        head_hit     = 1'b1;
        head_hit_way = hi_head[WAY_IDX_W-1:0];
      end
    end
  end

  always_comb begin
    fill_write_data = mem_rd_data_i;
    if ((cur_op == 1'b1) && (fill_beat == cur_word_off)) begin
      for (bi = 0; bi < DATA_W/8; bi = bi + 1) begin
        if (cur_store_mask[bi]) begin
          fill_write_data[bi*8 +: 8] = cur_store_data[bi*8 +: 8];
        end
      end
    end
  end

  assign rsp_valid_o = (rsp_count != 0);
  assign rsp_id_o    = rsp_fifo_id[rsp_head];
  assign rsp_data_o  = rsp_fifo_data[rsp_head];

  assign rsp_pop       = rsp_valid_o && rsp_ready_i;
  assign rsp_can_push  = (rsp_count < RSP_DEPTH) || (rsp_pop && (rsp_count > 0));
  assign miss_fifo_full= (miss_count == MAX_MISSES);

  assign sched_idle = (state == ST_IDLE) && (miss_count != 0) && !pending_rsp_valid;
  assign hit_allowed = !pending_rsp_valid && rsp_can_push && !sched_idle;
  assign miss_allowed= !miss_fifo_full;

  assign req_hit_eff = req_valid_i && req_hit;
  assign req_ready_o = req_hit_eff ? hit_allowed : miss_allowed;

  assign miss_push = req_valid_i && req_ready_o && !req_hit;
  assign hit_push  = req_valid_i && req_ready_o &&  req_hit;

  assign miss_pop      = (state == ST_RSP) && pending_rsp_valid && rsp_can_push;
  assign rsp_push_miss = miss_pop;
  assign rsp_push      = rsp_push_miss || hit_push;

  always_comb begin
    mem_req_valid_o = 1'b0;
    mem_req_we_o    = 1'b0;
    mem_req_addr_o  = 32'b0;
    mem_rd_ready_o  = 1'b0;
    mem_wr_valid_o  = 1'b0;
    mem_wr_data_o   = '0;

    case (state)
      ST_WB_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b1;
        mem_req_addr_o  = wb_addr;
      end
      ST_FILL_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b0;
        mem_req_addr_o  = cur_block_addr;
      end
      ST_WB_DATA: begin
        mem_wr_valid_o = 1'b1;
        mem_wr_data_o  = wb_data[wb_beat];
      end
      ST_FILL_DATA: begin
        mem_rd_ready_o = 1'b1;
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state <= ST_IDLE;

      for (si = 0; si < SETS; si = si + 1) begin
        for (wi = 0; wi < WAYS; wi = wi + 1) begin
          valid[si][wi] <= 1'b0;
          dirty[si][wi] <= 1'b0;
          tags[si][wi]  <= '0;
        end
        rr[si] <= '0;
      end

      miss_head  <= '0;
      miss_tail  <= '0;
      miss_count <= '0;

      rsp_head   <= '0;
      rsp_tail   <= '0;
      rsp_count  <= '0;

      pending_rsp_valid <= 1'b0;
      pending_rsp_id    <= '0;
      pending_rsp_data  <= '0;

      cur_block_addr <= '0;
      wb_addr        <= '0;

      cur_set        <= '0;
      cur_way        <= '0;
      cur_tag        <= '0;
      cur_word_off   <= '0;
      cur_op         <= 1'b0;
      cur_id         <= '0;
      cur_store_data <= '0;
      cur_store_mask <= '0;
      cur_load_data  <= '0;

      fill_beat <= '0;
      wb_beat   <= '0;
    end else begin

      if (rsp_push_miss) begin
        rsp_fifo_data[rsp_tail] <= pending_rsp_data;
        rsp_fifo_id[rsp_tail]   <= pending_rsp_id;
      end else if (hit_push) begin
        if (req_op_i == 1'b0) begin
          rsp_fifo_data[rsp_tail] <= data_array[req_set][req_hit_way][req_word_off];
        end else begin
          rsp_fifo_data[rsp_tail] <= '0;
        end
        rsp_fifo_id[rsp_tail] <= req_id_i;
      end

      if (rsp_pop) begin
        rsp_head <= rsp_head + 1'b1;
      end
      if (rsp_push) begin
        rsp_tail <= rsp_tail + 1'b1;
      end

      if (rsp_push && !rsp_pop) begin
        rsp_count <= rsp_count + 1'b1;
      end else if (!rsp_push && rsp_pop) begin
        rsp_count <= rsp_count - 1'b1;
      end

      if (miss_push) begin
        miss_id[miss_tail]    <= req_id_i;
        miss_op[miss_tail]    <= req_op_i;
        miss_addr[miss_tail]  <= req_addr_i;
        miss_wdata[miss_tail] <= req_data_i;
        miss_mask[miss_tail]  <= req_mask_i;
        miss_tail <= miss_tail + 1'b1;
      end

      if (miss_pop) begin
        miss_head <= miss_head + 1'b1;
      end

      if (miss_push && !miss_pop) begin
        miss_count <= miss_count + 1'b1;
      end else if (!miss_push && miss_pop) begin
        miss_count <= miss_count - 1'b1;
      end

      if (hit_push) begin
        if (req_op_i == 1'b1) begin
          for (b = 0; b < DATA_W/8; b = b + 1) begin
            if (req_mask_i[b]) begin
              data_array[req_set][req_hit_way][req_word_off][b*8 +: 8] <= req_data_i[b*8 +: 8];
            end
          end
          dirty[req_set][req_hit_way] <= 1'b1;
        end
      end

      if (miss_pop) begin
        pending_rsp_valid <= 1'b0;
        state             <= ST_IDLE;
      end

      case (state)
        ST_IDLE: begin
          if ((miss_count != 0) && !pending_rsp_valid) begin
            if (head_hit) begin
              if (head_op == 1'b1) begin
                for (b = 0; b < DATA_W/8; b = b + 1) begin
                  if (head_mask[b]) begin
                    data_array[head_set][head_hit_way][head_word_off][b*8 +: 8] <= head_wdata[b*8 +: 8];
                  end
                end
                dirty[head_set][head_hit_way] <= 1'b1;
              end

              pending_rsp_valid <= 1'b1;
              pending_rsp_id    <= head_id;
              if (head_op == 1'b0) begin
                pending_rsp_data <= data_array[head_set][head_hit_way][head_word_off];
              end else begin
                pending_rsp_data <= '0;
              end
              state <= ST_RSP;
            end else begin
              cur_set        <= head_set;
              cur_way        <= rr[head_set];
              cur_tag        <= head_tag;
              cur_word_off   <= head_word_off;
              cur_op         <= head_op;
              cur_id         <= head_id;
              cur_store_data <= head_wdata;
              cur_store_mask <= head_mask;
              cur_block_addr <= head_block_addr;

              rr[head_set] <= (rr[head_set] == WAYS-1) ? '0 : (rr[head_set] + 1'b1);

              valid[head_set][rr[head_set]] <= 1'b0;
              dirty[head_set][rr[head_set]] <= 1'b0;

              if (valid[head_set][rr[head_set]] && dirty[head_set][rr[head_set]]) begin
                for (wi = 0; wi < BLOCK_WORDS; wi = wi + 1) begin
                  wb_data[wi] <= data_array[head_set][rr[head_set]][wi];
                end
                wb_addr <= {tags[head_set][rr[head_set]], head_set, {(BYTE_OFF_W+2){1'b0}}};
                state   <= ST_WB_REQ;
              end else begin
                state <= ST_FILL_REQ;
              end
            end
          end
        end

        ST_WB_REQ: begin
          if (mem_req_ready_i) begin
            wb_beat <= '0;
            state   <= ST_WB_DATA;
          end
        end

        ST_WB_DATA: begin
          if (mem_wr_ready_i) begin
            if (wb_beat == BLOCK_WORDS-1) begin
              state <= ST_FILL_REQ;
            end else begin
              wb_beat <= wb_beat + 1'b1;
            end
          end
        end

        ST_FILL_REQ: begin
          if (mem_req_ready_i) begin
            fill_beat <= '0;
            state     <= ST_FILL_DATA;
          end
        end

        ST_FILL_DATA: begin
          if (mem_rd_valid_i) begin
            data_array[cur_set][cur_way][fill_beat] <= fill_write_data;

            if ((cur_op == 1'b0) && (fill_beat == cur_word_off)) begin
              cur_load_data <= mem_rd_data_i;
            end

            if (fill_beat == BLOCK_WORDS-1) begin
              valid[cur_set][cur_way] <= 1'b1;
              dirty[cur_set][cur_way] <= (cur_op == 1'b1) ? (|cur_store_mask) : 1'b0;
              tags[cur_set][cur_way]  <= cur_tag;

              pending_rsp_valid <= 1'b1;
              pending_rsp_id    <= cur_id;

              if (cur_op == 1'b0) begin
                if (cur_word_off == BLOCK_WORDS-1) begin
                  pending_rsp_data <= mem_rd_data_i;
                end else begin
                  pending_rsp_data <= cur_load_data;
                end
              end else begin
                pending_rsp_data <= '0;
              end

              state <= ST_RSP;
            end else begin
              fill_beat <= fill_beat + 1'b1;
            end
          end
        end

        ST_RSP: begin
        end

        default: begin
          state <= ST_IDLE;
        end
      endcase
    end
  end

endmodule
