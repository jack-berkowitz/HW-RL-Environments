// Directed probe driver. Reads probe_in.hex, writes probe_out.hex in the same
// 288-bit record format the scoring vectors use. Never scored, never shipped.
//
// Observation is a posedge monitor over an in-flight queue -- the same
// discipline as the scoring testbench, and for the same reason. The first
// version of this rig sampled the result at the negedge where in_ready_o was
// high, which is right for a COMBINATIONAL design and silently off-by-N for a
// pipelined one: driven against the 3-cycle second source it reported 51
// disagreements that were entirely its own.
module probe_drv_tb #(parameter int unsigned WIDTH = 64);
  localparam int unsigned MAXV = 4000;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  // iv STARTS LOW, and that is not cosmetic. A sibling probe declared it as
  // `logic iv = 1`, so it transacted during reset before the stimulus loop
  // began and every captured record was offset by the spurious transfers. It
  // then reported two mutants killing 50 of 50 band vectors across every
  // shape -- a number caught only because it was implausible on its face.
  logic iv=0, ir, vecm=0, ov, orr=1;
  logic [1:0] fmt=0; logic [2:0] rnd=0;
  logic [WIDTH-1:0] a=0,b=0,c=0,res; logic [4:0] fl;
  fp_multifmt_fma #(.WIDTH(WIDTH)) dut(.clk_i(clk),.rst_ni(rst_n),.in_valid_i(iv),.in_ready_o(ir),
    .fmt_i(fmt),.vec_i(vecm),.a_i(a),.b_i(b),.c_i(c),.rnd_i(rnd),
    .out_valid_o(ov),.out_ready_i(orr),.result_o(res),.flags_o(fl));

  logic [199:0] inp [0:MAXV-1];
  int fd, n, i, got;
  int q[$];

  always @(posedge clk) if (rst_n) begin
    logic [287:0] w;
    int idx;
    if (iv && ir) q.push_back(i);
    if (ov && orr) begin
      idx = q.pop_front();
      w = {20'b0, inp[idx][197:196], (WIDTH==64), inp[idx][195], inp[idx][194:192],
           inp[idx][191:128], inp[idx][127:64], inp[idx][63:0], 64'(res), fl};
      $fwrite(fd, "%072h\n", w);
      got++;
    end
  end

  initial begin
    for (i=0;i<MAXV;i++) inp[i] = '1;
    $readmemh("probe_in.hex", inp);
    n = 0; while (n < MAXV && inp[n] !== '1) n++;
    fd = $fopen("probe_out.hex","w"); got = 0;
    repeat(8) @(negedge clk); rst_n=1; repeat(4) @(negedge clk);
    for (i=0;i<n;i++) begin
      @(negedge clk);
      fmt = inp[i][197:196]; vecm = inp[i][195]; rnd = inp[i][194:192];
      a = inp[i][191:128]; b = inp[i][127:64]; c = inp[i][63:0];
      iv = 1'b1; #0;
      while(!ir) begin @(negedge clk); #0; end
      @(negedge clk); iv = 1'b0;
    end
    while (q.size() != 0) @(negedge clk);
    repeat(4) @(negedge clk);
    $fclose(fd);
    $display("PROBE: drove %0d, captured %0d", n, got);
    $finish;
  end
  initial begin #20_000_000; $display("PROBE: watchdog got=%0d", got); $finish; end
endmodule
