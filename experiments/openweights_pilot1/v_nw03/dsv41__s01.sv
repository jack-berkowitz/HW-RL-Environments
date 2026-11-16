module frame_arb_mux_tb;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_WIDTH = DATA_WIDTH / 8;

  // ---------------------------------------------------------------------------
  // Clock and reset (provided plumbing)
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst;
  initial rst = 1'b1;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata;
  logic [S_COUNT-1:0][KEEP_WIDTH-1:0]     s_tkeep;
  logic [S_COUNT-1:0]                     s_tvalid;
  logic [S_COUNT-1:0]                     s_tready;
  logic [S_COUNT-1:0]                     s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser;

  logic [DATA_WIDTH-1:0]                  m_tdata;
  logic [KEEP_WIDTH-1:0]                  m_tkeep;
  logic                                   m_tvalid;
  logic                                   m_tready;
  logic                                   m_tlast;
  logic [USER_WIDTH-1:0]                  m_tuser;

  // ---------------------------------------------------------------------------
  // DUT instantiation
  // ---------------------------------------------------------------------------
  frame_arb_mux #(
    .S_COUNT    (S_COUNT),
    .DATA_WIDTH (DATA_WIDTH),
    .USER_WIDTH (USER_WIDTH)
  ) dut (
    .clk_i      (clk),
    .rst_i      (rst),
    .s_tdata_i  (s_tdata),
    .s_tkeep_i  (s_tkeep),
    .s_tvalid_i (s_tvalid),
    .s_tready_o (s_tready),
    .s_tlast_i  (s_tlast),
    .s_tuser_i  (s_tuser),
    .m_tdata_o  (m_tdata),
    .m_tkeep_o  (m_tkeep),
    .m_tvalid_o (m_tvalid),
    .m_tready_i (m_tready),
    .m_tlast_o  (m_tlast),
    .m_tuser_o  (m_tuser)
  );

  // ---------------------------------------------------------------------------
  // Provided plumbing tasks
  // ---------------------------------------------------------------------------
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  task automatic bfm_send(input int                          k,
                          input logic [DATA_WIDTH-1:0]       data,
                          input logic [KEEP_WIDTH-1:0]       keep,
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

  // ---------------------------------------------------------------------------
  // Watchdog
  // ---------------------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Scoreboard and checker
  // ---------------------------------------------------------------------------
  typedef struct {
    int                     input_idx;
    int                     frame_id;
    int                     beat_index;
    int                     frame_len;
    logic [DATA_WIDTH-1:0]  data;
    logic [KEEP_WIDTH-1:0]  keep;
    logic [USER_WIDTH-1:0]  user;
    logic                   last;
  } beat_rec_t;

  beat_rec_t              beat_records[int];
  int unsigned            per_input_q[S_COUNT][$];
  int unsigned            discarded_ids[int];
  int                     current_frame_id    = -1;
  int                     current_frame_input = -1;
  int                     expected_beat_index = 0;
  int unsigned            seq_id              = 0;
  int unsigned            next_frame_id       = 0;
  int                     fail_count          = 0;
  int unsigned            completed_frame_count = 0;
  int                     completed_frame_inputs[$];
  bit                     stop_fairness       = 0;

  function automatic bit all_queues_empty();
    for (int i = 0; i < S_COUNT; i++) begin
      if (per_input_q[i].size() > 0) return 0;
    end
    return 1;
  endfunction

  // ---------------------------------------------------------------------------
  // Checker
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    automatic logic [DATA_WIDTH-1:0] id;
    automatic beat_rec_t             rec;

    if (rst) begin
      if (m_tvalid && m_tready) begin
        $display("FAIL S12: output beat transferred during reset");
        fail_count++;
      end
      if (m_tvalid) begin
        $display("FAIL S12: m_tvalid_o high during reset");
        fail_count++;
      end
    end else begin
      if (m_tvalid && m_tready) begin
        id = m_tdata;

        if (discarded_ids.exists(id)) begin
          $display("FAIL S12: pre-reset beat id=%0d appeared after reset", id);
          fail_count++;
        end else if (!beat_records.exists(id)) begin
          $display("FAIL S4: unexpected output beat id=%0d", id);
          fail_count++;
        end else begin
          rec = beat_records[id];

          // Payload integrity (S4)
          if (m_tdata !== rec.data) begin
            $display("FAIL S4: data mismatch id=%0d exp=%0h got=%0h", id, rec.data, m_tdata);
            fail_count++;
          end
          if (m_tkeep !== rec.keep) begin
            $display("FAIL S4: keep mismatch id=%0d exp=%0h got=%0h", id, rec.keep, m_tkeep);
            fail_count++;
          end
          if (m_tuser !== rec.user) begin
            $display("FAIL S4: user mismatch id=%0d exp=%0h got=%0h", id, rec.user, m_tuser);
            fail_count++;
          end
          if (m_tlast !== rec.last) begin
            $display("FAIL S4: last mismatch id=%0d exp=%0b got=%0b", id, rec.last, m_tlast);
            fail_count++;
          end

          // Per-input order (S4)
          if (per_input_q[rec.input_idx].size() == 0) begin
            $display("FAIL S4: output beat from input %0d but no pending beats", rec.input_idx);
            fail_count++;
          end else if (per_input_q[rec.input_idx][0] != id) begin
            $display("FAIL S4: out of order for input %0d: expected id %0d got %0d",
                     rec.input_idx, per_input_q[rec.input_idx][0], id);
            fail_count++;
          end else begin
            void'(per_input_q[rec.input_idx].pop_front());
          end

          // Frame atomicity (S3)
          if (current_frame_id == -1) begin
            if (rec.beat_index != 0) begin
              $display("FAIL S3: frame started at beat %0d (id=%0d)", rec.beat_index, id);
              fail_count++;
            end
            current_frame_id    = rec.frame_id;
            current_frame_input = rec.input_idx;
            expected_beat_index = 1;
          end else begin
            if (rec.frame_id != current_frame_id || rec.input_idx != current_frame_input) begin
              $display("FAIL S3: interleaved frame id=%0d input=%0d while frame id=%0d input=%0d in progress",
                       rec.frame_id, rec.input_idx, current_frame_id, current_frame_input);
              fail_count++;
            end else if (rec.beat_index != expected_beat_index) begin
              $display("FAIL S4: beat index mismatch in frame id=%0d: expected %0d got %0d",
                       rec.frame_id, expected_beat_index, rec.beat_index);
              fail_count++;
            end
            expected_beat_index = rec.beat_index + 1;
          end

          // End of frame
          if (rec.last) begin
            if (rec.beat_index != rec.frame_len - 1) begin
              $display("FAIL S4: last beat index %0d but frame length %0d (id=%0d)",
                       rec.beat_index, rec.frame_len, id);
              fail_count++;
            end
            current_frame_id    = -1;
            current_frame_input = -1;
            expected_beat_index = 0;
            completed_frame_inputs.push_back(rec.input_idx);
            completed_frame_count++;
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus tasks
  // ---------------------------------------------------------------------------
  task automatic send_beat(input int k,
                           input int unsigned id,
                           input int frame_id,
                           input int beat_index,
                           input int frame_len,
                           input logic last);
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic [USER_WIDTH-1:0] user;

    data = id;
    keep = id[KEEP_WIDTH-1:0];
    user = id[USER_WIDTH-1:0];

    beat_records[id] = '{input_idx: k, frame_id: frame_id, beat_index: beat_index,
                         frame_len: frame_len, data: data, keep: keep, user: user, last: last};
    per_input_q[k].push_back(id);
    bfm_send(k, data, keep, last, user);
  endtask

  task automatic send_frame(input int k, input int frame_id, input int length);
    for (int b = 0; b < length; b++) begin
      int unsigned id;
      id = seq_id;
      seq_id = seq_id + 1;
      send_beat(k, id, frame_id, b, length, (b == length - 1));
    end
    bfm_idle(k);
  endtask

  task automatic wait_queues_empty(input int timeout_cycles = 10000);
    int cycles = 0;
    while (!all_queues_empty() && cycles < timeout_cycles) begin
      @(posedge clk);
      cycles++;
    end
    if (!all_queues_empty()) begin
      $display("FAIL S5: timeout waiting for queues to empty");
      fail_count++;
    end
  endtask

  task automatic do_reset(input int cycles = 4);
    int unsigned id;
    @(negedge clk);
    rst = 1'b1;

    for (int i = 0; i < S_COUNT; i++) begin
      while (per_input_q[i].size() > 0) begin
        id = per_input_q[i].pop_front();
        discarded_ids[id] = 1;
      end
    end

    current_frame_id    = -1;
    current_frame_input = -1;
    expected_beat_index = 0;

    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    @(posedge clk);
    if (m_tvalid) begin
      $display("FAIL S12: m_tvalid_o high on first cycle after reset");
      fail_count++;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------
  initial begin
    s_tvalid = '0;
    s_tdata  = '0;
    s_tkeep  = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b1;
  end

  // ---------------------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------------------
  initial begin
    int frame_id;
    int fair_cycles;
    int check_count;

    // Initial reset
    do_reset(4);

    // -----------------------------------------------------------------------
    // Phase 1: Basic directed test
    // -----------------------------------------------------------------------
    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    send_frame(0, frame_id, 1);          // single-beat frame

    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    send_frame(1, frame_id, 3);          // 3-beat frame

    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    send_frame(2, frame_id, 1);          // single-beat frame

    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    send_frame(3, frame_id, 2);          // 2-beat frame

    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    send_frame(0, frame_id, 2);          // another frame from input 0

    wait_queues_empty();

    // -----------------------------------------------------------------------
    // Phase 2: Backpressure test
    // -----------------------------------------------------------------------
    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    fork
      begin
        bfm_ready(0);
        repeat (10) @(posedge clk);
        bfm_ready(1);
      end
      send_frame(1, frame_id, 5);
    join
    wait_queues_empty();

    // -----------------------------------------------------------------------
    // Phase 3: Fairness test (S10)
    // -----------------------------------------------------------------------
    completed_frame_inputs.delete();
    completed_frame_count = 0;
    stop_fairness = 0;
    bfm_ready(1);

    fork
      begin
        int unsigned local_id;
        int unsigned id;
        local_id = 0;
        while (!stop_fairness) begin
          id = 32'h10000000 + (0 << 20) + local_id;
          send_beat(0, id, (0 << 16) | local_id, 0, 1, 1);
          local_id = local_id + 1;
        end
        bfm_idle(0);
      end
      begin
        int unsigned local_id;
        int unsigned id;
        local_id = 0;
        while (!stop_fairness) begin
          id = 32'h10000000 + (1 << 20) + local_id;
          send_beat(1, id, (1 << 16) | local_id, 0, 1, 1);
          local_id = local_id + 1;
        end
        bfm_idle(1);
      end
      begin
        int unsigned local_id;
        int unsigned id;
        local_id = 0;
        while (!stop_fairness) begin
          id = 32'h10000000 + (2 << 20) + local_id;
          send_beat(2, id, (2 << 16) | local_id, 0, 1, 1);
          local_id = local_id + 1;
        end
        bfm_idle(2);
      end
      begin
        int unsigned local_id;
        int unsigned id;
        local_id = 0;
        while (!stop_fairness) begin
          id = 32'h10000000 + (3 << 20) + local_id;
          send_beat(3, id, (3 << 16) | local_id, 0, 1, 1);
          local_id = local_id + 1;
        end
        bfm_idle(3);
      end
    join_none

    fair_cycles = 0;
    while (completed_frame_count < 40 && fair_cycles < 5000) begin
      @(posedge clk);
      fair_cycles++;
    end
    stop_fairness = 1;

    if (completed_frame_count < 40) begin
      $display("FAIL S10: timeout waiting for 40 completed frames (got %0d)", completed_frame_count);
      fail_count++;
    end

    wait_queues_empty();

    // Check fairness windows (only the first 40 frames were under continuous load)
    check_count = (completed_frame_inputs.size() < 40) ? completed_frame_inputs.size() : 40;
    if (check_count >= 16) begin
      for (int i = 0; i <= check_count - 16; i++) begin
        bit seen[4];
        for (int j = 0; j < 4; j++) seen[j] = 0;
        for (int j = 0; j < 16; j++) begin
          seen[completed_frame_inputs[i + j]] = 1;
        end
        for (int j = 0; j < 4; j++) begin
          if (!seen[j]) begin
            $display("FAIL S10: input %0d missing in 16-frame window starting at %0d", j, i);
            fail_count++;
          end
        end
      end
    end else begin
      $display("FAIL S10: not enough completed frames for fairness check (%0d)", completed_frame_inputs.size());
      fail_count++;
    end

    // -----------------------------------------------------------------------
    // Phase 4: Reset test (S12)
    // -----------------------------------------------------------------------
    bfm_ready(0);                       // backpressure output
    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    send_frame(0, frame_id, 3);         // beats transfer on input, buffered
    do_reset(4);                        // reset discards them
    bfm_ready(1);                       // release backpressure
    repeat (20) @(posedge clk);         // give a chance for discarded beats to appear

    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    send_frame(1, frame_id, 2);         // new frame after reset
    wait_queues_empty();

    // -----------------------------------------------------------------------
    // Phase 5: More backpressure with toggling
    // -----------------------------------------------------------------------
    frame_id = next_frame_id; next_frame_id = next_frame_id + 1;
    fork
      begin
        for (int i = 0; i < 20; i++) begin
          bfm_ready(i % 2);
          repeat (3) @(posedge clk);
        end
        bfm_ready(1);
      end
      send_frame(2, frame_id, 10);
    join
    wait_queues_empty();

    // -----------------------------------------------------------------------
    // Final checks
    // -----------------------------------------------------------------------
    if (current_frame_id != -1) begin
      $display("FAIL S3: frame still in progress at end");
      fail_count++;
    end
    if (!all_queues_empty()) begin
      $display("FAIL S5: queues not empty at end");
      fail_count++;
    end

    if (fail_count == 0) begin
      $display("RESULT: PASS");
    end else begin
      $display("RESULT: FAIL");
    end
    $finish;
  end

endmodule
