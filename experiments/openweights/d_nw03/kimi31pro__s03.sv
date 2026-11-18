module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,
  parameter int unsigned M_COUNT = 4,
  parameter int unsigned DATA_W  = 32
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,

  input  logic [S_COUNT-1:0]                s_valid_i,
  output logic [S_COUNT-1:0]                s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]         s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]     s_keep_i,
  input  logic [S_COUNT-1:0]                s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  output logic [M_COUNT-1:0]                m_valid_o,
  input  logic [M_COUNT-1:0]                m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]         m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]     m_keep_o,
  output logic [M_COUNT-1:0]                m_last_o
);

  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned SEL_W  = $clog2(S_COUNT);

  // Each output independently locks onto one input for a complete frame.
  logic [M_COUNT-1:0]       active_q;
  logic [SEL_W-1:0]         sel_q [0:M_COUNT-1];
  logic [SEL_W-1:0]         rr_q  [0:M_COUNT-1];

  logic [S_COUNT-1:0]       req [0:M_COUNT-1];
  logic [M_COUNT-1:0]       arb_valid;
  logic [SEL_W-1:0]         arb_sel [0:M_COUNT-1];

  // Independent round-robin arbitration for every output.
  always_comb begin : p_arbitrate
    integer o;
    integer i;
    integer k;
    integer idx;
    logic   found;

    for (o = 0; o < M_COUNT; o = o + 1) begin
      req[o] = '0;
      for (i = 0; i < S_COUNT; i = i + 1) begin
        req[o][i] = s_valid_i[i] &&
                    (s_dest_i[i*DEST_W +: DEST_W] == DEST_W'(o));
      end

      arb_valid[o] = |req[o];
      arb_sel[o]   = '0;
      found        = 1'b0;
      idx          = 0;

      for (k = 0; k < S_COUNT; k = k + 1) begin
        idx = rr_q[o] + k;
        if (idx >= S_COUNT)
          idx = idx - S_COUNT;

        if (!found && req[o][idx]) begin
          arb_sel[o] = SEL_W'(idx);
          found      = 1'b1;
        end
      end
    end
  end

  // Cut-through datapaths. An idle output that is stalled registers its
  // selection, ensuring that the offered beat remains stable.
  always_comb begin : p_datapath
    integer o;

    s_ready_o = '0;
    m_valid_o = '0;
    m_data_o  = '0;
    m_keep_o  = '0;
    m_last_o  = '0;

    if (rst_ni) begin
      for (o = 0; o < M_COUNT; o = o + 1) begin
        if (active_q[o]) begin
          m_valid_o[o] = s_valid_i[sel_q[o]];
          m_data_o[o*DATA_W +: DATA_W] =
              s_data_i[sel_q[o]*DATA_W +: DATA_W];
          m_keep_o[o*KEEP_W +: KEEP_W] =
              s_keep_i[sel_q[o]*KEEP_W +: KEEP_W];
          m_last_o[o] = s_last_i[sel_q[o]];

          if (m_ready_i[o])
            s_ready_o[sel_q[o]] = 1'b1;
        end else if (arb_valid[o]) begin
          m_valid_o[o] = 1'b1;
          m_data_o[o*DATA_W +: DATA_W] =
              s_data_i[arb_sel[o]*DATA_W +: DATA_W];
          m_keep_o[o*KEEP_W +: KEEP_W] =
              s_keep_i[arb_sel[o]*KEEP_W +: KEEP_W];
          m_last_o[o] = s_last_i[arb_sel[o]];

          if (m_ready_i[o])
            s_ready_o[arb_sel[o]] = 1'b1;
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin : p_state
    integer o;

    if (!rst_ni) begin
      active_q <= '0;
      for (o = 0; o < M_COUNT; o = o + 1) begin
        sel_q[o] <= '0;
        rr_q[o]  <= '0;
      end
    end else begin
      for (o = 0; o < M_COUNT; o = o + 1) begin
        if (!active_q[o]) begin
          if (arb_valid[o]) begin
            if (m_ready_i[o]) begin
              // The first beat transfers directly through the idle path.
              if (s_last_i[arb_sel[o]]) begin
                active_q[o] <= 1'b0;
                rr_q[o]     <= arb_sel[o] + 1'b1;
              end else begin
                active_q[o] <= 1'b1;
                sel_q[o]    <= arb_sel[o];
              end
            end else begin
              // Lock an offered but unaccepted beat to preserve stability.
              active_q[o] <= 1'b1;
              sel_q[o]    <= arb_sel[o];
            end
          end
        end else if (s_valid_i[sel_q[o]] && m_ready_i[o]) begin
          if (s_last_i[sel_q[o]]) begin
            active_q[o] <= 1'b0;
            rr_q[o]     <= sel_q[o] + 1'b1;
          end
        end
      end
    end
  end

endmodule
