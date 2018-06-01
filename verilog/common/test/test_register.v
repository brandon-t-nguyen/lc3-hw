`define CHECK (pass ? "PASS" : "FAIL")
module test_register;
    localparam W = 8;

    reg clk;
    always #5 clk = ~clk;

    reg [W-1:0] d_i;
    reg wr_en;
    wire [W-1:0] d_o;
    register #(8) r0(.clk(clk), .wr_en(wr_en), .d_i(d_i), .d_o(d_o));

    localparam N = 4;
    reg [W-1:0] test_d_i   [0:N-1];
    reg         test_wr_en [0:N-1];
    reg [W-1:0] exp_d_o    [0:N-1];

    initial begin
        test_d_i[0] =  0; test_wr_en[0] = 1; exp_d_o[0] = 0;
        test_d_i[1] =  5; test_wr_en[1] = 0; exp_d_o[1] = 0;
        test_d_i[2] =  5; test_wr_en[2] = 1; exp_d_o[2] = 5;
        test_d_i[3] = 10; test_wr_en[3] = 1; exp_d_o[3] = 10;
        test_d_i[4] = 20; test_wr_en[4] = 0; exp_d_o[4] = 10;
    end

    integer i;
    integer pass;
    integer overall_pass;
    initial begin
        $dumpfile("test_register.vcd");
        $dumpvars(0, test_register);

        overall_pass = 1;

        clk = 0;

        #2;
        for (i = 0; i < N; i = i + 1) begin
            d_i = test_d_i[i];
            wr_en = test_wr_en[i];

            #5;

            pass = (d_o === exp_d_o[i]);
            if (overall_pass)
                overall_pass = pass;
            $display("d_i = %2d, wr_en=%1d => d_o = %2d, exp = %2d [%s]", d_i, wr_en, d_o, exp_d_o[i], `CHECK);
            #5;
        end


        if (overall_pass)
            $display("PASS");
        else
            $display("FAIL");

        $finish();
    end
endmodule
