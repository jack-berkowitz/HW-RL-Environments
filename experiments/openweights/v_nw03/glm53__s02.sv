`timescale 1ns/1ps

module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_W     = DATA_WIDTH/8;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_W-1:0]     keep;
    logic [USER_WIDTH-1:0] user;
    logic                  last;
  } beat_t;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst;
  initial rst = 1'b1;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  task automatic bfm_send(input int                        k,
                          input logic [DATA_WIDTH-1:0]      data,
                          input logic [KEEP_W-1:0]          keep,
                          input logic                       last,
                          input logic [USER_WIDTH-1:0]      user);
    @(negedge clk);
    s_tdata[k]  = data;
    s_tkeep[k]  = keep;
    s_tlast[k]  = last;
    s_tuser[k]  = user;
    s_tvalid[k] = 1'b1;
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

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------
  logic [S_COUNT-1:0][DATA_WIDTH-1:0]  s_tdata;
  logic [S_COUNT-1:0][KEEP_W-1:0]      s_tkeep;
  logic [S_COUNT-1:0]                  s_tvalid;
  logic [S_COUNT-1:0]                  s_tready;
  logic [S_COUNT-1:0]                  s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]  s_tuser;
  logic [DATA_WIDTH-1:0]               m_tdata;
  logic [KEEP_W-1:0]                   m_tkeep;
  logic                                m_tvalid;
  logic                                m_tready;
  logic                                m_tlast;
  logic [USER_WIDTH-1:0]               m_tuser;

  frame_arb_mux #(
    .S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk), .rst_i(rst),
    .s_tdata_i(s_tdata), .s_tkeep_i(s_tkeep), .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready), .s_tlast_i(s_tlast), .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata), .m_tkeep_o(m_tkeep), .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready), .m_tlast_o(m_tlast), .m_tuser_o(m_tuser)
  );

  // ---------------------------------------------------------------------------
  // CHECKER STATE
  // ---------------------------------------------------------------------------
  // Per-input log of beats that transferred on that input (S1), in order.
  // The output must consume each input's log strictly from the head, a whole
  // frame at a time (S3, S4, S5).
  beat_t q0[$]; beat_t q1[$]; beat_t q2[$]; beat_t q3[$];

  int    errors      = 0;
  int    frame_count = 0;
  logic  in_frame    = 1'b0;
  int    frame_len   = 0;
  int    cand[$];              // candidate source inputs for the frame in flight
  logic  ob_valid    = 1'b0;    // output beat captured at posedge, checked at negedge
  beat_t ob;
  beat_t inb;                   // scratch for the input monitor
  logic  fair_mode   = 1'b0;
  logic  rand_ready_en = 1'b0;
  int    last_start[S_COUNT];   // frame index at which each input last began a frame
  logic  offer[S_COUNT];         // input still offering frames (fairness phase)

  task automatic fail(input string req, input string msg);
    errors++;
    $display("FAIL %s: %s", req, msg);
  endtask

  function automatic int qsize(input int k);
    case (k)
      0: return q0.size();
      1: return q1.size();
      2: return q2.size();
      default: return q3.size();
    endcase
  endfunction

  function automatic beat_t qget(input int k, input int idx);
    case (k)
      0: return q0[idx];
      1: return q1[idx];
      2: return q2[idx];
      default: return q3[idx];
    endcase
  endfunction

  task automatic qshrink(input int k, input int n);
    repeat (n) begin
      case (k)
        0: q0.delete(0);
        1: q1.delete(0);
        2: q2.delete(0);
        default: q3.delete(0);
      endcase
    end
  endtask

  function automatic bit beat_eq(beat_t a, beat_t b);
    return (a.data === b.data) && (a.keep === b.keep) &&
           (a.user === b.user) && (a.last === b.last);
  endfunction

  // Called when the beat ending the in-flight output frame has been matched.
  task automatic finish_frame();
    if (fair_mode) begin
      for (int k = 0; k < S_COUNT; k++) begin
        if (offer[k] && (frame_count - last_start[k] > 16))
          fail("S10", $sformatf("input %0d began no frame within a 16-completed-frame window (gap %0d)",
                                k, frame_count - last_start[k]));
      end
      last_start[cand[0]] = frame_count;
    end
    qshrink(cand[0], frame_len);   // whole frame consumed from that input
    in_frame  = 1'b0;
    frame_len = 0;
    cand.delete();
    frame_count++;
  endtask

  // ---------------------------------------------------------------------------
  // INPUT MONITOR (S1): record every beat that transfers on any input.
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst) begin
      for (int k = 0; k < S_COUNT; k++) begin
        if (s_tvalid[k] && s_tready[k]) begin
          inb.data = s_tdata[k];
          inb.keep = s_tkeep[k];
          inb.user = s_tuser[k];
          inb.last = s_tlast[k];
          case (k)
            0: q0.push_back(inb);
            1: q1.push_back(inb);
            2: q2.push_back(inb);
            default: q3.push_back(inb);
          endcase
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // OUTPUT CAPTURE (S1): capture at the posedge, process at the negedge so the
  // input log for a same-cycle pass-through beat is already complete.
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst && m_tvalid && m_tready) begin
      ob.data  = m_tdata;
      ob.keep  = m_tkeep;
      ob.user  = m_tuser;
      ob.last  = m_tlast;
      ob_valid = 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // OUTPUT CHECKER (S3, S4, S5): every output beat must be the next beat of the
  // same input frame until m_tlast, matching data/keep/user/last exactly.
  // ---------------------------------------------------------------------------
  always @(negedge clk) begin
    if (ob_valid) begin
      ob_valid = 1'b0;
      if (!in_frame) begin
        cand.delete();
        for (int k = 0; k < S_COUNT; k++) begin
          if (qsize(k) > 0 && beat_eq(qget(k, 0), ob)) cand.push_back(k);
        end
        if (cand.size() == 0) begin
          fail("S4", "output beat matches no pending input beat (corrupt, duplicated or lost-context beat)");
        end else begin
          in_frame  = 1'b1;
          frame_len = 1;
          if (ob.last) finish_frame();
        end
      end else begin
        for (int i = cand.size() - 1; i >= 0; i--) begin
          if (!(qsize(cand[i]) > frame_len && beat_eq(qget(cand[i], frame_len), ob)))
            cand.delete(i);
        end
        if (cand.size() == 0) begin
          fail("S3", "mid-frame output beat does not continue the frame in flight (atomicity/order/payload)");
          in_frame  = 1'b0;
          frame_len = 0;
        end else begin
          frame_len++;
          if (ob.last) finish_frame();
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // STIMULUS HELPERS
  // ---------------------------------------------------------------------------
  task automatic send_exact(input int k, input int len, input int base);
    for (int i = 0; i < len; i++)
      bfm_send(k, base + i, $urandom_range(15), (i == len-1), $urandom_range(1));
    bfm_idle(k);
  endtask

  task automatic send_frames(input int k, input int nframes, input bit fair);
    for (int f = 0; f < nframes; f++) begin
      automatic int len;
      automatic logic [DATA_WIDTH-1:0] d;
      len = fair ? (1 + $urandom_range(2)) : (1 + $urandom_range(3));
      for (int i = 0; i < len; i++) begin
        if (fair) d = (k * 32'h10000000) | (f * 32'h1000) | i;
        else      d = (k * 32'h100000)   | (f * 32'h100)   | i;
        bfm_send(k, d, $urandom_range(15), (i == len-1), $urandom_range(1));
      end
    end
    bfm_idle(k);
    if (fair) offer[k] = 1'b0;   // this input has no more frames to offer
  endtask

  // Waits until every buffered complete frame has been emitted (S5), with the
  // sink ready held high. Samples at posedge: all checker state is written on
  // negedges, so it is stable here.
  task automatic drain_all();
    automatic int c;
    automatic int idle;
    c = 0; idle = 0;
    while (idle < 8 && c < 20000) begin
      @(posedge clk);
      c++;
      if (qsize(0)+qsize(1)+qsize(2)+qsize(3) == 0 && !in_frame && !ob_valid) idle++;
      else idle = 0;
    end
    if (c >= 20000)
      fail("S5", "timeout waiting for buffered complete frames to be emitted");
  endtask

  // ---------------------------------------------------------------------------
  // WATCHDOG
  // ---------------------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("FAIL watchdog: no forward progress");
    $display("RESULT: FAIL");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // MAIN SEQUENCE
  // ---------------------------------------------------------------------------
  initial begin
    for (int k = 0; k < S_COUNT; k++) begin
      s_tvalid[k] = 1'b0; s_tdata[k] = '0; s_tkeep[k] = '0;
      s_tlast[k]  = 1'b0; s_tuser[k] = '0;
      offer[k] = 1'b0;
    end
    m_tready     = 1'b0;
    rand_ready_en = 1'b0;
    fair_mode     = 1'b0;
    frame_count   = 0;
    in_frame      = 1'b0;
    frame_len     = 0;
    errors        = 0;

    bfm_reset(4);

    // ---- Phase 0: reset behaviour (S12) ------------------------------------
    bfm_ready(1);
    bfm_send(0, 32'hD00D0001, 4'hF, 1'b0, 1'b0);   // partial frame, no tlast
    bfm_send(0, 32'hD00D0002, 4'h3, 1'b0, 1'b1);
    bfm_idle(0);
    bfm_reset(3);
    @(posedge clk);
    if (m_tvalid)
      fail("S12", "m_tvalid high on the first cycle after reset release");
    repeat (50) begin
      @(posedge clk);
      if (m_tvalid && m_tready)
        fail("S12", "beat transferred before reset appeared on the output afterwards");
    end
    @(negedge clk);
    if (m_tvalid)
      fail("S12", "m_tvalid high after reset with no input offered");
    q0.delete(); q1.delete(); q2.delete(); q3.delete();
    in_frame = 1'b0; frame_len = 0; cand.delete(); ob_valid = 1'b0;

    // ---- Random backpressure thread (S8) -----------------------------------
    fork
      begin
        forever begin
          @(negedge clk);
          m_tready = rand_ready_en ? ($urandom_range(99) < 65) : 1'b1;
        end
      end
    join_none
    rand_ready_en = 1'b1;

    // ---- Phase A: single-input frames, incl. 1-beat frames (S2,S4,S8) ------
    for (int k = 0; k < S_COUNT; k++) begin
      send_exact(k, 1, k*1000 +   0);
      send_exact(k, 3, k*1000 + 100);
      send_exact(k, 6, k*1000 + 200);
    end

    // ---- Phase B: concurrent frames on all inputs (S3,S4,S5,S8) ------------
    fork
      send_frames(0, 5, 1'b0);
      send_frames(1, 5, 1'b0);
      send_frames(2, 5, 1'b0);
      send_frames(3, 5, 1'b0);
    join

    rand_ready_en = 1'b0;          // force sink ready for draining / fairness
    drain_all();

    // ---- Phase C: continuous offered load, fairness (S10) -------------------
    @(negedge clk);
    fair_mode = 1'b1;
    for (int k = 0; k < S_COUNT; k++) begin
      offer[k]      = 1'b1;
      last_start[k] = frame_count;
    end
    fork
      send_frames(0, 40, 1'b1);
      send_frames(1, 40, 1'b1);
      send_frames(2, 40, 1'b1);
      send_frames(3, 40, 1'b1);
    join
    fair_mode = 1'b0;

    // ---- Final drain and loss/duplication check (S5) ------------------------
    drain_all();
    for (int k = 0; k < S_COUNT; k++)
      if (qsize(k) != 0)
        fail("S5", $sformatf("input %0d has beats that never appeared on the output", k));
    if (in_frame)
      fail("S5", "output frame never completed with m_tlast_o");

    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
