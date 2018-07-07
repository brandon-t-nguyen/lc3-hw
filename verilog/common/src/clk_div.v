/**
 * Assorted clock dividers
 */

// even clock divider
module clk_div_e #(parameter DIV = 2)
    (
        input  wire arst_n,
        input  wire clk_ref,
        output reg  clk_out
    );
    localparam CNT_VAL  = DIV>>1;
    localparam CNT_SIZE = $clog2(CNT_VAL) + 1;

    reg [CNT_SIZE-1:0] cnt;

    initial begin
        // start counter at 0 to not have an
        // early edge flip
        cnt = 0;
        clk_out = 0;
    end

    always @(posedge clk_ref or negedge arst_n) begin
        if (!arst_n) begin
            cnt <= 0;
            clk_out <= 0;
        end else begin
            if (cnt == CNT_VAL - 1) begin
                cnt <= 0;
                clk_out <= ~clk_out;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule

// Concept from "Clock Dividers Made Easy" - Mohit Arora, ST Micro
// https://www.mikrocontroller.net/attachment/177198/Clock_Dividers_Made_Easy.pdf
// odd clock divider
module clk_div_o #(parameter DIV = 3)
    (
        input  wire arst_n,
        input  wire clk_ref,
        output wire clk_out
    );
    localparam CNT_VAL  = DIV - 1;
    localparam CNT_SIZE = $clog2(CNT_VAL) + 1;

    reg [CNT_SIZE-1:0] cnt;

    reg [1:0] tff;      // two T-FF's for two phases of a twice as slow clock
    wire [1:0] tff_en;

    assign tff_en[0] = (cnt == 0);                 // 0  degrees
    assign tff_en[1] = (cnt == ((DIV + 1) >> 1));  // 90 degrees
    assign clk_out = tff[0] ^ tff[1];

    initial begin
        cnt = 0;
        tff <= 0;
    end

    always @(posedge clk_ref or negedge arst_n) begin
        if (!arst_n) begin
            cnt <= 0;
            tff[0] <= 0;
        end else begin
            cnt <= (cnt != CNT_VAL) ? cnt + 1 : 0;
            tff[0] <= tff[0] ^ tff_en[0];
        end
    end

    always @(negedge clk_ref) begin
        if (!arst_n) begin
            tff[1] <= 0;
        end else begin
            tff[1] <= tff[1] ^ tff_en[1];
        end
    end

endmodule
