// Synthesis shim for d_ca06. Fixes the SCORED GEOMETRY and flattens the ports.
//
// WHY A SHIM RATHER THAN VERILOG_TOP_PARAMS. `T` is a TYPE parameter, and
// ORFS's VERILOG_TOP_PARAMS sets value parameters only -- it cannot pass
// `logic[31:0]`. A config that tried would silently synthesise the module's own
// default of logic[63:0] at DEPTH=128, which is 8,192 storage flops instead of
// 512, and label it the scored number.
//
// The shim also flattens the packed-array ports. Nothing here has logic in it;
// it exists so the geometry is stated once, in a file the build reads.
module queue_top (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [95:0]  write_data,     // 3 ports x 32 bits
  input  logic [2:0]   write_valid,
  output logic [2:0]   write_accept,
  output logic [95:0]  read_data,
  output logic [2:0]   read_valid,
  input  logic [2:0]   read_accept
);
  localparam int PORTS = 3;
  localparam int DW    = 32;

  logic [PORTS-1:0][DW-1:0] wd, rd;
  always_comb for (int i = 0; i < PORTS; i++) wd[i] = write_data[i*DW +: DW];
  always_comb for (int i = 0; i < PORTS; i++) read_data[i*DW +: DW] = rd[i];

  queue #(
    .T         (logic [DW-1:0]),
    .PTR_WIDTH (4),              // DEPTH = 16
    .PORTS     (PORTS)
  ) u_queue (
    .clk(clk), .rst_n(rst_n),
    .write_data(wd), .write_valid(write_valid), .write_accept(write_accept),
    .read_data(rd),  .read_valid(read_valid),   .read_accept(read_accept)
  );
endmodule
