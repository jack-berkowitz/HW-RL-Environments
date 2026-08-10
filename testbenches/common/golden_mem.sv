// =============================================================================
// golden_mem.sv -- shared golden byte-addressable memory reference model
// =============================================================================
// Used by the Tier-2 harnesses for LSQ (module 2), non-blocking cache
// (module 4) and MESI coherence (module 5). Written once, instantiated by each
// testbench; it is a VERIFICATION MODEL, never a DUT and never synthesised.
//
// Instantiate and call hierarchically:
//     golden_mem #(.ADDR_W(10)) gm ();
//     gm.wr_sized(addr, SZ_W, data);
//     exp = gm.rd_sized(addr, SZ_W);
//
// WHY IT IS DENSE, NOT SPARSE
//   Icarus 13 has no associative arrays at all (verified: `int a[int]`,
//   `[integer]`, `[logic[31:0]]`, `[string]` and `[*]` all fail to compile), so
//   this is a flat unpacked byte array over a bounded space. That is not a
//   compromise here: the Tier-2 convention is a small, deliberately skewed
//   address pool so aliasing and sharing actually happen, and a dense array over
//   a few KB covers that pool exactly.
//
// SIZE ENCODING (shared by every Tier-2 module that has a size field)
//   2'b00 = 1 byte, 2'b01 = 2 bytes, 2'b10 = 4 bytes.
//   Little-endian: byte 0 of a value lives at the lowest address.
//   Accesses are assumed naturally aligned; misaligned access is not modelled.
// =============================================================================

`ifndef GOLDEN_MEM_SV
`define GOLDEN_MEM_SV

module golden_mem #(
    parameter int ADDR_W     = 12,   // byte-address space = 1 << ADDR_W
    parameter int DATA_W     = 32,   // widest scalar access
    parameter int LINE_BYTES = 16    // line width for the cache/coherence models
) ();

    localparam int NBYTES = 1 << ADDR_W;
    localparam int LINE_W = 8 * LINE_BYTES;

    logic [7:0] mem [0:NBYTES-1];

    // ---------------------------------------------------------------------
    // size helpers
    // ---------------------------------------------------------------------
    function automatic int size_bytes(input int size_code);
        case (size_code)
            0:       return 1;
            1:       return 2;
            default: return 4;
        endcase
    endfunction

    // wrap into the modelled space so a stray high address can never index
    // out of bounds and kill the simulation
    function automatic int wrap(input int a);
        return a & (NBYTES - 1);
    endfunction

    // ---------------------------------------------------------------------
    // initialisation
    // ---------------------------------------------------------------------
    task automatic init_zero();
        for (int i = 0; i < NBYTES; i++) mem[i] = 8'h00;
    endtask

    // Deterministic non-zero fill: a load that returns 0 because the DUT never
    // actually fetched anything must not accidentally look correct.
    task automatic init_pattern(input int seed);
        for (int i = 0; i < NBYTES; i++)
            mem[i] = 8'((i * 7) ^ (i >> 3) ^ seed ^ 8'h5A);
    endtask

    // ---------------------------------------------------------------------
    // byte access
    // ---------------------------------------------------------------------
    function automatic void wr_byte(input int a, input logic [7:0] d);
        mem[wrap(a)] = d;
    endfunction

    function automatic logic [7:0] rd_byte(input int a);
        return mem[wrap(a)];
    endfunction

    // ---------------------------------------------------------------------
    // sized scalar access (little-endian)
    // ---------------------------------------------------------------------
    function automatic void wr_sized(input int a, input int size_code,
                                     input logic [DATA_W-1:0] d);
        int n;
        n = size_bytes(size_code);
        for (int i = 0; i < n; i++)
            mem[wrap(a + i)] = d[8*i +: 8];
    endfunction

    function automatic logic [DATA_W-1:0] rd_sized(input int a, input int size_code);
        logic [DATA_W-1:0] v;
        int n;
        v = '0;
        n = size_bytes(size_code);
        for (int i = 0; i < n; i++)
            v[8*i +: 8] = mem[wrap(a + i)];
        return v;
    endfunction

    // ---------------------------------------------------------------------
    // line access (modules 4 and 5)
    // ---------------------------------------------------------------------
    function automatic logic [LINE_W-1:0] rd_line(input int line_base);
        logic [LINE_W-1:0] v;
        v = '0;
        for (int i = 0; i < LINE_BYTES; i++)
            v[8*i +: 8] = mem[wrap(line_base + i)];
        return v;
    endfunction

    function automatic void wr_line(input int line_base, input logic [LINE_W-1:0] d);
        for (int i = 0; i < LINE_BYTES; i++)
            mem[wrap(line_base + i)] = d[8*i +: 8];
    endfunction

endmodule

`endif
