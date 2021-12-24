`define OP_ID_WIDTH 6
`define op_id_reg_t reg[`OP_ID_WIDTH-1 : 0]
`define op_id_wire_t wire[`OP_ID_WIDTH-1 : 0]

`define OP_ID_INVALID   `OP_ID_WIDTH'd0
// OP Identifier
// R Type
`define OP_ID_ADD   `OP_ID_WIDTH'd1
`define OP_ID_SUB   `OP_ID_WIDTH'd2
`define OP_ID_AND   `OP_ID_WIDTH'd3
`define OP_ID_OR    `OP_ID_WIDTH'd4
`define OP_ID_XOR   `OP_ID_WIDTH'd5

// I Type
`define OP_ID_ADDI  `OP_ID_WIDTH'd6
`define OP_ID_ANDI  `OP_ID_WIDTH'd7
`define OP_ID_JALR  `OP_ID_WIDTH'd8
`define OP_ID_LB    `OP_ID_WIDTH'd9
`define OP_ID_LW    `OP_ID_WIDTH'd10
`define OP_ID_ORI   `OP_ID_WIDTH'd11
`define OP_ID_SLLI  `OP_ID_WIDTH'd12
`define OP_ID_SRLI  `OP_ID_WIDTH'd13

// S Type
`define OP_ID_SB    `OP_ID_WIDTH'd14
`define OP_ID_SW    `OP_ID_WIDTH'd15

// B Type
`define OP_ID_BEQ   `OP_ID_WIDTH'd16
`define OP_ID_BNE   `OP_ID_WIDTH'd17

// U Type
`define OP_ID_AUIPC `OP_ID_WIDTH'd18
`define OP_ID_LUI   `OP_ID_WIDTH'd19

// J Type
`define OP_ID_JAL   `OP_ID_WIDTH'd20
