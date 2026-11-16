module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32  // {8, 32}
) (
  input  logic                               clk_i,
  input  logic                               rst_ni,      // active low, synchronous deassert

  // ---- input streams, concatenated port-major ------------------------------
  input  logic [S_COUNT-1:0]                 s_valid_i,
  output logic [S_COUNT-1:0]                 s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]           s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]       s_keep_i,
  input  logic [S_COUNT-1:0]                 s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0]  s_dest_i,

  // ---- output streams, concatenated port-major -----------------------------
  output logic [M_COUNT-1:0]                  m_valid_o,
  input  logic [M_COUNT-1:0]                  m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]           m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]       m_keep_o,
  output logic [M_COUNT-1:0]                  m_last_o
);

  // ---------------------------------------------------------------------------
  // Architecture (every choice below sits inside the contract's freedom):
  //
  //  * OUTPUT-QUEUED. Each output owns its own queue of 2 frame slots (the B1
  //    ceiling: 2 frames = 16 beats per output). Filling one slot overlaps
  //    draining the other, so a backlogged input/output pair sustains one beat
  //    per cycle and disjoint pairs proceed fully in parallel (C1: with 4
  //    disjoint pairs the aggregate is ~4 beats/cycle, comfortably above the
  //    floor of 2). There is no shared datapath to serialise traffic.
  //
  //  * NO HEAD-OF-LINE BLOCKING ACROSS INPUTS. Inputs contend only for a slot
  //    on the output they name; an input whose output is blocked never touches
  //    another output's queue (C2).
  //
  //  * FRAME ATOMICITY. A slot is exclusively owned by the input filling it,
  //    and is drained start-to-finish by its output before the next slot's
  //    frame starts. Beats can never interleave (R4). Slots are handed out per
  //    output in circular order and drained in the same circular order, so two
  //    frames from one input to one output keep their order (R5).
  //
  //  * FAIR ARBITRATION. When several idle inputs contend for one output's free
  //    slot, a round-robin picker grants one per cycle (L1, and it cannot
  //    starve an input, satisfying C3).
  //
  //  * R1b. m_valid_o is a pure function of registered slot state; it never
  //    depends combinationally on m_ready_i. s_ready_o is combinational in
  //    s_valid_i, which L5 permits.
  // ---------------------------------------------------------------------------

  // derived by this contract, not parameters
  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned S_W    = $clog2(S_COUNT);
  localparam int unsigned WORD_W = DATA_W + KEEP_W + 1; // {last, keep, data}
  localparam int unsigned NBEAT  = 8;                   // R6: frame <= 8 beats
  localparam int unsigned NENT   = 2;                   // B1: <= 2 frames/output

  localparam logic [1:0] ST_EMPTY = 2'd0;
  localparam logic [1:0] ST_FILL  = 2'd1;
  localparam logic [1:0] ST_FULL  = 2'd2;

  // ---- per-output queue state -----------------------------------------------
  // mem[m][e][b] = {last, keep, data} of beat b of slot e of output m
  logic [M_COUNT-1:0][NENT-1:0][NBEAT-1:0][WORD_W-1:0] mem;
  logic [M_COUNT-1:0][NENT-1:0][1:0] estate;  // slot state
  logic [M_COUNT-1:0][NENT-1:0][3:0] fcnt;     // beats stored in slot (0..8)
  logic [M_COUNT-1:0][NENT-1:0][2:0] dcnt;    // next beat to drain  (0..7)
  logic [M_COUNT-1:0] rdp;    // drain pointer,      1 bit since NENT == 2
  logic [M_COUNT-1:0] wrp;    // allocation pointer, 1 bit since NENT == 2
  logic [M_COUNT-1:0][S_W-1:0] rrp;            // round-robin grant state

  // ---- per-input in-flight frame ---------------------------------------------
  logic [S_COUNT-1:0]              iact;  // input owns a filling slot
  logic [S_COUNT-1:0][DEST_W-1:0]  idst;  // destination of the frame in flight
  logic [S_COUNT-1:0]              ient;  // slot index owned (1 bit)

  // ---- combinational ---------------------------------------------------------
  logic [S_COUNT-1:0]              sready_c;
  logic [S_COUNT-1:0][DEST_W-1:0]  idest_c;  // dest of the beat on offer
  logic [S_COUNT-1:0]              aent;     // slot an idle input would take
  logic [M_COUNT-1:0][S_COUNT-1:0] cmask;    // idle contenders per output
  logic [M_COUNT-1:0][S_COUNT-1:0] grant_oh; // one-hot grant per output
  logic [M_COUNT-1:0][S_W-1:0]     gidx;     // granted input index

  // beat word of input si: {last, keep, data}
  function automatic logic [WORD_W-1:0] beat_of(input int unsigned si);
    beat_of = {s_last_i[si], s_keep_i[si*KEEP_W +: KEEP_W],
               s_data_i[si*DATA_W +: DATA_W]};
  endfunction

  // first set bit of mask at or after ptr, circularly in S_COUNT
  // (S_COUNT is a power of two, so S_W-bit addition wraps modulo S_COUNT)
  function automatic logic [S_W-1:0] rr_pick(input logic [S_COUNT-1:0] mask,
                                             input logic [S_W-1:0]       ptr);
    logic [S_W-1:0] cnd;
    logic [S_W-1:0] res;
    logic           fnd;
    fnd = 1'b0;
    res = '0;
    for (int unsigned k = 0; k < S_COUNT; k++) begin
      cnd = ptr + S_W'(k);
      if (!fnd && mask[cnd]) begin
        res = cnd;
        fnd = 1'b1;
      end
    end
    rr_pick = res;
  endfunction

  // ---- input side: destination, per-output round-robin grant, ready ----------
  always_comb begin
    for (int unsigned s = 0; s < S_COUNT; s++) begin
      idest_c[s] = s_dest_i[s*DEST_W +: DEST_W];
      aent[s]    = wrp[idest_c[s]];
    end
    for (int unsigned m = 0; m < M_COUNT; m++) begin
      cmask[m]    = '0;
      grant_oh[m] = '0;
      gidx[m]     = '0;
    end
    for (int unsigned s = 0; s < S_COUNT; s++) begin
      if (!iact[s] && s_valid_i[s]) begin
        cmask[idest_c[s]][s] = 1'b1;
      end
    end
    for (int unsigned m = 0; m < M_COUNT; m++) begin
      // a slot is allocatable only if the allocation slot of this output is
      // empty; at most one contender is granted per output per cycle
      if ((cmask[m] != '0) && (estate[m][wrp[m]] == ST_EMPTY)) begin
        gidx[m]              = rr_pick(cmask[m], rrp[m]);
        grant_oh[m][gidx[m]] = 1'b1;
      end
    end
    for (int unsigned s = 0; s < S_COUNT; s++) begin
      if (iact[s]) begin
        // mid-frame: the owned slot always has room (R6 bounds frames at 8)
        sready_c[s] = (fcnt[idst[s]][ient[s]] < 4'd8);
      end else begin
        sready_c[s] = grant_oh[idest_c[s]][s];
      end
    end
  end

  assign s_ready_o = sready_c;

  // ---- output side: pure function of registered state (R1b) -----------------
  always_comb begin
    for (int unsigned m = 0; m < M_COUNT; m++) begin
      m_valid_o[m] = (estate[m][rdp[m]] == ST_FULL);
      m_data_o[m*DATA_W +: DATA_W] =
          mem[m][rdp[m]][dcnt[m][rdp[m]]][DATA_W-1:0];
      m_keep_o[m*KEEP_W +: KEEP_W] =
          mem[m][rdp[m]][dcnt[m][rdp[m]]][DATA_W+KEEP_W-1:DATA_W];
      m_last_o[m] = mem[m][rdp[m]][dcnt[m][rdp[m]]][DATA_W+KEEP_W];
    end
  end

  // ---- sequential: drain and fill run concurrently on independent slots ------
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      estate <= '0;
      fcnt   <= '0;
      dcnt   <= '0;
      rdp    <= '0;
      wrp    <= '0;
      rrp    <= '0;
      iact   <= '0;
      idst   <= '0;
      ient   <= '0;
    end else begin
      // -------- drain: one beat per output per cycle, atomic per slot --------
      for (int unsigned m = 0; m < M_COUNT; m++) begin
        if ((estate[m][rdp[m]] == ST_FULL) && m_ready_i[m]) begin
          if (mem[m][rdp[m]][dcnt[m][rdp[m]]][DATA_W+KEEP_W]) begin
            // last beat of the frame accepted by the sink: free the slot
            estate[m][rdp[m]] <= ST_EMPTY;
            dcnt[m][rdp[m]]   <= '0;
            rdp[m]            <= rdp[m] ^ 1'b1;
          end else begin
            dcnt[m][rdp[m]]   <= dcnt[m][rdp[m]] + 3'd1;
          end
        end
      end
      // -------- fill: accept beats into (exclusively owned) slots -------------
      for (int unsigned s = 0; s < S_COUNT; s++) begin
        if (s_valid_i[s] && sready_c[s]) begin
          if (iact[s]) begin
            // continuation of the frame this input already owns
            mem[idst[s]][ient[s]][fcnt[idst[s]][ient[s]][2:0]] <= beat_of(s);
            if (s_last_i[s]) begin
              estate[idst[s]][ient[s]] <= ST_FULL;
              dcnt[idst[s]][ient[s]]   <= '0;
              fcnt[idst[s]][ient[s]]   <= '0;
              iact[s]                  <= 1'b0;
            end else begin
              fcnt[idst[s]][ient[s]]   <= fcnt[idst[s]][ient[s]] + 4'd1;
            end
          end else begin
            // first beat of a frame: allocate the output's next free slot
            mem[idest_c[s]][aent[s]][0] <= beat_of(s);
            if (s_last_i[s]) begin
              estate[idest_c[s]][aent[s]] <= ST_FULL;
              dcnt[idest_c[s]][aent[s]]   <= '0;
              fcnt[idest_c[s]][aent[s]]   <= '0;
            end else begin
              estate[idest_c[s]][aent[s]] <= ST_FILL;
              fcnt[idest_c[s]][aent[s]]   <= 4'd1;
              iact[s]                     <= 1'b1;
              idst[s]                     <= idest_c[s];
              ient[s]                     <= aent[s];
            end
            wrp[idest_c[s]] <= wrp[idest_c[s]] ^ 1'b1;
            rrp[idest_c[s]] <= S_W'((s + 1) % S_COUNT);
          end
        end
      end
    end
  end

endmodule
