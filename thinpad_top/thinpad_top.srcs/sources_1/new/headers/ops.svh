// Generated file. DO NOT EDIT!

`ifndef OPS_H
`define OPS_H

`define OP_ID_WIDTH  6
`define op_id_reg_t  reg[`OP_ID_WIDTH-1 : 0]
`define op_id_wire_t wire[`OP_ID_WIDTH-1 : 0]

// Invalid
`define OP_ID_INVALID      `OP_ID_WIDTH'd0

// R Type
`define OP_ID_ADD          `OP_ID_WIDTH'd1
`define OP_ID_SUB          `OP_ID_WIDTH'd2
`define OP_ID_AND          `OP_ID_WIDTH'd3
`define OP_ID_OR           `OP_ID_WIDTH'd4
`define OP_ID_XOR          `OP_ID_WIDTH'd5
`define OP_ID_SLTU         `OP_ID_WIDTH'd6
`define OP_ID_XNOR         `OP_ID_WIDTH'd7
`define OP_ID_SBSET        `OP_ID_WIDTH'd8
`define OP_ID_MIN          `OP_ID_WIDTH'd9

// I Type
`define OP_ID_ADDI         `OP_ID_WIDTH'd10
`define OP_ID_ANDI         `OP_ID_WIDTH'd11
`define OP_ID_JALR         `OP_ID_WIDTH'd12
`define OP_ID_LB           `OP_ID_WIDTH'd13
`define OP_ID_LW           `OP_ID_WIDTH'd14
`define OP_ID_LBU          `OP_ID_WIDTH'd15
`define OP_ID_ORI          `OP_ID_WIDTH'd16
`define OP_ID_SLLI         `OP_ID_WIDTH'd17
`define OP_ID_SRLI         `OP_ID_WIDTH'd18

// S Type
`define OP_ID_SB           `OP_ID_WIDTH'd19
`define OP_ID_SW           `OP_ID_WIDTH'd20

// B Type
`define OP_ID_BEQ          `OP_ID_WIDTH'd21
`define OP_ID_BNE          `OP_ID_WIDTH'd22
`define OP_ID_BGEU         `OP_ID_WIDTH'd23

// U Type
`define OP_ID_AUIPC        `OP_ID_WIDTH'd24
`define OP_ID_LUI          `OP_ID_WIDTH'd25

// J Type
`define OP_ID_JAL          `OP_ID_WIDTH'd26

// Privileged Instructions
`define OP_ID_CSRRC        `OP_ID_WIDTH'd27
`define OP_ID_CSRRS        `OP_ID_WIDTH'd28
`define OP_ID_CSRRW        `OP_ID_WIDTH'd29
`define OP_ID_EBREAK       `OP_ID_WIDTH'd30
`define OP_ID_ECALL        `OP_ID_WIDTH'd31
`define OP_ID_MRET         `OP_ID_WIDTH'd32
`define OP_ID_SFENCE_VM    `OP_ID_WIDTH'd33

`endif
