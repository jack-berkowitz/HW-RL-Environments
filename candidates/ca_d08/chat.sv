module tiny_core #(
    parameter int IMEM_AW = 10,     // 8 / 10 / 12  (words)
    parameter int DMEM_AW = 10      // 8 / 10 / 12  (words)
) (
    input  logic        clk,
    input  logic        rst_n,

    // instruction fetch -- combinational read, always valid
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // data memory -- combinational read, synchronous write
    output logic        dmem_req,
    output logic        dmem_we,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,

    // retire interface
    output logic        retire_valid,
    output logic [31:0] retire_pc,
    output logic [4:0]  retire_rd,
    output logic [31:0] retire_rd_val,
    output logic        retire_is_store,
    output logic [31:0] retire_store_addr,
    output logic [31:0] retire_store_data
);

    // -------------------------------------------------------------------------
    // Architectural state
    // -------------------------------------------------------------------------

    logic [31:0] pc;

    // x1..x31 deliberately need not be reset.
    // regs[0] is never read directly and is never written.
    logic [31:0] regs [0:31];

    // Gives one idle cycle after synchronous reset release.
    // This is not required by the spec, but is legal and makes reset behavior
    // particularly simple.
    logic active;


    // -------------------------------------------------------------------------
    // Instruction fields
    // -------------------------------------------------------------------------

    logic [31:0] instr;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;

    logic [31:0] rs1_val;
    logic [31:0] rs2_val;


    // -------------------------------------------------------------------------
    // Immediate forms
    // -------------------------------------------------------------------------

    logic [31:0] imm_i;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;


    // -------------------------------------------------------------------------
    // Current-instruction execution results
    // -------------------------------------------------------------------------

    logic [31:0] next_pc;

    logic        wb_en;
    logic [4:0]  wb_rd;
    logic [31:0] wb_val;

    logic        is_store;
    logic [31:0] store_addr;
    logic [31:0] store_data;


    // -------------------------------------------------------------------------
    // Opcode constants
    // -------------------------------------------------------------------------

    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_IMM    = 7'b0010011;
    localparam logic [6:0] OP_REG    = 7'b0110011;


    // -------------------------------------------------------------------------
    // Fetch
    // -------------------------------------------------------------------------

    assign imem_addr = pc;
    assign instr     = imem_rdata;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];


    // -------------------------------------------------------------------------
    // Decode / execute / memory / retire generation
    //
    // Everything here corresponds to the instruction currently at PC.
    // Architectural state changes on the following rising edge.
    // -------------------------------------------------------------------------

    always_comb begin

        // ---------------------------------------------------------------------
        // x0 reads are always zero.
        // ---------------------------------------------------------------------

        rs1_val = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
        rs2_val = (rs2 == 5'd0) ? 32'd0 : regs[rs2];


        // ---------------------------------------------------------------------
        // RISC-V immediates, sign extended where appropriate
        // ---------------------------------------------------------------------

        // I immediate
        imm_i = {
            {20{instr[31]}},
            instr[31:20]
        };

        // S immediate
        imm_s = {
            {20{instr[31]}},
            instr[31:25],
            instr[11:7]
        };

        // B immediate
        imm_b = {
            {19{instr[31]}},
            instr[31],
            instr[7],
            instr[30:25],
            instr[11:8],
            1'b0
        };

        // U immediate
        imm_u = {
            instr[31:12],
            12'b0
        };

        // J immediate
        imm_j = {
            {11{instr[31]}},
            instr[31],
            instr[19:12],
            instr[20],
            instr[30:21],
            1'b0
        };


        // ---------------------------------------------------------------------
        // Defaults
        // ---------------------------------------------------------------------

        next_pc = pc + 32'd4;

        wb_en  = 1'b0;
        wb_rd  = rd;
        wb_val = 32'd0;

        is_store   = 1'b0;
        store_addr = 32'd0;
        store_data = 32'd0;

        dmem_req   = 1'b0;
        dmem_we    = 1'b0;
        dmem_addr  = 32'd0;
        dmem_wdata = 32'd0;


        // ---------------------------------------------------------------------
        // Instruction decode
        // ---------------------------------------------------------------------

        case (opcode)

            // -----------------------------------------------------------------
            // LUI
            // -----------------------------------------------------------------
            OP_LUI: begin
                wb_en  = 1'b1;
                wb_val = imm_u;
            end


            // -----------------------------------------------------------------
            // AUIPC
            //
            // Uses PC of this AUIPC instruction.
            // -----------------------------------------------------------------
            OP_AUIPC: begin
                wb_en  = 1'b1;
                wb_val = pc + imm_u;
            end


            // -----------------------------------------------------------------
            // ADDI
            //
            // It is the only legal OP-IMM instruction.
            // -----------------------------------------------------------------
            OP_IMM: begin
                if (funct3 == 3'b000) begin
                    wb_en  = 1'b1;
                    wb_val = rs1_val + imm_i;
                end
            end


            // -----------------------------------------------------------------
            // Register-register ALU instructions
            // -----------------------------------------------------------------
            OP_REG: begin
                wb_en = 1'b1;

                case (funct3)

                    // ADD / SUB
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            wb_val = rs1_val - rs2_val;   // SUB
                        else
                            wb_val = rs1_val + rs2_val;   // ADD
                    end

                    // SLL
                    3'b001: begin
                        wb_val = rs1_val << rs2_val[4:0];
                    end

                    // SLT -- signed
                    3'b010: begin
                        wb_val =
                            ($signed(rs1_val) < $signed(rs2_val))
                            ? 32'd1
                            : 32'd0;
                    end

                    // SLTU -- unsigned
                    3'b011: begin
                        wb_val =
                            (rs1_val < rs2_val)
                            ? 32'd1
                            : 32'd0;
                    end

                    // XOR
                    3'b100: begin
                        wb_val = rs1_val ^ rs2_val;
                    end

                    // SRL / SRA
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            wb_val =
                                $signed(rs1_val) >>> rs2_val[4:0];
                        else
                            wb_val =
                                rs1_val >> rs2_val[4:0];
                    end

                    // OR
                    3'b110: begin
                        wb_val = rs1_val | rs2_val;
                    end

                    // AND
                    3'b111: begin
                        wb_val = rs1_val & rs2_val;
                    end

                    default: begin
                        // Out of scope; never fetched.
                        wb_en  = 1'b0;
                        wb_val = 32'd0;
                    end

                endcase
            end


            // -----------------------------------------------------------------
            // LW
            // -----------------------------------------------------------------
            OP_LOAD: begin
                if (funct3 == 3'b010) begin
                    dmem_req  = active && rst_n;
                    dmem_we   = 1'b0;
                    dmem_addr = rs1_val + imm_i;

                    wb_en  = 1'b1;
                    wb_val = dmem_rdata;
                end
            end


            // -----------------------------------------------------------------
            // SW
            // -----------------------------------------------------------------
            OP_STORE: begin
                if (funct3 == 3'b010) begin
                    dmem_req   = active && rst_n;
                    dmem_we    = active && rst_n;
                    dmem_addr  = rs1_val + imm_s;
                    dmem_wdata = rs2_val;

                    is_store   = 1'b1;
                    store_addr = rs1_val + imm_s;
                    store_data = rs2_val;
                end
            end


            // -----------------------------------------------------------------
            // Branches
            // -----------------------------------------------------------------
            OP_BRANCH: begin
                case (funct3)

                    // BEQ
                    3'b000: begin
                        if (rs1_val == rs2_val)
                            next_pc = pc + imm_b;
                    end

                    // BNE
                    3'b001: begin
                        if (rs1_val != rs2_val)
                            next_pc = pc + imm_b;
                    end

                    // BLT -- signed
                    3'b100: begin
                        if ($signed(rs1_val) < $signed(rs2_val))
                            next_pc = pc + imm_b;
                    end

                    // BGE -- signed
                    3'b101: begin
                        if ($signed(rs1_val) >= $signed(rs2_val))
                            next_pc = pc + imm_b;
                    end

                    default: begin
                        // Out of scope.
                    end

                endcase
            end


            // -----------------------------------------------------------------
            // JAL
            // -----------------------------------------------------------------
            OP_JAL: begin
                wb_en  = 1'b1;

                // Link value is based on the JAL's own PC.
                wb_val = pc + 32'd4;

                next_pc = pc + imm_j;
            end


            // -----------------------------------------------------------------
            // JALR
            //
            // rs1_val is read from architectural state before wb_val is
            // committed, so rd == rs1 naturally has the required behavior.
            // -----------------------------------------------------------------
            OP_JALR: begin
                if (funct3 == 3'b000) begin
                    wb_en  = 1'b1;
                    wb_val = pc + 32'd4;

                    // Clear target bit zero as required by RISC-V.
                    next_pc =
                        (rs1_val + imm_i) & 32'hffff_fffe;
                end
            end


            default: begin
                // Outside the specified ISA subset; never fetched.
            end

        endcase


        // ---------------------------------------------------------------------
        // Retire interface
        //
        // In this single-cycle machine every active cycle retires exactly the
        // instruction currently at PC.
        // ---------------------------------------------------------------------

        retire_valid = active && rst_n;
        retire_pc    = pc;

        // The architectural destination is reported only if an actual
        // non-x0 write occurs.
        if (wb_en && (wb_rd != 5'd0)) begin
            retire_rd     = wb_rd;
            retire_rd_val = wb_val;
        end
        else begin
            // Includes stores, branches, and writes whose encoded rd is x0.
            retire_rd     = 5'd0;
            retire_rd_val = 32'd0;
        end

        retire_is_store = is_store;

        if (is_store) begin
            retire_store_addr = store_addr;
            retire_store_data = store_data;
        end
        else begin
            retire_store_addr = 32'd0;
            retire_store_data = 32'd0;
        end
    end


    // -------------------------------------------------------------------------
    // Architectural commit
    //
    // Data-memory writes are performed by the external memory on this same
    // rising edge from dmem_req/dmem_we/dmem_addr/dmem_wdata.
    // -------------------------------------------------------------------------

    always_ff @(posedge clk) begin

        if (!rst_n) begin
            pc     <= 32'd0;
            active <= 1'b0;

            // x1..x31 intentionally not reset.
        end
        else if (!active) begin
            // First post-reset setup cycle.
            pc     <= 32'd0;
            active <= 1'b1;
        end
        else begin

            // Commit destination register.
            //
            // Writes to x0 are discarded.
            if (wb_en && (wb_rd != 5'd0))
                regs[wb_rd] <= wb_val;

            // Commit next architectural PC.
            pc <= next_pc;
        end
    end

endmodule