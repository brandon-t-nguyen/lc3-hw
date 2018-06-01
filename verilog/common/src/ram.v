/**
 * Single ported RAM
 * 1 r/w port
 */
module spram #(parameter ADDR_WIDTH = 8, DATA_WIDTH = 8, DATA_DEPTH = 256)
    (
        input   wire                    clk,
        input   wire                    wr_en,
        input   wire [ADDR_WIDTH-1:0]   addr,
        input   wire [DATA_WIDTH-1:0]   wr_data,
        output  reg  [DATA_WIDTH-1:0]   rd_data
    );

    reg [DATA_WIDTH-1:0] mem[0:DATA_DEPTH-1];

    always @(posedge clk) begin
        if (wr_en) begin
            mem[addr] <= wr_data;
        end else begin
            rd_data <= mem[addr];
        end
    end
endmodule

/**
 * Dual ported RAM
 * 1 read, 1 write port
 */
module dpram #(parameter ADDR_WIDTH = 8, DATA_WIDTH = 8, DATA_DEPTH = 256)
    (
        input   wire                    clk,
        input   wire                    wr_en,
        input   wire [ADDR_WIDTH-1:0]   wr_addr,
        input   wire [DATA_WIDTH-1:0]   wr_data,
        input   wire [ADDR_WIDTH-1:0]   rd_addr,
        output  reg  [DATA_WIDTH-1:0]   rd_data
    );

    reg [DATA_WIDTH-1:0] mem[0:DATA_DEPTH-1];

    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
        rd_data <= mem[rd_addr];
    end
endmodule
