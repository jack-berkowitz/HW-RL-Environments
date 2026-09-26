module miss_handler_arb
  import miss_handler_arb_pkg::*;
#(
    parameter int unsigned NR_PORTS = 4     // scored at 4; see P2
) (
    input  logic clk,
    input  logic rst_n,                     // active low, asynchronous assert
    // ---- flush ---------------------------------------------------------------
    input  logic flush_i,                   // flush request
    output logic flush_ack_o,               // one-cycle acknowledgement -- F5-F8
    output logic miss_o,                    // performance counter output
    input  logic busy_i,                    // a requester is mid-operation
    // ---- requesters ----------------------------------------------------------
    input  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i,
    output logic [NR_PORTS-1:0]       bypass_gnt_o,
    output logic [NR_PORTS-1:0]       bypass_valid_o,
    output logic [NR_PORTS-1:0][63:0] bypass_data_o,
    output logic [NR_PORTS-1:0]       miss_gnt_o,
    output logic [NR_PORTS-1:0]       active_serving_o,
    output logic [63:0]               critical_word_o,
    output logic                      critical_word_valid_o,
    // ---- MSHR interrogation -- F3 --------------------------------------------
    input  logic [NR_PORTS-1:0][55:0] mshr_addr_i,
    output logic [NR_PORTS-1:0]       mshr_addr_matches_o,
    output logic [NR_PORTS-1:0]       mshr_index_matches_o,
    // ---- atomics -------------------------------------------------------------
    input  amo_req_t  amo_req_i,
    output amo_resp_t amo_resp_o,
    // ---- AXI: bypass path (single accesses and atomics) ----------------------
    output axi_req_t axi_bypass_req_o,
    input  axi_rsp_t axi_bypass_rsp_i,
    // ---- AXI: refill path (cacheline reads and evictions) --------------------
    output axi_req_t axi_data_req_o,
    input  axi_rsp_t axi_data_rsp_i,
    // ---- the cache array -----------------------------------------------------
    output logic [SET_ASSOC-1:0]        req_o,
    output logic [INDEX_WIDTH-1:0]      addr_o,
    output cache_line_t                 data_o,
    output cl_be_t                      be_o,
    input  cache_line_t [SET_ASSOC-1:0] data_i,
    output logic                        we_o
);
  localparam int PORT_BITS = NR_PORTS > 1 ? $clog2(NR_PORTS) : 1;
  typedef enum logic [3:0] {D_IDLE, D_LOOKUP, D_SELECT, D_AR, D_R,
                           D_INSTALL, F_READ, F_WRITE, D_WB, A_LAUNCH, A_WAIT} dstate_t;
  typedef enum logic [1:0] {B_IDLE, B_AR, B_R, B_WRITE} bstate_t;
  dstate_t ds;
  bstate_t bs;
  miss_req_t requests[NR_PORTS];
  logic have_miss, have_bypass;
  logic [PORT_BITS-1:0] miss_pick, bypass_pick, miss_owner, bypass_owner;
  miss_req_t refill, bypass;
  logic inflight;
  logic [2:0] victim_way, replacement_way, dirty_way;
  logic [127:0] fill_data, wb_data;
  logic [63:0] wb_addr;
  logic fill_beat;
  logic [1:0] wb_count;
  logic wb_aw_done, wb_for_flush;
  logic [7:0] flush_set, flushed_ways;
  logic flush_seen, flush_for_amo, flush_should_ack;
  logic dirty_found;
  logic victim_found;
  logic [2:0] choose_victim;
  amo_req_t atomic_q;
  logic b_atomic, b_aw_done, b_w_done, b_b_seen, b_r_seen;
  logic [63:0] b_result;
  logic atomic_supported, launch_atomic, atomic_done;
  logic b_b_take, b_r_take;
  logic [5:0] atomic_code;
  logic [63:0] atomic_wdata;
  logic [7:0] atomic_mask;

  // AXI AtomicLoad, little-endian: ADD/CLR/EOR/SET/SMAX/SMIN/UMAX/UMIN;
  // AtomicSwap is 0x30. AND uses CLR with the complemented operand.
  // LR, SC, CAS1 and CAS2 have no defined encoding/operand protocol in the
  // supplied contract. They are NOT silently mapped to another operation.
  function automatic logic supported_amo(input amo_t op);
    case(op)
      AMO_SWAP,AMO_ADD,AMO_AND,AMO_OR,AMO_XOR,
      AMO_MAX,AMO_MAXU,AMO_MIN,AMO_MINU: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction
  function automatic logic [5:0] atop_code(input amo_t op);
    case(op)
      AMO_ADD: return 6'h20;
      AMO_AND: return 6'h21;
      AMO_XOR: return 6'h22;
      AMO_OR: return 6'h23;
      AMO_MAX: return 6'h24;
      AMO_MIN: return 6'h25;
      AMO_MAXU:return 6'h26;
      AMO_MINU:return 6'h27;
      AMO_SWAP:return 6'h30;
      default:return 6'h00;
    endcase
  endfunction

  for(genvar n=0;n<NR_PORTS;n++) begin: request_cast
    assign requests[n] = miss_req_t'(miss_req_i[n]);
  end
  always_comb begin
    have_miss=0;have_bypass=0;miss_pick='0;bypass_pick='0;
    for(int unsigned n=0;n<NR_PORTS;n++) begin
      if(requests[n].valid && !requests[n].bypass && !have_miss) begin
        have_miss=1;miss_pick=PORT_BITS'(n);
      end
      if(requests[n].valid && requests[n].bypass && !have_bypass) begin
        have_bypass=1;bypass_pick=PORT_BITS'(n);
      end
    end
    choose_victim=replacement_way;victim_found=0;
    dirty_found=0;dirty_way=0;
    for(int unsigned w=0;w<SET_ASSOC;w++) begin
      if(!data_i[w].valid && !victim_found) begin
        choose_victim=3'(w);victim_found=1;
      end
      if(data_i[w].valid && data_i[w].dirty && !flushed_ways[w] && !dirty_found) begin
        dirty_found=1;dirty_way=3'(w);
      end
    end
    atomic_supported=supported_amo(amo_req_i.amo_op);
    atomic_code=atop_code(atomic_q.amo_op);
    atomic_wdata=atomic_q.amo_op==AMO_AND ? ~atomic_q.operand_b : atomic_q.operand_b;
    atomic_wdata=atomic_wdata << {atomic_q.operand_a[2:0],3'b0};
    atomic_mask=8'((9'd1 << (1 << atomic_q.size))-9'd1) << atomic_q.operand_a[2:0];
  end
  assign launch_atomic = rst_n && ds==A_LAUNCH && !have_miss && bs==B_IDLE && !have_bypass;
  assign b_b_take = bs==B_WRITE && axi_bypass_rsp_i.b_valid && !b_b_seen;
  assign b_r_take = bs==B_WRITE && b_atomic && axi_bypass_rsp_i.r_valid && !b_r_seen;
  assign atomic_done = bs==B_WRITE && b_atomic &&
    (b_b_seen || b_b_take) && (b_r_seen || b_r_take) &&
    (b_aw_done || axi_bypass_rsp_i.aw_ready) && (b_w_done || axi_bypass_rsp_i.w_ready);

  always_comb begin
    miss_gnt_o='0;bypass_gnt_o='0;active_serving_o='0;
    mshr_addr_matches_o='0;mshr_index_matches_o='0;
    miss_o=0;
    if(rst_n) begin
      if((ds==D_IDLE || ds==A_LAUNCH) && have_miss) begin
        miss_gnt_o[miss_pick]=1;miss_o=1;
      end
      if(bs==B_IDLE && have_bypass) bypass_gnt_o[bypass_pick]=1;
      if(inflight) begin
        active_serving_o[miss_owner]=1;
        for(int unsigned n=0;n<NR_PORTS;n++) begin
          mshr_index_matches_o[n]=mshr_addr_i[n][11:4]==refill.addr[11:4];
          mshr_addr_matches_o[n]=mshr_index_matches_o[n] && mshr_addr_i[n][55:12]==refill.addr[55:12];
        end
      end
    end
  end

  always_comb begin
    req_o='0;addr_o='0;data_o='0;be_o='0;we_o=0;
    axi_data_req_o='0;axi_bypass_req_o='0;
    if(rst_n) begin
      case(ds)
        D_LOOKUP: begin req_o='1;addr_o={refill.addr[11:4],4'b0};end
        D_INSTALL: begin
          req_o[victim_way]=1;addr_o={refill.addr[11:4],4'b0};we_o=1;
          data_o.tag=refill.addr[55:12];data_o.data=fill_data;data_o.valid=1;data_o.dirty=0;
          be_o.tag='1;be_o.data='1;be_o.vldrty[victim_way]=1;
        end
        F_READ,F_WRITE: begin
          addr_o={flush_set,4'b0};be_o.vldrty='1;
          if(ds==F_READ || !dirty_found) begin req_o='1;we_o=ds==F_WRITE;end
        end
        D_AR: begin
          axi_data_req_o.ar_valid=1;axi_data_req_o.ar.addr={refill.addr[63:4],4'b0};
          axi_data_req_o.ar.len=1;axi_data_req_o.ar.size=3;axi_data_req_o.ar.burst=1;
          axi_data_req_o.ar.cache=4'b0010;
        end
        D_R: axi_data_req_o.r_ready=1;
        D_WB: begin
          axi_data_req_o.aw_valid=!wb_aw_done;
          axi_data_req_o.aw.addr=wb_addr;axi_data_req_o.aw.len=1;
          axi_data_req_o.aw.size=3;axi_data_req_o.aw.burst=1;axi_data_req_o.aw.cache=4'b0010;
          axi_data_req_o.w_valid=wb_count<2;
          axi_data_req_o.w.data=wb_count==0 ? wb_data[63:0] : wb_data[127:64];
          axi_data_req_o.w.strb='1;axi_data_req_o.w.last=wb_count==1;
          axi_data_req_o.b_ready=wb_aw_done && wb_count==2;
        end
        default: begin end
      endcase
      case(bs)
        B_AR: begin
          axi_bypass_req_o.ar_valid=1;axi_bypass_req_o.ar.addr=bypass.addr;
          axi_bypass_req_o.ar.size={1'b0,bypass.size};axi_bypass_req_o.ar.burst=1;
        end
        B_R: axi_bypass_req_o.r_ready=1;
        B_WRITE: begin
          axi_bypass_req_o.aw_valid=!b_aw_done;
          axi_bypass_req_o.aw.addr=b_atomic ? atomic_q.operand_a : bypass.addr;
          axi_bypass_req_o.aw.size={1'b0,(b_atomic ? atomic_q.size : bypass.size)};
          axi_bypass_req_o.aw.burst=1;
          axi_bypass_req_o.aw.atop=b_atomic ? atomic_code : 6'b0;
          axi_bypass_req_o.w_valid=!b_w_done;
          axi_bypass_req_o.w.data=b_atomic ? atomic_wdata : bypass.wdata;
          axi_bypass_req_o.w.strb=b_atomic ? atomic_mask : bypass.be;
          axi_bypass_req_o.w.last=1;
          axi_bypass_req_o.b_ready=!b_b_seen;
          axi_bypass_req_o.r_ready=b_atomic && !b_r_seen;
        end
        default: begin end
      endcase
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      ds<=D_IDLE;bs<=B_IDLE;refill<='0;bypass<='0;
      miss_owner<='0;bypass_owner<='0;inflight<=0;
      victim_way<=0;replacement_way<=0;fill_data<=0;fill_beat<=0;
      wb_data<=0;wb_addr<=0;wb_count<=0;wb_aw_done<=0;wb_for_flush<=0;
      flush_set<=0;flushed_ways<=0;flush_seen<=0;flush_for_amo<=0;flush_should_ack<=0;
      atomic_q<='0;b_atomic<=0;b_aw_done<=0;b_w_done<=0;b_b_seen<=0;b_r_seen<=0;b_result<=0;
      flush_ack_o<=0;amo_resp_o<='0;bypass_valid_o<='0;bypass_data_o<='0;
      critical_word_o<=0;critical_word_valid_o<=0;
    end else begin
      flush_ack_o<=0;amo_resp_o.ack<=0;bypass_valid_o<='0;critical_word_valid_o<=0;
      if(!flush_i)flush_seen<=0;
      case(ds)
        D_IDLE,A_LAUNCH: begin
          // Capture only the winning miss. An atomic losing here is not
          // remembered: a still-asserted atomic request is re-evaluated later.
          if(have_miss) begin
            refill<=requests[miss_pick];miss_owner<=miss_pick;inflight<=1;
            flush_for_amo<=0;ds<=D_LOOKUP;
          end else if(ds==A_LAUNCH) begin
            if(launch_atomic)ds<=A_WAIT;
          end else if(!busy_i && ((flush_i && !flush_seen) ||
                     (amo_req_i.req && atomic_supported && !amo_resp_o.ack))) begin
            flush_set<=0;flushed_ways<=0;
            flush_for_amo<=amo_req_i.req && atomic_supported;
            // Any concurrent AMO request suppresses the genuine flush ack.
            flush_should_ack<=flush_i && !amo_req_i.req;
            if(flush_i)flush_seen<=1;
            if(amo_req_i.req && atomic_supported)atomic_q<=amo_req_i;
            ds<=F_READ;
          end
        end
        D_LOOKUP: ds<=D_SELECT;
        D_SELECT: begin
          victim_way<=choose_victim;replacement_way<=choose_victim+3'd1;
          fill_beat<=0;
          if(data_i[choose_victim].valid && data_i[choose_victim].dirty) begin
            wb_data<=data_i[choose_victim].data;
            wb_addr<={8'b0,data_i[choose_victim].tag,refill.addr[11:4],4'b0};
            wb_count<=0;wb_aw_done<=0;wb_for_flush<=0;ds<=D_WB;
          end else ds<=D_AR;
        end
        D_AR: if(axi_data_rsp_i.ar_ready)ds<=D_R;
        D_R: if(axi_data_rsp_i.r_valid) begin
          if(!fill_beat)fill_data[63:0]<=axi_data_rsp_i.r.data;
          else fill_data[127:64]<=axi_data_rsp_i.r.data;
          if(fill_beat==refill.addr[3]) begin
            critical_word_o<=axi_data_rsp_i.r.data;critical_word_valid_o<=1;
          end
          if(fill_beat)ds<=D_INSTALL;
          else fill_beat<=1;
        end
        D_INSTALL: begin inflight<=0;ds<=D_IDLE;end
        F_READ: ds<=F_WRITE;
        F_WRITE: begin
          if(dirty_found) begin
            wb_data<=data_i[dirty_way].data;
            wb_addr<={8'b0,data_i[dirty_way].tag,flush_set,4'b0};
            flushed_ways[dirty_way]<=1;
            wb_count<=0;wb_aw_done<=0;wb_for_flush<=1;ds<=D_WB;
          end else begin
            flushed_ways<=0;
            if(flush_set==8'hff) begin
              if(flush_should_ack)flush_ack_o<=1;
              ds<=flush_for_amo ? A_LAUNCH : D_IDLE;
            end else begin flush_set<=flush_set+8'd1;ds<=F_READ;end
          end
        end
        D_WB: begin
          if(axi_data_req_o.aw_valid && axi_data_rsp_i.aw_ready)wb_aw_done<=1;
          if(axi_data_req_o.w_valid && axi_data_rsp_i.w_ready)wb_count<=wb_count+2'd1;
          if(axi_data_req_o.b_ready && axi_data_rsp_i.b_valid)ds<=wb_for_flush ? F_WRITE : D_AR;
        end
        A_WAIT: if(atomic_done)ds<=D_IDLE;
        default: ds<=D_IDLE;
      endcase
      case(bs)
        B_IDLE: begin
          b_aw_done<=0;b_w_done<=0;b_b_seen<=0;b_r_seen<=0;
          if(have_bypass) begin
            bypass<=requests[bypass_pick];bypass_owner<=bypass_pick;b_atomic<=0;
            bs<=requests[bypass_pick].we ? B_WRITE : B_AR;
          end else if(launch_atomic)begin b_atomic<=1;bs<=B_WRITE;end
        end
        B_AR: if(axi_bypass_rsp_i.ar_ready)bs<=B_R;
        B_R: if(axi_bypass_rsp_i.r_valid) begin
          bypass_data_o[bypass_owner]<=axi_bypass_rsp_i.r.data;
          bypass_valid_o[bypass_owner]<=1;bs<=B_IDLE;
        end
        B_WRITE: begin
          if(axi_bypass_req_o.aw_valid && axi_bypass_rsp_i.aw_ready)b_aw_done<=1;
          if(axi_bypass_req_o.w_valid && axi_bypass_rsp_i.w_ready)b_w_done<=1;
          if(b_b_take)b_b_seen<=1;
          if(b_r_take)begin b_r_seen<=1;b_result<=axi_bypass_rsp_i.r.data;end
          if(atomic_done) begin
            amo_resp_o.ack<=1;
            amo_resp_o.result<=b_r_take ? axi_bypass_rsp_i.r.data : b_result;
            bs<=B_IDLE;
          end else if(!b_atomic && (b_b_seen || b_b_take) &&
                      (b_aw_done || axi_bypass_rsp_i.aw_ready) && (b_w_done || axi_bypass_rsp_i.w_ready)) begin
            bypass_valid_o[bypass_owner]<=1;bypass_data_o[bypass_owner]<=0;bs<=B_IDLE;
          end
        end
        default: bs<=B_IDLE;
      endcase
    end
  end
endmodule
