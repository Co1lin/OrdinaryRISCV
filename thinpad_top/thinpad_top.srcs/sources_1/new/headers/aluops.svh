`ifndef ALUOPS_H
`define ALUOPS_H

`define ALU_OP_WIDTH    5

`define alu_op_reg_t    reg[`ALU_OP_WIDTH-1 : 0]
`define alu_op_wire_t   wire[`ALU_OP_WIDTH-1 : 0]

`define ALU_ZERO    `ALU_OP_WIDTH'd0
`define ALU_ADD     `ALU_OP_WIDTH'd1
`define ALU_SUB     `ALU_OP_WIDTH'd2
`define ALU_AND     `ALU_OP_WIDTH'd3
`define ALU_OR      `ALU_OP_WIDTH'd4
`define ALU_XOR     `ALU_OP_WIDTH'd5
`define ALU_NOT     `ALU_OP_WIDTH'd6
`define ALU_SLL     `ALU_OP_WIDTH'd7
`define ALU_SRL     `ALU_OP_WIDTH'd8
`define ALU_SRA     `ALU_OP_WIDTH'd9
`define ALU_ROL     `ALU_OP_WIDTH'd10
`define ALU_XNOR    `ALU_OP_WIDTH'd11
`define ALU_MIN     `ALU_OP_WIDTH'd12
`define ALU_SBSET   `ALU_OP_WIDTH'd13
`define ALU_SLTU    `ALU_OP_WIDTH'd14


`endif