// =============================================================================
//  frame_arb_mux_tb  — self-checking testbench for frame_arb_mux
// =============================================================================
module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KW         = DATA_WIDTH / 8;

  // ---- DUT signals ---------------------------------------------------------
  logic clk, rst;
  logic [S_COUNT-1:0][DATA_WIDTH-1:0] s_tdata;
  logic [S_COUNT-1:0][KW-1:0]         s_tkeep;
  logic [S_COUNT-1:0]                 s_tvalid, s_tready, s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0] s_tuser;
  logic [DATA_WIDTH-1:0]              m_tdata;
  logic [KW-1:0]                      m_tkeep;
  logic                               m_tvalid, m_tready, m_tlast;
  logic [USER_WIDTH-1:0]              m_tuser;

  frame_arb_mux #(
    .S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk), .rst_i(rst),
    .s_tdata_i(s_tdata), .s_tkeep_i(s_tkeep), .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready), .s_tlast_i(s_tlast), .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata), .m_tkeep_o(m_tkeep), .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready), .m_tlast_o(m_tlast), .m_tuser_o(m_tuser)
  );

  // ===========================================================================
  //  Provided plumbing (clock, reset, bfm_send / bfm_idle / bfm_ready)
  // ===========================================================================
  initial begin clk = 1'b0; forever #5 clk = ~clk; end
  initial rst = 1'b1;

  initial begin
    m_tready = 1'b1;
    for (int i = 0; i < S_COUNT; i++) begin
      s_tvalid[i] = 1'b0;
      s_tdata[i]  = '0;
      s_tkeep[i]  = '0;
      s_tlast[i]  = 1'b0;
      s_tuser[i]  = '0;
    end
  end

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  task automatic bfm_send(input int                          k,
                          input logic [DATA_WIDTH-1:0]       data,
                          input logic [KW-1:0]               keep,
                          input logic                        last,
                          input logic [USER_WIDTH-1:0]       user);
    @(negedge clk);
    if (rst) return;                    // reset aborts pending send
    s_tdata[k]  = data;
    s_tkeep[k]  = keep;
    s_tlast[k]  = last;
    s_tuser[k]  = user;
    s_tvalid[k] = 1'b1;
    forever begin
      @(posedge clk);
      if (rst) begin
        @(negedge clk);
        s_tvalid[k] = 1'b0;
        return;
      end
      if (s_tready[k]) break;
    end
  endtask

  task automatic bfm_idle(input int k);
    @(negedge clk);
    s_tvalid[k] = 1'b0;
  endtask

  task automatic bfm_ready(input logic value);
    @(negedge clk);
    m_tready = value;
  endtask

  // ---- watchdog (fires unconditionally) -------------------------------------
  initial begin
    #20_000_000;
    $display("FAIL [watchdog]: no forward progress");
    $display("RESULT: FAIL");
    $finish;
  end

  // ===========================================================================
  //  Scoreboard structures
  // ===========================================================================
  typedef struct {
    logic [DATA_WIDTH-1:0] data;
    logic [KW-1:0]         keep;
    logic                  last;
    logic [USER_WIDTH-1:0] user;
  } beat_t;

  beat_t in_q[S_COUNT][$];             // beats transferred in, not yet emitted
  int    in_q_size[S_COUNT];
  int    cur_input;                    // <0 => idle between frames
  int    errors;

  beat_t pre_reset_beats[$];           // pending at reset → S12 trap

  // ---- fairness bookkeeping -------------------------------------------------
  int    frames_done;
  int    frame_start_q[S_COUNT][$];    // completion counts at which input began
  bit    fairness_active;

  // ---- fairness drivers -----------------------------------------------------
  bit    fstart;
  bit    fstop_fair;
  bit    drv_done[S_COUNT];
  int    drv_ctr[S_COUNT];

  // ---- S12 state ------------------------------------------------------------
  bit    seen_reset;

  initial begin
    cur_input = -1;
    errors    = 0;
    frames_done = 0;
    fairness_active = 0;
    fstart      = 0;
    fstop_fair  = 0;
    seen_reset  = 0;
    for (int k = 0; k < S_COUNT; k++) begin
      in_q_size[k] = 0;
      drv_done[k]  = 0;
      drv_ctr[k]   = 0;
    end
  end

  task automatic fail(input string req, input string msg);
    $display("FAIL [%s]: %s @ %0t", req, msg, $time);
    errors = errors + 1;
  endtask

  // ===========================================================================
  //  Fairness (S10)
  // ===========================================================================
  task automatic check_fairness();
    automatic int lo;
    automatic int hi;
    if (frames_done >= 16) begin
      lo = frames_done - 16;
      hi = frames_done - 1;
      for (int k = 0; k < S_COUNT; k++) begin
        automatic bit found;
        automatic int sz;
        found = 0;
        sz = frame_start_q[k].size();
        for (int i = 0; i < sz; i++) begin
          if (frame_start_q[k][i] >= lo && frame_start_q[k][i] <= hi) begin
            found = 1;
            break;
          end
        end
        if (!found) begin
          $display("FAIL [S10]: input %0d missed 16-frame window ending frame %0d @ %0t",
                   k, hi, $time);
          errors = errors + 1;
        end
      end
    end
  endtask

  // ===========================================================================
  //  Scoreboard monitor  (S1..S5, S8, S12)
  // ===========================================================================
  always @(posedge clk) begin
    if (rst) begin
      // Reset: move pending beats aside, clear state (S12)
      for (int k = 0; k < S_COUNT; k++) begin
        for (int i = 0; i < in_q_size[k]; i++) begin
          pre_reset_beats.push_back(in_q[k][i]);
        end
        in_q[k].delete();
        in_q_size[k] = 0;
      end
      cur_input  = -1;
      seen_reset = 1;
    end else begin
      automatic int k;

      // ---- S12: m_tvalid must be low on first cycle after reset release ----
      if (seen_reset) begin
        if (m_tvalid) begin
          fail("S12", "m_tvalid_o high on first cycle after reset release");
        end
        seen_reset = 0;
      end

      // ---- Sample input-side transfers (S1) --------------------------------
      for (k = 0; k < S_COUNT; k++) begin
        if (s_tvalid[k] && s_tready[k]) begin
          automatic beat_t b;
          b.data = s_tdata[k];
          b.keep = s_tkeep[k];
          b.last = s_tlast[k];
          b.user = s_tuser[k];
          in_q[k].push_back(b);
          in_q_size[k] = in_q_size[k] + 1;
        end
      end

      // ---- Sample output-side transfers (S3/S4/S5) -------------------------
      if (m_tvalid && m_tready) begin
        automatic beat_t ob, cand;
        automatic bit    found, is_pre;
        automatic int    mk;

        ob.data = m_tdata;
        ob.keep = m_tkeep;
        ob.last = m_tlast;
        ob.user = m_tuser;

        found = 0;
        mk    = -1;

        if (cur_input >= 0) begin
          // Mid-frame: must match next beat of the *same* frame (S3).
          if (in_q_size[cur_input] == 0) begin
            fail("S5", "output beat with empty active-frame queue");
          end else begin
            cand = in_q[cur_input][0];
            if (cand.data == ob.data && cand.keep == ob.keep &&
                cand.last == ob.last && cand.user == ob.user) begin
              in_q[cur_input].pop_front();
              in_q_size[cur_input] = in_q_size[cur_input] - 1;
              found = 1;
              if (ob.last) begin
                cur_input   = -1;
                frames_done = frames_done + 1;
                if (fairness_active) check_fairness();
              end
            end else begin
              fail("S3", "beat does not match active frame's next beat");
            end
          end
        end else begin
          // Between frames: must match head of some input queue (S4/S5).
          for (k = 0; k < S_COUNT; k++) begin
            if (!found && in_q_size[k] > 0) begin
              cand = in_q[k][0];
              if (cand.data == ob.data && cand.keep == ob.keep &&
                  cand.last == ob.last && cand.user == ob.user) begin
                found = 1;
                mk    = k;
              end
            end
          end

          if (found) begin
            in_q[mk].pop_front();
            in_q_size[mk] = in_q_size[mk] - 1;
            cur_input = mk;
            if (fairness_active) begin
              frame_start_q[mk].push_back(frames_done);
              while (frame_start_q[mk].size() > 32)
                frame_start_q[mk].pop_front();
            end
            if (ob.last) begin
              cur_input   = -1;
              frames_done = frames_done + 1;
              if (fairness_active) check_fairness();
            end
          end else begin
            // Beat matches nothing pending — could be a stale pre-reset beat.
            is_pre = 0;
            for (int i = 0; i < pre_reset_beats.size(); i++) begin
              cand = pre_reset_beats[i];
              if (cand.data == ob.data && cand.keep == ob.keep &&
                  cand.last == ob.last && cand.user == ob.user) begin
                is_pre = 1;
                break;
              end
            end
            if (is_pre) begin
              fail("S12", "pre-reset beat emitted after reset");
            end else begin
              fail("S4", "output beat matches no expected input beat");
            end
          end
        end
      end
    end
  end

  function automatic bit queues_empty();
    return (in_q_size[0] == 0 && in_q_size[1] == 0 &&
            in_q_size[2] == 0 && in_q_size[3] == 0 &&
            cur_input == -1);
  endfunction

  task automatic wait_all_drain();
    int cnt;
    cnt = 5000;
    while (!queues_empty() && cnt > 0) begin
      @(posedge clk);
      cnt = cnt - 1;
    end
    if (cnt == 0) begin
      fail("S5", "drain timeout — beats not emitted");
    end
  endtask

  // ===========================================================================
  //  Fairness drivers  (S10 under continuous load, m_tready high)
  // ===========================================================================
  task automatic fairness_driver(input int k);
    automatic int nbeats;
    automatic logic [DATA_WIDTH-1:0] dd;
    while (!fstart) @(posedge clk);
    while (!fstop_fair) begin
      nbeats = $urandom_range(1, 3);
      for (int b = 0; b < nbeats; b++) begin
        dd = drv_ctr[k] * 8 + k;            // globally unique
        drv_ctr[k] = drv_ctr[k] + 1;
        bfm_send(k, dd, 4'hF, (b == nbeats - 1), 1'b0);
      end
    end
    bfm_idle(k);
    drv_done[k] = 1;
  endtask

  initial fairness_driver(0);
  initial fairness_driver(1);
  initial fairness_driver(2);
  initial fairness_driver(3);

  // ===========================================================================
  //  Main test flow
  // ===========================================================================
  initial begin
    // ---- Test 1: single-beat single-frame on input 0 ---------------------
    bfm_reset();
    bfm_ready(1'b1);
    bfm_send(0, 32'h1000_0001, 4'hF, 1'b1, 1'b0);
    bfm_idle(0);
    wait_all_drain();

    // ---- Test 2: multi-beat frame on input 0 ----------------------------
    bfm_send(0, 32'h2000_0001, 4'hF, 1'b0, 1'b0);
    bfm_send(0, 32'h2000_0002, 4'h5, 1'b0, 1'b1);
    bfm_send(0, 32'h2000_0003, 4'hF, 1'b1, 1'b0);
    bfm_idle(0);
    wait_all_drain();

    // ---- Test 3: two frames back-to-back on same input ------------------
    bfm_send(0, 32'h3000_0001, 4'hF, 1'b0, 1'b0);
    bfm_send(0, 32'h3000_0002, 4'hF, 1'b1, 1'b0);
    bfm_send(0, 32'h3000_0003, 4'hF, 1'b1, 1'b0);
    bfm_idle(0);
    wait_all_drain();

    // ---- Test 4: four inputs offering different frame sizes concurrently -
    fork
      begin
        bfm_send(0, 32'h4000_0001, 4'hF, 1'b0, 1'b0);
        bfm_send(0, 32'h4000_0002, 4'hF, 1'b1, 1'b0);
        bfm_idle(0);
      end
      begin
        bfm_send(1, 32'h4100_0001, 4'hF, 1'b1, 1'b1);
        bfm_idle(1);
      end
      begin
        bfm_send(2, 32'h4200_0001, 4'hF, 1'b0, 1'b0);
        bfm_send(2, 32'h4200_0002, 4'h3, 1'b0, 1'b0);
        bfm_send(2, 32'h4200_0003, 4'hF, 1'b1, 1'b0);
        bfm_idle(2);
      end
      begin
        bfm_send(3, 32'h4300_0001, 4'hF, 1'b1, 1'b0);
        bfm_idle(3);
      end
    join
    wait_all_drain();

    // ---- Test 5: backpressure mid-frame (S8) ----------------------------
    bfm_ready(1'b0);
    fork
      begin
        bfm_send(0, 32'h5000_0001, 4'hF, 1'b0, 1'b0);
        bfm_send(0, 32'h5000_0002, 4'hF, 1'b0, 1'b0);
        bfm_send(0, 32'h5000_0003, 4'hF, 1'b0, 1'b0);
        bfm_send(0, 32'h5000_0004, 4'hF, 1'b1, 1'b0);
        bfm_idle(0);
      end
      begin
        repeat (20) @(posedge clk);
        bfm_ready(1'b1);
      end
    join
    wait_all_drain();

    // ---- Test 6: reset with pending queued beats (S12) ------------------
    bfm_reset();
    bfm_ready(1'b0);
    fork
      begin
        bfm_send(0, 32'h6000_0001, 4'hF, 1'b0, 1'b0);
        bfm_send(0, 32'h6000_0002, 4'hF, 1'b1, 1'b0);
        bfm_idle(0);
      end
      begin
        repeat (5) @(posedge clk);
        bfm_reset();
        bfm_ready(1'b1);
        repeat (20) @(posedge clk);
      end
    join
    bfm_idle(0);
    bfm_idle(1);
    bfm_idle(2);
    bfm_idle(3);
    wait_all_drain();

    // ---- Test 7: fairness under continuous offered load (S10) -----------
    bfm_reset();
    bfm_ready(1'b1);
    fairness_active = 1;
    frames_done     = 0;
    for (int k = 0; k < S_COUNT; k++) frame_start_q[k].delete();
    fstart = 1;

    while (frames_done < 40) @(posedge clk);
    fairness_active = 0;         // stop checking during teardown
    fstop_fair      = 1;

    while (!(drv_done[0] && drv_done[1] && drv_done[2] && drv_done[3]))
      @(posedge clk);
    wait_all_drain();

    // ---- Final verdict --------------------------------------------------
    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
