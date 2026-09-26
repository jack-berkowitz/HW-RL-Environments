module id_width_conv_tb;
  logic clk, rst_n;
  localparam int SLV_ID_W=4, MST_ID_W=2, ADDR_W=32, DATA_W=32;
  localparam int MAX_UNIQ_IDS=4, MAX_TXNS_PER_ID=2;
  logic [SLV_ID_W-1:0] s_awid;
  logic [ADDR_W-1:0] s_awaddr;
  logic [7:0] s_awlen;
  logic  s_awvalid;
  logic  s_awready;
  logic [DATA_W-1:0] s_wdata;
  logic [DATA_W/8-1:0] s_wstrb;
  logic  s_wlast;
  logic  s_wvalid;
  logic  s_wready;
  logic [SLV_ID_W-1:0] s_bid;
  logic [1:0] s_bresp;
  logic  s_bvalid;
  logic  s_bready;
  logic [SLV_ID_W-1:0] s_arid;
  logic [ADDR_W-1:0] s_araddr;
  logic [7:0] s_arlen;
  logic  s_arvalid;
  logic  s_arready;
  logic [SLV_ID_W-1:0] s_rid;
  logic [DATA_W-1:0] s_rdata;
  logic [1:0] s_rresp;
  logic  s_rlast;
  logic  s_rvalid;
  logic  s_rready;
  logic [MST_ID_W-1:0] m_awid;
  logic [ADDR_W-1:0] m_awaddr;
  logic [7:0] m_awlen;
  logic  m_awvalid;
  logic  m_awready;
  logic [DATA_W-1:0] m_wdata;
  logic [DATA_W/8-1:0] m_wstrb;
  logic  m_wlast;
  logic  m_wvalid;
  logic  m_wready;
  logic [MST_ID_W-1:0] m_bid;
  logic [1:0] m_bresp;
  logic  m_bvalid;
  logic  m_bready;
  logic [MST_ID_W-1:0] m_arid;
  logic [ADDR_W-1:0] m_araddr;
  logic [7:0] m_arlen;
  logic  m_arvalid;
  logic  m_arready;
  logic [MST_ID_W-1:0] m_rid;
  logic [DATA_W-1:0] m_rdata;
  logic [1:0] m_rresp;
  logic  m_rlast;
  logic  m_rvalid;
  logic  m_rready;
  id_width_conv #(.SLV_ID_W(SLV_ID_W),.MST_ID_W(MST_ID_W),
    .ADDR_W(ADDR_W),.DATA_W(DATA_W),.MAX_UNIQ_IDS(MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .s_awid(s_awid),
    .s_awaddr(s_awaddr),
    .s_awlen(s_awlen),
    .s_awvalid(s_awvalid),
    .s_awready(s_awready),
    .s_wdata(s_wdata),
    .s_wstrb(s_wstrb),
    .s_wlast(s_wlast),
    .s_wvalid(s_wvalid),
    .s_wready(s_wready),
    .s_bid(s_bid),
    .s_bresp(s_bresp),
    .s_bvalid(s_bvalid),
    .s_bready(s_bready),
    .s_arid(s_arid),
    .s_araddr(s_araddr),
    .s_arlen(s_arlen),
    .s_arvalid(s_arvalid),
    .s_arready(s_arready),
    .s_rid(s_rid),
    .s_rdata(s_rdata),
    .s_rresp(s_rresp),
    .s_rlast(s_rlast),
    .s_rvalid(s_rvalid),
    .s_rready(s_rready),
    .m_awid(m_awid),
    .m_awaddr(m_awaddr),
    .m_awlen(m_awlen),
    .m_awvalid(m_awvalid),
    .m_awready(m_awready),
    .m_wdata(m_wdata),
    .m_wstrb(m_wstrb),
    .m_wlast(m_wlast),
    .m_wvalid(m_wvalid),
    .m_wready(m_wready),
    .m_bid(m_bid),
    .m_bresp(m_bresp),
    .m_bvalid(m_bvalid),
    .m_bready(m_bready),
    .m_arid(m_arid),
    .m_araddr(m_araddr),
    .m_arlen(m_arlen),
    .m_arvalid(m_arvalid),
    .m_arready(m_arready),
    .m_rid(m_rid),
    .m_rdata(m_rdata),
    .m_rresp(m_rresp),
    .m_rlast(m_rlast),
    .m_rvalid(m_rvalid),
    .m_rready(m_rready));

  logic [1:0] response_code;


  initial begin clk = 1'b0; forever #5 clk = ~clk; end



  initial rst_n = 1'b0;

  // Asserted and released away from the sampling edge.

  task automatic bfm_reset(input int cycles = 4);

    @(negedge clk);

    rst_n = 1'b0;

    repeat (cycles) @(posedge clk);

    @(negedge clk);

    rst_n = 1'b1;

  endtask

  // Offer a read address and hold it stable until accepted or the budget runs

  // out. Reports BOTH facts: whether it went, and how many cycles it waited.

  // Interpreting a refusal is yours.

  task automatic bfm_ar(input  logic [SLV_ID_W-1:0] id,

                        input  logic [ADDR_W-1:0]   addr,

                        input  logic [7:0]          len,

                        input  int                  budget,

                        output bit                  accepted,

                        output int                  waited);

    accepted = 1'b0; waited = 0;

    @(negedge clk);

    s_arid = id; s_araddr = addr; s_arlen = len; s_arvalid = 1'b1;

    while (waited < budget) begin

      @(posedge clk);

      if (s_arready) begin accepted = 1'b1; break; end

      waited++;

    end

    @(negedge clk) s_arvalid = 1'b0;

  endtask

  // The same for a write address.

  task automatic bfm_aw(input  logic [SLV_ID_W-1:0] id,

                        input  logic [ADDR_W-1:0]   addr,

                        input  logic [7:0]          len,

                        input  int                  budget,

                        output bit                  accepted,

                        output int                  waited);

    accepted = 1'b0; waited = 0;

    @(negedge clk);

    s_awid = id; s_awaddr = addr; s_awlen = len; s_awvalid = 1'b1;

    while (waited < budget) begin

      @(posedge clk);

      if (s_awready) begin accepted = 1'b1; break; end

      waited++;

    end

    @(negedge clk) s_awvalid = 1'b0;

  endtask

  // One write data beat.

  task automatic bfm_w(input logic [DATA_W-1:0]   data,

                       input logic [DATA_W/8-1:0] strb,

                       input logic                last);

    @(negedge clk);

    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;

    forever begin @(posedge clk); if (s_wready) break; end

    @(negedge clk) s_wvalid = 1'b0;

  endtask

  // Present one downstream read response beat with the given master identifier.

  // WHICH identifier, and in what order, is yours to decide.

  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid,

                           input logic [DATA_W-1:0]   data,

                           input logic                last);

    @(negedge clk);

    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = response_code; m_rvalid = 1'b1;

    forever begin @(posedge clk); if (m_rready) break; end

    @(negedge clk) m_rvalid = 1'b0;

  endtask

  // Present one downstream write response.

  task automatic bfm_bbeat(input logic [MST_ID_W-1:0] mid);

    @(negedge clk);

    m_bid = mid; m_bresp = response_code; m_bvalid = 1'b1;

    forever begin @(posedge clk); if (m_bready) break; end

    @(negedge clk) m_bvalid = 1'b0;

  endtask

  // Addresses carry a driver-assigned transaction number. This is an explicit
  // bookkeeping tag, not a search for a matching (possibly repeated) payload.
  localparam int LIMIT=2048;
  typedef struct packed {
    bit offered, accepted, master_seen, completed, wr;
    logic [3:0] sid;
    logic [1:0] mid;
    logic [31:0] addr;
    logic [7:0] len;
    int accept_cycle;
  } txn_t;
  typedef struct packed {
    int tid;
    logic [31:0] data;
    logic [1:0] resp;
    bit last;
  } rsp_t;
  typedef struct packed {
    logic [31:0] data;
    logic [3:0] strb;
    bit last;
  } wbeat_t;
  txn_t tx[LIMIT];
  rsp_t rq[16][$], bq[16][$];
  int ro[16][$], wo[16][$];
  wbeat_t wq[$];
  int rc[16], wc[16];
  int next_tid=1, cycles=0;
  int master_rbeats=0, slave_rbeats=0, master_bbeats=0, slave_bbeats=0;
  int slave_wbeats=0, master_wbeats=0;
  bit ended=0;
  bit watch_active=0, watch_wr=0;
  int watch_sid, watch_tid, retire_cycle=-1;

  task automatic fail(input string clause,input string detail);
    if(!ended)begin
      ended=1;
      $display("%s: %s (cycle %0d)",clause,detail,cycles);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic int distinct_ids(input bit wr);
    int n;
    n=0;
    for(int i=0;i<16;i++)if(wr ? wc[i]!=0 : rc[i]!=0)n++;
    return n;
  endfunction

  task automatic prepare(input bit wr,input int sid,input int len,output int tid);
    tid=next_tid;next_tid++;
    if(tid>=LIMIT)fail("D4","testbench transaction capacity exhausted");
    tx[tid]='0;tx[tid].offered=1;tx[tid].wr=wr;
    tx[tid].sid=4'(sid);tx[tid].len=8'(len);
    tx[tid].addr=32'h5a000000 | (32'(tid)<<8) | 32'h40;
  endtask

  // Responses are processed before requests at the same edge. An entry may
  // legally be retired and reallocated on that very edge (A4/D2).
  always @(posedge clk) begin : monitor
    automatic int t;
    automatic int sid;
    automatic int junk;
    automatic rsp_t e;
    automatic wbeat_t w;
    cycles++;
    if(!rst_n)begin
      // Sample after a full reset cycle; synchronous assertion need not have
      // removed a previously visible response before its first reset edge.
      for(int i=0;i<16;i++)begin
        rc[i]=0;wc[i]=0;rq[i].delete();bq[i].delete();ro[i].delete();wo[i].delete();
      end
      for(int i=0;i<LIMIT;i++)tx[i]='0;
      wq.delete();watch_active=0;retire_cycle=-1;
      master_rbeats=0;slave_rbeats=0;master_bbeats=0;slave_bbeats=0;
      slave_wbeats=0;master_wbeats=0;
    end else begin
      if(s_rvalid)begin
        sid=int'(s_rid);
        if(rc[sid]==0 || rq[sid].size()==0)fail("C2","read response without its outstanding transaction");
        else begin
          e=rq[sid][0];
          if(ro[sid].size()==0 || ro[sid][0]!=e.tid)fail("E1","read transaction reordered within ID (B1)");
          if(s_rid!==tx[e.tid].sid)fail("C1","read ID not restored");
          if(s_rdata!==e.data || s_rresp!==e.resp || s_rlast!==e.last)fail("E1","read payload/response/last changed");
          if(s_rready)begin
            e=rq[sid].pop_front();slave_rbeats++;
            if(e.last)begin
              rc[sid]--;tx[e.tid].completed=1;junk=ro[sid].pop_front();
              if(watch_active&&!watch_wr&&sid==watch_sid&&rc[sid]==0)retire_cycle=cycles;
            end
          end
        end
      end
      if(s_bvalid)begin
        sid=int'(s_bid);
        if(wc[sid]==0 || bq[sid].size()==0)fail("C2","write response without its outstanding transaction");
        else begin
          e=bq[sid][0];
          if(wo[sid].size()==0 || wo[sid][0]!=e.tid)fail("E1","write response reordered within ID (B1)");
          if(s_bid!==tx[e.tid].sid)fail("C1","write ID not restored");
          if(s_bresp!==e.resp)fail("E1","write response code changed");
          if(s_bready)begin
            e=bq[sid].pop_front();slave_bbeats++;wc[sid]--;
            tx[e.tid].completed=1;junk=wo[sid].pop_front();
            if(watch_active&&watch_wr&&sid==watch_sid&&wc[sid]==0)retire_cycle=cycles;
          end
        end
      end
      for(int direction=0;direction<2;direction++)begin
        if((direction!=0) ? (s_awvalid&&s_awready) : (s_arvalid&&s_arready))begin
          t=(direction!=0) ? int'(s_awaddr[23:8]) : int'(s_araddr[23:8]);
          sid=(direction!=0) ? int'(s_awid) : int'(s_arid);
          if(t<=0||t>=LIMIT)fail("D4","unrecognized slave request bookkeeping tag");
          else begin
            if(!tx[t].offered||tx[t].accepted)fail("D4","slave address accepted twice");
            if(direction!=0)begin
              if(wc[sid]==0&&distinct_ids(1)>=MAX_UNIQ_IDS)fail("A3","new write ID accepted at full table");
              if(wc[sid]>=MAX_TXNS_PER_ID)fail("A5","write per-ID depth exceeded");
              wc[sid]++;wo[sid].push_back(t);
            end else begin
              if(rc[sid]==0&&distinct_ids(0)>=MAX_UNIQ_IDS)fail("A3","new read ID accepted at full table");
              if(rc[sid]>=MAX_TXNS_PER_ID)fail("A5","read per-ID depth exceeded");
              rc[sid]++;ro[sid].push_back(t);
            end
            tx[t].accepted=1;tx[t].accept_cycle=cycles;
          end
        end
        if((direction!=0) ? (m_awvalid&&m_awready) : (m_arvalid&&m_arready))begin
          t=(direction!=0) ? int'(m_awaddr[23:8]) : int'(m_araddr[23:8]);
          if(t<=0||t>=LIMIT)fail("E1","master address tag corrupted");
          else begin
            if(!tx[t].offered||tx[t].master_seen||tx[t].wr!=1'(direction))fail("D4","duplicate/unrequested master transaction");
            if((direction!=0) ? (m_awaddr!==tx[t].addr||m_awlen!==tx[t].len) :
                           (m_araddr!==tx[t].addr||m_arlen!==tx[t].len))fail("E1","address or burst length changed");
            for(int j=1;j<next_tid;j++)begin
              if(tx[j].master_seen&&!tx[j].completed&&tx[j].wr==1'(direction)&&tx[j].sid!=tx[t].sid &&
                 tx[j].mid==((direction!=0)?m_awid:m_arid))fail("D1","co-outstanding IDs collide / early reuse (D2)");
            end
            tx[t].mid=(direction!=0) ? m_awid:m_arid;tx[t].master_seen=1;
          end
        end
      end
      if(s_wvalid&&s_wready)slave_wbeats++;
      if(m_wvalid&&m_wready)begin
        if(wq.size()==0)fail("D4","unexpected or duplicated master write beat");
        else begin
          w=wq.pop_front();master_wbeats++;
          if(m_wdata!==w.data||m_wstrb!==w.strb||m_wlast!==w.last)fail("E1","write payload/strb/last or order changed (B3)");
        end
      end
      if(m_rvalid&&m_rready)master_rbeats++;
      if(m_bvalid&&m_bready)master_bbeats++;
      if(watch_active&&retire_cycle>=0&&cycles>=retire_cycle+2)begin
        if(!tx[watch_tid].accepted || tx[watch_tid].accept_cycle>retire_cycle+2)
          fail("A4","new identifier not accepted within two cycles of retirement");
        watch_active=0;
      end
    end
  end

  // Check reset response suppression on subsequent rising edges, never READY.
  bit reset_sampled=0;
  always @(posedge clk)begin
    if(!rst_n&&reset_sampled&&(s_rvalid||s_bvalid))fail("F1","response presented during reset");
    reset_sampled<=!rst_n;
  end

  task automatic offer(input bit wr,input int tid,input int budget,output bit accepted);
    int waited;
    if(wr)bfm_aw(tx[tid].sid,tx[tid].addr,tx[tid].len,budget,accepted,waited);
    else bfm_ar(tx[tid].sid,tx[tid].addr,tx[tid].len,budget,accepted,waited);
  endtask

  task automatic request_tx(input bit wr,input int sid,input int len,output int tid);
    bit accepted;
    prepare(wr,sid,len,tid);
    // No local latency assertion: arbitrarily slow correct variants may run
    // until the mandatory, generous whole-test watchdog.
    offer(wr,tid,1000000,accepted);
    if(!accepted)fail("D4","request made no forward progress");
  endtask

  task automatic blocked(input bit wr,input int sid,input string clause);
    int tid;bit accepted;
    prepare(wr,sid,0,tid);offer(wr,tid,8,accepted);
    if(accepted)fail(clause,"request accepted while its bound remained exhausted");
    // The supplied BFM permits withdrawing an unaccepted probe after budget.
  endtask

  task automatic await_master(input int tid);
    while(!tx[tid].master_seen)@(negedge clk);
  endtask

  task automatic send_write(input int tid);
    wbeat_t w;
    for(int n=0;n<=int'(tx[tid].len);n++)begin
      w.data=(n%2==0)?32'h55aa55aa:(32'(tid)*32'h01010101)^32'(n);
      w.strb=4'((n+tid)%16);w.last=n==int'(tx[tid].len);
      wq.push_back(w);bfm_w(w.data,w.strb,w.last);
    end
    while(master_wbeats!=slave_wbeats || wq.size()!=0)@(negedge clk);
  endtask

  task automatic read_beat(input int tid,input int beat);
    rsp_t e;
    await_master(tid);
    e.tid=tid;e.data=beat%2==0?32'h12345678:32'(tid*101+beat);
    e.resp=2'((tid+beat)%4);e.last=beat==int'(tx[tid].len);
    rq[tx[tid].sid].push_back(e);response_code=e.resp;
    bfm_rbeat(tx[tid].mid,e.data,e.last);
  endtask

  task automatic complete_tx(input int tid,input int first=0);
    rsp_t e;
    await_master(tid);
    if(tx[tid].wr)begin
      e='0;e.tid=tid;e.resp=2'(tid%4);e.last=1;
      bq[tx[tid].sid].push_back(e);response_code=e.resp;
      bfm_bbeat(tx[tid].mid);
    end else for(int n=first;n<=int'(tx[tid].len);n++)read_beat(tid,n);
    while(!tx[tid].completed)@(negedge clk);
  endtask

  // Random backpressure is driven only on falling edges, with one writer per
  // signal. It is disabled for A4 so no unrelated stall qualifies that bound.
  bit random_stalls=0;
  bit hold_responses=0;
  int rng_state=32'h7a19c3;
  always @(negedge clk)begin
    rng_state=(rng_state<<1)^((rng_state<0)?32'h04c11db7:0);
    m_awready= !random_stalls || (rng_state&3)!=0;
    m_arready= !random_stalls || (rng_state&12)!=0;
    m_wready = !random_stalls || (rng_state&48)!=0;
    s_rready = !hold_responses && (!random_stalls || (rng_state&192)!=0);
    s_bready = !hold_responses && (!random_stalls || (rng_state&768)!=0);
  end

  task automatic drain_check;
    // D4 has no latency limit: wait for all known transactions, then allow a
    // quiet observation interval for unsolicited/duplicate outputs.
    for(int t=1;t<next_tid;t++)if(tx[t].accepted)begin
      while(!tx[t].completed || !tx[t].master_seen)@(negedge clk);
    end
    repeat(12)@(negedge clk);
    if(master_rbeats!=slave_rbeats||master_bbeats!=slave_bbeats||master_wbeats!=slave_wbeats||wq.size()!=0)
      fail("D4","input/output transfer totals differ");
  endtask

  // Full table with two transactions per ID: completion of the first must
  // not free the ID; a partial read beat or stalled final response must not
  // free it either. The last transaction frees it on the slave response edge.
  task automatic boundary_phase(input bit wr);
    int ids[4][2];int fresh;bit accepted;
    for(int round_no=0;round_no<2;round_no++)begin
      for(int i=0;i<4;i++)begin
        request_tx(wr,2+i*3,round_no==1?3:0,ids[i][round_no]);
        if(wr)send_write(ids[i][round_no]);
      end
    end
    blocked(wr,15,"A3");blocked(wr,2,"A5");
    complete_tx(ids[0][0]);
    blocked(wr,15,"A3");
    if(!wr)begin
      read_beat(ids[0][1],0);blocked(0,15,"A3");
      read_beat(ids[0][1],1);read_beat(ids[0][1],2);
    end
    prepare(wr,15,1,fresh);
    watch_active=1;watch_wr=wr;watch_sid=2;watch_tid=fresh;retire_cycle=-1;
    // Offer the new request before allowing the final response to transfer.
    fork
      begin offer(wr,fresh,1000000,accepted);end
      begin
        @(posedge clk);hold_responses=1;
        fork
          begin complete_tx(ids[0][1],wr?0:3);end
          begin
            // No fixed response-latency assumption. Hold until it is visible.
            if(wr)begin while(!s_bvalid)@(negedge clk);end
            else begin while(!s_rvalid)@(negedge clk);end
            repeat(5)@(posedge clk);
            hold_responses=0;
          end
        join
      end
    join
    if(!accepted)fail("A4","retired slot never became reusable");
    repeat(3)@(negedge clk);
    if(wr)send_write(fresh);
    // Deliberately complete different IDs out of submission order.
    for(int i=3;i>=1;i--)begin complete_tx(ids[i][0]);complete_tx(ids[i][1]);end
    complete_tx(fresh);drain_check();
  endtask

  initial begin : stimulus
    automatic int r,w;
    automatic int reads[4],writes[4];
    automatic rsp_t reset_r;
    automatic bit took_r;
    s_awid=0;s_awaddr=0;s_awlen=0;s_awvalid=0;
    s_arid=0;s_araddr=0;s_arlen=0;s_arvalid=0;
    s_wdata=0;s_wstrb=0;s_wlast=0;s_wvalid=0;
    m_bid=0;m_bresp=0;m_bvalid=0;
    m_rid=0;m_rdata=0;m_rresp=0;m_rlast=0;m_rvalid=0;
    response_code=0;
    bfm_reset();
    boundary_phase(0);boundary_phase(1);
    // A1/A5: two reads AND two writes with the same slave ID are legal.
    // Their per-direction depths must not accidentally be summed together.
    for(int i=0;i<2;i++)begin
      request_tx(0,9,i+1,reads[i]);
      request_tx(1,9,i+1,writes[i]);send_write(writes[i]);
    end
    blocked(0,9,"A5");blocked(1,9,"A5");
    for(int i=0;i<2;i++)begin complete_tx(reads[i]);complete_tx(writes[i]);end
    drain_check();
    random_stalls=1;
    // Same slave IDs simultaneously active in both directions. This exercises
    // separate counts without assuming separate physical allocation tables.
    for(int batch=0;batch<12;batch++)begin
      for(int i=0;i<4;i++)begin
        request_tx(0,(batch+i*3)%16,(batch+i)%5,reads[i]);
        request_tx(1,(batch+i*3)%16,(batch+2*i)%4,writes[i]);send_write(writes[i]);
      end
      for(int i=3;i>=0;i--)begin complete_tx(reads[i]);complete_tx(writes[(i+2)%4]);end
    end
    drain_check();random_stalls=0;
    // Reset with accepted transactions outstanding, and with inputs offered
    // throughout reset. READY during reset is deliberately not constrained.
    request_tx(0,3,3,r);request_tx(1,3,2,w);send_write(w);
    await_master(r);await_master(w);
    // Leave genuine responses stalled at the upstream interface when reset
    // arrives, covering designs that buffer responses internally.
    @(posedge clk);hold_responses=1;
    @(negedge clk);
    reset_r='0;reset_r.tid=r;reset_r.data=32'hdecafbad;
    reset_r.resp=2;reset_r.last=0;rq[3].push_back(reset_r);
    m_rid=tx[r].mid;m_rdata=reset_r.data;m_rresp=reset_r.resp;m_rlast=0;m_rvalid=1;
    took_r=0;
    // Stop downstream VALID after exactly one handshake. Combinational
    // forwarding may present upstream responses without accepting them yet.
    forever begin
      @(posedge clk);
      if(m_rvalid&&m_rready)took_r=1;
      @(negedge clk);
      if(took_r)m_rvalid=0;
      if(s_rvalid)break;
    end
    rst_n=0;m_rvalid=0;m_bvalid=0;
    s_arvalid=1;s_arid=14;s_araddr=32'hdead0000;s_arlen=0;
    s_awvalid=1;s_awid=14;s_awaddr=32'hbeef0000;s_awlen=0;
    s_wvalid=1;s_wdata=32'haabbccdd;s_wstrb=15;s_wlast=1;
    repeat(5)@(posedge clk);
    hold_responses=0;
    @(negedge clk);s_arvalid=0;s_awvalid=0;s_wvalid=0;rst_n=1;
    repeat(12)@(negedge clk);
    boundary_phase(0);boundary_phase(1);
    drain_check();
    if(!ended)begin ended=1;$display("RESULT: PASS");$finish;end
  end

  // G1: unconditional termination, including a DUT that refuses all requests.
  initial begin
    #4_000_000;
    fail("D4","watchdog: no forward progress (G1)");
  end
endmodule
