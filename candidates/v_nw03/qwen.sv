module frame_arb_mux_tb;
  localparam int S_COUNT = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_WIDTH = DATA_WIDTH / 8;

  logic clk_i;
  logic rst_i;

  logic [S_COUNT-1:0][DATA_WIDTH-1:0] s_tdata_i;
  logic [S_COUNT-1:0][KEEP_WIDTH-1:0] s_tkeep_i;
  logic [S_COUNT-1:0] s_tvalid_i;
  logic [S_COUNT-1:0] s_tready_o;
  logic [S_COUNT-1:0] s_tlast_i;
  logic [S_COUNT-1:0][USER_WIDTH-1:0] s_tuser_i;

  logic [DATA_WIDTH-1:0] m_tdata_o;
  logic [KEEP_WIDTH-1:0] m_tkeep_o;
  logic m_tvalid_o;
  logic m_tready_i;
  logic m_tlast_o;
  logic [USER_WIDTH-1:0] m_tuser_o;

  frame_arb_mux #(
    .S_COUNT(S_COUNT),
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .s_tdata_i(s_tdata_i),
    .s_tkeep_i(s_tkeep_i),
    .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o),
    .s_tlast_i(s_tlast_i),
    .s_tuser_i(s_tuser_i),
    .m_tdata_o(m_tdata_o),
    .m_tkeep_o(m_tkeep_o),
    .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i),
    .m_tlast_o(m_tlast_o),
    .m_tuser_o(m_tuser_o)
  );

  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  initial begin
    #200000;
    $display("RESULT: FAIL");
    $display("Watchdog timeout");
    $finish;
  end

  typedef struct {
    logic [DATA_WIDTH-1:0] tdata;
    logic [KEEP_WIDTH-1:0] tkeep;
    logic tlast;
    logic [USER_WIDTH-1:0] tuser;
  } beat_t;

  beat_t pending_beats[S_COUNT][$];
  int current_frame_source = -1;
  int frame_source_history[$];
  int fail_count = 0;
  int pass_count = 0;
  bit pre_reset_beats_driven = 0;
  int pre_reset_beat_count = 0;
  int post_reset_output_count = 0;

  task automatic check(string req, bit pass, string msg = "");
    if (pass) begin
      pass_count++;
    end else begin
      fail_count++;
      $display("FAIL: %s - %s", req, msg);
    end
  endtask

  generate
    for (genvar k = 0; k < S_COUNT; k++) begin : gen_input_monitor
      always @(posedge clk_i) begin
        if (!rst_i && s_tvalid_i[k] && s_tready_o[k]) begin
          beat_t beat;
          beat.tdata = s_tdata_i[k];
          beat.tkeep = s_tkeep_i[k];
          beat.tlast = s_tlast_i[k];
          beat.tuser = s_tuser_i[k];
          pending_beats[k].push_back(beat);
          
          if (pre_reset_beats_driven) begin
            pre_reset_beat_count++;
          end
        end
      end
    end
  endgenerate

  always @(posedge clk_i) begin
    if (!rst_i && m_tvalid_o && m_tready_i) begin
      beat_t out_beat;
      out_beat.tdata = m_tdata_o;
      out_beat.tkeep = m_tkeep_o;
      out_beat.tlast = m_tlast_o;
      out_beat.tuser = m_tuser_o;

      int found = -1;
      for (int k = 0; k < S_COUNT; k++) begin
        if (pending_beats[k].size() > 0) begin
          beat_t expected = pending_beats[k][0];
          if (out_beat.tdata === expected.tdata &&
              out_beat.tkeep === expected.tkeep &&
              out_beat.tlast === expected.tlast &&
              out_beat.tuser === expected.tuser) begin
            found = k;
            break;
          end
        end
      end

      if (found < 0) begin
        check("S4", 0, "Output beat doesn't match any pending input beat");
      end else begin
        if (current_frame_source >= 0 && current_frame_source != found) begin
          check("S3", 0, $sformatf("Frame atomicity violation: expected source %0d, got %0d",
                                    current_frame_source, found));
        end

        pending_beats[found].delete(0);

        if (current_frame_source < 0) begin
          current_frame_source = found;
          frame_source_history.push_back(found);
          
          if (frame_source_history.size() >= 16) begin
            int seen[S_COUNT];
            for (int i = 0; i < S_COUNT; i++) seen[i] = 0;
            
            for (int i = frame_source_history.size() - 16; i < frame_source_history.size(); i++) begin
              seen[frame_source_history[i]] = 1;
            end
            
            for (int i = 0; i < S_COUNT; i++) begin
              check("S10", seen[i], $sformatf("Input %0d not seen in last 16 frames", i));
            end
          end
        end

        if (m_tlast_o) begin
          current_frame_source = -1;
        end
      end

      if (post_reset_output_count > 0 || pre_reset_beat_count > 0) begin
        post_reset_output_count++;
      end
    end
  end

  task automatic drive_beat(int src, beat_t beat);
    s_tdata_i[src] = beat.tdata;
    s_tkeep_i[src] = beat.tkeep;
    s_tvalid_i[src] = 1;
    s_tlast_i[src] = beat.tlast;
    s_tuser_i[src] = beat.tuser;

    while (!(s_tvalid_i[src] && s_tready_o[src])) begin
      @(posedge clk_i);
    end
    @(posedge clk_i);
    s_tvalid_i[src] = 0;
  endtask

  task automatic drive_frame(int src, int num_beats);
    for (int i = 0; i < num_beats; i++) begin
      beat_t beat;
      beat.tdata = $urandom();
      beat.tkeep = $urandom();
      beat.tlast = (i == num_beats - 1);
      beat.tuser = $urandom_range(0, (1 << USER_WIDTH) - 1);
      drive_beat(src, beat);
    end
  endtask

  task automatic wait_for_pending_empty();
    while (pending_beats[0].size() > 0 || pending_beats[1].size() > 0 ||
           pending_beats[2].size() > 0 || pending_beats[3].size() > 0) begin
      @(posedge clk_i);
    end
    repeat (5) @(posedge clk_i);
  endtask

  initial begin
    for (int i = 0; i < S_COUNT; i++) begin
      s_tvalid_i[i] = 0;
      s_tdata_i[i] = '0;
      s_tkeep_i[i] = '0;
      s_tlast_i[i] = 0;
      s_tuser_i[i] = '0;
    end

    rst_i = 1;
    m_tready_i = 0;

    repeat (10) @(posedge clk_i);
    rst_i = 0;
    @(posedge clk_i);

    m_tready_i = 1;

    $display("Test 1: Single-beat frames");
    fork
      drive_frame(0, 1);
      drive_frame(1, 1);
      drive_frame(2, 1);
      drive_frame(3, 1);
    join
    wait_for_pending_empty();

    $display("Test 2: Multi-beat frames");
    fork
      drive_frame(0, 3);
      drive_frame(1, 2);
      drive_frame(2, 4);
      drive_frame(3, 1);
    join
    wait_for_pending_empty();

    $display("Test 3: Backpressure");
    m_tready_i = 0;
    fork
      drive_frame(0, 2);
      drive_frame(1, 2);
      drive_frame(2, 2);
      drive_frame(3, 2);
    join
    repeat (20) @(posedge clk_i);
    m_tready_i = 1;
    wait_for_pending_empty();

    $display("Test 4: Reset behavior");
    pre_reset_beats_driven = 1;
    pre_reset_beat_count = 0;
    fork
      drive_frame(0, 3);
      drive_frame(1, 3);
    join_none
    repeat (3) @(posedge clk_i);
    
    rst_i = 1;
    repeat (5) @(posedge clk_i);
    rst_i = 0;
    
    for (int i = 0; i < S_COUNT; i++) begin
      pending_beats[i].delete();
      s_tvalid_i[i] = 0;
    end
    pre_reset_beats_driven = 0;
    
    repeat (10) @(posedge clk_i);
    check("S12", !m_tvalid_o, "Output valid after reset");
    
    fork
      drive_frame(0, 2);
      drive_frame(1, 2);
    join
    wait_for_pending_empty();

    $display("Test 5: Fairness");
    frame_source_history.delete();
    fork
      repeat (20) drive_frame(0, 1);
      repeat (20) drive_frame(1, 1);
      repeat (20) drive_frame(2, 1);
      repeat (20) drive_frame(3, 1);
    join
    wait_for_pending_empty();

    for (int i = 0; i < S_COUNT; i++) begin
      check("S5", pending_beats[i].size() == 0,
            $sformatf("Input %0d has pending beats", i));
    end

    if (fail_count == 0) begin
      $display("RESULT: PASS");
    end else begin
      $display("RESULT: FAIL");
    end
    $finish;
  end

endmodule