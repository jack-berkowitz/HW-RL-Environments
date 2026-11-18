// =============================================================================
// d_ai04 -- sdp_requant : 4-lane requantise / convert unit
// =============================================================================
module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,           // active-low, asynchronous assert

    // input stream -- one 64b word carrying four 16b lanes
    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    // configuration. Sampled with the word it applies to (A5).
    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,      // SIGNED, and SUBTRACTED (F3)
    input  logic [15:0]  cfg_scale,       // SIGNED
    input  logic [ 5:0]  cfg_truncate,    // 0..63
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    // output stream -- one 128b word carrying four 32b lanes
    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

    // ------------------------------------------------------------------
    // integer lane:  sat32( round_ties_away( (x - offset)*scale / 2^t ) )
    //
    // exact widths (F5):  x*scale     fits 32b  (|x*s|    <= 2^30)
    //                      offset*scale fits 48b (|os|    <= 2^46)
    //                      xs - os        fits 48b (|p|    <  2^47)
    // 'os' is computed once per word and shared by all four lanes.
    // ------------------------------------------------------------------
    function automatic logic [31:0] int_requant (
        input logic [15:0]        x,
        input logic signed [47:0] os,     // offset * scale, exact
        input logic [15:0]        scale,
        input logic [ 5:0]        trunc
    );
        logic signed [31:0] xs;            // x * scale
        logic signed [47:0] p;             // (x - offset) * scale
        logic                neg;
        logic [47:0]         mag;
        logic [47:0]         half;
        logic [47:0]         rm;
        xs   = $signed(x) * $signed(scale);
        p    = xs - os;
        neg  = p[47];
        mag  = neg ? (~p[47:0] + 48'd1) : p[47:0];
        // t == 0 is a no-op (half = 0); t >= 48 shifts half out of 48 bits -> 0
        half = (trunc == 6'd0) ? 48'd0 : (48'd1 << (trunc - 6'd1));
        rm   = (mag + half) >> trunc;      // round to nearest, ties away from 0
        if (rm[47:31] == 17'd0)            // |rm| < 2^31: fits, re-apply sign
            return neg ? (~rm[31:0] + 32'd1) : rm[31:0];
        else                               // saturate last (F5)
            return neg ? 32'h80000000 : 32'h7FFFFFFF;
    endfunction

    // ------------------------------------------------------------------
    // float lane: exact binary16 -> binary32 (F7-F9)
    // ------------------------------------------------------------------
    function automatic logic [31:0] fp16_to_fp32 (
        input logic [15:0] h,
        input logic        nan_to_zero
    );
        logic       s;
        logic [4:0] e;
        logic [9:0] m;
        logic [3:0] lz;
        logic [9:0] mn;
        logic [7:0] ex;
        s = h[15];
        e = h[14:10];
        m = h[9:0];
        if (e == 5'h1F) begin
            if (m == 10'd0)
                return {s, 8'hFE, 23'h7FFFFF};                 // inf -> FLT_MAX (F8)
            return nan_to_zero ? 32'd0 : {s, 8'hFF, 13'd0, m}; // NaN payload low (F9)
        end
        if (e == 5'd0) begin
            if (m == 10'd0)
                return {s, 31'd0};                             // signed zero (F7)
            // subnormal: normalise -- every fp16 subnormal is a normal fp32
            lz = m[9] ? 4'd0 : m[8] ? 4'd1 : m[7] ? 4'd2 :
                 m[6] ? 4'd3 : m[5] ? 4'd4 : m[4] ? 4'd5 :
                 m[3] ? 4'd6 : m[2] ? 4'd7 : m[1] ? 4'd8 : 4'd9;
            mn = m << lz;                                      // leading 1 -> bit 9
            ex = 8'd112 - {4'd0, lz};
            return {s, ex, mn[8:0], 14'd0};
        end
        return {s, {3'd0, e} + 8'd112, m, 13'd0};              // normal
    endfunction

    // ------------------------------------------------------------------
    // per-word combinational result, formed from the cfg present in the
    // cycle of acceptance (A5 by construction)
    // ------------------------------------------------------------------
    logic               is_float;
    logic signed [47:0] os;
    logic [3:0][31:0]   lane;
    logic [127:0]       w_word;

    always_comb begin
        is_float = (cfg_precision == 2'd2);   // 0,1,3 indistinguishable (F2)
        os       = $signed(cfg_offset) * $signed(cfg_scale);
        for (int k = 0; k < 4; k++) begin
            if (is_float)
                lane[k] = fp16_to_fp32(in_data[16*k +: 16], cfg_nan_to_zero);
            else if (cfg_bypass)              // integer mode only (F6)
                lane[k] = {{16{in_data[16*k + 15]}}, in_data[16*k +: 16]};
            else
                lane[k] = int_requant(in_data[16*k +: 16], os,
                                      cfg_scale, cfg_truncate);
        end
        w_word = {lane[3], lane[2], lane[1], lane[0]};
    end

    // ------------------------------------------------------------------
    // flow control: REGISTERED in_ready (A2) + two-slot skid (A3, A4).
    // Every accepted word lands in a slot in the same cycle; slots drain
    // only forward, so nothing is lost at a stall boundary (T5) and open
    // flow runs one word per cycle (T8).
    // ------------------------------------------------------------------
    logic         in_rdy_q;
    logic         out_v_q;
    logic         buf_v_q;
    logic [127:0] out_q;
    logic [127:0] buf_q;

    logic accept;
    logic out_consumed;
    logic buf_to_out;
    logic w_to_out;
    logic w_to_buf;
    logic out_v_nx;
    logic buf_v_nx;

    assign accept       = in_valid && in_rdy_q;
    assign out_consumed = out_v_q && out_ready;
    assign buf_to_out   = out_consumed && buf_v_q;
    assign w_to_out     = accept && (!out_v_q || (out_consumed && !buf_v_q));
    assign w_to_buf     = accept && out_v_q && !out_consumed;
    assign out_v_nx     = out_consumed ? (buf_v_q || w_to_out)
                                       : (out_v_q  || w_to_out);
    assign buf_v_nx     = (buf_v_q && !buf_to_out) || w_to_buf;

    assign in_ready  = in_rdy_q;   // flop: no comb path from out_ready (A2)
    assign out_valid = out_v_q;
    assign out_data  = out_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_rdy_q <= 1'b1;      // A6: ready high, no valid, nothing retained
            out_v_q  <= 1'b0;
            buf_v_q  <= 1'b0;
        end else begin
            in_rdy_q <= (!out_v_nx) || (!buf_v_nx);
            out_v_q  <= out_v_nx;
            buf_v_q  <= buf_v_nx;
            if (buf_to_out)
                out_q <= buf_q;
            else if (w_to_out)
                out_q <= w_word;
            if (w_to_buf)
                buf_q <= w_word;
        end
    end

endmodule
