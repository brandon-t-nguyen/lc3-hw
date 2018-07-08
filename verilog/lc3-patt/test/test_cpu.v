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

    integer i;
    initial begin
        $dumpfile("wave_cpu.vcd");
        $dumpvars(0, test_cpu);

        clk = 0;
        arst_n = 1;
        for (i = 0; i < 4; i = i + 1) @(posedge clk);

        $finish();
    end

endmodule

module mem #(parameter DATA_PATH = "data/data.hex")
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
