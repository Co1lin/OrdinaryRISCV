/*
 * by Colin
 */

`default_nettype none
`timescale 1ns / 1ps
`include "../headers/exc.svh"
`include "../headers/vga.svh"
`include "../headers/tlb.svh"

module MMUnit (
    input wire clk,
    input wire rst,

    input wire r_e_in,
    input wire w_e_in,

    input wire byte_mode_e,
    input wire unsigned_e,
    input wire[31:0] mem_addr_in,
    input wire[31:0] mem_data_in,
    output reg[31:0] mem_data_out,

    output wire finished,
    output wire timeout, // mtime > mtimecmp

    inout wire[31:0] data_bus,

    output reg[19:0] base_ram_addr, //BaseRAM地址
    output reg[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    inout wire[31:0] ext_ram_data_bus,  //ExtRAM数据

    output reg[19:0] ext_ram_addr, //ExtRAM地址
    output reg[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志
    output reg uart_rdn,          //读串口信号，低有效
    output reg uart_wrn,          //写串口信号，低有效

    input `sxlen_wire_t satp_in,
    input wire[1:0] pri_level_in,
    output wire illegal_access,

    output wire video_mem_w_e,
    output `vga_addr_wire video_mem_w_addr,
    output `vga_pixel_wire video_mem_w_data

);

enum reg[2:0] { 
    DEV_BASE_RAM = 0,
    DEV_EXT_RAM = 1,
    DEV_UART_IO = 2,
    DEV_UART_STATE = 3,
    DEV_UART_SKIP = 4,
    DEV_CSR = 5,
    DEV_VIDEO = 6,
    DEV_ILLEGAL = 7
} device;

enum reg[2:0] {
    VA_TYPE_MEM = 0,
    VA_TYPE_UART_IO = 1,
    VA_TYPE_UART_STATE = 2,
    VA_TYPE_VIDEO = 3,
    VA_TYPE_ILLEGAL = 4
} va_type;

always_comb begin
    if (mem_addr_in == 32'h1000_0000)
        va_type = VA_TYPE_UART_IO; // uart
    else if (mem_addr_in == 32'h1000_0005)
        va_type = VA_TYPE_UART_STATE; // uart state
    else if (32'h0100_0000 <= mem_addr_in && mem_addr_in <= 32'h0107_52ff)
        va_type = VA_TYPE_VIDEO;
    else if (32'h8000_0000 <= mem_addr_in && mem_addr_in <= 32'h8001_ffff ||
             32'h8010_0000 <= mem_addr_in && mem_addr_in <= 32'h8010_0fff ||
             32'h0000_0000 <= mem_addr_in && mem_addr_in <= 32'h002f_ffff ||
             32'h7fc1_0000 <= mem_addr_in && mem_addr_in <= 32'h7fff_ffff)
        va_type = VA_TYPE_MEM; // mem
    else
        va_type = VA_TYPE_ILLEGAL;
end

// Page table support for Mem

// decode SATP
satp_t satp;
always_comb begin
    satp = satp_in;
end
wire pt_e;
assign pt_e = satp.mode & (pri_level_in != `LEVEL_MACHINE) & (va_type == VA_TYPE_MEM) & (~tlb_hit);
// 32-bit page table entry
typedef struct packed {
    reg[11:0] ppn_1;
    reg[9:0] ppn_0;
    reg[1:0] rsw;
    reg D, A, G, U, X, W, R, V;
} pte_t;
pte_t pte_l1, pte_l2;

// tlb
tlb_item tlb[0:31];
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        tlb[0] <= 47'b0;
        tlb[1] <= 47'b0;
        tlb[2] <= 47'b0;
        tlb[3] <= 47'b0;
        tlb[4] <= 47'b0;
        tlb[5] <= 47'b0;
        tlb[6] <= 47'b0;
        tlb[7] <= 47'b0;
        tlb[8] <= 47'b0;
        tlb[9] <= 47'b0;
        tlb[10] <= 47'b0;
        tlb[11] <= 47'b0;
        tlb[12] <= 47'b0;
        tlb[13] <= 47'b0;
        tlb[14] <= 47'b0;
        tlb[15] <= 47'b0;
        tlb[16] <= 47'b0;
        tlb[17] <= 47'b0;
        tlb[18] <= 47'b0;
        tlb[19] <= 47'b0;
        tlb[20] <= 47'b0;
        tlb[21] <= 47'b0;
        tlb[22] <= 47'b0;
        tlb[23] <= 47'b0;
        tlb[24] <= 47'b0;
        tlb[25] <= 47'b0;
        tlb[26] <= 47'b0;
        tlb[27] <= 47'b0;
        tlb[28] <= 47'b0;
        tlb[29] <= 47'b0;
        tlb[30] <= 47'b0;
        tlb[31] <= 47'b0;
    end
end
// check for tlb
wire[4:0] tlb_tag;
wire tlb_hit;
assign tlb_tag = mem_addr_in[31:27];
assign tlb_hit = (tlb[tlb_tag].index == mem_addr_in[26:12]) & (tlb[tlb_tag].asid == satp.asid) & tlb[tlb_tag].valid;

// state machine
reg[1:0] pt_sm_state;
reg r_e, w_e;
reg pt_finished;
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        pt_sm_state <= 0;
    end
    else begin
        case (pt_sm_state)
            0: begin
                pte_l1 <= mem_data_out_buf;
                if (pt_e)
                    pt_sm_state <= 1;
            end
            1: begin
                pte_l2 <= mem_data_out_buf;
                pt_sm_state <= 2;
            end
            2: begin
                pt_sm_state <= 0;
                tlb[tlb_tag].index <= mem_addr_in[26:12];
                tlb[tlb_tag].asid <= satp.asid;
                tlb[tlb_tag].ppn <= mem_addr_reading[31:12];
                tlb[tlb_tag].valid <= 1;
            end
            default: ;
        endcase
    end
end
always_comb begin
    r_e = 0;
    w_e = 0;
    pt_finished = 0;
    if (pt_e) begin
        case (pt_sm_state)
            0: begin
                r_e = 1; 
                w_e = 0;
                pt_finished = 0;
            end
            1: begin
                r_e = 1; 
                w_e = 0;
                pt_finished = 0;
            end
            2: begin
                r_e = r_e_in; 
                w_e = w_e_in;
                pt_finished = 1;
            end
        endcase
    end
    else begin
        r_e = r_e_in; w_e = w_e_in;
    end
end

reg[31:0] mem_addr_reading;
always_comb begin
    if (pt_e) begin
        case (pt_sm_state)
            0: begin
                mem_addr_reading = (satp.ppn << 12) + (mem_addr_in[31:22] << 2);
            end
            1: begin
                mem_addr_reading = ({ pte_l1.ppn_1, pte_l1.ppn_0 } << 12) + (mem_addr_in[21:12] << 2);
            end
            2: begin
                mem_addr_reading = ({ pte_l2.ppn_1, pte_l2.ppn_0 } << 12) + (mem_addr_in[11:0]);
            end
            default: mem_addr_reading = 0;
        endcase
    end
    else if (satp.mode & (pri_level_in != `LEVEL_MACHINE) & (va_type == VA_TYPE_MEM) & tlb_hit) begin
        mem_addr_reading = (tlb[tlb_tag].ppn << 12) + (mem_addr_in[11:0]);
    end
    else begin
        mem_addr_reading = mem_addr_in;
    end
end


// map addr to device
always_comb begin
    if (32'h8000_0000 <= mem_addr_reading && mem_addr_reading <= 32'h803f_ffff)
        device = DEV_BASE_RAM; // base ram
    else if (32'h8040_0000 <= mem_addr_reading && mem_addr_reading <= 32'h807f_ffff)
        device = DEV_EXT_RAM; // ext ram
    else if (mem_addr_reading == 32'h1000_0000)
        device = DEV_UART_IO; // uart
    else if (mem_addr_reading == 32'h1000_0005)
        device = DEV_UART_STATE; // uart state
    else if (32'h1000_0001 <= mem_addr_reading && mem_addr_reading <= 32'h1000_0007 &&
             mem_addr_reading != 32'h1000_0000 && mem_addr_reading != 32'h1000_0005)
        device = DEV_UART_SKIP; // uart state to skip
    else if (mem_addr_reading == `CSR_MTIME || mem_addr_reading == `CSR_MTIME_HIGH ||
             mem_addr_reading == `CSR_MTIMECMP || mem_addr_reading == `CSR_MTIMECMP_HIGH)
        device = DEV_CSR; // csr mtime and mtimecmp
    else if (32'h0100_0000 <= mem_addr_reading && mem_addr_reading <= 32'h0107_52ff)
        device = DEV_VIDEO; // vga video memory
    else
        device = DEV_ILLEGAL; // unknown
end

// video memory signals
assign video_mem_w_e = (device == DEV_VIDEO) & w_e;
assign video_mem_w_addr = mem_addr_reading;
assign video_mem_w_data = mem_data_in;


/* According to byte enabling,
 * prepare data to write,
 * and set data for unified output interface
 */
reg[3:0] be_n_reg;
reg[31:0] mem_data_in_buf;  // data to write to bus
reg[31:0] mem_data_out_buf; // data got from bus
always_comb begin
    if (device == DEV_UART_STATE |
        pt_e & pt_sm_state != 2 | byte_mode_e == 0) begin
        be_n_reg = 4'b0;
        mem_data_in_buf = mem_data_in;
        mem_data_out = mem_data_out_buf;
    end
    else if (device == DEV_UART_IO) begin
        be_n_reg = 4'b0;
        mem_data_in_buf = {24'b0, mem_data_in[7:0]};
        mem_data_out = {{24{mem_data_out_buf[7]}}, mem_data_out_buf[7:0]};
    end
    else begin
        // for RAM, the byte to r/w depends
        case(mem_addr_in[1:0])
            2'b00: begin
                be_n_reg = 4'b1110;
                mem_data_in_buf = {24'b0, mem_data_in[7:0]};
                mem_data_out = {(unsigned_e ? 24'b0 : {24{mem_data_out_buf[7]}}), mem_data_out_buf[7:0]};
            end
            2'b01: begin
                be_n_reg = 4'b1101;
                mem_data_in_buf = {16'b0, mem_data_in[7:0], 8'b0};
                mem_data_out = {(unsigned_e ? 24'b0 : {24{mem_data_out_buf[15]}}), mem_data_out_buf[15:8]};
            end
            2'b10: begin
                be_n_reg = 4'b1011;
                mem_data_in_buf = {8'b0, mem_data_in[7:0], 16'b0};
                mem_data_out = {(unsigned_e ? 24'b0 : {24{mem_data_out_buf[23]}}), mem_data_out_buf[23:16]};
            end
            2'b11: begin
                be_n_reg = 4'b0111;
                mem_data_in_buf = {mem_data_in[7:0], 24'b0};
                mem_data_out = {(unsigned_e ? 24'b0 : {24{mem_data_out_buf[31]}}), mem_data_out_buf[31:24]};
            end
            default: be_n_reg = 4'b1111;
        endcase
    end
end

// set chip enabling, byte enabling and dev addr
always_comb begin
    base_ram_addr = mem_addr_reading[21:2];
    base_ram_be_n = be_n_reg;
    ext_ram_addr = mem_addr_reading[21:2];
    ext_ram_be_n = be_n_reg;
    case (device)
        DEV_BASE_RAM: begin
            base_ram_ce_n = 0;
            ext_ram_ce_n = 1;
        end
        DEV_EXT_RAM: begin
            base_ram_ce_n = 1;
            ext_ram_ce_n = 0;
        end
        default: begin
            base_ram_ce_n = 1;
            ext_ram_ce_n = 1;
        end
    endcase
end

assign data_bus = 
    (r_e && (device == DEV_BASE_RAM || device == DEV_UART_IO)) ?
    32'bz : mem_data_in_buf;
assign ext_ram_data_bus = 
    (r_e && (device == DEV_EXT_RAM)) ?
    32'bz : mem_data_in_buf;

// pull down the signal to read (MAGIC:)
assign base_ram_oe_n = 0; //(device != DEV_BASE_RAM) | clk | ~r_e ;
assign ext_ram_oe_n = 0; //(device != DEV_EXT_RAM) | clk | ~r_e ;
// pull down the signal to write
assign base_ram_we_n = (device != DEV_BASE_RAM) | clk | ~w_e ;
assign ext_ram_we_n = (device != DEV_EXT_RAM) | clk | ~w_e ;

reg uart_finished;
// state machine for UART
reg[2:0] uart_sm_state;
reg[31:0] uart_out_data;
always_ff @(negedge clk or posedge rst) begin
    if (rst | uart_finished) begin
        uart_rdn <= 1;
        uart_wrn <= 1;
        uart_sm_state <= 0;
        uart_finished <= 0;
    end
    else begin
        if (device == DEV_UART_IO) begin
            if (r_e) begin
                case (uart_sm_state)
                    0,1: begin
                        uart_finished <= 0;
                        uart_rdn <= 0;
                        uart_wrn <= 1;
                        uart_sm_state <= uart_sm_state + 1;
                    end
                    2: begin
                        uart_out_data <= data_bus;
                        uart_sm_state <= uart_sm_state + 1;
                    end
                    3: begin
                        uart_finished <= 1;
                        uart_rdn <= 1;
                    end
                    default: begin
                        uart_sm_state <= 0;
                        uart_finished <= 0;
                    end
                endcase
            end
            else if (w_e) begin
                case (uart_sm_state)
                    0,1: begin
                        uart_finished <= 0;
                        uart_rdn <= 1;
                        uart_wrn <= 0;
                        uart_sm_state <= uart_sm_state + 1;
                    end
                    2: begin
                        uart_finished <= 1;
                        uart_wrn <= 1;
                        uart_sm_state <= uart_sm_state + 1;
                    end
                    default: begin
                        uart_sm_state <= 0;
                        uart_finished <= 0;
                    end
                endcase
            end
            else begin
                uart_rdn <= 1;
                uart_wrn <= 1;
                uart_sm_state <= 0;
                uart_finished <= 0;
            end
        end
        else begin
            uart_rdn <= 1;
            uart_wrn <= 1;
            uart_finished <= 0;
            uart_sm_state <= 0;
        end
    end
end

// support timeout
// memory mapped CSRs
`mxlen_reg_t mtime_low, mtime_high;
`mxlen_reg_t mtimecmp_low, mtimecmp_high;
assign timeout = {mtime_high, mtime_low} > {mtimecmp_high, mtimecmp_low};
// increase mtime automatically, and write to mtimecmp
localparam interval = 10;
reg[9:0] counter;
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        mtime_low <= 0;
        mtime_high <= 0;
        mtimecmp_low <= 0;
        mtimecmp_high <= 0;
        counter <= 0;
    end
    else begin
        if (w_e) begin
            case (mem_addr_in)
                `CSR_MTIMECMP: mtimecmp_low <= mem_data_in_buf;
                `CSR_MTIMECMP_HIGH: mtimecmp_high <= mem_data_in_buf;
            endcase
        end
        // timecmp's increase in supervisor-rv is 10^7
        if (counter == interval - 1) begin
            counter <= 0;
            {mtime_high, mtime_low} <= {mtime_high, mtime_low} + 1;
        end
        else begin
            counter <= counter + 1;
        end
    end
end

// unified interface to collect data for further processing
always_comb begin
    mem_data_out_buf = 0;
    case (device)
        DEV_BASE_RAM: mem_data_out_buf = data_bus;
        DEV_EXT_RAM: mem_data_out_buf = ext_ram_data_bus;
        DEV_UART_IO: mem_data_out_buf = uart_out_data;
        DEV_UART_STATE: mem_data_out_buf = {24'b0, 2'b0, uart_tbre & uart_tsre, 4'b0, uart_dataready};
        DEV_CSR:
            case (mem_addr_in)
                `CSR_MTIME: mem_data_out_buf = mtime_low;
                `CSR_MTIME_HIGH: mem_data_out_buf = mtime_high;
                `CSR_MTIMECMP: mem_data_out_buf = mtimecmp_low;
                `CSR_MTIMECMP_HIGH: mem_data_out_buf = mtimecmp_high;
            endcase
        default: mem_data_out_buf = 0;
    endcase
end

assign finished =   (device == DEV_UART_IO) & uart_finished |
                    (device != DEV_UART_IO) & ( ~pt_e | pt_e & pt_finished );

assign illegal_access = device == DEV_ILLEGAL | pt_e & va_type == VA_TYPE_ILLEGAL;

endmodule