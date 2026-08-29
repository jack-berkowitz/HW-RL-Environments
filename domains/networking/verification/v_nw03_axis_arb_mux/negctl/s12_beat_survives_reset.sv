// DIFFERENTIAL: nc_replay = 1'b0
// S12 NEGATIVE CONTROL for v_nw03 -- it MUST FAIL, and on S12 alone.
//
// WHAT IT PROVES. This task had NO negative controls at all: every one of its
// clause checks rested on the mutant set, so nothing showed any of them could
// fire independently of the ten defects that happen to ship with it. Eight of
// the eleven verification tasks carry controls; this was one of the three that
// did not.
//
// WHAT IT PERTURBS. The last beat accepted before rst_i is captured, and one
// cycle after reset release it is presented once on the master port. That is a
// beat "taken in before reset" appearing after it, which is exactly what S12
// forbids and exactly what the testbench's discarded-list check was written to
// catch.
//
// WHY S12 AND NOT S3. S3 -- frame atomicity -- was the first choice, because it
// has a SINGLE check site and a clause checked once is the one with no
// redundancy behind it. It is not reachable from the ports. The testbench infers
// a beat's source from the payload tag it carries, and checks m_tlast under S4,
// so every port-level way to fake a mid-frame switch also corrupts a field S4
// compares: forcing tlast low or high trips S4, and redirecting a beat trips S4
// and S5. Producing an S3-only violation needs the arbiter to interleave
// correctly-ordered beats from two inputs, which is internal behaviour a wrapper
// cannot reach. Recorded because "S3 has one site and no control" is still true
// after this file, and the reason is a property of the testbench's attribution
// rather than an omission here.
//
// WHY IT LANDS ON S12 ALONE. The monitor tests the discarded list FIRST and, on
// a hit, reports S12 and deletes the entry WITHOUT touching exp_q. So the
// replayed beat never reaches the source-tag, ordering or payload comparisons
// that S4 and S5 own.
module fm_nc_s12_beat_survives_reset #(
    parameter int S_COUNT    = 4,
    parameter int DATA_WIDTH = 32,
    parameter int USER_WIDTH = 1
) (
    input  logic                                     clk_i,
    input  logic                                     rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep_i,
    input  logic [S_COUNT-1:0]                       s_tvalid_i,
    output logic [S_COUNT-1:0]                       s_tready_o,
    input  logic [S_COUNT-1:0]                       s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser_i,
    output logic [DATA_WIDTH-1:0]                    m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]                m_tkeep_o,
    output logic                                     m_tvalid_o,
    input  logic                                     m_tready_i,
    output logic                                     m_tlast_o,
    output logic [USER_WIDTH-1:0]                    m_tuser_o
);
  logic [DATA_WIDTH-1:0]     g_tdata;
  logic [(DATA_WIDTH/8)-1:0] g_tkeep;
  logic                      g_tvalid, g_tlast;
  logic [USER_WIDTH-1:0]     g_tuser;

  // Capture the most recent beat ACCEPTED on any slave port, from the port
  // handshakes only. rst_i is ACTIVE HIGH on this task -- four of the eleven are,
  // and assuming otherwise cost a wrong reading in the vacuity sweep.
  logic [DATA_WIDTH-1:0]     nc_data;
  logic [(DATA_WIDTH/8)-1:0] nc_keep;
  logic [USER_WIDTH-1:0]     nc_user;
  logic                      nc_have;
  always_ff @(posedge clk_i) begin
    if (!rst_i) begin
      for (int i = 0; i < S_COUNT; i++)
        if (s_tvalid_i[i] && s_tready_o[i]) begin
          nc_data <= s_tdata_i[i]; nc_keep <= s_tkeep_i[i];
          nc_user <= s_tuser_i[i]; nc_have <= 1'b1;
        end
    end
  end

  logic rst_q;
  always_ff @(posedge clk_i) rst_q <= rst_i;
  wire  nc_release = !rst_i && rst_q;

  logic nc_arm;
  always_ff @(posedge clk_i) begin
    if (nc_release)                       nc_arm <= nc_have;
    else if (nc_arm && m_tready_i)        nc_arm <= 1'b0;
  end
  wire nc_replay = nc_arm;

  assign m_tvalid_o = nc_replay ? 1'b1     : g_tvalid;
  assign m_tdata_o  = nc_replay ? nc_data  : g_tdata;
  assign m_tkeep_o  = nc_replay ? nc_keep  : g_tkeep;
  assign m_tuser_o  = nc_replay ? nc_user  : g_tuser;
  assign m_tlast_o  = nc_replay ? 1'b0     : g_tlast;

  int unsigned nc_fired = 0;
  always_ff @(posedge clk_i) if (!rst_i && nc_replay && m_tready_i) nc_fired <= nc_fired + 1;
  final $display("FIRED fm_nc_s12.replays %0d", nc_fired);

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
      .clk_i, .rst_i,
      .s_tdata_i, .s_tkeep_i, .s_tvalid_i, .s_tready_o, .s_tlast_i, .s_tuser_i,
      .m_tdata_o (g_tdata), .m_tkeep_o (g_tkeep), .m_tvalid_o (g_tvalid),
      .m_tready_i (m_tready_i && !nc_replay),
      .m_tlast_o (g_tlast), .m_tuser_o (g_tuser)
  );
endmodule
