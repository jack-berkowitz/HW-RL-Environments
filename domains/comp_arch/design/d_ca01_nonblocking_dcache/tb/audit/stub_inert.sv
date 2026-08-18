// Trivial NON-WORKING submission, used to prove the scored path DISCRIMINATES.
// Every output is tied off. It must FAIL. A path that passes this is not
// measuring anything -- the "control that fails everything validates nothing"
// hazard has a twin: a harness that passes everything.
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
  assign req_ready_o     = 1'b0;
  assign rsp_valid_o     = 1'b0;
  assign rsp_id_o        = '0;
  assign rsp_data_o      = '0;
  assign mem_req_valid_o = 1'b0;
  assign mem_req_we_o    = 1'b0;
  assign mem_req_addr_o  = '0;
  assign mem_rd_ready_o  = 1'b0;
  assign mem_wr_valid_o  = 1'b0;
  assign mem_wr_data_o   = '0;
endmodule
