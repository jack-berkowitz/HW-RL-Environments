// Non-equivalence witness harness -- rule 16. Scoring support, never shipped.
//
// Drives the golden and ONE mutant from a SHARED input sequence and compares
// their observable outputs every cycle. Payload is masked by its own valid and
// in_ready_o is masked by in_valid_i, because clause H3 says a ready bit
// carries no meaning while its input is not offering -- comparing it raw would
// report differences nothing can observe.
//
// Each input advances to its next beat only once BOTH sides have accepted the
// current one, so the two see an identical sequence and any difference in
// ready timing is itself a witness.
//
// Build once per mutant:  -DMUT_MOD=xb_mN_...
`ifndef MUT_MOD
  `define MUT_MOD xb_m1_fixed_priority
`endif

module nonequiv_tb;
  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;

  logic clk = 1'b0; always #5 clk = ~clk;
  logic rst_n = 1'b0;
  logic [N_IN*DW-1:0] in_data;
  logic [N_IN*SW-1:0] in_sel;
  logic [N_IN-1:0]    in_valid;
  logic [N_OUT-1:0]   out_ready;

  `define OUTS(p) logic [N_IN-1:0] p``_iready; logic [N_OUT*DW-1:0] p``_odata; \
                  logic [N_OUT*IW-1:0] p``_oidx; logic [N_OUT-1:0] p``_ovalid;
  `OUTS(g)
  `OUTS(m)

  `define CONN(p) \
    .clk_i(clk), .rst_ni(rst_n), .in_data_i(in_data), .in_sel_i(in_sel), \
    .in_valid_i(in_valid), .in_ready_o(p``_iready), .out_data_o(p``_odata), \
    .out_idx_o(p``_oidx), .out_valid_o(p``_ovalid), .out_ready_i(out_ready)

  route_xbar #(.N_IN(N_IN),.N_OUT(N_OUT),.DATA_W(DW),.SEL_W(SW),.IDX_W(IW)) i_g (`CONN(g));
  `MUT_MOD   #(.N_IN(N_IN),.N_OUT(N_OUT),.DATA_W(DW),.SEL_W(SW),.IDX_W(IW)) i_m (`CONN(m));

  int cyc = 0; always @(posedge clk) if (rst_n) cyc <= cyc + 1;

  // observable projection
  function automatic logic [N_OUT*(DW+IW)-1:0] proj(input logic [N_OUT*DW-1:0] d,
                                                    input logic [N_OUT*IW-1:0] x,
                                                    input logic [N_OUT-1:0] v);
    logic [N_OUT*(DW+IW)-1:0] r;
    r = '0;
    for (int unsigned j = 0; j < N_OUT; j++)
      if (v[j]) r[j*(DW+IW) +: (DW+IW)] = {d[j*DW +: DW], x[j*IW +: IW]};
    return r;
  endfunction

  int    diff_cyc = -1;
  string diff_what = "";
  always @(posedge clk) if (rst_n && diff_cyc < 0) begin
    automatic logic [N_IN-1:0] gr, mr;
    gr = g_iready & in_valid;  mr = m_iready & in_valid;
    if (g_ovalid !== m_ovalid) begin
      diff_cyc = cyc;
      diff_what = $sformatf("out_valid_o: golden %b / mutant %b", g_ovalid, m_ovalid);
    end else if (proj(g_odata, g_oidx, g_ovalid) !== proj(m_odata, m_oidx, m_ovalid)) begin
      diff_cyc = cyc;
      for (int unsigned j = 0; j < N_OUT; j++)
        if (g_ovalid[j] && (g_odata[j*DW +: DW] !== m_odata[j*DW +: DW]
                            || g_oidx[j*IW +: IW] !== m_oidx[j*IW +: IW]))
          diff_what = $sformatf("output %0d: golden data=%08x idx=%0d / mutant data=%08x idx=%0d",
                                j, g_odata[j*DW +: DW], g_oidx[j*IW +: IW],
                                m_odata[j*DW +: DW], m_oidx[j*IW +: IW]);
    end else if (gr !== mr) begin
      diff_cyc = cyc;
      diff_what = $sformatf("in_ready_o (masked by in_valid_i): golden %b / mutant %b", gr, mr);
    end
  end

  // ---- shared stimulus ----
  int nxt [N_IN];      // next beat number per input
  int sel_of [N_IN];
  int idle_left [N_IN];

  // Deterministic PRNG -- the witness cycle numbers in mutants/README.md are
  // only reproducible because this is not $urandom.
  int unsigned rs = 32'h1234_5678;
  function automatic int unsigned rnd();
    rs ^= rs << 13; rs ^= rs >> 17; rs ^= rs << 5; return rs;
  endfunction
  task automatic present(input int k);
    in_data[k*DW +: DW] = 32'h5A00_0000 + 32'(k << 20) + 32'(nxt[k]);
    in_sel [k*SW +: SW] = SW'(sel_of[k]);
    in_valid[k] = 1'b1;
  endtask

  initial begin
    for (int k = 0; k < N_IN; k++) begin nxt[k] = 0; sel_of[k] = 0; end
    in_data = '0; in_sel = '0; in_valid = '0; out_ready = '1;
    repeat (4) @(posedge clk); @(negedge clk) rst_n = 1'b1;

    // phase 1: every input hammers OUTPUT 0 -- the contention case
    @(negedge clk); for (int k = 0; k < N_IN; k++) begin sel_of[k] = 0; present(k); end
    for (int t = 0; t < 40 && diff_cyc < 0; t++) begin
      @(posedge clk);
      @(negedge clk);
      for (int k = 0; k < N_IN; k++)
        if (g_iready[k] && m_iready[k]) begin nxt[k]++; present(k); end
    end

    // phase 2: each input to its own output, with backpressure walking
    for (int k = 0; k < N_IN; k++) sel_of[k] = k;
    @(negedge clk); for (int k = 0; k < N_IN; k++) present(k);
    for (int t = 0; t < 40 && diff_cyc < 0; t++) begin
      @(negedge clk); out_ready = ~(4'b0001 << (t % 4));
      @(posedge clk);
      @(negedge clk);
      for (int k = 0; k < N_IN; k++)
        if (g_iready[k] && m_iready[k]) begin nxt[k]++; present(k); end
    end

    // phase 3: everyone to the HIGH outputs, all sinks ready
    @(negedge clk); out_ready = '1;
    for (int k = 0; k < N_IN; k++) sel_of[k] = 2 + (k % 2);
    @(negedge clk); for (int k = 0; k < N_IN; k++) present(k);
    for (int t = 0; t < 40 && diff_cyc < 0; t++) begin
      @(posedge clk);
      @(negedge clk);
      for (int k = 0; k < N_IN; k++)
        if (g_iready[k] && m_iready[k]) begin nxt[k]++; present(k); end
    end

    // phase 4: change the SET OF CONTENDERS while an output is offering but
    // stalled. An arbiter that does not lock its decision in can re-aim a beat
    // it has already offered; one that does cannot. Nothing before this phase
    // varies the request pattern once an output is stalled, so nothing before
    // it could tell the two apart.
    @(negedge clk); in_valid = '0; out_ready = '1;
    repeat (4) @(posedge clk);
    @(negedge clk); out_ready = 4'b1110;            // output 0 stalled
    sel_of[0] = 0; nxt[0]++; present(0);            // only input 0 offers
    repeat (3) @(posedge clk);
    @(negedge clk); sel_of[1] = 0; nxt[1]++; present(1);   // input 1 joins the contest
    repeat (6) @(posedge clk);
    @(negedge clk); sel_of[2] = 0; nxt[2]++; present(2);   // and input 2
    repeat (6) @(posedge clk);
    @(negedge clk); out_ready = '1;                 // let it drain
    repeat (10) @(posedge clk);

    // phase 5: long randomized soak.
    //
    // Phases 1-4 are targeted and short, and against the GUARDED mutant set
    // they are not enough: a defect that only fires on the 64th delivery, or
    // after an input has been idle for eight cycles, or when exactly three
    // inputs contend, is invisible to 120 cycles of fixed stimulus. This soak
    // cycles through four request modes -- random, four-way collision on one
    // output, three-way collision, and identity -- while the backpressure
    // pattern periodically stalls every output for twelve consecutive cycles.
    // That constructs the configurations the guards name, and runs long enough
    // to pass the counting thresholds.
    //
    // H2 is respected throughout: an input that has asserted in_valid_i holds
    // it, with the same payload, until BOTH sides have accepted. Idles are
    // entered only from an accepted beat, never by withdrawing an offer.
    @(negedge clk); in_valid = '0; out_ready = '1;
    for (int k = 0; k < N_IN; k++) idle_left[k] = k * 3;
    for (int t = 0; t < 4000 && diff_cyc < 0; t++) begin
      automatic int mode = (t / 40) % 4;
      @(negedge clk);

      // 1) harvest what the posedge just before this negedge accepted
      for (int k = 0; k < N_IN; k++)
        if (in_valid[k] && g_iready[k] && m_iready[k]) begin
          nxt[k]++;
          if ((rnd() % 100) < 30) begin                  // step away for a while
            in_valid[k] = 1'b0;
            idle_left[k] = 1 + int'(rnd() % 12);         // reaches the idle>=8 guards
          end else begin
            in_valid[k] = 1'b0;                          // re-offer below
          end
        end

      // 2) backpressure, including long full stalls
      if      ((t % 97) < 12) out_ready = 4'b0000;             // every output stalled
      else if ((t % 53) < 10) out_ready = ~(4'b0001 << (t % 4));
      else if ((t % 31) <  9) out_ready = 4'b0001;             // only output 0 drains
      else                    out_ready = '1;

      // 3) offers -- only for inputs not currently holding one
      for (int k = 0; k < N_IN; k++) begin
        if (!in_valid[k]) begin
          if (idle_left[k] > 0) idle_left[k]--;
          else begin
            case (mode)
              0: sel_of[k] = int'(rnd() % N_OUT);   // random
              1: sel_of[k] = 0;                     // four-way collision
              2: sel_of[k] = (k < 3) ? 1 : 2;       // exactly three contend
              default: sel_of[k] = k;               // identity
            endcase
            present(k);
          end
        end
      end

      @(posedge clk);
    end

    if (diff_cyc >= 0)
      $display("WITNESS %s: first difference at cycle %0d -- %s", `"`MUT_MOD`", diff_cyc, diff_what);
    else
      $display("WITNESS %s: NO DIFFERENCE OBSERVED -- treat the HARNESS as suspect, not the mutant",
               `"`MUT_MOD`");
    $finish;
  end
  initial begin #300000; $display("WITNESS %s: watchdog, diff_cyc=%0d -- %s",
                                  `"`MUT_MOD`", diff_cyc, diff_what); $finish; end
endmodule
