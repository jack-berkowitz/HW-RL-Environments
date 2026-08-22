module nonblocking_dcache #(
  parameter int unsigned DATA_W      = 32,
  parameter int unsigned SETS        = 16,
  parameter int unsigned WAYS        = 4,
  parameter int unsigned MAX_MISSES  = 8
) (
  input  logic                      clk_i,
  input  logic                      rst_ni,

  input  logic                      req_valid_i,
  output logic                      req_ready_o,
  input  logic [3:0]                req_id_i,
  input  logic                      req_op_i,
  input  logic [31:0]               req_addr_i,
  input  logic [DATA_W-1:0]         req_data_i,
  input  logic [(DATA_W/8)-1:0]     req_mask_i,

  output logic                      rsp_valid_o,
  input  logic                      rsp_ready_i,
  output logic [3:0]                rsp_id_o,
  output logic [DATA_W-1:0]         rsp_data_o,

  output logic                      mem_req_valid_o,
  input  logic                      mem_req_ready_i,
  output logic                      mem_req_we_o,
  output logic [31:0]               mem_req_addr_o,

  input  logic                      mem_rd_valid_i,
  output logic                      mem_rd_ready_o,
  input  logic [DATA_W-1:0]         mem_rd_data_i,

  output logic                      mem_wr_valid_o,
  input  logic                      mem_wr_ready_i,
  output logic [DATA_W-1:0]         mem_wr_data_o
);

  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned BYTE_LANES  = DATA_W / 8;
  localparam int unsigned BYTE_OFF_W  = $clog2(BYTE_LANES);
  localparam int unsigned WORD_IDX_W  = $clog2(BLOCK_WORDS);
  localparam int unsigned BLOCK_OFF_W = BYTE_OFF_W + WORD_IDX_W;
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned TAG_W       = 32 - BLOCK_OFF_W - SET_W;
  localparam int unsigned WAY_IDX_W   = (WAYS <= 1) ? 1 : $clog2(WAYS);
  localparam int unsigned MSHR_IDX_W  =
    (MAX_MISSES <= 1) ? 1 : $clog2(MAX_MISSES);

  typedef enum logic [2:0] {
    MEM_IDLE,
    MEM_WB_REQ,
    MEM_WB_DATA,
    MEM_RD_REQ,
    MEM_RD_DATA
  } mem_state_t;

  logic [DATA_W-1:0] data_mem
    [0:SETS-1][0:WAYS-1][0:BLOCK_WORDS-1];
  logic [TAG_W-1:0] tag_mem [0:SETS-1][0:WAYS-1];
  logic valid_mem [0:SETS-1][0:WAYS-1];
  logic dirty_mem [0:SETS-1][0:WAYS-1];
  logic [WAY_IDX_W-1:0] replace_way [0:SETS-1];

  logic miss_valid [0:MAX_MISSES-1];
  logic [31:0] miss_line [0:MAX_MISSES-1];
  logic [3:0] miss_id [0:MAX_MISSES-1];
  logic miss_op [0:MAX_MISSES-1];
  logic [WORD_IDX_W-1:0] miss_word [0:MAX_MISSES-1];
  logic [DATA_W-1:0] miss_data [0:MAX_MISSES-1];
  logic [BYTE_LANES-1:0] miss_mask [0:MAX_MISSES-1];

  mem_state_t mem_state_q;
  logic [MSHR_IDX_W-1:0] active_miss_q;
  logic [MSHR_IDX_W-1:0] schedule_ptr_q;
  logic [SET_W-1:0] active_set_q;
  logic [WAY_IDX_W-1:0] active_way_q;
  logic [TAG_W-1:0] active_tag_q;
  logic [31:0] victim_addr_q;
  logic [DATA_W-1:0] wb_data_q [0:BLOCK_WORDS-1];
  logic [WORD_IDX_W-1:0] beat_q;
  logic [DATA_W-1:0] load_data_q;

  logic [31:0] req_line_comb;
  logic [SET_W-1:0] req_set_comb;
  logic [TAG_W-1:0] req_tag_comb;
  logic [WORD_IDX_W-1:0] req_word_comb;
  logic req_hit_comb;
  logic [WAY_IDX_W-1:0] req_hit_way_comb;
  logic same_miss_comb;
  logic free_miss_comb;
  logic [MSHR_IDX_W-1:0] free_miss_idx_comb;

  logic any_miss_comb;
  logic schedule_valid_comb;
  logic [MSHR_IDX_W-1:0] schedule_idx_comb;
  logic [SET_W-1:0] schedule_set_comb;
  logic [TAG_W-1:0] schedule_tag_comb;
  logic [WAY_IDX_W-1:0] victim_way_comb;
  logic invalid_way_comb;
  logic response_space_comb;
  logic fill_finishing_comb;

  function automatic logic [DATA_W-1:0] masked_word(
    input logic [DATA_W-1:0]     old_word,
    input logic [DATA_W-1:0]     new_word,
    input logic [BYTE_LANES-1:0] byte_mask
  );
    integer byte_num;
    begin
      masked_word = old_word;
      for (
        byte_num = 0;
        byte_num < BYTE_LANES;
        byte_num = byte_num + 1
      ) begin
        if (byte_mask[byte_num]) begin
          masked_word[byte_num*8 +: 8] =
            new_word[byte_num*8 +: 8];
        end
      end
    end
  endfunction

  always_comb begin : request_lookup
    integer way_num;
    integer miss_num;

    req_line_comb =
      {req_addr_i[31:BLOCK_OFF_W], {BLOCK_OFF_W{1'b0}}};
    req_set_comb       = req_addr_i[BLOCK_OFF_W +: SET_W];
    req_tag_comb       = req_addr_i[31 -: TAG_W];
    req_word_comb      = req_addr_i[BYTE_OFF_W +: WORD_IDX_W];
    req_hit_comb       = 1'b0;
    req_hit_way_comb   = '0;
    same_miss_comb     = 1'b0;
    free_miss_comb     = 1'b0;
    free_miss_idx_comb = '0;

    for (
      way_num = 0;
      way_num < WAYS;
      way_num = way_num + 1
    ) begin
      if (!req_hit_comb &&
          valid_mem[req_set_comb][way_num] &&
          (tag_mem[req_set_comb][way_num] == req_tag_comb)) begin
        req_hit_comb     = 1'b1;
        req_hit_way_comb = way_num[WAY_IDX_W-1:0];
      end
    end

    for (
      miss_num = 0;
      miss_num < MAX_MISSES;
      miss_num = miss_num + 1
    ) begin
      if (miss_valid[miss_num] &&
          (miss_line[miss_num] == req_line_comb)) begin
        same_miss_comb = 1'b1;
      end

      if (!free_miss_comb && !miss_valid[miss_num]) begin
        free_miss_comb     = 1'b1;
        free_miss_idx_comb = miss_num[MSHR_IDX_W-1:0];
      end
    end
  end

  always_comb begin : scheduler_lookup
    integer miss_num;
    integer candidate;
    integer way_num;

    any_miss_comb       = 1'b0;
    schedule_valid_comb = 1'b0;
    schedule_idx_comb   = '0;
    schedule_set_comb   = '0;
    schedule_tag_comb   = '0;
    victim_way_comb     = '0;
    invalid_way_comb    = 1'b0;

    for (
      miss_num = 0;
      miss_num < MAX_MISSES;
      miss_num = miss_num + 1
    ) begin
      if (miss_valid[miss_num]) begin
        any_miss_comb = 1'b1;
      end

      candidate = (schedule_ptr_q + miss_num) % MAX_MISSES;

      if (!schedule_valid_comb && miss_valid[candidate]) begin
        schedule_valid_comb = 1'b1;
        schedule_idx_comb   = candidate[MSHR_IDX_W-1:0];
      end
    end

    if (schedule_valid_comb) begin
      schedule_set_comb =
        miss_line[schedule_idx_comb][BLOCK_OFF_W +: SET_W];
      schedule_tag_comb =
        miss_line[schedule_idx_comb][31 -: TAG_W];
      victim_way_comb =
        replace_way[schedule_set_comb];

      for (
        way_num = 0;
        way_num < WAYS;
        way_num = way_num + 1
      ) begin
        if (!invalid_way_comb &&
            !valid_mem[schedule_set_comb][way_num]) begin
          invalid_way_comb = 1'b1;
          victim_way_comb  = way_num[WAY_IDX_W-1:0];
        end
      end
    end
  end

  always_comb begin : interface_outputs
    response_space_comb = !rsp_valid_o || rsp_ready_i;

    fill_finishing_comb =
      (mem_state_q == MEM_RD_DATA) &&
      (beat_q == BLOCK_WORDS-1) &&
      mem_rd_valid_i &&
      response_space_comb;

    req_ready_o     = 1'b0;
    mem_req_valid_o = 1'b0;
    mem_req_we_o    = 1'b0;
    mem_req_addr_o  = 32'b0;
    mem_rd_ready_o  = 1'b0;
    mem_wr_valid_o  = 1'b0;
    mem_wr_data_o   = '0;

    if (rst_ni &&
        req_valid_i &&
        !((mem_state_q == MEM_IDLE) && any_miss_comb) &&
        !fill_finishing_comb) begin
      if (req_hit_comb) begin
        req_ready_o = response_space_comb;
      end else if (!same_miss_comb && free_miss_comb) begin
        req_ready_o = 1'b1;
      end
    end

    case (mem_state_q)
      MEM_WB_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b1;
        mem_req_addr_o  = victim_addr_q;
      end

      MEM_WB_DATA: begin
        mem_wr_valid_o = 1'b1;
        mem_wr_data_o  = wb_data_q[beat_q];
      end

      MEM_RD_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b0;
        mem_req_addr_o  = miss_line[active_miss_q];
      end

      MEM_RD_DATA: begin
        if (beat_q == BLOCK_WORDS-1) begin
          mem_rd_ready_o = response_space_comb;
        end else begin
          mem_rd_ready_o = 1'b1;
        end
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : cache_state
    integer set_num;
    integer way_num;
    integer miss_num;
    integer word_num;

    if (!rst_ni) begin
      rsp_valid_o    <= 1'b0;
      rsp_id_o       <= 4'b0;
      rsp_data_o     <= '0;
      mem_state_q    <= MEM_IDLE;
      active_miss_q  <= '0;
      schedule_ptr_q <= '0;
      active_set_q   <= '0;
      active_way_q   <= '0;
      active_tag_q   <= '0;
      victim_addr_q  <= 32'b0;
      beat_q         <= '0;
      load_data_q    <= '0;

      for (
        set_num = 0;
        set_num < SETS;
        set_num = set_num + 1
      ) begin
        replace_way[set_num] <= '0;

        for (
          way_num = 0;
          way_num < WAYS;
          way_num = way_num + 1
        ) begin
          valid_mem[set_num][way_num] <= 1'b0;
          dirty_mem[set_num][way_num] <= 1'b0;
        end
      end

      for (
        miss_num = 0;
        miss_num < MAX_MISSES;
        miss_num = miss_num + 1
      ) begin
        miss_valid[miss_num] <= 1'b0;
      end

      for (
        word_num = 0;
        word_num < BLOCK_WORDS;
        word_num = word_num + 1
      ) begin
        wb_data_q[word_num] <= '0;
      end
    end else begin
      if (rsp_valid_o && rsp_ready_i) begin
        rsp_valid_o <= 1'b0;
      end

      if (req_valid_i && req_ready_o) begin
        if (req_hit_comb) begin
          rsp_valid_o <= 1'b1;
          rsp_id_o    <= req_id_i;

          if (req_op_i) begin
            data_mem
              [req_set_comb]
              [req_hit_way_comb]
              [req_word_comb] <=
                masked_word(
                  data_mem
                    [req_set_comb]
                    [req_hit_way_comb]
                    [req_word_comb],
                  req_data_i,
                  req_mask_i
                );

            dirty_mem
              [req_set_comb]
              [req_hit_way_comb] <= 1'b1;

            rsp_data_o <= '0;
          end else begin
            rsp_data_o <=
              data_mem
                [req_set_comb]
                [req_hit_way_comb]
                [req_word_comb];
          end
        end else begin
          miss_valid[free_miss_idx_comb] <= 1'b1;
          miss_line[free_miss_idx_comb]  <= req_line_comb;
          miss_id[free_miss_idx_comb]    <= req_id_i;
          miss_op[free_miss_idx_comb]    <= req_op_i;
          miss_word[free_miss_idx_comb]  <= req_word_comb;
          miss_data[free_miss_idx_comb]  <= req_data_i;
          miss_mask[free_miss_idx_comb]  <= req_mask_i;
        end
      end

      case (mem_state_q)
        MEM_IDLE: begin
          beat_q <= '0;

          if (schedule_valid_comb) begin
            active_miss_q <= schedule_idx_comb;
            active_set_q  <= schedule_set_comb;
            active_way_q  <= victim_way_comb;
            active_tag_q  <= schedule_tag_comb;

            victim_addr_q <= {
              tag_mem[schedule_set_comb][victim_way_comb],
              schedule_set_comb,
              {BLOCK_OFF_W{1'b0}}
            };

            for (
              word_num = 0;
              word_num < BLOCK_WORDS;
              word_num = word_num + 1
            ) begin
              wb_data_q[word_num] <=
                data_mem
                  [schedule_set_comb]
                  [victim_way_comb]
                  [word_num];
            end

            valid_mem
              [schedule_set_comb]
              [victim_way_comb] <= 1'b0;

            dirty_mem
              [schedule_set_comb]
              [victim_way_comb] <= 1'b0;

            if (victim_way_comb == WAYS-1) begin
              replace_way[schedule_set_comb] <= '0;
            end else begin
              replace_way[schedule_set_comb] <=
                victim_way_comb + 1'b1;
            end

            if (schedule_idx_comb == MAX_MISSES-1) begin
              schedule_ptr_q <= '0;
            end else begin
              schedule_ptr_q <= schedule_idx_comb + 1'b1;
            end

            if (valid_mem[schedule_set_comb][victim_way_comb] &&
                dirty_mem[schedule_set_comb][victim_way_comb]) begin
              mem_state_q <= MEM_WB_REQ;
            end else begin
              mem_state_q <= MEM_RD_REQ;
            end
          end
        end

        MEM_WB_REQ: begin
          if (mem_req_valid_o && mem_req_ready_i) begin
            beat_q      <= '0;
            mem_state_q <= MEM_WB_DATA;
          end
        end

        MEM_WB_DATA: begin
          if (mem_wr_valid_o && mem_wr_ready_i) begin
            if (beat_q == BLOCK_WORDS-1) begin
              beat_q      <= '0;
              mem_state_q <= MEM_RD_REQ;
            end else begin
              beat_q <= beat_q + 1'b1;
            end
          end
        end

        MEM_RD_REQ: begin
          if (mem_req_valid_o && mem_req_ready_i) begin
            beat_q      <= '0;
            load_data_q <= '0;
            mem_state_q <= MEM_RD_DATA;
          end
        end

        MEM_RD_DATA: begin
          if (mem_rd_valid_i && mem_rd_ready_o) begin
            if (miss_op[active_miss_q] &&
                (miss_word[active_miss_q] == beat_q)) begin
              data_mem
                [active_set_q]
                [active_way_q]
                [beat_q] <=
                  masked_word(
                    mem_rd_data_i,
                    miss_data[active_miss_q],
                    miss_mask[active_miss_q]
                  );
            end else begin
              data_mem
                [active_set_q]
                [active_way_q]
                [beat_q] <= mem_rd_data_i;
            end

            if (!miss_op[active_miss_q] &&
                (miss_word[active_miss_q] == beat_q)) begin
              load_data_q <= mem_rd_data_i;
            end

            if (beat_q == BLOCK_WORDS-1) begin
              tag_mem
                [active_set_q]
                [active_way_q] <= active_tag_q;

              valid_mem
                [active_set_q]
                [active_way_q] <= 1'b1;

              dirty_mem
                [active_set_q]
                [active_way_q] <= miss_op[active_miss_q];

              rsp_valid_o <= 1'b1;
              rsp_id_o    <= miss_id[active_miss_q];

              if (miss_op[active_miss_q]) begin
                rsp_data_o <= '0;
              end else if (
                miss_word[active_miss_q] == beat_q
              ) begin
                rsp_data_o <= mem_rd_data_i;
              end else begin
                rsp_data_o <= load_data_q;
              end

              miss_valid[active_miss_q] <= 1'b0;
              beat_q      <= '0;
              mem_state_q <= MEM_IDLE;
            end else begin
              beat_q <= beat_q + 1'b1;
            end
          end
        end

        default: begin
          mem_state_q <= MEM_IDLE;
        end
      endcase
    end
  end

endmodule