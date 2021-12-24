/*
 * by Colin
 * Ref: https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html
 *      https://github.com/riscv-non-isa/riscv-asm-manual/blob/master/riscv-asm.md
 */

`default_nettype none
`timescale 1ns / 1ps

module MemCtrller (
    input wire clk,
    input wire rst,

    input wire r_e,
    input wire w_e,

    input wire byte_mode_e,
    input wire[31:0] mem_addr,
    input wire[31:0] mem_data_in,
    output reg[31:0] mem_data_out,

    output reg finished,

    inout wire[31:0] data_bus,

    output reg[19:0] base_ram_addr, //BaseRAM地址
    output reg[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg base_ram_ce_n,       //BaseRAM片选，低有效
    output reg base_ram_oe_n,       //BaseRAM读使能，低有效
    output reg base_ram_we_n,       //BaseRAM写使能，低有效

    inout wire[31:0] ext_ram_data,  //ExtRAM数据

    output reg[19:0] ext_ram_addr, //ExtRAM地址
    output reg[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg ext_ram_ce_n,       //ExtRAM片选，低有效
    output reg ext_ram_oe_n,       //ExtRAM读使能，低有效
    output reg ext_ram_we_n,       //ExtRAM写使能，低有效

    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志
    output reg uart_rdn,          //读串口信号，低有效
    output reg uart_wrn           //写串口信号，低有效
);

localparam DEV_BASE_RAM = 0;
localparam DEV_EXT_RAM = 1;
localparam DEV_UART_IO = 2;
localparam DEV_UART_STATE = 3;
localparam DEV_UART_SKIP = 4;
localparam DEV_UNKNOWN = 5;

reg[2:0] device;
always_comb begin
    if (32'h8000_0000 <= mem_addr && mem_addr <= 32'h803f_ffff)
        device = DEV_BASE_RAM; // base ram
    else if (32'h8040_0000 <= mem_addr && mem_addr <= 32'h807f_ffff)
        device = DEV_EXT_RAM; // ext ram
    else if (mem_addr == 32'h1000_0000)
        device = DEV_UART_IO; // uart
    else if (mem_addr == 32'h1000_0005)
        device = DEV_UART_STATE; // uart state
    else if (32'h1000_0001 <= mem_addr && mem_addr <= 32'h1000_0007 &&
             mem_addr != 32'h1000_0000 && mem_addr != 32'h1000_0005)
        device = DEV_UART_SKIP; // uart state
    else
        device = DEV_UNKNOWN; // unknown
end

reg[3:0] be_n_reg;
reg[31:0] mem_data_in_buf;
reg[31:0] mem_data_out_buf;
always_comb begin
    if (byte_mode_e == 0) begin
        be_n_reg = 4'b0;
        mem_data_in_buf = mem_data_in;
        mem_data_out = mem_data_out_buf;
    end
    else if (device > 1) begin
        be_n_reg = 4'b0;
        mem_data_in_buf = {24'b0, mem_data_in[7:0]};
        mem_data_out = {{24{mem_data_out_buf[7]}}, mem_data_out_buf[7:0]};
    end
    else begin
        case(mem_addr[1:0])
            2'b00: begin
                be_n_reg = 4'b1110;
                mem_data_in_buf = {24'b0, mem_data_in[7:0]};
                mem_data_out = {{24{mem_data_out_buf[7]}}, mem_data_out_buf[7:0]};
            end
            2'b01: begin
                be_n_reg = 4'b1101;
                mem_data_in_buf = {16'b0, mem_data_in[7:0], 8'b0};
                mem_data_out = {{24{mem_data_out_buf[15]}}, mem_data_out_buf[15:8]};
            end
            2'b10: begin
                be_n_reg = 4'b1011;
                mem_data_in_buf = {8'b0, mem_data_in[7:0], 16'b0};
                mem_data_out = {{24{mem_data_out_buf[23]}}, mem_data_out_buf[23:16]};
            end
            2'b11: begin
                be_n_reg = 4'b0111;
                mem_data_in_buf = {mem_data_in[7:0], 24'b0};
                mem_data_out = {{24{mem_data_out_buf[31]}}, mem_data_out_buf[31:24]};
            end
            default: be_n_reg = 4'b1111;
        endcase
    end
end

always_comb begin
    base_ram_addr = mem_addr[21:2];
    base_ram_be_n = be_n_reg;
    ext_ram_addr = mem_addr[21:2];
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

reg data_bus_z;
assign data_bus = data_bus_z ? 32'bz : mem_data_in_buf;
reg ext_ram_data_z;
assign ext_ram_data = ext_ram_data_z ? 32'bz : mem_data_in_buf;

reg[2:0] loop_counter;
always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        finished <= 0;
        base_ram_oe_n <= 1;
        base_ram_we_n <= 1;
        ext_ram_oe_n <= 1;
        ext_ram_we_n <= 1;
        uart_rdn <= 1;
        uart_wrn <= 1;
        data_bus_z <= 0;
        ext_ram_data_z <= 0;
        loop_counter <= 0;
        mem_data_out_buf <= 0;
    end
    else begin
        case(device)
        DEV_BASE_RAM: begin
            if (r_e) begin
                case (loop_counter)
                // 0: begin
                //     loop_counter <= loop_counter + 1;
                //     base_ram_oe_n <= 1;
                //     base_ram_we_n <= 1;
                //     data_bus_z <= 1;
                // end
                // 1,3: begin
                //     loop_counter <= loop_counter + 1;
                //     base_ram_oe_n <= 0;
                // end
                // 2: begin
                //     loop_counter <= loop_counter + 1;
                //     base_ram_oe_n <= 0;
                //     mem_data_out_buf <= data_bus;
                // end
                // 4: begin
                //     loop_counter <= loop_counter + 1;
                //     base_ram_oe_n <= 1;
                //     finished <= 1;
                // end
                0: begin
                    loop_counter <= loop_counter + 1;
                    base_ram_oe_n <= 0;
                    base_ram_we_n <= 1;
                    data_bus_z <= 1;
                end
                1: begin
                    loop_counter <= loop_counter + 1;
                    mem_data_out_buf <= data_bus;
                    finished <= 1;
                end
                default: begin
                    loop_counter <= 0;
                    base_ram_oe_n <= 1;
                    finished <= 0;
                    data_bus_z <= 0;
                end
                endcase
            end
            else if (w_e) begin
                // case (loop_counter)
                // 0: begin
                //     loop_counter <= loop_counter + 1;
                //     base_ram_oe_n <= 1;
                //     base_ram_we_n <= 1;
                //     data_bus_z <= 0;
                // end
                // 1,2: begin
                //     loop_counter <= loop_counter + 1;
                //     base_ram_we_n <= 0;
                // end
                // 3: begin
                //     loop_counter <= loop_counter + 1;
                //     base_ram_we_n <= 1;
                //     finished <= 1;
                // end
                // default: begin
                //     loop_counter <= 0;
                //     finished <= 0;
                // end
                case (loop_counter)
                0: begin
                    loop_counter <= loop_counter + 1;
                    base_ram_oe_n <= 1;
                    base_ram_we_n <= 0;
                    data_bus_z <= 0;
                end
                1: begin
                    loop_counter <= loop_counter + 1;
                    finished <= 1;
                end
                default: begin
                    loop_counter <= 0;
                    base_ram_we_n <= 1;
                    finished <= 0;
                end
                endcase
            end
        end
        DEV_EXT_RAM: begin
            if (r_e) begin
                case (loop_counter)
                0: begin
                    loop_counter <= loop_counter + 1;
                    ext_ram_oe_n <= 1;
                    ext_ram_we_n <= 1;
                    ext_ram_data_z <= 1;
                end
                1,3: begin
                    loop_counter <= loop_counter + 1;
                    ext_ram_oe_n <= 0;
                end
                2: begin
                    loop_counter <= loop_counter + 1;
                    ext_ram_oe_n <= 0;
                    mem_data_out_buf <= ext_ram_data;
                end
                4: begin
                    loop_counter <= loop_counter + 1;
                    ext_ram_oe_n <= 1;
                    finished <= 1;
                end
                default: begin
                    loop_counter <= 0;
                    finished <= 0;
                    ext_ram_data_z <= 0;
                end
                endcase
            end
            else if (w_e) begin
                case (loop_counter)
                0: begin
                    loop_counter <= loop_counter + 1;
                    ext_ram_oe_n <= 1;
                    ext_ram_we_n <= 1;
                    ext_ram_data_z <= 0;
                end
                1,2: begin
                    loop_counter <= loop_counter + 1;
                    ext_ram_we_n <= 0;
                end
                3: begin
                    loop_counter <= loop_counter + 1;
                    ext_ram_we_n <= 1;
                    finished <= 1;
                end
                default: begin
                    loop_counter <= 0;
                    finished <= 0;
                end
                endcase
            end
        end
        DEV_UART_IO: begin
            if (r_e) begin
                case (loop_counter)
                0: begin
                    data_bus_z <= 1;
                    uart_wrn <= 1;
                    if (uart_dataready == 1) begin
                        uart_rdn <= 0;
                        loop_counter <= loop_counter + 1;
                    end
                    else begin
                        loop_counter <= loop_counter;
                    end
                end
                1: begin
                    mem_data_out_buf <= data_bus;
                    finished <= 1;
                    loop_counter <= loop_counter + 1;
                end
                default: begin
                    uart_rdn <= 1;
                    data_bus_z <= 0;
                    finished <= 0;
                    loop_counter <= 0;
                end
                endcase
            end
            else if (w_e) begin
                case (loop_counter)
                0: begin
                    uart_rdn <= 1;
                    uart_wrn <= 0;
                    data_bus_z <= 0;
                    loop_counter <= loop_counter + 1;
                end
                1: begin
                    uart_wrn <= 0;
                    finished <= 1;
                    loop_counter <= loop_counter + 1;
                end
                default: begin
                    uart_wrn <= 1;
                    finished <= 0;
                    loop_counter <= 0;
                end
                endcase
            end
        end
        DEV_UART_STATE: begin
            if (r_e) begin
                case (loop_counter)
                0: begin
                    loop_counter <= 1;
                    mem_data_out_buf <= {24'b0, 2'b0, uart_tbre & uart_tsre, 4'b0, uart_dataready};
                    finished <= 1;
                end
                default: begin
                    finished <= 0;
                    loop_counter <= 0;
                end
                endcase
            end
            else begin
                finished <= 0;
                loop_counter <= 0;
            end
        end
        DEV_UART_SKIP: begin
            if (r_e | w_e) begin
                mem_data_out_buf <= 32'b0;
                case (loop_counter)
                0: begin
                    loop_counter <= 1;
                    finished <= 1;
                end
                default: begin
                    loop_counter <= 0;
                    finished <= 0;
                end
                endcase
            end
            else begin
                finished <= 0;
                loop_counter <= 0;
            end
        end
        default: begin
            finished <= 0;
            mem_data_out_buf <= 32'b0;
            loop_counter <= 0;
        end
        endcase
    end
end

endmodule