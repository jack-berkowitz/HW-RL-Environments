`timescale 1ns/1ps

module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_WIDTH = DATA_WIDTH / 8;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
  logic clk;
  logic rst;

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
    .S_COUNT(S_COUNT),
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .s_tdata_i(s_tdata),
    .s_tkeep_i(s_tkeep),
    .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready),
    .s_tlast_i(s_tlast),
    .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata),
    .m_tkeep_o(m_tkeep),
    .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready),
    .m_tlast_o(m_tlast),
    .m_tuser_o(m_tuser)
  );

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

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

  // Watchdog
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Beat bookkeeping
  // ---------------------------------------------------------------------------
  typedef struct {
    int                        input_id;
    int                        frame_seq;
    int                        beat_in_frame;
    bit                        is_last;
    logic [KEEP_WIDTH-1:0]     keep;
    logic [USER_WIDTH-1:0]     user;
  } beat_info_t;

  beat_info_t beat_map[int];
  bit         beat_delivered[int];

  int global_beat_ctr;
  int frame_ctr[S_COUNT];
  int beat_ctr[S_COUNT];

  int frames_committed;
  int frames_delivered;
  int errors;

  // Output frame tracking
  int  out_current_input;
  int  out_current_frame;
  int  out_current_beat;
  bit  out_in_frame;

  // Fairness tracking (sliding window of last 16 completed frames)
  int  out_frame_inputs[$];

  // Monitor scratch (module scope to keep Verilator happy)
  logic [DATA_WIDTH-1:0] mon_data;
  int                    mon_key;
  int                    mon_in_id;
  int                    mon_i;
  logic [3:0]            mon_seen;

  // ---------------------------------------------------------------------------
  // Output monitor
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      out_in_frame      = 0;
      out_current_input = -1;
      out_current_frame = -1;
      out_current_beat  = -1;
    end else if (m_tvalid && m_tready) begin
      mon_data = m_tdata;
      mon_key  = mon_data;

      if (!beat_map.exists(mon_key)) begin
        $display("FAIL: S4/S12 unknown tdata %h at time %0t", mon_data, $time);
        errors++;
      end else begin
        mon_in_id = beat_map[mon_key].input_id;

        // S4: payload integrity
        if (m_tkeep !== beat_map[mon_key].keep) begin
          $display("FAIL: S4 tkeep mismatch at time %0t (exp %h got %h)",
                   $time, beat_map[mon_key].keep, m_tkeep);
          errors++;
        end
        if (m_tuser !== beat_map[mon_key].user) begin
          $display("FAIL: S4 tuser mismatch at time %0t", $time);
          errors++;
        end
        if (m_tlast !== beat_map[mon_key].is_last) begin
          $display("FAIL: S4 tlast mismatch at time %0t", $time);
          errors++;
        end

        // S5: no duplication
        if (beat_delivered.exists(mon_key)) begin
          $display("FAIL: S5 beat duplicated at time %0t", $time);
          errors++;
        end
        beat_delivered[mon_key] = 1;

        // S3: frame atomicity / S4: ordering
        if (out_in_frame) begin
          if (mon_in_id != out_current_input) begin
            $display("FAIL: S3 frame interleaved at time %0t", $time);
            errors++;
          end
          if (beat_map[mon_key].frame_seq != out_current_frame) begin
            $display("FAIL: S3 frame changed mid-frame at time %0t", $time);
            errors++;
          end
          if (beat_map[mon_key].beat_in_frame != out_current_beat + 1) begin
            $display("FAIL: S4 beat out of order at time %0t", $time);
            errors++;
          end
        end else begin
          if (beat_map[mon_key].beat_in_frame != 0) begin
            $display("FAIL: S4 frame started mid-frame at time %0t", $time);
            errors++;
          end
          out_current_input = mon_in_id;
          out_current_frame = beat_map[mon_key].frame_seq;
        end

        out_current_beat = beat_map[mon_key].beat_in_frame;

        if (beat_map[mon_key].is_last) begin
          out_in_frame = 0;
          frames_delivered++;

          // S10: bounded fairness
          out_frame_inputs.push_back(mon_in_id);
          if (out_frame_inputs.size() > 16) out_frame_inputs.pop_front();
          if (out_frame_inputs.size() == 16) begin
            mon_seen = 4'b0000;
            for (mon_i = 0; mon_i < 16; mon_i++) begin
              mon_seen[out_frame_inputs[mon_i]] = 1'b1;
            end
            if (mon_seen != 4'b1111) begin
              $display("FAIL: S10 fairness violated at time %0t (seen=%b)",
                       $time, mon_seen);
              errors++;
            end
          end
        end else begin
          out_in_frame = 1;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Frame driver
  // ---------------------------------------------------------------------------
  task automatic send_frame(input int k, input int num_beats);
    int  fs;
    int  b;
    bit  is_last;
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic [USER_WIDTH-1:0] user;

    fs = frame_ctr[k];
    frame_ctr[k]++;

    for (b = 0; b < num_beats; b++) begin
      is_last = (b == num_beats - 1);
      data    = global_beat_ctr;
      keep    = $urandom & 4'hF;
      user    = $urandom & 1'b1;

      beat_map[data] = '{input_id: k, frame_seq: fs, beat_in_frame: b,
                         is_last: is_last, keep: keep, user: user};

      global_beat_ctr++;
      beat_ctr[k]++;

      bfm_send(k, data, keep, is_last, user);

      if (is_last) frames_committed++;
    end
  endtask

  // Send a partial frame (no tlast) — used for reset test
  task automatic send_partial(input int k, input int num_beats);
    int  fs;
    int  b;
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic [USER_WIDTH-1:0] user;

    fs = frame_ctr[k];
    frame_ctr[k]++;

    for (b = 0; b < num_beats; b++) begin
      data = global_beat_ctr;
      keep = $urandom & 4'hF;
      user = $urandom & 1'b1;

      beat_map[data] = '{input_id: k, frame_seq: fs, beat_in_frame: b,
                         is_last: 1'b0, keep: keep, user: user};

      global_beat_ctr++;
      beat_ctr[k]++;

      bfm_send(k, data, keep, 1'b0, user);
    end
  endtask

  // Wait until every committed frame has been delivered
  task automatic wait_all_delivered();
    int timeout;
    timeout = 0;
    while (frames_delivered < frames_committed && timeout < 200000) begin
      @(posedge clk);
      timeout++;
    end
    if (frames_delivered < frames_committed) begin
      $display("FAIL: S5 timeout waiting for delivery (%0d/%0d)",
               frames_delivered, frames_committed);
      errors++;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main test
  // ---------------------------------------------------------------------------
  initial begin
    int k;
    int i;

    errors           = 0;
    global_beat_ctr  = 0;
    frames_committed = 0;
    frames_delivered = 0;
    out_in_frame     = 0;
    out_current_input = -1;
    out_current_frame = -1;
    out_current_beat  = -1;

    for (k = 0; k < S_COUNT; k++) begin
      s_tvalid[k] = 1'b0;
      s_tdata[k]  = '0;
      s_tkeep[k]  = '0;
      s_tlast[k]  = 1'b0;
      s_tuser[k]  = '0;
      frame_ctr[k] = 0;
      beat_ctr[k]  = 0;
    end
    m_tready = 1'b0;

    bfm_reset();

    // -------------------------------------------------------------------
    // Phase 1: Basic — one multi-beat frame per input, in parallel
    // -------------------------------------------------------------------
    $display("[TB] Phase 1: Basic forwarding");
    fork
      begin send_frame(0, 3); bfm_idle(0); end
      begin send_frame(1, 3); bfm_idle(1); end
      begin send_frame(2, 3); bfm_idle(2); end
      begin send_frame(3, 3); bfm_idle(3); end
    join
    wait_all_delivered();

    // -------------------------------------------------------------------
    // Phase 2: Backpressure — random m_tready while sending mixed frames
    // -------------------------------------------------------------------
    $display("[TB] Phase 2: Backpressure");
    fork
      begin
        for (i = 0; i < 300; i++) begin
          bfm_ready($urandom & 1'b1);
        end
        bfm_ready(1'b1);
      end
      begin send_frame(0, 1); send_frame(0, 2); send_frame(0, 4); bfm_idle(0); end
      begin send_frame(1, 2); send_frame(1, 1); send_frame(1, 3); bfm_idle(1); end
      begin send_frame(2, 4); send_frame(2, 1); send_frame(2, 2); bfm_idle(2); end
      begin send_frame(3, 3); send_frame(3, 4); send_frame(3, 1); bfm_idle(3); end
    join
    wait_all_delivered();

    // -------------------------------------------------------------------
    // Phase 3: Fairness — continuous load, m_tready high, 20 frames/input
    // -------------------------------------------------------------------
    $display("[TB] Phase 3: Fairness");
    bfm_ready(1'b1);
    fork
      begin for (i = 0; i < 20; i++) send_frame(0, 1); bfm_idle(0); end
      begin for (i = 0; i < 20; i++) send_frame(1, 1); bfm_idle(1); end
      begin for (i = 0; i < 20; i++) send_frame(2, 1); bfm_idle(2); end
      begin for (i = 0; i < 20; i++) send_frame(3, 1); bfm_idle(3); end
    join
    wait_all_delivered();

    // -------------------------------------------------------------------
    // Phase 4: Reset — partial frame in flight, assert reset, verify no leak
    // -------------------------------------------------------------------
    $display("[TB] Phase 4: Reset");
    bfm_ready(1'b1);
    fork
      begin send_partial(0, 2); bfm_idle(0); end
    join

    bfm_reset();

    // Clear bookkeeping: anything from before reset must not appear now
    beat_map.delete();
    beat_delivered.delete();
    frames_committed = 0;
    frames_delivered = 0;
    out_in_frame     = 0;
    out_current_input = -1;
    out_current_frame = -1;
    out_current_beat  = -1;

    // S12: m_tvalid must be low on the first cycle after reset release
    @(posedge clk);
    if (m_tvalid) begin
      $display("FAIL: S12 m_tvalid high on first cycle after reset");
      errors++;
    end

    // Also verify nothing leaks out over the next few cycles
    repeat (10) @(posedge clk);
    if (m_tvalid) begin
      $display("FAIL: S12 m_tvalid high after reset (leak)");
      errors++;
    end

    // Send a fresh frame after reset — must be forwarded correctly
    fork
      begin send_frame(1, 2); bfm_idle(1); end
    join
    wait_all_delivered();

    // -------------------------------------------------------------------
    // Final result
    // -------------------------------------------------------------------
    repeat (10) @(posedge clk);
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL (%0d errors)", errors);
    $finish;
  end

endmodule
