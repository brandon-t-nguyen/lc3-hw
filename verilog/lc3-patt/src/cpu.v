/**
 * LC-3 Patt microarchitecture CPU module
 * As per Appendix C
 *
 * I'm interpreting the CPU as what is being wrapped by the bus
 * in Figures C.3/C.8: the CPU will expose memory related control signals
 * as output pins, as well as taking in the memory ready signal as
 * an input. The memory controller will be a separate module.
 */

module cpu #(parameter UCODE_PATH = "data/ucode.bin")
    (
        input   wire        clk,
        inout   wire [15:0] bus,

        // memory controller interface
        input   wire        mem_rdy,
        output  wire        mem_ld_mdr,
        output  wire        mem_ld_mar,
        output  wire        mem_gate_mdr,
        output  wire        mem_mio_en,
        output  wire        mem_rw,

        // interrupt controller interface
        input   wire        int_int,
        output  wire        int_gate_vec,
        output  wire        int_ld_vec,
        output  wire [2:0]  int_vec_mux
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
    reg         r_priv;
    reg [2:0]   r_pri;
    reg         r_cc_n;
    reg         r_cc_z;
    reg         r_cc_p;

    /*
     * control store
     */
    wire [48:0] ctrl;   // control signals
    rom #(.ADDR_WIDTH(6),
          .DATA_WIDTH(49),
          .DATA_DEPTH(64),
          .DATA_FILE(UCODE_PATH),
          .HEX(0))
        control_store
        (
            .addr(cs),
            .data(ctrl)
        );

    /*
     * control signals
     */
    wire        c_ird       = ctrl[48];
    wire [2:0]  c_cond      = ctrl[47:45];
    wire [5:0]  c_j         = ctrl[44:39];
    wire        c_ld_mar    = ctrl[38];
    wire        c_ld_mdr    = ctrl[37];
    wire        c_ld_ir     = ctrl[36];
    wire        c_ld_ben    = ctrl[35];
    wire        c_ld_reg    = ctrl[34];
    wire        c_ld_cc     = ctrl[33];
    wire        c_ld_pc     = ctrl[32];
    wire        c_ld_priv   = ctrl[31];
    wire        c_ld_s_ssp  = ctrl[30];
    wire        c_ld_s_usp  = ctrl[29];
    wire        c_ld_vec    = ctrl[28];
    wire        c_gt_pc     = ctrl[27];
    wire        c_gt_mdr    = ctrl[26];
    wire        c_gt_alu    = ctrl[25];
    wire        c_gt_marmux = ctrl[24];
    wire        c_gt_vec    = ctrl[23];
    wire        c_gt_pc_dec = ctrl[22];
    wire        c_gt_psr    = ctrl[21];
    wire        c_gt_sp     = ctrl[20];
    wire [1:0]  c_pcmux     = ctrl[19:18];
    wire [1:0]  c_drmux     = ctrl[17:16];
    wire [1:0]  c_sr1mux    = ctrl[15:14];
    wire        c_addr1mux  = ctrl[13];
    wire [1:0]  c_addr2mux  = ctrl[12:11];
    wire [1:0]  c_spmux     = ctrl[10:9];
    wire        c_marmux    = ctrl[8];
    wire [1:0]  c_vecmux    = ctrl[7:6];
    wire        c_psrmux    = ctrl[5];
    wire [1:0]  c_aluk      = ctrl[4:3];
    wire        c_mio_en    = ctrl[2];
    wire        c_rw        = ctrl[1];
    wire        c_set_priv  = ctrl[0];

    always @(posedge clk) begin
    end

endmodule
