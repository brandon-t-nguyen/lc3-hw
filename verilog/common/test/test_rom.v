`define CHECK (pass ? "PASS" : "FAIL")
module test_rom;
    localparam A_W = 4;
    localparam D_W = 8;
    localparam D_D = 16;


    reg [A_W-1:0] addr;
    wire [D_W-1:0] data_b;
    wire [D_W-1:0] data_h;

    rom #(
            .ADDR_WIDTH(A_W),
            .DATA_WIDTH(D_W),
            .DATA_DEPTH(D_D),
            .DATA_FILE("data/rom.bin"),
            .HEX(0)
         )
        rom_b(addr, data_b);

    rom #(
            .ADDR_WIDTH(A_W),
            .DATA_WIDTH(D_W),
            .DATA_DEPTH(D_D),
            .DATA_FILE("data/rom.hex"),
            .HEX(1)
         )
        rom_h(addr, data_h);

    integer i;
    integer pass;
    integer overall_pass;
    reg [D_W-1:0] expect;
    initial begin
        $dumpfile("test_rom.vcd");
        $dumpvars(0, test_rom);

        overall_pass = 1;

        for (i = 0; i < D_D; i = i + 1) begin
            #1;
            addr   = i;
            expect = {i[3:0],i[3:0]};

            #1;
            pass = (expect === data_b);
            if (!pass)
                $display("rom_b[%02d] = 0x%2x, expected 0x%2x", addr, data_b, expect);

            pass = (expect === data_h);
            if (!pass)
                $display("rom_h[%02d] = 0x%2x, expected 0x%2x", addr, data_h, expect);

            if (overall_pass)
                overall_pass = pass;
        end


        if (overall_pass)
            $display("test: rom: PASS");
        else
            $display("test: rom: FAIL");

        $finish();
    end
endmodule
