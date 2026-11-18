// ---------------------------------------------------------------------------
// frame_arb_mux_tb -- self-checking testbench for frame_arb_mux
// Checks: S3 (frame atomicity), S4 (payload integrity/order/tlast),
//         S5 (no loss/duplication), S10 (bounded fairness),
//         S12 (reset behaviour). S1 defines the sampling points used.
// Unspecified behaviours (selection order, latency, ready promptness,
// idle gaps, tkeep patterns) are deliberately NOT checked.
// ---------------------------------------------------------------------------
module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam logic [DATA_WIDTH-1:0] BASE = 32'h5A000000;

  // ---- DUT bus signals (declared before plumbing, which references them) --
  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata;
  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep;
  logic [S_COUNT-1:0]                     s_tvalid;
  logic [S_COUNT-1:0]                     s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser;
  logic [S_COUNT-1:0]                     s_tready;
  logic [DATA_WIDTH-1:0]                  m_tdata;
  logic [(DATA_WIDTH/8)-1:0]              m_tkeep;
  logic                                   m_tvalid;
  logic                                   m_tready;
  logic                                   m_tlast;
  logic [USER_WIDTH-1:0]                  m_tuser;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  ---------------------------------------------------------------------------
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

  task automatic bfm_send(input int                          k,
                          input logic [DATA_WIDTH-1:0]       data,
                          input logic [(DATA_WIDTH/8)-1:0]   keep,
                          input logic                        last,
                          input logic [USER_WIDTH-1:0]       user);
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

  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
  // ---------------------------------------------------------------------------

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
  // Scoreboard
  // ---------------------------------------------------------------------------
  typedef struct {
    logic [DATA_WIDTH-1:0]     data;
    logic [(DATA_WIDTH/8)-1:0] keep;
    logic [USER_WIDTH-1:0]     user;
    logic                      last;
  } beat_t;

  beat_t beats_a  [int];   // beat id -> expected payload as seen on the input
  int    beat_src [int];   // beat id -> source input index
  int    nxt      [S_COUNT]; // next expected beat id per input (order, S4/S5)
  int    in_cnt   [S_COUNT]; // beats accepted per input (loss check, S5)
  int    drv_id;            // next beat id to generate (globally unique data)
  int    beats_sent;        // one past the highest id accepted on any input
  int    cur_input;         // input whose frame is currently on the output
  bit    in_frame;          // an output frame is in progress (S3)
  bit    quiet_mode;        // after reset: any output beat is an S12 violation
  bit    fair_active;       // S10 checking enabled (continuous-load phase)
  bit    offering [S_COUNT];
  int    start_fidx [S_COUNT]; // completed-frame count when input last BEGAN a frame
  int    phase_frames;      // completed output frames during the fairness phase
  int    errors;

  task automatic fail(input string req, input string msg);
    errors++;
    $display("FAIL [%0s] %0s (time %0t)", req, msg, $time);
  endtask

  // ---------------------------------------------------------------------------
  // Monitor: samples on the rising edge (S1). Input beats are recorded by id
  // (the data field encodes a globally unique id, so attribution is by
  // bookkeeping, not by content matching). Output beats are checked against
  // the recorded beats.
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin : mon
    if (!rst) begin : active
      // ---- input side: record every transferred beat ----
      for (int k = 0; k < S_COUNT; k++) begin : inscan
        if (s_tvalid[k] && s_tready[k]) begin : rec
          automatic int    id = int'(s_tdata[k]) - int'(BASE);
          automatic beat_t b;
          b.data = s_tdata[k];
          b.keep = s_tkeep[k];
          b.user = s_tuser[k];
          b.last = s_tlast[k];
          beats_a[id]  = b;
          beat_src[id] = k;
          in_cnt[k]++;
          if (id >= beats_sent) beats_sent = id + 1;
        end
      end
      // ---- output side ----
      if (m_tvalid && m_tready) begin : outchk
        automatic int    id = int'(m_tdata) - int'(BASE);
        automatic int    k;
        automatic beat_t exp;
        if (quiet_mode) begin
          fail("S12", "beat appeared on the output after reset");
        end else if (id < 0 || id >= beats_sent || !beat_src.exists(id)) begin
          fail("S12", "output beat with unknown origin (pre-reset or fabricated)");
        end else begin
          k = beat_src[id];
          if (id < nxt[k])                    fail("S5", "duplicate output beat");
          if (in_frame && k != cur_input)     fail("S3", "beat of another input inside a frame in progress");
          if (!in_frame) begin
            in_frame  = 1'b1;
            cur_input = k;
            if (fair_active) start_fidx[k] = phase_frames;
          end
          if (id != nxt[k]) begin
            fail("S4", "beat out of order for its input");
          end else begin
            exp = beats_a[id];
            if (exp.keep != m_tkeep) fail("S4", "tkeep mismatch");
            if (exp.user != m_tuser) fail("S4", "tuser mismatch");
            if (exp.last != m_tlast) fail("S4", "tlast mismatch");
            nxt[k]++;
          end
          if (m_tlast) begin
            in_frame  = 1'b0;
            cur_input = -1;
            if (fair_active) begin
              phase_frames++;
              if (phase_frames > 16) begin
                for (int j = 0; j < S_COUNT; j++) begin
                  if (offering[j] && (phase_frames - start_fidx[j] > 16))
                    fail("S10", "input not begun a frame within the 16-frame window");
                end
              end
            end
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  function automatic bit pending_any();
    for (int k = 0; k < S_COUNT; k++)
      if (nxt[k] != in_cnt[k]) return 1'b1;
    return 1'b0;
  endfunction

  task automatic wait_drain(input int max_cycles);
    automatic int c = 0;
    while ((in_frame || pending_any()) && c < max_cycles) begin
      @(posedge clk);
      c++;
    end
    if (in_frame || pending_any())
      fail("S5", "transferred input beats never reached the output");
  endtask

  task automatic clear_sb();
    beats_a.delete();
    beat_src.delete();
    for (int k = 0; k < S_COUNT; k++) begin
      nxt[k]    = 0;
      in_cnt[k] = 0;
    end
    beats_sent = 0;
    in_frame   = 1'b0;
    cur_input  = -1;
  endtask

  // Sends one complete frame of len beats on input k. Data carries a globally
  // unique id; keep/user vary but are recorded exactly as driven.
  task automatic send_frame(input int k, input int len);
    for (int i = 0; i < len; i++) begin : b
      automatic logic [DATA_WIDTH-1:0]     d  = BASE + drv_id;
      automatic logic [(DATA_WIDTH/8)-1:0] kp = (1 << ((drv_id % 3) + 1)) - 1;
      automatic logic [USER_WIDTH-1:0]     u  = drv_id[USER_WIDTH-1:0];
      bfm_send(k, d, kp, (i == len - 1), u);
      drv_id++;
    end
  endtask

  task automatic drive_frames(input int k, input int n);
    for (int i = 0; i < n; i++)
      send_frame(k, 1 + ((k + i) % 3));
    offering[k] = 1'b0;
  endtask

  // ---------------------------------------------------------------------------
  // Main sequence
  // ---------------------------------------------------------------------------
  initial begin : main
    s_tdata  = '0;
    s_tkeep  = '0;
    s_tvalid = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b1;
    drv_id    = 0;
    beats_sent = 0;
    cur_input = -1;
    errors    = 0;
    for (int k = 0; k < S_COUNT; k++) begin
      nxt[k]       = 0;
      in_cnt[k]    = 0;
      offering[k]  = 1'b0;
      start_fidx[k] = 0;
    end
    bfm_reset(4);

    // ---- Phase 1: basic operation, one source at a time, ready high --------
    for (int k = 0; k < S_COUNT; k++) begin
      send_frame(k, 1);                       // single-beat frame (S2)
      send_frame(k, 1);
      send_frame(k, 3);
      send_frame(k, 1);
      send_frame(k, 5);
    end
    wait_drain(2000);

    // ---- Phase 2: concurrent sources with random backpressure (S8) --------
    fork
      begin : rdy_gen
        repeat (400) bfm_ready($urandom_range(0, 9) < 6);
      end
      begin : drv
        drive_frames(0, 5);
        drive_frames(1, 4);
        drive_frames(2, 6);
        drive_frames(3, 3);
      end
    join
    bfm_ready(1'b1);
    wait_drain(2000);

    // ---- Phase 3: continuous offered load, fairness (S10) ------------------
    fair_active  = 1'b1;
    phase_frames = 0;
    for (int k = 0; k < S_COUNT; k++) begin
      offering[k]   = 1'b1;
      start_fidx[k] = 0;
    end
    fork
      drive_frames(0, 30);
      drive_frames(1, 30);
      drive_frames(2, 30);
      drive_frames(3, 30);
    join
    fair_active = 1'b0;
    wait_drain(5000);

    // ---- Phase 4: reset behaviour (S12) ------------------------------------
    // Abandon a partial frame (allowed by S5a), then reset.
    bfm_send(0, BASE + drv_id, 4'b1111, 1'b0, 1'b0); drv_id++;
    bfm_send(0, BASE + drv_id, 4'b0011, 1'b0, 1'b1); drv_id++;
    bfm_idle(0);
    repeat (5) @(posedge clk);
    @(negedge clk);
    quiet_mode = 1'b1;
    bfm_reset(4);
    @(posedge clk);          // first post-release sampling edge
    @(negedge clk);          // sample the value driven by that edge
    if (m_tvalid)
      fail("S12", "m_tvalid high on the first cycle after reset release");
    repeat (20) @(posedge clk);   // quiet window: nothing pre-reset may appear
    @(negedge clk);
    quiet_mode = 1'b0;
    clear_sb();
    // normal operation must work after reset
    for (int k = 0; k < S_COUNT; k++)
      send_frame(k, 2);
    wait_drain(2000);

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL (%0d error(s))", errors);
    $finish;
  end

endmodule
