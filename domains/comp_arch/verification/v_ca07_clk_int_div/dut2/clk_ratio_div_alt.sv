// v_ca07 SECOND DUT -- an independent implementation. MUST BE ACCEPTED.
module clk_ratio_div_alt (
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       en_i,
  input  logic       test_mode_en_i,
  input  logic [3:0] div_i,
  input  logic       div_valid_i,
  output logic       div_ready_o,
  output logic       clk_o,
  output logic [3:0] cycl_count_o
);
  // -------------------------------------------------------------------------
  // An INDEPENDENT implementation of spec/clk_ratio_div_spec.md, written from
  // the specification. It does not instantiate the anchor and shares no code
  // with it. It takes the OPPOSITE legal choice on every one of the five named
  // latitude clauses:
  //
  //   L1  PHASE. Its period begins on the input edge after the transition ends,
  //       so the counter starts at zero there. The anchor's phase is its own.
  //   L2  GATING DURATION. It resumes in TWO input cycles from acceptance, below
  //       G1's bound, where the anchor sits at the bound and EXACTLY attains it
  //       on every transition to pass-through. A first attempt gated for two
  //       cycles and, with the negedge enable register on top, came to a gap of
  //       FOUR -- outside a bound of three. Being slower is not automatically
  //       safer when the clause is an upper bound.
  //   L3  WHEN div_ready_o RISES for a real change. Immediately, in the cycle
  //       the offer is seen. The anchor takes one to four cycles.
  //   L4  DEFERRAL LENGTH for a second request during a transition. About two
  //       cycles here; measured at eight on the anchor.
  //   L5  cycl_count_o WHILE GATED. Held at zero here. The anchor counts over
  //       the new divisor immediately.
  //
  // A testbench that fails this is encoding the anchor's timing rather than the
  // contract.
  // -------------------------------------------------------------------------
  typedef enum logic [1:0] {RUN, GATE} st_e;
  st_e         st;
  logic [3:0]  div_q;      // the divisor in force
  logic [3:0]  cnt;
  logic [1:0]  gate_left;

  wire pass    = (div_q < 4'd2);                 // P3: 0 and 1 both pass through
  wire [3:0] hi_cycles = div_q >> 1;             // P2: high = floor(div/2)
  wire same    = div_valid_i && (div_i == div_q);

  // H3: a same-value offer is granted in the SAME cycle and does not gate.
  // L3: a real change is also granted immediately -- the anchor waits.
  assign div_ready_o = (st == RUN) && div_valid_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      st <= RUN; div_q <= 4'd0; cnt <= '0; gate_left <= '0;   // R2: default divisor
    end else begin
      case (st)
        RUN: begin
          cnt <= (pass || (cnt >= div_q - 4'd1)) ? '0 : cnt + 4'd1;
          if (div_valid_i && !same) begin
            div_q     <= div_i;
            cnt       <= '0;
            gate_left <= 2'd0;                  // L2: resume as early as legal
            st        <= GATE;
          end
        end
        GATE: begin                              // H4: a second offer is DEFERRED
          cnt <= '0;                             // L5: counter held at zero
          if (gate_left == 2'd0) st <= RUN;
          else gate_left <= gate_left - 2'd1;
        end
        default: st <= RUN;
      endcase
    end
  end

  // C1/C2: 0..div-1 while running, constant 0 in pass-through
  assign cycl_count_o = pass ? 4'd0 : cnt;

  // The output. G2 says gated means idle LOW, and E3 says disabling must not
  // truncate a pulse, so the enable is taken on the NEGATIVE edge -- it changes
  // while the output is low, in both the pass-through and the divided path.
  logic run_en;
  always_ff @(negedge clk_i or negedge rst_ni)
    if (!rst_ni) run_en <= 1'b0;
    else         run_en <= en_i && (st == RUN);

  wire divided = (cnt < hi_cycles);
  assign clk_o = run_en & (pass ? clk_i : divided);
endmodule
