// step 5c: this defect re-derived IN dut2's OWN SOURCE, not as a wrapper.
// v_ca07 SECOND DUT -- an independent implementation. MUST BE ACCEPTED.
module clk_ratio_div (
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

  wire pass = (div_q < 4'd2);                    // P3: 0 and 1 both pass through
  wire same = div_valid_i && (div_i == div_q);

  // P2: 50% duty at EVERY divisor. At an even divisor the high phase is
  // div/2 whole cycles. At an ODD divisor it is a HALF-INTEGER, which cannot be
  // built from posedge logic alone: the second term below is the first delayed
  // half a cycle, and their AND is high for exactly div/2 -- 1.5 cycles at
  // div=3. A first version used floor(div/2) whole cycles and produced 33% at
  // div=3, which is not this contract.
  wire       odd  = div_q[0];
  // FIVE bits, not four. (div_q + 1) at div_q = 15 wraps to zero in 4-bit
  // arithmetic, the high phase becomes zero, and the clock never starts -- which
  // is what it did, at the top of the range only.
  wire [4:0] hi_p = odd ? (({1'b0, div_q} + 5'd1) >> 1) : ({1'b0, div_q} >> 1);
  wire       phase_p = ({1'b0, cnt} < hi_p);
  logic      phase_n;
  always_ff @(negedge clk_i or negedge rst_ni)
    if (!rst_ni) phase_n <= 1'b0; else phase_n <= phase_p;

  // H3: a same-value offer is granted in the SAME cycle and does not gate.
  // L3: a real change is also granted immediately -- the anchor waits.
  // ---- guard state, in this design's own terms ----------------------------
  int p_nsame, p_nodd, p_ndefer, p_nen, p_nrst, p_nchange;
  logic p_en_q, p_def_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      p_nsame<=0; p_nodd<=0; p_ndefer<=0; p_nen<=0; p_nchange<=0;
      p_en_q<=1'b1; p_def_q<=1'b0;
    end else begin
      p_en_q <= en_i;
      if (en_i != p_en_q) p_nen <= p_nen + 1;
      if ((st == RUN) && div_valid_i) begin
        if (same) p_nsame <= p_nsame + 1;
        else begin
          p_nchange <= p_nchange + 1;
          if (div_i[0] && div_i >= 4'd3) p_nodd <= p_nodd + 1;
        end
      end
      if ((st == GATE) && div_valid_i && !p_def_q) p_ndefer <= p_ndefer + 1;
      p_def_q <= (st == GATE) && div_valid_i;
    end
  end
  int p_nrst_q = 0;
  always_ff @(negedge rst_ni) p_nrst_q <= p_nrst_q + 1;

  // "in transition", READ FROM THE PORTS rather than from st. How long this
  // design's own GATE state lasts is L2 latitude, and keying a defect on it
  // made the defect UNREACHABLE here, because this design leaves GATE almost
  // at once. The window from accepting a change to the first rising edge of
  // the new clock is the CONTRACT's notion and both bases have it.
  logic p_busy, p_clk_q;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin p_busy <= 1'b0; p_clk_q <= 1'b0; end
    else begin
      p_clk_q <= clk_o;
      if (div_valid_i && div_ready_o && !same) p_busy <= 1'b1;
      else if (clk_o && !p_clk_q)              p_busy <= 1'b0;
    end

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
            gate_left <= (div_i < 4'd2) ? 2'd2 : 2'd0;
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
  wire divided  = odd ? (phase_p & phase_n) : phase_p;
  wire gate_src = pass ? clk_i : divided;
  logic run_en;
  always_ff @(negedge clk_i or negedge rst_ni)
    // The gate may only ever change while the signal it gates is LOW. Opening
    // it onto a phase that is already high emits a runt pulse; closing it on a
    // high phase truncates one. Both are glitches, and this module's whole
    // claim is that it does not make them. Found in step 5c, when the reference
    // was extended to check the period a reconfiguration settles at.
    if (!rst_ni)        run_en <= 1'b0;
    else if (!gate_src) run_en <= en_i && (st == RUN);

  assign clk_o  = run_en & gate_src;
endmodule
