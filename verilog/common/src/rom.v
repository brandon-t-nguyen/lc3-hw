module rom #(parameter ADDR_WIDTH = 8, DATA_WIDTH = 8, DATA_DEPTH = 8, DATA_FILE = "null", HEX = 0)
    (
        input   wire [ADDR_WIDTH-1:0] addr,
        output  wire [DATA_WIDTH-1:0] data
    );

    reg [DATA_WIDTH-1:0] contents [0:DATA_DEPTH-1];
    assign data = contents[addr];

    integer i;
    initial begin
        if (DATA_FILE != "null") begin
            if (HEX) begin
                $readmemh(DATA_FILE, contents);
            end else begin
                $readmemb(DATA_FILE, contents);
            end
        end
        else begin
            for (i = 0; i < DATA_DEPTH; i = i + 1) begin
                contents[i] = 0;
            end
        end
    end

endmodule
