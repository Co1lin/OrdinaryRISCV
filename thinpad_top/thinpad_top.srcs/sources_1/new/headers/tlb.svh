`ifndef TLB_H
`define TLB_H

`include "csrs.svh"
`define PAGE_OFFSET     12
`define TAG_WIDTH       5
`define INDEX_WIDTH     32-`TAG_WIDTH-`PAGE_OFFSET
typedef struct packed {
    reg[`INDEX_WIDTH-1 : 0] index;
    reg[8:0] asid;
    reg[21:0] ppn;
    reg valid;
} tlb_item;

`endif
