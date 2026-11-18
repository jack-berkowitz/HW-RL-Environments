module frame_arb_mux_tb;
  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_WIDTH = DATA_WIDTH / 8;

  // ---- DUT signals ----------------------------------------------------------
  logic clk, rst;
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

  frame_arb_mux #(
    .S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk), .rst_i(rst),
    .s_tdata_i(s_tdata), .s_tkeep_i(s_tkeep), .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready), .s_tlast_i(s_tlast), .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata), .m_tkeep_o(m_tkeep), .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready), .m_tlast_o(m_tlast), .m_tuser_o(m_tuser)
  );

  // ---- provided plumbing ----------------------------------------------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end
  initial rst = 1'b1;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  task automatic bfm_send(input int k,
                          input logic [DATA_WIDTH-1:0]     data,
                          input logic [KEEP_WIDTH-1:0]     keep,
                          input logic                      last,
                          input logic [USER_WIDTH-1:0]     user);
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
    $display("FAIL: watchdog timeout");
    $display("RESULT: FAIL");
    $finish;
  end

  // ---- scoreboard -----------------------------------------------------------
  typedef struct {
    int                    input_k;
    int                    frame_num;
    int                    beat_idx;
    logic                  is_last;
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic [USER_WIDTH-1:0] user;
    logic                  seen;
  } beat_info_t;

  beat_info_t beat_map[int];
  int         input_queue[S_COUNT][$];
  int         next_id     = 0;
  int         total_sent  = 0;
  int         total_seen  = 0;
  int         errors      = 0;

  int         input_frame_num[S_COUNT];
  int         input_beat_idx[S_COUNT];

  int         current_frame_input = -1;
  int         expected_beat_idx   = 0;
  int         frames_completed    = 0;
  int         frame_input_history[$];
  logic       check_fairness      = 0;
  logic       stop_sending        = 0;

  task automatic clear_scoreboard();
    beat_map.delete();
    for (int k = 0; k < S_COUNT; k++) begin
      input_queue[k].delete();
    end
    total_sent          = 0;
    total_seen          = 0;
    current_frame_input = -1;
    expected_beat_idx   = 0;
    frames_completed    = 0;
    frame_input_history.delete();
  endtask

  task automatic send_beat(input int k,
                           input logic [KEEP_WIDTH-1:0] keep,
                           input logic                  last,
                           input logic [USER_WIDTH-1:0] user);
    automatic int id = next_id++;
    automatic beat_info_t info;
    info.input_k  = k;
    info.frame_num = input_frame_num[k];
    info.beat_idx  = input_beat_idx[k];
    info.is_last   = last;
    info.data      = id;
    info.keep      = keep;
    info.user      = user;
    info.seen      = 0;
    beat_map[id]   = info;
    input_queue[k].push_back(id);
    total_sent++;
    if (last) begin
      input_frame_num[k]++;
      input_beat_idx[k] = 0;
    end else begin
      input_beat_idx[k]++;
    end
    bfm_send(k, id, keep, last, user);
  endtask

  task automatic send_frame(input int k, input int len);
    for (int i = 0; i < len; i++) begin
      automatic logic [KEEP_WIDTH-1:0] keep = $urandom;
      automatic logic [USER_WIDTH-1:0] user = $urandom;
      automatic logic                  last = (i == len - 1);
      send_beat(k, keep, last, user);
    end
  endtask

  task automatic wait_drain();
    automatic int   timeout = 0;
    automatic logic empty;
    while (1) begin
      empty = 1;
      for (int k = 0; k < S_COUNT; k++) begin
        if (input_queue[k].size() > 0) empty = 0;
      end
      if (empty && total_seen == total_sent) break;
      @(posedge clk);
      timeout++;
      if (timeout > 10000) begin
        $display("FAIL S5: drain timeout (sent=%0d seen=%0d)",
                 total_sent, total_seen);
        errors++;
        break;
      end
    end
  endtask

  // ---- output monitor -------------------------------------------------------
  always @(posedge clk) begin
    automatic int         id;
    automatic beat_info_t info;
    automatic int         start;
    automatic int         i;
    automatic int         k;
    automatic logic       seen_input[S_COUNT];

    if (rst) begin
      current_frame_input <= -1;
      expected_beat_idx   <= 0;
    end else if (m_tvalid && m_tready) begin
      id = m_tdata;
      if (!beat_map.exists(id)) begin
        $display("FAIL S12/S4: unknown beat id=%0d on output", id);
        errors++;
      end else begin
        info = beat_map[id];
        if (info.seen) begin
          $display("FAIL S5: duplicate beat id=%0d", id);
          errors++;
        end
        info.seen      = 1;
        beat_map[id]   = info;
        total_seen++;

        // S3 / S4: frame atomicity and ordering
        if (current_frame_input == -1) begin
          current_frame_input <= info.input_k;
          expected_beat_idx   <= 1;
          if (info.beat_idx != 0) begin
            $display("FAIL S4: frame-start beat_idx=%0d expected 0",
                     info.beat_idx);
            errors++;
          end
          if (input_queue[info.input_k].size() == 0 ||
              input_queue[info.input_k][0] != id) begin
            $display("FAIL S4: beat id=%0d not at head of input %0d queue",
                     id, info.input_k);
            errors++;
          end else begin
            void'(input_queue[info.input_k].pop_front());
          end
        end else begin
          if (info.input_k != current_frame_input) begin
            $display("FAIL S3: frame atomicity violated (expected input %0d got %0d)",
                     current_frame_input, info.input_k);
            errors++;
          end
          if (info.beat_idx != expected_beat_idx) begin
            $display("FAIL S4: beat_idx=%0d expected %0d",
                     info.beat_idx, expected_beat_idx);
            errors++;
          end
          if (input_queue[info.input_k].size() == 0 ||
              input_queue[info.input_k][0] != id) begin
            $display("FAIL S4: beat id=%0d not at head of input %0d queue",
                     id, info.input_k);
            errors++;
          end else begin
            void'(input_queue[info.input_k].pop_front());
          end
          expected_beat_idx <= expected_beat_idx + 1;
        end

        // S4: tlast
        if (m_tlast != info.is_last) begin
          $display("FAIL S4: m_tlast=%0d expected %0d (id=%0d)",
                   m_tlast, info.is_last, id);
          errors++;
        end

        // S4: payload integrity
        if (m_tdata != info.data) begin
          $display("FAIL S4: data mismatch id=%0d got=%0h exp=%0h",
                   id, m_tdata, info.data);
          errors++;
        end
        if (m_tkeep != info.keep) begin
          $display("FAIL S4: keep mismatch id=%0d got=%0h exp=%0h",
                   id, m_tkeep, info.keep);
          errors++;
        end
        if (m_tuser != info.user) begin
          $display("FAIL S4: user mismatch id=%0d got=%0h exp=%0h",
                   id, m_tuser, info.user);
          errors++;
        end

        // Frame completion + S10 fairness
        if (info.is_last) begin
          current_frame_input <= -1;
          expected_beat_idx   <= 0;
          frames_completed++;
          frame_input_history.push_back(info.input_k);
          if (check_fairness && frame_input_history.size() >= 16) begin
            start = frame_input_history.size() - 16;
            for (k = 0; k < S_COUNT; k++) seen_input[k] = 0;
            for (i = start; i < frame_input_history.size(); i++) begin
              seen_input[frame_input_history[i]] = 1;
            end
            for (k = 0; k < S_COUNT; k++) begin
              if (!seen_input[k]) begin
                $display("FAIL S10: input %0d not seen in last 16 frames", k);
                errors++;
              end
            end
          end
        end
      end
    end
  end

  // ---- sender thread for fairness test --------------------------------------
  task automatic sender_thread(input int k);
    while (!stop_sending) begin
      automatic int len = 1 + ($urandom & 3);
      send_frame(k, len);
    end
  endtask

  task automatic spawn_sender(input int k);
    fork
      sender_thread(k);
    join_none
  endtask

  // ---- main test ------------------------------------------------------------
  initial begin
    s_tvalid = '0;
    s_tdata  = '0;
    s_tkeep  = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b0;
    for (int k = 0; k < S_COUNT; k++) begin
      input_frame_num[k] = 0;
      input_beat_idx[k]  = 0;
    end

    bfm_reset(4);

    // ---- Phase 1: reset test (S12) -----------------------------------------
    // Send some beats; they transfer on input but stay in the design's buffer.
    fork
      send_frame(0, 3);
      send_frame(1, 2);
    join
    // Assert reset; design must discard buffered beats.
    bfm_reset(4);
    // Discard scoreboard so any pre-reset beat appearing now is "unknown".
    clear_scoreboard();
    // First cycle after release: m_tvalid_o must be low.
    @(posedge clk);
    if (m_tvalid) begin
      $display("FAIL S12: m_tvalid_o high on first cycle after reset release");
      errors++;
    end
    // Post-reset traffic must flow normally.
    bfm_ready(1);
    fork
      send_frame(0, 2);
      send_frame(2, 3);
    join
    wait_drain();

    // ---- Phase 2: basic forwarding (S3/S4/S5) ------------------------------
    bfm_ready(1);
    fork
      send_frame(0, 3);
      send_frame(1, 1);   // single-beat frame (S2)
      send_frame(2, 4);
      send_frame(3, 2);
    join
    wait_drain();

    // ---- Phase 3: backpressure (S8) ----------------------------------------
    fork
      send_frame(0, 3);
      send_frame(1, 2);
      send_frame(2, 3);
      send_frame(3, 2);
    join_none
    for (int i = 0; i < 100; i++) begin
      bfm_ready($urandom & 1);
    end
    bfm_ready(1);
    wait fork;
    wait_drain();

    // ---- Phase 4: fairness under continuous load (S10) ---------------------
    check_fairness = 1;
    stop_sending   = 0;
    bfm_ready(1);
    for (int k = 0; k < S_COUNT; k++) begin
      spawn_sender(k);
    end
    wait (frames_completed >= 100);
    stop_sending = 1;
    wait fork;
    wait_drain();
    check_fairness = 0;

    // ---- final tally -------------------------------------------------------
    if (total_sent != total_seen) begin
      $display("FAIL S5: total_sent=%0d total_seen=%0d",
               total_sent, total_seen);
      errors++;
    end

    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end
endmodule
