`define CHECK (pass ? "PASS" : "FAIL")
module test_tristate;

    reg in;
    reg en;
    wire out;

    tristate #(1) ts(in, out, en);

    localparam N = 4;
    reg [1:N] test_in = 8'b0011;
    reg [1:N] test_en = 8'b0101;
    reg [1:N] exp_out = 8'bz0z1;

    integer i;

    integer pass;
    integer overall_pass;
    initial begin
        $dumpfile("test_tristate.vcd");
        $dumpvars(0, test_tristate);

        overall_pass = 1;
        for (i = 1; i <= N; i = i + 1) begin
            #1;
            in = test_in[i];
            en = test_en[i];
            #1;

            pass = (out === exp_out[i]);
            if (overall_pass)
                overall_pass = pass;
            $display("in=%0d, en=%0d => out=%0d, exp=%0d [%s]", in, en, out, exp_out[i], `CHECK);
        end


        if (overall_pass)
            $display("PASS");
        else
            $display("FAIL");

        $finish();
    end
endmodule
