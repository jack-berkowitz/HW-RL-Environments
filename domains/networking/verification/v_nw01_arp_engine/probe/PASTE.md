# Task: write a SystemVerilog testbench from a specification

You are given a **specification** and a **port map**. You are not given the
design, and you will not be. Write a testbench that decides whether a design
presented to it obeys the specification.

Your testbench will be compiled against several different designs. One of them
is correct. Others are correct in every respect but one, each breaking a single
clause below. **Not one of them can be told apart from a correct design by a
single successful lookup.** Three of them are only visible if you leave a lookup
unanswered for hundreds of cycles and measure what happens; others need a frame
aimed at somebody else, an address outside the local subnet, or a frame that is
not ARP at all.

Your testbench must **accept** every design that obeys the specification and
**reject** every design that does not. Both halves matter: one that rejects
everything is worth nothing, and neither is one that accepts everything.

A design that obeys the specification may still differ from another that also
obeys it. The clauses marked **latitude** name exactly where. Requiring one of
those choices is a defect in your testbench, and one of the designs you will be
run against deliberately takes the opposite choice on every one of them.

---

## Port map

```systemverilog
module arp_engine (
  input  logic        clk_i,
  input  logic        rst_i,               // SYNCHRONOUS, ACTIVE HIGH
  // ---- received Ethernet frame ----
  input  logic        s_hdr_valid_i,
  output logic        s_hdr_ready_o,
  input  logic [47:0] s_dest_mac_i,
  input  logic [47:0] s_src_mac_i,
  input  logic [15:0] s_eth_type_i,
  input  logic [7:0]  s_payload_data_i,
  input  logic        s_payload_valid_i,
  output logic        s_payload_ready_o,
  input  logic        s_payload_last_i,
  input  logic        s_payload_user_i,
  // ---- transmitted Ethernet frame ----
  output logic        m_hdr_valid_o,
  input  logic        m_hdr_ready_i,
  output logic [47:0] m_dest_mac_o,
  output logic [47:0] m_src_mac_o,
  output logic [15:0] m_eth_type_o,
  output logic [7:0]  m_payload_data_o,
  output logic        m_payload_valid_o,
  input  logic        m_payload_ready_i,
  output logic        m_payload_last_o,
  output logic        m_payload_user_o,
  // ---- address lookup ----
  input  logic        req_valid_i,
  output logic        req_ready_o,
  input  logic [31:0] req_ip_i,
  output logic        resp_valid_o,
  input  logic        resp_ready_i,
  output logic        resp_error_o,
  output logic [47:0] resp_mac_o,
  // ---- configuration ----
  input  logic [47:0] local_mac_i,
  input  logic [31:0] local_ip_i,
  input  logic [31:0] gateway_ip_i,
  input  logic [31:0] subnet_mask_i,
  input  logic        clear_cache_i
);

  // no body -- see spec/arp_engine_spec.md for required behaviour
endmodule
```

---

## Specification

An address-resolution engine. It answers lookups of the form "what MAC address
belongs to this IP address" from a small cache, and when the cache cannot
answer it asks the network, retries, and eventually gives up. It also answers
other stations' requests for its own address, and learns from every ARP frame
it sees.

Clauses marked **latitude** are choices the implementation is free to make;
your testbench must not require either answer.

---

## 0. Configuration — pinned

| quantity | value |
|---|---|
| request retry count | **4** |
| request retry interval | **64** cycles |
| request timeout | **256** cycles |
| cache capacity | **4** entries |
| `rst_i` | **synchronous**, **active high** |

`local_mac_i`, `local_ip_i`, `gateway_ip_i` and `subnet_mask_i` are inputs, not
constants; hold them steady while the engine is running.

## F. The ARP frame

An ARP frame is an Ethernet frame with `eth_type` **`0x0806`** whose payload is
**28 bytes**, sent most significant byte first:

| bytes | field | value on the wire |
|---|---|---|
| 0–1 | hardware type | `0x0001` |
| 2–3 | protocol type | `0x0800` |
| 4 | hardware length | `6` |
| 5 | protocol length | `4` |
| 6–7 | **operation** | `1` request, `2` reply |
| 8–13 | sender MAC (SHA) | |
| 14–17 | sender IP (SPA) | |
| 18–23 | target MAC (THA) | |
| 24–27 | target IP (TPA) | |

The header (`*_dest_mac`, `*_src_mac`, `*_eth_type`) is presented on its own
handshake, ahead of the payload stream.

## Q. Lookups

- **Q1.** A lookup whose address is already in the cache is answered from the
  cache: `resp_valid_o` with `resp_error_o` low and `resp_mac_o` the cached MAC,
  and **no frame is transmitted**.
- **Q2.** A lookup whose address is not in the cache causes an ARP **request**
  frame to be transmitted, broadcast to `ff:ff:ff:ff:ff:ff`, carrying
  `SHA = local_mac_i`, `SPA = local_ip_i` and `THA = 0`.
- **Q3.** The address asked for is the looked-up address itself when it is
  **inside the local subnet** — that is, when
  `(ip & subnet_mask_i) == (local_ip_i & subnet_mask_i)` — and
  `gateway_ip_i` otherwise.
- **Q4.** If no answer arrives, **exactly 4** request frames are transmitted in
  total, and consecutive requests are between **64 and 80 cycles** apart. The
  count is exact; the spacing is a window, because a handshake takes a cycle or
  two that this contract does not fix.
- **Q5.** If no answer arrives, the lookup is answered with `resp_valid_o` and
  `resp_error_o` **high**, between **256 and 300 cycles** after the fourth
  request — and not before.
- **Q6.** An ARP **reply** whose `SPA` is the address being asked for resolves
  the outstanding lookup: `resp_valid_o` with `resp_error_o` low and
  `resp_mac_o` equal to that reply's `SHA`. No further request is transmitted.

## A. Answering other stations

- **A1.** A received ARP **request** whose `TPA` equals `local_ip_i` is answered
  with an ARP **reply** carrying `operation = 2`, `SHA = local_mac_i`,
  `SPA = local_ip_i`, `THA` the requester's `SHA` and `TPA` the requester's
  `SPA`, sent to `dest_mac` equal to the requester's `SHA`.
- **A2.** A received ARP request whose `TPA` is **not** `local_ip_i` is not
  answered.
- **A3.** A received frame whose `eth_type` is not `0x0806` is ignored
  entirely: it is neither answered nor learned from.

## C. The cache

- **C1.** Every received ARP frame — request or reply — inserts the pair
  (`SPA`, `SHA`) into the cache. A lookup of that address afterwards is
  answered from the cache under Q1.
- **C2.** The cache holds **4** entries. An insert never fails; when the cache
  is full it displaces an existing entry.
- **C3.** `clear_cache_i` empties the cache. Every address is unknown
  afterwards, so the next lookup of any address goes to the network under Q2.

## X. Reset and liveness

- **X1.** `rst_i` is **synchronous** and **active high**. While it is high no
  output valid is asserted.
- **X2.** After reset the cache is empty and no lookup is outstanding.
- **X3 (liveness bound).** The engine makes forward progress in both
  directions, with the response channel held ready:
  - a lookup offered on `req_valid_i` is accepted within **32** cycles, and one
    that hits the cache is answered within **32** cycles of acceptance; and
  - a received frame's header, and each byte of its payload, is accepted within
    **32** cycles of being offered.

---

## L. Latitude — named, and deliberately unconstrained

- **L1.** **Which entry a full cache displaces.** Entries are placed by a
  function of the address that this contract does not fix, so which older
  entries survive an insert is unspecified. Do not require any particular one
  to still be there — only the one just inserted (C1) and the effect of C3.
- **L2.** `resp_mac_o` when `resp_error_o` is high. There is no address to
  report, so nothing is required of it.
- **L3.** The exact cycle on which a response or a frame appears, subject to
  the counts and intervals Q4, Q5 and X3 fix.

These three are the whole of the latitude in this contract.

---

## What this contract does not say

It says nothing about frames whose payload is shorter or longer than 28 bytes,
nor about `s_payload_user_i`, nor about what happens if a second lookup is
offered while one is outstanding. It places no requirement on the transmitted
payload beyond the fields F names.


---

## Termination — a requirement on your testbench

Your testbench must **always** reach a verdict and stop. Print exactly one of

```
RESULT: PASS
```

when the design obeys every clause, or

```
RESULT: FAIL
```

when it does not, then call `$finish`. You may print anything you like
alongside; only the `RESULT:` line is read.

A design that never accepts a lookup must produce `RESULT: FAIL`, not a hang. A
hang is not a verdict. Keep the watchdog in the provided plumbing, or write your
own — and bound the waits in your own stimulus too, or a design that accepts
nothing will hang you instead of failing.

---

## SystemVerilog constraints — read these first

Your file is compiled with **Verilator 5.x** (`--binary --timing`). These are
tool-enforced, not style advice. Every one has already caused a submitted
testbench to be rejected with none of its checking ever running:

- **Declarations come before statements.** Every variable declared in a
  `begin`/`end` block must appear before the first statement in that block.
  `int found = -1;` written after an assignment is a syntax error, not a warning.

- **Use `automatic` for anything declared inside a procedural block that you
  assign on each execution.** A declaration with an initialiser inside an
  `always` or `initial` block is **static**: `rec_t e = q.pop_front();` runs its
  initialiser once, at time zero, and never again — so `e` silently holds an
  all-zero value for the whole run and every comparison against it is
  meaningless. Write `automatic rec_t e = q.pop_front();`.

- **Do not use a reserved word as an identifier.** All of these are errors:
  `sequence`, `property`, `context`, `do`, `ref`, `expect`, `this`, `final`,
  `table`, `bind`, `cover`, `assert`, `event`, `local`, `type`, `class`,
  `virtual`, `program`, `interface`, `modport`, `extern`, `randomize`,
  `constraint`, `solve`, `before`, `alias`. If a name reads like a verification
  concept, rename it: `seq_no`, `ctx_id`, `is_final`.

- **Module instantiation belongs at module scope**, never inside an `initial` or
  `always` block.

- **Match a port's array form exactly.** Dimensions written BEFORE the name are
  *packed*; dimensions written AFTER the name are *unpacked*; they are different
  types and will not connect.

- **Never change a signal in the same timestep as the edge that samples it —
  including the falling edge.** Both of these race:

```systemverilog
  @(posedge clk); x = 1;   // races a design sampling x on the rising edge
  @(negedge clk); x = 1;   // races YOUR OWN checker if it runs on negedge
```

  The second is the one that gets missed. Drive from the edge OPPOSITE to the
  one that samples. The provided plumbing already does this.

- **Identify a result by bookkeeping, not by matching on its value.** Values
  repeat, so content matching is ambiguous and will mis-attribute.

- Do not use `#` delays for anything except the clock generator and the watchdog.
- No UVM, no `randsequence`, no DPI. Queues and associative arrays are fine.

---

## Provided plumbing

It packs and unpacks ARP frames and decides nothing. Paste it inside your
module, above your own code. It has been compiled and run against a correct
design.

```systemverilog
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves frames and lookups, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on serialising
// ARP frames byte by byte. It has been compiled and run against a correct
// design.
//
// What it does: generates the clock, sequences reset, connects the design,
// packs an ARP frame into the 28 bytes clause F describes and drives it in,
// unpacks every frame the design sends out into its fields, and offers a
// lookup.
//
// What it does NOT do: it keeps no cache, models no retry or timeout, decides
// nothing about which address should have been asked for, and draws no
// conclusion from any frame it captured. Every check is yours to write.
//
// ONE THING WORTH KNOWING: a frame is only complete when its last payload byte
// has moved, twenty-eight cycles after its header at the earliest. Waiting
// twenty cycles for one and concluding the design sent nothing is a mistake
// about the plumbing, not a finding about the design.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst = 1'b1;            // SYNCHRONOUS, ACTIVE HIGH

  task automatic bfm_reset(input int cycles = 6);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (3) @(posedge clk);
  endtask

  // ---- signals and the design under test ------------------------------------
  logic        s_hv = 1'b0, s_hr;
  logic [47:0] s_dm = '0, s_sm = '0;
  logic [15:0] s_et = '0;
  logic [7:0]  s_pd = '0;
  logic        s_pv = 1'b0, s_pr, s_pl = 1'b0, s_pu = 1'b0;
  logic        m_hv, m_hr = 1'b1;
  logic [47:0] m_dm, m_sm;
  logic [15:0] m_et;
  logic [7:0]  m_pd;
  logic        m_pv, m_pr = 1'b1, m_pl, m_pu;
  logic        rq_v = 1'b0, rq_r;
  logic [31:0] rq_ip = '0;
  logic        rs_v, rs_r = 1'b1, rs_e;
  logic [47:0] rs_mac;
  logic        clr_cache = 1'b0;
  logic [47:0] cfg_local_mac  = 48'h02_00_00_00_00_01;
  logic [31:0] cfg_local_ip   = 32'hC0A8_0101;
  logic [31:0] cfg_gateway_ip = 32'hC0A8_01FE;
  logic [31:0] cfg_subnet     = 32'hFFFF_FF00;

  arp_engine dut (
    .clk_i(clk), .rst_i(rst),
    .s_hdr_valid_i(s_hv), .s_hdr_ready_o(s_hr), .s_dest_mac_i(s_dm),
    .s_src_mac_i(s_sm), .s_eth_type_i(s_et), .s_payload_data_i(s_pd),
    .s_payload_valid_i(s_pv), .s_payload_ready_o(s_pr), .s_payload_last_i(s_pl),
    .s_payload_user_i(s_pu),
    .m_hdr_valid_o(m_hv), .m_hdr_ready_i(m_hr), .m_dest_mac_o(m_dm),
    .m_src_mac_o(m_sm), .m_eth_type_o(m_et), .m_payload_data_o(m_pd),
    .m_payload_valid_o(m_pv), .m_payload_ready_i(m_pr), .m_payload_last_o(m_pl),
    .m_payload_user_o(m_pu),
    .req_valid_i(rq_v), .req_ready_o(rq_r), .req_ip_i(rq_ip),
    .resp_valid_o(rs_v), .resp_ready_i(rs_r), .resp_error_o(rs_e), .resp_mac_o(rs_mac),
    .local_mac_i(cfg_local_mac), .local_ip_i(cfg_local_ip),
    .gateway_ip_i(cfg_gateway_ip), .subnet_mask_i(cfg_subnet),
    .clear_cache_i(clr_cache));

  // ---- every frame the design sends, unpacked --------------------------------
  typedef struct packed {
    logic [47:0] dest_mac, src_mac;
    logic [15:0] eth_type, htype, ptype, oper;
    logic [7:0]  hlen, plen;
    logic [47:0] sha, tha;
    logic [31:0] spa, tpa;
    int          at;          // the cycle its header moved
    int          nbytes;      // payload length, so you can check it yourself
  } bfm_frame_t;

  bfm_frame_t bfm_rx [$];     // frames captured from the design
  logic [7:0] bfm_buf [$];
  logic [47:0] bfm_pdm, bfm_psm; logic [15:0] bfm_pet; int bfm_pat;

  always @(posedge clk) if (!rst) begin
    if (m_hv && m_hr) begin bfm_pdm = m_dm; bfm_psm = m_sm; bfm_pet = m_et; bfm_pat = bfm_cycle; end
    if (m_pv && m_pr) begin
      bfm_buf.push_back(m_pd);
      if (m_pl) begin
        bfm_frame_t f;
        f.dest_mac = bfm_pdm; f.src_mac = bfm_psm; f.eth_type = bfm_pet;
        f.at = bfm_pat; f.nbytes = bfm_buf.size();
        f.htype = (bfm_buf.size() > 1)  ? {bfm_buf[0], bfm_buf[1]} : '0;
        f.ptype = (bfm_buf.size() > 3)  ? {bfm_buf[2], bfm_buf[3]} : '0;
        f.hlen  = (bfm_buf.size() > 4)  ? bfm_buf[4] : '0;
        f.plen  = (bfm_buf.size() > 5)  ? bfm_buf[5] : '0;
        f.oper  = (bfm_buf.size() > 7)  ? {bfm_buf[6], bfm_buf[7]} : '0;
        f.sha   = (bfm_buf.size() > 13) ? {bfm_buf[8],bfm_buf[9],bfm_buf[10],
                                           bfm_buf[11],bfm_buf[12],bfm_buf[13]} : '0;
        f.spa   = (bfm_buf.size() > 17) ? {bfm_buf[14],bfm_buf[15],bfm_buf[16],bfm_buf[17]} : '0;
        f.tha   = (bfm_buf.size() > 23) ? {bfm_buf[18],bfm_buf[19],bfm_buf[20],
                                           bfm_buf[21],bfm_buf[22],bfm_buf[23]} : '0;
        f.tpa   = (bfm_buf.size() > 27) ? {bfm_buf[24],bfm_buf[25],bfm_buf[26],bfm_buf[27]} : '0;
        bfm_rx.push_back(f);
        bfm_buf.delete();
      end
    end
  end

  // ---- driving a frame in ----------------------------------------------------
  // Returns without waiting for any response. `ok` is low if the design did not
  // accept the header or a payload byte within `limit` cycles.
  task automatic bfm_send(input logic [15:0] oper, input logic [47:0] sha,
                          input logic [31:0] spa, input logic [47:0] tha,
                          input logic [31:0] tpa, output bit ok,
                          input logic [15:0] ethtype = 16'h0806, input int limit = 32);
    logic [7:0] p [28];
    ok = 1'b1;
    p[0]=8'h00; p[1]=8'h01; p[2]=8'h08; p[3]=8'h00; p[4]=8'd6; p[5]=8'd4;
    p[6]=oper[15:8]; p[7]=oper[7:0];
    for (int i=0;i<6;i++) p[8+i]  = sha[47-8*i -: 8];
    for (int i=0;i<4;i++) p[14+i] = spa[31-8*i -: 8];
    for (int i=0;i<6;i++) p[18+i] = tha[47-8*i -: 8];
    for (int i=0;i<4;i++) p[24+i] = tpa[31-8*i -: 8];
    @(negedge clk); s_dm = cfg_local_mac; s_sm = sha; s_et = ethtype; s_hv = 1'b1;
    begin bit took = 1'b0;
      for (int t=0;t<limit;t++) begin @(posedge clk); if (s_hr) begin took=1'b1; break; end end
      if (!took) ok = 1'b0;
    end
    @(negedge clk) s_hv = 1'b0;
    if (!ok) return;
    for (int i=0;i<28;i++) begin
      bit took = 1'b0;
      @(negedge clk); s_pd = p[i]; s_pl = (i==27); s_pv = 1'b1;
      for (int t=0;t<limit;t++) begin @(posedge clk); if (s_pr) begin took=1'b1; break; end end
      @(negedge clk) s_pv = 1'b0; s_pl = 1'b0;
      if (!took) begin ok = 1'b0; return; end
    end
  endtask

  // ---- offering a lookup ------------------------------------------------------
  task automatic bfm_lookup(input logic [31:0] ip, output bit ok, input int limit = 32);
    ok = 1'b0;
    @(negedge clk); rq_ip = ip; rq_v = 1'b1;
    for (int t=0;t<limit;t++) begin @(posedge clk); if (rq_r) begin ok = 1'b1; break; end end
    @(negedge clk) rq_v = 1'b0;
  endtask

  // Waits for a response. `got` is low if none arrived within `limit` cycles.
  task automatic bfm_await(input int limit, output bit got, output bit err,
                           output logic [47:0] mac, output int took);
    got = 1'b0; err = 1'b0; mac = '0; took = 0;
    for (int t=0;t<limit;t++) begin
      @(posedge clk); took = t;
      if (rs_v) begin got = 1'b1; err = rs_e; mac = rs_mac; break; end
    end
  endtask

  task automatic bfm_wait(input int n); repeat (n) @(posedge clk); endtask

  // ---- watchdog ---------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does: one of the
  // faulty designs never accepts a lookup at all, and without this your
  // testbench hangs instead of reporting. A hang is not a verdict.
  initial begin
    #8_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end
```

---

## What to produce

A single self-contained SystemVerilog file declaring

```systemverilog
module arp_engine_tb;
  // the provided plumbing, then your own stimulus and checking
endmodule
```

It must compile under Verilator 5.x with `--binary --timing`, instantiate the
design exactly once as `arp_engine`, and print exactly one `RESULT:` line before
finishing.

Say which clause a failure violates when you report one. A message naming the
clause is worth far more than a bare mismatch, both to you and to anyone reading
the result.
