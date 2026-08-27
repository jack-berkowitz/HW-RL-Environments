module miss_handler_arb

  import miss_handler_arb_pkg::*;

#(
    parameter int unsigned NR_PORTS = 4
) (
    input  logic clk,
    input  logic rst_n,

    // ---- flush ---------------------------------------------------------------
    input  logic flush_i,
    output logic flush_ack_o,
    output logic miss_o,
    input  logic busy_i,

    // ---- requesters ----------------------------------------------------------
    input  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i,

    output logic [NR_PORTS-1:0]       bypass_gnt_o,
    output logic [NR_PORTS-1:0]       bypass_valid_o,
    output logic [NR_PORTS-1:0][63:0] bypass_data_o,

    output logic [NR_PORTS-1:0]       miss_gnt_o,
    output logic [NR_PORTS-1:0]       active_serving_o,

    output logic [63:0] critical_word_o,
    output logic        critical_word_valid_o,

    // ---- MSHR interrogation --------------------------------------------------
    input  logic [NR_PORTS-1:0][55:0] mshr_addr_i,

    output logic [NR_PORTS-1:0] mshr_addr_matches_o,
    output logic [NR_PORTS-1:0] mshr_index_matches_o,

    // ---- atomics -------------------------------------------------------------
    input  amo_req_t  amo_req_i,
    output amo_resp_t amo_resp_o,

    // ---- AXI: bypass ---------------------------------------------------------
    output axi_req_t axi_bypass_req_o,
    input  axi_rsp_t axi_bypass_rsp_i,

    // ---- AXI: refill ---------------------------------------------------------
    output axi_req_t axi_data_req_o,
    input  axi_rsp_t axi_data_rsp_i,

    // ---- cache array ---------------------------------------------------------
    output logic [SET_ASSOC-1:0]   req_o,
    output logic [INDEX_WIDTH-1:0] addr_o,
    output cache_line_t            data_o,
    output cl_be_t                 be_o,
    input  cache_line_t [SET_ASSOC-1:0] data_i,
    output logic                   we_o
);

    localparam int unsigned PORT_W =
        (NR_PORTS <= 1) ? 1 : $clog2(NR_PORTS);

    /*
     * AXI IDs used by the original organization:
     *
     *   refill       = 7
     *   bypass port0 = 8
     *   bypass port1 = 9
     *   ...
     *   AMO          = 8 | NR_PORTS
     */
    localparam logic [3:0] AXI_REFILL_ID = 4'h7;

    /*
     * -------------------------------------------------------------------------
     * Request decoding
     * -------------------------------------------------------------------------
     */

    miss_req_t req_dec [0:NR_PORTS-1];

    always_comb begin : decode_requests
        integer i;

        for (i = 0; i < NR_PORTS; i = i + 1)
            req_dec[i] = miss_req_t'(miss_req_i[i]);
    end


    /*
     * -------------------------------------------------------------------------
     * AMO -> AXI ATOP encoding
     * -------------------------------------------------------------------------
     *
     * AXI ATOP:
     *
     *   SWAP = 110000
     *
     *   AtomicLoad:
     *       ADD  = 100000
     *       CLR  = 100001
     *       EOR  = 100010
     *       SET  = 100011
     *       SMAX = 100100
     *       SMIN = 100101
     *       UMAX = 100110
     *       UMIN = 100111
     */

    function automatic logic [5:0] atop_from_amo(
        input amo_t op
    );
        begin
            case (op)
                AMO_SWAP: atop_from_amo = 6'b110000;

                AMO_ADD:  atop_from_amo = 6'b100000;
                AMO_AND:  atop_from_amo = 6'b100001;
                AMO_XOR:  atop_from_amo = 6'b100010;
                AMO_OR:   atop_from_amo = 6'b100011;

                AMO_MAX:  atop_from_amo = 6'b100100;
                AMO_MIN:  atop_from_amo = 6'b100101;
                AMO_MAXU: atop_from_amo = 6'b100110;
                AMO_MINU: atop_from_amo = 6'b100111;

                default:  atop_from_amo = 6'b000000;
            endcase
        end
    endfunction


    function automatic logic amo_write_returns_r(
        input amo_t op
    );
        begin
            case (op)
                AMO_SWAP,
                AMO_ADD,
                AMO_AND,
                AMO_OR,
                AMO_XOR,
                AMO_MAX,
                AMO_MAXU,
                AMO_MIN,
                AMO_MINU:
                    amo_write_returns_r = 1'b1;

                default:
                    amo_write_returns_r = 1'b0;
            endcase
        end
    endfunction


    /*
     * AXI implements AND through ATOP_CLR.  CLR clears every bit which is
     * asserted in the write data, so RISC-V AMO_AND sends the complement.
     */
    function automatic logic [63:0] atomic_wdata(
        input amo_t        op,
        input logic [1:0]  size,
        input logic [63:0] addr,
        input logic [63:0] data
    );
        logic [63:0] value;

        begin
            if (op == AMO_AND)
                value = ~data;
            else
                value = data;

            if (size == 2'b11) begin
                atomic_wdata = value;
            end
            else if (addr[2]) begin
                atomic_wdata = {
                    value[31:0],
                    32'b0
                };
            end
            else begin
                atomic_wdata = value;
            end
        end
    endfunction


    function automatic logic [7:0] atomic_strb(
        input logic [1:0]  size,
        input logic [63:0] addr
    );
        begin
            if (size == 2'b11)
                atomic_strb = 8'hff;
            else if (addr[2])
                atomic_strb = 8'hf0;
            else
                atomic_strb = 8'h0f;
        end
    endfunction


    function automatic logic [63:0] format_amo_result(
        input logic [63:0] raw,
        input logic [1:0]  size,
        input logic [63:0] addr
    );
        logic [31:0] word;

        begin
            if (size == 2'b10) begin
                if (addr[2])
                    word = raw[63:32];
                else
                    word = raw[31:0];

                format_amo_result = {
                    {32{word[31]}},
                    word
                };
            end
            else begin
                format_amo_result = raw;
            end
        end
    endfunction


    /*
     * =========================================================================
     * MAIN CACHE-MISS / FLUSH / AMO FSM
     * =========================================================================
     */

    typedef enum logic [3:0] {
        MH_IDLE,

        MH_MISS_READ,
        MH_MISS_SELECT,

        MH_EVICT_SEND0,
        MH_EVICT_SEND1,
        MH_EVICT_B,

        MH_REFILL_AR,
        MH_REFILL_R,
        MH_REFILL_WRITE,

        MH_FLUSH_READ,
        MH_FLUSH_WRITE,

        MH_AMO_REQ,
        MH_AMO_WAIT
    } mh_state_t;

    mh_state_t mh_state_q;
    mh_state_t mh_state_d;


    /*
     * MSHR.
     */
    logic                  mshr_valid_q;
    logic                  mshr_valid_d;

    logic [PORT_W-1:0]     mshr_port_q;
    logic [PORT_W-1:0]     mshr_port_d;

    logic [63:0]           mshr_req_addr_q;
    logic [63:0]           mshr_req_addr_d;

    logic                  mshr_we_q;
    logic                  mshr_we_d;

    logic [7:0]            mshr_be_q;
    logic [7:0]            mshr_be_d;

    logic [63:0]           mshr_wdata_q;
    logic [63:0]           mshr_wdata_d;


    /*
     * Refill/victim state.
     */
    logic [SET_ASSOC-1:0] victim_way_q;
    logic [SET_ASSOC-1:0] victim_way_d;

    cache_line_t victim_line_q;
    cache_line_t victim_line_d;

    logic [LINE_WIDTH-1:0] refill_line_q;
    logic [LINE_WIDTH-1:0] refill_line_d;

    logic refill_beat_q;
    logic refill_beat_d;

    logic evict_aw_done_q;
    logic evict_aw_done_d;

    logic evict_w0_done_q;
    logic evict_w0_done_d;


    /*
     * Flush state.
     */
    logic [7:0] flush_set_q;
    logic [7:0] flush_set_d;

    /*
     * This flag is what intentionally implements F7/F8.
     *
     * If set, the current flush is an AMO-induced flush and therefore must
     * not pulse flush_ack_o.
     */
    logic serve_amo_q;
    logic serve_amo_d;


    /*
     * Latched AMO.
     */
    amo_t        amo_op_q;
    amo_t        amo_op_d;

    logic [1:0]  amo_size_q;
    logic [1:0]  amo_size_d;

    logic [63:0] amo_addr_q;
    logic [63:0] amo_addr_d;

    logic [63:0] amo_data_q;
    logic [63:0] amo_data_d;


    /*
     * Interface from the main FSM to the independent bypass arbiter.
     */
    logic        amo_bp_req_c;
    logic        amo_bp_gnt_c;
    logic        amo_bp_done_c;
    logic [63:0] amo_bp_result_c;


    /*
     * -------------------------------------------------------------------------
     * Victim selection
     * -------------------------------------------------------------------------
     *
     * Replacement policy is not pinned by the contract.  Prefer the first
     * invalid way; if every way is valid, use way 0.
     */

    logic [SET_ASSOC-1:0] victim_way_c;
    logic [2:0]           victim_idx_c;
    cache_line_t          victim_line_c;

    always_comb begin : victim_select
        integer i;
        logic found;

        victim_way_c = {{(SET_ASSOC-1){1'b0}}, 1'b1};
        victim_idx_c = 3'd0;
        found        = 1'b0;

        for (i = 0; i < SET_ASSOC; i = i + 1) begin
            if (!found && !data_i[i].valid) begin
                victim_way_c    = '0;
                victim_way_c[i] = 1'b1;
                victim_idx_c    = i;
                found           = 1'b1;
            end
        end

        victim_line_c = data_i[victim_idx_c];
    end


    /*
     * -------------------------------------------------------------------------
     * MSHR interrogation
     * -------------------------------------------------------------------------
     *
     * Full-address and index matches are deliberately independent comparisons.
     * Therefore a full-address hit naturally asserts BOTH outputs.
     *
     * The currently-served requester is deliberately NOT excluded.
     */

    always_comb begin : mshr_matching
        integer i;

        mshr_addr_matches_o  = '0;
        mshr_index_matches_o = '0;

        for (i = 0; i < NR_PORTS; i = i + 1) begin

            if (
                mshr_valid_q &&
                (
                    mshr_addr_i[i][55:4] ==
                    mshr_req_addr_q[55:4]
                )
            ) begin
                mshr_addr_matches_o[i] = 1'b1;
            end

            if (
                mshr_valid_q &&
                (
                    mshr_addr_i[i][11:4] ==
                    mshr_req_addr_q[11:4]
                )
            ) begin
                mshr_index_matches_o[i] = 1'b1;
            end

        end
    end


    /*
     * -------------------------------------------------------------------------
     * Main combinational process
     * -------------------------------------------------------------------------
     */

    always_comb begin : main_comb
        integer i;

        logic found_miss;
        logic aw_done_now;
        logic w0_done_now;

        /*
         * State defaults.
         */
        mh_state_d = mh_state_q;

        mshr_valid_d    = mshr_valid_q;
        mshr_port_d     = mshr_port_q;
        mshr_req_addr_d = mshr_req_addr_q;
        mshr_we_d       = mshr_we_q;
        mshr_be_d       = mshr_be_q;
        mshr_wdata_d    = mshr_wdata_q;

        victim_way_d  = victim_way_q;
        victim_line_d = victim_line_q;

        refill_line_d = refill_line_q;
        refill_beat_d = refill_beat_q;

        evict_aw_done_d = evict_aw_done_q;
        evict_w0_done_d = evict_w0_done_q;

        flush_set_d = flush_set_q;
        serve_amo_d = serve_amo_q;

        amo_op_d   = amo_op_q;
        amo_size_d = amo_size_q;
        amo_addr_d = amo_addr_q;
        amo_data_d = amo_data_q;


        /*
         * Output defaults.
         */
        flush_ack_o = 1'b0;
        miss_o      = 1'b0;

        miss_gnt_o        = '0;
        active_serving_o  = '0;

        critical_word_o       = 64'b0;
        critical_word_valid_o = 1'b0;

        amo_resp_o = '0;

        req_o  = '0;
        addr_o = '0;
        data_o = '0;
        be_o   = '0;
        we_o   = 1'b0;

        axi_data_req_o = '0;

        amo_bp_req_c = 1'b0;

        found_miss = 1'b0;
        aw_done_now = 1'b0;
        w0_done_now = 1'b0;


        /*
         * The currently serviced cached miss remains visible during its entire
         * MSHR lifetime.
         */
        if (mshr_valid_q)
            active_serving_o[mshr_port_q] = 1'b1;


        case (mh_state_q)

            /*
             * =================================================================
             * IDLE
             * =================================================================
             */
            MH_IDLE: begin

                /*
                 * serve_amo is meaningful only for a newly-started flush.
                 */
                serve_amo_d = 1'b0;


                /*
                 * -------------------------------------------------------------
                 * Atomic candidate.
                 * -------------------------------------------------------------
                 *
                 * This intentionally happens BEFORE flush_i.
                 *
                 * Consequently, atomic + flush in the same cycle starts a
                 * flush with serve_amo=1, suppressing flush_ack_o exactly as F8
                 * requires.
                 */
                if (amo_req_i.req && !busy_i) begin

                    amo_op_d   = amo_req_i.amo_op;
                    amo_size_d = amo_req_i.size;
                    amo_addr_d = amo_req_i.operand_a;
                    amo_data_d = amo_req_i.operand_b;

                    flush_set_d = 8'd0;
                    serve_amo_d = 1'b1;
                    mh_state_d  = MH_FLUSH_READ;

                end


                /*
                 * -------------------------------------------------------------
                 * Genuine flush.
                 * -------------------------------------------------------------
                 *
                 * If an atomic was also present above, serve_amo_d remains 1
                 * and therefore this becomes the F8 no-ack flush.
                 */
                if (flush_i && !busy_i) begin

                    flush_set_d = 8'd0;
                    mh_state_d  = MH_FLUSH_READ;

                end


                /*
                 * -------------------------------------------------------------
                 * Cached miss.
                 * -------------------------------------------------------------
                 *
                 * This is evaluated last.  Hence an incoming refill miss wins
                 * over a same-cycle atomic, clearing the AMO-pending state
                 * exactly as F9 requires.
                 *
                 * Lowest index wins.
                 */
                for (i = 0; i < NR_PORTS; i = i + 1) begin

                    if (
                        !found_miss &&
                        req_dec[i].valid &&
                        !req_dec[i].bypass
                    ) begin

                        found_miss = 1'b1;

                        mshr_valid_d    = 1'b1;
                        mshr_port_d     = i;
                        mshr_req_addr_d = req_dec[i].addr;
                        mshr_we_d       = req_dec[i].we;
                        mshr_be_d       = req_dec[i].be;
                        mshr_wdata_d    = req_dec[i].wdata;

                        /*
                         * Miss wins over a pending AMO.
                         */
                        serve_amo_d = 1'b0;

                        mh_state_d = MH_MISS_READ;

                    end

                end

            end


            /*
             * =================================================================
             * CACHE MISS: synchronous array lookup
             * =================================================================
             */
            MH_MISS_READ: begin

                /*
                 * Read every way of the indexed set.
                 */
                req_o  = '1;
                addr_o = mshr_req_addr_q[INDEX_WIDTH-1:0];
                we_o   = 1'b0;

                /*
                 * Performance-counter miss pulse.
                 */
                miss_o = 1'b1;

                mh_state_d = MH_MISS_SELECT;

            end


            /*
             * Returned array contents are now visible on data_i.
             */
            MH_MISS_SELECT: begin

                victim_way_d  = victim_way_c;
                victim_line_d = victim_line_c;

                evict_aw_done_d = 1'b0;
                evict_w0_done_d = 1'b0;

                /*
                 * Dirty replacement needs a 128-bit AXI writeback first.
                 */
                if (
                    victim_line_c.valid &&
                    victim_line_c.dirty
                ) begin

                    mh_state_d = MH_EVICT_SEND0;

                end
                else begin

                    mh_state_d = MH_REFILL_AR;

                end

            end


            /*
             * =================================================================
             * DIRTY EVICTION
             * =================================================================
             *
             * First W beat and AW may proceed independently.
             */
            MH_EVICT_SEND0: begin

                /*
                 * AW
                 */
                axi_data_req_o.aw_valid = !evict_aw_done_q;

                axi_data_req_o.aw.id     = AXI_REFILL_ID;
                axi_data_req_o.aw.addr   = {
                    8'b0,
                    victim_line_q.tag,
                    mshr_req_addr_q[11:4],
                    4'b0000
                };

                axi_data_req_o.aw.len    = 8'd1;
                axi_data_req_o.aw.size   = 3'd3;
                axi_data_req_o.aw.burst  = 2'b01;
                axi_data_req_o.aw.lock   = 1'b0;
                axi_data_req_o.aw.cache  = 4'b0010;
                axi_data_req_o.aw.prot   = 3'b000;
                axi_data_req_o.aw.qos    = 4'b0000;
                axi_data_req_o.aw.region = 4'b0000;
                axi_data_req_o.aw.atop   = 6'b000000;
                axi_data_req_o.aw.user   = '0;

                /*
                 * First 64-bit data beat.
                 */
                axi_data_req_o.w_valid = !evict_w0_done_q;

                axi_data_req_o.w.data = victim_line_q.data[63:0];
                axi_data_req_o.w.strb = 8'hff;
                axi_data_req_o.w.last = 1'b0;
                axi_data_req_o.w.user = '0;


                aw_done_now =
                    evict_aw_done_q ||
                    (
                        !evict_aw_done_q &&
                        axi_data_rsp_i.aw_ready
                    );

                w0_done_now =
                    evict_w0_done_q ||
                    (
                        !evict_w0_done_q &&
                        axi_data_rsp_i.w_ready
                    );


                if (
                    !evict_aw_done_q &&
                    axi_data_rsp_i.aw_ready
                )
                    evict_aw_done_d = 1'b1;

                if (
                    !evict_w0_done_q &&
                    axi_data_rsp_i.w_ready
                )
                    evict_w0_done_d = 1'b1;


                if (aw_done_now && w0_done_now)
                    mh_state_d = MH_EVICT_SEND1;

            end


            /*
             * Second 64-bit writeback beat.
             */
            MH_EVICT_SEND1: begin

                axi_data_req_o.w_valid = 1'b1;

                axi_data_req_o.w.data = victim_line_q.data[127:64];
                axi_data_req_o.w.strb = 8'hff;
                axi_data_req_o.w.last = 1'b1;
                axi_data_req_o.w.user = '0;

                if (axi_data_rsp_i.w_ready)
                    mh_state_d = MH_EVICT_B;

            end


            /*
             * Wait for writeback completion.
             */
            MH_EVICT_B: begin

                axi_data_req_o.b_ready = 1'b1;

                if (axi_data_rsp_i.b_valid)
                    mh_state_d = MH_REFILL_AR;

            end


            /*
             * =================================================================
             * CACHELINE REFILL
             * =================================================================
             */
            MH_REFILL_AR: begin

                axi_data_req_o.ar_valid = 1'b1;

                axi_data_req_o.ar.id = AXI_REFILL_ID;

                /*
                 * 16-byte cacheline alignment.
                 */
                axi_data_req_o.ar.addr = {
                    mshr_req_addr_q[63:4],
                    4'b0000
                };

                /*
                 * Two 64-bit beats = 128-bit line.
                 */
                axi_data_req_o.ar.len   = 8'd1;
                axi_data_req_o.ar.size  = 3'd3;
                axi_data_req_o.ar.burst = 2'b01;
                axi_data_req_o.ar.lock  = 1'b0;
                axi_data_req_o.ar.cache = 4'b0010;
                axi_data_req_o.ar.prot  = 3'b000;
                axi_data_req_o.ar.qos   = 4'b0000;
                axi_data_req_o.ar.region = 4'b0000;
                axi_data_req_o.ar.user   = '0;


                if (axi_data_rsp_i.ar_ready) begin

                    /*
                     * Cached-miss grant corresponds to the refill actually
                     * entering the AXI path.
                     */
                    miss_gnt_o[mshr_port_q] = 1'b1;

                    refill_line_d = '0;
                    refill_beat_d = 1'b0;

                    mh_state_d = MH_REFILL_R;

                end

            end


            MH_REFILL_R: begin

                axi_data_req_o.r_ready = 1'b1;

                if (axi_data_rsp_i.r_valid) begin

                    /*
                     * Line assembly.
                     */
                    if (!refill_beat_q)
                        refill_line_d[63:0] =
                            axi_data_rsp_i.r.data;
                    else
                        refill_line_d[127:64] =
                            axi_data_rsp_i.r.data;


                    /*
                     * Critical word forward.
                     *
                     * Address bit 3 selects the requested 64-bit word inside
                     * the 16-byte cacheline.
                     */
                    if (refill_beat_q == mshr_req_addr_q[3]) begin

                        critical_word_o =
                            axi_data_rsp_i.r.data;

                        critical_word_valid_o = 1'b1;

                    end


                    if (
                        axi_data_rsp_i.r.last ||
                        refill_beat_q
                    ) begin

                        mh_state_d = MH_REFILL_WRITE;

                    end
                    else begin

                        refill_beat_d = 1'b1;

                    end

                end

            end


            /*
             * Write the completed line into the selected way.
             */
            MH_REFILL_WRITE: begin

                req_o  = victim_way_q;
                addr_o = mshr_req_addr_q[INDEX_WIDTH-1:0];
                we_o   = 1'b1;

                /*
                 * Write tag and full line data, but only selected way's
                 * valid/dirty status.
                 */
                be_o = '1;
                be_o.vldrty = victim_way_q;

                data_o.tag   = mshr_req_addr_q[55:12];
                data_o.data  = refill_line_q;
                data_o.valid = 1'b1;
                data_o.dirty = mshr_we_q;


                /*
                 * A store miss merges the requested bytes into the freshly
                 * fetched cacheline before installation.
                 */
                if (mshr_we_q) begin

                    for (i = 0; i < 8; i = i + 1) begin

                        if (mshr_be_q[i]) begin

                            if (mshr_req_addr_q[3]) begin

                                data_o.data[
                                    64 + (i * 8) +: 8
                                ] =
                                    mshr_wdata_q[
                                        (i * 8) +: 8
                                    ];

                            end
                            else begin

                                data_o.data[
                                    (i * 8) +: 8
                                ] =
                                    mshr_wdata_q[
                                        (i * 8) +: 8
                                    ];

                            end

                        end

                    end

                end


                /*
                 * Refill has retired.
                 */
                mshr_valid_d = 1'b0;
                mh_state_d   = MH_IDLE;

            end


            /*
             * =================================================================
             * FLUSH WALK
             * =================================================================
             *
             * Exactly two array accesses per set:
             *
             *     READ
             *     WRITE invalidate
             *
             * for 256 sets = exactly 512 requests / 256 writes.
             */
            MH_FLUSH_READ: begin

                req_o = '1;

                addr_o = {
                    flush_set_q,
                    {OFFSET_WIDTH{1'b0}}
                };

                we_o = 1'b0;

                mh_state_d = MH_FLUSH_WRITE;

            end


            MH_FLUSH_WRITE: begin

                req_o = '1;

                addr_o = {
                    flush_set_q,
                    {OFFSET_WIDTH{1'b0}}
                };

                we_o = 1'b1;

                /*
                 * Only valid/dirty state is changed.
                 */
                be_o = '0;
                be_o.vldrty = '1;

                data_o = '0;
                data_o.valid = 1'b0;
                data_o.dirty = 1'b0;


                /*
                 * Last set.
                 */
                if (flush_set_q == (NUM_WORDS - 1)) begin

                    if (serve_amo_q) begin

                        /*
                         * AMO-induced flush: never acknowledge it as a normal
                         * flush.
                         */
                        serve_amo_d = 1'b0;
                        mh_state_d  = MH_AMO_REQ;

                    end
                    else begin

                        /*
                         * Genuine F5 flush.
                         */
                        flush_ack_o = 1'b1;
                        mh_state_d  = MH_IDLE;

                    end

                end
                else begin

                    flush_set_d = flush_set_q + 8'd1;
                    mh_state_d  = MH_FLUSH_READ;

                end

            end


            /*
             * =================================================================
             * AMO
             * =================================================================
             *
             * After the forced flush, the atomic becomes the lowest-priority
             * requester on the independent bypass arbiter.
             */
            MH_AMO_REQ: begin

                amo_bp_req_c = 1'b1;

                if (amo_bp_gnt_c)
                    mh_state_d = MH_AMO_WAIT;

            end


            MH_AMO_WAIT: begin

                if (amo_bp_done_c) begin

                    amo_resp_o.ack    = 1'b1;
                    amo_resp_o.result = amo_bp_result_c;

                    mh_state_d = MH_IDLE;

                end

            end


            default: begin
                mh_state_d = MH_IDLE;
            end

        endcase
    end


    /*
     * -------------------------------------------------------------------------
     * Main registers
     * -------------------------------------------------------------------------
     */

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            mh_state_q <= MH_IDLE;

            mshr_valid_q    <= 1'b0;
            mshr_port_q     <= '0;
            mshr_req_addr_q <= 64'b0;
            mshr_we_q       <= 1'b0;
            mshr_be_q       <= 8'b0;
            mshr_wdata_q    <= 64'b0;

            victim_way_q  <= '0;
            victim_line_q <= '0;

            refill_line_q <= '0;
            refill_beat_q <= 1'b0;

            evict_aw_done_q <= 1'b0;
            evict_w0_done_q <= 1'b0;

            flush_set_q <= 8'b0;
            serve_amo_q <= 1'b0;

            amo_op_q   <= AMO_NONE;
            amo_size_q <= 2'b0;
            amo_addr_q <= 64'b0;
            amo_data_q <= 64'b0;

        end
        else begin

            mh_state_q <= mh_state_d;

            mshr_valid_q    <= mshr_valid_d;
            mshr_port_q     <= mshr_port_d;
            mshr_req_addr_q <= mshr_req_addr_d;
            mshr_we_q       <= mshr_we_d;
            mshr_be_q       <= mshr_be_d;
            mshr_wdata_q    <= mshr_wdata_d;

            victim_way_q  <= victim_way_d;
            victim_line_q <= victim_line_d;

            refill_line_q <= refill_line_d;
            refill_beat_q <= refill_beat_d;

            evict_aw_done_q <= evict_aw_done_d;
            evict_w0_done_q <= evict_w0_done_d;

            flush_set_q <= flush_set_d;
            serve_amo_q <= serve_amo_d;

            amo_op_q   <= amo_op_d;
            amo_size_q <= amo_size_d;
            amo_addr_q <= amo_addr_d;
            amo_data_q <= amo_data_d;

        end
    end


    /*
     * =========================================================================
     * BYPASS / AMO ARBITER AND AXI ENGINE
     * =========================================================================
     *
     * Normal bypass ports have strict lowest-index priority.
     *
     * The atomic request is logically an extra final requester, therefore every
     * ordinary bypass requester outranks it.
     */

    typedef enum logic [2:0] {
        BP_IDLE,
        BP_SEND_RD,
        BP_WAIT_RD,
        BP_SEND_WR,
        BP_WAIT_B,
        BP_WAIT_ATOMIC
    } bp_state_t;

    bp_state_t bp_state_q;
    bp_state_t bp_state_d;

    logic [PORT_W-1:0] bp_port_q;
    logic [PORT_W-1:0] bp_port_d;

    logic              bp_atomic_q;
    logic              bp_atomic_d;

    logic [3:0]        bp_id_q;
    logic [3:0]        bp_id_d;

    logic [63:0]       bp_addr_q;
    logic [63:0]       bp_addr_d;

    logic [63:0]       bp_wdata_q;
    logic [63:0]       bp_wdata_d;

    logic [7:0]        bp_be_q;
    logic [7:0]        bp_be_d;

    logic [1:0]        bp_size_q;
    logic [1:0]        bp_size_d;

    amo_t              bp_amo_q;
    amo_t              bp_amo_d;

    logic [5:0]        bp_atop_q;
    logic [5:0]        bp_atop_d;

    logic              bp_lock_q;
    logic              bp_lock_d;

    logic              bp_need_r_q;
    logic              bp_need_r_d;

    logic              bp_aw_done_q;
    logic              bp_aw_done_d;

    logic              bp_w_done_q;
    logic              bp_w_done_d;

    logic              bp_b_seen_q;
    logic              bp_b_seen_d;

    logic              bp_r_seen_q;
    logic              bp_r_seen_d;

    logic [63:0]       bp_atomic_rdata_q;
    logic [63:0]       bp_atomic_rdata_d;


    always_comb begin : bypass_comb
        integer i;

        logic found;
        logic aw_now;
        logic w_now;
        logic b_now;
        logic r_now;

        logic [63:0] raw_atomic_result;


        /*
         * Register defaults.
         */
        bp_state_d = bp_state_q;

        bp_port_d   = bp_port_q;
        bp_atomic_d = bp_atomic_q;

        bp_id_d    = bp_id_q;
        bp_addr_d  = bp_addr_q;
        bp_wdata_d = bp_wdata_q;
        bp_be_d    = bp_be_q;
        bp_size_d  = bp_size_q;

        bp_amo_d  = bp_amo_q;
        bp_atop_d = bp_atop_q;
        bp_lock_d = bp_lock_q;

        bp_need_r_d = bp_need_r_q;

        bp_aw_done_d = bp_aw_done_q;
        bp_w_done_d  = bp_w_done_q;

        bp_b_seen_d = bp_b_seen_q;
        bp_r_seen_d = bp_r_seen_q;

        bp_atomic_rdata_d = bp_atomic_rdata_q;


        /*
         * Output defaults.
         */
        bypass_gnt_o   = '0;
        bypass_valid_o = '0;
        bypass_data_o  = '0;

        axi_bypass_req_o = '0;

        amo_bp_gnt_c   = 1'b0;
        amo_bp_done_c  = 1'b0;
        amo_bp_result_c = 64'b0;

        found = 1'b0;

        aw_now = 1'b0;
        w_now  = 1'b0;
        b_now  = 1'b0;
        r_now  = 1'b0;

        raw_atomic_result = bp_atomic_rdata_q;


        case (bp_state_q)

            /*
             * =================================================================
             * Arbitration
             * =================================================================
             */
            BP_IDLE: begin

                /*
                 * Strict lowest-index priority.
                 */
                for (i = 0; i < NR_PORTS; i = i + 1) begin

                    if (
                        !found &&
                        req_dec[i].valid &&
                        req_dec[i].bypass
                    ) begin

                        found = 1'b1;

                        /*
                         * Requester observes its grant immediately when the
                         * request is captured by this arbiter.
                         */
                        bypass_gnt_o[i] = 1'b1;

                        bp_port_d   = i;
                        bp_atomic_d = 1'b0;

                        bp_id_d = 4'h8 | i;

                        bp_addr_d  = req_dec[i].addr;
                        bp_wdata_d = req_dec[i].wdata;
                        bp_be_d    = req_dec[i].be;
                        bp_size_d  = req_dec[i].size;

                        bp_amo_d  = AMO_NONE;
                        bp_atop_d = 6'b000000;
                        bp_lock_d = 1'b0;

                        bp_need_r_d = 1'b0;

                        bp_aw_done_d = 1'b0;
                        bp_w_done_d  = 1'b0;

                        bp_b_seen_d = 1'b0;
                        bp_r_seen_d = 1'b0;

                        if (req_dec[i].we)
                            bp_state_d = BP_SEND_WR;
                        else
                            bp_state_d = BP_SEND_RD;

                    end

                end


                /*
                 * AMO is an extra, lowest-priority bypass requester.
                 */
                if (!found && amo_bp_req_c) begin

                    amo_bp_gnt_c = 1'b1;

                    bp_atomic_d = 1'b1;

                    bp_id_d = 4'h8 | NR_PORTS;

                    bp_addr_d = amo_addr_q;
                    bp_size_d = amo_size_q;

                    bp_amo_d  = amo_op_q;
                    bp_atop_d = atop_from_amo(amo_op_q);

                    bp_lock_d =
                        (amo_op_q == AMO_LR) ||
                        (amo_op_q == AMO_SC);

                    bp_wdata_d =
                        atomic_wdata(
                            amo_op_q,
                            amo_size_q,
                            amo_addr_q,
                            amo_data_q
                        );

                    bp_be_d =
                        atomic_strb(
                            amo_size_q,
                            amo_addr_q
                        );

                    bp_need_r_d =
                        amo_write_returns_r(
                            amo_op_q
                        );

                    bp_aw_done_d = 1'b0;
                    bp_w_done_d  = 1'b0;

                    bp_b_seen_d = 1'b0;
                    bp_r_seen_d = 1'b0;

                    bp_atomic_rdata_d = 64'b0;

                    /*
                     * LR is an exclusive AXI read.
                     * Everything else is a write-side transaction.
                     */
                    if (amo_op_q == AMO_LR)
                        bp_state_d = BP_SEND_RD;
                    else
                        bp_state_d = BP_SEND_WR;

                end

            end


            /*
             * =================================================================
             * Single read / LR
             * =================================================================
             */
            BP_SEND_RD: begin

                axi_bypass_req_o.ar_valid = 1'b1;

                axi_bypass_req_o.ar.id     = bp_id_q;
                axi_bypass_req_o.ar.addr   = bp_addr_q;
                axi_bypass_req_o.ar.len    = 8'd0;
                axi_bypass_req_o.ar.size   = {1'b0, bp_size_q};
                axi_bypass_req_o.ar.burst  = 2'b01;
                axi_bypass_req_o.ar.lock   = bp_lock_q;
                axi_bypass_req_o.ar.cache  = 4'b0010;
                axi_bypass_req_o.ar.prot   = 3'b000;
                axi_bypass_req_o.ar.qos    = 4'b0000;
                axi_bypass_req_o.ar.region = 4'b0000;
                axi_bypass_req_o.ar.user   = '0;

                if (axi_bypass_rsp_i.ar_ready)
                    bp_state_d = BP_WAIT_RD;

            end


            BP_WAIT_RD: begin

                axi_bypass_req_o.r_ready = 1'b1;

                if (axi_bypass_rsp_i.r_valid) begin

                    if (bp_atomic_q) begin

                        amo_bp_done_c = 1'b1;

                        amo_bp_result_c =
                            format_amo_result(
                                axi_bypass_rsp_i.r.data,
                                bp_size_q,
                                bp_addr_q
                            );

                    end
                    else begin

                        bypass_valid_o[bp_port_q] = 1'b1;

                        bypass_data_o[bp_port_q] =
                            axi_bypass_rsp_i.r.data;

                    end

                    bp_state_d = BP_IDLE;

                end

            end


            /*
             * =================================================================
             * Single write / AXI ATOP
             * =================================================================
             *
             * AW and W are independent AXI channels.  Each valid remains high
             * until its corresponding ready has been observed.
             */
            BP_SEND_WR: begin

                /*
                 * AW
                 */
                axi_bypass_req_o.aw_valid =
                    !bp_aw_done_q;

                axi_bypass_req_o.aw.id     = bp_id_q;
                axi_bypass_req_o.aw.addr   = bp_addr_q;
                axi_bypass_req_o.aw.len    = 8'd0;
                axi_bypass_req_o.aw.size   = {1'b0, bp_size_q};
                axi_bypass_req_o.aw.burst  = 2'b01;
                axi_bypass_req_o.aw.lock   = bp_lock_q;
                axi_bypass_req_o.aw.cache  = 4'b0010;
                axi_bypass_req_o.aw.prot   = 3'b000;
                axi_bypass_req_o.aw.qos    = 4'b0000;
                axi_bypass_req_o.aw.region = 4'b0000;
                axi_bypass_req_o.aw.atop   = bp_atop_q;
                axi_bypass_req_o.aw.user   = '0;

                /*
                 * W
                 */
                axi_bypass_req_o.w_valid =
                    !bp_w_done_q;

                axi_bypass_req_o.w.data =
                    bp_wdata_q;

                axi_bypass_req_o.w.strb =
                    bp_be_q;

                axi_bypass_req_o.w.last = 1'b1;
                axi_bypass_req_o.w.user = '0;


                aw_now =
                    bp_aw_done_q ||
                    (
                        !bp_aw_done_q &&
                        axi_bypass_rsp_i.aw_ready
                    );

                w_now =
                    bp_w_done_q ||
                    (
                        !bp_w_done_q &&
                        axi_bypass_rsp_i.w_ready
                    );


                if (
                    !bp_aw_done_q &&
                    axi_bypass_rsp_i.aw_ready
                )
                    bp_aw_done_d = 1'b1;

                if (
                    !bp_w_done_q &&
                    axi_bypass_rsp_i.w_ready
                )
                    bp_w_done_d = 1'b1;


                if (aw_now && w_now) begin

                    bp_b_seen_d = 1'b0;
                    bp_r_seen_d = 1'b0;

                    if (
                        bp_atomic_q &&
                        bp_need_r_q
                    )
                        bp_state_d = BP_WAIT_ATOMIC;
                    else
                        bp_state_d = BP_WAIT_B;

                end

            end


            /*
             * Normal write and SC complete from B.
             */
            BP_WAIT_B: begin

                axi_bypass_req_o.b_ready = 1'b1;

                if (axi_bypass_rsp_i.b_valid) begin

                    if (bp_atomic_q) begin

                        amo_bp_done_c = 1'b1;

                        /*
                         * Store conditional:
                         *
                         * EXOKAY = reservation succeeded -> return 0.
                         * Anything else                 -> return 1.
                         */
                        if (bp_amo_q == AMO_SC) begin

                            if (
                                axi_bypass_rsp_i.b.resp ==
                                2'b01
                            )
                                amo_bp_result_c = 64'd0;
                            else
                                amo_bp_result_c = 64'd1;

                        end
                        else begin

                            amo_bp_result_c = 64'd0;

                        end

                    end
                    else begin

                        bypass_valid_o[bp_port_q] = 1'b1;
                        bypass_data_o[bp_port_q]  = 64'b0;

                    end

                    bp_state_d = BP_IDLE;

                end

            end


            /*
             * =================================================================
             * AXI ATOP response
             * =================================================================
             *
             * Contract A7 requires BOTH B and R.  Either may arrive first.
             */
            BP_WAIT_ATOMIC: begin

                axi_bypass_req_o.b_ready =
                    !bp_b_seen_q;

                axi_bypass_req_o.r_ready =
                    !bp_r_seen_q;


                b_now = bp_b_seen_q;
                r_now = bp_r_seen_q;

                raw_atomic_result =
                    bp_atomic_rdata_q;


                if (
                    !bp_b_seen_q &&
                    axi_bypass_rsp_i.b_valid
                ) begin

                    bp_b_seen_d = 1'b1;
                    b_now      = 1'b1;

                end


                if (
                    !bp_r_seen_q &&
                    axi_bypass_rsp_i.r_valid
                ) begin

                    bp_r_seen_d = 1'b1;
                    r_now      = 1'b1;

                    bp_atomic_rdata_d =
                        axi_bypass_rsp_i.r.data;

                    raw_atomic_result =
                        axi_bypass_rsp_i.r.data;

                end


                if (b_now && r_now) begin

                    amo_bp_done_c = 1'b1;

                    amo_bp_result_c =
                        format_amo_result(
                            raw_atomic_result,
                            bp_size_q,
                            bp_addr_q
                        );

                    bp_state_d = BP_IDLE;

                end

            end


            default: begin
                bp_state_d = BP_IDLE;
            end

        endcase
    end


    /*
     * -------------------------------------------------------------------------
     * Bypass registers
     * -------------------------------------------------------------------------
     */

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            bp_state_q <= BP_IDLE;

            bp_port_q   <= '0;
            bp_atomic_q <= 1'b0;

            bp_id_q    <= 4'b0;
            bp_addr_q  <= 64'b0;
            bp_wdata_q <= 64'b0;
            bp_be_q    <= 8'b0;
            bp_size_q  <= 2'b0;

            bp_amo_q  <= AMO_NONE;
            bp_atop_q <= 6'b0;
            bp_lock_q <= 1'b0;

            bp_need_r_q <= 1'b0;

            bp_aw_done_q <= 1'b0;
            bp_w_done_q  <= 1'b0;

            bp_b_seen_q <= 1'b0;
            bp_r_seen_q <= 1'b0;

            bp_atomic_rdata_q <= 64'b0;

        end
        else begin

            bp_state_q <= bp_state_d;

            bp_port_q   <= bp_port_d;
            bp_atomic_q <= bp_atomic_d;

            bp_id_q    <= bp_id_d;
            bp_addr_q  <= bp_addr_d;
            bp_wdata_q <= bp_wdata_d;
            bp_be_q    <= bp_be_d;
            bp_size_q  <= bp_size_d;

            bp_amo_q  <= bp_amo_d;
            bp_atop_q <= bp_atop_d;
            bp_lock_q <= bp_lock_d;

            bp_need_r_q <= bp_need_r_d;

            bp_aw_done_q <= bp_aw_done_d;
            bp_w_done_q  <= bp_w_done_d;

            bp_b_seen_q <= bp_b_seen_d;
            bp_r_seen_q <= bp_r_seen_d;

            bp_atomic_rdata_q <= bp_atomic_rdata_d;

        end
    end

endmodule