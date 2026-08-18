// Trivial WORKING submission, used to prove the scored path can also PASS.
//
// It is a cache in name only: it stores nothing, so every access misses and
// goes to memory. That is enough to satisfy the STEP 2 SKELETON testbench and
// nothing more -- it would fail C1 (one miss outstanding, not MAX_MISSES),
// C2 (no line is ever resident, so there is no hit to answer under a miss) and
// R5 (a store is dropped). It exists to show the harness discriminates, not to
// stand in for a submission.
// Never scored, never shipped.
module nonblocking_dcache #(
  parameter int unsigned DATA_W = 32, parameter int unsigned SETS = 16,
  parameter int unsigned WAYS = 4,    parameter int unsigned MAX_MISSES = 8
) (
  input logic clk_i, input logic rst_ni,
  input logic req_valid_i, output logic req_ready_o, input logic [3:0] req_id_i,
  input logic req_op_i, input logic [31:0] req_addr_i,
  input logic [DATA_W-1:0] req_data_i, input logic [(DATA_W/8)-1:0] req_mask_i,
  output logic rsp_valid_o, input logic rsp_ready_i,
  output logic [3:0] rsp_id_o, output logic [DATA_W-1:0] rsp_data_o,
  output logic mem_req_valid_o, input logic mem_req_ready_i,
  output logic mem_req_we_o, output logic [31:0] mem_req_addr_o,
  input logic mem_rd_valid_i, output logic mem_rd_ready_o, input logic [DATA_W-1:0] mem_rd_data_i,
  output logic mem_wr_valid_o, input logic mem_wr_ready_i, output logic [DATA_W-1:0] mem_wr_data_o
);
  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned WORD_SEL_W  = $clog2(DATA_W/8);
  localparam int unsigned BLK_OFF_W   = WORD_SEL_W + $clog2(BLOCK_WORDS);

  typedef enum logic [1:0] { S_IDLE, S_REQ, S_FILL, S_RSP } state_e;
  state_e state_q;

  logic [3:0]                    id_q;
  logic [31:0]                   addr_q;
  logic [DATA_W-1:0]             data_q;
  logic [$clog2(BLOCK_WORDS)-1:0] beat_q;

  wire [$clog2(BLOCK_WORDS)-1:0] want_beat = addr_q[BLK_OFF_W-1:WORD_SEL_W];

  assign req_ready_o     = (state_q == S_IDLE);
  assign mem_req_valid_o = (state_q == S_REQ);
  assign mem_req_we_o    = 1'b0;
  assign mem_req_addr_o  = {addr_q[31:BLK_OFF_W], {BLK_OFF_W{1'b0}}};
  assign mem_rd_ready_o  = (state_q == S_FILL);
  assign rsp_valid_o     = (state_q == S_RSP);
  assign rsp_id_o        = id_q;
  assign rsp_data_o      = data_q;
  assign mem_wr_valid_o  = 1'b0;
  assign mem_wr_data_o   = '0;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= S_IDLE;
      id_q    <= '0;
      addr_q  <= '0;
      data_q  <= '0;
      beat_q  <= '0;
    end
    else begin
      case (state_q)
        S_IDLE: if (req_valid_i) begin
                  id_q    <= req_id_i;
                  addr_q  <= req_addr_i;
                  beat_q  <= '0;
                  state_q <= S_REQ;
                end
        S_REQ:  if (mem_req_ready_i) state_q <= S_FILL;
        S_FILL: if (mem_rd_valid_i) begin
                  if (beat_q == want_beat) data_q <= mem_rd_data_i;
                  if (beat_q == $clog2(BLOCK_WORDS)'(BLOCK_WORDS-1)) state_q <= S_RSP;
                  beat_q <= beat_q + 1'b1;
                end
        S_RSP:  if (rsp_ready_i) state_q <= S_IDLE;
        default: state_q <= S_IDLE;
      endcase
    end
  end
endmodule
