`timescale 1ns/1ps

module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_WIDTH = DATA_WIDTH / 8;

  localparam int FUNC_FRAMES_PER_INPUT = 3;
  localparam int FAIRNESS_WINDOW       = 16;
  localparam int FAIRNESS_FRAMES_NEEDED = 80;
  localparam int TIMEOUT_NS            = 10_000_000; // 10 ms

  typedef struct {
    int unsigned input_id;
    int unsigned frame_id;
    int unsigned beat_in_frame;
    int unsigned tag;
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic                 last;
    logic [USER_WIDTH-1:0] user;
  } beat_t;

  logic clk_i = 1'b0;
  logic rst_i;
  initial begin
    rst_i = 1'b1;
    repeat (10) @(posedge clk_i);
    rst_i = 1'b0;
  end

  logic [S_COUNT-1:0][DATA_WIDTH-1:0] s_tdata_i;
  logic [S_COUNT-1:0][KEEP_WIDTH-1:0] s_tkeep_i;
  logic [S_COUNT-1:0]                 s_tvalid_i;
  logic [S_COUNT-1:0]                 s_tready_o;
  logic [S_COUNT-1:0]                 s_tlast_i;
  logic [S_COUNT-1:0][USER_WIDTH-1:0] s_tuser_i;

  logic [DATA_WIDTH-1:0]             m_tdata_o;
  logic [KEEP_WIDTH-1:0]             m_tkeep_o;
  logic                              m_tvalid_o;
  logic                              m_tready_i;
  logic                              m_tlast_o;
  logic [USER_WIDTH-1:0]             m_tuser_o;

  frame_arb_mux #(
    .S_COUNT   (S_COUNT),
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i     (clk_i),
    .rst_i     (rst_i),
    .s_tdata_i (s_tdata_i),
    .s_tkeep_i (s_tkeep_i),
    .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o),
    .s_tlast_i (s_tlast_i),
    .s_tuser_i (s_tuser_i),
    .m_tdata_o (m_tdata_o),
    .m_tkeep_o (m_tkeep_o),
    .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i),
    .m_tlast_o (m_tlast_o),
    .m_tuser_o (m_tuser_o)
  );

  // Internal testbench state
  logic [S_COUNT-1:0]                 valid_drive;
  logic [S_COUNT-1:0][DATA_WIDTH-1:0] data_drive;
  logic [S_COUNT-1:0][KEEP_WIDTH-1:0] keep_drive;
  logic [S_COUNT-1:0]                 last_drive;
  logic [S_COUNT-1:0][USER_WIDTH-1:0] user_drive;

  int unsigned local_tag  [S_COUNT];
  int unsigned frame_id   [S_COUNT];
  int unsigned beat_idx   [S_COUNT];
  int unsigned frame_len  [S_COUNT];
  int unsigned frames_sent[S_COUNT];
  int unsigned out_ptr    [S_COUNT];

  beat_t in_q[S_COUNT][$];

  typedef enum int {
    PH_RESET,
    PH_FUNC,
    PH_FAIR,
    PH_DONE
  } phase_t;

  phase_t phase = PH_RESET;

  logic prev_rst = 1'b1;
  int unsigned cycle_count = 0;
  logic m_tready_drive = 1'b1;
  logic stop_offer = 1'b0;
  int unsigned fair_frames_seen = 0;
  int fair_window[$];

  logic current_frame_active = 1'b0;
  int current_source = -1;
  int current_frame  = -1;

  int unsigned total_output_beats = 0;
  logic done = 1'b0;
  logic failed = 1'b0;

  // Clock generator
  always #5 clk_i = ~clk_i;

  // Watchdog
  initial begin
    #TIMEOUT_NS;
    if (!done) begin
      $display("FAIL requirement Watchdog");
      $display("RESULT: FAIL");
      $finish;
    end
  end

  task automatic fail(input string req);
    if (!done && !failed) begin
      failed = 1'b1;
      done   = 1'b1;
      $display("FAIL requirement %s", req);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic logic [DATA_WIDTH-1:0] make_data(input int k, input int unsigned tag);
    logic [3:0]  kk;
    logic [27:0] tt;
    kk = k[3:0];
    tt = tag[27:0];
    return {kk, tt};
  endfunction

  function automatic logic [KEEP_WIDTH-1:0] make_keep(input int k, input int unsigned tag);
    logic [KEEP_WIDTH-1:0] kk;
    kk = (tag + 1) & 4'hF;
    return kk;
  endfunction

  function automatic logic [USER_WIDTH-1:0] make_user(input int k, input int unsigned tag);
    logic [USER_WIDTH-1:0] u;
    u = (tag ^ k) & 1'b1;
    return u;
  endfunction

  function automatic int unsigned func_len(input int k);
    return 2 + (k % 3);
  endfunction

  function automatic logic all_inputs_deasserted();
    for (int k = 0; k < S_COUNT; k++) begin
      if (valid_drive[k] !== 1'b0) return 1'b0;
    end
    return 1'b1;
  endfunction

  function automatic logic all_out_ptr_done();
    for (int k = 0; k < S_COUNT; k++) begin
      if (out_ptr[k] != in_q[k].size()) return 1'b0;
    end
    return 1'b1;
  endfunction

  function automatic logic fair_window_has(input int id);
    for (int i = 0; i < fair_window.size(); i++) begin
      if (fair_window[i] == id) return 1'b1;
    end
    return 1'b0;
  endfunction

  task automatic init_func_phase();
    phase = PH_FUNC;
    stop_offer = 1'b0;
    fair_frames_seen = 0;
    fair_window.delete();
    current_frame_active = 1'b0;
    current_source = -1;
    current_frame  = -1;
    cycle_count = 0;
    total_output_beats = 0;
    m_tready_drive = 1'b1;

    for (int k = 0; k < S_COUNT; k++) begin
      local_tag[k]   = 0;
      frame_id[k]    = 0;
      beat_idx[k]    = 0;
      frame_len[k]   = func_len(k);
      frames_sent[k] = 0;
      valid_drive[k] = 1'b1;
      data_drive[k]  = make_data(k, local_tag[k]);
      keep_drive[k]  = make_keep(k, local_tag[k]);
      last_drive[k]  = (frame_len[k] == 1);
      user_drive[k]  = make_user(k, local_tag[k]);
      out_ptr[k]     = 0;
      in_q[k].delete();
    end
  endtask

  task automatic init_fair_phase();
    phase = PH_FAIR;
    stop_offer = 1'b0;
    fair_frames_seen = 0;
    fair_window.delete();
    current_frame_active = 1'b0;
    current_source = -1;
    current_frame  = -1;
    total_output_beats = 0;
    m_tready_drive = 1'b1;

    for (int k = 0; k < S_COUNT; k++) begin
      local_tag[k]   = 0;
      frame_id[k]    = 0;
      beat_idx[k]    = 0;
      frame_len[k]   = 1;
      frames_sent[k] = 0;
      valid_drive[k] = 1'b1;
      data_drive[k]  = make_data(k, local_tag[k]);
      keep_drive[k]  = make_keep(k, local_tag[k]);
      last_drive[k]  = 1'b1;
      user_drive[k]  = make_user(k, local_tag[k]);
      out_ptr[k]     = 0;
      in_q[k].delete();
    end
  endtask

  task automatic record_input_beat(input int k);
    beat_t rec;
    rec.input_id      = k;
    rec.frame_id      = frame_id[k];
    rec.beat_in_frame = beat_idx[k];
    rec.tag           = local_tag[k];
    rec.data          = s_tdata_i[k];
    rec.keep          = s_tkeep_i[k];
    rec.last          = s_tlast_i[k];
    rec.user          = s_tuser_i[k];
    in_q[k].push_back(rec);
  endtask

  task automatic advance_input_state(input int k);
    if (phase == PH_FUNC) begin
      local_tag[k] = local_tag[k] + 1;

      if (beat_idx[k] + 1 < frame_len[k]) begin
        beat_idx[k] = beat_idx[k] + 1;
        data_drive[k] = make_data(k, local_tag[k]);
        keep_drive[k] = make_keep(k, local_tag[k]);
        last_drive[k] = (beat_idx[k] == frame_len[k]-1);
        user_drive[k] = make_user(k, local_tag[k]);
      end else begin
        frames_sent[k] = frames_sent[k] + 1;
        if (frames_sent[k] >= FUNC_FRAMES_PER_INPUT) begin
          valid_drive[k] = 1'b0;
        end else begin
          frame_id[k]  = frame_id[k] + 1;
          beat_idx[k]  = 0;
          frame_len[k] = func_len(k);
          data_drive[k] = make_data(k, local_tag[k]);
          keep_drive[k] = make_keep(k, local_tag[k]);
          last_drive[k] = (frame_len[k] == 1);
          user_drive[k] = make_user(k, local_tag[k]);
        end
      end
    end else if (phase == PH_FAIR) begin
      if (stop_offer) begin
        valid_drive[k] = 1'b0;
      end else begin
        local_tag[k] = local_tag[k] + 1;
        frame_id[k]  = frame_id[k] + 1;
        beat_idx[k]  = 0;
        frame_len[k] = 1;
        data_drive[k] = make_data(k, local_tag[k]);
        keep_drive[k] = make_keep(k, local_tag[k]);
        last_drive[k] = 1'b1;
        user_drive[k] = make_user(k, local_tag[k]);
      end
    end
  endtask

  task automatic process_output_beat();
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic [USER_WIDTH-1:0] user;
    logic                 last;
    int unsigned          k;
    int unsigned          tag;
    beat_t                exp;

    data = m_tdata_o;
    keep = m_tkeep_o;
    user = m_tuser_o;
    last = m_tlast_o;

    k   = data[31:28];
    tag = data[27:0];

    if (k >= S_COUNT) begin
      fail("S4");
      return;
    end

    if (tag >= in_q[k].size()) begin
      fail("S4");
      return;
    end

    exp = in_q[k][tag];

    if (data !== exp.data) begin fail("S4"); return; end
    if (keep !== exp.keep) begin fail("S4"); return; end
    if (user !== exp.user) begin fail("S4"); return; end
    if (last !== exp.last) begin fail("S4"); return; end

    if (tag != out_ptr[k]) begin
      if (tag < out_ptr[k]) fail("S5");
      else                  fail("S4");
      return;
    end

    if (!current_frame_active) begin
      current_frame_active = 1'b1;
      current_source       = k;
      current_frame        = exp.frame_id;
    end else begin
      if (k != current_source || exp.frame_id != current_frame) begin
        fail("S3");
        return;
      end
    end

    if (last) begin
      current_frame_active = 1'b0;
    end

    out_ptr[k] = tag + 1;
    total_output_beats = total_output_beats + 1;

    if (phase == PH_FAIR) begin
      fair_frames_seen = fair_frames_seen + 1;
      fair_window.push_back(k);
      if (fair_window.size() > FAIRNESS_WINDOW) begin
        void'(fair_window.pop_front());
      end
      if (fair_window.size() == FAIRNESS_WINDOW) begin
        for (int id = 0; id < S_COUNT; id++) begin
          if (!fair_window_has(id)) begin
            fail("S10");
            return;
          end
        end
      end
    end
  endtask

  task automatic final_pass();
    if (done || failed) return;

    for (int k = 0; k < S_COUNT; k++) begin
      if (out_ptr[k] != in_q[k].size()) begin
        fail("S5");
        return;
      end
    end

    int unsigned total_in = 0;
    for (int k = 0; k < S_COUNT; k++) begin
      total_in = total_in + in_q[k].size();
    end

    if (total_output_beats != total_in) begin
      fail("S5");
      return;
    end

    done = 1'b1;
    $display("RESULT: PASS");
    $finish;
  endtask

  always @(posedge clk_i) begin
    if (rst_i) begin
      phase = PH_RESET;
      prev_rst <= 1'b1;
      cycle_count = 0;
      m_tready_drive = 1'b1;
      stop_offer = 1'b0;
      fair_frames_seen = 0;
      fair_window.delete();
      current_frame_active = 1'b0;
      current_source = -1;
      current_frame  = -1;
      total_output_beats = 0;

      for (int k = 0; k < S_COUNT; k++) begin
        valid_drive[k] = 1'b0;
        data_drive[k]  = '0;
        keep_drive[k]  = '0;
        last_drive[k]  = 1'b0;
        user_drive[k]  = '0;
        local_tag[k]   = 0;
        frame_id[k]    = 0;
        beat_idx[k]    = 0;
        frame_len[k]   = 1;
        frames_sent[k] = 0;
        out_ptr[k]     = 0;
        in_q[k].delete();
      end
    end else begin
      if (prev_rst) begin
        if (m_tvalid_o !== 1'b0) begin
          fail("S12");
        end
        init_func_phase();
        prev_rst <= 1'b0;
        cycle_count = 0;
      end else begin
        cycle_count <= cycle_count + 1;

        // Input transfers
        for (int k = 0; k < S_COUNT; k++) begin
          if (s_tvalid_i[k] && s_tready_o[k]) begin
            record_input_beat(k);
            advance_input_state(k);
          end
        end

        // Output transfer
        if (m_tvalid_o && m_tready_i) begin
          process_output_beat();
        end

        // Phase control
        if (phase == PH_FUNC) begin
          if (all_inputs_deasserted()) begin
            m_tready_drive = 1'b1;
          end else begin
            if ((cycle_count % 7) >= 5) m_tready_drive = 1'b0;
            else                        m_tready_drive = 1'b1;
          end

          if (all_inputs_deasserted() && all_out_ptr_done()) begin
            init_fair_phase();
          end
        end else if (phase == PH_FAIR) begin
          m_tready_drive = 1'b1;

          if (fair_frames_seen >= FAIRNESS_FRAMES_NEEDED) begin
            stop_offer = 1'b1;
          end

          if (stop_offer && all_inputs_deasserted() && all_out_ptr_done()) begin
            final_pass();
          end
        end
      end
    end

    // Drive DUT inputs from internal state
    for (int k = 0; k < S_COUNT; k++) begin
      s_tvalid_i[k] <= valid_drive[k];
      s_tdata_i[k]  <= data_drive[k];
      s_tkeep_i[k]  <= keep_drive[k];
      s_tlast_i[k]  <= last_drive[k];
      s_tuser_i[k]  <= user_drive[k];
    end
    m_tready_i <= m_tready_drive;
  end

endmodule