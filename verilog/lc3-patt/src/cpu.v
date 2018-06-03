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
        input   wire [2:0]  int_pri,
        output  wire        int_gate_vec,
        output  wire        int_ld_vec,
        output  wire [2:0]  int_vec_mux
    );

    reg [5:0]   cs; // current state: micro-address

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
    wire [2:0]  a_cc = {r_cc_n, r_cc_z, r_cc_p};

    // other internal registers
    reg         r_ben;

    /*
     * control store
     */
    wire [48:0] uinst;   // microinstruction
    rom #(.ADDR_WIDTH(6),
          .DATA_WIDTH(49),
          .DATA_DEPTH(64),
          .DATA_FILE(UCODE_PATH),
          .HEX(0))
        control_store
        (
            .addr(cs),
            .data(uinst)
        );

    /*
     * control signals
     */
    wire        c_ird       = uinst[48];
    wire [2:0]  c_cond      = uinst[47:45];
    wire [5:0]  c_j         = uinst[44:39];
    wire        c_ld_mar    = uinst[38]; assign mem_ld_mar = c_ld_mar;
    wire        c_ld_mdr    = uinst[37]; assign mem_ld_mdr = c_ld_mdr;
    wire        c_ld_ir     = uinst[36];
    wire        c_ld_ben    = uinst[35];
    wire        c_ld_reg    = uinst[34];
    wire        c_ld_cc     = uinst[33];
    wire        c_ld_pc     = uinst[32];
    wire        c_ld_priv   = uinst[31];
    wire        c_ld_s_ssp  = uinst[30];
    wire        c_ld_s_usp  = uinst[29];
    wire        c_ld_vec    = uinst[28]; assign int_ld_vec = c_ld_vec;
    wire        c_gt_pc     = uinst[27];
    wire        c_gt_mdr    = uinst[26]; assign mem_gate_mdr = c_gt_mdr;
    wire        c_gt_alu    = uinst[25];
    wire        c_gt_mar_mux= uinst[24];
    wire        c_gt_vec    = uinst[23]; assign int_gate_vec = c_gt_vec;
    wire        c_gt_pc_dec = uinst[22];
    wire        c_gt_psr    = uinst[21];
    wire        c_gt_sp     = uinst[20];
    wire [1:0]  c_pc_mux    = uinst[19:18];
    wire [1:0]  c_dr_mux    = uinst[17:16];
    wire [1:0]  c_sr1_mux   = uinst[15:14];
    wire        c_addr1_mux = uinst[13];
    wire [1:0]  c_addr2_mux = uinst[12:11];
    wire [1:0]  c_sp_mux    = uinst[10:9];
    wire        c_mar_mux   = uinst[8];
    wire [1:0]  c_vec_mux   = uinst[7:6]; assign int_vec_mux = c_vec_mux;
    wire        c_psr_mux   = uinst[5];
    wire [1:0]  c_aluk      = uinst[4:3];
    wire        c_mio_en    = uinst[2]; assign mem_mio_en = c_mio_en;
    wire        c_rw        = uinst[1]; assign mem_rw = c_rw;
    wire        c_set_priv  = uinst[0];

    /*
     * combinational signals
     */
    // mux results
    reg [15:0] cb_pc_mux;
    reg [2:0]  cb_dr;
    reg [2:0]  cb_sr1;
    reg [15:0] cb_addr1_mux;
    reg [15:0] cb_addr2_mux;
    reg [15:0] cb_sp_mux;
    reg [15:0] cb_mar_mux;
    // vector mux handled by interrupt controller

    // psr mux is handled by multiple muxes
    reg [2:0]  cb_cc_mux;
    reg [2:0]  cb_pri_mux;
    reg        cb_priv_mux;

    reg [15:0] cb_sr2_mux;

    reg [15:0] cb_addr_add;
    reg [15:0] cb_pc_inc;
    reg [15:0] cb_pc_dec;
    reg [15:0] cb_alu;
    reg [2:0]  cb_sr2;
    reg [15:0] cb_sr1_out;
    reg [15:0] cb_sr2_out;
    reg [15:0] cb_alu_a;
    reg [15:0] cb_alu_b;
    reg [15:0] cb_base_r;
    reg        cb_addr_mode; // determines value of sr2_mux
    reg        cb_cc_n;
    reg        cb_cc_z;
    reg        cb_cc_p;

    // interrupt stuff
    reg [15:0] cb_sp_inc;
    reg [15:0] cb_sp_dec;

    always @(*) begin
        /*
         * intermediate signals
         */
        cb_addr_add = cb_addr1_mux + cb_addr2_mux;
        cb_pc_inc = r_pc + 1;
        cb_pc_dec = r_pc - 1;
        cb_addr_mode = r_ir[5];
        cb_sr2 = r_ir[2:0];
        cb_sr1_out = r_reg[cb_sr1];
        cb_sr2_out = r_reg[cb_sr2];
        cb_alu_a = cb_sr1_out;
        cb_alu_b = cb_sr2_mux;
        cb_base_r = cb_sr1_out;

        case (c_aluk)
            0: cb_alu = cb_alu_a + cb_alu_b;
            1: cb_alu = cb_alu_a &  cb_alu_b;
            2: cb_alu = ~cb_alu_a;
            3: cb_alu = cb_alu_a;
            default: cb_alu = 16'bx;
        endcase

        // condition codes
        cb_cc_n = bus[15];
        cb_cc_z = (bus == 0);
        cb_cc_p = !(cb_cc_n | cb_cc_z);

        // interrupt signals
        cb_sp_inc = cb_sr1_out + 1;
        cb_sp_dec = cb_sr1_out - 1;

        /*
         * muxes
         */
        // pc mux
        case (c_pc_mux)
            0: cb_pc_mux = cb_pc_inc;
            1: cb_pc_mux = bus;
            2: cb_pc_mux = cb_addr_add;
            default: cb_pc_mux = 16'bx;
        endcase

        // dr mux
        case (c_dr_mux)
            0: cb_dr = r_ir[11:9];
            1: cb_dr = 3'd7;
            2: cb_dr = 3'd6;
            default: cb_dr = 3'bx;
        endcase

        // sr1 mux
        case (c_sr1_mux)
            0: cb_sr1 = r_ir[11:9];
            1: cb_sr1 = r_ir[8:6];
            2: cb_sr1 = 3'd6;
            default: cb_sr1 = 3'bx;
        endcase

        // addr1 mux
        case (c_addr1_mux)
            0: cb_addr1_mux = r_pc;
            1: cb_addr1_mux = cb_base_r;
            default: cb_addr1_mux = 16'bx;
        endcase

        // addr2 mux
        case (c_addr2_mux)
            0: cb_addr2_mux = 16'd0;
            1: cb_addr2_mux = {{10{r_ir[5]}}, r_ir[5:0]};
            2: cb_addr2_mux = {{7{r_ir[8]}}, r_ir[8:0]};
            3: cb_addr2_mux = {{5{r_ir[10]}}, r_ir[10:0]};
            default: cb_addr2_mux = 16'bx;
        endcase

        // sp mux
        case (c_sp_mux)
            0: cb_sp_mux = cb_sp_inc;
            1: cb_sp_mux = cb_sp_dec;
            2: cb_sp_mux = r_s_ssp;
            3: cb_sp_mux = r_s_usp;
            default: cb_sp_mux = 16'bx;
        endcase

        // mar mux
        case (c_mar_mux)
            0: cb_mar_mux = {8'b0, r_ir[7:0]};
            1: cb_mar_mux = cb_addr_add;
            default: cb_mar_mux = 16'bx;
        endcase

        // psr mux
        case (c_psr_mux)
            0: begin
                cb_cc_mux   = {cb_cc_n, cb_cc_z, cb_cc_p};
                cb_pri_mux  = int_pri;
                cb_priv_mux = c_set_priv;
            end
            1: begin
                cb_cc_mux   = bus[2:0];
                cb_pri_mux  = bus[10:8];
                cb_priv_mux = bus[15];
            end
            default: begin
                cb_cc_mux   = 3'bx;
                cb_pri_mux  = 3'bx;
                cb_priv_mux = 1'bx;
            end
        endcase

        // sr2 mux (value, not reg number)
        case (cb_addr_mode)
            0: cb_sr2_mux = cb_sr2_out;
            1: cb_sr2_mux = {{11{r_ir[4]}}, r_ir[4:0]};
            default: cb_sr2_mux = 16'bx;
        endcase
    end

    /*
     * microsequencer
     */
    reg [5:0]  ns; // next micro-address

    // qualifiers for the usequencer
    wire q_mem_rdy   = mem_rdy;
    wire q_branch    = r_ben;
    wire q_addr_mode = r_ir[11];
    wire q_priv      = r_priv;
    wire q_interrupt = int_int;
    always @(*) begin
        if (c_ird) begin
            ns = {12'b0, r_ir[15:12]};
        end
        else begin
            ns[5] = c_j[5];
            ns[4] = c_j[4] | (q_interrupt && c_cond == 5);
            ns[3] = c_j[3] | (q_priv      && c_cond == 4);
            ns[2] = c_j[2] | (q_branch    && c_cond == 2);
            ns[1] = c_j[1] | (q_mem_rdy   && c_cond == 1);
            ns[0] = c_j[0] | (q_addr_mode && c_cond == 3);
        end
    end

    /*
     * bus drivers
     */
    tsb_h #(16) tsb_pc(r_pc, bus, c_gt_pc);
    // MDR handled by memory controller
    tsb_h #(16) tsb_alu(cb_alu, bus, c_gt_alu);
    tsb_h #(16) tsb_mar_mux(cb_mar_mux, bus, c_gt_mar_mux);
    tsb_h #(16) tsb_pc_dec(cb_pc_dec, bus, c_gt_pc_dec);

    tsb_h #(1) tsb_priv(r_priv, bus[15], c_gt_psr);
    tsb_h #(3) tsb_pri(r_pri, bus[10:8], c_gt_psr);
    tsb_h #(3) tsb_cc(a_cc, bus[2:0], c_gt_psr);

    tsb_h #(16) tsb_sp(cb_sp_mux, bus, c_gt_sp);

    always @(posedge clk) begin
        cs <= ns;

        // register loads
        // MAR, MDR handled by memory controller
        if (c_ld_ir) r_ir <= bus;
        if (c_ld_ben) begin
            r_ben <= (r_ir[11:9] == a_cc);
        end
        if (c_ld_reg) r_reg[cb_dr] <= bus;
        if (c_ld_cc) begin
            r_cc_n <= cb_cc_mux[2];
            r_cc_z <= cb_cc_mux[1];
            r_cc_p <= cb_cc_mux[0];
        end
        if (c_ld_pc) r_pc <= cb_pc_mux;
        if (c_ld_priv) r_priv <= cb_priv_mux;
        if (c_ld_s_ssp) r_s_ssp <= cb_sr1_out;
        if (c_ld_s_usp) r_s_usp <= cb_sr1_out;
    end

endmodule
