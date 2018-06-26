module test_mau;
    reg clk;
    always #5 clk = ~clk;

    // MAU signals
    reg arst_n;
    reg [15:0] bus;
    wire [15:0] bus_shim = bus;
    reg cpu_ld_mdr;
    reg cpu_ld_mar;
    reg cpu_gate_mdr;
    reg cpu_mio_en;
    reg cpu_rw;
    wire cpu_rdy;

    wire mem_init_txn;
    wire mem_wtxn;
    wire [15:0] mem_addr;
    wire [15:0] mem_wdata;
    reg [15:0] mem_rdata;
    reg mem_rdy;

    wire per_init_txn;
    wire per_wtxn;
    wire [7:0] per_addr;
    wire [15:0] per_wdata;
    reg [15:0] per_rdata;
    reg per_rdy;

    mau northbridge
        (
            .arst_n(arst_n),
            .clk(clk),
            .bus(bus_shim),
            .cpu_ld_mdr(cpu_ld_mdr),
            .cpu_ld_mar(cpu_ld_mar),
            .cpu_gate_mdr(cpu_gate_mdr),
            .cpu_mio_en(cpu_mio_en),
            .cpu_rw(cpu_rw),
            .cpu_rdy(cpu_rdy),

            .mem_init_txn(mem_init_txn),
            .mem_wtxn(mem_wtxn),
            .mem_addr(mem_addr),
            .mem_wdata(mem_wdata),
            .mem_rdata(mem_rdata),
            .mem_rdy(mem_rdy),

            .per_init_txn(per_init_txn),
            .per_wtxn(per_wtxn),
            .per_addr(per_addr),
            .per_wdata(per_wdata),
            .per_rdata(per_rdata),
            .per_rdy(per_rdy)
        );

    integer i;
    integer pass;
    integer overall_pass;
    initial begin
        $dumpfile("test_mau.vcd");
        $dumpvars(0, test_mau);

        overall_pass = 1;
        clk = 0;

        // initial signals
        arst_n = 1;
        bus = 16'bz;
        cpu_ld_mdr = 0; cpu_ld_mar = 0; cpu_gate_mdr = 0;
        cpu_mio_en = 0; cpu_rw = 0;

        mem_rdata = 0;
        mem_rdy = 1;

        per_rdata = 0;
        per_rdy = 1;

        //  test a write to memory
        //      mem[0xdead]=0xbeef
        bus = 16'hdead; cpu_ld_mar = 1;
        @(posedge clk);

        cpu_ld_mar = 0;
        cpu_ld_mdr = 1;
        bus = 16'hbeef;
        @(posedge clk);
        cpu_ld_mdr = 0;

        cpu_rw = 1;
        cpu_mio_en = 1;
        @(posedge clk);
        //      at this point, the transaction has started
        //      mem_init_txn should be strobed with wtxn
        pass = (mem_init_txn === 1); overall_pass = overall_pass & pass;
        if (!pass)
            $display("write mem[0xdead]=0xbeef: mem_init_txn != 1");

        #100;

        if (overall_pass)
            $display("test: register: PASS");
        else
            $display("test: register: FAIL");

        $finish();
    end
endmodule
