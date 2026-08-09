// =============================================================================
// arbiter.sv -- single-cycle arbiter with three selectable policies.
// Implements the interface and semantics of interfaces/arbiter_iface.sv exactly.
// =============================================================================
//
// Structure: the grant is a purely combinational scan over `req` plus the
// priority state; the state advances on a rising edge whenever grant_valid is
// asserted (a granted request is taken in the same cycle, there is no ack).
//
// The three policies share one always_comb; VARIANT is a parameter, so exactly
// one branch survives elaboration.
//   0 FIXED  : stateless, lowest set index wins.
//   1 RR     : scan from rr_ptr upward, wrapping. NUM_REQ is a power of two, so
//              the wrap is just IDX_W-bit truncation.
//   2 MATRIX : W[i][j] == "i outranks j"; the unique requester that outranks
//              every other requester wins. W is stored flattened as a single
//              NUM_REQ*NUM_REQ vector (W[i*NUM_REQ+j]) for portability.
// =============================================================================

module arbiter #(
    parameter int NUM_REQ = 4,   // 2 / 4 / 8 / 16
    parameter int VARIANT = 1,   // 0=fixed, 1=round-robin, 2=matrix
    // derived -- do not override
    parameter int IDX_W   = $clog2(NUM_REQ)
) (
    input  logic               clk,
    input  logic               rst_n,

    input  logic [NUM_REQ-1:0] req,

    output logic [NUM_REQ-1:0] grant,        // one-hot, subset of req
    output logic               grant_valid,  // |req
    output logic [IDX_W-1:0]   grant_idx     // index of the set bit of grant
);

    // ---------------------------------------------------------------------
    // priority state
    // ---------------------------------------------------------------------
    logic [IDX_W-1:0]         rr_ptr;                 // variant 1
    logic [NUM_REQ*NUM_REQ-1:0] w_mat;                // variant 2, W[i][j]

    // ---------------------------------------------------------------------
    // combinational grant
    // ---------------------------------------------------------------------
    assign grant_valid = |req;

    always_comb begin
        logic [IDX_W-1:0] i;
        logic             wins;

        grant     = '0;
        grant_idx = '0;

        if (VARIANT == 0) begin
            // lowest set index wins: scan downward so index 0 assigns last
            for (int k = NUM_REQ-1; k >= 0; k--)
                if (req[k]) begin
                    grant     = (NUM_REQ'(1) << k);
                    grant_idx = IDX_W'(k);
                end
        end else if (VARIANT == 1) begin
            // scan rr_ptr, rr_ptr+1, ...; scan downward so k==0 (rr_ptr itself,
            // the highest priority slot) assigns last and therefore wins
            for (int k = NUM_REQ-1; k >= 0; k--) begin
                i = rr_ptr + IDX_W'(k);   // wraps mod NUM_REQ (power of two)
                if (req[i]) begin
                    grant     = (NUM_REQ'(1) << i);
                    grant_idx = i;
                end
            end
        end else begin
            // the unique requester that outranks every other requester
            for (int k = 0; k < NUM_REQ; k++) begin
                wins = req[k];
                for (int j = 0; j < NUM_REQ; j++)
                    if (j != k && req[j] && !w_mat[k*NUM_REQ + j])
                        wins = 1'b0;
                if (wins) begin
                    grant     = (NUM_REQ'(1) << k);
                    grant_idx = IDX_W'(k);
                end
            end
        end
    end

    // ---------------------------------------------------------------------
    // state update -- synchronous active-low reset; holds when grant_valid==0
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rr_ptr <= '0;
            for (int i = 0; i < NUM_REQ; i++)
                for (int j = 0; j < NUM_REQ; j++)
                    w_mat[i*NUM_REQ + j] <= (i < j);
        end else if (grant_valid) begin
            // round robin: next scan starts just past the granted index
            rr_ptr <= grant_idx + IDX_W'(1);

            // matrix: the granted index becomes lowest priority
            for (int i = 0; i < NUM_REQ; i++)
                for (int j = 0; j < NUM_REQ; j++)
                    if (i != j) begin
                        if (grant[i])      w_mat[i*NUM_REQ + j] <= 1'b0;
                        else if (grant[j]) w_mat[i*NUM_REQ + j] <= 1'b1;
                    end
        end
    end

endmodule
