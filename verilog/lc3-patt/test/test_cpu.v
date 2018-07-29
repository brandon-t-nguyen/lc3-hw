module test_cpu;

    reg clk;
    always #5 clk = ~clk;

    reg arst_n;

    wire [15:0] bus;
    wire mem_rdy, mem_ld_mdr, mem_ld_mar, mem_gate_mdr, mem_mio_en, mem_rw;
    wire int_gate_vec, int_ld_vec;
    wire [2:0] int_pri, int_vec_mux;

    cpu #("data/ucode.bin") lc3
        (
            .arst_n(arst_n),
            .clk(clk),
            .bus(bus),

            .mem_rdy(mem_rdy),
            .mem_ld_mdr(mem_ld_mdr),
            .mem_ld_mar(mem_ld_mar),
            .mem_gate_mdr(mem_gate_mdr),
            .mem_mio_en(mem_mio_en),
            .mem_rw(mem_rw),

            //.int_pri(int_pri),
            .int_pri(3'b000),
            .int_gate_vec(int_gate_vec),
            .int_ld_vec(int_ld_vec),
            .int_vec_mux(int_vec_mux)
        );

    mem memory
        (
            .clk(clk),
            .rdy(mem_rdy),
            .ld_mdr(mem_ld_mdr),
            .ld_mar(mem_ld_mar),
            .gate_mdr(mem_gate_mdr),
            .mio_en(mem_mio_en),
            .rw(mem_rw),

            .bus(bus)
        );

    integer file;
    integer pass;
    integer i;
    integer line;

    integer test;
    integer status;
    reg [15:0] src;
    reg [7:0] cmd, idx, base;
    reg [15:0] assert;
    reg [15:0] actual;

    initial begin
        $dumpfile("wave_cpu.vcd");
        $dumpvars(0, test_cpu);

        clk = 0;
        arst_n = 1;

        pass = 1;
        file = $fopen("test_cpu.test", "r");
        line = 0;

        while (!$feof(file)) begin
            status = $fscanf(file, "%c ", cmd);
            if (cmd == "n") begin
                line = line + 1;
                assert = 1;
                status = $fscanf(file, "%d ", assert);
                for (i = 0; i < assert; i = i + 1) begin
                    #10;
                    while (lc3.cs != 18) #10;
                end
            end
            // assert
            else if (cmd == "a") begin
                line = line + 1;
                status = $fscanf(file, "%s ", src);
                //status = $fscanf(file, "%c %d %c", src, idx, base);

                if (src == "r" || src == "m") begin
                    status = $fscanf(file, "%d %c", idx, base);
                end
                else if (src == "pc") begin
                    status = $fscanf(file, "%c", base);
                end

                if (base == "d") begin
                    status = $fscanf(file, "%d", assert);
                end
                else if (base == "h") begin
                    status = $fscanf(file, "%x", assert);
                end

                if (src == "r") begin
                    actual = lc3.r_reg[idx];
                end
                else if (src == "m") begin
                    actual = memory.ram[idx];
                end
                else if (src == "pc") begin
                    actual = lc3.r_pc;
                end

                test = (actual == assert);
                if (pass && !test)
                    pass = 0;
                if (!test) begin
                    if (src == "pc") begin
                        if (base == "d") begin
                            $display("[%2d]Expected %s = %d, actual = %d", line, src, assert, actual);
                        end
                        else if (base == "h") begin
                            $display("[%2d] Expected %s = 0x%04x, actual = 0x%04x", line, idx, assert, actual);
                        end
                    end
                    else begin
                        if (base == "d") begin
                            $display("[%2d] Expected %s[%2d] = %d, actual = %d", line, src, idx, assert, actual);
                        end
                        else if (base == "h") begin
                            $display("[%2d] Expected %s[%2d] = 0x%04x, actual = 0x%04x", line, src, idx, assert, actual);
                        end
                    end
                end
            end
        end

        $display("TEST COMPLETE: %s", pass ? "PASS" : "FAIL");
        $finish();
    end

endmodule

module mem #(parameter DATA_PATH = "data/test.hex")
    (
        input clk,
        inout [15:0] bus,

        output wire rdy,
        input wire ld_mdr,
        input wire ld_mar,
        input wire gate_mdr,
        input wire mio_en,
        input wire rw
    );

    reg [15:0] ram [0:65535];

    reg [15:0] mar;
    reg [15:0] mdr;

    tsb_h #(16) tsb_mdr(mdr, bus, gate_mdr);
    assign rdy = 1;

    integer i;
    initial begin
        for (i = 0; i < 16'hfe00; i = i + 1)
            ram[i] = 16'h0000;
        $readmemh(DATA_PATH, ram);
    end

    always @(posedge clk) begin
        if (ld_mdr) begin
            if (mio_en)
                mdr <= ram[mar];
            else
                mdr <= bus;
        end
        if (ld_mar) mar <= bus;
    end

endmodule