`ifndef COMMON_H
`define COMMON_H
`include "ops.svh"

`define BASE            32
`define WORD_SIZE       32
`define BYTE_SIZE       8
`define WORD_BYTE_SIZE  4

`define ZERO_WORD       `WORD_SIZE'h0

`define INSTR_WIDTH     `BASE
`define instr_reg_t     reg[`INSTR_WIDTH-1 : 0]
`define instr_wire_t    wire[`INSTR_WIDTH-1 : 0]

`define INSTR_WIDTH     `BASE
`define imm_reg_t       reg[`INSTR_WIDTH-1 : 0]
`define imm_wire_t      wire[`INSTR_WIDTH-1 : 0]

`define REGID_WIDTH     5
`define regid_reg_t     reg[`REGID_WIDTH-1 : 0]
`define regid_wire_t    reg[`REGID_WIDTH-1 : 0]

`define word_reg_t      reg[`WORD_SIZE-1 : 0]
`define word_wire_t     wire[`WORD_SIZE-1 : 0]
`define byte_reg_t      reg[`BYTE_SIZE-1 : 0]
`define byte_wire_t     wire[`BYTE_SIZE-1 : 0]

`define MEM_ADDR_WIDTH  `BASE
`define mem_addr_reg_t  reg[`BASE-1 : 0]
`define mem_addr_wire_t wire[`BASE-1 : 0]

`define PC_WIDTH        `BASE
`define pc_reg_t        `mem_addr_reg_t
`define pc_wire_t       `mem_addr_wire_t

`define INIT_PC         32'h8000_0000

`define INSTR_NOP       32'h0000_0033   // add zero,zero,zero
`define OP_ID_NOP       `OP_ID_ADD

`endif