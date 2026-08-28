// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Authors:
// - Andreas Kurth <akurth@iis.ee.ethz.ch>
// - Wolfgang Roenninger <wroennin@iis.ee.ethz.ch>

/// Filter atomic operations (ATOPs) in a protocol-compliant manner.
///
/// This module filters atomic operations (ATOPs), i.e., write transactions that have a non-zero
/// `aw_atop` value, from its `slv` to its `mst` port. This module guarantees that:
///
/// 1) `aw_atop` is always zero on the `mst` port;
///
/// 2) write transactions with non-zero `aw_atop` on the `slv` port are handled in conformance with
///    the AXI standard by replying to such write transactions with the proper B and R responses.
///    The response code on atomic operations that reach this module is always SLVERR
///    (implementation-specific, not defined in the AXI standard).
///
/// ## Intended usage
/// This module is intended to be placed between masters that may issue ATOPs and slaves that do not
/// support ATOPs. That way, this module ensures that the AXI protocol remains in a defined state on
/// systems with mixed ATOP capabilities.
///
/// ## Specification reminder
/// The AXI standard specifies that there may be no ordering requirements between different atomic
/// bursts (i.e., a burst started by an AW with ATOP other than 0) and none between atomic bursts
/// and non-atomic bursts [E2.1.4]. That is, **an atomic burst may never have the same ID as any
/// other write or read burst that is in-flight at the same time**.
module axi_atop_filter_m12_stalls_aw_with_no_debt #(
  /// AXI ID width
  parameter int unsigned AxiIdWidth = 0,
  /// Maximum number of in-flight AXI write transactions
  parameter int unsigned AxiMaxWriteTxns = 0,
  /// AXI request type
  parameter type axi_req_t  = logic,
  /// AXI response type
  parameter type axi_resp_t = logic
) (
  /// Rising-edge clock of both ports
  input  logic      clk_i,
  /// Asynchronous reset, active low
  input  logic      rst_ni,
  /// Slave port request
  input  axi_req_t  slv_req_i,
  /// Slave port response
  output axi_resp_t slv_resp_o,
  /// Master port request
  output axi_req_t  mst_req_o,
  /// Master port response
  input  axi_resp_t mst_resp_i
);

  // Minimum counter width is 2 to detect underflows.
  localparam int unsigned COUNTER_WIDTH = (AxiMaxWriteTxns == 1) ? 2 : $clog2(AxiMaxWriteTxns+1);
  typedef struct packed {
    logic                     underflow;
    logic [COUNTER_WIDTH-1:0] cnt;
  } cnt_t;
  cnt_t   w_cnt_d, w_cnt_q;

  typedef enum logic [2:0] {
    W_RESET, W_FEEDTHROUGH, BLOCK_AW, ABSORB_W, HOLD_B, INJECT_B, WAIT_R
  } w_state_e;
  w_state_e   w_state_d, w_state_q;

  typedef enum logic [1:0] { R_RESET, R_FEEDTHROUGH, INJECT_R, R_HOLD } r_state_e;
  r_state_e   r_state_d, r_state_q;

  typedef logic [AxiIdWidth-1:0] id_t;
  id_t  id_d, id_q;
  // ---- MUTANT bookkeeping: all of this counts things the CONTRACT names ----
  logic [7:0] atomic_seen_q;     // how many filtered writes so far
  logic [7:0] since_atomic_q;    // cycles since the last filtered write began
  logic [7:0] full_aged_q;       // cycles the write debt has sat at its bound
  wire        aw_is_atomic = slv_req_i.aw_valid
                             && (slv_req_i.aw.atop[5:4] != axi_pkg::ATOP_NONE)
                             && slv_resp_o.aw_ready;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      atomic_seen_q <= '0; since_atomic_q <= '0; full_aged_q <= '0;
    end else begin
      if (aw_is_atomic) begin
        atomic_seen_q  <= atomic_seen_q + 8'd1;
        since_atomic_q <= '0;
      end else if (since_atomic_q != 8'hFF) since_atomic_q <= since_atomic_q + 8'd1;
      full_aged_q <= (w_cnt_q.cnt == AxiMaxWriteTxns) ? (full_aged_q + 8'd1) : 8'd0;
    end
  end



  typedef logic [7:0] len_t;
  len_t   r_beats_d,  r_beats_q;

  typedef struct packed {
    len_t len;
  } r_resp_cmd_t;
  r_resp_cmd_t  r_resp_cmd_push, r_resp_cmd_pop;

  logic aw_without_complete_w_downstream,
        complete_w_without_aw_downstream,
        r_resp_cmd_push_valid,  r_resp_cmd_push_ready,
        r_resp_cmd_pop_valid,   r_resp_cmd_pop_ready;

  // An AW without a complete W burst is in-flight downstream if the W counter is > 0 and not
  // underflowed.
  assign aw_without_complete_w_downstream = !w_cnt_q.underflow && (w_cnt_q.cnt > 0);
  localparam int unsigned MUT_ORDINAL = 1;

  // ---- MUTANT bookkeeping: all of this counts things the CONTRACT names -------
  // W3 says: while the debt is STRICTLY BELOW AxiMaxWriteTxns, this bound alone
  // does not stall a non-atomic AW. This mutant stalls one anyway, guarded --
  // and it stalls it at the FURTHEST POINT FROM THE BOUND THERE IS.
  //
  // WHY THIS EXISTS WHEN af_m11 ALREADY VIOLATES W3. It does, but only at ONE of
  // W3's two reporting sites. Measured: af_m11 drives W3 from gov_admitted and
  // NEVER from gov_aw_timeout, which reports X4 instead. The reason is
  // arithmetic. AxiMaxWriteTxns is 4 and af_m11 fires from the FIFTH non-atomic
  // AW offered while the debt is below the bound -- by which point four writes
  // are outstanding, so the debt is AT the bound when the AW finally times out,
  // and gov_aw_timeout's `(debt_now < bound_) ? "W3" : "X4"` takes the other
  // branch. The stall was below the bound; the TIMEOUT was at it.
  //
  // So this guard requires the debt to be EMPTY, not merely below the bound of
  // four. RELAXING IT TO `<= 1` WAS TRIED AND LOST THE BRANCH: measured, the
  // stall then begins at a different point in the stimulus, the AW is eventually
  // accepted, and gov_aw_timeout is never reached at all (W3@aw_timeout 1 -> 0)
  // while gov_admitted still fires. The exact debt the guard admits is not a
  // tuning knob here -- it selects WHICH of W3's two sites reports. Stalling then keeps it empty -- no
  // AW is admitted, so nothing can become outstanding -- and the condition
  // sustains itself through the reference's 4000-cycle try_aw window. The debt
  // is 0 when the timeout fires, which is unambiguously `debt_now < bound_`.
  //
  // The guard counts the CLASS OCCURRING, never the defect's own effect. af_m11's
  // first counter counted acceptances, and stalling drives aw_ready low, so once
  // the guard fired the counter could never advance again -- it read 0 at the end
  // of a run in which the stall had been applied 184 times.
  wire mut_class = slv_req_i.aw_valid
                   && (slv_req_i.aw.atop[5:4] == axi_pkg::ATOP_NONE)
                   && !w_cnt_q.underflow
                   && (w_cnt_q.cnt == '0);

  // COUNT PRESENTATIONS, NOT CYCLES. `mut_class` is a CYCLE predicate: aw_valid
  // is held until the AW is accepted, so an ordinal over cycles counts how long
  // one AW waited, not how many arrived. Measured on the first version: 8
  // class-CYCLES in a clean run, and 4304 once the stall held aw_valid high --
  // and ordinals of 1, 2 and 3 produced byte-identical runs, because all three
  // are reached inside the first presentation. That is an UNGUARDED defect
  // wearing an ordinal, and this set exists to avoid exactly that.
  //
  // The rising edge counts each presentation once, however long it is held. It
  // is also not self-suppressing, which is the other trap here: af_m11's first
  // counter counted ACCEPTANCES, and stalling drives aw_ready low, so the guard
  // silenced its own trigger and read 0 after firing 184 times. Stalling holds
  // `mut_class` HIGH, so the edge is taken once and the count simply stops --
  // wrong in the safe direction, and visible in the FIRED counters below.
  logic mut_class_q = 1'b0;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) mut_class_q <= 1'b0; else mut_class_q <= mut_class;
  wire mut_pres = mut_class && !mut_class_q;
  int unsigned mut_hit_q = 0;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)       mut_hit_q <= 0;
    else if (mut_pres) mut_hit_q <= mut_hit_q + 1;
  end
  // THE ORDINAL IS ONE, AND ONE IS THE ONLY VALUE THAT WORKS. Swept, with the
  // reference testbench, reading the two W3 sites apart by their message text:
  //
  //   ordinal   result            ids                 W3@aw_timeout  W3@admitted
  //   (none)    PASS              --                       0              0     <- supply probe
  //   0         FAIL 16           P2 W3 W4 X4              1              1
  //   1         FAIL 17           P2 W3 W4 X3 X4           1              1     <- chosen
  //   2         FAIL 11           P2 W3 W4 X3 X4           0              1
  //   3         PASS              --                       0              0
  //
  // CLEAN-RUN SUPPLY IS TWO PRESENTATIONS. That is the whole constraint. Ordinal
  // 0 is unguarded -- it fires on the first AW of its class, which measures
  // whether a testbench exercised the class rather than whether it checks. Ordinal
  // 2 still fires (the stall itself manufactures more presentations, 8 of them)
  // but LOSES gov_aw_timeout, the branch this mutant exists for. Ordinal 3 is out
  // of reach entirely. One is the only value that is guarded at all AND reaches
  // the target site.
  //
  // THIS IS SHALLOWER THAN THE REST OF THE SET, which runs 4th to 10th, and the
  // reason is supply rather than choice: the reference offers exactly two
  // non-atomic AWs with an empty debt. This set's README says the fix for a guard
  // out of reach is to EXTEND THE REFERENCE and that dialling the guard back is
  // the fallback -- and that is the right order. It is not taken here because
  // extending the reference changes the supply for the other eleven mutants,
  // whose ordinals were calibrated against the current stimulus, and trading a
  // recalibration of eleven working guards for depth on one is not a judgement to
  // make unasked. Recorded as a known shallow guard, not as a calibrated one.
  //
  // Rule 16, the other side of the bound: nonequiv_tb distinguishes this mutant
  // from the golden at cycle 139 on s_awready, so it is licensable.
  wire mut_stall_aw = mut_class && (mut_hit_q >= MUT_ORDINAL);

  // DID THE GUARD EVER FIRE? A mutant that produces no difference is either a
  // wrong defect or a guard the stimulus never reaches, and the verdict cannot
  // tell them apart. These counters can, and on af_m11's first guard they did.
  // n_pres has NO reset clause on purpose. mut_hit_q does, and the reference
  // pulses reset once, late -- so mut_hit_q reads 0 at $finish however many
  // times it counted. That cost a wrong supply reading on v_dsp02 before it was
  // understood, and it is the number this measurement depends on.
  int unsigned n_class = 0, n_fire = 0, n_pres = 0;
  always_ff @(posedge clk_i) if (rst_ni) begin
    if (mut_class)    n_class <= n_class + 1;
    if (mut_pres)     n_pres  <= n_pres  + 1;
    if (mut_stall_aw) n_fire  <= n_fire  + 1;
  end
  final $display("FIRED nc_m12.presentations %0d", n_pres);
  final $display("FIRED nc_m12.class_seen %0d", n_class);
  final $display("FIRED nc_m12.class_accepted %0d", mut_hit_q);
  final $display("FIRED nc_m12.stall_applied %0d", n_fire);

  // A complete W burst without AW is in-flight downstream if the W counter is -1.
  assign complete_w_without_aw_downstream = w_cnt_q.underflow && &(w_cnt_q.cnt);

  // Manage AW, W, and B channels.
  always_comb begin
    // Defaults:
    // Disable AW and W handshakes.
    mst_req_o.aw_valid  = 1'b0;
    slv_resp_o.aw_ready = 1'b0;
    mst_req_o.w_valid   = 1'b0;
    slv_resp_o.w_ready  = 1'b0;
    // Feed write responses through.
    mst_req_o.b_ready   = slv_req_i.b_ready;
    slv_resp_o.b_valid  = mst_resp_i.b_valid;
    slv_resp_o.b        = mst_resp_i.b;
    // Keep ID stored for B and R response.
    id_d = id_q;
    // Do not push R response commands.
    r_resp_cmd_push_valid = 1'b0;
    // Keep the current state.
    w_state_d = w_state_q;

    unique case (w_state_q)
      W_RESET: w_state_d = W_FEEDTHROUGH;

      W_FEEDTHROUGH: begin
        // Feed AW channel through if the maximum number of outstanding bursts is not reached.
        // MUTANT: `&& !mut_stall_aw` is the whole defect. The debt is EMPTY,
        // so W3 says this bound alone must not stall the AW -- and it does.
        if ((complete_w_without_aw_downstream || (w_cnt_q.cnt < AxiMaxWriteTxns))
            && !mut_stall_aw) begin

          mst_req_o.aw_valid  = slv_req_i.aw_valid;
          slv_resp_o.aw_ready = mst_resp_i.aw_ready;
        end
        // Feed W channel through if ..
        if (aw_without_complete_w_downstream // .. downstream is missing W bursts ..
            // .. or a new non-ATOP AW is being applied and there is not already a complete W burst
            // downstream (to prevent underflows of w_cnt).
            || ((slv_req_i.aw_valid && slv_req_i.aw.atop[5:4] == axi_pkg::ATOP_NONE)
                && !complete_w_without_aw_downstream)
        ) begin
          mst_req_o.w_valid  = slv_req_i.w_valid;
          slv_resp_o.w_ready = mst_resp_i.w_ready;
        end
        // Filter out AWs that are atomic operations.
        if (slv_req_i.aw_valid && slv_req_i.aw.atop[5:4] != axi_pkg::ATOP_NONE) begin
          mst_req_o.aw_valid  = 1'b0; // Do not let AW pass to master port.
          slv_resp_o.aw_ready = 1'b1; // Absorb AW on slave port.
          id_d = slv_req_i.aw.id; // Store ID for B response.
          // Some atomic operations require a response on the R channel.
          if (slv_req_i.aw.atop[axi_pkg::ATOP_R_RESP]) begin
            // Push R response command.  We do not have to wait for the ready of the register
            // because we know it is ready: we are its only master and will wait for the register to
            // be emptied before going back to the `W_FEEDTHROUGH` state.
            r_resp_cmd_push_valid = 1'b1;
          end
          // If downstream is missing W beats, block the AW channel and let the W bursts complete.
          if (aw_without_complete_w_downstream) begin
            w_state_d = BLOCK_AW;
          // If downstream is not missing W beats, absorb the W beats for this atomic AW.
          end else begin
            mst_req_o.w_valid  = 1'b0; // Do not let W beats pass to master port.
            slv_resp_o.w_ready = 1'b1; // Absorb W beats on slave port.
            if (slv_req_i.w_valid && slv_req_i.w.last) begin
              // If the W beat is valid and the last, proceed by injecting the B response.
              // However, if there is a non-handshaked B on our response port, we must let that
              // complete first.
              if (slv_resp_o.b_valid && !slv_req_i.b_ready) begin
                w_state_d = HOLD_B;
              end else begin
                w_state_d = INJECT_B;
              end
            end else begin
              // Otherwise continue with absorbing W beats.
              w_state_d = ABSORB_W;
            end
          end
        end
      end

      BLOCK_AW: begin
        // Feed W channel through to let outstanding bursts complete.
        if (aw_without_complete_w_downstream) begin
          mst_req_o.w_valid  = slv_req_i.w_valid;
          slv_resp_o.w_ready = mst_resp_i.w_ready;
        end else begin
          // If there are no more outstanding W bursts, start absorbing the next W burst.
          slv_resp_o.w_ready = 1'b1;
          if (slv_req_i.w_valid && slv_req_i.w.last) begin
            // If the W beat is valid and the last, proceed by injecting the B response.
            if (slv_resp_o.b_valid && !slv_req_i.b_ready) begin
              w_state_d = HOLD_B;
            end else begin
              w_state_d = INJECT_B;
            end
          end else begin
            // Otherwise continue with absorbing W beats.
            w_state_d = ABSORB_W;
          end
        end
      end

      ABSORB_W: begin
        // Absorb all W beats of the current burst.
        slv_resp_o.w_ready = 1'b1;
        if (slv_req_i.w_valid && slv_req_i.w.last) begin
          if (slv_resp_o.b_valid && !slv_req_i.b_ready) begin
            w_state_d = HOLD_B;
          end else begin
            w_state_d = INJECT_B;
          end
        end
      end

      HOLD_B: begin
        // Proceed with injection of B response upon handshake.
        if (slv_resp_o.b_valid && slv_req_i.b_ready) begin
          w_state_d = INJECT_B;
        end
      end

      INJECT_B: begin
        // Pause forwarding of B response.
        mst_req_o.b_ready = 1'b0;
        // Inject error response instead.  Since the B channel has an ID and the atomic burst we are
        // replying to is guaranteed to be the only burst with this ID in flight, we do not have to
        // observe any ordering and can immediately inject on the B channel.
        slv_resp_o.b = '0;
        slv_resp_o.b.id = id_q;
        slv_resp_o.b.resp = axi_pkg::RESP_SLVERR;
        slv_resp_o.b_valid = 1'b1;
        if (slv_req_i.b_ready) begin
          // If not all beats of the R response have been injected, wait for them. Otherwise, return
          // to `W_FEEDTHROUGH`.
          if (r_resp_cmd_pop_valid && !r_resp_cmd_pop_ready) begin
            w_state_d = WAIT_R;
          end else begin
            w_state_d = W_FEEDTHROUGH;
          end
        end
      end

      WAIT_R: begin
        // Wait with returning to `W_FEEDTHROUGH` until all beats of the R response have been
        // injected.
        if (!r_resp_cmd_pop_valid) begin
          w_state_d = W_FEEDTHROUGH;
        end
      end

      default: w_state_d = W_RESET;
    endcase
  end
  // Connect signals on AW and W channel that are not managed by the control FSM from slave port to
  // master port.
  // Feed-through of the AW and W vectors, make sure that downstream aw.atop is always zero
  always_comb begin
    // overwrite the atop signal
    mst_req_o.aw      = slv_req_i.aw;
    mst_req_o.aw.atop = '0;
  end
  assign mst_req_o.w = slv_req_i.w;

  // Manage R channel.
  always_comb begin
    // Defaults:
    // Feed read responses through.
    slv_resp_o.r       = mst_resp_i.r;
    slv_resp_o.r_valid = mst_resp_i.r_valid;
    mst_req_o.r_ready  = slv_req_i.r_ready;
    // Do not pop R response command.
    r_resp_cmd_pop_ready = 1'b0;
    // Keep the current value of the beats counter.
    r_beats_d = r_beats_q;
    // Keep the current state.
    r_state_d = r_state_q;

    unique case (r_state_q)
      R_RESET: r_state_d = R_FEEDTHROUGH;

      R_FEEDTHROUGH: begin
        if (mst_resp_i.r_valid && !slv_req_i.r_ready) begin
          r_state_d = R_HOLD;
        end else if (r_resp_cmd_pop_valid) begin
          // Upon a command to inject an R response, immediately proceed with doing so because there
          // are no ordering requirements with other bursts that may be ongoing on the R channel at
          // this moment.
          r_beats_d = r_resp_cmd_pop.len;
          r_state_d = INJECT_R;
        end
      end

      INJECT_R: begin
        mst_req_o.r_ready  = 1'b0;
        slv_resp_o.r       = '0;
        slv_resp_o.r.id    = id_q;
        slv_resp_o.r.resp  = axi_pkg::RESP_SLVERR;
        slv_resp_o.r.last  = (r_beats_q == '0);
        slv_resp_o.r_valid = 1'b1;
        if (slv_req_i.r_ready) begin
          if (slv_resp_o.r.last) begin
            r_resp_cmd_pop_ready = 1'b1;
            r_state_d = R_FEEDTHROUGH;
          end else begin
            r_beats_d -= 1;
          end
        end
      end

      R_HOLD: begin
        if (mst_resp_i.r_valid && slv_req_i.r_ready) begin
          r_state_d = R_FEEDTHROUGH;
        end
      end

      default: r_state_d = R_RESET;
    endcase
  end
  // Feed all signals on AR through.
  assign mst_req_o.ar        = slv_req_i.ar;
  assign mst_req_o.ar_valid  = slv_req_i.ar_valid;
  assign slv_resp_o.ar_ready = mst_resp_i.ar_ready;

  // Keep track of outstanding downstream write bursts and responses.
  always_comb begin
    w_cnt_d = w_cnt_q;
    if (mst_req_o.aw_valid && mst_resp_i.aw_ready) begin
      w_cnt_d.cnt += 1;
    end
    if (mst_req_o.w_valid && mst_resp_i.w_ready && mst_req_o.w.last) begin
      w_cnt_d.cnt -= 1;
    end
    if (w_cnt_q.underflow && (w_cnt_d.cnt == '0)) begin
      w_cnt_d.underflow = 1'b0;
    end else if (w_cnt_q.cnt == '0 && &(w_cnt_d.cnt)) begin
      w_cnt_d.underflow = 1'b1;
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      id_q <= '0;
      r_beats_q <= '0;
      r_state_q <= R_RESET;
      w_cnt_q <= '{default: '0};
      w_state_q <= W_RESET;
    end else begin
      id_q <= id_d;
      r_beats_q <= r_beats_d;
      r_state_q <= r_state_d;
      w_cnt_q <= w_cnt_d;
      w_state_q <= w_state_d;
    end
  end

  stream_register #(
    .T(r_resp_cmd_t)
  ) r_resp_cmd (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (1'b0),
    .testmode_i (1'b0),
    .valid_i    (r_resp_cmd_push_valid),
    .ready_o    (r_resp_cmd_push_ready),
    .data_i     (r_resp_cmd_push),
    .valid_o    (r_resp_cmd_pop_valid),
    .ready_i    (r_resp_cmd_pop_ready),
    .data_o     (r_resp_cmd_pop)
  );
  assign r_resp_cmd_push.len = slv_req_i.aw.len;

// pragma translate_off
`ifndef VERILATOR
  initial begin: p_assertions
    assert (AxiIdWidth >= 1) else $fatal(1, "AXI ID width must be at least 1!");
    assert (AxiMaxWriteTxns >= 1)
      else $fatal(1, "Maximum number of outstanding write transactions must be at least 1!");
  end
`endif
// pragma translate_on
endmodule
