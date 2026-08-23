// v_ai02 POLICY-DIVERGENT PERTURBATION -- this MUST BE ACCEPTED.
//
// Opposite sign to mutants/: this satisfies the contract and must survive.
//
// It is NOT a wrapper. It is an independent implementation written from
// spec/stream_realign_spec.md alone -- an explicit popcount and a case-selected
// join, against the anchor's barrel shifter with its width-truncated shift
// amounts -- and it takes the OPPOSITE choice on both named latitude clauses:
//
//   L1  the golden accepts a line's FIRST beat whether or not the sink is
//       ready, since that beat produces no output. This one makes every beat,
//       first included, wait for the sink.
//   L2  the golden drives the computed value on pop_data_o even while
//       pop_valid_o is low. This one drives a fixed pattern there instead.
//
// A reference testbench that fails this is encoding the golden's readiness
// policy rather than the contract.
module stream_realign (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        clear_i,
  input  logic        realign_i,
  input  logic        first_i,
  input  logic        last_i,
  input  logic [3:0]  strb_i,
  input  logic [31:0] push_data_i,
  input  logic [3:0]  push_strb_i,
  input  logic        push_valid_i,
  output logic        push_ready_o,
  output logic [31:0] pop_data_o,
  output logic [3:0]  pop_strb_o,
  output logic        pop_valid_o,
  input  logic        pop_ready_i
);
  logic [31:0] held_q;
  logic [2:0]  rot_q;

  function automatic logic [2:0] popcnt(input logic [3:0] s);
    automatic int n = 0;
    for (int i = 0; i < 4; i++) n += int'(s[i]);
    return 3'(n);
  endfunction

  // The join, selected by case rather than computed with shift amounts that
  // rely on their own width truncation. R2's two extremes are explicit here.
  function automatic logic [31:0] joined(input logic [31:0] cur,
                                         input logic [31:0] prev,
                                         input logic [2:0]  r);
    unique case (r)
      3'd0:    joined = cur;
      3'd1:    joined = {cur[23:0], prev[31:24]};
      3'd2:    joined = {cur[15:0], prev[31:16]};
      3'd3:    joined = {cur[7:0],  prev[31:8]};
      default: joined = prev;                     // r == 4: a whole beat
    endcase
  endfunction

  wire produce = realign_i ? (push_valid_i && !first_i && (last_i || (|strb_i)))
                           : push_valid_i;

  // ---- mutant guard state: the SAME contract-level quantities as the golden
  // base, recomputed from this implementation's own ports.
  logic [7:0] g_line_q, g_beat_q, g_stall_q, g_out_q, g_hold_q;
  logic [1:0] g_rel_q;
  logic       g_realigned_q;
  wire        g_deliver = produce && push_ready_o;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      g_line_q <= '0; g_beat_q <= '0; g_stall_q <= '0; g_out_q <= '0;
      g_hold_q <= '0; g_rel_q <= 2'd0; g_realigned_q <= 1'b0;
    end else begin
      if (realign_i) g_realigned_q <= 1'b1;
      if ((g_stall_q >= 8'd8) && !(pop_valid_o && !pop_ready_i)) g_hold_q <= 8'd20;
      else if (g_hold_q != 8'd0)                                 g_hold_q <= g_hold_q - 8'd1;
      if (clear_i) begin
        g_line_q <= '0; g_beat_q <= '0; g_stall_q <= '0; g_rel_q <= 2'd0;
      end else begin
        if (pop_valid_o && !pop_ready_i) g_stall_q <= g_stall_q + 8'd1;
        else                             g_stall_q <= '0;
        if ((g_stall_q >= 8'd4) && !(pop_valid_o && !pop_ready_i)) g_rel_q <= 2'd3;
        else if (g_rel_q != 2'd0)                                  g_rel_q <= g_rel_q - 2'd1;
        if (g_deliver) g_out_q <= g_out_q + 8'd1;
        if (push_valid_i && push_ready_o) begin
          if (first_i) begin g_line_q <= g_line_q + 8'd1; g_beat_q <= 8'd1; end
          else                g_beat_q <= g_beat_q + 8'd1;
        end
      end
    end
  end

  assign pop_valid_o = produce;
  // clause L2 -- the golden drives the computed value here regardless
  assign pop_data_o  = !produce ? 32'hDEAD_BEEF
                     : realign_i ? joined(push_data_i, held_q, rot_q)
                                 : push_data_i;
  assign pop_strb_o  = !produce ? 4'h0 : (realign_i ? 4'hF : push_strb_i);

  // clause L1 -- every beat waits for the sink, the first one included
  assign push_ready_o = pop_ready_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      held_q <= '0; rot_q <= '0;
    end else if (clear_i) begin
      held_q <= '0; rot_q <= '0;
    end else if (push_valid_i && push_ready_o && realign_i) begin
      if (g_rel_q == 2'd0) held_q <= push_data_i;
      if (first_i) rot_q <= popcnt(strb_i);        // R4: captured at the first beat only
    end
  end
endmodule
