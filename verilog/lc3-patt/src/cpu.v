/**
 * LC-3 Patt microarchitecture CPU module
 * As per Appendix C
 *
 * I'm interpreting the CPU as what is being wrapped by the bus
 * in Figures C.3/C.8: the CPU will expose memory related control signals
 * as output pins, as well as taking in the memory ready signal as
 * an input. The memory controller will be a separate module.
 */

module cpu
    (
        input   wire        clk,
        inout   wire [15:0] bus,

        // memory controller interface
        input   wire        mem_rdy,
        output  wire        mem_ld_mdr,
        output  wire        mem_ld_mar,
        output  wire        mem_mio_en,
        output  wire        mem_rw

        // interrupt controller interface
        input   wire        int_int,
        output  wire        int_gate_vec,
        output  wire        int_ld_vec,
        output  wire [2:0]  int_vec_mux,
    );

    reg [5:0]   cs; // current state: micro-address
    wire [5:0]  ns; // next micro-address

    /*
     * registers
     */
    // register file
    reg [15:0]  r_reg[0:7];

    // special registers
    reg [15:0]  r_pc;
    reg [15:0]  r_ir;
    reg [15:0]  r_s_usp;    // saved user stack ptr
    reg [15:0]  r_s_ssp;    // saved user supervisor ptr

    // psr registers
    reg [0:0]   r_priv;
    reg [2:0]   r_pri;
    reg [0:0]   r_cc_n;
    reg [0:0]   r_cc_z;
    reg [0:0]   r_cc_p;

    always @(posedge clk) begin
    end

endmodule
