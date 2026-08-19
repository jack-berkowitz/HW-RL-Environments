module frame_arb_mux_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
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
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata;
  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep;
  logic [S_COUNT-1:0]                       s_tvalid;
  logic [S_COUNT-1:0]                       s_tready;
  logic [S_COUNT-1:0]                       s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser;

  logic [DATA_WIDTH-1:0]                    m_tdata;
  logic [(DATA_WIDTH/8)-1:0]                m_tkeep;
  logic                                     m_tvalid;
  logic                                     m_tready;
  logic                                     m_tlast;
  logic [USER_WIDTH-1:0]                    m_tuser;

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------
  frame_arb_mux #(
    .S_COUNT    (S_COUNT),
    .DATA_WIDTH (DATA_WIDTH),
    .USER_WIDTH (USER_WIDTH)
  ) dut (
    .clk_i        (clk),
    .rst_i        (rst),
    .s_tdata_i    (s_tdata),
    .s_tkeep_i    (s_tkeep),
    .s_tvalid_i   (s_tvalid),
    .s_tready_o   (s_tready),
    .s_tlast_i    (s_tlast),
    .s_tuser_i    (s_tuser),
    .m_tdata_o    (m_tdata),
    .m_tkeep_o    (m_tkeep),
    .m_tvalid_o   (m_tvalid),
    .m_tready_i   (m_tready),
    .m_tlast_o    (m_tlast),
    .m_tuser_o    (m_tuser)
  );

  // ---------------------------------------------------------------------------
  // Scoreboard structures
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [DATA_WIDTH-1:0]       data;
    logic [(DATA_WIDTH/8)-1:0]   keep;
    logic                        last;
    logic                        user;
    logic [1:0]                  src;
  } beat_t;

  beat_t input_log[$];
  beat_t output_log[$];
  int    frame_start_seq[$];

  // ---------------------------------------------------------------------------
  // Input monitor
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    for (int k = 0; k < S_COUNT; k++) begin
      if (!rst && s_tvalid[k] && s_tready[k]) begin
        input_log.push_back(beat_t'{s_tdata[k], s_tkeep[k], s_tlast[k],
                                      s_tuser[k], k[1:0]});
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Output monitor
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst && m_tvalid && m_tready) begin
      output_log.push_back(beat_t'{m_tdata, m_tkeep, m_tlast, m_tuser, 2'b00});
    end
  end

  // ---------------------------------------------------------------------------
  // Helper tasks
  // ---------------------------------------------------------------------------
  task automatic fail_test(input string req, msg);
    $display("FAIL %s: %s", req, msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic send_beat(input int                    k,
                           input logic [31:0]           data,
                           input logic [3:0]            keep,
                           input logic                  last,
                           input logic                  user);
    int cnt;
    @(negedge clk);
    s_tdata[k]  = data;
    s_tkeep[k]  = keep;
    s_tlast[k]  = last;
    s_tuser[k]  = user;
    s_tvalid[k] = 1'b1;
    cnt = 0;
    forever begin
      @(posedge clk);
      cnt++;
      if (s_tready[k]) break;
      if (cnt >= 500_000) begin
        $display("FAIL S10: input %0d not granted in %0d cycles", k, cnt);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  task automatic idle_all();
    @(negedge clk);
    for (int k = 0; k < S_COUNT; k++) begin
      s_tvalid[k] = 1'b0;
    end
  endtask

  task automatic wait_drain(input int expected_count);
    int cnt;
    cnt = 0;
    while (output_log.size() < expected_count) begin
      @(posedge clk);
      cnt++;
      if (cnt > 500_000) begin
        fail_test("S5", "timeout waiting for output beats");
      end
    end
    // Allow any late extras to surface.
    repeat (5) @(posedge clk);
    if (output_log.size() != expected_count) begin
      fail_test("S5", $sformatf("output beat count %0d expected %0d",
                                 output_log.size(), expected_count));
    end
  endtask

  task automatic drive_input_frames(input int k, input int nframes);
    int f, b;
    logic [31:0] data;
    logic [3:0]  keep;
    logic        last;
    logic        user;

    for (f = 0; f < nframes; f++) begin
      for (b = 0; b < 3; b++) begin
        data = (k << 28) | (f << 16) | (b << 8) | 32'hA5;
        keep = 4'b1111;
        last = (b == 2);
        user = k[0];
        send_beat(k, data, keep, last, user);
      end
    end
  endtask

  task automatic check_output_order();
    beat_t input_q[4][$];
    int i;
    int current_input;
    int found;
    int k;
    beat_t b;
    beat_t ob;
    beat_t exp;
    beat_t first;

    frame_start_seq.delete();

    while (input_log.size() > 0) begin
      b = input_log.pop_front();
      input_q[b.src].push_back(b);
    end

    current_input = -1;
    for (i = 0; i < output_log.size(); i++) begin
      ob = output_log[i];

      if (current_input == -1) begin
        found = -1;
        for (k = 0; k < S_COUNT; k++) begin
          if (input_q[k].size() > 0) begin
            first = input_q[k][0];
            if ((first.data == ob.data) && (first.keep == ob.keep) &&
                (first.last == ob.last) && (first.user == ob.user)) begin
              found = k;
              break;
            end
          end
        end

        if (found == -1) begin
          fail_test("S4", $sformatf("unmatched output beat data=%h keep=%h last=%b user=%b",
                                     ob.data, ob.keep, ob.last, ob.user));
        end

        current_input = found;
        frame_start_seq.push_back(found);
      end

      if (input_q[current_input].size() == 0) begin
        fail_test("S3", "frame continues but selected input has no beats");
      end

      exp = input_q[current_input].pop_front();

      if ((exp.data != ob.data) || (exp.keep != ob.keep) ||
          (exp.last != ob.last) || (exp.user != ob.user)) begin
        fail_test("S4", $sformatf("payload mismatch exp data=%h keep=%h last=%b user=%b got data=%h keep=%h last=%b user=%b",
                                   exp.data, exp.keep, exp.last, exp.user,
                                   ob.data, ob.keep, ob.last, ob.user));
      end

      if (ob.last) begin
        current_input = -1;
      end
    end

    if (current_input != -1) begin
      fail_test("S3", "output ended mid-frame");
    end

    for (k = 0; k < S_COUNT; k++) begin
      if (input_q[k].size() != 0) begin
        fail_test("S5", $sformatf("input %0d has %0d untransmitted beats",
                                   k, input_q[k].size()));
      end
    end
  endtask

  task automatic check_fairness();
    int n;
    int i, j;
    bit seen[4];

    n = frame_start_seq.size();
    if (n < 16) begin
      fail_test("S10", "fewer than 16 completed output frames");
    end

    for (i = 0; i <= n - 16; i++) begin
      seen[0] = 0; seen[1] = 0; seen[2] = 0; seen[3] = 0;
      for (j = 0; j < 16; j++) begin
        seen[frame_start_seq[i+j]] = 1'b1;
      end
      if (!(seen[0] && seen[1] && seen[2] && seen[3])) begin
        fail_test("S10", $sformatf("fairness window starting at frame %0d missing an input", i));
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main stimulus
  // ---------------------------------------------------------------------------
  initial begin
    automatic int expected_beats;

    // Initialize all driven signals.
    s_tdata  = '0;
    s_tkeep  = '0;
    s_tvalid = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b0;

    // Reset and check initial idle state.
    bfm_reset(4);
    @(posedge clk);
    if (m_tvalid !== 1'b0) begin
      fail_test("S12", "m_tvalid_o not low after reset");
    end

    input_log.delete();
    output_log.delete();
    frame_start_seq.delete();

    // ------------------------------------------------------------------
    // Phase 1: basic multi/single-beat frames, backpressure
    // ------------------------------------------------------------------
    bfm_ready(1'b1);

    // Input 0: 3-beat frame.
    send_beat(0, 32'h00000001, 4'b1111, 0, 1'b0);
    send_beat(0, 32'h00000002, 4'b1111, 0, 1'b0);
    send_beat(0, 32'h00000003, 4'b1111, 1, 1'b0);

    // Input 1: single-beat frame.
    send_beat(1, 32'h00000010, 4'b1111, 1, 1'b1);

    // Input 2: 2-beat frame.
    send_beat(2, 32'h00000020, 4'b1111, 0, 1'b0);
    send_beat(2, 32'h00000021, 4'b1111, 1, 1'b0);

    // Input 3: 2-beat frame.
    send_beat(3, 32'h00000030, 4'b1111, 0, 1'b1);
    send_beat(3, 32'h00000031, 4'b1111, 1, 1'b1);

    idle_all();

    // Exercise output backpressure.
    bfm_ready(1'b0);
    repeat (10) @(posedge clk);
    bfm_ready(1'b1);

    expected_beats = input_log.size();
    wait_drain(expected_beats);
    check_output_order();

    input_log.delete();
    output_log.delete();
    frame_start_seq.delete();

    // ------------------------------------------------------------------
    // Phase 2: continuous offered load / bounded fairness (S10)
    // ------------------------------------------------------------------
    bfm_ready(1'b1);

    fork
      drive_input_frames(0, 8);
      drive_input_frames(1, 8);
      drive_input_frames(2, 8);
      drive_input_frames(3, 8);
    join

    idle_all();
    expected_beats = input_log.size();
    wait_drain(expected_beats);

    check_output_order();
    check_fairness();

    input_log.delete();
    output_log.delete();
    frame_start_seq.delete();

    // ------------------------------------------------------------------
    // Phase 3: reset discards state (S12)
    // ------------------------------------------------------------------
    bfm_ready(1'b1);

    send_beat(0, 32'h00000100, 4'b1111, 0, 1'b0);
    send_beat(0, 32'h00000101, 4'b1111, 1, 1'b0);
    idle_all();

    repeat (5) @(posedge clk);

    bfm_reset(4);
    @(posedge clk);
    if (m_tvalid !== 1'b0) begin
      fail_test("S12", "m_tvalid_o not low after reset in reset test");
    end

    input_log.delete();
    output_log.delete();
    frame_start_seq.delete();

    repeat (10) @(posedge clk);
    if (output_log.size() != 0) begin
      fail_test("S12", "output appeared after reset");
    end

    $display("RESULT: PASS");
    $finish;
  end

endmodule