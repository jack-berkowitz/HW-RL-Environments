// Bounded miter: gold (reference shim) vs gate (mutant), identical inputs.
// Outputs are compared QUALIFIED BY VALIDITY -- an unqualified compare makes a
// mutant that only perturbs a payload trivially non-equivalent at cycle 0,
// which is true and worthless. A counterexample here is a PROOF of
// non-equivalence at bounded depth, not a statement about one stimulus.
module miter (
  input  logic clk_i, input logic rst_ni,
  input  logic req_valid_i, input logic [3:0] req_id_i, input logic req_op_i,
  input  logic [31:0] req_addr_i, input logic [31:0] req_data_i, input logic [3:0] req_mask_i,
  input  logic rsp_ready_i, input logic mem_req_ready_i,
  input  logic mem_rd_valid_i, input logic [31:0] mem_rd_data_i, input logic mem_wr_ready_i
);
  logic g_rq_rdy, g_rs_v, g_mrq_v, g_mrq_we, g_mrd_rdy, g_mwr_v;
  logic [3:0] g_rs_id; logic [31:0] g_rs_d, g_mrq_a, g_mwr_d;
  logic t_rq_rdy, t_rs_v, t_mrq_v, t_mrq_we, t_mrd_rdy, t_mwr_v;
  logic [3:0] t_rs_id; logic [31:0] t_rs_d, t_mrq_a, t_mwr_d;

  gold u_g (.clk_i, .rst_ni, .req_valid_i, .req_ready_o(g_rq_rdy), .req_id_i, .req_op_i,
    .req_addr_i, .req_data_i, .req_mask_i, .rsp_valid_o(g_rs_v), .rsp_ready_i,
    .rsp_id_o(g_rs_id), .rsp_data_o(g_rs_d), .mem_req_valid_o(g_mrq_v), .mem_req_ready_i,
    .mem_req_we_o(g_mrq_we), .mem_req_addr_o(g_mrq_a), .mem_rd_valid_i,
    .mem_rd_ready_o(g_mrd_rdy), .mem_rd_data_i, .mem_wr_valid_o(g_mwr_v),
    .mem_wr_ready_i, .mem_wr_data_o(g_mwr_d));
  gate u_t (.clk_i, .rst_ni, .req_valid_i, .req_ready_o(t_rq_rdy), .req_id_i, .req_op_i,
    .req_addr_i, .req_data_i, .req_mask_i, .rsp_valid_o(t_rs_v), .rsp_ready_i,
    .rsp_id_o(t_rs_id), .rsp_data_o(t_rs_d), .mem_req_valid_o(t_mrq_v), .mem_req_ready_i,
    .mem_req_we_o(t_mrq_we), .mem_req_addr_o(t_mrq_a), .mem_rd_valid_i,
    .mem_rd_ready_o(t_mrd_rdy), .mem_rd_data_i, .mem_wr_valid_o(t_mwr_v),
    .mem_wr_ready_i, .mem_wr_data_o(t_mwr_d));

  always @(posedge clk_i) if (rst_ni) begin
    a_rq_rdy: assert (g_rq_rdy  == t_rq_rdy);
    a_rs_v:   assert (g_rs_v    == t_rs_v);
    a_mrq_v:  assert (g_mrq_v   == t_mrq_v);
    a_mwr_v:  assert (g_mwr_v   == t_mwr_v);
    a_mrd_r:  assert (g_mrd_rdy == t_mrd_rdy);
    if (g_rs_v)  begin a_rs_id: assert (g_rs_id == t_rs_id);
                       a_rs_d:  assert (g_rs_d  == t_rs_d);  end
    if (g_mrq_v) begin a_we:    assert (g_mrq_we == t_mrq_we);
                       a_addr:  assert (g_mrq_a  == t_mrq_a); end
    if (g_mwr_v) begin a_wd:    assert (g_mwr_d  == t_mwr_d); end
  end
endmodule
