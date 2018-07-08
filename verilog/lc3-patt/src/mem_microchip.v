/**
 * Main memory controller utilizing the Microchip 23X256 line of serial SRAM chips
 *
 * Design utilizes 4 chips, forming two ranks of two chips per word
 *
 * Each rank has two columns to form a word.
 * Two chip selects: one for each rank
 * Two MOSI/MISO pairs: one for each column
 *
 * Address breakdown
 * addr[14:0] select a row in the chips
 * addr[15] selects a rank of chips
 */

module mem_microchip
    (
        input   wire    arst_n,
        input   wire    clk,

        // STI slave interface
        input  wire        init_txn,
        input  wire        wtxn,
        input  wire [15:0] addr,
        input  wire [15:0] wdata,
        output wire [15:0] rdata,
        output wire        rdy,     // high when ready: initial states will keep this low

        // external interface to the SRAM chips and their SPI interface
        output wire        sck,     // sck will operate at 1/5th the speed of clk
        output wire [1:0]  mosi,
        input  wire [1:0]  miso,
        output wire [1:0]  cs_n     // cs_n[0] is selected when addr[15] == 0, else cs_n[1]
    );
    localparam INST_READ = 8'b0000_0011;
    localparam INST_WRIT = 8'b0000_0010;

    localparam ST_IDLE  = 0;
    localparam ST_INST  = 1;
    localparam ST_WAIT  = 2;
    localparam ST_FAULT = 3;
    localparam NUM_STATES = 3;
    localparam STATE_SIZE = $clog2(NUM_STATES);

    reg [STATE_SIZE-1:0] cs;

    reg [1:0]  sel;
    assign cs_n = ~sel; // abstracting as active high

    // we have the entire instruction needed
    reg [31:0] shf_o[0:1];
    reg [7:0]  shf_i[0:1];

    // save values to be pushed out
    reg        r_wren;  // write enable
    reg [15:0] r_addr;
    reg [15:0] r_wdata;
    reg [15:0] r_rdata; assign rdata = r_rdata;
    reg [5:0]  r_cnt;   // each transfer is 32 SCKs, inc on a shift

    wire clk_sck;
    wire div_arst_n;
    clk_div_o #(5) div_sck (div_arst_n, clk, clk_sck);

    // SM logic
    // SM works on the system clock
    reg [STATE_SIZE-1:0] ns;

    // outputs
    reg o_rdy; assign rdy = o_rdy;
    reg o_set_sel;  // set the appropriate cs_n
    reg o_clr_sel;  // don't select any chips
    reg o_ld_addr;  // save STI address
    reg o_ld_wdata; // save STI write data
    reg o_ld_rdata; // save read data from shf_i
    reg o_ld_shf_o; // load the shift out reg
    reg o_ld_wren;  //

    reg o_rst_cnt;  // reset count reg
    reg o_rst_div; assign div_arst_n =  ~o_rst_div; // reset the divider
    reg o_sck_en; assign sck = o_sck_en & clk_sck; // allow SCK clock to come out
    reg o_shf_en;   // allow shifts on negedge

    // qualifiers
    wire q_init = init_txn;
    wire q_wren = r_wren;

    always @(*) begin
        ns = ST_FAULT;
        o_rdy       = 0;
        o_set_sel   = 0;
        o_clr_sel   = 0;
        o_ld_addr   = 0;
        o_ld_wdata  = 0;
        o_ld_rdata  = 0;
        o_ld_shf_o  = 0;
        o_ld_wren   = 0;

        o_rst_cnt   = 0;
        o_rst_div   = 0;
        o_sck_en    = 0;
        o_shf_en    = 0;

        case (cs)
        ST_IDLE: begin
            if (q_init) begin
                ns = ST_INST;
                o_ld_addr   = 1;
                o_ld_wdata  = 1;
                o_ld_wren   = 1;
                o_rst_cnt   = 1;
            end else begin
                ns = ST_IDLE;
                o_rdy       = 1;
                o_clr_sel   = 1;
            end
        end

        // shim to load up the shift register
        ST_INST: begin
            ns = ST_WAIT;
            o_ld_shf_o = 1;
            o_set_sel  = 1;
            o_rst_div  = 1;
        end

        // wait until all 32 shifts occur
        ST_WAIT: begin
            if (r_cnt == 32) begin
                ns = ST_IDLE;
                o_ld_rdata = !q_wren; // load rdata if it's a read
            end else begin
                ns = ST_WAIT;
                o_sck_en = 1;
                o_shf_en = 1;
            end
        end
        endcase
    end

    initial begin
        cs <= ST_IDLE;
        r_wren <= 0;
        r_addr <= 0;
        r_wdata <= 0;
        r_rdata <= 0;
        r_cnt <= 0;
        sel <= 0;
    end

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            cs <= ST_IDLE;
            r_wren <= 0;
            r_addr <= 0;
            r_wdata <= 0;
            r_rdata <= 0;
            r_cnt <= 0;
            sel <= 0;
        end else begin
            cs <= ns;

            if (o_set_sel) begin
                sel <= r_addr[15] ? 2'b10 : 2'b01;
            end else if (o_clr_sel) begin
                sel <= 2'b00;
            end

            if (o_ld_addr)  r_addr  <= addr;
            if (o_ld_wdata) r_wdata <= wdata;
            if (o_ld_rdata) r_rdata <= {shf_i[1], shf_i[0]};
            if (o_ld_shf_o) begin
                if (q_wren) begin
                    shf_o[0] <= {INST_WRIT, r_addr, r_wdata[7:0]};
                    shf_o[1] <= {INST_WRIT, r_addr, r_wdata[15:8]};
                end else begin
                    shf_o[0] <= {INST_READ, r_addr, 8'h00};
                    shf_o[1] <= {INST_READ, r_addr, 8'h00};
                end
            end
            if (o_ld_wren)  r_wren  <= wtxn;

            if (o_rst_cnt) r_cnt <= 0;
        end
    end

    always @(negedge sck) begin
        if (o_shf_en) begin
            shf_o[0] <= {shf_o[0][30:0], 1'b0};
            shf_o[1] <= {shf_o[1][30:0], 1'b0};
        end
    end

    always @(posedge sck) begin
        if (o_shf_en) begin
            r_cnt <= r_cnt + 1;
            shf_i[0] <= {shf_i[0][6:0], miso[0]};
            shf_i[1] <= {shf_i[1][6:0], miso[1]};
        end
    end

    assign mosi[0] = shf_o[0][31];
    assign mosi[1] = shf_o[1][31];

endmodule
