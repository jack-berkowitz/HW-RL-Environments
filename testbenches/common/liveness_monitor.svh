// =============================================================================
// liveness_monitor.svh -- shared forward-progress monitor. NEVER SHIPPED.
// =============================================================================
// Built once, reused by every task whose correctness is a LIVENESS property
// rather than a data property: d_nw01 (axi4_xbar), d_ca01 (nonblocking_dcache),
// d_nw02 (vc_router_alloc), d_nw04 (tcdm_log_interconnect).
//
// WHY THIS EXISTS
// ---------------
// Deadlock and starvation are invisible to output comparison. A crossbar that
// wedges produces no wrong data -- it produces NO data, and a scoreboard that
// only checks what came out reports a clean pass on a dead design. Every
// checker built so far in this project would pass a DUT that stopped
// responding, because "nothing arrived" is indistinguishable from "nothing was
// due" unless something is tracking what is outstanding.
//
// WHAT IT CHECKS
// --------------
// Two distinct properties, deliberately separated because they fail for
// different reasons and want different diagnostics:
//
//   LM_STALL  -- no forward progress ANYWHERE. Offered load is present and
//                accepted somewhere, but the design has not retired anything
//                for STALL_LIMIT cycles. This is deadlock.
//
//   LM_STARVE -- forward progress exists, but one requester has been waiting
//                STARVE_LIMIT cycles while OTHERS have been served. This is
//                starvation, and it is the failure a round-robin bug produces:
//                the design is manifestly alive, just not to everyone.
//
// Starvation is only meaningful relative to progress elsewhere, which is why
// the per-requester counter is reset by ANY requester being served, not by that
// requester being served. A design that serves nobody trips LM_STALL instead.
//
// USAGE
// -----
//   `include "liveness_monitor.svh"
//   `LM_DECLARE(N_REQUESTERS)
//   ...
//   always_ff @(posedge clk) if (rst_n) begin
//     `LM_TICK(offered_mask, served_mask)     // one bit per requester
//   end
//   ...
//   `LM_CHECK(note_fail)                      // at end of test
//
// `offered_mask[i]` is 1 while requester i has a request outstanding and
// unserved. `served_mask[i]` pulses when requester i retires something.
//
// The limits are deliberately loose. This is not a performance check -- it must
// never fire on a slow-but-correct design, only on one that has genuinely
// stopped. Tightening them to measure quality would encode one implementation's
// arbitration into the contract, which is exactly what the second-source rule
// exists to prevent.
// =============================================================================

`ifndef LIVENESS_MONITOR_SVH
`define LIVENESS_MONITOR_SVH

`define LM_DECLARE(NREQ)                                                      \
  localparam int LM_N = (NREQ);                                               \
  /* cycles since ANY requester was served, while load was offered */         \
  int lm_global_idle = 0;                                                     \
  /* per-requester cycles waiting while somebody else made progress */        \
  int lm_wait [0:(NREQ)-1];                                                   \
  int lm_served_count [0:(NREQ)-1];                                           \
  int lm_worst_wait = 0;                                                      \
  int lm_worst_req  = -1;                                                     \
  bit lm_stall_fired  = 1'b0;                                                 \
  bit lm_starve_fired = 1'b0;                                                 \
  string lm_reason = "";                                                      \
  int lm_stall_limit  = 4000;                                                 \
  int lm_starve_limit = 8000;                                                 \
  initial begin                                                               \
    for (int i = 0; i < LM_N; i++) begin lm_wait[i] = 0; lm_served_count[i] = 0; end \
  end

// One clocked update. `off` and `srv` are LM_N-bit masks.
`define LM_TICK(off, srv)                                                     \
  begin                                                                       \
    bit lm_any_off, lm_any_srv;                                               \
    lm_any_off = ((off) != '0);                                               \
    lm_any_srv = ((srv) != '0);                                               \
    if (lm_any_srv) lm_global_idle = 0;                                       \
    else if (lm_any_off) lm_global_idle = lm_global_idle + 1;                 \
    if (lm_global_idle > lm_stall_limit && !lm_stall_fired) begin             \
      lm_stall_fired = 1'b1;                                                  \
      lm_reason = $sformatf(                                                  \
        "DEADLOCK: %0d cycles with load offered and nothing retired anywhere", \
        lm_global_idle);                                                      \
    end                                                                       \
    for (int i = 0; i < LM_N; i++) begin                                      \
      if ((srv)[i]) begin                                                     \
        lm_wait[i] = 0;                                                       \
        lm_served_count[i] = lm_served_count[i] + 1;                          \
      end else if ((off)[i] && lm_any_srv) begin                              \
        /* waiting WHILE someone else progressed -- the starvation condition */ \
        lm_wait[i] = lm_wait[i] + 1;                                          \
        if (lm_wait[i] > lm_worst_wait) begin                                 \
          lm_worst_wait = lm_wait[i];                                         \
          lm_worst_req  = i;                                                  \
        end                                                                   \
        if (lm_wait[i] > lm_starve_limit && !lm_starve_fired) begin           \
          lm_starve_fired = 1'b1;                                             \
          lm_reason = $sformatf(                                              \
            "STARVATION: requester %0d waited %0d cycles while others were served", \
            i, lm_wait[i]);                                                   \
        end                                                                   \
      end                                                                     \
    end                                                                       \
  end

// Report. FAILTASK is the harness's note_fail.
`define LM_CHECK(FAILTASK)                                                    \
  begin                                                                       \
    $display("METRIC: liveness worst_wait=%0d (requester %0d) global_idle_max_seen=%0d", \
             lm_worst_wait, lm_worst_req, lm_global_idle);                    \
    $write("// coverage: served_per_requester =");                            \
    for (int i = 0; i < LM_N; i++) $write(" %0d", lm_served_count[i]);        \
    $write("\n");                                                             \
    if (lm_stall_fired || lm_starve_fired) FAILTASK(lm_reason);               \
    for (int i = 0; i < LM_N; i++)                                            \
      if (lm_served_count[i] == 0)                                            \
        FAILTASK($sformatf("requester %0d was never served at all", i));      \
  end

`endif
