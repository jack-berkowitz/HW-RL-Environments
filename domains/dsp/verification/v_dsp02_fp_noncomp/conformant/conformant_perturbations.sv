// =============================================================================
// conformant_perturbations.sv -- these MUST SURVIVE.
// =============================================================================
// Each wraps the UNMODIFIED golden and changes something spec section 10 leaves
// open. A submitted testbench must ACCEPT every one; a failure here means it
// checked something the specification never promised.
//
// The port list and the golden instantiation are machine-emitted so that all
// eleven wrappers here and in mutants/ are identical outside their one injected
// change. A hand-copied port list is where a wrapper defect hides, and a broken
// wrapper reads as a checker defect (CONVENTIONS.md).
// =============================================================================
// ----------------------------------------------------------------------------
// Licence: latitude 1 (latency).
// One extra register stage on the outputs, with a combinational upstream ready:
// exactly one more cycle of latency and no loss of throughput.
module fn_c1_extra_latency (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,
    input  logic        in_valid_i,
    output logic        in_ready_o,
    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,
    output logic        out_valid_o,
    input  logic        out_ready_i
);

  logic [31:0] g_res;  logic [9:0] g_cls;  logic [4:0] g_st;
  logic        g_valid, g_ready;
  logic [31:0] r_res;  logic [9:0] r_cls;  logic [4:0] r_st;  logic r_valid;

  wire fire = r_valid & out_ready_i;
  wire free = ~r_valid | fire;
  assign g_ready     = free;
  assign out_valid_o = r_valid;
  assign result_o    = r_res;
  assign class_mask_o= r_cls;
  assign status_o    = r_st;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) r_valid <= 1'b0;
    else begin
      if (fire) r_valid <= 1'b0;
      if (free && g_valid) begin
        r_valid <= 1'b1; r_res <= g_res; r_cls <= g_cls; r_st <= g_st;
      end
    end
  end
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (operand_a_i),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (g_res),
      .class_mask_o (g_cls),
      .status_o     (g_st),
      .out_valid_o  (g_valid),
      .out_ready_i  (g_ready)
  );
endmodule

// ----------------------------------------------------------------------------
// Licence: latitude 2.
// result_o, class_mask_o and status_o are unconstrained while out_valid_o is low,
// so this drives LFSR noise there. A testbench sampling them without qualifying
// on out_valid_o fails here and only here.
module fn_c2_garbage_when_invalid (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,
    input  logic        in_valid_i,
    output logic        in_ready_o,
    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,
    output logic        out_valid_o,
    input  logic        out_ready_i
);

  logic [31:0] g_res;  logic [9:0] g_cls;  logic [4:0] g_st;  logic g_valid;
  logic [31:0] lfsr;
  always_ff @(posedge clk_i)
    if (!rst_ni) lfsr <= 32'h1357_9BDF;
    else         lfsr <= {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};

  assign out_valid_o  = g_valid;
  assign result_o     = g_valid ? g_res : lfsr;
  assign class_mask_o = g_valid ? g_cls : lfsr[9:0];
  assign status_o     = g_valid ? g_st  : lfsr[4:0];
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (operand_a_i),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (g_res),
      .class_mask_o (g_cls),
      .status_o     (g_st),
      .out_valid_o  (g_valid),
      .out_ready_i  (out_ready_i)
  );
endmodule

// ----------------------------------------------------------------------------
// Licence: latitude 3.
// in_ready_o may be low on any cycle for any reason. Valid in and ready out are
// gated TOGETHER, so no cycle exists in which the golden accepts an operation the
// source does not know about.
module fn_c3_ready_withheld (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,
    input  logic        in_valid_i,
    output logic        in_ready_o,
    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,
    output logic        out_valid_o,
    input  logic        out_ready_i
);

  logic [1:0] cnt;
  logic       g_valid_in, g_ready;
  always_ff @(posedge clk_i) if (!rst_ni) cnt <= '0; else cnt <= cnt + 1;
  wire block = (cnt == 2'd0);
  assign g_valid_in = in_valid_i & ~block;
  assign in_ready_o = g_ready    & ~block;
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (operand_a_i),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (g_valid_in),
      .in_ready_o   (g_ready),
      .result_o     (result_o),
      .class_mask_o (class_mask_o),
      .status_o     (status_o),
      .out_valid_o  (out_valid_o),
      .out_ready_i  (out_ready_i)
  );
endmodule

// ----------------------------------------------------------------------------
// Licence: latitude 4.
// result_o is unconstrained when the operation is CLASSIFY. The operation is
// tracked through a queue because results are delivered in order (H2), so the
// override lands on the right result under any backpressure.
module fn_c4_garbage_result_on_classify (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,
    input  logic        in_valid_i,
    output logic        in_ready_o,
    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,
    output logic        out_valid_o,
    input  logic        out_ready_i
);

  logic [31:0] g_res;  logic g_valid;
  logic [1:0]  opq [$];
  logic [31:0] lfsr;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      opq.delete();
      lfsr <= 32'h2468_ACE0;
    end else begin
      lfsr <= {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
      if (in_valid_i  && in_ready_o)  opq.push_back(op_i);
      if (out_valid_o && out_ready_i && opq.size() > 0) void'(opq.pop_front());
    end
  end

  wire is_class = (opq.size() > 0) && (opq[0] == 2'd3);
  assign out_valid_o = g_valid;
  assign result_o    = is_class ? lfsr : g_res;
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (operand_a_i),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (g_res),
      .class_mask_o (class_mask_o),
      .status_o     (status_o),
      .out_valid_o  (g_valid),
      .out_ready_i  (out_ready_i)
  );
endmodule

// ----------------------------------------------------------------------------
// Licence: latitude 5.
// class_mask_o is unconstrained for every operation other than CLASSIFY.
module fn_c5_garbage_class_when_not_classify (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,
    input  logic        in_valid_i,
    output logic        in_ready_o,
    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,
    output logic        out_valid_o,
    input  logic        out_ready_i
);

  logic [9:0] g_cls;  logic g_valid;
  logic [1:0] opq [$];
  logic [31:0] lfsr;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      opq.delete();
      lfsr <= 32'h0F1E_2D3C;
    end else begin
      lfsr <= {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
      if (in_valid_i  && in_ready_o)  opq.push_back(op_i);
      if (out_valid_o && out_ready_i && opq.size() > 0) void'(opq.pop_front());
    end
  end

  wire is_class = (opq.size() > 0) && (opq[0] == 2'd3);
  assign out_valid_o  = g_valid;
  assign class_mask_o = is_class ? g_cls : lfsr[9:0];
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (operand_a_i),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (result_o),
      .class_mask_o (g_cls),
      .status_o     (status_o),
      .out_valid_o  (g_valid),
      .out_ready_i  (out_ready_i)
  );
endmodule
