module test_clk_div_e;

    reg clk;
    always #5 clk = ~clk;

    reg arst_n;
    wire clk_out;

    clk_div_e #(4) div (.arst_n(arst_n), .clk_ref(clk), .clk_out(clk_out));

    integer i;
    initial begin
        $dumpfile("test_clk_div_e.vcd");
        $dumpvars(0, test_clk_div_e);

        arst_n = 1;
        clk = 0;

        /*
        #10;
        arst_n = 0;
        #12;
        arst_n = 1;
        */

        for (i = 0; i < 50; i = i + 1) begin
            @(posedge clk);
        end

        #10;
        arst_n = 0;
        #12;
        arst_n = 1;

        for (i = 0; i < 50; i = i + 1) begin
            @(posedge clk);
        end



        $finish();
    end
endmodule

module test_clk_div_o;
    reg clk;
    always #5 clk = ~clk;

    reg arst_n;
    wire clk_out;

    clk_div_o #(3) div (.arst_n(arst_n), .clk_ref(clk), .clk_out(clk_out));

    integer i;
    initial begin
        $dumpfile("test_clk_div_o.vcd");
        $dumpvars(0, test_clk_div_o);

        arst_n = 1;
        clk = 0;

        #10;
        arst_n = 0;
        #12;
        arst_n = 1;

        for (i = 0; i < 50; i = i + 1) begin
            @(posedge clk);
        end

        $finish();
    end
endmodule
