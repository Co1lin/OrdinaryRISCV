`default_nettype none
`timescale 1ns / 1ps
`include "headers/common.svh"
`include "headers/ops.svh"
`include "headers/aluops.svh"
`include "headers/csrs.svh"
`include "headers/exc.svh"
`include "headers/vga.svh"

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

// PLL (phase lock loop) gnerating clock of customized frequency
wire my_clk_locked, my_clk;
reg my_rst;
pll_example clock_gen(
    .clk_in1(clk_50M),  // input of outside clk
    .clk_out1(my_clk), // output of customized clk
    .reset(reset_btn),  // input of rst
    .locked(my_clk_locked) // status of whether it is stable (1 means stable)
);
always_ff @(posedge my_clk or negedge my_clk_locked) begin
    if (~my_clk_locked)
        my_rst <= 1'b1;
    else
        my_rst <= 1'b0;
end

// -------------------------- Units --------------------------

// vga
wire [11:0] vga_x, vga_y;
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M),
    .rst(reset_btn),
    .x(vga_x),
    .y(vga_y),
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);

wire video_mem_c_e = 1;
wire video_mem_w_e;
`vga_addr_wire video_mem_w_addr;
`vga_pixel_wire video_mem_w_data;

// // addr on mem = x + y * 800
// `vga_addr_wire video_mem_r_addr = vga_x + vga_y << 9 + vga_y << 8 + vga_y << 5;
// addr on mem = (x>>2) + (y>>2) * 200
`vga_addr_wire video_mem_r_addr = (vga_x >> 2) + ((vga_y>>2) << 7) + ((vga_y>>2) << 6) + ((vga_y>>2) << 3);
`vga_pixel_wire video_mem_r_data;
assign video_red = video_mem_r_data[7:5];
assign video_green = video_mem_r_data[4:2];
assign video_blue = video_mem_r_data[1:0];

blk_mem_gen_0 video_mem(
    .clka(my_clk),
    .ena(video_mem_c_e),
    .wea(video_mem_w_e),
    .addra(video_mem_w_addr),
    .dina(video_mem_w_data),
    .clkb(clk_50M),
    .enb(video_mem_c_e),
    .addrb(video_mem_r_addr),
    .doutb(video_mem_r_data)
);


// unified controller of memory and uart
wire mem_finished;
reg mem_r_e, mem_w_e, mem_byte_mode_e, mem_unsigned_e;
`mem_addr_reg_t mem_addr;
`word_reg_t mem_data_in;
`word_wire_t mem_data_out;
wire mem_out_timeout;
`sxlen_wire_t mem_in_satp;
`pri_level_reg_t mem_in_pri_level;
wire mem_illegal_access;
MMUnit mem_unit(
    .clk(my_clk),
    .rst(my_rst),
    .r_e_in(mem_r_e),
    .w_e_in(mem_w_e),
    .byte_mode_e(mem_byte_mode_e),
    .unsigned_e(mem_unsigned_e),
    .mem_addr_in(mem_addr),
    .mem_data_in(mem_data_in),
    .mem_data_out(mem_data_out),
    .finished(mem_finished),
    .data_bus(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_be_n(base_ram_be_n),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),
    .ext_ram_data_bus(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_be_n(ext_ram_be_n),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n),
    .uart_dataready(uart_dataready),
    .uart_tbre(uart_tbre),
    .uart_tsre(uart_tsre),
    .uart_rdn(uart_rdn),
    .uart_wrn(uart_wrn),
    .timeout(mem_out_timeout),
    .satp_in(mem_in_satp),
    .pri_level_in(mem_in_pri_level),
    .illegal_access(mem_illegal_access),
    .video_mem_w_e(video_mem_w_e),
    .video_mem_w_addr(video_mem_w_addr),
    .video_mem_w_data(video_mem_w_data)
);

`instr_wire_t decoder_instr;
`regid_wire_t decoder_rs1, decoder_rs2, decoder_rd;
`op_id_wire_t decoder_op_id;
`word_wire_t decoder_imm;
wire decoder_imm_select;
wire decoder_wb_e;
wire decoder_csr_e;
`csr_addr_wire_t decoder_csr_addr;
InstrDecoder instr_decoder(
    .instr(decoder_instr),
    .rs1(decoder_rs1),
    .rs2(decoder_rs2),
    .rd(decoder_rd),
    .op_id(decoder_op_id),
    .imm(decoder_imm),
    .imm_select(decoder_imm_select),
    .wb_e(decoder_wb_e),
    .csr_e(decoder_csr_e),
    .csr_addr(decoder_csr_addr)
);

wire regfile_w_e;
`regid_wire_t regfile_w_regid;
`word_wire_t regfile_w_data;
`word_wire_t regfile_r_data1, regfile_r_data2;
RegFile reg_file(
    .clk(my_clk),
    .rst(my_rst),
    .w_e(regfile_w_e),
    .w_id(regfile_w_regid),
    .w_data(regfile_w_data),
    .r_id1(decoder_rs1),
    .r_id2(decoder_rs2),
    .r_data1(regfile_r_data1),
    .r_data2(regfile_r_data2)
);

`word_reg_t id_exe_in_rs1_data; // forwarded data
`word_reg_t id_exe_in_rs2_data; // forwarded data
`pc_wire_t id_exe_out_pc;
`pc_wire_t if_id_out_pc;

`mxlen_reg_t exc_unit_r_data;
wire exc_ret_e;
wire exc_unit_intrpt_e;
`pc_wire_t exc_unit_jump_pc;
`mxlen_wire_t exc_unit_mtvec;
`pri_level_wire_t exc_unit_pri_level_in;
`pri_level_wire_t exc_unit_pri_level_next;
EXCUnit exc_unit(
    .clk(my_clk),
    .rst(my_rst),
    .op_id(decoder_op_id),
    .csr_e(decoder_csr_e),
    .csr_addr(decoder_csr_addr),
    .rs1_data(id_exe_in_rs1_data),
    .mem_out_timeout(mem_out_timeout),
    .id_exe_out_pc(id_exe_out_pc),
    .if_id_out_pc(if_id_out_pc),
    .csr_r_data(exc_unit_r_data),
    .intrpt_e(exc_unit_intrpt_e),
    .exc_ret_e(exc_ret_e),
    .target_addr(exc_unit_jump_pc),
    .satp(mem_in_satp),
    .pri_level_in(exc_unit_pri_level_in),
    .pri_level_next(exc_unit_pri_level_next)
);

`alu_op_wire_t alu_op;
`word_reg_t alu_a, alu_b;
`word_wire_t alu_res;
ALU alu(
    .a(alu_a),
    .b(alu_b),
    .op(alu_op),
    .r(alu_res)
);

// -------------------------- Pipeline! --------------------------

`pc_reg_t fetching_pc;
`pc_reg_t poss_new_pc;

reg data_if_hazard;
reg load_use_hazard;

wire ppl_fwd_e = mem_finished;
wire bf_if_fwd_e;
assign bf_if_fwd_e = ppl_fwd_e & ~data_if_hazard & ~load_use_hazard;
wire if_id_fwd_e;
assign if_id_fwd_e = ppl_fwd_e & ~data_if_hazard & ~load_use_hazard;
wire id_exe_fwd_e = ppl_fwd_e;
wire exe_mem_fwd_e = ppl_fwd_e;
wire mem_wb_fwd_e = ppl_fwd_e;

// IF Stage: read instr from memory
`pc_wire_t bf_if_out_pc;
`pri_level_wire_t bf_if_in_pri_level, bf_if_out_pri_level;
// generate pc value for the next instr
`pc_wire_t next_pc_to_fetch;
assign next_pc_to_fetch = exc_ret_e ? 
    exc_unit_jump_pc : fetching_pc + `WORD_BYTE_SIZE;
assign bf_if_in_pri_level = exc_ret_e ? 
    exc_unit_pri_level_next : bf_if_out_pri_level;

DFFR #(`PC_WIDTH, `INIT_PC) bf_if_pc(.clk(my_clk), .rst(my_rst), .e(bf_if_fwd_e),
    .nxt(next_pc_to_fetch), .cur(bf_if_out_pc));
DFFR #(`PRI_LEVEL_WIDTH, `LEVEL_MACHINE) bf_if_pri_level(.clk(my_clk), .rst(my_rst), .e(bf_if_fwd_e),
    .nxt(bf_if_in_pri_level), .cur(bf_if_out_pri_level));

// ID Stage: decode instruction
// `instr_wire_t instr_to_decode = data_if_hazard ? `ZERO_WORD : mem_data_out;
`alu_op_reg_t id_exe_in_alu_op;
`pc_wire_t id_exe_in_pc;
assign id_exe_in_pc = load_use_hazard ? `ZERO_WORD : if_id_out_pc;
`instr_wire_t if_id_in_instr;
assign if_id_in_instr = exc_ret_e ? `INSTR_NOP : mem_data_out;

DFFR #(`INSTR_WIDTH, `INSTR_NOP)    if_id_instr(.clk(my_clk), .rst(my_rst), .e(if_id_fwd_e),
    .nxt(if_id_in_instr),      .cur(decoder_instr));
// `pc_wire_t if_id_in_pc = data_if_hazard ? `ZERO_WORD : fetching_pc;
DFF #(`PC_WIDTH)                    if_id_pc(.clk(my_clk), .e(if_id_fwd_e),
    .nxt(fetching_pc),       .cur(if_id_out_pc));
DFFR #(`PRI_LEVEL_WIDTH, `LEVEL_MACHINE) if_id_pri_level(.clk(my_clk), .rst(my_rst), .e(bf_if_fwd_e),
    .nxt(bf_if_out_pri_level), .cur(exc_unit_pri_level_in));

// EXE Stage: ALU
`word_reg_t id_exe_out_rs1_data;
`word_reg_t id_exe_out_rs2_data;
`regid_wire_t id_exe_out_rd;
`op_id_reg_t id_exe_out_op_id;
`imm_reg_t id_exe_out_imm;
wire id_exe_out_imm_select;
reg id_exe_out_wb_e;
`word_wire_t id_exe_out_csr_wb_data; // write csr to integer register
wire id_exe_out_csr_e; // whether to write csr to integer register
`word_wire_t exe_mem_in_wb_data;
`pri_level_wire_t id_exe_out_pri_level;
assign exe_mem_in_wb_data = id_exe_out_csr_e ? id_exe_out_csr_wb_data : alu_res;

DFF #(`PC_WIDTH)        id_exe_pc(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(id_exe_in_pc),         .cur(id_exe_out_pc));
`regid_wire_t id_exe_in_rd;
assign id_exe_in_rd = (load_use_hazard | data_if_hazard | exc_unit_intrpt_e) ? 5'b0 : decoder_rd;
DFF #(`REGID_WIDTH)     id_exe_rd(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(id_exe_in_rd),         .cur(id_exe_out_rd));
DFF #(`WORD_SIZE)       id_exe_rs1_data(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(id_exe_in_rs1_data),   .cur(id_exe_out_rs1_data));
DFF #(`WORD_SIZE)       id_exe_rs2_data(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(id_exe_in_rs2_data),   .cur(id_exe_out_rs2_data));
DFF #(`ALU_OP_WIDTH)    id_exe_alu_op(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(id_exe_in_alu_op),     .cur(alu_op));
`op_id_wire_t id_exe_in_op_id;
assign id_exe_in_op_id = (load_use_hazard | data_if_hazard | exc_unit_intrpt_e) ? `OP_ID_NOP : decoder_op_id;
DFFR #(`OP_ID_WIDTH, `OP_ID_NOP) id_exe_op_id(.clk(my_clk), .rst(my_rst), .e(id_exe_fwd_e),
    .nxt(id_exe_in_op_id),      .cur(id_exe_out_op_id));
DFF #(1)                id_exe_imm_select(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(decoder_imm_select),   .cur(id_exe_out_imm_select));
DFF #(`WORD_SIZE)       id_exe_imm(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(decoder_imm),          .cur(id_exe_out_imm));
wire id_exe_in_wb_e;
assign id_exe_in_wb_e = (load_use_hazard | data_if_hazard | exc_unit_intrpt_e) ? 0 : decoder_wb_e;
DFF #(1)                id_exe_wb_e(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(id_exe_in_wb_e),       .cur(id_exe_out_wb_e));
DFF #(1)                id_exe_csr_e(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(decoder_csr_e),        .cur(id_exe_out_csr_e));
DFF #(`WORD_SIZE)       id_exe_csr_data(.clk(my_clk), .e(id_exe_fwd_e),
    .nxt(exc_unit_r_data), .cur(id_exe_out_csr_wb_data));
DFFR #(`PRI_LEVEL_WIDTH, `LEVEL_MACHINE) id_exe_pri_level(.clk(my_clk), .rst(my_rst), .e(bf_if_fwd_e),
    .nxt(exc_unit_pri_level_in), .cur(id_exe_out_pri_level));


// MEM Stage: load or write data from or to memory
`word_wire_t exe_mem_out_alu_res;
`op_id_wire_t exe_mem_out_op_id;
`word_reg_t exe_mem_out_rs2_data;
`regid_wire_t exe_mem_out_rd;
reg exe_mem_out_wb_e;
`word_reg_t mem_wb_in_wb_data;
`pri_level_wire_t exe_mem_out_pri_level;

DFF #(`WORD_SIZE)   exe_mem_alu_res(.clk(my_clk), .e(exe_mem_fwd_e),
    .nxt(exe_mem_in_wb_data),   .cur(exe_mem_out_alu_res));
`regid_wire_t exe_mem_in_rd;
assign exe_mem_in_rd = exc_unit_intrpt_e ? 5'b0 : id_exe_out_rd;
DFF #(`REGID_WIDTH) exe_mem_rd(.clk(my_clk), .e(exe_mem_fwd_e),
    .nxt(exe_mem_in_rd),        .cur(exe_mem_out_rd));
`op_id_wire_t exe_mem_in_op_id;
assign exe_mem_in_op_id = exc_unit_intrpt_e ? `OP_ID_NOP : id_exe_out_op_id;
DFF #(`OP_ID_WIDTH) exe_mem_op_id(.clk(my_clk), .e(exe_mem_fwd_e),
    .nxt(exe_mem_in_op_id),     .cur(exe_mem_out_op_id));
DFF #(`WORD_SIZE)   exe_mem_rs2_data(.clk(my_clk), .e(exe_mem_fwd_e),
    .nxt(id_exe_out_rs2_data),  .cur(exe_mem_out_rs2_data));
wire exe_mem_in_wb_e;
assign exe_mem_in_wb_e = exc_unit_intrpt_e ? 0 : id_exe_out_wb_e;
DFF #(1) exe_mem_wb_e(.clk(my_clk), .e(exe_mem_fwd_e),
    .nxt(exe_mem_in_wb_e),      .cur(exe_mem_out_wb_e));
DFFR #(`PRI_LEVEL_WIDTH, `LEVEL_MACHINE) exe_mem_pri_level(.clk(my_clk), .rst(my_rst), .e(bf_if_fwd_e),
    .nxt(id_exe_out_pri_level), .cur(exe_mem_out_pri_level));

// WB Stage: write data back to registers
DFF #(`REGID_WIDTH)     mem_wb_rd(.clk(my_clk), .e(mem_wb_fwd_e),
    .nxt(exe_mem_out_rd),       .cur(regfile_w_regid));
DFFR #(1, 0)            mem_wb_wb_e(.clk(my_clk), .rst(my_rst), .e(mem_wb_fwd_e),
    .nxt(exe_mem_out_wb_e),     .cur(regfile_w_e));
DFF #(`WORD_SIZE)       mem_wb_wb_data(.clk(my_clk), .e(mem_wb_fwd_e),
    .nxt(mem_wb_in_wb_data),    .cur(regfile_w_data));


// -------------------------- Generators --------------------------
// Generate signals for units by combinatorial logic

/* Possible new PC calculation for branch and jump
 * At ID stage, calculate target pc for the next instruction
 * (will be used only for branch and jump instr)
 */
always_comb begin
    if (id_exe_in_op_id == `OP_ID_JALR)
        poss_new_pc = id_exe_in_rs1_data + decoder_imm;
    else    // beq, jal, etc.
        poss_new_pc = if_id_out_pc + decoder_imm;
end

/* fetching_pc
 * If the condition of jumping is satisfied,
 * change fetching_pc to the right target (poss_new_pc) immediately
 * this eliminates bubbles after branching or jumping!
 */
always_comb begin
    if (id_exe_in_op_id == `OP_ID_BEQ && id_exe_in_rs1_data == id_exe_in_rs2_data ||
        id_exe_in_op_id == `OP_ID_BNE && id_exe_in_rs1_data != id_exe_in_rs2_data ||
        id_exe_in_op_id == `OP_ID_BGEU && $unsigned(id_exe_in_rs1_data) >= $unsigned(id_exe_in_rs2_data) ||
        id_exe_in_op_id == `OP_ID_JAL ||
        id_exe_in_op_id == `OP_ID_JALR)
        fetching_pc = poss_new_pc;
    else
        fetching_pc = bf_if_out_pc;
end

/* Data forwarding (bypassing) before EXE stage
 * this cooperates with the calculation of fetching_pc at ID stage
 */
// forward rs1_data
always_comb begin
    if (id_exe_out_wb_e && id_exe_out_rd != 0 && 
        id_exe_out_rd == decoder_rs1)
        id_exe_in_rs1_data = exe_mem_in_wb_data;
    else if (exe_mem_out_wb_e && exe_mem_out_rd != 0 && 
        exe_mem_out_rd == decoder_rs1)
        id_exe_in_rs1_data = mem_wb_in_wb_data;
    else
        id_exe_in_rs1_data = regfile_r_data1;
end
// forward rs2_data
always_comb begin
    if (id_exe_out_wb_e && id_exe_out_rd != 0 && 
        id_exe_out_rd == decoder_rs2)
        id_exe_in_rs2_data = exe_mem_in_wb_data;
    else if (exe_mem_out_wb_e && exe_mem_out_rd != 0 && 
        exe_mem_out_rd == decoder_rs2)
        id_exe_in_rs2_data = mem_wb_in_wb_data;
    else
        id_exe_in_rs2_data = regfile_r_data2;
end
// prepare alu_op before EXE stage
always_comb begin
    case(id_exe_in_op_id)
        `OP_ID_ADD, `OP_ID_ADDI, `OP_ID_JALR, `OP_ID_LB, `OP_ID_LW, `OP_ID_LBU,
                `OP_ID_SB, `OP_ID_SW, `OP_ID_AUIPC, `OP_ID_LUI, `OP_ID_JAL:
            id_exe_in_alu_op = `ALU_ADD;
        `OP_ID_SUB: id_exe_in_alu_op = `ALU_SUB;
        `OP_ID_AND, `OP_ID_ANDI: id_exe_in_alu_op = `ALU_AND;
        `OP_ID_OR, `OP_ID_ORI: id_exe_in_alu_op = `ALU_OR;
        `OP_ID_XOR: id_exe_in_alu_op = `ALU_XOR;
        `OP_ID_SLLI: id_exe_in_alu_op = `ALU_SLL;
        `OP_ID_SRLI: id_exe_in_alu_op = `ALU_SRL;
        `OP_ID_XNOR: id_exe_in_alu_op = `ALU_XNOR;
        `OP_ID_MIN: id_exe_in_alu_op = `ALU_MIN;
        `OP_ID_SBSET: id_exe_in_alu_op = `ALU_SBSET;
        `OP_ID_SLTU: id_exe_in_alu_op = `ALU_SLTU;
        default: id_exe_in_alu_op = `ALU_ZERO;
    endcase
end
// for ALU
always_comb begin   // alu_a
    case(id_exe_out_op_id)
        `OP_ID_AUIPC, `OP_ID_JAL, `OP_ID_JALR:
            alu_a = id_exe_out_pc;
        `OP_ID_LUI: alu_a = `ZERO_WORD;
        default: alu_a = id_exe_out_rs1_data;
    endcase
end
always_comb begin   // alu_b
    if (id_exe_out_imm_select) begin
        case (id_exe_out_op_id)
            `OP_ID_JAL, `OP_ID_JALR:
                alu_b = `WORD_BYTE_SIZE;    // offset to next instr
            default: alu_b = id_exe_out_imm;
        endcase
    end
    else alu_b = id_exe_out_rs2_data;
end

/* Generate signals for mem_ctrller
 * Read or write data if op_id for the memory stage is load/store instr
 * Otherwise, fetch the next instruction
 */
always_comb begin
    mem_unsigned_e = 0;
    case(exe_mem_out_op_id)
        `OP_ID_LW: begin
            data_if_hazard = 1;
            mem_r_e = 1;
            mem_w_e = 0;
            mem_byte_mode_e = 0;
            mem_addr = exe_mem_out_alu_res;
            mem_data_in = `ZERO_WORD;
            mem_in_pri_level = exe_mem_out_pri_level;
        end
        `OP_ID_LB: begin
            data_if_hazard = 1;
            mem_r_e = 1;
            mem_w_e = 0;
            mem_byte_mode_e = 1;
            mem_addr = exe_mem_out_alu_res;
            mem_data_in = `ZERO_WORD;
            mem_in_pri_level = exe_mem_out_pri_level;
        end
        `OP_ID_SW: begin
            data_if_hazard = 1;
            mem_r_e = 0;
            mem_w_e = 1;
            mem_byte_mode_e = 0;
            mem_addr = exe_mem_out_alu_res;
            mem_data_in = exe_mem_out_rs2_data;
            mem_in_pri_level = exe_mem_out_pri_level;
        end
        `OP_ID_SB: begin
            data_if_hazard = 1;
            mem_r_e = 0;
            mem_w_e = 1;
            mem_byte_mode_e = 1;
            mem_addr = exe_mem_out_alu_res;
            mem_data_in = exe_mem_out_rs2_data;
            mem_in_pri_level = exe_mem_out_pri_level;
        end
        `OP_ID_LBU: begin
            data_if_hazard = 1;
            mem_r_e = 1;
            mem_w_e = 0;
            mem_byte_mode_e = 1;
            mem_unsigned_e = 1;
            mem_addr = exe_mem_out_alu_res;
            mem_data_in = `ZERO_WORD;
        end
        default: begin  // fetch new instr
            data_if_hazard = 0;
            mem_r_e = 1;
            mem_w_e = 0;
            mem_byte_mode_e = 0;
            mem_addr = fetching_pc;
            mem_data_in = `ZERO_WORD;
            mem_in_pri_level = bf_if_out_pri_level;
        end
    endcase
end

// select the data to write back
always_comb begin
    case(exe_mem_out_op_id)
        `OP_ID_ADD, `OP_ID_SUB, `OP_ID_AND, `OP_ID_OR, `OP_ID_XOR, 
        `OP_ID_ADDI, `OP_ID_ANDI, `OP_ID_JALR, `OP_ID_ORI, `OP_ID_SLLI, 
        `OP_ID_SRLI, `OP_ID_AUIPC, `OP_ID_LUI, `OP_ID_JAL, 
        `OP_ID_CSRRW, `OP_ID_CSRRS, `OP_ID_CSRRC,
        `OP_ID_XNOR, `OP_ID_MIN, `OP_ID_SBSET, `OP_ID_SLTU:
            mem_wb_in_wb_data = exe_mem_out_alu_res;
        `OP_ID_LW, `OP_ID_LB, `OP_ID_LBU:
            mem_wb_in_wb_data = mem_data_out;
        default: mem_wb_in_wb_data = `ZERO_WORD;
    endcase
end

/* "load & use" hazard detection
 * this may lead to a bubble
 */
always_comb begin
    if ((id_exe_out_op_id == `OP_ID_LW || id_exe_out_op_id == `OP_ID_LB || id_exe_out_op_id == `OP_ID_LBU) && 
        id_exe_out_wb_e && 
        (id_exe_out_rd == decoder_rs1 || id_exe_out_rd == decoder_rs2))
        load_use_hazard = 1;
    else
        load_use_hazard = 0;
end

// display some info for debugging
assign leds[13:0] = if_id_out_pc[13:0];
assign leds[15:14] = {mem_data_out[0], uart_dataready};
SEG7_LUT seg0(.iDIG(0), .oSEG1(dpy0));
SEG7_LUT seg1(.iDIG(0), .oSEG1(dpy1));

//ila_0 ila(clk_50M, fetching_pc, decoder_instr, bf_if_out_pc, next_pc_to_fetch, mem_data_out, poss_new_pc);


endmodule
