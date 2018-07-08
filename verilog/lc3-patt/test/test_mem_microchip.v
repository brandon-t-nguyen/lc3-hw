module test_mem_microchip;
    reg arst_n;
    reg clk;
    always #5 clk = ~clk;

    // STI signals
    reg init_txn;
    reg wtxn;
    reg [15:0]  addr;
    reg [15:0]  wdata;
    wire [15:0] rdata;
    wire        rdy;

    // SPI signals
    wire sck;
    wire [1:0] mosi;
    wire [1:0] miso;
    wire [1:0] cs_n;

    mem_microchip mem
        (
            .arst_n(arst_n),
            .clk(clk),

            .init_txn(init_txn),
            .wtxn(wtxn),
            .addr(addr),
            .wdata(wdata),
            .rdata(rdata),
            .rdy(rdy),

            .sck(sck),
            .mosi(mosi),
            .miso(miso),
            .cs_n(cs_n)
        );

    microchip_23X256 r0c0 (.sck(sck), .cs_n(cs_n[0]), .so(miso[0]), .si(mosi[0]), .hold_n(1'b1));
    microchip_23X256 r0c1 (.sck(sck), .cs_n(cs_n[0]), .so(miso[1]), .si(mosi[1]), .hold_n(1'b1));
    microchip_23X256 r1c0 (.sck(sck), .cs_n(cs_n[1]), .so(miso[0]), .si(mosi[0]), .hold_n(1'b1));
    microchip_23X256 r1c1 (.sck(sck), .cs_n(cs_n[1]), .so(miso[1]), .si(mosi[1]), .hold_n(1'b1));

    integer i;
    initial begin
        $dumpfile("wave_mem_microchip.vcd");
        $dumpvars(0, test_mem_microchip);
        for (i = 0; i < 2; i = i + 1) begin
            $dumpvars(0, mem.shf_o[i]);
            $dumpvars(0, mem.shf_i[i]);
        end

        arst_n = 1;
        clk = 0;
        #1;
        arst_n = 0;
        #1;
        arst_n = 1;

        init_txn = 1;
        wtxn = 1;
        addr  = 16'h1000;
        wdata = 16'hdead;
        @(posedge clk);
        #1;
        init_txn = 0;
        wtxn     = 0;
        @(posedge rdy);
        $display("r0c0[0x1000] = 0x%02X", r0c0.data[15'h1000]);
        $display("r0c1[0x1000] = 0x%02X", r0c1.data[15'h1000]);

        @(posedge clk);
        init_txn = 1;
        wtxn = 1;
        addr  = 16'h9000;
        wdata = 16'hbeef;
        @(posedge clk);
        #1;
        init_txn = 0;
        wtxn     = 0;
        @(posedge rdy);
        $display("r1c0[0x1000] = 0x%02X", r1c0.data[15'h1000]);
        $display("r1c1[0x1000] = 0x%02X", r1c1.data[15'h1000]);

        @(posedge clk);
        init_txn = 1;
        wtxn = 0;
        addr = 16'h1000;
        @(posedge clk);
        #1;
        init_txn = 0;
        @(posedge rdy);
        $display("mem[0x1000] = 0x%04X", rdata);

        @(posedge clk);
        init_txn = 1;
        wtxn = 0;
        addr = 16'h9000;
        @(posedge clk);
        #1;
        init_txn = 0;
        @(posedge rdy);
        $display("mem[0x9000] = 0x%04X", rdata);

        $finish();
    end

endmodule
