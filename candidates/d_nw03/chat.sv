module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                                clk_i,
  input  logic                                rst_ni,

  // ---- input streams, concatenated port-major ------------------------------
  input  logic [S_COUNT-1:0]                  s_valid_i,
  output logic [S_COUNT-1:0]                  s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]           s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]       s_keep_i,
  input  logic [S_COUNT-1:0]                  s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0]  s_dest_i,

  // ---- output streams, concatenated port-major -----------------------------
  output logic [M_COUNT-1:0]                  m_valid_o,
  input  logic [M_COUNT-1:0]                  m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]           m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]       m_keep_o,
  output logic [M_COUNT-1:0]                  m_last_o
);

  localparam int unsigned KEEP_W  = DATA_W / 8;
  localparam int unsigned DEST_W  = $clog2(M_COUNT);
  localparam int unsigned S_IDX_W = $clog2(S_COUNT);


  /*
   * --------------------------------------------------------------------------
   * Unpacked input views
   * --------------------------------------------------------------------------
   */

  logic [DATA_W-1:0] s_data_u [0:S_COUNT-1];
  logic [KEEP_W-1:0] s_keep_u [0:S_COUNT-1];
  logic [DEST_W-1:0] s_dest_u [0:S_COUNT-1];

  genvar gi;

  generate
    for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : GEN_INPUT_UNPACK

      assign s_data_u[gi] =
          s_data_i[
            gi*DATA_W +: DATA_W
          ];

      assign s_keep_u[gi] =
          s_keep_i[
            gi*KEEP_W +: KEEP_W
          ];

      assign s_dest_u[gi] =
          s_dest_i[
            gi*DEST_W +: DEST_W
          ];

    end
  endgenerate


  /*
   * --------------------------------------------------------------------------
   * Per-output state
   * --------------------------------------------------------------------------
   *
   * owner_valid_q[o]:
   *
   *   0 -> output o is between frames and may arbitrate.
   *
   *   1 -> output o is locked to owner_q[o].  The lock remains through gaps
   *        in valid and through output backpressure, and is released only when
   *        that owner's LAST beat handshakes.
   *
   * The same lock also handles a first beat that is presented while the output
   * is stalled.  This is required so m_data/m_keep/m_last cannot change while
   * m_valid is asserted and m_ready is low.
   */

  logic [M_COUNT-1:0] owner_valid_q;

  logic [S_IDX_W-1:0] owner_q [0:M_COUNT-1];

  /*
   * First input considered when the output next arbitrates.
   */
  logic [S_IDX_W-1:0] rr_q [0:M_COUNT-1];


  /*
   * Combinational winner for each output.
   */
  logic [M_COUNT-1:0] sel_valid_c;

  logic [S_IDX_W-1:0] sel_idx_c [0:M_COUNT-1];


  /*
   * --------------------------------------------------------------------------
   * Independent output arbitration and crossbar
   * --------------------------------------------------------------------------
   *
   * There is one arbitration decision PER OUTPUT, not one global decision.
   * Therefore four disjoint pairs can transfer four beats on one clock.
   */

  always_comb begin : route_comb

    integer o;
    integer k;
    integer idx;
    logic   found;

    s_ready_o = '0;

    m_valid_o = '0;
    m_data_o  = '0;
    m_keep_o  = '0;
    m_last_o  = '0;

    sel_valid_c = '0;

    for (o = 0; o < M_COUNT; o = o + 1) begin

      /*
       * Default index is harmless when sel_valid_c[o] is zero.
       */
      sel_idx_c[o] = owner_q[o];

      found = 1'b0;


      /*
       * --------------------------------------------------------------
       * A frame is already bound to this output.
       * --------------------------------------------------------------
       */
      if (owner_valid_q[o]) begin

        sel_idx_c[o] = owner_q[o];

        /*
         * Gaps between beats are allowed; nobody else may use this
         * output until the owner's frame finishes.
         */
        if (s_valid_i[owner_q[o]])
          sel_valid_c[o] = 1'b1;

      end


      /*
       * --------------------------------------------------------------
       * Between frames: round-robin selection.
       * --------------------------------------------------------------
       */
      else begin

        for (k = 0; k < S_COUNT; k = k + 1) begin

          idx = rr_q[o] + k;

          if (idx >= S_COUNT)
            idx = idx - S_COUNT;

          if (
              !found &&
              s_valid_i[idx] &&
              (s_dest_u[idx] == o)
          ) begin

            found = 1'b1;

            sel_valid_c[o] = 1'b1;
            sel_idx_c[o]   = idx;

          end

        end

      end


      /*
       * --------------------------------------------------------------
       * Cut-through datapath.
       * --------------------------------------------------------------
       *
       * m_valid does NOT depend on m_ready.
       *
       * s_ready may depend on m_ready; L5 explicitly permits that.
       */
      if (sel_valid_c[o]) begin

        m_valid_o[o] =
            rst_ni;

        m_data_o[
          o*DATA_W +: DATA_W
        ] =
            s_data_u[
              sel_idx_c[o]
            ];

        m_keep_o[
          o*KEEP_W +: KEEP_W
        ] =
            s_keep_u[
              sel_idx_c[o]
            ];

        m_last_o[o] =
            s_last_i[
              sel_idx_c[o]
            ];

        /*
         * Since one input has exactly one destination, an input can be
         * selected by at most one output.
         */
        s_ready_o[
          sel_idx_c[o]
        ] =
            rst_ni &&
            m_ready_i[o];

      end

    end

  end


  /*
   * --------------------------------------------------------------------------
   * Frame locks and fairness
   * --------------------------------------------------------------------------
   *
   * Round-robin state advances only when an entire frame completes.
   * Therefore arbitration is fair between frames without ever interleaving
   * their beats.
   */

  always_ff @(posedge clk_i or negedge rst_ni) begin : state_ff

    integer o;

    if (!rst_ni) begin

      owner_valid_q <= '0;

      for (o = 0; o < M_COUNT; o = o + 1) begin

        owner_q[o] <= '0;
        rr_q[o]    <= '0;

      end

    end
    else begin

      for (o = 0; o < M_COUNT; o = o + 1) begin


        /*
         * ============================================================
         * Existing frame owner
         * ============================================================
         */
        if (owner_valid_q[o]) begin

          /*
           * LAST beat accepted: frame is complete.
           */
          if (
              sel_valid_c[o] &&
              m_ready_i[o] &&
              s_last_i[owner_q[o]]
          ) begin

            owner_valid_q[o] <=
                1'b0;

            /*
             * Next arbitration begins after this owner.
             */
            if (owner_q[o] == (S_COUNT - 1))
              rr_q[o] <= '0;
            else
              rr_q[o] <=
                  owner_q[o] +
                  1'b1;

          end

        end


        /*
         * ============================================================
         * Output currently between frames
         * ============================================================
         */
        else if (sel_valid_c[o]) begin

          /*
           * If the first beat stalls, remember the selection immediately
           * so the output remains stable on the following cycle.
           */
          if (!m_ready_i[o]) begin

            owner_valid_q[o] <=
                1'b1;

            owner_q[o] <=
                sel_idx_c[o];

          end


          /*
           * First beat transferred.
           */
          else begin

            /*
             * Multi-beat frame: retain ownership.
             */
            if (!s_last_i[sel_idx_c[o]]) begin

              owner_valid_q[o] <=
                  1'b1;

              owner_q[o] <=
                  sel_idx_c[o];

            end


            /*
             * Single-beat frame: it completed immediately.
             */
            else begin

              if (sel_idx_c[o] == (S_COUNT - 1))
                rr_q[o] <= '0;
              else
                rr_q[o] <=
                    sel_idx_c[o] +
                    1'b1;

            end

          end

        end

      end

    end

  end

endmodule