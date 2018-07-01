/**
 * Model for Microchip's 23A256/23K256 serial SRAM chips
 * based on behavior detailed in their datasheet:
 * http://ww1.microchip.com/downloads/en/DeviceDoc/22100F.pdf
 */

module microchip_23X256
    (
        input wire cs_n,    // ~chip select
        output wire so,     // serial out
        input wire hold_n,  // ~hold input
        input wire sck,     // serial clock
        input wire si       // serial in
    );

    localparam ST_RECV_CMD  = 0; // receiving command
    localparam ST_RD_ADDR   = 1; // receiving read address
    localparam ST_RD_MEM    = 2; // sending data back for a mem read
    localparam ST_RD_STA    = 3; // sending data back for a status read
    localparam ST_WR_ADDR   = 4; // receiving write address
    localparam ST_WR_MEM    = 5; // receiving data for mem write
    localparam ST_WR_STA    = 6; // receiving data for status write
    localparam ST_FAULT     = 7;

    localparam MODE_BYTE = 2'b00;
    localparam MODE_SEQU = 2'b01;
    localparam MODE_PAGE = 2'b10;

    localparam INST_READ = 8'b0000_0011;
    localparam INST_WRIT = 8'b0000_0010;
    localparam INST_RDSR = 8'b0000_0101;
    localparam INST_WRSR = 8'b0000_0001;

    // overall design:
    // spi shift register works on positive edge of sck
    // internal regs latch on the negative edge

    reg [2:0] cs;
    reg [4:0] cnt;  // counter for shifts

    reg [7:0] data [0:32767];
    reg [14:0] addr;

    reg [1:0] mode;
    reg       hold_en;

    reg [15:0] shf_i;   // shift in
    reg [7:0]  shf_o;   // shift out

    // combinational SM logic
    reg [2:0] ns;
    // outputs
    reg o_rst_cnt;
    reg o_inc_cnt;
    reg o_so_en; assign so = o_so_en ? shf_o[7] : 1'bz;
    reg o_ld_sta;
    reg o_ld_rd_mema;   // use address reg
    reg o_ld_rd_memp;   // passthrough address from recv and si
    reg o_ld_rd_stat;
    reg o_ld_wr_mema;   // use address reg
    reg o_ld_wr_memp;   // passthrough address from recv/ don't actually need it for writes
    reg o_ld_wr_stat;
    reg o_ld_addr;
    reg o_inc_addr;

    // qualifiers
    wire q_byte = (mode == MODE_BYTE);
    wire q_sequ = (mode == MODE_SEQU);

    always @(*) begin
        ns           = ST_FAULT;
        o_rst_cnt    = 0;
        o_inc_cnt    = 0;
        o_so_en      = 0;
        o_ld_sta     = 0;
        o_ld_rd_mema = 0;
        o_ld_rd_memp = 0;
        o_ld_rd_stat = 0;
        o_ld_wr_mema = 0;
        o_ld_wr_memp = 0;
        o_ld_wr_stat = 0;
        o_ld_addr    = 0;
        o_inc_addr   = 0;

        // note that cnt is updated on the negedge
        // that means when receiving, check for count N at N-1
        // and for transmitting, check at N-1, because N is more of
        // "signals presented" rather than shifts out

        case (cs)
        ST_RECV_CMD: begin
            if (cnt == 7) begin
                // decode
                case (shf_i[7:0])
                INST_READ: ns = ST_RD_ADDR;
                INST_WRIT: ns = ST_WR_ADDR;
                INST_RDSR: begin
                    ns = ST_RD_STA;
                    o_ld_rd_stat = 1;
                end
                INST_WRSR: ns = ST_WR_STA;
                default: ns = ST_FAULT;
                endcase

                o_rst_cnt = 1;
            end else begin
                // still rx
                ns = ST_RECV_CMD;
                o_inc_cnt = 1;
            end
        end

        ST_RD_ADDR: begin
            if (cnt == 15) begin
                ns = ST_RD_MEM;
                // load the address and load the shift reg w/ passthrough
                o_rst_cnt = 1;
                o_ld_rd_memp = 1;
                o_ld_addr = 1;
            end else begin
                ns = ST_RD_ADDR;
                o_inc_cnt = 1;
            end
        end

        ST_RD_MEM: begin
            o_so_en = 1;
            if (cnt == 7) begin
                // If in sequential or page mode, continue reading out
                if (q_byte) begin
                    ns = ST_FAULT;
                end else begin
                    ns = ST_RD_MEM;
                    o_rst_cnt = 1;
                    o_ld_rd_mema = 1;
                end
            end else begin
                ns = ST_RD_MEM;

                o_inc_cnt = 1;
                if (cnt == 6) begin
                    o_inc_addr = 1; // increment that addr (for seq and page mode)
                end
            end
        end

        ST_WR_ADDR: begin
            if (cnt == 15) begin
                ns = ST_WR_MEM;
                // load the address and load the shift reg w/ passthrough
                o_rst_cnt = 1;
                o_ld_addr = 1;
            end else begin
                ns = ST_WR_ADDR;
                o_inc_cnt = 1;
            end
        end

        ST_WR_MEM: begin
            if (cnt == 7) begin
                // If in sequential or page mode, continue reading out
                o_ld_wr_mema = 1;
                if (q_byte) begin
                    ns = ST_FAULT;
                end else begin
                    ns = ST_WR_MEM;
                    o_rst_cnt = 1;
                    o_inc_addr = 1; // increment that addr (for seq and page mode)
                end
            end else begin
                ns = ST_WR_MEM;

                o_inc_cnt = 1;
            end
        end

        ST_RD_STA: begin
            o_so_en = 1;
            if (cnt == 7) begin
                ns = ST_FAULT;
            end else begin
                ns = ST_RD_STA;
                o_inc_cnt = 1;
            end
        end

        ST_WR_STA: begin
            if (cnt == 7) begin
                ns = ST_FAULT;

                o_ld_wr_stat = 1;
            end else begin
                ns = ST_WR_STA;

                o_inc_cnt = 1;
            end
        end

        ST_FAULT: begin
            ns = ST_FAULT;  // only way out is to pull CS high
        end

        endcase
    end

    initial begin
        //mode <= 2'b00;
        mode <= MODE_BYTE;
        hold_en <= 0;
        cs <= ST_RECV_CMD;
        shf_i <= 0;
        shf_o <= 0;
    end

    always @(*) begin
        if (cs_n) begin
            // if high, put back into default state
            cs <= ST_RECV_CMD;
            cnt <= 0;
        end
    end

    always @(posedge sck) begin
        if (!cs_n) begin
            // if low, can perform logic
            if (hold_n | hold_en) begin
                // can only work if not in HOLD
                shf_i <= {shf_i[14:0], si};
            end
        end
    end

    // update internal regs (non-shfit) on the negative edge
    always @(negedge sck) begin
        if (!cs_n) begin
            if (hold_n | hold_en) begin
                // can only work if not in HOLD
                cs <= ns;

                // shifts out on negative edge
                shf_o <= {shf_o[6:0], 1'b0};

                // counter reset in negedge land, incremented in posedge land
                if (o_rst_cnt) cnt <= 0;
                else if (o_inc_cnt) cnt <= cnt + 1;

                // load the status reg
                if (o_ld_sta) begin
                    mode    <= shf_i[7:6];
                    hold_en <= shf_i[0];
                end

                // load the output shift reg with appropriate contents
                if      (o_ld_rd_mema) shf_o <= data[addr[14:0]];
                else if (o_ld_rd_memp) shf_o <= data[shf_i[14:0]];
                else if (o_ld_rd_stat) shf_o <= {mode, {5{1'b0}}, hold_en};

                // handle writes
                if (o_ld_wr_mema) data[addr[14:0]] <= shf_i[7:0];
                if (o_ld_wr_memp) data[shf_i[14:0]] <= shf_i[7:0];

                if (o_ld_wr_stat) begin
                    mode    <= shf_i[7:6];
                    hold_en <= shf_i[0];
                end

                if (o_ld_addr) addr <= {shf_i[14:0]};
                else if (o_inc_addr) begin
                    if (mode == MODE_PAGE) addr <= {addr[14:5], addr[4:0] + 5'b1};
                    else                   addr <= addr + 1;
                end
            end
        end
    end
endmodule
