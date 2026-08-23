// v_ca04 POLICY-DIVERGENT PERTURBATION -- this MUST BE ACCEPTED.
//
// Opposite sign to mutants/: this satisfies the contract and must survive.
//
// It is NOT a wrapper. It is an independent crossbar written from
// spec/route_xbar_spec.md alone, and it takes the OPPOSITE choice on the named
// latitude clauses:
//
//   L2  the golden's rotation runs UPWARD -- after serving input k the next
//       contender favoured is k+1. This one runs DOWNWARD, favouring k-1. Both
//       satisfy the A2 window; they differ in the order within it.
//   L3  the golden's outputs are combinational in its inputs, so a beat can be
//       accepted and delivered in the same cycle. This one REGISTERS every
//       output, so a beat is always delivered the cycle after it is accepted.
//   L1  and therefore its latency differs by a cycle throughout.
//
// A reference testbench that fails this is encoding the golden's rotation
// direction or its zero-latency path rather than the contract.
module route_xbar #(
  parameter int unsigned N_IN   = 4,
  parameter int unsigned N_OUT  = 4,
  parameter int unsigned DATA_W = 32,
  parameter int unsigned SEL_W  = 2,
  parameter int unsigned IDX_W  = 2
) (
  input  logic                    clk_i,
  input  logic                    rst_ni,
  input  logic [N_IN*DATA_W-1:0]  in_data_i,
  input  logic [N_IN*SEL_W-1:0]   in_sel_i,
  input  logic [N_IN-1:0]         in_valid_i,
  output logic [N_IN-1:0]         in_ready_o,
  output logic [N_OUT*DATA_W-1:0] out_data_o,
  output logic [N_OUT*IDX_W-1:0]  out_idx_o,
  output logic [N_OUT-1:0]        out_valid_o,
  input  logic [N_OUT-1:0]        out_ready_i
);
  // one held beat per output -- registered, so delivery is never same-cycle
  logic [N_OUT-1:0]      held_v;
  logic [DATA_W-1:0]     held_d [N_OUT];
  logic [IDX_W-1:0]      held_x [N_OUT];
  logic [IDX_W-1:0]      rot    [N_OUT];   // the contender favoured next

  // ---- MUTANT bookkeeping, on contract-level state only -------------------
  logic [N_OUT-1:0][7:0] mstall, midle;
  logic [N_OUT-1:0][6:0] mdeliv;
  logic [N_OUT-1:0][3:0] mturn;
  int mtarget [N_OUT];
  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      mtarget[j] = 0;
      for (int unsigned k = 0; k < N_IN; k++)
        if (in_valid_i[k] && sel_of(int'(k)) == int'(j)) mtarget[j]++;
    end
  end
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin mstall <= '0; midle <= '0; mdeliv <= '0; mturn <= '0; end
    else for (int unsigned j = 0; j < N_OUT; j++) begin
      mstall[j] <= (held_v[j] && !out_ready_i[j]) ? (mstall[j] + 8'd1) : 8'd0;
      midle[j]  <= held_v[j] ? 8'd0 : (midle[j] + 8'd1);
      if (held_v[j] && out_ready_i[j]) begin
        mdeliv[j] <= (mdeliv[j] == 7'd63) ? 7'd0 : (mdeliv[j] + 7'd1);
        mturn[j]  <= (mturn[j] == 4'd10) ? 4'd0 : (mturn[j] + 4'd1);
      end
    end
  end

  logic [N_OUT-1:0]      grant_v;
  int                    grant_k [N_OUT];
  logic [N_OUT-1:0]      can_take;

  function automatic int sel_of(input int k);
    return int'(in_sel_i[k*SEL_W +: SEL_W]);
  endfunction

  // A slot can take a new beat if it is empty, or if the beat it holds is
  // moving this cycle. Clause A3 falls out of the register: a held beat is
  // never replaced until it has moved.
  always_comb
    for (int unsigned j = 0; j < N_OUT; j++)
      can_take[j] = !held_v[j] || out_ready_i[j] || (mstall[j] >= 8'd8);

  // Round robin DOWNWARD from the favoured index (clause L2, opposite choice).
  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      grant_v[j] = 1'b0;
      grant_k[j] = 0;
      for (int unsigned n = 0; n < N_IN; n++) begin
        automatic int kk = (int'(rot[j]) - int'(n) + 2*int'(N_IN)) % int'(N_IN);
        if (!grant_v[j] && in_valid_i[kk] && sel_of(kk) == int'(j)) begin
          grant_v[j] = 1'b1;
          grant_k[j] = kk;
        end
      end
    end
  end

  always_comb begin
    in_ready_o = '0;
    for (int unsigned k = 0; k < N_IN; k++) begin
      automatic int j = sel_of(k);
      if (in_valid_i[k] && grant_v[j] && grant_k[j] == int'(k) && can_take[j])
        in_ready_o[k] = 1'b1;
    end
  end

  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      out_data_o[j*DATA_W +: DATA_W] = held_d[j];
      out_idx_o [j*IDX_W  +: IDX_W]  = held_x[j];
    end
  end
  assign out_valid_o = held_v;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      held_v <= '0;
      for (int unsigned j = 0; j < N_OUT; j++) begin
        held_d[j] <= '0; held_x[j] <= '0; rot[j] <= IDX_W'(N_IN - 1);
      end
    end else begin
      for (int unsigned j = 0; j < N_OUT; j++) begin
        if (held_v[j] && out_ready_i[j]) held_v[j] <= 1'b0;
        if (can_take[j] && grant_v[j]) begin
          held_v[j] <= 1'b1;
          held_d[j] <= in_data_i[grant_k[j]*DATA_W +: DATA_W];
          held_x[j] <= IDX_W'(grant_k[j]);
          rot[j]    <= IDX_W'((grant_k[j] + int'(N_IN) - 1) % int'(N_IN));
        end
      end
    end
  end
endmodule
