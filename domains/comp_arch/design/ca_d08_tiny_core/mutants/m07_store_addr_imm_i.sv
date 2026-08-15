// =============================================================================
// m07_store_addr_imm_i -- MUTANT. NEVER SHIPPED.
// class: decode
// injected bug: the store address uses the I-type immediate instead of the S-type one
// Derived from ref/tiny_core_ref.sv by exactly one edit.
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

    // Unpacked, memory-style register file. A packed 2D array here would infer
    // flip-flops and blow up the instance count at synthesis.
    logic [31:0] regs [0:31];
    logic [31:0] pc;
    logic        running;      // low for one cycle out of reset (spec R9)

    // ---- fetch -------------------------------------------------------------
    assign imem_addr = pc;
    wire [31:0] ir = imem_rdata;

    wire [6:0] opcode = ir[6:0];
    wire [4:0] rd     = ir[11:7];
    wire [2:0] f3     = ir[14:12];
    wire [4:0] rs1    = ir[19:15];
    wire [4:0] rs2    = ir[24:20];
    wire [6:0] f7     = ir[31:25];

    // x0 reads as zero regardless of what the register file happens to hold.
    wire [31:0] a = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    wire [31:0] b = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    // ---- immediates --------------------------------------------------------
    wire [31:0] imm_i = {{20{ir[31]}}, ir[31:20]};
    wire [31:0] imm_s = {{20{ir[31]}}, ir[31:25], ir[11:7]};
    wire [31:0] imm_b = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
    wire [31:0] imm_u = {ir[31:12], 12'd0};
    wire [31:0] imm_j = {{11{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};

    // ---- ALU ---------------------------------------------------------------
    wire [4:0]  shamt = b[4:0];                 // only rs2[4:0] (spec)
    wire signed [31:0] a_s = a;
    wire signed [31:0] b_s = b;

    // Shift results are computed in ISOLATED wires, not inline in the case.
    // Inside `(f7==7'h20) ? (a_s >>> shamt) : (a >> shamt)` the unsigned srl
    // branch makes the WHOLE conditional expression unsigned, which silently
    // demotes a_s to unsigned and turns the arithmetic shift into a logical
    // one. Separating them keeps each operand's signedness self-contained.
    wire [31:0] sra_r = $unsigned($signed(a) >>> shamt);
    wire [31:0] srl_r = a >> shamt;

    logic [31:0] alu_r;
    always_comb begin
        unique case (f3)
            3'b000: alu_r = (f7 == 7'h20) ? (a - b) : (a + b);
            3'b001: alu_r = a << shamt;
            3'b010: alu_r = (a_s < b_s) ? 32'd1 : 32'd0;          // signed
            3'b011: alu_r = (a   < b)   ? 32'd1 : 32'd0;          // unsigned
            3'b100: alu_r = a ^ b;
            3'b101: alu_r = (f7 == 7'h20) ? sra_r : srl_r;
            3'b110: alu_r = a | b;
            default: alu_r = a & b;
        endcase
    end

    // ---- branch condition --------------------------------------------------
    logic br_taken;
    always_comb begin
        unique case (f3)
            3'b000:  br_taken = (a == b);                          // beq
            3'b001:  br_taken = (a != b);                          // bne
            3'b100:  br_taken = (a_s <  b_s);                      // blt  signed
            default: br_taken = (a_s >= b_s);                      // bge  signed
        endcase
    end

    // ---- memory ------------------------------------------------------------
    wire is_load  = (opcode == 7'h03);
    wire is_store = (opcode == 7'h23);
    assign dmem_req   = running && (is_load || is_store);
    assign dmem_we    = running && is_store;
    assign dmem_addr  = is_store ? (a + imm_s) : (a + imm_i);
    assign dmem_wdata = b;

    // ---- writeback value and next PC --------------------------------------
    logic [31:0] wb_val, next_pc;
    logic        wb_en;
    always_comb begin
        wb_val  = 32'd0;
        wb_en   = 1'b0;
        next_pc = pc + 32'd4;
        unique case (opcode)
            7'h37: begin wb_val = imm_u;            wb_en = 1'b1; end       // lui
            7'h17: begin wb_val = pc + imm_u;       wb_en = 1'b1; end       // auipc
            7'h6F: begin wb_val = pc + 32'd4;       wb_en = 1'b1;           // jal
                         next_pc = pc + imm_j; end
            7'h67: begin wb_val = pc + 32'd4;       wb_en = 1'b1;           // jalr
                         next_pc = (a + imm_i) & ~32'd1; end
            7'h63: begin if (br_taken) next_pc = pc + imm_b; end            // branch
            7'h03: begin wb_val = dmem_rdata;       wb_en = 1'b1; end       // lw
            7'h23: begin end                                               // sw
            7'h13: begin wb_val = a + imm_i;        wb_en = 1'b1; end       // addi
            default: begin wb_val = alu_r;          wb_en = 1'b1; end       // R-type
        endcase
    end

    // ---- retire ------------------------------------------------------------
    // Single-cycle: the instruction being executed this cycle is the one
    // retiring this cycle.
    assign retire_valid      = running;
    assign retire_pc         = pc;
    assign retire_rd         = wb_en ? rd : 5'd0;
    // spec R6: a write to x0 is discarded, so the reported value must be zero.
    assign retire_rd_val     = (wb_en && rd != 5'd0) ? wb_val : 32'd0;
    assign retire_is_store   = running && is_store;
    assign retire_store_addr = a + imm_i;   // MUTANT: wrong immediate format
    assign retire_store_data = b;

    // ---- state -------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc      <= 32'd0;
            running <= 1'b0;
        end else begin
            running <= 1'b1;
            if (running) begin
                pc <= next_pc;
                if (wb_en && rd != 5'd0) regs[rd] <= wb_val;
            end
        end
    end

endmodule
