// ---------------------------------------------------------------------------
// frame_arb_mux_tb -- self-checking testbench for frame_arb_mux
// Checks S3 (frame atomicity), S4 (payload integrity/order/tlast),
// S5 (no loss/duplication), S8 (backpressure), S10 (bounded fairness),
// S12 (reset behaviour).  S9/S11/out-of-scope items are deliberately not
// checked.
// ---------------------------------------------------------------------------
module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEPW      = DATA_WIDTH/8;

  // ---- clock ---------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset ---------------------------------------------------------------
  logic rst;
  initial rst = 1'b1;

  // ---- DUT signals (packed forms match the port map exactly) ---------------
  logic [S_COUNT-1:0][DATA_WIDTH-1:0]  s_tdata;
  logic [S_COUNT-1:0][KEEPW-1:0]        s_tkeep;
  logic [S_COUNT-1:0]                   s_tvalid;
  logic [S_COUNT-1:0]                   s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]   s_tuser;
  logic [S_COUNT-1:0]                   s_tready;

  logic [DATA_WIDTH-1:0]                m_tdata;
  logic [KEEPW-1:0]                     m_tkeep;
  logic                                 m_tvalid;
  logic                                 m_tready;
  logic                                 m_tlast;
  logic [USER_WIDTH-1:0]                m_tuser;

  frame_arb_mux #(
    .S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk), .rst_i(rst),
    .s_tdata_i(s_tdata), .s_tkeep_i(s_tkeep), .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready), .s_tlast_i(s_tlast), .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata), .m_tkeep_o(m_tkeep), .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready), .m_tlast_o(m_tlast), .m_tuser_o(m_tuser)
  );

  // ---- expected-beat model --------------------------------------------------
  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [KEEPW-1:0]      keep;
    logic [USER_WIDTH-1:0] user;
    logic                  last;
  } beat_t;

  // one queue per input (case-selected wrappers keep Verilator happy)
  beat_t q0[$], q1[$], q2[$], q3[$];

  function automatic int qsize(input int k);
    case (k)
      0: return q0.size();
      1: return q1.size();
      2: return q2.size();
      default: return q3.size();
    endcase
  endfunction

  task automatic qpush(input int k, input beat_t b);
    case (k)
      0: q0.push_back(b);
      1: q1.push_back(b);
      2: q2.push_back(b);
      3: q3.push_back(b);
    endcase
  endtask

  function automatic beat_t qfront(input int k);
    case (k)
      0: return q0[0];
      1: return q1[0];
      2: return q2[0];
      default: return q3[0];
    endcase
  endfunction

  task automatic qpop(input int k);
    case (k)
      0: void'(q0.pop_front());
      1: void'(q1.pop_front());
      2: void'(q2.pop_front());
      3: void'(q3.pop_front());
    endcase
  endtask

  task automatic qclr(input int k);
    case (k)
      0: q0.delete();
      1: q1.delete();
      2: q2.delete();
      3: q3.delete();
    endcase
  endtask

  // ---- bookkeeping ----------------------------------------------------------
  int  errors      = 0;
  int  in_flight   = 0;   // beats accepted on inputs, not yet seen on output
  int  cur_in      = -1;  // input whose frame is currently on the output
  int  gen         = 0;   // generation tag, toggled on reset (S12)
  bit  bad_frame   = 1'b0;
  bit  fair_chk    = 1'b0;
  bit  done_k      [S_COUNT];
  int  frames_done = 0;
  int  last_start  [S_COUNT];
  int  fcnt        [S_COUNT];

  task automatic fail(input string req, input string msg);
    errors++;
    $display("FAIL %s: %s (time %0t)", req, msg, $time);
  endtask

  // S10: under continuous offered load every input must begin a frame within
  // any window of 16 consecutive completed output frames.
  task automatic chk_fair();
    if (fair_chk) begin
      for (int j = 0; j < S_COUNT; j++) begin
        if (!done_k[j] && (frames_done - last_start[j] > 16)) begin
          fail("S10", $sformatf("input %0d began no frame within %0d completed output frames",
                                j, frames_done - last_start[j]));
          fair_chk = 1'b0; // report once, avoid spam
        end
      end
    end
  endtask

  // ---- BFM -------------------------------------------------------------------
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  // Offers ONE beat on input k, returns once it transferred (S7 compliant).
  // The beat is entered into the expected model at presentation time (negedge)
  // so that a zero-latency implementation that forwards it on the very next
  // posedge is still checked correctly.
  task automatic bfm_send(input int k, input logic [DATA_WIDTH-1:0] data,
                          input logic [KEEPW-1:0] keep, input logic last,
                          input logic [USER_WIDTH-1:0] user);
    beat_t b;
    @(negedge clk);
    s_tdata[k]  = data;
    s_tkeep[k]  = keep;
    s_tlast[k]  = last;
    s_tuser[k]  = user;
    s_tvalid[k] = 1'b1;
    b.data = data;
    b.keep = keep;
    b.user = user;
    b.last = last;
    qpush(k, b);
    in_flight++;
    forever begin
      @(posedge clk);
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

  // ---- stimulus helpers -------------------------------------------------------
  // data[31:28]=input, [27]=generation, [26:16]=frame id, [15:0]=beat id
  function automatic logic [DATA_WIDTH-1:0] mk_data(input int k, input int fid, input int bid);
    logic [DATA_WIDTH-1:0] d;
    d = '0;
    d[31:28] = k;
    d[27]    = gen[0];
    d[26:16] = fid;
    d[15:0]  = bid;
    return d;
  endfunction

  task automatic send_frame(input int k, input int nbeats);
    for (int i = 0; i < nbeats; i++) begin
      bfm_send(k, mk_data(k, fcnt[k], i), $urandom, (i == nbeats-1), $urandom);
    end
    fcnt[k]++;
  endtask

  task automatic drain_frames(input string tag);
    int guard;
    guard = 0;
    while (in_flight != 0 && guard < 20000) begin
      @(posedge clk);
      guard++;
    end
    if (in_flight != 0)
      fail("S5", $sformatf("%s: %0d accepted input beats never appeared on the output",
                           tag, in_flight));
  endtask

  // ---- output checker ----------------------------------------------------------
  // Runs on the sampling edge; everything it reads was driven on the opposite
  // edge (or by the DUT itself), so there is no same-timestep race.
  always @(posedge clk) begin
    if (!rst && m_tvalid && m_tready) begin
      automatic int    k;
      automatic beat_t b;
      automatic bit    ok;
      if (bad_frame) begin
        // a mismatch was already reported; ride out the rest of this frame
        if (m_tlast) begin
          bad_frame = 1'b0;
          cur_in = -1;
          frames_done++;
          chk_fair();
        end
      end else if (cur_in == -1) begin
        // first beat of a new output frame: identify the source input
        k  = m_tdata[31:28];
        ok = 1'b0;
        if (k >= S_COUNT) begin
          fail("S4", "output beat does not decode to a valid input number");
          bad_frame = 1'b1;
        end else if (m_tdata[27] != gen[0]) begin
          fail("S12", "beat that transferred before/during reset appeared on the output afterwards");
          bad_frame = 1'b1;
        end else if (qsize(k) == 0) begin
          fail("S4", "output beat matches no outstanding accepted input beat");
          bad_frame = 1'b1;
        end else begin
          b = qfront(k);
          if (b.data === m_tdata && b.keep === m_tkeep &&
              b.user === m_tuser && b.last === m_tlast) begin
            ok = 1'b1;
          end else begin
            fail("S4", "first beat of frame: payload/tkeep/tuser/tlast mismatch vs expected input beat");
            bad_frame = 1'b1;
          end
        end
        if (ok) begin
          qpop(k);
          in_flight--;
          cur_in = k;
          if (fair_chk) last_start[k] = frames_done;
          if (m_tlast) begin
            cur_in = -1;
            frames_done++;
            chk_fair();
          end
        end
      end else begin
        // S3: mid-frame, the next beat must be the next beat of the same frame
        if (qsize(cur_in) == 0) begin
          fail("S3", "output frame continues past the end of the expected input beats");
          bad_frame = 1'b1;
        end else begin
          b = qfront(cur_in);
          if (b.data === m_tdata && b.keep === m_tkeep &&
              b.user === m_tuser && b.last === m_tlast) begin
            qpop(cur_in);
            in_flight--;
          end else begin
            fail("S3", "mid-frame beat differs from the next expected beat of the selected input (interleaving or corruption)");
            bad_frame = 1'b1;
            qpop(cur_in);   // best effort: keep the model moving
            in_flight--;
          end
          if (m_tlast) begin
            cur_in = -1;
            frames_done++;
            chk_fair();
          end
        end
      end
    end
  end

  // ---- watchdog ----------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- main sequence --------------------------------------------------------------
  initial begin : main
    s_tdata  = '0;
    s_tkeep  = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    s_tvalid = '0;
    m_tready = 1'b1;
    for (int j = 0; j < S_COUNT; j++) begin
      last_start[j] = 0;
      fcnt[j]       = 0;
      done_k[j]     = 1'b0;
    end

    bfm_reset(4);
    // S12: first cycle after release
    @(posedge clk);
    @(negedge clk);
    if (m_tvalid)
      fail("S12", "m_tvalid_o high on the first cycle after reset release");

    // ---- phase 1: single-beat frames, one input at a time (S2, S4, S5)
    for (int k = 0; k < S_COUNT; k++) begin
      for (int f = 0; f < 3; f++) send_frame(k, 1);
      bfm_idle(k);
    end
    drain_frames("phase1");

    // ---- phase 2: multi-beat frames with random backpressure (S8)
    fork
      begin
        for (int i = 0; i < 80; i++)
          bfm_ready(($urandom_range(0, 3) != 0));
        bfm_ready(1'b1);
      end
      begin
        for (int k = 0; k < S_COUNT; k++) begin
          for (int f = 0; f < 3; f++)
            send_frame(k, 1 + $urandom_range(0, 5));
          bfm_idle(k);
        end
      end
    join
    drain_frames("phase2");

    // ---- phase 2b: long stall in the middle of a frame (S8)
    fork
      begin
        bfm_ready(1'b0);
        repeat (12) @(posedge clk);
        bfm_ready(1'b1);
      end
      begin
        send_frame(1, 5);
        bfm_idle(1);
      end
    join
    drain_frames("phase2b");

    // ---- phase 3: continuous offered load on all inputs (S10)
    bfm_ready(1'b1);
    for (int j = 0; j < S_COUNT; j++) last_start[j] = frames_done;
    fair_chk = 1'b1;
    fork
      begin
        for (int f = 0; f < 16; f++) send_frame(0, 1 + $urandom_range(0, 2));
        bfm_idle(0);
        done_k[0] = 1'b1;
      end
      begin
        for (int f = 0; f < 16; f++) send_frame(1, 1 + $urandom_range(0, 2));
        bfm_idle(1);
        done_k[1] = 1'b1;
      end
      begin
        for (int f = 0; f < 16; f++) send_frame(2, 1 + $urandom_range(0, 2));
        bfm_idle(2);
        done_k[2] = 1'b1;
      end
      begin
        for (int f = 0; f < 16; f++) send_frame(3, 1 + $urandom_range(0, 2));
        bfm_idle(3);
        done_k[3] = 1'b1;
      end
    join
    fair_chk = 1'b0;
    drain_frames("phase3");

    // ---- phase 4: reset in the middle of a partially-emitted frame (S12)
    bfm_send(2, mk_data(2, fcnt[2], 0), 4'hF, 1'b0, 1'b0);
    bfm_send(2, mk_data(2, fcnt[2], 1), 4'hF, 1'b0, 1'b0);
    bfm_idle(2);                       // abandon frame at source (allowed, S5a)
    repeat (5) @(posedge clk);         // let the design start emitting it
    bfm_reset(2);
    s_tvalid = '0;                     // same negedge step as reset release
    for (int j = 0; j < S_COUNT; j++) qclr(j);
    in_flight = 0;
    cur_in    = -1;
    bad_frame = 1'b0;
    gen       = gen + 1;               // stale beats now fail the S12 check
    fcnt[2]++;

    // S12: first cycle after release
    @(posedge clk);
    @(negedge clk);
    if (m_tvalid)
      fail("S12", "m_tvalid_o high on the first cycle after reset release");

    // ---- phase 4b: post-reset traffic must still be forwarded correctly
    for (int k = 0; k < S_COUNT; k++) begin
      for (int f = 0; f < 2; f++) send_frame(k, 1 + $urandom_range(0, 3));
      bfm_idle(k);
    end
    drain_frames("phase4");

    // ---- final S5 sweep
    for (int j = 0; j < S_COUNT; j++) begin
      if (qsize(j) != 0)
        fail("S5", $sformatf("input %0d: %0d accepted beats never forwarded", j, qsize(j)));
    end

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL (%0d error(s))", errors);
    $finish;
  end

endmodule
