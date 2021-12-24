`ifndef CSRS_H
`define CSRS_H

`include "common.svh"

`define CSR_ADDR_WIDTH      12
`define csr_addr_wire_t     wire[`CSR_ADDR_WIDTH-1:0]
`define csr_addr_reg_t      reg[`CSR_ADDR_WIDTH-1:0]

`define MXLEN 				`BASE
`define mxlen_reg_t         reg[`MXLEN-1 : 0]
`define mxlen_wire_t        wire[`MXLEN-1 : 0]
`define sxlen_reg_t         reg[`MXLEN-1 : 0]
`define sxlen_wire_t        wire[`MXLEN-1 : 0]

// CSRs
// Ref: https://www.five-embeddev.com/quickref/csrs.html
`define CSR_MSTATUS 		`CSR_ADDR_WIDTH'h300
`define CSR_MIE 			`CSR_ADDR_WIDTH'h304
`define CSR_MTVEC 			`CSR_ADDR_WIDTH'h305
`define CSR_MSCRATCH 		`CSR_ADDR_WIDTH'h340
`define CSR_MEPC 			`CSR_ADDR_WIDTH'h341
`define CSR_MCAUSE 			`CSR_ADDR_WIDTH'h342
`define CSR_MIP 			`CSR_ADDR_WIDTH'h344
`define CSR_SATP            `CSR_ADDR_WIDTH'h180

// write mask for csr instruction
// 1 stands for writable, 0 stands for not writable
// each bit functions as a selector between new value and old value 

// mip:
// Only the bits corresponding to lower-privilege software interrupts (USIP, SSIP), timer interrupts
// (UTIP, STIP), and external interrupts (UEIP, SEIP) in mip are writable through this CSR address;
// the remaining bits are read-only.
`define CSR_MIP_MASK        32'b0000_0000_0000_0000_0000_0011_0011_0011

// memory mapped csrs
`define CSR_MTIME           32'h0200_bff8
`define CSR_MTIME_HIGH      32'h0200_bffc
`define CSR_MTIMECMP        32'h0200_4000
`define CSR_MTIMECMP_HIGH   32'h0200_4004

// CSR Reg Structures
typedef struct packed {
    reg[`MXLEN-13 : 0] WPRI_0;
    reg meip, WPRI_1, seip, ueip, mtip, WPRI_2, stip, utip, msip, WPRI_3, ssip, usip;
} mip_t;

typedef struct packed {
    reg[`MXLEN-13 : 0] WPRI_0;
    reg meie, WPRI_1, seie, ueie, mtie, WPRI_2, stie, utie, msie, WPRI_3, ssie, usie;
} mie_t;

typedef struct packed {
    reg sd; reg[7:0] WPRI_0;
    reg tsr, tw, tvm, mxr, sum, mprv;
    reg[1:0] xs, fs, mpp, WPRI_1;
    reg spp, mpie, WPRI_2, spie, upie, mie, WPRI_3, sie, uie;
} mstatus_t; // mpp, spp is WARL

typedef struct packed {
    reg[`MXLEN-3 : 0] base;
    reg[1:0] mode;
} mtvec_t; // base, mode is WARL

typedef struct packed {
    reg intrpt; reg[`MXLEN-2 : 0] exception_code;
} mcause_t; // exception_code is WLRL

typedef struct packed {
    reg mode; reg[8:0] asid; reg[21:0] ppn;
} satp_t;

typedef reg[`MXLEN-1 : 0] mscratch_t;
typedef reg[`MXLEN-1 : 0] mepc_t; // WARL
// typedef reg[`MXLEN-1 : 0] mtval_t;

`endif