module test_23X256;

    reg cs_n;
    reg hold_n;
    reg sck;
    reg si;
    wire so;
    reg [7:0] rx;


    localparam INST_READ = 8'b0000_0011;
    localparam INST_WRIT = 8'b0000_0010;
    localparam INST_RDSR = 8'b0000_0101;
    localparam INST_WRSR = 8'b0000_0001;

    reg [0:31] wr_inst = {
                            INST_WRIT,
                            16'h0123,
                            8'h25
                          };
    reg [0:31] rd_inst = {
                            INST_READ,
                            16'h0123,
                            8'bx
                          };

    reg [0:15] wrsr_inst = {INST_WRSR, 8'b0100_0000};
    reg [0:15] rdsr_inst = {INST_RDSR, 8'bx};

    // put into sequential mode: write stuff
    reg [0:63] wrsq_inst = {
                            INST_WRIT,
                            16'h3000,
                            8'h12,
                            8'h34,
                            8'h56,
                            8'h78,
                            8'h90
                           };

    reg [0:63] rdsq_inst = {
                            INST_READ,
                            16'h3000,
                            8'hxx,
                            8'hxx,
                            8'hxx,
                            8'hxx,
                            8'hxx
                           };

    // put into page mode
    reg [0:15] wrsr_page = {INST_WRSR, 8'b1000_0000};
    reg [0:63] wrpg_inst = {
                            INST_WRIT,
                            16'h201E,
                            8'h09,
                            8'h87,
                            8'h65,
                            8'h43,
                            8'h21
                           };

    reg [0:63] rdpg_inst = {
                            INST_READ,
                            16'h201E,
                            8'hxx,
                            8'hxx,
                            8'hxx,
                            8'hxx,
                            8'hxx
                           };

    microchip_23X256 sram
        (
            .cs_n(cs_n),
            .so(so),
            .hold_n(hold_n),
            .sck(sck),
            .si(si)
        );

    integer i;
    initial begin
        $dumpfile("test_23X256.vcd");
        $dumpvars(0, test_23X256);

        cs_n = 1;
        hold_n = 1;
        sck = 0;
        si = 1'bz;
        rx = 0;

        #50;

        cs_n = 0;
        for (i = 0; i < 32; i = i + 1) begin
            sck = 0;
            si = wr_inst[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;

        cs_n = 0;
        for (i = 0; i < 32; i = i + 1) begin
            sck = 0;
            si = rd_inst[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;
        $display("mem[0x0123]= 0x%02x", sram.data[15'h0123]);

        cs_n = 0;
        for (i = 0; i < 16; i = i + 1) begin
            sck = 0;
            si = wrsr_inst[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;

        cs_n = 0;
        for (i = 0; i < 16; i = i + 1) begin
            sck = 0;
            si = rdsr_inst[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;
        $display("SR= %04b_%04b", {sram.mode, 2'b0}, {3'b0, sram.hold_en});

        cs_n = 0;
        for (i = 0; i < 64; i = i + 1) begin
            sck = 0;
            si = wrsq_inst[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;
        $display("mem[0x3000]= 0x%02x", sram.data[15'h3000]);
        $display("mem[0x3001]= 0x%02x", sram.data[15'h3001]);
        $display("mem[0x3002]= 0x%02x", sram.data[15'h3002]);
        $display("mem[0x3003]= 0x%02x", sram.data[15'h3003]);
        $display("mem[0x3004]= 0x%02x", sram.data[15'h3004]);

        cs_n = 0;
        for (i = 0; i < 64; i = i + 1) begin
            sck = 0;
            si = rdsq_inst[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;

        cs_n = 0;
        for (i = 0; i < 16; i = i + 1) begin
            sck = 0;
            si = wrsr_page[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;

        cs_n = 0;
        for (i = 0; i < 64; i = i + 1) begin
            sck = 0;
            si = wrpg_inst[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;
        $display("mem[0x201E]= 0x%02x", sram.data[15'h201E]);
        $display("mem[0x201F]= 0x%02x", sram.data[15'h201F]);
        $display("mem[0x2000]= 0x%02x", sram.data[15'h2000]);
        $display("mem[0x2001]= 0x%02x", sram.data[15'h2001]);
        $display("mem[0x2002]= 0x%02x", sram.data[15'h2002]);

        cs_n = 0;
        for (i = 0; i < 64; i = i + 1) begin
            sck = 0;
            si = rdpg_inst[i];
            #5;
            rx = {rx[6:0], so};
            sck = 1;
            #5;
        end
        sck = 0;
        #5;
        cs_n = 1;
        #5;

        $finish();
    end
endmodule
