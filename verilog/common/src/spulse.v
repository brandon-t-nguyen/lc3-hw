// Single pulser
module spulse(
        input wire  in,  // debounced, synchronized input
        input wire  clk, // clock to do a single pulse on
        output wire out  // single pulsed output
    );

    reg state; // flipflop holding state

    assign out = in & (~state);
    always @(posedge clk) begin
        state <= in;
    end

endmodule
