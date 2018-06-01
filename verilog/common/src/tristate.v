/**
 * Tristate buffer
 */

module tristate #(parameter WIDTH = 1)
    (
        input   wire [WIDTH-1:0] in,
        output  wire [WIDTH-1:0] out,
        input   wire             en
    );

    assign out = en ? in: {WIDTH{1'bz}};
endmodule
