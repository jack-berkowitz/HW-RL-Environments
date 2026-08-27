// =============================================================================
// sdp_requant : 4-lane requantise / convert unit
//
// Implements EXACT arithmetic for both Integer and Float modes matching the
// measured anchor behaviour. Contains a synchronous depth-4 Skid/FIFO to 
// sustain 1 word/cycle throughput with a perfectly registered ready signal.
// 
// Synthesis safe: Uses continuous assignments within generate blocks to strictly
// avoid block declaration order restrictions in Verilator / Slang.
// =============================================================================

module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,
    input  logic [15:0]  cfg_scale,
    input  logic [ 5:0]  cfg_truncate,
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

    // -------------------------------------------------------------------------
    // ARITHMETIC DATAPATH (Combinational)
    // -------------------------------------------------------------------------
    wire [127:0] dp_out_data;

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_lanes
            wire [15:0] x = in_data[i*16 +: 16];
            wire x_sign = x[15];

            // -----------------------------------------------------------------
            // INTEGER MODE PATH
            // -----------------------------------------------------------------
            // Explicit sign extension mapping (avoids SV casting edge cases)
            wire signed [32:0] x_ext33   = { {17{x[15]}}, x };
            wire signed [32:0] off_ext33 = { {1{cfg_offset[31]}}, cfg_offset };
            
            // F3: Exact subtraction
            wire signed [32:0] diff = x_ext33 - off_ext33;
            
            // F5: Exact product (33-bit * 16-bit = 49-bit)
            wire signed [48:0] diff_ext  = { {16{diff[32]}}, diff };
            wire signed [48:0] scale_ext = { {33{cfg_scale[15]}}, cfg_scale };
            wire signed [48:0] prod = diff_ext * scale_ext;
            
            // F4: Round to nearest, ties AWAY FROM ZERO
            wire prod_sign = prod[48];
            wire [48:0] mag = prod_sign ? -prod : prod;
            wire [63:0] mag64 = {15'd0, mag};
            
            // Shift into 64-bit space to allow shift factor up to 63 without overflow
            wire [63:0] mag_rounded64 = (cfg_truncate == 6'd0) ? mag64 :
                                        (mag64 + (64'd1 << (cfg_truncate - 6'd1))) >> cfg_truncate;
                                        
            // Restore sign into 65-bit signed container to safely verify saturation bounds
            wire signed [64:0] rnd_signed = prod_sign ? -$signed({1'b0, mag_rounded64}) : 
                                                         $signed({1'b0, mag_rounded64});
                                                         
            // F5: Saturation happens LAST
            wire [31:0] int_sat = (rnd_signed > 65'sd2147483647)  ? 32'h7FFFFFFF :
                                  (rnd_signed < -65'sd2147483648) ? 32'h80000000 :
                                  rnd_signed[31:0];
                                  
            // F6: Integer Mode Bypass
            wire [31:0] x_sign_ext32 = { {16{x[15]}}, x };
            wire [31:0] int_mode_final = cfg_bypass ? x_sign_ext32 : int_sat;

            // -----------------------------------------------------------------
            // FLOAT MODE PATH (fp16 -> fp32)
            // -----------------------------------------------------------------
            wire [4:0] exp = x[14:10];
            wire [9:0] frac = x[9:0];

            // F7: Subnormal LZA and normalization
            wire [3:0] lz = frac[9] ? 4'd0 :
                            frac[8] ? 4'd1 :
                            frac[7] ? 4'd2 :
                            frac[6] ? 4'd3 :
                            frac[5] ? 4'd4 :
                            frac[4] ? 4'd5 :
                            frac[3] ? 4'd6 :
                            frac[2] ? 4'd7 :
                            frac[1] ? 4'd8 :
                            frac[0] ? 4'd9 : 4'd10;

            wire [7:0] new_exp_sub = 8'd112 - {4'd0, lz};
            wire [22:0] frac23 = {frac, 13'd0};
            // Left shifting seamlessly drops the normalized hidden bit across the 23-bit boundary
            wire [22:0] new_frac_sub = frac23 << (lz + 4'd1);

            wire is_zero = (exp == 5'd0) && (frac == 10'd0);
            wire is_sub  = (exp == 5'd0) && (frac != 10'd0);
            wire is_inf  = (exp == 5'd31) && (frac == 10'd0);
            wire is_nan  = (exp == 5'd31) && (frac != 10'd0);

            wire [31:0] flt_out =
                is_zero ? {x_sign, 31'd0} :
                is_sub  ? {x_sign, new_exp_sub, new_frac_sub} :
                is_inf  ? {x_sign, 8'hFE, 23'h7FFFFF} :  // F8: Clamp to FLT_MAX
                is_nan  ? (cfg_nan_to_zero ? 32'd0 : {x_sign, 8'hFF, 13'b0, frac}) : // F9: NaN
                          {x_sign, 8'd112 + {3'd0, exp}, frac, 13'b0};

            // -----------------------------------------------------------------
            // F2: MODE SELECTION
            // -----------------------------------------------------------------
            assign dp_out_data[i*32 +: 32] = (cfg_precision == 2'd2) ? flt_out : int_mode_final;
        end
    endgenerate

    // -------------------------------------------------------------------------
    // A2 & A4: SUSTAINED THROUGHPUT SYNCHRONOUS FIFO
    // -------------------------------------------------------------------------
    // Depth 4 allows 100% throughput while keeping in_ready strictly registered,
    // explicitly isolating out_ready from in_ready to satisfy A2 completely.
    logic [127:0] fifo_mem [0:3];
    logic [1:0]   wr_ptr;
    logic [1:0]   rd_ptr;
    logic [2:0]   count;
    logic         in_ready_reg;

    assign in_ready = in_ready_reg;
    assign out_valid = (count > 3'd0);
    assign out_data = fifo_mem[rd_ptr];

    wire push = in_valid && in_ready;
    wire pop  = out_valid && out_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 2'd0;
            rd_ptr <= 2'd0;
            count  <= 3'd0;
            in_ready_reg <= 1'b1;
        end else begin
            if (push) begin
                fifo_mem[wr_ptr] <= dp_out_data;
                wr_ptr <= wr_ptr + 2'd1;
            end
            
            if (pop) begin
                rd_ptr <= rd_ptr + 2'd1;
            end

            case ({push, pop})
                2'b10: begin
                    count <= count + 3'd1;
                    in_ready_reg <= ((count + 3'd1) < 3'd4);
                end
                2'b01: begin
                    count <= count - 3'd1;
                    in_ready_reg <= 1'b1;
                end
                2'b11: begin
                    in_ready_reg <= (count < 3'd4);
                end
                2'b00: begin
                    in_ready_reg <= (count < 3'd4);
                end
            endcase
        end
    end

endmodule