// =============================================================================
// axis_switch_oq.sv -- S_COUNT x M_COUNT output-queued stream switch
// -----------------------------------------------------------------------------
// Structure: ONE QUEUE PER OUTPUT, with the arbitration on the WRITE side of
// each queue and independent per output.
//
//   input s ---\                    +-----------+
//   input s'----> arb(out 0) -----> | queue  0  | ---> output 0
//              /                    +-----------+
//   input s ---\                    +-----------+
//   input s'----> arb(out 1) -----> | queue  1  | ---> output 1
//                                   +-----------+
//
// Why this shape rather than the two obvious alternatives:
//
//  * A single shared datapath with one arbiter is correct on every frame and
//    delivers one beat per cycle whatever the port counts say. C1 is an
//    absolute rate, so that design cannot clear it at 4x4 -- there are
//    M_COUNT independent write ports and M_COUNT independent read ports here,
//    so disjoint pairs cost each other nothing and the rate is M_COUNT.
//
//  * A full S_COUNT x M_COUNT mesh of per-pair queues also works, but costs
//    S_COUNT times the storage for no behaviour this contract can observe.
//    One queue per output is enough because the thing that would otherwise
//    make a shared queue block -- a frame at its head bound for a stalled
//    output -- cannot arise when the queue serves exactly one output.
//
// Frame atomicity (R4) is enforced where frames ENTER the queue, not where
// they leave it: an input that wins an output's write port holds it until it
// writes `last`. The queue therefore only ever contains whole frames back to
// back, and the read side needs no frame tracking at all -- it just drains.
// That also gives R5 for free, since one queue is one order.
//
// No head-of-line blocking (C2): an input whose output is backpressured fills
// only that output's queue and then stalls itself. It holds no resource any
// other input needs, so a different input reaches a free output unimpeded.
//
// Forward progress (C3): each output's write port arbitrates round-robin, with
// the pointer advanced past the winner when its frame completes. An input can
// therefore be delayed by at most the other inputs' current frames, which R6
// bounds at 8 beats each.
// =============================================================================

module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,      // active low, synchronous deassert

  // ---- input streams, concatenated port-major ------------------------------
  input  logic [S_COUNT-1:0]                s_valid_i,
  output logic [S_COUNT-1:0]                s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]         s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]     s_keep_i,
  input  logic [S_COUNT-1:0]                s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  // ---- output streams, concatenated port-major -----------------------------
  output logic [M_COUNT-1:0]                m_valid_o,
  input  logic [M_COUNT-1:0]                m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]         m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]     m_keep_o,
  output logic [M_COUNT-1:0]                m_last_o
);

  // Derived by this contract, not parameters.
  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);

  // Depth 4 holds a partial frame without stalling a full-rate producer while
  // the reader drains at one beat per cycle; R6's 8-beat bound is not a storage
  // requirement here because this is not a store-and-forward design.
  localparam int unsigned QD    = 4;
  localparam int unsigned PW    = $clog2(QD);
  localparam int unsigned CW    = $clog2(QD + 1);
  localparam int unsigned EW    = DATA_W + KEEP_W + 1;   // {last, keep, data}
  localparam int unsigned SIW   = (S_COUNT <= 2) ? 1 : $clog2(S_COUNT);

  // ---------------------------------------------------------------------------
  // Rotating-priority pick. `p` has the highest priority and priority wraps
  // upward from it; returns `p` when nothing requests, which is harmless since
  // the caller also tests the winner's request bit.
  // ---------------------------------------------------------------------------
  function automatic int unsigned rr_pick(input logic [3:0]  req,
                                          input int unsigned n,
                                          input int unsigned p);
    int unsigned i, j;
    logic        found;
    rr_pick = p;
    found   = 1'b0;
    for (i = 0; i < 4; i = i + 1) begin
      if (i < n) begin
        j = p + i;
        if (j >= n) j = j - n;
        if (req[j] && !found) begin
          rr_pick = j;
          found   = 1'b1;
        end
      end
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Unpack the port-major input vectors
  // ---------------------------------------------------------------------------
  logic [DATA_W-1:0] sdata [S_COUNT];
  logic [KEEP_W-1:0] skeep [S_COUNT];
  logic [DEST_W-1:0] sdest [S_COUNT];

  // ---------------------------------------------------------------------------
  // Per-output queue and write-port arbitration state
  // ---------------------------------------------------------------------------
  logic [EW-1:0]  qmem  [M_COUNT][QD];
  logic [PW-1:0]  qrp   [M_COUNT];
  logic [PW-1:0]  qwp   [M_COUNT];
  logic [CW-1:0]  qcnt  [M_COUNT];

  logic           lockd [M_COUNT];      // a frame is part-written into this queue
  logic [SIW-1:0] lsrc  [M_COUNT];      // and this input owns the write port
  logic [SIW-1:0] rptr  [M_COUNT];      // round-robin pointer

  int unsigned    osel  [M_COUNT];      // input currently owning the write port
  logic           ofull [M_COUNT];
  logic           opush [M_COUNT];
  logic           opop  [M_COUNT];
  logic [EW-1:0]  owdat [M_COUNT];
  logic           olast [M_COUNT];      // `last` of the beat being written

  genvar gs, gm;

  generate
    for (gs = 0; gs < S_COUNT; gs = gs + 1) begin : g_unpack
      assign sdata[gs] = s_data_i[gs*DATA_W +: DATA_W];
      assign skeep[gs] = s_keep_i[gs*KEEP_W +: KEEP_W];
      assign sdest[gs] = s_dest_i[gs*DEST_W +: DEST_W];
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // Per-output write port: select an input, then push its beat
  // ---------------------------------------------------------------------------
  generate
    for (gm = 0; gm < M_COUNT; gm = gm + 1) begin : g_out
      localparam int unsigned GM = gm;

      // ---- arbitrate ------------------------------------------------------
      always_comb begin
        logic [3:0]  req;
        int unsigned s;
        req = 4'b0000;
        for (s = 0; s < S_COUNT; s = s + 1)
          if (s_valid_i[s] && (32'(sdest[s]) == GM)) req[s] = 1'b1;

        // A part-written frame keeps the port; `dest` is stable for a frame
        // (R2), so the locked owner can only ever be requesting this output.
        osel[gm] = lockd[gm] ? 32'(lsrc[gm]) : rr_pick(req, S_COUNT, 32'(rptr[gm]));

        owdat[gm] = '0;
        olast[gm] = 1'b0;
        for (s = 0; s < S_COUNT; s = s + 1) if (osel[gm] == s) begin
          owdat[gm] = {s_last_i[s], skeep[s], sdata[s]};
          olast[gm] = s_last_i[s];
        end

        ofull[gm] = (qcnt[gm] == QD[CW-1:0]);
        opush[gm] = req[osel[gm]] && !ofull[gm];
        opop [gm] = m_valid_o[gm] && m_ready_i[gm];
      end

      // ---- queue ----------------------------------------------------------
      always_ff @(posedge clk_i) begin
        int unsigned onext;
        onext = (osel[gm] + 1 >= S_COUNT) ? 0 : (osel[gm] + 1);
        if (!rst_ni) begin
          qrp[gm]   <= '0;
          qwp[gm]   <= '0;
          qcnt[gm]  <= '0;
          lockd[gm] <= 1'b0;
          lsrc[gm]  <= '0;
          rptr[gm]  <= '0;
        end else begin
          if (opush[gm]) begin
            qmem[gm][qwp[gm]] <= owdat[gm];
            qwp[gm] <= (32'(qwp[gm]) == QD-1) ? '0 : (qwp[gm] + 1'b1);
            // hold the port for the rest of the frame; release it on `last`
            // and step the pointer past the winner so it cannot re-win
            // immediately while another input is waiting (C3).
            if (olast[gm]) begin
              lockd[gm] <= 1'b0;
              rptr[gm]  <= onext[SIW-1:0];
            end else begin
              lockd[gm] <= 1'b1;
              lsrc[gm]  <= osel[gm][SIW-1:0];
            end
          end
          if (opop[gm])
            qrp[gm] <= (32'(qrp[gm]) == QD-1) ? '0 : (qrp[gm] + 1'b1);

          case ({opush[gm], opop[gm]})
            2'b10:   qcnt[gm] <= qcnt[gm] + 1'b1;
            2'b01:   qcnt[gm] <= qcnt[gm] - 1'b1;
            default: ;
          endcase
        end
      end

      // ---- read side: the queue holds whole frames, so just drain ---------
      assign m_valid_o[gm]                = (qcnt[gm] != '0);
      assign m_data_o[gm*DATA_W +: DATA_W] = qmem[gm][qrp[gm]][DATA_W-1:0];
      assign m_keep_o[gm*KEEP_W +: KEEP_W] = qmem[gm][qrp[gm]][DATA_W +: KEEP_W];
      assign m_last_o[gm]                  = qmem[gm][qrp[gm]][EW-1];
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // An input is ready exactly when it owns its destination's write port and
  // that queue has room. Only its own destination is consulted, so a stalled
  // output cannot reach across and hold up an unrelated input (C2).
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned s, d;
    for (s = 0; s < S_COUNT; s = s + 1) begin
      d = 32'(sdest[s]);
      s_ready_o[s] = (osel[d] == s) && !ofull[d];
    end
  end

endmodule