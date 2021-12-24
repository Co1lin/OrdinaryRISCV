`ifndef EXC_H
`define EXC_H

`include "csrs.svh"

`define PRI_LEVEL_WIDTH     2
`define pri_level_reg_t     reg[`PRI_LEVEL_WIDTH-1:0]
`define pri_level_wire_t    wire[`PRI_LEVEL_WIDTH-1:0]
`define LEVEL_USER          `PRI_LEVEL_WIDTH'b00
`define LEVEL_SUPERVISOR    `PRI_LEVEL_WIDTH'b01
`define LEVEL_ILLEGAL       `PRI_LEVEL_WIDTH'b10
`define LEVEL_MACHINE       `PRI_LEVEL_WIDTH'b11

// exception(in broad sense) code for mcause
// currently only support machine timer interrupt and exception in a narrow sense
`define EXC_CODE_INTERRUPT_MACHINE_TIMER 7
`define EXC_CODE_EXCEPTION_BREAK 3
`define EXC_CODE_EXCEPTION_ECALL_FROM_U 8

`endif