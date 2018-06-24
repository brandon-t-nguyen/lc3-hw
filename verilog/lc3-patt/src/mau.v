/**
 * MAU: Memory Abstraction Unit
 * This provides an abstract view of memory to the CPU in the form of
 * the MDR/MAR interface
 *
 * This allows for different forms of memory being able to be hooked up
 * to the LC-3 without the CPU knowing about it e.g. you could put a cache
 * and cache controller without the CPU having to change its interface
 *
 * This is effectively like a northbridge of sorts
 */

module mau
    (
        input   wire        arst_n,
        input   wire        clk,
        inout   wire [15:0] bus,

        // cpu interface
        input   wire        cpu_ld_mdr,
        input   wire        cpu_ld_mar,
        input   wire        cpu_gate_mdr,
        input   wire        cpu_mio_en,
        input   wire        cpu_rw,
        output  wire        cpu_rdy,

        // concrete memory interface
        // for now: simple transaction interface (STI)
        // STI master interface
        output  wire        mem_init_txn,   // kick off a transaction
        output  wire        mem_wtxn,       // is it a write?
        output  wire [15:0] mem_addr,       // address to rd/wr
        output  wire [15:0] mem_wdata,      // data to write
        input   wire [15:0] mem_rdata,      // read data
        input   wire        mem_rdy,        // transaction complete

        // peripheral interface
        // also using STI
        // STI master interface
        output  wire        per_init_txn,   // kick off a transaction
        output  wire        per_wtxn,       // is it a write?
        output  wire [7:0]  per_addr,       // address to rd/wr; no odd addresses so only 8 wires
        output  wire [15:0] per_wdata,      // data to write
        input   wire [15:0] per_rdata,      // read data
        input   wire        per_rdy         // transaction complete
    );
    localparam ST_IDLE = 0;
    localparam ST_BUSY = 1;
    localparam MODE_MEM = 0;
    localparam MODE_PER = 1;

    /*
     **********************
     * LC-3 specified logic
     **********************
     */

    /*
     * registers
     */
    // lc3
    reg [15:0] r_mar;
    reg [15:0] r_mdr;

    // mem/per interface
    reg r_cs; // mau state

    /*
     * combinational signals
     */

    wire cb_mode = (r_mar < 16'hfe00) ? MODE_MEM : MODE_PER;

    // lc3
    reg [15:0] cb_mio_mux;
    reg [15:0] cb_in_mux;

    always @(*) begin
        cb_mio_mux = cpu_mio_en ? cb_in_mux : bus;

        if (cb_mode == MODE_MEM)
            cb_in_mux = mem_rdata;
        else
            cb_in_mux = per_rdata;
    end

    // mem/per STI master state machines
    reg o_rdy; assign cpu_rdy = o_rdy; // ready signal handled by these machines

    reg o_ns;
    reg o_init_txn;

    // qualifiers
    wire q_mode = cb_mode;
    wire q_rdy = (cb_mode == MODE_MEM) ? mem_rdy : per_rdy;

    // If MIO.EN=YES while in idle, then it'll kick off a transaction
    // based on R/W
    // single pulse that signal
    wire q_init_txn;
    spulse sp_mio_en(.in(cpu_mio_en), .clk(clk), .out(q_init_txn));

    always @(*) begin
        o_rdy = 0;  // triggered when moving from busy to idle
        o_ns = ST_IDLE;
        o_init_txn = 0;

        case (r_cs)
            ST_IDLE: begin
                if (q_init_txn) begin
                    o_init_txn = 1;
                    o_ns = ST_BUSY;
                end else begin
                    o_ns = ST_IDLE;
                end
            end

            ST_BUSY: begin
                if (q_rdy) begin
                    o_rdy = 1;
                    o_ns = ST_IDLE;
                end else begin
                    o_ns = ST_BUSY;
                end
            end
        endcase
    end

    /*
     * interface assignments
     */

    assign mem_init_txn = (cb_mode == MODE_MEM) & o_init_txn;
    assign mem_init_txn = (cb_mode == MODE_PER) & o_init_txn;

    assign mem_wtxn = cpu_rw;
    assign per_wtxn = cpu_rw;

    assign mem_addr = r_mar;
    assign per_addr = (r_mar - 16'hfe00) >> 1;  // don't allow odd addresses

    assign mem_wdata = r_mdr;
    assign per_wdata = r_mdr;

    /*
     * bus drivers
     */
    tsb_h #(16) tsb_mdr(r_mdr, bus, cpu_gate_mdr);

    /*
     * sequential logic
     */
    initial begin
        r_mar <= 0;
        r_mdr <= 0;
        r_cs  <= ST_IDLE;
    end
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            r_mar <= 0;
            r_mdr <= 0;
            r_cs  <= ST_IDLE;
        end
        else begin
            // lc3
            if (cpu_ld_mar) r_mar <= bus;
            if (cpu_ld_mdr) r_mdr <= cb_mio_mux;

            r_cs <= o_ns;
        end
    end

endmodule
