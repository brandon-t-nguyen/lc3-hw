/**
 * Register for structural use
 * Registers are asynchronous-read, synchronous write
 */

module register #(parameter WIDTH = 1)
    (
        input   wire        clk,        // clock
        input   wire        wr_en,      // write enable
        input   wire [WIDTH-1:0] d_i,   // data in
        output  wire [WIDTH-1:0] d_o    // data out
    );

    reg [WIDTH-1] data;
    assign d_o = data;

    always @(posedge clk) begin
        if (wr_en)
            data <= d_i;
    end
endmodule
