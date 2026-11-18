module stream_realign_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  logic rst_n = 1'b0;
  logic clr   = 1'b0;

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_clear();
    @(negedge clk) clr = 1'b1;
    @(negedge clk) clr = 1'b0;
    repeat (2) @(posedge clk);
  endtask

  logic        ra = 1'b0, fst = 1'b0, lst = 1'b0;
  logic [3:0]  strb = 4'hF;
  logic [31:0] pdata = '0;
  logic [3:0]  pstrb = 4'hF;
  logic        pvalid = 1'b0, pready;
  logic [31:0] qdata;
  logic [3:0]  qstrb;
  logic        qvalid;
  logic        qready = 1'b1;

  stream_realign dut (
    .clk_i(clk), .rst_ni(rst_n), .clear_i(clr), .realign_i(ra), .first_i(fst),
    .last_i(lst), .strb_i(strb), .push_data_i(pdata), .push_strb_i(pstrb),
    .push_valid_i(pvalid), .push_ready_o(pready), .pop_data_o(qdata),
    .pop_strb_o(qstrb), .pop_valid_o(qvalid), .pop_ready_i(qready));

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  dstrb;
    logic        first;
    logic        last;
    logic        realign;
    logic [3:0]  lstrb;
  } bfm_beat_t;

  bfm_beat_t bfm_q [$];

  task automatic bfm_send(input logic [31:0] data, input bit first, input bit last,
                          input bit do_realign, input logic [3:0] lstrb,
                          input logic [3:0] dstrb = 4'hF);
    bfm_beat_t b;
    b.data = data; b.dstrb = dstrb; b.first = first; b.last = last;
    b.realign = do_realign; b.lstrb = lstrb;
    bfm_q.push_back(b);
  endtask

  task automatic bfm_ready(input bit v); qready = v; endtask

  task automatic bfm_idle(input int max_cycles = 400);
    for (int t = 0; t < max_cycles; t++) begin
      @(posedge clk);
      if (bfm_q.size() == 0 && !pvalid) break;
    end
    repeat (6) @(posedge clk);
  endtask

  logic bfm_hs;
  always @(posedge clk) bfm_hs <= (rst_n && !clr) ? (pvalid & pready) : 1'b0;

  always @(negedge clk) begin
    if (!rst_n) begin
      pvalid = 1'b0;
    end else begin
      if (bfm_hs && bfm_q.size() > 0) begin void'(bfm_q.pop_front()); pvalid = 1'b0; end
      if (!pvalid && bfm_q.size() > 0) begin
        pdata = bfm_q[0].data;  pstrb = bfm_q[0].dstrb; fst = bfm_q[0].first;
        lst   = bfm_q[0].last;  strb  = bfm_q[0].lstrb; ra  = bfm_q[0].realign;
        pvalid = 1'b1;
      end
    end
  end

  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// CHECKER
// ---------------------------------------------------------------------------
  typedef struct packed {
    logic [31:0] data;
    bit          wc;      // wildcard: value depends on L4 latitude
  } exp_t;

  exp_t        e_cur;
  exp_t        exp_q [$];

  bit          line_on;
  bit          wc_next;
  int          rot_r;
  logic [31:0] ret_data;
  int          acc_cnt;
  int          owed_cnt;
  int          edge_cnt;
  bit          failed;
  bit          hs_in, hs_out;

  // sampled snapshot (one-cycle lag, consistent for every check)
  logic        s_pvalid = 0, s_pready = 0, s_qvalid = 0, s_qready = 0;
  logic        s_fst = 0, s_lst = 0, s_ra = 0, s_clr = 0, s_rstn = 0;
  logic [31:0] s_pdata = 0, s_qdata = 0;
  logic [3:0]  s_strb = 0, s_qstrb = 0;

  logic [31:0] sd = 32'h03020100;

  function automatic logic [31:0] next_data();
    next_data = sd;
    sd = sd + 32'd1000;
  endfunction

  task automatic fail(input string why);
    if (!failed) begin
      failed = 1'b1;
      $display("RESULT: FAIL (%s)", why);
      $finish;
    end
  endtask

  always @(posedge clk) begin
    s_pvalid <= pvalid;  s_pready <= pready;
    s_qvalid <= qvalid;  s_qready <= qready;
    s_fst    <= fst;     s_lst    <= lst;
    s_ra     <= ra;      s_clr    <= clr;     s_rstn <= rst_n;
    s_pdata  <= pdata;   s_qdata  <= qdata;
    s_strb   <= strb;    s_qstrb  <= qstrb;
  end

  always @(posedge clk) begin
    edge_cnt = edge_cnt + 1;
    if (!failed) begin
      if (!s_rstn) begin
        if (edge_cnt > 3 && s_qvalid)
          fail("X1: pop_valid_o high during reset with inputs quiet");
        exp_q.delete();
        line_on = 1'b0; wc_next = 1'b0;
        acc_cnt = 0; owed_cnt = 0;
      end else if (s_clr) begin
        exp_q.delete();
        line_on = 1'b0; wc_next = 1'b0;
        acc_cnt = 0; owed_cnt = 0;
      end else begin
        hs_in  = s_pvalid && s_pready;
        hs_out = s_qvalid && s_qready;

        // ---- input side: build expectations (R1/R2/R4/R6/L4) ----
        if (hs_in && s_ra) begin
          if (s_fst) begin
            line_on  = 1'b1;
            rot_r    = $countones(s_strb);   // R4: rotation from first beat only
            ret_data = s_pdata;
            wc_next  = 1'b0;
          end else begin
            if (s_lst || (s_strb != 4'h0)) begin
              e_cur.data = (s_pdata << (8 * rot_r)) |
                           (ret_data >> (8 * (4 - rot_r)));
              e_cur.wc  = wc_next;
              wc_next   = 1'b0;
              exp_q.push_back(e_cur);
            end else begin
              wc_next = 1'b1;  // silently consumed: next join is L4-ambiguous
            end
            ret_data = s_pdata;
            if (s_lst) line_on = 1'b0;
          end
        end

        // ---- output side: every beat must be owed, and must match ----
        if (hs_out) begin
          if (exp_q.size() == 0) begin
            if (!(hs_in && !s_ra))
              fail("R1/R2: output beat produced with none owed");
          end else begin
            e_cur = exp_q.pop_front();
            if (!e_cur.wc && (s_qdata != e_cur.data))
              fail("R2/R4/R5: realigned output data mismatch");
            if (s_qstrb != 4'hF)
              fail("R3: pop_strb_o not all ones on realign output");
          end
        end

        // ---- P1: transparency of data path and handshake ----
        if (s_pvalid && !s_ra) begin
          if (!s_qvalid)
            fail("P1: pop_valid_o does not follow push_valid_i");
          if (s_pready != s_qready)
            fail("P1: push_ready_o does not follow pop_ready_i");
          if (s_pready && (s_qdata != s_pdata))
            fail("P1: transparent data mismatch");
        end
        if (!s_pvalid && !s_ra && (exp_q.size() == 0) && !line_on && s_qvalid)
          fail("P1/R2/X2: pop_valid_o asserted with nothing owed");

        // ---- X3: input liveness ----
        if (hs_in || !s_pvalid || !s_qready) begin
          acc_cnt = 0;
        end else begin
          acc_cnt = acc_cnt + 1;
          if (acc_cnt > 16)
            fail("X3: offered beat not accepted within 16 cycles");
        end

        // ---- R2: an owed output must eventually appear ----
        if ((exp_q.size() > 0) && s_qready && !hs_out) begin
          owed_cnt = owed_cnt + 1;
          if (owed_cnt > 64)
            fail("R2: owed output beat not produced");
        end else begin
          owed_cnt = 0;
        end
      end
    end
  end

// ---------------------------------------------------------------------------
// STIMULUS
// ---------------------------------------------------------------------------
  task automatic wiggle(input int n);
    repeat (n) begin
      @(negedge clk); bfm_ready(1'b0);
      repeat (2) @(posedge clk);
      @(negedge clk); bfm_ready(1'b1);
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic drain_check(input int max_c = 300);
    for (int t = 0; t < max_c; t++) begin
      @(posedge clk);
      if (exp_q.size() == 0) break;
    end
    if (exp_q.size() != 0)
      fail("R2/R6: missing output beat(s) for a line");
  endtask

  task automatic send_line(input logic [3:0] fs,
                            input int         nbody,
                            input bit         last_zero,
                            input bit         silent_mid,
                            input bit         first_pstrb_zero);
    logic [31:0] d;
    logic [3:0]  bstrb;
    logic [3:0]  pstrb;
    d = next_data();
    bfm_send(d, 1'b1, 1'b0, 1'b1, fs, first_pstrb_zero ? 4'h0 : 4'b0011);
    for (int i = 0; i < nbody; i++) begin
      d = next_data();
      bstrb = 4'b0001 << (i % 4);                       // nonzero, varying
      pstrb = (i % 3 == 1) ? 4'h0 :                      // push_strb means nothing
              ((i % 3 == 2) ? 4'b0110 : 4'hF);
      bfm_send(d, 1'b0, 1'b0, 1'b1, bstrb, pstrb);
    end
    if (silent_mid) begin
      d = next_data();
      bfm_send(d, 1'b0, 1'b0, 1'b1, 4'h0, 4'hF);         // silently consumed beat
    end
    d = next_data();
    bfm_send(d, 1'b0, 1'b1, 1'b1,
             last_zero ? 4'h0 : 4'b0101, 4'h0);          // R6 when last_zero
    wiggle(2);
    bfm_idle();
    drain_check();
  endtask

  initial begin
    bfm_reset(5);

    // ---- Phase A: transparent mode (P1). Strobe deliberately partial (L3). ----
    for (int i = 0; i < 12; i++)
      bfm_send(next_data(), 1'b0, 1'b0, 1'b0, 4'hF,
               (i % 2) ? 4'b0011 : 4'b1000);
    wiggle(3);
    bfm_idle();
    drain_check();

    // ---- Phase B: realign lines, R = 0..4 incl. non-contiguous patterns ----
    send_line(4'h0, 3, 1, 0, 1);  // R=0, R6 last, first-beat push_strb zero
    send_line(4'h1, 4, 0, 0, 0);  // R=1
    send_line(4'h3, 2, 1, 0, 0);  // R=2
    send_line(4'h6, 3, 0, 0, 1);  // R=2 non-contiguous
    send_line(4'h9, 1, 1, 0, 0);  // R=2 non-contiguous (catches lowest-set-bit)
    send_line(4'h7, 3, 0, 0, 1);  // R=3
    send_line(4'hF, 2, 1, 0, 0);  // R=4 (catches mod-4 rotation)
    send_line(4'h3, 0, 0, 0, 0);  // first + last only
    send_line(4'h3, 0, 1, 1, 0);  // first, silent, last(strb=0): exactly one output
    send_line(4'h1, 1, 0, 1, 0);  // first, body, silent, last: exactly two outputs

    // ---- Phase C: clear mid-life (X2) ----
    bfm_send(next_data(), 1'b1, 1'b0, 1'b1, 4'h3, 4'hF);
    bfm_send(next_data(), 1'b0, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_idle();
    drain_check();
    bfm_clear();
    bfm_send(next_data(), 1'b0, 1'b0, 1'b0, 4'hF, 4'b0011); // nothing carried over
    bfm_idle();
    drain_check();
    send_line(4'h1, 2, 1, 0, 0);                            // fresh line works

    // ---- Phase D: reset mid-life (X1) ----
    bfm_send(next_data(), 1'b1, 1'b0, 1'b1, 4'h3, 4'hF);
    bfm_send(next_data(), 1'b0, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_idle();
    drain_check();
    bfm_reset(3);
    bfm_send(next_data(), 1'b0, 1'b0, 1'b0, 4'hF, 4'b0011);
    bfm_idle();
    drain_check();
    send_line(4'h7, 1, 0, 0, 0);

    // ---- verdict ----
    if (!failed) begin
      if (exp_q.size() != 0) fail("R2: outputs still owed at end of test");
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule
