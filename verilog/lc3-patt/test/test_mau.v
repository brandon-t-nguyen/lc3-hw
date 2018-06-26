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
        bus = 16'hdead;
        cpu_ld_mar = 1;
        @(posedge clk);
        bus = 16'bz;

        cpu_ld_mar = 0;
        cpu_ld_mdr = 1;

        bus = 16'hbeef;
        @(posedge clk);
        bus = 16'bz;

        cpu_ld_mdr = 0;
        cpu_rw = 1;
        cpu_mio_en = 1;

        #1;
        pass = (cpu_rdy === 0); overall_pass = overall_pass & pass;
        if (!pass) $display("write mem[0xdead]=0xbeef: cpu_rdy != 0");
        @(posedge clk);
        //      at this point, the transaction has started
        //      mem_init_txn and mem_wtxn should be strobed, w/ appropriate addr and data
        pass = (mem_init_txn === 1); overall_pass = overall_pass & pass;
        if (!pass) $display("write mem[0xdead]=0xbeef: mem_init_txn != 1");

        pass = (mem_wtxn === 1); overall_pass = overall_pass & pass;
        if (!pass) $display("write mem[0xdead]=0xbeef: mem_wtxn != 1");

        pass = (mem_addr === 16'hdead); overall_pass = overall_pass & pass;
        if (!pass) $display("write mem[0xdead]=0xbeef: mem_addr != 0xdead");

        pass = (mem_wdata === 16'hbeef); overall_pass = overall_pass & pass;
        if (!pass) $display("write mem[0xdead]=0xbeef: mem_wdata != 0xbeef");

        pass = (cpu_rdy === 0); overall_pass = overall_pass & pass;
        if (!pass) $display("write mem[0xdead]=0xbeef: cpu_rdy != 0");

        //      transaction has started
        mem_rdy = 0;
        //      delay a bit
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        mem_rdy = 1;

        @(posedge clk);
        //      cycle later, cpu should be ready
        pass = (cpu_rdy === 1); overall_pass = overall_pass & pass;
        if (!pass) $display("write mem[0xdead]=0xbeef: cpu_rdy != 1");

        @(posedge clk);
        cpu_rw = 0;
        cpu_mio_en = 0;
        @(posedge clk);


        //  test a read from memory
        //      mem[0xcafe]=0xbabe
        bus = 16'hcafe;
        cpu_ld_mar = 1;
        @(posedge clk);
        bus = 16'bz;

        cpu_rw = 0;
        cpu_mio_en = 1;
        cpu_ld_mdr = 1;
        cpu_ld_mar = 0;

        #1;
        pass = (cpu_rdy === 0); overall_pass = overall_pass & pass;
        if (!pass) $display("read mem[0xcafe]=0xbabe: cpu_rdy != 0");

        @(posedge clk);
        //      at this point, txn has started
        //      mem_init_txn should be strobed w/ appropriate addr
        pass = (mem_init_txn === 1); overall_pass = overall_pass & pass;
        if (!pass) $display("read mem[0xcafe]=0xbabe: mem_init_txn != 1");

        pass = (mem_wtxn === 0); overall_pass = overall_pass & pass;
        if (!pass) $display("read mem[0xcafe]=0xbabe: mem_wtxn != 1");

        pass = (mem_addr === 16'hcafe); overall_pass = overall_pass & pass;
        if (!pass) $display("read mem[0xcafe]=0xbabe: mem_addr != 0xcafe");

        pass = (cpu_rdy === 0); overall_pass = overall_pass & pass;
        if (!pass) $display("read mem[0xcafe]=0xbabe: cpu_rdy != 0");

        //      transaction has started
        mem_rdy = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        mem_rdata = 16'hbabe;
        mem_rdy = 1;
        @(posedge clk);
        pass = (cpu_rdy === 1); overall_pass = overall_pass & pass;
        if (!pass) $display("read mem[0xcafe]=0xbabe: cpu_rdy != 1");

        @(posedge clk);
        cpu_rw = 0;
        cpu_mio_en = 0;
        cpu_ld_mdr  = 0;
        cpu_gate_mdr = 1;
        //      see if MDR gets on the bus
        #1;
        pass = (bus_shim === 16'hbabe); overall_pass = overall_pass & pass;
        if (!pass) $display("read mem[0xcafe]=0xbabe: bus != 0xbabe");

        #100;

        if (overall_pass)
            $display("test: register: PASS");
        else
            $display("test: register: FAIL");

        $finish();
    end
endmodule
