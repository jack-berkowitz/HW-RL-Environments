// =============================================================================
// tiny_core_alt_ref.sv -- SECOND SOURCE for ca_d08. NEVER SHIPPED.
// =============================================================================
// A FALSIFIER, not an oracle. Written to make DIFFERENT free choices from
// ref/tiny_core_ref.sv and thereby try to break the checker. It never grades a
// submission and the spec is never validated against it. Its only job is to
// fail -- and if it does, the checker is over-constrained.
//
// The difference that matters here is TIMING:
//
//   ref/tiny_core_ref.sv          | this
//   ------------------------------|-------------------------------------------
//   single-cycle                  | MULTI-CYCLE FSM
//   retires EVERY cycle           | retires every 3 cycles (ALU/branch/jump)
//                                 | and every 4 cycles (load/store)
//   constant retire cadence       | VARIABLE cadence, instruction-dependent
//   combinational fetch->retire   | instruction registered in FETCH, operands
//                                 | registered in EXEC, retire driven from
//                                 | registers in WB
//
// This is aimed squarely at the property DESIGN_CATALOG.md warns about: the
// comparison must be ORDER-BASED, never cycle-stamped. A checker that assumed
// one retire per cycle, or a fixed number of cycles per instruction, passes the
// single-cycle reference and fails this.
//
// FSM: FETCH -> EXEC -> [MEM for lw/sw] -> WB -> FETCH
// =============================================================================

`timescale 1ns/1ps

module tiny_core #(
    parameter int IMEM_AW = 10,
    parameter int DMEM_AW = 10
) (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    output logic        dmem_req,
    output logic        dmem_we,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,
    output logic        retire_valid,
    output logic [31:0] retire_pc,
    output logic [4:0]  retire_rd,
    output logic [31:0] retire_rd_val,
    output logic        retire_is_store,
    output logic [31:0] retire_store_addr,
    output logic [31:0] retire_store_data
);

    typedef enum logic [1:0] { S_FETCH, S_EXEC, S_MEM, S_WB } state_e;
    state_e st;

    logic [31:0] regs [0:31];
    logic [31:0] pc, ir_q, pc_q;

    // results captured in EXEC, consumed in WB
    logic [31:0] res_q, npc_q, sa_q, sd_q;
    logic [4:0]  rd_q;
    logic        wen_q, st_q, ld_q;

    assign imem_addr = pc;

    // ---- decode of the REGISTERED instruction ------------------------------
    wire [6:0] opc = ir_q[6:0];
    wire [4:0] rdf = ir_q[11:7];
    wire [2:0] f3  = ir_q[14:12];
    wire [4:0] s1  = ir_q[19:15];
    wire [4:0] s2  = ir_q[24:20];
    wire [6:0] f7  = ir_q[31:25];

    wire [31:0] ra = (s1 == 5'd0) ? 32'd0 : regs[s1];
    wire [31:0] rb = (s2 == 5'd0) ? 32'd0 : regs[s2];

    wire [31:0] ii = {{20{ir_q[31]}}, ir_q[31:20]};
    wire [31:0] is = {{20{ir_q[31]}}, ir_q[31:25], ir_q[11:7]};
    wire [31:0] ib = {{19{ir_q[31]}}, ir_q[31], ir_q[7], ir_q[30:25], ir_q[11:8], 1'b0};
    wire [31:0] iu = {ir_q[31:12], 12'd0};
    wire [31:0] ij = {{11{ir_q[31]}}, ir_q[31], ir_q[19:12], ir_q[20], ir_q[30:21], 1'b0};

    wire [4:0] sh = rb[4:0];
    // Signedness kept in isolated wires -- mixing a signed and an unsigned
    // branch in one conditional expression demotes the signed one.
    wire [31:0] sra_w = $unsigned($signed(ra) >>> sh);
    wire [31:0] srl_w = ra >> sh;
    wire        lt_s  = ($signed(ra) <  $signed(rb));
    wire        ge_s  = ($signed(ra) >= $signed(rb));
    wire        lt_u  = (ra < rb);

    logic [31:0] alu;
    always_comb begin
        unique case (f3)
            3'b000:  alu = (f7 == 7'h20) ? (ra - rb) : (ra + rb);
            3'b001:  alu = ra << sh;
            3'b010:  alu = {31'd0, lt_s};
            3'b011:  alu = {31'd0, lt_u};
            3'b100:  alu = ra ^ rb;
            3'b101:  alu = (f7 == 7'h20) ? sra_w : srl_w;
            3'b110:  alu = ra | rb;
            default: alu = ra & rb;
        endcase
    end

    logic br;
    always_comb begin
        unique case (f3)
            3'b000:  br = (ra == rb);
            3'b001:  br = (ra != rb);
            3'b100:  br = lt_s;
            default: br = ge_s;
        endcase
    end

    wire is_ld = (opc == 7'h03);
    wire is_st = (opc == 7'h23);

    // ---- memory is driven only in S_MEM ------------------------------------
    assign dmem_req   = (st == S_MEM) && (is_ld || is_st);
    assign dmem_we    = (st == S_MEM) && is_st;
    assign dmem_addr  = is_st ? (ra + is) : (ra + ii);
    assign dmem_wdata = rb;

    // ---- retire is driven from REGISTERS in WB -----------------------------
    assign retire_valid      = (st == S_WB);
    assign retire_pc         = pc_q;
    assign retire_rd         = rd_q;
    assign retire_rd_val     = res_q;
    assign retire_is_store   = st_q;
    assign retire_store_addr = sa_q;
    assign retire_store_data = sd_q;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st   <= S_FETCH;
            pc   <= 32'd0;
            rd_q <= 5'd0;
            wen_q <= 1'b0;
            st_q <= 1'b0;
            ld_q <= 1'b0;
        end else begin
            unique case (st)
                S_FETCH: begin
                    ir_q <= imem_rdata;
                    pc_q <= pc;
                    st   <= S_EXEC;
                end

                S_EXEC: begin
                    // defaults
                    npc_q <= pc_q + 32'd4;
                    rd_q  <= 5'd0;
                    wen_q <= 1'b0;
                    st_q  <= 1'b0;
                    ld_q  <= 1'b0;
                    res_q <= 32'd0;
                    sa_q  <= ra + is;
                    sd_q  <= rb;

                    unique case (opc)
                        7'h37: begin res_q <= iu;            rd_q <= rdf; wen_q <= 1'b1; end
                        7'h17: begin res_q <= pc_q + iu;     rd_q <= rdf; wen_q <= 1'b1; end
                        7'h6F: begin res_q <= pc_q + 32'd4;  rd_q <= rdf; wen_q <= 1'b1;
                                     npc_q <= pc_q + ij; end
                        7'h67: begin res_q <= pc_q + 32'd4;  rd_q <= rdf; wen_q <= 1'b1;
                                     npc_q <= (ra + ii) & ~32'd1; end
                        7'h63: begin if (br) npc_q <= pc_q + ib; end
                        7'h03: begin rd_q <= rdf; wen_q <= 1'b1; ld_q <= 1'b1; end
                        7'h23: begin st_q <= 1'b1; end
                        7'h13: begin res_q <= ra + ii;       rd_q <= rdf; wen_q <= 1'b1; end
                        default: begin res_q <= alu;         rd_q <= rdf; wen_q <= 1'b1; end
                    endcase

                    // x0 is hardwired: report zero and write nothing (spec R6)
                    if (rdf == 5'd0) begin
                        rd_q  <= 5'd0;
                        res_q <= 32'd0;
                    end

                    // if/else rather than a ternary: a conditional expression
                    // between two enum values is not an enum, and Icarus
                    // requires an explicit cast for the assignment.
                    if (is_ld || is_st) st <= S_MEM;
                    else                st <= S_WB;
                end

                S_MEM: begin
                    if (ld_q) res_q <= (rd_q == 5'd0) ? 32'd0 : dmem_rdata;
                    st <= S_WB;
                end

                S_WB: begin
                    if (wen_q && rd_q != 5'd0) regs[rd_q] <= res_q;
                    pc <= npc_q;
                    st <= S_FETCH;
                end

                default: st <= S_FETCH;
            endcase
        end
    end

endmodule
