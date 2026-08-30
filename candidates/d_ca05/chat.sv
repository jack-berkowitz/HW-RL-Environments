module miss_handler_arb
  import miss_handler_arb_pkg::*;
#(
  parameter int unsigned NR_PORTS = 4
) (
  input  logic clk,
  input  logic rst_n,

  input  logic flush_i,
  output logic flush_ack_o,
  output logic miss_o,
  input  logic busy_i,

  input  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i,
  output logic [NR_PORTS-1:0]       bypass_gnt_o,
  output logic [NR_PORTS-1:0]       bypass_valid_o,
  output logic [NR_PORTS-1:0][63:0] bypass_data_o,
  output logic [NR_PORTS-1:0]       miss_gnt_o,
  output logic [NR_PORTS-1:0]       active_serving_o,
  output logic [63:0]               critical_word_o,
  output logic                      critical_word_valid_o,

  input  logic [NR_PORTS-1:0][55:0] mshr_addr_i,
  output logic [NR_PORTS-1:0]       mshr_addr_matches_o,
  output logic [NR_PORTS-1:0]       mshr_index_matches_o,

  input  amo_req_t  amo_req_i,
  output amo_resp_t amo_resp_o,

  output axi_req_t axi_bypass_req_o,
  input  axi_rsp_t axi_bypass_rsp_i,

  output axi_req_t axi_data_req_o,
  input  axi_rsp_t axi_data_rsp_i,

  output logic [SET_ASSOC-1:0]          req_o,
  output logic [INDEX_WIDTH-1:0]        addr_o,
  output cache_line_t                   data_o,
  output cl_be_t                        be_o,
  input  cache_line_t [SET_ASSOC-1:0]  data_i,
  output logic                          we_o
);

  localparam int unsigned PORT_W =
    (NR_PORTS <= 1) ? 1 : $clog2(NR_PORTS);

  localparam logic [AXI_ID_W-1:0] DATA_AXI_ID = 4'h7;
  localparam logic [AXI_ID_W-1:0] AMO_AXI_ID  = 4'hc;

  localparam int unsigned FLUSH_STEP =
    (1 << OFFSET_WIDTH);


  typedef struct packed {
    logic              valid;
    logic [PORT_W-1:0] src;
    logic [63:0]       addr;
    logic [7:0]        be;
    logic [1:0]        size;
    logic              we;
    logic [63:0]       wdata;
  } mshr_reg_t;


  typedef enum logic [3:0] {
    MH_IDLE,
    MH_MISS_LOOKUP,
    MH_MISS_SELECT,
    MH_EVICT_SEND,
    MH_EVICT_WAIT_B,
    MH_REFILL_AR,
    MH_REFILL_R,
    MH_REFILL_COMMIT,
    MH_FLUSH_READ,
    MH_FLUSH_WRITE,
    MH_AMO_WAIT
  } mh_state_t;


  typedef enum logic [2:0] {
    BP_IDLE,
    BP_READ_AR,
    BP_READ_R,
    BP_WRITE_SEND,
    BP_WRITE_B,
    BP_AMO_SEND,
    BP_AMO_RESP
  } bp_state_t;


  miss_req_t miss_req_dec [NR_PORTS-1:0];

  mh_state_t mh_state_q;
  mh_state_t mh_state_d;

  bp_state_t bp_state_q;
  bp_state_t bp_state_d;

  mshr_reg_t mshr_q;
  mshr_reg_t mshr_d;

  logic [SET_ASSOC-1:0] victim_way_q;
  logic [SET_ASSOC-1:0] victim_way_d;

  cache_line_t evict_line_q;
  cache_line_t evict_line_d;

  logic [127:0] refill_line_q;
  logic [127:0] refill_line_d;

  logic refill_beat_q;
  logic refill_beat_d;

  logic data_aw_done_q;
  logic data_aw_done_d;

  logic [1:0] data_w_count_q;
  logic [1:0] data_w_count_d;

  logic [INDEX_WIDTH-1:0] flush_addr_q;
  logic [INDEX_WIDTH-1:0] flush_addr_d;

  logic serve_amo_q;
  logic serve_amo_d;

  amo_t amo_op_q;
  amo_t amo_op_d;

  logic [1:0] amo_size_q;
  logic [1:0] amo_size_d;

  logic [63:0] amo_addr_q;
  logic [63:0] amo_addr_d;

  logic [63:0] amo_operand_q;
  logic [63:0] amo_operand_d;

  logic [PORT_W-1:0] bp_src_q;
  logic [PORT_W-1:0] bp_src_d;

  miss_req_t bp_req_q;
  miss_req_t bp_req_d;

  logic bp_aw_done_q;
  logic bp_aw_done_d;

  logic bp_w_done_q;
  logic bp_w_done_d;

  logic bp_amo_b_seen_q;
  logic bp_amo_b_seen_d;

  logic bp_amo_r_seen_q;
  logic bp_amo_r_seen_d;

  logic [63:0] bp_amo_rdata_q;
  logic [63:0] bp_amo_rdata_d;

  logic        amo_bus_done;
  logic [63:0] amo_bus_result;


  genvar gi;

  generate
    for (
      gi = 0;
      gi < NR_PORTS;
      gi = gi + 1
    ) begin : g_decode_req

      assign miss_req_dec[gi] =
        miss_req_t'(miss_req_i[gi]);

    end
  endgenerate


  function automatic logic [SET_ASSOC-1:0] first_onehot(
    input logic [SET_ASSOC-1:0] mask
  );

    logic [SET_ASSOC-1:0] ret;
    integer i;

    begin
      ret = '0;

      for (
        i = 0;
        i < SET_ASSOC;
        i = i + 1
      ) begin

        if (
          (ret == '0) &&
          mask[i]
        )
          ret[i] = 1'b1;

      end

      first_onehot = ret;
    end

  endfunction


  function automatic logic [2:0] onehot_index(
    input logic [SET_ASSOC-1:0] mask
  );

    logic [2:0] ret;
    integer i;

    begin
      ret = 3'd0;

      for (
        i = 0;
        i < SET_ASSOC;
        i = i + 1
      ) begin

        if (mask[i])
          ret = i;

      end

      onehot_index = ret;
    end

  endfunction


  function automatic logic [5:0] amo_to_atop(
    input amo_t op
  );

    begin

      case (op)

        AMO_SWAP:
          amo_to_atop = 6'b110000;

        AMO_ADD:
          amo_to_atop = 6'b100000;

        AMO_AND:
          amo_to_atop = 6'b100001;

        AMO_XOR:
          amo_to_atop = 6'b100010;

        AMO_OR:
          amo_to_atop = 6'b100011;

        AMO_MAX:
          amo_to_atop = 6'b100100;

        AMO_MIN:
          amo_to_atop = 6'b100101;

        AMO_MAXU:
          amo_to_atop = 6'b100110;

        AMO_MINU:
          amo_to_atop = 6'b100111;

        AMO_CAS1:
          amo_to_atop = 6'b110001;

        AMO_CAS2:
          amo_to_atop = 6'b110001;

        AMO_LR:
          amo_to_atop = 6'b110000;

        AMO_SC:
          amo_to_atop = 6'b110000;

        default:
          amo_to_atop = 6'b000000;

      endcase

    end

  endfunction


  function automatic logic [63:0] amo_write_data(
    input amo_t        op,
    input logic [1:0]  size,
    input logic [63:0] addr,
    input logic [63:0] operand
  );

    logic [63:0] v;

    begin

      if (op == AMO_AND)
        v = ~operand;
      else
        v = operand;

      if (
        (size == 2'b10) &&
        addr[2]
      )
        amo_write_data = {
          v[31:0],
          32'b0
        };
      else
        amo_write_data = v;

    end

  endfunction


  function automatic logic [7:0] amo_write_strb(
    input logic [1:0]  size,
    input logic [63:0] addr
  );

    begin

      if (size == 2'b11)
        amo_write_strb = 8'hff;

      else if (addr[2])
        amo_write_strb = 8'hf0;

      else
        amo_write_strb = 8'h0f;

    end

  endfunction


  function automatic logic [63:0] amo_result_align(
    input logic [1:0]  size,
    input logic [63:0] addr,
    input logic [63:0] raw
  );

    logic [31:0] half;

    begin

      if (size == 2'b10) begin

        if (addr[2])
          half = raw[63:32];
        else
          half = raw[31:0];

        amo_result_align = {
          {32{half[31]}},
          half
        };

      end else begin

        amo_result_align = raw;

      end

    end

  endfunction


  // --------------------------------------------------------------------------
  // MSHR matching.
  //
  // Address and index matches overlap intentionally.
  // The currently-served requester is not excluded.
  // --------------------------------------------------------------------------

  always_comb begin

    integer i;

    mshr_addr_matches_o  = '0;
    mshr_index_matches_o = '0;

    for (
      i = 0;
      i < NR_PORTS;
      i = i + 1
    ) begin

      if (
        mshr_q.valid &&
        (
          mshr_addr_i[i][55:4] ==
          mshr_q.addr[55:4]
        )
      )
        mshr_addr_matches_o[i] =
          1'b1;


      if (
        mshr_q.valid &&
        (
          mshr_addr_i[i][11:4] ==
          mshr_q.addr[11:4]
        )
      )
        mshr_index_matches_o[i] =
          1'b1;

    end

  end


  // --------------------------------------------------------------------------
  // Main miss / flush / atomic sequencer.
  // --------------------------------------------------------------------------

  always_comb begin

    logic [SET_ASSOC-1:0] valid_mask;

    integer i;
    integer w;
    integer b;

    logic [SET_ASSOC-1:0] invalid_mask;

    logic [SET_ASSOC-1:0] chosen_way;

    logic [2:0] chosen_idx;

    logic refill_found;

    logic [127:0] commit_line;

    logic [63:0] evict_addr;


    mh_state_d      = mh_state_q;
    mshr_d          = mshr_q;

    victim_way_d    = victim_way_q;
    evict_line_d    = evict_line_q;

    refill_line_d   = refill_line_q;
    refill_beat_d   = refill_beat_q;

    data_aw_done_d  = data_aw_done_q;
    data_w_count_d  = data_w_count_q;

    flush_addr_d    = flush_addr_q;

    serve_amo_d     = serve_amo_q;

    amo_op_d        = amo_op_q;
    amo_size_d      = amo_size_q;
    amo_addr_d      = amo_addr_q;
    amo_operand_d   = amo_operand_q;


    flush_ack_o =
      1'b0;

    miss_o =
      1'b0;

    miss_gnt_o =
      '0;

    active_serving_o =
      '0;

    critical_word_o =
      axi_data_rsp_i.r.data;

    critical_word_valid_o =
      1'b0;

    amo_resp_o =
      '0;

    axi_data_req_o =
      '0;

    req_o =
      '0;

    addr_o =
      '0;

    data_o =
      '0;

    be_o =
      '0;

    we_o =
      1'b0;


    valid_mask   = '0;
    invalid_mask = '0;
    chosen_way   = '0;

    chosen_idx =
      3'd0;

    refill_found =
      1'b0;

    commit_line =
      refill_line_q;

    evict_addr =
      '0;


    if (mshr_q.valid)
      active_serving_o[mshr_q.src] =
        1'b1;


    for (
      w = 0;
      w < SET_ASSOC;
      w = w + 1
    )
      valid_mask[w] =
        data_i[w].valid;


    invalid_mask =
      ~valid_mask;


    case (mh_state_q)

      // ----------------------------------------------------------------------
      // Idle.
      // ----------------------------------------------------------------------

      MH_IDLE: begin

        serve_amo_d =
          1'b0;


        /*
         * Atomic request.
         *
         * An atomic first performs the complete cache flush.
         */
        if (
          amo_req_i.req &&
          !busy_i
        ) begin

          mh_state_d =
            MH_FLUSH_READ;

          flush_addr_d =
            '0;

          serve_amo_d =
            1'b1;

          amo_op_d =
            amo_req_i.amo_op;

          amo_size_d =
            amo_req_i.size;

          amo_addr_d =
            amo_req_i.operand_a;

          amo_operand_d =
            amo_req_i.operand_b;

        end


        /*
         * Genuine flush.
         *
         * If flush and AMO arrive together, the AMO's serve_amo
         * state remains asserted, which suppresses flush_ack_o.
         */
        if (
          flush_i &&
          !busy_i
        ) begin

          mh_state_d =
            MH_FLUSH_READ;

          flush_addr_d =
            '0;

          if (!amo_req_i.req)
            serve_amo_d =
              1'b0;

        end


        /*
         * Non-bypass cache miss has priority over atomic work.
         *
         * Lowest requester index wins.
         */
        refill_found =
          1'b0;


        for (
          i = 0;
          i < NR_PORTS;
          i = i + 1
        ) begin

          if (
            !refill_found &&
            miss_req_dec[i].valid &&
            !miss_req_dec[i].bypass
          ) begin

            refill_found =
              1'b1;

            mh_state_d =
              MH_MISS_LOOKUP;

            serve_amo_d =
              1'b0;

            mshr_d.valid =
              1'b1;

            mshr_d.src =
              i;

            mshr_d.addr = {
              8'b0,
              miss_req_dec[i].addr[55:0]
            };

            mshr_d.be =
              miss_req_dec[i].be;

            mshr_d.size =
              miss_req_dec[i].size;

            mshr_d.we =
              miss_req_dec[i].we;

            mshr_d.wdata =
              miss_req_dec[i].wdata;

          end

        end

      end


      // ----------------------------------------------------------------------
      // Cache lookup.
      // ----------------------------------------------------------------------

      MH_MISS_LOOKUP: begin

        req_o =
          '1;

        addr_o =
          mshr_q.addr[INDEX_WIDTH-1:0];

        miss_o =
          1'b1;

        mh_state_d =
          MH_MISS_SELECT;

      end


      // ----------------------------------------------------------------------
      // Pick replacement way.
      // ----------------------------------------------------------------------

      MH_MISS_SELECT: begin

        if (|invalid_mask)
          chosen_way =
            first_onehot(invalid_mask);

        else begin

          chosen_way =
            {{(SET_ASSOC-1){1'b0}}, 1'b1};

        end


        chosen_idx =
          onehot_index(chosen_way);

        victim_way_d =
          chosen_way;


        /*
         * If all ways are valid and the chosen victim is dirty,
         * evict it before refill.
         */
        if (
          (
            valid_mask ==
            {SET_ASSOC{1'b1}}
          ) &&
          data_i[chosen_idx].dirty
        ) begin

          evict_line_d =
            data_i[chosen_idx];

          data_aw_done_d =
            1'b0;

          data_w_count_d =
            2'd0;

          mh_state_d =
            MH_EVICT_SEND;

        end else begin

          mh_state_d =
            MH_REFILL_AR;

        end

      end


      // ----------------------------------------------------------------------
      // Dirty victim AXI write.
      // ----------------------------------------------------------------------

      MH_EVICT_SEND: begin

        evict_addr = {
          8'b0,
          evict_line_q.tag,
          mshr_q.addr[
            INDEX_WIDTH-1:
            OFFSET_WIDTH
          ],
          {OFFSET_WIDTH{1'b0}}
        };


        axi_data_req_o.aw.id =
          DATA_AXI_ID;

        axi_data_req_o.aw.addr =
          evict_addr;

        axi_data_req_o.aw.len =
          8'd1;

        axi_data_req_o.aw.size =
          3'd3;

        axi_data_req_o.aw.burst =
          2'b01;

        axi_data_req_o.aw.lock =
          1'b0;

        axi_data_req_o.aw.cache =
          4'b0010;

        axi_data_req_o.aw.prot =
          3'b000;

        axi_data_req_o.aw.qos =
          4'b0000;

        axi_data_req_o.aw.region =
          4'b0000;

        axi_data_req_o.aw.atop =
          6'b000000;

        axi_data_req_o.aw.user =
          '0;

        axi_data_req_o.aw_valid =
          !data_aw_done_q;


        axi_data_req_o.w.strb =
          8'hff;

        axi_data_req_o.w.user =
          '0;

        axi_data_req_o.w_valid =
          (data_w_count_q < 2);


        if (data_w_count_q == 0) begin

          axi_data_req_o.w.data =
            evict_line_q.data[63:0];

          axi_data_req_o.w.last =
            1'b0;

        end else begin

          axi_data_req_o.w.data =
            evict_line_q.data[127:64];

          axi_data_req_o.w.last =
            1'b1;

        end


        if (
          !data_aw_done_q &&
          axi_data_rsp_i.aw_ready
        )
          data_aw_done_d =
            1'b1;


        if (
          (data_w_count_q < 2) &&
          axi_data_rsp_i.w_ready
        )
          data_w_count_d =
            data_w_count_q + 1'b1;


        if (
          (data_aw_done_d == 1'b1) &&
          (data_w_count_d == 2)
        )
          mh_state_d =
            MH_EVICT_WAIT_B;

      end


      // ----------------------------------------------------------------------
      // Dirty eviction response.
      // ----------------------------------------------------------------------

      MH_EVICT_WAIT_B: begin

        axi_data_req_o.b_ready =
          1'b1;

        if (axi_data_rsp_i.b_valid)
          mh_state_d =
            MH_REFILL_AR;

      end


      // ----------------------------------------------------------------------
      // Refill address.
      // ----------------------------------------------------------------------

      MH_REFILL_AR: begin

        axi_data_req_o.ar.id =
          DATA_AXI_ID;

        axi_data_req_o.ar.addr = {
          mshr_q.addr[63:OFFSET_WIDTH],
          {OFFSET_WIDTH{1'b0}}
        };

        axi_data_req_o.ar.len =
          8'd1;

        axi_data_req_o.ar.size =
          3'd3;

        axi_data_req_o.ar.burst =
          2'b01;

        axi_data_req_o.ar.lock =
          1'b0;

        axi_data_req_o.ar.cache =
          4'b0010;

        axi_data_req_o.ar.prot =
          3'b000;

        axi_data_req_o.ar.qos =
          4'b0000;

        axi_data_req_o.ar.region =
          4'b0000;

        axi_data_req_o.ar.user =
          '0;

        axi_data_req_o.ar_valid =
          1'b1;


        if (axi_data_rsp_i.ar_ready) begin

          miss_gnt_o[mshr_q.src] =
            1'b1;

          refill_line_d =
            '0;

          refill_beat_d =
            1'b0;

          mh_state_d =
            MH_REFILL_R;

        end

      end


      // ----------------------------------------------------------------------
      // Refill data.
      // ----------------------------------------------------------------------

      MH_REFILL_R: begin

        axi_data_req_o.r_ready =
          1'b1;


        if (axi_data_rsp_i.r_valid) begin

          if (!refill_beat_q)
            refill_line_d[63:0] =
              axi_data_rsp_i.r.data;

          else
            refill_line_d[127:64] =
              axi_data_rsp_i.r.data;


          /*
           * The address bit selecting the requested 64-bit word
           * is bit 3 because the line is 16 bytes.
           */
          if (
            refill_beat_q ==
            mshr_q.addr[3]
          ) begin

            critical_word_o =
              axi_data_rsp_i.r.data;

            critical_word_valid_o =
              1'b1;

          end


          if (
            axi_data_rsp_i.r.last ||
            refill_beat_q
          ) begin

            mh_state_d =
              MH_REFILL_COMMIT;

          end else begin

            refill_beat_d =
              1'b1;

          end

        end

      end


      // ----------------------------------------------------------------------
      // Install refill into cache array.
      // ----------------------------------------------------------------------

      MH_REFILL_COMMIT: begin

        commit_line =
          refill_line_q;


        /*
         * Store miss: merge the requested bytes into the newly
         * fetched cache line before writing it to the array.
         */
        if (mshr_q.we) begin

          if (mshr_q.addr[3]) begin

            for (
              b = 0;
              b < 8;
              b = b + 1
            ) begin

              if (mshr_q.be[b])
                commit_line[
                  64 + b*8 +: 8
                ] =
                  mshr_q.wdata[
                    b*8 +: 8
                  ];

            end

          end else begin

            for (
              b = 0;
              b < 8;
              b = b + 1
            ) begin

              if (mshr_q.be[b])
                commit_line[
                  b*8 +: 8
                ] =
                  mshr_q.wdata[
                    b*8 +: 8
                  ];

            end

          end

        end


        req_o =
          victim_way_q;

        addr_o =
          mshr_q.addr[INDEX_WIDTH-1:0];

        we_o =
          1'b1;

        be_o =
          '1;

        be_o.vldrty =
          victim_way_q;


        data_o.tag =
          mshr_q.addr[55:12];

        data_o.data =
          commit_line;

        data_o.valid =
          1'b1;

        data_o.dirty =
          mshr_q.we;


        mshr_d.valid =
          1'b0;

        mh_state_d =
          MH_IDLE;

      end


      // ----------------------------------------------------------------------
      // Flush read phase.
      // ----------------------------------------------------------------------

      MH_FLUSH_READ: begin

        req_o =
          '1;

        addr_o =
          flush_addr_q;

        we_o =
          1'b0;

        mh_state_d =
          MH_FLUSH_WRITE;

      end


      // ----------------------------------------------------------------------
      // Flush write phase.
      // ----------------------------------------------------------------------

      MH_FLUSH_WRITE: begin

        /*
         * One invalidating write per set.
         *
         * The preceding read plus this write gives:
         *
         *   256 reads
         * + 256 writes
         * = 512 array requests
         */
        req_o =
          {{(SET_ASSOC-1){1'b0}}, 1'b1};

        addr_o =
          flush_addr_q;

        we_o =
          1'b1;

        be_o.vldrty =
          '1;

        data_o =
          '0;


        if (
          flush_addr_q[
            INDEX_WIDTH-1:
            OFFSET_WIDTH
          ] ==
          NUM_WORDS-1
        ) begin

          flush_addr_d =
            '0;


          if (serve_amo_q) begin

            /*
             * Atomic-induced flush.
             *
             * This includes the simultaneous flush+AMO case.
             * No flush acknowledgement is produced.
             */
            serve_amo_d =
              1'b0;

            mh_state_d =
              MH_AMO_WAIT;

          end else begin

            flush_ack_o =
              1'b1;

            mh_state_d =
              MH_IDLE;

          end

        end else begin

          flush_addr_d =
            flush_addr_q +
            FLUSH_STEP;

          mh_state_d =
            MH_FLUSH_READ;

        end

      end


      // ----------------------------------------------------------------------
      // Atomic waits for bypass AXI transaction to consume BOTH B and R.
      // ----------------------------------------------------------------------

      MH_AMO_WAIT: begin

        if (amo_bus_done) begin

          amo_resp_o.ack =
            1'b1;

          amo_resp_o.result =
            amo_result_align(
              amo_size_q,
              amo_addr_q,
              amo_bus_result
            );

          mh_state_d =
            MH_IDLE;

        end

      end


      default: begin

        mh_state_d =
          MH_IDLE;

      end

    endcase

  end


  // --------------------------------------------------------------------------
  // Bypass path.
  //
  // Requester arbitration is strict lowest-index priority.
  // Atomic AXI traffic has lower priority than all requester bypass traffic.
  // --------------------------------------------------------------------------

  always_comb begin

    logic bp_found;

    integer i;

    logic [63:0] atom_wdata;
    logic [7:0]  atom_wstrb;

    logic amo_b_seen_now;
    logic amo_r_seen_now;

    logic [63:0] amo_rdata_now;


    bp_state_d =
      bp_state_q;

    bp_src_d =
      bp_src_q;

    bp_req_d =
      bp_req_q;

    bp_aw_done_d =
      bp_aw_done_q;

    bp_w_done_d =
      bp_w_done_q;

    bp_amo_b_seen_d =
      bp_amo_b_seen_q;

    bp_amo_r_seen_d =
      bp_amo_r_seen_q;

    bp_amo_rdata_d =
      bp_amo_rdata_q;


    bypass_gnt_o =
      '0;

    bypass_valid_o =
      '0;

    bypass_data_o =
      '0;

    axi_bypass_req_o =
      '0;


    amo_bus_done =
      1'b0;

    amo_bus_result =
      bp_amo_rdata_q;


    bp_found =
      1'b0;


    atom_wdata =
      amo_write_data(
        amo_op_q,
        amo_size_q,
        amo_addr_q,
        amo_operand_q
      );


    atom_wstrb =
      amo_write_strb(
        amo_size_q,
        amo_addr_q
      );


    amo_b_seen_now =
      bp_amo_b_seen_q;

    amo_r_seen_now =
      bp_amo_r_seen_q;

    amo_rdata_now =
      bp_amo_rdata_q;


    case (bp_state_q)

      // ----------------------------------------------------------------------
      // Idle / arbitration.
      // ----------------------------------------------------------------------

      BP_IDLE: begin

        bp_aw_done_d =
          1'b0;

        bp_w_done_d =
          1'b0;

        bp_amo_b_seen_d =
          1'b0;

        bp_amo_r_seen_d =
          1'b0;

        bp_amo_rdata_d =
          '0;


        /*
         * Strict lowest-index priority.
         */
        for (
          i = 0;
          i < NR_PORTS;
          i = i + 1
        ) begin

          if (
            !bp_found &&
            miss_req_dec[i].valid &&
            miss_req_dec[i].bypass
          ) begin

            bp_found =
              1'b1;

            bp_src_d =
              i;

            bp_req_d =
              miss_req_dec[i];

            bypass_gnt_o[i] =
              1'b1;


            if (miss_req_dec[i].we)
              bp_state_d =
                BP_WRITE_SEND;

            else
              bp_state_d =
                BP_READ_AR;

          end

        end


        /*
         * Atomic is the lowest-priority user of the bypass AXI port.
         */
        if (
          !bp_found &&
          (mh_state_q == MH_AMO_WAIT)
        ) begin

          bp_aw_done_d =
            1'b0;

          bp_w_done_d =
            1'b0;

          bp_amo_b_seen_d =
            1'b0;

          bp_amo_r_seen_d =
            1'b0;

          bp_amo_rdata_d =
            '0;

          bp_state_d =
            BP_AMO_SEND;

        end

      end


      // ----------------------------------------------------------------------
      // Single-beat bypass read address.
      // ----------------------------------------------------------------------

      BP_READ_AR: begin

        axi_bypass_req_o.ar.id =
          4'h8 | bp_src_q;

        axi_bypass_req_o.ar.addr =
          bp_req_q.addr;

        axi_bypass_req_o.ar.len =
          8'd0;

        axi_bypass_req_o.ar.size =
          {1'b0, bp_req_q.size};

        axi_bypass_req_o.ar.burst =
          2'b01;

        axi_bypass_req_o.ar.lock =
          1'b0;

        axi_bypass_req_o.ar.cache =
          4'b0010;

        axi_bypass_req_o.ar.prot =
          3'b000;

        axi_bypass_req_o.ar.qos =
          4'b0000;

        axi_bypass_req_o.ar.region =
          4'b0000;

        axi_bypass_req_o.ar.user =
          '0;

        axi_bypass_req_o.ar_valid =
          1'b1;


        if (axi_bypass_rsp_i.ar_ready)
          bp_state_d =
            BP_READ_R;

      end


      // ----------------------------------------------------------------------
      // Bypass read response.
      // ----------------------------------------------------------------------

      BP_READ_R: begin

        axi_bypass_req_o.r_ready =
          1'b1;


        if (axi_bypass_rsp_i.r_valid) begin

          bypass_valid_o[bp_src_q] =
            1'b1;

          bypass_data_o[bp_src_q] =
            axi_bypass_rsp_i.r.data;

          bp_state_d =
            BP_IDLE;

        end

      end


      // ----------------------------------------------------------------------
      // Single-beat bypass write.
      //
      // AW and W handshakes are tracked independently.
      // ----------------------------------------------------------------------

      BP_WRITE_SEND: begin

        axi_bypass_req_o.aw.id =
          4'h8 | bp_src_q;

        axi_bypass_req_o.aw.addr =
          bp_req_q.addr;

        axi_bypass_req_o.aw.len =
          8'd0;

        axi_bypass_req_o.aw.size =
          {1'b0, bp_req_q.size};

        axi_bypass_req_o.aw.burst =
          2'b01;

        axi_bypass_req_o.aw.lock =
          1'b0;

        axi_bypass_req_o.aw.cache =
          4'b0010;

        axi_bypass_req_o.aw.prot =
          3'b000;

        axi_bypass_req_o.aw.qos =
          4'b0000;

        axi_bypass_req_o.aw.region =
          4'b0000;

        axi_bypass_req_o.aw.atop =
          6'b000000;

        axi_bypass_req_o.aw.user =
          '0;

        axi_bypass_req_o.aw_valid =
          !bp_aw_done_q;


        axi_bypass_req_o.w.data =
          bp_req_q.wdata;

        axi_bypass_req_o.w.strb =
          bp_req_q.be;

        axi_bypass_req_o.w.last =
          1'b1;

        axi_bypass_req_o.w.user =
          '0;

        axi_bypass_req_o.w_valid =
          !bp_w_done_q;


        if (
          !bp_aw_done_q &&
          axi_bypass_rsp_i.aw_ready
        )
          bp_aw_done_d =
            1'b1;


        if (
          !bp_w_done_q &&
          axi_bypass_rsp_i.w_ready
        )
          bp_w_done_d =
            1'b1;


        if (
          bp_aw_done_d &&
          bp_w_done_d
        )
          bp_state_d =
            BP_WRITE_B;

      end


      // ----------------------------------------------------------------------
      // Bypass write response.
      // ----------------------------------------------------------------------

      BP_WRITE_B: begin

        axi_bypass_req_o.b_ready =
          1'b1;


        if (axi_bypass_rsp_i.b_valid) begin

          bypass_valid_o[bp_src_q] =
            1'b1;

          bypass_data_o[bp_src_q] =
            64'b0;

          bp_state_d =
            BP_IDLE;

        end

      end


      // ----------------------------------------------------------------------
      // Atomic AXI ATOP request.
      // ----------------------------------------------------------------------

      BP_AMO_SEND: begin

        axi_bypass_req_o.aw.id =
          AMO_AXI_ID;

        axi_bypass_req_o.aw.addr =
          amo_addr_q;

        axi_bypass_req_o.aw.len =
          8'd0;

        axi_bypass_req_o.aw.size =
          {1'b0, amo_size_q};

        axi_bypass_req_o.aw.burst =
          2'b01;

        axi_bypass_req_o.aw.lock =
          1'b0;

        axi_bypass_req_o.aw.cache =
          4'b0010;

        axi_bypass_req_o.aw.prot =
          3'b000;

        axi_bypass_req_o.aw.qos =
          4'b0000;

        axi_bypass_req_o.aw.region =
          4'b0000;

        axi_bypass_req_o.aw.atop =
          amo_to_atop(amo_op_q);

        axi_bypass_req_o.aw.user =
          '0;

        axi_bypass_req_o.aw_valid =
          !bp_aw_done_q;


        axi_bypass_req_o.w.data =
          atom_wdata;

        axi_bypass_req_o.w.strb =
          atom_wstrb;

        axi_bypass_req_o.w.last =
          1'b1;

        axi_bypass_req_o.w.user =
          '0;

        axi_bypass_req_o.w_valid =
          !bp_w_done_q;


        if (
          !bp_aw_done_q &&
          axi_bypass_rsp_i.aw_ready
        )
          bp_aw_done_d =
            1'b1;


        if (
          !bp_w_done_q &&
          axi_bypass_rsp_i.w_ready
        )
          bp_w_done_d =
            1'b1;


        if (
          bp_aw_done_d &&
          bp_w_done_d
        )
          bp_state_d =
            BP_AMO_RESP;

      end


      // ----------------------------------------------------------------------
      // Atomic response.
      //
      // Both the B response and the R response are required.
      // ----------------------------------------------------------------------

      BP_AMO_RESP: begin

        axi_bypass_req_o.b_ready =
          1'b1;

        axi_bypass_req_o.r_ready =
          1'b1;


        if (axi_bypass_rsp_i.b_valid)
          amo_b_seen_now =
            1'b1;


        if (axi_bypass_rsp_i.r_valid) begin

          amo_r_seen_now =
            1'b1;

          amo_rdata_now =
            axi_bypass_rsp_i.r.data;

        end


        bp_amo_b_seen_d =
          amo_b_seen_now;

        bp_amo_r_seen_d =
          amo_r_seen_now;

        bp_amo_rdata_d =
          amo_rdata_now;


        if (
          amo_b_seen_now &&
          amo_r_seen_now
        ) begin

          amo_bus_done =
            1'b1;

          amo_bus_result =
            amo_rdata_now;

          bp_state_d =
            BP_IDLE;

        end

      end


      default: begin

        bp_state_d =
          BP_IDLE;

      end

    endcase

  end


  // --------------------------------------------------------------------------
  // Sequential state.
  //
  // Reset assertion is asynchronous.
  // State evolution after release occurs on clock edges.
  // --------------------------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

      mh_state_q <=
        MH_IDLE;

      mshr_q <=
        '0;

      victim_way_q <=
        '0;

      evict_line_q <=
        '0;

      refill_line_q <=
        '0;

      refill_beat_q <=
        1'b0;

      data_aw_done_q <=
        1'b0;

      data_w_count_q <=
        2'd0;

      flush_addr_q <=
        '0;

      serve_amo_q <=
        1'b0;

      amo_op_q <=
        AMO_NONE;

      amo_size_q <=
        '0;

      amo_addr_q <=
        '0;

      amo_operand_q <=
        '0;


      bp_state_q <=
        BP_IDLE;

      bp_src_q <=
        '0;

      bp_req_q <=
        '0;

      bp_aw_done_q <=
        1'b0;

      bp_w_done_q <=
        1'b0;

      bp_amo_b_seen_q <=
        1'b0;

      bp_amo_r_seen_q <=
        1'b0;

      bp_amo_rdata_q <=
        '0;

    end else begin

      mh_state_q <=
        mh_state_d;

      mshr_q <=
        mshr_d;

      victim_way_q <=
        victim_way_d;

      evict_line_q <=
        evict_line_d;

      refill_line_q <=
        refill_line_d;

      refill_beat_q <=
        refill_beat_d;

      data_aw_done_q <=
        data_aw_done_d;

      data_w_count_q <=
        data_w_count_d;

      flush_addr_q <=
        flush_addr_d;

      serve_amo_q <=
        serve_amo_d;

      amo_op_q <=
        amo_op_d;

      amo_size_q <=
        amo_size_d;

      amo_addr_q <=
        amo_addr_d;

      amo_operand_q <=
        amo_operand_d;


      bp_state_q <=
        bp_state_d;

      bp_src_q <=
        bp_src_d;

      bp_req_q <=
        bp_req_d;

      bp_aw_done_q <=
        bp_aw_done_d;

      bp_w_done_q <=
        bp_w_done_d;

      bp_amo_b_seen_q <=
        bp_amo_b_seen_d;

      bp_amo_r_seen_q <=
        bp_amo_r_seen_d;

      bp_amo_rdata_q <=
        bp_amo_rdata_d;

    end

  end

endmodule