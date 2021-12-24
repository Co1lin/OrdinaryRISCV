`define BASE            32
`define WORD_SIZE       32
`define BYTE_SIZE       8
`define WORD_BYTE_SIZE  4

`define ZERO_WORD       `WORD_SIZE'h0

`define instr_reg_t     reg[`BASE-1 : 0]
`define instr_wire_t    wire[`BASE-1 : 0]

`define imm_reg_t       reg[`BASE-1 : 0]
`define imm_wire_t      wire[`BASE-1 : 0]

`define regid_reg_t     reg[4 : 0]
`define regid_wire_t    reg[4 : 0]

`define word_reg_t      reg[`WORD_SIZE-1 : 0]
`define word_wire_t     wire[`WORD_SIZE-1 : 0]
`define byte_reg_t      reg[`BYTE_SIZE-1 : 0]
`define byte_wire_t     wire[`BYTE_SIZE-1 : 0]

`define mem_addr_reg_t  reg[`BASE-1 : 0]
`define mem_addr_wire_t wire[`BASE-1 : 0]

`define pc_reg_t        `mem_addr_reg_t
`define pc_wire_t       `mem_addr_wire_t