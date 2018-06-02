/**
 * Tristate buffer: active high
 */
module tsb_h #(parameter WIDTH = 1)
    (
        input   wire [WIDTH-1:0] in,
        output  wire [WIDTH-1:0] out,
        input   wire             en
    );

    assign out = en ? in: {WIDTH{1'bz}};
endmodule

/**
 * Tristate buffer: active low
 */
module tsb_l #(parameter WIDTH = 1)
    (
        input   wire [WIDTH-1:0] in,
        output  wire [WIDTH-1:0] out,
        input   wire             en_n
    );

    assign out = en_n ? {WIDTH{1'bz}} : in;
endmodule
