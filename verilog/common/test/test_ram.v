`define CHECK (pass ? "PASS" : "FAIL")
module test_spram;
    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 8;
    localparam DATA_DEPTH = 16;

    reg clk;
    reg en;
    reg wr_en;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] wr_data;
    wire [DATA_WIDTH-1:0] rd_data;

    spram #(.ADDR_WIDTH(ADDR_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .DATA_DEPTH(DATA_DEPTH))
        sp(
            .clk(clk),
            .en(en),
            .wr_en(wr_en),
            .addr(addr),
            .wr_data(wr_data),
            .rd_data(rd_data)
    );

    always #5 clk = ~clk;
    integer i;
    integer pass;
    integer overall_pass;
    reg [DATA_WIDTH-1:0] expect;
    initial begin
        $dumpfile("test_spram.vcd");
        $dumpvars(0, test_spram);
        overall_pass = 1;

        clk = 0;
        en = 1;

        wr_en = 1;
        expect = 8'b10101010;
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            addr = i[7:0];
            wr_data = expect;
            #10;
            expect = ~expect;
        end

        wr_en = 0;
        expect = 8'b10101010;
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            addr = i[7:0];
            #10;

            pass = (rd_data === expect);
            if (!pass)
                $display("FAIL: spram[%2d] = %08b, expected %08b", addr, rd_data, expect);

            if (overall_pass)
                overall_pass = pass;

            expect = ~expect;
        end

        wr_en = 0;
        wr_data = 0;
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            addr = i[7:0];
            #10;
        end

        expect = 8'b10101010;
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            addr = i[7:0];
            #10;

            pass = (rd_data === expect);
            if (!pass)
                $display("FAIL: spram[%2d] = %08b, expected %08b", addr, rd_data, expect);

            if (overall_pass)
                overall_pass = pass;

            expect = ~expect;
        end

        if (overall_pass)
            $display("test: spram: PASS");
        else
            $display("test: spram: FAIL");

        $finish();
    end
endmodule

module test_dpram;
    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 8;
    localparam DATA_DEPTH = 16;

    reg clk;
    reg en;
    reg wr_en;
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [DATA_WIDTH-1:0] wr_data;
    wire [DATA_WIDTH-1:0] rd_data;

    dpram #(.ADDR_WIDTH(ADDR_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .DATA_DEPTH(DATA_DEPTH))
        dp(
            .clk(clk),
            .en(en),
            .wr_en(wr_en),
            .wr_addr(wr_addr),
            .wr_data(wr_data),
            .rd_addr(rd_addr),
            .rd_data(rd_data)
    );

    always #5 clk = ~clk;
    integer i;
    integer pass;
    integer overall_pass;
    reg [DATA_WIDTH-1:0] expect;
    initial begin
        $dumpfile("test_dpram.vcd");
        $dumpvars(0, test_dpram);
        overall_pass = 1;

        clk = 0;
        en = 1;

        wr_en = 1;
        expect = 8'b10101010;
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            wr_addr = i[7:0];
            if (i > 0)
                rd_addr = wr_addr - 1;
            wr_data = expect;
            #10;

            if (i > 0) begin
                pass = (rd_data === ~expect);

                if (!pass)
                    $display("FAIL: dpram[%2d] = %08b, expected %08b", rd_addr, rd_data, expect);

                if (overall_pass)
                    overall_pass = pass;
            end

            expect = ~expect;
        end


        if (overall_pass)
            $display("test: dpram: PASS");
        else
            $display("test: dpram: FAIL");

        $finish();
    end
endmodule
