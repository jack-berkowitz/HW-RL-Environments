// =============================================================================
// d_ai04 -- sdp_requant : 4-lane requantise / convert unit
// =============================================================================
module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,           // active-low, asynchronous assert

    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,      // signed, SUBTRACTED (F3)
    input  logic [15:0]  cfg_scale,       // signed
    input  logic [ 5:0]  cfg_truncate,    // 0..63
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

    // ------------------------------------------------------------------
    // INTEGER lane (F3-F6):
    //   sat32( round_ties_away( (x - offset) * scale / 2^truncate ) )
    //
    // Widths are derived, not guessed (F5):
    //   x - offset : signed 33 (reaches +-(2^31 + 2^15), must not wrap)
    //   product    : signed 49 (33 + 16), carried exactly
    //   |product|  : < 2^46 (bound relied on by shift/index logic)
    // ------------------------------------------------------------------
    function automatic logic [31:0] lane_int (
        input logic [15:0] x,
        input logic [31:0] off,
        input logic [15:0] scl,
        input logic [ 5:0] tr,
        input logic        byp
    );
        logic signed [32:0] diff;   // x - off, exact
        logic signed [48:0] prod;  // exact product
        logic        [48:0] mag;   // |prod|
        logic        [63:0] magx;  // |prod| zero-extended, safe to index
        logic        [48:0] rmag;  // |prod| >> tr
        logic               rbit;  // round-up decision
        logic        [48:0] rm;   // rounded magnitude
        logic        [31:0] res;
        begin
            if (byp) begin
                res = {{16{x[15]}}, x};                      // F6
            end else begin
                diff = $signed({{17{x[15]}}, x}) - $signed({off[31], off});
                prod = diff * $signed(scl);                  // exact, F5
                mag  = prod[48] ? (~prod + 49'd1) : prod;
                magx = {15'd0, mag};
                // F4: ties away from zero. On the magnitude this is
                // round-half-up, and (mag + 2^(t-1)) >> t decomposes as
                // (mag >> t) + mag[t-1]. tr == 0 is a pure no-op.
                rbit = (tr == 6'd0) ? 1'b0 : magx[tr - 6'd1];
                rmag = mag >> tr;
                rm   = rmag + {48'd0, rbit};
                // F5: saturation happens LAST; sign comes from the product
                if (prod[48] == 1'b0) begin
                    res = (rm >= 49'd2147483648) ? 32'h7FFFFFFF : rm[31:0];
                end else begin
                    res = (rm  > 49'd2147483648) ? 32'h80000000
                                                  : (~rm[31:0] + 32'd1);
                end
            end
            lane_int = res;
        end
    endfunction

    // ------------------------------------------------------------------
    // FLOAT lane (F7-F9): exact binary16 -> binary32.
    //   normal    : exponent +112, mantissa in top of 23-bit fraction
    //   subnormal : NORMALISED via leading-zero count (F7) -- every binary16
    //               subnormal is a normal binary32
    //   infinity  : clamped to FLT_MAX, not propagated (F8)
    //   NaN       : payload into LOW fraction bits, sign kept; or zero when
    //               cfg_nan_to_zero is set (F9)
    // ------------------------------------------------------------------
    function automatic logic [31:0] lane_flt (
        input logic [15:0] h,
        input logic        n2z
    );
        logic        s;
        logic [ 4:0] e;
        logic [ 9:0] m;
        logic [ 3:0] lz;
        logic [ 9:0] sh;
        logic [31:0] res;
        begin
            s = h[15];
            e = h[14:10];
            m = h[ 9: 0];
            if (e == 5'h1F) begin
                if (m == 10'd0) begin
                    res = {s, 8'hFE, 23'h7FFFFF};            // F8 inf->FLT_MAX
                end else begin
                    res = n2z ? 32'h00000000               // F9 nan_to_zero
                               : {s, 8'hFF, 13'd0, m};     // F9 payload low
                end
            end else if (e == 5'd0) begin
                if (m == 10'd0) begin
                    res = {s, 31'd0};                       // F7 signed zero
                end else begin
                    casez (m)                                // F7 normalise
                        10'b1?????????: lz = 4'd0;
                        10'b01????????: lz = 4'd1;
                        10'b001???????: lz = 4'd2;
                        10'b0001??????: lz = 4'd3;
                        10'b00001?????: lz = 4'd4;
                        10'b000001????: lz = 4'd5;
                        10'b0000001???: lz = 4'd6;
                        10'b00000001??: lz = 4'd7;
                        10'b000000001?: lz = 4'd8;
                        10'b0000000001: lz = 4'd9;
                        default:         lz = 4'd0;         // m==0, unreachable
                    endcase
                    sh  = m << lz;
                    // value = m * 2^-24 = 1.f * 2^(112-lz-127)
                    res = {s, (8'd112 - {4'd0, lz}), sh[8:0], 14'd0};
                end
            end else begin
                res = {s, ({3'd0, e} + 8'd112), m, 13'd0};  // normal
            end
            lane_flt = res;
        end
    endfunction

    // ------------------------------------------------------------------
    // Lane results for the word currently on the input. Computed
    // combinationally and captured on the acceptance edge, so the cfg_*
    // present at acceptance are the ones applied (A5). The two modes are
    // unrelated arithmetic sharing only the buffer (F2).
    // ------------------------------------------------------------------
    logic [127:0] result;

    always_comb begin
        if (cfg_precision == 2'd2) begin                     // F2 float mode
            result[ 31:  0] = lane_flt(in_data[ 15:  0], cfg_nan_to_zero);
            result[ 63: 32] = lane_flt(in_data[ 31: 16], cfg_nan_to_zero);
            result[ 95: 64] = lane_flt(in_data[ 47: 32], cfg_nan_to_zero);
            result[127: 96] = lane_flt(in_data[ 63: 48], cfg_nan_to_zero);
        end else begin                                       // F2 integer mode
            result[ 31:  0] = lane_int(in_data[ 15:  0], cfg_offset,
                                       cfg_scale, cfg_truncate, cfg_bypass);
            result[ 63: 32] = lane_int(in_data[ 31: 16], cfg_offset,
                                       cfg_scale, cfg_truncate, cfg_bypass);
            result[ 95: 64] = lane_int(in_data[ 47: 32], cfg_offset,
                                       cfg_scale, cfg_truncate, cfg_bypass);
            result[127: 96] = lane_int(in_data[ 63: 48], cfg_offset,
                                       cfg_scale, cfg_truncate, cfg_bypass);
        end
    end

    // ------------------------------------------------------------------
    // Buffer / handshake (A1-A6). Two slots: head drives out_data /
    // out_valid; skid parks a word accepted under a stalled head.
    // in_ready is a REGISTER (A2) computed from post-edge occupancy, so
    // toggling out_ready within a cycle cannot move it. Two slots are the
    // minimum that holds a word accepted in the cycle the consumer stalls
    // (A3/T5) while sustaining one word per cycle on open flow (A4/T8).
    // ------------------------------------------------------------------
    logic [127:0] head_q, skid_q;
    logic         head_v_q, skid_v_q;
    logic         in_ready_q;

    logic         accept;
    logic         deliver;
    logic         head_stays;
    logic         head_v_n;
    logic         skid_v_n;

    assign accept     = in_valid && in_ready_q;
    assign deliver    = head_v_q && out_ready;
    assign head_stays = head_v_q && !deliver;

    // slot occupancy after this edge
    assign head_v_n   = head_stays || skid_v_q || accept;
    assign skid_v_n   = head_stays ? (skid_v_q || accept)
                                   : (skid_v_q && accept);

    assign out_valid = head_v_q;
    assign out_data  = head_q;
    assign in_ready  = in_ready_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_v_q   <= 1'b0;                    // A6: nothing stale retained
            skid_v_q   <= 1'b0;
            in_ready_q <= 1'b1;                    // A6: ready after release
            head_q     <= 128'd0;
            skid_q     <= 128'd0;
        end else begin
            head_v_q   <= head_v_n;
            skid_v_q   <= skid_v_n;
            in_ready_q <= !(head_v_n && skid_v_n); // ready iff a slot is free

            if (!head_stays) begin
                if (skid_v_q) begin
                    head_q <= skid_q;             // skid promotes to head
                end else if (accept) begin
                    head_q <= result;             // straight into the head
                end
            end
            // head_stays: head_q holds -- stable across the stall (A1)

            if (accept) begin
                if (head_stays) begin
                    if (!skid_v_q) begin
                        skid_q <= result;         // park under a stalled head
                    end
                end else if (skid_v_q) begin
                    skid_q <= result;             // refill behind a promotion
                end
            end
        end
    end

endmodule
